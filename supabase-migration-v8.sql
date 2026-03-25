-- ============================================================
-- MIGRATION v8: Materiality fields on engagements
-- Run in Supabase SQL Editor
-- ============================================================

alter table engagements add column if not exists materiality_benchmark text;
alter table engagements add column if not exists materiality_amount numeric;
alter table engagements add column if not exists materiality_pct numeric;
alter table engagements add column if not exists materiality_perf_pct numeric default 75;
alter table engagements add column if not exists materiality_overall numeric;
alter table engagements add column if not exists materiality_performance numeric;
alter table engagements add column if not exists materiality_trivial numeric;
alter table engagements add column if not exists materiality_rationale text default '';
