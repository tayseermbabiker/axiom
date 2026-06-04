# Controls D&I Evaluation + Reliance Decision (Verification Spec)

**Status:** SPEC — BUILD-READY. Standards verification DONE (Perplexity + Gemini) + Copilot schema pass DONE (all 2026-06-04). Build on user "go".
**Branch:** `staging` on `tayseermbabiker/axiom`
**Effort estimate:** ~1-2d (light structured register, no OE testing engine)
**Origin:** Demo 2026-06-03. Prospect asked: *"Does the tool cover the test of controls / walkthrough — where we study the client's process and manuals to decide whether controls are weak, and whether to RELY on them or focus on substantive testing?"*

---

## 1. Gap addressed

Audexon already documents controls **as narrative** — `engagement_entity_understanding` §D (five IC components), §E (IT environment / ITGCs). What is missing:

1. A **structured D&I conclusion** per relevant control (design effective/deficient + implemented y/n) — not buried in prose.
2. An explicit **reliance decision** (No reliance / Rely / Combined) that is visible and drives the substantive response.
3. The enforced **risk → control → response linkage**. The risk matrix today links `engagement_risks → procedures` directly; there is no control entity in the chain.

This is exactly the ISA 230 / ISA 315 documentation deficiency confirmed by both AIs (see §2). The fix is a **light structured controls register for *relevant controls only***, slotted inside Risk Assessment — **not** an operating-effectiveness (OE) testing engine.

**ISA mapped:** ISA 315 (Revised 2019) .26 (controls relevant to the audit), .25 (IC components / IT), D&I evaluation; ISA 330 (response linkage); ISA 230 (structured documentation); ISA 500 (IPTE / information produced by the entity).

---

## 1a. HARD ANTI-BLOAT CONSTRAINT (non-negotiable acceptance criterion)

Audexon's positioning is "lighter than CaseWare." This feature must NOT make every engagement heavier. Binding rules:

1. **The substantive-only default is completable in ONE action.** The section opens empty with a single conclusion control defaulting to *"No reliance — substantive approach throughout."* The auditor confirms and moves on. This satisfies the section for the ~90% SME case with zero control rows.
2. **Nothing is mandatory except the single reliance conclusion.** Control rows are added ONLY when relevant controls exist. The register is an add-when-relevant list, never a grid that must be filled.
3. **No duplication.** The five IC components stay in `engagement_entity_understanding` §D/§E. This section is ONLY the structured D&I conclusion + reliance decision for the handful of relevant controls — it does not re-document control narrative.
4. **Progressive disclosure.** The reliance warning, IPTE note, and per-control fields appear only when their trigger is set. Empty state shows the one-action path, nothing else.

If the build cannot meet rule 1 (one-action substantive-only), STOP and re-scope — a mandatory grid is an automatic reject.

---

## 2. Standards verification — DONE (2026-06-04)

**Perplexity (IFAC/ISA-anchored) — confirmed:**
- D&I of controls *relevant to the audit* is **mandatory on every audit**, including fully substantive SME audits. Only OE testing is conditional (ISA 330 — required only if relying, or if substantive alone is insufficient).
- Free-text narrative alone — no explicit D&I conclusion, no reliance decision, no risk→response linkage — is a **documentation deficiency under ISA 230 + ISA 315**. Inspectors expect a structured table/workpaper, not prose.
- Two refinements folded into scope: (a) scope to **"relevant controls" only** — significant-risk controls, journal-entry controls, and any control planned for reliance (this keeps the build small); (b) flag **IPTE under ISA 500** where entity-produced info is used as evidence.

**Gemini (build-scope) — confirmed + one guard:**
- Light structured step inside Risk Assessment is **methodologically superior** to a standalone module (enforces Risk → Control D&I → Residual risk → Substantive procedure flow). Deferring OE engine is **highly defensible** for SME-focused tool.
- **The "False Comfort Trap" (design guard):** if the tool lets a user toggle "Rely on controls" and *auto-drops* substantive extent with zero structured OE evidence, the file **fails inspection**. Therefore:
  - Reliance field **defaults to `no_reliance` (substantive-only)**.
  - Toggling to `rely`/`combined` must NOT silently reduce substantive extent. It triggers a **hardcoded warning** instructing the user to document sampling methodology + OE workpapers manually (attachment), since the OE engine is deferred.
- Adds: a light **ITGC / automated-controls acknowledgement** is mandatory (already partly covered by `engagement_entity_understanding` §E narrative — confirm it satisfies, else add a structured checkbox here).

**Net consensus = build:** structured, assertion-level register for *relevant controls only* — D&I conclusion + reliance decision (default no-reliance, gated warning on rely) + link to the risk it addresses. **Defer:** OE testing / sampling engine.

---

## 3. UI inventory

**Placement:** Risk Assessment module → new sub-section / tab **"Controls & reliance"** (sits between Understanding-the-Entity narrative and the risk→procedure matrix). Gemini-confirmed: inside Risk Assessment, not standalone.

**Gates:** Pro-tier banner if `feature_tier !== 'pro'`; read-only for non-admin; INSERT/UPDATE admin-only.

**Empty state (the default, per §1a):** section opens with the **engagement-level reliance conclusion** control pre-set to `no_reliance` — *"No reliance on controls — substantive approach throughout."* One confirm action satisfies the section. A subtle "+ Add a relevant control" link is the only way to expand into the register. No control rows are required.

**Controls register (child table, one row per relevant control — only when relevant controls exist):**
- Control reference / name (text)
- Process / cycle (e.g. Revenue, Purchases, Payroll, JE) (text)
- Related assertion(s) (text or multi — occurrence, cut-off, completeness, etc.)
- **Links to risk:** dropdown of existing `engagement_risks` for this engagement (nullable — but warn if a significant risk has no linked control consideration)
- Control type (enum: `manual` / `automated` / `itgc`)
- Walkthrough performed? (boolean) + walkthrough reference (text)
- **Design conclusion** (enum: `effective` / `deficient` / `not_applicable`)
- **Implementation** (enum: `implemented` / `not_implemented`)
- **Reliance decision** (enum: `no_reliance` / `rely` / `combined` — **DEFAULT `no_reliance`**)
- IPTE relied upon? (boolean — ISA 500) + accuracy/completeness assessed note (text, shown only if true)
- Notes (text)

**Reliance warning (Gemini guard):** when `reliance` ≠ `no_reliance`, render an inline non-dismissable banner: *"You have selected control reliance. The operating-effectiveness testing module is not yet available — you must document your sampling methodology and tests-of-controls workpapers and attach them manually. Selecting reliance does NOT automatically reduce the extent of substantive testing."* No auto-mutation of substantive extent.

**Roll-up into Risk Assessment confirmation:** add one attestation to `engagement_risk_assessment`: `isa_315_controls_di_concluded` (boolean) — "D&I evaluation completed for controls relevant to the audit; reliance decisions documented." Added to the existing confirmation CHECK.

---

## 4. Data model

### `public.engagement_controls` (new child table)

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | gen_random_uuid() |
| `engagement_id` | uuid FK | ON DELETE CASCADE |
| `organization_id` | uuid FK | ON DELETE CASCADE |
| `risk_id` | uuid FK engagement_risks | nullable, ON DELETE SET NULL |
| `control_ref` | text | |
| `process_cycle` | text | |
| `assertions` | text | (free text or csv v1) |
| `control_type` | text | CHECK IN ('manual','automated','itgc') |
| `walkthrough_performed` | boolean | default false |
| `walkthrough_ref` | text | |
| `design_conclusion` | text | CHECK IN ('effective','deficient','not_applicable') |
| `implementation` | text | CHECK IN ('implemented','not_implemented') |
| `reliance_decision` | text | CHECK IN ('no_reliance','rely','combined') DEFAULT 'no_reliance' |
| `ipte_relied` | boolean | default false |
| `ipte_assessment_note` | text | |
| `notes` | text | |
| `created_by` | uuid FK profiles | |
| `created_at` | timestamptz | default now() |
| `updated_at` | timestamptz | DB-managed trigger |

**RLS / GRANT:** identical pattern to `engagement_risks` — SELECT any org member; INSERT/UPDATE/DELETE admin AND Pro; explicit GRANT SELECT,INSERT,UPDATE,DELETE TO authenticated (per [[supabase-grant-cutover]] — explicit grants now mandatory on new tables).

**Trigger:** `trg_ec_set_updated_at` BEFORE UPDATE → `set_updated_at_now()`.

**Chain achieved:** `engagement_controls.risk_id → engagement_risks.id → engagement_risk_procedure_links → procedures`. That is the full **risk → control → response** trace for the inspection PDF.

### `engagement_risk_assessment` — add column
- `isa_315_controls_di_concluded` boolean default false. Update confirmation CHECK to require it (alongside existing 3 + stand-back attestation).

---

### Copilot schema pass — resolutions (2026-06-04)

All four design choices confirmed correct; refinements folded in below.

**R1 — Flat table confirmed (not JSONB).** JSONB would lose FK integrity, make per-control RLS awkward, and complicate triggers/CHECKs. Add these indexes so the inspection-PDF JOIN and the "significant risk with no linked control" query stay cheap:
```sql
CREATE INDEX idx_ec_risk_engagement ON engagement_controls(risk_id, engagement_id);
CREATE INDEX idx_er_engagement_significant ON engagement_risks(engagement_id, is_significant);
```
Detection query (significant risk lacking a linked control → UI warning per J3):
```sql
SELECT r.* FROM engagement_risks r
LEFT JOIN engagement_controls c ON c.risk_id = r.id AND c.engagement_id = r.engagement_id
WHERE r.engagement_id = :eid AND r.is_significant = true AND c.id IS NULL;
```

**R2 — `risk_id ON DELETE SET NULL` confirmed.** Orphan report = `SELECT * FROM engagement_controls WHERE engagement_id = :eid AND risk_id IS NULL`. OPTIONAL (deferred, anti-bloat): a `risk_deleted_at timestamptz` column + BEFORE DELETE trigger on `engagement_risks` to distinguish "never linked" from "risk later deleted." Skip in v1 unless the inspection PDF needs that distinction — plain `risk_id IS NULL` is enough.

**R3 — CHECK extension = Option A (backfill).** Add `isa_315_controls_di_concluded boolean NOT NULL DEFAULT false`, then backfill existing confirmed rows so they stay valid, then recreate the confirmation CHECK to require the flag on new confirmations:
```sql
ALTER TABLE engagement_risk_assessment ADD COLUMN isa_315_controls_di_concluded boolean NOT NULL DEFAULT false;
UPDATE engagement_risk_assessment SET isa_315_controls_di_concluded = true WHERE status = 'confirmed';
-- drop + recreate the status='confirmed' CHECK adding: AND isa_315_controls_di_concluded = true
```
Semantic assumption (accepted): pre-existing confirmed assessments — on staging AND the few prod engagements confirmed under the prior methodology — are treated as "controls D&I concluded." Defensible: they were signed off before this methodology layer existed. (Option B — timestamp-cutover exemption — is the fallback if we ever decide NOT to assert that; not needed here.)

**R4 — RLS + GRANT confirmed; RLS runs BEFORE the trigger.** Critical ordering: RLS decides *who* can attempt the DELETE; if RLS blocks, the BEFORE DELETE trigger never fires. The orphan-guard business rule stays in a trigger (mirrors `prevent_orphaned_significant_risks` on the junction table), RLS only gates role. Policies + grants:
```sql
ALTER TABLE engagement_controls ENABLE ROW LEVEL SECURITY;
-- SELECT: any org member ; INSERT/UPDATE/DELETE: admin+Pro (use the codebase's actual helpers)
REVOKE ALL ON TABLE engagement_controls FROM PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON engagement_controls TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON engagement_controls TO service_role;
```
**Build note:** Copilot assumed helpers `is_org_member()` / `is_org_admin_or_pro()`. Confirm the ACTUAL helper-function names / inline membership-check pattern used by `engagement_risks` policies and copy that exactly — do not introduce new helper names.

---

## 5. Out of scope (deferred — defensible per §2)

- **Operating-effectiveness testing engine** — sampling, attribute testing, control test workpapers. Manual attachment stopgap with hardcoded warning. Build only when a paying firm takes a reliance approach.
- ITGC register per application × control area — narrative in `engagement_entity_understanding` §E stays as-is for v1.
- Auto-suggestion of controls from the entity-understanding narrative.
- Carry-forward of controls from prior-year engagement.
- Auto-reduction of substantive sample size from reliance decision (explicitly REJECTED — False Comfort Trap).

---

## 6. Judgment calls

**J1 — Inside Risk Assessment, not standalone.** Gemini-confirmed methodologically superior; enforces the cognitive flow inspectors expect.

**J2 — Reliance defaults to `no_reliance`.** Gemini guard. Most SME audits are substantive-led; defaulting to reliance would invite unsupported reliance. Toggling up is a deliberate act that triggers the warning.

**J3 — `risk_id` nullable, not mandatory.** Some relevant controls (e.g. JE controls per ISA 315) aren't tied to a single assessed risk row. Nullable, but UI warns on significant risks with no control consideration. Avoids forcing fake links.

**J4 — Register scoped to "relevant controls," not all controls.** Per Perplexity — you only D&I the relevant subset. UI copy + empty-state prompt makes this explicit so partners don't try to log every control.

**J5 — Roll into existing Risk Assessment attestation, no separate approval workflow.** Keeps build at ~1-2d and avoids a fourth approval surface. The controls conclusion is evidenced by the `isa_315_controls_di_concluded` attestation on the existing confirmation.

---

## 7. Blocking verification — Copilot schema pass ✅ DONE (2026-06-04)

All four questions answered and resolved — see "Copilot schema pass — resolutions" in §4. Summary: flat table confirmed (+ 2 indexes), SET NULL confirmed (+ simple orphan query), CHECK extension via Option A backfill, RLS-before-trigger ordering confirmed with policies/grants drafted. One build-time TODO: confirm the codebase's actual org-membership helper names before writing the RLS policies.

---

## 8. Closure checklist

- [x] Copilot Q1-Q4 addressed (2026-06-04 — see §4 resolutions)
- [x] **BUILT 2026-06-04** — migration `20260604120000_engagement_controls.sql` (table + indexes R1, SET NULL R2, CHECK Option A R3, RLS R4) + UI in `public/pages/engagement.html`
- [x] Build-time TODO resolved: real helpers are `get_user_org_ids` / `user_has_role_in_org(org,'admin')` / `org_has_pro_tier` (NOT the generic names Copilot assumed) — copied from `engagement_risks` policies
- [x] **ANTI-BLOAT GATE (§1a):** empty state shows substantive-only default note; zero control rows required; one attestation tick at confirm satisfies the section
- [x] UI: "Controls & reliance" sub-section in Risk Assessment, Pro+admin-gated (rides existing `loadRiskAssessment` gate)
- [x] Reliance warning banner fires on `rely`/`combined`; no auto-mutation of substantive extent (decision is documentation-only)
- [x] `isa_315_controls_di_concluded` attestation = 5th checkbox in confirm modal, set on confirm, enforced by DB CHECK `era_controls_di_concluded_chk`
- [x] Inspection PDF (`report.html`): controls register + D&I/reliance + control→risk link rendered in the Risk Assessment block; 5th attestation row added (render parity per pre-commit checklist #2/#7)
- [ ] **PENDING (user/runtime):** migration applied to staging Supabase `lbwowlvajgpdxsdpudem`
- [ ] **PENDING (user):** smoke test — add control → D&I conclusion → default no_reliance → confirm; toggle rely → warning; non-admin read-only; Essentials sees Pro banner
- [ ] User signs off

When the deferred PDF item is built and smoke test passes, **CLOSED**.
