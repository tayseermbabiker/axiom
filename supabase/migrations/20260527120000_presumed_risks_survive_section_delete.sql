-- =========================================================================
-- 2026-05-27 — ISA 240 presumed fraud risks survive section deletion.
-- =========================================================================
-- Background: in the original schema engagement_risks.section_id was
-- declared NOT NULL REFERENCES audit_sections(id) ON DELETE CASCADE.
-- This was logically right for custom risks (delete the section → its
-- custom risks go with it) but wrong for the 2 ISA 240 presumed fraud
-- risks: those are engagement-level mandates (ISA 240.26 + 240.31) that
-- must exist on every audit regardless of which sections happen to be
-- present. Attaching them to a section was a schema convenience that
-- caused them to disappear when their host section was deleted.
--
-- Fix: section_id becomes nullable + ON DELETE SET NULL. A CHECK
-- constraint preserves the old invariant for custom risks (they must
-- have a section). A BEFORE DELETE trigger on audit_sections still
-- cascade-removes non-presumed risks, so the "custom risk dies with
-- section" behavior is unchanged. Presumed risks linger with
-- section_id = NULL until the partner re-links them via the edit modal.

-- 1. Drop the existing FK (auto-named engagement_risks_section_id_fkey)
ALTER TABLE public.engagement_risks
  DROP CONSTRAINT IF EXISTS engagement_risks_section_id_fkey;

-- 2. Allow NULL section_id (presumed risks may end up unlinked after
--    a section delete; partner re-links from the edit modal).
ALTER TABLE public.engagement_risks
  ALTER COLUMN section_id DROP NOT NULL;

-- 3. Re-add the FK with ON DELETE SET NULL.
ALTER TABLE public.engagement_risks
  ADD CONSTRAINT engagement_risks_section_id_fkey
  FOREIGN KEY (section_id) REFERENCES public.audit_sections(id) ON DELETE SET NULL;

-- 4. Preserve the old invariant for custom risks: only presumed risks
--    may have NULL section_id. Custom risks still require a section.
ALTER TABLE public.engagement_risks
  DROP CONSTRAINT IF EXISTS engagement_risks_custom_must_have_section;

ALTER TABLE public.engagement_risks
  ADD CONSTRAINT engagement_risks_custom_must_have_section
  CHECK (section_id IS NOT NULL OR is_locked_presumed = true);

-- 5. BEFORE DELETE trigger on audit_sections: remove custom risks linked
--    to the doomed section so the "custom risk dies with section"
--    behavior is unchanged. Presumed risks survive — the FK above SETs
--    NULL for them automatically.
CREATE OR REPLACE FUNCTION public.cleanup_custom_risks_on_section_delete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM public.engagement_risks
  WHERE section_id = OLD.id
    AND is_locked_presumed = false;
  RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_cleanup_custom_risks_on_section_delete ON public.audit_sections;
CREATE TRIGGER trg_cleanup_custom_risks_on_section_delete
  BEFORE DELETE ON public.audit_sections
  FOR EACH ROW
  EXECUTE FUNCTION public.cleanup_custom_risks_on_section_delete();

-- 6. Update seed_presumed_fraud_risks: the EXISTS check should not key
--    on section_id, because a presumed risk that lost its section
--    (section_id = NULL post-cascade) must still be recognised as
--    "already exists" and not duplicate-seeded on the next load.
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
  v_revenue_section_id uuid;
  v_first_section_id   uuid;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE user_id = auth.uid() AND organization_id = p_organization_id
  ) THEN
    RAISE EXCEPTION 'seed_presumed_fraud_risks: caller is not a member of organization %', p_organization_id;
  END IF;

  -- Best-effort: find a Revenue section to anchor the presumed revenue
  -- risk to. May return NULL if no Revenue-named section exists — that's
  -- OK now that section_id is nullable for presumed risks.
  SELECT id INTO v_revenue_section_id
  FROM public.audit_sections
  WHERE engagement_id = p_engagement_id
    AND name ILIKE '%revenue%'
  ORDER BY sort_order NULLS LAST, name
  LIMIT 1;

  -- Best-effort: first section by sort order for management override.
  SELECT id INTO v_first_section_id
  FROM public.audit_sections
  WHERE engagement_id = p_engagement_id
  ORDER BY sort_order NULLS LAST, name
  LIMIT 1;

  -- 1. Revenue Recognition (ISA 240.26)
  -- EXISTS check ignores section_id so we don't double-seed when the
  -- existing presumed risk has lost its section_id via cascade SET NULL.
  IF NOT EXISTS (
    SELECT 1 FROM public.engagement_risks
    WHERE engagement_id     = p_engagement_id
      AND is_locked_presumed = true
      AND source             = 'fraud'
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

  -- 2. Management Override of Controls (ISA 240.31)
  IF NOT EXISTS (
    SELECT 1 FROM public.engagement_risks
    WHERE engagement_id     = p_engagement_id
      AND source             = 'management_override'
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
