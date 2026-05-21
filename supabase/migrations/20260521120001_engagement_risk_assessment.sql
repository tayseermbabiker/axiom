-- Sprint 3 #3 — Risk Assessment Matrix (ISA 315.27 + ISA 330 + ISA 240).
--
-- Three tables:
--   engagement_risks                    — parent (one row per identified risk)
--   engagement_risk_procedure_links     — many-to-many (risk -> audit_procedure)
--   engagement_risk_assessment          — engagement-level attestation + status
--
-- Verified upfront with Perplexity (ISA research) + Copilot (code review).
-- Three verification fixes baked in (see specs/sprint-3-risk-assessment.md § 9):
--
--   1. ISA 240.26 rebuttal workflow — 4 columns + 2 CHECKs. Revenue fraud
--      risk can be rebutted with rationale + admin approval; management
--      override stays non-rebuttable per ISA 240.31.
--
--   2. Stand-back attestation — 4th attestation on the engagement-level row.
--      Confirmation forces partner to consider whether material sections
--      without significant risks warrant such treatment (ISA 315.A114).
--
--   3. Architecture: pre-seed assessment row at engagement creation (handled
--      in dashboard.html; no AFTER INSERT trigger here). BEFORE DELETE
--      trigger on the junction table prevents post-confirmation procedure
--      deletes from orphaning a significant risk's required ISA 330.21
--      linkage.
--
-- Auto-seeding of the ISA 240 presumed risks (revenue + management override)
-- happens via seed_presumed_fraud_risks(), called from dashboard.html
-- engagement creation alongside seedSectionsForEngagement.

-- =========================================================================
-- TABLE: engagement_risks (parent)
-- =========================================================================
CREATE TABLE public.engagement_risks (
  id                         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  engagement_id              uuid NOT NULL REFERENCES public.engagements(id) ON DELETE CASCADE,
  organization_id            uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  section_id                 uuid NOT NULL REFERENCES public.audit_sections(id) ON DELETE CASCADE,

  assertion                  text NOT NULL
                               CHECK (assertion IN (
                                 'existence','completeness','accuracy','valuation',
                                 'cutoff','classification','rights_obligations','presentation'
                               )),
  risk_description           text NOT NULL,
  source                     text NOT NULL
                               CHECK (source IN (
                                 'entity','industry','it','fraud',
                                 'management_override','rap','other'
                               )),

  inherent_rating            text NOT NULL CHECK (inherent_rating IN ('low','medium','high')),
  control_rating             text NOT NULL CHECK (control_rating  IN ('low','medium','high')),
  combined_rating            text NOT NULL CHECK (combined_rating IN ('low','medium','high')),

  is_significant             boolean NOT NULL DEFAULT false,
  significant_rationale      text,

  overall_response           text NOT NULL,

  -- ISA 240 presumed risks (revenue recognition + management override)
  is_locked_presumed         boolean NOT NULL DEFAULT false,

  -- ISA 240.26 rebuttal workflow (revenue only; mgmt override is non-rebuttable per ISA 240.31)
  presumption_rebutted       boolean NOT NULL DEFAULT false,
  rebuttal_rationale         text,
  rebuttal_approved_by       uuid REFERENCES public.profiles(id),
  rebuttal_approved_at       timestamptz,

  created_by                 uuid REFERENCES public.profiles(id),
  created_at                 timestamptz NOT NULL DEFAULT now(),
  updated_at                 timestamptz NOT NULL DEFAULT now(),

  -- If marked significant, rationale is required (ISA 315.A115).
  CHECK (
    is_significant = false
    OR significant_rationale IS NOT NULL
  ),

  -- Rebuttal integrity: if rebutted, rationale + approver + timestamp required.
  CHECK (
    presumption_rebutted = false
    OR (
      rebuttal_rationale     IS NOT NULL
      AND rebuttal_approved_by IS NOT NULL
      AND rebuttal_approved_at IS NOT NULL
    )
  ),

  -- ISA 240.31: management override is non-rebuttable.
  CHECK (
    source <> 'management_override'
    OR presumption_rebutted = false
  )
);

CREATE INDEX idx_er_engagement_id   ON public.engagement_risks(engagement_id);
CREATE INDEX idx_er_organization_id ON public.engagement_risks(organization_id);
CREATE INDEX idx_er_section_id      ON public.engagement_risks(section_id);
CREATE INDEX idx_er_is_significant  ON public.engagement_risks(engagement_id) WHERE is_significant = true;

ALTER TABLE public.engagement_risks ENABLE ROW LEVEL SECURITY;

CREATE POLICY er_select ON public.engagement_risks
  FOR SELECT
  USING (organization_id IN (SELECT public.get_user_org_ids()));

CREATE POLICY er_insert ON public.engagement_risks
  FOR INSERT
  WITH CHECK (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

CREATE POLICY er_update ON public.engagement_risks
  FOR UPDATE
  USING (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

CREATE POLICY er_delete ON public.engagement_risks
  FOR DELETE
  USING (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

GRANT SELECT, INSERT, UPDATE, DELETE ON public.engagement_risks TO authenticated;

DROP TRIGGER IF EXISTS trg_er_set_updated_at ON public.engagement_risks;
CREATE TRIGGER trg_er_set_updated_at
  BEFORE UPDATE ON public.engagement_risks
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at_now();


-- =========================================================================
-- TABLE: engagement_risk_procedure_links (many-to-many)
-- =========================================================================
CREATE TABLE public.engagement_risk_procedure_links (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  risk_id       uuid NOT NULL REFERENCES public.engagement_risks(id) ON DELETE CASCADE,
  procedure_id  uuid NOT NULL REFERENCES public.audit_procedures(id) ON DELETE CASCADE,
  notes         text,
  created_at    timestamptz NOT NULL DEFAULT now(),

  UNIQUE (risk_id, procedure_id)
);

CREATE INDEX idx_erpl_risk_id      ON public.engagement_risk_procedure_links(risk_id);
CREATE INDEX idx_erpl_procedure_id ON public.engagement_risk_procedure_links(procedure_id);

ALTER TABLE public.engagement_risk_procedure_links ENABLE ROW LEVEL SECURITY;

-- RLS gates work through the parent risk's organization_id.
CREATE POLICY erpl_select ON public.engagement_risk_procedure_links
  FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.engagement_risks r
    WHERE r.id = risk_id
      AND r.organization_id IN (SELECT public.get_user_org_ids())
  ));

CREATE POLICY erpl_insert ON public.engagement_risk_procedure_links
  FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.engagement_risks r
    WHERE r.id = risk_id
      AND r.organization_id IN (SELECT public.get_user_org_ids())
      AND public.user_has_role_in_org(r.organization_id, 'admin')
      AND public.org_has_pro_tier(r.organization_id)
  ));

CREATE POLICY erpl_delete ON public.engagement_risk_procedure_links
  FOR DELETE
  USING (EXISTS (
    SELECT 1 FROM public.engagement_risks r
    WHERE r.id = risk_id
      AND r.organization_id IN (SELECT public.get_user_org_ids())
      AND public.user_has_role_in_org(r.organization_id, 'admin')
      AND public.org_has_pro_tier(r.organization_id)
  ));

GRANT SELECT, INSERT, DELETE ON public.engagement_risk_procedure_links TO authenticated;


-- =========================================================================
-- TABLE: engagement_risk_assessment (engagement-level summary + attestation)
-- One row per engagement, pre-seeded at engagement creation.
-- =========================================================================
CREATE TABLE public.engagement_risk_assessment (
  engagement_id                            uuid PRIMARY KEY
                                             REFERENCES public.engagements(id) ON DELETE CASCADE,
  organization_id                          uuid NOT NULL
                                             REFERENCES public.organizations(id) ON DELETE CASCADE,
  status                                   text NOT NULL DEFAULT 'draft'
                                             CHECK (status IN ('draft','confirmed')),

  -- Attestations (all 4 required when status='confirmed')
  isa_315_27_assertions_assessed           boolean NOT NULL DEFAULT false,
  isa_315_28_significant_risks_identified  boolean NOT NULL DEFAULT false,
  isa_315_stand_back_completed             boolean NOT NULL DEFAULT false,
  isa_330_responses_linked                 boolean NOT NULL DEFAULT false,

  confirmed_by                             uuid REFERENCES public.profiles(id),
  confirmed_at                             timestamptz,

  created_at                               timestamptz NOT NULL DEFAULT now(),
  updated_at                               timestamptz NOT NULL DEFAULT now(),

  CHECK (
    status <> 'confirmed'
    OR (
      isa_315_27_assertions_assessed           = true
      AND isa_315_28_significant_risks_identified = true
      AND isa_315_stand_back_completed         = true
      AND isa_330_responses_linked             = true
      AND confirmed_by                         IS NOT NULL
      AND confirmed_at                         IS NOT NULL
    )
  )
);

CREATE INDEX idx_era_organization_id ON public.engagement_risk_assessment(organization_id);

ALTER TABLE public.engagement_risk_assessment ENABLE ROW LEVEL SECURITY;

CREATE POLICY era_select ON public.engagement_risk_assessment
  FOR SELECT
  USING (organization_id IN (SELECT public.get_user_org_ids()));

-- INSERT is via RPC (seed_engagement_risk_assessment, SECURITY DEFINER).
-- We still allow direct INSERT for admins on Pro tier as a safety net, but
-- the seeded row should already exist before any user gets to the UI.
CREATE POLICY era_insert ON public.engagement_risk_assessment
  FOR INSERT
  WITH CHECK (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

CREATE POLICY era_update ON public.engagement_risk_assessment
  FOR UPDATE
  USING (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

GRANT SELECT, INSERT, UPDATE ON public.engagement_risk_assessment TO authenticated;

DROP TRIGGER IF EXISTS trg_era_set_updated_at ON public.engagement_risk_assessment;
CREATE TRIGGER trg_era_set_updated_at
  BEFORE UPDATE ON public.engagement_risk_assessment
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at_now();


-- =========================================================================
-- TRIGGER: prevent_orphaned_significant_risks (Copilot Q6 fix)
-- BEFORE DELETE on the junction table. Blocks deletion when the assessment
-- is confirmed AND the risk is significant. Prevents the silent-orphan
-- race where a procedure deletion CASCADEs the junction row and breaks
-- the ISA 330.21 linkage invariant.
-- =========================================================================
CREATE OR REPLACE FUNCTION public.prevent_orphaned_significant_risks()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_eng_id      uuid;
  v_significant boolean;
  v_confirmed   boolean;
BEGIN
  SELECT r.engagement_id, r.is_significant
    INTO v_eng_id, v_significant
    FROM public.engagement_risks r
   WHERE r.id = OLD.risk_id;

  IF NOT v_significant THEN
    RETURN OLD;
  END IF;

  SELECT (status = 'confirmed') INTO v_confirmed
    FROM public.engagement_risk_assessment
   WHERE engagement_id = v_eng_id;

  IF v_confirmed THEN
    RAISE EXCEPTION
      'Cannot delete procedure link: risk assessment is confirmed and this is a significant risk. Unconfirm the risk assessment first (Risk Assessment tab -> Revise).';
  END IF;

  RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_orphaned_significant_risks ON public.engagement_risk_procedure_links;
CREATE TRIGGER trg_prevent_orphaned_significant_risks
  BEFORE DELETE ON public.engagement_risk_procedure_links
  FOR EACH ROW EXECUTE FUNCTION public.prevent_orphaned_significant_risks();


-- =========================================================================
-- RPC: seed_engagement_risk_assessment
-- Idempotent. Called from dashboard.html at engagement creation, alongside
-- seedSectionsForEngagement. Pre-seeds the assessment row so it exists
-- from day 1 (simpler invariant; avoids AFTER-INSERT trigger).
-- =========================================================================
CREATE OR REPLACE FUNCTION public.seed_engagement_risk_assessment(
  p_engagement_id   uuid,
  p_organization_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE user_id = auth.uid() AND organization_id = p_organization_id
  ) THEN
    RAISE EXCEPTION 'seed_engagement_risk_assessment: caller is not a member of organization %', p_organization_id;
  END IF;

  INSERT INTO public.engagement_risk_assessment (engagement_id, organization_id, status)
  VALUES (p_engagement_id, p_organization_id, 'draft')
  ON CONFLICT (engagement_id) DO NOTHING;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.seed_engagement_risk_assessment(uuid, uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.seed_engagement_risk_assessment(uuid, uuid) TO authenticated;


-- =========================================================================
-- RPC: seed_presumed_fraud_risks
-- Per ISA 240.26 + 240.31, create two mandatory significant risks on
-- engagement creation:
--   - Revenue Recognition (rebuttable per 240.26)
--   - Management Override of Controls (non-rebuttable per 240.31)
-- Called from dashboard.html after sections are seeded. Idempotent: if
-- a Revenue section doesn't exist, the revenue risk is skipped silently.
-- Mgmt override is always inserted (no section dependency — uses the first
-- engagement section as a host, or skips if no sections exist).
-- =========================================================================
CREATE OR REPLACE FUNCTION public.seed_presumed_fraud_risks(
  p_engagement_id   uuid,
  p_organization_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_revenue_section_id  uuid;
  v_first_section_id    uuid;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE user_id = auth.uid() AND organization_id = p_organization_id
  ) THEN
    RAISE EXCEPTION 'seed_presumed_fraud_risks: caller is not a member of organization %', p_organization_id;
  END IF;

  IF NOT public.org_has_pro_tier(p_organization_id) THEN
    -- Risk Assessment is Pro-only; skip silently for Essentials.
    RETURN;
  END IF;

  -- Find a Revenue section (typical names: Revenue, Sales, Income).
  SELECT id INTO v_revenue_section_id
  FROM public.audit_sections
  WHERE engagement_id = p_engagement_id
    AND (LOWER(name) LIKE '%revenue%' OR LOWER(name) LIKE '%sales%' OR LOWER(name) = 'income')
  ORDER BY sort_order NULLS LAST, name
  LIMIT 1;

  -- Find the first available section for the mgmt-override risk to live on.
  SELECT id INTO v_first_section_id
  FROM public.audit_sections
  WHERE engagement_id = p_engagement_id
  ORDER BY sort_order NULLS LAST, name
  LIMIT 1;

  -- 1. Revenue Recognition (ISA 240.26 — presumed, rebuttable)
  IF v_revenue_section_id IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM public.engagement_risks
       WHERE engagement_id = p_engagement_id
         AND section_id    = v_revenue_section_id
         AND is_locked_presumed = true
         AND source        = 'fraud'
     ) THEN
    INSERT INTO public.engagement_risks (
      engagement_id, organization_id, section_id,
      assertion, risk_description, source,
      inherent_rating, control_rating, combined_rating,
      is_significant, significant_rationale,
      overall_response, is_locked_presumed,
      created_by
    ) VALUES (
      p_engagement_id, p_organization_id, v_revenue_section_id,
      'cutoff',
      'Improper revenue recognition (fraud risk presumed under ISA 240.26). Risk that revenue is recognised in the wrong period or through fictitious transactions, manipulation of accounting estimates, or improper application of accounting policies to inflate earnings or meet targets.',
      'fraud',
      'high', 'medium', 'high',
      true,
      'Presumed significant fraud risk per ISA 240.26 (revenue recognition). Rebut with explicit rationale + admin approval only if the specific circumstances of this engagement (e.g., simple cash-basis service business with no targets / no estimates) genuinely render the presumption inapplicable.',
      'Apply elevated professional skepticism, increased substantive testing of revenue transactions (especially near period-end), confirmation of receivables, cut-off testing, journal entry analysis for unusual revenue postings.',
      true,
      auth.uid()
    );
  END IF;

  -- 2. Management Override of Controls (ISA 240.31 — mandatory, non-rebuttable)
  IF v_first_section_id IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM public.engagement_risks
       WHERE engagement_id = p_engagement_id
         AND source        = 'management_override'
         AND is_locked_presumed = true
     ) THEN
    INSERT INTO public.engagement_risks (
      engagement_id, organization_id, section_id,
      assertion, risk_description, source,
      inherent_rating, control_rating, combined_rating,
      is_significant, significant_rationale,
      overall_response, is_locked_presumed,
      created_by
    ) VALUES (
      p_engagement_id, p_organization_id, v_first_section_id,
      'accuracy',
      'Management override of controls (mandatory fraud risk per ISA 240.31). Risk that management, in a unique position to perpetrate fraud, overrides controls that otherwise appear to be operating effectively — through inappropriate journal entries, biased accounting estimates, or unusual transactions.',
      'management_override',
      'high', 'high', 'high',
      true,
      'Mandatory non-rebuttable significant risk per ISA 240.31 — applies to every audit regardless of entity characteristics.',
      'Test the appropriateness of journal entries and other adjustments. Review accounting estimates for biases (look-back analysis). Evaluate the business rationale for significant unusual transactions (ISA 240.32-33).',
      true,
      auth.uid()
    );
  END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.seed_presumed_fraud_risks(uuid, uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.seed_presumed_fraud_risks(uuid, uuid) TO authenticated;


-- =========================================================================
-- RPC: confirm_risk_assessment
-- Validates the register, then atomic UPDATE to confirmed. CHECK constraint
-- enforces attestations + stamps.
-- Validation: every is_significant risk MUST have ≥1 linked procedure
-- (ISA 330.21). Non-significant unlinked risks are NOT blocked here — the
-- UI surfaces them as a soft warning before this RPC is called.
-- =========================================================================
CREATE OR REPLACE FUNCTION public.confirm_risk_assessment(
  p_engagement_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id           uuid;
  v_orphan_count     int;
  v_total_risks      int;
BEGIN
  SELECT organization_id INTO v_org_id
  FROM public.engagement_risk_assessment
  WHERE engagement_id = p_engagement_id;

  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'confirm_risk_assessment: no assessment row exists for engagement %', p_engagement_id;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE user_id = auth.uid() AND organization_id = v_org_id
  ) THEN
    RAISE EXCEPTION 'confirm_risk_assessment: caller is not a member of organization %', v_org_id;
  END IF;

  IF NOT public.user_has_role_in_org(v_org_id, 'admin') THEN
    RAISE EXCEPTION 'confirm_risk_assessment: caller must be an admin in organization %', v_org_id;
  END IF;

  IF NOT public.org_has_pro_tier(v_org_id) THEN
    RAISE EXCEPTION 'confirm_risk_assessment: organization % is not on Pro tier', v_org_id;
  END IF;

  -- Must have at least one risk
  SELECT COUNT(*) INTO v_total_risks
  FROM public.engagement_risks
  WHERE engagement_id = p_engagement_id;
  IF v_total_risks = 0 THEN
    RAISE EXCEPTION 'confirm_risk_assessment: at least one risk must be identified before confirmation';
  END IF;

  -- Every significant risk must have ≥1 linked procedure (ISA 330.21)
  SELECT COUNT(*) INTO v_orphan_count
  FROM public.engagement_risks r
  WHERE r.engagement_id = p_engagement_id
    AND r.is_significant = true
    AND NOT EXISTS (
      SELECT 1 FROM public.engagement_risk_procedure_links l
      WHERE l.risk_id = r.id
    );
  IF v_orphan_count > 0 THEN
    RAISE EXCEPTION 'confirm_risk_assessment: % significant risk(s) have no linked procedures. ISA 330.21 requires responsive procedures for every significant risk.', v_orphan_count;
  END IF;

  UPDATE public.engagement_risk_assessment
  SET status       = 'confirmed',
      confirmed_by = auth.uid(),
      confirmed_at = now()
  WHERE engagement_id = p_engagement_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.confirm_risk_assessment(uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.confirm_risk_assessment(uuid) TO authenticated;


-- =========================================================================
-- RPC: unconfirm_risk_assessment
-- Reverses confirmation so partner can edit risks post-confirmation.
-- Risks themselves persist; only the attestation toggles. activity_log
-- captures the unconfirm event.
-- =========================================================================
CREATE OR REPLACE FUNCTION public.unconfirm_risk_assessment(
  p_engagement_id uuid
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
  FROM public.engagement_risk_assessment
  WHERE engagement_id = p_engagement_id;

  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'unconfirm_risk_assessment: no assessment row exists for engagement %', p_engagement_id;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE user_id = auth.uid() AND organization_id = v_org_id
  ) THEN
    RAISE EXCEPTION 'unconfirm_risk_assessment: caller is not a member of organization %', v_org_id;
  END IF;

  IF NOT public.user_has_role_in_org(v_org_id, 'admin') THEN
    RAISE EXCEPTION 'unconfirm_risk_assessment: caller must be an admin in organization %', v_org_id;
  END IF;

  UPDATE public.engagement_risk_assessment
  SET status       = 'draft',
      confirmed_by = NULL,
      confirmed_at = NULL
  WHERE engagement_id = p_engagement_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.unconfirm_risk_assessment(uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.unconfirm_risk_assessment(uuid) TO authenticated;


-- =========================================================================
-- RPC: rebut_revenue_presumption
-- Admin rebuts ISA 240.26 revenue fraud presumption with explicit
-- rationale. Sets presumption_rebutted=true, stamps approver + timestamp,
-- and unsets is_significant. Only valid for source='fraud' + is_locked_presumed.
-- Management override (source='management_override') cannot be rebutted
-- (enforced by the table CHECK).
-- =========================================================================
CREATE OR REPLACE FUNCTION public.rebut_revenue_presumption(
  p_risk_id   uuid,
  p_rationale text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id    uuid;
  v_source    text;
  v_locked    boolean;
BEGIN
  SELECT organization_id, source, is_locked_presumed
    INTO v_org_id, v_source, v_locked
    FROM public.engagement_risks
   WHERE id = p_risk_id;

  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'rebut_revenue_presumption: risk % not found', p_risk_id;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE user_id = auth.uid() AND organization_id = v_org_id
  ) THEN
    RAISE EXCEPTION 'rebut_revenue_presumption: caller is not a member of organization %', v_org_id;
  END IF;

  IF NOT public.user_has_role_in_org(v_org_id, 'admin') THEN
    RAISE EXCEPTION 'rebut_revenue_presumption: caller must be an admin';
  END IF;

  IF NOT public.org_has_pro_tier(v_org_id) THEN
    RAISE EXCEPTION 'rebut_revenue_presumption: organization is not on Pro tier';
  END IF;

  IF v_source = 'management_override' THEN
    RAISE EXCEPTION 'rebut_revenue_presumption: ISA 240.31 management override is non-rebuttable';
  END IF;

  IF NOT v_locked THEN
    RAISE EXCEPTION 'rebut_revenue_presumption: rebuttal only applies to ISA 240 presumed risks';
  END IF;

  IF p_rationale IS NULL OR LENGTH(TRIM(p_rationale)) < 20 THEN
    RAISE EXCEPTION 'rebut_revenue_presumption: rationale must be at least 20 characters explaining why the presumption is inapplicable';
  END IF;

  UPDATE public.engagement_risks
  SET presumption_rebutted    = true,
      rebuttal_rationale      = p_rationale,
      rebuttal_approved_by    = auth.uid(),
      rebuttal_approved_at    = now(),
      is_significant          = false,
      significant_rationale   = NULL
  WHERE id = p_risk_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.rebut_revenue_presumption(uuid, text) FROM public;
GRANT  EXECUTE ON FUNCTION public.rebut_revenue_presumption(uuid, text) TO authenticated;
