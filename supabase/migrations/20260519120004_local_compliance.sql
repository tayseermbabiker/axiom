-- Sprint 1 — Local Compliance custom section (20th audit section).
-- One template per organization. Procedures are COPIED (not referenced) into
-- new engagements via seed_compliance_section() so master template edits do
-- not retroactively alter in-progress engagements.
-- Jurisdiction is a free-text label entered by the firm — no Qatar/UAE/etc.
-- code logic branches on its value.

-- =========================================================================
-- TABLE: org_local_compliance_templates
-- =========================================================================
CREATE TABLE public.org_local_compliance_templates (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id     uuid NOT NULL UNIQUE
                        REFERENCES public.organizations(id) ON DELETE CASCADE,

  name                text NOT NULL DEFAULT 'Local Compliance & Regulatory',
  section_description text,
  jurisdiction        text,    -- free-text label, display only

  sort_order          int  NOT NULL DEFAULT 20,
  phase               text NOT NULL DEFAULT 'final'
                        CHECK (phase IN ('interim','final')),

  is_active           boolean NOT NULL DEFAULT true,

  created_by          uuid REFERENCES public.profiles(id),
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_olct_organization_id ON public.org_local_compliance_templates(organization_id);

ALTER TABLE public.org_local_compliance_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY olct_select ON public.org_local_compliance_templates
  FOR SELECT
  USING (organization_id IN (SELECT public.get_user_org_ids()));

-- Pro tier + admin role required to author the Local Compliance template.
-- Reading remains open to all org members so downgrade doesn't break history.
CREATE POLICY olct_insert ON public.org_local_compliance_templates
  FOR INSERT
  WITH CHECK (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

CREATE POLICY olct_update ON public.org_local_compliance_templates
  FOR UPDATE
  USING (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
  );

GRANT SELECT, INSERT, UPDATE ON public.org_local_compliance_templates TO authenticated;


-- =========================================================================
-- TABLE: org_compliance_procedures (master procedure library)
-- =========================================================================
CREATE TABLE public.org_compliance_procedures (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id     uuid NOT NULL
                    REFERENCES public.org_local_compliance_templates(id) ON DELETE CASCADE,
  organization_id uuid NOT NULL
                    REFERENCES public.organizations(id) ON DELETE CASCADE,

  description     text NOT NULL,
  procedure_type  text NOT NULL DEFAULT 'other'
                    CHECK (procedure_type IN ('test_of_detail','analytical','controls','other')),
  sort_order      int NOT NULL DEFAULT 1,
  regulatory_ref  text,

  is_active       boolean NOT NULL DEFAULT true,

  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_ocp_template_id     ON public.org_compliance_procedures(template_id);
CREATE INDEX idx_ocp_organization_id ON public.org_compliance_procedures(organization_id);
CREATE INDEX idx_ocp_sort            ON public.org_compliance_procedures(template_id, sort_order);

ALTER TABLE public.org_compliance_procedures ENABLE ROW LEVEL SECURITY;

CREATE POLICY ocp_select ON public.org_compliance_procedures
  FOR SELECT
  USING (organization_id IN (SELECT public.get_user_org_ids()));

CREATE POLICY ocp_insert ON public.org_compliance_procedures
  FOR INSERT
  WITH CHECK (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

CREATE POLICY ocp_update ON public.org_compliance_procedures
  FOR UPDATE
  USING (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
  );

GRANT SELECT, INSERT, UPDATE ON public.org_compliance_procedures TO authenticated;


-- =========================================================================
-- FUNCTION: seed_compliance_section(engagement_id, organization_id)
-- Call from the engagement-creation flow AFTER the 19 standard sections are
-- seeded by audit-templates.js. Returns the new audit_sections.id, or NULL
-- if the firm has no active Local Compliance template (engagement keeps 19 sections).
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
  -- Caller must belong to this organization
  IF NOT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE user_id = auth.uid()
      AND organization_id = p_organization_id
  ) THEN
    RAISE EXCEPTION 'seed_compliance_section: caller is not a member of organization %', p_organization_id;
  END IF;

  -- Engagement must belong to that organization
  IF NOT EXISTS (
    SELECT 1 FROM public.engagements
    WHERE id = p_engagement_id
      AND organization_id = p_organization_id
  ) THEN
    RAISE EXCEPTION 'seed_compliance_section: engagement % does not belong to organization %',
      p_engagement_id, p_organization_id;
  END IF;

  -- Find active template; if none → silently skip
  SELECT * INTO v_template
  FROM public.org_local_compliance_templates
  WHERE organization_id = p_organization_id
    AND is_active = true
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  -- Insert the 20th audit section
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

  -- Copy active master procedures into audit_procedures (snapshot, not reference)
  FOR v_proc IN
    SELECT * FROM public.org_compliance_procedures
    WHERE template_id = v_template.id
      AND is_active = true
    ORDER BY sort_order ASC
  LOOP
    INSERT INTO public.audit_procedures (
      id, section_id, description, procedure_type, sort_order
    ) VALUES (
      gen_random_uuid(),
      v_section_id,
      v_proc.description,
      v_proc.procedure_type,
      v_proc.sort_order
    );
  END LOOP;

  RETURN v_section_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.seed_compliance_section(uuid, uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.seed_compliance_section(uuid, uuid) TO authenticated;
