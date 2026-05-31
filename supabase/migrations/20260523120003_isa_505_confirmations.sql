-- =========================================================================
-- Sprint 4 — ISA 505 External confirmations tracker
-- (4-AI standards floor synthesis 2026-05-23).
-- =========================================================================
-- World Bank smaller-audits paper and IFAC SME ISA Guide both call out
-- confirmations as something reviewers explicitly ask for:
--   "Show me all confirmations sent, returned, exceptions, and
--    alternative procedures performed."
-- Currently buried in procedure responses as free text. Surfacing
-- structurally makes inspection prep trivial.
--
-- Minimalist design per 4-AI synthesis: 1 table, 7 fields, add-row UI.
-- No automation, no email sending, no templates. Just tracking.
--
-- CRITICAL field (Perplexity caught, Copilot's 6-field design missed):
--   alternative_procedures — ISA 505.12 requires the auditor to perform
--   alternative procedures when a confirmation is not returned. The
--   tracker must capture what was done instead.
--
-- See [[audexon-scope-freeze]]: no email integration / no automation.

CREATE TABLE public.engagement_confirmations (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  engagement_id          uuid NOT NULL
                           REFERENCES public.engagements(id) ON DELETE CASCADE,
  organization_id        uuid NOT NULL
                           REFERENCES public.organizations(id) ON DELETE CASCADE,

  -- Optional link to the section that requested this confirmation
  -- (Receivables / Cash / Payables / Legal / Related parties).
  section_id             uuid REFERENCES public.audit_sections(id) ON DELETE SET NULL,

  -- The 7 ISA 505 fields (Perplexity + Copilot converged + alternative_procedures)
  counterparty           text NOT NULL,
  confirmation_type      text NOT NULL
                           CHECK (confirmation_type IN
                             ('bank','ar','ap','legal','related_party','other')),
  sent_date              date,
  returned_date          date,
  result                 text
                           CHECK (result IS NULL
                             OR result IN ('clean','exception','no_reply','partial')),
  alternative_procedures text,
  notes                  text,

  created_by             uuid REFERENCES public.profiles(id),
  created_at             timestamptz NOT NULL DEFAULT now(),
  updated_at             timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_econf_engagement_id   ON public.engagement_confirmations(engagement_id);
CREATE INDEX idx_econf_organization_id ON public.engagement_confirmations(organization_id);
CREATE INDEX idx_econf_section_id      ON public.engagement_confirmations(section_id) WHERE section_id IS NOT NULL;

ALTER TABLE public.engagement_confirmations ENABLE ROW LEVEL SECURITY;

CREATE POLICY econf_select ON public.engagement_confirmations
  FOR SELECT
  USING (organization_id IN (SELECT public.get_user_org_ids()));

CREATE POLICY econf_insert ON public.engagement_confirmations
  FOR INSERT
  WITH CHECK (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

CREATE POLICY econf_update ON public.engagement_confirmations
  FOR UPDATE
  USING (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

CREATE POLICY econf_delete ON public.engagement_confirmations
  FOR DELETE
  USING (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

GRANT SELECT, INSERT, UPDATE, DELETE ON public.engagement_confirmations TO authenticated;

DROP TRIGGER IF EXISTS trg_econf_set_updated_at ON public.engagement_confirmations;
CREATE TRIGGER trg_econf_set_updated_at
  BEFORE UPDATE ON public.engagement_confirmations
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at_now();
