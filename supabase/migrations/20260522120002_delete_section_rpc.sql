-- 2026-05-22 — Backfill missing delete_section RPC.
--
-- The UI calls supabaseClient.rpc('delete_section', { p_section_id })
-- but the function existed only in the prod Supabase project (never
-- got captured in a migration). Staging is therefore missing it.
--
-- Most child tables (audit_procedures, findings, review_notes, documents,
-- engagement_risks) reference audit_sections with ON DELETE CASCADE,
-- so a simple DELETE on the section handles fan-out. The RPC just wraps
-- it with org-membership + admin-role checks so partners can clean up
-- mis-created sections without granting blanket DELETE on the table.

CREATE OR REPLACE FUNCTION public.delete_section(
  p_section_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_eng_id uuid;
  v_org_id uuid;
  v_partner_approved timestamptz;
BEGIN
  SELECT s.engagement_id, e.organization_id, s.partner_approved_at
    INTO v_eng_id, v_org_id, v_partner_approved
    FROM public.audit_sections s
    JOIN public.engagements    e ON e.id = s.engagement_id
   WHERE s.id = p_section_id;

  IF v_eng_id IS NULL THEN
    RAISE EXCEPTION 'delete_section: section % not found', p_section_id;
  END IF;

  -- Org-membership gate
  IF NOT EXISTS (
    SELECT 1 FROM public.organization_members
     WHERE user_id = auth.uid() AND organization_id = v_org_id
  ) THEN
    RAISE EXCEPTION 'delete_section: caller is not a member of organization %', v_org_id;
  END IF;

  -- Partner-only action (matches UI's can('delete_section') check)
  IF NOT public.user_has_role_in_org(v_org_id, 'admin') THEN
    RAISE EXCEPTION 'delete_section: only partners (admin role) can delete sections';
  END IF;

  -- Cannot delete partner-approved sections (matches UI gate)
  IF v_partner_approved IS NOT NULL THEN
    RAISE EXCEPTION 'delete_section: section is partner-approved and cannot be deleted';
  END IF;

  DELETE FROM public.audit_sections WHERE id = p_section_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.delete_section(uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.delete_section(uuid) TO authenticated;
