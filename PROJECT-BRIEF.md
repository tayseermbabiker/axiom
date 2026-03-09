# PROJECT BRIEF — Audit SaaS

## What is this?
A modern workpaper manager for small audit firms (5-20 people) that links trial balance lines to workpapers and source documents, with tamper-proof sign-offs and a clear audit trail.

"Linear for Audit" — simple, fast, opinionated. Not enterprise. Not legacy.

## The problem
Small audit firms use Excel files in shared folders, email, WhatsApp, USB drives, and printed binders to manage audit evidence. There is no link between a trial balance number and the document that proves it. Nobody knows what's done, who reviewed what, or where the supporting documents are. This hasn't changed in 15+ years.

## Who is it for?
- Small/mid audit firms: 5-20 people
- Currently using Excel/Word + shared folders
- No CaseWare, no AuditFile, no modern tooling
- UAE first (test market), USA for revenue

## Positioning
- NOT "Ivalua for Audit" (too ambitious, too enterprise)
- IS "Linear for Audit" — simple, modern, affordable workpaper & TB workflow
- Position as "workpaper and TB workflow for small firms" NOT "complete audit software"
- Competitors: Fieldguide (enterprise, $10k+), AuditFile (closest, $99-149/mo flat), CaseWare Cloud (per-user, complex), DataSnipper (Excel-bound), MKInsight (popular in UAE/GCC, expensive, dated UI), SmartAudit (~$99/mo)
- Our edge: dead simple, modern UI, flat-tier pricing, built for firms under 25 people
- No existing tool positions itself as "Linear-style, opinionated, super-simple workpapers" for 3-25 person firms — they all skew enterprise or bundled

---

## Survey Validation (March 2026 — 2 UAE respondents)

Both respondents: 6-15 person firms.

| Question | Respondent 1 | Respondent 2 |
|----------|-------------|-------------|
| Workpaper tool | Excel/Word in shared folders | Excel/Word in shared folders |
| Client docs via | Cloud storage (Google Drive/OneDrive) | USB/hard drive + in person/printed |
| Evidence linking | Excel cross-references | Excel cross-references |
| Peer review ready? | Very confident | Somewhat confident |
| Problems faced | Staff duplicating work (can't see what's done) | Difficulty finding supporting docs during review |
| Hours wasted/week | 2-5 hours | 5-10 hours |
| Would tool help? | Very useful | Very useful |
| Biggest time waster | (no answer) | "Required information not available" |

Key takeaways:
- 100% use Excel/Word in folders — zero modern tooling
- 100% use manual Excel cross-references for evidence linking
- 100% said tool would be "very useful"
- Combined 7-15 hours/week wasted on organizing and searching
- Two complementary pains: no visibility into progress + can't find documents

---

## Pricing (flat-tier, not per-seat)
| Plan | Members | Price | Per-user |
|------|---------|-------|----------|
| Starter | up to 5 | $99/mo | ~$20/user |
| Team | up to 12 | $149/mo | ~$12/user |
| Firm | up to 25 | $299/mo | ~$12/user |

- Flat tiers = predictable cost, no seat management friction
- $99 entry = crosses "serious software" threshold (not suspiciously cheap)
- Still 3-5x cheaper than AuditFile/CaseWare at equivalent team sizes
- "9" ending — proven SaaS pricing psychology
- Free trial: 1 engagement, no credit card
- Revisit pricing at v0.4 when materiality/risk/templates are added (potential hybrid: base + per-engagement)

Sources: Validated against Gemini + Perplexity + Copilot market research (March 2026)

---

# MVP SCOPE (v0.2 — "Show it to a friend")

## Core architecture
```
Organization (the firm, flat-tier plan)
  └── Engagement (client + year-end)
        ├── Trial Balance (imported from Excel/CSV)
        └── Audit Sections (Cash & Bank, AP, AR, Revenue, Opex, etc.)
              ├── TB Lines (grouped into this section)
              ├── Audit Procedures (admin-defined tests, up to ~15 per section)
              │     ├── Type: Test of Detail / Analytical / Controls / Other
              │     └── Procedure Responses (preparer fills in + attaches docs)
              ├── Findings (issues discovered during testing)
              │     ├── Severity: High / Medium / Low
              │     ├── Status: Open / Resolved / Reported
              │     └── Management Response
              ├── Section Conclusion (preparer writes, reviewer approves)
              ├── Review Notes (thread between reviewer and preparer)
              └── Assigned To (team member — preparer)
```

## What it does
1. **Organization/team**: create firm, invite members by email, roles (admin/reviewer/preparer)
2. **Engagements**: create engagement (client, year-end, type: audit/review/compilation)
3. **TB import**: upload Excel or CSV with smart column auto-mapping (handles DR/CR or single balance)
4. **Audit sections**: group TB lines into areas (Cash & Bank, AR, AP, Revenue, etc.), assign to team members
5. **Audit procedures**: admin defines custom tests per section (Test of Detail, Analytical, Controls, Other)
6. **Procedure responses**: preparer fills in response for each procedure, attaches supporting docs, marks done
7. **Findings**: preparer logs issues found during testing (severity, status, monetary impact)
8. **Section conclusion**: preparer writes short conclusion, reviewer approves
9. **Review workflow**: submit for review → reviewer comments → return to preparer → approve (immutable sign-off)
10. **Activity log**: every action logged (who did what, when) — immutable, cannot be edited or deleted
11. **Dashboard**: sections progress, open findings by severity, team workload

## What it does NOT do (yet)
- No reconciliation engine
- No AI anything
- No client portal / PBC request list
- No QuickBooks/Xero integration
- No billing/subscription (free for testing)
- No materiality table or risk assessment engine
- No assertion mapping (optional later)
- No procedure template library (reusable across engagements — v0.3)
- No rollforward / prior-year import
- No management letter auto-generation
- No offline mode

## User flow
1. Admin signs up → creates firm → invites team members
2. Admin creates engagement: "ABC Company — FY 2025"
3. Admin uploads trial balance (Excel/CSV) — smart column mapping
4. Admin creates audit sections (Cash & Bank, Revenue, Opex...), groups TB lines, assigns to team members
5. Admin adds audit procedures to each section (custom tests)
6. Preparer opens assigned section → sees procedure checklist
7. For each procedure: writes response, attaches supporting docs (bank confirmation, invoices...), marks done
8. If preparer finds an issue → logs a Finding (severity, details)
9. Preparer writes section conclusion → submits for review
10. Reviewer reviews responses + docs → adds review comments → approves or returns with reason
11. Dashboard shows: 3/8 sections approved, 2 open findings (1 High), team workload
12. Activity log shows full trail per engagement — who did what, when

---

# TECH STACK

## Decided
- **Database + Auth + Storage**: Supabase (free tier to start)
  - PostgreSQL for all data
  - Supabase Auth for login
  - Supabase Storage for file uploads (PDFs, images, Excel)
  - Row Level Security for data isolation
- **Frontend**: Vanilla HTML/CSS/JS (same approach as other projects)
- **Hosting**: Netlify (static site + functions if needed)
- **Email**: Resend (for transactional emails later)
- **No n8n**: confirmed — not sustainable for a real product
- **No Airtable**: confirmed — need real relational database

---

# DATABASE SCHEMA (v0.2 — Organization + Sections based)

## profiles (extends Supabase auth.users)
- id (uuid, PK, FK -> auth.users)
- email, full_name, created_at

## organizations (the audit firm)
- id, name, plan (starter|team|firm), max_members, created_by, created_at

## organization_members
- id, organization_id, user_id, role (admin|reviewer|preparer), created_at
- unique(organization_id, user_id)

## organization_invites
- id, organization_id, email, role, invited_by, status (pending|accepted|expired), created_at

## engagements (belongs to org)
- id, organization_id, client_name, year_end_date, engagement_type, status, created_by, created_at

## trial_balance_lines
- id, engagement_id, account_code, account_name, balance, classification (asset|liability|equity|revenue|expense|unclassified), created_at

## audit_sections (replaces workpapers — grouped by audit area)
- id, engagement_id, name (e.g. "Cash & Bank"), assigned_to (FK -> profiles), status, conclusion, conclusion_by, approved_by, approved_at (IMMUTABLE), created_at, updated_at, sort_order

## section_tb_lines (links TB lines to sections)
- id, section_id, trial_balance_line_id
- unique(section_id, trial_balance_line_id)

## audit_procedures (admin-defined tests per section)
- id, section_id, description, procedure_type (test_of_detail|analytical|controls|other), sort_order, created_at

## procedure_responses (preparer fills in)
- id, procedure_id, user_id, response (text), status (pending|done), created_at, updated_at

## documents (attached to procedure responses OR sections)
- id, section_id (nullable), procedure_response_id (nullable), file_name, file_path, file_size, file_type, uploaded_by, created_at

## findings (issues discovered during testing)
- id, section_id, procedure_id (nullable — for roll-up flexibility), reported_by, title, condition, criteria, cause, effect, recommendation, management_response, severity (high|medium|low), status (open|resolved|reported), monetary_impact (numeric, nullable), created_at, updated_at

## review_notes (APPEND-ONLY — immutable)
- id, section_id, user_id, note, note_type (review_comment|preparer_response|return_reason), created_at

## activity_log (APPEND-ONLY — immutable)
- id, engagement_id, user_id, action, target_type, target_id, details (jsonb), created_at

---

# TEST CASE — "Show it to a friend"

## What to demonstrate
Give your friend access. Ask them to:
1. Create an engagement for a real or fictional client
2. Upload a trial balance (even a simple 10-line CSV)
3. Create workpapers for 3-5 TB lines
4. Upload a few documents (any PDFs)
5. See the dashboard — which lines are done, which aren't
6. Try the sign-off flow

## What to ask them after
1. "Does this match how you think about organizing audit files?"
2. "What's missing that would make you actually use this?"
3. "Would you pay $100/month for this if it had [their missing feature]?"
4. "What would you show your team first?"

## Success criteria
- They understand the flow without explanation
- They say "I wish we had this" or similar
- They identify 1-2 missing features (that become v0.2)
- They don't say "we already have something like this"

---

# ROADMAP

## v0.2 — "Show it to a friend" (BUILD NOW)
- Organization/team system (create firm, invite members, roles)
- Flat-tier pricing structure (starter/team/firm)
- TB import with smart Excel/CSV column mapping (DR/CR support)
- Audit sections (group TB lines into areas, assign to team members)
- Audit procedures (admin-defined custom tests per section)
- Procedure responses (preparer fills in + attaches docs)
- Findings tracker (severity, status, per-procedure or per-section)
- Section conclusion (preparer writes, reviewer approves)
- Review workflow (submit → comment → return → approve, immutable sign-off)
- Activity log (immutable, who did what when)
- Dashboard (section progress, findings summary, team workload)
- Two-level sign-off (prepared_by + approved_by)

## v0.3 — "Let a firm try it" (after friend feedback)
- Procedure template library (reusable across engagements)
- Materiality table (overall, performance, trivial threshold)
- Risk assessment (inherent/control risk per section, link to procedures)
- Assertion mapping (optional — Existence, Completeness, Accuracy, Cutoff, Valuation, R&O, Presentation)
- Management letter auto-generation from findings (condition, criteria, cause, effect, recommendation)
- Rollforward — import prior-year engagement as starting point
- Search across sections, procedures, and documents
- Files on client's Google Drive (swap from Supabase Storage)
- Email notifications (assignment, sign-off reminders, findings alerts)

## v0.4 — "Charge money"
- Subscription billing (Stripe)
- Export audit file as ZIP package
- PBC request list (simple checklist with status tracking)
- 60-day archiving countdown + auto-lock
- Engagement-level sections (Planning, Going Concern, Subsequent Events, Related Parties)
- Cross-referencing between sections/procedures/findings
- Disclosure checklist

## v1.0 — "Real product"
- Client portal (clients upload docs directly, mapped to PBC list)
- Basic reconciliation helper
- Encrypted storage option (premium tier)
- Engagement-specific role permissions
- AI-assisted first-pass testing (future differentiator)

---

# COMPETITIVE LANDSCAPE (validated March 2026 — Gemini + Perplexity research)

## Direct Competitors
| Product | Pricing | Target | Threat |
|---------|---------|--------|--------|
| AuditFile | $99-149/mo flat | Small/mid firms | HIGH — closest match |
| Fieldguide | $10k-25k+/yr | Mid-large firms | LOW — different segment |
| CaseWare Cloud | $800-1200/user/yr | All (heavy on mid-large) | MEDIUM — complex setup, hated by small firms |
| DataSnipper | ~$64/user/mo | All sizes | LOW — Excel add-on only |
| MKInsight | Enterprise annual license | UAE/GCC mid-large | MEDIUM — popular in our test market, dated UI |
| SmartAudit | ~$99/mo | Small/mid firms | MEDIUM — cloud workpapers |

## Adjacent (PBC/Workflow)
Suralink, AuditDashboard, Financial Cents, Karbon, TaxDome, Canopy, Inflo

## Emerging threats
- Inflo — "Digital First" audit, strong client collaboration
- TaxDome — not audit-specific but firms force audit workflows into it
- Agentic AI startups — auto-audit tools performing first-pass testing

## Our Position
None of the above position as "Linear-style, opinionated, super-simple workpapers" for 3-25 person firms. They all skew enterprise, bundled, or Excel-bound.

## Defensibility
- Evidence graph (TB -> sections -> procedures -> responses -> docs) is a data model, not a feature
- Immutable audit trail is architecture, not a checkbox
- Once firms adopt as system of record, switching cost is very high
- Flat-tier pricing removes the per-seat friction that competitors impose

---

# KEY DECISIONS LOG

| Decision | Choice | Reason |
|----------|--------|--------|
| n8n | NO | Not sustainable for real product |
| Airtable | NO | Need real relational DB |
| Framework | Vanilla JS | Keep it simple, build what you know |
| Database | Supabase (PostgreSQL) | Already know it from PlainFinancials |
| Market | UAE test, USA revenue | UAE for relationships, USA for willingness to pay |
| Pricing | $99-299/month flat tier | Undercut all competitors, no per-seat friction |
| MVP scope | Sections + procedures + findings | Not just workpapers — real audit workflow |
| Approach | Start small, grow organic | No VC, no over-engineering |
| Data storage | Hybrid — files on client's Google Drive, metadata on Supabase | Trust-first: "your files never leave your Drive." Immutable audit trail stays on our DB (tamper-proof). Builds trust as unknown brand. |
| Storage roadmap | v0.1: all Supabase (fast to build). v0.2: Google Drive for files. Later: encrypted Supabase as premium option | Don't let integration slow down v0.1. Swap storage layer after flow is proven. |

---

# STRATEGIC WARNINGS (from Copilot review, March 2026)

## Risk #1: "Just another document manager"
If firms see this as a nicer Google Drive or a prettier folder structure, they won't switch.
Everything — UI, language, flow — must scream AUDIT. TB lines, workpaper references,
sign-off chains, completion percentages. Not generic files and folders.

## Risk #2: Marketing must target two audiences differently
- Partners buy on: compliance fear (AU-C 230), peer review risk, liability reduction
- Staff adopt on: less busywork, clear instructions, no training needed
- Landing page needs both messages: "Reduce peer review risk + cut audit time by 20%"

## Risk #3: What makes firms actually switch (3 conditions)
1. Switching saves partner time (5-10 hours per engagement)
2. Switching reduces risk (immutable trail, locked sign-offs, archive compliance)
3. Switching doesn't disrupt staff (UI feels like Google Drive + Notion, zero training)
All 3 must be true or they won't move off Excel.

## Deferred features that become critical in v0.3
- Procedure template library — so firms reuse tests across engagements
- Materiality + risk assessment — ISA 315 compliance
- Rollforward (prior-year import) — essential for retention after first year
- PBC request list — solves document chaos at the source
- Management letter auto-generation — the deliverable clients actually receive
These are NOT in v0.2 but MUST be in v0.3 or firms won't adopt long-term.

## Copilot feedback (March 2026)
- Data model aligns with ISA 230, ISA 315, ISA 330 documentation requirements
- Findings should belong to procedure (nullable) + always to section (for roll-up)
- Management letter structure: condition, criteria, cause, effect, recommendation, management response
- Section conclusion is expected by reviewers — add it
- Don't enforce assertion mapping at MVP — make optional later
- Don't over-engineer procedure types — flat list is enough
- MKInsight uses Engagement → Areas → Workpapers → Procedures → Findings tied to workpapers
- AuditFile uses Programs → Procedures → Subprocedures → Findings tied to procedures
