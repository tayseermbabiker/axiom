# Sprint 4 — Standards Floor (Verification Spec)

**Status:** SHIPPED — awaiting Perplexity + Copilot answers, then close.
**Branch:** `staging` on `tayseermbabiker/axiom`
**Sprint window:** 2026-05-23 (1-day push, 7 commits)
**Effort actual:** ~7 hours coding (Claude Opus 4.7) + ~1 hour spec + manual SQL apply per migration.

---

## 0. What triggered this sprint

User shifted the gap-benchmark rule mid-conversation:

> "What Qatar partner said is not a comprehensive list. He only said what came at the top of his head. So if something is missing by standard or best practice, say our benchmark is Perplexity. We need to put it. So we don't sit here again, walla shno."

Until that point, Sprint 3 had been planned around the Qatar partner's verbal gap list (planning / materiality / risk / completion memo / FS upload / procedure specificity). The new rule says: **standards floor = Perplexity's IFAC-anchored gap list, not partner verbal asks.** Captured in memory at `feedback-audexon-perplexity-benchmark.md`.

Sprint 4 implements the full 7-item standards floor from the 4-AI synthesis 2026-05-23, in 9 days before the Qatar partner pilot demo 2026-06-01.

---

## 1. The 4-AI synthesis that drove scope

Four independent AI reviews of `docs/COVERAGE-REPORT.txt` (Perplexity / Copilot / Claude.ai independent + Claude.ai meta-review of the other two) converged on a single list of items every SME audit file needs under ISA, even if no inspector or partner has asked yet:

| ISA | Item | Pre-sprint state | Demo-blocking per Claude.ai | Tier per Copilot | Per Perplexity |
|---|---|---|---|---|---|
| 450 | Consolidated misstatement schedule | data existed, no view | YES | Tier 1 | "must but light" |
| 540 | Accounting estimates | buried in findings | post-demo | Tier 2 | "must but light, UAE inspection hot spot" |
| 505 | External confirmations | buried in procedure_responses | post-demo | Tier 1 | "must but light" |
| 530 | Sampling documentation | free text | post-demo | Tier 2 | "must but light" |
| 315 | Understanding the entity | parked 2026-05-21 | defensible | Tier 1 | "must but light, embed not separate" |
| 510 | Opening balances | nothing | defensible | Tier 2 | "checkbox is enough" |
| 230 | File assembly lock | engagement.status=completed only | defensible | Tier 3 | "toggle is enough" |

User's decision after 4-AI synthesis: **build all 7 before demo.** Coverage % debate (78 / 80-83 / 85-88 / 90-93) was treated as theatre — the right framing is "structure complete, depth varies." Reconciled real coverage post-Sprint-4: ~92% structural, ~80% inspection-depth.

---

## 2. Per-module shipped

### 2.1 ISA 450 — Consolidated misstatement schedule

**Commit:** `0f16aba`
**Migration:** none — pure UI on existing `findings` + `adjusting_entries`.
**Files:** `public/pages/completion-memo.html`, `public/pages/report.html`.

**UI:**
- New block inside the Completion Memo Rollup tab, below the four aggregate cards.
- Three groups: **Corrected** (has at least one posted adjusting entry), **Uncorrected** (no posted adjustment, not flagged trivial — accumulate against materiality per ISA 450.11), **Clearly trivial** (`close_category = 'unadjusted_immaterial'` — per ISA 450.5).
- Per-row columns: finding title + effect excerpt, section name, monetary impact, dr/cr accounts of each adjusting entry, posted status (Posted / Partial / Not posted / —).
- Group subtotals + total row showing **Uncorrected as % of overall materiality** when materiality is set.
- Auto-refreshes on Refresh System Checks.

**PDF:** "Misstatement Schedule (ISA 450)" section in completion report replaces the prior "Summary of Unadjusted Misstatements". Same three-group layout + per-group Σ + aggregate-evaluation table vs overall / performance materiality.

**Classification logic:**
```js
if (anyAdjustingEntry.is_posted)        → corrected
else if (close_category === 'unadjusted_immaterial') → clearly_trivial
else                                    → uncorrected
```

**No new schema.** Data was already there from Sprint 1 — only the surface was missing.

---

### 2.2 ISA 540 — Accounting estimates

**Commit:** `e7a19df`
**Migration:** `20260523120002_isa_540_estimates.sql`
**Files:** `public/pages/engagement.html`, `public/pages/report.html`, migration.

**Schema — `public.engagement_estimates`:**

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | gen_random_uuid() |
| `engagement_id` | uuid FK | ON DELETE CASCADE |
| `organization_id` | uuid FK | ON DELETE CASCADE |
| `section_id` | uuid FK | ON DELETE SET NULL — optional link |
| `estimate_name` | text NOT NULL | required |
| `method_used` | text | ISA 540.13(a) |
| `key_assumptions` | text | ISA 540.13(c) |
| `data_sources` | text | ISA 540.13(b) |
| `sensitivity_analysis` | text | ISA 540.15 |
| `misstatement_risk` | text | CHECK IN (low/medium/high/significant) |
| `conclusion` | text | |
| `created_by` | uuid FK profiles | |
| `created_at, updated_at` | timestamptz | trigger sets updated_at |

**RLS:** org-member SELECT; admin + Pro INSERT/UPDATE/DELETE. Same pattern as the rest of the Pro-tier workpapers.

**UI:** new "Estimates" tab in Execution phase between Findings and Financial Statements. Table view + modal with all 7 fields + section linker. Color-coded risk badges (green/amber/red/dark-red).

**PDF (completion only):** "Significant Accounting Estimates (ISA 540)" with one table per estimate showing risk badge, linked section, and all 5 narrative fields + conclusion.

**Scope chosen vs declined:**
- ✅ Manual structured fields per Perplexity / Copilot.
- ❌ Automated sensitivity engine — per `audexon-scope-freeze`.
- ❌ Per-estimate sign-off chain — partner sign-off lives at completion memo level.

---

### 2.3 ISA 505 — External confirmations tracker

**Commit:** `53c2ea5`
**Migration:** `20260523120003_isa_505_confirmations.sql`

**Schema — `public.engagement_confirmations`:**

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | |
| `engagement_id` | uuid FK | |
| `organization_id` | uuid FK | |
| `section_id` | uuid FK | optional, ON DELETE SET NULL |
| `counterparty` | text NOT NULL | required |
| `confirmation_type` | text NOT NULL | CHECK IN (bank / ar / ap / legal / related_party / other) |
| `sent_date` | date | |
| `returned_date` | date | UI validates ≥ sent_date |
| `result` | text | CHECK IN (clean / exception / partial / no_reply) — null = pending |
| `alternative_procedures` | text | ISA 505.12 — required when result IN (exception, no_reply) |
| `notes` | text | |
| `created_by` | uuid FK profiles | |
| `created_at, updated_at` | timestamptz | trigger |

**Key catch (Perplexity):** the `alternative_procedures` field is ISA 505.12 evidence — Copilot's original 6-field design missed it. Without it, no-reply confirmations would be inspection failures.

**UI:** new "Confirmations" tab in Execution between Estimates and Financial Statements. Status summary chip row (clean / exception / partial / no_reply / pending counts) above the table. Modal form with all fields. **Soft gate:** when result is `exception` or `no_reply`, form blocks save until `alternative_procedures` is documented (clear error message cites ISA 505.12).

**PDF (completion only):** "External Confirmations (ISA 505)" — summary line of counts + per-confirmation row with alternative-procedures column.

---

### 2.4 ISA 530 — Audit sampling documentation

**Commit:** `7f323ff`
**Migration:** `20260523120004_isa_530_sampling.sql`

**Schema — `public.procedure_sampling`:**

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | |
| `procedure_id` | uuid NOT NULL UNIQUE | FK audit_procedures, ON DELETE CASCADE. **UNIQUE** = at most one card per procedure |
| `population_description` | text | ISA 530.7 |
| `population_size` | numeric | |
| `sample_size` | numeric | UI: ≤ population_size |
| `sampling_method` | text | CHECK IN (random / systematic / haphazard / monetary_unit / judgmental / other) |
| `selection_basis` | text | how items were picked |
| `results_summary` | text | ISA 530.A21 |
| `projection_amount` | numeric | optional projected misstatement |
| `conclusion` | text | ISA 530.15 |
| `notes` | text | |
| `created_by, created_at, updated_at` | | trigger |

**RLS:** single `psamp_all` policy that derives org via procedure → section → engagement (same pattern as `procedure_responses`).

**UI:** **per-procedure**, not a tab. New "Sampling" button in each procedure card action row in `section.html`. Label toggles between "+ Sampling" and "Edit sampling". When sampling exists, an inline summary chip appears inside the procedure body ("ISA 530 sampling: 30 of 850 · method: random · results excerpt"). Modal with all 9 fields.

**PDF (completion only):** "Audit Sampling Documentation (ISA 530)" aggregating every sampling card across the engagement, grouped by section / procedure. **Trade-off:** the parked spec assumed procedures would render in the PDF — they don't (per ISA 220 / Big-4 methodology, partner-facing reports omit section workpapers). So sampling aggregates at completion instead of nesting under each procedure. Consistent with how estimates + confirmations were placed.

---

### 2.5 ISA 315 — Understanding the entity (un-parked, embedded)

**Commit:** `e007839`
**Migration:** `20260523120001_isa_315_understanding.sql`

**Context:** Originally parked 2026-05-21 via 3-AI go/no-go (`sprint-3-understanding-entity-go-no-go.md`). Decision was Option C — embed in Audit Planning as Section B inside the existing workpaper. Un-parked here under the Perplexity-benchmark rule. The parked design was used verbatim.

**Schema:** ALTER existing `public.engagement_audit_strategies` — no new table:

- 3 new attestation booleans (NOT NULL DEFAULT false): `isa_315_inquiry_performed`, `isa_315_analytical_performed`, `isa_315_observation_inspection_performed` — map to ISA 315.14(a)/(b)/(c).
- 2 new narratives: `industry_external_environment` (ISA 315.19(a)), `significant_changes_from_prior_year` (ISA 315.A47).
- **Backfill:** existing approved strategy rows pre-Sprint-4 had attestations defaulted to false. The migration `UPDATE`s them to true — defensible because the partner already signed off on the full audit strategy (which inherently includes ISA 315 procedures). New approvals after this migration must explicitly tick.
- **New named CHECK:** `isa_315_attestations_required_on_approve` gates approval on all 3 procedures = true.
- `revise_audit_strategy` RPC updated to carry forward all Tier 1 fields (which it previously dropped — note in migration 20260522120000 flagged this) plus the new ISA 315 fields. Attestations still reset to false on revise (each version gets fresh sign-off per ISA 300.12).

**UI:** "Audit strategy" relabelled **"Audit planning"** across the app (nav tab, h2, button, PDF section header). New "Understanding the entity (ISA 315)" section between the existing ISA-specific narratives and Partner Attestations. Two narrative textareas + a structured card containing the three procedure attestations. Confirm-validation requires all 3 ISA 315 attestations ticked before approval (matches DB CHECK).

**PDF:** "Audit Planning (ISA 300 + ISA 315)" header. New fields rendered under ISA-specific narratives. ISA 315.14 attestations rendered as a check-mark table.

---

### 2.6 ISA 510 — Opening balances (one checkbox, not a module)

**Commit:** `d9f7894` (bundled with ISA 230)
**Migration:** `20260523120000_isa_510_and_230.sql`

Perplexity nuance: "ISA 510 can be a field, not a module. For continuance engagements (majority of files), it's N/A — a clear note in planning or acceptance is enough."

**Schema:** ALTER `public.engagement_acceptance`:

- `opening_balances_status` text, CHECK IN (`verified`, `na_continuance`, NULL).
- `opening_balances_notes` text.
- `revise_engagement_acceptance` RPC updated to carry forward both fields.

**UI:** new "Opening balances (ISA 510)" section between Prior-issues and Partner Attestation on the Acceptance workpaper. Dropdown + textarea. Confirm-validation hard-gates: when status is `verified`, notes are required ("describe the ISA 510 approach").

**PDF:** "Opening balances (ISA 510)" sub-block under the Acceptance section in planning report.

---

### 2.7 ISA 230 — File assembly archive (one toggle, not a module)

**Commit:** `d9f7894` (bundled with ISA 510)

**Schema:** ALTER `public.engagements`:

- `is_archived` boolean NOT NULL DEFAULT false.
- `archived_at` timestamptz.
- `archived_by` uuid FK profiles.

**RPCs (admin-only, SECURITY DEFINER):**
- `archive_engagement(engagement_id, organization_id)` — hard-gates on completion memo being `status='locked'`. Per ISA 230.A23 (file assembly happens AFTER auditor's report is dated).
- `unarchive_engagement(...)` — for rare ISA 560.A14-A19 post-issuance scenarios. Logged via activity_log as post-assembly change.

**UI (engagement.html):**
- Engagement card: when `engagement.status='completed'` + admin, "Archive (ISA 230)" button appears next to "Reopen Engagement". Confirm dialog before action.
- Archived state takes precedence: new banner ("File assembled and archived per ISA 230 on [date]. No further changes permitted without partner reopening."). All create/upload buttons hidden. Only "Unarchive (post-assembly change)" available for admin — opens reason modal.

**PDF:** when archived, completion memo block stamps "File assembly (ISA 230): ARCHIVED · assembled [date] by [name]".

**Out of scope:** RLS-level hard immutability on child tables. UI gates + memo lock provide effective immutability for v1; full DB-level enforcement would require touching every child table's RLS policy — too risky in 1hr scope. Tracked as follow-up if a network inspector flags during pilot.

---

## 3. Migrations applied (in order)

| # | File | Purpose | Status |
|---|---|---|---|
| 1 | `20260523120000_isa_510_and_230.sql` | ISA 510 columns on acceptance + ISA 230 columns + RPCs on engagements | applied to staging |
| 2 | `20260523120001_isa_315_understanding.sql` | ISA 315 columns on audit_strategies + named CHECK + revise RPC fix | applied to staging |
| 3 | `20260523120002_isa_540_estimates.sql` | new engagement_estimates table | applied to staging |
| 4 | `20260523120003_isa_505_confirmations.sql` | new engagement_confirmations table | applied to staging |
| 5 | `20260523120004_isa_530_sampling.sql` | new procedure_sampling table | applied to staging |

All migrations confirmed by user as `run successfully` on staging Supabase `lbwowlvajgpdxsdpudem`. Prod application pending pilot lock-in decision.

---

## 4. Architectural principles reinforced

Two memories were written during this sprint to encode the durable decisions:

**`feedback-audexon-perplexity-benchmark.md`:** Standards floor = Perplexity's IFAC-anchored gap list, NOT partner verbal asks, NOT Copilot's label-trusting reads.

**`audexon-scope-freeze.md`** — items deliberately NOT built:
- SOX-style controls testing workflows
- Automated analytics dashboards (per-engagement)
- Risk scoring engines (numeric/algorithmic)
- AI-driven anomaly detection
- IFRS disclosure checklists
- Multi-entity consolidation
- Automated sampling engines (vs documentation of sampling judgment)
- More granular review stages beyond preparer / supervisor / partner
- Full TB↔FS automated reconciliation module
- Standalone Permanent File concept
- Per-ISA mirror modules
- ISQM 1 firm-wide quality dashboard (deferred to post-revenue tier)

---

## 5. Verification questions for Perplexity (ISA research)

1. **ISA 450 classification edge case.** A misstatement finding has both a posted adjusting entry AND `close_category='unadjusted_immaterial'`. Our classifier puts it in "Corrected" (posted check fires first). Is that the right ISA 450 reading, or should an inspector see it labelled "Corrected, also flagged trivial"? Real-world case: management posted the entry but the auditor noted it was below the trivial threshold anyway.

2. **ISA 540 risk levels.** Our enum is `low / medium / high / significant`. Is "significant" (ISA 540.18) the right top-tier name, or do inspectors look for the term "significant estimate"? Should we relabel?

3. **ISA 505.12 alternative-procedures threshold.** We hard-gate UI save when `result` is `exception` or `no_reply` and alternative_procedures is empty. Is that the right ISA 505 threshold, or should we also include `partial` results in the gate?

4. **ISA 530 sampling method enum.** We offer random / systematic / haphazard / monetary_unit / judgmental / other. Is `judgmental` an accepted ISA term (some texts treat "judgmental" as non-statistical sampling — should we relabel to "non-statistical"?)

5. **ISA 315 attestations.** We require ticking all three of 14(a)/(b)/(c) before approval. Is that reasonable for a small-firm audit (one-employee owner-managed entity where observation/inspection of premises may be functionally identical to inquiry)? Should there be an N/A path?

6. **ISA 230 assembly timing.** Our `archive_engagement` RPC requires the completion memo to be locked. ISA 230.A23 references "60 days" after the auditor's report. Should we add a soft warning if the archive happens > 60 days after `cm.signed_at`?

7. **ISA 510 continuance defensibility.** Is "N/A — continuance engagement" with no additional documentation enough under ISA 510, assuming the prior year was audited by us? Or do inspectors expect at least a one-line note even for continuance?

---

## 6. Verification questions for Copilot (code review)

1. **Migration 20260523120001 backfill.** The `UPDATE` setting ISA 315 attestations to true on existing approved rows — is the migration idempotent? If a partner runs the migration twice (unlikely but possible), no harm should occur. (My read: yes, idempotent — the WHERE clause `status='approved'` is stable across runs.)

2. **Three new tables, three new RLS policy patterns.** `engagement_estimates` and `engagement_confirmations` follow the standard 4-policy pattern (SELECT / INSERT / UPDATE / DELETE). `procedure_sampling` uses a single FOR ALL policy (matches `procedure_responses`). Is the single-policy pattern preferred when org is derived via join? Should the other two be refactored?

3. **`misstatement_risk` enum extensibility.** If we later want to add `negligible` (below low) or `extreme` (above significant), the CHECK constraint needs to be dropped + re-added. Should we have used a separate enum type from the start to make this cheaper?

4. **`procedure_sampling.procedure_id` UNIQUE.** This forces 1:1. If a procedure needs to document TWO different sampling tests (e.g., one for completeness, one for accuracy), the current schema can't represent it. Is the 1:1 assumption right for SME audits, or should it be 1:N?

5. **Soft gate on ISA 505.12.** UI blocks save if exception/no_reply lacks alt_procedures, but the DB allows it. A user who bypasses the UI (direct API call) could create a non-compliant row. Should the DB enforce it via CHECK? Trade-off: a partial draft state would be impossible.

6. **`revise_audit_strategy` carry-forward completeness.** The migration explicitly names every column in the INSERT...VALUES. If a future migration adds a column and forgets to update this RPC, the new column silently NULL-defaults on the next revision. The current pattern is intentional (loud-fail) but easy to miss. Should we add a regression test or schema-snapshot check?

7. **`archive_engagement` and findings/sections.** When archived, the UI hides edit affordances but RLS still allows admin writes to child tables (sections, findings, adjusting_entries, etc.). Is this a defensible v1 stance ("memo lock + UI gating + archive flag is enough for ISA 230") or should we add a `WHERE NOT engagements.is_archived` clause to every child-table UPDATE policy?

---

## 7. Closure checklist

- [ ] Perplexity questions 1-7 answered → resolutions captured here.
- [ ] Copilot questions 1-7 answered → resolutions captured here.
- [ ] `docs/COVERAGE-REPORT.txt` updated — 7 new modules added, KNOWN GAPS section updated.
- [ ] All 5 migrations applied to **prod** Supabase (currently staging only).
- [ ] End-to-end demo rehearsal on staging — Task #9 in sprint plan.
- [ ] Pilot lock-in conversation with Qatar partners — 2026-06-01 demo.

When all boxes ticked, status flips to **Closed**.

---

## 8. Source material

- Memory: `feedback-audexon-perplexity-benchmark.md`, `audexon-scope-freeze.md`
- 4-AI synthesis transcripts: `C:\Users\LENOVO\Downloads\audexon_real_coverage_assessment.html` (Claude.ai independent), `C:\Users\LENOVO\Desktop\copilot.txt`, `C:\Users\LENOVO\Desktop\perplexity.txt`, `C:\Users\LENOVO\Downloads\cplt feedback.html`, `C:\Users\LENOVO\Downloads\perp feedback.html` (Claude.ai meta)
- Parked specs revived: `sprint-3-audit-planning-PARKED.md` (renamed RESUMED), `sprint-3-understanding-entity-go-no-go.md`
- Pre-existing report: `docs/COVERAGE-REPORT.txt` (pre-Sprint-4 inventory — to be updated)
