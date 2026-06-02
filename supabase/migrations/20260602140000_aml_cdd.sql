-- AML / KYC / Client Due Diligence (reviewer #1). Audit firms are DNFBPs; CDD + beneficial-ownership
-- + screening + AML risk rating are performed at client acceptance/continuance (permanent file) before
-- engagement acceptance. MENA-AGNOSTIC: no country-specific portal (e.g. goAML) or retention years —
-- reporting/retention referenced generically ("the relevant national authority/FIU per local law").
-- One CDD record per engagement (refreshed in place) + a beneficial-owners child list.
-- RLS mirrors engagement_acceptance: org-member SELECT; admin + Pro-tier for writes.

create table if not exists public.engagement_aml_cdd (
  id                              uuid primary key default gen_random_uuid(),
  engagement_id                   uuid not null references public.engagements(id) on delete cascade,
  organization_id                 uuid not null references public.organizations(id) on delete cascade,

  status                          text not null default 'draft' check (status in ('draft','confirmed')),
  cdd_date                        date,

  -- Client identification (CDD)
  client_legal_name               text,
  legal_form                      text,
  registration_number             text,
  registered_address              text,
  country                         text,
  business_activity               text,

  -- Beneficial ownership / control
  ownership_structure_understood  boolean not null default false,
  ownership_notes                 text,

  -- Screening (sanctions / PEP / adverse media)
  screening_performed             boolean not null default false,
  screening_date                  date,
  screening_source                text,
  screening_results               text,

  -- PEP
  pep_involved                    boolean not null default false,
  pep_notes                       text,

  -- Source of funds / wealth
  source_of_funds_notes           text,

  -- AML risk rating + CDD level (drives simplified vs enhanced due diligence)
  risk_rating                     text check (risk_rating is null or risk_rating in ('low','medium','high')),
  risk_rationale                  text,
  cdd_level                       text check (cdd_level is null or cdd_level in ('simplified','standard','enhanced')),

  -- Suspicious activity (reporting obligation — generic, MENA-agnostic)
  suspicious_activity_flag        boolean not null default false,
  suspicious_activity_notes       text,

  -- Conclusion
  conclusion                      text check (conclusion is null or conclusion in ('accept','accept_edd','decline')),
  conclusion_notes                text,

  -- Attestation (partner / MLRO)
  attestation_made                boolean not null default false,
  attestation_by                  uuid references public.profiles(id),
  attestation_date                date,

  created_by                      uuid references public.profiles(id),
  created_at                      timestamptz not null default now(),
  updated_at                      timestamptz not null default now(),

  check (status <> 'confirmed' or (attestation_made = true and attestation_date is not null))
);

create unique index if not exists idx_aml_one_per_engagement on public.engagement_aml_cdd(engagement_id);
create index if not exists idx_aml_org on public.engagement_aml_cdd(organization_id);

alter table public.engagement_aml_cdd enable row level security;

create policy aml_select on public.engagement_aml_cdd for select
  using (organization_id in (select public.get_user_org_ids()));
create policy aml_insert on public.engagement_aml_cdd for insert
  with check (organization_id in (select public.get_user_org_ids())
              and public.user_has_role_in_org(organization_id, 'admin')
              and public.org_has_pro_tier(organization_id));
create policy aml_update on public.engagement_aml_cdd for update
  using (organization_id in (select public.get_user_org_ids())
         and public.user_has_role_in_org(organization_id, 'admin')
         and public.org_has_pro_tier(organization_id));

grant select, insert, update, delete on public.engagement_aml_cdd to authenticated;

drop trigger if exists trg_aml_set_updated_at on public.engagement_aml_cdd;
create trigger trg_aml_set_updated_at
  before update on public.engagement_aml_cdd
  for each row execute function public.set_updated_at_now();

create table if not exists public.engagement_aml_beneficial_owners (
  id              uuid primary key default gen_random_uuid(),
  aml_cdd_id      uuid not null references public.engagement_aml_cdd(id) on delete cascade,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  full_name       text,
  ownership_pct   numeric,
  nationality     text,
  is_pep          boolean not null default false,
  notes           text,
  sort_order      int not null default 0,
  created_at      timestamptz not null default now()
);

create index if not exists idx_aml_bo_parent on public.engagement_aml_beneficial_owners(aml_cdd_id);
create index if not exists idx_aml_bo_org on public.engagement_aml_beneficial_owners(organization_id);

alter table public.engagement_aml_beneficial_owners enable row level security;

create policy aml_bo_select on public.engagement_aml_beneficial_owners for select
  using (organization_id in (select public.get_user_org_ids()));
create policy aml_bo_insert on public.engagement_aml_beneficial_owners for insert
  with check (organization_id in (select public.get_user_org_ids())
              and public.user_has_role_in_org(organization_id, 'admin')
              and public.org_has_pro_tier(organization_id));
create policy aml_bo_update on public.engagement_aml_beneficial_owners for update
  using (organization_id in (select public.get_user_org_ids())
         and public.user_has_role_in_org(organization_id, 'admin')
         and public.org_has_pro_tier(organization_id));
create policy aml_bo_delete on public.engagement_aml_beneficial_owners for delete
  using (organization_id in (select public.get_user_org_ids())
         and public.user_has_role_in_org(organization_id, 'admin')
         and public.org_has_pro_tier(organization_id));

grant select, insert, update, delete on public.engagement_aml_beneficial_owners to authenticated;
