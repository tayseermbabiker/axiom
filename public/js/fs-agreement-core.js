// FS Agreement core (ISA 330.20(a)) — shared by pages/engagement.html (FS agreement
// tab) and pages/report.html (inspection PDF) so both show identical figures.
// Spec: specs/tb-fs-agreement-2026-11.md
// IFRS for SMEs line items (Sections 4 + 5). nature = natural balance side;
// credit-natural captions are displayed as positive when in credit.
const FS_CAPTIONS = [
  { key: 'ppe',                 st: 'sofp', grp: 'nca', nature: 'debit',  label: 'Property, plant and equipment' },
  { key: 'investment_property', st: 'sofp', grp: 'nca', nature: 'debit',  label: 'Investment property' },
  { key: 'intangibles',         st: 'sofp', grp: 'nca', nature: 'debit',  label: 'Intangible assets and goodwill' },
  { key: 'investments_assoc',   st: 'sofp', grp: 'nca', nature: 'debit',  label: 'Investments in associates and joint ventures' },
  { key: 'fin_assets_nc',       st: 'sofp', grp: 'nca', nature: 'debit',  label: 'Other financial assets (non-current)' },
  { key: 'deferred_tax_asset',  st: 'sofp', grp: 'nca', nature: 'debit',  label: 'Deferred tax asset' },
  { key: 'inventories',         st: 'sofp', grp: 'ca',  nature: 'debit',  label: 'Inventories' },
  { key: 'trade_receivables',   st: 'sofp', grp: 'ca',  nature: 'debit',  label: 'Trade and other receivables' },
  { key: 'prepayments',         st: 'sofp', grp: 'ca',  nature: 'debit',  label: 'Prepayments and other current assets' },
  { key: 'due_from_rp',         st: 'sofp', grp: 'ca',  nature: 'debit',  label: 'Due from related parties' },
  { key: 'current_tax_asset',   st: 'sofp', grp: 'ca',  nature: 'debit',  label: 'Current tax asset' },
  { key: 'cash',                st: 'sofp', grp: 'ca',  nature: 'debit',  label: 'Cash and cash equivalents' },
  { key: 'share_capital',       st: 'sofp', grp: 'eq',  nature: 'credit', label: 'Share capital' },
  { key: 'reserves',            st: 'sofp', grp: 'eq',  nature: 'credit', label: 'Statutory and other reserves' },
  { key: 'retained_earnings',   st: 'sofp', grp: 'eq',  nature: 'credit', label: 'Retained earnings', note: 'Includes the current-year result from the TB' },
  { key: 'borrowings_nc',       st: 'sofp', grp: 'ncl', nature: 'credit', label: 'Borrowings (non-current)' },
  { key: 'provisions_nc',       st: 'sofp', grp: 'ncl', nature: 'credit', label: 'Employee end-of-service benefits and provisions (non-current)' },
  { key: 'other_ncl',           st: 'sofp', grp: 'ncl', nature: 'credit', label: 'Other non-current liabilities' },
  { key: 'deferred_tax_liab',   st: 'sofp', grp: 'ncl', nature: 'credit', label: 'Deferred tax liability' },
  { key: 'trade_payables',      st: 'sofp', grp: 'cl',  nature: 'credit', label: 'Trade and other payables' },
  { key: 'due_to_rp',           st: 'sofp', grp: 'cl',  nature: 'credit', label: 'Due to related parties' },
  { key: 'borrowings_c',        st: 'sofp', grp: 'cl',  nature: 'credit', label: 'Borrowings and bank overdrafts (current)' },
  { key: 'provisions_c',        st: 'sofp', grp: 'cl',  nature: 'credit', label: 'Provisions (current)' },
  { key: 'current_tax_liab',    st: 'sofp', grp: 'cl',  nature: 'credit', label: 'Current tax liability' },
  { key: 'revenue',             st: 'pl',   grp: 'pl',  nature: 'credit', label: 'Revenue' },
  { key: 'cost_of_sales',       st: 'pl',   grp: 'pl',  nature: 'debit',  label: 'Cost of sales' },
  { key: 'other_income',        st: 'pl',   grp: 'pl',  nature: 'credit', label: 'Other income' },
  { key: 'distribution_costs',  st: 'pl',   grp: 'pl',  nature: 'debit',  label: 'Selling and distribution expenses' },
  { key: 'admin_expenses',      st: 'pl',   grp: 'pl',  nature: 'debit',  label: 'General and administrative expenses' },
  { key: 'other_expenses',      st: 'pl',   grp: 'pl',  nature: 'debit',  label: 'Other expenses' },
  { key: 'finance_income',      st: 'pl',   grp: 'pl',  nature: 'credit', label: 'Finance income' },
  { key: 'finance_costs',       st: 'pl',   grp: 'pl',  nature: 'debit',  label: 'Finance costs' },
  { key: 'income_tax',          st: 'pl',   grp: 'pl',  nature: 'debit',  label: 'Income tax expense' },
];
const FS_CAPTION_BY_KEY = Object.fromEntries(FS_CAPTIONS.map(c => [c.key, c]));
const FS_GROUP_LABELS = {
  nca: 'Non-current assets', ca: 'Current assets', eq: 'Equity',
  ncl: 'Non-current liabilities', cl: 'Current liabilities', pl: 'Profit or loss',
};

// Suggestion = section name + account_type → caption. Suggested only; the
// auditor applies and reviews. Keyword rules run first for equity/tax detail.
const FS_SECTION_SUGGEST = {
  'Cash & Bank':                          { asset: 'cash', liability: 'borrowings_c', income: 'finance_income', expense: 'finance_costs' },
  'Accounts Receivable':                  { asset: 'trade_receivables', expense: 'admin_expenses' },
  'Prepayments & Other Receivables':      { asset: 'prepayments' },
  'Inventory':                            { asset: 'inventories', expense: 'cost_of_sales' },
  'PPE / Fixed Assets':                   { asset: 'ppe', expense: 'admin_expenses', income: 'other_income' },
  'Accounts Payable':                     { liability: 'trade_payables' },
  'Loans & Borrowings':                   { liability: 'borrowings_nc', expense: 'finance_costs' },
  'Provisions & End-of-Service Benefits': { liability: 'provisions_nc', expense: 'admin_expenses' },
  'Equity & Share Capital':               { equity: 'share_capital' },
  'Revenue':                              { income: 'revenue', liability: 'trade_payables' },
  'Cost of Sales':                        { expense: 'cost_of_sales' },
  'Payroll & HR':                         { expense: 'admin_expenses', liability: 'trade_payables' },
  'Operating Expenses':                   { expense: 'admin_expenses' },
  'Tax':                                  { expense: 'income_tax', liability: 'current_tax_liab', asset: 'current_tax_asset' },
  'Related Parties':                      { asset: 'due_from_rp', liability: 'due_to_rp' },
};


// Posted, corrected journals only (ISA 450) — keyed by account_code so an adjustment
// still applies after the TB is re-imported. Same rule as the Working TB tab.
function fsPostedAdjByCode(entries, lines) {
  const postedIds = new Set((entries || [])
    .filter(e => e.isa450_status === 'corrected' && e.is_posted_to_adjusted_tb).map(e => e.id));
  const map = {};
  for (const ln of (lines || [])) {
    if (!postedIds.has(ln.journal_entry_id) || !ln.account_code) continue;
    if (!map[ln.account_code]) map[ln.account_code] = { debit: 0, credit: 0 };
    map[ln.account_code].debit  += Number(ln.debit)  || 0;
    map[ln.account_code].credit += Number(ln.credit) || 0;
  }
  return map;
}

// Caption totals in RAW signed TB terms (debit +). Closing retained earnings
// include the current-year result, since the TB is usually pre-close.
function fsCaptionTotals(tbLines, adjByCode, captionMap) {
  const raw = {};
  FS_CAPTIONS.forEach(c => { raw[c.key] = 0; });
  let unmapped = 0, unmappedBal = 0, tbNet = 0;
  for (const line of (tbLines || [])) {
    const a = adjByCode[line.account_code] || { debit: 0, credit: 0 };
    const bal = (Number(line.balance) || 0) + a.debit - a.credit;
    tbNet += bal;
    const key = captionMap[line.account_code];
    if (key && raw[key] !== undefined) raw[key] += bal;
    else if (Math.abs(bal) >= 0.005) { unmapped++; unmappedBal += bal; }
  }
  const plRaw = FS_CAPTIONS.filter(c => c.st === 'pl').reduce((s, c) => s + raw[c.key], 0);
  raw.retained_earnings += plRaw;
  return { raw, plRaw, unmapped, unmappedBal, tbNet };
}

// Display value in the FS rounding unit with the caption's natural sign.
function fsDisplayAmount(c, rawVal, unit) {
  const v = c.nature === 'credit' ? -rawVal : rawVal;
  return v / (unit || 1);
}

// Everything the reviewer signs (stored in engagement_fs_agreements.review_snapshot).
// linesByKey: caption_key -> engagement_fs_agreement_lines row; captionMap: account_code -> caption_key.
function fsBuildSnapshot(totals, linesByKey, captionMap, tbVersionId, fsUploadId, unit) {
  const captions = {};
  for (const c of FS_CAPTIONS) {
    const ln = linesByKey[c.key] || {};
    const tb = Math.round(fsDisplayAmount(c, totals.raw[c.key], unit) * 100) / 100;
    if (!tb && ln.fs_amount_cy == null && ln.fs_amount_py == null) continue;
    captions[c.key] = {
      tb, fs_cy: ln.fs_amount_cy ?? null, fs_py: ln.fs_amount_py ?? null,
      py_agreed: !!ln.py_agreed, resolution: ln.resolution_type || null, journal: ln.journal_entry_id || null,
    };
  }
  const mapping = Object.keys(captionMap).sort().map(k => k + '=' + captionMap[k]).join('|');
  return {
    tb_version_id: tbVersionId || null,
    fs_upload_id: fsUploadId || null,
    rounding_unit: unit || 1,
    captions,
    mapping_hash: fsHash(mapping),
  };
}

function fsHash(str) {
  let h = 5381;
  for (let i = 0; i < str.length; i++) h = ((h << 5) + h + str.charCodeAt(i)) | 0;
  return (h >>> 0).toString(16);
}

// Human-readable list of what changed between the signed snapshot and now.
function fsSnapshotDiff(oldS, newS) {
  const out = [];
  if (!oldS) return out;
  if (oldS.tb_version_id !== newS.tb_version_id) out.push('a new TB version was uploaded');
  if (oldS.fs_upload_id !== newS.fs_upload_id) out.push('a different FS version is linked');
  if (oldS.rounding_unit !== newS.rounding_unit) out.push('the rounding unit changed');
  if (oldS.mapping_hash !== newS.mapping_hash) out.push('the account mapping changed');
  const keys = new Set([...Object.keys(oldS.captions || {}), ...Object.keys(newS.captions || {})]);
  let tbChanged = false, fsChanged = false;
  keys.forEach(k => {
    const a = (oldS.captions || {})[k] || {}, b = newS.captions[k] || {};
    if ((a.tb || 0) !== (b.tb || 0)) tbChanged = true;
    if ((a.fs_cy ?? null) !== (b.fs_cy ?? null) || (a.fs_py ?? null) !== (b.fs_py ?? null) || !!a.py_agreed !== !!b.py_agreed
      || (a.resolution || null) !== (b.resolution || null) || (a.journal || null) !== (b.journal || null)) fsChanged = true;
  });
  if (tbChanged) out.push('adjusted TB amounts changed (journals posted or edited)');
  if (fsChanged) out.push('keyed FS figures or resolutions changed');
  return out;
}
