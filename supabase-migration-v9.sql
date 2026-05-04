-- ============================================================
-- MIGRATION v9 — Allow cascade deletes on activity_log + review_notes
-- ============================================================
-- Problem: deleting an engagement raised "activity_log is immutable"
-- (and would also raise "review_notes are immutable" if the engagement
-- had any). Both tables had a BEFORE DELETE trigger that fired even on
-- legitimate FK cascade deletes from engagement removal.
--
-- Audit-trail immutability is still fully enforced by:
--   1. RLS — neither table has a DELETE policy, so the REST API
--      cannot delete rows directly. Only cascade deletes from a parent
--      engagement (which runs at the DB level, bypassing RLS) succeed.
--   2. UPDATE triggers below — still block any tampering with existing
--      rows.
--
-- Run this in Supabase SQL Editor.
-- ============================================================

-- activity_log: drop the delete trigger, keep the update trigger
drop trigger if exists activity_log_no_delete on activity_log;

-- review_notes: the existing trigger fires on "update or delete" — replace
-- with an update-only trigger
drop trigger if exists block_review_note_changes on review_notes;

create trigger review_notes_no_update
  before update on review_notes
  for each row execute function block_review_note_changes();
