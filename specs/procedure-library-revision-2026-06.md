# Procedure Library Revision — June 2026

Bringing the 12 "thin" section procedure templates up to the standard of the
6 "deep" ones (Going Concern, Related Parties, JET, Provisions, Prepayments,
Cost of Sales). Method: Claude proposes → Perplexity benchmarks (ISA + IFAC
SME guide, proportionate for SMPs) → reconcile → lock here → batch-apply to
`public/js/audit-templates.js` (staging) when all done. Forward-only: affects
NEW engagements only.

Status legend: ✅ locked · ⏳ in progress · ⬜ pending

## Targets (12)
1. ✅ Cash & Bank
2. ✅ Accounts Receivable
3. ✅ Inventory
4. ✅ PPE / Fixed Assets
5. ✅ Accounts Payable
6. ✅ Loans & Borrowings
7. ✅ Equity & Share Capital
8. ✅ Revenue
9. ✅ Payroll & HR
10. ✅ Operating Expenses
11. ✅ Tax
12. ✅ Subsequent Events

Skip (already strong): Going Concern, Related Parties, Journal Entry Testing,
Provisions & EoSB, Prepayments & Other Receivables, Cost of Sales.
Utility (fine): Out of Scope / Below Materiality.

---

## 1. Cash & Bank — ✅ LOCKED (Claude + Perplexity, IFAC-anchored)

1. Obtain external bank confirmations (ISA 505) for all accounts incl. those opened/closed during the year — balances, facilities/limits, security/liens/guarantees, authorized signatories; for non-replies perform alternatives (post-year-end statement + clearing review). — test_of_detail
2. For each material bank account, test the year-end reconciliation: agree balance to confirmation/statement and GL, recompute, and vouch reconciling items to source (ISA 500). — test_of_detail
3. Investigate reconciling items that are material or unusual (aged >30 days, round-sum, related-party) for window-dressing; resolve or document rationale (ISA 240). — test_of_detail
4. Inter-bank transfer (kiting) test for transfers around year-end: trace to both bank statements and GL to confirm same-period recording (ISA 240). — test_of_detail
5. Test cut-off of receipts/disbursements immediately before and after year-end against pre/post year-end statements and GL (ISA 500). — test_of_detail
6. Identify restricted/pledged cash, liens, and guarantees; confirm with the bank; verify restricted-vs-unrestricted and current/non-current classification + disclosure (IAS 1, IFRS 7). — test_of_detail
7. For foreign-currency balances, verify retranslation at the closing rate and recompute FX gain/loss (IAS 21). — test_of_detail
8. For overdrafts, verify offsetting only where a legal right of set-off and intent to settle net exist (IAS 32); otherwise present gross. — test_of_detail
9. Verify composition and disclosure of cash & cash equivalents (IAS 7): equivalents meet the short-term/highly-liquid/insignificant-risk definition; check maturities, restrictions, and statement-of-cash-flows classification. — test_of_detail
10. Identify related-party bank balances/facilities and any undrawn facilities/contingent liabilities; verify recognition and disclosure (IAS 24, IFRS 7). — test_of_detail
11. If relying on controls, test key cash-disbursement controls — authorization limits, segregation of initiation/approval/reconciliation, online-banking access — by inquiry, inspection, and reperformance of a small sample (ISA 315/330). — controls
12. Perform analytical procedures: interest income vs average balances and bank charges vs prior period; investigate significant variances (ISA 520). — analytical

Note: procedures 6–10 are conditional (no FX / no overdraft / no restricted cash / no related-party accounts → mark N/A), keeping the set proportionate for simple SMEs.

---

## 2. Accounts Receivable — ✅ LOCKED (Claude + Perplexity, IFAC-anchored)

1. Send positive confirmations (ISA 505) to a sample including large, old, disputed, and related-party balances; for non-replies, perform alternatives — trace subsequent cash receipts to bank statements and vouch to invoice + contract/PO + proof of delivery/acceptance. — test_of_detail
2. Reconcile the AR sub-ledger to the GL/trial balance and perform a search for unrecorded sales via review of post-year-end cash receipts and credit notes (completeness). — test_of_detail
3. Review subsequent cash receipts for year-end balances: trace to bank statements, match to specific invoices, and assess recoverability of unresolved/disputed amounts. — test_of_detail
4. Obtain aging analysis; test the ECL allowance under IFRS 9 using a practical provision-matrix approach for SMEs (historical loss rates + limited forward-looking adjustment), plus specific provisions on disputed/long-overdue accounts; recompute. — test_of_detail
5. Test cut-off of sales and credit notes immediately before/after year-end against delivery evidence (GRN, shipping, customer acceptance), consistent with IFRS 15. — test_of_detail
6. Investigate credit balances, long-overdue, and related-party/owner receivables: assess recoverability and IFRS 9 impact, and reclassify credit balances to trade payables where settlement is not expected via goods/services. — test_of_detail
7. Vouch a sample to invoice + customer contract/PO + proof of delivery/acceptance to confirm existence, rights & obligations, and accuracy under IFRS 15. — test_of_detail
8. For foreign-currency receivables, verify retranslation at the closing rate and recompute FX gain/loss (IAS 21). — test_of_detail
9. Test disclosure: aging by credit-risk bucket, credit-risk concentration, related-party receivables, current/non-current split, collateral/security held, and significant credit concessions (IAS 1, IFRS 7, IAS 24). — test_of_detail
10. If relying on controls, test key credit-and-sales controls — credit approval, invoicing, segregation of duties, cash application — by inquiry, inspection, and reperformance of a sample (ISA 315/330). — controls
11. Perform analytical procedures: DSO, receivables turnover, and allowance-to-receivables ratio vs prior period and budget; investigate significant variances (ISA 520). — analytical

Note: procedures 6 (related-party), 8 (FX), and 10 (controls) are conditional → mark N/A where not applicable.

---

## 3. Inventory — ✅ LOCKED (Claude + Perplexity, IFAC-anchored)

1. Attend the physical inventory count (ISA 501): observe management's count, perform two-way test counts (floor-to-sheet and sheet-to-floor), record cut-off (last GRN/GDN numbers), and evaluate count instructions/controls; if not at year-end, perform roll-forward/roll-back. — test_of_detail
2. Reconcile physical count quantities to perpetual/book records; investigate and resolve material variances; review system controls and assess reliability of perpetual records for future reliance (ISA 500). — test_of_detail
3. Test inventory cost (IAS 2): vouch a sample to recent purchase invoices including landed costs (freight, duty, clearing); for finished goods test the cost build-up (materials, labour, overhead). — test_of_detail
4. Test net realizable value (IAS 2): compare cost to post-year-end selling prices less costs to complete/sell; recognize write-downs where NRV < cost. — test_of_detail
5. Verify costing method (FIFO / weighted average) is consistent with policy and prior period; recompute for a sample (IAS 2). — test_of_detail
6. (Manufacturers only) Recompute production overhead absorption — overheads only, normal-capacity basis; exclude abnormal waste, admin, and selling costs (IAS 2). — test_of_detail
7. Identify slow-moving/obsolete/damaged inventory via aging and sales pipeline; test adequacy of the obsolescence/NRV provision against historical loss rates, current orders, and forward sales; ensure write-downs where appropriate. — test_of_detail
8. Test cut-off of receipts/shipments around year-end by tracing last GRNs/GDNs to records and assessing ownership (FOB terms) and correct period (IAS 2). — test_of_detail
9. For goods in transit / consignment / third-party-held inventory: verify ownership (rights) and correct inclusion/exclusion; confirm third-party-held stock with the custodian (ISA 501). — test_of_detail
10. Test disclosure: categories (raw materials/WIP/finished goods), carrying amount, cost formula, write-downs recognized/reversed, inventory pledged as security, and inventory recognized as expense (IAS 2, IAS 1). — test_of_detail
11. Perform analytical procedures: inventory turnover, days in inventory, gross margin vs prior period and budget; investigate variances (ISA 520). — analytical
12. Reconcile inventory sub-ledger to GL and search for unrecorded movements via post-year-end GRNs/GDNs and production reports (completeness, ISA 500). — test_of_detail

Note: procedures 6 (manufacturers) and 9 (consignment/third-party) are conditional → mark N/A for simple traders.

---

## 4. PPE / Fixed Assets — ✅ LOCKED (Claude + Perplexity, IFAC-anchored)

1. Vouch additions to invoices/contracts; verify capitalized cost = purchase price + directly attributable costs + borrowing costs (if a qualifying asset per IAS 23); confirm application of the capitalization threshold and policy (IAS 16). — test_of_detail
2. Test disposals/retirements: remove from register, trace proceeds to bank, recompute gain/loss, confirm derecognition (IAS 16). — test_of_detail
3. Recompute depreciation for a sample; assess useful lives, residual values, and method for appropriateness/consistency; confirm depreciation begins when available for use; verify componentization for significant parts with different useful lives (IAS 16). — test_of_detail
4. Existence: physically inspect a sample of significant assets and reconcile to the fixed-asset register (ISA 500). — test_of_detail
5. Completeness: reconcile the fixed-asset register to GL; test a sample of repairs/maintenance above the capitalization threshold for proper expensing vs capitalization (IAS 16). — test_of_detail
6. Impairment (IAS 36): review indicators (idle, obsolete, damaged, market decline, restructuring); where present, test management's recoverable-amount/impairment assessment; otherwise document that no indicators exist. — test_of_detail
7. Rights & obligations: verify title deeds (property) and registration (vehicles); confirm assets pledged as security with lenders where needed and test disclosure (IAS 16). — test_of_detail
8. (If revaluation model) Assess valuer competence/independence and valuation date; verify recognition in OCI/revaluation surplus and disclosure (IAS 16). — test_of_detail
9. (If leases — IFRS 16) Verify right-of-use assets and lease liabilities, their depreciation and interest unwind, or confirm short-term/low-value exemptions (IFRS 16). — test_of_detail
10. (If assets under construction) Verify existence and progress (site visits, contractor reports) and test capitalized costs for eligibility (IAS 16, IAS 23). — test_of_detail
11. Disclosure & classification: carrying-amount reconciliation (cost, additions, disposals, depreciation, impairment), methods/useful lives, pledged assets, capital commitments, CIP, restrictions on title; verify PPE category split (land/buildings/plant/vehicles/etc.) and current/non-current classification (IAS 16, IAS 1). — test_of_detail
12. Analytical: depreciation-to-cost ratio, additions vs capex budget, repairs trend; investigate significant variances (ISA 520). — analytical

Note: procedures 8 (revaluation), 9 (IFRS 16 leases), 10 (CIP) are conditional → mark N/A where not applicable.

---

## 5. Accounts Payable — ✅ LOCKED (Claude + Perplexity, IFAC-anchored)

Liability focus = completeness/understatement risk. (Perplexity's IAS 37 "test provisions" item dropped here — already covered by the dedicated Provisions & EoSB section; avoid duplication.)

1. Search for unrecorded liabilities (primary completeness test): review post-year-end payments, unmatched GRNs/POs, and supplier invoices/statements received after year-end; trace to the correct period (ISA 500). — test_of_detail
2. Reconcile supplier statements to the AP ledger for major/active suppliers, including suppliers with low/nil recorded balances but prior activity; investigate and resolve differences (ISA 500). — test_of_detail
3. Use confirmations (ISA 505) selectively for major suppliers without statements, disputed balances, or related-party payables; non-replies → alternatives (subsequent payment, supplier statement). — test_of_detail
4. Test cut-off of purchases/goods received immediately before/after year-end by tracing to GRN/invoice dates; correct period (ISA 500). — test_of_detail
5. Test accruals and unbilled liabilities (utilities, rent, bonuses, professional fees, taxes) for completeness and measurement: vouch to contracts and subsequent invoices; recompute key accruals (ISA 500). — test_of_detail
6. Investigate debit balances in AP; reclassify to receivables where recoverable from suppliers, or to prepayments where they relate to future goods/services; assess recoverability (IAS 1). — test_of_detail
7. Identify related-party payables; confirm terms, assess arm's-length nature, and test disclosure (IAS 24). — test_of_detail
8. For foreign-currency payables, verify retranslation at the closing rate and recompute FX gain/loss (IAS 21). — test_of_detail
9. Test classification & disclosure: trade vs other payables, current/non-current split, related-party payables, credit terms, credit-risk concentrations, and contingent liabilities/commitments (IAS 1, IFRS 7, IAS 24). — test_of_detail
10. If relying on controls, test key purchase-cycle controls: purchase authorization, 3-way match (PO/GRN/invoice), segregation — inquiry/inspection/reperformance of a sample (ISA 315/330). — controls
11. Analytical: payables turnover / DPO and AP-to-purchases ratio vs prior period; investigate significant variances (ISA 520). — analytical
12. Reconcile the AP sub-ledger to GL and investigate unreconciled differences (ISA 500). — test_of_detail

Note: procedures 7 (related-party), 8 (FX), 10 (controls) are conditional → mark N/A where not applicable.

---

## 6. Loans & Borrowings — ✅ LOCKED (Claude + Perplexity, IFAC-anchored)

1. Obtain loan confirmations (ISA 505) from all lenders — principal, rate, maturity, security, covenants, undrawn facilities; non-replies → loan agreements + bank statements. — test_of_detail
2. Agree opening balance + movements (drawdowns/repayments) to loan agreements and bank statements; recompute closing balance (ISA 500). — test_of_detail
3. Recompute interest expense and accrued interest using agreement rates and outstanding principal; reconcile to cash payments; verify capitalized borrowing costs (IAS 23) and effective-interest measurement for material loans (IFRS 9) — reasonableness check for simple SME loans. — test_of_detail
4. Review loan agreements for covenant terms; recalculate compliance ratios at year-end; where breached, verify an unconditional waiver was obtained BEFORE year-end — if not, reclassify to current per IAS 1.74. — test_of_detail
5. Verify current vs non-current classification on contractual maturity and any repayable-on-demand / breach-of-covenant terms (IAS 1.73–76). — test_of_detail
6. Identify related-party / shareholder loans; confirm terms, assess arm's-length nature and interest, evaluate recoverability of director loans (and whether effectively equity), and test disclosure (IAS 24). — test_of_detail
7. Confirm pledged assets/guarantees; cross-reference to pledged PPE/cash; test disclosure of security (IFRS 7). — test_of_detail
8. (If loan modified/refinanced) Assess whether the modification is substantial → modification vs derecognition accounting (IFRS 9). — test_of_detail
9. Test disclosure: maturity analysis by contractual remaining-maturity buckets, effective vs nominal rates, security details, covenant terms, defaults/breaches, and fair value hierarchy where required (IFRS 7, IAS 1). — test_of_detail
10. Analytical: interest expense vs average debt (effective-rate reasonableness); debt movement vs cash flow; investigate variances (ISA 520). — analytical
11. Search for unrecorded borrowings: review post-year-end payments, board minutes, and bank statements for interest payments to unknown lenders; confirm all borrowings are recorded (completeness, ISA 500). — test_of_detail

Note: procedures 3 (borrowing-cost/EIR depth), 6 (related-party), 8 (modification) are conditional → mark N/A where not applicable.

---

## 7. Equity & Share Capital — ✅ LOCKED (Claude + Perplexity, IFAC-anchored)

1. Agree share capital (authorized / issued / paid-up) — number of shares, par value, total — to MOA/AOA, share register, trade/commercial-registry filings, and prior-year FS; verify any changes were duly filed (IAS 1, ISA 500). — test_of_detail
2. Test share movements (issues, buy-backs, transfers) to board/shareholder resolutions and certificates; trace consideration to bank; verify allocation between share capital and share premium (IAS 32). — test_of_detail
3. (Conditional — only where such instruments exist) Assess equity-vs-liability classification under IAS 32 (substance over form) for redeemable/puttable preference shares, mandatorily-distributable instruments, or shareholder loans presented as equity. — test_of_detail
4. Dividends: agree declared/paid to resolutions; verify within distributable reserves and legal limits, correct period, and withholding-tax treatment (IAS 1). — test_of_detail
5. For each reserve (retained earnings, revaluation, FX, statutory/legal, other), confirm composition and recompute roll-forward from opening to closing (P&L, OCI, owner transactions, transfers) (IAS 1). — test_of_detail
6. Where local company law requires, test statutory/legal reserve transfers (common across MENA — e.g., a required percentage of annual profit transferred to a statutory reserve up to a capped proportion of capital): recompute the required transfer and verify posting (IAS 1 / applicable local law). — test_of_detail
7. (Conditional — only if OCI items exist) Tie OCI-routed reserve movements (revaluation surplus, FX translation) back to their source sections and working papers (IAS 1, IAS 16). — test_of_detail
8. Review board/shareholder minutes for unrecorded equity transactions, capital commitments, and guarantees affecting equity classification/disclosure (ISA 500). — test_of_detail
9. Test SOCIE and equity disclosures (IAS 1): each component reconciles opening→closing; notes disclose share-capital details, dividends, nature/purpose of each reserve, capital management, and restrictions on distribution. — test_of_detail
10. (Conditional — prior-period errors/policy changes) Verify retrospective IAS 8 adjustments affecting equity are correctly presented in SOCIE and notes (IAS 8, IAS 1). — test_of_detail
11. Analytical reconciliation of equity: opening + P&L − dividends ± OCI ± capital movements = closing; agree to TB and SOCIE (ISA 520). — analytical

Note: procedures 3 (special instruments), 7 (OCI), 10 (IAS 8 errors) are conditional → mark N/A for plain share-capital equity.

---

## 8. Revenue — ✅ LOCKED (Claude + Perplexity, IFAC-anchored) — ISA 240 fraud-presumed area

1. For a risk-based sample of contracts, test recognition against the IFRS 15 five-step model (contract → performance obligations → transaction price → allocation → recognition); verify point-in-time vs over-time and control-transfer evidence (IFRS 15, ISA 500). — test_of_detail
2. Cut-off (critical): test sales/deliveries just before/after year-end to shipping/delivery/acceptance evidence; correct period when control transfers (IFRS 15, ISA 500). — test_of_detail
3. Apply ISA 240 fraud lens: test for improper recognition (channel-stuffing, bill-and-hold, side agreements, premature/fictitious sales); examine large/unusual/period-end entries; review post-year-end credit notes/reversals as overstatement indicators (ISA 240, ISA 500). — test_of_detail
4. Vouch a sample to contract + invoice + proof of delivery/acceptance (occurrence, ISA 500). — test_of_detail
5. Completeness: trace delivery docs/contracts to recorded revenue; reconcile revenue to cash receipts + receivables movement; search for unrecorded sales via post-year-end cash and credit notes (ISA 500). — test_of_detail
6. Test deferred revenue / contract liabilities: existence, measurement, and release timing per IFRS 15. — test_of_detail
7. (If variable consideration) Test estimation and the constraint for discounts, rebates, returns, volume bonuses (IFRS 15) — practical/historical basis for SMEs. — test_of_detail
8. (If bundled/multi-element) Test transaction-price allocation across distinct performance obligations (IFRS 15). — test_of_detail
9. (If related-party revenue) Same recognition policy as third-party, arm's-length terms, disclosure (IFRS 15, IAS 24). — test_of_detail
10. Analytical: revenue vs prior/budget/external indicators; gross margin by line; monthly trends for period-end spikes; investigate variances (ISA 520). — analytical
11. Test disclosure per IFRS 15: disaggregation (category/segment/timing), performance obligations, contract balances (receivables, contract assets, contract liabilities), and significant judgments. — test_of_detail
12. (If relying on controls) Test invoice authorization, pricing/master-data changes, credit-note approval, segregation — inquiry/inspection/reperformance (ISA 315/330). — controls

Note: procedures 7, 8, 9, 12 are conditional → mark N/A where not applicable.

---

## 9. Payroll & HR — ✅ LOCKED (Claude + Perplexity, IFAC-anchored)

EoSB liability recalculation lives in the Provisions & EoSB section — Payroll references it (no duplication).

1. Test a sample of payroll calculations: recalculate gross pay (contracts/approved rates), statutory + voluntary deductions, employer contributions, net pay; agree to payslips and bank payments (and any statutory wage-protection system, where applicable in the jurisdiction) (IAS 19, ISA 500). — test_of_detail
2. Reconcile payroll register to GL and bank payments; reconcile monthly payroll cost to TB; investigate variances (ISA 500). — test_of_detail
3. Vouch new hires and terminations to HR records/contracts; verify payroll additions/removals in the correct period. — test_of_detail
4. Ghost-employee / existence test (ISA 240 fraud lens): sample employees, verify existence via HR file + ID, review for duplicate bank accounts/IDs; risk-based focus on large/high-risk payrolls. — test_of_detail
5. Test statutory contributions/withholdings (social security/pension, statutory wage-protection filings, and payroll-related taxes/withholdings as applicable in the entity's jurisdiction): recalculate, agree to payments, verify filings. — test_of_detail
6. End-of-service benefits: agree the payroll-side movement to the Provisions & EoSB working paper (detailed recalc performed there). — test_of_detail
7. Year-end accrued payroll & cut-off: accrued salaries, annual leave, bonuses, and commissions — test completeness/measurement, approval basis, and correct period (IAS 19). — test_of_detail
8. Management/director remuneration: verify authorization (board/contract), completeness, and KMP disclosure (IAS 24). — test_of_detail
9. Classification: payroll cost allocated correctly by function (COGS / SG&A / production overheads) per IAS 1. — test_of_detail
10. (If relying on controls) Segregation of HR master-data / payroll prep / payment authorization, master-data change controls, and payment/bank-file approval — inquiry/inspection/reperformance (ISA 315/330). — controls
11. Analytical: average cost per head, payroll-to-revenue ratio, headcount trend vs prior; investigate variances (ISA 520). — analytical
12. Test disclosure: total employee benefit expense and KMP compensation (short-term, post-employment, termination benefits) per IAS 24 and IAS 1. — test_of_detail

Note: procedure 10 (controls) is conditional → mark N/A where not relied upon.

---

## 10. Operating Expenses — ✅ LOCKED (Claude + Perplexity, IFAC-anchored)

(Perplexity's standalone "test prepayments" item dropped here — covered by the dedicated Prepayments & Other Receivables section; the expense-side accrued/prepaid cut-off in #3–4 stays.)

1. Test a sample of operating expenses to supporting docs (invoice, approval, GRN/service evidence); verify occurrence and accuracy (ISA 500). — test_of_detail
2. Completeness: search for unrecorded expenses (post-year-end invoices, missing accruals); reconcile expenses to AP/accruals; review recurring expenses for missing months (ISA 500). — test_of_detail
3. Cut-off: test accrued and prepaid expenses at year-end (rent, utilities, insurance, professional fees, subscriptions) for correct period (IAS 1, ISA 500). — test_of_detail
4. Recompute key accruals/prepayments for completeness and measurement (IAS 1, ISA 500). — test_of_detail
5. Review unusual/non-recurring/one-off expenses; obtain explanations; assess classification (operating vs exceptional) per IAS 1 — risk-based (large/unusual/period-end). — test_of_detail
6. (If related-party expenses) Test management/professional/related-party fees for arm's-length terms, authorization, and disclosure (IAS 24). — test_of_detail
7. Classification by nature/function per IAS 1; ensure capital items aren't expensed (tie to PPE) and vice versa (IAS 16). — test_of_detail
8. ISA 240 fraud lens: expenses with override/fraud indicators (round-sum, unusual payees, related parties); tie to Journal Entry Testing. — test_of_detail
9. (If relying on controls) Test expense authorization limits, approval workflow, segregation — inquiry/inspection/reperformance (ISA 315/330). — controls
10. Analytical (primary for routine opex): opex by category vs prior/budget; expense-to-revenue ratios; investigate variances (ISA 520). — analytical
11. Test disclosure: expenses by nature/function, auditor remuneration, related-party expenses (IAS 1, IAS 24). — test_of_detail

Note: procedures 6 (related-party), 9 (controls) are conditional → mark N/A where not applicable.

---

## 11. Tax — ✅ LOCKED (Claude + Perplexity, IFAC-anchored) — MENA-agnostic

IMPORTANT: jurisdiction-agnostic. Perplexity re-inserted UAE-specific rates (0%/AED 375k/FTA) — genericized out. No single-country rates, thresholds, or authority names in the procedures.

1. Recompute the current tax/Zakat provision: reconcile accounting profit to taxable base (add-backs/deductions such as non-deductible expenses and tax-exempt income) under the applicable corporate income tax (or Zakat) regime in the entity's jurisdiction, applying that regime's rate(s)/threshold(s); agree to the tax computation. For Zakat-liable entities, verify the correct CT-vs-Zakat regime selection and that Zakat is accounted for appropriately (as a distribution/equity or as an expense) per local law (IAS 12). — test_of_detail
2. Deferred tax: identify material temporary differences (depreciation vs tax base, provisions, EoSB, tax losses); apply the enacted/substantively-enacted rate; assess recoverability of deferred tax assets against future taxable profits (IAS 12). — test_of_detail
3. Effective-tax-rate reconciliation: tax expense vs PBT × applicable statutory rate; investigate unusual reconciling items; disclose per IAS 12 (abridged/grouped acceptable for simple SMEs). — test_of_detail
4. (If indirect tax applies) VAT/GST: reconcile output/input to ledgers; agree payments/refunds to the tax authority and bank; assess exposure on late/unfiled returns. — test_of_detail
5. (Conditional) Tax administration/compliance: verify registration, filing, available reliefs/elections, exempt income, and special regimes (e.g., free-zone/qualifying-entity status) under the applicable jurisdiction's law. — test_of_detail
6. Agree tax payments/refunds (income tax + indirect tax) to tax-authority correspondence/portal and bank statements. — test_of_detail
7. Review outstanding assessments, audits, disputes, penalties; assess provisions/contingencies and uncertain tax positions per IFRIC 23 (most-likely-amount vs expected-value) and IAS 37. — test_of_detail
8. (If cross-border/related-party) Test withholding tax and transfer-pricing compliance and any related deferred-tax/uncertain positions (IAS 24, applicable local law). — test_of_detail
9. Classification & disclosure (IAS 12, IAS 1): current/deferred split, components of tax expense (current, deferred, prior-period adjustments), ETR reconciliation, unused losses/credits, unrecognized DTAs, uncertain positions. — test_of_detail
10. Analytical: ETR vs applicable statutory rate and prior period; tax-to-PBT trend; investigate variances (ISA 520). — analytical
11. Completeness over tax exposures: review legal letters, significant contracts, and board minutes for tax clauses/assessments/restructurings that may create provisions or uncertain positions (IFRIC 23 / IAS 37, ISA 500). — test_of_detail

Note: procedures 4 (indirect tax), 5 (special regimes), 8 (WHT/TP) are conditional → mark N/A where not applicable.

---

## 12. Subsequent Events — ✅ LOCKED (Claude + Perplexity, IFAC-anchored)

Execution-side ISA 560 program (GC post-balance-sheet review stays in the GC section; ISA 560 datum stays in the completion memo — no duplication).

1. Perform ISA 560.7 procedures through the auditor's report date: inquire of management and TCWG about post-reporting-date events and understand their identification procedures (ISA 560, ISA 500). — test_of_detail
2. Read minutes of shareholder/director/committee meetings held after year-end; inquire on matters where minutes aren't yet available (ISA 560). — test_of_detail
3. Review the latest post-year-end interim financials / management accounts and budgets for significant changes in revenue, margins, liquidity, borrowings, litigation, or other events affecting year-end assertions (ISA 560). — test_of_detail
4. Review post-year-end transactions (cash, sales/purchases, credit notes, new borrowings) for evidence of year-end or new conditions affecting the FS (ISA 560) — material transactions for low-risk SMEs. — test_of_detail
5. Review post-year-end developments on judgmental items (litigation, claims, asset values, impairments); update legal confirmations where needed and reassess provisions/contingencies (ISA 560, IAS 37). — test_of_detail
6. Classify each event as adjusting vs non-adjusting (IAS 10); verify adjusting events are reflected in the FS and material non-adjusting events are disclosed with nature + estimated effect (or a statement it cannot be estimated). — test_of_detail
7. Cross-reference subsequent-events findings affecting going concern (update the GC assessment through report date and, where relevant, 12 months from the statement date per ISA 570) and the completion memo (ISA 560 datum). — other
8. Obtain written management representation that all subsequent events requiring adjustment or disclosure have been properly handled (ISA 560.9 / ISA 580). — other
9. (If facts discovered after the report date — ISA 560.10–17) Document procedures and response (discuss with management, consider amending report/FS). — other
10. Document the conclusion: period covered (through report date), events identified, treatment (adjust / deny adjustment / disclose), and cross-references to disclosures, going concern, and opinion (ISA 230). — other

Note: procedure 9 (facts after report date) is conditional → only when triggered.

---

## ALL 12 LOCKED ✅ — ready to batch into public/js/audit-templates.js (forward-only; new engagements only).

---

## Deep-section verification pass (2026-06-02)
Benchmarking the 6 "already strong" sections too, to be thorough (the partner's GC feedback prompted it).

### Going Concern — ✅ verified strong + 2 small additions
Perplexity confirmed the existing 11 procedures are lean/proportionate (its final set mirrored the current one). Two genuine additions applied:
- NEW procedure: where GC relies on **related-party/shareholder/parent financial support** (common in owner-managed SMEs), obtain + evaluate the support (letter of financial support), assess the supporter's ability/intent/enforceability, and disclose (ISA 570/550, IAS 24). Real gap — added.
- ENHANCED disclosure procedure to include **IAS 1.122/136-137 significant-judgments** disclosure on close-call GC conclusions.
GC now 12 procedures. Applied directly to audit-templates.js (staging).

### Related Parties — ✅ verified strong, NO change needed
Perplexity's final set mirrored the current 10 exactly; every suggested "add" (group-package reconciliation, KMP per IAS 24.9/24.17, parent/ultimate controller 24.13, RP-support-for-GC) is already present. No edit.

### Pending verification: Journal Entry Testing, Provisions & EoSB, Prepayments & Other Receivables, Cost of Sales.
