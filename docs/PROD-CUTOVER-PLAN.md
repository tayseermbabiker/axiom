# Audexon — Production Cutover Plan

Step-by-step plan for migrating Audexon from `staging` to production. Read this top to bottom before pressing any button. Total time on cutover day: **~90 min** if nothing surprises us.

**Staging environment** (current):
- Branch: `staging` on `tayseermbabiker/axiom`
- Netlify deploy: `https://staging--auditsaas.netlify.app/`
- Supabase: project ref `lbwowlvajgpdxsdpudem` (the second free account, see [`audexon-qatar-pilot-feedback.md`](../../../.claude/projects/C--Users-LENOVO/memory/audexon-qatar-pilot-feedback.md))

**Production environment** (target):
- Domain: `audexon.com`
- Netlify: production deploy from `main` branch (or whatever the prod branch ends up being)
- Supabase: the original prod project (first account, hit 2-project free limit)
- Stripe: live mode

---

## Pre-cutover prerequisites (do these in the days BEFORE cutover)

- [ ] **Run the full bug test protocol** on staging (`docs/BUG-TEST-PROTOCOL.md`) — at least Pass A end-to-end. Fix everything that surfaces.
- [ ] **Confirm staging Supabase has every migration applied**, ordered:
  - 20260519* (Sprint 1: feature_tier, rls_helpers, completion_memo, fs_uploads, local_compliance, triggers, attestation_registry)
  - 20260520* (Sprint 2: verification_fixes, fs_upload_hardening, fs_upload_evidence, local_compliance_hardening, engagement_letters, engagement_independence, engagement_acceptance)
  - 20260521* (Sprint 3: engagement_audit_strategy, engagement_risk_assessment, materiality_versioning)
  - 20260522* (Sprint 3 polish: isa_gap_items, section_specific_risks, delete_section_rpc, refresh_completion_rollups_rpc, eqr_external_reviewer, tier1_completion_memo_fields)
  - 20260523* (Sprint 4 standards floor: isa_510_and_230, isa_315_understanding, isa_540_estimates, isa_505_confirmations, isa_530_sampling)
  - 20260524120000_isa_260_250_polish
  - 20260527120000_presumed_risks_survive_section_delete
- [ ] **Confirm the schema verification SQL passes on staging** (the EXISTS-check query block from the conversation). All rows should return `true`.
- [ ] **Domain DNS** — own `audexon.com`, A/CNAME records ready to point to Netlify.
- [ ] **Stripe live mode** — keys ready (publishable + secret), webhook endpoint URL prepared.
- [ ] **First admin account** for prod — decide which email; create user record post-cutover.

---

## Cutover day — sequence (~90 min total)

Execute in this exact order. Don't skip the verification steps between.

### Step 1 — Apply all migrations to prod Supabase (Owner: Claude + user)

For each migration file in chronological order:
1. Open Supabase dashboard → SQL Editor on the **prod** project.
2. Paste the migration SQL.
3. Run.
4. Confirm no errors.
5. Move to the next.

After ALL migrations applied, run the verification query:

```sql
SELECT 'engagement_acceptance.opening_balances_status' AS col,
       EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema='public' AND table_name='engagement_acceptance'
               AND column_name='opening_balances_status') AS ok
UNION ALL SELECT 'engagements.is_archived',
       EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema='public' AND table_name='engagements'
               AND column_name='is_archived')
UNION ALL SELECT 'engagement_audit_strategies.isa_315_inquiry_performed',
       EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema='public' AND table_name='engagement_audit_strategies'
               AND column_name='isa_315_inquiry_performed')
UNION ALL SELECT 'engagement_audit_strategies.key_laws_regulations',
       EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema='public' AND table_name='engagement_audit_strategies'
               AND column_name='key_laws_regulations')
UNION ALL SELECT 'engagement_estimates table',
       EXISTS (SELECT 1 FROM information_schema.tables
               WHERE table_schema='public' AND table_name='engagement_estimates')
UNION ALL SELECT 'engagement_confirmations table',
       EXISTS (SELECT 1 FROM information_schema.tables
               WHERE table_schema='public' AND table_name='engagement_confirmations')
UNION ALL SELECT 'procedure_sampling table',
       EXISTS (SELECT 1 FROM information_schema.tables
               WHERE table_schema='public' AND table_name='procedure_sampling')
UNION ALL SELECT 'archive_engagement RPC',
       EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
               WHERE n.nspname='public' AND p.proname='archive_engagement')
UNION ALL SELECT 'CHECK isa_315_attestations_required_on_approve',
       EXISTS (SELECT 1 FROM information_schema.table_constraints
               WHERE table_schema='public'
               AND constraint_name='isa_315_attestations_required_on_approve')
UNION ALL SELECT 'CHECK engagement_risks_custom_must_have_section',
       EXISTS (SELECT 1 FROM information_schema.table_constraints
               WHERE table_schema='public'
               AND constraint_name='engagement_risks_custom_must_have_section')
ORDER BY 1;
```

**All rows must return `ok = true`.** If any are false, fix before proceeding.

### Step 2 — Storage bucket + RLS verification (Owner: user)

- [ ] Confirm `fs-documents` bucket exists on prod Supabase Storage.
- [ ] Confirm storage RLS policy: org-membership-only access, signed-URL retrieval.
- [ ] Run a manual test: upload a sample file, retrieve via signed URL, confirm 60-sec expiry.

### Step 3 — Auth + first admin user (Owner: user)

- [ ] On Supabase Auth, create the founder user account (email + password) OR sign up via the live URL and grab the user.id.
- [ ] In SQL: create the organization row, the membership row with `role='admin'`, and set `feature_tier` accordingly (probably `pro` for self).

```sql
-- Replace placeholders. Run inside a transaction so it's all-or-nothing.
BEGIN;
INSERT INTO organizations (name, feature_tier)
VALUES ('Your Firm Name', 'pro')
RETURNING id;
-- Take the returned id, paste below:
INSERT INTO organization_members (organization_id, user_id, role)
VALUES ('<org-id-from-above>', '<your-auth-user-id>', 'admin');
COMMIT;
```

### Step 4 — Environment variables on Netlify prod (Owner: user)

In the Netlify dashboard for the prod site, set these env vars:

| Key | Value |
|---|---|
| `SUPABASE_URL` | Prod Supabase URL |
| `SUPABASE_ANON_KEY` | Prod Supabase publishable (anon) key |
| `STRIPE_SECRET_KEY` | Stripe **live** secret key |
| `STRIPE_PUBLISHABLE_KEY` | Stripe **live** publishable key |
| `STRIPE_WEBHOOK_SECRET` | Stripe live webhook signing secret |
| `STRIPE_PRICE_STARTER` | Live Stripe price ID for Starter tier |
| `STRIPE_PRICE_TEAM` | Live Stripe price ID for Team tier |
| `STRIPE_PRICE_FIRM` | Live Stripe price ID for Firm tier |

After saving, **trigger a fresh deploy** so the variables are picked up. Netlify env vars don't propagate to existing deploys.

### Step 5 — `config.js` environment detection (Owner: Claude or user)

Verify `public/js/config.js` correctly picks the prod Supabase project on the `audexon.com` hostname (not staging.auditsaas.netlify.app). It should auto-detect via hostname. If not, swap the production Supabase URL + anon key in there.

### Step 6 — Switch DNS (Owner: user)

- [ ] In Netlify dashboard, add `audexon.com` as a custom domain on the prod site.
- [ ] In your DNS provider, point the A record + www CNAME at Netlify.
- [ ] Wait for SSL cert provisioning (Netlify auto-issues via Let's Encrypt, usually 1–5 min).
- [ ] Confirm `https://audexon.com` loads the app.

### Step 7 — MFA enforcement for admin (Owner: user)

- [ ] In Supabase dashboard → Authentication → Multi-Factor → enable TOTP.
- [ ] Optionally: enforce MFA for users with `role='admin'`. As of Supabase Auth today this isn't a one-toggle setting — typically done in-app via an MFA modal on first admin login. Park as Sprint 5 if not easy.

### Step 8 — Verify CSP + security headers (Owner: Claude)

- [ ] Hit `https://audexon.com` with DevTools open.
- [ ] Network tab → click the HTML file → Response Headers → confirm:
  - `Content-Security-Policy: default-src 'self'; ...` is present
  - `X-Frame-Options: DENY`
  - `Strict-Transport-Security: max-age=31536000; includeSubDomains`
  - `X-Content-Type-Options: nosniff`
- [ ] Console: zero CSP violation errors. If any appear, widen the policy minimally and redeploy.

### Step 9 — End-to-end smoke test (Owner: user, ~30 min)

Run an abbreviated version of `BUG-TEST-PROTOCOL.md` Pass A against the prod URL:
- [ ] Sign in as admin
- [ ] Create one test engagement (use the cheatsheet data)
- [ ] Walk through Planning → Execution → Completion
- [ ] Generate both PDFs
- [ ] Archive the engagement
- [ ] Delete the test engagement (so prod starts clean)

### Step 10 — Cutover communication (Owner: user)

- [ ] Update README / landing page copy if needed (remove "beta" badges, update pricing copy to reflect live).
- [ ] If Qatar pilot partners are involved: send them the prod URL + first-time login instructions.

---

## First month on prod (post-cutover priorities)

These don't block launch but should be in place before scaling onboarding past 5–10 firms.

### Activate Sentry (~10 min)
- Sign up for Sentry (free tier ok), create a project for Audexon, copy the DSN.
- Set `SENTRY_DSN` in Netlify env vars OR paste it into `public/js/sentry-init.js` directly (it's a public key, safe in client).
- Redeploy. Sentry should start receiving errors within minutes.

### Schema-drift CI check (~1 hr)
- Add a GitHub Action that runs on every PR: diff the current migration files against what's actually in prod Supabase, fail the CI if there's drift.
- Tools: Supabase CLI has `db diff` for this purpose.

### Activity log dashboard (~3 hr)
- Add a `/team.html` or new `/activity.html` view that surfaces the `activity_log` table for admin users.
- Filter by date range, action type, user.
- Big audit-trail value with small build cost.

### Session expiry config (~5 min)
- In Supabase dashboard → Authentication → Settings → adjust session lifetime if you want 7-day refresh (default is different).

---

## Ongoing discipline (calendar reminders, not code)

- **Every 90 days**: rotate Stripe API keys. Generate new keys in Stripe dashboard, update Netlify env vars, redeploy, then revoke the old keys.
- **Every 6 months**: rotate Supabase JWT secret. Schedule a low-traffic window (signs everyone out).
- **Quarterly**: review the list of users with Supabase project access. Should always be just you. Revoke anyone who shouldn't have it.
- **Weekly**: skim `activity_log` for the past 7 days, looking for unusual admin actions, RLS denials, failed login bursts.

---

## Post-revenue (don't build until needed)

- `httpOnly` cookie migration (auth flow change, risky — only if a paying customer with strict requirements asks)
- IP-restricted admin panel
- External penetration test
- GitHub secret-scanning paid plan (if going private repo)
- SOC2 prep (if enterprise customers ask)
- Per-user RPC rate limiting beyond Supabase platform defaults

---

## What this plan deliberately does NOT do

- **No new external service signups** — everything runs on tools already in use (Supabase, Netlify, Stripe, GitHub, Sentry).
- **No big-bang refactors** — the cutover applies what's on staging, doesn't add features.
- **No data migration from staging** — staging Supabase data does NOT migrate to prod. Prod starts clean. (Users have to recreate engagements if they want to test on prod data after.)
- **No DNS or Stripe changes ahead of cutover day** — keep them on the prod-day checklist so nothing is half-flipped if something breaks.

---

## If something goes wrong mid-cutover

| Scenario | Recovery |
|---|---|
| Migration step fails on prod Supabase | Stop. Don't continue. Tell Claude the exact SQL error. Restore from Supabase's automatic backup if needed. |
| DNS cutover hangs (cert not issuing) | Wait 10 min, then check Netlify domain settings. If still stuck, revert DNS to old A record; investigate. |
| CSP breaks the app | Open `netlify.toml`, add the missing source to the relevant directive, push, wait 1 min for redeploy. |
| First admin can't log in | Most likely a config.js prod URL/key mismatch. Verify env vars saved, redeploy, retry. |
| Stripe Checkout fails | Almost always a wrong-mode key (test vs live mismatch). Verify all 7 Stripe vars in Netlify, redeploy. |

Stay calm. Every step in this plan is independently reversible until DNS flips. The DNS flip is the only point of no easy return — and even that's revertible by switching the A record back.
