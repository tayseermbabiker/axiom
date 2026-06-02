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
- ⬜ P1 schema migration
- ⬜ P1 Screen A / B / C
- ⬜ P2 SUM
- ⬜ P3 lock/assembly

## Notes
- Build prod-direct + test with founder org (staging Supabase can't receive the migration via the prod-scoped MCP; prod has ~0 real WTB data anyway).
- Inspector chain to satisfy: finding → journal → TB effect → FS → opinion.
