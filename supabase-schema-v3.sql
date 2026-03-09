-- ============================================================
-- AXIOM v0.3 — Complete Schema (Fresh Install)
-- Sections, Procedures, Responses, Findings
-- Relay model: zero file storage, links only
-- Run this in Supabase SQL Editor
-- ============================================================
-- WARNING: This drops ALL existing tables and data.

BEGIN;

-- ============================================================
-- CLEANUP: Drop everything from previous versions
-- CASCADE removes all policies, triggers, indexes automatically
-- ============================================================

-- Drop trigger on auth.users first (not cascade-able from table drops)
drop trigger if exists on_auth_user_created on auth.users;

-- Drop all functions
drop function if exists handle_new_user() cascade;
drop function if exists protect_approved_at() cascade;
drop function if exists block_review_note_changes() cascade;
drop function if exists block_activity_log_changes() cascade;
drop function if exists auto_update_timestamp() cascade;
drop function if exists user_org_ids() cascade;
drop function if exists is_org_admin() cascade;

-- Drop storage policies (storage.objects always exists)
do $$ begin
  drop policy if exists "Org members upload files" on storage.objects;
  drop policy if exists "Org members view files" on storage.objects;
  drop policy if exists "Org members delete files" on storage.objects;
  drop policy if exists "Users can upload audit files" on storage.objects;
  drop policy if exists "Users can view own audit files" on storage.objects;
  drop policy if exists "Users can delete own audit files" on storage.objects;
  drop policy if exists "Org members can upload files" on storage.objects;
  drop policy if exists "Org members can read files" on storage.objects;
  drop policy if exists "Org members can delete files" on storage.objects;
end $$;

-- Drop all tables (CASCADE removes their policies, triggers, indexes)
drop table if exists activity_log cascade;
drop table if exists review_notes cascade;
drop table if exists findings cascade;
drop table if exists documents cascade;
drop table if exists procedure_responses cascade;
drop table if exists audit_procedures cascade;
drop table if exists section_tb_lines cascade;
drop table if exists audit_sections cascade;
drop table if exists trial_balance_lines cascade;
drop table if exists workpapers cascade;
drop table if exists engagements cascade;
drop table if exists organization_invites cascade;
drop table if exists organization_members cascade;
drop table if exists organizations cascade;
drop table if exists profiles cascade;


-- ============================================================
-- 1. PROFILES (extends Supabase auth.users)
-- ============================================================
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text not null default '',
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'full_name', ''));
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Backfill profiles from existing auth.users (if any)
insert into profiles (id, email, full_name)
select id, email, coalesce(raw_user_meta_data->>'full_name', '')
from auth.users
where id not in (select id from profiles)
on conflict (id) do nothing;


-- ============================================================
-- 2. ORGANIZATIONS
-- ============================================================
create table organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  plan text not null default 'starter' check (plan in ('starter', 'team', 'firm')),
  max_members int not null default 5,
  created_by uuid not null references profiles(id),
  created_at timestamptz not null default now()
);
-- starter: 5 members, $99/mo
-- team: 12 members, $149/mo
-- firm: 25 members, $299/mo


-- ============================================================
-- 3. ORGANIZATION MEMBERS
-- ============================================================
create table organization_members (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  role text not null default 'preparer' check (role in ('admin', 'reviewer', 'preparer')),
  created_at timestamptz not null default now(),
  unique(organization_id, user_id)
);


-- ============================================================
-- 4. ORGANIZATION INVITES
-- ============================================================
create table organization_invites (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  email text not null,
  role text not null default 'preparer' check (role in ('admin', 'reviewer', 'preparer')),
  invited_by uuid not null references profiles(id),
  status text not null default 'pending' check (status in ('pending', 'accepted', 'expired')),
  created_at timestamptz not null default now(),
  unique(organization_id, email)
);


-- ============================================================
-- 5. ENGAGEMENTS
-- ============================================================
create table engagements (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  client_name text not null,
  year_end_date date not null,
  engagement_type text not null default 'audit' check (engagement_type in ('audit', 'review', 'compilation')),
  status text not null default 'active' check (status in ('active', 'archived')),
  shared_folder_url text,  -- Google Drive / OneDrive / SharePoint shared folder for all engagement documents
  created_by uuid not null references profiles(id),
  created_at timestamptz not null default now()
);


-- ============================================================
-- 6. TRIAL BALANCE LINES
-- ============================================================
create table trial_balance_lines (
  id uuid primary key default gen_random_uuid(),
  engagement_id uuid not null references engagements(id) on delete cascade,
  account_code text not null,
  account_name text not null,
  balance numeric not null default 0,
  classification text not null default 'unclassified',
  created_at timestamptz not null default now()
);


-- ============================================================
-- 7. AUDIT SECTIONS (replaces workpapers)
-- ============================================================
create table audit_sections (
  id uuid primary key default gen_random_uuid(),
  engagement_id uuid not null references engagements(id) on delete cascade,
  name text not null,
  assigned_to uuid references profiles(id),
  status text not null default 'not_started'
    check (status in ('not_started', 'in_progress', 'ready_for_review', 'returned', 'approved')),
  conclusion text default '',
  conclusion_by uuid references profiles(id),
  approved_by uuid references profiles(id),
  approved_at timestamptz,
  classification_tags text[] default '{}',  -- array of classification values this section covers (e.g. {'Fixed Assets', 'Depreciation'})
  assertions text[] default '{}',  -- e.g. {'Existence', 'Completeness', 'Accuracy', 'Rights & Obligations'}
  sort_order int default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);


-- ============================================================
-- 8. AUDIT PROCEDURES (admin-defined tests per section)
-- ============================================================
create table audit_procedures (
  id uuid primary key default gen_random_uuid(),
  section_id uuid not null references audit_sections(id) on delete cascade,
  description text not null,
  procedure_type text not null
    check (procedure_type in ('test_of_detail', 'analytical', 'controls', 'other')),
  assertions text[] default '{}',  -- assertions this procedure addresses (e.g. {'Existence', 'Accuracy'})
  sort_order int default 0,
  created_at timestamptz default now()
);


-- ============================================================
-- 10. PROCEDURE RESPONSES (preparer fills in)
-- ============================================================
create table procedure_responses (
  id uuid primary key default gen_random_uuid(),
  procedure_id uuid not null references audit_procedures(id) on delete cascade,
  user_id uuid not null references profiles(id),
  response text not null default '',
  status text not null default 'pending'
    check (status in ('pending', 'done')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);


-- ============================================================
-- 11. DOCUMENTS — Relay model (links only, zero file storage)
-- ============================================================
create table documents (
  id uuid primary key default gen_random_uuid(),
  section_id uuid references audit_sections(id) on delete cascade,
  procedure_response_id uuid references procedure_responses(id) on delete cascade,
  file_name text not null,
  file_url text not null,
  source_type text not null default 'other'
    check (source_type in ('google_drive', 'onedrive', 'sharepoint', 'dropbox', 'other')),
  file_type text not null default 'other'
    check (file_type in ('pdf', 'image', 'excel', 'word', 'other')),
  linked_by uuid not null references profiles(id),
  created_at timestamptz not null default now(),
  constraint documents_parent_check
    check (section_id is not null or procedure_response_id is not null)
);


-- ============================================================
-- 12. FINDINGS (issues discovered during testing)
-- ============================================================
create table findings (
  id uuid primary key default gen_random_uuid(),
  section_id uuid not null references audit_sections(id) on delete cascade,
  procedure_id uuid references audit_procedures(id),
  reported_by uuid not null references profiles(id),
  title text not null,
  condition text default '',
  criteria text default '',
  cause text default '',
  effect text default '',
  recommendation text default '',
  management_response text default '',
  severity text not null check (severity in ('high', 'medium', 'low')),
  status text not null default 'open' check (status in ('open', 'resolved', 'reported')),
  monetary_impact numeric,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);


-- ============================================================
-- 13. REVIEW NOTES (append-only, immutable — per section)
-- ============================================================
create table review_notes (
  id uuid primary key default gen_random_uuid(),
  section_id uuid not null references audit_sections(id) on delete cascade,
  user_id uuid not null references profiles(id),
  note text not null,
  note_type text not null
    check (note_type in ('review_comment', 'preparer_response', 'return_reason')),
  created_at timestamptz default now()
);


-- ============================================================
-- 14. ACTIVITY LOG (append-only, immutable)
-- ============================================================
create table activity_log (
  id uuid primary key default gen_random_uuid(),
  engagement_id uuid not null references engagements(id) on delete cascade,
  user_id uuid not null references profiles(id),
  action text not null,
  target_type text not null check (target_type in (
    'engagement', 'trial_balance', 'document', 'review_note',
    'organization', 'member', 'section', 'procedure', 'finding', 'response'
  )),
  target_id uuid not null,
  details jsonb default '{}',
  created_at timestamptz not null default now()
);


-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

-- Get user's org IDs (security definer to avoid RLS recursion)
create or replace function user_org_ids()
returns setof uuid as $$
  select organization_id from organization_members where user_id = auth.uid();
$$ language sql security definer stable set search_path = public;

-- Check if user is admin (avoids recursion in org_members policies)
create or replace function is_org_admin(org_id uuid)
returns boolean as $$
  select exists(
    select 1 from organization_members
    where organization_id = org_id
    and user_id = auth.uid()
    and role = 'admin'
  );
$$ language sql security definer stable set search_path = public;


-- ============================================================
-- TRIGGERS & FUNCTIONS
-- ============================================================

-- Protect approved_at immutability + auto-update timestamp
create or replace function protect_approved_at()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if old.approved_at is not null and (
    new.approved_at is null or new.approved_at is distinct from old.approved_at
  ) then
    raise exception 'approved_at is immutable once set';
  end if;
  new.updated_at := now();
  return new;
end;
$$;

create trigger protect_approved_at
  before update on audit_sections
  for each row execute function protect_approved_at();

-- Immutable review_notes
create or replace function block_review_note_changes()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  raise exception 'review_notes are immutable — updates and deletes are not allowed';
  return null;
end;
$$;

create trigger block_review_note_changes
  before update or delete on review_notes
  for each row execute function block_review_note_changes();

-- Immutable activity_log
create or replace function block_activity_log_changes()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  raise exception 'activity_log is immutable';
  return null;
end;
$$;

create trigger activity_log_no_update
  before update on activity_log
  for each row execute function block_activity_log_changes();

create trigger activity_log_no_delete
  before delete on activity_log
  for each row execute function block_activity_log_changes();

-- Auto-update timestamp helper
create or replace function auto_update_timestamp()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger auto_update_timestamp
  before update on procedure_responses
  for each row execute function auto_update_timestamp();

create trigger auto_update_finding_timestamp
  before update on findings
  for each row execute function auto_update_timestamp();


-- ============================================================
-- INDEXES
-- ============================================================
create index idx_org_members_org on organization_members(organization_id);
create index idx_org_members_user on organization_members(user_id);
create index idx_org_invites_org on organization_invites(organization_id);
create index idx_org_invites_email on organization_invites(email);
create index idx_engagements_org on engagements(organization_id);
create index idx_tb_lines_engagement on trial_balance_lines(engagement_id);
create index idx_audit_sections_engagement on audit_sections(engagement_id);
create index idx_tb_lines_classification on trial_balance_lines(classification);
create index idx_audit_procedures_section on audit_procedures(section_id);
create index idx_procedure_responses_procedure on procedure_responses(procedure_id);
create index idx_documents_section on documents(section_id);
create index idx_documents_response on documents(procedure_response_id);
create index idx_findings_section on findings(section_id);
create index idx_review_notes_section on review_notes(section_id);
create index idx_activity_log_engagement on activity_log(engagement_id);


-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table profiles enable row level security;
alter table organizations enable row level security;
alter table organization_members enable row level security;
alter table organization_invites enable row level security;
alter table engagements enable row level security;
alter table trial_balance_lines enable row level security;
alter table audit_sections enable row level security;
alter table audit_procedures enable row level security;
alter table procedure_responses enable row level security;
alter table documents enable row level security;
alter table findings enable row level security;
alter table review_notes enable row level security;
alter table activity_log enable row level security;

-- ---- Profiles ----
create policy "View org members profiles" on profiles for select
  using (id = auth.uid() or id in (
    select user_id from organization_members where organization_id in (select user_org_ids())
  ));
create policy "Update own profile" on profiles for update using (auth.uid() = id);
create policy "Insert profile via trigger" on profiles for insert with check (true);

-- ---- Organizations ----
create policy "View own orgs" on organizations for select
  using (id in (select user_org_ids()) or created_by = auth.uid());
create policy "Create org" on organizations for insert
  with check (auth.uid() = created_by);
create policy "Admin update org" on organizations for update
  using (is_org_admin(id));

-- ---- Organization Members ----
create policy "View org members" on organization_members for select
  using (organization_id in (select user_org_ids()));
create policy "Admin add members" on organization_members for insert
  with check (is_org_admin(organization_id) or user_id = auth.uid());
create policy "Admin remove members" on organization_members for delete
  using (is_org_admin(organization_id));
create policy "Admin update member roles" on organization_members for update
  using (is_org_admin(organization_id));

-- ---- Organization Invites ----
create policy "View org invites" on organization_invites for select
  using (
    is_org_admin(organization_id)
    or lower(email) = lower((select email from auth.users where id = auth.uid()))
  );
create policy "Admin create invites" on organization_invites for insert
  with check (is_org_admin(organization_id));
create policy "Update invite status" on organization_invites for update
  using (
    is_org_admin(organization_id)
    or lower(email) = lower((select email from auth.users where id = auth.uid()))
  );

-- ---- Engagements ----
create policy "View org engagements" on engagements for select
  using (organization_id in (select user_org_ids()));
create policy "Create engagements" on engagements for insert
  with check (organization_id in (select user_org_ids()));
create policy "Update org engagements" on engagements for update
  using (organization_id in (select user_org_ids()));
create policy "Delete org engagements" on engagements for delete
  using (is_org_admin(organization_id));

-- ---- Trial Balance Lines ----
create policy "View org TB lines" on trial_balance_lines for select
  using (engagement_id in (select id from engagements where organization_id in (select user_org_ids())));
create policy "Create TB lines" on trial_balance_lines for insert
  with check (engagement_id in (select id from engagements where organization_id in (select user_org_ids())));
create policy "Update TB lines" on trial_balance_lines for update
  using (engagement_id in (select id from engagements where organization_id in (select user_org_ids())));
create policy "Delete TB lines" on trial_balance_lines for delete
  using (engagement_id in (select id from engagements where organization_id in (select user_org_ids())));

-- ---- Audit Sections ----
create policy "Org members can read audit_sections" on audit_sections for select
  using (engagement_id in (select id from engagements where organization_id in (select user_org_ids())));
create policy "Org members can insert audit_sections" on audit_sections for insert
  with check (engagement_id in (select id from engagements where organization_id in (select user_org_ids())));
create policy "Org members can update audit_sections" on audit_sections for update
  using (engagement_id in (select id from engagements where organization_id in (select user_org_ids())));
create policy "Org members can delete audit_sections" on audit_sections for delete
  using (engagement_id in (select id from engagements where organization_id in (select user_org_ids())));

-- ---- Audit Procedures ----
create policy "Org members can read audit_procedures" on audit_procedures for select
  using (section_id in (select id from audit_sections where engagement_id in (
    select id from engagements where organization_id in (select user_org_ids()))));
create policy "Org members can insert audit_procedures" on audit_procedures for insert
  with check (section_id in (select id from audit_sections where engagement_id in (
    select id from engagements where organization_id in (select user_org_ids()))));
create policy "Org members can update audit_procedures" on audit_procedures for update
  using (section_id in (select id from audit_sections where engagement_id in (
    select id from engagements where organization_id in (select user_org_ids()))));

-- ---- Procedure Responses ----
create policy "Org members can read procedure_responses" on procedure_responses for select
  using (procedure_id in (select id from audit_procedures where section_id in (
    select id from audit_sections where engagement_id in (
      select id from engagements where organization_id in (select user_org_ids())))));
create policy "Org members can insert procedure_responses" on procedure_responses for insert
  with check (procedure_id in (select id from audit_procedures where section_id in (
    select id from audit_sections where engagement_id in (
      select id from engagements where organization_id in (select user_org_ids())))));
create policy "Org members can update procedure_responses" on procedure_responses for update
  using (procedure_id in (select id from audit_procedures where section_id in (
    select id from audit_sections where engagement_id in (
      select id from engagements where organization_id in (select user_org_ids())))));

-- ---- Documents (Relay links) ----
create policy "Org members can read documents" on documents for select
  using (
    (section_id is not null and section_id in (select id from audit_sections where engagement_id in (
      select id from engagements where organization_id in (select user_org_ids()))))
    or
    (procedure_response_id is not null and procedure_response_id in (
      select id from procedure_responses where procedure_id in (
        select id from audit_procedures where section_id in (
          select id from audit_sections where engagement_id in (
            select id from engagements where organization_id in (select user_org_ids()))))))
  );
create policy "Org members can insert documents" on documents for insert
  with check (
    (section_id is not null and section_id in (select id from audit_sections where engagement_id in (
      select id from engagements where organization_id in (select user_org_ids()))))
    or
    (procedure_response_id is not null and procedure_response_id in (
      select id from procedure_responses where procedure_id in (
        select id from audit_procedures where section_id in (
          select id from audit_sections where engagement_id in (
            select id from engagements where organization_id in (select user_org_ids()))))))
  );
create policy "Org members can delete documents" on documents for delete
  using (
    (section_id is not null and section_id in (select id from audit_sections where engagement_id in (
      select id from engagements where organization_id in (select user_org_ids()))))
    or
    (procedure_response_id is not null and procedure_response_id in (
      select id from procedure_responses where procedure_id in (
        select id from audit_procedures where section_id in (
          select id from audit_sections where engagement_id in (
            select id from engagements where organization_id in (select user_org_ids()))))))
  );

-- ---- Findings ----
create policy "Org members can read findings" on findings for select
  using (section_id in (select id from audit_sections where engagement_id in (
    select id from engagements where organization_id in (select user_org_ids()))));
create policy "Org members can insert findings" on findings for insert
  with check (section_id in (select id from audit_sections where engagement_id in (
    select id from engagements where organization_id in (select user_org_ids()))));
create policy "Org members can update findings" on findings for update
  using (section_id in (select id from audit_sections where engagement_id in (
    select id from engagements where organization_id in (select user_org_ids()))));

-- ---- Review Notes (SELECT + INSERT only — immutable) ----
create policy "Org members can read review_notes" on review_notes for select
  using (section_id in (select id from audit_sections where engagement_id in (
    select id from engagements where organization_id in (select user_org_ids()))));
create policy "Org members can insert review_notes" on review_notes for insert
  with check (section_id in (select id from audit_sections where engagement_id in (
    select id from engagements where organization_id in (select user_org_ids()))));

-- ---- Activity Log ----
create policy "View org activity log" on activity_log for select
  using (engagement_id in (select id from engagements where organization_id in (select user_org_ids())));
create policy "Create activity log entries" on activity_log for insert
  with check (engagement_id in (select id from engagements where organization_id in (select user_org_ids())));


-- ============================================================
-- NO STORAGE POLICIES — Axiom Relay: zero file storage
-- Files stay on client's Google Drive / OneDrive / SharePoint
-- We only store document links (file_url) in the documents table
-- ============================================================


COMMIT;
