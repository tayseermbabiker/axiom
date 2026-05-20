# Sprint 3 — Audit Strategy / Overall Plan (Verification Spec)

**Status:** SPEC — awaiting Perplexity + Copilot answers, then build.
**Branch:** `staging` on `tayseermbabiker/axiom`
**Effort estimate:** ~0.5d

---

## 1. Partner gap addressed

Qatar partner gap list (2026-05-19): planning is the partner-facing phase, and nothing in v0.5 captured the partner's *overall audit strategy* — the high-level approach, scope, timing, and resourcing decisions an inspector expects to see signed off at the front of the file. CaseWare and MKInsight both have a dedicated planning narrative workpaper; ours did not.

**ISA standards mapped:**
- **ISA 300 — Planning an Audit of Financial Statements** (primary)
- **ISA 300.7-8** — overall audit strategy: scope, timing, direction
- **ISA 300.9** — what the strategy must address (characteristics of the engagement, reporting objectives, factors significant in directing the team, results of preliminary engagement activities, nature/timing/extent of resources)
- **ISA 300.12** — documentation of strategy + any significant changes during the engagement
- **ISA 220 (Revised)** — partner-level direction of the engagement (links to Independence + Acceptance workpapers already shipped)

---

## 2. UI inventory

**Entry point:** Planning phase → new module tab **"Audit Strategy"** in `public/pages/engagement.html`. **Placement:** position 5 — between Independence and Materiality. Reflects the natural ISA workflow: acceptance → engagement letter → independence (engagement-level decisions) → audit strategy (planning of the audit) → materiality (one of the inputs to strategy). Original spec said "first" — moved on reconsideration during build (the umbrella argument is real but partners reading the tabs left-to-right shouldn't be asked to plan the audit before they've accepted the client).

**Page:** in-place tab on engagement.html (same pattern as Materiality, Independence, Acceptance, Engagement Letter). No separate page.

**Gates (in order):**
1. **Pro-tier blocked** banner if `feature_tier !== 'pro'` (consistent with other Planning workpapers shipped in Sprint 2)
2. **Read-only** for non-admin roles; INSERT/UPDATE gated to admin

**Tab content — single card with two sections:**

**Section A — Engagement Strategy (ISA 300.9 directed prompts):**
Free-text textareas, each labeled with the ISA 300.9 sub-bullet it addresses:
- **Characteristics defining scope** — reporting framework, industry-specific reporting requirements, locations of components, group audit relationships
- **Reporting objectives + timing** — deadline for the audit report, key communications with management/TCWG, interim vs final fieldwork dates
- **Significant factors directing the team** — preliminary materiality (read from the Materiality tab — display-only, not re-entered), preliminary risk areas, evidence of prior misstatements, results of prior audit
- **Results of preliminary engagement activities** — independence conclusion (link to Independence tab), client acceptance/continuance conclusion (link to Acceptance tab), engagement letter status (link to Engagement Letter tab)
- **Nature, timing, extent of resources** — team composition with roles, specialist involvement (IT, valuation, tax), EQR requirement (yes/no + name if yes), budgeted hours

**Section B — Partner direction (ISA 220 Revised) — added per Perplexity Q3:**
- **`partner_direction_plan`** narrative textarea — describes nature/timing/extent of direction, supervision, and review of engagement team members' work. Inspectors expect explicit partner-direction evidence; not safe to leave implicit in `significant_factors`.

**Section C — Strategy Approval:**
- **isa_300_strategy_documented** attestation
- **isa_300_resources_assessed** attestation
- **isa_300_team_briefed** attestation
- **isa_220_direction_supervision_planned** attestation (added per Perplexity Q3)
- **Partner sign-off** — Approve button (admin role) → calls `approve_audit_strategy` RPC, stamps `approved_by`, `approved_at`. Versioning: approval locks the active row; a subsequent "Revise Strategy" creates a new draft and supersedes (mirrors Engagement Letter pattern).

**Header row when an approved version exists:**
- Status badge: "Approved" (green) / "Draft" (gray) / "Superseded" (muted) — only active version shown by default; "View history" link reveals superseded rows read-only
- "Revise Strategy" button (admin + Pro, only when active is approved) — calls `revise_audit_strategy` RPC, creates new draft pre-filled from prior version

**Empty state** (no row yet): "No audit strategy documented yet" card with "Start Strategy" button → creates the initial draft row.

---

## 3. Data model

### `public.engagement_audit_strategies`

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | gen_random_uuid() |
| `engagement_id` | uuid FK | ON DELETE CASCADE |
| `organization_id` | uuid FK | ON DELETE CASCADE |
| `version_label` | text | nullable |
| `is_superseded` | boolean | default false |
| `superseded_at` | timestamptz | nullable |
| `superseded_by` | uuid FK profiles | nullable |
| `status` | text | CHECK IN ('draft','approved') |
| **Strategy narrative (ISA 300.9):** | | |
| `scope_characteristics` | text | A1 |
| `reporting_objectives` | text | A2 |
| `significant_factors` | text | A3 |
| `preliminary_activities_summary` | text | A4 |
| `resources_plan` | text | A5 |
| `partner_direction_plan` | text | ISA 220 (R) — added per Perplexity Q3 |
| **Team / specialists:** | | |
| `team_composition` | text | free-form list |
| `specialists_involved` | text | free-form list |
| `eqr_required` | boolean | default false |
| `eqr_reviewer_name` | text | nullable |
| `budgeted_hours` | numeric | nullable |
| **Attestations (ISA 300.12 doc):** | | |
| `isa_300_strategy_documented` | boolean | default false |
| `isa_300_resources_assessed` | boolean | default false |
| `isa_300_team_briefed` | boolean | default false |
| `isa_220_direction_supervision_planned` | boolean | default false — added per Perplexity Q3 |
| **Approval:** | | |
| `approved_by` | uuid FK profiles | nullable |
| `approved_at` | timestamptz | nullable |
| `created_by` | uuid FK profiles | |
| `created_at` | timestamptz | default now() |
| `updated_at` | timestamptz | default now(), DB-managed trigger |

**Partial unique index:** `idx_eas_one_active ON engagement_audit_strategies(engagement_id) WHERE is_superseded = false`

**CHECK constraint:** `status='approved'` requires all four attestations true (3 × ISA 300 + 1 × ISA 220 direction) + approved_by + approved_at NOT NULL.

### RLS (identical pattern to engagement_letters)
- SELECT — any org member
- INSERT/UPDATE — admin role AND Pro tier
- GRANT SELECT, INSERT, UPDATE TO authenticated

### Trigger
- `trg_eas_set_updated_at` BEFORE UPDATE → `set_updated_at_now()`

### RPC: `revise_audit_strategy(p_engagement_id uuid, p_organization_id uuid) RETURNS uuid`
SECURITY DEFINER. Membership + admin + Pro checks inline (raise on fail). Supersedes the active row, inserts a new draft carrying ALL narrative + team fields but resetting attestations + approval. Returns new row id.

### RPC: `approve_audit_strategy(p_strategy_id uuid) RETURNS void`
SECURITY DEFINER. Membership + admin + Pro check via the row's organization_id. Atomic UPDATE: sets `status='approved'`, `approved_by=auth.uid()`, `approved_at=now()`. CHECK constraint enforces attestations were filled.

---

## 4. Permissions & workflow

| Action | Role | Tier |
|---|---|---|
| See "Audit Strategy" tab | any member | any |
| View strategy content | any member | any |
| Start initial draft | admin | Pro |
| Edit draft fields | admin | Pro |
| Approve strategy | admin | Pro |
| Revise approved strategy | admin | Pro |
| View superseded versions | any member | any |

State: at most one non-superseded row per engagement. Approval is a one-way action per version — to change after approval, partner must Revise (creates a new draft, supersedes the old).

---

## 5. Out of scope

- Auto-populating strategy fields from prior-year engagement (carry-forward) — would need engagement-to-engagement linkage we don't have yet
- Strategy templates per industry (pharma/construction/etc.)
- Specialist letter/scope tracking as a separate sub-table — free-text only for now
- Direct integration with the Risk Assessment matrix (#3 of this sprint) — strategy is narrative, matrix is structured; they coexist
- EQR workflow itself (just the flag + reviewer name; the actual EQR sign-off is a separate item in the Qatar gap list — deferred)
- Budget vs actual hours tracking — `budgeted_hours` recorded only; no actuals comparison

---

## 6. Judgment calls

**J1 — Five narrative textareas (A1-A5) rather than one combined free-text**
Splits ISA 300.9's five sub-bullets into discrete prompts. Risk: more friction than one big box. Reasoning: inspectors checking ISA 300 compliance scan for the five elements explicitly — a single box hides whether each was addressed.

**J2 — Approval is per-version, not amendable**
Once approved, no field-level edits allowed; must Revise to change. Risk: friction if a partner notices a typo post-approval. Mitigation: Revise carries all content forward, so re-approval after a quick fix is one click + re-attest. Consistent with Engagement Letter pattern.

**J3 — Preliminary materiality shown as display-only (read from `engagements.materiality_*`)**
Strategy doesn't re-capture the number. Risk: if materiality is later revised, the strategy narrative may reference a stale figure. Mitigation: live-read from the engagements table at render time; revised materiality auto-updates the strategy view.

**J4 — EQR requirement captured here, not as a separate workpaper**
Strategy is where the decision is made (per ISA 220.20 + ISQM 1). The actual EQR workpaper is a Sprint 4+ item per the Qatar gap list. Risk: partner sets eqr_required=true here but no downstream artifact enforces it. Accepted — Sprint 3 doesn't promise EQR workflow.

**J5 — `budgeted_hours` is a single number, not a per-section breakdown**
Per-section budget would mean another child table. Reasoning: 0.5d build doesn't justify it. Partners can write the breakdown into `resources_plan` free-text if they want.

---

## 7. Blocking verification questions

**For Perplexity:**

1. "Under ISA 300.9, the overall audit strategy must address five specific elements (characteristics defining scope; reporting objectives + timing + communications; significant factors directing the team; results of preliminary engagement activities; nature/timing/extent of resources). Is this list canonically the FIVE elements, or has the IAASB collapsed/expanded the count in the 2024-2025 edition? We're building exactly five narrative fields aligned to these."

2. "ISA 300.12 requires the auditor to document the overall strategy AND significant changes during the engagement. Does 'significant change' have a defined threshold (e.g., scope change, change in materiality, change in significant risks), or is it judgement-based? Our model treats every Revise as a supersede event with a fresh approval — is this overkill, or is it the right inspection trail?"

3. "For ISA 220 (Revised) partner-level engagement direction, does the engagement strategy itself satisfy the partner-direction documentation requirement, or is a separate 'partner direction' workpaper expected by network methodologies (BDO/RSM/Crowe/Mazars)? We're folding it into the strategy attestations."

**For Copilot:**

4. **`engagement_audit_strategies` CHECK constraint** — `status='approved'` requires three attestations + approved_by + approved_at. Confirm the CHECK fires *after* the UPDATE in `approve_audit_strategy` (i.e., the attestations the user ticked in the same form submission are visible to the constraint). Risk: if the client posts attestations + approval in one round-trip, ordering matters.

5. **`revise_audit_strategy`** — the RPC carries every narrative + team field through to the new draft. Confirm there's no missed column (especially newly-added ones during build) that would silently default to NULL/false on revision. Suggest a pattern (e.g., explicit SELECT * INTO + INSERT named-column list) that minimises drift risk.

6. **Pro-tier check at three layers** (client UI banner, RLS WITH CHECK, RPC inline raise) — confirm this matches the Engagement Letter pattern exactly so partner-facing behavior is consistent. Flag any inconsistency.

---

## 8. Closure checklist

- [ ] Perplexity Q1-Q3 answered (or deferred with explicit reasoning)
- [ ] Copilot Q4-Q6 addressed
- [ ] Migration `20260521120000_engagement_audit_strategy.sql` applied to staging
- [ ] UI: tab appears as first Planning module on engagement.html, Pro-tier banner correct
- [ ] Smoke test: start draft → fill all fields → approve → verify CHECK enforces attestations
- [ ] Smoke test: revise approved strategy → confirm new draft pre-fills, prior row is_superseded=true
- [ ] Smoke test: non-admin sees read-only, Essentials org sees upgrade banner
- [ ] Smoke test: preliminary materiality on strategy view updates when materiality tab is changed
- [ ] User signs off

When all nine ticked, **CLOSED**.
