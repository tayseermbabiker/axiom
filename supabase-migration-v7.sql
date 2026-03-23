-- ============================================================
-- MIGRATION v7: Trial expiry on organizations
-- Run in Supabase SQL Editor
-- ============================================================

-- Add trial_expires_at to organizations (3 months from creation)
alter table organizations add column if not exists trial_expires_at timestamptz;

-- Set existing orgs to expire 3 months from now
update organizations set trial_expires_at = now() + interval '3 months' where trial_expires_at is null;
