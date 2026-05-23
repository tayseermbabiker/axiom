-- =========================================================================
-- Sprint 4 — 4-AI standards floor (synthesis 2026-05-23)
-- ISA 510 (opening balances) + ISA 230 (engagement archive toggle).
-- =========================================================================
-- Two small additions, both validated by the 4-AI synthesis as the
-- minimal SME-proportionate implementation of the underlying standards:
--   - ISA 510: not a module, just a status flag + notes on acceptance.
--     For continuance engagements (the majority of files), opening
--     balances are last year's signed FS. For first-year engagements,
--     the partner attests verification (predecessor inquiry, alternative
--     procedures, re-audit) and documents the approach.
--   - ISA 230: not a workflow, just a single archive toggle that locks
--     in the file assembly date. Completion memo lock provides the
--     real immutability; this toggle marks file assembly per ISA 230.A23.
-- Both deliberately avoid Big-4 bloat per [[audexon-scope-freeze]].

-- =========================================================================
-- ISA 510 — Opening balances on engagement_acceptance
-- =========================================================================
ALTER TABLE public.engagement_acceptance
  ADD COLUMN IF NOT EXISTS opening_balances_status text
    CHECK (opening_balances_status IS NULL
           OR opening_balances_status IN ('verified', 'na_continuance')),
  ADD COLUMN IF NOT EXISTS opening_balances_notes  text;

-- Update revise RPC to carry forward opening balances state as a stable
-- continuance fact — a client that was 'na_continuance' last year stays
-- 'na_continuance' the next year (their prior closing = our prior audited
-- balances). Partner can override if circumstances change.
CREATE OR REPLACE FUNCTION public.revise_engagement_acceptance(
  p_engagement_id   uuid,
  p_organization_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_prior  public.engagement_acceptance%ROWTYPE;
  v_new_id uuid;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE user_id = auth.uid() AND organization_id = p_organization_id
  ) THEN
    RAISE EXCEPTION 'revise_engagement_acceptance: caller is not a member of organization %', p_organization_id;
  END IF;

  IF NOT public.user_has_role_in_org(p_organization_id, 'admin') THEN
    RAISE EXCEPTION 'revise_engagement_acceptance: caller must be an admin in organization %', p_organization_id;
  END IF;

  IF NOT public.org_has_pro_tier(p_organization_id) THEN
    RAISE EXCEPTION 'revise_engagement_acceptance: organization % is not on Pro tier', p_organization_id;
  END IF;

  SELECT * INTO v_prior
  FROM public.engagement_acceptance
  WHERE engagement_id = p_engagement_id AND is_superseded = false
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'revise_engagement_acceptance: no active row for engagement %', p_engagement_id;
  END IF;

  UPDATE public.engagement_acceptance
  SET is_superseded = true,
      superseded_at = now(),
      superseded_by = auth.uid()
  WHERE id = v_prior.id;

  v_new_id := gen_random_uuid();

  INSERT INTO public.engagement_acceptance (
    id, engagement_id, organization_id, status, acceptance_type,
    had_predecessor_auditor, predecessor_auditor_name,
    predecessor_communication_done, predecessor_communication_summary,
    predecessor_workpapers_accessed,
    integrity_method_prior_experience, integrity_method_internet_search,
    integrity_method_predecessor_inquiry, integrity_method_other,
    integrity_method_other_description,
    competence_resources_considered, competence_resources_notes,
    opening_balances_status, opening_balances_notes,
    created_by
  ) VALUES (
    v_new_id, p_engagement_id, p_organization_id, 'draft', 'continuance',
    v_prior.had_predecessor_auditor, v_prior.predecessor_auditor_name,
    v_prior.predecessor_communication_done, v_prior.predecessor_communication_summary,
    v_prior.predecessor_workpapers_accessed,
    v_prior.integrity_method_prior_experience, v_prior.integrity_method_internet_search,
    v_prior.integrity_method_predecessor_inquiry, v_prior.integrity_method_other,
    v_prior.integrity_method_other_description,
    v_prior.competence_resources_considered, v_prior.competence_resources_notes,
    v_prior.opening_balances_status, v_prior.opening_balances_notes,
    auth.uid()
  );

  RETURN v_new_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.revise_engagement_acceptance(uuid, uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.revise_engagement_acceptance(uuid, uuid) TO authenticated;


-- =========================================================================
-- ISA 230 — Engagement archive toggle on engagements
-- =========================================================================
-- File assembly date per ISA 230.A23. Memo lock provides the real
-- immutability; archive captures the explicit assembly milestone.
ALTER TABLE public.engagements
  ADD COLUMN IF NOT EXISTS is_archived  boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS archived_at  timestamptz,
  ADD COLUMN IF NOT EXISTS archived_by  uuid REFERENCES public.profiles(id);

-- Archive RPC — admin only, requires completion memo to be locked.
-- ISA 230.A23 expects file assembly AFTER the auditor's report is dated.
CREATE OR REPLACE FUNCTION public.archive_engagement(
  p_engagement_id   uuid,
  p_organization_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_memo_status text;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE user_id = auth.uid() AND organization_id = p_organization_id
  ) THEN
    RAISE EXCEPTION 'archive_engagement: caller is not a member of organization %', p_organization_id;
  END IF;

  IF NOT public.user_has_role_in_org(p_organization_id, 'admin') THEN
    RAISE EXCEPTION 'archive_engagement: caller must be an admin in organization %', p_organization_id;
  END IF;

  SELECT status INTO v_memo_status
  FROM public.engagement_completion_memo
  WHERE engagement_id = p_engagement_id
  LIMIT 1;

  IF v_memo_status IS NULL OR v_memo_status <> 'locked' THEN
    RAISE EXCEPTION 'archive_engagement: completion memo must be locked before archive (current status: %)',
                    COALESCE(v_memo_status, 'no memo created');
  END IF;

  UPDATE public.engagements
  SET is_archived = true,
      archived_at = now(),
      archived_by = auth.uid()
  WHERE id = p_engagement_id
    AND organization_id = p_organization_id
    AND is_archived = false;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'archive_engagement: engagement % not found or already archived', p_engagement_id;
  END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.archive_engagement(uuid, uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.archive_engagement(uuid, uuid) TO authenticated;

-- Unarchive RPC — for rare ISA 560.A14-A19 post-issuance scenarios
-- (subsequent fact discovered, opinion withdrawn, etc.). Admin only.
-- Activity log entry will record the unarchive as a post-assembly change.
CREATE OR REPLACE FUNCTION public.unarchive_engagement(
  p_engagement_id   uuid,
  p_organization_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE user_id = auth.uid() AND organization_id = p_organization_id
  ) THEN
    RAISE EXCEPTION 'unarchive_engagement: caller is not a member of organization %', p_organization_id;
  END IF;

  IF NOT public.user_has_role_in_org(p_organization_id, 'admin') THEN
    RAISE EXCEPTION 'unarchive_engagement: caller must be an admin in organization %', p_organization_id;
  END IF;

  UPDATE public.engagements
  SET is_archived = false,
      archived_at = NULL,
      archived_by = NULL
  WHERE id = p_engagement_id
    AND organization_id = p_organization_id
    AND is_archived = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'unarchive_engagement: engagement % not found or not archived', p_engagement_id;
  END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.unarchive_engagement(uuid, uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.unarchive_engagement(uuid, uuid) TO authenticated;
