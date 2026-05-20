-- Sprint 2 — Engagement Independence & Ethics workpaper (ISA 220 + IESBA Code).
--
-- Versioned model (like engagement letters): independence is point-in-time but
-- can change during the engagement (new threat emerges, new NAS, team changes).
-- Multiple rows per engagement allowed; partial unique index keeps at most one
-- active assessment.
--
-- Three tables:
--   1. engagement_independence       — parent, one active per engagement
--   2. engagement_independence_threats — 5 IESBA threat rows per parent
--                                        (self_interest / self_review /
--                                         advocacy / familiarity / intimidation)
--   3. engagement_nas                 — non-audit services list (engagement-level,
--                                        not tied to a specific assessment)
--
-- Schema design verified upfront with Perplexity (ISA 220 + IESBA) +
-- Copilot (code review). Per-team-member confirmations deferred to Sprint 3.

-- =========================================================================
-- 1. engagement_independence (PARENT)
-- =========================================================================
CREATE TABLE public.engagement_independence (
  id                          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  engagement_id               uuid NOT NULL
                                REFERENCES public.engagements(id) ON DELETE CASCADE,
  organization_id             uuid NOT NULL
                                REFERENCES public.organizations(id) ON DELETE CASCADE,

  -- Versioning
  is_superseded               boolean NOT NULL DEFAULT false,
  superseded_at               timestamptz,
  superseded_by               uuid REFERENCES public.profiles(id),

  -- Status
  status                      text NOT NULL DEFAULT 'draft'
                                CHECK (status IN ('draft','confirmed')),
  assessment_date             date,

  -- Partner attestation (ISA 220 Revised — engagement partner is responsible)
  partner_attestation_made    boolean NOT NULL DEFAULT false,
  partner_attestation_date    date,
  partner_attestation_user_id uuid REFERENCES public.profiles(id),

  -- Fee dependence (IESBA — self-interest threat)
  fee_pct_of_firm_total       numeric,  -- e.g., 12.5 means 12.5%
  fee_dependence_band         text
                                CHECK (fee_dependence_band IS NULL
                                       OR fee_dependence_band IN
                                          ('lt_10','10_to_15','15_to_20','gt_20')),
  fee_dependence_safeguards   text,

  -- Engagement-partner rotation / long association (IESBA — familiarity threat)
  partner_tenure_years        integer,
  partner_rotation_required   boolean NOT NULL DEFAULT false,
  partner_rotation_action     text,

  -- NAS summary (the actual NAS list is in engagement_nas)
  no_nas_provided             boolean NOT NULL DEFAULT false,

  -- Overall conclusion
  overall_conclusion          text,
  notes                       text,

  created_by                  uuid REFERENCES public.profiles(id),
  created_at                  timestamptz NOT NULL DEFAULT now(),
  updated_at                  timestamptz NOT NULL DEFAULT now(),

  -- Cannot confirm without partner attestation + date
  CHECK (
    status <> 'confirmed'
    OR (
      partner_attestation_made = true
      AND partner_attestation_date IS NOT NULL
    )
  )
);

CREATE UNIQUE INDEX idx_ei_one_active
  ON public.engagement_independence(engagement_id)
  WHERE is_superseded = false;
CREATE INDEX idx_ei_engagement_id   ON public.engagement_independence(engagement_id);
CREATE INDEX idx_ei_organization_id ON public.engagement_independence(organization_id);

ALTER TABLE public.engagement_independence ENABLE ROW LEVEL SECURITY;

CREATE POLICY ei_select ON public.engagement_independence
  FOR SELECT
  USING (organization_id IN (SELECT public.get_user_org_ids()));

CREATE POLICY ei_insert ON public.engagement_independence
  FOR INSERT
  WITH CHECK (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

CREATE POLICY ei_update ON public.engagement_independence
  FOR UPDATE
  USING (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

GRANT SELECT, INSERT, UPDATE ON public.engagement_independence TO authenticated;

DROP TRIGGER IF EXISTS trg_ei_set_updated_at ON public.engagement_independence;
CREATE TRIGGER trg_ei_set_updated_at
  BEFORE UPDATE ON public.engagement_independence
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at_now();


-- =========================================================================
-- 2. engagement_independence_threats (CHILD — 5 IESBA threats per parent)
-- =========================================================================
CREATE TABLE public.engagement_independence_threats (
  id                          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  engagement_independence_id  uuid NOT NULL
                                REFERENCES public.engagement_independence(id) ON DELETE CASCADE,
  organization_id             uuid NOT NULL
                                REFERENCES public.organizations(id) ON DELETE CASCADE,

  threat_type                 text NOT NULL
                                CHECK (threat_type IN (
                                  'self_interest',
                                  'self_review',
                                  'advocacy',
                                  'familiarity',
                                  'intimidation'
                                )),

  present                     boolean NOT NULL DEFAULT false,
  description                 text,
  safeguards                  text,
  conclusion                  text,
  sort_order                  int NOT NULL,

  created_at                  timestamptz NOT NULL DEFAULT now(),

  UNIQUE (engagement_independence_id, threat_type)
);

CREATE INDEX idx_eit_parent     ON public.engagement_independence_threats(engagement_independence_id);
CREATE INDEX idx_eit_organization_id ON public.engagement_independence_threats(organization_id);

ALTER TABLE public.engagement_independence_threats ENABLE ROW LEVEL SECURITY;

CREATE POLICY eit_select ON public.engagement_independence_threats
  FOR SELECT
  USING (organization_id IN (SELECT public.get_user_org_ids()));

CREATE POLICY eit_insert ON public.engagement_independence_threats
  FOR INSERT
  WITH CHECK (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

CREATE POLICY eit_update ON public.engagement_independence_threats
  FOR UPDATE
  USING (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

GRANT SELECT, INSERT, UPDATE ON public.engagement_independence_threats TO authenticated;


-- =========================================================================
-- 3. engagement_nas (CHILD — non-audit services list, engagement-level)
--    Attached to engagement, not to a specific assessment, because NAS is
--    a real-world fact about the client/firm relationship that persists
--    across reassessments.
-- =========================================================================
CREATE TABLE public.engagement_nas (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  engagement_id       uuid NOT NULL
                        REFERENCES public.engagements(id) ON DELETE CASCADE,
  organization_id     uuid NOT NULL
                        REFERENCES public.organizations(id) ON DELETE CASCADE,

  service_type        text NOT NULL,  -- e.g., 'bookkeeping','tax','valuation','it','payroll','other'
  description         text,

  threat_category     text NOT NULL
                        CHECK (threat_category IN (
                          'self_interest','self_review','advocacy','familiarity','intimidation'
                        )),
  safeguards          text,
  conclusion          text,

  is_prohibited       boolean NOT NULL DEFAULT false,  -- IESBA-prohibited service flag
  service_provider    text,  -- if not the audit firm itself (e.g., affiliated entity)
  is_active           boolean NOT NULL DEFAULT true,   -- false = terminated / declined

  created_by          uuid REFERENCES public.profiles(id),
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_enas_engagement_id    ON public.engagement_nas(engagement_id);
CREATE INDEX idx_enas_organization_id  ON public.engagement_nas(organization_id);

ALTER TABLE public.engagement_nas ENABLE ROW LEVEL SECURITY;

CREATE POLICY enas_select ON public.engagement_nas
  FOR SELECT
  USING (organization_id IN (SELECT public.get_user_org_ids()));

CREATE POLICY enas_insert ON public.engagement_nas
  FOR INSERT
  WITH CHECK (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

CREATE POLICY enas_update ON public.engagement_nas
  FOR UPDATE
  USING (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

GRANT SELECT, INSERT, UPDATE ON public.engagement_nas TO authenticated;

DROP TRIGGER IF EXISTS trg_enas_set_updated_at ON public.engagement_nas;
CREATE TRIGGER trg_enas_set_updated_at
  BEFORE UPDATE ON public.engagement_nas
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at_now();


-- =========================================================================
-- RPC: seed_independence_threats — creates the 5 IESBA threat rows for a
-- newly-created engagement_independence parent. Called by the client right
-- after inserting a parent row.
-- =========================================================================
CREATE OR REPLACE FUNCTION public.seed_independence_threats(
  p_independence_id uuid,
  p_organization_id uuid
)
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_inserted int;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE user_id = auth.uid() AND organization_id = p_organization_id
  ) THEN
    RAISE EXCEPTION 'seed_independence_threats: caller is not a member of organization %', p_organization_id;
  END IF;

  INSERT INTO public.engagement_independence_threats (
    engagement_independence_id, organization_id, threat_type, sort_order, present
  )
  VALUES
    (p_independence_id, p_organization_id, 'self_interest', 1, false),
    (p_independence_id, p_organization_id, 'self_review',   2, false),
    (p_independence_id, p_organization_id, 'advocacy',      3, false),
    (p_independence_id, p_organization_id, 'familiarity',   4, false),
    (p_independence_id, p_organization_id, 'intimidation',  5, false)
  ON CONFLICT (engagement_independence_id, threat_type) DO NOTHING;

  GET DIAGNOSTICS v_inserted = ROW_COUNT;
  RETURN v_inserted;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.seed_independence_threats(uuid, uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.seed_independence_threats(uuid, uuid) TO authenticated;


-- =========================================================================
-- RPC: revise_independence_assessment — supersedes the current active
-- assessment and creates a fresh draft, copying parent fields as a starting
-- point. Auto-seeds the 5 threat rows on the new assessment. Threat content
-- is NOT carried — partner re-evaluates fresh per ISA 220 reassessment.
-- =========================================================================
CREATE OR REPLACE FUNCTION public.revise_independence_assessment(
  p_engagement_id   uuid,
  p_organization_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_prior  public.engagement_independence%ROWTYPE;
  v_new_id uuid;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE user_id = auth.uid() AND organization_id = p_organization_id
  ) THEN
    RAISE EXCEPTION 'revise_independence_assessment: caller is not a member of organization %', p_organization_id;
  END IF;

  IF NOT public.user_has_role_in_org(p_organization_id, 'admin') THEN
    RAISE EXCEPTION 'revise_independence_assessment: caller must be an admin in organization %', p_organization_id;
  END IF;

  IF NOT public.org_has_pro_tier(p_organization_id) THEN
    RAISE EXCEPTION 'revise_independence_assessment: organization % is not on Pro tier', p_organization_id;
  END IF;

  SELECT * INTO v_prior
  FROM public.engagement_independence
  WHERE engagement_id = p_engagement_id AND is_superseded = false
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'revise_independence_assessment: no active assessment for engagement %', p_engagement_id;
  END IF;

  UPDATE public.engagement_independence
  SET is_superseded = true,
      superseded_at = now(),
      superseded_by = auth.uid()
  WHERE id = v_prior.id;

  v_new_id := gen_random_uuid();

  INSERT INTO public.engagement_independence (
    id, engagement_id, organization_id, status,
    -- Carry context fields (the relationship facts persist across reassessments)
    fee_pct_of_firm_total, fee_dependence_band, fee_dependence_safeguards,
    partner_tenure_years, partner_rotation_required, partner_rotation_action,
    no_nas_provided,
    -- Reset attestation + threat evaluation for fresh reassessment
    created_by
  ) VALUES (
    v_new_id, p_engagement_id, p_organization_id, 'draft',
    v_prior.fee_pct_of_firm_total, v_prior.fee_dependence_band, v_prior.fee_dependence_safeguards,
    v_prior.partner_tenure_years, v_prior.partner_rotation_required, v_prior.partner_rotation_action,
    v_prior.no_nas_provided,
    auth.uid()
  );

  -- Seed the 5 threat rows on the new assessment
  PERFORM public.seed_independence_threats(v_new_id, p_organization_id);

  RETURN v_new_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.revise_independence_assessment(uuid, uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.revise_independence_assessment(uuid, uuid) TO authenticated;
