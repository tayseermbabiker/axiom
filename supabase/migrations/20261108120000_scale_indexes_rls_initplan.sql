-- Scale hardening (Nov 2026) — Supabase performance advisor.
--
-- 1. Indexes on the two largest-growing lookup paths (TB lines by version,
--    TB versions by engagement). Without them the Working TB / FS agreement
--    loads scan the whole table once there are millions of TB lines.
-- 2. auth.uid() / auth.email() wrapped in (select ...) so Postgres evaluates
--    them once per query instead of once per row. Same logic, same access.
--    ALTER POLICY keeps each policy's command and roles unchanged.

create index if not exists idx_tbl_tb_version_id on public.trial_balance_lines(tb_version_id);
create index if not exists idx_tb_versions_engagement_id on public.tb_versions(engagement_id);

alter policy "View org invites" on public.organization_invites
  using (is_org_admin(organization_id) or lower(email) = lower((select auth.email())));

alter policy "Update invite status" on public.organization_invites
  using (is_org_admin(organization_id) or lower(email) = lower((select auth.email())));

alter policy admins_can_delete_invites on public.organization_invites
  using (exists (
    select 1 from public.organization_members om
    where om.organization_id = organization_invites.organization_id
      and om.user_id = (select auth.uid())
      and om.role = 'admin'
  ));

alter policy "Admin add members" on public.organization_members
  with check (is_org_admin(organization_id) or user_id = (select auth.uid()));

alter policy "Create org" on public.organizations
  with check ((select auth.uid()) = created_by);

alter policy "View own orgs" on public.organizations
  using (id in (select user_org_ids()) or created_by = (select auth.uid()));

alter policy "Update own profile" on public.profiles
  using ((select auth.uid()) = id);

alter policy "View org members profiles" on public.profiles
  using (
    id = (select auth.uid())
    or id in (
      select organization_members.user_id from public.organization_members
      where organization_members.organization_id in (select user_org_ids())
    )
  );
