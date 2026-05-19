# Qatar Pilot Feedback — 2026-05-19

Two-partner Qatar audit firm. ~40-minute live walkthrough of Audexon v0.5. Strongest pre-purchase signal Audexon has received to date.

---

## The room

- **Two partners present.** One drove the feedback throughout the session; the other observed without objection.
- **Speaking partner:** likely managing / business partner — owns direction and budget.
- **Silent partner:** likely technical / audit partner — would use the tool day-to-day for reviews and sign-offs.
- In a 2-partner small firm, software purchases at $100-400/mo are a joint call. The silent partner's endorsement is **not yet explicitly locked**. The next demo must engage him directly by name to either convert silence into a verbal yes or surface a hidden objection while the deal is still warm.

## Verbatim and near-verbatim quotes

- *"We invested 40 minutes of our time — if we weren't interested we wouldn't sit with you. Just solve our headache and pain area."*
- *"Willing to pay money if it takes the headache from me."*
- *"The current SaaS only covers the execution part of the audit. It serves the team, not the partner who has to do the planning, materiality, engagement, conclusion, risk assessment."*
- *(On opening the Going Concern test and reading the procedures)* *"It isn't specific."*
- *(On financial statements)* *"Don't get confused — I don't want generation. Even a place where I can upload them is fine. They tried to build a universal system for this and it failed because every client's FS is different."*
- *(On partner summary)* *"I need a summary section so that the partner can issue not just the correct opinion, but to ensure no risk is breached."*
- *(On standards)* *"Being a small firm doesn't mean we don't comply with local requirements. We also have international firms and collaborations we have to obtain — and to keep them, we have to do work in a certain way."*

## Decoded gap list (mapped to ISAs)

| # | What he said | What it means | ISA reference |
|---|---|---|---|
| 1 | "Serves the team, not the partner" | No planning binder — acceptance, independence, materiality, risk assessment, audit strategy all missing | ISA 220, 300, 315, 320, 330 |
| 2 | "Tests aren't specific" (Going Concern) | Procedures read like table of contents, not directive steps. Staff doesn't know *how* to execute | ISA 230, 570 |
| 3 | "Engagement isn't covered anywhere" | Engagement acceptance / continuance + engagement letter + independence missing as discrete workpapers | ISA 210, 220 |
| 4 | "Summary section" / "no risk breached" | Engagement Completion Memorandum — single rollup for partner before signing opinion | ISA 220 Revised |
| 5 | "Upload FS, not generate" | Parking slot for signed FS file (Word + PDF, versioned) — audit file completeness | — |
| 6 | "Local + international network requirements" | Must produce inspection-ready audit file that survives network quality reviews | ISA 220, ISQM 1, ISQM 2 |

## Qatar and international network angle (the market unlock)

Gulf small/mid firms are typically **correspondent or full members of international networks**:
- Networks (stricter): BDO, Mazars, Crowe, RSM, Moore, HLB, Baker Tilly, Grant Thornton, Nexia
- Associations (lighter): PrimeGlobal, Allinial Global, MGI Worldwide, Kreston, Praxity, Morison Global

Network membership requires **periodic quality inspection** (typically every 3 years). Inspectors pull a random engagement file and grade it against network methodology. Common findings that downgrade or expel firms:
- Missing planning documentation (ISA 300 strategy memo)
- No documented risk assessment at assertion level (ISA 315)
- Materiality rationale missing or weak (ISA 320)
- Procedures don't tie back to identified risks (ISA 330)
- No EQR where required (ISA 220 Revised, ISQM 2)
- Findings without ISA 230 documentation (who/what/when/why)
- No completion memo / partner sign-off evidence

**The real competitor isn't Excel — it's CaseWare or MKInsight,** which firms hate but use because their network mandates a compliant methodology platform.

## Positioning shift

**Old:** "Linear for audit — simple workpapers for small firms."

**New:** "The first inspection-ready audit platform built for small firms — survives network quality reviews and regulator file inspections without CaseWare overhead."

This answers the question *why would I pay $99-399/mo*. The answer is no longer "less Excel" — it's *"keep your network membership and your firm license."*

## International + configurable local strategy

Skip country-specific code. Build to **ISA + ISQM 1 + ISQM 2 + ISA 220 Revised** and automatically cover 80%+ of every market — UAE, Qatar, Saudi, Egypt, Kenya, Nigeria, South Africa, Malaysia, Singapore, India, Australia, UK, most of Europe / Africa / Asia / Latin America. Exceptions: US (PCAOB / AICPA), Japan, China.

Configurable per firm or per engagement: reporting currency, tax authority name, EoSB / gratuity rule, regulator name, audit report wording template (firm uploads their own — we do not draft jurisdictional opinions).

Add a 20th seeded section: **"Local Compliance & Regulatory"** — empty by default. Firm fills in procedures relevant to their jurisdiction (VAT, ESR, UBO, WPS, etc.) and the procedures propagate to every new engagement of theirs.

## Re-ordered build priority (for closing this partner)

| # | Item | Effort | Why this priority |
|---|------|--------|-------------------|
| 1 | Engagement Completion Memorandum + partner sign-off gate | 1-2 weeks | The single highest-leverage feature he asked for; required by ISA 220 Revised; protects the partner personally |
| 2 | FS upload slot on engagement page (draft / final / signed, versioned) | 1 day | Trivial build; audit file completeness; he asked for it explicitly |
| 3 | Local Compliance custom section + per-firm config | 2-3 days | International positioning with tailored compliance; no country code |
| 4 | Directive-style procedure rewrite (Going Concern + JET + Related Parties first) | 3-5 days | Directly addresses "tests aren't specific" — ISA 230 inspection-readiness |
| 5 | Engagement Letter + Independence + Acceptance/Continuance (3 new engagement-level sections) | 1 week | ISA 210, 220 — network requirement |
| 6 | Planning + Materiality + Risk Assessment module | 4-6 weeks | The biggest gap he raised; required by ISA 300, 315, 320, 330; required by network inspections |
| 7 | Inspection-ready PDF export overhaul | 2-3 weeks | The demo artifact that proves Audexon survives a network review — single most important pitch asset for every future Gulf demo |
| 8 | EQR workflow (ISQM 2) | bundled with #1 | Required for listed / PIE engagements; assign engagement quality reviewer, separate sign-off track |

**Sequencing strategy:**

- **Sprint 1 (Days 1-14):** Items 1, 2, 3, 8 → second demo. Show him the completion memo first.
- **Sprint 2 (Days 15-28):** Items 4, 5 → third demo. Procedure library + engagement-level workpapers.
- **Sprint 3 (Days 29-70):** Items 6, 7 → fourth demo. Planning module + inspection-ready PDF.
- **Lock paid pilot after Sprint 1 or 2.** Do not burn 6 weeks on the planning module without a contract.

## Emerging pricing / packaging direction

Selling the current product as-is to firms like Sahar's (who liked v0.5 unchanged) and selling the new methodology layer as a separate paid tier. Working name: **Essentials / Pro**.

| Tier | Members | Essentials | Pro |
|---|---|---|---|
| Starter | up to 5 | $49 | $99 |
| Team | up to 12 | $99 | $199 |
| Firm | up to 25 | $199 | $399 |

**Discovery question that decides the tier in 5 seconds:** *"Is your firm part of an international network or association?"*
- Yes → Pro (they need methodology compliance for network inspection)
- No → Essentials (they want less Excel, not full methodology)

**Pricing logic:** Pro = 2x Essentials. Still 3-5x cheaper than CaseWare ($800-1200/user/yr) and MKInsight (enterprise license). Network-affiliated partner pays $399 happily because the alternative is $10K+/yr CaseWare.

**Naming and price points not yet locked.** Revisit after second demo.

## Why this is significant (executive summary)

- **Two partners gave 40 minutes of billable time** (~$130-260 opportunity cost each = $260-520 combined) for free.
- **One stated conditional intent to purchase**, the other gave silent non-objection across the full session.
- **He gave the spec** for upgrading Audexon from "interesting demo" to "purchase order" — exact ISA-mapped gaps, with priority signal from his own pain.
- **He named the real competitor** (CaseWare / network methodology mandates), which unlocks the correct positioning across the entire Gulf small/mid-firm market.
- **He defined the bar for "good enough"** — survives a network inspection. Concrete and testable.

This is the strongest pre-purchase signal Audexon has received. Build sequence is locked by his pain, not by guesswork.

## Immediate next actions

1. **Send follow-up email within 24-48 hours of the demo** while the conversation is fresh. Address both partners by name (get the names if not captured). Confirm what's being built in the next 2 weeks (completion memo, FS upload, local compliance slot). Set the second demo date.
2. **Ask three discovery questions** in that email:
   - Which international network or association is your firm affiliated with?
   - When is your next network quality inspection?
   - At your last inspection, what did the inspector pull from the file first?
3. **Capture firm size** (total partners, total staff, engagements per year) — determines tier and deal size.
4. **Start the Sprint 1 build immediately.** Items 1, 2, 3, 8 → completion memo + FS upload + local compliance + EQR. Target: ready for second demo at day 14.

## Cross-references

- Product architecture and schema: `axiom-details.md` (in Claude memory — 59+ days old, partially stale on pricing and version)
- Roadmap: `ROADMAP.md` (in project root) — needs update to reflect this re-ordering
- Existing procedure library: `public/js/audit-templates.js` (Going Concern procedures at lines 165-172)
- Project brief: `PROJECT-BRIEF.md` (in project root)

---

*Last updated: 2026-05-19*
