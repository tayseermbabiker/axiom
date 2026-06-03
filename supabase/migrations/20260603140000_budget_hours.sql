-- Per-team-member budgeted hours (reviewer #5b). ISA 300 mandates allocating work to the team;
-- this hours-per-member (and optional rate) breakdown supports costing. Engagement-level child;
-- total reconciles to the lump-sum budgeted_hours on engagement_audit_strategies. RLS mirrors the
-- audit-strategy workpaper (admin + Pro). MENA-agnostic (no currency assumed).

create table if not exists public.engagement_budget_hours (
  id              uuid primary key default gen_random_uuid(),
  engagement_id   uuid not null references public.engagements(id) on delete cascade,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  member_name     text,
  grade           text check (grade is null or grade in ('partner','manager','senior','junior','other')),
  budgeted_hours  numeric,
  hourly_rate     numeric,
  sort_order      int not null default 0,
  created_at      timestamptz not null default now()
);

create index if not exists idx_budget_hours_engagement on public.engagement_budget_hours(engagement_id);
create index if not exists idx_budget_hours_org        on public.engagement_budget_hours(organization_id);

alter table public.engagement_budget_hours enable row level security;

create policy bh_select on public.engagement_budget_hours for select
  using (organization_id in (select public.get_user_org_ids()));
create policy bh_insert on public.engagement_budget_hours for insert
  with check (organization_id in (select public.get_user_org_ids())
              and public.user_has_role_in_org(organization_id, 'admin')
              and public.org_has_pro_tier(organization_id));
create policy bh_update on public.engagement_budget_hours for update
  using (organization_id in (select public.get_user_org_ids())
         and public.user_has_role_in_org(organization_id, 'admin')
         and public.org_has_pro_tier(organization_id));
create policy bh_delete on public.engagement_budget_hours for delete
  using (organization_id in (select public.get_user_org_ids())
         and public.user_has_role_in_org(organization_id, 'admin')
         and public.org_has_pro_tier(organization_id));

grant select, insert, update, delete on public.engagement_budget_hours to authenticated;
