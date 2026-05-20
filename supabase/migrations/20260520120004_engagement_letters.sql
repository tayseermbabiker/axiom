-- Sprint 2 — Engagement Letter workpaper (ISA 210).
--
-- Versioned model: multiple rows per engagement allowed, partial unique index
-- enforces at most one active (non-superseded) letter at a time. Revising the
-- letter mid-engagement (e.g., scope change) creates a new active row and
-- supersedes the prior. Past versions remain queryable for inspection per
-- ISA 210.13 and ISA 230 documentation-of-changes principles.
--
-- Schema design verified upfront with Perplexity (ISA research) + Copilot
-- (code review). Five discrete ISA 210.10 attestations rather than one
-- combined; expanded field set covers what inspectors typically check beyond
-- the ISA 210.10 minimums (audit period, fees basis, other reporting
-- obligations). CHECK constraint on status='signed' enforces minimum
-- evidence: signed_date + file + letter_date + signatory.
--
-- File storage: reuses the existing 'fs-documents' bucket with sub-path:
--   {organization_id}/{engagement_id}/engagement-letter/{letter_id}.{ext}
-- Existing storage RLS keys on foldername[1] = organization_id and still
-- covers this path without changes.

CREATE TABLE public.engagement_letters (
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
                                      CHECK (status IN ('draft','signed')),

  -- Letter metadata
  letter_date                       date,
  signed_date                       date,
  client_signatory_name             text,
  client_signatory_role             text,

  -- Audit scope
  reporting_framework               text,
  audit_period_start                date,
  audit_period_end                  date,

  -- Additional terms inspectors typically check (per ISA 210 application material)
  fees_basis                        text,
  other_reporting_obligations       text,
  other_terms                       text,

  -- ISA 210.10 minimum required elements — discrete attestations
  isa_210_objective_scope           boolean NOT NULL DEFAULT false,
  isa_210_auditor_responsibilities  boolean NOT NULL DEFAULT false,
  isa_210_mgmt_responsibilities     boolean NOT NULL DEFAULT false,
  isa_210_framework_identified      boolean NOT NULL DEFAULT false,
  isa_210_report_form_referenced    boolean NOT NULL DEFAULT false,

  -- Optional signed PDF
  file_name                         text,
  file_path                         text,
  file_size_bytes                   bigint,
  file_sha256                       text,
  mime_type                         text,

  created_by                        uuid REFERENCES public.profiles(id),
  created_at                        timestamptz NOT NULL DEFAULT now(),
  updated_at                        timestamptz NOT NULL DEFAULT now(),

  -- Status integrity: signed requires the four minimum-evidence fields
  CHECK (
    status <> 'signed'
    OR (
      signed_date           IS NOT NULL
      AND file_path         IS NOT NULL
      AND letter_date       IS NOT NULL
      AND client_signatory_name IS NOT NULL
    )
  )
);

-- Partial unique index: at most one active (non-superseded) letter per engagement
CREATE UNIQUE INDEX idx_el_one_active
  ON public.engagement_letters(engagement_id)
  WHERE is_superseded = false;

CREATE INDEX idx_el_engagement_id   ON public.engagement_letters(engagement_id);
CREATE INDEX idx_el_organization_id ON public.engagement_letters(organization_id);

ALTER TABLE public.engagement_letters ENABLE ROW LEVEL SECURITY;

-- Read open to org members; write gated to admin + Pro.
CREATE POLICY el_select ON public.engagement_letters
  FOR SELECT
  USING (organization_id IN (SELECT public.get_user_org_ids()));

CREATE POLICY el_insert ON public.engagement_letters
  FOR INSERT
  WITH CHECK (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

CREATE POLICY el_update ON public.engagement_letters
  FOR UPDATE
  USING (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

GRANT SELECT, INSERT, UPDATE ON public.engagement_letters TO authenticated;

-- DB-managed updated_at (re-uses generic trigger from migration 003).
DROP TRIGGER IF EXISTS trg_el_set_updated_at ON public.engagement_letters;
CREATE TRIGGER trg_el_set_updated_at
  BEFORE UPDATE ON public.engagement_letters
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at_now();

-- =========================================================================
-- RPC: revise_engagement_letter
-- Supersede the currently-active letter and create a fresh draft, copying
-- the prior letter's metadata as starting point for the revision. Returns
-- the new letter id. SECURITY DEFINER + Pro/admin checks inline.
-- =========================================================================
CREATE OR REPLACE FUNCTION public.revise_engagement_letter(
  p_engagement_id   uuid,
  p_organization_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_prior public.engagement_letters%ROWTYPE;
  v_new_id uuid;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE user_id = auth.uid() AND organization_id = p_organization_id
  ) THEN
    RAISE EXCEPTION 'revise_engagement_letter: caller is not a member of organization %', p_organization_id;
  END IF;

  IF NOT public.user_has_role_in_org(p_organization_id, 'admin') THEN
    RAISE EXCEPTION 'revise_engagement_letter: caller must be an admin in organization %', p_organization_id;
  END IF;

  IF NOT public.org_has_pro_tier(p_organization_id) THEN
    RAISE EXCEPTION 'revise_engagement_letter: organization % is not on Pro tier', p_organization_id;
  END IF;

  SELECT * INTO v_prior
  FROM public.engagement_letters
  WHERE engagement_id = p_engagement_id AND is_superseded = false
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'revise_engagement_letter: no active letter exists for engagement %', p_engagement_id;
  END IF;

  -- Supersede prior
  UPDATE public.engagement_letters
  SET is_superseded = true,
      superseded_at = now(),
      superseded_by = auth.uid()
  WHERE id = v_prior.id;

  -- Insert new draft, carrying prior content as starting point.
  -- Note: file_* fields NOT carried — partner attaches the new signed PDF.
  v_new_id := gen_random_uuid();
  INSERT INTO public.engagement_letters (
    id, engagement_id, organization_id, status,
    letter_date, client_signatory_name, client_signatory_role,
    reporting_framework, audit_period_start, audit_period_end,
    fees_basis, other_reporting_obligations, other_terms,
    isa_210_objective_scope, isa_210_auditor_responsibilities,
    isa_210_mgmt_responsibilities, isa_210_framework_identified,
    isa_210_report_form_referenced,
    created_by
  ) VALUES (
    v_new_id, p_engagement_id, p_organization_id, 'draft',
    NULL, v_prior.client_signatory_name, v_prior.client_signatory_role,
    v_prior.reporting_framework, v_prior.audit_period_start, v_prior.audit_period_end,
    v_prior.fees_basis, v_prior.other_reporting_obligations, v_prior.other_terms,
    v_prior.isa_210_objective_scope, v_prior.isa_210_auditor_responsibilities,
    v_prior.isa_210_mgmt_responsibilities, v_prior.isa_210_framework_identified,
    v_prior.isa_210_report_form_referenced,
    auth.uid()
  );

  RETURN v_new_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.revise_engagement_letter(uuid, uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.revise_engagement_letter(uuid, uuid) TO authenticated;
