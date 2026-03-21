-- ============================================================
-- MIGRATION v6: TB Versioning
-- Run ALL of this in Supabase SQL Editor
-- ============================================================

-- 1. Create tb_versions table
create table if not exists tb_versions (
  id uuid primary key default gen_random_uuid(),
  engagement_id uuid not null references engagements(id) on delete cascade,
  label text not null default 'Initial',
  uploaded_by uuid references profiles(id),
  uploaded_at timestamptz not null default now()
);

alter table tb_versions enable row level security;

create policy "Org members can read tb_versions" on tb_versions for select
  using (engagement_id in (select id from engagements where organization_id in (select user_org_ids())));
create policy "Org members can insert tb_versions" on tb_versions for insert
  with check (engagement_id in (select id from engagements where organization_id in (select user_org_ids())));
create policy "Org members can delete tb_versions" on tb_versions for delete
  using (engagement_id in (select id from engagements where organization_id in (select user_org_ids())));

-- 2. Add tb_version_id to trial_balance_lines
alter table trial_balance_lines add column if not exists tb_version_id uuid references tb_versions(id) on delete cascade;

-- 3. Add tb_version_id to audit_sections
alter table audit_sections add column if not exists tb_version_id uuid references tb_versions(id);

-- 4. Migrate existing TB lines into a version
-- For each engagement that has TB lines, create a version and link them
do $migrate$
declare
  eng record;
  ver_id uuid;
begin
  for eng in
    select distinct engagement_id from trial_balance_lines where tb_version_id is null
  loop
    insert into tb_versions (engagement_id, label)
    values (eng.engagement_id, 'Initial')
    returning id into ver_id;

    update trial_balance_lines
    set tb_version_id = ver_id
    where engagement_id = eng.engagement_id and tb_version_id is null;

    -- Link existing sections to this version
    update audit_sections
    set tb_version_id = ver_id
    where engagement_id = eng.engagement_id and tb_version_id is null;
  end loop;
end;
$migrate$;

-- 5. Update delete_section RPC to handle new schema
create or replace function delete_section(p_section_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_engagement_id uuid;
  v_org_id uuid;
  v_user_org_id uuid;
begin
  select engagement_id into v_engagement_id
  from audit_sections where id = p_section_id;

  if v_engagement_id is null then
    raise exception 'Section not found';
  end if;

  select organization_id into v_org_id
  from engagements where id = v_engagement_id;

  select organization_id into v_user_org_id
  from organization_members where user_id = auth.uid() and organization_id = v_org_id;

  if v_user_org_id is null then
    raise exception 'Access denied';
  end if;

  delete from adjusting_entries where finding_id in (
    select id from findings where section_id = p_section_id);
  delete from documents where procedure_response_id in (
    select id from procedure_responses where procedure_id in (
      select id from audit_procedures where section_id = p_section_id));
  delete from documents where section_id = p_section_id;
  delete from procedure_responses where procedure_id in (
    select id from audit_procedures where section_id = p_section_id);
  delete from audit_procedures where section_id = p_section_id;
  delete from findings where section_id = p_section_id;
  delete from review_notes where section_id = p_section_id;
  delete from audit_sections where id = p_section_id;
end;
$fn$;
