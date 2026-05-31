-- Optional link to the returned confirmation document on the ISA 505 register.
-- Keeps Audexon on the link-based (zero-storage) evidence model: the register
-- row points to the signed confirmation letter held in the firm's own cloud
-- (Drive / OneDrive / SharePoint) instead of uploading/storing the file.
-- Existing table-level RLS and grants on engagement_confirmations cover the
-- new column; no new policy or grant needed.

ALTER TABLE public.engagement_confirmations
  ADD COLUMN IF NOT EXISTS document_url text;

COMMENT ON COLUMN public.engagement_confirmations.document_url IS
  'Optional link (Google Drive / OneDrive / SharePoint) to the returned confirmation document. Link only — Audexon stores the link, not the file.';
