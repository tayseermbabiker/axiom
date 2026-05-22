-- 2026-05-22 — External EQR reviewer support
--
-- Small firms doing audits that require EQR (listed entity, regulated
-- client, etc.) often source the reviewer from OUTSIDE the firm —
-- another firm's partner, freelance senior, network resource. The
-- existing eqr_reviewer_id (FK to profiles) only works for users that
-- exist in the Audexon org.
--
-- This migration adds external-reviewer fields. The UI toggles between
-- internal (dropdown -> eqr_reviewer_id) and external (text fields ->
-- eqr_external_reviewer_name + firm). The eqr_completed_at /
-- eqr_completed_by stamps stay the same in both modes.

ALTER TABLE public.engagement_completion_memo
  ADD COLUMN IF NOT EXISTS eqr_is_external            boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS eqr_external_reviewer_name text,
  ADD COLUMN IF NOT EXISTS eqr_external_reviewer_firm text;
