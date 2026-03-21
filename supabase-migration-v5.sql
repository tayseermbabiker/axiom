-- ============================================================
-- MIGRATION v5: Phases, finding closure categories
-- Run ALL of this in Supabase SQL Editor
-- ============================================================

-- 1. Add phase to audit_sections
alter table audit_sections add column if not exists phase text not null default 'final'
  check (phase in ('interim', 'final'));

-- 2. Add finding closure fields
alter table findings add column if not exists identified_in_phase text not null default 'final'
  check (identified_in_phase in ('interim', 'final'));

alter table findings add column if not exists close_category text default null
  check (close_category in (
    'unadjusted_immaterial',
    'communicated_to_management',
    'control_deficiency_communicated',
    'control_deficiency_significant',
    'observation_no_action',
    null
  ));

-- 3. Add engagement closure fields
alter table engagements add column if not exists closed_by uuid references profiles(id);
alter table engagements add column if not exists closed_at timestamptz;
alter table engagements add column if not exists close_acknowledgment text default '';

-- 4. Update activity_log target_type to allow 'procedure_response'
-- (needed for existing code that logs response changes)
alter table activity_log drop constraint if exists activity_log_target_type_check;
alter table activity_log add constraint activity_log_target_type_check
  check (target_type in (
    'engagement', 'trial_balance', 'document', 'review_note',
    'organization', 'member', 'section', 'procedure', 'finding',
    'response', 'procedure_response'
  ));
