-- ============================================================
-- SEAT ENFORCEMENT
-- Prevents adding members beyond organizations.max_members
-- Run this in Supabase SQL Editor
-- ============================================================

create or replace function enforce_seat_limit()
returns trigger as $$
declare
  current_count int;
  max_allowed int;
begin
  -- Get current member count and max_members for this org
  select count(*) into current_count
  from organization_members
  where organization_id = NEW.organization_id;

  select o.max_members into max_allowed
  from organizations o
  where o.id = NEW.organization_id;

  if current_count >= max_allowed then
    raise exception 'Seat limit reached. Your plan allows % members. Upgrade your plan to add more.', max_allowed;
  end if;

  return NEW;
end;
$$ language plpgsql;

-- Drop existing trigger if any
drop trigger if exists check_seat_limit on organization_members;

-- Create trigger (fires BEFORE INSERT so it blocks the row)
create trigger check_seat_limit
  before insert on organization_members
  for each row
  execute function enforce_seat_limit();


-- ============================================================
-- Also enforce on invites (prevent inviting beyond limit)
-- Counts members + pending invites against max_members
-- ============================================================

create or replace function enforce_invite_seat_limit()
returns trigger as $$
declare
  member_count int;
  pending_invite_count int;
  max_allowed int;
begin
  select count(*) into member_count
  from organization_members
  where organization_id = NEW.organization_id;

  select count(*) into pending_invite_count
  from organization_invites
  where organization_id = NEW.organization_id
    and status = 'pending';

  select o.max_members into max_allowed
  from organizations o
  where o.id = NEW.organization_id;

  if (member_count + pending_invite_count) >= max_allowed then
    raise exception 'Seat limit reached. Your plan allows % members (% active, % pending invites). Upgrade to add more.', max_allowed, member_count, pending_invite_count;
  end if;

  return NEW;
end;
$$ language plpgsql;

drop trigger if exists check_invite_seat_limit on organization_invites;

create trigger check_invite_seat_limit
  before insert on organization_invites
  for each row
  execute function enforce_invite_seat_limit();
