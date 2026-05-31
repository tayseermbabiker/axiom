-- Sprint 1 — Financial Statements upload slot (metadata only).
-- Files stored in Supabase Storage bucket 'fs-documents' (created out-of-band).
-- Multiple draft/final_for_review versions allowed. One active 'signed' enforced
-- via partial unique index.

CREATE TABLE public.engagement_fs_uploads (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  engagement_id   uuid NOT NULL REFERENCES public.engagements(id)   ON DELETE CASCADE,
  organization_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,

  version_type    text NOT NULL
                    CHECK (version_type IN ('draft','final_for_review','signed')),

  file_name       text NOT NULL,
  file_path       text NOT NULL,
  file_size_bytes bigint,
  mime_type       text,

  version_label   text,

  uploaded_by     uuid NOT NULL REFERENCES public.profiles(id),
  uploaded_at     timestamptz NOT NULL DEFAULT now(),

  is_superseded   boolean NOT NULL DEFAULT false,
  superseded_at   timestamptz,
  superseded_by   uuid REFERENCES public.profiles(id),

  notes           text,
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_efu_engagement_id    ON public.engagement_fs_uploads(engagement_id);
CREATE INDEX idx_efu_organization_id  ON public.engagement_fs_uploads(organization_id);
CREATE INDEX idx_efu_version_type     ON public.engagement_fs_uploads(engagement_id, version_type);

-- At most one non-superseded 'signed' upload per engagement
CREATE UNIQUE INDEX idx_efu_one_active_signed
  ON public.engagement_fs_uploads(engagement_id)
  WHERE version_type = 'signed' AND is_superseded = false;

ALTER TABLE public.engagement_fs_uploads ENABLE ROW LEVEL SECURITY;

CREATE POLICY efu_select ON public.engagement_fs_uploads
  FOR SELECT
  USING (organization_id IN (SELECT public.get_user_org_ids()));

CREATE POLICY efu_insert ON public.engagement_fs_uploads
  FOR INSERT
  WITH CHECK (organization_id IN (SELECT public.get_user_org_ids()));

CREATE POLICY efu_update ON public.engagement_fs_uploads
  FOR UPDATE
  USING (organization_id IN (SELECT public.get_user_org_ids()));

GRANT SELECT, INSERT, UPDATE ON public.engagement_fs_uploads TO authenticated;

-- =========================================================================
-- STORAGE BUCKET 'fs-documents'  (create separately in Supabase dashboard
-- or via the Supabase Management API, then apply the policies below).
-- Path convention: {organization_id}/{engagement_id}/{upload_id}.{ext}
-- =========================================================================
--
-- Bucket settings (set in Supabase dashboard):
--   public:               false
--   file_size_limit:      52428800   -- 50 MB
--   allowed_mime_types:   application/pdf,
--                         application/vnd.openxmlformats-officedocument.wordprocessingml.document,
--                         application/msword
--
-- Storage RLS policy (run in Supabase SQL editor against storage schema
-- AFTER the bucket exists — uncomment and run):
--
-- CREATE POLICY "fs_documents_select_own_org" ON storage.objects
--   FOR SELECT
--   USING (
--     bucket_id = 'fs-documents'
--     AND (storage.foldername(name))[1] IN (
--       SELECT organization_id::text
--       FROM public.organization_members
--       WHERE user_id = auth.uid()
--     )
--   );
--
-- CREATE POLICY "fs_documents_insert_own_org" ON storage.objects
--   FOR INSERT
--   WITH CHECK (
--     bucket_id = 'fs-documents'
--     AND (storage.foldername(name))[1] IN (
--       SELECT organization_id::text
--       FROM public.organization_members
--       WHERE user_id = auth.uid()
--     )
--   );
--
-- No DELETE policy — soft-delete only via engagement_fs_uploads.is_superseded.
