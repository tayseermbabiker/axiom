# Audexon — Internal Bug Test Protocol

Internal-only QA protocol for catching defects before every release / demo / pilot lock-in. No external services, no signups — everything runs against your existing Supabase staging + Netlify deploy.

**When to run:** before every Qatar partner demo, every pilot onboarding, every major feature ship. Time budget: ~90 minutes for a full pass, ~30 minutes for a focused regression pass.

---

## 0. Setup — test accounts (one-time)

You need three accounts on the staging org to exercise role-based gates. Create them once and reuse for every test cycle.

| Role | Email convention | What it tests |
|---|---|---|
| Admin (partner) | `admin@audexon-test.com` | Full access — currently your founder account; nothing new to create |
| Supervisor | `supervisor@audexon-test.com` | Review chain, can edit but not delete/sign |
| Preparer (staff) | `preparer@audexon-test.com` | Fieldwork only, no approvals |

**Setup steps:**
1. Sign in as admin → Team page → invite both users with the correct roles
2. From a private browser window, accept each invite, set password, confirm landing on dashboard
3. Verify Team page shows all three with correct role badges

Once set up, you can hop between browser tabs/private windows to test each role's perspective without re-inviting.

---

## 1. Test plan structure — 3 passes per release

| Pass | Browser | Role | Focus | Duration |
|---|---|---|---|---|
| **A. Admin Pass** | Window 1 | Admin | Planning workpapers, sign-offs, memo, archive | ~40 min |
| **B. Supervisor Pass** | Window 2 (private) | Supervisor | Section review chain, finding edits | ~20 min |
| **C. Preparer Pass** | Window 3 (private) | Preparer | Procedure responses, finding raising | ~20 min |

For demo prep, prioritise Pass A. Passes B + C catch role-leak bugs (preparer seeing admin-only buttons, etc.).

---

## 2. Pass A — Admin (the full demo flow)

Use **`AUDEXON-CHEATSHEET-INITIAL.txt`** or **`AUDEXON-CHEATSHEET-CONTINUANCE.txt`** as the data script. Follow it step-by-step. The protocol below is what to look for AT EACH STEP, not the data values.

### A.1 — Dashboard landing

- [ ] Header subtitle reads `N engagements in progress · X sections awaiting partner review` (or similar — never empty/loading)
- [ ] 4 status tiles render with non-zero values where expected
- [ ] Clicking a tile filters the cards below
- [ ] Search filters by client name in real time
- [ ] Engagements grouped by client_name (same client across years sits together)
- [ ] "New Engagement" button visible

### A.2 — Engagement creation

- [ ] New Engagement modal opens
- [ ] Date picker rejects 5+ digit years (the year-20226 bug from before)
- [ ] Auto-seeds the 19 standard sections + Local Compliance template (if firm has one) + Risk Assessment + 2 ISA 240 presumed risks
- [ ] Lands on engagement page in **Planning phase** (admin = Planning per role-aware default)

### A.3 — Engagement page chrome

- [ ] Overview card renders: overall %, progress bar, 3 phase chips, quick stats
- [ ] Planning PDF and Completion PDF buttons in the overview card (not in header)
- [ ] Page subtitle shows client name + year-end + active status
- [ ] Phase chips clickable; clicking Execution / Conclusion switches phase

### A.4 — Acceptance (ISA 220 + 510)

- [ ] All form fields present (type, decision, integrity, competence, predecessor/prior-year branches, opening balances dropdown, partner attestation)
- [ ] Opening balances dropdown shows "Verified" / "N/A — continuance" / "(empty)"
- [ ] When status = "Verified", saving without notes is blocked with ISA 510 message
- [ ] After Confirm, form locks read-only; Revise decision button appears
- [ ] Predecessor block only visible when "Had predecessor" = TICK

### A.5 — Engagement Letter (ISA 210)

- [ ] Date fields cap at 9999-12-31
- [ ] File picker label: "Upload signed letter" when none attached → "Replace signed letter (optional)" when one attached
- [ ] After file upload, SHA-256 hash + filename shown in green status card
- [ ] Download button generates signed URL and opens file
- [ ] Reporting considerations block (ISA 700) fields editable
- [ ] After Sign, form locks; Revise letter button appears

### A.6 — Independence (ISA 220 R + IESBA)

- [ ] Fee dependence band dropdown: `< 10%` / `10–15%` / `15–20%` / `> 20%`
- [ ] Partner tenure number field, rotation required checkbox + rotation action textarea
- [ ] 5 IESBA threat blocks render with Present / Description / Safeguards / Conclusion
- [ ] After Save, hard-refresh once and verify all threat data persisted
- [ ] No NAS checkbox suppresses the NAS table
- [ ] Confirm independence locks form

### A.7 — Audit Planning (ISA 300 + ISA 315)

- [ ] Tab labelled **"Audit planning"** (not "Audit strategy")
- [ ] All 5 ISA 300.9 narratives present
- [ ] ISA-specific narratives section includes: internal controls overview, planning analytics, going concern, subsequent events, **Key laws & regulations (ISA 250)**, **Planned communications with mgmt & TCWG (ISA 260)**
- [ ] Understanding the entity (ISA 315) section: industry & external env, significant changes, 3 ISA 315.14 attestations (inquiry / analytical / observation)
- [ ] Approve blocked unless all 3 ISA 315.14 boxes ticked
- [ ] Budgeted hours field below EQR row (not inside the EQR row)
- [ ] Fraud team discussion: held checkbox + date + attendees (placeholder reads "e.g. J. Smith (Partner)")
- [ ] Approve planning locks form

### A.8 — Materiality (ISA 320)

- [ ] Benchmark dropdown + amount + percentage → overall materiality auto-computes
- [ ] Performance materiality % + reason (no_history / prior_misstatements / first_year / other) → amount auto-computes
- [ ] Trivial threshold % → amount auto-computes
- [ ] Specific materiality items add-row works
- [ ] Approve locks form

### A.9 — Risk Assessment (ISA 315 / 330 / 240)

- [ ] The 2 ISA 240 presumed risks auto-seeded (revenue recognition + management override)
- [ ] If a section is deleted that hosted a presumed risk, the risk survives in a red "Unlinked — re-link required" group at the top
- [ ] Custom risks can be added; require section + assertion + ratings + linked procedures (for significant risks)
- [ ] Significant risk without linked procedures blocks confirmation
- [ ] Confirm requires all 4 attestations ticked

### A.10 — Switch to Execution phase

- [ ] Trial Balance tab: upload CSV/Excel, classifications tagged, version replacement supported
- [ ] After TB replace, Edit Tags dialog shows ONLY current-version classifications (no zombie tags)
- [ ] Sections auto-populate based on TB classifications
- [ ] Section assignee dropdown shows partner (J. Smith) as selectable — not blank

### A.11 — Sections + Procedures + ISA 530 Sampling

- [ ] Open a section, expand a procedure
- [ ] "+ Sampling" button visible next to "Mark as Done"
- [ ] Sampling modal: 9 fields (population, pop size, sample size, method, basis, results, projection, conclusion, notes)
- [ ] Sample size > population size blocked
- [ ] After save, inline summary chip appears in the procedure body
- [ ] Button label flips to "Edit sampling"

### A.12 — Findings (ISA 450)

- [ ] Raise 3 findings:
  1. Posted AJE — revenue cut-off, AED 22,000
  2. Unposted AJE — AR allowance, AED 45,000, close_category = communicated_to_management
  3. Clearly trivial — AED 1,200, close_category = unadjusted_immaterial

### A.13 — Estimates (ISA 540)

- [ ] Estimates tab in Execution phase between Findings and Financial statements
- [ ] Add 2 estimates (EoSB + doubtful debts) via modal
- [ ] Risk badge colors render (low green / medium amber / high red / significant dark red)
- [ ] Linked section dropdown lists current engagement's sections

### A.14 — Confirmations (ISA 505)

- [ ] Confirmations tab in Execution phase
- [ ] Add bank (clean), AR (exception), bank (no_reply) confirmations
- [ ] When result is `exception` or `no_reply`, save blocked until alternative_procedures filled
- [ ] Status summary chips above the table show correct counts

### A.15 — Approve & Close → Completion Memo

- [ ] Section sign-off chain: preparer submits → supervisor approves → partner approves
- [ ] All sections approved → "Approve & Close Engagement" enabled
- [ ] Completion memo opens; status = draft
- [ ] **Rollup tab**: misstatement schedule shows 3 groups (Corrected / Uncorrected / Clearly trivial)
- [ ] Impact column does NOT show 0 when AJE amount is filled (the fallback fix)
- [ ] Σ Uncorrected vs overall materiality % shown
- [ ] **Narrative tab**: GC (structured dropdown + rationale), SE (structured), Final analytical, Uncorrected mistatements eval + mgmt rationale, Final independence conclusion
- [ ] **Reps & Comms tab**: MRL + TCWG
- [ ] **Opinion tab**: opinion dropdown; basis textarea ONLY for modified opinions
- [ ] **EQR tab**: not required = auto-pass
- [ ] **Attestations tab**: 9 auto-checks green; 3 manual ticked
- [ ] Sign and Lock fires; status flips to LOCKED & SIGNED with date + partner name (not "by —")

### A.16 — Archive (ISA 230)

- [ ] "Archive (ISA 230)" button appears next to Reopen after memo lock
- [ ] Click → confirm dialog → archived banner appears with date
- [ ] All edit affordances hidden
- [ ] "Unarchive (post-assembly change)" button available for admin

### A.17 — PDFs

#### Planning PDF
- [ ] Cover: client name, year-end, **Engagement partner shows real name** (not org name / not blank), file status, report generated date
- [ ] No "Engagement supervisor" line on cover (removed for solo firms)
- [ ] Acceptance section includes Opening Balances (ISA 510) sub-block when filled
- [ ] Independence section: status, fee%, tenure with ROTATION DUE badge if applicable, IESBA threats table renders **content** (not blank rows — verifies the column-name fix)
- [ ] NAS table renders Service / Description / Threat / Prohibited / Safeguards (no dead Fee column)
- [ ] Audit Planning section: header reads "(ISA 300 + ISA 315)"; ISA 250 + 260 lines present
- [ ] Risk assessment matrix + register render

#### Completion PDF
- [ ] Cover stats: opinion, findings (open / total), AJE entries posted, sections approved
- [ ] Misstatement Schedule (ISA 450): line-by-line grouped, Σ matches narrative (no 0 vs 45K contradiction)
- [ ] Significant Accounting Estimates (ISA 540) section renders
- [ ] External Confirmations (ISA 505) with alternative_procedures column
- [ ] Audit Sampling Documentation (ISA 530) — per-procedure cards
- [ ] Completion Memo block: opinion, materiality, Going Concern, Subsequent Events, Final Analytical Review, Uncorrected Misstatements Evaluation, Final Independence, MRL, TCWG, File Assembly stamp (when archived)

---

## 3. Pass B — Supervisor

Login as supervisor in private window. Open the engagement created in Pass A.

### B.1 — What supervisor CAN do
- [ ] See the engagement on the dashboard (counts visible)
- [ ] Open the engagement page → lands on Execution by default (role-aware)
- [ ] Upload / replace TB
- [ ] Create / edit / reassign sections (but NOT delete)
- [ ] Add procedures, add review comments on sections
- [ ] Move sections through supervisor review states (supervisor_approve, supervisor_return)

### B.2 — What supervisor MUST NOT do (test these are HIDDEN or DISABLED)
- [ ] **Cannot create new engagement** — "New Engagement" button hidden on dashboard
- [ ] **Cannot delete an engagement** — Delete button hidden on cards
- [ ] **Cannot delete a section** — Delete button hidden in section list
- [ ] **Cannot author/confirm Pro workpapers** — Acceptance, Engagement Letter, Independence, Audit Planning, Materiality, Risk Assessment forms show Pro-blocked or read-only
- [ ] **Cannot partner-approve a section** — only supervisor-approve allowed
- [ ] **Cannot sign completion memo**
- [ ] **Cannot archive engagement**
- [ ] **Compliance Template nav hidden** in sidebar

### B.3 — Role leak check
Hover over admin-only buttons. Console errors? Hidden via `display:none` only, or actually guarded server-side? Try directly typing the admin URL (`/local-compliance.html`) — should redirect or show Pro/Admin blocked banner, NOT the editor itself.

---

## 4. Pass C — Preparer (staff)

Login as preparer in private window. Open same engagement.

### C.1 — What preparer CAN do
- [ ] See engagement on dashboard
- [ ] Open engagement → lands on Execution by default
- [ ] Open any section
- [ ] Respond to procedures (write what they did + save + mark as Done)
- [ ] Upload work-paper / source-doc links inside procedure responses
- [ ] Raise findings on sections they're working
- [ ] Submit a section for supervisor review

### C.2 — What preparer MUST NOT do
- [ ] **Cannot create / delete engagement**
- [ ] **Cannot upload / replace TB** — buttons hidden
- [ ] **Cannot create / delete / reassign sections**
- [ ] **Cannot edit findings** (raise yes, edit no)
- [ ] **Cannot supervisor-approve / partner-approve**
- [ ] **Cannot author Pro workpapers**
- [ ] **Cannot sign memo / archive**

### C.3 — Section view toggle
- [ ] Section list shows "My sections only" toggle (preparer-specific)
- [ ] Filtering to "My sections" only shows sections where assigned_to = current user
- [ ] All sections still visible if they toggle back to "All"

---

## 5. Sprint 4 module regression matrix

For each module, verify the green-path behavior + the most likely break:

| Module | Green path | Most-likely break |
|---|---|---|
| **ISA 450** misstatement schedule | 3 findings render in 3 groups | Impact = 0 when only AJE amount filled (verifies impact fallback) |
| **ISA 540** estimates | Add via modal, renders with risk badge | Section dropdown empty (verifies sections loaded before modal opens) |
| **ISA 505** confirmations | Add 3 with different results, summary chips update | Save without alt-procs on exception/no_reply (verifies ISA 505.12 gate) |
| **ISA 530** sampling | + Sampling on procedure card opens modal | Sample size > population blocks save |
| **ISA 315** understanding | Approve planning with all 3 procedure attestations | Approve blocked when any of the 3 unticked |
| **ISA 510** opening balances | "Verified" path requires notes | Save Verified without notes blocked |
| **ISA 230** archive | Button appears after memo lock | Button does NOT appear if memo unsigned |

---

## 6. Demo-killer regression checklist (known previously-fixed bugs)

Hit these explicitly every run — they've broken before:

- [ ] **Date year-20226 bug** — every date input rejects 5+ digit years
- [ ] **Independence threat data persistence** — fill all 5 threats, save, refresh, verify threat data is in the PDF
- [ ] **Signer name resolution** — completion memo PDF shows real partner name (not "—" or org name)
- [ ] **Misstatement schedule impact fallback** — when finding.monetary_impact is null but AJE has amount, schedule shows AJE amount not 0
- [ ] **TB tag dialog superseded-version filter** — replace TB, open Edit Tags, no zombie tags from old version
- [ ] **Section assignee dropdown solo-firm fallback** — partner is selectable in the dropdown
- [ ] **Presumed risks survive section delete** — delete a section that had presumed risks linked; risks appear in "Unlinked" group, not gone
- [ ] **Browser autofill disabled** — re-typing in a field that was filled earlier does not show stale suggestions
- [ ] **Engagement letter file picker label** — switches between "Upload" and "Replace" based on whether file is attached
- [ ] **Names placeholder** — fraud attendees placeholder reads "J. Smith (Partner)" not "T. Babiker / S. Khan / J. Doe"

---

## 7. After-run reporting

Capture defects in a single text file under `docs/test-runs/<YYYY-MM-DD>.md`:

```
# Test run 2026-05-27

## Failed
- [Pass A.7] ISA 250 field not visible — migration 20260524120000 not applied to staging
- [Pass B.2] Supervisor sees Delete button on engagement cards (should be hidden)

## Passed
- All else

## Action items
- Re-apply migration on staging
- Hide Delete from supervisor card render path in dashboard.html
```

Then create the bug fixes immediately if demo is imminent.

---

## 8. What this protocol explicitly does NOT need

| Tool / service | Why not |
|---|---|
| Codacy / SonarCloud / DeepSource | Internal protocol — manual + scripted checks only |
| GitHub Copilot review subscription | Not used — we have Claude Code locally |
| Playwright / Cypress / external test runners | Demo-day testing is human-led; automated tests are Sprint 5+ |
| Bug tracker (Jira / Linear / GitHub Projects) | Defects live in `docs/test-runs/<date>.md`, fixed inline; if it grows, GitHub Issues is the upgrade path |
| External penetration / fuzz testing service | Defer to post-revenue |

Everything in this protocol runs against tools you already own: Supabase staging, Netlify deploy, your existing Claude Code Audexon project, your browser.

---

## Closing

Run Pass A end-to-end at minimum 24 hours before any demo. Run Passes B + C at minimum once before any new pilot lock-in. Update this document whenever Sprint N ships new modules — add to Section 5 (regression matrix) and Section 6 (demo-killer checklist).
