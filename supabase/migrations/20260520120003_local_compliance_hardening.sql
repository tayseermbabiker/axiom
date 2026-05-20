-- Sprint 1 verification — Local Compliance hardening + ISA 315/330 risk linkage.
-- Combines five fixes from the Perplexity + Copilot review pass:
--
--   (C1) DB-managed updated_at via BEFORE UPDATE trigger. Client clock is
--        brittle; DB now owns the timestamp.
--   (C2) Tighten UPDATE RLS to require Pro tier (consistency with INSERT).
--        Local Compliance IS the Pro layer; downgraded orgs shouldn't keep
--        editing it.
--   (C3) Defense-in-depth Pro tier check inside seed_compliance_section.
--   (P4) Add risk_category to org_compliance_procedures + audit_procedures
--        so each procedure carries ISA 315/330 risk linkage.
--   (P6) Rewrite seed_compliance_section to handle the "template inactive"
--        case explicitly — instead of silent skip, create an Applicability
--        Assessment section with a single procedure prompting the partner
--        to document why no procedures applied (ISA 230 evidence trail).

-- =========================================================================
-- (C1) Generic updated_at trigger
-- =========================================================================
CREATE OR REPLACE FUNCTION public.set_updated_at_now()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_olct_set_updated_at ON public.org_local_compliance_templates;
CREATE TRIGGER trg_olct_set_updated_at
  BEFORE UPDATE ON public.org_local_compliance_templates
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at_now();

DROP TRIGGER IF EXISTS trg_ocp_set_updated_at ON public.org_compliance_procedures;
CREATE TRIGGER trg_ocp_set_updated_at
  BEFORE UPDATE ON public.org_compliance_procedures
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at_now();

-- =========================================================================
-- (C2) Tighten UPDATE policies — require Pro tier
-- =========================================================================
DROP POLICY IF EXISTS olct_update ON public.org_local_compliance_templates;
CREATE POLICY olct_update ON public.org_local_compliance_templates
  FOR UPDATE
  USING (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

DROP POLICY IF EXISTS ocp_update ON public.org_compliance_procedures;
CREATE POLICY ocp_update ON public.org_compliance_procedures
  FOR UPDATE
  USING (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

-- =========================================================================
-- (P4) risk_category column on org_compliance_procedures + audit_procedures
-- =========================================================================
ALTER TABLE public.org_compliance_procedures
  ADD COLUMN IF NOT EXISTS risk_category text NOT NULL DEFAULT 'standard'
    CHECK (risk_category IN ('standard','compliance','significant','fraud'));

COMMENT ON COLUMN public.org_compliance_procedures.risk_category IS
  'ISA 315/330 risk linkage. standard = routine. compliance = ISA 250 local-law risk. significant = significant risk per ISA 315.27. fraud = ISA 240 fraud-risk procedure. Carried into audit_procedures.risk_category at seed time.';

-- Non-Local-Compliance procedures keep risk_category NULL (no implicit risk
-- assertion). Only seeded Local Compliance procedures get a real value.
ALTER TABLE public.audit_procedures
  ADD COLUMN IF NOT EXISTS risk_category text
    CHECK (risk_category IS NULL OR risk_category IN ('standard','compliance','significant','fraud'));

COMMENT ON COLUMN public.audit_procedures.risk_category IS
  'Mirrors org_compliance_procedures.risk_category for seeded Local Compliance procedures. NULL for the standard 19-section procedures until they get a risk dimension in a later sprint.';

-- =========================================================================
-- (C3 + P6) seed_compliance_section v2:
--   - defense-in-depth Pro tier check
--   - template inactive → still create an Applicability Assessment section
--     with a partner-prompt procedure (ISA 230 evidence trail)
--   - carry risk_category through into audit_procedures
-- =========================================================================
CREATE OR REPLACE FUNCTION public.seed_compliance_section(
  p_engagement_id   uuid,
  p_organization_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_template public.org_local_compliance_templates%ROWTYPE;
  v_section_id uuid;
  v_proc public.org_compliance_procedures%ROWTYPE;
BEGIN
  -- Membership check.
  IF NOT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE user_id = auth.uid()
      AND organization_id = p_organization_id
  ) THEN
    RAISE EXCEPTION 'seed_compliance_section: caller is not a member of organization %', p_organization_id;
  END IF;

  -- Engagement must belong to that organization.
  IF NOT EXISTS (
    SELECT 1 FROM public.engagements
    WHERE id = p_engagement_id
      AND organization_id = p_organization_id
  ) THEN
    RAISE EXCEPTION 'seed_compliance_section: engagement % does not belong to organization %',
      p_engagement_id, p_organization_id;
  END IF;

  -- C3: defense-in-depth Pro tier check inside the function.
  IF NOT public.org_has_pro_tier(p_organization_id) THEN
    RAISE EXCEPTION 'seed_compliance_section: organization % is not on Pro tier', p_organization_id;
  END IF;

  -- Find ANY template (active or not) for this org.
  SELECT * INTO v_template
  FROM public.org_local_compliance_templates
  WHERE organization_id = p_organization_id
  LIMIT 1;

  IF NOT FOUND THEN
    -- No template ever authored — firm has not enabled the feature.
    -- Silent skip is appropriate; engagement gets 19 sections.
    RETURN NULL;
  END IF;

  IF v_template.is_active THEN
    -- Normal path: copy the master procedures into the engagement.
    INSERT INTO public.audit_sections (
      id, engagement_id, name, sort_order, status, phase
    ) VALUES (
      gen_random_uuid(),
      p_engagement_id,
      v_template.name,
      v_template.sort_order,
      'not_started',
      v_template.phase
    )
    RETURNING id INTO v_section_id;

    FOR v_proc IN
      SELECT * FROM public.org_compliance_procedures
      WHERE template_id = v_template.id AND is_active = true
      ORDER BY sort_order ASC
    LOOP
      INSERT INTO public.audit_procedures (
        id, section_id, description, procedure_type, sort_order, risk_category
      ) VALUES (
        gen_random_uuid(),
        v_section_id,
        v_proc.description,
        v_proc.procedure_type,
        v_proc.sort_order,
        v_proc.risk_category
      );
    END LOOP;
  ELSE
    -- P6: Template exists but is inactive. DO NOT silently skip — leaving
    -- the engagement with no section can be read by an inspector as "the
    -- firm forgot," not "the firm assessed and concluded N/A." Instead,
    -- create a single Applicability Assessment section that documents
    -- partner consideration per ISA 230.
    INSERT INTO public.audit_sections (
      id, engagement_id, name, sort_order, status, phase
    ) VALUES (
      gen_random_uuid(),
      p_engagement_id,
      v_template.name || ' (Applicability Assessment)',
      v_template.sort_order,
      'not_started',
      v_template.phase
    )
    RETURNING id INTO v_section_id;

    INSERT INTO public.audit_procedures (
      id, section_id, description, procedure_type, sort_order, risk_category
    ) VALUES (
      gen_random_uuid(),
      v_section_id,
      'Local Compliance template is currently INACTIVE at the firm level. Partner: document jurisdiction-specific local-compliance applicability for this engagement (e.g., "N/A — no UAE/Qatar/KSA entities in scope; no entity-specific regulatory regime applies", or attach external workpaper reference). This procedure exists per ISA 230 to evidence that local-compliance applicability was considered, even where no substantive procedures applied.',
      'other',
      1,
      'compliance'
    );
  END IF;

  RETURN v_section_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.seed_compliance_section(uuid, uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.seed_compliance_section(uuid, uuid) TO authenticated;
