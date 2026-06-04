-- Per-procedure assertion tagging (ISA 315 A190 assertions)
-- Spec: specs/procedure-assertion-tagging-2026-06.md
-- Origin: demo 2026-06-03 — restore the per-procedure assertion tag that the
-- procedure-library rewrite dropped (breadcrumb at section.html:1509).
--
-- 3-AI verified 2026-06-04: Perplexity + Gemini (ISA conformance — split
-- existence/occurrence, add FS-level/pervasive for going concern, relabel the
-- "other" type as Risk Assessment/Admin), Copilot (text[] + GIN, optional <@
-- CHECK, forward-only seeding safe, locking obeys existing section pattern).
--
-- Vocabulary: 9 assertions + 1 level tag (fs_level). engagement_risks keeps its
-- original 8 (no occurrence) — procedures are a separate field; aligning the
-- risk table is a later optional change.
--
-- Forward-only: existing audit_procedures rows keep assertions = '{}' (render
-- degrades to no chips). New engagements seed tags from PROCEDURE_ASSERTIONS.

ALTER TABLE public.audit_procedures
  ADD COLUMN IF NOT EXISTS assertions text[] NOT NULL DEFAULT '{}';

-- GIN index supports "procedures testing assertion X" (&&/ANY) queries cheaply.
CREATE INDEX IF NOT EXISTS audit_procedures_assertions_gin_idx
  ON public.audit_procedures USING gin (assertions);

-- Future-proof: every element must be a known code (cheap; UI already restricts).
ALTER TABLE public.audit_procedures
  DROP CONSTRAINT IF EXISTS audit_procedures_assertions_valid;
ALTER TABLE public.audit_procedures
  ADD CONSTRAINT audit_procedures_assertions_valid
  CHECK (
    assertions <@ ARRAY[
      'existence','occurrence','completeness','accuracy','valuation',
      'cutoff','classification','rights_obligations','presentation','fs_level'
    ]::text[]
  );
