# Per-Procedure Assertion Tagging + ISA Test-Type Relabel (Verification Spec)

**Status:** VERIFIED (Perplexity + Gemini, 2026-06-04) — building. Copilot schema answers folded into §4.

## VERIFICATION RESULTS (2026-06-04) — corrections applied

Perplexity + Gemini converged. Confirmed: 4-type taxonomy; single Presentation chip OK; tests-of-controls carry the assertions they address; process/conclusion steps carry no assertion. Three corrections folded in:

1. **Split Existence vs Occurrence** (both: merging is non-conformant for transaction cycles — ISA 315 A190). Added **`occurrence`** assertion; transaction-level procedures (Revenue, COS, Payroll, Opex, JET, plus PPE additions/disposals, share/dividend movements, RP transactions, joiners/leavers) tagged **Occurrence** not Existence. Balance-level period-end tests stay **Existence**. Fixes spot-checks (f) + (h).
2. **Going Concern = FS-level / pervasive** (ISA 315.A193), not merely Presentation. Added **`fs_level`** tag ("FS-level / Pervasive"); GC procedures tagged fs_level (+ valuation/presentation where specific).
3. **Relabel type `other` → "Risk Assessment / Admin"** (display only; enum unchanged) so ISA 315.14 risk-assessment work isn't diluted in a generic "Other".

Label nit: `valuation` chip displays as **"Valuation & Allocation"** (AVA).

Final vocabulary = 9 assertions (existence, occurrence, completeness, accuracy, valuation, cutoff, classification, rights_obligations, presentation) + 1 level tag (fs_level). Note: `engagement_risks` still uses the original 8 (no occurrence) — procedures are a separate field; aligning the risk table is a later optional change. The corrected canonical mapping lives in `PROCEDURE_ASSERTIONS` in `audit-templates.js`.

---

**Original status:** SPEC — awaiting Perplexity (ISA) + Copilot (schema/render) answers, then build.
**Origin:** Demo 2026-06-03. Each section procedure used to show two tags — the **assertion(s)** it tests (existence, completeness…) and the **nature of the test** (test of controls / analytical / test of details). The procedure-library rewrite kept the type tag but dropped the per-procedure assertion tag (breadcrumb at `section.html:1509` — `// Assertions shown at section level only`). Goal: restore ISA-conformant per-procedure categorisation. **Procedure text is NOT changing — only its categorisation.**

---

## 1. Current state (verified in code)

- **Test-type tag EXISTS.** `audit_procedures.procedure_type` CHECK IN (`test_of_detail`,`analytical`,`controls`,`other`). Rendered in `section.html` as a badge / editable dropdown (line 1528) and seeded from each template's `type`.
- **Per-procedure assertion does NOT exist.** No `assertions` column on `audit_procedures`; templates carry no per-procedure assertion. Only a section-level `audit_sections.assertions` chip row exists.
- Decision: add per-procedure assertions (schema + seed + render + editable), and relabel the type badges to ISA-precise wording.

---

## 2. Assertion vocabulary (proposed)

Reuse the **same 8 assertions** already in `engagement_risks.assertion` so the risk matrix, the section chips, and procedures all speak one language:

| Code | Assertion | Applies to |
|---|---|---|
| **E** | Existence / Occurrence | balances (existence) + transactions (occurrence) — merged |
| **C** | Completeness | both |
| **A** | Accuracy | transactions + accuracy/measurement of balances |
| **V** | Valuation & Allocation | balances (impairment, ECL, NRV, estimates) |
| **CO** | Cut-off | transactions |
| **CL** | Classification | both |
| **RO** | Rights & Obligations | balances |
| **P** | Presentation & Disclosure | both |

`—` = no assertion-level mapping (pure scoping / documentation / conclusion / ISA-process step — e.g. "document the JET scope", "obtain management representation on…"). These stay untagged rather than forced.

**Open question for Perplexity (Q1):** is merging *existence* and *occurrence* into one chip acceptable, or should transaction-level procedures carry a distinct **Occurrence** (9th code)? Merging keeps one vocabulary across risks + procedures; splitting is more textbook-precise.

---

## 3. Test-type relabel (ISA 330 / 520) — labels only, no schema change

| DB value | Current label | New ISA label |
|---|---|---|
| `controls` | Controls | **Test of Controls** (ISA 330.8) |
| `test_of_detail` | Test of Detail | **Test of Details** (ISA 330.18) |
| `analytical` | Analytical | **Substantive Analytical** (ISA 520) |
| `other` | Other | **Other / Risk assessment** |

The enum value `controls` stays; only the display string changes (section.html dropdown + badge, report.html). Confirm with Perplexity that these four cover the ISA 330 response taxonomy for an SME file (Q2).

---

## 4. Schema + render plan (brief — full detail after verification)

- **Schema:** `ALTER TABLE audit_procedures ADD COLUMN assertions text[] NOT NULL DEFAULT '{}'`. No CHECK on array contents (Postgres can't easily constrain array elements to an enum cleanly) — UI offers only the 8 valid chips; app validates. Copilot to confirm (Q-C1).
- **Seed:** add `assertions: [...]` to each template procedure object; `seedSectionsForEngagement` writes it alongside `procedure_type`. Forward-only (existing engagements keep current rows; optional one-off backfill tool later).
- **Render:** assertion chips under each procedure description in `section.html` (revive the orphaned `.assertion-chip` CSS), editable multi-select for admin/preparer (like the type dropdown), read-only when section approved. Render parity in `report.html` procedure listing.

---

## 5. Proposed assertion mappings (FULL — for review)

Legend: E=Exist/Occur · C=Complete · A=Accuracy · V=Valuation · CO=Cut-off · CL=Classification · RO=Rights&Oblig · P=Present/Disclose · —=process step. Type in brackets: TD=test of details, AN=analytical, TC=test of controls, OT=other.

### Cash & Bank
1. Bank confirmations (balances/facilities/liens/signatories) [TD] → **E, RO, C**
2. Test year-end bank reconciliation, recompute [TD] → **E, A**
3. Investigate reconciling items (window-dressing) [TD] → **CO, E**
4. Inter-bank transfer (kiting) test [TD] → **CO**
5. Cut-off of receipts/disbursements [TD] → **CO**
6. Restricted/pledged cash, classification, disclosure [TD] → **RO, CL, P**
7. FX retranslation at closing rate [TD] → **V**
8. Overdraft set-off (IAS 32) [TD] → **CL, P**
9. Cash & equivalents composition/disclosure (IAS 7) [TD] → **CL, P**
10. Related-party balances/facilities disclosure [TD] → **P, C**
11. Cash-disbursement controls [TC] → **E, A**
12. Analytical: interest income, bank charges [AN] → **A, C**

### Accounts Receivable
1. Positive confirmations + alternatives [TD] → **E, RO, A**
2. Reconcile sub-ledger to GL + search unrecorded sales [TD] → **C, A**
3. Subsequent receipts / recoverability [TD] → **E, V**
4. ECL allowance IFRS 9 recompute [TD] → **V**
5. Cut-off sales & credit notes [TD] → **CO**
6. Credit balances / related-party, reclassify [TD] → **CL, V**
7. Vouch to invoice+contract+POD [TD] → **E, RO, A**
8. FX retranslation [TD] → **V**
9. Disclosure: aging / credit risk / related party [TD] → **P**
10. Credit & sales controls [TC] → **E, A**
11. Analytical: DSO, turnover, allowance ratio [AN] → **A, C**

### Prepayments & Other Receivables
1. Listing reconcile to GL [TD] → **C, E**
2. Agree top items to contract/invoice [TD] → **E, A, RO**
3. Recalculate amortization [TD] → **V, A, CO**
4. Supplier advances confirm + delivery [TD] → **E, RO**
5. Employee advances to HR + settlement [TD] → **E, RO**
6. Aging & recoverability impairment [TD] → **V**
7. Current/non-current classification [TD] → **CL**
8. Analytical vs prior + commitments [AN] → **A, C**
9. Post year-end utilization [TD] → **V, E**
10. Search unrecorded (completeness) [TD] → **C**
11. Disclosure (IAS 1) [TD] → **P**
12. Mgmt rep: existence/recoverability/classification [OT] → **E, V, CL**

### Inventory
1. Attend physical count (ISA 501) [TD] → **E, C**
2. Reconcile count to perpetual [TD] → **E, C, A**
3. Test cost (IAS 2) vouch to invoices [TD] → **V, A**
4. Net realizable value test [TD] → **V**
5. Costing method consistency, recompute [TD] → **V, A**
6. Overhead absorption (manufacturers) [TD] → **V, A**
7. Slow-moving / obsolete provision [TD] → **V**
8. Cut-off receipts/shipments [TD] → **CO, RO**
9. Goods in transit / consignment ownership [TD] → **RO, E**
10. Disclosure: categories (IAS 2) [TD] → **P, CL**
11. Analytical: turnover, margin [AN] → **A, C**
12. Reconcile sub-ledger to GL + search unrecorded [TD] → **C**

### PPE / Fixed Assets
1. Vouch additions, capitalized cost [TD] → **E, A, V, RO**
2. Disposals / retirements, gain/loss [TD] → **E, A, CO**
3. Recompute depreciation, useful lives [TD] → **V, A**
4. Existence physical inspection [TD] → **E**
5. Completeness register→GL, repairs vs capitalisation [TD] → **C, CL**
6. Impairment (IAS 36) [TD] → **V**
7. Rights & obligations — title deeds [TD] → **RO**
8. Revaluation model (if used) [TD] → **V**
9. Leases IFRS 16 ROU [TD] → **E, V, CL**
10. Assets under construction [TD] → **E, V**
11. Disclosure & classification, carrying reconciliation [TD] → **P, CL**
12. Analytical: depreciation ratio, additions vs budget [AN] → **A, C**

### Accounts Payable
1. Search for unrecorded liabilities (primary) [TD] → **C**
2. Reconcile supplier statements [TD] → **E, C, A**
3. Confirmations (selective) [TD] → **E, C**
4. Cut-off purchases / goods received [TD] → **CO**
5. Accruals & unbilled liabilities [TD] → **C, V**
6. Debit balances reclassify [TD] → **CL, V**
7. Related-party payables disclosure [TD] → **P, RO**
8. FX retranslation [TD] → **V**
9. Classification & disclosure trade/other [TD] → **CL, P**
10. Purchase-cycle controls (3-way match) [TC] → **C, A**
11. Analytical: payables turnover / DPO [AN] → **A, C**
12. Reconcile AP sub-ledger to GL [TD] → **C, A**

### Loans & Borrowings
1. Loan confirmations [TD] → **E, C, RO**
2. Agree opening + movements, recompute [TD] → **E, A**
3. Recompute interest & accrued [TD] → **A, V**
4. Covenant review, reclassify if breached [TD] → **CL, P**
5. Current/non-current classification [TD] → **CL**
6. Related-party / shareholder loans [TD] → **P, RO**
7. Pledged assets / guarantees [TD] → **RO, P**
8. Loan modification IFRS 9 (if any) [TD] → **V**
9. Disclosure: maturity analysis (IFRS 7) [TD] → **P**
10. Analytical: interest vs average debt [AN] → **A**
11. Search unrecorded borrowings [TD] → **C**

### Provisions & End-of-Service Benefits
1. HR schedule, reconcile headcount [TD] → **C, A**
2. Recalculate EoSB accrual [TD] → **V, A, C**
3. Verify basis (basic wage) [TD] → **A, V**
4. Sample joiners / leavers [TD] → **E, A, CO**
5. Legal counsel confirmations [TD] → **C, E**
6. Evaluate contingent classification IAS 37 [OT] → **CL, P**
7. Warranty / restructuring / onerous provisions [TD] → **V, C**
8. Review minutes for undisclosed claims [TD] → **C, P**
9. Analytical: EoSB movement [AN] → **A, C**
10. Current/non-current classification [TD] → **CL**
11. Disclosure IAS 37 reconciliation [TD] → **P**
12. Mgmt rep: completeness of provisions/contingencies [OT] → **C, P**

### Equity & Share Capital
1. Agree share capital to MOA/register [TD] → **E, A, RO**
2. Share movements to resolutions [TD] → **E, A, CO**
3. Equity-vs-liability classification IAS 32 [TD] → **CL, P**
4. Dividends to resolutions, distributable [TD] → **E, A, CL**
5. Reserves roll-forward [TD] → **A, C**
6. Statutory / legal reserve transfers [TD] → **A, C**
7. OCI items tie to source [TD] → **A, C**
8. Review minutes for unrecorded equity [TD] → **C**
9. SOCIE & equity disclosures [TD] → **P**
10. Prior-period errors / policy changes IAS 8 [TD] → **A, P**
11. Analytical: equity reconciliation [AN] → **A, C**

### Revenue
1. IFRS 15 five-step recognition [TD] → **E, A, CO**
2. Cut-off sales/deliveries (critical) [TD] → **CO**
3. ISA 240 fraud lens — improper recognition [TD] → **E, CO**
4. Vouch to contract+invoice+POD (occurrence) [TD] → **E**
5. Completeness: trace delivery→revenue [TD] → **C**
6. Deferred revenue / contract liabilities [TD] → **C, V, CO**
7. Variable consideration estimation [TD] → **A, V**
8. Bundled / multi-element allocation [TD] → **A**
9. Related-party revenue [TD] → **E, P**
10. Analytical: revenue vs prior/budget, margin [AN] → **A, C**
11. Disclosure IFRS 15 disaggregation [TD] → **P**
12. Revenue-cycle controls [TC] → **E, A**

### Cost of Sales
1. Analytical: gross margin by line [AN] → **A, C**
2. Cut-off shipments / goods received [TD] → **CO**
3. Sample COS to purchase invoices / GRNs [TD] → **E, A**
4. Landed cost of imported goods [TD] → **V, A**
5. Costing method consistency [OT] → **V, A**
6. Overhead absorption (manufacturers) [TD] → **V, A**
7. 3-way match controls [TC] → **E, A**
8. Monthly analytical: COS-to-revenue [AN] → **A, C**
9. Supplier confirmation / statement recon [TD] → **E, A**
10. FX purchases (IAS 21) [TD] → **A, V**
11. Reconcile COS to inventory movements + search unrecorded [TD] → **C**
12. Classification & disclosure of COS components [TD] → **CL, P**

### Payroll & HR
1. Sample payroll recalculation [TD] → **A, E**
2. Reconcile payroll register to GL [TD] → **C, A**
3. Vouch new hires / terminations [TD] → **E, CO**
4. Ghost-employee existence test (fraud) [TD] → **E**
5. Statutory contributions / withholdings [TD] → **A, C**
6. EoSB movement → provisions WP [TD] → **A, C**
7. Year-end accrued payroll & cut-off [TD] → **C, CO, V**
8. Director remuneration / KMP disclosure [TD] → **P, A**
9. Classification by function [TD] → **CL**
10. Payroll segregation controls [TC] → **E, A**
11. Analytical: cost per head, payroll-to-revenue [AN] → **A, C**
12. Disclosure: employee benefit expense / KMP [TD] → **P**

### Operating Expenses
1. Sample opex to supporting docs [TD] → **E, A**
2. Completeness: search unrecorded [TD] → **C**
3. Cut-off accrued / prepaid [TD] → **CO**
4. Recompute accruals / prepayments [TD] → **A, V, C**
5. Unusual / non-recurring, classification [TD] → **CL, E**
6. Related-party expenses [TD] → **E, P**
7. Classification by nature / function [TD] → **CL**
8. ISA 240 fraud lens — expenses [TD] → **E**
9. Expense-authorization controls [TC] → **E, A**
10. Analytical: opex vs prior/budget [AN] → **A, C**
11. Disclosure: expenses by nature/function [TD] → **P**

### Tax
1. Recompute current tax / Zakat provision [TD] → **A, V, C**
2. Deferred tax temporary differences [TD] → **V, A**
3. ETR reconciliation [TD] → **A, P**
4. VAT/GST reconcile (if applicable) [TD] → **A, C**
5. Tax admin / compliance, registration [TD] → **C, RO**
6. Agree tax payments to authority / bank [TD] → **E, A**
7. Outstanding assessments / uncertain positions IFRIC 23 [TD] → **C, V**
8. Withholding / transfer pricing (if any) [TD] → **A, C**
9. Classification & disclosure (IAS 12) [TD] → **CL, P**
10. Analytical: ETR vs statutory [AN] → **A**
11. Completeness over tax exposures [TD] → **C**

### Related Parties (ISA 550 — mostly process)
1. Document scope & risk tier [OT] → **—**
2. Management's complete list, verify completeness [TD] → **C**
3. Identify undisclosed related parties [TD] → **C**
4. Substantive procedures on material RP transactions [TD] → **E, A, RO**
5. Existence & recoverability of RP balances [TD] → **E, V, RO**
6. Significant-influence indicators, classification [TD] → **C, CL**
7. Review minutes for RP transactions [TD] → **C**
8. FS disclosures IAS 24 [OT] → **P**
9. Mgmt rep (ISA 550.26) [OT] → **C, P**
10. Document the conclusion [OT] → **—**

### Subsequent Events (ISA 560)
1. ISA 560.7 inquiry procedures [TD] → **C, CO**
2. Read post-year-end minutes [TD] → **C**
3. Review interim financials / management accounts [TD] → **C, CO**
4. Review post-year-end transactions [TD] → **C, CO**
5. Post-year-end developments on judgmental items [TD] → **V, C**
6. Classify adjusting vs non-adjusting (IAS 10) [TD] → **CL, P, CO**
7. Cross-reference GC & completion memo [OT] → **—**
8. Mgmt rep on subsequent events [OT] → **C, P**
9. Facts discovered after report date [OT] → **—**
10. Document the conclusion [OT] → **—**

### Going Concern (ISA 570 — see Perplexity Q3)
1. Document GC scope & risk tier [TD] → **—**
2. Financial indicators (ISA 570 Appendix) [TD] → **P**
3. Operating indicators [TD] → **P**
4. Other indicators [TD] → **P**
5. Recalculate cash-flow forecast + stress test [AN] → **V, P**
6. Loan covenants / maturity [TD] → **CL, P**
7. Related-party financial support [TD] → **P, V**
8. Post-balance-sheet events affecting GC [TD] → **P, CO**
9. Evaluate significant doubt / material uncertainty [OT] → **P**
10. Review GC disclosures [TD] → **P**
11. Document audit conclusion / opinion [OT] → **—**
12. Mgmt rep on GC [OT] → **P**
13. Analytical: trend ratios [AN] → **P, A**

### Journal Entry Testing (ISA 240.32 — mostly E/A/override)
1. Document JET scope & risk tier [OT] → **—**
2. Obtain GL JE listing, reconcile to TB [TD] → **C, A**
3. ISA 240.32(a) inquiries [TD] → **C**
4. Filter — end-of-period entries [TD] → **E, CO, A**
5. Filter — round-sum / repeating digits [TD] → **A, E**
6. Filter — unusual user entries [TD] → **E, A**
7. Filter — suspense / clearing / contra [TD] → **CL, A**
8. Filter — unrelated / seldom-used accounts [TD] → **E, CL**
9. Filter — vague / missing narratives [TD] → **E, A**
10. Filter — reversing entries [TD] → **E, CO**
11. Segregation-of-duties over JE [TC] → **E, A**
12. Document overall conclusion [OT] → **—**

### Out of Scope / Below Materiality
1. Document PM threshold (ISA 320) [OT] → **—**
2. Schedule accounts below PM, confirm aggregate [TD] → **C**
3. Document justification [OT] → **—**
4. Final review — no significant/sensitive item [OT] → **—**

---

## 6. Verification questions — Perplexity (ISA conformance)

1. **Existence vs Occurrence:** For a practical SME audit tool, is it acceptable to merge *existence* (balances) and *occurrence* (transactions) into one assertion chip, or should transaction-level procedures (revenue, expenses, JET) carry a distinct **Occurrence** assertion? Cite ISA 315 (Revised 2019) A190.
2. **Test-type taxonomy:** Do the four labels — Test of Controls (ISA 330.8), Test of Details (ISA 330.18), Substantive Analytical (ISA 520), Other/Risk-assessment — correctly and completely categorise the *nature* of procedures in an ISA audit file? Is "risk assessment procedures" (ISA 315.14: inquiry, observation/inspection, analytical) a category we should surface separately, or is folding them into "Other" acceptable for response-phase section work?
3. **Going Concern assertions:** GC procedures (ISA 570) mostly concern the *going-concern basis* and *material-uncertainty disclosure* rather than a single FS-line assertion. Is tagging GC procedures predominantly **Presentation & Disclosure** correct, or should they be treated as overall-FS-level (no assertion)? 
4. **Disclosure procedures → Presentation:** We tag disclosure-testing procedures with **Presentation & Disclosure (P)**. Confirm this aligns with the ISA 315 "presentation and disclosure" assertion category (occurrence/rights, completeness, classification & understandability, accuracy & valuation of disclosures), and whether we are over-simplifying by using a single P chip.
5. **Test-of-controls procedures → assertions:** We tag each test-of-controls procedure with the assertions the control *addresses* (e.g. revenue cycle controls → Existence/Occurrence + Accuracy). Is tagging a control test with assertions ISA-appropriate, or should ToC be assertion-agnostic (linked to the control objective rather than the assertion)?
6. **Process/conclusion steps untagged (—):** Scoping, mgmt-representation-only, and conclusion-documentation steps are left without an assertion. Acceptable per ISA, or should every procedure carry at least one assertion?
7. **Spot-checks — confirm or correct:** (a) Bank confirmations → E, RO, C; (b) AR ECL allowance → V only; (c) Inventory NRV → V; (d) Revenue cut-off → CO; (e) PPE title deeds → RO; (f) JET round-sum filter → A, E; (g) AP search for unrecorded liabilities → C; (h) Payroll ghost-employee test → E.

## 7. Verification questions — Copilot (schema / render)

- **C1.** `assertions text[] NOT NULL DEFAULT '{}'` on `audit_procedures` vs a junction table vs CSV text. Given we render chips, filter "procedures testing assertion X", and seed from templates — is `text[]` the right call? Any RLS/index concern (procedures inherit RLS via section)?
- **C2.** No DB CHECK on array element values (Postgres array-element enum constraint is awkward). UI restricts to the 8 codes. Acceptable, or worth a trigger/domain? 
- **C3.** Forward-only seeding leaves existing engagements' `audit_procedures` rows with `assertions = '{}'`. Confirm the render degrades gracefully (no chips) and propose a minimal one-off backfill approach if we later want to tag in-flight engagements.
- **C4.** Render parity: chips in `section.html` (editable multi-select) AND read-only in `report.html`. Confirm the multi-select edit pattern (vs the existing single `procedure_type` dropdown) won't fight the section-approval lock.

## 8. Closure checklist

- [x] Perplexity Q1–Q7 answered (vocabulary + GC + spot-checks)
- [x] Gemini answered (corroborated Perplexity; pushed FS-level tag + occurrence split)
- [x] Copilot C1–C4 answered — `text[]` + GIN + optional `<@` CHECK (included), forward-only safe, locking obeys section pattern
- [x] Mappings reconciled & corrected (occurrence added, fs_level added, type relabel, V→Valuation & Allocation)
- [x] **BUILT 2026-06-04** — migration `20260604130000_procedure_assertions.sql` (text[] + GIN + `<@` CHECK over 10 codes)
- [x] Templates seeded: `PROCEDURE_ASSERTIONS` in `audit-templates.js` (verified mappings); wired into both seed paths (seedSectionsForEngagement + engagement.html New Section modal)
- [x] `section.html`: read-only assertion chips in header + click-to-toggle editor in body; type badges relabelled (Test of Controls / Test of Details / Substantive Analytical / Risk Assessment·Admin)
- [x] `report.html`: assertion chips + relabelled type in the procedures table (render parity)
- [x] Migration applied to **prod** Supabase 2026-06-04 — feature LIVE on `main`
- [ ] **PENDING (user):** smoke test — new engagement shows tags; toggle assertions; approved section locks edit (chips read-only); PDF shows assertions
- [ ] User signs off

When migration applied + smoke test passes, **CLOSED**.
