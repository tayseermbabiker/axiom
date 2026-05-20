# Sprint 1 — Completion Memo (Verification Spec)

**Status:** CLOSED — verification pass complete 2026-05-20. See "Verification pass" section below for what changed.
**Branch:** `staging` on `tayseermbabiker/axiom`
**Staging URL:** https://staging--auditsaas.netlify.app/

---

## 1. Partner gap addressed

From the 2026-05-19 Qatar partner demo (full doc at `AUDIT SAAS/QATAR-PILOT-FEEDBACK.md`):

> *"Where is the partner sign-off? Where does the partner say, 'I've reviewed everything, here's my conclusion'? We need one place where the partner signs the engagement off."*

The gap: v0.5 had three-level section sign-off but no engagement-level partner rollup. A network inspector would not be able to confirm the partner reviewed the engagement as a whole and accepted the opinion.

**ISA standards this feature is positioned against:**

- **ISA 220 (Revised) — Quality Management for an Audit of Financial Statements** — engagement partner responsibility for the overall engagement and review of work
- **ISA 230 — Audit Documentation** — sufficient documentation of partner conclusions
- **ISA 450 — Evaluation of Misstatements** — final evaluation of uncorrected misstatements vs. materiality
- **ISA 500 — Audit Evidence** — sufficient appropriate evidence has been obtained
- **ISA 540 (Revised), 550, 560, 570, 580** — domain-specific completion checks (estimates, related parties, subsequent events, going concern, written reps)
- **ISA 700 — Forming an Opinion and Reporting** — opinion type selection and basis
- **ISQM 2 — Engagement Quality Reviews** — EQR/EQCR requirement and completion before report date

---

## 2. UI inventory

**Entry point:** `engagement.html` → "Completion Memo" button in page header. Visible to `admin` role only (engagement partner). Pro tier required to *create* a new memo; reading existing memos works on any tier (so a downgrade does not block history).

**Page:** `public/pages/completion-memo.html` (864 lines, self-contained, no external framework). Loads via URL hash `#<engagement_id>`.

**Header:**
- Memo title: `Completion Memo — <client_name>`
- Status badge: `draft` / `complete` / `locked`
- "Back to Engagement" link
- "Refresh System Checks" button (re-runs `recompute_attestation_checks` RPC). Hidden when memo is locked.

**Locked banner** (visible only when `status='locked'`): "Memo is locked. Signed by X on Y. All fields are read-only."

**Pro-tier gate:** `access-blocked` panel shown when `currentOrg.feature_tier !== 'pro'`. Links to `/index.html#pricing`. Page exits before loading memo data.

### Tab 1 — Rollup (default tab)

Four rollup cards + a materiality-vs-misstatements status banner:

| Card | Fields shown | Source |
|---|---|---|
| **Sections** | `sections_approved / total_sections` | `engagement_completion_memo.sections_approved`, `.total_sections` (refreshed by trigger 4) |
| **Findings** | `total_findings` headline; sub `findings_open · resolved · reported` | Same table, refreshed on findings INSERT/UPDATE/DELETE |
| **Misstatements** | `total_misstatements` headline; sub `posted · unposted` adjustments | Refreshed on `adjusting_entries` changes (filtered by `finding_type = 'misstatement'`) |
| **Overall Materiality** | `engagements.materiality_overall`; sub line `Performance: <value>` | Live read from `engagements` (NOT snapshotted while draft — snapshot only on lock) |

**Materiality status banner** (one of four states, color-coded):
- `below` (green) — "Uncorrected misstatements are below overall materiality."
- `approaching` (amber) — "Uncorrected misstatements are approaching overall materiality (75–100%) — review carefully."
- `exceeds` (red) — "Uncorrected misstatements EXCEED overall materiality. Resolve before signing."
- `not_calculated` (gray) — "Materiality not yet entered — set it on the Engagement page first."

Classifier logic (trigger 4): `unposted < 0.75×materiality → below`, `unposted ≤ materiality → approaching`, else `exceeds`. NULL materiality → `not_calculated`.

### Tab 2 — Attestations

Header text: "13 attestations must be ticked before the memo can be signed. The system pre-checks 9 of them. Three (independence, mgmt rep, review notes) are manual. EQR auto-passes if not required."

Counter in tab label: `Attestations (N/13)`.

Each attestation row shows:
- **Check tile** (left): tickable only when (system check passes OR row is manual) AND role is `admin` AND memo not locked. Visual states:
  - Empty (gray border) — not yet ticked, system check passing, ready to tick
  - Ticked (green `✓`)
  - System-fail (red `!`) — system check NOT passing, blocked from ticking
  - Blocked (gray) — memo is locked
- **Title** — human label (e.g., "All Sections Approved")
- **ISA reference tag** — small gray pill (e.g., `ISA 230.7`)
- **Description** — `source_check` text from seed function
- **Status line** — one of: `✓ Attested · <timestamp>` / `System check passed — ready to attest` / `System check NOT passed — resolve before attesting` / `Manual attestation — admin must confirm`

The 13 attestations (full list, from `seed_attestations_for_memo`):

| # | Key | ISA ref | Source check / logic |
|---|---|---|---|
| 1 | `all_sections_approved` | ISA 230.7 | Every audit section for this engagement has `status = 'approved'` |
| 2 | `no_open_findings` | ISA 450.14 | No findings remain in `status = 'open'` |
| 3 | `uncorrected_below_materiality` | ISA 450.14 | Sum of `adjusting_entries.amount where is_posted = false` < `engagements.materiality_overall` |
| 4 | `misstatements_communicated` | ISA 450.14 | Every misstatement finding has `management_response` and is not open |
| 5 | `going_concern_assessed` | ISA 570.26 | Going Concern section is approved AND has a conclusion |
| 6 | `subsequent_events_reviewed` | ISA 560.10 | Subsequent Events section is approved AND has a conclusion |
| 7 | `related_parties_complete` | ISA 550.27 | Related Parties section is approved |
| 8 | `all_procedures_responded` | ISA 500.6 | Every `audit_procedure` has at least one `procedure_response` with `status = 'done'` |
| 9 | `independence_reconfirmed` | ISA 220.14 | **Manual** — admin reconfirms at completion |
| 10 | `written_reps_obtained` | ISA 580.10 | **Manual** — mgmt rep letter obtained (Sprint 2 wires to `mgmt_rep_letters`) |
| 11 | `review_notes_resolved` | ISA 220.17 | **Manual** — all review notes addressed (Sprint 2 adds status column) |
| 12 | `opinion_type_selected` | ISA 700.10 | `engagement_completion_memo.opinion_type IS NOT NULL` |
| 13 | `eqr_review_complete` | ISQM 2 / ISA 220 Rev | If `eqr_required = false`: auto-pass. If true: `eqr_completed_at IS NOT NULL` |

### Tab 3 — Narrative

Three free-text fields, saved together via "Save Narrative" button:
- **Going Concern Conclusion** — labeled `(ISA 570)`. Placeholder: "State the partner's conclusion on management's going concern assessment..." Hint: "Auto-populated from the Going Concern section if available. Edit as needed." (Note: auto-populate not actually wired yet — see Judgment Calls.)
- **Subsequent Events Conclusion** — labeled `(ISA 560)`
- **Other Matters** — free-form

All three stored on `engagement_completion_memo.{going_concern_conclusion, subsequent_events_conclusion, other_matters}`.

### Tab 4 — Opinion

- **Opinion Type** dropdown (ISA 700): unmodified / qualified / adverse / disclaimer
- **Basis for Opinion** textarea — auto-hidden when `unmodified` selected; **required** when modified (validated client-side in `saveOpinion()`)

Saved to `engagement_completion_memo.{opinion_type, opinion_basis_notes}`. After save, triggers `recompute_attestation_checks` so attestation #12 (`opinion_type_selected`) flips.

### Tab 5 — EQR

- **Checkbox** "EQR is required for this engagement (ISQM 2 / ISA 220 Revised)" — toggling fires `saveEqrRequired()` immediately, then `refreshChecks()`
- Hint: "Typically required for listed entities, public interest entities, high-risk engagements, or where network methodology mandates it."
- When checked, additional fields appear:
  - **Engagement Quality Reviewer** dropdown — populated from `organization_members` (all roles). Hint: "Must be different from the engagement admin (partner)."
  - "Save Reviewer" button → updates `eqr_reviewer_id`
  - "Mark EQR Complete" button → enforces `currentUser.id === memo.eqr_reviewer_id` client-side, sets `eqr_completed_at` + `eqr_completed_by`
- Status line: "EQR completed by <reviewer> on <timestamp>." when complete

### Signoff bar (sticky, bottom of page)

- Progress text: `N / 13 attestations complete`
- "Sign & Lock Memo" button — enabled only when `memo.status === 'draft' && memo.all_attestations_complete && currentRole === 'admin'`. Browser-native `confirm()` before signing.
- Hidden entirely when memo is locked.

---

## 3. Data model

**Migrations** (all applied to staging):

- `20260519120000_feature_tier.sql` — adds `organizations.feature_tier` enum + `org_has_pro_tier()` helper
- `20260519120001_rls_helpers.sql` — `get_user_org_ids()` helper used by all RLS policies
- `20260519120002_completion_memo.sql` — the two tables below
- `20260519120005_triggers.sql` — 4 triggers (see below)
- `20260519120006_attestation_registry.sql` — `seed_attestations_for_memo()` + `recompute_attestation_checks()` RPCs

### Table: `engagement_completion_memo` (one row per engagement, UNIQUE on `engagement_id`)

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | |
| `engagement_id` | uuid, **UNIQUE**, FK→engagements | |
| `organization_id` | uuid, FK→organizations | |
| `status` | text | `draft` / `complete` / `locked`. Default `draft`. The `complete` value is in the CHECK constraint but not currently used in the workflow — `draft` flips straight to `locked` on sign. See Judgment Calls. |
| Rollup fields | int (9 of them) | Refreshed by trigger 4 while `status='draft'`, frozen on lock |
| `overall_materiality_snapshot`, `performance_materiality_snapshot` | numeric | Set by trigger 2 on lock |
| `uncorrected_vs_materiality` | text enum | `below`/`approaching`/`exceeds`/`not_calculated` — set by trigger 4 |
| `eqr_required` | bool, default false | |
| `eqr_reviewer_id`, `eqr_completed_at`, `eqr_completed_by` | uuid + ts + uuid | |
| `going_concern_conclusion`, `subsequent_events_conclusion`, `other_matters` | text | Narrative tab |
| `opinion_type`, `opinion_basis_notes` | text + text | ISA 700 |
| `all_attestations_complete` | bool, default false | Flipped by trigger 1 |
| `signed_by`, `signed_at`, `snapshot_taken_at` | uuid + ts + ts | Set on lock |
| `created_at`, `updated_at` | timestamptz | |

**RLS:**
- SELECT — any org member
- INSERT — org member AND `org_has_pro_tier(organization_id)`
- UPDATE — any org member (Pro check only on INSERT — see Judgment Calls)

### Table: `completion_attestations` (13 rows per memo)

| Column | Notes |
|---|---|
| `id`, `memo_id`, `organization_id`, `engagement_id` | FK chain |
| `attestation_key`, `attestation_order`, `isa_reference`, `source_table`, `source_check` | Seeded constants |
| `system_check_passed`, `system_checked_at` | Updated by RPC `recompute_attestation_checks` |
| `attested_by`, `attested_at` | Set when admin ticks the check |
| UNIQUE INDEX | `(memo_id, attestation_key)` |

**RLS:** same shape as the memo table. UPDATE open to any org member — see Judgment Calls (only admin role enforced client-side).

### Triggers (migration 005)

1. **`fn_check_attestation_completeness`** — `AFTER UPDATE OF attested_at` on `completion_attestations`. Counts ticked vs. total; flips `memo.all_attestations_complete` to true when 13/13, back to false on any un-tick.
2. **`fn_snapshot_and_lock_memo`** — `BEFORE UPDATE OF signed_at` on the memo. When `signed_at` transitions from NULL to a value: validates `all_attestations_complete = true` (else RAISE), then sets `status='locked'`, `snapshot_taken_at=now()`, snapshots both materiality values from `engagements`.
3. **`fn_block_engagement_close`** — `BEFORE UPDATE OF status` on `engagements`. Blocks transition into `'completed'` unless a locked memo exists with `all_attestations_complete = true AND signed_at IS NOT NULL`. **This is the network-inspection-survival gate.**
4. **`fn_refresh_memo_rollups`** — `AFTER INSERT/UPDATE/DELETE` on `audit_sections`, `findings`, `adjusting_entries`. Recomputes all 9 rollup fields + `uncorrected_vs_materiality` classifier. Only fires for memos in `status='draft'` (snapshot frozen once locked).

### RPCs

- **`seed_attestations_for_memo(p_memo_id, p_organization_id, p_engagement_id) → int`** — SECURITY DEFINER. Inserts the 13 attestation rows. Called from the client immediately after creating the memo. Membership check via `organization_members`.
- **`recompute_attestation_checks(p_memo_id) → void`** — SECURITY DEFINER. Re-runs all 13 system checks. Called on page load, after opinion save, after EQR toggle, after attestation toggle.

---

## 4. Permissions & workflow

### Role gates

| Action | Role | Tier gate |
|---|---|---|
| See "Completion Memo" button on engagement page | `admin` | none (button visible to admin regardless of tier; Pro check on the destination page) |
| Create memo (INSERT) | any role, enforced by client as `admin` only | **Pro** (RLS enforces) |
| Read memo | any org member | none |
| Tick / un-tick attestation | `admin` (client-enforced; RLS allows any org member) | none |
| Save narrative / opinion / EQR fields | `admin` (client-enforced; RLS allows any org member) | none |
| Mark EQR complete | `currentUser.id === memo.eqr_reviewer_id` (client-enforced) | none |
| Sign memo | `admin` AND all 13 attestations ticked | none on the sign action itself — but the memo had to be created on Pro |
| Close engagement (`status → 'completed'`) | DB trigger blocks unless locked memo exists | — |

### State machine

```
[draft] ──(13/13 attestations ticked)──▶ all_attestations_complete=true
   │
   │ admin clicks "Sign & Lock Memo"
   │ ↓ signed_at set
   ▼
[BEFORE trigger fires]
   ├─ if NOT all_attestations_complete → RAISE EXCEPTION
   └─ snapshot materiality + set status='locked' + snapshot_taken_at=now()
   ▼
[locked] ──▶ engagement.status can now transition to 'completed'
```

The `'complete'` status value exists in the CHECK constraint but is unused in current workflow — see Judgment Calls.

---

## 5. Out of scope (NOT built in Sprint 1)

Reviewers please don't flag these as gaps — they are intentionally deferred:

- **PDF export of the signed memo** — Sprint 3+ (inspection PDF will subsume this)
- **Mgmt rep letter wiring** — attestation #10 is manual-only in Sprint 1; Sprint 2 adds `mgmt_rep_letters` table + binding to attestation
- **Review-note status column** — attestation #11 is manual-only; Sprint 2 adds `review_notes.status`
- **EQR reviewer ≠ admin enforcement at DB level** — currently only soft-warned client-side
- **EQR documentation workpaper** — Sprint 2+; the checkbox + completion timestamp is the v1 surface area
- **Auto-populating narrative fields from section conclusions** — UI hint says it's wired but it isn't yet; the field is empty on first load
- **Locking individual narrative fields independently** — whole memo locks atomically on sign
- **Re-opening a locked memo** — no UI path; would require DB intervention. Intentional for evidence integrity
- **Multi-partner sign-off** — single partner signs; second partner (silent observer in Qatar demo) not yet a workflow citizen
- **Engagement letter / independence confirmation / client acceptance workpapers** — Sprint 2
- **Planning + materiality calculation workpaper (full)** — Sprint 3 (materiality calculator exists at engagement level; planning narrative does not)
- **Risk assessment matrix (significant risks per assertion)** — Sprint 3
- **Procedure rewrite to directive style** — separate Sprint 1 task (Going Concern), not in this feature

---

## 6. Judgment calls made

These are the lines reviewers should attack hardest. Each is a place where I picked one path over another.

### J1 — Pro tier gate is enforced only on memo INSERT, not on attestation INSERT/UPDATE or memo UPDATE

**Choice:** RLS for `engagement_completion_memo` INSERT requires Pro; UPDATE is open to any org member. Attestations: INSERT requires Pro, UPDATE open to any org member.

**Reasoning:** Lets an org that downgrades from Pro → Essentials retain access to historical memos (read + minor edits) without paying again. Prevents the worst regressive UX. But it means a downgrade does not actually take away the ability to *finish signing* an in-flight memo.

**Risk:** Inconsistent gating. If a network inspector asks "did Pro paying status correlate to the dates of attestations?" — we'd have to say "the memo was created on Pro but the attestations could have been ticked after downgrade."

**Alternative considered:** Hard-gate every write. Rejected because the demo target is small firms with cash-flow lumpiness — they may pause Pro for a month, then resume.

### J2 — Single-partner sign-off (no second signature)

**Choice:** One `signed_by` / `signed_at` field. Single click locks the memo.

**Reasoning:** All Audexon target firms (1–10 partner shops) operate under single-partner accountability. ISA 220 puts the engagement partner as the responsible individual.

**Risk:** Does not model dual-partner concurrence which some networks (e.g., RSM, Crowe) require for higher-risk engagements. EQR is the closest analog and is modeled separately.

### J3 — The `'complete'` status value is unused

**Choice:** CHECK constraint allows `draft / complete / locked` but workflow only uses `draft → locked`.

**Reasoning:** Originally planned a `complete` intermediate state (all attestations done but not yet signed). Removed it as redundant because `all_attestations_complete` boolean serves the same purpose.

**Risk:** Dead value in the schema. Should either remove from CHECK or wire up a use case. Minor.

### J4 — Materiality is *read live* during draft, *snapshotted* on lock

**Choice:** Rollup tab and trigger 4 both read `engagements.materiality_overall` live. Snapshot columns (`overall_materiality_snapshot`, `performance_materiality_snapshot`) are populated only by trigger 2 on lock.

**Reasoning:** Partner may revise materiality during the engagement; the memo should reflect the current value while still open. On lock, freezing the value preserves evidence integrity for inspection.

**Risk:** If materiality is changed *during* signing (race condition), the snapshot captures the value at lock time, not at the time attestation #3 was ticked. Practically unlikely (admin user, single browser tab).

### J5 — System check 5/6/7 match section names with `ILIKE '%going concern%'` etc.

**Choice:** Triggers and `recompute_attestation_checks` look for sections by name pattern, not by a typed `section_kind` column.

**Reasoning:** v0.5 schema has no typed kind on `audit_sections`; sections are seeded by `audit-templates.js` and named in English.

**Risk:** Internationalization, renaming, custom-named sections — all break the match. Should add a `section_kind` enum or canonical key to `audit_sections` (Sprint 2 cleanup).

### J6 — Manual attestations (9, 10, 11) have `system_check_passed = true` always

**Choice:** RPC sets system_check_passed = true for the three manual rows so the UI lets the admin tick them.

**Reasoning:** No way to system-verify these in Sprint 1 (no mgmt rep table, no review-note status). Admin's manual tick is the audit-trail evidence.

**Risk:** Admin can tick without doing the underlying work. The audit-trail row (`attested_by`, `attested_at`) is the evidence — same standard as paper-based audits.

### J7 — Trigger 4 fires on every section/finding/adjustment write

**Choice:** Three separate `AFTER` triggers, all calling the same function, which runs ~9 COUNT queries per fire.

**Reasoning:** Keeps the memo live without polling. Cost is bearable at small-firm scale (one engagement = 19 sections × 5–20 findings).

**Risk:** Scales poorly. If a firm bulk-imports findings (Sprint 3 risk?), each insert fires the trigger. Mitigation: batch ops should `SET session_replication_role` or trigger fires once at end. Not addressed.

### J8 — Engagement closure block uses `EXISTS` on locked memo, not `engagement.completion_memo_id`

**Choice:** Trigger 3 looks up the memo by `engagement_id` each time, rather than adding a denormalized FK.

**Reasoning:** Simpler, no migration to existing `engagements` table.

**Risk:** Slightly slower lookup; rationally indexed via `idx_ecm_engagement_id`.

### J9 — `confirm()` (browser-native) used for sign action

**Choice:** Plain `confirm('Sign and lock this completion memo? ...')`.

**Reasoning:** Quick to ship. Engagement.html has a fancier `showActionModal` but the memo page doesn't include it.

**Risk:** Inconsistent UX vs. rest of app. Not safety-critical (sign is recoverable only by DB intervention either way).

---

## 7. Verification questions for Perplexity

Paste any of these into Perplexity for deep ISA research. The goal is to confirm or refute the judgment calls and attestation set.

**On the attestation list:**

1. "For an ISA 220 (Revised) compliant audit completion memo at a non-PIE small-firm audit, what is the minimum set of attestations the engagement partner should sign? Specifically: should we be including attestations beyond the 13 currently listed — e.g., fraud risk assessment (ISA 240), accounting estimates (ISA 540), opening balances (ISA 510), or use of internal audit work (ISA 610)?"

2. "Under ISA 580.10, is obtaining a written representation letter a binary prerequisite or does the standard permit completion of the audit with limited reps disclosed in the auditor's report? If binary, our manual attestation #10 must remain blocking — confirm."

3. "ISA 220 (Revised) replaced ISA 220 in late 2023. Are there any new partner-level obligations in the Revised version that an audit completion memo MUST evidence — e.g., resources allocation review, network monitoring expectations — that are absent from our 13-item list?"

4. "Does ISA 230 specify a minimum retention period for the completion memo (e.g., 5 or 7 years post-report date)? We are not currently tracking retention dates."

**On EQR (ISQM 2):**

5. "Under ISQM 2, what triggers a mandatory EQR for a non-PIE engagement? Our UI says 'listed entities, PIEs, high-risk engagements, or network mandates' — is 'high-risk' a defined ISQM 2 term, or did we paraphrase? What is the actual ISQM 2 definition?"

6. "Is there an ISQM 2 requirement that the EQR be completed BEFORE the auditor's report date? Our flow allows the EQR mark-complete to happen at any time before the engagement is closed. Should we enforce a sequence?"

**On materiality + misstatements:**

7. "ISA 450.11 requires the auditor to communicate uncorrected misstatements to TCWG and request correction. Our attestation #4 (`misstatements_communicated`) checks for `management_response` on each misstatement finding. Is having a `management_response` field sufficient evidence of ISA 450.11 communication, or is a separate communication letter required?"

8. "Our materiality-vs-misstatements classifier uses thresholds: below 75% of overall = 'below', 75–100% = 'approaching', >100% = 'exceeds'. Is the 75% threshold an ISA-recognized line, or is this a judgment call? ISA 320 talks about performance materiality but I want to confirm we're not implying a false standard."

**On the sign-off lock:**

9. "Once an engagement partner signs the completion memo and we lock all related fields, is there an ISA requirement that supports OR forbids re-opening it? E.g., if a subsequent event under ISA 560 emerges after sign-off, what is the auditor's documentation obligation?"

10. "Network inspections (BDO, RSM, Mazars, Crowe) — when an inspector reviews the completion memo, what specific evidence are they checking for that our 13-attestation list might miss? Is there a published network inspection checklist we should benchmark against?"

**On documentation completeness:**

11. "ISA 230.10 says documentation should be 'sufficient to enable an experienced auditor with no previous connection with the audit to understand the nature, timing, and extent of work performed.' Does our memo achieve this with the rollup numbers + narrative fields + attestation list, or are there specific required documentation elements missing (e.g., the actual results of significant procedures)?"

---

## 8. Verification questions for Copilot (code review)

Paste into Copilot Chat against the relevant files:

1. **`completion-memo.html` line 854** — `saveEqrReviewer()` has a guard that triple-checks the reviewer equals both engagement.created_by AND currentUser.id. Is this logic correct? It looks like a copy-paste bug — the intent is "reviewer should not be the admin," but the check is more restrictive than that.

2. **`completion-memo.html` lines 887-905** — `signMemo()` does not refresh memo state after the update. The trigger sets `status='locked'` server-side; the client only knows because of a downstream fetch. Is there a race where the next user action sees stale state?

3. **`migrations/20260519120002_completion_memo.sql` line 87** — RLS UPDATE policy on `engagement_completion_memo` does not include the Pro check (only INSERT does). Is this intentional or a bug? See Judgment Call J1.

4. **`migrations/20260519120005_triggers.sql` lines 143-156** — `fn_refresh_memo_rollups` resolves `engagement_id` from three different tables. Confirm the DELETE branches work (NEW is NULL on DELETE; OLD has the data).

5. **`migrations/20260519120006_attestation_registry.sql` line 137-141** — the `uncorrected_below_materiality` check uses a JOIN through findings to derive engagement_id. Does this correctly count adjusting entries that aren't tied to a finding? (Adjusting entries with NULL `finding_id` would be excluded — is that intended?)

6. **Trigger 4 fire frequency** — `fn_refresh_memo_rollups` runs ~9 COUNT subqueries on every INSERT/UPDATE/DELETE on three tables. At what scale does this become a problem?

---

## 9. Closure checklist

Sprint 1 — Completion Memo closes when:

- [ ] Perplexity questions 1–11 answered; spec updated with conclusions
- [ ] Copilot questions 1–6 addressed; code fixes committed or deferred with reason
- [ ] Any gaps surfaced trigger either a fix or a documented "deferred to Sprint N" entry in Section 5
- [ ] User reviews and signs off on this spec

When all four boxes are ticked, this feature is **CLOSED** and we move on without revisiting.

---

## 10. Verification pass — 2026-05-20

Cross-checked against Perplexity (ISA research) + GitHub Copilot (code review) + claude.ai (product tiebreaks). Three commits applied:

- `9e8d19f` — mechanical fixes (EQR guard bug, EQR hint wording, materiality threshold labels)
- `88bbf04` — ISA 220 Revised gap (resources/consultations field) + Pro-tier gate on sign-off
- Migration `20260520120000_verification_fixes.sql` applied to staging Supabase

### Issues fixed

| # | Source | Issue | Fix |
|---|---|---|---|
| C1 | Copilot Q1 | `saveEqrReviewer` guard had a copy-paste triple-check that only fired when admin picked themselves | Replaced with `reviewerId === engagement.created_by` |
| C2 | Copilot Q2 | `signMemo` stale state concern | Verified already present (re-fetch + renderAll at signMemo end) — Copilot snippet was truncated |
| C3 | Copilot Q3 + claude.ai | RLS UPDATE allowed downgraded orgs to sign for free | `fn_snapshot_and_lock_memo` now checks `org_has_pro_tier()` at moment of signing. Edits stay open; signing requires Pro. Loophole closed without punishing mid-engagement cash flow pauses |
| P3 | Perplexity Q3 + claude.ai | ISA 220 (Revised) gap on resources/specialists/consultations evidencing | Added `resources_consultations` narrative field with NOT NULL default ("No specialists engaged. No formal consultations required."). Field is never blank at inspection; partner overwrites when applicable. Chose narrative over 2 new attestations to avoid friction on simple audits |
| P5 | Perplexity Q5 | EQR trigger hint wording was loose paraphrase | Rephrased: "Required by ISQM 2 for listed entities, other PIEs, engagements with significant risks or complex/contentious judgements, or engagements designated by your firm's ISQM 1 risk assessment or network policy." |
| P8 | Perplexity Q8 | 75% materiality bands could imply false ISA standard | Banner text now explicit: "firm policy threshold — ISA 320 does not prescribe a fixed band" / "not an ISA-mandated threshold" |

### Confirmed-correct-as-built (no change needed)

| # | Source | Finding |
|---|---|---|
| P1 | Perplexity Q1 | 13-attestation list is a valid design choice for non-PIE small firms; not a mandated count |
| P2 | Perplexity Q2 | Treating written-rep attestation as blocking is aligned with ISA 580.10-11 |
| P6 | Perplexity Q6 | EQR before report date — our system check #13 blocks signing without EQR completion, which is the effective enforcement at v1 scale. Partner sign-date IS the report date |
| C4 | Copilot Q4 | DELETE trigger paths correct as-built for current schema (finding_id always present) |
| C5 | Copilot Q5 | INNER JOIN through findings is correct under current design assumption (every adjusting entry tied to a finding). Constraint hardening deferred |
| C6 | Copilot Q6 | Trigger performance fine at small-firm scale (<500 findings, <1000 adjustments, <30 writes/sec). Rule of thumb documented |

### Deferred to Sprint 2/3 (logged here, will not be revisited in Sprint 1)

| # | Source | Why deferred |
|---|---|---|
| P4 | Perplexity Q4 | 5-year retention tracking — needs new fields + UI surface area; Sprint 3 |
| P7 | Perplexity Q7 | TCWG-vs-management communication distinction on misstatements — needs findings schema change; Sprint 2 |
| P9 | Perplexity Q9 | Append-only addendum support post sign-off — new design pattern; Sprint 3 |
| P11 | Perplexity Q11 | "Significant Matters with workpaper cross-refs" section — requires workpaper reference model; Sprint 2 |
| C5b | Copilot Q5 | `adjusting_entries.finding_id NOT NULL` constraint — needs data audit first; Sprint 2 |
| C6b | Copilot Q6 | Trigger statement-batching optimization — escape hatch only; revisit when an engagement crosses the documented thresholds |

**Sprint 1 — Completion Memo: CLOSED.**
