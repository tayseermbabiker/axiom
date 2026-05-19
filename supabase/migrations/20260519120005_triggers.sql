-- Sprint 1 — Triggers
-- 1. fn_check_attestation_completeness: when all 13 attestations are ticked,
--    flip engagement_completion_memo.all_attestations_complete = true.
--    Also resets to false if someone un-ticks.
-- 2. fn_snapshot_and_lock_memo: when signed_at is set, validate the gate,
--    snapshot materiality from engagements, lock the memo (status='locked').
-- 3. fn_block_engagement_close: prevent engagements.status='completed'
--    without a locked memo.
-- 4. fn_refresh_memo_rollups: keep rollup fields current while memo is in 'draft'.

-- =========================================================================
-- TRIGGER 1: attestation completeness flag
-- =========================================================================
CREATE OR REPLACE FUNCTION public.fn_check_attestation_completeness()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_total  int;
  v_ticked int;
BEGIN
  SELECT COUNT(*), COUNT(attested_at)
  INTO v_total, v_ticked
  FROM public.completion_attestations
  WHERE memo_id = NEW.memo_id;

  IF v_total > 0 AND v_total = v_ticked THEN
    UPDATE public.engagement_completion_memo
    SET all_attestations_complete = true,
        updated_at = now()
    WHERE id = NEW.memo_id
      AND all_attestations_complete = false;
  ELSIF v_ticked < v_total THEN
    UPDATE public.engagement_completion_memo
    SET all_attestations_complete = false,
        updated_at = now()
    WHERE id = NEW.memo_id
      AND all_attestations_complete = true;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_attestation_completeness ON public.completion_attestations;
CREATE TRIGGER trg_attestation_completeness
  AFTER UPDATE OF attested_at ON public.completion_attestations
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_check_attestation_completeness();


-- =========================================================================
-- TRIGGER 2: snapshot materiality and lock memo on sign
-- =========================================================================
CREATE OR REPLACE FUNCTION public.fn_snapshot_and_lock_memo()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_eng public.engagements%ROWTYPE;
BEGIN
  IF NEW.signed_at IS NOT NULL AND OLD.signed_at IS NULL THEN
    IF NEW.all_attestations_complete = false THEN
      RAISE EXCEPTION 'Cannot sign completion memo: not all attestations are complete';
    END IF;

    SELECT * INTO v_eng
    FROM public.engagements
    WHERE id = NEW.engagement_id;

    -- BEFORE trigger: mutate NEW directly so we don't loop
    NEW.status                            := 'locked';
    NEW.snapshot_taken_at                 := now();
    NEW.overall_materiality_snapshot      := v_eng.materiality_overall;
    NEW.performance_materiality_snapshot  := v_eng.materiality_performance;
    NEW.updated_at                        := now();
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_snapshot_and_lock_memo ON public.engagement_completion_memo;
CREATE TRIGGER trg_snapshot_and_lock_memo
  BEFORE UPDATE OF signed_at ON public.engagement_completion_memo
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_snapshot_and_lock_memo();


-- =========================================================================
-- TRIGGER 3: block engagement closure without a locked memo
-- engagements.status: 'active' | 'completed' | 'archived'
-- Block transition INTO 'completed' unless a locked memo exists.
-- =========================================================================
CREATE OR REPLACE FUNCTION public.fn_block_engagement_close()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.status = 'completed' AND COALESCE(OLD.status, '') <> 'completed' THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.engagement_completion_memo
      WHERE engagement_id = NEW.id
        AND status = 'locked'
        AND all_attestations_complete = true
        AND signed_at IS NOT NULL
    ) THEN
      RAISE EXCEPTION
        'Engagement cannot move to completed without a locked completion memo signed by the engagement admin';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_block_engagement_close ON public.engagements;
CREATE TRIGGER trg_block_engagement_close
  BEFORE UPDATE OF status ON public.engagements
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_block_engagement_close();


-- =========================================================================
-- TRIGGER 4: refresh memo rollups while in draft
-- Fired on changes to audit_sections / findings / adjusting_entries.
-- Only updates the memo if it exists and is in 'draft' status.
-- =========================================================================
CREATE OR REPLACE FUNCTION public.fn_refresh_memo_rollups()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_eng_id  uuid;
  v_memo_id uuid;
  v_overall_mat numeric;
  v_sum_unposted numeric;
  v_cls text;
BEGIN
  -- Resolve engagement_id from whichever table fired.
  -- findings has no engagement_id — derive via section.
  -- adjusting_entries → finding → section → engagement.
  IF TG_TABLE_NAME = 'audit_sections' THEN
    v_eng_id := COALESCE(NEW.engagement_id, OLD.engagement_id);
  ELSIF TG_TABLE_NAME = 'findings' THEN
    SELECT asec.engagement_id INTO v_eng_id
    FROM public.audit_sections asec
    WHERE asec.id = COALESCE(NEW.section_id, OLD.section_id);
  ELSIF TG_TABLE_NAME = 'adjusting_entries' THEN
    SELECT asec.engagement_id INTO v_eng_id
    FROM public.findings f
    JOIN public.audit_sections asec ON asec.id = f.section_id
    WHERE f.id = COALESCE(NEW.finding_id, OLD.finding_id);
  ELSE
    RETURN COALESCE(NEW, OLD);
  END IF;

  IF v_eng_id IS NULL THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  SELECT id INTO v_memo_id
  FROM public.engagement_completion_memo
  WHERE engagement_id = v_eng_id
    AND status = 'draft'
  LIMIT 1;

  IF v_memo_id IS NULL THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  -- Fetch materiality for the vs-materiality classifier
  SELECT materiality_overall INTO v_overall_mat
  FROM public.engagements WHERE id = v_eng_id;

  SELECT COALESCE(SUM(ae.amount), 0) INTO v_sum_unposted
  FROM public.adjusting_entries ae
  JOIN public.findings f      ON f.id    = ae.finding_id
  JOIN public.audit_sections asec ON asec.id = f.section_id
  WHERE asec.engagement_id = v_eng_id AND ae.is_posted = false;

  v_cls := CASE
    WHEN v_overall_mat IS NULL                               THEN 'not_calculated'
    WHEN v_sum_unposted < (v_overall_mat * 0.75)             THEN 'below'
    WHEN v_sum_unposted <= v_overall_mat                     THEN 'approaching'
    ELSE 'exceeds'
  END;

  UPDATE public.engagement_completion_memo SET
    total_sections = (
      SELECT COUNT(*) FROM public.audit_sections
      WHERE engagement_id = v_eng_id),
    sections_approved = (
      SELECT COUNT(*) FROM public.audit_sections
      WHERE engagement_id = v_eng_id AND status = 'approved'),
    sections_with_open_issues = (
      SELECT COUNT(*) FROM public.audit_sections
      WHERE engagement_id = v_eng_id AND status <> 'approved'),
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
    total_misstatements = (
      SELECT COUNT(*) FROM public.findings f
      JOIN public.audit_sections asec ON asec.id = f.section_id
      WHERE asec.engagement_id = v_eng_id AND f.finding_type = 'misstatement'),
    posted_adjustments = (
      SELECT COUNT(*) FROM public.adjusting_entries ae
      JOIN public.findings f      ON f.id    = ae.finding_id
      JOIN public.audit_sections asec ON asec.id = f.section_id
      WHERE asec.engagement_id = v_eng_id AND ae.is_posted = true),
    unposted_adjustments = (
      SELECT COUNT(*) FROM public.adjusting_entries ae
      JOIN public.findings f      ON f.id    = ae.finding_id
      JOIN public.audit_sections asec ON asec.id = f.section_id
      WHERE asec.engagement_id = v_eng_id AND ae.is_posted = false),
    uncorrected_vs_materiality = v_cls,
    updated_at = now()
  WHERE id = v_memo_id;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_refresh_rollups_sections    ON public.audit_sections;
DROP TRIGGER IF EXISTS trg_refresh_rollups_findings    ON public.findings;
DROP TRIGGER IF EXISTS trg_refresh_rollups_adjustments ON public.adjusting_entries;

CREATE TRIGGER trg_refresh_rollups_sections
  AFTER INSERT OR UPDATE OF status OR DELETE ON public.audit_sections
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_refresh_memo_rollups();

CREATE TRIGGER trg_refresh_rollups_findings
  AFTER INSERT OR UPDATE OF status, finding_type OR DELETE ON public.findings
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_refresh_memo_rollups();

CREATE TRIGGER trg_refresh_rollups_adjustments
  AFTER INSERT OR UPDATE OF is_posted, amount OR DELETE ON public.adjusting_entries
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_refresh_memo_rollups();
