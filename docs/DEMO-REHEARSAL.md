# Demo rehearsal — Qatar partner pilot 2026-06-01

A scripted end-to-end walkthrough on staging that exercises every Sprint 4 standards-floor feature alongside the existing core flow. Run this **at least once** before demo day. The seed data below is designed so every new module produces something visible — if a step does nothing or shows an empty state, you have a bug to fix before the partners log in.

**Environment:** `https://staging--auditsaas.netlify.app/`
**Supabase:** staging project `lbwowlvajgpdxsdpudem`
**Prerequisites:** all 5 Sprint 4 migrations applied (`20260523120000` through `20260523120004`) — confirmed by you 2026-05-23.

Estimated time: 45–60 min. Slower than the live demo because we click everything; the demo itself is ~20–25 min.

---

## 0. Seed identity (fictional client)

Pick one fictional engagement for the rehearsal and reuse the same fields for the live demo. Continuance engagement so ISA 510 routes through the cheap path (the N/A branch) — keeps the demo narrative clean.

| Field | Value |
|---|---|
| Client name | **Falcon Trading LLC** |
| Year-end | **2025-12-31** |
| Engagement type | **Continuance** |
| Industry | Trading — auto parts |
| Reporting framework | IFRS for SMEs |
| Overall materiality | **AED 250,000** (5% PBT) |
| Performance materiality | **AED 187,500** (75% of overall) |
| Headcount | 24 (drives EoSB estimate) |
| Partner / Manager / Senior | use your existing staging users |

Memorise this card. Partners read fast — every number you type wastes their attention.

---

## 1. Pre-flight (5 min)

- [ ] Open `https://staging--auditsaas.netlify.app/` in a private window. Log in as the **admin** (partner) account.
- [ ] Dashboard renders, no Sentry errors in DevTools console.
- [ ] Verify your org is on **Pro** tier — go to Team / Settings (whichever page shows it). If not, set it via the admin UI or directly in Supabase: `UPDATE organizations SET feature_tier = 'pro' WHERE id = '<your org>';`
- [ ] Confirm at least one **other** user exists for review-note demonstrations later (supervisor or preparer).

If any of these fail, fix before continuing — partners won't tolerate a stuck login.

---

## 2. New engagement (3 min)

- [ ] From dashboard, create new engagement with the Falcon Trading data above.
- [ ] Lands on the engagement page in **Planning** phase, on the **Overview / Acceptance** tab depending on default.

**Expected:** sidebar / phase stepper shows Planning · Execution · Conclusion. Module tabs for Planning are now: Overview, Acceptance, Engagement letter, Independence, **Audit planning** (renamed Sprint 4 — was "Audit strategy"), Materiality, Risk assessment.

If the tab still says "Audit strategy", the Sprint 4 deploy didn't pick up `e007839` — hard-refresh or check Netlify deploy status.

---

## 3. Planning phase — Acceptance (ISA 510 path)

Open **Acceptance** tab.

- [ ] Type: **Continuance**. Decision: **Accept**. Decision date: today. Rationale: "Repeat client, no material changes."
- [ ] Risk tier: **Medium**.
- [ ] Integrity: tick "Prior experience" + "Internet search". Integrity conclusion: "No adverse media; ten-year client relationship."
- [ ] Competence: tick. Notes: "Existing team carries forward."
- [ ] Prior-year issues: tick. Summary: "No material findings prior year."
- [ ] **NEW — Opening balances (ISA 510):** dropdown → **"N/A — continuance engagement"**. Leave notes blank (continuance route doesn't require them).
- [ ] Partner attestation: tick. Date: today.
- [ ] Click **Confirm decision**.

**Expected:** workpaper locks; status badge flips to "Confirmed" green; a Revise button appears.

**Bug-hunt:** if you try Confirm with status=`Verified` and no notes, the form should block with the ISA 510 message. Test this path quickly by editing to Verified, attempting Confirm, getting blocked, then switching back to N/A.

---

## 4. Planning — Engagement Letter + Independence

Skip the deep walk (no Sprint 4 changes here). Just:

- [ ] Engagement letter: upload any test PDF. Save dates + signatory + ISA 210 attestations.
- [ ] Independence: at least the parent row + ISA 220 R checkbox so the downstream attestations don't system-fail.

---

## 5. Planning — **Audit planning** (ISA 300 + ISA 315 embedded) — Sprint 4 centerpiece

Open **Audit planning** tab (formerly "Audit strategy"). This is where ISA 315 was un-parked.

- [ ] Scope characteristics: "IFRS for SMEs framework; single-entity trading company in UAE."
- [ ] Reporting objectives: "Audit report due 2026-03-31; one-week buffer for partner final review."
- [ ] Significant factors: "Prior year clean; new VAT-inspection focus on related-party transactions noted by industry."
- [ ] Preliminary engagement activities summary: "Acceptance and continuance confirmed; independence confirmed; no scope limitations."
- [ ] Resources plan: "Senior + manager + partner. No specialists. EQR not required (Falcon below firm EQR threshold)."
- [ ] Partner direction plan: "Weekly status calls; all areas with judgement reviewed by partner; final review pre-opinion."
- [ ] Team composition, specialists, EQR off, budgeted hours = 120.

**ISA-specific narratives (Tier 1 — was already there):**
- [ ] Internal controls overview: "Entity uses QuickBooks; no ERP; substantive approach."
- [ ] Planning analytics: "Revenue up 12% YoY; margin stable; AR turnover deteriorated 45→62 days — flag receivables."
- [ ] Going concern (planning): "No GC indicators identified."
- [ ] Subsequent events (planning): "Cut-off review at completion."
- [ ] Fraud team discussion held: tick. Date today. Attendees: "T. Babiker, S. Khan, J. Doe."

**Understanding the entity (ISA 315) — Sprint 4 un-park:**
- [ ] Industry & external environment (ISA 315.19(a)): "UAE Corporate Tax Year 1; sector slowdown in retail trading; new VAT inspection focus on RPT."
- [ ] Significant changes since prior period (ISA 315.A47): "New CFO appointed Q3 2025; refinanced long-term loan at lower rate; no other material changes."
- [ ] Tick all 3 ISA 315.14 procedures (inquiry / analytical / observation).

**Partner attestations:** tick all 4. Click **Approve planning**.

**Expected:** status flips to Approved green. Revise button appears. If approval fails with the ISA 315 attestation error, the DB CHECK is doing its job — confirm the 3 boxes are ticked and try again.

---

## 6. Planning — Materiality

- [ ] Benchmark: PBT, amount: AED 5,000,000, percentage 5% → overall AED 250,000.
- [ ] Performance: 75% → AED 187,500. Trivial: 5% → AED 12,500.
- [ ] Rationale: "Standard profit-based benchmark; prior-year experience supports 75% perf-mat."
- [ ] Approve.

---

## 7. Planning — Risk assessment

- [ ] Click into the risk matrix. The 2 ISA 240 presumed risks (revenue recognition, management override) should auto-seed locked.
- [ ] Add 2-3 entity-specific risks: e.g. "AR collectability" (sections: Receivables, assertions: valuation), "Inventory NRV" (Inventory, valuation), "Cut-off" (Revenue, cutoff).
- [ ] Each risk needs at least one linked procedure (the hard block on unlinked significant risks).
- [ ] **Confirm risk assessment.**

If the confirm button greys out, check the unlinked-significant-risks banner — it tells you which risk has no procedure.

---

## 8. Execution phase — switch over

Click the **Execution** phase chip in the stepper.

**Expected module tabs:** Trial balance · Sections · Findings · **Estimates** (new Sprint 4) · **Confirmations** (new Sprint 4) · Financial statements · Activity log.

If Estimates or Confirmations doesn't appear, the deploy didn't include `e7a19df` / `53c2ea5` — check Netlify.

---

## 9. Execution — Trial balance

- [ ] Upload a small CSV/Excel TB (~10-20 lines). Use any plausible accounts.
- [ ] Tag classifications so sections can map.
- [ ] Mark version as final.

---

## 10. Execution — Sections + Procedures + **Sampling**

- [ ] Open the **Revenue** section (auto-seeded from the 19+1 template).
- [ ] Open any one procedure → fill "What you did" with: "Selected a sample of 30 revenue transactions from the population of 850 invoices using systematic sampling (every 28th). Agreed each to source invoice, GL entry, and bank receipt."
- [ ] Save the response. Mark as Done.
- [ ] **NEW — Click the "+ Sampling" button** next to "Mark as Done":
  - Population: "All revenue invoices issued in FY25 (excluding credit notes)."
  - Population size: **850**
  - Sample size: **30**
  - Method: **Systematic**
  - Selection basis: "Every 28th invoice starting from item 14 (random start)."
  - Results summary: "All 30 traced without exception. No cut-off errors identified."
  - Projection: leave blank or 0
  - Conclusion: "Sample provides sufficient appropriate evidence. No projected misstatement."
  - Save sampling.
- [ ] **Expected:** procedure body now shows the inline summary chip *"ISA 530 sampling: 30 of 850 · method: systematic · All 30 traced without exception. No cut-off er…"* and the button label flips to "Edit sampling".

- [ ] **Bug-hunt:** open another procedure, click "+ Sampling", try **sample 1000 of population 100** — should block.

---

## 11. Execution — Findings + adjusting entries (sets up ISA 450 schedule)

You need at least 3 findings to make the misstatement schedule interesting:

- [ ] **Finding 1 — Corrected.** Section: Revenue. Title: "Cut-off — revenue posted in wrong period". Type: misstatement. Severity: medium. Effect: "Revenue overstated AED 22,000". Monetary impact: 22000. Add adjusting entry: Dr Sales, Cr Deferred income, 22000, **is_posted = true**. Status: resolved.
- [ ] **Finding 2 — Uncorrected.** Section: Receivables. Title: "Provision for doubtful debts — under-accrued". Type: misstatement. Severity: medium. Effect: "Allowance understated AED 45,000". Monetary impact: 45000. Add adjusting entry: Dr Bad debt expense, Cr Allowance, 45000, **is_posted = false**. Status: reported.
- [ ] **Finding 3 — Clearly trivial.** Section: Expenses. Title: "Stationery accrual miss". Type: misstatement. Severity: low. Monetary impact: 1200. Close category: **unadjusted_immaterial**. Status: resolved.

---

## 12. Execution — **Estimates** (ISA 540) — Sprint 4

Click **Estimates** tab. Empty state appears with "Add the first estimate".

Add **two** estimates:

**Estimate 1 — EoSB provision (the canonical UAE example):**
- Name: "End-of-service benefits (EoSB) provision"
- Linked section: Provisions (or Liabilities, whichever exists)
- Method: "UAE Labour Law accrual — 21 days per year of service paid at last basic salary; final 12 months at 30 days/year."
- Assumptions: "No early departures; 5% salary growth; full headcount of 24 employees at year-end."
- Data sources: "HR system payroll register at YE; signed labour contracts; prior-year leaver history."
- Sensitivity: "1% change in salary growth = AED 12K impact on accrual."
- Risk: **Medium**
- Conclusion: "Recalculated independently — agrees within AED 1,200 (immaterial). Assumptions reasonable. Accept as recorded."
- Save.

**Estimate 2 — Doubtful debts:**
- Name: "Allowance for doubtful debts"
- Linked section: Receivables
- Method: "Specific provision for AR > 180 days + general 5% on 90-180 days bucket."
- Assumptions: "Historic recovery rates from prior 3 years; no major customer in distress at YE."
- Data sources: "AR ageing report; subsequent collections through audit date."
- Risk: **High** (links to Finding 2 above)
- Conclusion: "Under-provided per Finding 2 — AJE AED 45,000 proposed but management declined. Treated as uncorrected misstatement."
- Save.

**Expected:** table now has 2 rows with color-coded risk badges (yellow Medium + red High). Each shows the linked section as a hyperlink back to the section.

---

## 13. Execution — **Confirmations** (ISA 505) — Sprint 4

Click **Confirmations** tab.

Add **three** confirmations to exercise each result branch:

**Conf 1 — Clean bank:**
- Counterparty: "Emirates NBD — current account 1234567"
- Type: **Bank**
- Linked section: Cash
- Sent date: today minus 30 days. Returned date: today minus 22 days.
- Result: **Clean**
- Alternative procedures: leave blank (clean doesn't need them)
- Save.

**Conf 2 — AR exception (forces ISA 505.12 path):**
- Counterparty: "Customer XYZ — balance AED 45,000"
- Type: **Accounts receivable**
- Linked section: Receivables
- Sent: -30 days. Returned: -10 days.
- Result: **Exception**
- **Try saving without alternative procedures** → should hit the soft gate with the ISA 505.12 message.
- Now fill: "Customer disputed AED 12,000 of the balance. Traced to delivery note 4471 — goods returned post-cutoff. Adjusted AR ageing accordingly. No further action."
- Save.

**Conf 3 — Bank no-reply (also forces 505.12):**
- Counterparty: "Mashreq Bank — savings account 9876543"
- Type: **Bank**
- Linked section: Cash
- Sent: -30 days. Returned: blank.
- Result: **No reply**
- Alt procedures: "Reviewed subsequent bank statements through 2026-02-15. Agreed YE balance of AED 8,400 to next-day statement. Verified Dr/Cr movements to GL. No issues."
- Save.

**Expected:** summary chip row above the table shows **1 clean · 1 exception · 0 partial · 1 no reply · 0 pending**.

---

## 14. Approve sections, close engagement, build completion memo

- [ ] Send the Revenue, Receivables, Provisions, Cash sections through the sign-off chain. Approve all sections you've touched.
- [ ] Categorize any open findings (Finding 2 → communicated_to_management; Finding 3 → unadjusted_immaterial already set).
- [ ] **Approve & Close Engagement** from the engagement card. Banner flips to "Completed".

---

## 15. Conclusion — Completion memo (ISA 450 schedule lives here)

Click **Conclusion** in the stepper → open the completion memo.

### Rollup tab

- [ ] Rollup cards show: sections approved, findings counts, misstatements count (3), posted/unposted adjustments.
- [ ] **NEW — Misstatement Schedule (ISA 450)** block below the cards, with **three groups**:
  - **Corrected (1)** — Finding 1 with the Dr/Cr lines, "Posted" badge.
  - **Uncorrected (1)** — Finding 2 with the unposted entry, "Not posted" badge.
  - **Clearly trivial (1)** — Finding 3 with no AJE.
- [ ] Totals block: Corrected Σ = 22,000, Uncorrected Σ = 45,000, Clearly trivial Σ = 1,200. Materiality: 250,000 overall, 187,500 performance. Uncorrected vs overall = **18.0%**.

**Bug-hunt:** if any group renders empty when it shouldn't, the classifier logic is off — refresh System Checks once; if still wrong, the migration may not have created findings.finding_type correctly or the close_category wasn't saved.

### Narrative tab

- [ ] Going concern: "No material uncertainty identified". Rationale: short paragraph.
- [ ] Subsequent events: fill the structured fields (procedures, review-through date, no events identified).
- [ ] Final analytical review: short paragraph.
- [ ] **Uncorrected misstatements evaluation (ISA 450):** "Aggregate uncorrected of AED 45,000 (18% of overall materiality) is within firm tolerance and individually immaterial. Communicated to management; declined to correct as outside firm tolerance band."
- [ ] Mgmt rationale: "Provision methodology disputed by management; auditor disagrees but immaterial in aggregate."
- [ ] Final independence: short paragraph.

### Reps & Comms tab

- [ ] Tick Mgmt Rep Letter received + date.
- [ ] Tick TCWG comm done + date.

### Opinion tab

- [ ] Opinion: **Unmodified**. Date: today.

### EQR tab

- [ ] EQR not required (per planning). Should auto-pass.

### Attestations tab

- [ ] Verify the 13 attestation rows are mostly green (system-checked). Tick the 3 manual ones (independence, mgmt rep, review notes).

### Sign

- [ ] Click **Sign and Lock**. Confirm in the dialog.

**Expected:** memo flips to "Locked & Signed". All fields read-only. "Refresh System Checks" disappears.

---

## 16. ISA 230 archive (Sprint 4)

Back to the engagement card.

- [ ] **Archive (ISA 230)** button is visible next to "Reopen Engagement".
- [ ] Click it → confirm dialog → archive.
- [ ] **Expected:** new grey "Archived" banner replaces "Completed" banner with the assembly date. All Create/Upload buttons hidden. Only "Unarchive (post-assembly change)" available.

**Bug-hunt:** if Archive fails with "completion memo must be locked", the memo lock didn't take — go back, sign properly, retry.

---

## 17. Generate PDFs

These are what the partners will see — both must render cleanly.

### Planning PDF

- [ ] Navigate to Report → Planning Memorandum (ISA 300).
- [ ] **Sections to verify:**
  - Header with client, year-end, firm name, partner name.
  - Client Acceptance / Continuance (ISA 220) — includes **Opening balances (ISA 510)** sub-block: "N/A — continuance engagement (prior period audited, opening balances are prior closing)".
  - Engagement Letter (ISA 210).
  - Independence (ISA 220 + IESBA).
  - **Audit Planning (ISA 300 + ISA 315)** (renamed). All 5 ISA 300.9 narratives + partner direction + ISA-specific narratives + **new ISA 315 fields** (industry, significant changes) + **ISA 315.14 attestations table** (3 checkmarks) + fraud team discussion box.
  - Materiality (ISA 320).
  - Risk Assessment matrix.
- [ ] PDF prints in 2-3 pages. No broken HTML escapes. No infinite empty space.

### Completion PDF

- [ ] Navigate to Report → Completion Memorandum (ISA 700).
- [ ] **Sections to verify:**
  - Summary of Findings table (all 3 findings, ISA refs).
  - **Misstatement Schedule (ISA 450)** — three groups + aggregate-evaluation table showing % vs materiality (~18%).
  - **Significant Accounting Estimates (ISA 540)** — both estimates with risk badges + all narrative fields.
  - **External Confirmations (ISA 505)** — summary line + table including alternative_procedures column for the exception and no-reply rows.
  - **Audit Sampling Documentation (ISA 530)** — revenue sampling card with all 9 fields.
  - Work-done summary (per-section synthesis).
  - Completion Memorandum block with all attestations + Going Concern + Subsequent Events + Final Analytical Review + Uncorrected Misstatements Evaluation + Final Independence + Mgmt Rep + TCWG + Opinion + EQR + **File assembly (ISA 230) — ARCHIVED with date and archiver name** (Sprint 4).

If any of these are missing or empty, screenshot + tell me which one — that's a render-side bug to fix before demo.

---

## 18. Smoke checks for the live demo

Final pre-flight before the partner call. Run on staging in your demo browser tab so muscle memory is fresh:

- [ ] Refresh the dashboard. Engagement appears with "Archived" badge.
- [ ] Click into the engagement → archive banner shows.
- [ ] Click "Unarchive" → reason modal appears (don't actually unarchive unless rehearsing recovery).
- [ ] Open the planning PDF in a new tab. Confirm it renders within 3-4 seconds (large engagements can be slower — Falcon is small).
- [ ] Open the completion PDF. Same.
- [ ] Have these URLs ready:
  - Engagement detail page
  - Completion memo
  - Planning PDF (open in tab)
  - Completion PDF (open in tab)

## 19. Demo-day narrative (suggested order)

Optimised for the Qatar partners' gap list (planning / materiality / risk / completion memo / FS upload / procedure specificity) + the Sprint 4 standards-floor additions.

1. **Dashboard → engagements index** — "every audit lives here, one click per file"
2. **Falcon — Planning phase** — walk through Acceptance (point out ISA 510 line), Engagement Letter, Independence, **Audit Planning** ("this single workpaper covers ISA 300 strategy and ISA 315 understanding — IFAC SME guidance says integrate, don't fragment"), Materiality (versioned), Risk Assessment matrix (their headline ask)
3. **Falcon — Execution** — Trial balance (versioned), Sections (the 19+1 framework — their second ask), open a procedure to show the response + the **ISA 530 sampling chip** ("inspector asks for this exact thing"), Findings, **Estimates** ("EoSB, NRV — every UAE file has these"), **Confirmations** ("show me bank confirmations with alt-procs per 505.12")
4. **Falcon — Conclusion** — Completion memo Rollup tab → **point at the ISA 450 schedule grouped corrected/uncorrected/trivial** ("inspector's first ask — done"), Attestations (13 with hard gates), Opinion, EQR, sign + lock
5. **Archive (ISA 230)** — single click, file assembled, banner stamps the date
6. **PDFs** — open planning + completion side-by-side. "This is the file as a network inspector sees it."

Estimated demo time: 22-25 minutes. Buffer 10 min for partner questions.

## 20. Known things you may want to fix between now and 2026-06-01

These are NOT blockers but worth a polish pass:

- The 3-AI questions in `specs/sprint-4-standards-floor.md` aren't answered yet — if a partner asks "have you stress-tested this against ISA experts," you'd want at least Perplexity's answers back.
- 5 migrations still only on staging Supabase. **Decision required:** do you demo on staging (lower risk if a bug surfaces) or apply migrations to prod and demo from prod (better PR optics — "this is live")? My recommendation: stay on staging for the demo unless prod has paying users now.
- No analytics / no Sentry DSN yet. If something crashes mid-demo you'll only see it in the browser console.
- Solo-firm shortcut (admin can submit_for_review) works but hasn't been exercised in a clean rehearsal — flag this if you're demoing as a single-user firm.

---

## Closing the loop

After running this rehearsal end-to-end at least once:

- [ ] Capture any bugs / rough edges in a follow-up commit before 2026-06-01.
- [ ] Tick the "Demo rehearsal" box in `specs/sprint-4-standards-floor.md` closure checklist.
- [ ] Optionally: take screenshots of the most polished views (completion PDF page with ISA 450 schedule + ISA 540 estimates + ISA 505 confirmations) as a backup deck in case staging hiccups during the live call.

When the demo is done — win or lose — write a short "demo notes" file capturing what landed and what didn't. That's the input for Sprint 5.
