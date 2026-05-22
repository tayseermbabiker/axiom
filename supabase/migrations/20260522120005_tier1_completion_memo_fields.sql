-- 2026-05-22 — Tier 1 Completion Memo gap items per 3-AI synthesis
-- (Perplexity + claude.ai + Copilot). Adds 13 new fields across 6 ISA
-- documentation requirements that small-firm inspectors universally flag.
--
-- Architecture: pure ALTER on engagement_completion_memo. No new tables.
-- All fields are nullable / default false so existing memos are unaffected.
-- Hard-gate validation (EQR + Mgmt Rep Letter must be present before
-- signMemo()) is enforced in the UI layer + sign_completion_memo RPC.
--
-- Items shipped (Copilot's recommended priority order):
--   1. EQR reconciliation gate    (ISA 220R)   — validation only, no schema
--   2. Mgmt Representation Letter (ISA 580)    — 3 fields, hard gate on lock
--   3. TCWG Communication         (ISA 260)    — 4 fields
--   4. Going Concern structured   (ISA 570)    — 2 new fields (assessment + rationale)
--   5. Subsequent Events struct.  (ISA 560)    — 3 new fields (procedures + cutoff + identified)
--   6. Final Analytical Review    (ISA 520)    — 1 field
--   7. Uncorrected Misstatements  (ISA 450)    — 2 fields (evaluation + mgmt rationale)
--   8. Final Independence         (ISA 220)    — 1 field
--
-- Existing fields preserved:
--   going_concern_conclusion       — repurposed as the structured-conclusion rationale text
--   subsequent_events_conclusion   — repurposed as the structured-conclusion text
--   uncorrected_vs_materiality     — keep as quantitative classifier (below/approaching/exceeds)

ALTER TABLE public.engagement_completion_memo
  -- ISA 580 — Management Representation Letter
  ADD COLUMN IF NOT EXISTS mgmt_rep_letter_obtained boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS mgmt_rep_letter_date     date,
  ADD COLUMN IF NOT EXISTS mgmt_rep_letter_reference text,
  -- ISA 260 — Communication with Those Charged with Governance
  ADD COLUMN IF NOT EXISTS tcwg_communicated         boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS tcwg_communication_date   date,
  ADD COLUMN IF NOT EXISTS tcwg_matters_communicated text,
  ADD COLUMN IF NOT EXISTS tcwg_response             text,
  -- ISA 570 — Going Concern (structured assessment dropdown + rationale)
  ADD COLUMN IF NOT EXISTS going_concern_assessment text
    CHECK (going_concern_assessment IS NULL OR going_concern_assessment IN
      ('no_uncertainty','identified_disclosed','identified_adverse_implications')),
  -- ISA 560 — Subsequent Events (structured sub-fields)
  ADD COLUMN IF NOT EXISTS subseq_events_procedures        text,
  ADD COLUMN IF NOT EXISTS subseq_events_review_through    date,
  ADD COLUMN IF NOT EXISTS subseq_events_identified        boolean,
  -- ISA 520 — Final Analytical Review
  ADD COLUMN IF NOT EXISTS final_analytical_review_conclusion text,
  -- ISA 450 — Uncorrected Misstatements (qualitative evaluation)
  ADD COLUMN IF NOT EXISTS uncorrected_misstatements_evaluation text,
  ADD COLUMN IF NOT EXISTS uncorrected_misstatements_mgmt_rationale text,
  -- ISA 220 / IESBA Code — Final Independence Conclusion
  ADD COLUMN IF NOT EXISTS final_independence_conclusion text;
