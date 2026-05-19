// Org has access if it has an active subscription plan OR an unexpired trial.
// The two grant mechanisms are independent — either one alone is sufficient.
function hasActiveAccess(org) {
  if (org.plan) return true;
  if (org.trial_expires_at && new Date() < new Date(org.trial_expires_at)) return true;
  return false;
}

// Check if user is logged in, redirect to login if not
// Also checks for org membership — redirects to onboarding if no org
async function requireAuth() {
  const { data: { session } } = await supabaseClient.auth.getSession();
  if (!session) {
    window.location.href = '/pages/login.html';
    return null;
  }

  // Check if user has an organization (skip check on onboarding page)
  const isOnboarding = window.location.pathname.includes('onboarding.html');
  if (!isOnboarding) {
    const org = await getUserOrg();
    if (!org) {
      window.location.href = '/pages/onboarding.html';
      return null;
    }

    // Access check — granted if either an active subscription (org.plan) or
    // an unexpired trial. Both signals are independent and either one alone
    // is sufficient.
    if (!hasActiveAccess(org)) {
      document.body.innerHTML = '<div style="font-family:Inter,sans-serif;max-width:480px;margin:100px auto;text-align:center;padding:40px;"><h2 style="margin-bottom:12px;">Access Inactive</h2><p style="color:#6B7280;margin-bottom:24px;">Your subscription or trial has ended. Subscribe to continue using Audexon.</p><a href="/index.html#pricing" style="display:inline-block;background:#3A7BFF;color:white;padding:12px 24px;border-radius:8px;text-decoration:none;font-weight:600;margin-bottom:16px;">View pricing</a><br><a href="mailto:support@audexon.com" style="color:#6B7280;font-size:14px;">support@audexon.com</a></div>';
      return null;
    }
  }

  return session.user;
}

// Get current user
async function getCurrentUser() {
  const { data: { session } } = await supabaseClient.auth.getSession();
  return session?.user || null;
}

// Get user profile from profiles table
async function getUserProfile() {
  const user = await getCurrentUser();
  if (!user) return null;
  const { data } = await supabaseClient
    .from('profiles')
    .select('*')
    .eq('id', user.id)
    .single();
  return data;
}

// Get user's organization (via organization_members join)
async function getUserOrg() {
  const user = await getCurrentUser();
  if (!user) return null;

  const { data, error } = await supabaseClient
    .from('organization_members')
    .select('role, organizations(*)')
    .eq('user_id', user.id)
    .limit(1)
    .single();

  if (error || !data) return null;
  return data.organizations;
}

// Get user's role in their organization
async function getUserRole() {
  const user = await getCurrentUser();
  if (!user) return null;

  const { data, error } = await supabaseClient
    .from('organization_members')
    .select('role')
    .eq('user_id', user.id)
    .limit(1)
    .single();

  if (error || !data) return null;
  return data.role;
}

// Get org + role together (single query, avoids duplicate calls)
async function getUserOrgAndRole() {
  const user = await getCurrentUser();
  if (!user) return { org: null, role: null };

  const { data, error } = await supabaseClient
    .from('organization_members')
    .select('role, organizations(*)')
    .eq('user_id', user.id)
    .limit(1)
    .single();

  if (error || !data) return { org: null, role: null };
  return { org: data.organizations, role: data.role };
}

// ---- Role-based permission helpers ----
// Roles hierarchy: admin (partner) > supervisor > preparer
const PERMISSIONS = {
  // Engagements
  create_engagement:        ['admin'],
  edit_shared_folder:       ['admin', 'supervisor'],
  upload_tb:                ['admin', 'supervisor'],
  replace_tb:               ['admin', 'supervisor'],

  // Sections
  create_section:           ['admin', 'supervisor'],
  delete_section:           ['admin'],
  edit_section_tags:        ['admin', 'supervisor'],
  reassign_section:         ['admin', 'supervisor'],

  // Procedures
  add_procedure:            ['admin', 'supervisor'],
  respond_procedure:        ['admin', 'supervisor', 'preparer'],
  toggle_procedure:         ['admin', 'supervisor', 'preparer'],

  // Findings
  add_finding:              ['admin', 'supervisor', 'preparer'],
  edit_finding:             ['admin', 'supervisor'],

  // Documents
  add_document:             ['admin', 'supervisor', 'preparer'],

  // Review — three-level sign-off
  add_review_comment:       ['admin', 'supervisor'],
  add_preparer_response:    ['admin', 'supervisor', 'preparer'],
  submit_for_review:        ['preparer'],
  supervisor_approve:       ['admin', 'supervisor'],
  supervisor_return:        ['admin', 'supervisor'],
  partner_approve:          ['admin'],
  partner_return:           ['admin'],
  reopen_section:           ['admin'],

  // Conclusion
  save_conclusion:          ['admin', 'supervisor', 'preparer'],

  // Team
  manage_team:              ['admin']
};

function can(action) {
  const allowed = PERMISSIONS[action];
  if (!allowed) return false;
  return allowed.includes(currentRole);
}

// Sign out — return to the public homepage so visitors see the marketing site
async function signOut() {
  await supabaseClient.auth.signOut();
  window.location.href = '/';
}
