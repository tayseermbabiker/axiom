-- Staging setup for the 'fs-documents' Supabase Storage bucket.
-- Run AFTER creating the bucket in the Supabase dashboard with these settings:
--
--   Name:                 fs-documents
--   Public:               false
--   File size limit:      52428800   (50 MB)
--   Allowed MIME types:   application/pdf,
--                         application/vnd.openxmlformats-officedocument.wordprocessingml.document,
--                         application/msword
--
-- Path convention enforced by public/pages/engagement.html:
--   {organization_id}/{engagement_id}/{upload_id}.{ext}
--
-- These policies tie storage access to organization membership, mirroring the
-- public.engagement_fs_uploads RLS in migration 003. Soft-delete only.
--
-- Drop existing copies so this is rerunnable.

DROP POLICY IF EXISTS "fs_documents_select_own_org" ON storage.objects;
DROP POLICY IF EXISTS "fs_documents_insert_own_org" ON storage.objects;

CREATE POLICY "fs_documents_select_own_org" ON storage.objects
  FOR SELECT
  USING (
    bucket_id = 'fs-documents'
    AND (storage.foldername(name))[1] IN (
      SELECT organization_id::text
      FROM public.organization_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "fs_documents_insert_own_org" ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'fs-documents'
    AND (storage.foldername(name))[1] IN (
      SELECT organization_id::text
      FROM public.organization_members
      WHERE user_id = auth.uid()
    )
  );
