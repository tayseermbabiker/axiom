# Audexon Pre-Pilot QA Checklist

A systematic walk-through of every role and every section state. Run this once end-to-end before opening the pilot. Each line has an expected behavior and a checkbox — tick after you verify it on the live site.

Time estimate: ~90 minutes for a full pass.

---

## 0. Setup (one-time, ~10 min)

Create or confirm you have three test accounts in the same firm:

- [ ] **Partner**: admin role — `totta1785@gmail.com` (or your existing admin)
- [ ] **Supervisor**: supervisor role — invite a second account via Team page
- [ ] **Preparer**: preparer role — invite a third account via Team page

Confirm the role badge under the firm name shows the correct role for each login.

Create a clean test engagement:

- [ ] As **Partner**, click "+ New Engagement"
- [ ] Enter a client name (e.g., "QA Test Co")
- [ ] Confirm the engagement page opens with 19 auto-seeded sections
- [ ] Confirm every section shows the **Partner's name** in the assignee dropdown (auto-assigned per PR 1)

Set materiality:

- [ ] As **Partner**, open Materiality tab → enter benchmark, amount, percentages
- [ ] Click "Save Materiality"
- [ ] Refresh — confirm materiality values persist
- [ ] Log in as **Supervisor** → confirm materiality is shown but read-only (no calculator)

---

## 1. Section workflow matrix (~30 min)

Pick one section (e.g., "Cash & Bank"). Walk it through every status. After each transition, verify what each role sees.

### Step 1.1 — Section starts at `not_started`

- [ ] **Partner** assigns the section to **Preparer** via the inline assignee dropdown
- [ ] Confirm assignment shows correctly in section card AND in the section page hero

### Step 1.2 — Preparer fills work and submits

Log in as **Preparer**. Open the assigned section.

- [ ] Conclusion field is editable
- [ ] Procedures: can mark Done / Pending, can edit "What you did"
- [ ] Can add Work Files and Client Files
- [ ] Can add findings
- [ ] Bottom of page shows **Send to Supervisor for Review** button
- [ ] Click it → confirm modal warns about locking
- [ ] After click, status badge at top shows "With Supervisor"

### Step 1.3 — Status is now `ready_for_supervisor_review`

Confirm all three views:

- [ ] **Preparer** view: status message "This section is with your supervisor for review. You cannot edit until it is returned." No edit on any field. No action buttons.
- [ ] **Supervisor** view: section is editable. Bottom shows **Approve (Supervisor)** + **Return to Preparer** buttons.
- [ ] **Partner** view: bottom shows status message "Supervisor review complete. Awaiting partner approval." No action buttons (because supervisor hasn't approved yet, so status hasn't reached partner-review).

### Step 1.4 — Supervisor returns to Preparer

As **Supervisor**, write a review comment in the Review Notes box → click **Add Review Comment** → click **Return to Preparer**.

- [ ] Status badge flips to "Returned to Preparer"
- [ ] Activity log records both the note and the return

Now switch to **Preparer**:

- [ ] Section is editable again (conclusion, procedures, files)
- [ ] Review note from supervisor is visible in Review Notes thread
- [ ] Preparer can click **Add Response** to reply
- [ ] Bottom shows **Send to Supervisor for Review** button (so preparer can resubmit after amending)

### Step 1.5 — Preparer resubmits

As **Preparer**, click Send to Supervisor again.

- [ ] Status flips back to "With Supervisor"

### Step 1.6 — Supervisor approves to Partner

As **Supervisor**, click **Approve (Supervisor)**.

- [ ] Status flips to "With Partner"
- [ ] Supervisor's view now shows status message "Supervisor review complete. Awaiting partner approval."

### Step 1.7 — Status is `ready_for_partner_review`

- [ ] **Partner** view: section is editable for partner (conclusion, etc.). Bottom shows **Final Approve (Partner)** + **Return to Supervisor**.
- [ ] **Supervisor** view: section is read-only ("Supervisor locked when with partner"). No action buttons.
- [ ] **Preparer** view: section is read-only. Status message "This section is with the engagement partner for final approval."

### Step 1.8 — Partner returns to Supervisor

As **Partner**, write a review comment → click **Add Review Comment** → click **Return to Supervisor**.

- [ ] Status badge flips to "Returned to Supervisor"
- [ ] Partner's view is no longer frozen — the actions bar refreshes (verifies the `applyApprovedState` fix from commit 35d8922)

As **Supervisor**:

- [ ] Section is editable again
- [ ] Partner's comment is visible in Review Notes
- [ ] Bottom shows **Send to Partner** (not "Approve (Supervisor)") + **Return to Preparer**
- [ ] Click Send to Partner → status flips back to "With Partner"

### Step 1.9 — Partner gives final approval

As **Partner**, click **Final Approve (Partner)**.

- [ ] Status badge flips to "Approved"
- [ ] All fields become read-only across all three roles
- [ ] **Partner** view: a "Reopen Section" button appears

### Step 1.10 — Partner reopens

As **Partner**, click **Reopen Section** → enter a reason in the modal.

- [ ] Status flips back to a working state
- [ ] All fields editable again for appropriate roles
- [ ] Activity log records the reopen with reason

---

## 2. Findings flow (~10 min)

Inside one section as **Preparer** (during step 1.2):

- [ ] Click **+ Add Finding** → create one with type = "observation"
- [ ] Create another with type = "misstatement" → confirm the adjusting-entry panel (debit/credit/amount) appears
- [ ] Create a third with the management-letter flag checked
- [ ] All three appear in the section's Findings list AND on the engagement's Findings tab

As **Supervisor** or **Partner**:

- [ ] Can change finding status: open → resolved → reported
- [ ] Cannot change status as preparer (read-only badge)

---

## 3. Engagement closure (~10 min)

Bring **all 19 sections** to `approved` (or for a faster test, delete 18 sections and only keep one approved section).

As **Partner**:

- [ ] Top-right of engagement page shows **Close Engagement** button (next to Export PDF)
- [ ] If sections aren't all approved, instead shows grey text "X final section(s) not yet approved"

Test closure with open findings:

- [ ] Leave at least one finding with status = "open"
- [ ] Click Close Engagement → modal opens with the finding listed
- [ ] Each finding requires a categorization (ISA 450/265: Unadjusted Immaterial, Communicated to Management, Significant Deficiency, etc.)
- [ ] Cannot click "Acknowledge & Close" until every finding is categorized
- [ ] After close: red banner "This engagement has been closed. All sections are read-only."
- [ ] All "+ New Section", "Upload TB", and edit buttons are hidden

Reopen:

- [ ] **Partner** sees red "Reopen Engagement" button in the same spot
- [ ] Click → modal requires a reason
- [ ] After reopen: banner disappears, normal buttons return
- [ ] Activity log records both close (with `open_findings_acknowledged` count) and reopen (with reason)

---

## 4. Section reassignment (~5 min)

As **Partner**:

- [ ] On the engagement page section list, click the assignee dropdown on any section card
- [ ] Confirm the dropdown opens **without** navigating to the section detail page (verifies the click fix from commit 2ded101)
- [ ] Pick a different team member → confirm the avatar/name updates immediately
- [ ] Refresh the page → confirm the new assignment persists
- [ ] Open the activity tab → confirm an entry "Reassigned section" exists with from/to user IDs

Same test on the section detail page (the dropdown in the hero):

- [ ] Change assignee from there
- [ ] Verify persistence and activity log

As **Preparer**:

- [ ] On any section card, the assignee is shown as a static avatar (no dropdown — preparers can't reassign)
- [ ] On a section page, "Assigned to: name" is plain text

---

## 5. Preparer "All sections / My sections only" toggle (~3 min)

As **Preparer**:

- [ ] Toggle is visible at the top of the section list ("All sections" / "My sections only")
- [ ] Default: "All sections" — own sections highlighted with a blue left border
- [ ] Click "My sections only" → only sections assigned to current user are shown
- [ ] Refresh — toggle remembers the choice
- [ ] If no sections are assigned to preparer, empty state shows "No sections assigned to you yet. Switch to 'All sections' to see the full list."

As **Partner** or **Supervisor**:

- [ ] Toggle is **not** visible (admin/supervisor always see all sections)

---

## 6. Trial Balance (~10 min)

As **Partner**:

- [ ] Upload a TB CSV (use `sample-tb.csv` in repo)
- [ ] Confirm sections auto-populate with classification tags
- [ ] Replace TB with a new version → confirm old version is preserved (TB versioning)
- [ ] Sections retain their classification mappings after TB replacement

As **Preparer**:

- [ ] Cannot upload or replace TB (button hidden)

---

## 7. Activity log (~3 min)

After running all of the above:

- [ ] Activity tab on the engagement page shows entries for: created_engagement, created_section, reassigned_section, submitted_for_review, supervisor_approved, returned_to_preparer, partner_approved, returned_to_supervisor, closed_engagement, reopened_engagement
- [ ] Each entry has the user's name, timestamp, and the relevant details

---

## 8. PDF Export (~3 min)

As **Partner** or **Supervisor**:

- [ ] Click "Export PDF" → confirm report.html opens with engagement data
- [ ] Print to PDF — confirm all sections, conclusions, findings appear
- [ ] Acceptable quality (this is a known area marked for major overhaul, just confirm it doesn't crash)

---

## 9. Edge cases (~10 min)

- [ ] Try to delete a section that has been partner-approved → confirm error message or button hidden
- [ ] Try to upload a TB as preparer → confirm button is hidden
- [ ] Try to access a section URL of a different firm directly → confirm RLS blocks it (404 or redirect)
- [ ] Sign out and sign back in — confirm role persists, no permission leaks
- [ ] Open the section page on a mobile browser — confirm the assignee dropdown opens as a native picker without navigating

---

## When all boxes are ticked

You have walked every primary path. Open issues at this point are:
- Items you ticked but felt slow or confusing → product polish backlog
- Items that broke → file a bug

Only after this checklist is clean do you onboard pilot users.

---

## What this checklist does NOT cover

These are out of scope for pre-pilot QA but should be tested before billing goes live:

- Stripe / Lemon Squeezy checkout flow
- Email deliverability (Resend SPF/DKIM)
- Seat-limit enforcement at the DB trigger level
- Multi-firm isolation (one user in multiple firms)
- Browser-specific behavior outside Chrome/Edge/Firefox/Safari
