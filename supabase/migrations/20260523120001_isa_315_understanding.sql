-- =========================================================================
-- Sprint 4 — ISA 315 Understanding the entity, embedded in Audit Planning
-- (4-AI standards floor synthesis 2026-05-23 + 3-AI parked-spec resume).
-- =========================================================================
-- Un-parks `sprint-3-audit-planning-PARKED.md`. Adds the missing ISA 315
-- structural pieces inside the existing engagement_audit_strategies table
-- — no new workpaper, no new approval flow. The 3-AI verification (2026-
-- 05-21) and 4-AI synthesis (2026-05-23) both converged on Option C
-- (embed) as the right SME-proportionate design.
--
-- IFAC SME ISA Guide explicitly endorses integration over per-ISA mirror
-- modules — see [[audexon-scope-freeze]]. Workpaper now covers ISA 300
-- (strategy) AND ISA 315 (understanding) under one approval.
--
-- Fields previously shipped in Tier 1 (20260522120000_isa_gap_items):
--   fraud_team_discussion_held / _date / _attendees
--   internal_controls_overview, planning_analytics_note,
--   going_concern_planning_note, subsequent_events_planning_note
-- ↑ These cover most ISA 315 surface area already. This migration adds
-- the remaining structural pieces.

-- =========================================================================
-- 1. New columns — 3 ISA 315.14 procedure attestations + 2 narratives
-- =========================================================================
ALTER TABLE public.engagement_audit_strategies
  ADD COLUMN IF NOT EXISTS isa_315_inquiry_performed               boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS isa_315_analytical_performed            boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS isa_315_observation_inspection_performed boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS industry_external_environment           text,
  ADD COLUMN IF NOT EXISTS significant_changes_from_prior_year     text;

-- =========================================================================
-- 2. Backfill existing approved rows
-- =========================================================================
-- Pre-existing approved strategies were signed off under the ISA 300
-- envelope which inherently includes the ISA 315 procedures (you cannot
-- form an audit strategy without performing risk assessment procedures).
-- Marking attestations true for already-approved rows is defensible —
-- the partner attested to a complete audit strategy. New approvals after
-- this migration must explicitly tick all three.
UPDATE public.engagement_audit_strategies
SET isa_315_inquiry_performed                = true,
    isa_315_analytical_performed             = true,
    isa_315_observation_inspection_performed = true
WHERE status = 'approved';

-- =========================================================================
-- 3. New CHECK constraint — ISA 315 attestations gate approval
-- =========================================================================
-- Separate named CHECK (not folded into the original anonymous CHECK) so
-- the constraint's purpose is documented at the schema level and future
-- DROPs don't require finding an implicit name.
ALTER TABLE public.engagement_audit_strategies
  DROP CONSTRAINT IF EXISTS isa_315_attestations_required_on_approve;

ALTER TABLE public.engagement_audit_strategies
  ADD CONSTRAINT isa_315_attestations_required_on_approve
  CHECK (
    status <> 'approved'
    OR (
      isa_315_inquiry_performed                = true
      AND isa_315_analytical_performed         = true
      AND isa_315_observation_inspection_performed = true
    )
  );

-- =========================================================================
-- 4. Update revise_audit_strategy RPC — carry forward all narrative +
--    team + Tier-1 + ISA 315 fields. Attestations reset on each revision
--    (every version gets fresh sign-off per ISA 300.12).
-- =========================================================================
CREATE OR REPLACE FUNCTION public.revise_audit_strategy(
  p_engagement_id   uuid,
  p_organization_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_old    public.engagement_audit_strategies%ROWTYPE;
  v_new_id uuid;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE user_id = auth.uid() AND organization_id = p_organization_id
  ) THEN
    RAISE EXCEPTION 'revise_audit_strategy: caller is not a member of organization %', p_organization_id;
  END IF;

  IF NOT public.user_has_role_in_org(p_organization_id, 'admin') THEN
    RAISE EXCEPTION 'revise_audit_strategy: caller must be an admin in organization %', p_organization_id;
  END IF;

  IF NOT public.org_has_pro_tier(p_organization_id) THEN
    RAISE EXCEPTION 'revise_audit_strategy: organization % is not on Pro tier', p_organization_id;
  END IF;

  SELECT * INTO v_old
  FROM public.engagement_audit_strategies
  WHERE engagement_id = p_engagement_id AND is_superseded = false
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'revise_audit_strategy: no active strategy exists for engagement %', p_engagement_id;
  END IF;

  UPDATE public.engagement_audit_strategies
  SET is_superseded = true,
      superseded_at = now(),
      superseded_by = auth.uid()
  WHERE id = v_old.id;

  v_new_id := gen_random_uuid();
  INSERT INTO public.engagement_audit_strategies (
    id, engagement_id, organization_id, status,
    -- ISA 300 strategy narratives
    scope_characteristics, reporting_objectives, significant_factors,
    preliminary_activities_summary, resources_plan,
    partner_direction_plan,
    team_composition, specialists_involved,
    eqr_required, eqr_reviewer_name, budgeted_hours,
    -- Tier 1 planning narratives (carry forward — stable across revisions)
    internal_controls_overview, planning_analytics_note,
    going_concern_planning_note, subsequent_events_planning_note,
    fraud_team_discussion_held, fraud_team_discussion_date,
    fraud_team_discussion_attendees,
    -- ISA 315 narratives (carry forward — stable client facts)
    industry_external_environment, significant_changes_from_prior_year,
    created_by
  ) VALUES (
    v_new_id, p_engagement_id, p_organization_id, 'draft',
    v_old.scope_characteristics, v_old.reporting_objectives, v_old.significant_factors,
    v_old.preliminary_activities_summary, v_old.resources_plan,
    v_old.partner_direction_plan,
    v_old.team_composition, v_old.specialists_involved,
    v_old.eqr_required, v_old.eqr_reviewer_name, v_old.budgeted_hours,
    v_old.internal_controls_overview, v_old.planning_analytics_note,
    v_old.going_concern_planning_note, v_old.subsequent_events_planning_note,
    v_old.fraud_team_discussion_held, v_old.fraud_team_discussion_date,
    v_old.fraud_team_discussion_attendees,
    v_old.industry_external_environment, v_old.significant_changes_from_prior_year,
    auth.uid()
  );

  RETURN v_new_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.revise_audit_strategy(uuid, uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.revise_audit_strategy(uuid, uuid) TO authenticated;
