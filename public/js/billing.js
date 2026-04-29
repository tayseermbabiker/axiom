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

// Kill switch: while Lemon Squeezy is in mandatory test mode (store approval
// pending), Subscribe buttons route to /contact.html for manual onboarding
// instead of sending real customers into a test-mode checkout that won't
// accept real cards. Flip to true once LS approves the Audexon store and
// the buy links below point to live-mode products.
const LEMON_LIVE = false;

const LEMON_CHECKOUT = {
  starter: 'https://audexon.lemonsqueezy.com/checkout/buy/1f3b11f7-cb8c-4336-a36f-036902bbf652',
  team:    'https://audexon.lemonsqueezy.com/checkout/buy/ee81faf1-55a4-4a91-bd07-791c81e50bd6',
  firm:    'https://audexon.lemonsqueezy.com/checkout/buy/5b05c366-6fce-4928-9059-a3ae7a0d11f3',
};

async function audexonCheckout(tier) {
  if (!LEMON_LIVE) {
    sessionStorage.setItem('audexon_pending_tier', tier);
    window.location.href = '/contact.html';
    return;
  }

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
