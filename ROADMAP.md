# Audexon Roadmap

Internal document. What we build now, what we park, what we revisit.

Last updated: 2026-05-18

---

## Phase 1 — Pre-pilot through first 20 firms (current, ~2026 Q2-Q3)

**Goal:** validate the core audit workpaper workflow with 5-20 paying firms.

Shipped:
- TB upload + auto-classification into 19 standard audit sections
- Three-level sign-off chain (preparer → supervisor → partner)
- Section reassignment, return-to-preparer / return-to-supervisor flows
- Findings with ISA 230 / 265 / 450 categorization
- Adjusting entries on misstatement findings
- Engagement close with open-finding acknowledgment + reopen with reason
- Activity log (immutable audit trail)
- PDF report export (basic, needs overhaul — see Phase 2)
- Bento landing page + 2-min demo video
- Access-code-gated free 3-month trial
- Stripe-ready pricing tiers ($49 / $99 / $199)

Outstanding for Phase 1 close:
- Lemon Squeezy or Stripe checkout live (currently routes to contact form)
- SPF/DKIM/DMARC on conferix.com for Resend email deliverability
- Sentry error monitoring
- UptimeRobot uptime monitoring
- Supabase Pro tier upgrade ($25/mo)
- RLS policy audit for airtight firm isolation

---

## Phase 2 — Post-pilot expansion (target: 2026 Q4 / 2027 Q1, revisit decision at 6 months)

These items are **parked**, not committed. We revisit each when one or more of these signals fires:

- 10+ paying firms asking for the same feature
- Phase 1 product-market fit signal is clear
- Cash flow supports the build cost
- Competitive pressure makes the feature table-stakes

### 2.1 Financial Statement Generator (IFRS/IAS-compliant)

**The opportunity.** CaseWare's CaseView product auto-generates IFRS-compliant financial statements (Statement of Financial Position, P&L, Cash Flow, Changes in Equity, Notes to FS) from the TB plus adjusting entries. In many UAE firms this is MORE valuable than the audit workpapers themselves because IFRS FS preparation in Excel is painful.

**What Audexon already captures.** Most of the source data: trial balance lines, account classifications, adjusting entries (via misstatement findings with debit/credit/amount), engagement metadata. The gap is the FS template layer and the disclosure / notes engine.

**Three implementation paths:**

| Path | What | Effort | When |
|---|---|---|---|
| A — Stay focused | Don't build FS at all; position Audexon as "the audit file, not the FS preparer" | 0 | Default if demand never materializes |
| B — Lightweight Excel export | "Download Adjusted TB" button exports TB + posted adjusting entries to Excel. Firm pastes into their existing IFRS template | ~1 day | Ship in Phase 1 if a pilot firm asks |
| C — Native FS generator | Build templates for IFRS for SMEs, then full IFRS. FS auto-populates from adjusted TB. Notes engine with cross-referencing. Sold as $99/mo add-on | 2-4 months full-time | Phase 2 if demand justifies |

**Decision trigger.** Revisit at 6 months. If 30%+ of pilot firms specifically ask for FS generation, go Path C. Otherwise stay Path A/B.

**Risk of going too early.** CaseView has been refined for 30 years. Building a mediocre version is worse than not having one. Auditors will judge the FS module against CaseView regardless of price.

### 2.2 Additional engagement types

Currently: **audit only**. Database supports review and compilation but UI hides them.

| Engagement type | What it adds | Build effort |
|---|---|---|
| Review engagement (limited assurance) | Reduced procedures, analytical-only workflow, no detailed substantive testing, single-level sign-off | 2-3 weeks |
| Compilation engagement (no assurance) | No procedures, just TB classification + FS prep, partner sign-off only | 1 week |
| Agreed-upon procedures | Custom procedure list per engagement, separate sign-off model | 2-3 weeks |

**Decision trigger.** Two pilot firms ask for review or compilation engagements.

### 2.3 PDF report overhaul

Current PDF export is **basic** — stats and summaries, not workpaper substance. Per memory: needs cover page, engagement conclusion, section-by-section workpapers with procedures + responses, findings detail, management letter points, filtered activity log. ISA 230 requires: nature/timing/extent of procedures, results, conclusions, who/when.

**Build effort:** 2-3 weeks full-time. Probably the most important Phase 2 item — your audit deliverable.

**Decision trigger.** Any pilot firm asks for a more complete PDF, OR before any audit is peer-reviewed.

### 2.4 Native mobile app

Currently the web app is responsive and works on mobile browsers. Native iOS/Android apps would add: push notifications when sections are returned to you, offline read-only mode for reviewing on a plane, file upload from phone camera.

**Build effort:** 6-8 weeks if using React Native or similar.

**Decision trigger.** 5+ firms ask for native mobile. Until then, mobile web is fine.

### 2.5 Accounting platform integrations

Direct sync from client accounting platforms instead of manual TB upload:
- Xero
- QuickBooks Online
- Sage 50 / Sage 200
- Wafeq (UAE local)
- Zoho Books

**Build effort:** 1-2 weeks per integration depending on API quality. Wafeq + Zoho Books should be first for UAE market.

**Decision trigger.** Pilot firms complain about manual TB upload friction.

### 2.6 Analytics (marketing + product)

Currently: **no analytics installed**. Confirmed 2026-05-18 — no Google Analytics, GTM, Plausible, PostHog, or any tracking in the codebase. Site is flying blind on visitor metrics by design, not by oversight.

**Why we're skipping now.** At pre-pilot scale, the signal we need (what's broken, what's confusing, what converts) comes from 30-minute pilot calls, not dashboards. A Google tag on a confidentiality-focused audit SaaS marketing site also slightly contradicts the pitch (the homepage that brags about your data not leaving your cloud shouldn't ship visitor behavior to Google).

**When to revisit.** Two thresholds:

1. **50+ paying firms** &mdash; product analytics (PostHog) becomes useful for spotting patterns at scale that 1:1 conversations can't catch.
2. **Cold marketing campaigns start** (cold email outreach, LinkedIn ads, content marketing) &mdash; marketing analytics (Plausible recommended for privacy fit) becomes necessary to measure which channel converts.

**What to install when the trigger fires.**

- **Marketing site:** Plausible or Fathom. Cookie-free, GDPR-compliant by default, ~$9/mo. No cookie banner required. Fits the confidentiality brand.
- **In-app:** PostHog (free tier generous). Self-hosted EU region if data sensitivity demands it. Configure session-recording carefully &mdash; never record TB numbers, conclusions, or findings text.
- **Never:** Google Analytics on the marketing site &mdash; conflicts with the confidentiality pitch and forces a cookie banner. If someone insists, push back with the Plausible alternative.

### 2.7 AI-assisted features

Per memory, the "Audexon Review module" idea — TB anomaly detection, leverages existing engine. Possible AI additions:
- TB anomaly detection (unusual journal entries, suspicious ratios, outlier balances)
- Auto-draft section conclusions from the procedure responses
- Risk assessment scoring based on TB classifications and historical data
- Auto-categorization of findings (ISA 265 vs 450 vs observation)

**Build effort:** 3-4 weeks for first iteration using Claude API or similar.

**Decision trigger.** Phase 1 stable, paying customers want assistance — not before.

---

## Phase 3 — Long-term (2027+, speculative)

Things we'd love to have but won't seriously consider until Phase 2 is producing results:

- White-label for accounting bodies (ICAEW, ACCA, CPA Canada) to offer Audexon to their members at scale
- Multi-language UI (Arabic, French for North Africa)
- Inspection-ready packaging (one-click MoET evidence pack, per AML SaaS notes)
- Peer review marketplace (firms can request peer review from credentialed reviewers inside Audexon)
- API for firm-built integrations
- Audit firm benchmarking dashboards (anonymized industry comparisons across our customer base)

---

## How we use this document

- **Don't build anything in Phase 2 or Phase 3 before its decision trigger fires.** The trigger is the discipline.
- **Update the "Last updated" date** whenever a Phase moves between sections (parked → in progress → shipped).
- **When a prospect asks for something not on this list**, write it down here in a "Phase 2.x — requested by prospect" subsection with the firm name and date. Patterns will emerge.
- **Revisit Phase 2 priorities at the 6-month mark** (target: 2026-11-18). The order may have changed by then based on what pilot firms actually asked for.

---

## Out of scope, permanently

Things we're explicitly NOT going to build, even if asked:

- A full ERP / general ledger system (compete with QuickBooks/Sage) — that's not our space
- Tax preparation (compete with Tax Star / Vat-it / Avalara) — that's not our space
- Document storage with our own file servers (would defeat the "files stay in your cloud" positioning)
- Bookkeeping services (we sell software, not services)
- Audit-as-a-service (we are the tool, not the auditor)
