-- =====================================================================
-- STAGING RLS AUDIT  (read-only diagnostic — changes nothing)
-- Run in the STAGING Supabase SQL editor (project lbwowlvajgpdxsdpudem).
-- Lists every public table and whether RLS is enabled + how many policies
-- it has. Any row with rls_enabled = false is what Supabase is alerting on.
-- =====================================================================
SELECT
  c.relname                                   AS table_name,
  c.relrowsecurity                            AS rls_enabled,
  COUNT(p.polname)                            AS policy_count
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_policy p ON p.polrelid = c.oid
WHERE n.nspname = 'public'
  AND c.relkind = 'r'            -- ordinary tables only
GROUP BY c.relname, c.relrowsecurity
ORDER BY c.relrowsecurity ASC, c.relname;   -- exposed tables float to top
