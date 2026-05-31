-- Sprint 3 #1 — Audit Strategy / Overall Plan workpaper (ISA 300).
--
-- Versioned per the Engagement Letter / Independence pattern: partial unique
-- index enforces at most one active (non-superseded) strategy per engagement.
-- Revisions create a new draft and supersede the prior approved version per
-- ISA 300.12 (documentation of significant changes to the overall strategy).
--
-- Schema decisions verified upfront with Perplexity (ISA research) + Copilot
-- (code review):
--   * 5 narrative fields aligned to ISA 300.9's five canonical elements
--     (scope, reporting objectives + timing, significant factors,
--     preliminary activities, resources).
--   * Per Perplexity Q3 on ISA 220 (Revised): partner direction captured as
--     an EXPLICIT narrative field + dedicated attestation, not folded into
--     'significant_factors'. Inspectors look for explicit partner-direction
--     evidence; we don't want it implicit.
--   * Per Copilot Q5: the revise_audit_strategy RPC uses SELECT * INTO + an
--     INSERT...SELECT with explicit named columns so a newly-added column on
--     a future migration fails loudly here rather than silently NULLing out
--     on revision.
--   * CHECK constraint mirrors Engagement Letter: status='approved' requires
--     all 4 attestations + approved_by + approved_at, all enforced at DB.

CREATE TABLE public.engagement_audit_strategies (
  id                                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  engagement_id                     uuid NOT NULL
                                      REFERENCES public.engagements(id) ON DELETE CASCADE,
  organization_id                   uuid NOT NULL
                                      REFERENCES public.organizations(id) ON DELETE CASCADE,

  -- Versioning
  version_label                     text,
  is_superseded                     boolean NOT NULL DEFAULT false,
  superseded_at                     timestamptz,
  superseded_by                     uuid REFERENCES public.profiles(id),

  -- Status
  status                            text NOT NULL DEFAULT 'draft'
                                      CHECK (status IN ('draft','approved')),

  -- ISA 300.9 — five strategy elements (narrative)
  scope_characteristics             text,
  reporting_objectives              text,
  significant_factors               text,
  preliminary_activities_summary    text,
  resources_plan                    text,

  -- ISA 220 (Revised) — partner direction, supervision, review (explicit)
  partner_direction_plan            text,

  -- Team / specialists / EQR
  team_composition                  text,
  specialists_involved              text,
  eqr_required                      boolean NOT NULL DEFAULT false,
  eqr_reviewer_name                 text,
  budgeted_hours                    numeric,

  -- ISA 300 + ISA 220 attestations
  isa_300_strategy_documented            boolean NOT NULL DEFAULT false,
  isa_300_resources_assessed             boolean NOT NULL DEFAULT false,
  isa_300_team_briefed                   boolean NOT NULL DEFAULT false,
  isa_220_direction_supervision_planned  boolean NOT NULL DEFAULT false,

  -- Approval
  approved_by                       uuid REFERENCES public.profiles(id),
  approved_at                       timestamptz,

  created_by                        uuid REFERENCES public.profiles(id),
  created_at                        timestamptz NOT NULL DEFAULT now(),
  updated_at                        timestamptz NOT NULL DEFAULT now(),

  -- Status integrity: approved requires four attestations + approval stamps
  CHECK (
    status <> 'approved'
    OR (
      isa_300_strategy_documented           = true
      AND isa_300_resources_assessed        = true
      AND isa_300_team_briefed              = true
      AND isa_220_direction_supervision_planned = true
      AND approved_by                       IS NOT NULL
      AND approved_at                       IS NOT NULL
    )
  )
);

CREATE UNIQUE INDEX idx_eas_one_active
  ON public.engagement_audit_strategies(engagement_id)
  WHERE is_superseded = false;

CREATE INDEX idx_eas_engagement_id   ON public.engagement_audit_strategies(engagement_id);
CREATE INDEX idx_eas_organization_id ON public.engagement_audit_strategies(organization_id);

ALTER TABLE public.engagement_audit_strategies ENABLE ROW LEVEL SECURITY;

-- Read open to org members; write gated to admin + Pro (matches Engagement Letter).
CREATE POLICY eas_select ON public.engagement_audit_strategies
  FOR SELECT
  USING (organization_id IN (SELECT public.get_user_org_ids()));

CREATE POLICY eas_insert ON public.engagement_audit_strategies
  FOR INSERT
  WITH CHECK (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

CREATE POLICY eas_update ON public.engagement_audit_strategies
  FOR UPDATE
  USING (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

GRANT SELECT, INSERT, UPDATE ON public.engagement_audit_strategies TO authenticated;

DROP TRIGGER IF EXISTS trg_eas_set_updated_at ON public.engagement_audit_strategies;
CREATE TRIGGER trg_eas_set_updated_at
  BEFORE UPDATE ON public.engagement_audit_strategies
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at_now();

-- =========================================================================
-- RPC: approve_audit_strategy
-- Atomic single-UPDATE: stamps approved_by + approved_at + status='approved'.
-- The attestations must already be set to true by the client form submission
-- in the same payload (UI-enforced). CHECK constraint enforces this at DB
-- level — single-UPDATE timing means CHECK evaluates against the post-update
-- row (Copilot Q4 verified).
-- =========================================================================
CREATE OR REPLACE FUNCTION public.approve_audit_strategy(
  p_strategy_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id uuid;
BEGIN
  SELECT organization_id INTO v_org_id
  FROM public.engagement_audit_strategies
  WHERE id = p_strategy_id AND is_superseded = false;

  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'approve_audit_strategy: strategy % not found or already superseded', p_strategy_id;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE user_id = auth.uid() AND organization_id = v_org_id
  ) THEN
    RAISE EXCEPTION 'approve_audit_strategy: caller is not a member of organization %', v_org_id;
  END IF;

  IF NOT public.user_has_role_in_org(v_org_id, 'admin') THEN
    RAISE EXCEPTION 'approve_audit_strategy: caller must be an admin in organization %', v_org_id;
  END IF;

  IF NOT public.org_has_pro_tier(v_org_id) THEN
    RAISE EXCEPTION 'approve_audit_strategy: organization % is not on Pro tier', v_org_id;
  END IF;

  UPDATE public.engagement_audit_strategies
  SET status      = 'approved',
      approved_by = auth.uid(),
      approved_at = now()
  WHERE id = p_strategy_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.approve_audit_strategy(uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.approve_audit_strategy(uuid) TO authenticated;

-- =========================================================================
-- RPC: revise_audit_strategy
-- Supersede the active approved row and create a fresh draft carrying all
-- narrative + team fields forward, but RESETTING attestations + approval
-- (each revision is a fresh sign-off event per ISA 300.12).
--
-- Uses SELECT * INTO v_old + INSERT...SELECT v_old.* with explicit named
-- columns (Copilot Q5 pattern). If a future migration adds a column that
-- should carry forward, the developer must add it here or risk silent NULLs
-- on the next revision — which is exactly the loud-fail behaviour we want.
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

  -- Supersede prior
  UPDATE public.engagement_audit_strategies
  SET is_superseded = true,
      superseded_at = now(),
      superseded_by = auth.uid()
  WHERE id = v_old.id;

  -- Insert new draft. Carry narrative + team + ISA-doc fields forward.
  -- Explicitly EXCLUDE: id, is_superseded, superseded_at, superseded_by,
  -- status, attestations, approved_by/at, created_by/at, updated_at.
  v_new_id := gen_random_uuid();
  INSERT INTO public.engagement_audit_strategies (
    id, engagement_id, organization_id, status,
    scope_characteristics, reporting_objectives, significant_factors,
    preliminary_activities_summary, resources_plan,
    partner_direction_plan,
    team_composition, specialists_involved,
    eqr_required, eqr_reviewer_name, budgeted_hours,
    created_by
  ) VALUES (
    v_new_id, p_engagement_id, p_organization_id, 'draft',
    v_old.scope_characteristics, v_old.reporting_objectives, v_old.significant_factors,
    v_old.preliminary_activities_summary, v_old.resources_plan,
    v_old.partner_direction_plan,
    v_old.team_composition, v_old.specialists_involved,
    v_old.eqr_required, v_old.eqr_reviewer_name, v_old.budgeted_hours,
    auth.uid()
  );

  RETURN v_new_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.revise_audit_strategy(uuid, uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.revise_audit_strategy(uuid, uuid) TO authenticated;
