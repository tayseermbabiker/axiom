-- Prior-year fees settled (IESBA R410 / Section 290 — overdue prior-year fees are a
-- self-interest, loan-like threat to independence). Reviewer-driven planning enhancement
-- (June 2026, item #5a). Additive, nullable, backward compatible.

alter table public.engagement_independence
  add column if not exists prior_year_fees_status text,
  add column if not exists prior_year_fees_note   text;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'engagement_independence_prior_year_fees_status_chk'
  ) then
    alter table public.engagement_independence
      add constraint engagement_independence_prior_year_fees_status_chk
      check (prior_year_fees_status is null
             or prior_year_fees_status in ('settled','outstanding','na_first_year'));
  end if;
end $$;

comment on column public.engagement_independence.prior_year_fees_status is
  'IESBA R410: settled | outstanding | na_first_year — overdue prior-year fees are a self-interest (loan-like) threat to independence.';
comment on column public.engagement_independence.prior_year_fees_note is
  'Threat evaluation and safeguard where prior-year fees are outstanding (amount/age, action taken).';
