-- Sprint 1 verification — FS upload hardening.
-- Three fixes from the Copilot review:
--   (C1) Transactional supersede+insert via RPC.
--   (C6) Tighten RLS with role check (admin/supervisor only).
--   (C4) Friendly unique-violation handling moves to the client.
-- Together these flip the failure mode for FS uploads from
--   "lost active signed" to "harmless orphan file."

-- =========================================================================
-- HELPER: user_can_upload_fs(org_id)
-- True when the caller is an admin or supervisor in that org.
-- Mirrors the client-side can('upload_fs') gate so a preparer cannot
-- bypass the UI by hitting the Supabase API directly.
-- =========================================================================
CREATE OR REPLACE FUNCTION public.user_can_upload_fs(p_org_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.organization_members om
    WHERE om.organization_id = p_org_id
      AND om.user_id = auth.uid()
      AND om.role IN ('admin','supervisor')
  );
$$;

REVOKE EXECUTE ON FUNCTION public.user_can_upload_fs(uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.user_can_upload_fs(uuid) TO authenticated;


-- =========================================================================
-- RLS: tighten INSERT + UPDATE to require admin/supervisor.
-- SELECT stays open to any org member.
-- =========================================================================
DROP POLICY IF EXISTS efu_insert ON public.engagement_fs_uploads;
CREATE POLICY efu_insert ON public.engagement_fs_uploads
  FOR INSERT
  WITH CHECK (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_can_upload_fs(organization_id)
  );

DROP POLICY IF EXISTS efu_update ON public.engagement_fs_uploads;
CREATE POLICY efu_update ON public.engagement_fs_uploads
  FOR UPDATE
  USING (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_can_upload_fs(organization_id)
  );


-- =========================================================================
-- RPC: commit_fs_upload — supersede + insert atomically inside one tx.
--
-- Client flow (revised):
--   1. Upload file to Supabase Storage.
--   2. Call this RPC with the metadata.
--   3. On RPC failure → clean up the storage object (orphan is harmless).
--
-- This RPC is the single write path for FS metadata. Direct INSERTs from
-- the client still work (RLS-gated) for backwards compatibility but the
-- recommended path is the RPC because:
--   - Supersede + insert in one tx (prior signed cannot be lost).
--   - RAISE EXCEPTION on permission failure surfaces clearly.
-- =========================================================================
CREATE OR REPLACE FUNCTION public.commit_fs_upload(
  p_upload_id        uuid,
  p_engagement_id    uuid,
  p_organization_id  uuid,
  p_version_type     text,
  p_file_name        text,
  p_file_path        text,
  p_file_size_bytes  bigint,
  p_mime_type        text,
  p_version_label    text,
  p_notes            text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Role check: only admin/supervisor can write FS uploads.
  IF NOT public.user_can_upload_fs(p_organization_id) THEN
    RAISE EXCEPTION
      'commit_fs_upload: caller does not have upload_fs permission for organization %',
      p_organization_id;
  END IF;

  -- Engagement must belong to the same org.
  IF NOT EXISTS (
    SELECT 1 FROM public.engagements
    WHERE id = p_engagement_id
      AND organization_id = p_organization_id
  ) THEN
    RAISE EXCEPTION
      'commit_fs_upload: engagement % does not belong to organization %',
      p_engagement_id, p_organization_id;
  END IF;

  -- Validate version_type against the CHECK constraint on the table.
  IF p_version_type NOT IN ('draft','final_for_review','signed') THEN
    RAISE EXCEPTION 'commit_fs_upload: invalid version_type %', p_version_type;
  END IF;

  -- For signed uploads, supersede any existing active signed in the same
  -- transaction as the insert. The partial unique index ensures only one
  -- active signed at a time. Doing both in one tx means a failed insert
  -- rolls back the supersede automatically.
  IF p_version_type = 'signed' THEN
    UPDATE public.engagement_fs_uploads
    SET is_superseded = true,
        superseded_at = now(),
        superseded_by = auth.uid()
    WHERE engagement_id = p_engagement_id
      AND version_type = 'signed'
      AND is_superseded = false;
  END IF;

  -- Insert the new row.
  INSERT INTO public.engagement_fs_uploads (
    id, engagement_id, organization_id, version_type,
    file_name, file_path, file_size_bytes, mime_type,
    version_label, uploaded_by, notes
  ) VALUES (
    p_upload_id, p_engagement_id, p_organization_id, p_version_type,
    p_file_name, p_file_path, p_file_size_bytes, p_mime_type,
    p_version_label, auth.uid(), p_notes
  );

  RETURN p_upload_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.commit_fs_upload(
  uuid, uuid, uuid, text, text, text, bigint, text, text, text
) FROM public;
GRANT  EXECUTE ON FUNCTION public.commit_fs_upload(
  uuid, uuid, uuid, text, text, text, bigint, text, text, text
) TO authenticated;
