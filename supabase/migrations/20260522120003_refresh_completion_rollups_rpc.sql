-- 2026-05-22 — Add explicit refresh_completion_memo_rollups RPC.
--
-- The Completion Memo page shows section / finding / AJE counts that
-- come from the engagement_completion_memo rollup columns. Those columns
-- are normally maintained by the fn_refresh_memo_rollups trigger
-- (migration 20260519120005), but that trigger only fires when a
-- draft memo exists at the time the underlying change happens.
--
-- If the partner approves sections BEFORE creating the memo (the natural
-- flow on a fresh engagement), no trigger ever fires for those sections
-- against this memo — so the memo shows 0/0 even when 1/1 is approved.
--
-- This RPC provides an on-demand recomputation the client calls when
-- the memo is opened or when "Refresh System Checks" is clicked. Mirrors
-- the UPDATE logic from fn_refresh_memo_rollups but callable as an RPC.

CREATE OR REPLACE FUNCTION public.refresh_completion_memo_rollups(
  p_memo_id uuid
)
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
  v_cls           text;
BEGIN
  SELECT engagement_id, organization_id
    INTO v_eng_id, v_org_id
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

  SELECT materiality_overall INTO v_overall_mat
    FROM public.engagements WHERE id = v_eng_id;

  SELECT COALESCE(SUM(ae.amount), 0) INTO v_sum_unposted
    FROM public.adjusting_entries ae
    JOIN public.findings f          ON f.id    = ae.finding_id
    JOIN public.audit_sections asec ON asec.id = f.section_id
   WHERE asec.engagement_id = v_eng_id AND ae.is_posted = false;

  v_cls := CASE
    WHEN v_overall_mat IS NULL                   THEN 'not_calculated'
    WHEN v_sum_unposted < (v_overall_mat * 0.75) THEN 'below'
    WHEN v_sum_unposted <= v_overall_mat         THEN 'approaching'
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
        JOIN public.findings f          ON f.id    = ae.finding_id
        JOIN public.audit_sections asec ON asec.id = f.section_id
       WHERE asec.engagement_id = v_eng_id AND ae.is_posted = true),
    unposted_adjustments = (
      SELECT COUNT(*) FROM public.adjusting_entries ae
        JOIN public.findings f          ON f.id    = ae.finding_id
        JOIN public.audit_sections asec ON asec.id = f.section_id
       WHERE asec.engagement_id = v_eng_id AND ae.is_posted = false),
    uncorrected_vs_materiality = v_cls,
    updated_at = now()
   WHERE id = p_memo_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.refresh_completion_memo_rollups(uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.refresh_completion_memo_rollups(uuid) TO authenticated;
