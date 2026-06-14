-- Section page perf: return the whole section in ONE round-trip instead of the
-- ~7 serial queries (section -> engagement -> tb_version -> tb_lines, procedures
-- -> responses -> docs/sampling, findings, review_notes, working TB) the client
-- ran in sequence. High-latency clients felt every hop as a separate "stage".
--
-- SECURITY DEFINER + membership guard: aggregates fast (bypasses per-row RLS)
-- while only exposing sections in the caller's own organization.
CREATE OR REPLACE FUNCTION public.section_bootstrap(p_section_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_section  public.audit_sections;
  v_org      uuid;
  v_eng      uuid;
  v_version  uuid;
  v_is_pro   boolean := false;
  v_proc_ids uuid[];
  v_resp_ids uuid[];
  result     jsonb;
BEGIN
  SELECT * INTO v_section FROM public.audit_sections WHERE id = p_section_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'section_bootstrap: section % not found', p_section_id;
  END IF;
  v_eng := v_section.engagement_id;

  SELECT e.organization_id, (o.feature_tier = 'pro')
    INTO v_org, v_is_pro
  FROM public.engagements e
  JOIN public.organizations o ON o.id = e.organization_id
  WHERE e.id = v_eng;

  IF NOT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE user_id = auth.uid() AND organization_id = v_org
  ) THEN
    RAISE EXCEPTION 'section_bootstrap: caller is not a member of organization %', v_org;
  END IF;

  -- TB version this section reads: pinned, else current (latest upload).
  v_version := v_section.tb_version_id;
  IF v_version IS NULL THEN
    SELECT id INTO v_version
    FROM public.tb_versions
    WHERE engagement_id = v_eng
    ORDER BY uploaded_at DESC
    LIMIT 1;
  END IF;

  SELECT array_agg(id) INTO v_proc_ids
    FROM public.audit_procedures WHERE section_id = p_section_id;
  v_proc_ids := COALESCE(v_proc_ids, '{}');

  SELECT array_agg(r.id) INTO v_resp_ids
    FROM public.procedure_responses r WHERE r.procedure_id = ANY(v_proc_ids);
  v_resp_ids := COALESCE(v_resp_ids, '{}');

  result := jsonb_build_object(
    'section',       to_jsonb(v_section),
    'engagement',    (SELECT to_jsonb(x) FROM (
                        SELECT client_name, shared_folder_url, status
                        FROM public.engagements WHERE id = v_eng) x),
    'tb_version_id', v_version,
    'is_pro',        v_is_pro,
    'tb_lines', COALESCE((
        SELECT jsonb_agg(to_jsonb(t) ORDER BY t.account_code)
        FROM public.trial_balance_lines t
        WHERE t.engagement_id = v_eng
          AND (v_version IS NULL OR t.tb_version_id = v_version)
          AND t.classification = ANY(COALESCE(v_section.classification_tags, '{}'))
      ), '[]'::jsonb),
    'procedures', COALESCE((
        SELECT jsonb_agg(to_jsonb(p) ORDER BY p.sort_order)
        FROM public.audit_procedures p WHERE p.section_id = p_section_id
      ), '[]'::jsonb),
    'responses', COALESCE((
        SELECT jsonb_agg(to_jsonb(r))
        FROM public.procedure_responses r WHERE r.procedure_id = ANY(v_proc_ids)
      ), '[]'::jsonb),
    'documents', COALESCE((
        SELECT jsonb_agg(to_jsonb(d) ORDER BY d.created_at)
        FROM public.documents d
        WHERE (d.section_id = p_section_id AND d.procedure_response_id IS NULL)
           OR d.procedure_response_id = ANY(v_resp_ids)
      ), '[]'::jsonb),
    'sampling', COALESCE((
        SELECT jsonb_agg(to_jsonb(s))
        FROM public.procedure_sampling s WHERE s.procedure_id = ANY(v_proc_ids)
      ), '[]'::jsonb),
    'findings', COALESCE((
        SELECT jsonb_agg(to_jsonb(f) ORDER BY f.created_at)
        FROM public.findings f WHERE f.section_id = p_section_id
      ), '[]'::jsonb),
    'review_notes', COALESCE((
        SELECT jsonb_agg(to_jsonb(n) ORDER BY n.created_at)
        FROM (
          SELECT rn.*, jsonb_build_object('full_name', pr.full_name, 'email', pr.email) AS profiles
          FROM public.review_notes rn
          LEFT JOIN public.profiles pr ON pr.id = rn.user_id
          WHERE rn.section_id = p_section_id
        ) n
      ), '[]'::jsonb)
  );

  -- Working-TB block (Pro only — matches loadSectionWorkingTB's early return).
  IF v_is_pro THEN
    result := result || jsonb_build_object(
      'wtb_all', COALESCE((
          SELECT jsonb_agg(to_jsonb(t) ORDER BY t.account_code)
          FROM public.trial_balance_lines t
          WHERE t.engagement_id = v_eng
            AND (v_version IS NULL OR t.tb_version_id = v_version)
        ), '[]'::jsonb),
      'wtb_entries', COALESCE((
          SELECT jsonb_agg(to_jsonb(je) ORDER BY je.created_at)
          FROM public.journal_entries je WHERE je.engagement_id = v_eng
        ), '[]'::jsonb),
      'wtb_lines', COALESCE((
          SELECT jsonb_agg(to_jsonb(jl))
          FROM public.journal_lines jl
          WHERE jl.journal_entry_id IN (
            SELECT id FROM public.journal_entries WHERE engagement_id = v_eng)
        ), '[]'::jsonb)
    );
  END IF;

  RETURN result;
END;
$$;

-- Only signed-in users; revoke the auto-granted public/anon EXECUTE.
REVOKE EXECUTE ON FUNCTION public.section_bootstrap(uuid) FROM public;
REVOKE EXECUTE ON FUNCTION public.section_bootstrap(uuid) FROM anon;
GRANT  EXECUTE ON FUNCTION public.section_bootstrap(uuid) TO authenticated;
