# Sprint 3 — Understanding the Entity & Its Environment (Verification Spec)

**Status:** SPEC — awaiting Perplexity + Copilot answers, then build.
**Branch:** `staging` on `tayseermbabiker/axiom`
**Effort estimate:** ~1-2d

---

## 1. Partner gap addressed

Qatar partner gap list (2026-05-19): item #2 in Sprint 3 ordering. Audexon v0.5 had no place to document the auditor's understanding of the entity, its industry, regulatory environment, or internal control. CaseWare and MKInsight both have a dedicated "Understanding the Entity" workpaper at the front of the planning file. Inspectors look for this workpaper specifically because ISA 315 (Revised 2019) is the foundation of the entire risk-based audit — no understanding → no risk identification → no targeted procedures.

This workpaper is what the Risk Assessment matrix (Sprint 3 #3) will reference. If understanding is thin, the matrix will be guesses.

**ISA standards mapped:**
- **ISA 315 (Revised 2019) — Identifying and Assessing the Risks of Material Misstatement** (primary)
- **ISA 315.19-27** — understanding the entity and its environment, the applicable financial reporting framework, and the entity's system of internal control
- **ISA 315.21-23** — industry, regulatory, and other external factors
- **ISA 315.25-27** — five components of internal control + IT environment + IT general controls (new emphasis in 2019 revision)
- **ISA 315.A89-A111** — inherent risk factors and "spectrum thinking" introduced in the 2019 revision

---

## 2. UI inventory

**Entry point:** Planning phase → new module tab **"Understanding the entity"**. **Placement decision (open):** logically belongs at position 5 (between Independence and Audit Strategy) because understanding drives strategy. This means moving Audit Strategy from position 5 → 6 and Materiality from 6 → 7. See §6 J1.

**Page:** in-place tab on engagement.html (same pattern as Audit Strategy).

**Gates:**
1. Pro-tier blocked banner if `feature_tier !== 'pro'`
2. Read-only for non-admin; INSERT/UPDATE gated to admin
3. Empty state with "Start understanding" button → creates initial draft row

**Sections (single card, eight prompt blocks):**

**A. Entity overview**
- Nature of business (textarea)
- Ownership structure (textarea)
- Governance (TCWG composition, audit committee status, key personnel) (textarea)
- Locations / components in scope (textarea)

**B. Industry, regulatory, and external environment** (ISA 315.21-23)
- Industry overview + competitive position (textarea)
- Regulatory environment — sector-specific regulators, licenses, recent reform (textarea)
- External pressures — economic conditions, FX exposure, supply chain, technology disruption (textarea)

**C. Applicable financial reporting framework**
- Framework (free text — IFRS, IFRS for SMEs, local GAAP) — display-only link to engagement letter's `reporting_framework` if set; partner can over-state here with deeper notes
- Significant accounting policies considered (textarea — revenue recognition method, inventory valuation, impairment indicators, etc.)

**D. Five components of internal control** (ISA 315.25 — one textarea per component)
- 1. Control environment
- 2. Entity's risk assessment process
- 3. Information system and communication
- 4. Control activities relevant to the audit
- 5. Monitoring of controls

**E. IT environment** (ISA 315 Revised 2019 — heightened emphasis)
- IT environment overview (single textarea: applications used, hosting, integration)
- IT general controls considered (textarea: change management, access, operations, backup/recovery)
- IT-dependent controls / automated controls reliance plan (textarea)

**F. Material classes of transactions, account balances, disclosures (CoTABDs)**
- Single textarea v1. Lists the CoTABDs that warrant focused understanding — typically maps to the audit sections (revenue, COGS, cash, receivables, etc.). v2 might structure this as a child table linked to `audit_sections`.

**G. Inherent risk factors considered** (ISA 315 Revised 2019 — "spectrum thinking")
- Textarea prompted with the ISA 315.A92 risk factors as helper text: complexity, subjectivity, change, uncertainty, susceptibility to bias or fraud.

**H. Sources used + conclusion**
- Sources textarea (prior-year file, management interviews, walkthroughs, industry reports, regulator filings)
- Conclusion textarea (summary statement: understanding obtained is sufficient as a basis for risk identification and assessment, OR areas where further work is needed)

**Section I — Partner approval:**
- Four attestations + Approve button (same RPC + CHECK pattern as Audit Strategy)
- Revise creates a new draft, supersedes prior

---

## 3. Data model

### `public.engagement_entity_understanding`

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
| **A. Entity overview:** | | |
| `entity_nature` | text | |
| `entity_ownership` | text | |
| `entity_governance` | text | |
| `entity_locations` | text | |
| **B. Industry / regulatory / external:** | | |
| `industry_overview` | text | |
| `regulatory_environment` | text | |
| `external_pressures` | text | |
| **C. Framework + policies:** | | |
| `framework_notes` | text | (partner over-narration on top of EL's framework) |
| `accounting_policies_considered` | text | |
| **D. Five components of internal control:** | | |
| `ic_control_environment` | text | |
| `ic_risk_assessment_process` | text | |
| `ic_information_system` | text | |
| `ic_control_activities` | text | |
| `ic_monitoring` | text | |
| **E. IT environment:** | | |
| `it_environment_overview` | text | |
| `it_general_controls` | text | |
| `it_dependent_controls_plan` | text | |
| **F. CoTABDs:** | | |
| `material_cotabds` | text | |
| **G. Inherent risk factors:** | | |
| `inherent_risk_factors` | text | |
| **H. Sources + conclusion:** | | |
| `sources_used` | text | |
| `conclusion` | text | |
| **Attestations:** | | |
| `isa_315_entity_understood` | boolean | default false |
| `isa_315_internal_control_understood` | boolean | default false |
| `isa_315_it_environment_considered` | boolean | default false |
| `isa_315_inherent_risk_factors_considered` | boolean | default false |
| **Approval:** | | |
| `approved_by` | uuid FK profiles | nullable |
| `approved_at` | timestamptz | nullable |
| `created_by` | uuid FK profiles | |
| `created_at` | timestamptz | default now() |
| `updated_at` | timestamptz | default now(), DB-managed trigger |

**Partial unique index:** `idx_eeu_one_active ON engagement_entity_understanding(engagement_id) WHERE is_superseded = false`

**CHECK constraint:** `status='approved'` requires all 4 attestations true + approved_by + approved_at NOT NULL.

### RLS (identical pattern to engagement_audit_strategies)
- SELECT — any org member
- INSERT/UPDATE — admin AND Pro
- GRANT SELECT, INSERT, UPDATE TO authenticated

### Trigger
- `trg_eeu_set_updated_at` BEFORE UPDATE → `set_updated_at_now()`

### RPC: `approve_engagement_understanding(p_understanding_id uuid) RETURNS void`
SECURITY DEFINER. Membership + admin + Pro inline checks. Single UPDATE: status='approved' + approved_by + approved_at. CHECK enforces attestations.

### RPC: `revise_engagement_understanding(p_engagement_id, p_organization_id) RETURNS uuid`
SECURITY DEFINER. Same gating. `SELECT * INTO v_old` + explicit-named-column INSERT carrying all narrative forward; resets attestations + approval (per Copilot Q5 pattern, proven in #1).

---

## 4. Permissions & workflow

| Action | Role | Tier |
|---|---|---|
| See "Understanding the entity" tab | any member | any |
| View content | any member | any |
| Start initial draft | admin | Pro |
| Edit draft fields | admin | Pro |
| Approve | admin | Pro |
| Revise approved | admin | Pro |
| View superseded | any member | any |

State: one active row per engagement. Approval is per-version (Audit Strategy pattern).

---

## 5. Out of scope

- Carry-forward from prior-year engagement (no engagement-to-engagement linkage yet)
- Industry templates / starter content (pharma / construction / financial services) — partner authors from scratch in v1
- Structured CoTABDs child table linked to `audit_sections` — single textarea in v1; structure in Sprint 4 if partners ask
- Walkthrough documentation (separate ISA 315 application material) — referenced in narrative only
- Risk identification itself — happens on the Risk Assessment matrix (Sprint 3 #3); this workpaper is the *input* to that
- IT general controls testing workpaper — narrative only here, testing belongs in execution
- Auto-suggestion of inherent risk factors from TB anomalies — Sprint 4+ if at all
- Linkage to a "significant risks" register — risks register is the matrix (Sprint 3 #3)

---

## 6. Judgment calls

**J1 — Tab placement: position 5 (move Audit Strategy to 6, Materiality to 7)**
Understanding drives strategy per ISA 315 → ISA 300 sequence. The Audit Strategy tab I just shipped sits at position 5 — moving it back one slot keeps the workflow read order correct. Risk: if partners have already opened a staging engagement, the tab order changes underneath them. Acceptable on staging.

**J2 — Eight narrative blocks (A-H), no structured sub-tables**
Could have made the five IC components a child table, CoTABDs a child table, IT controls a structured list. Chose flat narrative for v1 to keep build inside 1-2d and stay consistent with Audit Strategy's all-textarea approach. Risk: less inspector-friendly than CaseWare's structured forms. Mitigation: explicit prompts under each textarea label give partners the "checklist" feeling without the schema cost.

**J3 — Framework duplicated (engagement letter + here)**
EL has `reporting_framework` (the line in the signed letter). This workpaper has `framework_notes` (the partner's deeper narrative on how the framework applies). Risk: drift between the two. Reasoning: they serve different purposes — EL is the legal document, this is the audit working paper. Accepted.

**J4 — Inherent risk factors as a single prompted textarea, not a structured tagger**
ISA 315.A92 lists ~7 inherent risk factors (complexity, subjectivity, change, uncertainty, susceptibility to bias, susceptibility to fraud, ...). Could have done tags + per-factor narrative. Chose single textarea with helper text. Risk: shallower than per-factor capture. Reasoning: Sprint 3 #3 (Risk Assessment matrix) will be where per-assertion inherent risk is structured; here it's the engagement-level narrative input.

**J5 — IT environment as 3 textareas, not a structured controls register**
ISA 315 R 2019 puts heavy emphasis on IT general controls (ITGCs). A full ITGC register (per application × control area) is more inspection-friendly. Choosing narrative for v1 because most small-firm audits don't rely on automated controls at all — partner usually concludes "no reliance on ITGCs, substantive approach throughout." Forcing a full ITGC register for those engagements is bureaucracy. If a partner audits a SaaS / fintech client they can write a richer narrative; v2 can add structure.

**J6 — `material_cotabds` as plain textarea, not linked to `audit_sections` table**
audit_sections already exists as the section list per engagement. Could have either (a) made this a multi-select of sections or (b) added a `is_material` flag on audit_sections. Chose narrative for v1 to avoid coupling. Risk: drift between what's documented as material here vs which sections actually exist in the engagement. Mitigation: the textarea prompt names the typical sections (revenue, COGS, cash, receivables, ...) to keep partners pointed at the audit section list.

---

## 7. Blocking verification questions

**For Perplexity:**

1. "Under ISA 315 (Revised 2019), is the 'understanding of the entity' a documentation requirement at the OVERALL engagement level (one workpaper) or per significant CoTABD (one per balance/transaction class)? Our model is one engagement-level workpaper with a CoTABDs section inside — confirm this satisfies ISA 315.32 documentation rules, or call out where granular per-CoTABD documentation is expected."

2. "ISA 315 R 2019 introduced the 'spectrum of inherent risk' concept and explicit emphasis on inherent risk factors (complexity, subjectivity, change, uncertainty, susceptibility to bias, susceptibility to fraud). For a SMALL-firm audit (e.g., a private SME with simple operations), is the auditor required to document each inherent risk factor explicitly, or is a high-level narrative concluding 'inherent risk is low across the engagement; no significant risks identified' acceptable? Our v1 has a single narrative textarea — flag if that's a documentation gap."

3. "ISA 315 R 2019 expanded the IT environment requirements (315.26 + A173-A180). For an SME audit where the entity uses off-the-shelf accounting software (e.g., QuickBooks, Sage, Xero) with no integrations and no reliance on automated controls, what is the MINIMUM IT documentation required by ISA 315? Our model has three IT narrative fields — is that proportionate, or is even less acceptable for these engagements?"

4. "The five components of internal control per ISA 315.25 (control environment, risk assessment process, information system + communication, control activities, monitoring) — is the auditor required to document understanding of ALL FIVE in every engagement, or only those relevant to identified risks? Specifically: can a small-firm auditor doing a fully substantive audit (no reliance on controls) document 'controls were considered but no reliance is planned' for control activities + monitoring, or must each component still have substantive narrative?"

**For Copilot:**

5. **`engagement_entity_understanding` schema breadth** — 28 narrative columns is large for a single table. Confirm Postgres column-count is not a concern at this scale (max is 1600), and that RLS policies + indexes won't suffer from the wide row. Suggest if any columns should be split into a JSONB blob to keep the table narrower.

6. **`revise_engagement_understanding` carry-forward INSERT list** — same risk as Audit Strategy's revise (long INSERT column list). Confirm the SELECT * INTO + explicit-named-column INSERT pattern handles a 28-column carry-forward without truncation or PL/pgSQL surprises. Suggest a test pattern to detect drift if a column is added later but missed in the RPC.

7. **`approve_engagement_understanding` CHECK timing** — identical structure to `approve_audit_strategy`. Confirm the four-attestation CHECK fires correctly when client posts attestations + approval in one UPDATE (we proved this works for #1; this is a sanity check that nothing in the wider attestation count changes the answer).

---

## 8. Closure checklist

- [ ] Perplexity Q1-Q4 answered (or deferred with reasoning)
- [ ] Copilot Q5-Q7 addressed
- [ ] Tab order decision (J1) confirmed before placement
- [ ] Migration `20260521120001_engagement_entity_understanding.sql` applied to staging
- [ ] UI: tab appears at decided position with proper Pro-tier gating
- [ ] Smoke test: start draft → fill all sections → approve → CHECK enforces 4 attestations
- [ ] Smoke test: revise approved → new draft pre-fills, attestations reset
- [ ] Smoke test: non-admin sees read-only, Essentials org sees Pro banner
- [ ] User signs off

When all nine ticked, **CLOSED**.
