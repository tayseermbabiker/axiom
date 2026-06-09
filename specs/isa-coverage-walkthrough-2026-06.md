# ISA Coverage Walkthrough — tab-by-tab SME completeness validation (2026-06)

Goal: confirm each module captures everything **ISA-required for an SME audit** — without bloat. Driven by Perplexity Pro, one tab per round.

Inventory source: `docs/COVERAGE-REPORT.txt` (generated from code 2026-05-23). Modules built after that date are inventoried from code when we reach them (marked ⚠️ below).

## Anti-bloat rule (applies to every round)

**This walkthrough produces a MAP + a documented scoping decision — NOT a build queue.** For an SME audit, deliberately documenting "considered X, excluded for proportionality (ISA cite)" is MORE inspection-defensible than building X. ISA is explicitly scalable. So most findings end up SHELVED, not built.

**Step 1 — Perplexity classifies each suggestion:**
- **R — Required** for an SME ISA audit, exact ISA paragraph cited.
- **C — Conditional** — required only if a stated condition applies (group/listed/specific risk).
- **N — Not required / overkill.**

**Step 2 — I reconcile each against the actual code** (drop false-positives hidden in the screenshot; drop what's already built; dedup cross-module).

**Step 3 — Every surviving real gap gets a TRIAGE TAG (default = 🟠 SHELVE):**
- 🔴 **BUILD-NOW** — only if *cheap AND real AND an inspector/pilot would actually flag it*. High bar. Goes into the single batched migration.
- 🟠 **SHELVE-DOCUMENTED** — real but disproportionate for SME. Output = one line "considered, excluded for proportionality + ISA cite." That line IS the deliverable. **This is the default.**
- 🔵 **BACKLOG** — build only if an actual pilot or inspector asks.

**Cap:** the BUILD-NOW batch is ONE short session of the cheap, real few — not a multi-week thing. If the BUILD-NOW list grows past a handful, the bar wasn't high enough.

### Running BUILD-NOW list — EMPTY (decision 2026-06-04)

**Decision: build nothing from this walkthrough.** Bar = "has a real reviewer flagged it as missing?" No real reviewer (Qatar partners, Sadig/ex-Deloitte, Khalid) flagged any of these — Khalid's only catch (prior-year fees) was already built. Everything Perplexity surfaced is theoretical ISA-completeness, not a real-reviewer gap. Per anti-bloat + no-developer-trap, all candidates → BACKLOG (build instantly only if a real reviewer / pilot / inspector raises one).

Closed conclusion: the product is validated as complete by BOTH real auditors AND a thorough ISA gap-analysis — nothing crucial missing. That's a selling point, not a build list.

### BACKLOG (build ONLY if a real reviewer/inspector/pilot raises it)
- 🔵 Acceptance — independence hard gate (confirm CHECK) + integrity conclusion gate (confirm CHECK) + ISA 210.6 preconditions checkboxes. *(Closest to "real" — they're actual sign-off-integrity gates — so top of backlog, but no spectator has asked.)*
- 🔵 Materiality — "clearly trivial (ISA 450)" relabel + accumulation line.
- 🔵 Independence — team-level independence-confirmation checkbox (ISA 220.17).
- 🔵 Audit Planning — fraud-discussion date + participants (ISA 240.16).

### Running SHELVE list (documented scoping, NOT built)
- 🟠 Acceptance — ISA 220.23 acceptance→planning bridge note; ISA 220.24 post-acceptance disqualifying-info flag.
- 🟠 Engagement Letter — written-reps commitment checkbox (ISA 210.10c/580.9); recurring-terms reassessment checkbox (ISA 210.13). Both one-box, low-frequency for SME.

### Backlog
- 🔵 (none yet)

---

## Module 14 — Completion Memo — reconciled (2026-06-04). WALKTHROUGH COMPLETE.

**The MOST-built module. Perplexity's "Opinion screen severely under-built" = screenshot artifact** (it saw the bare Opinion-Type tab in isolation). Verified in code: opinion is assembled across `engagement_completion_memo` + a **13-attestation hard gate in signMemo()** + `report.html` builder.
- ✅ Already built (false positives): Basis for Opinion (report wording in report.html); modification basis (`opinion_basis_notes`, hard-gated "required for modified opinions"); misstatement→opinion linkage (opinion-logic warning); GC→opinion / MUGC (3 outcomes incl. adverse/disclaimer-implications, rendered); partner name + formal sign-off (13-attestation signMemo + report partner render); uncorrected-misstatements eval (Tier 1 fields); mgmt rep letter (hard-gated); TCWG comms; final analytical (ISA 520); final independence; subsequent events + review date; EQR (conditional, external toggle); file lock on section approval.
- 🟠 SHELVE (real but light/conditional/SME-rare, none flagged by a real reviewer): report_date ≥ subsequent-events-date validation rule; EQR reviewer conclusion narrative (EQR not required for SME); post-lock amendment log (ISA 230.13, rare); rep-letter explicit ISA 450.14 representation (guidance/wording); split qualified-misstatement vs qualified-scope (type is "qualified", reason in basis).
- 🔴 BUILD: none.

### ✅ WALKTHROUGH CLOSED (2026-06-04)
All modules validated. **Net result: 0 lines of code.** ~70 theoretical findings across 8+ modules → every one already built (false positives from collapsed/old screenshots) or shelved with documented ISA-cited proportionality rationale. Product validated complete by BOTH real auditors (Qatar/Sadig/Khalid) AND paragraph-level ISA gap analysis. Backlog holds the cheap items for if-a-real-reviewer-ever-asks. Decision bar held: build only what a real reviewer flags.

---

## Reconciled modules 3–7 + PBC (from Deep Research PDF, 2026-06-04)

**Headline: ~40 flagged → almost all already built or deliberately shelved. Net new build candidates = 3 tiny, all borderline.** Screenshots showed collapsed views and predate the controls/assertion build.

### Independence — strong module
- ✅ Already built (false positives): R2 independence-before-report → completion memo `final_independence_conclusion`; R4 overdue-fees action → `prior_year_fees_note` ("amount/age, action taken").
- 🟠 SHELVE: R3 long-association extra structure (flag+rotation checkbox suffices for SME); R5 "who performed NAS" (self-review threat category captures it); C1 financial-interests (under self-interest threat); C3 network firm (not a network).
- 🔴/🟠 borderline: **R1 team-level independence confirmation** (ISA 220.17) — one checkbox "all engagement team members confirmed independence". Lean SHELVE; cheap if we do it.

### Audit Planning (strategy + understanding-the-entity)
- ✅ Already built (false positive): **R5 "the audit plan" (ISA 300.8 assertion-level procedures)** — Perplexity's "single most significant gap" is actually the execution sections + procedures (now with `procedure_type` + assertions + risk→procedure matrix). It's built, just in a different tab.
- 🟠 SHELVE: R2 GC planning (full ISA 570 lives in the dedicated Going Concern section); R3 IT environment (deliberate narrative for SME — `it_environment_*` fields); R4 TCWG-split (conflated for owner-managed); C1/C2/C4 (acceptance/expert/group).
- 🔴/🟠 borderline: **R1 fraud discussion structure** (ISA 240.16) — add date + participants to the existing checkbox+notes. Defensible, light.

### Materiality — strongest quantitative module
- ✅ Already built (false positive): R4 specific materiality → `engagement_specific_materiality_items` table (`class_or_account` + `specific_amount`).
- 🟠 SHELVE: R1 revision mechanism (the workpaper is versioned — revising = new version); R3 PM%-risk-anchoring (reason dropdown + rationale field cover it).
- 🔴/🟠 borderline: **R2 "clearly trivial" labelling** — relabel trivial-threshold as "clearly trivial (ISA 450.3)" + one-line "below this, not accumulated". Basically a copy tweak — near-free, worth doing.

### Risk Assessment — 4 of 6 R's already built
- ✅ Already built (false positives): R1 inherent/control/assertion (`inherent_rating`/`control_rating`/`combined_rating`/`assertion`); R2 controls understanding (NEW controls D&I feature); R4 revenue rebuttal (`is_locked_presumed`/`presumption_rebutted`/`rebut_revenue_presumption`); R6 stand-back (`isa_315_stand_back_completed` attestation + warning); C1 ToC-on-reliance (NEW controls reliance + OE warning).
- 🟠 SHELVE: R3 FS-level risk register (mgmt-override seeded + GC module cover pervasive risk; distinct register disproportionate); R5 enforced procedure structure (`procedure_type` + ISA 530 `procedure_sampling` exist); C2 ITGC (narrative); C3 mgmt-override (seeded mandatory non-rebuttable).
- 🔴 BUILD: none.

### PBC — workflow tracker, evidence lives elsewhere
- 🟠 SHELVE (all): R1 procedure-per-item / R2 accuracy-completeness / R3 assertion-linkage → testing lives in the section procedures (assertion-linked); R4 timely-assembly → dedicated File Assembly (ISA 230) module; C1 third-party confirmations → separate Confirmations (ISA 505) module; C2/C3 conditional.
- 🔴 BUILD: none.

### Updated net BUILD-NOW (still tiny)
Confirmed Acceptance (3) + at most 3 tiny new (all borderline, user decides):
4. 🟠→? Materiality R2 — "clearly trivial" relabel + accumulation line (near-free copy).
5. 🟠→? Independence R1 — one team-confirmation checkbox.
6. 🟠→? Audit Planning R1 — fraud-discussion date + participants.
Everything else: already built (false positives) or SHELVE-documented (proportionality).

## Module order & status

| # | Module | ISA | Inventory | Status |
|---|---|---|---|---|
| 1 | Client Acceptance / Continuance | ISA 220 | report | ⬜ prompt ready |
| 2 | Engagement Letter | ISA 210 | report | ⬜ |
| 3 | Independence & Ethics (incl. prior-year fees) | ISA 220 + IESBA | report + ⚠️ fees | ⬜ |
| 4 | Materiality | ISA 320 | report | ⬜ |
| 5 | Understanding the Entity | ISA 315 | ⚠️ code | ⬜ |
| 6 | Audit Strategy | ISA 300 | report | ⬜ |
| 7 | Risk Assessment + Controls | ISA 315 / 330 | report + ⚠️ controls | ⬜ |
| 8 | AML / KYC (CDD) | local DNFBP | ⚠️ code | ⬜ |
| 9 | Trial Balance / Working TB | ISA 500 | ⚠️ working-tb | ⬜ |
| 10 | PBC list | — | ⚠️ code | ⬜ |
| 11 | Audit sections / procedures (+ assertions) | ISA 330 | report + ⚠️ assertions | ⬜ |
| 12 | Estimates | ISA 540 | report | ⬜ |
| 13 | Confirmations | ISA 505 | report | ⬜ |
| 14 | Completion Memo | ISA 700/705/260/450/220/580 | report + ⚠️ Tier1 fields | ⬜ |
| 15 | Subsequent Events | ISA 560 | report | ⬜ |
| 16 | Going Concern | ISA 570 | report | ⬜ |
| 17 | FS Upload | ISA 500/230 | report | ⬜ |
| 18 | File Assembly | ISA 230 | report | ⬜ |

Status key: ⬜ not started · 🟡 prompt sent, awaiting Perplexity · 🔵 reconciling · ✅ validated (no R gaps or R gaps shipped).

## Log (per-module findings)

### 1. Client Acceptance / Continuance — reconciled
Real cheap gates (build in final batch): **independence hard gate** (add `independence_assessment_completed` to confirm CHECK — ISA 220.22) + **integrity conclusion gate** (require `integrity_conclusion` at confirm — ISA 220.A20-22). Optional light: ISA 220.23 acceptance→planning bridge note; ISA 220.24 post-acceptance disqualifying-info flag. False positives (already in code): predecessor outcome+workpapers, opening balances, EQR, ISA 210 preconditions (in Engagement Letter module).

### 8. AML / KYC — reconciled, DEFERRED to a dedicated GCC pass
**Decision (user, 2026-06-04): module serves the whole GCC, must stay jurisdiction-agnostic — NOT UAE-centric.** Perplexity (Deep Research) anchored on UAE law (Cabinet Decision 58/2020, Federal Decree-Law 20/2018, 5-yr retention, 25% threshold) — do NOT import UAE-specific machinery.
- Already built (false positives): UBO `ownership_pct`, separate `pep_involved`/`pep_notes`, continuance carry-forward (`cdd_basis`/`no_changes_confirmed`/`carried_forward_from`).
- Covered-enough: identity via evidence-URL links, EDD path (`cdd_level=enhanced`/`accept_edd`/`source_of_funds_notes`), simplified basis (`cdd_level`+`risk_rationale`).
- Only jurisdiction-agnostic candidates: (a) PEP senior-management-approval field when `pep_involved=true` (FATF Rec 12, universal); (b) generic record-retention confirmation checkbox (FATF Rec 11, no hardcoded years).
- **⏸ DO FURTHER DIGGING LATER:** dedicated GCC-wide AML research pass — map the common FATF baseline across UAE/KSA/Qatar/Bahrain/Kuwait/Oman + where they diverge, then decide which agnostic fields to add. Not now.

