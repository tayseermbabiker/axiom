# Working / Adjusted Trial Balance (reviewer #7) — June 2026

Design locked & 4-way validated (Claude + Perplexity + Copilot + Gemini all converge) + pressure-tested against prod schema. Standards: **ISA 450** (accumulate/evaluate misstatements, corrected vs uncorrected) + **ISA 230** (audit trail). MENA-agnostic.

## Architecture (final)
**Central engine + section views** (how CaseWare/Inflo work). User's instinct preserved: base TB immutable, adjustments passed *in the section where work happens*, consolidated audited TB generated centrally.
- **Engine (central):** every adjustment is a full double-entry **journal** stored centrally → adjusted TB computed = base + posted *corrected* journals. Account-precise (not via the messy `classification` string — only 1/39 sections tagged, codes vs labels mixed).
- **Views (section):** each section shows Original | Net adj | Adjusted for its accounts, + "journals initiated here". Cross-section contra legs (Dr COGS / Cr Inventory) just work because storage is central.
- **Tags solve cross-section:** `source_section` (where initiated) vs `account_section` (account's natural home).

## Data model — header + lines (chosen; adjusting_entries has 0 rows → clean to adopt)
Existing `adjusting_entries` (flat, 2-leg, finding-only) is superseded by:
- **`journal_entries`** (header): engagement_id, source_section_id, description, `impact_type`(adjustment|reclassification), `misstatement_type`(factual|judgmental|projected), `isa450_status`(proposed|corrected|uncorrected|trivial_excluded), management_response, is_posted_to_adjusted_tb, linked_finding_id, tb_version_id, prepared_by/at, reviewed_by/at, status(draft|reviewed|final), created_by/at.
- **`journal_lines`** (legs): journal_entry_id, trial_balance_line_id (account-precise FK), account_code, account_name, debit, credit, account_section_id, is_pl_affecting, sort_order.
- **`tb_versions`** +`is_locked`. **`trial_balance_lines`** +`account_type`(asset|liability|equity|income|expense) +`section_id`(FK audit_sections, the reliable section bridge).

## Phasing
- **P1 (this round):** schema + Screen A (Central Working TB grid) + Screen B (section filtered view + "initiated here") + Screen C (journal modal, dynamic legs, **Dr=Cr save-guard**, impact/misstatement/status, narration, linked finding). Posted+corrected → adjusted TB live. `isa450_status` captured but SUM view deferred.
- **P2:** Screen D — Summary of Uncorrected Misstatements (uncorrected above clearly-trivial threshold; P&L vs BS impact vs OM/PM); Gemini pro-forma toggle; export to mgmt-rep tables.
- **P3:** file assembly lock/reopen window (= reviewer #8): is_locked + reopen_reason/by/at, additions-only after assembly, activity-log diffs.

## Status
- ✅ P1 schema migration (applied to prod, committed `45ba2c6`)
- ✅ P1 Screen A — Central Working TB grid (Original | Dr adj | Cr adj | Adjusted, totals, balance bar, "adjusted only" toggle, journals list + filter chips). Placed as a **tab in the Execution phase** right after Trial Balance (NOT Conclusion — that phase is locked until execution completes, but journals are passed during fieldwork). Pro-gated in UI.
- ✅ P1 Screen C — Journal modal: dynamic multi-leg double entry, **Dr=Cr save-guard** (+ "each line is debit XOR credit"), impact_type / misstatement_type / isa450_status, narration, linked finding, management response. Posts to adjusted TB when status=corrected.
- ✅ P1 Screen B — in `section.html`: "Adjustments (this section)" card with Original/Net adj/Adjusted strip for the section's accounts + "Journals initiated in this section" list + "+ Propose adjustment" modal (pre-tags `source_section_id`; account picker spans the whole engagement TB so contra legs in other sections work). Pro-gated, hidden when section approved. Inline JS syntax-checked.
- ✅ P2 SUM + completion surfacing.
  - **SUM card on Working TB tab** (engagement.html): uncorrected entries → amount + effect-on-profit (from `is_pl_affecting`), totals, vs active materiality (OM/PM/trivial from `engagement_materiality_versions`), verdict (aggregate vs OM, ISA 450.11). Loads active materiality in `loadWorkingTB`.
  - **Completion PDF** (report.html, completion report): fetches journals; renders **Adjusted Trial Balance (ISA 450)** (accounts with posted-corrected adjustments: Original/Adjustment/Audited) + **Summary of Uncorrected Misstatements** (table + OM/PM/trivial + aggregate-vs-materiality verdict). This is the "falls into completion" surfacing.
  - Note: effect-on-profit shows "—" until `account_type` is populated on TB lines (is_pl_affecting derives from it); aggregate amount vs OM works regardless. All inline JS syntax-checked.
- ⬜ P3 lock/assembly (reviewer #8)

## Assumptions / notes (P1)
- Adjusted balance = original + Σposted-corrected debit − Σposted-corrected credit (TB treated debit-positive). Balance bar verifies **posted Dr = posted Cr** (true invariant, independent of TB sign convention) rather than adjusted-sum-zero.
- Journal legs pick accounts from the uploaded TB (account-precise rollup). "New/off-TB account" support deferred.
- Section tag on a leg derived from existing `tbToSectionMap` (classification match); `trial_balance_lines.section_id` reserved for the more robust mapping later.

## Notes
- Build prod-direct + test with founder org (staging Supabase can't receive the migration via the prod-scoped MCP; prod has ~0 real WTB data anyway).
- Inspector chain to satisfy: finding → journal → TB effect → FS → opinion.
