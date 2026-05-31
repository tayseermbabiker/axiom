# Inspection PDF — polish backlog (PARKED)

**Status:** Parked 2026-05-21. Build is shipped + functional. Polish items captured below for post-validation / post-demo work.

Verified working end-to-end against `ABC TRADING — Audit File — Audexon.pdf` (16 pages, all sections rendered, page breaks clean, partner-presentable). Issues below are cosmetic/defensive, not blockers.

---

## Issues to fix later

### 1. Cover page — Engagement Partner / Supervisor names missing

**Symptom:** Cover shows "Engagement Partner: —" and "Supervisor: —" even when the org has admin + supervisor members assigned.

**Root cause:** `report.html` lines ~213-216 use a simple role-string lookup:
```js
const partnerMember = (profilesRes.data || []).find(m => m.role === 'admin');
const supervisorMember = (profilesRes.data || []).find(m => m.role === 'supervisor');
```
Org may have admins but no one with `role === 'supervisor'` (it might be `'member'` or unassigned). Or there may be multiple admins and we're picking one arbitrarily.

**Fix:** Look up the specific person who actually approved sections / signed the completion memo for this engagement. Use the most-recent partner attestation source rather than org-role guessing. Probably:
- Engagement Partner = `engagement_completion_memo.signed_by` if memo locked, else most-recent `audit_sections.partner_approved_by`
- Supervisor = most-recent `audit_sections.supervisor_approved_by`

### 2. Date input bug — 5-digit years accepted

**Symptom:** Decision date on Client Acceptance rendered "22025-03-11" (extra leading "2"). HTML `<input type="date">` accepts years past 9999 if the user types past 4 digits without leaving the field.

**Fix:** Add `max="9999-12-31"` to every `<input type="date">` in `engagement.html` AND add JS validation on save that rejects dates outside [1900, current_year + 10].

Find date inputs:
```
grep -n 'type="date"' public/pages/engagement.html
```

### 3. Empty IESBA threats render as 5 blank rows

**Symptom:** Independence section shows 5 rows with "—" everywhere when partner hasn't filled in threats.

**Fix in report.html:** filter `eiThreats` before rendering:
```js
const meaningfulThreats = eiThreats.filter(t => t.identified || (t.description && t.description.trim()) || (t.safeguards && t.safeguards.trim()));
```
If `meaningfulThreats.length === 0`, render "No IESBA threats identified" instead of the empty table.

### 4. NAS rows with empty fields render as junk

**Symptom:** NAS table shows a row with "—" for service / fee but a permitted X mark — looks like data corruption.

**Fix:** Either (a) filter empty NAS in report.html (`n.service_description && n.service_description.trim()`), or (b) enforce non-null `service_description` at the DB level via CHECK constraint + UI validation. Prefer (b) — empty rows shouldn't exist.

### 5. Audit Strategy renders empty when no narrative

**Symptom:** "Audit Strategy (ISA 300)" heading + "Status: Draft" table, then nothing — looks abandoned.

**Fix in report.html:** if `easActive` exists but all narrative fields are NULL, render:
```
"Strategy started but no narrative content recorded. Partner can complete in Planning → Audit strategy tab."
```

### 6. Logo / brand on cover

**Symptom:** Cover is all text. Audexon brand bar is "AUDEXON AUDIT FILE" in letterspaced caps but no logo. For partner demo, a small logo lockup would feel more professional.

**Fix:** Add a small SVG logo to the cover header. Brand audit needed — current Audexon brand assets, if any, live in the repo at... (check `public/img/`, `public/branding/`, etc.)

### 7. Optional UX add-ons (worth considering)

- **Inspection PDF cover-page table of contents:** "Section 1: Acceptance — page 2 · Section 2: Engagement Letter — page 2..." Helps inspectors navigate a 30-page PDF.
- **Page numbers + header on every page** (currently only first page has full cover): "ABC TRADING — Audit File — Page X of Y" in the footer.
- **Date the inspection PDF was generated** as a watermark or footer note (currently shown once on cover).
- **Risk Assessment Pivot view** rendered horizontally — currently the "Cut-Off" column header wraps awkwardly because of the hyphen.
- **Section workpaper grouping by phase** — "FINAL PHASE" label appears once at top; consider a fresh "FINAL PHASE — continued" on subsequent pages or per-section if user expects clear phase boundaries.

---

## When to revisit

- Before scaling beyond Qatar pilot (2026-Q3+) — first 2-3 partners will give feedback that supersedes our guesses
- If any pilot firm flags inspection-readiness concerns
- Before the public Pro tier launch — these polish items become marketing-relevant

## What was validated as working (2026-05-21)

Verified in `ABC TRADING — Audit File — Audexon.pdf`:
- 16-page render, no truncation
- Page breaks between major sections clean
- Status badges (CONFIRMED / SIGNED / DRAFT / NOT STARTED) display correctly
- Risk matrix pivot shows correctly (sparse, gold for significant)
- ISA 330.21 violation flagged in red on Risk Assessment summary
- All 19 audit sections rendered with their procedures
- Procedures show "Not recorded" in red when responses missing
- Trial Balance "no data" state renders cleanly
- Completion Memo "draft" state renders without false-positive data
