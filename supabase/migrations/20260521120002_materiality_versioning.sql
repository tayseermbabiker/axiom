-- Sprint 3 (post-review) — Materiality versioning per ISA 320.12
--
-- Three-AI synthesis (Perplexity + Copilot + claude.ai) converged on
-- versioned materiality as THE #1 ISA 320 inspection gap for small firms.
-- "Edit + activity log" is too weak: inspectors need to see planning
-- materiality vs revised materiality + reason for change, plus the
-- impact on already-classified findings.
--
-- This migration adds a versioned workpaper alongside the existing
-- engagements.materiality_* snapshot columns (kept for legacy reads).
-- On approve of a new version, we copy the active fields back to
-- engagements.materiality_* so risk assessment / completion memo /
-- findings keep working without a deeper refactor.
--
-- Also adds:
--  - Specific materiality items child table (ISA 320.10, optional)
--  - Qualitative considerations checklist (ISA 320.A1)
--  - Benchmark selection rationale + period flag (ISA 320.A4)
--  - Performance materiality rationale dropdown
--  - Reason-for-revision (required v2+) + strategy-reviewed checkbox
--    (ISA 320.13)
--
-- Auto-migration at the bottom: every engagement that has a non-null
-- engagements.materiality_overall gets a v1 = approved row created so
-- partners aren't forced to re-enter on existing engagements.

-- =========================================================================
-- TABLE: engagement_materiality_versions (parent versioned record)
-- =========================================================================
CREATE TABLE public.engagement_materiality_versions (
  id                                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  engagement_id                     uuid NOT NULL
                                      REFERENCES public.engagements(id) ON DELETE CASCADE,
  organization_id                   uuid NOT NULL
                                      REFERENCES public.organizations(id) ON DELETE CASCADE,

  -- Versioning (same pattern as engagement_letters / engagement_audit_strategies)
  version_label                     text,
  is_superseded                     boolean NOT NULL DEFAULT false,
  superseded_at                     timestamptz,
  superseded_by                     uuid REFERENCES public.profiles(id),

  -- Status
  status                            text NOT NULL DEFAULT 'draft'
                                      CHECK (status IN ('draft','approved')),

  -- Benchmark
  benchmark                         text  CHECK (benchmark IS NULL OR benchmark IN ('pbt','revenue','assets','equity','other')),
  benchmark_other_label             text,
  benchmark_amount                  numeric,
  benchmark_selection_reason        text  CHECK (benchmark_selection_reason IS NULL OR benchmark_selection_reason IN ('profit_based','asset_based','revenue_driven','volatile_profits','other')),
  benchmark_selection_other_text    text,

  -- Benchmark period flag (ISA 320.A4 — abnormal years)
  benchmark_period                  text  CHECK (benchmark_period IS NULL OR benchmark_period IN ('current','normalized','prior','other')) DEFAULT 'current',
  benchmark_period_other_text       text,
  benchmark_period_reason           text,

  -- Calculations
  percentage_applied                numeric,
  overall_materiality               numeric,
  performance_materiality_pct       numeric  DEFAULT 75,
  performance_materiality_amount    numeric,
  performance_materiality_reason    text  CHECK (performance_materiality_reason IS NULL OR performance_materiality_reason IN ('no_history','prior_misstatements','first_year','other')),
  performance_materiality_other_text text,
  trivial_pct                       numeric  DEFAULT 5,
  trivial_amount                    numeric,

  -- Qualitative considerations (ISA 320.A1 checklist)
  qual_regulatory_sensitivity       boolean NOT NULL DEFAULT false,
  qual_covenant_compliance          boolean NOT NULL DEFAULT false,
  qual_fraud_risk_indicators        boolean NOT NULL DEFAULT false,
  qual_sensitive_disclosures        boolean NOT NULL DEFAULT false,
  qual_mgmt_compensation_impact     boolean NOT NULL DEFAULT false,
  qual_key_ratios_trends            boolean NOT NULL DEFAULT false,
  qual_other_text                   text,

  -- Specific materiality toggle (ISA 320.10)
  has_specific_materiality          boolean NOT NULL DEFAULT false,

  -- Free-form rationale (existing field, carried into versioning)
  rationale                         text,

  -- Revision tracking (v2+ requires reason)
  reason_for_revision               text,

  -- Strategy reassessment trigger (ISA 320.13, only on revision)
  strategy_reviewed_on_revision     boolean,
  strategy_reviewed_date            date,

  -- Approval stamps
  approved_by                       uuid REFERENCES public.profiles(id),
  approved_at                       timestamptz,

  created_by                        uuid REFERENCES public.profiles(id),
  created_at                        timestamptz NOT NULL DEFAULT now(),
  updated_at                        timestamptz NOT NULL DEFAULT now(),

  -- Approval integrity: approved requires the basic fields + stamps
  CHECK (
    status <> 'approved'
    OR (
      benchmark               IS NOT NULL
      AND benchmark_amount    IS NOT NULL
      AND percentage_applied  IS NOT NULL
      AND overall_materiality IS NOT NULL
      AND approved_by         IS NOT NULL
      AND approved_at         IS NOT NULL
    )
  )
);

CREATE UNIQUE INDEX idx_emv_one_active
  ON public.engagement_materiality_versions(engagement_id)
  WHERE is_superseded = false;

CREATE INDEX idx_emv_engagement_id   ON public.engagement_materiality_versions(engagement_id);
CREATE INDEX idx_emv_organization_id ON public.engagement_materiality_versions(organization_id);

ALTER TABLE public.engagement_materiality_versions ENABLE ROW LEVEL SECURITY;

-- Read open to org members; write gated to admin + Pro (matches Audit Strategy)
CREATE POLICY emv_select ON public.engagement_materiality_versions
  FOR SELECT
  USING (organization_id IN (SELECT public.get_user_org_ids()));

CREATE POLICY emv_insert ON public.engagement_materiality_versions
  FOR INSERT
  WITH CHECK (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

CREATE POLICY emv_update ON public.engagement_materiality_versions
  FOR UPDATE
  USING (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

GRANT SELECT, INSERT, UPDATE ON public.engagement_materiality_versions TO authenticated;

DROP TRIGGER IF EXISTS trg_emv_set_updated_at ON public.engagement_materiality_versions;
CREATE TRIGGER trg_emv_set_updated_at
  BEFORE UPDATE ON public.engagement_materiality_versions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at_now();


-- =========================================================================
-- TABLE: engagement_specific_materiality_items (child of versioned record)
-- ISA 320.10 — lower materiality for particular classes/balances/disclosures.
-- Created per-version so revisions can have different specific items.
-- =========================================================================
CREATE TABLE public.engagement_specific_materiality_items (
  id                       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  materiality_version_id   uuid NOT NULL
                             REFERENCES public.engagement_materiality_versions(id) ON DELETE CASCADE,
  class_or_account         text NOT NULL,
  specific_amount          numeric NOT NULL,
  rationale                text,
  sort_order               integer,
  created_at               timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_esmi_version_id ON public.engagement_specific_materiality_items(materiality_version_id);

ALTER TABLE public.engagement_specific_materiality_items ENABLE ROW LEVEL SECURITY;

-- RLS gates work through the parent version's organization_id.
CREATE POLICY esmi_select ON public.engagement_specific_materiality_items
  FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.engagement_materiality_versions v
    WHERE v.id = materiality_version_id
      AND v.organization_id IN (SELECT public.get_user_org_ids())
  ));

CREATE POLICY esmi_insert ON public.engagement_specific_materiality_items
  FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.engagement_materiality_versions v
    WHERE v.id = materiality_version_id
      AND v.organization_id IN (SELECT public.get_user_org_ids())
      AND public.user_has_role_in_org(v.organization_id, 'admin')
      AND public.org_has_pro_tier(v.organization_id)
  ));

CREATE POLICY esmi_update ON public.engagement_specific_materiality_items
  FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM public.engagement_materiality_versions v
    WHERE v.id = materiality_version_id
      AND v.organization_id IN (SELECT public.get_user_org_ids())
      AND public.user_has_role_in_org(v.organization_id, 'admin')
      AND public.org_has_pro_tier(v.organization_id)
  ));

CREATE POLICY esmi_delete ON public.engagement_specific_materiality_items
  FOR DELETE
  USING (EXISTS (
    SELECT 1 FROM public.engagement_materiality_versions v
    WHERE v.id = materiality_version_id
      AND v.organization_id IN (SELECT public.get_user_org_ids())
      AND public.user_has_role_in_org(v.organization_id, 'admin')
      AND public.org_has_pro_tier(v.organization_id)
  ));

GRANT SELECT, INSERT, UPDATE, DELETE ON public.engagement_specific_materiality_items TO authenticated;


-- =========================================================================
-- RPC: approve_materiality
-- Single-UPDATE: stamps approved_by + approved_at + status='approved'.
-- Then copies key fields back to engagements.materiality_* for legacy reads
-- (risk assessment, completion memo, findings still read from there).
-- =========================================================================
CREATE OR REPLACE FUNCTION public.approve_materiality(
  p_materiality_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id uuid;
  v_eng_id uuid;
  v_row    public.engagement_materiality_versions%ROWTYPE;
BEGIN
  SELECT * INTO v_row
  FROM public.engagement_materiality_versions
  WHERE id = p_materiality_id AND is_superseded = false;

  IF v_row.id IS NULL THEN
    RAISE EXCEPTION 'approve_materiality: materiality % not found or already superseded', p_materiality_id;
  END IF;

  v_org_id := v_row.organization_id;
  v_eng_id := v_row.engagement_id;

  IF NOT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE user_id = auth.uid() AND organization_id = v_org_id
  ) THEN
    RAISE EXCEPTION 'approve_materiality: caller is not a member of organization %', v_org_id;
  END IF;

  IF NOT public.user_has_role_in_org(v_org_id, 'admin') THEN
    RAISE EXCEPTION 'approve_materiality: caller must be an admin in organization %', v_org_id;
  END IF;

  IF NOT public.org_has_pro_tier(v_org_id) THEN
    RAISE EXCEPTION 'approve_materiality: organization % is not on Pro tier', v_org_id;
  END IF;

  -- Approve the version
  UPDATE public.engagement_materiality_versions
  SET status      = 'approved',
      approved_by = auth.uid(),
      approved_at = now()
  WHERE id = p_materiality_id;

  -- Mirror key fields to engagements.materiality_* for legacy reads
  UPDATE public.engagements
  SET materiality_benchmark   = v_row.benchmark,
      materiality_amount      = v_row.benchmark_amount,
      materiality_pct         = v_row.percentage_applied,
      materiality_perf_pct    = v_row.performance_materiality_pct,
      materiality_overall     = v_row.overall_materiality,
      materiality_performance = v_row.performance_materiality_amount,
      materiality_trivial     = v_row.trivial_amount,
      materiality_trivial_pct = v_row.trivial_pct,
      materiality_rationale   = v_row.rationale
  WHERE id = v_eng_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.approve_materiality(uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.approve_materiality(uuid) TO authenticated;


-- =========================================================================
-- RPC: revise_materiality
-- Supersede the active approved row and create a fresh draft carrying all
-- narrative + qualitative + specific-item fields forward. Resets approval.
-- Reason for revision is REQUIRED for the new draft to be approved later
-- (enforced UI-side; DB stores the field as nullable for the draft state).
--
-- SELECT * INTO v_old + explicit-named-column INSERT (drift-proof pattern
-- proven on revise_audit_strategy and revise_engagement_letter).
-- =========================================================================
CREATE OR REPLACE FUNCTION public.revise_materiality(
  p_engagement_id   uuid,
  p_organization_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_old    public.engagement_materiality_versions%ROWTYPE;
  v_new_id uuid;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE user_id = auth.uid() AND organization_id = p_organization_id
  ) THEN
    RAISE EXCEPTION 'revise_materiality: caller is not a member of organization %', p_organization_id;
  END IF;

  IF NOT public.user_has_role_in_org(p_organization_id, 'admin') THEN
    RAISE EXCEPTION 'revise_materiality: caller must be an admin in organization %', p_organization_id;
  END IF;

  IF NOT public.org_has_pro_tier(p_organization_id) THEN
    RAISE EXCEPTION 'revise_materiality: organization % is not on Pro tier', p_organization_id;
  END IF;

  SELECT * INTO v_old
  FROM public.engagement_materiality_versions
  WHERE engagement_id = p_engagement_id AND is_superseded = false
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'revise_materiality: no active materiality exists for engagement %', p_engagement_id;
  END IF;

  -- Supersede prior
  UPDATE public.engagement_materiality_versions
  SET is_superseded = true,
      superseded_at = now(),
      superseded_by = auth.uid()
  WHERE id = v_old.id;

  -- Insert new draft. Carry forward all content + qualitative fields.
  -- Reset: id, is_superseded, status, approval stamps, reason_for_revision,
  -- strategy_reviewed_* (these are per-revision).
  v_new_id := gen_random_uuid();
  INSERT INTO public.engagement_materiality_versions (
    id, engagement_id, organization_id, status,
    benchmark, benchmark_other_label, benchmark_amount,
    benchmark_selection_reason, benchmark_selection_other_text,
    benchmark_period, benchmark_period_other_text, benchmark_period_reason,
    percentage_applied, overall_materiality,
    performance_materiality_pct, performance_materiality_amount,
    performance_materiality_reason, performance_materiality_other_text,
    trivial_pct, trivial_amount,
    qual_regulatory_sensitivity, qual_covenant_compliance, qual_fraud_risk_indicators,
    qual_sensitive_disclosures, qual_mgmt_compensation_impact, qual_key_ratios_trends,
    qual_other_text,
    has_specific_materiality,
    rationale,
    created_by
  ) VALUES (
    v_new_id, p_engagement_id, p_organization_id, 'draft',
    v_old.benchmark, v_old.benchmark_other_label, v_old.benchmark_amount,
    v_old.benchmark_selection_reason, v_old.benchmark_selection_other_text,
    v_old.benchmark_period, v_old.benchmark_period_other_text, v_old.benchmark_period_reason,
    v_old.percentage_applied, v_old.overall_materiality,
    v_old.performance_materiality_pct, v_old.performance_materiality_amount,
    v_old.performance_materiality_reason, v_old.performance_materiality_other_text,
    v_old.trivial_pct, v_old.trivial_amount,
    v_old.qual_regulatory_sensitivity, v_old.qual_covenant_compliance, v_old.qual_fraud_risk_indicators,
    v_old.qual_sensitive_disclosures, v_old.qual_mgmt_compensation_impact, v_old.qual_key_ratios_trends,
    v_old.qual_other_text,
    v_old.has_specific_materiality,
    v_old.rationale,
    auth.uid()
  );

  -- Carry specific-materiality items forward (if any)
  INSERT INTO public.engagement_specific_materiality_items (
    materiality_version_id, class_or_account, specific_amount, rationale, sort_order
  )
  SELECT
    v_new_id, class_or_account, specific_amount, rationale, sort_order
  FROM public.engagement_specific_materiality_items
  WHERE materiality_version_id = v_old.id;

  RETURN v_new_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.revise_materiality(uuid, uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.revise_materiality(uuid, uuid) TO authenticated;


-- =========================================================================
-- ONE-TIME AUTO-MIGRATION: existing engagements with materiality set get a
-- v1 = approved row created automatically. Idempotent — uses NOT EXISTS
-- check so re-running won't duplicate. SECURITY DEFINER not needed since
-- this runs at migration time as the superuser.
-- =========================================================================
DO $migrate$
DECLARE
  e RECORD;
BEGIN
  FOR e IN
    SELECT id, organization_id, materiality_benchmark, materiality_amount,
           materiality_pct, materiality_perf_pct, materiality_overall,
           materiality_performance, materiality_trivial, materiality_trivial_pct,
           materiality_rationale
    FROM public.engagements
    WHERE materiality_overall IS NOT NULL
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM public.engagement_materiality_versions
      WHERE engagement_id = e.id
    ) THEN
      INSERT INTO public.engagement_materiality_versions (
        engagement_id, organization_id, status,
        benchmark, benchmark_amount,
        percentage_applied, overall_materiality,
        performance_materiality_pct, performance_materiality_amount,
        trivial_pct, trivial_amount,
        rationale,
        approved_at,
        created_at, updated_at
      ) VALUES (
        e.id, e.organization_id, 'approved',
        e.materiality_benchmark, e.materiality_amount,
        e.materiality_pct, e.materiality_overall,
        e.materiality_perf_pct, e.materiality_performance,
        e.materiality_trivial_pct, e.materiality_trivial,
        e.materiality_rationale,
        now(),
        now(), now()
      );
    END IF;
  END LOOP;
END;
$migrate$;
