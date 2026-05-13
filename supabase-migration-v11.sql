-- ============================================================
-- MIGRATION v11 — Partial unique constraint on organization_invites
--                  + admin DELETE policy
-- ============================================================
-- Problem 1: organization_invites had a unique constraint on
--   (organization_id, email) that applied to ALL rows. So an admin
--   could not re-invite someone whose invite was previously cancelled
--   or accepted — even though the cancel/accept flow leaves stale rows.
--
-- Problem 2: there was no DELETE policy for organization_invites, so
--   admins clicking "Cancel" silently failed (Supabase returns success
--   with 0 rows affected when RLS blocks a delete).
--
-- Fix: drop the table-wide unique constraint, replace with a partial
-- unique index that only fires for pending invites. And add a DELETE
-- policy so admins can actually cancel.
--
-- Run this in Supabase SQL Editor.
-- ============================================================

-- Drop the existing table-wide unique constraint (if it exists)
alter table organization_invites
  drop constraint if exists organization_invites_organization_id_email_key;

-- Replace with a partial unique index: only pending invites must be unique
create unique index if not exists organization_invites_unique_pending
  on organization_invites (organization_id, email)
  where status = 'pending';

-- DELETE policy: org admins can cancel invites for their own org
do $$
begin
  if not exists (
    select 1 from pg_policies
    where tablename = 'organization_invites'
      and policyname = 'admins_can_delete_invites'
  ) then
    create policy admins_can_delete_invites
      on organization_invites
      for delete
      using (
        exists (
          select 1
          from organization_members om
          where om.organization_id = organization_invites.organization_id
            and om.user_id = auth.uid()
            and om.role = 'admin'
        )
      );
  end if;
end $$;
