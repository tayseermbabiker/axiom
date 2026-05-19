-- Sprint 1 — Attestation seeding + system-check recomputation.
-- Two SECURITY DEFINER functions called by the application layer:
--   seed_attestations_for_memo()  — inserts the 13 attestation rows for a new memo
--   recompute_attestation_checks() — refreshes system_check_passed for one memo

-- =========================================================================
-- FUNCTION: seed_attestations_for_memo
-- Call this immediately after inserting a new engagement_completion_memo row.
-- =========================================================================
CREATE OR REPLACE FUNCTION public.seed_attestations_for_memo(
  p_memo_id         uuid,
  p_organization_id uuid,
  p_engagement_id   uuid
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
    RAISE EXCEPTION 'seed_attestations_for_memo: caller not a member of organization %', p_organization_id;
  END IF;

  INSERT INTO public.completion_attestations (
    memo_id, organization_id, engagement_id,
    attestation_key, attestation_order, isa_reference, source_table, source_check
  )
  VALUES
    (p_memo_id, p_organization_id, p_engagement_id,
      'all_sections_approved',          1,  'ISA 230.7',
      'audit_sections',
      'Every audit section for this engagement has status = approved'),
    (p_memo_id, p_organization_id, p_engagement_id,
      'no_open_findings',               2,  'ISA 450.14',
      'findings',
      'No findings remain in status = open'),
    (p_memo_id, p_organization_id, p_engagement_id,
      'uncorrected_below_materiality',  3,  'ISA 450.14',
      'adjusting_entries,engagements',
      'Sum of adjusting_entries.amount where is_posted = false is below engagements.materiality_overall'),
    (p_memo_id, p_organization_id, p_engagement_id,
      'misstatements_communicated',     4,  'ISA 450.14',
      'findings',
      'Every misstatement finding has a management_response and is no longer open'),
    (p_memo_id, p_organization_id, p_engagement_id,
      'going_concern_assessed',         5,  'ISA 570.26',
      'audit_sections',
      'Going Concern section is approved and has a conclusion'),
    (p_memo_id, p_organization_id, p_engagement_id,
      'subsequent_events_reviewed',     6,  'ISA 560.10',
      'audit_sections',
      'Subsequent Events section is approved and has a conclusion'),
    (p_memo_id, p_organization_id, p_engagement_id,
      'related_parties_complete',       7,  'ISA 550.27',
      'audit_sections',
      'Related Parties section is approved'),
    (p_memo_id, p_organization_id, p_engagement_id,
      'all_procedures_responded',       8,  'ISA 500.6',
      'audit_procedures,procedure_responses',
      'Every audit_procedure has at least one procedure_response with status = done'),
    (p_memo_id, p_organization_id, p_engagement_id,
      'independence_reconfirmed',       9,  'ISA 220.14',
      NULL,
      'Manual attestation: engagement admin reconfirms independence at completion'),
    (p_memo_id, p_organization_id, p_engagement_id,
      'written_reps_obtained',         10,  'ISA 580.10',
      NULL,
      'Manual attestation: management representation letter obtained (Sprint 2 will wire to mgmt_rep_letters)'),
    (p_memo_id, p_organization_id, p_engagement_id,
      'review_notes_resolved',         11,  'ISA 220.17',
      NULL,
      'Manual attestation: all review notes addressed (Sprint 2 will add a status column to review_notes)'),
    (p_memo_id, p_organization_id, p_engagement_id,
      'opinion_type_selected',         12,  'ISA 700.10',
      'engagement_completion_memo',
      'engagement_completion_memo.opinion_type is set on this memo'),
    (p_memo_id, p_organization_id, p_engagement_id,
      'eqr_review_complete',           13,  'ISQM 2 / ISA 220 Rev',
      'engagement_completion_memo',
      'If eqr_required = false: auto-pass. If eqr_required = true: eqr_completed_at must be set');

  GET DIAGNOSTICS v_inserted = ROW_COUNT;
  RETURN v_inserted;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.seed_attestations_for_memo(uuid, uuid, uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.seed_attestations_for_memo(uuid, uuid, uuid) TO authenticated;


-- =========================================================================
-- FUNCTION: recompute_attestation_checks
-- Refreshes system_check_passed for every attestation on one memo.
-- The application calls this whenever the memo page loads and after
-- significant state changes (find/edit/resolve sections/findings/adjustments).
-- =========================================================================
CREATE OR REPLACE FUNCTION public.recompute_attestation_checks(p_memo_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_eng_id        uuid;
  v_org_id        uuid;
  v_overall_mat   numeric;
  v_sum_unposted  numeric;
  v_eqr_required  boolean;
  v_eqr_completed timestamptz;
  v_opinion_type  text;
BEGIN
  SELECT engagement_id, organization_id, eqr_required, eqr_completed_at, opinion_type
  INTO v_eng_id, v_org_id, v_eqr_required, v_eqr_completed, v_opinion_type
  FROM public.engagement_completion_memo
  WHERE id = p_memo_id;

  IF v_eng_id IS NULL THEN
    RETURN;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE user_id = auth.uid() AND organization_id = v_org_id
  ) THEN
    RAISE EXCEPTION 'recompute_attestation_checks: caller not a member of organization %', v_org_id;
  END IF;

  SELECT materiality_overall INTO v_overall_mat
  FROM public.engagements WHERE id = v_eng_id;

  SELECT COALESCE(SUM(ae.amount), 0) INTO v_sum_unposted
  FROM public.adjusting_entries ae
  JOIN public.findings f      ON f.id    = ae.finding_id
  JOIN public.audit_sections asec ON asec.id = f.section_id
  WHERE asec.engagement_id = v_eng_id AND ae.is_posted = false;

  -- 1. all_sections_approved
  UPDATE public.completion_attestations
  SET system_check_passed = NOT EXISTS (
        SELECT 1 FROM public.audit_sections
        WHERE engagement_id = v_eng_id AND status <> 'approved'),
      system_checked_at = now()
  WHERE memo_id = p_memo_id AND attestation_key = 'all_sections_approved';

  -- 2. no_open_findings
  UPDATE public.completion_attestations
  SET system_check_passed = NOT EXISTS (
        SELECT 1 FROM public.findings f
        JOIN public.audit_sections asec ON asec.id = f.section_id
        WHERE asec.engagement_id = v_eng_id AND f.status = 'open'),
      system_checked_at = now()
  WHERE memo_id = p_memo_id AND attestation_key = 'no_open_findings';

  -- 3. uncorrected_below_materiality
  UPDATE public.completion_attestations
  SET system_check_passed = CASE
        WHEN v_overall_mat IS NULL          THEN false
        WHEN v_sum_unposted < v_overall_mat THEN true
        ELSE false
      END,
      system_checked_at = now()
  WHERE memo_id = p_memo_id AND attestation_key = 'uncorrected_below_materiality';

  -- 4. misstatements_communicated
  UPDATE public.completion_attestations
  SET system_check_passed = NOT EXISTS (
        SELECT 1 FROM public.findings f
        JOIN public.audit_sections asec ON asec.id = f.section_id
        WHERE asec.engagement_id = v_eng_id
          AND f.finding_type = 'misstatement'
          AND (f.management_response IS NULL OR f.status = 'open')),
      system_checked_at = now()
  WHERE memo_id = p_memo_id AND attestation_key = 'misstatements_communicated';

  -- 5. going_concern_assessed
  UPDATE public.completion_attestations
  SET system_check_passed = EXISTS (
        SELECT 1 FROM public.audit_sections
        WHERE engagement_id = v_eng_id
          AND name ILIKE '%going concern%'
          AND status = 'approved'
          AND conclusion IS NOT NULL),
      system_checked_at = now()
  WHERE memo_id = p_memo_id AND attestation_key = 'going_concern_assessed';

  -- 6. subsequent_events_reviewed
  UPDATE public.completion_attestations
  SET system_check_passed = EXISTS (
        SELECT 1 FROM public.audit_sections
        WHERE engagement_id = v_eng_id
          AND name ILIKE '%subsequent event%'
          AND status = 'approved'
          AND conclusion IS NOT NULL),
      system_checked_at = now()
  WHERE memo_id = p_memo_id AND attestation_key = 'subsequent_events_reviewed';

  -- 7. related_parties_complete
  UPDATE public.completion_attestations
  SET system_check_passed = EXISTS (
        SELECT 1 FROM public.audit_sections
        WHERE engagement_id = v_eng_id
          AND name ILIKE '%related part%'
          AND status = 'approved'),
      system_checked_at = now()
  WHERE memo_id = p_memo_id AND attestation_key = 'related_parties_complete';

  -- 8. all_procedures_responded
  UPDATE public.completion_attestations
  SET system_check_passed = NOT EXISTS (
        SELECT 1
        FROM public.audit_procedures ap
        JOIN public.audit_sections asec ON asec.id = ap.section_id
        LEFT JOIN public.procedure_responses pr ON pr.procedure_id = ap.id AND pr.status = 'done'
        WHERE asec.engagement_id = v_eng_id
          AND pr.id IS NULL),
      system_checked_at = now()
  WHERE memo_id = p_memo_id AND attestation_key = 'all_procedures_responded';

  -- 9, 10, 11 — manual attestations: system check always passes (admin still ticks)
  UPDATE public.completion_attestations
  SET system_check_passed = true, system_checked_at = now()
  WHERE memo_id = p_memo_id
    AND attestation_key IN ('independence_reconfirmed','written_reps_obtained','review_notes_resolved');

  -- 12. opinion_type_selected
  UPDATE public.completion_attestations
  SET system_check_passed = (v_opinion_type IS NOT NULL),
      system_checked_at = now()
  WHERE memo_id = p_memo_id AND attestation_key = 'opinion_type_selected';

  -- 13. eqr_review_complete
  UPDATE public.completion_attestations
  SET system_check_passed = CASE
        WHEN v_eqr_required = false THEN true
        WHEN v_eqr_required = true AND v_eqr_completed IS NOT NULL THEN true
        ELSE false
      END,
      system_checked_at = now()
  WHERE memo_id = p_memo_id AND attestation_key = 'eqr_review_complete';
END;
$$;

REVOKE EXECUTE ON FUNCTION public.recompute_attestation_checks(uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.recompute_attestation_checks(uuid) TO authenticated;
