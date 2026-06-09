-- Dashboard perf: one server-side aggregation instead of pulling every procedure,
-- response, and finding to the client and counting in JS. The old path ran 5
-- sequential queries with huge .in(...) id lists (slow, big payloads). This RPC
-- returns one row of counts per engagement in a single round-trip.
--
-- SECURITY DEFINER + explicit org filter + membership guard: bypasses per-row RLS
-- (fast aggregation) while still only exposing the caller's own organization.

CREATE OR REPLACE FUNCTION public.dashboard_engagement_stats(p_org_id uuid)
RETURNS TABLE (
  engagement_id     uuid,
  total_sections    int,
  approved_sections int,
  review_sections   int,
  total_procs       int,
  done_procs        int,
  open_findings     int
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE user_id = auth.uid() AND organization_id = p_org_id
  ) THEN
    RAISE EXCEPTION 'dashboard_engagement_stats: caller is not a member of organization %', p_org_id;
  END IF;

  RETURN QUERY
  WITH eng AS (
    SELECT id FROM public.engagements WHERE organization_id = p_org_id
  ),
  sec AS (
    SELECT s.id, s.engagement_id, s.status
    FROM public.audit_sections s
    JOIN eng ON eng.id = s.engagement_id
  ),
  sc AS (
    SELECT sec.engagement_id,
      count(*)::int                                                                                   AS total_sections,
      count(*) FILTER (WHERE sec.status = 'approved')::int                                            AS approved_sections,
      count(*) FILTER (WHERE sec.status IN ('ready_for_partner_review','in_partner_review'))::int     AS review_sections
    FROM sec GROUP BY sec.engagement_id
  ),
  pc AS (
    SELECT sec.engagement_id,
      count(DISTINCT p.id)::int                                          AS total_procs,
      count(DISTINCT p.id) FILTER (WHERE r.id IS NOT NULL)::int          AS done_procs
    FROM public.audit_procedures p
    JOIN sec ON sec.id = p.section_id
    LEFT JOIN public.procedure_responses r ON r.procedure_id = p.id AND r.status = 'done'
    GROUP BY sec.engagement_id
  ),
  fc AS (
    SELECT sec.engagement_id,
      count(*) FILTER (WHERE f.status = 'open')::int AS open_findings
    FROM public.findings f
    JOIN sec ON sec.id = f.section_id
    GROUP BY sec.engagement_id
  )
  SELECT e.id,
    COALESCE(sc.total_sections, 0),
    COALESCE(sc.approved_sections, 0),
    COALESCE(sc.review_sections, 0),
    COALESCE(pc.total_procs, 0),
    COALESCE(pc.done_procs, 0),
    COALESCE(fc.open_findings, 0)
  FROM eng e
  LEFT JOIN sc ON sc.engagement_id = e.id
  LEFT JOIN pc ON pc.engagement_id = e.id
  LEFT JOIN fc ON fc.engagement_id = e.id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.dashboard_engagement_stats(uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.dashboard_engagement_stats(uuid) TO authenticated;
