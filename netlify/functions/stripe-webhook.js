// Audexon — Stripe webhook handler
//
// Verifies Stripe signature, maps the price_id to an Audexon tier
// (starter/team/firm), and updates the org's plan + max_members.
//
// Required Netlify env vars:
//   STRIPE_WEBHOOK_SECRET   — signing secret from Stripe webhook config (whsec_...)
//   STRIPE_SECRET_KEY       — Stripe API key (sk_live_... or sk_test_...)
//   SUPABASE_URL            — e.g. https://xxx.supabase.co
//   SUPABASE_SERVICE_ROLE_KEY — service_role (bypasses RLS, server-only)
//   Execution plan (essentials tier):
//   STRIPE_PRICE_STARTER      — $49  Execution Starter (<=5)
//   STRIPE_PRICE_TEAM         — $99  Execution Team (<=12)
//   STRIPE_PRICE_FIRM         — $199 Execution Firm (<=25)
//   Full Workflow plan (pro tier):
//   STRIPE_PRICE_FULL_STARTER — $199 Full Workflow Starter (<=5)
//   STRIPE_PRICE_FULL_TEAM    — $299 Full Workflow Team (<=12)
//   STRIPE_PRICE_FULL_FIRM    — $399 Full Workflow Firm (<=25)
//
// Stripe dashboard setup:
//   Webhooks → Add endpoint
//     URL:    https://audexon.com/.netlify/functions/stripe-webhook
//     Events: checkout.session.completed, customer.subscription.updated,
//             customer.subscription.deleted, invoice.payment_succeeded

const crypto = require('crypto');

const STRIPE_SECRET_KEY = process.env.STRIPE_SECRET_KEY;
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

const TIER_BY_PRICE = {
  // Execution plan -> essentials feature tier (reuses the original 3 price vars)
  [process.env.STRIPE_PRICE_STARTER]:      { plan: 'starter', max_members: 5,  feature_tier: 'essentials' },
  [process.env.STRIPE_PRICE_TEAM]:         { plan: 'team',    max_members: 12, feature_tier: 'essentials' },
  [process.env.STRIPE_PRICE_FIRM]:         { plan: 'firm',    max_members: 25, feature_tier: 'essentials' },
  // Full Workflow plan -> pro feature tier (3 new price vars)
  [process.env.STRIPE_PRICE_FULL_STARTER]: { plan: 'starter', max_members: 5,  feature_tier: 'pro' },
  [process.env.STRIPE_PRICE_FULL_TEAM]:    { plan: 'team',    max_members: 12, feature_tier: 'pro' },
  [process.env.STRIPE_PRICE_FULL_FIRM]:    { plan: 'firm',    max_members: 25, feature_tier: 'pro' },
};

exports.handler = async (event) => {
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Method not allowed' };
  }

  const rawBody = event.body || '';
  const signatureHeader = event.headers['stripe-signature'] || event.headers['Stripe-Signature'];
  const secret = process.env.STRIPE_WEBHOOK_SECRET;

  if (!secret) {
    console.error('[stripe-webhook] STRIPE_WEBHOOK_SECRET not set');
    return { statusCode: 500, body: 'Webhook secret not configured' };
  }
  if (!signatureHeader) {
    return { statusCode: 401, body: 'Missing signature' };
  }

  if (!verifyStripeSignature(rawBody, signatureHeader, secret)) {
    console.warn('[stripe-webhook] invalid signature');
    return { statusCode: 401, body: 'Invalid signature' };
  }

  let payload;
  try {
    payload = JSON.parse(rawBody);
  } catch (e) {
    return { statusCode: 400, body: 'Invalid JSON' };
  }

  const eventType = payload?.type || '';
  const obj = payload?.data?.object || {};
  console.log(`[stripe-webhook] ${eventType}`, { id: obj.id });

  try {
    switch (eventType) {
      case 'checkout.session.completed': {
        // Initial subscription — link user → org → plan
        const userId = obj.client_reference_id || null;
        const email = obj.customer_email || obj.customer_details?.email || null;
        const subscriptionId = obj.subscription;
        const customerId = obj.customer || null;

        if (!subscriptionId) {
          console.warn('[stripe-webhook] no subscription on session');
          return ok({ ignored: 'no subscription' });
        }

        const sub = await fetchSubscription(subscriptionId);
        const priceId = sub?.items?.data?.[0]?.price?.id;
        const tier = TIER_BY_PRICE[priceId];
        if (!tier) {
          console.warn('[stripe-webhook] unknown price_id', priceId);
          return ok({ warning: 'unknown price' });
        }

        const orgId = await findOrgId({ userId, email });
        if (!orgId) {
          console.warn('[stripe-webhook] no org found for', { userId, email });
          return ok({ warning: 'no org' });
        }

        const updates = {
          plan: tier.plan,
          max_members: tier.max_members,
          feature_tier: tier.feature_tier,
        };
        if (customerId) updates.stripe_customer_id = customerId;
        await patchOrg(orgId, updates);
        console.log('[stripe-webhook] activated', { orgId, plan: tier.plan, customerId });
        return ok({ event: eventType, action: 'activate', orgId });
      }

      case 'customer.subscription.updated': {
        // Plan change, renewal, status change
        const status = obj.status;
        const priceId = obj.items?.data?.[0]?.price?.id;
        const customerId = obj.customer;

        // If subscription is no longer active, clear plan to revoke access.
        // Trial timestamp is preserved — auth.js separately allows access if
        // the original trial (if any) hasn't expired.
        if (status === 'canceled' || status === 'unpaid' || status === 'incomplete_expired') {
          const email = await fetchCustomerEmail(customerId);
          const orgId = await findOrgId({ email });
          if (orgId) {
            await patchOrg(orgId, { plan: null, feature_tier: 'essentials' });
            console.log('[stripe-webhook] expired', { orgId, status });
          }
          return ok({ event: eventType, action: 'expire' });
        }

        const tier = TIER_BY_PRICE[priceId];
        if (!tier) {
          console.warn('[stripe-webhook] unknown price_id on update', priceId);
          return ok({ warning: 'unknown price' });
        }

        const email = await fetchCustomerEmail(customerId);
        const orgId = await findOrgId({ email });
        if (!orgId) {
          console.warn('[stripe-webhook] no org for customer', customerId);
          return ok({ warning: 'no org' });
        }

        await patchOrg(orgId, { plan: tier.plan, max_members: tier.max_members, feature_tier: tier.feature_tier });
        console.log('[stripe-webhook] updated', { orgId, plan: tier.plan });
        return ok({ event: eventType, action: 'activate', orgId });
      }

      case 'customer.subscription.deleted': {
        // Subscription fully ended — clear plan to revoke access. Trial
        // timestamp is preserved (it might still be in the future, in which
        // case auth.js will keep access via the trial branch).
        const customerId = obj.customer;
        const email = await fetchCustomerEmail(customerId);
        const orgId = await findOrgId({ email });
        if (orgId) {
          await patchOrg(orgId, { plan: null });
          console.log('[stripe-webhook] deleted', { orgId });
        }
        return ok({ event: eventType, action: 'expire' });
      }

      case 'invoice.payment_succeeded': {
        // Recurring payment OK — no DB change needed (subscription.updated covers state)
        return ok({ event: eventType, action: 'noop' });
      }

      default:
        return ok({ ignored: eventType });
    }
  } catch (e) {
    console.error('[stripe-webhook] handler failed:', e.message);
    return { statusCode: 500, body: 'Handler failed' };
  }
};

function ok(body) {
  return {
    statusCode: 200,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ received: true, ...body }),
  };
}

// --- Stripe signature verification ---------------------------------------

function verifyStripeSignature(rawBody, header, secret) {
  // Stripe header format: t=<timestamp>,v1=<sig>[,v1=<sig>...]
  const parts = header.split(',').reduce((acc, kv) => {
    const [k, v] = kv.split('=');
    if (k === 't') acc.timestamp = v;
    if (k === 'v1') (acc.signatures = acc.signatures || []).push(v);
    return acc;
  }, {});

  if (!parts.timestamp || !parts.signatures?.length) return false;

  const signedPayload = `${parts.timestamp}.${rawBody}`;
  const expected = crypto.createHmac('sha256', secret).update(signedPayload).digest('hex');

  return parts.signatures.some((sig) => {
    if (sig.length !== expected.length) return false;
    try {
      return crypto.timingSafeEqual(Buffer.from(sig, 'utf8'), Buffer.from(expected, 'utf8'));
    } catch (e) {
      return false;
    }
  });
}

// --- Stripe API helpers --------------------------------------------------

async function fetchSubscription(subscriptionId) {
  const res = await fetch(`https://api.stripe.com/v1/subscriptions/${subscriptionId}`, {
    headers: { Authorization: `Bearer ${STRIPE_SECRET_KEY}` },
  });
  if (!res.ok) throw new Error(`Stripe sub fetch ${res.status}: ${await res.text()}`);
  return res.json();
}

async function fetchCustomerEmail(customerId) {
  if (!customerId) return null;
  const res = await fetch(`https://api.stripe.com/v1/customers/${customerId}`, {
    headers: { Authorization: `Bearer ${STRIPE_SECRET_KEY}` },
  });
  if (!res.ok) return null;
  const data = await res.json();
  return data?.email || null;
}

// --- Supabase helpers ----------------------------------------------------

async function findOrgId({ userId, email } = {}) {
  if (!SUPABASE_URL || !SUPABASE_KEY) {
    throw new Error('Supabase env vars not set');
  }

  let resolvedUserId = userId;
  if (!resolvedUserId && email) {
    resolvedUserId = await lookupUserIdByEmail(email);
  }
  if (!resolvedUserId) return null;

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
