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
    { description: 'Obtain bank confirmations for all bank accounts as at the reporting date', type: 'test_of_detail' },
    { description: 'Test bank reconciliations — agree balances to bank statements and GL', type: 'test_of_detail' },
    { description: 'Investigate outstanding reconciling items over 30 days', type: 'test_of_detail' },
    { description: 'Test a sample of cash receipts and disbursements around year-end for proper cutoff', type: 'test_of_detail' },
    { description: 'Verify restricted cash balances and confirm any liens or pledges', type: 'test_of_detail' },
    { description: 'Perform analytical review of interest income against average balances', type: 'analytical' },
    { description: 'Test controls over bank payment authorization and signatories', type: 'controls' },
    { description: 'Review bank accounts opened or closed during the year and confirm proper inclusion in reconciliations', type: 'test_of_detail' },
    { description: 'Review for unusual bank transactions (large, round-sum, related-party payments) and obtain explanations', type: 'test_of_detail' },
  ],
  'Accounts Receivable': [
    { description: 'Send confirmations to a sample of trade receivable balances', type: 'test_of_detail' },
    { description: 'Perform aging analysis and test the allowance for doubtful accounts', type: 'test_of_detail' },
    { description: 'Test subsequent cash receipts for balances outstanding at year-end', type: 'test_of_detail' },
    { description: 'Investigate any credit balances or unusual items in AR ledger', type: 'test_of_detail' },
    { description: 'Test cutoff by examining sales transactions immediately before and after year-end', type: 'test_of_detail' },
    { description: 'Perform analytical review of receivables turnover and days sales outstanding', type: 'analytical' },
    { description: 'Test controls over credit approval and customer credit limits', type: 'controls' },
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
    { description: 'Attend physical inventory counts at year-end and test count procedures', type: 'test_of_detail' },
    { description: 'Test pricing of inventory items by reference to recent purchases or sales', type: 'test_of_detail' },
    { description: 'Review for slow-moving, obsolete, or damaged inventory and assess provisions', type: 'test_of_detail' },
    { description: 'Test inventory cutoff — last receipts and shipments around year-end', type: 'test_of_detail' },
    { description: 'Verify consistency of inventory costing method (FIFO, weighted average) with prior periods', type: 'test_of_detail' },
    { description: 'Reconcile physical count results to perpetual inventory records and investigate variances', type: 'test_of_detail' },
    { description: 'Test net realizable value for finished goods inventory near year-end', type: 'test_of_detail' },
  ],
  'PPE / Fixed Assets': [
    { description: 'Vouch additions during the period to purchase invoices and capitalization policy', type: 'test_of_detail' },
    { description: 'Test disposals — verify removal from register, proceeds received, gain/loss calculation', type: 'test_of_detail' },
    { description: 'Recalculate depreciation for a sample and verify useful lives and methods are consistent with policy', type: 'test_of_detail' },
    { description: 'Perform existence test by physical inspection of significant assets', type: 'test_of_detail' },
    { description: 'Review for impairment indicators — idle assets, obsolescence, declining market value', type: 'test_of_detail' },
    { description: 'Verify title to property and significant equipment through documentation review', type: 'test_of_detail' },
    { description: 'Test capitalization vs expense classification for repairs and maintenance over threshold', type: 'test_of_detail' },
  ],
  // ---------- Balance Sheet — Liabilities & Equity ----------
  'Accounts Payable': [
    { description: 'Send confirmations to a sample of trade payable balances', type: 'test_of_detail' },
    { description: 'Test cutoff — examine purchases recorded before and after year-end', type: 'test_of_detail' },
    { description: 'Perform search for unrecorded liabilities — review post-period payments and unmatched purchase orders', type: 'test_of_detail' },
    { description: 'Reconcile supplier statements to AP ledger for major vendors', type: 'test_of_detail' },
    { description: 'Test debit balances in AP for potential reclassification', type: 'test_of_detail' },
    { description: 'Test accruals and unbilled supplier liabilities', type: 'test_of_detail' },
    { description: 'Test controls over purchase authorization and three-way match (PO, GRN, invoice)', type: 'controls' },
  ],
  'Loans & Borrowings': [
    { description: 'Obtain loan confirmations from banks and lenders', type: 'test_of_detail' },
    { description: 'Test interest expense calculation and accrual', type: 'test_of_detail' },
    { description: 'Review loan covenants compliance and obtain waivers if breached', type: 'test_of_detail' },
    { description: 'Verify classification between current and non-current portions', type: 'test_of_detail' },
    { description: 'Review for related-party loans and arm\'s length terms', type: 'test_of_detail' },
    { description: 'Confirm security and collateral pledged against borrowings', type: 'test_of_detail' },
  ],
  'Provisions & End-of-Service Benefits': [
    { description: 'Obtain HR schedule of all employees as at year-end; reconcile headcount and basic salaries to payroll records', type: 'test_of_detail' },
    { description: 'Recalculate end-of-service benefit accrual per applicable labour law and entity\'s defined benefit policy; agree calculation methodology to local statute and accounting policy', type: 'test_of_detail' },
    { description: 'Verify the basis used for end-of-service benefits aligns with the legal definition in the applicable jurisdiction (typically basic wage only, excluding allowances)', type: 'test_of_detail' },
    { description: 'Test a sample of joiners and leavers during the period — verify accrual additions and final settlement payouts to settlement records and bank transfers', type: 'test_of_detail' },
    { description: 'Send confirmation requests to entity legal counsel for pending litigation, claims, and assessments at and after year-end', type: 'test_of_detail' },
    { description: 'Evaluate management classification of contingent items under IAS 37 (probable / possible / remote) and corresponding recognition vs disclosure treatment', type: 'other' },
    { description: 'For warranty, restructuring, or onerous contract provisions, test reasonableness of management estimate against historical experience and contractual terms', type: 'test_of_detail' },
    { description: 'Review board minutes, signed contracts, and post-year-end correspondence for undisclosed claims, guarantees, indemnities, or commitments', type: 'test_of_detail' },
    { description: 'Perform analytical review of EoSB movement (opening + accrual − payments = closing); investigate unusual variances', type: 'analytical' },
    { description: 'Obtain written management representation on completeness of provisions, contingent liabilities, and commitments disclosed', type: 'other' },
  ],
  'Equity & Share Capital': [
    { description: 'Agree share capital to constitutional documents and prior-year financial statements', type: 'test_of_detail' },
    { description: 'Test movements in equity during the period and supporting authorizations', type: 'test_of_detail' },
    { description: 'Verify dividends declared and paid against board resolutions', type: 'test_of_detail' },
    { description: 'Confirm reserves and movements thereto', type: 'test_of_detail' },
    { description: 'Review for any unrecognized commitments or contingencies affecting equity', type: 'test_of_detail' },
  ],
  // ---------- Income Statement ----------
  'Revenue': [
    { description: 'Test a sample of revenue transactions to underlying contracts and supporting evidence', type: 'test_of_detail' },
    { description: 'Perform cutoff testing around year-end for sales and deliveries', type: 'test_of_detail' },
    { description: 'Test for unusual revenue patterns, credit notes, and reversals after year-end', type: 'test_of_detail' },
    { description: 'Perform analytical review of revenue against budget, prior periods, and external indicators', type: 'analytical' },
    { description: 'Test revenue recognition for compliance with IFRS 15 — performance obligations and timing', type: 'test_of_detail' },
    { description: 'Test deferred revenue and contract liabilities at year-end', type: 'test_of_detail' },
    { description: 'Test controls over invoice authorization and pricing', type: 'controls' },
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
    { description: 'Test a sample of payroll calculations including gross pay, deductions, and net pay', type: 'test_of_detail' },
    { description: 'Vouch new hires and terminations to HR records', type: 'test_of_detail' },
    { description: 'Test end-of-service benefit accrual calculations per applicable labour law', type: 'test_of_detail' },
    { description: 'Reconcile payroll totals to general ledger and payroll register', type: 'test_of_detail' },
    { description: 'Test for ghost employees by sampling employees and verifying employment status', type: 'test_of_detail' },
    { description: 'Verify segregation of duties between HR, payroll preparation, and payment authorization', type: 'controls' },
    { description: 'Perform analytical review of average compensation per head against prior period', type: 'analytical' },
  ],
  'Operating Expenses': [
    { description: 'Test a sample of operating expense transactions to supporting documentation', type: 'test_of_detail' },
    { description: 'Perform analytical review of operating expenses against budget and prior periods', type: 'analytical' },
    { description: 'Test cutoff for major expense categories — accrued and prepaid', type: 'test_of_detail' },
    { description: 'Review for unusual or non-recurring expenses and obtain explanations', type: 'test_of_detail' },
    { description: 'Test management fees, professional fees, and related-party expenses for arm\'s length pricing', type: 'test_of_detail' },
    { description: 'Test controls over expense authorization and approval limits', type: 'controls' },
  ],
  'Tax': [
    { description: 'Recalculate current tax provision based on applicable corporate tax rates and adjustments', type: 'test_of_detail' },
    { description: 'Review deferred tax positions and timing differences', type: 'test_of_detail' },
    { description: 'Test compliance with VAT / GST / sales tax filing requirements where applicable', type: 'test_of_detail' },
    { description: 'Verify tax payments and refunds against authority correspondence and bank statements', type: 'test_of_detail' },
    { description: 'Review for outstanding tax assessments, audits, or disputes with tax authorities', type: 'test_of_detail' },
    { description: 'Review withholding tax and transfer pricing compliance for cross-border transactions', type: 'test_of_detail' },
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
    { description: 'Read minutes of meetings of shareholders, directors, and key committees subsequent to year-end', type: 'test_of_detail' },
    { description: 'Inquire of management regarding any material events occurring after year-end', type: 'test_of_detail' },
    { description: 'Review interim financial information and management accounts for the period after year-end', type: 'test_of_detail' },
    { description: 'Test material events for proper recognition (adjusting) or disclosure (non-adjusting) per IAS 10', type: 'test_of_detail' },
    { description: 'Obtain management representation regarding subsequent events', type: 'other' },
  ],
  'Going Concern': [
    { description: 'Document the going concern assessment scope and risk tier rationale. (a) Obtain management\'s going concern assessment covering at least 12 months from the reporting date per ISA 570.13; if shorter, request extension. (b) Risk-tier the engagement: low-risk (profitable, positive net assets, no significant debt, no adverse indicators) may justify a reduced procedure set; standard or elevated risk requires the full procedure set in this section. Document the tier and rationale here — the file must show that going concern was considered even when reduced procedures are applied (ISA 570 requires evidence proportionate to assessed risk)', type: 'test_of_detail' },
    { description: 'Test the FINANCIAL indicators per ISA 570 Appendix: (a) net liability / net current liability position, (b) fixed-term borrowings nearing maturity without realistic renewal prospects, (c) negative operating cash flows (historical or forecast), (d) adverse key ratios, (e) substantial operating losses or significant asset value deterioration, (f) arrears or discontinuance of dividends, (g) inability to pay creditors on due dates, (h) inability to comply with loan covenant terms, (i) change from credit to cash-on-delivery supplier terms, (j) inability to obtain financing for essential investments. For each indicator: mark present / not present / N/A with supporting evidence reference', type: 'test_of_detail' },
    { description: 'Test the OPERATING indicators per ISA 570 Appendix: (a) management intent to liquidate or cease operations, (b) loss of key management without replacement, (c) loss of a major market / key customer / franchise / license / principal supplier, (d) labour difficulties, (e) shortages of important supplies, (f) emergence of a highly successful competitor. Document evidence reviewed (board minutes, customer/supplier correspondence, post year-end transactions)', type: 'test_of_detail' },
    { description: 'Test OTHER indicators per ISA 570 Appendix: (a) non-compliance with capital or statutory regulatory requirements (e.g., solvency/liquidity floors for regulated entities), (b) pending legal or regulatory proceedings that, if successful, would create claims the entity is unlikely to satisfy, (c) changes in law/regulation/government policy expected to adversely affect the entity, (d) uninsured or underinsured catastrophes. Obtain confirmation from entity legal counsel; review regulator correspondence; document conclusion per indicator', type: 'test_of_detail' },
    { description: 'Recalculate the cash flow forecast supporting management\'s assessment. Verify (a) opening cash position agrees to the trial balance, (b) revenue assumptions are consistent with order book / signed contracts / pipeline, (c) operating cost assumptions reconcile to historical run-rate and committed costs, (d) capex assumptions agree to board-approved budget, (e) financing inflows/outflows agree to loan schedules and any approved facilities. Then stress-test the forecast against at least one downside scenario tailored to the ENTITY\'S specific vulnerabilities (ISA 570 does not prescribe fixed percentages — common scenarios include: loss of a major customer or franchise, margin compression in core product line, delayed AR collections, loan covenant pressure, withdrawal of an unconfirmed funding line, regulatory or market disruption). Document the scenario assumptions, the resulting cash position, and whether the entity remains solvent through the assessment period', type: 'analytical' },
    { description: 'For loans and borrowings: obtain the loan schedule and confirm (a) maturity dates within 12 months of reporting date, (b) outstanding balance vs. covenant thresholds at reporting date, (c) any covenant breaches or expected breaches in the assessment period, (d) renewal/refinancing status — documented commitments from lenders, not management intent. Where renewal is unconfirmed, treat as a material uncertainty indicator', type: 'test_of_detail' },
    { description: 'Review post-balance-sheet transactions and events through the date of the auditor\'s report for any condition that arose after year-end and that affects the going concern conclusion (ISA 570.18 / ISA 560). Examples: loan default after year-end, loss of a major customer, regulatory enforcement action. Document the events identified and their effect on the conclusion', type: 'test_of_detail' },
    { description: 'Evaluate whether identified events or conditions cast SIGNIFICANT DOUBT on the entity\'s ability to continue as a going concern (ISA 570.17). Significant doubt is the conceptual threshold — not a generic "indicator present" trigger. If significant doubt exists, evaluate management\'s plans to address the events/conditions and obtain sufficient appropriate evidence about whether the plans are feasible and likely to be executed. If significant doubt remains after considering management\'s plans, conclude that a MATERIAL UNCERTAINTY exists requiring disclosure and a MURGC section per ISA 570.18-19. Document: (a) which events/conditions were identified, (b) management\'s mitigating plans, (c) audit evidence supporting plan feasibility (not just management assertion), (d) audit conclusion: no significant doubt / significant doubt resolved by plans / material uncertainty exists', type: 'other' },
    { description: 'Review the going concern disclosures in the financial statements for (a) the basis of preparation note explicitly stating going concern basis, (b) where a material uncertainty is identified — disclosure of the events/conditions, management\'s plans, and explicit statement that a material uncertainty exists. Compare disclosures against ISA 570.19 / IAS 1.25-26 requirements', type: 'test_of_detail' },
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
