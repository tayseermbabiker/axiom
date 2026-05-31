# Sprint 3 #2 — Understanding the Entity: GO / NO-GO gate

**Decision needed before building.** The Sprint 3 #2 spec (`sprint-3-understanding-entity.md`) describes the workpaper as designed. This file is the *should we even build it* gate.

---

## Why this gate exists

The "Understanding the Entity" workpaper (ISA 315 R 2019) is conventionally a **hybrid Permanent File / Current File** artifact in real audit firms:
- Entity nature, ownership, governance, industry, internal control narrative — **rarely change year-over-year** (Permanent File territory)
- Risk-relevant changes, current-year IT environment shifts, new significant accounts — change annually (Current File)

**Audexon's product constraint (locked):**
- We will NOT build a Permanent File concept. Every workpaper is annual / per-engagement.
- Carry-forward across years is OUT of scope (no engagement-to-engagement linkage planned for v1.x).
- This means: if we ship the Understanding workpaper as-spec'd, partners re-enter the entity overview, ownership, internal control narrative, IT environment, etc., from scratch every year. For 80%+ of the content, nothing has changed.

**The risk:** partners will see this as bureaucratic re-typing, hate it, and either skip the workpaper entirely (defeats inspection readiness) or paste prior-year content (which inspectors will spot if dates / FX figures don't update).

**The alternative:** drop the dedicated workpaper. Capture the ISA 315 understanding INSIDE existing planned workpapers:
- Audit Strategy (#1, shipped) — already has "significant factors directing the team" + "preliminary engagement activities" narrative fields
- Risk Assessment matrix (#3, planned) — captures inherent risk factors per assertion (the heart of ISA 315 risk identification)
- Sections / Findings (v0.5, shipped) — substantive work is documented per-section

**The middle path:** ship a *minimal* Understanding workpaper — 4-6 narrative fields max, focused on what changes annually (industry conditions this year, new risks identified, internal control changes since last year) — and skip the PF-style entity descriptors.

---

## Three options to decide between

**A. Build as currently spec'd** — full 28-narrative-field workpaper, accept the annual re-entry pain.
**B. Drop entirely** — rely on Audit Strategy + Risk Assessment to satisfy ISA 315.
**C. Build minimal** — 4-6 fields focused on annual-change content only, drop the PF-character fields.

---

## Verification questions

### For Perplexity (ISA + inspection angle)

1. "Under ISA 315 (Revised 2019), is there a documentation requirement for a SEPARATE 'Understanding the Entity' workpaper, or can the auditor satisfy ISA 315.32 (documentation of understanding obtained, risk identification, and the basis for risk assessment) by capturing the understanding INSIDE other workpapers — specifically an overall Audit Strategy workpaper (ISA 300) and a Risk Assessment matrix (ISA 315.27)? In other words: if our software has Audit Strategy + Risk Assessment, do we ALSO need a standalone Understanding workpaper, or is that redundant under ISA?"

2. "For small-firm audits subject to international network quality reviews (BDO / RSM / Crowe / Mazars), do network inspectors specifically look for a STANDALONE 'Understanding the Entity' working paper, or do they accept the understanding being demonstrated across other workpapers (strategy + risk + section-level narrative)? Asking because our product targets small Gulf firms doing network-affiliated work."

3. "Our software architecture will NOT support carry-forward from prior-year engagements (every engagement is independent — no Permanent File concept). For the parts of ISA 315 understanding that are TRULY permanent-file in nature (entity legal structure, ownership, governance, broad industry overview, foundational internal control narrative), what's the ISA-compliant minimum we MUST capture per engagement, vs. what we can rely on being implicit in the partner's prior-year knowledge of the client? Specifically: can a continuance partner write 'No material changes to entity, ownership, governance, or industry conditions since prior period — refer to prior-year file' and have that be ISA 315 sufficient?"

### For Copilot (engineering / integration angle)

4. "Given that we just shipped an Audit Strategy workpaper with these narrative fields: scope_characteristics, reporting_objectives, significant_factors, preliminary_activities_summary, resources_plan, partner_direction_plan — and we're planning a Risk Assessment matrix that will capture significant risks per assertion per audit section — what content from the proposed 'Understanding the Entity' workpaper (entity nature, ownership, governance, industry, regulatory environment, 5 components of internal control, IT environment, CoTABDs, inherent risk factors, sources, conclusion) is genuinely NEW vs already captured or about-to-be-captured? Identify the unique-content delta and flag fields that would be pure duplication."

5. "If we drop the dedicated Understanding workpaper and instead expand the Audit Strategy 'significant_factors' field with sub-prompts (industry, regulatory, internal control overview, IT environment), is that schema-cheaper than maintaining a separate `engagement_entity_understanding` table with 28 columns? Specifically: do partners gain or lose by having ISA 315 understanding folded into Audit Strategy rather than as its own approval-gated workpaper?"

### For claude.ai (product strategy angle)

6. "Audexon is a solo-founder SaaS for small audit firms targeting inspection readiness for international network reviews (BDO / RSM / Crowe / Mazars). The Qatar partner gap list (May 2026) flagged 'planning + materiality + risk + completion memo' as the missing pieces — NOT 'understanding the entity' specifically. We're planning to build it as item #2 of Sprint 3 (~1-2 days) because it's the canonical ISA 315 workpaper. BUT: our product will NOT support Permanent File / carry-forward across engagement years, which means partners would re-enter most of this content annually — a known UX drag. Given option A (build full, accept re-entry pain), option B (drop entirely, rely on Audit Strategy + Risk Assessment to satisfy ISA 315), option C (build minimal — 4-6 fields focused on annual change only) — what's the right call for a 2026-06-01 partner demo + Qatar pilot lock-in? Optimize for: (a) partners signing the pilot, (b) inspection readiness defensibility, (c) build velocity to the demo date."

7. "If the call is to drop the standalone workpaper (option B), what's the minimum we should add to the existing Audit Strategy form so it credibly substitutes for ISA 315 understanding — to keep the Qatar partner's reaction at 'good enough' rather than 'where's the ISA 315 workpaper'? Should we rename Audit Strategy to 'Audit Planning' and add ISA 315 attestations + 1-2 industry/IC narrative fields, or leave Audit Strategy as-is and let Risk Assessment carry the ISA 315 weight?"

---

## What to do with the answers

Paste each agent's response into `C:\Users\LENOVO\Desktop\` as:
- `perplexity-go-no-go.txt`
- `copilot-go-no-go.txt`
- `claude-ai-go-no-go.txt`

Then tell Claude Code "answers in" and I'll synthesize → recommend A/B/C → either update the existing spec, drop #2 from Sprint 3, or write a new minimal spec.

---

## Decision log

- **Date decided:** 2026-05-21
- **Verdict:** **C (refined)** — parked for this sprint
- **Reasoning:** Three-agent verification (Perplexity + Copilot + claude.ai) converged on Option C (minimal). Claude.ai refined: rename "Audit Strategy" → "Audit Planning", embed ISA 315 as Section B inside the same workpaper (no new table — ALTER existing). User parked the build because: (a) Qatar partner did NOT name ISA 315 understanding on the original gap list, (b) #3 Risk Assessment matrix is the actual partner-facing centerpiece and needs the velocity, (c) #5 Inspection PDF is the demo headline. Parking #2 frees ~1.5d of build time.
- **Next action:** Refined design captured at `sprint-3-audit-planning-PARKED.md`. Resume only if Qatar partner flags ISA 315 during 2026-06-01 demo, or in Sprint 4.
