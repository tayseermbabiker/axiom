-- =====================================================================
-- STAGING BOOTSTRAP — Audexon v0.5 minimum schema
-- Run this ONCE in the staging Supabase SQL Editor before applying the
-- Sprint 1 migrations. It recreates the existing v0.5 tables so the
-- new Sprint 1 tables have valid foreign-key targets.
--
-- This is NOT a perfect mirror of production. It deliberately omits:
--   - Prod RLS policies on existing tables (Sprint 1 only needs its own)
--   - Prod triggers (immutable timestamps, seat enforcement, activity log)
--   - Indexes beyond primary keys (testing doesn't need them)
-- Only columns, CHECK constraints, primary keys, and foreign keys are
-- recreated — enough for Sprint 1 functional testing.
-- =====================================================================

-- Extension required for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ---------------------------------------------------------------------
-- profiles  (one row per Supabase auth.users)
-- ---------------------------------------------------------------------
CREATE TABLE public.profiles (
  id           uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email        text NOT NULL,
  full_name    text NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- organizations  (the audit firm)
-- ---------------------------------------------------------------------
CREATE TABLE public.organizations (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name               text NOT NULL,
  plan               text NOT NULL DEFAULT 'starter'
                       CHECK (plan IN ('starter','team','firm')),
  max_members        integer NOT NULL DEFAULT 5,
  created_by         uuid NOT NULL REFERENCES public.profiles(id),
  created_at         timestamptz NOT NULL DEFAULT now(),
  trial_expires_at   timestamptz,
  stripe_customer_id text,
  country            text
);

-- ---------------------------------------------------------------------
-- organization_members  (user ↔ org link with role)
-- ---------------------------------------------------------------------
CREATE TABLE public.organization_members (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  user_id         uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role            text NOT NULL
                    CHECK (role IN ('admin','supervisor','preparer')),
  created_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (organization_id, user_id)
);

-- ---------------------------------------------------------------------
-- organization_invites
-- ---------------------------------------------------------------------
CREATE TABLE public.organization_invites (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  email           text NOT NULL,
  role            text NOT NULL
                    CHECK (role IN ('admin','supervisor','preparer')),
  invited_by      uuid NOT NULL REFERENCES public.profiles(id),
  status          text NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending','accepted','expired')),
  created_at      timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- engagements  (one per client × year-end)
-- ---------------------------------------------------------------------
CREATE TABLE public.engagements (
  id                       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id          uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  client_name              text NOT NULL,
  year_end_date            date NOT NULL,
  engagement_type          text NOT NULL DEFAULT 'audit'
                             CHECK (engagement_type IN ('audit','review','compilation')),
  status                   text NOT NULL DEFAULT 'active'
                             CHECK (status IN ('active','completed','archived')),
  created_by               uuid NOT NULL REFERENCES public.profiles(id),
  created_at               timestamptz NOT NULL DEFAULT now(),
  shared_folder_url        text,
  closed_by                uuid REFERENCES public.profiles(id),
  closed_at                timestamptz,
  close_acknowledgment     text,

  -- Materiality (already present in production)
  materiality_benchmark    text,
  materiality_amount       numeric,
  materiality_pct          numeric,
  materiality_perf_pct     numeric,
  materiality_overall      numeric,
  materiality_performance  numeric,
  materiality_trivial      numeric,
  materiality_trivial_pct  numeric,
  materiality_rationale    text
);

-- ---------------------------------------------------------------------
-- tb_versions  (Trial Balance versions per engagement)
-- ---------------------------------------------------------------------
CREATE TABLE public.tb_versions (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  engagement_id uuid NOT NULL REFERENCES public.engagements(id) ON DELETE CASCADE,
  label         text NOT NULL,
  uploaded_by   uuid REFERENCES public.profiles(id),
  uploaded_at   timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- trial_balance_lines
-- ---------------------------------------------------------------------
CREATE TABLE public.trial_balance_lines (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  engagement_id  uuid NOT NULL REFERENCES public.engagements(id) ON DELETE CASCADE,
  account_code   text NOT NULL,
  account_name   text NOT NULL,
  balance        numeric NOT NULL,
  classification text NOT NULL,
  created_at     timestamptz NOT NULL DEFAULT now(),
  tb_version_id  uuid REFERENCES public.tb_versions(id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
-- audit_sections  (19 seeded per engagement; 20th added by Sprint 1)
-- ---------------------------------------------------------------------
CREATE TABLE public.audit_sections (
  id                       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  engagement_id            uuid NOT NULL REFERENCES public.engagements(id) ON DELETE CASCADE,
  name                     text NOT NULL,
  assigned_to              uuid REFERENCES public.profiles(id),
  status                   text NOT NULL DEFAULT 'not_started'
                             CHECK (status IN (
                               'not_started','in_progress',
                               'ready_for_supervisor_review','in_supervisor_review',
                               'ready_for_partner_review','in_partner_review',
                               'returned_to_preparer','returned_to_supervisor',
                               'approved')),
  conclusion               text,
  conclusion_by            uuid REFERENCES public.profiles(id),
  approved_by              uuid REFERENCES public.profiles(id),
  approved_at              timestamptz,
  sort_order               integer,
  created_at               timestamptz DEFAULT now(),
  updated_at               timestamptz DEFAULT now(),
  classification_tags      text[],
  assertions               text[],
  supervisor_approved_by   uuid REFERENCES public.profiles(id),
  supervisor_approved_at   timestamptz,
  partner_approved_by      uuid REFERENCES public.profiles(id),
  partner_approved_at      timestamptz,
  phase                    text NOT NULL DEFAULT 'final'
                             CHECK (phase IN ('interim','final')),
  tb_version_id            uuid REFERENCES public.tb_versions(id)
);

-- ---------------------------------------------------------------------
-- audit_procedures  (5-10 per section)
-- ---------------------------------------------------------------------
CREATE TABLE public.audit_procedures (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  section_id     uuid NOT NULL REFERENCES public.audit_sections(id) ON DELETE CASCADE,
  description    text NOT NULL,
  procedure_type text NOT NULL DEFAULT 'other'
                   CHECK (procedure_type IN ('test_of_detail','analytical','controls','other')),
  sort_order     integer,
  created_at     timestamptz DEFAULT now(),
  assertions     text[]
);

-- ---------------------------------------------------------------------
-- procedure_responses
-- ---------------------------------------------------------------------
CREATE TABLE public.procedure_responses (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  procedure_id uuid NOT NULL REFERENCES public.audit_procedures(id) ON DELETE CASCADE,
  user_id      uuid NOT NULL REFERENCES public.profiles(id),
  response     text NOT NULL,
  status       text NOT NULL DEFAULT 'pending'
                 CHECK (status IN ('pending','done')),
  created_at   timestamptz DEFAULT now(),
  updated_at   timestamptz DEFAULT now()
);

-- ---------------------------------------------------------------------
-- findings  (ISA 230 / 265 / 450)
-- ---------------------------------------------------------------------
CREATE TABLE public.findings (
  id                          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  section_id                  uuid NOT NULL REFERENCES public.audit_sections(id) ON DELETE CASCADE,
  procedure_id                uuid REFERENCES public.audit_procedures(id),
  reported_by                 uuid NOT NULL REFERENCES public.profiles(id),
  title                       text NOT NULL,
  condition                   text,
  criteria                    text,
  cause                       text,
  effect                      text,
  recommendation              text,
  management_response         text,
  severity                    text NOT NULL
                                CHECK (severity IN ('high','medium','low')),
  status                      text NOT NULL DEFAULT 'open'
                                CHECK (status IN ('open','resolved','reported')),
  monetary_impact             numeric,
  created_at                  timestamptz DEFAULT now(),
  updated_at                  timestamptz DEFAULT now(),
  finding_type                text NOT NULL
                                CHECK (finding_type IN ('misstatement','control_deficiency','observation')),
  is_management_letter_point  boolean NOT NULL DEFAULT false,
  identified_in_phase         text NOT NULL
                                CHECK (identified_in_phase IN ('interim','final')),
  close_category              text
                                CHECK (close_category IS NULL OR close_category IN (
                                  'unadjusted_immaterial',
                                  'communicated_to_management',
                                  'control_deficiency_communicated',
                                  'control_deficiency_significant',
                                  'observation_no_action'))
);

-- findings.engagement_id is NOT in production — derived via section_id → audit_sections.engagement_id.
-- All Sprint 1 queries that count findings per engagement join through audit_sections.

-- ---------------------------------------------------------------------
-- adjusting_entries  (linked to misstatement findings)
-- ---------------------------------------------------------------------
CREATE TABLE public.adjusting_entries (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  finding_id      uuid NOT NULL REFERENCES public.findings(id) ON DELETE CASCADE,
  debit_account   text NOT NULL,
  credit_account  text NOT NULL,
  amount          numeric NOT NULL,
  narration       text,
  is_posted       boolean NOT NULL DEFAULT false,
  created_at      timestamptz DEFAULT now()
);

-- ---------------------------------------------------------------------
-- documents  (attached to sections or procedure responses)
-- ---------------------------------------------------------------------
CREATE TABLE public.documents (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  section_id            uuid REFERENCES public.audit_sections(id) ON DELETE CASCADE,
  procedure_response_id uuid REFERENCES public.procedure_responses(id) ON DELETE CASCADE,
  file_name             text NOT NULL,
  file_url              text NOT NULL,
  source_type           text NOT NULL
                          CHECK (source_type IN ('google_drive','onedrive','sharepoint','dropbox','other')),
  file_type             text NOT NULL
                          CHECK (file_type IN ('pdf','image','excel','word','other')),
  linked_by             uuid NOT NULL REFERENCES public.profiles(id),
  created_at            timestamptz NOT NULL DEFAULT now(),
  doc_category          text NOT NULL
                          CHECK (doc_category IN ('working_paper','source_document')),
  description           text,
  CHECK (section_id IS NOT NULL OR procedure_response_id IS NOT NULL)
);

-- ---------------------------------------------------------------------
-- review_notes  (immutable thread per section)
-- ---------------------------------------------------------------------
CREATE TABLE public.review_notes (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  section_id  uuid NOT NULL REFERENCES public.audit_sections(id) ON DELETE CASCADE,
  user_id     uuid NOT NULL REFERENCES public.profiles(id),
  note        text NOT NULL,
  note_type   text NOT NULL
                CHECK (note_type IN ('review_comment','preparer_response','return_reason')),
  created_at  timestamptz DEFAULT now()
);

-- ---------------------------------------------------------------------
-- activity_log  (immutable audit trail per engagement)
-- ---------------------------------------------------------------------
CREATE TABLE public.activity_log (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  engagement_id uuid NOT NULL REFERENCES public.engagements(id) ON DELETE CASCADE,
  user_id       uuid NOT NULL REFERENCES public.profiles(id),
  action        text NOT NULL,
  target_type   text NOT NULL
                  CHECK (target_type IN (
                    'engagement','trial_balance','document','review_note',
                    'organization','member','section','procedure',
                    'finding','response','procedure_response')),
  target_id     uuid NOT NULL,
  details       jsonb,
  created_at    timestamptz NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- Done. Staging now has the v0.5 minimum schema. Apply Sprint 1
-- migrations next (in order, 7 files starting with feature_tier).
-- ---------------------------------------------------------------------
