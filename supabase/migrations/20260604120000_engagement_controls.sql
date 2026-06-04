-- Controls D&I Evaluation + Reliance Decision (ISA 315 D&I / ISA 330 / ISA 230 / ISA 500)
-- Spec: specs/controls-di-reliance-2026-06.md
-- Origin: demo 2026-06-03 — prospect asked whether the SaaS covers the controls
-- walkthrough / test-of-controls reliance decision.
--
-- 3-AI verified 2026-06-04: Perplexity (D&I mandatory every audit, free-text-only
-- = ISA 230/315 deficiency), Gemini (light fix defensible, "False Comfort Trap"
-- guard → reliance must NOT auto-drop substantive extent), Copilot (flat table +
-- 2 indexes, risk_id ON DELETE SET NULL, CHECK via Option A backfill, RLS runs
-- before triggers).
--
-- Anti-bloat (spec §1a): the substantive-only default needs ZERO control rows.
-- The engagement-level conclusion is the isa_315_controls_di_concluded attestation
-- below; control rows are added only when relevant controls actually exist.

-- =========================================================================
-- TABLE: engagement_controls
-- One row per RELEVANT control only (significant-risk controls, JE controls,
-- or any control planned for reliance). Not a per-cycle grid.
-- =========================================================================
CREATE TABLE public.engagement_controls (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  engagement_id         uuid NOT NULL REFERENCES public.engagements(id)   ON DELETE CASCADE,
  organization_id       uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  -- SET NULL (not CASCADE): deleting a risk must not silently erase documented
  -- control work. Orphaned controls (risk_id IS NULL) surface in the UI warning.
  risk_id               uuid REFERENCES public.engagement_risks(id) ON DELETE SET NULL,

  control_ref           text NOT NULL,
  process_cycle         text,
  assertions            text,
  control_type          text NOT NULL DEFAULT 'manual'
                          CHECK (control_type IN ('manual','automated','itgc')),

  walkthrough_performed boolean NOT NULL DEFAULT false,
  walkthrough_ref       text,

  design_conclusion     text CHECK (design_conclusion IN ('effective','deficient','not_applicable')),
  implementation        text CHECK (implementation   IN ('implemented','not_implemented')),

  -- Reliance decision. Defaults to no_reliance (the substantive-led SME norm).
  -- Toggling to rely/combined does NOT auto-reduce substantive extent — the UI
  -- raises a hardcoded warning to attach OE workpapers manually (OE engine deferred).
  reliance_decision     text NOT NULL DEFAULT 'no_reliance'
                          CHECK (reliance_decision IN ('no_reliance','rely','combined')),

  -- ISA 500: information produced by the entity used as audit evidence.
  ipte_relied           boolean NOT NULL DEFAULT false,
  ipte_assessment_note  text,

  notes                 text,

  created_by            uuid REFERENCES public.profiles(id),
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now()
);

-- Copilot R1: keep the inspection-PDF JOIN (control -> risk -> procedure) and the
-- "significant risk with no linked control" detection cheap.
CREATE INDEX idx_ec_engagement_id        ON public.engagement_controls(engagement_id);
CREATE INDEX idx_ec_organization_id      ON public.engagement_controls(organization_id);
CREATE INDEX idx_ec_risk_engagement      ON public.engagement_controls(risk_id, engagement_id);

ALTER TABLE public.engagement_controls ENABLE ROW LEVEL SECURITY;

-- RLS mirrors engagement_risks exactly (real helpers, not the generic names a
-- code reviewer might assume): get_user_org_ids / user_has_role_in_org / org_has_pro_tier.
CREATE POLICY ec_select ON public.engagement_controls
  FOR SELECT
  USING (organization_id IN (SELECT public.get_user_org_ids()));

CREATE POLICY ec_insert ON public.engagement_controls
  FOR INSERT
  WITH CHECK (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

CREATE POLICY ec_update ON public.engagement_controls
  FOR UPDATE
  USING (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

CREATE POLICY ec_delete ON public.engagement_controls
  FOR DELETE
  USING (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.user_has_role_in_org(organization_id, 'admin')
    AND public.org_has_pro_tier(organization_id)
  );

GRANT SELECT, INSERT, UPDATE, DELETE ON public.engagement_controls TO authenticated;

DROP TRIGGER IF EXISTS trg_ec_set_updated_at ON public.engagement_controls;
CREATE TRIGGER trg_ec_set_updated_at
  BEFORE UPDATE ON public.engagement_controls
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at_now();


-- =========================================================================
-- engagement_risk_assessment: add the controls D&I conclusion attestation.
-- Copilot R3 (Option A backfill): the existing confirmation CHECK is an UNNAMED
-- inline constraint — rather than guess its auto-generated name and risk dropping
-- the wrong one, add a SEPARATE named CHECK. Backfill existing confirmed rows to
-- true first so the new constraint validates against history (those engagements
-- were signed off before this methodology layer existed).
-- =========================================================================
ALTER TABLE public.engagement_risk_assessment
  ADD COLUMN IF NOT EXISTS isa_315_controls_di_concluded boolean NOT NULL DEFAULT false;

UPDATE public.engagement_risk_assessment
  SET isa_315_controls_di_concluded = true
  WHERE status = 'confirmed';

ALTER TABLE public.engagement_risk_assessment
  DROP CONSTRAINT IF EXISTS era_controls_di_concluded_chk;
ALTER TABLE public.engagement_risk_assessment
  ADD CONSTRAINT era_controls_di_concluded_chk
  CHECK (status <> 'confirmed' OR isa_315_controls_di_concluded = true);
