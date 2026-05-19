-- Migration v12: Add country to organizations
--
-- Records which country each firm operates from. Used for marketing
-- focus, pricing decisions, and localization signals. Stored as ISO
-- 3166-1 alpha-2 codes (AE, SA, QA, etc.) plus the literal 'OTHER'
-- fallback.
--
-- New signups will be required to pick a country (enforced client-side
-- in onboarding.html). Existing firms keep country = NULL until they
-- choose to update it manually.
--
-- Run this in Supabase SQL Editor before deploying the country
-- dropdown UI change, otherwise the firm-creation insert will fail.

alter table organizations
  add column if not exists country text;
