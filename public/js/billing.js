// Audexon billing — Lemon Squeezy checkout redirect
//
// Each tier has its own LS product/variant with a hosted checkout URL.
// Fill in the URLs below after creating the products in the Lemon Squeezy dashboard.
//
//   Dashboard → Products → New product (one per tier) → copy the "buy link" / share URL
//   Format: https://audexon.lemonsqueezy.com/buy/<uuid>
//
// We pass:
//   - checkout[email]            → prefills email if user is signed in
//   - checkout[custom][user_id]  → so the webhook can map payment → Supabase org
//   - checkout[success_url]      → returns user to Audexon after payment

const LEMON_CHECKOUT = {
  starter: 'https://audexon.lemonsqueezy.com/buy/REPLACE-WITH-STARTER-UUID',
  team:    'https://audexon.lemonsqueezy.com/buy/REPLACE-WITH-TEAM-UUID',
  firm:    'https://audexon.lemonsqueezy.com/buy/REPLACE-WITH-FIRM-UUID',
};

async function audexonCheckout(tier) {
  const baseUrl = LEMON_CHECKOUT[tier];
  if (!baseUrl || baseUrl.includes('REPLACE-WITH')) {
    alert('Checkout is not configured yet. Please contact support@audexon.com to subscribe.');
    return;
  }

  let user = null;
  try {
    if (typeof supabaseClient !== 'undefined') {
      const { data: { session } } = await supabaseClient.auth.getSession();
      user = session?.user || null;
    }
  } catch (e) {
    // Supabase not loaded or session check failed — proceed as guest
  }

  // Not signed in → send them to login first; they'll subscribe after creating an org
  if (!user) {
    sessionStorage.setItem('audexon_pending_tier', tier);
    window.location.href = '/pages/login.html';
    return;
  }

  const params = new URLSearchParams();
  params.set('checkout[email]', user.email || '');
  params.set('checkout[custom][user_id]', user.id || '');
  params.set('checkout[success_url]', `${window.location.origin}/pages/dashboard.html?subscribed=${tier}`);

  window.location.href = `${baseUrl}?${params.toString()}`;
}
