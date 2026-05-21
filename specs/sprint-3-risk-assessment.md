# Sprint 3 #3 — Risk Assessment Matrix (Verification Spec)

**Status:** SPEC — verification complete 2026-05-21 (Perplexity + Copilot). Building per spec + 3 verification fixes (see § 9).
**Branch:** `staging` on `tayseermbabiker/axiom`
**Effort estimate:** ~2-3d (largest piece of Sprint 3)

---

## 1. Partner gap addressed

Qatar partner gap list (2026-05-19): **the headline item**. Audexon v0.5 has no explicit risk register — risks are implicit in the procedures within each section. ISA 315.32 requires documented risk identification + assessment at both financial statement and assertion level, with the basis for the assessment. ISA 330.6 requires the auditor's responses (overall + specific procedures) to be linked back to the assessed risks. CaseWare and MKInsight both have a structured risk matrix that drives the procedure design — without one, network inspectors immediately flag the file.

Partner verbatim from the demo memo: *"How do you know your procedures are responsive to risk if you don't have a risk register?"*

**ISA standards mapped:**
- **ISA 315 (Revised 2019)** — identifying and assessing risks of material misstatement
  - 315.27 — risks at assertion level per significant CoTABD
  - 315.28 — significant risks identification
  - 315.32 — documentation of risks + basis for assessment
- **ISA 330** — auditor's responses to assessed risks
  - 330.5 — overall responses
  - 330.6-7 — risk-specific procedures
  - 330.21 — significant risk procedures
- **ISA 240** — fraud risk integration (presumed risks: revenue + management override)

---

## 2. UI inventory

**Entry point:** Planning phase → new module tab **"Risk assessment"** at position 7 (after Materiality). Order: Overview → Acceptance → Engagement letter → Independence → Audit strategy → Materiality → **Risk assessment**.

**Page:** in-place tab on engagement.html.

**Gates:**
1. Pro-tier blocked banner if `feature_tier !== 'pro'`
2. Read-only for non-admin; INSERT/UPDATE/DELETE gated to admin
3. Empty state with helper text + "Add first risk" button

**Layout — single card, three regions:**

### Region 1 — Header summary
- Counters: total risks · significant risks · risks without linked procedures (red badge if >0)
- "Confirm risk assessment complete" button (admin) → calls `confirm_risk_assessment` RPC → stamps engagement-level attestation + timestamp
- Status badge: "Draft" / "Confirmed" / "Confirmed · [date]"
- "Revise" button (when confirmed) → unstamps the attestation (no row-level supersede needed; risks themselves persist)

### Region 2 — Risk register (the matrix)
Table grouped by audit section. Columns:
- Section (group header, collapsible)
- Assertion (chip — existence / completeness / accuracy / valuation / cutoff / classification / rights & obligations / presentation)
- Risk description (truncated, click to expand)
- Source (chip — entity / industry / IT / fraud / RAP / management override / other)
- Inherent (chip — low / medium / high — color-coded)
- Control (chip — low / medium / high)
- Combined (auto-calculated chip)
- Significant? (icon, golden star if yes)
- Linked procedures (count badge, click to open linked-procedure manager)
- Actions: Edit · Delete (admin)

Inline "+ Add risk" button at the bottom of each section group + a top-level "+ Add risk to any section" button.

### Region 3 — Add/edit risk modal
- Section (required, dropdown of engagement's audit_sections)
- Assertion (required, single-select)
- Risk description (required textarea, prompt: "What could cause material misstatement?")
- Source (required, single-select)
- Inherent rating (required, low/medium/high)
- Control rating (required, low/medium/high)
- Combined rating (auto-calculated; partner can override)
- Significant risk flag (checkbox; when ticked: reveals "Why significant?" textarea — required per ISA 315.A115)
- **ISA 240 presumed-fraud-risk flags:** for the Revenue section, default `is_significant=true` + source='fraud' + locked banner (revenue recognition is a presumed risk per ISA 240.26); for any section, allow the partner to mark "management override of controls" as a separate row (ISA 240.31, mandatory significant risk)
- Overall response (required textarea — ISA 330.5: more experienced staff, increased supervision, professional skepticism, unpredictability)
- Linked procedures (multi-select; show only procedures from the SAME section; allow inline "+ Create new procedure" that opens the section's procedure editor)
- Save / Cancel

### Region 4 — Pivot view (read-only, collapsed by default)
Toggle: "Show matrix view" → renders a pivot:
- Rows: audit sections
- Columns: 8 assertions
- Cells: count of risks, with significant-risk count in gold
- Purely visual for inspector demos; not editable.

---

## 3. Data model

### `public.engagement_risks` (parent)

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | gen_random_uuid() |
| `engagement_id` | uuid FK | ON DELETE CASCADE |
| `organization_id` | uuid FK | ON DELETE CASCADE |
| `section_id` | uuid FK audit_sections | ON DELETE CASCADE |
| `assertion` | text | CHECK IN ('existence','completeness','accuracy','valuation','cutoff','classification','rights_obligations','presentation') |
| `risk_description` | text NOT NULL | |
| `source` | text NOT NULL | CHECK IN ('entity','industry','it','fraud','management_override','rap','other') |
| `inherent_rating` | text NOT NULL | CHECK IN ('low','medium','high') |
| `control_rating` | text NOT NULL | CHECK IN ('low','medium','high') |
| `combined_rating` | text NOT NULL | CHECK IN ('low','medium','high') — defaults to higher of inherent/control, overridable |
| `is_significant` | boolean NOT NULL DEFAULT false | |
| `significant_rationale` | text | CHECK: if `is_significant` then NOT NULL |
| `overall_response` | text NOT NULL | ISA 330.5 |
| `is_locked_presumed` | boolean NOT NULL DEFAULT false | true for revenue + mgmt override; UI blocks unticking `is_significant` |
| `created_by` | uuid FK profiles | |
| `created_at` | timestamptz | default now() |
| `updated_at` | timestamptz | default now(), DB-managed trigger |

### `public.engagement_risk_procedure_links` (junction)

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | |
| `risk_id` | uuid FK engagement_risks | ON DELETE CASCADE |
| `procedure_id` | uuid FK audit_procedures | ON DELETE CASCADE |
| `notes` | text | optional |
| `created_at` | timestamptz | default now() |

UNIQUE on `(risk_id, procedure_id)`.

### `public.engagement_risk_assessment` (engagement-level summary + attestation)

| Column | Type | Notes |
|---|---|---|
| `engagement_id` | uuid PK FK | — one row per engagement |
| `organization_id` | uuid FK | |
| `status` | text | CHECK IN ('draft','confirmed'), default 'draft' |
| `isa_315_27_assertions_assessed` | boolean | default false |
| `isa_315_28_significant_risks_identified` | boolean | default false |
| `isa_330_responses_linked` | boolean | default false |
| `confirmed_by` | uuid FK profiles | nullable |
| `confirmed_at` | timestamptz | nullable |
| `created_at` | timestamptz | default now() |
| `updated_at` | timestamptz | default now(), DB-managed trigger |

CHECK: `status='confirmed'` requires all 3 attestations + confirmed_by + confirmed_at NOT NULL.

Auto-created on first risk insert via trigger (so the row exists when the partner is ready to confirm).

### RLS

Identical pattern to engagement_audit_strategies:
- SELECT — any org member
- INSERT/UPDATE/DELETE — admin AND Pro tier (on all three tables)
- GRANT SELECT, INSERT, UPDATE, DELETE TO authenticated

### Triggers

- `trg_er_set_updated_at` — engagement_risks BEFORE UPDATE → set_updated_at_now()
- `trg_era_set_updated_at` — engagement_risk_assessment BEFORE UPDATE
- `trg_er_seed_presumed_risks` — engagement_risks AFTER INSERT first risk → auto-INSERT engagement_risk_assessment row if missing

### RPC: `confirm_risk_assessment(p_engagement_id uuid) RETURNS void`

SECURITY DEFINER. Membership + admin + Pro inline. Validates:
- At least one risk exists for the engagement
- Every `is_significant=true` risk has at least one linked procedure (ISA 330.21)
- Every risk has at least one linked procedure (ISA 330.7) OR raise warning (?) — TBD per Perplexity Q3

Then UPDATE engagement_risk_assessment SET status='confirmed' + confirmed_by/at + the three attestations to true (assumes UI form has set them — CHECK enforces).

### RPC: `unconfirm_risk_assessment(p_engagement_id uuid) RETURNS void`

SECURITY DEFINER. Reverses confirmation so partner can edit risks post-confirmation. No supersede — risks themselves persist; only the attestation toggles.

### RPC: `seed_presumed_fraud_risks(p_engagement_id uuid) RETURNS void`

SECURITY DEFINER. Per ISA 240.26 + 240.31:
- For the Revenue section (if exists in engagement): INSERT a `is_locked_presumed=true` risk (Revenue Recognition, source=fraud, is_significant=true, inherent=high, default response narrative)
- For ANY section: INSERT a single Management Override risk (source=management_override, is_significant=true, locked)

Called from dashboard.html when a new engagement is created (alongside `seedSectionsForEngagement`).

---

## 4. Permissions & workflow

| Action | Role | Tier |
|---|---|---|
| View risk register | any member | any |
| View matrix pivot | any member | any |
| Add / edit / delete risks | admin | Pro |
| Link / unlink procedures | admin | Pro |
| Confirm risk assessment | admin | Pro |
| Unconfirm to edit | admin | Pro |

State: risks are NOT versioned (no supersede pattern). The engagement-level attestation toggles draft ↔ confirmed.

---

## 5. Out of scope

- Per-CoTABD significant-risk register beyond what audit_sections provides
- Risk auto-detection from TB anomalies — Sprint 4+ (would require the ML layer)
- Going Concern risk integration — narrative already in the Going Concern section template (Sprint 1)
- Inherent risk "spectrum thinking" beyond 3-tier low/medium/high — ISA 315 R 2019 introduced spectrum but most small firms still operate on 3-tier
- Carry-forward of prior-year risk assessment — same no-permanent-file constraint
- Risk taxonomy / library / starter risks per industry — partner authors per engagement
- Walkthrough documentation linkage
- Control reliance testing (ISA 330.8) — if control_rating < high we assume substantive approach; partner can document otherwise in overall_response
- Per-assertion materiality (component materiality) — single overall materiality only
- Risk-to-finding traceability — findings table already has section_id; an inspector can cross-reference manually

---

## 6. Judgment calls

**J1 — Single assertion per risk row, not multi**
Some risks span multiple assertions (e.g., fraudulent revenue recognition affects existence + cutoff + accuracy). Could allow `assertion text[]`. Chose single for v1 because the matrix pivot view is cleaner. Partners can add multiple rows if a risk genuinely affects multiple assertions. Risk: more rows in the register. Acceptable.

**J2 — Combined rating auto-calculated as max(inherent, control), overridable**
Simpler than a full 9-cell matrix lookup. Inherent=high + Control=low → combined=high (more conservative). Partner can override if their professional judgement differs. Risk: simplistic. Mitigation: override field captures the partner's actual call.

**J3 — Pro-gated entirely**
Risk Assessment is core ISA, not a "Pro" feature in the canonical sense. But: (a) network inspectors are who demand the structured risk register, (b) Essentials users get the implicit risk model via sections + procedures (which is what most small-firm partners actually do today). Gating risk assessment to Pro keeps the tier story clean. Risk: ISA-purist may complain. Reasoning: partners doing inspection-level audits ARE the Pro target.

**J4 — Auto-seed ISA 240 presumed risks (revenue + management override)**
ISA 240.26 + 240.31 make these MANDATORY significant risks. Auto-seeding them on engagement creation enforces compliance + saves the partner from re-typing them every engagement. Locked so partner can't accidentally untick `is_significant`. Risk: assumes every engagement has a Revenue section (most do; the template includes it). Mitigation: if no Revenue section exists, skip the Revenue presumed risk silently.

**J5 — Engagement-level attestation row instead of per-risk versioning**
Risks evolve continuously during the engagement; versioning each risk would create noise. The engagement-level attestation toggles draft↔confirmed for the whole register. Risk: changing a confirmed risk doesn't carry an audit trail of the prior state. Mitigation: activity_log captures every risk INSERT / UPDATE / DELETE with timestamps + user (existing infrastructure).

**J6 — Procedure linking limited to procedures in the SAME section as the risk**
A risk on Revenue can only link to Revenue procedures. Could allow cross-section linking (rare but valid for pervasive risks). Chose intra-section for v1 because (a) it's the common case, (b) cross-section UI is more complex. Pervasive risks can be expressed as multiple risks across sections.

**J7 — Pivot view is read-only, not the editing surface**
True matrix UX (sections × assertions grid, click cell to edit) is the conventional CaseWare paradigm. Chose table-with-pivot-toggle because the matrix grid is mostly empty cells (sparse) and editing inline inside a tiny cell is bad UX. Risk: doesn't *look* like a matrix at a glance. Mitigation: the pivot view IS the matrix; the editor is the table.

**J8 — `confirm_risk_assessment` requires every significant risk to have ≥1 linked procedure**
ISA 330.21: special procedures must be performed for significant risks. Hard-blocking confirmation forces the linkage. Risk: partner annoyance if they forgot to link. Acceptable — the error message points them to the unlinked risks list.

---

## 7. Blocking verification questions

**For Perplexity:**

1. "Under ISA 315 (Revised 2019), is a risk register required to identify EVERY assertion-level risk for EVERY significant CoTABD, or only those risks that are 'reasonably possible' to result in material misstatement? Our model lets partners add risks freely but doesn't force a per-section, per-assertion exhaustive matrix. Is that a documentation gap, or is it consistent with the 'professional judgement' framing in ISA 315.A114?"

2. "ISA 240.26 establishes a presumed (rebuttable) significant risk of fraud in revenue recognition. ISA 240.31 establishes a non-rebuttable significant risk for management override. For a small-firm audit on a non-revenue-recognition-fraud-risk client (e.g., a cash-based service business with simple invoicing), is the auditor required to rebut the ISA 240.26 presumption in writing, or can they simply mark the risk as 'low inherent' without explicit rebuttal documentation? Our model auto-creates these as significant + locked — flag whether the rebuttal mechanism is missing."

3. "ISA 330.7 says responsive procedures should be performed for EVERY assessed risk; ISA 330.21 says special procedures for SIGNIFICANT risks. Is it acceptable under ISA for a risk assessed as 'low combined' to have ONLY analytical procedures with no test of detail, or does ISA 330 require at least one test of detail per assessed risk regardless of rating? We're considering hard-blocking risk-assessment confirmation if any significant risk has zero linked procedures — flag whether we should also block on low-risk no-procedure cases."

4. "For 'inherent risk spectrum thinking' introduced in ISA 315 R 2019 (vs. the traditional 3-tier low/medium/high), is a 3-tier rating still ISA-compliant in 2024-2025, or do inspectors now expect a 5-point or richer scale? Our v1 uses 3-tier — flag if this is already obsolete vs. the standard's intent."

**For Copilot:**

5. **Schema choice — junction table vs `linked_procedure_ids uuid[]`** — for many-to-many risk-procedure linkage, we chose a junction table (`engagement_risk_procedure_links`). Confirm this is the right call for: (a) inspection PDF queries (probably needs a JOIN-friendly structure), (b) per-procedure-deletion cascade behavior, (c) reporting queries that need 'unlinked risks' detection. Suggest if `text[]`/`uuid[]` would be materially simpler given the access patterns we've described.

6. **`confirm_risk_assessment` validation logic** — the RPC validates "every significant risk has ≥1 linked procedure" before allowing confirmation. Confirm the validation should happen at: (a) the RPC layer (current design), (b) a deferred CHECK constraint, (c) both. Flag if there's a race condition where a partner could DELETE a procedure (which CASCADEs to the junction row) and orphan a significant risk's linkage after confirmation.

7. **Trigger ordering — `trg_er_seed_presumed_risks`** — the trigger fires AFTER INSERT on `engagement_risks` to auto-create the parent `engagement_risk_assessment` row if missing. Alternative: pre-INSERT a stub row when an engagement is created (via `seedSectionsForEngagement` extension). Which is more robust given Supabase's trigger behavior + the no-engagement-created-without-sections invariant? Flag any pitfall.

---

## 8. Closure checklist

- [ ] Perplexity Q1-Q4 answered (or deferred with reasoning)
- [ ] Copilot Q5-Q7 addressed
- [ ] Migration `20260522120000_engagement_risk_assessment.sql` applied to staging
- [ ] UI: Risk assessment tab at planning position 7, Pro-tier gating correct
- [ ] Smoke test: new engagement → presumed fraud risks auto-seeded (revenue + mgmt override), both locked + significant
- [ ] Smoke test: add 3 non-presumed risks → link each to a procedure → confirm assessment → CHECK enforces attestations
- [ ] Smoke test: try to confirm with an unlinked significant risk → blocked with clear error pointing to the risk
- [ ] Smoke test: pivot view renders sparse grid with significant-risk counts in gold
- [ ] Smoke test: non-admin sees read-only register, Essentials org sees Pro banner
- [ ] User signs off

When all ten ticked, **CLOSED**.

---

## 9. Verification fixes (2026-05-21)

Three changes from the post-verification synthesis (see `Desktop\perplexity.txt` + `copilot.txt`):

### Fix 1 — ISA 240.26 rebuttal workflow (Perplexity Q2)

A bare "low inherent" on the locked Revenue Recognition risk = documentation gap. ISA 240.26 presumption must be EXPLICITLY rebutted with rationale + admin approval. Management override stays non-rebuttable per ISA 240.31.

**Schema additions on `engagement_risks`:**

| Column | Type | Notes |
|---|---|---|
| `presumption_rebutted` | boolean | default false |
| `rebuttal_rationale` | text | required if presumption_rebutted=true |
| `rebuttal_approved_by` | uuid FK profiles | required if presumption_rebutted=true |
| `rebuttal_approved_at` | timestamptz | required if presumption_rebutted=true |

**CHECK constraints:**
- If `presumption_rebutted=true` then rebuttal_rationale + rebuttal_approved_by + rebuttal_approved_at NOT NULL
- If `source='management_override'` then `presumption_rebutted=false` (non-rebuttable)

**UI:** "Rebut presumption" button on the locked Revenue risk (source='fraud' + is_locked_presumed=true). Opens modal: rationale (required) → admin approval click → unticks `is_significant` + stamps approver/timestamp. Management override risk does NOT show a Rebut button.

### Fix 2 — Stand-back attestation (Perplexity Q1)

Add a 4th attestation to `engagement_risk_assessment`: `isa_315_stand_back_completed`. Confirmation modal lists sections without significant risks: *"Confirm you considered whether any of these warrant significant-risk treatment per ISA 315 'stand back'."*

Updated CHECK on `engagement_risk_assessment`: `status='confirmed'` now requires all 4 attestations (3 original + stand_back) + confirmed_by + confirmed_at.

### Fix 3 — Architecture: pre-seed assessment row + race fix (Copilot Q6 + Q7)

**Drop the AFTER INSERT trigger on `engagement_risks`** (was: auto-create assessment row on first risk insert). Instead, pre-seed `engagement_risk_assessment` row when the engagement itself is created — added to `public/pages/dashboard.html` engagement creation flow, alongside `seedSectionsForEngagement`. Reasoning: simpler invariant ("every engagement has an assessment row from day 1"), avoids RLS/trigger interaction edge cases.

**Add BEFORE DELETE trigger on `engagement_risk_procedure_links`** that blocks deletion when the assessment is confirmed AND the risk is significant. Prevents the orphan race where a partner deletes a procedure post-confirmation, CASCADE wipes the junction row, and a significant risk silently loses its required ISA 330.21 linkage.

```sql
CREATE OR REPLACE FUNCTION public.prevent_orphaned_significant_risks()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  v_eng_id uuid;
  v_significant boolean;
  v_confirmed boolean;
BEGIN
  SELECT r.engagement_id, r.is_significant
    INTO v_eng_id, v_significant
    FROM public.engagement_risks r
   WHERE r.id = OLD.risk_id;
  IF NOT v_significant THEN RETURN OLD; END IF;
  SELECT (status='confirmed') INTO v_confirmed
    FROM public.engagement_risk_assessment
   WHERE engagement_id = v_eng_id;
  IF v_confirmed THEN
    RAISE EXCEPTION 'Cannot delete procedure link: risk assessment is confirmed and this is a significant risk. Unconfirm first.';
  END IF;
  RETURN OLD;
END;
$$;
```

### Soft warning for non-significant unlinked risks (Perplexity Q3)

Don't hard-block, but the UI confirmation modal lists *all* risks with zero linked procedures (significant + non-significant). Hard error only when a significant risk has none; warning + "Confirm anyway" for non-significant unlinked risks.

