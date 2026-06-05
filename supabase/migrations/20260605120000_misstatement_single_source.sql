-- T2: journal_entries becomes the SINGLE source of truth for misstatements/adjustments.
-- Ends the split-brain where the auditor entered an adjustment twice — once as a
-- finding (+ adjusting_entries, OLD model) and once as a journal (journal_entries,
-- NEW model). adjusting_entries is now legacy. 3-AI validated (Perplexity/Gemini/
-- Copilot); spec: the misstatement is the journal, the finding is the narrative wrapper.
--
-- Three parts:
--   1. Backfill adjusting_entries -> journal_entries + journal_lines (idempotent,
--      traceable via source_adjusting_entry_id).
--   2. Repoint the rollup trigger (posted/unposted/total misstatements + vs-materiality)
--      to journal_entries.isa450_status. Keeps the status='draft' guard so SIGNED memos
--      stay frozen (the existing snapshot mechanism — no new table needed).
--   3. Repoint recompute_attestation_checks #3 (uncorrected vs materiality) and #4
--      (misstatements communicated) to journal_entries, and ADD a draft-guard so a
--      signed memo's system checks can't be retroactively flipped.

-- =========================================================================
-- 1. BACKFILL — adjusting_entries -> journal_entries (+ 2 journal_lines legs)
-- =========================================================================
ALTER TABLE public.journal_entries
  ADD COLUMN IF NOT EXISTS source_adjusting_entry_id uuid;  -- traceability + idempotency

-- Header: one journal_entry per legacy adjusting_entry. is_posted -> corrected/uncorrected.
INSERT INTO public.journal_entries (
  engagement_id, organization_id, tb_version_id,
  description, source_section_id, linked_finding_id,
  impact_type, isa450_status, is_posted_to_adjusted_tb,
  status, created_at, source_adjusting_entry_id
)
SELECT
  e.id, e.organization_id, NULL,
  COALESCE(ae.narration, 'Adjusting entry (migrated)'), f.section_id, ae.finding_id,
  'adjustment',
  CASE WHEN ae.is_posted THEN 'corrected' ELSE 'uncorrected' END,
  ae.is_posted,
  'final', ae.created_at, ae.id
FROM public.adjusting_entries ae
JOIN public.findings f        ON f.id    = ae.finding_id
JOIN public.audit_sections s  ON s.id    = f.section_id
JOIN public.engagements e     ON e.id    = s.engagement_id
WHERE NOT EXISTS (
  SELECT 1 FROM public.journal_entries je WHERE je.source_adjusting_entry_id = ae.id
);

-- Legs: debit (sort 0) + credit (sort 1) per backfilled journal. Old model stored
-- account names as text (no TB-line ref), so trial_balance_line_id stays null.
INSERT INTO public.journal_lines (
  journal_entry_id, organization_id, account_code, account_name, debit, credit, sort_order
)
SELECT je.id, je.organization_id, ae.debit_account, ae.debit_account, ae.amount, 0, 0
FROM public.journal_entries je
JOIN public.adjusting_entries ae ON ae.id = je.source_adjusting_entry_id
WHERE je.source_adjusting_entry_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM public.journal_lines jl WHERE jl.journal_entry_id = je.id)
UNION ALL
SELECT je.id, je.organization_id, ae.credit_account, ae.credit_account, 0, ae.amount, 1
FROM public.journal_entries je
JOIN public.adjusting_entries ae ON ae.id = je.source_adjusting_entry_id
WHERE je.source_adjusting_entry_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM public.journal_lines jl WHERE jl.journal_entry_id = je.id);


-- =========================================================================
-- 2. REPOINT the rollup trigger to journal_entries (single source)
--    - posted/unposted/total misstatements + vs-materiality from journal_entries
--    - findings/section counts stay on findings (narrative umbrella)
--    - status='draft' guard kept: SIGNED memos stay frozen
-- =========================================================================
CREATE OR REPLACE FUNCTION public.fn_refresh_memo_rollups()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_eng_id       uuid;
  v_memo_id      uuid;
  v_overall_mat  numeric;
  v_sum_unposted numeric;
  v_cls          text;
BEGIN
  -- Resolve engagement_id from whichever table fired.
  IF TG_TABLE_NAME = 'audit_sections' THEN
    v_eng_id := COALESCE(NEW.engagement_id, OLD.engagement_id);
  ELSIF TG_TABLE_NAME = 'findings' THEN
    SELECT asec.engagement_id INTO v_eng_id
    FROM public.audit_sections asec
    WHERE asec.id = COALESCE(NEW.section_id, OLD.section_id);
  ELSIF TG_TABLE_NAME = 'journal_entries' THEN
    v_eng_id := COALESCE(NEW.engagement_id, OLD.engagement_id);
  ELSIF TG_TABLE_NAME = 'journal_lines' THEN
    SELECT je.engagement_id INTO v_eng_id
    FROM public.journal_entries je
    WHERE je.id = COALESCE(NEW.journal_entry_id, OLD.journal_entry_id);
  ELSE
    RETURN COALESCE(NEW, OLD);
  END IF;

  IF v_eng_id IS NULL THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  SELECT id INTO v_memo_id
  FROM public.engagement_completion_memo
  WHERE engagement_id = v_eng_id AND status = 'draft'
  LIMIT 1;

  IF v_memo_id IS NULL THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  SELECT materiality_overall INTO v_overall_mat
  FROM public.engagements WHERE id = v_eng_id;

  -- Sum of UNCORRECTED journal magnitudes (sum of debit legs = entry magnitude).
  SELECT COALESCE(SUM(jl.debit), 0) INTO v_sum_unposted
  FROM public.journal_entries je
  JOIN public.journal_lines jl ON jl.journal_entry_id = je.id
  WHERE je.engagement_id = v_eng_id AND je.isa450_status = 'uncorrected';

  v_cls := CASE
    WHEN v_overall_mat IS NULL                   THEN 'not_calculated'
    WHEN v_sum_unposted < (v_overall_mat * 0.75) THEN 'below'
    WHEN v_sum_unposted <= v_overall_mat         THEN 'approaching'
    ELSE 'exceeds'
  END;

  UPDATE public.engagement_completion_memo SET
    total_sections = (
      SELECT COUNT(*) FROM public.audit_sections WHERE engagement_id = v_eng_id),
    sections_approved = (
      SELECT COUNT(*) FROM public.audit_sections WHERE engagement_id = v_eng_id AND status = 'approved'),
    sections_with_open_issues = (
      SELECT COUNT(*) FROM public.audit_sections WHERE engagement_id = v_eng_id AND status <> 'approved'),
    total_findings = (
      SELECT COUNT(*) FROM public.findings f
      JOIN public.audit_sections asec ON asec.id = f.section_id
      WHERE asec.engagement_id = v_eng_id),
    findings_resolved = (
      SELECT COUNT(*) FROM public.findings f
      JOIN public.audit_sections asec ON asec.id = f.section_id
      WHERE asec.engagement_id = v_eng_id AND f.status = 'resolved'),
    findings_reported = (
      SELECT COUNT(*) FROM public.findings f
      JOIN public.audit_sections asec ON asec.id = f.section_id
      WHERE asec.engagement_id = v_eng_id AND f.status = 'reported'),
    findings_open = (
      SELECT COUNT(*) FROM public.findings f
      JOIN public.audit_sections asec ON asec.id = f.section_id
      WHERE asec.engagement_id = v_eng_id AND f.status = 'open'),
    -- Misstatement numerics now come from journal_entries (single source).
    total_misstatements = (
      SELECT COUNT(*) FROM public.journal_entries je
      WHERE je.engagement_id = v_eng_id),
    posted_adjustments = (
      SELECT COUNT(*) FROM public.journal_entries je
      WHERE je.engagement_id = v_eng_id AND je.isa450_status = 'corrected'),
    unposted_adjustments = (
      SELECT COUNT(*) FROM public.journal_entries je
      WHERE je.engagement_id = v_eng_id AND je.isa450_status = 'uncorrected'),
    uncorrected_vs_materiality = v_cls,
    updated_at = now()
  WHERE id = v_memo_id;

  RETURN COALESCE(NEW, OLD);
END;
$$;

-- Fire on journal_entries / journal_lines (the new source); drop the legacy adjustments trigger.
DROP TRIGGER IF EXISTS trg_refresh_rollups_adjustments ON public.adjusting_entries;
DROP TRIGGER IF EXISTS trg_refresh_rollups_journals     ON public.journal_entries;
DROP TRIGGER IF EXISTS trg_refresh_rollups_journal_lines ON public.journal_lines;

CREATE TRIGGER trg_refresh_rollups_journals
  AFTER INSERT OR UPDATE OF isa450_status, is_posted_to_adjusted_tb OR DELETE ON public.journal_entries
  FOR EACH ROW EXECUTE FUNCTION public.fn_refresh_memo_rollups();

CREATE TRIGGER trg_refresh_rollups_journal_lines
  AFTER INSERT OR UPDATE OF debit, credit OR DELETE ON public.journal_lines
  FOR EACH ROW EXECUTE FUNCTION public.fn_refresh_memo_rollups();


-- =========================================================================
-- 3. REPOINT recompute_attestation_checks (#3 + #4) to journal_entries,
--    and ADD a draft-guard so signed memos can't be retroactively flipped.
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
  v_status        text;
  v_overall_mat   numeric;
  v_sum_unposted  numeric;
  v_eqr_required  boolean;
  v_eqr_completed timestamptz;
  v_opinion_type  text;
BEGIN
  SELECT engagement_id, organization_id, status, eqr_required, eqr_completed_at, opinion_type
  INTO v_eng_id, v_org_id, v_status, v_eqr_required, v_eqr_completed, v_opinion_type
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

  -- Immutability: never re-flip a signed/locked memo's system checks.
  IF v_status <> 'draft' THEN
    RETURN;
  END IF;

  SELECT materiality_overall INTO v_overall_mat
  FROM public.engagements WHERE id = v_eng_id;

  -- Uncorrected magnitude from journal_entries (single source).
  SELECT COALESCE(SUM(jl.debit), 0) INTO v_sum_unposted
  FROM public.journal_entries je
  JOIN public.journal_lines jl ON jl.journal_entry_id = je.id
  WHERE je.engagement_id = v_eng_id AND je.isa450_status = 'uncorrected';

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

  -- 3. uncorrected_below_materiality  (journal_entries single source)
  UPDATE public.completion_attestations
  SET system_check_passed = CASE
        WHEN v_overall_mat IS NULL          THEN false
        WHEN v_sum_unposted < v_overall_mat THEN true
        ELSE false
      END,
      system_checked_at = now()
  WHERE memo_id = p_memo_id AND attestation_key = 'uncorrected_below_materiality';

  -- 4. misstatements_communicated  (every misstatement journal dispositioned;
  --    uncorrected ones have a management response)
  UPDATE public.completion_attestations
  SET system_check_passed = NOT EXISTS (
        SELECT 1 FROM public.journal_entries je
        WHERE je.engagement_id = v_eng_id
          AND ( je.isa450_status = 'proposed'
                OR (je.isa450_status = 'uncorrected'
                    AND (je.management_response IS NULL OR length(trim(je.management_response)) = 0)) )),
      system_checked_at = now()
  WHERE memo_id = p_memo_id AND attestation_key = 'misstatements_communicated';

  -- 5. going_concern_assessed
  UPDATE public.completion_attestations
  SET system_check_passed = EXISTS (
        SELECT 1 FROM public.audit_sections
        WHERE engagement_id = v_eng_id AND name ILIKE '%going concern%'
          AND status = 'approved' AND conclusion IS NOT NULL),
      system_checked_at = now()
  WHERE memo_id = p_memo_id AND attestation_key = 'going_concern_assessed';

  -- 6. subsequent_events_reviewed
  UPDATE public.completion_attestations
  SET system_check_passed = EXISTS (
        SELECT 1 FROM public.audit_sections
        WHERE engagement_id = v_eng_id AND name ILIKE '%subsequent event%'
          AND status = 'approved' AND conclusion IS NOT NULL),
      system_checked_at = now()
  WHERE memo_id = p_memo_id AND attestation_key = 'subsequent_events_reviewed';

  -- 7. related_parties_complete
  UPDATE public.completion_attestations
  SET system_check_passed = EXISTS (
        SELECT 1 FROM public.audit_sections
        WHERE engagement_id = v_eng_id AND name ILIKE '%related part%' AND status = 'approved'),
      system_checked_at = now()
  WHERE memo_id = p_memo_id AND attestation_key = 'related_parties_complete';

  -- 8. all_procedures_responded
  UPDATE public.completion_attestations
  SET system_check_passed = NOT EXISTS (
        SELECT 1
        FROM public.audit_procedures ap
        JOIN public.audit_sections asec ON asec.id = ap.section_id
        LEFT JOIN public.procedure_responses pr ON pr.procedure_id = ap.id AND pr.status = 'done'
        WHERE asec.engagement_id = v_eng_id AND pr.id IS NULL),
      system_checked_at = now()
  WHERE memo_id = p_memo_id AND attestation_key = 'all_procedures_responded';

  -- 9, 10, 11 — manual attestations: system check always passes
  UPDATE public.completion_attestations
  SET system_check_passed = true, system_checked_at = now()
  WHERE memo_id = p_memo_id
    AND attestation_key IN ('independence_reconfirmed','written_reps_obtained','review_notes_resolved');

  -- 12. opinion_type_selected
  UPDATE public.completion_attestations
  SET system_check_passed = (v_opinion_type IS NOT NULL), system_checked_at = now()
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


-- =========================================================================
-- 4. REPOINT the on-demand rollup RPC (called by the memo page) to
--    journal_entries, and ADD a draft-guard so it can't mutate a signed memo.
-- =========================================================================
CREATE OR REPLACE FUNCTION public.refresh_completion_memo_rollups(p_memo_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_eng_id       uuid;
  v_org_id       uuid;
  v_status       text;
  v_overall_mat  numeric;
  v_sum_unposted numeric;
  v_cls          text;
BEGIN
  SELECT engagement_id, organization_id, status
    INTO v_eng_id, v_org_id, v_status
    FROM public.engagement_completion_memo
   WHERE id = p_memo_id;

  IF v_eng_id IS NULL THEN
    RAISE EXCEPTION 'refresh_completion_memo_rollups: memo % not found', p_memo_id;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.organization_members
     WHERE user_id = auth.uid() AND organization_id = v_org_id
  ) THEN
    RAISE EXCEPTION 'refresh_completion_memo_rollups: caller is not a member of organization %', v_org_id;
  END IF;

  -- Immutability: never recompute a signed/locked memo's frozen counts.
  IF v_status <> 'draft' THEN
    RETURN;
  END IF;

  SELECT materiality_overall INTO v_overall_mat
    FROM public.engagements WHERE id = v_eng_id;

  SELECT COALESCE(SUM(jl.debit), 0) INTO v_sum_unposted
    FROM public.journal_entries je
    JOIN public.journal_lines jl ON jl.journal_entry_id = je.id
   WHERE je.engagement_id = v_eng_id AND je.isa450_status = 'uncorrected';

  v_cls := CASE
    WHEN v_overall_mat IS NULL                   THEN 'not_calculated'
    WHEN v_sum_unposted < (v_overall_mat * 0.75) THEN 'below'
    WHEN v_sum_unposted <= v_overall_mat         THEN 'approaching'
    ELSE 'exceeds'
  END;

  UPDATE public.engagement_completion_memo SET
    total_sections = (
      SELECT COUNT(*) FROM public.audit_sections WHERE engagement_id = v_eng_id),
    sections_approved = (
      SELECT COUNT(*) FROM public.audit_sections WHERE engagement_id = v_eng_id AND status = 'approved'),
    sections_with_open_issues = (
      SELECT COUNT(*) FROM public.audit_sections WHERE engagement_id = v_eng_id AND status <> 'approved'),
    total_findings = (
      SELECT COUNT(*) FROM public.findings f
        JOIN public.audit_sections asec ON asec.id = f.section_id
       WHERE asec.engagement_id = v_eng_id),
    findings_resolved = (
      SELECT COUNT(*) FROM public.findings f
        JOIN public.audit_sections asec ON asec.id = f.section_id
       WHERE asec.engagement_id = v_eng_id AND f.status = 'resolved'),
    findings_reported = (
      SELECT COUNT(*) FROM public.findings f
        JOIN public.audit_sections asec ON asec.id = f.section_id
       WHERE asec.engagement_id = v_eng_id AND f.status = 'reported'),
    findings_open = (
      SELECT COUNT(*) FROM public.findings f
        JOIN public.audit_sections asec ON asec.id = f.section_id
       WHERE asec.engagement_id = v_eng_id AND f.status = 'open'),
    -- Misstatement numerics from journal_entries (single source).
    total_misstatements = (
      SELECT COUNT(*) FROM public.journal_entries je WHERE je.engagement_id = v_eng_id),
    posted_adjustments = (
      SELECT COUNT(*) FROM public.journal_entries je
       WHERE je.engagement_id = v_eng_id AND je.isa450_status = 'corrected'),
    unposted_adjustments = (
      SELECT COUNT(*) FROM public.journal_entries je
       WHERE je.engagement_id = v_eng_id AND je.isa450_status = 'uncorrected'),
    uncorrected_vs_materiality = v_cls,
    updated_at = now()
   WHERE id = p_memo_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.refresh_completion_memo_rollups(uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.refresh_completion_memo_rollups(uuid) TO authenticated;
