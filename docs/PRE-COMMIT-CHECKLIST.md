# Pre-commit self-review checklist — Audexon

A one-page mental walkthrough I run before every push. Designed for
this codebase's reality: **vanilla JS + HTML pages + Supabase RPCs +
RLS at the DB layer + Netlify deploy**. No build step, no type system,
no automated test suite — so the discipline is in the head, not the
toolchain.

This document is intentionally short. Long checklists get skipped.

---

## Before staging the change

### 1. Did I break a workflow?
Mentally trace the affected flow end-to-end. If I changed a section
approval rule, walk through: section creation → procedures → finding
→ approval chain → completion memo trigger. If I changed an attestation
key, walk through: seed → render → tick → sign-memo gate.

If I can't predict what breaks, I haven't understood the change well
enough.

### 2. Did I add a DB field?
If yes, four follow-ups must happen in the same commit:
- [ ] Migration file written (`supabase/migrations/<timestamp>_<name>.sql`)
- [ ] Field added to the UI form (load + save)
- [ ] Field rendered in the corresponding PDF block in `report.html`
- [ ] If the field has a CHECK constraint, the UI validates it BEFORE
  the user submits (otherwise the DB error surfaces as a cryptic alert)

Pattern: **add → load → save → render**. Missing any of these = the
field exists but is invisible to the user OR invisible to the inspector.

### 3. Did I add an RPC?
- [ ] `SECURITY DEFINER` + `SET search_path = public`
- [ ] Org-membership check inside the function
- [ ] Role check matches the UI's `can(...)` gate
- [ ] `REVOKE EXECUTE ... FROM public` + `GRANT EXECUTE ... TO authenticated`
- [ ] If the new RPC is called by a feature that's been in staging,
  did I tell the user to apply the migration before they test?

### 4. Are inputs validated?
- [ ] Text fields: `.trim()` before save, store `null` not empty string
- [ ] Numeric fields: `parseFloat()` with `|| 0` fallback, not `Number(x)`
  which returns `NaN` on empty
- [ ] Date fields: `<input type="date" max="9999-12-31">` to prevent
  the year-2026 → year-20226 bug
- [ ] Enum dropdowns: include a `""` empty option with explicit label,
  not just an empty placeholder

### 5. Are error paths surfaced?
The single most common bug in this codebase is silently swallowed errors.
- [ ] Every `await supabaseClient.from(...).insert/update/delete` must
  destructure `{ error }` and `alert()` it on failure
- [ ] Every `.rpc(...)` must destructure `{ error }`
- [ ] No fire-and-forget promises on user actions (Save / Approve / Sign)

### 6. Did I add a soft warning instead of a hard gate?
For ISA-related gates (attestations, opinion validation, partner
sign-off), prefer:
- **Confirm dialog with explicit override** → records the override
  in the attestation trail
- NOT silent block → user can't proceed and doesn't know why

Hard gates ONLY when the missing item is truly non-negotiable
(e.g. EQR required but not done; Mgmt Rep Letter not obtained).

### 7. Is there logic that should be the same in two places?
Common drift sites:
- UI render in `engagement.html` AND PDF render in `report.html`
  for the same field
- Permission check in `auth.js` AND RLS in the DB
- Status enum values in JS labels AND DB CHECK constraint

If I changed one, did I change the other?

### 8. Did I introduce a typo by typing the field name twice?
Pattern that bites: a new DB column with a slightly different name
than the JS variable that loads/saves it. Search for the new name
across the codebase to confirm it's referenced consistently.

---

## After pushing

### 9. Did I tell the user what manual steps are required?
If the commit includes a migration:
- [ ] Tell them the exact file path to copy into Supabase SQL Editor
- [ ] State whether it's safe (pure ALTER) or risky (data migration)
- [ ] State what they should see after applying it (smoke-test cue)

If the commit changes UX:
- [ ] One-line summary of what changed visually
- [ ] One-line summary of what behaviour changed
- [ ] Specific path to test (e.g. "go to Completion Memo → Reps & Comms tab → tick Mgmt Rep Letter")

### 10. Did I leave the staging branch in a deployable state?
Every commit pushed to `staging` should be safe to demo. If a
half-finished feature is in flight, hold it on a feature branch
until it's complete.

---

## Done. Push.
