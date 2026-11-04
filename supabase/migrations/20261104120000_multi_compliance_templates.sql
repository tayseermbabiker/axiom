-- Multiple Local Compliance sections per firm (Nov 2026).
--
-- Before: one template per organization (UNIQUE organization_id) → every new
-- engagement got exactly one compliance section. Firms with clients in several
-- jurisdictions (UAE ESR + KSA Zakat + Qatar QFC) or several regulators had to
-- cram everything into one section.
--
-- After:
--   - A firm can author any number of templates (one per regime/regulator).
--   - is_active = "offered on new engagements" (pre-ticked in the picker).
--   - At engagement creation the partner ticks which templates apply.
--     seed_compliance_sections() copies each ticked template into its own
--     section (copies, not references — same as before).
--   - If the partner unticks templates that were offered, or the firm has
--     templates but none are active, a single Applicability Assessment
--     section is created naming what was not applied, so the partner
--     documents why (ISA 230 evidence trail — keeps the P6 behaviour).
--   - Admins (Pro) can delete a master template. Engagement copies are
--     unaffected because they were copied, not referenced.
--   - Default sort order moves from 20 to 22: the standard library now seeds
--     21 sections, so 20 collided with "Trial Balance, Adjustments & Lead
--     Schedules". Existing rows are left as the firm set them.

-- =========================================================================
-- 1. Drop the one-template-per-org UNIQUE constraint
-- =========================================================================
DO $$
DECLARE
  v_con text;
BEGIN
  SELECT c.conname INTO v_con
  FROM pg_constraint c
  JOIN pg_attribute a
    ON a.attrelid = c.conrelid AND a.attnum = ANY (c.conkey)
  WHERE c.conrelid = 'public.org_local_compliance_templates'::regclass
    AND c.contype = 'u'
    AND a.attname = 'organization_id'
    AND array_length(c.conkey, 1) = 1;

  IF v_con IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.org_local_compliance_templates DROP CONSTRAINT %I', v_con);
  END IF;
END $$;

ALTER TABLE public.org_local_compliance_templates
  ALTER COLUMN sort_order SET DEFAULT 22,
  ALTER COLUMN name SET DEFAULT 'Local Compliance & Regulatory';

-- =========================================================================
-- 2. DELETE policy (admin + Pro). Master procedures cascade via FK.
-- =========================================================================
DROP POLICY IF EXISTS olct_delete ON public.org_local_compliance_templates;
CREATE POLICY olct_delete ON public.org_local_compliance_templates
  FOR DELETE
  USING (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

GRANT DELETE ON public.org_local_compliance_templates TO authenticated;

-- =========================================================================
-- 3. seed_compliance_sections(engagement, org, template_ids)
--    p_template_ids NULL → every active template (used by the legacy wrapper).
--    Returns the number of sections created.
-- =========================================================================
CREATE OR REPLACE FUNCTION public.seed_compliance_sections(
  p_engagement_id   uuid,
  p_organization_id uuid,
  p_template_ids    uuid[] DEFAULT NULL
)
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_template     public.org_local_compliance_templates%ROWTYPE;
  v_proc         public.org_compliance_procedures%ROWTYPE;
  v_section_id   uuid;
  v_created      int := 0;
  v_any_template boolean;
  v_not_applied  text[] := ARRAY[]::text[];
  v_max_sort     int := 22;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE user_id = auth.uid()
      AND organization_id = p_organization_id
  ) THEN
    RAISE EXCEPTION 'seed_compliance_sections: caller is not a member of organization %', p_organization_id;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.engagements
    WHERE id = p_engagement_id
      AND organization_id = p_organization_id
  ) THEN
    RAISE EXCEPTION 'seed_compliance_sections: engagement % does not belong to organization %',
      p_engagement_id, p_organization_id;
  END IF;

  IF NOT public.org_has_pro_tier(p_organization_id) THEN
    RAISE EXCEPTION 'seed_compliance_sections: organization % is not on Pro tier', p_organization_id;
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.org_local_compliance_templates
    WHERE organization_id = p_organization_id
  ) INTO v_any_template;

  -- Firm never enabled the feature → standard sections only.
  IF NOT v_any_template THEN
    RETURN 0;
  END IF;

  FOR v_template IN
    SELECT * FROM public.org_local_compliance_templates
    WHERE organization_id = p_organization_id
      AND is_active = true
    ORDER BY sort_order ASC, created_at ASC
  LOOP
    v_max_sort := GREATEST(v_max_sort, v_template.sort_order);

    IF p_template_ids IS NOT NULL AND NOT (v_template.id = ANY (p_template_ids)) THEN
      -- Offered but unticked by the partner for this engagement.
      v_not_applied := v_not_applied || v_template.name;
      CONTINUE;
    END IF;

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

    v_created := v_created + 1;
  END LOOP;

  -- Nothing applied, or some offered templates were excluded → document it.
  IF v_created = 0 OR array_length(v_not_applied, 1) > 0 THEN
    INSERT INTO public.audit_sections (
      id, engagement_id, name, sort_order, status, phase
    ) VALUES (
      gen_random_uuid(),
      p_engagement_id,
      'Local Compliance (Applicability Assessment)',
      v_max_sort + 1,
      'not_started',
      'final'
    )
    RETURNING id INTO v_section_id;

    INSERT INTO public.audit_procedures (
      id, section_id, description, procedure_type, sort_order, risk_category
    ) VALUES (
      gen_random_uuid(),
      v_section_id,
      CASE
        WHEN array_length(v_not_applied, 1) > 0 THEN
          'The following firm compliance templates were NOT applied to this engagement: '
          || array_to_string(v_not_applied, '; ')
          || '. Partner: document why each does not apply (e.g., "N/A — entity is not in scope of this regime"), or attach an external workpaper reference. This procedure exists per ISA 230 to evidence that local-compliance applicability was considered.'
        ELSE
          'No firm compliance template is currently active. Partner: document jurisdiction-specific local-compliance applicability for this engagement (e.g., "N/A — no entity-specific regulatory regime applies"), or attach an external workpaper reference. This procedure exists per ISA 230 to evidence that local-compliance applicability was considered, even where no substantive procedures applied.'
      END,
      'other',
      1,
      'compliance'
    );

    v_created := v_created + 1;
  END IF;

  RETURN v_created;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.seed_compliance_sections(uuid, uuid, uuid[]) FROM public;
GRANT  EXECUTE ON FUNCTION public.seed_compliance_sections(uuid, uuid, uuid[]) TO authenticated;

-- =========================================================================
-- 4. Legacy wrapper — keeps browsers on a cached old dashboard.html working.
--    Applies every active template. Returns NULL (callers ignored the id).
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
BEGIN
  PERFORM public.seed_compliance_sections(p_engagement_id, p_organization_id, NULL);
  RETURN NULL;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.seed_compliance_section(uuid, uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.seed_compliance_section(uuid, uuid) TO authenticated;
