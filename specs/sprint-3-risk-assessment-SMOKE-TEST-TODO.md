# Sprint 3 #3 — Risk Assessment: Smoke Test TODO

**Status:** Parked 2026-05-21. Migration applied to staging. Run this when you're ready to verify.

---

## Why this file exists

Migration `20260521120001_engagement_risk_assessment.sql` succeeded on staging Supabase. Tab is live. But the auto-seeding only fires on **NEWLY-created Pro engagements** — existing engagements stay empty. Smoke testing needs a clean engagement, so it can't be done on the engagement you're currently working in.

---

## Steps

### Setup

1. Open `https://staging--auditsaas.netlify.app/` → log in as Pro admin
2. Dashboard → create a NEW engagement (any client name, any year-end). Make sure the org is Pro.
3. Open the new engagement → Planning phase → "Risk assessment" tab (7th, after Materiality)

### What should appear automatically

**Two pre-seeded risks** (both locked + significant + PRESUMED badge):

- **Revenue Recognition** — assertion: Cut-off · source: Fraud · ISA 240.26
- **Management Override of Controls** — assertion: Accuracy · source: Mgmt override · ISA 240.31

If both appear → seeding works, move to the next steps.

If they DON'T appear → most likely cause: the engagement's audit_sections don't include a section name matching the seeder's pattern. The seeder looks for sections where the name (lower-cased) matches:
- `LIKE '%revenue%'` OR `LIKE '%sales%'` OR equals `'income'`

Check the engagement's sections (Execution → Sections tab). If you see "Revenue" or "Sales" but the seed didn't happen, check browser console for errors from `seed_presumed_fraud_risks`. The mgmt-override risk should appear regardless (it lives on the first section it can find).

### Functional smoke tests

4. **Link procedures:** click "Procedures" on Revenue → multi-select 1-2 procedures from the modal → close → counter "With procedures" should increment, "Unlinked" should decrement.

5. **Rebut workflow:** click "Rebut" on Revenue → modal opens → type a short rationale (<20 chars) → expect error → type ≥20 chars (e.g. "Cash-basis service business; no revenue targets; revenue recognized at point of cash receipt") → Rebut & approve → modal closes → Revenue risk now shows "Rebutted (ISA 240.26)" note + is_significant unticks.

6. **Mgmt override is non-rebuttable:** Mgmt Override row should NOT have a Rebut button. Confirmed by ISA 240.31.

7. **Add custom risk:** "+ Add risk" → pick any section → fill description / source / ratings → tick "Mark as significant" → rationale field appears → fill it + overall response → Save → appears in register.

8. **Confirm flow — should BLOCK first:** click "Confirm risk assessment" (header). If Management Override has no linked procedure → confirmation modal shows red "Blocked: 1 significant risk(s) have no linked procedures" banner. Confirm button stays disabled even if you tick attestations.

9. **Confirm flow — should PASS:** link Mgmt Override to a procedure → reopen confirm modal → red banner gone → tick all 4 attestation checkboxes → Confirm button enables → click → modal closes → green "Confirmed & locked" banner appears in the tab header + status badge goes from "Draft" to "Confirmed".

10. **Stand-back warning:** the confirm modal also shows a yellow "Stand-back check" banner listing all sections without significant risks. Useful for the partner; not a block.

11. **BEFORE DELETE trigger (orphan race fix):** while confirmed, go to a section workpaper that has procedures linked to a significant risk → try to delete that procedure → should be blocked with error message about unconfirming first.

12. **Revise:** click "Revise" in the header → confirmation drops → register editable again → attestations un-tick → can re-confirm.

13. **Pivot view:** click "Show matrix view" → sparse table of sections × assertions → cells with risks show count, with gold background if any risk in that cell is significant.

### Edge cases to skip if pressed for time

- Non-admin (member role) viewing — should be read-only
- Essentials org viewing — should show Pro-blocked banner
- Concurrency (two browsers editing same risk simultaneously) — not a v1 concern

---

## When done

Move the smoke test outcomes into the spec's § 8 closure checklist (`sprint-3-risk-assessment.md`). If everything passes, sprint #3 closes.

If anything broke, paste the error here or send a screenshot and I'll fix.
