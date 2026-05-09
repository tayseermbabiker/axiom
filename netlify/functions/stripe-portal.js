// Audexon — Stripe Customer Portal session creator
//
// Returns a one-time URL to Stripe's hosted customer portal where the
// signed-in admin can self-serve cancel, change plan, update payment
// method, and download invoices.
//
// Auth flow:
//   1. Frontend POSTs with the Supabase access token in the Authorization
//      header.
//   2. We verify the token by calling Supabase /auth/v1/user.
//   3. We look up the user's admin org and grab stripe_customer_id.
//   4. If the column isn't set yet, fall back to looking up the customer
//      in Stripe by email (covers subscriptions created before the column
//      existed).
//   5. We call Stripe to create a portal session and return the URL.
//
// Required Netlify env vars (already set):
//   STRIPE_SECRET_KEY
//   SUPABASE_URL
//   SUPABASE_SERVICE_ROLE_KEY

const STRIPE_SECRET_KEY = process.env.STRIPE_SECRET_KEY;
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

exports.handler = async (event) => {
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Method not allowed' };
  }

  const authHeader = event.headers.authorization || event.headers.Authorization || '';
  const token = authHeader.replace(/^Bearer\s+/i, '');
  if (!token) {
    return { statusCode: 401, body: JSON.stringify({ error: 'Missing auth token' }) };
  }

  try {
    const user = await verifySupabaseUser(token);
    if (!user) {
      return { statusCode: 401, body: JSON.stringify({ error: 'Invalid token' }) };
    }

    const org = await findAdminOrg(user.id);
    if (!org) {
      return { statusCode: 403, body: JSON.stringify({ error: 'No admin org found' }) };
    }

    let customerId = org.stripe_customer_id;
    if (!customerId) {
      customerId = await findStripeCustomerByEmail(user.email);
      if (customerId) {
        await saveCustomerIdOnOrg(org.id, customerId);
      }
    }
    if (!customerId) {
      return { statusCode: 404, body: JSON.stringify({ error: 'No Stripe customer on file. Contact support@audexon.com.' }) };
    }

    const returnUrl = (event.headers.origin || 'https://audexon.com') + '/pages/dashboard.html';
    const session = await createPortalSession(customerId, returnUrl);

    return {
      statusCode: 200,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ url: session.url }),
    };
  } catch (e) {
    console.error('[stripe-portal] failed:', e.message);
    return { statusCode: 500, body: JSON.stringify({ error: 'Failed to create portal session' }) };
  }
};

// --- Supabase ------------------------------------------------------------

async function verifySupabaseUser(accessToken) {
  const res = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
    headers: {
      apikey: SUPABASE_KEY,
      Authorization: `Bearer ${accessToken}`,
    },
  });
  if (!res.ok) return null;
  return res.json();
}

async function findAdminOrg(userId) {
  const url = `${SUPABASE_URL}/rest/v1/organization_members?select=organization_id,role,organizations(id,stripe_customer_id)&user_id=eq.${encodeURIComponent(userId)}&role=eq.admin&limit=1`;
  const res = await fetch(url, {
    headers: {
      apikey: SUPABASE_KEY,
      Authorization: `Bearer ${SUPABASE_KEY}`,
    },
  });
  if (!res.ok) throw new Error(`Supabase ${res.status}: ${await res.text()}`);
  const rows = await res.json();
  const row = rows?.[0];
  if (!row?.organizations) return null;
  return {
    id: row.organizations.id,
    stripe_customer_id: row.organizations.stripe_customer_id,
  };
}

async function saveCustomerIdOnOrg(orgId, customerId) {
  const url = `${SUPABASE_URL}/rest/v1/organizations?id=eq.${encodeURIComponent(orgId)}`;
  await fetch(url, {
    method: 'PATCH',
    headers: {
      apikey: SUPABASE_KEY,
      Authorization: `Bearer ${SUPABASE_KEY}`,
      'Content-Type': 'application/json',
      Prefer: 'return=minimal',
    },
    body: JSON.stringify({ stripe_customer_id: customerId }),
  });
}

// --- Stripe --------------------------------------------------------------

async function findStripeCustomerByEmail(email) {
  if (!email) return null;
  const url = `https://api.stripe.com/v1/customers?email=${encodeURIComponent(email)}&limit=1`;
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${STRIPE_SECRET_KEY}` },
  });
  if (!res.ok) return null;
  const data = await res.json();
  return data?.data?.[0]?.id || null;
}

async function createPortalSession(customerId, returnUrl) {
  const body = new URLSearchParams();
  body.set('customer', customerId);
  body.set('return_url', returnUrl);

  const res = await fetch('https://api.stripe.com/v1/billing_portal/sessions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${STRIPE_SECRET_KEY}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: body.toString(),
  });
  if (!res.ok) throw new Error(`Stripe portal session ${res.status}: ${await res.text()}`);
  return res.json();
}
