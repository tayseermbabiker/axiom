# Audexon — Security & Confidentiality Brief

*Prepared for audit firms and network-affiliated partners evaluating Audexon.*
*Version 1.0 — 2026-05-29*

---

## 1. Who we are

Audexon is an audit working-paper and engagement platform built by an independent
software company registered in Dubai, UAE. We build exclusively for the audit
profession — three-level sign-off, working papers, trial-balance versioning,
findings, and inspection-ready export are the core of the product, not an add-on.

**Why you can rely on us as a young vendor:**
- Registered UAE entity (Dubai) with a named, accountable founder.
- Reviewed and validated by serving Big Four and regional audit partners.
- **Your data is portable and yours** — see §6. You are never locked in, and you
  are never dependent on our continued existence to retain or use your records.

---

## 2. Where your data lives

Audexon runs on enterprise cloud infrastructure (Supabase on AWS for the database
and authentication; Netlify for application delivery). Your engagement data is held
in a managed PostgreSQL database, not on shared spreadsheets or local machines.

- **Data residency:** the database region can be set to match your regulatory
  requirements (e.g. EU, Middle East). Confirmed per engagement.
- **No data on personal devices:** unlike desktop tools, working papers are never
  scattered across individual laptops that can be lost or stolen.

---

## 3. How your data is protected

| Control | Status |
|---|---|
| Encryption in transit (TLS) | **Live** — all traffic |
| Encryption at rest | **Live** — managed at the database and storage layer |
| Tenant isolation (Row-Level Security) | **Live** — one firm can never query another firm's data |
| Per-organization document isolation | **Live** — uploaded files are partitioned by organization; storage access is tied to organization membership |
| File-integrity proof (SHA-256) | **Live** — every uploaded financial statement is hash-pinned at upload, giving cryptographic proof the file has not been altered since (ISA 230) |
| Role-based access (three-level sign-off) | **Live** — preparer / supervisor / partner; only admin/supervisor can upload financial statements |
| Soft-delete (no destructive deletes) | **Live** — superseded/removed records are retained, not hard-deleted, preserving the inspection trail |
| Access-code gate on sign-up | **Live** |
| Multi-factor authentication (MFA) | **Available on request / rollout** |
| Immutable activity & audit log | **On roadmap** — who changed what, when |
| Automated database backups | **Live** — managed, point-in-time recovery |
| SOC 2 / ISO 27001 | **Roadmap** — controls being built to the standard ahead of certification |

We do **not** sell, mine, or use your client data for any purpose other than
operating the service for you.

### What we store, plainly

Audexon stores your engagement records — trial balances, procedures, findings,
sign-offs, completion memos — and the financial statements you choose to upload as
audit evidence. This is the **same model used by every leading cloud audit
platform** (CaseWare Cloud, Inflo, Suralink, AuditFile, CCH Axcess): the working
file lives in a secure, access-controlled cloud, not scattered across personal
laptops. What sets us apart is **per-firm isolation, file-integrity hashing, your
own export rights at any time, and an optional bring-your-own-cloud deployment**
(see §5) for firms that want the data to never leave infrastructure they own.

---

## 4. Sub-processors

We rely on a short, audited list of established infrastructure providers:

- **Supabase / AWS** — database, authentication, storage
- **Netlify** — application hosting and delivery
- **Resend** — transactional email (alerts, invitations)

A current sub-processor list and a Data Processing Agreement (DPA) are available on
request.

---

## 5. Deployment options — you choose how much we touch your data

Audexon is designed so that confidentiality scales with your firm's requirements:

| Option | Where data lives | Best for |
|---|---|---|
| **Shared SaaS** | Our managed cloud, isolated per firm via RLS | Firms comfortable with standard managed SaaS |
| **Dedicated instance** | A database isolated to your firm, in your chosen region | Firms wanting physical separation |
| **Bring-Your-Own-Cloud (BYOC)** | **Your own cloud account** — we deploy into infrastructure you own and can revoke our access to at any time | Network-affiliated firms with strict data-control mandates |

With BYOC, **client data never resides on Audexon's servers.** You hold the keys; we
provide the software. This delivers stronger confidentiality than installed desktop
software — without the loss of backups, audit trail, access control, or updates that
local installs suffer.

---

## 6. Data ownership, portability & exit

- **You own your data.** Always.
- You can export your engagement data at any time.
- On termination, we provide a full export and delete your data on request within a
  defined retention window.
- For firms requiring it, source-code escrow can be arranged so that continuity is
  guaranteed independent of the vendor.

---

## 7. Business continuity

- Managed, automated backups with point-in-time recovery.
- Infrastructure runs on tier-1 cloud providers with their own redundancy and SLAs.
- Data export guarantees (§6) mean your records survive any vendor event.

---

## Contact

For a DPA, sub-processor list, data-residency confirmation, or a BYOC/dedicated
deployment discussion, contact the Audexon team.

---

> **Internal note (delete before sending):** Mark items honestly. Before handing
> this to a partner, confirm:
> 1. **Company facts (§1)** — fill in the real entity name, license type (FZ-LLC /
>    mainland / DIFC), incorporation year, and founder credentials. Do **not** state
>    figures you can't evidence; an ex-Deloitte partner may ask for the trade licence.
> 2. **Supabase region** of staging/prod and whether it matches the buyer's residency
>    requirement.
> 3. **Current MFA status** — "rollout" vs "available" must be true.
> 4. **BYOC/dedicated** — not yet technically scoped against the current Supabase
>    setup. Frame as "available" / "on request", do not promise a delivery date.
> 5. Audit-log and SOC 2 lines are **roadmap, not live** — keep them framed that way.
>
> **DO NOT CLAIM** "we store zero client financial data" or "evidence stays in your
> Google Drive / OneDrive" (Copilot's wording). It is FALSE for Audexon as built:
> client financial statements are stored in the private Supabase `fs-documents`
> bucket, and TB/findings/memos are in the Supabase DB. There is no Drive/OneDrive
> integration. The honest, equally strong story is the "What we store, plainly"
> paragraph in §3 — use that.
