-- ============================================================
-- MIGRATION v10 — Add stripe_customer_id to organizations
-- ============================================================
-- Used by:
--   1. stripe-webhook.js — saves the Stripe customer ID on
--      checkout.session.completed so we can look up the customer
--      later for the customer portal.
--   2. stripe-portal.js — looks up the customer ID to create a
--      Stripe Customer Portal session for self-serve billing.
--
-- Run this in Supabase SQL Editor.
-- ============================================================

alter table organizations
  add column if not exists stripe_customer_id text;

create index if not exists organizations_stripe_customer_id_idx
  on organizations (stripe_customer_id);
