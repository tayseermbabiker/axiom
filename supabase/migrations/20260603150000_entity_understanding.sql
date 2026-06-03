-- Understanding the entity (reviewer #2, ISA 315 Revised 2019 para 19). Structured "nature of the
-- entity" profile added to the audit-strategy workpaper (integrated, not a separate file — IFAC SME
-- guide). Additive text columns. MENA-agnostic.

alter table public.engagement_audit_strategies
  add column if not exists entity_business_model        text,  -- 19(a) business model & operations
  add column if not exists entity_ownership_governance  text,  -- 19(a) organizational structure / ownership / governance
  add column if not exists entity_locations             text,  -- 19(a) locations / branches / components
  add column if not exists entity_it_environment        text,  -- 19(a) use of IT
  add column if not exists entity_objectives_strategies text,  -- 19(a) objectives, strategies & business risks
  add column if not exists entity_performance_measures  text;  -- 19(c) measures used to assess financial performance
