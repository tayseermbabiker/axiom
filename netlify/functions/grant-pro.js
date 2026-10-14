// Audexon — activate Pro outside Stripe + send welcome email
//
// Admin-only tool for subscriptions agreed outside Stripe (e.g. a signed
// contract with a full fee waiver). Two-step by design:
//
//   1. Preview (no changes):
//      /.netlify/functions/grant-pro?key=GRANT_SECRET&email=admin@firm.com&tier=starter&from=2026-10-14
//   2. Apply (updates the org + sends the welcome email):
//      ...same URL...&confirm=1
//
// Params:
//   email  — email of the firm's admin user (the person who created the org)
//   tier   — starter | team | firm   (same seat limits as stripe-webhook: 5 / 12 / 25 users)
//   from   — optional subscription start date, YYYY-MM-DD (default: today) — shown in the email
//   until  — optional internal note only (e.g. waiver end); NOT shown in the email.
//            Access does NOT auto-expire — revoke with `update organizations set plan = null where id = ...`
//   confirm=1 — actually apply
//
// Required Netlify env vars:
//   GRANT_SECRET, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, RESEND_API_KEY

const crypto = require('crypto');
const { Resend } = require('resend');

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const SITE_URL = process.env.SITE_URL || 'https://auditsaas.netlify.app';

// Same seat limits as stripe-webhook.js TIER_BY_PRICE.
const TIERS = {
  starter: { max_members: 5,  label_en: 'Up to 5 users',  label_ar: 'حتى 5 مستخدمين',   count_ar: '5 مستخدمين' },
  team:    { max_members: 12, label_en: 'Up to 12 users', label_ar: 'حتى 12 مستخدماً', count_ar: '12 مستخدماً' },
  firm:    { max_members: 25, label_en: 'Up to 25 users', label_ar: 'حتى 25 مستخدماً', count_ar: '25 مستخدماً' },
};

exports.handler = async (event) => {
  if (event.httpMethod !== 'GET') return json(405, { error: 'Method not allowed' });

  const secret = process.env.GRANT_SECRET;
  if (!secret) return json(500, { error: 'GRANT_SECRET not configured' });
  const p = event.queryStringParameters || {};
  if (!safeEqual(p.key || '', secret)) return json(401, { error: 'Unauthorized' });
  if (!SUPABASE_URL || !SUPABASE_KEY) return json(500, { error: 'Supabase env vars not set' });

  const email = (p.email || '').trim().toLowerCase();
  const tierKey = (p.tier || '').trim().toLowerCase();
  const until = (p.until || '').trim();
  const from = (p.from || new Date().toISOString().slice(0, 10)).trim();
  const confirm = p.confirm === '1';

  if (!email) return json(400, { error: 'email is required' });
  if (!TIERS[tierKey]) return json(400, { error: 'tier must be starter, team or firm' });
  if (!isDate(from)) return json(400, { error: 'from must be YYYY-MM-DD' });
  if (until && !isDate(until)) return json(400, { error: 'until must be YYYY-MM-DD' });
  if (until && until < from) return json(400, { error: 'until is before from' });

  try {
    // Exact email match via profiles (populated from auth.users by trigger).
    const profiles = await sb(`profiles?select=id,email,full_name&email=eq.${encodeURIComponent(email)}`);
    if (profiles.length !== 1) {
      return json(404, { error: `Expected exactly 1 user with that email, found ${profiles.length}` });
    }
    const user = profiles[0];

    const memberships = await sb(`organization_members?select=organization_id,role&user_id=eq.${user.id}&role=eq.admin`);
    if (memberships.length !== 1) {
      return json(404, { error: `Expected the user to be admin of exactly 1 organization, found ${memberships.length}` });
    }
    const orgId = memberships[0].organization_id;
    const orgs = await sb(`organizations?select=id,name,plan,feature_tier,max_members,trial_expires_at&id=eq.${orgId}`);
    const org = orgs[0];
    if (!org) return json(404, { error: 'Organization not found' });

    const tier = TIERS[tierKey];
    const changes = { plan: tierKey, feature_tier: 'pro', max_members: tier.max_members };
    const summary = {
      user: { email: user.email, name: user.full_name },
      organization: { id: org.id, name: org.name },
      before: { plan: org.plan, feature_tier: org.feature_tier, max_members: org.max_members, trial_expires_at: org.trial_expires_at },
      after: changes,
      start_date: from,
      internal_note_until: until || null,
      welcome_email_to: user.email,
    };

    if (!confirm) {
      return json(200, { mode: 'PREVIEW — nothing changed. Add &confirm=1 to apply.', ...summary });
    }

    await sb(`organizations?id=eq.${orgId}`, { method: 'PATCH', body: changes });

    let emailResult;
    try {
      const resend = new Resend(process.env.RESEND_API_KEY);
      const { data, error } = await resend.emails.send({
        from: 'Audexon <noreply@audexon.com>',
        to: user.email,
        reply_to: 'support@audexon.com',
        subject: 'تأكيد تفعيل اشتراككم في منصة Audexon — باقة Pro',
        html: welcomeHtml({ orgName: org.name, tier, from }),
      });
      emailResult = error ? { sent: false, error: error.message } : { sent: true, id: data.id };
    } catch (e) {
      emailResult = { sent: false, error: e.message };
    }

    console.log('[grant-pro] applied', { orgId, tier: tierKey, until, email: emailResult.sent });
    return json(200, { mode: 'APPLIED', ...summary, email: emailResult });
  } catch (e) {
    console.error('[grant-pro] failed:', e.message);
    return json(500, { error: e.message });
  }
};

function welcomeHtml({ orgName, tier, from }) {
  const esc = (s) => String(s || '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const loginUrl = `${SITE_URL}/pages/login.html`;
  const [y, m, d] = from.split('-');
  const fromDisplay = `${d}/${m}/${y}`;
  const p = (html) => `<p style="font-size:14px;color:#374151;line-height:1.9;margin:0 0 14px;">${html}</p>`;
  const li = (title, body) => `<li style="font-size:14px;color:#374151;line-height:1.9;margin:0 0 10px;"><strong>${title}:</strong> ${body}</li>`;
  const row = (k, v) => `<tr><td style="padding:8px 12px;font-size:13px;color:#6b7280;border-bottom:1px solid #eef0f3;width:40%;">${k}</td><td style="padding:8px 12px;font-size:13px;font-weight:600;color:#111827;border-bottom:1px solid #eef0f3;">${v}</td></tr>`;
  return `
  <div dir="rtl" style="font-family:Tahoma,'Segoe UI',Arial,sans-serif;max-width:580px;margin:0 auto;padding:32px 0;text-align:right;">
    <div style="background:#0A1A2F;padding:24px 28px;border-radius:12px 12px 0 0;">
      <h1 style="color:white;margin:0;font-size:22px;font-weight:700;">Audexon</h1>
    </div>
    <div style="background:white;border:1px solid #e5e7eb;border-top:none;padding:28px;border-radius:0 0 12px 12px;">
      <p style="font-size:15px;color:#111827;margin:0 0 12px;">السادة / <strong>${esc(orgName)}</strong> المحترمون،</p>
      ${p('تحية طيبة وبعد،')}
      ${p('يسعدنا إعلامكم بتفعيل اشتراككم رسمياً في منصة <strong>Audexon</strong> لإدارة أعمال التدقيق.')}
      <p style="font-size:14px;color:#111827;font-weight:700;margin:18px 0 8px;">تفاصيل الاشتراك:</p>
      <table dir="rtl" style="border-collapse:collapse;width:100%;background:#F8FAFC;border:1px solid #eef0f3;border-radius:8px;margin:0 0 20px;">
        ${row('الباقة', 'Pro')}
        ${row('عدد المستخدمين', esc(tier.label_ar))}
        ${row('تاريخ التفعيل', esc(fromDisplay))}
      </table>
      <p style="font-size:14px;color:#111827;font-weight:700;margin:0 0 8px;">تتضمن باقتكم المزايا التالية:</p>
      <ul style="padding-right:20px;padding-left:0;margin:0 0 16px;">
        ${li('إدارة ملفات التدقيق', 'إنشاء ملفات تدقيق غير محدودة، وتتبع مراحل العمل (التخطيط، والتنفيذ، والإنجاز) وفقاً للمعايير الدولية للمراجعة (ISA).')}
        ${li('إدارة طلبات العملاء (PBC)', 'قوائم مخصصة لطلب وتتبع مستندات العملاء بكل كفاءة.')}
        ${li('الأرشفة والإغلاق', 'أرشفة وإغلاق ملفات التدقيق وفق معيار المراجعة الدولي (ISA 230).')}
        ${li('دعم متعدد اللغات', 'واجهة سحابية متكاملة تدعم اللغتين العربية والإنجليزية.')}
      </ul>
      ${p('يمكنكم الآن البدء بإنشاء حسابات فريق العمل وإدارة مشاريعكم عبر المنصة.')}
      <div style="text-align:center;margin:24px 0 8px;">
        <a href="${loginUrl}" style="display:inline-block;background:#3A7BFF;color:white;padding:10px 24px;border-radius:8px;text-decoration:none;font-weight:600;font-size:14px;">تسجيل الدخول إلى المنصة</a>
      </div>
      <hr style="border:none;border-top:1px solid #e5e7eb;margin:24px 0 16px;">
      <p style="font-size:12px;color:#6b7280;margin:0 0 6px;line-height:1.7;text-align:center;">لأي استفسار، يرجى التواصل مع فريق الدعم الفني عبر: <a href="mailto:support@audexon.com" style="color:#3A7BFF;text-decoration:none;">support@audexon.com</a></p>
      <p style="font-size:12px;color:#9ca3af;margin:0;text-align:center;"><a href="${SITE_URL}/terms.html" style="color:#9ca3af;">شروط الخدمة</a> · <a href="${SITE_URL}/privacy.html" style="color:#9ca3af;">سياسة الخصوصية</a></p>
    </div>
    <p style="font-size:11px;color:#9ca3af;text-align:center;margin-top:16px;">Audexon</p>
  </div>`;
}

async function sb(path, opts = {}) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    method: opts.method || 'GET',
    headers: {
      apikey: SUPABASE_KEY,
      Authorization: `Bearer ${SUPABASE_KEY}`,
      'Content-Type': 'application/json',
      Prefer: 'return=minimal',
    },
    body: opts.body ? JSON.stringify(opts.body) : undefined,
  });
  if (!res.ok) throw new Error(`Supabase ${res.status}: ${await res.text()}`);
  return opts.method === 'PATCH' ? null : res.json();
}

function isDate(s) {
  return /^\d{4}-\d{2}-\d{2}$/.test(s) && !isNaN(new Date(s + 'T00:00:00Z'));
}

function safeEqual(a, b) {
  const x = Buffer.from(String(a));
  const y = Buffer.from(String(b));
  return x.length === y.length && crypto.timingSafeEqual(x, y);
}

function json(statusCode, body) {
  return { statusCode, headers: { 'Content-Type': 'application/json; charset=utf-8' }, body: JSON.stringify(body, null, 2) };
}
