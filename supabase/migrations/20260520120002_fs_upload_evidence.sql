-- Sprint 1 verification — FS upload evidence fields.
-- Three design calls from the Perplexity + Copilot + claude.ai cross-check:
--   (P2) Auditor's report date — substantive ISA 560 datum, must be a
--        first-class field on signed FS versions, not derived from upload
--        timestamp.
--   (P8) SHA-256 hash-pinning — cryptographic proof that the stored file
--        has not been modified since upload. Computed client-side, stored
--        on the row. Inspection-positive integrity signal.
--   (P5) Restatement labeling — handled in the UI layer; no schema change.
--
-- =========================================================================
-- New columns
-- =========================================================================
ALTER TABLE public.engagement_fs_uploads
  ADD COLUMN IF NOT EXISTS report_date date,
  ADD COLUMN IF NOT EXISTS file_sha256 text;

COMMENT ON COLUMN public.engagement_fs_uploads.report_date IS
  'The auditor''s report date associated with this version. REQUIRED for version_type = ''signed'' per ISA 560 — establishes which report attaches to this FS version. Restatements get a new signed row with a new report_date.';

COMMENT ON COLUMN public.engagement_fs_uploads.file_sha256 IS
  'Lowercase hex SHA-256 of the uploaded file content, computed client-side at upload time. Provides cryptographic proof the stored file has not been modified since upload (ISA 230 documentation integrity). 64 chars when populated.';

-- =========================================================================
-- CHECK constraint: report_date required for signed uploads
-- =========================================================================
ALTER TABLE public.engagement_fs_uploads
  DROP CONSTRAINT IF EXISTS efu_signed_requires_report_date;

ALTER TABLE public.engagement_fs_uploads
  ADD CONSTRAINT efu_signed_requires_report_date
  CHECK (version_type <> 'signed' OR report_date IS NOT NULL);

-- =========================================================================
-- Recreate commit_fs_upload with the two new params.
-- Drop old signature first so callers can't pick the stale function up
-- by overload resolution.
-- =========================================================================
DROP FUNCTION IF EXISTS public.commit_fs_upload(
  uuid, uuid, uuid, text, text, text, bigint, text, text, text
);

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
  p_notes            text,
  p_report_date      date,
  p_file_sha256      text
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

  IF p_version_type NOT IN ('draft','final_for_review','signed') THEN
    RAISE EXCEPTION 'commit_fs_upload: invalid version_type %', p_version_type;
  END IF;

  -- Application-layer guard mirroring the CHECK constraint for a friendlier error.
  IF p_version_type = 'signed' AND p_report_date IS NULL THEN
    RAISE EXCEPTION
      'commit_fs_upload: report_date is required for signed financial statements (ISA 560).';
  END IF;

  -- For signed uploads, supersede any existing active signed in the same tx.
  IF p_version_type = 'signed' THEN
    UPDATE public.engagement_fs_uploads
    SET is_superseded = true,
        superseded_at = now(),
        superseded_by = auth.uid()
    WHERE engagement_id = p_engagement_id
      AND version_type = 'signed'
      AND is_superseded = false;
  END IF;

  INSERT INTO public.engagement_fs_uploads (
    id, engagement_id, organization_id, version_type,
    file_name, file_path, file_size_bytes, mime_type,
    version_label, uploaded_by, notes,
    report_date, file_sha256
  ) VALUES (
    p_upload_id, p_engagement_id, p_organization_id, p_version_type,
    p_file_name, p_file_path, p_file_size_bytes, p_mime_type,
    p_version_label, auth.uid(), p_notes,
    p_report_date, p_file_sha256
  );

  RETURN p_upload_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.commit_fs_upload(
  uuid, uuid, uuid, text, text, text, bigint, text, text, text, date, text
) FROM public;
GRANT  EXECUTE ON FUNCTION public.commit_fs_upload(
  uuid, uuid, uuid, text, text, text, bigint, text, text, text, date, text
) TO authenticated;
