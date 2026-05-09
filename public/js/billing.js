// Audexon billing — Stripe Payment Link redirect
//
// Each tier has its own Stripe product/price with a hosted Payment Link.
// Fill in the URLs below after creating the Payment Links in the Stripe dashboard.
//
//   Dashboard → Payment Links → New → select product → copy URL
//   Format: https://buy.stripe.com/<id>
//
// We pass:
//   - prefilled_email      → prefills email if user is signed in
//   - client_reference_id  → Supabase user_id, used by webhook to map to org

const STRIPE_LIVE = true;

const STRIPE_CHECKOUT = {
  starter: 'https://buy.stripe.com/5kQ5kCcgn25k1628yt83C00',
  team:    'https://buy.stripe.com/7sY8wO5RZ4ds2a6dSN83C01',
  firm:    'https://buy.stripe.com/bJe28q94b6lAcOK01X83C02',
};

async function audexonCheckout(tier) {
  if (!STRIPE_LIVE) {
    sessionStorage.setItem('audexon_pending_tier', tier);
    window.location.href = '/contact.html';
    return;
  }

  const baseUrl = STRIPE_CHECKOUT[tier];
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
  params.set('prefilled_email', user.email || '');
  params.set('client_reference_id', user.id || '');

  window.location.href = `${baseUrl}?${params.toString()}`;
}
