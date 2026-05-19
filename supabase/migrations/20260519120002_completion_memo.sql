-- Sprint 1 — Engagement Completion Memorandum + Attestations
-- One memo row per engagement. 13 attestation rows per memo, ticked by the engagement admin.
-- Rollup fields are computed live while memo is in 'draft'; snapshotted when 'locked'.

-- =========================================================================
-- TABLE: engagement_completion_memo
-- =========================================================================
CREATE TABLE public.engagement_completion_memo (
  id                                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  engagement_id                     uuid NOT NULL UNIQUE
                                      REFERENCES public.engagements(id) ON DELETE CASCADE,
  organization_id                   uuid NOT NULL
                                      REFERENCES public.organizations(id) ON DELETE CASCADE,

  status                            text NOT NULL DEFAULT 'draft'
                                      CHECK (status IN ('draft','complete','locked')),

  -- Rollup fields (refreshed by trigger while status='draft', frozen at 'locked')
  total_sections                    int NOT NULL DEFAULT 0,
  sections_approved                 int NOT NULL DEFAULT 0,
  sections_with_open_issues         int NOT NULL DEFAULT 0,

  total_findings                    int NOT NULL DEFAULT 0,
  findings_resolved                 int NOT NULL DEFAULT 0,
  findings_reported                 int NOT NULL DEFAULT 0,
  findings_open                     int NOT NULL DEFAULT 0,

  total_misstatements               int NOT NULL DEFAULT 0,
  posted_adjustments                int NOT NULL DEFAULT 0,
  unposted_adjustments              int NOT NULL DEFAULT 0,

  -- Materiality snapshot — copied from engagements.materiality_overall /
  -- engagements.materiality_performance when the memo is locked.
  overall_materiality_snapshot      numeric,
  performance_materiality_snapshot  numeric,

  uncorrected_vs_materiality        text
                                      CHECK (uncorrected_vs_materiality IN
                                        ('below','approaching','exceeds','not_calculated')),

  -- EQR / EQCR (ISQM 2 / ISA 220 Revised)
  eqr_required                      boolean NOT NULL DEFAULT false,
  eqr_reviewer_id                   uuid REFERENCES public.profiles(id),
  eqr_completed_at                  timestamptz,
  eqr_completed_by                  uuid REFERENCES public.profiles(id),

  -- Narrative conclusions
  going_concern_conclusion          text,
  subsequent_events_conclusion      text,
  other_matters                     text,

  -- Opinion basis
  opinion_type                      text
                                      CHECK (opinion_type IN
                                        ('unmodified','qualified','adverse','disclaimer')),
  opinion_basis_notes               text,

  -- Sign-off gate
  all_attestations_complete         boolean NOT NULL DEFAULT false,
  signed_by                         uuid REFERENCES public.profiles(id),
  signed_at                         timestamptz,
  snapshot_taken_at                 timestamptz,

  created_at                        timestamptz NOT NULL DEFAULT now(),
  updated_at                        timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_ecm_engagement_id   ON public.engagement_completion_memo(engagement_id);
CREATE INDEX idx_ecm_organization_id ON public.engagement_completion_memo(organization_id);
CREATE INDEX idx_ecm_status          ON public.engagement_completion_memo(status);

ALTER TABLE public.engagement_completion_memo ENABLE ROW LEVEL SECURITY;

CREATE POLICY ecm_select ON public.engagement_completion_memo
  FOR SELECT
  USING (organization_id IN (SELECT public.get_user_org_ids()));

-- Pro tier required to CREATE memos. Reading existing memos stays open to
-- all org members (so an org that downgrades doesn't lose access to history).
CREATE POLICY ecm_insert ON public.engagement_completion_memo
  FOR INSERT
  WITH CHECK (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.org_has_pro_tier(organization_id)
  );

CREATE POLICY ecm_update ON public.engagement_completion_memo
  FOR UPDATE
  USING (organization_id IN (SELECT public.get_user_org_ids()));

-- Explicit GRANTs (Supabase Data API GRANT cutover compliance)
GRANT SELECT, INSERT, UPDATE ON public.engagement_completion_memo TO authenticated;


-- =========================================================================
-- TABLE: completion_attestations  (child of engagement_completion_memo)
-- 13 rows seeded per memo by seed_attestations_for_memo() — see migration 6.
-- =========================================================================
CREATE TABLE public.completion_attestations (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  memo_id               uuid NOT NULL
                          REFERENCES public.engagement_completion_memo(id) ON DELETE CASCADE,
  organization_id       uuid NOT NULL
                          REFERENCES public.organizations(id) ON DELETE CASCADE,
  engagement_id         uuid NOT NULL
                          REFERENCES public.engagements(id) ON DELETE CASCADE,

  attestation_key       text NOT NULL,
  attestation_order     int  NOT NULL,
  isa_reference         text NOT NULL,
  source_table          text,
  source_check          text,

  system_check_passed   boolean,
  system_checked_at     timestamptz,

  attested_by           uuid REFERENCES public.profiles(id),
  attested_at           timestamptz,

  created_at            timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX        idx_ca_memo_id        ON public.completion_attestations(memo_id);
CREATE INDEX        idx_ca_engagement_id  ON public.completion_attestations(engagement_id);
CREATE UNIQUE INDEX idx_ca_memo_key       ON public.completion_attestations(memo_id, attestation_key);

ALTER TABLE public.completion_attestations ENABLE ROW LEVEL SECURITY;

CREATE POLICY ca_select ON public.completion_attestations
  FOR SELECT
  USING (organization_id IN (SELECT public.get_user_org_ids()));

CREATE POLICY ca_insert ON public.completion_attestations
  FOR INSERT
  WITH CHECK (
    organization_id IN (SELECT public.get_user_org_ids())
    AND public.org_has_pro_tier(organization_id)
  );

CREATE POLICY ca_update ON public.completion_attestations
  FOR UPDATE
  USING (organization_id IN (SELECT public.get_user_org_ids()));

GRANT SELECT, INSERT, UPDATE ON public.completion_attestations TO authenticated;
