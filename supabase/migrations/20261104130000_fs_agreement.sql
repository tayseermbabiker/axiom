-- FS Agreement workpaper — V1 (Nov 2026). ISA 330.20(a) + 330.30.
-- Spec: specs/tb-fs-agreement-2026-11.md (§9 = the V1 scope actually built).
--
-- Agrees management's primary financial statements (SoFP + P&L, CY + PY)
-- to the adjusted TB. Audexon does NOT prepare the client's FS.
--
-- Design notes:
--   - Caption library is the IFRS for SMEs set defined in the frontend
--     (FS_CAPTIONS in engagement.html); rows store the caption_key text.
--   - Adjusted-TB caption totals are computed client-side with the SAME
--     function the Working TB tab uses (render parity). At reviewer sign-off
--     the totals, TB version, FS upload and keyed figures are frozen into
--     review_snapshot; the tab compares live vs snapshot and shows a
--     "changed since sign-off" banner instead of silently changing evidence.
--   - Reviewer sign-off only through sign_off_fs_agreement() (admin or
--     supervisor). A guard trigger blocks writing reviewed_* any other way.

-- =========================================================================
-- 1. Header — one per engagement
-- =========================================================================
create table if not exists public.engagement_fs_agreements (
  id               uuid primary key default gen_random_uuid(),
  engagement_id    uuid not null unique references public.engagements(id) on delete cascade,
  organization_id  uuid not null references public.organizations(id) on delete cascade,

  -- The management FS version being agreed (ISA 230: identify what was tested).
  fs_upload_id     uuid references public.engagement_fs_uploads(id) on delete set null,
  rounding_unit    int  not null default 1 check (rounding_unit in (1, 1000, 1000000)),
  currency         text,
  py_fs_reference  text,   -- e.g. "FY2025 signed FS dated 2026-03-14, auditor's report p.3"

  prepared_by      uuid references public.profiles(id),
  prepared_at      timestamptz,
  reviewed_by      uuid references public.profiles(id),
  reviewed_at      timestamptz,
  review_snapshot  jsonb,

  created_by       uuid references public.profiles(id),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create index if not exists idx_efsa_org on public.engagement_fs_agreements(organization_id);

-- =========================================================================
-- 2. Account → caption mapping (per engagement, keyed by account_code so it
--    survives TB re-uploads into new tb_versions)
-- =========================================================================
create table if not exists public.engagement_fs_caption_map (
  id               uuid primary key default gen_random_uuid(),
  engagement_id    uuid not null references public.engagements(id) on delete cascade,
  organization_id  uuid not null references public.organizations(id) on delete cascade,
  account_code     text not null,
  caption_key      text not null,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  unique (engagement_id, account_code)
);

create index if not exists idx_efcm_engagement on public.engagement_fs_caption_map(engagement_id);

-- =========================================================================
-- 3. Agreement lines — one per caption
-- =========================================================================
create table if not exists public.engagement_fs_agreement_lines (
  id               uuid primary key default gen_random_uuid(),
  engagement_id    uuid not null references public.engagements(id) on delete cascade,
  organization_id  uuid not null references public.organizations(id) on delete cascade,
  caption_key      text not null,

  fs_amount_cy     numeric,          -- as shown in management's FS (in the FS rounding unit)
  fs_amount_py     numeric,          -- comparative as shown in management's FS
  py_agreed        boolean not null default false,  -- comparative agrees to PY signed FS (ISA 710)

  resolution_type  text check (resolution_type is null or resolution_type in
                     ('rounding','classification','misstatement','fs_to_be_corrected')),
  explanation      text,
  journal_entry_id uuid references public.journal_entries(id) on delete set null,

  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  unique (engagement_id, caption_key)
);

create index if not exists idx_efal_engagement on public.engagement_fs_agreement_lines(engagement_id);

-- =========================================================================
-- 4. RLS — org members via the engagement chain; Pro on writes
-- =========================================================================
alter table public.engagement_fs_agreements      enable row level security;
alter table public.engagement_fs_caption_map     enable row level security;
alter table public.engagement_fs_agreement_lines enable row level security;

do $$
declare
  t text;
begin
  foreach t in array array['engagement_fs_agreements','engagement_fs_caption_map','engagement_fs_agreement_lines']
  loop
    execute format('drop policy if exists %1$s_select on public.%1$s', t);
    execute format('drop policy if exists %1$s_insert on public.%1$s', t);
    execute format('drop policy if exists %1$s_update on public.%1$s', t);
    execute format('drop policy if exists %1$s_delete on public.%1$s', t);

    execute format($p$
      create policy %1$s_select on public.%1$s for select
        using (organization_id in (select public.get_user_org_ids()))
    $p$, t);

    execute format($p$
      create policy %1$s_insert on public.%1$s for insert
        with check (
          organization_id in (select public.get_user_org_ids())
          and engagement_id in (select e.id from public.engagements e where e.organization_id = %1$s.organization_id)
          and public.org_has_pro_tier(organization_id)
        )
    $p$, t);

    execute format($p$
      create policy %1$s_update on public.%1$s for update
        using (
          organization_id in (select public.get_user_org_ids())
          and public.org_has_pro_tier(organization_id)
        )
        with check (
          organization_id in (select public.get_user_org_ids())
          and engagement_id in (select e.id from public.engagements e where e.organization_id = %1$s.organization_id)
        )
    $p$, t);

    execute format($p$
      create policy %1$s_delete on public.%1$s for delete
        using (
          organization_id in (select public.get_user_org_ids())
          and public.org_has_pro_tier(organization_id)
        )
    $p$, t);

    execute format('grant select, insert, update, delete on public.%I to authenticated', t);

    execute format('drop trigger if exists trg_%1$s_updated_at on public.%1$s', t);
    execute format('create trigger trg_%1$s_updated_at before update on public.%1$s for each row execute function public.set_updated_at_now()', t);
  end loop;
end $$;

-- =========================================================================
-- 5. Guard: reviewed_* only writable inside sign_off_fs_agreement()
-- =========================================================================
create or replace function public.guard_fs_agreement_review()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if coalesce(current_setting('audexon.fs_signoff', true), '') = 'on' then
    return new;
  end if;

  if tg_op = 'INSERT' then
    if new.reviewed_by is not null or new.reviewed_at is not null or new.review_snapshot is not null then
      raise exception 'FS agreement review sign-off can only be recorded by a reviewer via sign_off_fs_agreement()';
    end if;
  elsif (new.reviewed_by     is distinct from old.reviewed_by)
     or (new.reviewed_at     is distinct from old.reviewed_at)
     or (new.review_snapshot is distinct from old.review_snapshot) then
    raise exception 'FS agreement review sign-off can only be recorded by a reviewer via sign_off_fs_agreement()';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_efsa_guard_review on public.engagement_fs_agreements;
create trigger trg_efsa_guard_review
  before insert or update on public.engagement_fs_agreements
  for each row execute function public.guard_fs_agreement_review();

-- =========================================================================
-- 6. sign_off_fs_agreement(engagement, snapshot) — admin or supervisor only
-- =========================================================================
create or replace function public.sign_off_fs_agreement(
  p_engagement_id uuid,
  p_snapshot      jsonb
)
returns timestamptz
language plpgsql
security definer
set search_path = public
as $$
declare
  v_org uuid;
  v_at  timestamptz := now();
begin
  select organization_id into v_org from public.engagements where id = p_engagement_id;
  if v_org is null then
    raise exception 'sign_off_fs_agreement: engagement % not found', p_engagement_id;
  end if;

  if not exists (
    select 1 from public.organization_members
    where organization_id = v_org
      and user_id = auth.uid()
      and role in ('admin','supervisor')
  ) then
    raise exception 'sign_off_fs_agreement: only a supervisor or partner can sign off the FS agreement';
  end if;

  if not public.org_has_pro_tier(v_org) then
    raise exception 'sign_off_fs_agreement: organization is not on Pro';
  end if;

  if p_snapshot is null then
    raise exception 'sign_off_fs_agreement: snapshot is required';
  end if;

  perform set_config('audexon.fs_signoff', 'on', true);

  update public.engagement_fs_agreements
  set reviewed_by     = auth.uid(),
      reviewed_at     = v_at,
      review_snapshot = p_snapshot
  where engagement_id = p_engagement_id;

  if not found then
    raise exception 'sign_off_fs_agreement: no FS agreement exists for this engagement yet';
  end if;

  perform set_config('audexon.fs_signoff', '', true);
  return v_at;
end;
$$;

revoke execute on function public.sign_off_fs_agreement(uuid, jsonb) from public;
grant  execute on function public.sign_off_fs_agreement(uuid, jsonb) to authenticated;
