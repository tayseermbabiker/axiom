-- =========================================================================
-- Sprint 4 — ISA 530 Audit sampling documentation
-- (4-AI standards floor synthesis 2026-05-23).
-- =========================================================================
-- ISA 530 requires documenting: population, sampling method, sample size,
-- selection basis, results, and projection of misstatement when sampling
-- is used. Previously buried in procedure_responses free text — inspectors
-- can't trace the judgment.
--
-- Minimalist design per 4-AI synthesis: child table on procedure_id with
-- 9 fields, opened via a "Sampling" button on each procedure card. No
-- global sampling engine — per [[audexon-scope-freeze]].
--
-- 1:1 with procedure (UNIQUE on procedure_id) — a procedure either uses
-- sampling or it doesn't. Partner can edit, the form replaces.

CREATE TABLE public.procedure_sampling (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  procedure_id           uuid NOT NULL UNIQUE
                           REFERENCES public.audit_procedures(id) ON DELETE CASCADE,

  -- The 9 ISA 530 fields (Perplexity + Copilot converged)
  population_description text,
  population_size        numeric,
  sample_size            numeric,
  sampling_method        text
                           CHECK (sampling_method IS NULL
                             OR sampling_method IN
                               ('random','systematic','haphazard','monetary_unit','judgmental','other')),
  selection_basis        text,
  results_summary        text,
  projection_amount      numeric,
  conclusion             text,
  notes                  text,

  created_by             uuid REFERENCES public.profiles(id),
  created_at             timestamptz NOT NULL DEFAULT now(),
  updated_at             timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_psamp_procedure_id ON public.procedure_sampling(procedure_id);

ALTER TABLE public.procedure_sampling ENABLE ROW LEVEL SECURITY;

-- Follow the procedure_responses pattern: single FOR ALL policy that
-- derives org via procedure → section → engagement.
CREATE POLICY psamp_all ON public.procedure_sampling
  FOR ALL
  USING (
    procedure_id IN (
      SELECT ap.id FROM public.audit_procedures ap
      JOIN public.audit_sections asec ON asec.id = ap.section_id
      JOIN public.engagements e       ON e.id    = asec.engagement_id
      WHERE e.organization_id IN (SELECT public.get_user_org_ids())
    )
  );

GRANT SELECT, INSERT, UPDATE, DELETE ON public.procedure_sampling TO authenticated;

DROP TRIGGER IF EXISTS trg_psamp_set_updated_at ON public.procedure_sampling;
CREATE TRIGGER trg_psamp_set_updated_at
  BEFORE UPDATE ON public.procedure_sampling
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at_now();
