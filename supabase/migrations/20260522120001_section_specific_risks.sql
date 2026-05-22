-- 2026-05-22 — Section-level engagement-specific risks (ISA 330 control)
--
-- Per 3-AI procedures synthesis (Perplexity + Copilot + claude.ai),
-- the "template-lazy" inspection risk is best mitigated NOT by
-- per-procedure confirmation checkboxes (which become click-through
-- compliance) but by a section-level required textarea that forces
-- partners to articulate client-specific factors BEFORE section
-- sign-off — even when keeping all default procedures.
--
-- Claude.ai quote: "the real design intervention here is in the
-- rationale field, not the procedure list."
--
-- Single field. No CHECK constraint (avoids breaking existing
-- engagements). UI-side validation enforces it before partner
-- sign-off; soft warning before supervisor sign-off.

ALTER TABLE public.audit_sections
  ADD COLUMN IF NOT EXISTS engagement_specific_risks text;
