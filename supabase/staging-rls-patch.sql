-- =====================================================================
-- STAGING RLS PATCH
-- Run this in the STAGING Supabase SQL editor only.
-- Adds basic org-isolation policies to the v0.5 tables so the existing
-- onboarding + engagement flows work. These are looser than production's
-- RLS — fine for staging testing, not a replacement for prod policies.
-- =====================================================================

-- Helper: turn on RLS on every v0.5 table (Sprint 1 tables already have it)
ALTER TABLE public.profiles              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organizations         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organization_members  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organization_invites  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.engagements           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tb_versions           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trial_balance_lines   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_sections        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_procedures      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.procedure_responses   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.findings              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.adjusting_entries     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.review_notes          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_log          ENABLE ROW LEVEL SECURITY;

-- =====================================================================
-- profiles  (everyone reads, self-insert + self-update)
-- =====================================================================
CREATE POLICY profiles_select ON public.profiles
  FOR SELECT USING (true);

CREATE POLICY profiles_insert ON public.profiles
  FOR INSERT WITH CHECK (id = auth.uid());

CREATE POLICY profiles_update ON public.profiles
  FOR UPDATE USING (id = auth.uid());

-- =====================================================================
-- organizations  (any authenticated user can create; only members can read)
-- =====================================================================
CREATE POLICY organizations_select ON public.organizations
  FOR SELECT
  USING (id IN (SELECT public.get_user_org_ids()));

CREATE POLICY organizations_insert ON public.organizations
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY organizations_update ON public.organizations
  FOR UPDATE
  USING (id IN (SELECT public.get_user_org_ids()));

-- =====================================================================
-- organization_members  (any authed user can add themselves; org members read)
-- =====================================================================
CREATE POLICY orgmembers_select ON public.organization_members
  FOR SELECT
  USING (
    user_id = auth.uid()
    OR organization_id IN (SELECT public.get_user_org_ids())
  );

CREATE POLICY orgmembers_insert ON public.organization_members
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY orgmembers_update ON public.organization_members
  FOR UPDATE
  USING (organization_id IN (SELECT public.get_user_org_ids()));

CREATE POLICY orgmembers_delete ON public.organization_members
  FOR DELETE
  USING (organization_id IN (SELECT public.get_user_org_ids()));

-- =====================================================================
-- organization_invites  (org members manage)
-- =====================================================================
CREATE POLICY invites_select ON public.organization_invites
  FOR SELECT
  USING (organization_id IN (SELECT public.get_user_org_ids()));

CREATE POLICY invites_insert ON public.organization_invites
  FOR INSERT
  WITH CHECK (organization_id IN (SELECT public.get_user_org_ids()));

CREATE POLICY invites_update ON public.organization_invites
  FOR UPDATE
  USING (organization_id IN (SELECT public.get_user_org_ids()));

-- =====================================================================
-- engagements
-- =====================================================================
CREATE POLICY engagements_select ON public.engagements
  FOR SELECT
  USING (organization_id IN (SELECT public.get_user_org_ids()));

CREATE POLICY engagements_insert ON public.engagements
  FOR INSERT
  WITH CHECK (organization_id IN (SELECT public.get_user_org_ids()));

CREATE POLICY engagements_update ON public.engagements
  FOR UPDATE
  USING (organization_id IN (SELECT public.get_user_org_ids()));

CREATE POLICY engagements_delete ON public.engagements
  FOR DELETE
  USING (organization_id IN (SELECT public.get_user_org_ids()));

-- =====================================================================
-- tb_versions / trial_balance_lines  (members of engagement's org)
-- =====================================================================
CREATE POLICY tbv_all ON public.tb_versions
  FOR ALL
  USING (
    engagement_id IN (
      SELECT id FROM public.engagements
      WHERE organization_id IN (SELECT public.get_user_org_ids())
    )
  )
  WITH CHECK (
    engagement_id IN (
      SELECT id FROM public.engagements
      WHERE organization_id IN (SELECT public.get_user_org_ids())
    )
  );

CREATE POLICY tbl_all ON public.trial_balance_lines
  FOR ALL
  USING (
    engagement_id IN (
      SELECT id FROM public.engagements
      WHERE organization_id IN (SELECT public.get_user_org_ids())
    )
  )
  WITH CHECK (
    engagement_id IN (
      SELECT id FROM public.engagements
      WHERE organization_id IN (SELECT public.get_user_org_ids())
    )
  );

-- =====================================================================
-- audit_sections / audit_procedures / procedure_responses
-- =====================================================================
CREATE POLICY sections_all ON public.audit_sections
  FOR ALL
  USING (
    engagement_id IN (
      SELECT id FROM public.engagements
      WHERE organization_id IN (SELECT public.get_user_org_ids())
    )
  )
  WITH CHECK (
    engagement_id IN (
      SELECT id FROM public.engagements
      WHERE organization_id IN (SELECT public.get_user_org_ids())
    )
  );

CREATE POLICY procedures_all ON public.audit_procedures
  FOR ALL
  USING (
    section_id IN (
      SELECT id FROM public.audit_sections
      WHERE engagement_id IN (
        SELECT id FROM public.engagements
        WHERE organization_id IN (SELECT public.get_user_org_ids())
      )
    )
  )
  WITH CHECK (
    section_id IN (
      SELECT id FROM public.audit_sections
      WHERE engagement_id IN (
        SELECT id FROM public.engagements
        WHERE organization_id IN (SELECT public.get_user_org_ids())
      )
    )
  );

CREATE POLICY responses_all ON public.procedure_responses
  FOR ALL
  USING (
    procedure_id IN (
      SELECT ap.id FROM public.audit_procedures ap
      JOIN public.audit_sections asec ON asec.id = ap.section_id
      JOIN public.engagements e       ON e.id    = asec.engagement_id
      WHERE e.organization_id IN (SELECT public.get_user_org_ids())
    )
  )
  WITH CHECK (
    procedure_id IN (
      SELECT ap.id FROM public.audit_procedures ap
      JOIN public.audit_sections asec ON asec.id = ap.section_id
      JOIN public.engagements e       ON e.id    = asec.engagement_id
      WHERE e.organization_id IN (SELECT public.get_user_org_ids())
    )
  );

-- =====================================================================
-- findings / adjusting_entries
-- =====================================================================
CREATE POLICY findings_all ON public.findings
  FOR ALL
  USING (
    section_id IN (
      SELECT id FROM public.audit_sections
      WHERE engagement_id IN (
        SELECT id FROM public.engagements
        WHERE organization_id IN (SELECT public.get_user_org_ids())
      )
    )
  )
  WITH CHECK (
    section_id IN (
      SELECT id FROM public.audit_sections
      WHERE engagement_id IN (
        SELECT id FROM public.engagements
        WHERE organization_id IN (SELECT public.get_user_org_ids())
      )
    )
  );

CREATE POLICY adj_entries_all ON public.adjusting_entries
  FOR ALL
  USING (
    finding_id IN (
      SELECT f.id FROM public.findings f
      JOIN public.audit_sections asec ON asec.id = f.section_id
      JOIN public.engagements e       ON e.id    = asec.engagement_id
      WHERE e.organization_id IN (SELECT public.get_user_org_ids())
    )
  )
  WITH CHECK (
    finding_id IN (
      SELECT f.id FROM public.findings f
      JOIN public.audit_sections asec ON asec.id = f.section_id
      JOIN public.engagements e       ON e.id    = asec.engagement_id
      WHERE e.organization_id IN (SELECT public.get_user_org_ids())
    )
  );

-- =====================================================================
-- documents / review_notes / activity_log
-- =====================================================================
CREATE POLICY documents_all ON public.documents
  FOR ALL
  USING (
    section_id IS NULL OR section_id IN (
      SELECT id FROM public.audit_sections
      WHERE engagement_id IN (
        SELECT id FROM public.engagements
        WHERE organization_id IN (SELECT public.get_user_org_ids())
      )
    )
  )
  WITH CHECK (
    section_id IS NULL OR section_id IN (
      SELECT id FROM public.audit_sections
      WHERE engagement_id IN (
        SELECT id FROM public.engagements
        WHERE organization_id IN (SELECT public.get_user_org_ids())
      )
    )
  );

CREATE POLICY reviewnotes_all ON public.review_notes
  FOR ALL
  USING (
    section_id IN (
      SELECT id FROM public.audit_sections
      WHERE engagement_id IN (
        SELECT id FROM public.engagements
        WHERE organization_id IN (SELECT public.get_user_org_ids())
      )
    )
  )
  WITH CHECK (
    section_id IN (
      SELECT id FROM public.audit_sections
      WHERE engagement_id IN (
        SELECT id FROM public.engagements
        WHERE organization_id IN (SELECT public.get_user_org_ids())
      )
    )
  );

CREATE POLICY activity_log_all ON public.activity_log
  FOR ALL
  USING (
    engagement_id IN (
      SELECT id FROM public.engagements
      WHERE organization_id IN (SELECT public.get_user_org_ids())
    )
  )
  WITH CHECK (
    engagement_id IN (
      SELECT id FROM public.engagements
      WHERE organization_id IN (SELECT public.get_user_org_ids())
    )
  );

-- =====================================================================
-- Explicit GRANTs (Supabase Data API GRANT cutover compliance)
-- =====================================================================
GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles              TO authenticated;
GRANT SELECT, INSERT, UPDATE         ON public.organizations         TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.organization_members  TO authenticated;
GRANT SELECT, INSERT, UPDATE         ON public.organization_invites  TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.engagements           TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.tb_versions           TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.trial_balance_lines   TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.audit_sections        TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.audit_procedures      TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.procedure_responses   TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.findings              TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.adjusting_entries     TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.documents             TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.review_notes          TO authenticated;
GRANT SELECT, INSERT, UPDATE         ON public.activity_log          TO authenticated;
