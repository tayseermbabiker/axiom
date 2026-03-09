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
// Roles hierarchy: admin > reviewer > preparer
const PERMISSIONS = {
  // Engagements
  create_engagement:    ['admin'],
  edit_shared_folder:   ['admin', 'reviewer'],
  upload_tb:            ['admin', 'reviewer'],
  replace_tb:           ['admin', 'reviewer'],

  // Sections
  create_section:       ['admin', 'reviewer'],
  delete_section:       ['admin'],
  edit_section_tags:    ['admin', 'reviewer'],

  // Procedures
  add_procedure:        ['admin', 'reviewer'],
  respond_procedure:    ['admin', 'reviewer', 'preparer'],
  toggle_procedure:     ['admin', 'reviewer', 'preparer'],

  // Findings
  add_finding:          ['admin', 'reviewer', 'preparer'],
  edit_finding:         ['admin', 'reviewer'],

  // Documents
  add_document:         ['admin', 'reviewer', 'preparer'],

  // Review
  add_review_comment:   ['admin', 'reviewer'],
  add_preparer_response:['admin', 'preparer'],
  submit_for_review:    ['admin', 'reviewer', 'preparer'],
  approve_section:      ['admin', 'reviewer'],
  return_to_preparer:   ['admin', 'reviewer'],

  // Conclusion
  save_conclusion:      ['admin', 'reviewer'],

  // Team (handled separately in team.html already)
  manage_team:          ['admin']
};

function can(action) {
  const allowed = PERMISSIONS[action];
  if (!allowed) return false;
  return allowed.includes(currentRole);
}

// Sign out
async function signOut() {
  await supabaseClient.auth.signOut();
  window.location.href = '/pages/login.html';
}
