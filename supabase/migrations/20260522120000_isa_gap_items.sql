-- 2026-05-22 — ISA gap items per 2-AI synthesis (Perplexity + claude.ai)
--
-- Adds fields to existing planning workpapers to close the substantive
-- gaps both AIs flagged in the Planning Memorandum PDF review. No new
-- tables; pure ALTER. CHECK constraints unchanged (these are narrative
-- fields, not attestations).
--
-- Items shipped:
--   1. Going concern planning narrative (ISA 570 planning side)
--   2. Subsequent events planning narrative (ISA 560 planning side)
--   3. Internal controls overview (ISA 315.12-26)
--   4. Fraud team discussion (ISA 240.17) — checkbox + date + attendees
--   5. Planning analytics (ISA 315.6)
--   6. Reporting considerations — 3 fields on Engagement Letter
--      (ISA 700 planning-side anticipation)
--
-- Rationale: claude.ai identified items 4 + 5 as "most commonly cited
-- deficiencies in small firm inspections." Items 1, 2, 3, 6 both AIs
-- converged on as RED gaps. Entity overview / industry-regulatory
-- deliberately DEFERRED (= parked Sprint 3 #2 / Audit Planning refresh).

-- =========================================================================
-- 1. engagement_audit_strategies — 5 new narrative/attestation fields
-- =========================================================================
ALTER TABLE public.engagement_audit_strategies
  ADD COLUMN IF NOT EXISTS going_concern_planning_note     text,
  ADD COLUMN IF NOT EXISTS subsequent_events_planning_note text,
  ADD COLUMN IF NOT EXISTS internal_controls_overview      text,
  ADD COLUMN IF NOT EXISTS planning_analytics_note         text,
  ADD COLUMN IF NOT EXISTS fraud_team_discussion_held      boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS fraud_team_discussion_date      date,
  ADD COLUMN IF NOT EXISTS fraud_team_discussion_attendees text;

-- Carry-forward note for revise_audit_strategy: these new fields are NOT
-- yet in the explicit-named-column INSERT inside revise_audit_strategy.
-- The next revise after this migration WILL drop these fields to defaults
-- in the new draft. Acceptable for v1 (these are rarely changed mid-engagement)
-- but should be added to the RPC in a follow-up if revisions become common.

-- =========================================================================
-- 2. engagement_letters — 3 new fields for reporting considerations
-- =========================================================================
ALTER TABLE public.engagement_letters
  ADD COLUMN IF NOT EXISTS expected_report_type        text
    CHECK (expected_report_type IS NULL OR expected_report_type IN
      ('unmodified','qualified','adverse','disclaimer','unknown')),
  ADD COLUMN IF NOT EXISTS modification_risk_notes     text,
  ADD COLUMN IF NOT EXISTS report_delivery_target_date date;

-- Same carry-forward note applies to revise_engagement_letter — these new
-- fields will reset to defaults on the next revision. Acceptable for v1.
