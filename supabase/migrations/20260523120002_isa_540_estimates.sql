-- =========================================================================
-- Sprint 4 — ISA 540 Accounting estimates (4-AI standards floor 2026-05-23)
-- =========================================================================
-- Perplexity flagged this as a UAE inspection hot spot — EoSB, NRV,
-- impairment, doubtful debts, provisions appear on nearly every file.
-- Currently buried in findings free-text; this surfaces them structurally.
--
-- Minimalist design per 4-AI synthesis: 1 table, 7 fields, add-row UI in
-- Execution. No workflow. No versioning. No risk engine. Optional link
-- to an audit section (PPE / Inventory / Provisions / Receivables) so
-- inspectors can trace estimate → testing.
--
-- See [[audexon-scope-freeze]]: no automated sensitivity engine, no
-- per-estimate sign-off chain. The estimate evaluation belongs in the
-- partner's narrative, not in tooling.

CREATE TABLE public.engagement_estimates (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  engagement_id         uuid NOT NULL
                          REFERENCES public.engagements(id) ON DELETE CASCADE,
  organization_id       uuid NOT NULL
                          REFERENCES public.organizations(id) ON DELETE CASCADE,

  -- Optional link to the section that tests this estimate (PPE / Inventory
  -- / Provisions / Receivables). SET NULL if section is deleted — the
  -- estimate documentation stands independently.
  section_id            uuid REFERENCES public.audit_sections(id) ON DELETE SET NULL,

  -- The 7 ISA 540 fields (Perplexity + Copilot converged on this set)
  estimate_name         text NOT NULL,
  method_used           text,
  key_assumptions       text,
  data_sources          text,
  sensitivity_analysis  text,
  misstatement_risk     text
                          CHECK (misstatement_risk IS NULL
                                 OR misstatement_risk IN ('low','medium','high','significant')),
  conclusion            text,

  created_by            uuid REFERENCES public.profiles(id),
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_eest_engagement_id   ON public.engagement_estimates(engagement_id);
CREATE INDEX idx_eest_organization_id ON public.engagement_estimates(organization_id);
CREATE INDEX idx_eest_section_id      ON public.engagement_estimates(section_id) WHERE section_id IS NOT NULL;

ALTER TABLE public.engagement_estimates ENABLE ROW LEVEL SECURITY;

CREATE POLICY eest_select ON public.engagement_estimates
  FOR SELECT
  USING (organization_id IN (SELECT public.get_user_org_ids()));

CREATE POLICY eest_insert ON public.engagement_estimates
  FOR INSERT
  WITH CHECK (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

CREATE POLICY eest_update ON public.engagement_estimates
  FOR UPDATE
  USING (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

CREATE POLICY eest_delete ON public.engagement_estimates
  FOR DELETE
  USING (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

GRANT SELECT, INSERT, UPDATE, DELETE ON public.engagement_estimates TO authenticated;

DROP TRIGGER IF EXISTS trg_eest_set_updated_at ON public.engagement_estimates;
CREATE TRIGGER trg_eest_set_updated_at
  BEFORE UPDATE ON public.engagement_estimates
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at_now();
