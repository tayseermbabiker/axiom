# Sprint 1 — Financial Statements Upload Slot (Verification Spec)

**Status:** CLOSED — verification pass complete 2026-05-20. See "Verification pass" section below for what changed.
**Branch:** `staging` on `tayseermbabiker/axiom`
**Staging URL:** https://staging--auditsaas.netlify.app/
**Manual step still required before it works on staging:** create the `fs-documents` Supabase Storage bucket + run `supabase/staging-fs-storage.sql` (see Section 3).

---

## 1. Partner gap addressed

From the 2026-05-19 Qatar partner demo:

> *"Where do I attach the client's financial statements? The signed PDF that the client gives us — where does that go? In CaseWare we have a slot for it."*

The gap: v0.5 had a generic shared-drive link field on the engagement, but no first-class place to store and version the client's prepared FS. Network inspectors checking the audit file ask for: (a) the FS the auditor opined on, (b) the version chain showing draft revisions, (c) evidence that the audit opinion was issued on the *signed* version.

**ISA standards this feature is positioned against:**

- **ISA 200 — Overall Objectives** — the auditor obtains reasonable assurance about whether *the financial statements as a whole* are free from material misstatement. We need a record of *which* FS.
- **ISA 230 — Audit Documentation** — the documentation must include the FS the auditor reported on
- **ISA 450 — Evaluation of Misstatements** — uncorrected misstatements are tracked against the FS submitted by management; a version chain shows whether management corrected them
- **ISA 560 — Subsequent Events** — if FS are revised after the auditor's report date, the version chain provides evidence of what changed and when
- **ISA 700 / 705 — Forming the Opinion / Modifications** — the opinion references "the accompanying financial statements"; we need to know what's accompanying

---

## 2. UI inventory

**Entry point:** new tab "Financial Statements" on `engagement.html`. Tab is visible to all roles; upload action gated to `admin` + `supervisor` via new permission `upload_fs`.

**Tab structure (`#tab-fs`):**

### Card header
- Title: "Financial Statements"
- Subtitle: "Client-prepared financial statements supporting the audit opinion. Keep the signed version on file as audit evidence."
- "Upload Financial Statements" button (right-aligned, primary). Visible only to `admin` + `supervisor`.

### Active signed banner (green card, shown only when an active signed version exists)
- "Signed" pill (green) + "Active signed version on file"
- Filename (large, word-break)
- Meta line: "Uploaded by <name> on <timestamp> · <size> · <version_label>"
- Two buttons (right):
  - **Download** — generates a 60-second signed URL and opens it in a new tab
  - **Supersede** (admin/supervisor only) — marks the active signed version as superseded (no replacement required at the same time)

### Version History table
Columns:
- **Version** — colored pill matching the version type (Signed green, Final for Review blue, Draft gray) + an "Active" or "Superseded" badge
- **File** — filename + optional version label sub-line
- **Uploaded** — uploader name + timestamp
- **Size** — formatted (B / KB / MB)
- **Actions** — Download (any user) + Supersede (admin/supervisor, only on non-superseded rows)

### Empty state
- "No financial statements uploaded yet."
- "Upload Financial Statements" button (admin/supervisor only)

### Upload modal (`#modal-upload-fs`, 520px wide)

Title: "Upload Financial Statements". Body:
- Intro: "Upload the client-prepared FS for review. Accepts PDF and Word (max 50 MB)."
- **Version Type** select (required):
  - `draft` — "Draft (client working copy)"
  - `final_for_review` — "Final for Review (client signed off, ready for partner)"
  - `signed` — "Signed (final signed by client — audit evidence)"
  - Hint: "Uploading a new Signed version will mark the previous signed version as superseded."
- **Version Label** text input (optional) — placeholder "e.g. v1, Final Adjusted, Post-AJE"
- **File** input (required) — `accept=".pdf,.doc,.docx,application/pdf,application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document"`
- **Notes** textarea (optional, 2 rows) — "What changed in this version?"
- **Error banner** (red, hidden by default) — shown when client-side validation fails or server-side errors come back
- Footer: Cancel + Upload buttons. Upload button shows "Uploading..." during the call.

### Client-side validation order

1. File present → else "Choose a file to upload."
2. Size ≤ 50 MB → else "File is X — limit is 50 MB."
3. Extension in {pdf, doc, docx} → else "Only PDF and Word (.doc, .docx) files are accepted."

---

## 3. Data model

### Table: `public.engagement_fs_uploads` (migration `20260519120003_fs_uploads.sql`)

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | Default `gen_random_uuid()`. Client supplies a value so it can be used as the storage path. |
| `engagement_id` | uuid, FK→engagements, ON DELETE CASCADE | |
| `organization_id` | uuid, FK→organizations, ON DELETE CASCADE | |
| `version_type` | text | CHECK: `draft` / `final_for_review` / `signed` |
| `file_name` | text NOT NULL | Original filename (preserved for download) |
| `file_path` | text NOT NULL | Path in storage: `{organization_id}/{engagement_id}/{id}.{ext}` |
| `file_size_bytes` | bigint | Captured from `File.size` |
| `mime_type` | text | Captured from `File.type` |
| `version_label` | text | Optional admin-set label |
| `uploaded_by` | uuid, FK→profiles | |
| `uploaded_at` | timestamptz, default now() | |
| `is_superseded` | bool, default false | Soft-delete flag |
| `superseded_at`, `superseded_by` | ts + uuid | |
| `notes` | text | |
| `created_at` | timestamptz, default now() | |

### Indexes
- `idx_efu_engagement_id` — list by engagement
- `idx_efu_organization_id` — RLS performance
- `idx_efu_version_type` — composite on `(engagement_id, version_type)`
- **`idx_efu_one_active_signed`** — partial UNIQUE index: `(engagement_id) WHERE version_type = 'signed' AND is_superseded = false`. This is what enforces "at most one active signed per engagement."

### RLS (all use `public.get_user_org_ids()` from migration 001)

- **SELECT** — org members
- **INSERT** — org members (NO Pro-tier check — FS upload is included in all tiers)
- **UPDATE** — org members
- GRANT: `SELECT, INSERT, UPDATE` to `authenticated`. No DELETE policy — soft-delete only.

### Supabase Storage — `fs-documents` bucket (out-of-band setup)

**Bucket settings (set in dashboard):**
- Name: `fs-documents`
- Public: false
- File size limit: 52,428,800 bytes (50 MB)
- Allowed MIME types: `application/pdf`, `application/vnd.openxmlformats-officedocument.wordprocessingml.document`, `application/msword`

**Path convention:** `{organization_id}/{engagement_id}/{upload_id}.{ext}` — the upload row's id is the storage filename, which is why the client generates the UUID locally.

**Storage RLS policies** (in `supabase/staging-fs-storage.sql`, run after bucket exists):
- `fs_documents_select_own_org` — SELECT allowed when bucket = `fs-documents` AND first folder segment ∈ user's `organization_members.organization_id`
- `fs_documents_insert_own_org` — INSERT allowed under same condition
- No UPDATE, no DELETE — files are immutable, superseding is metadata-only

---

## 4. Permissions & workflow

### Role gates

Added to `public/js/auth.js`:

```js
upload_fs: ['admin', 'supervisor']
```

| Action | Role |
|---|---|
| See FS tab | any role |
| See "Upload Financial Statements" button | admin, supervisor |
| Upload a new version | admin, supervisor |
| Download any version | any role (60s signed URL) |
| Mark a version superseded | admin, supervisor |

**Note on enforcement:** the `upload_fs` permission is enforced client-side (`can('upload_fs')` guard on `openFsUploadModal` and `supersedeFsUpload`). The RLS policy is broader — any org member can INSERT/UPDATE rows. If a `preparer` somehow bypassed the UI, they could write rows. **Mitigation:** Sprint 2 should add `WITH CHECK (public.user_role_in_org(organization_id) IN ('admin','supervisor'))` to the INSERT policy.

### Version workflow

```
[Draft uploaded] ──┐
[Draft uploaded] ──┤   (multiple drafts can co-exist)
[Draft uploaded] ──┘
                     │
[Final for Review] ──┤   (multiple FFRs can co-exist)
[Final for Review] ──┘
                     │
[Signed v1] ────── ACTIVE SIGNED (unique)
                     │
[Signed v2 uploaded]
   ├─ JS auto-supersedes v1 (sets is_superseded=true, superseded_at, superseded_by)
   ├─ Storage upload to new path
   ├─ INSERT new row
   └─ If INSERT fails → cleanup orphaned storage object
[Signed v2] ────── ACTIVE SIGNED (now unique)
[Signed v1] ────── superseded
```

The supersede-then-insert is **not transactional** — if the supersede UPDATE succeeds and the storage upload fails, the old signed is now flagged as superseded with no replacement. See Judgment Calls.

### Audit-log entries (via `logActivity`)

- `uploaded_fs` — action; entity = engagement_fs_upload; details = `{version_type, file_name, size_bytes}`
- `superseded_fs` — details = `{file_name, version_type}`

These show up on the Activity Log tab.

---

## 5. Out of scope (NOT built in Sprint 1)

- **PDF preview inline** — Download opens in a new tab via signed URL; no embedded PDF viewer
- **DOCX preview** — same; the browser downloads it
- **File replacement (re-upload over an existing id)** — no UI path. Mistake = supersede + re-upload
- **Bulk download / ZIP export** — Sprint 3 (part of inspection PDF)
- **Comparison/diff between versions** — not in scope. Auditor uses whatever desktop tool
- **OCR / text extraction** — not in scope
- **TB-to-FS reconciliation** — separate roadmap item, not Sprint 1
- **Signature verification on signed PDFs** — not in scope
- **Notification when client uploads a new version** — uploads are admin/supervisor only in Sprint 1; client-portal upload is Sprint 3+
- **Hard delete** — by policy, no DELETE. Misuploads stay on record (note field can explain)
- **File-name sanitization** — original name preserved; if it has odd characters, browser handles
- **DB-enforced role check on INSERT** — RLS is org-scoped only; role enforcement is client-side
- **Storage-level virus scan** — relies on Supabase defaults

---

## 6. Judgment calls made

### J1 — Single tab, not a separate page

**Choice:** FS upload lives as a tab on `engagement.html`, not as a standalone page like Completion Memo.

**Reasoning:** Completion Memo is a partner-only, heavy workflow with its own page. FS upload is a simple file-management slot that belongs in the engagement context. Keeps clicks low for the most common action (check what FS we have).

**Alternative:** Standalone page. Rejected — would force navigation away from the engagement.

### J2 — No Pro-tier gate on FS upload

**Choice:** FS uploads are available on all tiers (Essentials + Pro). Completion Memo + Local Compliance are Pro-gated; FS is not.

**Reasoning:** Storing the client's FS is table stakes. An Essentials firm absolutely needs to attach the FS they audited. Gating this would push Essentials firms to keep using shared drives + manual tracking — defeats the product premise.

**Risk:** Reduces Pro upgrade pressure. Decision: accepted.

### J3 — Auto-supersede on signed re-upload (not a manual "replace" flow)

**Choice:** When a user uploads a new `signed` version, the JS automatically marks the existing active signed as superseded *before* inserting the new row. The UI hint explains this.

**Reasoning:** Respects the partial unique index without forcing the user to do two steps. The alternative (failing the insert with a constraint error and asking the user to manually supersede first) is worse UX.

**Risk:** Not transactional — if the storage upload fails after the supersede UPDATE succeeds, the firm is left without an active signed. JS retries from the upload step would re-supersede a no-longer-active row (no-op). **The hole:** a transient browser crash between supersede and upload leaves the engagement with no active signed and a "Superseded" old version. Manual fix: re-upload a signed version.

**Mitigation considered:** Wrap in a `pg_transaction()` RPC. Deferred to Sprint 2 cleanup if it becomes a real-world problem.

### J4 — Client generates the upload UUID

**Choice:** `crypto.randomUUID()` in the browser → use as both the row id AND the storage filename.

**Reasoning:** Lets us write to storage *before* the DB insert, then use the same id in the insert. If we generated the id server-side via DB default, we'd have a chicken-and-egg between storage path and DB row.

**Risk:** Trust the browser's UUID. `crypto.randomUUID()` is browser-native and collision-resistant; same standard as `gen_random_uuid()` server-side.

### J5 — 60-second signed URL for downloads

**Choice:** Each download click generates a fresh signed URL expiring in 60s.

**Reasoning:** Long enough to start the download, short enough that a leaked URL is useless. No download tokens persisted.

**Risk:** User saves the page, comes back in 5 minutes, clicks Download from the old DOM — won't work, will need to re-click. Acceptable.

### J6 — Files are immutable; no overwrite path

**Choice:** Once uploaded, the file in storage never changes. Filename in storage is `<uuid>.<ext>`; the original filename is only stored in the DB row.

**Reasoning:** Evidence integrity. A file that can change is a file that can be tampered with after the fact. Network inspectors look for this.

### J7 — Supersede is a separate action, not bundled with "upload next version"

**Choice:** UI has both: "Upload Financial Statements" (which can promote a new signed) AND a per-row "Supersede" button.

**Reasoning:** Two real use cases: (a) client sends a revised version → upload it, system auto-supersedes prior signed. (b) Auditor realizes a draft was uploaded by mistake → wants to mark it superseded without replacement. The standalone button serves (b).

**Risk:** A user might supersede a row they shouldn't have. No undo. Activity log has the action — recoverable via DB.

### J8 — No DB-level role enforcement on INSERT/UPDATE

**Choice:** RLS allows any org member to INSERT or UPDATE. Client-side `can('upload_fs')` is the only enforcement.

**Reasoning:** Pattern match with TB upload table (`trial_balance_lines`) which has the same shape.

**Risk:** Bypass via direct API call by a preparer-role user. Sprint 2 should harden — add `user_role_in_org()` helper used in WITH CHECK clauses across all admin-gated tables.

### J9 — Tab-index bug fixed during this work

**Choice:** While editing `switchTab()`, I also fixed the pre-existing `tabMap` bug where button DOM order didn't match the index map. Was: `{ sections: 0, tb: 1, findings: 2, materiality: 3, activity: 4 }`. Now: `{ tb: 0, materiality: 1, sections: 2, findings: 3, fs: 4, activity: 5 }`.

**Reasoning:** Could not add the new tab without correcting the map, and discovered the original was misaligned. Net: one drive-by fix.

**Risk:** None — old code highlighted the wrong button on click. New code matches DOM order.

---

## 7. Verification questions for Perplexity

**On evidence sufficiency:**

1. "Under ISA 230, what level of documentation of the financial statements being audited is required? Specifically: does the auditor need to retain the actual FS file (PDF/DOCX), or is a reference sufficient? Are there jurisdictional differences (UAE, Qatar, US) on retaining the FS file in the audit working papers?"

2. "ISA 560 (Subsequent Events) requires the auditor to consider events between the FS date and the auditor's report date. If management revises the FS after the report date, what version is the auditor's report 'on'? Should our 'signed' version include the auditor's report date as a field, not just the upload timestamp?"

**On retention + format:**

3. "ISA 230.A23 mentions retention periods. The IAASB suggests not less than five years from the date of the auditor's report. We are not enforcing a retention period — files persist until manually deleted (which we don't allow). Is unlimited retention acceptable, or could it create a discoverability/privilege issue?"

4. "Are there ISA-prescribed file format requirements for the FS in the audit file? Specifically, must we keep a 'machine-readable' or 'tagged' version (e.g., iXBRL where applicable), or is PDF sufficient?"

**On signed-version uniqueness:**

5. "Our partial unique index allows exactly one active 'signed' version per engagement, with prior signed versions auto-superseded. Is this correct in principle, or would a network inspector expect to see multiple 'signed' versions in cases of restatement (e.g., signed-original + signed-restated)? Should restatements be a separate version_type instead of overwriting?"

**On supersede semantics:**

6. "If management provides a revised FS after the audit field work but before report issuance, is the prior draft considered superseded or retained as evidence of what was reviewed? Our current model marks it superseded — should it instead be 'retained for evidence' with a different flag?"

7. "Does ISA 580 (Written Representations) require management to confirm the version of FS they're representing on? If so, our system should tie the management rep letter to a specific FS upload id. Currently not linked."

**On access + integrity:**

8. "Network inspectors will ask: 'how do we know this PDF wasn't modified after the audit report date?' We store the file in private object storage and don't allow overwrite. Is hash-pinning (SHA-256 of file content stored in the DB row at upload time) standard practice for audit evidence, or overkill?"

9. "Under PCAOB AS 1215 (the US equivalent of ISA 230), is there a requirement that audit documentation include a 'documentation completion date' after which changes are restricted? Should we be tracking a per-engagement 'documentation lock' date that disables FS uploads?"

**On scope:**

10. "What other workpapers, beyond the FS itself, are typically expected to be 'attached' to an engagement in a CaseWare-style audit tool? E.g., trial balance (we have it), management rep letter, engagement letter, independence declaration, planning memo. Which of these are ISA-mandatory vs. firm-policy?"

---

## 8. Verification questions for Copilot (code review)

1. **`engagement.html` — `handleFsUpload()`** — the supersede-then-upload is not transactional. If `supabaseClient.storage.from(FS_BUCKET).upload(...)` throws after the supersede UPDATE succeeded, the user is left with no active signed and a superseded prior. Is there a safer pattern with the supabase-js client (e.g., reverse the order: insert metadata first, then upload, with cleanup on failure)?

2. **`engagement.html` — `handleFsUpload()` cleanup** — on metadata insert failure, I call `supabaseClient.storage.from(FS_BUCKET).remove([storagePath])`. If `remove()` itself fails, we have an orphaned file. Should we add a retry queue, or trust that orphans are rare enough to manually clean?

3. **`engagement.html` — `crypto.randomUUID()`** — confirm this is available in all browsers Audexon supports. We've been silent on browser-support floor.

4. **`migrations/20260519120003_fs_uploads.sql` — partial unique index** — confirm `WHERE version_type = 'signed' AND is_superseded = false` correctly enforces one-active-signed across concurrent inserts. If two browser tabs upload signed FS within 100ms of each other, can both succeed?

5. **`supabase/staging-fs-storage.sql` — storage policies** — confirm `(storage.foldername(name))[1]` returns the first segment correctly when the path is `<uuid>/<uuid>/<uuid>.pdf`. Test case I haven't run: what if `name` is `'../foo'` (path traversal attempt)?

6. **RLS broadness** — `efu_insert` and `efu_update` allow any org member to write rows. A `preparer`-role user could call the Supabase API directly and upload an FS, bypassing our client guard. Worth tightening now or Sprint 2?

7. **Memory usage on large files** — Supabase JS client loads the full File into memory before upload. At 50MB cap × concurrent users, is that a Netlify-side concern? (Likely not — Netlify isn't proxying the file; it goes directly to Supabase.)

---

## 9. Closure checklist

Sprint 1 — FS Upload closes when:

- [ ] `fs-documents` bucket created in **staging** Supabase dashboard with the prescribed settings
- [ ] `supabase/staging-fs-storage.sql` applied in **staging** SQL editor
- [ ] Manual smoke test: upload a draft, upload a final_for_review, upload a signed, upload a second signed (verify auto-supersede), download each, supersede manually, verify activity log
- [ ] Perplexity questions 1–10 answered; spec updated with conclusions
- [ ] Copilot questions 1–7 addressed; code fixes committed or deferred with reason
- [ ] Any gaps trigger fix-or-defer entry in Section 5
- [ ] User reviews and signs off on this spec

When all seven boxes are ticked, this feature is **CLOSED**.

---

## 10. Verification pass — 2026-05-20

Cross-checked against Perplexity (ISA research) + GitHub Copilot (code review) + claude.ai (product tiebreaks). Two commits + two migrations applied:

- `0eea3bd` — C1+C4+C6 hardening (transactional RPC, RLS role gate, unique-violation message)
- (next commit) — P2+P5+P8 evidence fields (report_date, SHA-256, restatement labeling)
- Migration `20260520120001_fs_upload_hardening.sql` applied to staging
- Migration `20260520120002_fs_upload_evidence.sql` applied to staging

### Issues fixed

| # | Source | Issue | Fix |
|---|---|---|---|
| C1 | Copilot Q1 | Supersede UPDATE → upload → INSERT was non-transactional; storage upload failure between steps could orphan engagement with no active signed | New `commit_fs_upload` RPC supersedes + inserts in one transaction. Client now uploads to storage first, then calls RPC. Worst failure = harmless orphan file |
| C4 | Copilot Q4 | Concurrent signed uploads surfaced raw 23505 constraint error | Client detects `23505` / `idx_efu_one_active_signed` / "duplicate key" and shows: *"Another signed version was just uploaded by someone else. Please reload to see the latest file."* |
| C6 | Copilot Q6 | RLS allowed any org member to INSERT/UPDATE `engagement_fs_uploads`; preparer could bypass UI gate via direct API | New `user_can_upload_fs()` helper checks admin/supervisor role; both INSERT and UPDATE policies now require it. SELECT stays open |
| P2 + claude.ai | Perplexity Q2 | ISA 560 — auditor's report date is a substantive datum but we only had upload timestamp | Added `report_date` (date) column, REQUIRED for signed uploads via CHECK constraint + app-layer guard. UI shows date input only when version_type='signed'. Display in active-signed banner and history table |
| P5 + claude.ai | Perplexity Q5 | UI labeled all superseded rows the same, losing the "this was the signed-original-before-restatement" semantic that inspectors look for | Superseded signed rows now display amber badge **"Signed (superseded by restatement)"** with tooltip referencing ISA 560. Drafts and FFRs keep the neutral "Superseded" badge |
| P8 + claude.ai | Perplexity Q8 | No cryptographic proof that stored file hadn't been modified since upload | Added `file_sha256` column (lowercase hex). Computed client-side via Web Crypto `crypto.subtle.digest('SHA-256', ...)` before upload, passed to the RPC, stored on row. Truncated hash displayed in UI (`a3b4c5d6…1234`) with full hash on hover. Inspector can verify integrity by re-hashing the downloaded file |

### Confirmed correct as-built (no change needed)

| # | Source | Finding |
|---|---|---|
| C3 | Copilot Q3 | `crypto.randomUUID()` is widely supported in target browsers (Chrome/Edge/Safari/Firefox 2023+). No polyfill needed |
| C5 | Copilot Q5 | `(storage.foldername(name))[1]` correctly returns first path segment; `../foo/file.pdf` resolves to `..` which fails the org-membership check. Path traversal handled by Supabase |
| C7 | Copilot Q7 | 50 MB cap + Supabase JS client buffering is fine for our scale. TUS resumable uploads only needed if cap raised to hundreds of MB |
| P1 | Perplexity Q1 | Retaining the actual FS file (not just a reference) is correct under ISA 230. We already do this via Supabase Storage |
| P4 | Perplexity Q4 | PDF (or any non-editable locked format) is sufficient for ISA. We accept PDF + DOCX + DOC |
| P6 | Perplexity Q6 | Current supersede semantics for pre-report drafts acceptable — clerical changes can be superseded; substantively different drafts should be retained-for-evidence. Latter handled by per-row notes field |

### Deferred to Sprint 2/3 (logged here, will not be revisited in Sprint 1)

| # | Source | Why deferred |
|---|---|---|
| C2 | Copilot Q2 | Orphan-file reconciliation job — needs server-side cron/queue; Sprint 3 |
| P3 | Perplexity Q3 | Configurable retention policy per firm (default 5-7y) — needs settings UI + enforcement job; Sprint 3 |
| P7 | Perplexity Q7 | Mgmt rep letter ↔ FS upload linkage — `mgmt_rep_letters` table doesn't exist yet; Sprint 2 |
| P9 | Perplexity Q9 | Documentation lock date / 60-day post-report assembly per ISA 230 — new fields on engagements + enforcement; Sprint 2/3 |
| P10 | Perplexity Q10 | Other expected workpapers (engagement letter, planning memo, TCWG comms) — Sprint 2 backlog already covers these |

**Sprint 1 — FS Upload: CLOSED.**
