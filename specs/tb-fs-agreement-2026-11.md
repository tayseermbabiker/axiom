# TB ↔ FS Agreement — reconciled design (2026-11-04)

**Status:** DESIGN RECONCILED (Claude + Copilot + Perplexity, checked against the codebase). Not built. Needs founder sign-off on §9.

**Origin:** a pilot client partner asked "why not build the FS from the final TB?" The founder answered that producing FS is messy across sectors, but reconciling FS to TB is doable. The partner agreed FS preparation is management's responsibility, but as auditor wants assurance that **the final adjusted TB figures = the FS figures exactly**.

**Scope-freeze note:** `sprint-4-standards-floor.md` lists "Full TB↔FS automated reconciliation module" as NOT built. This is a direct client request, so it's a conscious reversal. Log it in `ROADMAP.md` under "requested by prospect".

---

## 1. Verdict (all three sources agree)

**Build a reconciliation workpaper. Do NOT build FS preparation.**

- **Requirement:** ISA 330.20(a) says to agree or reconcile the FS, *including disclosures*, with the underlying accounting records. ISA 330.30 says the documentation must show it.
  - *Correction:* Claude first cited "330.30(a)", which doesn't exist. Perplexity is right. The procedure library (`audit-templates.js:313`, `:335`) already uses 330.20(a) correctly.
- **Independence:** under IESBA R601.6, preparing FS for a PIE audit client is prohibited. For non-PIEs, R601.5 allows it only if it's routine/mechanical, with safeguards, and only if management makes the judgments (R400.21).
- **Oman:** the FSA has flagged auditors preparing their audit clients' FS as an independence concern in inspections. Not verified first-hand, but Perplexity cited fsa.gov.om. Two pilot contacts are in Muscat, so this alone rules out an "FS generator".
- **Perplexity's key safeguard:** never show "FS agreed" just because Audexon's own mapped totals balance. Agreement has to be against an *identified version of management's FS*.

## 2. What already exists (verified in code)

- `trial_balance_lines`: account_code, account_name, balance (signed), `account_type`, `section_id`, `tb_version_id`.
  - Old versions stay in the table, so **every query must filter by version**.
- `tb_versions` (label, `is_locked`).
- `journal_entries` + `journal_lines`:
  - Lines are `debit` / `credit` (both ≥ 0) with a `trial_balance_line_id` link.
  - `impact_type` = adjustment | reclassification.
  - `is_posted_to_adjusted_tb`.
  - The adjusted TB = base + posted journals.
- `engagement_fs_uploads`: the management FS PDF, versioned draft / final_for_review / signed.
- Roles: admin / supervisor / preparer. Helpers: `get_user_org_ids()`, `user_has_role_in_org()`, `org_has_pro_tier()`, `organizations.feature_tier`.
- Procedures already in the library:
  - 330.20(a) agreement (`:313`, `:335`)
  - lead schedules incl. PY (`:329`)
  - CFS testing (`:316`)
  - cash-equivalent composition (`:32`)
  - comparatives to PY audited FS (`:318`)
- ISA 510 opening balances already tracked in Acceptance (`opening_balances_status`).
- **The new workpaper is the structured evidence for procedures that already exist. It doesn't add new audit scope.**
- Missing: an FS-caption layer and any prior-year figures.

## 3. Assessment of each source

| Topic | Copilot | Perplexity | Decision |
|---|---|---|---|
| Mapping location | Separate table keyed (engagement, account_code). ✅ | Separate from section tags; support controlled splits. ✅ | Separate table, **with split rows** (see §4.2). |
| Sign handling | Store raw signed; flip for display only. ✅ | "Unusual signs" check. ✅ | Both. |
| Totals computation | SQL view. ✅ But wrong columns (`leg_type`/`amount`), no version filter (**double count**), and claimed views inherit RLS (**false**: needs `security_invoker = true`). | — | SQL view, `security_invoker = true`, filtered to the engagement's current TB version. |
| Freeze at sign-off | Snapshot + invalidation flag. ✅ But sign-off enforced only "in app" (`with check (true)`): **preparer could self-sign**. Role check excluded admins/supervisors. | Flag affected work when TB, mapping, adjustments **or FS version** change. ✅ | Sign-off only via SECURITY DEFINER RPC (role check inside). Invalidate on any of the 5 triggers (§4.5). |
| Balance check | "assets + liab/equity = 0". **Wrong pre-close**: current-year P&L isn't in TB equity yet. | — | SoFP check includes current-year profit. |
| Difference handling | Explanation text. | **"Explained ≠ acceptable."** A misstatement needs disposition, not a comment. ✅ | Resolution type enum; misstatement → must link a `journal_entries` row (ISA 450 flow). |
| Comparatives | Keyed PY now; design for PY TB later. ✅ | PY signed-FS tie-out is enough for ISA 710. Keep opening balances (510) as a **separate status**. ✅ | Keyed PY + PY FS reference. 510 already lives in Acceptance; link, don't duplicate. |
| Disclosures | Not covered. | 330.20(a) **includes disclosures**; some come from outside the ledger. ✅ | V1 includes "other-source" agreement rows. |
| Cash flow | Not covered. | Five checks are **necessary, not sufficient**. Needs a movement bridge; cash-equivalent definition ≠ the TB "cash" grouping; FX effects; framework-versioned rules. ✅ | V1: refined tie-outs + the existing CFS procedure (`:316`). V2: movement bridge, which needs a PY TB. |
| FS identity | — | Record FS version, currency, rounding unit, page/note refs. ✅ | V1. Rounding unit drives the tolerance. |
| Completion statuses | — | Separate results: mapping / CY / PY / disclosures / CFS / presentation. ✅ | Five statuses (presentation review stays a procedure). |
| Labelling | — | "Auditor's expected caption amounts — reconciliation working paper; not management's FS." No export as client FS. ✅ | Adopt. The FS-layout view gets no PDF/Word export. |

## 4. Final design — V1

### 4.1 FS identity (header)
- Links to one `engagement_fs_uploads` row: the version being agreed, normally `final_for_review` then `signed`.
- Records presentation currency, rounding unit (units / '000 / million) and framework (IFRS / IFRS for SMEs + edition).
- If a new FS upload supersedes the linked one, the sign-off is invalidated.

### 4.2 Captions and mapping
- **`fs_captions`** (org library, seeded with a default SoFP + P&L set the firm can edit):
  - fields: statement `sofp|pl`, name, parent/subtotal, `display_sign` (`debit_natural` | `credit_natural`), sort_order
  - an `is_cash_equivalent` flag, so the cash-equivalent definition is explicit (Perplexity / IAS 7.6–8)
- **`tb_account_caption_map`**:
  - fields: engagement_id, account_code, caption_id, `split_amount numeric NULL`
  - `NULL` means "remainder". One remainder row per account is allowed, so current/non-current splits work.
  - Reused across TB re-uploads by account_code.
  - The next year, the partner picks "copy mapping from engagement X". No clients table needed.
- **Suggestions:** a lookup table (section name + account_type → caption), suggested only and never auto-committed. Accounts without a section go in the "Unmapped" bucket.
- **Mapping completeness checks:**
  - unmapped balances
  - splits not summing to the balance
  - unusual sign vs `display_sign`
  - manual overrides of suggestions, listed for the reviewer

### 4.3 Agreement schedule (`engagement_fs_agreement`, one row per caption)
- **Computed:**
  - `tb_amount`: from the view, adjusted TB by caption
  - `tb_amount_frozen`: snapshotted at sign-off
- **Keyed:**
  - `fs_amount_cy`, `fs_page_ref`
  - `fs_amount_py`, `py_agreed_to_signed_fs bool`, PY FS reference
  - `py_restatement_note`
- **Difference:** `fs_amount_cy − tb_amount` (displayed with sign flipped by `display_sign`). Tolerance is set by the rounding unit.
- **Resolution** (`resolution_type`), required if difference ≠ 0:
  - `rounding`: auto-allowed within tolerance
  - `classification`: needs explanation
  - `misstatement`: **must link a `journal_entries` row**, so it flows into the ISA 450 summary
  - `fs_to_be_corrected`: management will amend the FS. Blocks sign-off until a new FS version is linked.

### 4.4 Other-source agreement rows (disclosures)
- Free rows: note/disclosure item, FS amount, source type (schedule / register / contract / other), evidence link, agreed tick, note.
- Covers maturity analysis, commitments, related-party amounts, and similar.

### 4.5 Tie-out checks (computed live, frozen at sign-off)
1. SoFP balances: Σ assets + Σ liabilities + Σ equity + current-year P&L = 0 (raw signed).
2. P&L profit in the FS = TB current-year profit.
3. CFS closing cash = Σ captions flagged `is_cash_equivalent` (incl. qualifying overdrafts).
4. CFS opening cash = PY closing cash (keyed PY).
5. Net movement + FX effect = closing − opening.
6. Depreciation/amortisation add-back = Σ mapped D&A captions. Not a single account.
7. CFS starting profit = P&L figure. Which figure (PBT or other) is configured by framework.

Checks 3–7 need the auditor to key in the CFS figures. They are labelled "arithmetic tie-outs — classification, gross presentation and non-cash items are tested in the CFS procedure", which links to `:316`.

### 4.6 Sign-off, invalidation, statuses
- **Five statuses:**
  - Mapping complete
  - CY agreed
  - PY comparatives agreed
  - Disclosures agreed
  - CFS tie-outs done
- Each is computed from the data. They are not manual ticks.
- **Sign-off** is through the RPC `sign_off_fs_agreement`. It is SECURITY DEFINER and checks the role inside (supervisor or admin reviews; preparer prepares).
- **Sign-off is refused while:**
  - any unexplained difference exists
  - an `fs_to_be_corrected` row is open
  - unmapped balances exist
  - the TB version is unlocked
- **Invalidation trigger** sets `is_invalidated` + reason when any of these happen after sign-off:
  - a journal is posted or unposted
  - journal lines are edited
  - a new TB version is uploaded
  - the mapping changes
  - a new FS upload supersedes the linked one
- The UI then shows the frozen figure next to the current one, with a banner.

### 4.7 Security
- RLS on all new tables, using the existing helpers (org membership via the engagement chain).
- Preparers, supervisors and admins can edit figures and mapping. Only the RPC writes sign-off columns: revoke column UPDATE on those, or block them with a trigger.
- The view is created `WITH (security_invoker = true)`.
- Explicit `GRANT` on every table and the view (Supabase Oct 30 2026 cutover). RPCs: `REVOKE … FROM public`, `GRANT … TO authenticated`.
- Pro gating in RLS on INSERT/UPDATE. SELECT stays open to org members, so a downgrade keeps history visible.

### 4.8 Presentation
- Tab title: **"FS Agreement"**.
- Optional "expected layout" toggle with the label: *"Auditor's expected caption amounts — reconciliation working paper; not management's financial statements."*
- No export of the expected layout. The workpaper itself exports with the inspection PDF.

## 5. V2 (not now)
- PY TB upload as a `tb_version` flagged `is_prior_year`. This gives account-level movements.
- CFS movement bridge: working capital, capex cash vs accruals, gross financing flows, tax and interest paid, non-cash transactions (IAS 7.43).
- Account-name fuzzy match for mapping reuse when account codes change.
- Framework rule sets versioned by edition: IFRS 18 consequential amendments; IFRS for SMEs 2025 effective 1 Jan 2027.

## 6. Out of scope (permanently)
- Generating management's FS, notes or a CFS for the client.
- Any "client-ready FS" export.

## 7. Effort estimate
- 1 migration: 4 tables + 1 view + 2 RPCs + triggers + RLS/GRANTs.
- 1 engagement tab, plus seeding the caption library.
- Roughly the size of the Working TB build (June).

---

## Appendix — verification prompts sent (2026-11-04)

### A. Prompt for Perplexity (ISA / IESBA / inspection angle)

```
I'm building audit software (Audexon) for small and mid-size audit firms in the GCC (UAE, Qatar, Oman, KSA), many of them affiliated with international networks (BDO, RSM, Crowe, Mazars) and subject to network quality inspections. Please answer with citations to ISA paragraphs, the IESBA Code, and inspection findings (IFIAR, network/regulator inspection reports) where possible.

Context: the software already holds the client's trial balance, with each account tagged to an audit section and an account type, and it computes an adjusted TB (base TB + posted audit adjustments under ISA 450). A partner asked whether the software should generate the financial statements from the final TB. We think FS preparation is management's responsibility, and the partner agrees. What the partner wants is assurance that the final adjusted TB figures agree exactly to the financial statements.

Questions:
1. Under ISA 330.30(a) (agreeing or reconciling the FS with the underlying accounting records) and ISA 500/230, what is the minimum documentation an inspector expects for TB-to-FS agreement? Is a per-line-item agreement schedule (FS caption = sum of mapped TB accounts, difference = 0 or explained, preparer/reviewer sign-off) sufficient? What do inspectors commonly flag as deficient here?
2. Under the IESBA Code (section 601 on accounting and bookkeeping services, and the self-review threat), what are the independence implications if audit software generates the client's financial statements from the audited TB, for (a) PIE clients and (b) non-PIE SME clients? Does showing a "TB-derived expected FS" purely as an auditor's working paper (clearly labelled as not the client's FS) raise the same concern?
3. Comparatives: under ISA 510 and ISA 710, what must the auditor document for prior-year comparative figures? Is it enough to record the PY figure per FS line item and evidence that it agrees to the prior-year signed FS, or do inspectors expect the prior-year TB itself?
4. Cash flow statement: what audit procedures do inspectors expect for the cash flow statement in SME audits (IAS 7 / IFRS for SMEs section 7)? Would these tie-out checks be considered adequate: closing cash = cash per TB; opening cash = PY closing cash; net movement agrees; depreciation add-back = TB depreciation; profit before tax agrees to P&L? What else is commonly missed?
5. Are there GCC-specific requirements (UAE MoE / SCA, Qatar QFCRA / MoCI, Oman CMA, KSA SOCPA) on agreeing FS to the TB or on auditor involvement in preparing FS?
6. In practice, how do mid-tier network firms document TB-to-FS agreement? (e.g. CaseWare "FS mapping + lead schedules", Excel "FS tick-and-tie", mapping codes.) What's the recognised best practice we should mirror?
```

### B. Prompt for Copilot (engineering / data-model angle)

```
Context: Audexon is a vanilla-JS + Supabase (Postgres with RLS) audit SaaS. Relevant existing tables:
- trial_balance_lines(id, engagement_id, account_code, account_name, balance numeric, classification, account_type in (asset, liability, equity, income, expense), section_id → audit_sections)
- tb_versions(id, engagement_id, is_locked, ...)
- journal_entries(id, engagement_id, impact_type adjustment|reclassification, isa450_status, is_posted_to_adjusted_tb, ...) + journal_lines (debit/credit legs per account)
- Adjusted TB = base TB + posted corrected journals.
- engagement_fs_uploads stores the client's FS PDF (metadata only; figures are not parsed).
- There is no prior-year data and no FS-caption layer. Audit sections are audit areas, not FS captions. "Tax" feeds income-tax expense, current tax payable and deferred tax; "Loans & Borrowings" splits current/non-current.

Goal: an "FS Agreement" workpaper. The auditor maps TB accounts to FS captions. The app computes each caption's adjusted-TB total. The auditor keys in the figure from management's FS (CY and PY). The app shows differences, runs tie-out checks (SoFP balances; P&L profit = equity movement; closing cash = Cash & Bank caption; CFS opening/closing cash and depreciation add-back), and blocks sign-off while any unexplained difference ≠ 0. We are NOT generating the client's FS.

Proposed tables: fs_captions (org-level library, statement sofp|pl, sort_order, sign convention, is_subtotal); tb_account_caption_map (engagement_id, account_code, caption_id); engagement_fs_agreement (engagement_id, caption_id, tb_amount frozen at sign-off, fs_amount_cy, fs_amount_py, py_agreed, difference_explanation, prepared/reviewed by/at).

Please review:
1. Is mapping by account_code per engagement right, or should mapping live on trial_balance_lines.caption_id? How does each behave across TB re-uploads (new tb_versions) and year-to-year reuse when there's no client table (engagements only have client_name text)?
2. Sign conventions: TB balances are signed (debit +, credit −). What's the cleanest way to store and display caption totals so liabilities, equity and income show as positive in an FS layout without bugs in the tie-out maths?
3. Should caption totals be computed in a SQL view/RPC (adjusted TB grouped by caption) or client-side? Show a Postgres view that joins base TB + posted journal_lines and groups by caption.
4. How do we freeze evidence at sign-off (snapshot tb_amount per caption + TB version id) so later journal postings or TB re-uploads visibly invalidate the sign-off rather than silently changing it? Suggest the trigger/RPC pattern.
5. Default mapping heuristic: suggest a caption from (section name + account_type), e.g. section "Tax" + liability → "Current tax payable", + expense → "Income tax expense". Is a lookup table better than code? How do we handle accounts with no section tag?
6. Prior year: compare (a) keyed PY figures per caption vs (b) uploading a PY TB as a tb_version flagged prior_year. Which gives the better path to a later working-capital / cash-flow movement check?
7. RLS: preparers edit FS figures and the mapping; only supervisor/partner can sign off. Mirror the existing pattern (org membership via the engagement chain, Pro tier gated). Flag any policy pitfalls, including the Supabase Oct 2026 explicit-GRANT requirement.
```

---

## 9. Founder decisions (2026-11-04) — V1 is deliberately SIMPLE
- **Requested by:** the last demo firm.
- **Scope:** primary financials only, i.e. SoFP + P&L, CY + PY. **No notes/disclosure rows.** Notes are prepared and agreed manually through the existing procedure (`audit-templates.js:313`). Overrides §4.4.
- **Cash flow:** deferred entirely. Overrides §4.5 checks 3–7.
- **Tier:** all firms are now on a single Pro plan ($50 flat; Execution tier cancelled). No extra gating beyond the existing Pro pattern.
- **Caption library:** IFRS for SMEs (Section 4 SoFP, Section 5 P&L).
- **V1 cut list (simplicity):**
  - no account splits: one account maps to one caption
  - no FS-layout toggle
  - tie-outs limited to "SoFP balances incl. CY profit" and "P&L profit agrees"
- **V1 keeps:**
  - FS version link + rounding unit
  - mapping with suggestions + unmapped check
  - CY/PY agreement with resolution types (misstatement → journal link)
  - frozen sign-off via RPC
  - invalidation on TB/journal/mapping/FS-version change
