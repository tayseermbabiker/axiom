// Audexon — Lemon Squeezy webhook handler
//
// Verifies HMAC signature, maps the LS variant to an Audexon tier
// (starter/team/firm), and updates the org's plan + max_members.
//
// Required Netlify env vars:
//   LEMONSQUEEZY_WEBHOOK_SECRET  — signing secret set in LS webhook config
//   SUPABASE_URL                  — e.g. https://xxx.supabase.co
//   SUPABASE_SERVICE_ROLE_KEY     — service_role (bypasses RLS, server-only)
//   LEMON_VARIANT_STARTER         — LS variant ID for the $49 Starter plan
//   LEMON_VARIANT_TEAM            — LS variant ID for the $99 Team plan
//   LEMON_VARIANT_FIRM            — LS variant ID for the $199 Firm plan
//
// LS dashboard setup:
//   Settings → Webhooks → New webhook
//     URL:    https://audexon.com/.netlify/functions/lemon-webhook
//     Events: subscription_created, subscription_updated, subscription_cancelled,
//             subscription_resumed, subscription_expired, subscription_payment_success

const crypto = require('crypto');

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

const TIER_BY_VARIANT = {
  [process.env.LEMON_VARIANT_STARTER]: { plan: 'starter', max_members: 5  },
  [process.env.LEMON_VARIANT_TEAM]:    { plan: 'team',    max_members: 12 },
  [process.env.LEMON_VARIANT_FIRM]:    { plan: 'firm',    max_members: 25 },
};

exports.handler = async (event) => {
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Method not allowed' };
  }

  const rawBody = event.body || '';
  const signature = event.headers['x-signature'] || event.headers['X-Signature'];
  const secret = process.env.LEMONSQUEEZY_WEBHOOK_SECRET;

  if (!secret) {
    console.error('[lemon-webhook] LEMONSQUEEZY_WEBHOOK_SECRET not set');
    return { statusCode: 500, body: 'Webhook secret not configured' };
  }
  if (!signature) {
    return { statusCode: 401, body: 'Missing signature' };
  }

  const expected = crypto.createHmac('sha256', secret).update(rawBody).digest('hex');
  const valid =
    signature.length === expected.length &&
    crypto.timingSafeEqual(Buffer.from(signature, 'utf8'), Buffer.from(expected, 'utf8'));
  if (!valid) {
    console.warn('[lemon-webhook] invalid signature');
    return { statusCode: 401, body: 'Invalid signature' };
  }

  let payload;
  try {
    payload = JSON.parse(rawBody);
  } catch (e) {
    return { statusCode: 400, body: 'Invalid JSON' };
  }

  const eventName = payload?.meta?.event_name || '';
  const customData = payload?.meta?.custom_data || {};
  const attrs = payload?.data?.attributes || {};
  const userId = customData.user_id || null;
  const email = attrs.user_email || null;
  const variantId = String(attrs.variant_id || '');
  const subscriptionId = payload?.data?.id || null;
  const status = attrs.status || null;
  const renewsAt = attrs.renews_at || null;
  const endsAt = attrs.ends_at || null;

  console.log(`[lemon-webhook] ${eventName}`, { userId, email, variantId, status });

  // Resolve tier from variant id (skip the lookup for events that don't need it)
  const tier = TIER_BY_VARIANT[variantId] || null;

  let action = null; // 'activate' | 'expire' | 'noop'
  switch (eventName) {
    case 'subscription_created':
    case 'subscription_resumed':
    case 'subscription_payment_success':
      action = (status === 'active' || status === 'on_trial' || status === 'past_due') ? 'activate' : 'noop';
      break;
    case 'subscription_updated':
      // Plan change (upgrade/downgrade) — re-apply tier
      action = 'activate';
      break;
    case 'subscription_cancelled':
      // User cancelled but keeps access until ends_at — leave plan as-is, just record status
      action = 'note';
      break;
    case 'subscription_expired':
      action = 'expire';
      break;
    default:
      return { statusCode: 200, body: JSON.stringify({ received: true, ignored: eventName }) };
  }

  if (action === 'activate' && !tier) {
    console.warn('[lemon-webhook] unknown variant_id, cannot map to tier:', variantId);
    return { statusCode: 200, body: JSON.stringify({ received: true, warning: 'unknown variant' }) };
  }

  try {
    const orgId = await findOrgId({ userId, email });
    if (!orgId) {
      console.warn('[lemon-webhook] no org found for', { userId, email });
      return { statusCode: 200, body: JSON.stringify({ received: true, warning: 'no org' }) };
    }

    if (action === 'activate') {
      await patchOrg(orgId, {
        plan: tier.plan,
        max_members: tier.max_members,
      });
    } else if (action === 'expire') {
      // Subscription ended — drop back to a safe baseline. Admin can reactivate manually.
      await patchOrg(orgId, {
        plan: 'starter',
        max_members: 5,
      });
    }
    // 'note' (cancelled) — no DB change yet; could be added once we track subscription_id

    console.log('[lemon-webhook] applied', { orgId, action, plan: tier?.plan, subscriptionId, renewsAt, endsAt });
  } catch (e) {
    console.error('[lemon-webhook] update failed:', e.message);
    return { statusCode: 500, body: 'Update failed' };
  }

  return {
    statusCode: 200,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ received: true, event: eventName, action }),
  };
};

// --- Supabase helpers ----------------------------------------------------

async function findOrgId({ userId, email }) {
  if (!SUPABASE_URL || !SUPABASE_KEY) {
    throw new Error('Supabase env vars not set');
  }

  let resolvedUserId = userId;
  if (!resolvedUserId && email) {
    resolvedUserId = await lookupUserIdByEmail(email);
  }
  if (!resolvedUserId) return null;

  // The org "owner" is the admin in organization_members
  const url = `${SUPABASE_URL}/rest/v1/organization_members?select=organization_id&user_id=eq.${encodeURIComponent(resolvedUserId)}&role=eq.admin&limit=1`;
  const res = await fetch(url, {
    headers: {
      apikey: SUPABASE_KEY,
      Authorization: `Bearer ${SUPABASE_KEY}`,
    },
  });
  if (!res.ok) {
    throw new Error(`Supabase ${res.status}: ${await res.text()}`);
  }
  const rows = await res.json();
  return rows?.[0]?.organization_id || null;
}

async function lookupUserIdByEmail(email) {
  const url = `${SUPABASE_URL}/auth/v1/admin/users?email=${encodeURIComponent(email)}`;
  const res = await fetch(url, {
    headers: {
      apikey: SUPABASE_KEY,
      Authorization: `Bearer ${SUPABASE_KEY}`,
    },
  });
  if (!res.ok) return null;
  const data = await res.json();
  return data?.users?.[0]?.id || null;
}

async function patchOrg(orgId, fields) {
  const url = `${SUPABASE_URL}/rest/v1/organizations?id=eq.${encodeURIComponent(orgId)}`;
  const res = await fetch(url, {
    method: 'PATCH',
    headers: {
      apikey: SUPABASE_KEY,
      Authorization: `Bearer ${SUPABASE_KEY}`,
      'Content-Type': 'application/json',
      Prefer: 'return=minimal',
    },
    body: JSON.stringify(fields),
  });
  if (!res.ok) {
    throw new Error(`Supabase PATCH ${res.status}: ${await res.text()}`);
  }
}
