-- Sprint 1 — RLS helper functions
-- get_user_org_ids() returns every organization the current auth user belongs to.
-- user_has_role_in_org() returns true if the current user has the given role in the given org.
-- Both are SECURITY DEFINER so RLS policies can call them without recursion.

CREATE OR REPLACE FUNCTION public.get_user_org_ids()
RETURNS SETOF uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT organization_id
  FROM public.organization_members
  WHERE user_id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.user_has_role_in_org(
  org_id        uuid,
  required_role text
)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.organization_members
    WHERE user_id = auth.uid()
      AND organization_id = org_id
      AND role = required_role
  );
$$;

REVOKE EXECUTE ON FUNCTION public.get_user_org_ids()                       FROM public;
REVOKE EXECUTE ON FUNCTION public.user_has_role_in_org(uuid, text)         FROM public;
GRANT  EXECUTE ON FUNCTION public.get_user_org_ids()                       TO authenticated;
GRANT  EXECUTE ON FUNCTION public.user_has_role_in_org(uuid, text)         TO authenticated;
