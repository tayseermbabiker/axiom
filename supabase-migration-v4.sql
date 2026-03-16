-- ============================================================
-- MIGRATION v4: Three-level sign-off, rename reviewer→supervisor,
--               finding enhancements, adjusting entries
-- Run ALL of this in Supabase SQL Editor (one paste, one run)
-- ============================================================


-- ============================================================
-- 1. RENAME REVIEWER → SUPERVISOR
-- ============================================================
update organization_members set role = 'supervisor' where role = 'reviewer';
update organization_invites set role = 'supervisor' where role = 'reviewer';

alter table organization_members drop constraint if exists organization_members_role_check;
alter table organization_members add constraint organization_members_role_check
  check (role in ('admin', 'supervisor', 'preparer'));

alter table organization_invites drop constraint if exists organization_invites_role_check;
alter table organization_invites add constraint organization_invites_role_check
  check (role in ('admin', 'supervisor', 'preparer'));


-- ============================================================
-- 2. THREE-LEVEL SIGN-OFF: Update audit_sections
-- ============================================================

-- Drop old constraint FIRST
alter table audit_sections drop constraint if exists audit_sections_status_check;

-- Migrate old status values BEFORE adding new constraint
update audit_sections set status = 'ready_for_supervisor_review' where status = 'ready_for_review';
update audit_sections set status = 'returned_to_preparer' where status = 'returned';

-- Now add new constraint (all rows already have valid values)
alter table audit_sections add constraint audit_sections_status_check
  check (status in (
    'not_started',
    'in_progress',
    'ready_for_supervisor_review',
    'in_supervisor_review',
    'ready_for_partner_review',
    'in_partner_review',
    'returned_to_preparer',
    'returned_to_supervisor',
    'approved'
  ));

-- Add new approval fields
alter table audit_sections add column if not exists supervisor_approved_by uuid references profiles(id);
alter table audit_sections add column if not exists supervisor_approved_at timestamptz;
alter table audit_sections add column if not exists partner_approved_by uuid references profiles(id);
alter table audit_sections add column if not exists partner_approved_at timestamptz;

-- Migrate existing approvals to partner level
update audit_sections
set partner_approved_by = approved_by,
    partner_approved_at = approved_at,
    supervisor_approved_by = approved_by,
    supervisor_approved_at = approved_at
where approved_at is not null;


-- ============================================================
-- 3. UPDATE IMMUTABILITY TRIGGER
-- ============================================================
create or replace function protect_approval_timestamps()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if old.supervisor_approved_at is not null
    and new.supervisor_approved_at is distinct from old.supervisor_approved_at
    and new.status not in ('returned_to_preparer', 'returned_to_supervisor', 'in_progress')
  then
    raise exception 'supervisor_approved_at is immutable once set (use reopen to clear)';
  end if;

  if old.partner_approved_at is not null
    and new.partner_approved_at is distinct from old.partner_approved_at
    and new.status not in ('returned_to_supervisor', 'in_supervisor_review', 'in_progress')
  then
    raise exception 'partner_approved_at is immutable once set (use reopen to clear)';
  end if;

  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists protect_approved_at on audit_sections;
drop trigger if exists protect_approval_timestamps on audit_sections;
create trigger protect_approval_timestamps
  before update on audit_sections
  for each row execute function protect_approval_timestamps();


-- ============================================================
-- 4. FINDING ENHANCEMENTS
-- ============================================================
alter table findings add column if not exists finding_type text not null default 'observation'
  check (finding_type in ('misstatement', 'control_deficiency', 'observation'));
alter table findings add column if not exists is_management_letter_point boolean not null default false;


-- ============================================================
-- 5. ADJUSTING ENTRIES TABLE
-- ============================================================
create table if not exists adjusting_entries (
  id uuid primary key default gen_random_uuid(),
  finding_id uuid not null references findings(id) on delete cascade,
  debit_account text not null,
  credit_account text not null,
  amount numeric not null,
  narration text default '',
  is_posted boolean not null default false,
  created_at timestamptz default now()
);

alter table adjusting_entries enable row level security;

create policy "Org members can read adjusting_entries" on adjusting_entries for select
  using (finding_id in (
    select id from findings where section_id in (
      select id from audit_sections where engagement_id in (
        select id from engagements where organization_id in (select user_org_ids())))));

create policy "Org members can insert adjusting_entries" on adjusting_entries for insert
  with check (finding_id in (
    select id from findings where section_id in (
      select id from audit_sections where engagement_id in (
        select id from engagements where organization_id in (select user_org_ids())))));

create policy "Org members can update adjusting_entries" on adjusting_entries for update
  using (finding_id in (
    select id from findings where section_id in (
      select id from audit_sections where engagement_id in (
        select id from engagements where organization_id in (select user_org_ids())))));

create policy "Org members can delete adjusting_entries" on adjusting_entries for delete
  using (finding_id in (
    select id from findings where section_id in (
      select id from audit_sections where engagement_id in (
        select id from engagements where organization_id in (select user_org_ids())))));


-- ============================================================
-- 6. UPDATE delete_section RPC
-- ============================================================
create or replace function delete_section(p_section_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_engagement_id uuid;
  v_org_id uuid;
  v_user_org_id uuid;
begin
  select engagement_id into v_engagement_id
  from audit_sections where id = p_section_id;

  if v_engagement_id is null then
    raise exception 'Section not found';
  end if;

  select organization_id into v_org_id
  from engagements where id = v_engagement_id;

  select organization_id into v_user_org_id
  from organization_members where user_id = auth.uid() and organization_id = v_org_id;

  if v_user_org_id is null then
    raise exception 'Access denied';
  end if;

  delete from adjusting_entries where finding_id in (
    select id from findings where section_id = p_section_id);
  delete from documents where procedure_response_id in (
    select id from procedure_responses where procedure_id in (
      select id from audit_procedures where section_id = p_section_id));
  delete from documents where section_id = p_section_id;
  delete from procedure_responses where procedure_id in (
    select id from audit_procedures where section_id = p_section_id);
  delete from audit_procedures where section_id = p_section_id;
  delete from findings where section_id = p_section_id;
  delete from review_notes where section_id = p_section_id;
  delete from audit_sections where id = p_section_id;
end;
$$;
