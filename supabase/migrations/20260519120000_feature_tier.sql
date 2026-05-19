-- Sprint 1 — Feature tier on organizations.
-- Distinguishes Essentials (current v0.5 product) from Pro (methodology layer).
-- 'plan' column stays as the seat-size tier (starter/team/firm).
-- 'feature_tier' is orthogonal — the methodology layer flag.
--
-- Pro features (gated in UI + reinforced by helper function):
--   - Engagement Completion Memorandum + EQR
--   - Local Compliance custom section
--   - Future: Planning + Materiality (full) + Risk Assessment + Inspection-ready PDF
--
-- Essentials features (always on, today's product):
--   - TB import, 19 sections, procedures, findings, sign-off, FS upload, activity log

ALTER TABLE public.organizations
  ADD COLUMN IF NOT EXISTS feature_tier text NOT NULL DEFAULT 'essentials'
    CHECK (feature_tier IN ('essentials','pro'));

-- Helper used by application and (optionally) by RLS / SQL functions
CREATE OR REPLACE FUNCTION public.org_has_pro_tier(p_organization_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.organizations
    WHERE id = p_organization_id
      AND feature_tier = 'pro'
  );
$$;

REVOKE EXECUTE ON FUNCTION public.org_has_pro_tier(uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.org_has_pro_tier(uuid) TO authenticated;
