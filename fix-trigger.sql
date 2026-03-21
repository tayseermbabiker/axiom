-- Step 1: Disable the trigger temporarily
alter table audit_sections disable trigger protect_approval_timestamps;

-- Step 2: Clear stuck approval data
update audit_sections
set supervisor_approved_by = null,
    supervisor_approved_at = null,
    partner_approved_by = null,
    partner_approved_at = null
where status in ('returned_to_supervisor', 'returned_to_preparer', 'in_progress', 'not_started', 'ready_for_supervisor_review');

-- Step 3: Drop ALL old triggers on this table
drop trigger if exists protect_approval_timestamps on audit_sections;
drop trigger if exists protect_approved_at on audit_sections;

-- Step 4: Recreate the function (permissive on return/reopen statuses)
create or replace function protect_approval_timestamps()
returns trigger
language plpgsql security definer set search_path = public
as $fn$
begin
  -- Allow any change when moving to a return/reopen/working status
  if new.status in (
    'returned_to_preparer',
    'returned_to_supervisor',
    'in_progress',
    'in_supervisor_review',
    'ready_for_supervisor_review',
    'not_started'
  ) then
    new.updated_at := now();
    return new;
  end if;

  -- Block tampering with supervisor timestamp once set
  if old.supervisor_approved_at is not null
    and new.supervisor_approved_at is distinct from old.supervisor_approved_at
  then
    raise exception 'supervisor_approved_at is immutable once set (use reopen to clear)';
  end if;

  -- Block tampering with partner timestamp once set
  if old.partner_approved_at is not null
    and new.partner_approved_at is distinct from old.partner_approved_at
  then
    raise exception 'partner_approved_at is immutable once set (use reopen to clear)';
  end if;

  new.updated_at := now();
  return new;
end;
$fn$;

-- Step 5: Recreate the trigger
create trigger protect_approval_timestamps
  before update on audit_sections
  for each row execute function protect_approval_timestamps();
