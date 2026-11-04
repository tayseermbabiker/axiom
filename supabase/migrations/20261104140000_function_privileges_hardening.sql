-- Function privilege hardening (Nov 2026) — clears Supabase security advisor warnings.
--
-- 1. No public-schema function is callable by anon (logged-out visitors).
--    The frontend only calls RPCs after login; Netlify functions use the
--    service_role key, which is unaffected.
-- 2. Trigger functions are not callable directly by anyone. Triggers still
--    fire: Postgres checks EXECUTE on the trigger function at CREATE TRIGGER
--    time, not when the trigger fires (verified in a rolled-back test).
-- 3. Functions without a pinned search_path get search_path = public.
-- 4. Future functions: no default EXECUTE for PUBLIC/anon. Migrations must
--    GRANT EXECUTE ... TO authenticated explicitly (already the convention).
--
-- authenticated keeps its explicit EXECUTE grants on every non-trigger
-- function (verified before applying: auth_explicit = true for all).

DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT p.oid::regprocedure AS sig
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.prorettype = 'trigger'::regtype
  LOOP
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM public, anon, authenticated', r.sig);
  END LOOP;

  FOR r IN
    SELECT p.oid::regprocedure AS sig
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.prorettype <> 'trigger'::regtype
  LOOP
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM public, anon', r.sig);
  END LOOP;

  FOR r IN
    SELECT p.oid::regprocedure AS sig
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proconfig IS NULL
  LOOP
    EXECUTE format('ALTER FUNCTION %s SET search_path = public', r.sig);
  END LOOP;
END $$;

ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM public, anon;
