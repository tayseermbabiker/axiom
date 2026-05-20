# Sprint 1 — Local Compliance Section (Verification Spec)

**Status:** Shipped to staging. Awaiting Perplexity + Copilot cross-check.
**Branch:** `staging` on `tayseermbabiker/axiom`

---

## 1. Partner gap addressed

Qatar partner asked: *"Our network expects us to add a section for local compliance — ESR, Qatar Investment Authority filings, AML decree. CaseWare lets us customize. Can your platform do that?"*

The gap: 19 standard audit sections are universal. Network methodology often requires a jurisdiction-specific 20th section (UAE ESR, Qatar QFC, Saudi Zakat, etc.). Building this in lets us position "international ISA-based product, configurable per firm."

**ISA standards mapped:**
- **ISA 250 (Revised) — Consideration of Laws and Regulations** — auditor obligation to identify and address laws/regs material to the FS
- **ISA 300 — Planning** — engagement-specific procedures designed in advance
- **ISA 210 — Agreeing Terms** — clarity on regulatory scope of the audit
- Network methodology mandates (BDO, RSM, Crowe, Mazars) generally require explicit local-compliance workpapers

---

## 2. UI inventory

**Entry point:** Sidebar nav "Local Compliance" link on dashboard / team / engagement / completion-memo. Visible only when `currentRole === 'admin' && currentOrg.feature_tier === 'pro'`.

**Page:** `public/pages/local-compliance.html` (~370 lines).

**Gates (in order):**
1. **Pro-tier blocked** banner if `feature_tier !== 'pro'` — "Local Compliance is a Pro feature" with link to pricing
2. **Role-blocked** banner if `currentRole !== 'admin'` — "Partner-only settings"

**Empty state** (no template row yet): "No Local Compliance section yet" card with "Enable Local Compliance" button. Click creates the template row with defaults.

**Template settings card:**
- Active checkbox (label: "uncheck to skip the 20th section on new engagements")
- Section Name (required) — placeholder examples: "UAE Regulatory Compliance", "Qatar QFC Requirements"
- Description (textarea)
- 3-column grid: Jurisdiction (free text), Phase (interim/final), Sort Order (default 20)
- Save Template button

**Procedures card:**
- Subtitle: "These procedures are copied (not referenced) into each new engagement's 20th section. Edits to the master here don't affect engagements already created."
- "+ Add Procedure" button → opens modal
- Procedure list: description + type badge + sort number + regulatory ref + Edit/Deactivate buttons per row
- Inactive procedures shown grayed out
- Empty state: "No procedures yet. Add at least one before creating new engagements."

**Procedure modal:**
- Description (required textarea, 3 rows)
- Type select: Test of Detail / Analytical / Controls / Other
- Sort Order (auto-defaults to max+1 when adding)
- Regulatory Reference (free text, e.g., "Cabinet Resolution 57 of 2020, ISA 250")
- Save / Cancel

---

## 3. Data model (from migration 004)

### `public.org_local_compliance_templates`
- One row per organization (UNIQUE on `organization_id`)
- Fields: name, section_description, jurisdiction (free text), sort_order (default 20), phase (interim/final), is_active, created_by, timestamps

### `public.org_compliance_procedures`
- Many per template
- Fields: description, procedure_type (test_of_detail/analytical/controls/other), sort_order, regulatory_ref, is_active, timestamps
- ON DELETE CASCADE from template

### RPC: `seed_compliance_section(p_engagement_id, p_organization_id) → uuid`
SECURITY DEFINER. Membership-checked. Looks up active template; if none → returns NULL. Otherwise inserts a new `audit_sections` row (with the template's name/phase/sort_order) and **copies** all active master procedures into `audit_procedures` (snapshot, not reference).

### RLS
- SELECT — any org member
- INSERT/UPDATE — admin role AND (Pro tier on INSERT only)
- Template + procedures: both gated identically

### Wiring point
`public/pages/dashboard.html` line ~745, immediately after `seedSectionsForEngagement` for the standard 19. Pro-tier check client-side as a fast path; RPC is no-op for non-Pro orgs anyway. Failure is non-blocking.

---

## 4. Permissions & workflow

| Action | Role | Tier |
|---|---|---|
| See "Local Compliance" nav link | admin | Pro |
| Visit page | admin | Pro |
| Create initial template ("Enable Local Compliance") | admin | Pro |
| Edit template / add procedure / toggle active | admin | Pro on INSERT, any tier on UPDATE |
| New engagement auto-seeds 20th section | any role creating engagement, if firm's template is active | Pro |

State: one master template per org. Active=true → seeded into every new engagement. Active=false → skipped silently. Procedures copied at engagement creation time so master edits don't retroactively change existing engagements.

---

## 5. Out of scope

- Multiple templates per org (e.g., one per jurisdiction) — single template only
- Per-engagement override of which procedures get seeded
- Pre-built jurisdiction packs (UAE ESR, KSA Zakat, etc.) — firm authors their own
- Sync existing in-progress engagements when template changes
- Importing procedures from a CSV
- Public/shared template marketplace
- ISA 250 deeper integration (e.g., automatic risk-assessment linkage)
- Audit trail of who edited a procedure when

---

## 6. Judgment calls

**J1 — Single template per org (not per-jurisdiction)**
A multi-jurisdiction firm sees ONE Local Compliance section per engagement. If they audit both UAE + Qatar entities, they'd need to combine procedures into one master or rotate.
*Risk:* awkward for cross-border firms. Mitigation: jurisdiction is a free-text label, so they can change it per period.

**J2 — Procedures copied at engagement creation, not referenced live**
Editing the master after an engagement exists does NOT update that engagement. Auditor must manually edit the engagement's section if they want the change.
*Risk:* drift between master and historical engagements. Reasoning: evidence integrity — once seeded, the workpaper is the workpaper.

**J3 — Pro check on INSERT only (same as Completion Memo)**
A firm that downgrades from Pro can still toggle, edit, deactivate. They just can't author a new template after downgrade.
*Risk:* same as Completion Memo J1. Accepted for the same reason.

**J4 — Wiring uses client-side Pro check before calling RPC**
Saves an RPC round-trip for Essentials orgs. RPC also returns NULL safely if called by a Pro org with no template, so the guard is defense-in-depth, not safety-critical.

**J5 — Seeding failure is silent (non-blocking)**
If the RPC fails, the engagement is still created with 19 sections. Partner can add the 20th manually. No error surfaced to the user.
*Risk:* silent data loss if the RPC consistently fails. Mitigation: ISA documentation rules expect partner-level review of section coverage on every engagement.

---

## 7. Blocking verification questions (only the ones that could change what we build)

**For Perplexity:**

1. "Under ISA 250 (Revised), is there a documentation requirement that local-law procedures be in a SEPARATE workpaper section from general substantive testing, or is it acceptable to embed them in the relevant balance-sheet sections? Our model uses a separate 20th section — is this aligned with ISA 250, or does it create false separation?"

2. "For a Gulf small/mid firm that is a correspondent member of an international network (BDO/RSM/Crowe/Mazars), what are the typical network-methodology requirements for documenting jurisdictional regulatory compliance? Specifically: do they require named procedures (e.g., 'verify ESR notification submitted'), risk-rated procedures, or just narrative conclusion?"

**For Copilot:**

3. **`local-compliance.html` saveTemplate** — when user clicks "Save Template," every field is updated regardless of whether it changed. Confirm this is OK under RLS (UPDATE with no-op values). Confirm `updated_at` is correctly set on every save.

4. **`migrations/.../seed_compliance_section`** — the function uses `auth.uid()` for the membership check, but is called from the dashboard right after an INSERT. Confirm `auth.uid()` is reliably populated in this context (i.e., no anon session edge case).

---

## 8. Closure checklist

- [ ] Smoke test: create template, add 2 procedures, create a new test engagement, verify 20th section appears with the procedures
- [ ] Smoke test: deactivate template, create another engagement, verify only 19 sections
- [ ] Smoke test: deactivate one procedure, verify it does NOT seed into new engagement
- [ ] Perplexity Q1+Q2 answered (or deferred to partner demo with explicit reasoning)
- [ ] Copilot Q3+Q4 addressed
- [ ] User signs off

When all six are ticked, **CLOSED**.
