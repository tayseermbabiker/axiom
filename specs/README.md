# Specs

Verification specs for shipped Audexon features. **One file per sprint feature.** Each spec must be cross-checked against Perplexity (ISA research) and Copilot (code review) before the sprint closes.

## Why these exist

We are building a regulated product as a solo founder. Claude + Copilot both miss things. The 2026-05-19 Qatar partner demo proved that a ranked gap list anchored on real ISA references beats guessing. To avoid rebuilding features later when partner demos surface gaps, every shipped feature gets a spec describing:

1. The partner gap it addresses (with verbatim quote where possible) + ISA standards it maps to
2. UI inventory — every tab, field, button, label, and what ISA requirement it satisfies
3. Data model — tables, columns, RPCs, triggers
4. Permissions + workflow — role gates, state transitions, tier gates
5. Out of scope — what was NOT built (prevents false-gap flags during review)
6. Judgment calls — places where one path was chosen over another, with reasoning (the highest-risk lines)
7. Verification questions for Perplexity (ISA deep research)
8. Verification questions for Copilot (code review)
9. Closure checklist — sprint closes only when every box is ticked

## File naming

`sprint-<N>-<feature-slug>.md` — e.g. `sprint-1-completion-memo.md`, `sprint-1-fs-upload.md`.

## Status legend

Inside each spec, the top status block tracks:
- **Shipped** — code in staging, awaiting verification
- **Verified** — Perplexity + Copilot questions resolved, gaps fixed or deferred
- **Closed** — checklist complete; will not be revisited unless production user surfaces a defect
