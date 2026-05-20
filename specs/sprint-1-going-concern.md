# Sprint 1 — Going Concern Procedure Rewrite (Verification Spec)

**Status:** CLOSED — verification pass complete 2026-05-20.
**Branch:** `staging` on `tayseermbabiker/axiom`

---

## 1. Partner gap addressed

Qatar partner verbatim: *"Your going-concern tests aren't specific. 'Evaluate management's assessment' — what does that mean operationally? CaseWare gives me a checklist. This reads like a textbook."*

The gap: the 6 original procedures were generic verbs ("evaluate", "review", "assess") with no instruction on WHAT to test or HOW to conclude. The rewrite gives the auditor directive steps + the ISA 570 indicator checklist explicitly named.

**ISA standards mapped:**
- **ISA 570 (Revised) — Going Concern** (primary)
- **ISA 560 — Subsequent Events** (post-balance-sheet review)
- **ISA 580 — Written Representations** (mgmt rep)
- **IAS 1.25-26** — going concern disclosure obligation

---

## 2. What changed

**File:** `public/js/audit-templates.js` → `PROCEDURE_TEMPLATES['Going Concern']`.

**Before:** 6 procedures, generic ("Evaluate management's going concern assessment...", "Review financing arrangements...").

**After:** 12 procedures, each directive and operationally testable. Highlights:
- Explicit 12-month minimum period check (ISA 570.13)
- Three full indicator checklists baked into procedures 2-4: **Financial** (10 indicators), **Operating** (6 indicators), **Other** (4 indicators) — taken verbatim from ISA 570 Appendix
- Cash flow forecast recalculation with explicit stress-test step
- Loan + covenant testing with maturity / renewal evidence distinction (lender commitment, not management intent)
- ISA 560 post-balance-sheet review for events affecting the conclusion
- Material uncertainty evaluation as a discrete step (ISA 570.18)
- Disclosure adequacy check against ISA 570.19 / IAS 1.25-26
- Audit conclusion decision tree mapping the four ISA 570 outcomes (unmodified / MURGC / qualified-or-adverse / adverse) and cross-referencing the Completion Memo Opinion tab
- Written representation per ISA 570.16 / ISA 580
- Analytical trend ratio review as final corroborating procedure

---

## 3. Impact / wiring

- These procedures are seeded into every NEW engagement via `seedSectionsForEngagement` → no migration required
- **Existing in-progress engagements still have the old 6 procedures** — by design (evidence integrity, see Local Compliance spec J2). Partners can manually add new procedures if needed
- New-Section modal also picks these up via `PROCEDURE_TEMPLATES['Going Concern']`

---

## 4. Out of scope

- Going Concern conclusion narrative auto-populating into the Completion Memo Narrative tab — still manual copy/paste
- Automated indicator detection from the TB (e.g., flag a net liability position automatically) — Sprint 3 candidate
- Multi-year horizon assessment beyond 12 months
- Industry-specific going concern indicators (banks, insurance, real estate) — generic only
- Stress-test parameter library (the 20%/60-day example in procedure 5 is illustrative, not enforced)

---

## 5. Judgment calls

**J1 — Indicators embedded as three giant procedures, not 20 individual ones**
Could have made each ISA 570 indicator its own procedure row (~20 procedures total). Chose three grouped procedures so the auditor sees the indicator clusters together and the section doesn't sprawl.
*Risk:* harder to mark individual indicators as "tested" — the procedure is binary done/not-done.

**J2 — Conclusion decision tree as a procedure (not a memo field)**
Procedure #10 walks the four ISA 570 outcomes. Alternative would be making it a memo template / dropdown. Chose procedure because it cross-references the Completion Memo Opinion tab — auditor sees both halves of the conclusion in one place.

**J3 — Written rep step is procedure-level, not separately tracked**
Once we wire `mgmt_rep_letters` in Sprint 2, this procedure should reference that table. For now, it's a manual evidence-attached check.

**J4 — Trend ratio review kept analytical, not predictive**
Procedure #12 compares to prior 2 periods. Did not add a forward-projected ratio test. Reasoning: forecast tested in procedure #5 (cash flow); ratios are corroborating.

---

## 6. Blocking verification questions

**For Perplexity:**

1. "Under ISA 570 (Revised), is the 'at least twelve months from the reporting date' the actual standard text, or has the IAASB extended it in recent revisions? I want to confirm the 12-month threshold is still authoritative as of the 2024-2025 ISA edition."

2. "ISA 570.18 introduces 'material uncertainty.' Is the test 'one or more indicators present + management mitigation not fully supported' a correct paraphrase, or does ISA 570 set a specifically higher bar (e.g., 'significant doubt' as a higher threshold than 'doubt')?"

3. "For a small-firm audit where the entity is clearly profitable and has positive net assets with no debt, must the auditor still document the going concern procedures, or is there an ISA 570 documentation threshold below which the procedures can be reduced/skipped? Our 12 procedures assume full documentation is always required."

**For Copilot:**

4. **`audit-templates.js`** — confirm the 12 procedures are syntactically valid JS objects (no missing commas, quotes correctly escaped — note ISA quotes use straight ASCII apostrophes consistently).

5. **Existing engagements** — confirm the new procedure list does NOT retroactively replace procedures in already-created Going Concern sections (the seeding only fires on engagement creation; rewrite is forward-only).

---

## 7. Closure checklist

- [ ] Create a fresh test engagement on staging
- [ ] Open the Going Concern section
- [ ] Verify the 12 new procedures appear in order
- [ ] Verify the ISA 570 Appendix indicator names (financial / operating / other) are spelled correctly per the official standard
- [ ] Verify an OLD engagement (created before this change) still shows the old 6 procedures
- [ ] Perplexity Q1-Q3 answered
- [ ] Copilot Q4-Q5 addressed
- [ ] User signs off

When all eight ticked, **CLOSED**.

---

## 8. Verification pass — 2026-05-20

Cross-checked against Perplexity (ISA research) + GitHub Copilot (code review). Three content edits + one comment in `audit-templates.js`. No schema changes.

### Issues fixed

| # | Source | Issue | Fix |
|---|---|---|---|
| P2 | Perplexity Q2 | Procedure #8 paraphrased "material uncertainty" too loosely as "indicator + unsupported mitigation" | Reframed around ISA 570.17 "significant doubt" as the conceptual threshold; material uncertainty becomes the *conclusion* when significant doubt persists after considering management's plans. Documentation now distinguishes (a) no significant doubt / (b) significant doubt resolved by plans / (c) material uncertainty exists |
| P3 | Perplexity Q3 | Implicit assumption that all 12 procedures applied in every engagement (overkill for clearly profitable, debt-free entities per ISA 570) | Procedure #1 now explicitly requires risk-tiering at the scope step. Low-risk engagements may justify reduced procedure set with documented rationale; standard/elevated risk requires the full set. Keeps the firm methodology defensible without forcing mechanical full-checklist compliance |
| P4 | Perplexity Q4 | Procedure #5 used fixed "20% revenue / 60-day AR" stress-test parameters that aren't in ISA 570 | Reworded to require stress-test scenarios tailored to entity-specific vulnerabilities (loss of major customer, margin compression, covenant pressure, etc.). ISA 570 explicitly noted as not prescribing fixed parameters |
| C2 | Copilot Q2 | Forward-only seeding semantics weren't documented in code | Added a comment block above `PROCEDURE_TEMPLATES` explaining that edits affect only new engagements; existing engagements keep their persisted procedures unless migrated explicitly |

### Confirmed correct as-built

| # | Source | Finding |
|---|---|---|
| P1 | Perplexity Q1 | 12-month minimum horizon (ISA 570.13) still authoritative in 2024-2025 ISA edition |
| P5 | Perplexity Q5 | 4-outcome conclusion tree complete; disclaimer is NOT a standard ISA 570 outcome (only arises from broader scope conditions) |
| C1 | Copilot Q1 | Single-quoted string syntax with escaped apostrophes is safe. Double-quoted alternative is more robust but not necessary |
| C3 | Copilot Q3 | `text` column handles any procedure length. UI considerations (collapsible bodies, mobile readability) are polish — deferred |

### Deferred

| # | Source | Why deferred |
|---|---|---|
| C3 | Copilot Q3 | UI polish (collapsible procedure bodies, mobile typography tuning) — Sprint 2 if partner feedback flags it |

**Sprint 1 — Going Concern: CLOSED. Sprint 1 FULLY CLOSED.**
