# Planning & Completion Enhancements — June 2026

Source: second-opinion reviewer (detail-oriented) → cross-checked by Claude + Perplexity (both agreed on classification/standards). MENA-agnostic discipline applies (no country-specific rates/portals/retention-years — state ranges).

Status: ✅ done · 🔧 in progress · ⬜ scoped/pending

## Quick correctness fixes (small, high-ROI) — ✅ DONE 2026-06-02
- ✅ **#3 Opening balances phase fix** — relabelled to planning intent in `engagement.html` (acceptance UI: continuance = prior-year audited by us / initial = ISA 510 approach *planned*, verified in fieldwork), notes field → "Planned ISA 510 approach", validation msg + `report.html` OB_LABELS updated. Enum values kept ('verified'/'na_continuance') — display-only relabel, no migration. Forward + back compatible.
- ✅ **#4 Engagement letter "expected opinion"** — reframed in `engagement.html` letter UI + `report.html`: "Expected report type / Unmodified opinion (expected)" → "Anticipated report type (planning assumption — not stated in the letter)" with modification-RISK option labels; intro clarifies the letter states only the objective. Letter already carries `isa_210_objective_scope` attestation. Display-only, no migration.
- ✅ **#5a Prior-year fees settled (independence)** — added to Fee-dependence section: `ei-prior-fees-status` (settled / na_first_year / outstanding) + conditional `ei-prior-fees-note` (shown when outstanding); load + save wired; rendered in `report.html` independence block with THREAT badge. Migration `20260602120000_independence_prior_year_fees.sql` (cols `prior_year_fees_status` + `prior_year_fees_note` + CHECK) **applied to PROD** via MCP. ⚠️ **Staging DB needs the same SQL** (MCP is prod-scoped) before testing independence on staging.

## Scoped builds (post, in value order)
- ⬜ **#7 Working / adjusted Trial Balance** (ISA 450 + 230) — BIGGEST gap / highest impact. Unadjusted (per-books) TB → auditor adjustments (FS-changing, need mgmt agreement) AND reclassifications (presentation-only) → audited TB, with full trail. Existing `adjusting_entries` (is_posted) + ISA 450 misstatement schedule should *feed* the rollup. Completion phase, current file.
- ✅ **#1 AML / KYC / CDD module** (regulatory — DNFBP). Migration `20260602140000_aml_cdd.sql` (applied to prod): `engagement_aml_cdd` (identity, beneficial-ownership flag, screening, PEP, source of funds, AML risk rating + CDD level, suspicious-activity, conclusion accept/accept_edd/decline, attestation) + `engagement_aml_beneficial_owners` child. RLS mirrors acceptance (admin + Pro). UI = "AML & KYC" tab in Planning (after Acceptance, engagement.html `loadAmlKyc`/`saveAml`) with editable beneficial-owner rows; Pro-gated, admin-edit/read-only. Rendered in the **Planning PDF** (report.html). **MENA-agnostic** — no goAML, generic "report to the relevant national authority/FIU per local law". Proportionate (simplified/standard/enhanced CDD by risk).
- ⬜ **#8 File assembly / lock window** (ISA 230 A21 / ISQM 1) — configurable assembly window (default 60 days post-report) editable; then hard-lock to additions-only-with-documented-reason (who/when/why); retention "per local law, commonly 5–7 yrs". Builds on existing `archive_engagement` RPC + memo lock + Reopen + activity log.
- ⬜ **#2 Understanding the Entity enhancement** (ISA 315.11-12) — already partially in `engagement_audit_strategies` (ISA 315 inquiry/analytical/observation, industry/external environment, internal-controls overview, prior-year changes). Add structured entity overview: business model, sector, branches/locations, ownership/governance, IT environment.

## Backlog
- ⬜ **#5b Budgeted hours per team member/grade** — best practice (ISA 300 mandates *work allocation*, already via Team Assignments; hours breakdown is the add) for costing.

## Cross-cutting design idea
- ⬜ **"Less-complex entity" toggle** — dials down documentation per ISA 315.A15 / 510.A3 / 300.A10. Same conditional/N-A proportionality pattern already used in the procedure library, applied at engagement level.
