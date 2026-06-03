-- AML/KYC v2 (post-demo redesign + carry-forward). Keeps the module LEAN and audit-oriented
-- (DNFBP CDD, not bank KYC). MENA-agnostic. Additive only — heavier fields from v1 are simply
-- hidden in the UI (not dropped), so this migration adds columns, never removes.
--
-- Adds: structured screening result, evidence links (Drive/OneDrive — on-brand link-not-store),
-- high-risk-jurisdiction flag, and continuance carry-forward fields.

alter table public.engagement_aml_cdd
  -- Structured screening outcome (replaces relying on the free-text results box)
  add column if not exists screening_result text
    check (screening_result is null or screening_result in ('clear','hit_false_positive','hit_true_match')),
  -- Evidence links (client cloud — Audexon links, does not store the document)
  add column if not exists screening_evidence_url text,
  add column if not exists license_evidence_url   text,
  add column if not exists ownership_evidence_url  text,
  -- Geography risk
  add column if not exists high_risk_jurisdiction boolean not null default false,
  -- Continuance / carry-forward (initial vs recurring engagement)
  add column if not exists cdd_basis text
    check (cdd_basis is null or cdd_basis in ('initial','continuance')),
  add column if not exists no_changes_confirmed boolean not null default false,
  add column if not exists carried_forward_from uuid references public.engagement_aml_cdd(id) on delete set null;

comment on column public.engagement_aml_cdd.screening_result is 'clear | hit_false_positive | hit_true_match (sanctions/PEP/adverse-media screening outcome).';
comment on column public.engagement_aml_cdd.cdd_basis is 'initial = first engagement; continuance = recurring client (identity/UBO carried forward, refreshed).';
comment on column public.engagement_aml_cdd.no_changes_confirmed is 'Continuance: auditor confirmed no change to identity/ownership since the prior CDD.';
