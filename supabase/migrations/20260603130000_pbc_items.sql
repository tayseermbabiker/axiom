-- Prepared-By-Client (PBC) request tracker. Best-practice / practice-management tool that
-- operationalises ISA 300 (planning the info needed), ISA 500 (information produced by the entity —
-- IPTE) and ISA 230 (documentation). Created/seeded at planning, tracked through execution.
-- Separate from external confirmations (ISA 505). MENA-agnostic. Team-editable (RLS = org membership,
-- like findings/confirmations); Pro-gated in the UI.

create table if not exists public.engagement_pbc_items (
  id              uuid primary key default gen_random_uuid(),
  engagement_id   uuid not null references public.engagements(id) on delete cascade,
  organization_id uuid not null references public.organizations(id) on delete cascade,

  description     text not null,
  audit_area      text,
  section_id      uuid references public.audit_sections(id) on delete set null,

  requested_from  text,           -- client contact / role
  responsible     text,           -- audit team member who owns the chase

  requested_date  date,
  due_date        date,
  received_date   date,

  status          text not null default 'outstanding'
                    check (status in ('outstanding','requested','received','under_review','accepted','waived')),
  priority        text check (priority is null or priority in ('high','medium','low')),

  evidence_url    text,           -- Drive / OneDrive link to the received document
  ipte_checked    boolean not null default false,  -- ISA 500: accuracy & completeness of IPTE considered
  notes           text,

  sort_order      int not null default 0,
  created_by      uuid references public.profiles(id),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists idx_pbc_engagement on public.engagement_pbc_items(engagement_id);
create index if not exists idx_pbc_org        on public.engagement_pbc_items(organization_id);

alter table public.engagement_pbc_items enable row level security;

create policy pbc_select on public.engagement_pbc_items for select
  using (organization_id in (select public.get_user_org_ids()));
create policy pbc_insert on public.engagement_pbc_items for insert
  with check (organization_id in (select public.get_user_org_ids()));
create policy pbc_update on public.engagement_pbc_items for update
  using (organization_id in (select public.get_user_org_ids()));
create policy pbc_delete on public.engagement_pbc_items for delete
  using (organization_id in (select public.get_user_org_ids()));

grant select, insert, update, delete on public.engagement_pbc_items to authenticated;

drop trigger if exists trg_pbc_set_updated_at on public.engagement_pbc_items;
create trigger trg_pbc_set_updated_at
  before update on public.engagement_pbc_items
  for each row execute function public.set_updated_at_now();
