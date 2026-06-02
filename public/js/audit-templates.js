// Shared audit-section templates and engagement seeding.
//
// Used by:
//   - public/pages/dashboard.html — seedSectionsForEngagement() is called
//     right after a new engagement is inserted, so the auditor lands on a
//     pre-populated engagement page.
//   - public/pages/engagement.html — PROCEDURE_TEMPLATES is referenced by
//     the New Section modal to auto-populate procedures when an auditor
//     creates a section using one of the standard templates.
//
// Globals exposed: PROCEDURE_TEMPLATES, SECTION_SEED_ORDER,
//                  seedSectionsForEngagement.

// Forward-only seeding: edits to this map affect ONLY new engagements
// created after the change is deployed. Existing engagements already have
// their audit_procedures rows persisted in the database and are NOT
// retroactively updated. If we ever need to upgrade procedures across
// existing engagements (e.g., a regulatory rewrite), do it via an explicit
// migration or an in-app "refresh procedures" tool — not by relying on
// this template.
const PROCEDURE_TEMPLATES = {
  // ---------- Balance Sheet — Assets ----------
  'Cash & Bank': [
    { description: 'Obtain external bank confirmations (ISA 505) for all accounts including those opened or closed during the year — balances, facilities/limits, security/liens/guarantees, and authorized signatories; for non-replies perform alternatives (post-year-end statement + clearing review)', type: 'test_of_detail' },
    { description: 'For each material bank account, test the year-end reconciliation: agree balance to the confirmation/statement and GL, recompute, and vouch reconciling items to source (ISA 500)', type: 'test_of_detail' },
    { description: 'Investigate reconciling items that are material or unusual (aged over 30 days, round-sum, related-party) for window-dressing; resolve or document rationale (ISA 240)', type: 'test_of_detail' },
    { description: 'Inter-bank transfer (kiting) test for transfers around year-end: trace to both bank statements and GL to confirm same-period recording (ISA 240)', type: 'test_of_detail' },
    { description: 'Test cut-off of receipts/disbursements immediately before and after year-end against pre/post year-end statements and GL (ISA 500)', type: 'test_of_detail' },
    { description: 'Identify restricted/pledged cash, liens, and guarantees; confirm with the bank; verify restricted-vs-unrestricted and current/non-current classification and disclosure (IAS 1, IFRS 7)', type: 'test_of_detail' },
    { description: 'For foreign-currency balances, verify retranslation at the closing rate and recompute FX gain/loss (IAS 21)', type: 'test_of_detail' },
    { description: 'For overdrafts, verify offsetting only where a legal right of set-off and intent to settle net exist (IAS 32); otherwise present gross', type: 'test_of_detail' },
    { description: 'Verify composition and disclosure of cash and cash equivalents (IAS 7): equivalents meet the short-term/highly-liquid/insignificant-risk definition; check maturities, restrictions, and statement-of-cash-flows classification', type: 'test_of_detail' },
    { description: 'Identify related-party bank balances/facilities and any undrawn facilities/contingent liabilities; verify recognition and disclosure (IAS 24, IFRS 7)', type: 'test_of_detail' },
    { description: 'If relying on controls, test key cash-disbursement controls — authorization limits, segregation of initiation/approval/reconciliation, online-banking access — by inquiry, inspection, and reperformance of a small sample (ISA 315/330)', type: 'controls' },
    { description: 'Perform analytical procedures: interest income vs average balances and bank charges vs prior period; investigate significant variances (ISA 520)', type: 'analytical' },
  ],
  'Accounts Receivable': [
    { description: 'Send positive confirmations (ISA 505) to a sample including large, old, disputed, and related-party balances; for non-replies perform alternatives — trace subsequent cash receipts to bank statements and vouch to invoice + contract/PO + proof of delivery/acceptance', type: 'test_of_detail' },
    { description: 'Reconcile the AR sub-ledger to the GL/trial balance and perform a search for unrecorded sales via review of post-year-end cash receipts and credit notes (completeness)', type: 'test_of_detail' },
    { description: 'Review subsequent cash receipts for year-end balances: trace to bank statements, match to specific invoices, and assess recoverability of unresolved/disputed amounts', type: 'test_of_detail' },
    { description: 'Obtain aging analysis; test the ECL allowance under IFRS 9 using a practical provision-matrix approach for SMEs (historical loss rates + limited forward-looking adjustment), plus specific provisions on disputed/long-overdue accounts; recompute', type: 'test_of_detail' },
    { description: 'Test cut-off of sales and credit notes immediately before/after year-end against delivery evidence (GRN, shipping, customer acceptance), consistent with IFRS 15', type: 'test_of_detail' },
    { description: 'Investigate credit balances, long-overdue, and related-party/owner receivables: assess recoverability and IFRS 9 impact, and reclassify credit balances to trade payables where settlement is not expected via goods/services', type: 'test_of_detail' },
    { description: 'Vouch a sample to invoice + customer contract/PO + proof of delivery/acceptance to confirm existence, rights and obligations, and accuracy under IFRS 15', type: 'test_of_detail' },
    { description: 'For foreign-currency receivables, verify retranslation at the closing rate and recompute FX gain/loss (IAS 21)', type: 'test_of_detail' },
    { description: 'Test disclosure: aging by credit-risk bucket, credit-risk concentration, related-party receivables, current/non-current split, collateral/security held, and significant credit concessions (IAS 1, IFRS 7, IAS 24)', type: 'test_of_detail' },
    { description: 'If relying on controls, test key credit-and-sales controls — credit approval, invoicing, segregation of duties, cash application — by inquiry, inspection, and reperformance of a sample (ISA 315/330)', type: 'controls' },
    { description: 'Perform analytical procedures: DSO, receivables turnover, and allowance-to-receivables ratio vs prior period and budget; investigate significant variances (ISA 520)', type: 'analytical' },
  ],
  'Prepayments & Other Receivables': [
    { description: 'Obtain detailed listing of prepayments and other receivables; reconcile to general ledger and trial balance', type: 'test_of_detail' },
    { description: 'For top items by value, agree balance to underlying contract, invoice, or agreement', type: 'test_of_detail' },
    { description: 'Recalculate prepaid expense amortization — verify portion released to P&L corresponds to contract period (e.g., prepaid rent, insurance, software licenses)', type: 'test_of_detail' },
    { description: 'For supplier advances, send confirmation to counterparty and verify expected delivery or service performance post year-end', type: 'test_of_detail' },
    { description: 'For employee advances, agree to HR records and advance agreements; verify post-year-end settlement via payroll deduction or repayment', type: 'test_of_detail' },
    { description: 'Review aging of advances and refundable deposits; assess recoverability of overdue or stale items and consider impairment under IFRS 9', type: 'test_of_detail' },
    { description: 'Verify classification between current and non-current based on expected recovery period per IAS 1', type: 'test_of_detail' },
    { description: 'Perform analytical review of prepayment balance vs prior period and known contracted commitments', type: 'analytical' },
    { description: 'Review post year-end utilization — confirm prepayments are consumed against valid services or written off if expired', type: 'test_of_detail' },
    { description: 'Obtain management representation on existence, recoverability, and classification of other receivables', type: 'other' },
  ],
  'Inventory': [
    { description: 'Attend the physical inventory count (ISA 501): observe management\'s count, perform two-way test counts (floor-to-sheet and sheet-to-floor), record cut-off (last GRN/GDN numbers), and evaluate count instructions/controls; if not at year-end, perform roll-forward/roll-back', type: 'test_of_detail' },
    { description: 'Reconcile physical count quantities to perpetual/book records; investigate and resolve material variances; review system controls and assess reliability of perpetual records for future reliance (ISA 500)', type: 'test_of_detail' },
    { description: 'Test inventory cost (IAS 2): vouch a sample to recent purchase invoices including landed costs (freight, duty, clearing); for finished goods test the cost build-up (materials, labour, overhead)', type: 'test_of_detail' },
    { description: 'Test net realizable value (IAS 2): compare cost to post-year-end selling prices less costs to complete/sell; recognize write-downs where NRV is below cost', type: 'test_of_detail' },
    { description: 'Verify costing method (FIFO / weighted average) is consistent with policy and prior period; recompute for a sample (IAS 2)', type: 'test_of_detail' },
    { description: '(Manufacturers only) Recompute production overhead absorption — overheads only, normal-capacity basis; exclude abnormal waste, admin, and selling costs (IAS 2)', type: 'test_of_detail' },
    { description: 'Identify slow-moving/obsolete/damaged inventory via aging and sales pipeline; test adequacy of the obsolescence/NRV provision against historical loss rates, current orders, and forward sales; ensure write-downs where appropriate', type: 'test_of_detail' },
    { description: 'Test cut-off of receipts/shipments around year-end by tracing last GRNs/GDNs to records and assessing ownership (FOB terms) and correct period (IAS 2)', type: 'test_of_detail' },
    { description: 'For goods in transit / consignment / third-party-held inventory: verify ownership (rights) and correct inclusion/exclusion; confirm third-party-held stock with the custodian (ISA 501)', type: 'test_of_detail' },
    { description: 'Test disclosure: categories (raw materials/WIP/finished goods), carrying amount, cost formula, write-downs recognized/reversed, inventory pledged as security, and inventory recognized as expense (IAS 2, IAS 1)', type: 'test_of_detail' },
    { description: 'Perform analytical procedures: inventory turnover, days in inventory, gross margin vs prior period and budget; investigate variances (ISA 520)', type: 'analytical' },
    { description: 'Reconcile inventory sub-ledger to GL and search for unrecorded movements via post-year-end GRNs/GDNs and production reports (completeness, ISA 500)', type: 'test_of_detail' },
  ],
  'PPE / Fixed Assets': [
    { description: 'Vouch additions to invoices/contracts; verify capitalized cost = purchase price + directly attributable costs + borrowing costs (if a qualifying asset per IAS 23); confirm application of the capitalization threshold and policy (IAS 16)', type: 'test_of_detail' },
    { description: 'Test disposals/retirements: remove from register, trace proceeds to bank, recompute gain/loss, confirm derecognition (IAS 16)', type: 'test_of_detail' },
    { description: 'Recompute depreciation for a sample; assess useful lives, residual values, and method for appropriateness/consistency; confirm depreciation begins when available for use; verify componentization for significant parts with different useful lives (IAS 16)', type: 'test_of_detail' },
    { description: 'Existence: physically inspect a sample of significant assets and reconcile to the fixed-asset register (ISA 500)', type: 'test_of_detail' },
    { description: 'Completeness: reconcile the fixed-asset register to GL; test a sample of repairs/maintenance above the capitalization threshold for proper expensing vs capitalization (IAS 16)', type: 'test_of_detail' },
    { description: 'Impairment (IAS 36): review indicators (idle, obsolete, damaged, market decline, restructuring); where present, test management\'s recoverable-amount/impairment assessment; otherwise document that no indicators exist', type: 'test_of_detail' },
    { description: 'Rights and obligations: verify title deeds (property) and registration (vehicles); confirm assets pledged as security with lenders where needed and test disclosure (IAS 16)', type: 'test_of_detail' },
    { description: '(If revaluation model) Assess valuer competence/independence and valuation date; verify recognition in OCI/revaluation surplus and disclosure (IAS 16)', type: 'test_of_detail' },
    { description: '(If leases — IFRS 16) Verify right-of-use assets and lease liabilities, their depreciation and interest unwind, or confirm short-term/low-value exemptions (IFRS 16)', type: 'test_of_detail' },
    { description: '(If assets under construction) Verify existence and progress (site visits, contractor reports) and test capitalized costs for eligibility (IAS 16, IAS 23)', type: 'test_of_detail' },
    { description: 'Disclosure and classification: carrying-amount reconciliation (cost, additions, disposals, depreciation, impairment), methods/useful lives, pledged assets, capital commitments, CIP, restrictions on title; verify PPE category split and current/non-current classification (IAS 16, IAS 1)', type: 'test_of_detail' },
    { description: 'Analytical: depreciation-to-cost ratio, additions vs capex budget, repairs trend; investigate significant variances (ISA 520)', type: 'analytical' },
  ],
  // ---------- Balance Sheet — Liabilities & Equity ----------
  'Accounts Payable': [
    { description: 'Search for unrecorded liabilities (primary completeness test): review post-year-end payments, unmatched GRNs/POs, and supplier invoices/statements received after year-end; trace to the correct period (ISA 500)', type: 'test_of_detail' },
    { description: 'Reconcile supplier statements to the AP ledger for major/active suppliers, including suppliers with low/nil recorded balances but prior activity; investigate and resolve differences (ISA 500)', type: 'test_of_detail' },
    { description: 'Use confirmations (ISA 505) selectively for major suppliers without statements, disputed balances, or related-party payables; non-replies → alternatives (subsequent payment, supplier statement)', type: 'test_of_detail' },
    { description: 'Test cut-off of purchases/goods received immediately before/after year-end by tracing to GRN/invoice dates; correct period (ISA 500)', type: 'test_of_detail' },
    { description: 'Test accruals and unbilled liabilities (utilities, rent, bonuses, professional fees, taxes) for completeness and measurement: vouch to contracts and subsequent invoices; recompute key accruals (ISA 500)', type: 'test_of_detail' },
    { description: 'Investigate debit balances in AP; reclassify to receivables where recoverable from suppliers, or to prepayments where they relate to future goods/services; assess recoverability (IAS 1)', type: 'test_of_detail' },
    { description: 'Identify related-party payables; confirm terms, assess arm\'s-length nature, and test disclosure (IAS 24)', type: 'test_of_detail' },
    { description: 'For foreign-currency payables, verify retranslation at the closing rate and recompute FX gain/loss (IAS 21)', type: 'test_of_detail' },
    { description: 'Test classification & disclosure: trade vs other payables, current/non-current split, related-party payables, credit terms, credit-risk concentrations, and contingent liabilities/commitments (IAS 1, IFRS 7, IAS 24)', type: 'test_of_detail' },
    { description: 'If relying on controls, test key purchase-cycle controls: purchase authorization, 3-way match (PO/GRN/invoice), segregation — inquiry/inspection/reperformance of a sample (ISA 315/330)', type: 'controls' },
    { description: 'Analytical: payables turnover / DPO and AP-to-purchases ratio vs prior period; investigate significant variances (ISA 520)', type: 'analytical' },
    { description: 'Reconcile the AP sub-ledger to GL and investigate unreconciled differences (ISA 500)', type: 'test_of_detail' },
  ],
  'Loans & Borrowings': [
    { description: 'Obtain loan confirmations (ISA 505) from all lenders — principal, rate, maturity, security, covenants, undrawn facilities; non-replies → loan agreements + bank statements', type: 'test_of_detail' },
    { description: 'Agree opening balance + movements (drawdowns/repayments) to loan agreements and bank statements; recompute closing balance (ISA 500)', type: 'test_of_detail' },
    { description: 'Recompute interest expense and accrued interest using agreement rates and outstanding principal; reconcile to cash payments; verify capitalized borrowing costs (IAS 23) and effective-interest measurement for material loans (IFRS 9)', type: 'test_of_detail' },
    { description: 'Review loan agreements for covenant terms; recalculate compliance ratios at year-end; where breached, verify an unconditional waiver was obtained before year-end — if not, reclassify to current per IAS 1.74', type: 'test_of_detail' },
    { description: 'Verify current vs non-current classification on contractual maturity and any repayable-on-demand / breach-of-covenant terms (IAS 1.73-76)', type: 'test_of_detail' },
    { description: 'Identify related-party / shareholder loans; confirm terms, assess arm\'s-length nature and interest, evaluate recoverability of director loans (and whether effectively equity), and test disclosure (IAS 24)', type: 'test_of_detail' },
    { description: 'Confirm pledged assets/guarantees; cross-reference to pledged PPE/cash; test disclosure of security (IFRS 7)', type: 'test_of_detail' },
    { description: '(If loan modified/refinanced) Assess whether the modification is substantial → modification vs derecognition accounting (IFRS 9)', type: 'test_of_detail' },
    { description: 'Test disclosure: maturity analysis by contractual remaining-maturity buckets, effective vs nominal rates, security details, covenant terms, defaults/breaches, and fair value hierarchy where required (IFRS 7, IAS 1)', type: 'test_of_detail' },
    { description: 'Analytical: interest expense vs average debt (effective-rate reasonableness); debt movement vs cash flow; investigate variances (ISA 520)', type: 'analytical' },
    { description: 'Search for unrecorded borrowings: review post-year-end payments, board minutes, and bank statements for interest payments to unknown lenders; confirm all borrowings are recorded (completeness, ISA 500)', type: 'test_of_detail' },
  ],
  'Provisions & End-of-Service Benefits': [
    { description: 'Obtain HR schedule of all employees as at year-end; reconcile headcount and basic salaries to payroll records', type: 'test_of_detail' },
    { description: 'Recalculate end-of-service benefit accrual per applicable labour law and entity\'s defined benefit policy; agree calculation methodology to local statute and accounting policy; recompute for a sample of employees (years of service × salary base × applicable rate). Where the EoSB obligation is material or long-service, consider IAS 19 measurement (actuarial valuation, or a proportionate simplified method for smaller entities)', type: 'test_of_detail' },
    { description: 'Verify the basis used for end-of-service benefits aligns with the legal definition in the applicable jurisdiction (typically basic wage only, excluding allowances)', type: 'test_of_detail' },
    { description: 'Test a sample of joiners and leavers during the period — verify accrual additions and final settlement payouts to settlement records and bank transfers', type: 'test_of_detail' },
    { description: 'Send confirmation requests to entity legal counsel for pending litigation, claims, and assessments at and after year-end', type: 'test_of_detail' },
    { description: 'Evaluate management classification of contingent items under IAS 37 (probable / possible / remote) and corresponding recognition vs disclosure treatment', type: 'other' },
    { description: 'For warranty, restructuring, or onerous contract provisions, test reasonableness of management estimate against historical experience and contractual terms', type: 'test_of_detail' },
    { description: 'Review board minutes, signed contracts, and post-year-end correspondence for undisclosed claims, guarantees, indemnities, or commitments', type: 'test_of_detail' },
    { description: 'Perform analytical review of EoSB movement (opening + accrual − payments = closing); investigate unusual variances and reconcile to payroll expense', type: 'analytical' },
    { description: 'Test current vs non-current classification of provisions and EoSB per IAS 1 (amounts expected to be settled within 12 months vs beyond)', type: 'test_of_detail' },
    { description: 'Test disclosure per IAS 37 / IAS 1: nature of each provision, timing of expected outflows, uncertainties, and amounts, plus the provision reconciliation (opening + additions/charges − utilisations/payments ± remeasurement = closing)', type: 'test_of_detail' },
    { description: 'Obtain written management representation on completeness of provisions, contingent liabilities, and commitments disclosed', type: 'other' },
  ],
  'Equity & Share Capital': [
    { description: 'Agree share capital (authorized / issued / paid-up) — number of shares, par value, total — to MOA/AOA, share register, trade/commercial-registry filings, and prior-year FS; verify any changes were duly filed (IAS 1, ISA 500)', type: 'test_of_detail' },
    { description: 'Test share movements (issues, buy-backs, transfers) to board/shareholder resolutions and certificates; trace consideration to bank; verify allocation between share capital and share premium (IAS 32)', type: 'test_of_detail' },
    { description: '(If such instruments exist) Assess equity-vs-liability classification under IAS 32 (substance over form) for redeemable/puttable preference shares, mandatorily-distributable instruments, or shareholder loans presented as equity', type: 'test_of_detail' },
    { description: 'Dividends: agree declared/paid to resolutions; verify within distributable reserves and legal limits, correct period, and withholding-tax treatment (IAS 1)', type: 'test_of_detail' },
    { description: 'For each reserve (retained earnings, revaluation, FX, statutory/legal, other), confirm composition and recompute roll-forward from opening to closing (P&L, OCI, owner transactions, transfers) (IAS 1)', type: 'test_of_detail' },
    { description: 'Where local company law requires, test statutory/legal reserve transfers (common across MENA — e.g., a required percentage of annual profit to a statutory reserve up to a capped proportion of capital): recompute and verify posting (IAS 1 / applicable local law)', type: 'test_of_detail' },
    { description: '(If OCI items exist) Tie OCI-routed reserve movements (revaluation surplus, FX translation) back to their source sections and working papers (IAS 1, IAS 16)', type: 'test_of_detail' },
    { description: 'Review board/shareholder minutes for unrecorded equity transactions, capital commitments, and guarantees affecting equity classification/disclosure (ISA 500)', type: 'test_of_detail' },
    { description: 'Test SOCIE and equity disclosures (IAS 1): each component reconciles opening to closing; notes disclose share-capital details, dividends, nature/purpose of each reserve, capital management, and restrictions on distribution', type: 'test_of_detail' },
    { description: '(If prior-period errors/policy changes) Verify retrospective IAS 8 adjustments affecting equity are correctly presented in SOCIE and notes (IAS 8, IAS 1)', type: 'test_of_detail' },
    { description: 'Analytical reconciliation of equity: opening + P&L − dividends ± OCI ± capital movements = closing; agree to TB and SOCIE (ISA 520)', type: 'analytical' },
  ],
  // ---------- Income Statement ----------
  'Revenue': [
    { description: 'For a risk-based sample of contracts, test recognition against the IFRS 15 five-step model (contract → performance obligations → transaction price → allocation → recognition); verify point-in-time vs over-time and control-transfer evidence (IFRS 15, ISA 500)', type: 'test_of_detail' },
    { description: 'Cut-off (critical): test sales/deliveries just before/after year-end to shipping/delivery/acceptance evidence; correct period when control transfers (IFRS 15, ISA 500)', type: 'test_of_detail' },
    { description: 'Apply ISA 240 fraud lens: test for improper recognition (channel-stuffing, bill-and-hold, side agreements, premature/fictitious sales); examine large/unusual/period-end entries; review post-year-end credit notes/reversals as overstatement indicators (ISA 240, ISA 500)', type: 'test_of_detail' },
    { description: 'Vouch a sample to contract + invoice + proof of delivery/acceptance (occurrence, ISA 500)', type: 'test_of_detail' },
    { description: 'Completeness: trace delivery docs/contracts to recorded revenue; reconcile revenue to cash receipts + receivables movement; search for unrecorded sales via post-year-end cash and credit notes (ISA 500)', type: 'test_of_detail' },
    { description: 'Test deferred revenue / contract liabilities: existence, measurement, and release timing per IFRS 15', type: 'test_of_detail' },
    { description: '(If variable consideration) Test estimation and the constraint for discounts, rebates, returns, volume bonuses (IFRS 15) — practical/historical basis for SMEs', type: 'test_of_detail' },
    { description: '(If bundled/multi-element) Test transaction-price allocation across distinct performance obligations (IFRS 15)', type: 'test_of_detail' },
    { description: '(If related-party revenue) Same recognition policy as third-party, arm\'s-length terms, disclosure (IFRS 15, IAS 24)', type: 'test_of_detail' },
    { description: 'Analytical: revenue vs prior/budget/external indicators; gross margin by line; monthly trends for period-end spikes; investigate variances (ISA 520)', type: 'analytical' },
    { description: 'Test disclosure per IFRS 15: disaggregation (category/segment/timing), performance obligations, contract balances (receivables, contract assets, contract liabilities), and significant judgments', type: 'test_of_detail' },
    { description: '(If relying on controls) Test invoice authorization, pricing/master-data changes, credit-note approval, segregation — inquiry/inspection/reperformance (ISA 315/330)', type: 'controls' },
  ],
  'Cost of Sales': [
    { description: 'Perform analytical review of gross margin by product line / category vs prior period and budget; investigate variances exceeding threshold', type: 'analytical' },
    { description: 'Test cut-off — select shipments and goods received immediately before and after year-end and verify recording in correct period', type: 'test_of_detail' },
    { description: 'Test a sample of COS entries to underlying purchase invoices, GRNs, and supplier statements', type: 'test_of_detail' },
    { description: 'For imported goods, verify landed cost components (customs duty, freight, insurance, clearing) are capitalized into inventory cost per IAS 2', type: 'test_of_detail' },
    { description: 'Verify inventory costing method (FIFO / Weighted Average) is consistent with prior period and entity accounting policy', type: 'other' },
    { description: 'For manufacturers, recalculate overhead absorption rate and verify only production overheads are included per IAS 2', type: 'test_of_detail' },
    { description: 'Test controls over 3-way match between purchase order, goods receipt note, and supplier invoice', type: 'controls' },
    { description: 'Perform monthly analytical review of COS-to-revenue ratio; investigate unusual fluctuations indicating cut-off or recording errors', type: 'analytical' },
    { description: 'For top suppliers by value, obtain supplier confirmation or perform supplier statement reconciliation as alternative procedure', type: 'test_of_detail' },
    { description: 'For foreign-currency purchases, verify exchange rate applied at transaction date per IAS 21', type: 'test_of_detail' },
  ],
  'Payroll & HR': [
    { description: 'Test a sample of payroll calculations: recalculate gross pay (contracts/approved rates), statutory + voluntary deductions, employer contributions, net pay; agree to payslips and bank payments (and any statutory wage-protection system, where applicable in the jurisdiction) (IAS 19, ISA 500)', type: 'test_of_detail' },
    { description: 'Reconcile payroll register to GL and bank payments; reconcile monthly payroll cost to TB; investigate variances (ISA 500)', type: 'test_of_detail' },
    { description: 'Vouch new hires and terminations to HR records/contracts; verify payroll additions/removals in the correct period', type: 'test_of_detail' },
    { description: 'Ghost-employee / existence test (ISA 240 fraud lens): sample employees, verify existence via HR file + ID, review for duplicate bank accounts/IDs; risk-based focus on large/high-risk payrolls', type: 'test_of_detail' },
    { description: 'Test statutory contributions/withholdings (social security/pension, statutory wage-protection filings, and payroll-related taxes/withholdings as applicable in the entity\'s jurisdiction): recalculate, agree to payments, verify filings', type: 'test_of_detail' },
    { description: 'End-of-service benefits: agree the payroll-side movement to the Provisions & EoSB working paper (detailed recalculation performed there)', type: 'test_of_detail' },
    { description: 'Year-end accrued payroll & cut-off: accrued salaries, annual leave, bonuses, and commissions — test completeness/measurement, approval basis, and correct period (IAS 19)', type: 'test_of_detail' },
    { description: 'Management/director remuneration: verify authorization (board/contract), completeness, and KMP disclosure (IAS 24)', type: 'test_of_detail' },
    { description: 'Classification: payroll cost allocated correctly by function (COGS / SG&A / production overheads) per IAS 1', type: 'test_of_detail' },
    { description: '(If relying on controls) Segregation of HR master-data / payroll prep / payment authorization, master-data change controls, and payment/bank-file approval — inquiry/inspection/reperformance (ISA 315/330)', type: 'controls' },
    { description: 'Analytical: average cost per head, payroll-to-revenue ratio, headcount trend vs prior; investigate variances (ISA 520)', type: 'analytical' },
    { description: 'Test disclosure: total employee benefit expense and KMP compensation (short-term, post-employment, termination benefits) per IAS 24 and IAS 1', type: 'test_of_detail' },
  ],
  'Operating Expenses': [
    { description: 'Test a sample of operating expenses to supporting docs (invoice, approval, GRN/service evidence); verify occurrence and accuracy (ISA 500)', type: 'test_of_detail' },
    { description: 'Completeness: search for unrecorded expenses (post-year-end invoices, missing accruals); reconcile expenses to AP/accruals; review recurring expenses for missing months (ISA 500)', type: 'test_of_detail' },
    { description: 'Cut-off: test accrued and prepaid expenses at year-end (rent, utilities, insurance, professional fees, subscriptions) for correct period (IAS 1, ISA 500)', type: 'test_of_detail' },
    { description: 'Recompute key accruals/prepayments for completeness and measurement (IAS 1, ISA 500)', type: 'test_of_detail' },
    { description: 'Review unusual/non-recurring/one-off expenses; obtain explanations; assess classification (operating vs exceptional) per IAS 1 — risk-based (large/unusual/period-end)', type: 'test_of_detail' },
    { description: '(If related-party expenses) Test management/professional/related-party fees for arm\'s-length terms, authorization, and disclosure (IAS 24)', type: 'test_of_detail' },
    { description: 'Classification by nature/function per IAS 1; ensure capital items aren\'t expensed (tie to PPE) and vice versa (IAS 16)', type: 'test_of_detail' },
    { description: 'ISA 240 fraud lens: expenses with override/fraud indicators (round-sum, unusual payees, related parties); tie to Journal Entry Testing', type: 'test_of_detail' },
    { description: '(If relying on controls) Test expense authorization limits, approval workflow, segregation — inquiry/inspection/reperformance (ISA 315/330)', type: 'controls' },
    { description: 'Analytical (primary for routine opex): opex by category vs prior/budget; expense-to-revenue ratios; investigate variances (ISA 520)', type: 'analytical' },
    { description: 'Test disclosure: expenses by nature/function, auditor remuneration, related-party expenses (IAS 1, IAS 24)', type: 'test_of_detail' },
  ],
  'Tax': [
    { description: 'Recompute the current tax/Zakat provision: reconcile accounting profit to taxable base (add-backs/deductions such as non-deductible expenses and tax-exempt income) under the applicable corporate income tax (or Zakat) regime in the entity\'s jurisdiction, applying that regime\'s rate(s)/threshold(s); agree to the tax computation. For Zakat-liable entities, verify the correct CT-vs-Zakat regime selection and that Zakat is accounted for appropriately (as a distribution/equity or as an expense) per local law (IAS 12)', type: 'test_of_detail' },
    { description: 'Deferred tax: identify material temporary differences (depreciation vs tax base, provisions, EoSB, tax losses); apply the enacted/substantively-enacted rate; assess recoverability of deferred tax assets against future taxable profits (IAS 12)', type: 'test_of_detail' },
    { description: 'Effective-tax-rate reconciliation: tax expense vs PBT × applicable statutory rate; investigate unusual reconciling items; disclose per IAS 12 (abridged/grouped acceptable for simple SMEs)', type: 'test_of_detail' },
    { description: '(If indirect tax applies) VAT/GST: reconcile output/input to ledgers; agree payments/refunds to the tax authority and bank; assess exposure on late/unfiled returns', type: 'test_of_detail' },
    { description: '(Conditional) Tax administration/compliance: verify registration, filing, available reliefs/elections, exempt income, and special regimes (e.g., free-zone/qualifying-entity status) under the applicable jurisdiction\'s law', type: 'test_of_detail' },
    { description: 'Agree tax payments/refunds (income tax + indirect tax) to tax-authority correspondence/portal and bank statements', type: 'test_of_detail' },
    { description: 'Review outstanding assessments, audits, disputes, penalties; assess provisions/contingencies and uncertain tax positions per IFRIC 23 (most-likely-amount vs expected-value) and IAS 37', type: 'test_of_detail' },
    { description: '(If cross-border/related-party) Test withholding tax and transfer-pricing compliance and any related deferred-tax/uncertain positions (IAS 24, applicable local law)', type: 'test_of_detail' },
    { description: 'Classification & disclosure (IAS 12, IAS 1): current/deferred split, components of tax expense (current, deferred, prior-period adjustments), ETR reconciliation, unused losses/credits, unrecognized DTAs, uncertain positions', type: 'test_of_detail' },
    { description: 'Analytical: ETR vs applicable statutory rate and prior period; tax-to-PBT trend; investigate variances (ISA 520)', type: 'analytical' },
    { description: 'Completeness over tax exposures: review legal letters, significant contracts, and board minutes for tax clauses/assessments/restructurings that may create provisions or uncertain positions (IFRIC 23 / IAS 37, ISA 500)', type: 'test_of_detail' },
  ],
  // ---------- Cross-cutting & Closing ----------
  'Related Parties': [
    { description: 'Document scope and risk tier. Related-party identification is required by ISA 550 in every audit. (a) Document the type of entity (closely-held / family / group / listed) — closely-held and family-owned entities carry elevated risk. (b) Document any prior-year related-party concerns or restatements. (c) Tier the risk: routine (single shareholder, no group structure) / elevated (multiple jurisdictions, group structure, or owner withdrawals) / significant risk (owner-managed with significant cash transactions or undocumented loans). Tie scope to ISA 315 risk assessment', type: 'other' },
    { description: 'Obtain management\'s complete list of related parties per ISA 550.13. Verify completeness via independent procedures: (a) trade-register / commercial-registry lookup for the entity and its shareholders/directors, (b) review of shareholder agreements, articles of incorporation, group structure charts, (c) cross-reference to director declarations and conflict-of-interest registers, (d) review of group consolidation packages if applicable. Document any related parties identified by the audit team that were NOT on management\'s list — this is a significant finding per ISA 550.A18', type: 'test_of_detail' },
    { description: 'Identify undisclosed related parties via independent indicators per ISA 550.16: (a) bank confirmations naming related-party guarantors / co-signers, (b) board minutes referencing transactions with named individuals or entities not on the list, (c) loan agreements with named directors or shareholders, (d) significant non-arm\'s-length terms in supplier or customer contracts (unusual pricing, extended payment terms), (e) post-year-end transactions revealing previously undisclosed relationships, (f) management override patterns identified in JET that involve specific counterparty accounts', type: 'test_of_detail' },
    { description: 'For each material related-party transaction, perform substantive procedures per ISA 550.18-19: (a) inspect the underlying contract / invoice / agreement, (b) verify board or shareholder authorisation, (c) test whether transaction terms are at arm\'s length — compare pricing, payment terms, and conditions to comparable third-party transactions; document any deviation, (d) for sales/services to related parties: verify revenue recognition follows the same policy as third-party sales, (e) for loans/advances: verify interest rate, repayment terms, security, and IFRS 9 ECL impact', type: 'test_of_detail' },
    { description: 'Test the existence and recoverability of year-end related-party balances. (a) Obtain direct confirmation from the related party for receivables, payables, and loans where material, (b) For receivables/loans from owner-directors: assess recoverability — long-standing director loans with no documented repayment plan may need impairment under IFRS 9 (ISA 550.19), (c) For intercompany balances in a group: agree to the counterparty\'s books and obtain reconciliation of any differences, (d) Verify the classification (current vs non-current) is consistent with expected settlement', type: 'test_of_detail' },
    { description: 'Test transactions with significant influence indicators even where management does not classify the counterparty as a related party. Per IAS 24.9, related-party status can arise from significant influence (typically 20%+ ownership), key management personnel, close family members of KMP, or controlled/jointly-controlled entities. Where the audit team identifies these relationships, challenge management\'s classification and document the conclusion. Failure to disclose constitutes a misstatement per IAS 24', type: 'test_of_detail' },
    { description: 'Review board and shareholder meeting minutes for the entire period (and through to the auditor\'s report date) for related-party transactions, guarantees, indemnities, or commitments. Read partner / director resolutions, share transfer records, dividend declarations, and any post-period subsequent-event documentation per ISA 550 + ISA 560', type: 'test_of_detail' },
    { description: 'Test FS disclosures against IAS 24 disclosure requirements: (a) nature of related-party relationships, (b) information about transactions and outstanding balances necessary for an understanding of the relationship\'s potential effect on the FS, (c) parent and ultimate controlling party (IAS 24.13), (d) key management personnel compensation (IAS 24.17 — total + categories: short-term, post-employment, other long-term, termination, share-based), (e) outstanding balances and any provisions for doubtful debts. Map each disclosure to underlying audit evidence; gaps are findings', type: 'other' },
    { description: 'Obtain written management representation per ISA 550.26 / ISA 580: (a) management has disclosed to the auditor the identity of the entity\'s related parties and all the related-party relationships and transactions of which they are aware, (b) the entity has accounted for and disclosed such relationships and transactions in accordance with the applicable framework. If management refuses to provide this representation, treat as a scope limitation per ISA 550.27', type: 'other' },
    { description: 'Document the conclusion: (a) all material related-party transactions identified, tested, and either accepted as arm\'s-length-equivalent or posted as audit adjustments, (b) all material balances confirmed or substantiated, (c) disclosures complete per IAS 24, (d) any indicators of undisclosed related parties resolved or escalated. Cross-reference any findings to the Findings section and flag any matter requiring partner attention in the Completion Memo. Where significant risk was identified, document how it was responded to per ISA 550.18', type: 'other' },
  ],
  'Subsequent Events': [
    { description: 'Perform ISA 560.7 procedures through the auditor\'s report date: inquire of management and TCWG about post-reporting-date events and understand their identification procedures (ISA 560, ISA 500)', type: 'test_of_detail' },
    { description: 'Read minutes of shareholder/director/committee meetings held after year-end; inquire on matters where minutes aren\'t yet available (ISA 560)', type: 'test_of_detail' },
    { description: 'Review the latest post-year-end interim financials / management accounts and budgets for significant changes in revenue, margins, liquidity, borrowings, litigation, or other events affecting year-end assertions (ISA 560)', type: 'test_of_detail' },
    { description: 'Review post-year-end transactions (cash, sales/purchases, credit notes, new borrowings) for evidence of year-end or new conditions affecting the FS (ISA 560) — material transactions for low-risk SMEs', type: 'test_of_detail' },
    { description: 'Review post-year-end developments on judgmental items (litigation, claims, asset values, impairments); update legal confirmations where needed and reassess provisions/contingencies (ISA 560, IAS 37)', type: 'test_of_detail' },
    { description: 'Classify each event as adjusting vs non-adjusting (IAS 10); verify adjusting events are reflected in the FS and material non-adjusting events are disclosed with nature + estimated effect (or a statement it cannot be estimated)', type: 'test_of_detail' },
    { description: 'Cross-reference subsequent-events findings affecting going concern (update the GC assessment through report date and, where relevant, 12 months from the statement date per ISA 570) and the completion memo (ISA 560 datum)', type: 'other' },
    { description: 'Obtain written management representation that all subsequent events requiring adjustment or disclosure have been properly handled (ISA 560.9 / ISA 580)', type: 'other' },
    { description: '(If facts discovered after the report date — ISA 560.10-17) Document procedures and response (discuss with management, consider amending report/FS)', type: 'other' },
    { description: 'Document the conclusion: period covered (through report date), events identified, treatment (adjust / deny adjustment / disclose), and cross-references to disclosures, going concern, and opinion (ISA 230)', type: 'other' },
  ],
  'Going Concern': [
    { description: 'Document the going concern assessment scope and risk tier rationale. (a) Obtain management\'s going concern assessment covering at least 12 months from the reporting date per ISA 570.13; if shorter, request extension. (b) Risk-tier the engagement: low-risk (profitable, positive net assets, no significant debt, no adverse indicators) may justify a reduced procedure set; standard or elevated risk requires the full procedure set in this section. Document the tier and rationale here — the file must show that going concern was considered even when reduced procedures are applied (ISA 570 requires evidence proportionate to assessed risk)', type: 'test_of_detail' },
    { description: 'Test the FINANCIAL indicators per ISA 570 Appendix: (a) net liability / net current liability position, (b) fixed-term borrowings nearing maturity without realistic renewal prospects, (c) negative operating cash flows (historical or forecast), (d) adverse key ratios, (e) substantial operating losses or significant asset value deterioration, (f) arrears or discontinuance of dividends, (g) inability to pay creditors on due dates, (h) inability to comply with loan covenant terms, (i) change from credit to cash-on-delivery supplier terms, (j) inability to obtain financing for essential investments. For each indicator: mark present / not present / N/A with supporting evidence reference', type: 'test_of_detail' },
    { description: 'Test the OPERATING indicators per ISA 570 Appendix: (a) management intent to liquidate or cease operations, (b) loss of key management without replacement, (c) loss of a major market / key customer / franchise / license / principal supplier, (d) labour difficulties, (e) shortages of important supplies, (f) emergence of a highly successful competitor. Document evidence reviewed (board minutes, customer/supplier correspondence, post year-end transactions)', type: 'test_of_detail' },
    { description: 'Test OTHER indicators per ISA 570 Appendix: (a) non-compliance with capital or statutory regulatory requirements (e.g., solvency/liquidity floors for regulated entities), (b) pending legal or regulatory proceedings that, if successful, would create claims the entity is unlikely to satisfy, (c) changes in law/regulation/government policy expected to adversely affect the entity, (d) uninsured or underinsured catastrophes. Obtain confirmation from entity legal counsel; review regulator correspondence; document conclusion per indicator', type: 'test_of_detail' },
    { description: 'Recalculate the cash flow forecast supporting management\'s assessment. Verify (a) opening cash position agrees to the trial balance, (b) revenue assumptions are consistent with order book / signed contracts / pipeline, (c) operating cost assumptions reconcile to historical run-rate and committed costs, (d) capex assumptions agree to board-approved budget, (e) financing inflows/outflows agree to loan schedules and any approved facilities. Then stress-test the forecast against at least one downside scenario tailored to the ENTITY\'S specific vulnerabilities (ISA 570 does not prescribe fixed percentages — common scenarios include: loss of a major customer or franchise, margin compression in core product line, delayed AR collections, loan covenant pressure, withdrawal of an unconfirmed funding line, regulatory or market disruption). Document the scenario assumptions, the resulting cash position, and whether the entity remains solvent through the assessment period', type: 'analytical' },
    { description: 'For loans and borrowings: obtain the loan schedule and confirm (a) maturity dates within 12 months of reporting date, (b) outstanding balance vs. covenant thresholds at reporting date, (c) any covenant breaches or expected breaches in the assessment period, (d) renewal/refinancing status — documented commitments from lenders, not management intent. Where renewal is unconfirmed, treat as a material uncertainty indicator', type: 'test_of_detail' },
    { description: 'Where the going concern conclusion relies on financial support from related parties, shareholders, or a parent/group (common in owner-managed SMEs), obtain and evaluate that support (e.g., a signed letter of financial support); assess the supporter\'s ability and intent to provide it throughout the assessment period (their own liquidity/solvency) and the enforceability of the commitment; verify related disclosure (ISA 570, ISA 550, IAS 24)', type: 'test_of_detail' },
    { description: 'Review post-balance-sheet transactions and events through the date of the auditor\'s report for any condition that arose after year-end and that affects the going concern conclusion (ISA 570.18 / ISA 560). Examples: loan default after year-end, loss of a major customer, regulatory enforcement action. Document the events identified and their effect on the conclusion', type: 'test_of_detail' },
    { description: 'Evaluate whether identified events or conditions cast SIGNIFICANT DOUBT on the entity\'s ability to continue as a going concern (ISA 570.17). Significant doubt is the conceptual threshold — not a generic "indicator present" trigger. If significant doubt exists, evaluate management\'s plans to address the events/conditions and obtain sufficient appropriate evidence about whether the plans are feasible and likely to be executed. If significant doubt remains after considering management\'s plans, conclude that a MATERIAL UNCERTAINTY exists requiring disclosure and a MURGC section per ISA 570.18-19. Document: (a) which events/conditions were identified, (b) management\'s mitigating plans, (c) audit evidence supporting plan feasibility (not just management assertion), (d) audit conclusion: no significant doubt / significant doubt resolved by plans / material uncertainty exists', type: 'other' },
    { description: 'Review the going concern disclosures in the financial statements for (a) the basis of preparation note explicitly stating going concern basis, (b) where a material uncertainty is identified — disclosure of the events/conditions, management\'s plans, and explicit statement that a material uncertainty exists, and (c) where management made significant close-call judgments in concluding on going concern, disclosure of those judgments per IAS 1.122/136-137. Compare disclosures against ISA 570.19 / IAS 1.25-26 requirements', type: 'test_of_detail' },
    { description: 'Document the audit conclusion: (a) going concern basis appropriate, no material uncertainty → unmodified opinion; (b) going concern basis appropriate but material uncertainty disclosed adequately → unmodified opinion with Material Uncertainty Related to Going Concern (MURGC) section per ISA 570.22; (c) going concern basis appropriate but material uncertainty NOT adequately disclosed → qualified or adverse opinion per ISA 570.23; (d) going concern basis inappropriate → adverse opinion per ISA 570.21. State conclusion explicitly and cross-reference to the Opinion in the Completion Memo', type: 'other' },
    { description: 'Obtain a written management representation confirming (a) management has assessed the entity\'s ability to continue as a going concern for at least 12 months from the reporting date, (b) all relevant information has been disclosed to the auditor, (c) feasibility of any mitigating plans is supported by the cash flow forecast (ISA 570.16 / ISA 580)', type: 'other' },
    { description: 'Perform analytical review of trend ratios: current ratio, quick ratio, debt-to-equity, interest coverage, operating cash flow / total debt. Compare to prior 2 periods and document any deteriorating trend with explanation. Adverse trends in isolation are not conclusive but feed the overall ISA 570 conclusion', type: 'analytical' },
  ],
  'Journal Entry Testing': [
    { description: 'Document the JET scope and risk tier. JET is MANDATORY under ISA 240.32 for every audit — it cannot be scoped out as low-risk. Document: (a) the period covered (full year vs cut-off window), (b) whether testing extends throughout the period or focuses on end-of-period (ISA 240.32(c)), (c) the population — manual JEs vs system-generated vs both, (d) the rationale for any exclusions (e.g., recurring depreciation entries auto-generated by the ERP). Tie the scope to the assessed fraud risk identified in the planning risk-assessment memo', type: 'other' },
    { description: 'Obtain complete general ledger journal entry listing for the period in machine-readable format (Excel/CSV). Reconcile: (a) total debits = total credits, (b) entry count to the financial reporting system, (c) period-end account balances rebuilt from the JE listing tie to the trial balance. Document any reconciliation differences and resolution. A JE population that does not reconcile to the TB invalidates all downstream procedures (ISA 240.32, ISA 500.6)', type: 'test_of_detail' },
    { description: 'Conduct ISA 240.32(a) inquiries with individuals involved in the financial reporting process — typically the FC, CFO, and any controller/accountant who posts or approves JEs. Document: (a) whether they are aware of any inappropriate, unusual, or fraudulent journal entries, (b) how journal entries are reviewed and approved, (c) which users have posting AND approval rights (segregation of duties), (d) any system access bypassed during the period. Obtain signed inquiry memos where possible', type: 'test_of_detail' },
    { description: 'Filter 1 — End-of-period entries per ISA 240.32(b). Identify all JEs posted in: (a) the final week before period end, (b) the close cut-off window (typically 5-10 business days after period end before books are locked), (c) any post-closing adjustment entries. For each entry above performance materiality OR with unusual characteristics: vouch to supporting documentation, verify business purpose, agree to authorisation', type: 'test_of_detail' },
    { description: 'Filter 2 — Round-sum / repeating-digit entries. Identify all JEs where the amount ends in three or more zeros (e.g., 50,000; 100,000) OR has repeating digits (111,111; 250,250). These patterns indicate estimates posted without supporting calculation. For each above the materiality threshold, vouch to underlying calculation or invoice; absence of either is a finding', type: 'test_of_detail' },
    { description: 'Filter 3 — Unusual user entries. Identify JEs posted by: (a) senior management with system access (CFO, FC, owner-directors), (b) users outside the regular accounting team, (c) users with both posting and approval rights, (d) any user whose normal role does not include journal entry posting. For each: verify business purpose, confirm authorisation, document why the entry was posted by that user', type: 'test_of_detail' },
    { description: 'Filter 4 — Suspense, clearing, and contra accounts. Identify all JEs posted to suspense accounts, intercompany clearing accounts, or contra-revenue / contra-expense accounts during the period. Verify each entry: (a) business purpose, (b) timeliness of clearance (suspense balances should not persist past month-end), (c) reclassification entries that move amounts between income statement lines materially', type: 'test_of_detail' },
    { description: 'Filter 5 — Unrelated or seldom-used accounts (ISA 240.A41). Identify JEs that touch GL accounts which are not typically used by the entity OR that combine accounts that do not normally appear together (e.g., revenue and a balance-sheet liability, payroll and accounts receivable). These are classic fraud patterns. For each: trace to source documentation, confirm business rationale', type: 'test_of_detail' },
    { description: 'Filter 6 — Vague or missing narratives. Identify JEs where the narrative is blank, contains only generic terms ("adjustment", "correction", "reclass", "AJE", "to clear"), or references an unintelligible code. For each above materiality: obtain a substantive explanation in writing from the preparer; if not forthcoming, treat as a deficiency in internal control and document', type: 'test_of_detail' },
    { description: 'Filter 7 — Reversing entries. Identify all entries marked as reversing OR posted as a pair (entry + opposite entry within days). For each pair: verify both the original entry and the reversal, confirm the underlying business purpose for both, ensure the reversal was not used to undo legitimate transactions to hide fraud or manipulate period results', type: 'test_of_detail' },
    { description: 'Evaluate segregation of duties around JE processing. From the user-access listing for the accounting system, identify: (a) users with both posting AND approval rights for journal entries, (b) users who can post directly to the GL bypassing approval workflows, (c) users with both JE-posting and bank-reconciliation rights (a high-risk combination per ISA 240). Document findings and recommend compensating controls or report as a control deficiency', type: 'controls' },
    { description: 'Document the overall conclusion. State explicitly: (a) the total population tested by each filter and number of entries selected for substantive vouching, (b) exceptions found and their disposition (resolved with management explanation / posted as audit adjustment / escalated as a finding), (c) the impact on the fraud risk assessment per ISA 240.A45 — does the JET work confirm, reduce, or increase the risk of material misstatement due to fraud? (d) any changes required to other audit procedures based on JET findings. Cross-reference any unresolved exceptions to the Findings section', type: 'other' },
  ],
  'Out of Scope / Below Materiality': [
    { description: 'Document the performance materiality threshold determined for the engagement and the basis of calculation per ISA 320', type: 'other' },
    { description: 'Schedule all classifications and accounts assigned to this section with aggregate balance; confirm total is below performance materiality', type: 'test_of_detail' },
    { description: 'Document justification for not performing substantive procedures on these balances, considering both quantitative and qualitative materiality factors', type: 'other' },
    { description: 'Confirm via final review that no individually significant or qualitatively sensitive item (related party, fraud-prone, restricted, regulatory) is included in this aggregation', type: 'other' },
  ],
};

// BS-then-P&L order — used by seedSectionsForEngagement to give every new
// engagement a predictable layout. Never alphabetical.
const SECTION_SEED_ORDER = [
  // BS — Assets
  'Cash & Bank',
  'Accounts Receivable',
  'Prepayments & Other Receivables',
  'Inventory',
  'PPE / Fixed Assets',
  // BS — Liabilities & Equity
  'Accounts Payable',
  'Loans & Borrowings',
  'Provisions & End-of-Service Benefits',
  'Equity & Share Capital',
  // Income statement
  'Revenue',
  'Cost of Sales',
  'Payroll & HR',
  'Operating Expenses',
  'Tax',
  // Cross-cutting and closing
  'Related Parties',
  'Subsequent Events',
  'Going Concern',
  'Journal Entry Testing',
  'Out of Scope / Below Materiality',
];

// Seeds the 19 standard audit sections (with their procedure templates)
// onto a freshly created engagement. Idempotent-ish: if any section with
// the same name already exists for the engagement, that section is
// skipped (matters when an admin re-runs seeding manually).
async function seedSectionsForEngagement(supabaseClient, engagementId, createdBy) {
  // Check what sections already exist so we don't duplicate
  const { data: existing } = await supabaseClient
    .from('audit_sections')
    .select('name')
    .eq('engagement_id', engagementId);
  const existingNames = new Set((existing || []).map(s => s.name));

  // Default assignee to the engagement creator (partner) so sections land
  // owned rather than orphaned. Partner can reassign inline on the section card.
  const sectionsToInsert = SECTION_SEED_ORDER
    .filter(name => !existingNames.has(name))
    .map((name, i) => ({
      engagement_id: engagementId,
      name: name,
      assigned_to: createdBy || null,
      classification_tags: [],
      assertions: [],
      status: 'not_started',
      sort_order: i + 1,
      phase: 'final',
    }));

  if (sectionsToInsert.length === 0) return { sectionsCreated: 0, proceduresCreated: 0 };

  const { data: created, error: secErr } = await supabaseClient
    .from('audit_sections')
    .insert(sectionsToInsert)
    .select();

  if (secErr) {
    return { sectionsCreated: 0, proceduresCreated: 0, error: secErr.message };
  }

  // Build procedure rows for each section that has a template
  const proceduresToInsert = [];
  for (const sec of (created || [])) {
    const tmpl = PROCEDURE_TEMPLATES[sec.name];
    if (!tmpl) continue;
    tmpl.forEach((p, i) => {
      proceduresToInsert.push({
        section_id: sec.id,
        description: p.description,
        procedure_type: p.type,
        sort_order: i + 1,
      });
    });
  }

  if (proceduresToInsert.length > 0) {
    const { error: procErr } = await supabaseClient
      .from('audit_procedures')
      .insert(proceduresToInsert)
      .select();
    if (procErr) {
      return {
        sectionsCreated: (created || []).length,
        proceduresCreated: 0,
        error: procErr.message,
      };
    }
  }

  return {
    sectionsCreated: (created || []).length,
    proceduresCreated: proceduresToInsert.length,
  };
}
