# Sprint 3 #2 — Audit Planning (rename + embed ISA 315) — RESUMED 2026-05-23

**Status:** RESUMED 2026-05-23 as Sprint 4 Task #5. The 4-AI standards-floor synthesis (2026-05-23) confirmed the parked design and the [[feedback-audexon-perplexity-benchmark]] rule moved this from "wait for partner to flag" to "build because standards require it." Migration `20260523120001_isa_315_understanding.sql` implements this spec. See commit log for ship details.

**Original status (2026-05-21):** PARKED. Not building this sprint. Pick up post-pilot if Qatar partner flags the ISA 315 gap during demo, or in Sprint 4.

**Decision basis:** Qatar partner gap list (May 2026) did NOT specifically flag ISA 315 understanding — they named planning + materiality + risk + completion memo + FS upload. Sprint 3 #3 (Risk Assessment matrix) and #5 (Inspection PDF) are the actual partner-facing wins for 2026-06-01 demo. Parking #2 frees ~1.5d of build velocity.

**Verdict from three-agent verification:** Option C — minimal — won. Refined by claude.ai into a stronger form: rename "Audit Strategy" → "Audit Planning" and embed ISA 315 as Section B inside the same workpaper. No new table. ALTER existing `engagement_audit_strategies`. One approval covers both ISA 300 and ISA 315.

Original 28-field standalone-workpaper spec at `sprint-3-understanding-entity.md` is superseded by this design when we revisit.

---

## Design (when we resume)

### Rename

UI label: **"Audit strategy"** → **"Audit planning"**. Two collapsible sections inside the existing panel:
- **A — Audit strategy (ISA 300)** — existing fields, unchanged
- **B — Understanding the entity (ISA 315)** — new fields below

### New columns to add to `engagement_audit_strategies`

| Column | Type | Purpose | ISA ref |
|---|---|---|---|
| `isa_315_inquiry_performed` | boolean | Attestation: inquiries of management performed | ISA 315.14(a) |
| `isa_315_analytical_performed` | boolean | Attestation: analytical procedures performed as RAP | ISA 315.14(b) |
| `isa_315_observation_inspection_performed` | boolean | Attestation: observation/inspection performed | ISA 315.14(c) |
| `industry_external_environment` | text | "What industry/regulatory changes affect this client's risk profile this year?" | ISA 315.19(a) |
| `internal_control_narrative` | text | IC strengths/weaknesses + IT systems in use ("Entity uses QuickBooks; IT risk low" satisfies SME minimum) | ISA 315.21-26 |
| `significant_changes_from_prior_year` | text | Ownership / management / business model / contracts / financing / going concern — partner fills as a *diff*, not from scratch | ISA 315.A47 |
| `fraud_team_discussion_date` | date | When the team fraud discussion was held | ISA 240 / ISA 315 |
| `fraud_team_discussion_attendees` | text | Attendees of the fraud discussion | ISA 240 / ISA 315 |

### Updated CHECK constraint

`status='approved'` adds to current rules:
- All three `isa_315_*_performed` true
- `fraud_team_discussion_date` IS NOT NULL
- `fraud_team_discussion_attendees` IS NOT NULL

### Risk Register gate (cross-sprint linkage)

Once Sprint 3 #3 ships, gate the Risk Assessment matrix so it cannot be opened until `fraud_team_discussion_date` is filled on the active strategy row. Forces the ISA workflow sequence (315 understanding → 315 fraud discussion → risk identification).

### Bonus UX

`significant_changes_from_prior_year` pre-populates the Risk Register header as context for the partner before they rate risks. Demonstrates Audexon understands the ISA 315 → ISA 330 linkage visually.

### Optional safety valve

If Qatar partner pushes during demo: add a collapsed 5-component IC checklist (control environment / risk assessment / information system / control activities / monitoring) with a free-text box per item. Build collapsed by default, promote to required only if partner requests.

---

## Why parked

| Reason | Detail |
|---|---|
| Not on Qatar gap list | Partner named planning/materiality/risk/completion memo/FS upload — not ISA 315 specifically |
| Risk matrix is the centerpiece | #3 is what the Qatar partner actually asked for — needs the velocity |
| PDF export is the demo headline | #5 is the inspection-readiness proof point — can't slip |
| Compressible | Refined design is ~1d build whenever we want |
| No architectural debt | ALTER TABLE, no new table, no new approval flow |

---

## Resume trigger

Revive this spec when ONE of:
- Qatar partner flags ISA 315 gap during 2026-06-01 demo → build immediately, ship before pilot signature
- Sprint 4 kicks off with no urgent partner items → fold in as quality-of-life
- Network inspector flags it during a pilot review

---

## Source material

Three-agent convergence on 2026-05-21:
- `Desktop\perplexity.txt` (lean — ISA doesn't require standalone workpaper, but current file must stand alone with per-year snapshot)
- `Desktop\copilot.txt` (delta analysis — unique ISA 315 content vs. duplicates)
- `Desktop\3.txt` (Option C refinement — rename + embed + Risk Register gate)

Decision log entry in `sprint-3-understanding-entity-go-no-go.md` § Decision log to be filled in once revived.
