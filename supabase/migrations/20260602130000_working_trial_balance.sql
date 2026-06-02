-- Working / Adjusted Trial Balance (reviewer #7, P1) — ISA 450 + ISA 230.
-- Central engine: double-entry journals stored centrally; adjusted TB = base + posted corrected journals.
-- Section views are filtered views of the central TB. adjusting_entries (0 rows) is superseded by
-- journal_entries + journal_lines (header + legs). RLS mirrors the team-editable base-table pattern
-- (org members via engagement chain) so PREPARERS can create journals — NOT admin-gated like the
-- independence workpaper. Pro-tier is gated in the UI, consistent with other Pro features.

-- 1. Base TB: lockable + richer line metadata (reliable section bridge + account type for SUM)
alter table public.tb_versions
  add column if not exists is_locked boolean not null default false;

alter table public.trial_balance_lines
  add column if not exists account_type text
    check (account_type is null or account_type in ('asset','liability','equity','income','expense')),
  add column if not exists section_id uuid references public.audit_sections(id) on delete set null;

create index if not exists idx_tbl_section_id on public.trial_balance_lines(section_id);

-- 2. journal_entries (header — one misstatement record)
create table if not exists public.journal_entries (
  id                       uuid primary key default gen_random_uuid(),
  engagement_id            uuid not null references public.engagements(id) on delete cascade,
  organization_id          uuid not null references public.organizations(id) on delete cascade,
  tb_version_id            uuid references public.tb_versions(id) on delete set null,

  description              text,
  source_section_id        uuid references public.audit_sections(id) on delete set null,
  linked_finding_id        uuid references public.findings(id) on delete set null,

  impact_type              text not null
                             check (impact_type in ('adjustment','reclassification')),
  misstatement_type        text
                             check (misstatement_type is null
                                    or misstatement_type in ('factual','judgmental','projected')),
  isa450_status            text not null default 'proposed'
                             check (isa450_status in ('proposed','corrected','uncorrected','trivial_excluded')),
  management_response      text,
  is_posted_to_adjusted_tb boolean not null default false,

  -- ISA 230 audit trail
  status                   text not null default 'draft'
                             check (status in ('draft','reviewed','final')),
  prepared_by              uuid references public.profiles(id),
  prepared_at              timestamptz default now(),
  reviewed_by              uuid references public.profiles(id),
  reviewed_at              timestamptz,
  reason_for_change        text,

  created_by               uuid references public.profiles(id),
  created_at               timestamptz not null default now(),
  updated_at               timestamptz not null default now()
);

create index if not exists idx_je_engagement  on public.journal_entries(engagement_id);
create index if not exists idx_je_organization on public.journal_entries(organization_id);
create index if not exists idx_je_tb_version   on public.journal_entries(tb_version_id);
create index if not exists idx_je_finding      on public.journal_entries(linked_finding_id);

alter table public.journal_entries enable row level security;

create policy je_select on public.journal_entries for select
  using (organization_id in (select public.get_user_org_ids()));
create policy je_insert on public.journal_entries for insert
  with check (organization_id in (select public.get_user_org_ids()));
create policy je_update on public.journal_entries for update
  using (organization_id in (select public.get_user_org_ids()));
create policy je_delete on public.journal_entries for delete
  using (organization_id in (select public.get_user_org_ids()));

grant select, insert, update, delete on public.journal_entries to authenticated;

drop trigger if exists trg_je_set_updated_at on public.journal_entries;
create trigger trg_je_set_updated_at
  before update on public.journal_entries
  for each row execute function public.set_updated_at_now();

-- 3. journal_lines (legs — the double entry)
create table if not exists public.journal_lines (
  id                    uuid primary key default gen_random_uuid(),
  journal_entry_id      uuid not null references public.journal_entries(id) on delete cascade,
  organization_id       uuid not null references public.organizations(id) on delete cascade,

  trial_balance_line_id uuid references public.trial_balance_lines(id) on delete set null,
  account_code          text,
  account_name          text,
  account_section_id    uuid references public.audit_sections(id) on delete set null,

  debit                 numeric not null default 0,
  credit                numeric not null default 0,
  is_pl_affecting       boolean,
  sort_order            int not null default 0,

  created_at            timestamptz not null default now(),

  check (debit >= 0 and credit >= 0),
  check (not (debit > 0 and credit > 0))   -- each leg is either a debit or a credit, not both
);

create index if not exists idx_jl_entry       on public.journal_lines(journal_entry_id);
create index if not exists idx_jl_tbline       on public.journal_lines(trial_balance_line_id);
create index if not exists idx_jl_organization on public.journal_lines(organization_id);

alter table public.journal_lines enable row level security;

create policy jl_select on public.journal_lines for select
  using (organization_id in (select public.get_user_org_ids()));
create policy jl_insert on public.journal_lines for insert
  with check (organization_id in (select public.get_user_org_ids()));
create policy jl_update on public.journal_lines for update
  using (organization_id in (select public.get_user_org_ids()));
create policy jl_delete on public.journal_lines for delete
  using (organization_id in (select public.get_user_org_ids()));

grant select, insert, update, delete on public.journal_lines to authenticated;
