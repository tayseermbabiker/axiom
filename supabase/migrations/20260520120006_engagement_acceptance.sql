-- Sprint 2 — Client Acceptance / Continuance workpaper (ISA 220 Revised).
--
-- Versioned model (same pattern as Independence + Engagement Letter): one
-- active row per engagement, partial unique index, revise RPC. Single table
-- covers both initial acceptance AND annual continuance via acceptance_type
-- field. Type-specific columns coexist on the same table (predecessor
-- auditor for initial, prior-year-issues for continuance) with UI showing
-- only the relevant fields per type.
--
-- Design verified upfront with Perplexity (ISA 220 + practice-review
-- guidance) + Copilot (code review). Key choices anchored:
--   - Single table + acceptance_type discriminator
--   - Structured integrity-method booleans (not single narrative box)
--   - Predecessor communication section LIVES in this workpaper
--   - Decision enum: accept / accept_with_conditions / decline
--   - Risk tier: low / medium / high
--   - Soft UI link to Independence (no DB CHECK / FK)
--   - CHECK constraint enforces minimum confirmed-state fields

CREATE TABLE public.engagement_acceptance (
  id                                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  engagement_id                       uuid NOT NULL
                                        REFERENCES public.engagements(id) ON DELETE CASCADE,
  organization_id                     uuid NOT NULL
                                        REFERENCES public.organizations(id) ON DELETE CASCADE,

  -- Versioning
  is_superseded                       boolean NOT NULL DEFAULT false,
  superseded_at                       timestamptz,
  superseded_by                       uuid REFERENCES public.profiles(id),

  -- Type and status
  acceptance_type                     text
                                        CHECK (acceptance_type IS NULL
                                               OR acceptance_type IN ('initial','continuance')),
  status                              text NOT NULL DEFAULT 'draft'
                                        CHECK (status IN ('draft','confirmed')),

  -- Decision
  decision                            text
                                        CHECK (decision IS NULL
                                               OR decision IN ('accept','accept_with_conditions','decline')),
  decision_date                       date,
  decision_rationale                  text,
  conditions_summary                  text,  -- required UI-side when decision = accept_with_conditions

  -- Engagement risk tier (informs planning + materiality + EQR triggers)
  risk_tier                           text
                                        CHECK (risk_tier IS NULL
                                               OR risk_tier IN ('low','medium','high')),

  -- Integrity assessment (ISA 220.A20-A22 — owners / management / TCWG)
  integrity_method_prior_experience   boolean NOT NULL DEFAULT false,
  integrity_method_internet_search    boolean NOT NULL DEFAULT false,
  integrity_method_predecessor_inquiry boolean NOT NULL DEFAULT false,
  integrity_method_other              boolean NOT NULL DEFAULT false,
  integrity_method_other_description  text,
  integrity_conclusion                text,

  -- Competence and resources (ISA 220 requirement)
  competence_resources_considered     boolean NOT NULL DEFAULT false,
  competence_resources_notes          text,

  -- Predecessor auditor (typically for acceptance_type = 'initial')
  had_predecessor_auditor             boolean NOT NULL DEFAULT false,
  predecessor_auditor_name            text,
  predecessor_communication_done      boolean NOT NULL DEFAULT false,
  predecessor_communication_summary   text,
  predecessor_workpapers_accessed     boolean NOT NULL DEFAULT false,

  -- Prior-year issues (typically for acceptance_type = 'continuance')
  prior_year_issues_considered        boolean NOT NULL DEFAULT false,
  prior_year_issues_summary           text,

  -- Independence cross-check (SOFT link — UI warns if not done, no DB FK)
  independence_assessment_completed   boolean NOT NULL DEFAULT false,

  -- Partner attestation (ISA 220 Revised — partner takes responsibility)
  partner_attestation_made            boolean NOT NULL DEFAULT false,
  partner_attestation_date            date,
  partner_attestation_user_id         uuid REFERENCES public.profiles(id),

  notes                               text,

  created_by                          uuid REFERENCES public.profiles(id),
  created_at                          timestamptz NOT NULL DEFAULT now(),
  updated_at                          timestamptz NOT NULL DEFAULT now(),

  -- Confirmed state requires the core decision fields
  CHECK (
    status <> 'confirmed'
    OR (
      acceptance_type          IS NOT NULL
      AND decision             IS NOT NULL
      AND decision_date        IS NOT NULL
      AND risk_tier            IS NOT NULL
      AND partner_attestation_made = true
      AND partner_attestation_date IS NOT NULL
    )
  )
);

CREATE UNIQUE INDEX idx_eacc_one_active
  ON public.engagement_acceptance(engagement_id)
  WHERE is_superseded = false;
CREATE INDEX idx_eacc_engagement_id   ON public.engagement_acceptance(engagement_id);
CREATE INDEX idx_eacc_organization_id ON public.engagement_acceptance(organization_id);

ALTER TABLE public.engagement_acceptance ENABLE ROW LEVEL SECURITY;

CREATE POLICY eacc_select ON public.engagement_acceptance
  FOR SELECT
  USING (organization_id IN (SELECT public.get_user_org_ids()));

CREATE POLICY eacc_insert ON public.engagement_acceptance
  FOR INSERT
  WITH CHECK (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

CREATE POLICY eacc_update ON public.engagement_acceptance
  FOR UPDATE
  USING (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

GRANT SELECT, INSERT, UPDATE ON public.engagement_acceptance TO authenticated;

DROP TRIGGER IF EXISTS trg_eacc_set_updated_at ON public.engagement_acceptance;
CREATE TRIGGER trg_eacc_set_updated_at
  BEFORE UPDATE ON public.engagement_acceptance
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at_now();


-- =========================================================================
-- RPC: revise_engagement_acceptance — supersedes current + creates new
-- draft. Carries forward stable client-fact fields (predecessor info,
-- integrity-method history) so the partner doesn't re-document the same
-- background facts every year for continuance.
-- =========================================================================
CREATE OR REPLACE FUNCTION public.revise_engagement_acceptance(
  p_engagement_id   uuid,
  p_organization_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_prior  public.engagement_acceptance%ROWTYPE;
  v_new_id uuid;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE user_id = auth.uid() AND organization_id = p_organization_id
  ) THEN
    RAISE EXCEPTION 'revise_engagement_acceptance: caller is not a member of organization %', p_organization_id;
  END IF;

  IF NOT public.user_has_role_in_org(p_organization_id, 'admin') THEN
    RAISE EXCEPTION 'revise_engagement_acceptance: caller must be an admin in organization %', p_organization_id;
  END IF;

  IF NOT public.org_has_pro_tier(p_organization_id) THEN
    RAISE EXCEPTION 'revise_engagement_acceptance: organization % is not on Pro tier', p_organization_id;
  END IF;

  SELECT * INTO v_prior
  FROM public.engagement_acceptance
  WHERE engagement_id = p_engagement_id AND is_superseded = false
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'revise_engagement_acceptance: no active row for engagement %', p_engagement_id;
  END IF;

  UPDATE public.engagement_acceptance
  SET is_superseded = true,
      superseded_at = now(),
      superseded_by = auth.uid()
  WHERE id = v_prior.id;

  v_new_id := gen_random_uuid();

  -- New draft. acceptance_type defaults to 'continuance' on revise (the
  -- normal case — annual reassessment of an existing client). Partner can
  -- override if the engagement is being restructured. Predecessor fields
  -- carry forward as historical background. Decision + attestation reset.
  INSERT INTO public.engagement_acceptance (
    id, engagement_id, organization_id, status, acceptance_type,
    had_predecessor_auditor, predecessor_auditor_name,
    predecessor_communication_done, predecessor_communication_summary,
    predecessor_workpapers_accessed,
    integrity_method_prior_experience, integrity_method_internet_search,
    integrity_method_predecessor_inquiry, integrity_method_other,
    integrity_method_other_description,
    competence_resources_considered, competence_resources_notes,
    created_by
  ) VALUES (
    v_new_id, p_engagement_id, p_organization_id, 'draft', 'continuance',
    v_prior.had_predecessor_auditor, v_prior.predecessor_auditor_name,
    v_prior.predecessor_communication_done, v_prior.predecessor_communication_summary,
    v_prior.predecessor_workpapers_accessed,
    v_prior.integrity_method_prior_experience, v_prior.integrity_method_internet_search,
    v_prior.integrity_method_predecessor_inquiry, v_prior.integrity_method_other,
    v_prior.integrity_method_other_description,
    v_prior.competence_resources_considered, v_prior.competence_resources_notes,
    auth.uid()
  );

  RETURN v_new_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.revise_engagement_acceptance(uuid, uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.revise_engagement_acceptance(uuid, uuid) TO authenticated;
