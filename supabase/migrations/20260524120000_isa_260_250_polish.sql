-- =========================================================================
-- Sprint 4 polish — ISA 260 + ISA 250 lines on Audit Planning
-- Driven by Perplexity review of the FALCOM continuance planning PDF
-- 2026-05-24: "no major gaps; two one-line polish items if you want to
-- be extra tight."
-- =========================================================================
-- Both fields are small text narratives that close the only two nitpicks
-- Perplexity could find. Neither is structurally required by ISA but
-- both show up cleanly in inspection checklists.
--
-- ISA 260 — Communication with TCWG/management. The planning workpaper
-- already documents reporting objectives + timing; this field captures
-- HOW audit matters / control deficiencies will be communicated during
-- and after the audit.
--
-- ISA 250 — Laws and regulations. Industry/external environment already
-- mentions specific laws (e.g. UAE corporate tax); this field is the
-- explicit "key laws and regulatory regimes considered" line a network
-- inspector expects to see called out.

ALTER TABLE public.engagement_audit_strategies
  ADD COLUMN IF NOT EXISTS planned_communications_mgmt_tcwg text,
  ADD COLUMN IF NOT EXISTS key_laws_regulations             text;

-- Add the two new fields to the revise_audit_strategy carry-forward
-- (Tier 1 + ISA 315 fields were added in migration 20260523120001;
-- this extends the named-column INSERT to include the new pair so
-- revisions don't silently NULL them).
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
    -- Tier 1 planning narratives
    internal_controls_overview, planning_analytics_note,
    going_concern_planning_note, subsequent_events_planning_note,
    fraud_team_discussion_held, fraud_team_discussion_date,
    fraud_team_discussion_attendees,
    -- ISA 315 narratives
    industry_external_environment, significant_changes_from_prior_year,
    -- ISA 260 + ISA 250 polish (Perplexity 2026-05-24)
    planned_communications_mgmt_tcwg, key_laws_regulations,
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
    v_old.planned_communications_mgmt_tcwg, v_old.key_laws_regulations,
    auth.uid()
  );

  RETURN v_new_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.revise_audit_strategy(uuid, uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.revise_audit_strategy(uuid, uuid) TO authenticated;
