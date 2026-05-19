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
    { description: 'Obtain management list of related parties and verify completeness', type: 'test_of_detail' },
    { description: 'Test material related-party transactions for proper authorization and arm\'s length terms', type: 'test_of_detail' },
    { description: 'Review related-party balances at year-end for appropriate disclosure', type: 'test_of_detail' },
    { description: 'Inquire of management and review minutes for evidence of undisclosed related parties', type: 'test_of_detail' },
    { description: 'Test disclosures in financial statements for compliance with IAS 24', type: 'other' },
  ],
  'Subsequent Events': [
    { description: 'Read minutes of meetings of shareholders, directors, and key committees subsequent to year-end', type: 'test_of_detail' },
    { description: 'Inquire of management regarding any material events occurring after year-end', type: 'test_of_detail' },
    { description: 'Review interim financial information and management accounts for the period after year-end', type: 'test_of_detail' },
    { description: 'Test material events for proper recognition (adjusting) or disclosure (non-adjusting) per IAS 10', type: 'test_of_detail' },
    { description: 'Obtain management representation regarding subsequent events', type: 'other' },
  ],
  'Going Concern': [
    { description: 'Evaluate management\'s going concern assessment and supporting cash flow forecasts', type: 'analytical' },
    { description: 'Review financing arrangements and available credit facilities', type: 'test_of_detail' },
    { description: 'Assess covenant compliance and upcoming debt maturities', type: 'test_of_detail' },
    { description: 'Inquire of management about plans to address any liquidity concerns', type: 'test_of_detail' },
    { description: 'Review disclosures related to going concern in the financial statements', type: 'test_of_detail' },
    { description: 'Perform analytical review of key financial ratios and trends', type: 'analytical' },
  ],
  'Journal Entry Testing': [
    { description: 'Obtain complete general ledger journal entry listing for the period; reconcile total debits, credits, and entry count to the financial reporting system', type: 'test_of_detail' },
    { description: 'Test all journal entries above performance materiality posted to revenue, expense, or non-routine accounts', type: 'test_of_detail' },
    { description: 'Test journal entries posted to suspense, clearing, or contra accounts; verify business purpose and timely clearance', type: 'test_of_detail' },
    { description: 'Test journal entries posted by senior management or finance leadership (CFO, FC, owners) for appropriate authorization and business rationale', type: 'test_of_detail' },
    { description: 'Test journal entries posted in the final week of the period and during the close cut-off window', type: 'test_of_detail' },
    { description: 'Test reversing journal entries — verify original entry, reversal, and underlying business purpose for both', type: 'test_of_detail' },
    { description: 'Test round-sum or large-round-number journal entries that may indicate estimates posted without supporting calculation', type: 'test_of_detail' },
    { description: 'Test journal entries with missing, vague, or generic narratives (e.g., "adjustment", "correction", "reclass")', type: 'test_of_detail' },
    { description: 'Evaluate segregation of duties — identify users with ability to both post and approve journal entries', type: 'controls' },
    { description: 'Document journal entry testing approach, selection criteria, exceptions identified, and overall conclusion on fraud risk per ISA 240', type: 'other' },
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
