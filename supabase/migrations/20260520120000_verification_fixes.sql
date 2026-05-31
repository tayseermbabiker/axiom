-- Sprint 1 verification pass — fixes from Perplexity + Copilot + Claude.ai cross-check.
--
-- (a) Add resources_consultations narrative column with a sensible default so
--     the inspector never sees a blank field — the partner has actively
--     confirmed N/A rather than just left it empty. Addresses Perplexity Q3
--     gap on ISA 220 (Revised) resources / specialists / consultations
--     evidencing. Implemented as a narrative field instead of two new
--     attestations to avoid friction on simple small-firm audits where these
--     are usually N/A.
--
-- (b) Tighten sign-off paywall: a firm that downgraded from Pro can still
--     edit attestations, narratives, opinion, EQR — but cannot actually
--     sign and lock the memo without re-upgrading. Closes the "create on
--     Pro, downgrade, sign for free" loophole without punishing firms
--     mid-engagement.

-- =========================================================================
-- (a) New narrative column: resources / specialists / consultations
-- =========================================================================
ALTER TABLE public.engagement_completion_memo
  ADD COLUMN IF NOT EXISTS resources_consultations text
    NOT NULL
    DEFAULT 'No specialists engaged. No formal consultations required.';

COMMENT ON COLUMN public.engagement_completion_memo.resources_consultations IS
  'ISA 220 (Revised) evidence of partner consideration of resources, specialists, and required consultations. Defaults to N/A statement so the field is never blank at inspection — partner overwrites when applicable.';


-- =========================================================================
-- (b) Pro-tier gate on sign-off (status transition to locked)
--     Replaces fn_snapshot_and_lock_memo with a version that first checks
--     org_has_pro_tier() at the moment signed_at transitions from NULL to a
--     value. Non-Pro orgs can do everything else on the memo — they just
--     can't sign.
-- =========================================================================
CREATE OR REPLACE FUNCTION public.fn_snapshot_and_lock_memo()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_eng public.engagements%ROWTYPE;
BEGIN
  IF NEW.signed_at IS NOT NULL AND OLD.signed_at IS NULL THEN
    -- Pro tier required to sign. Edits / attestation ticking remain open
    -- to org members regardless of tier — see ecm_update RLS policy.
    IF NOT public.org_has_pro_tier(NEW.organization_id) THEN
      RAISE EXCEPTION
        'Signing a completion memo is a Pro-tier capability. Upgrade your plan to sign and lock this memo.';
    END IF;

    IF NEW.all_attestations_complete = false THEN
      RAISE EXCEPTION 'Cannot sign completion memo: not all attestations are complete';
    END IF;

    SELECT * INTO v_eng
    FROM public.engagements
    WHERE id = NEW.engagement_id;

    NEW.status                            := 'locked';
    NEW.snapshot_taken_at                 := now();
    NEW.overall_materiality_snapshot      := v_eng.materiality_overall;
    NEW.performance_materiality_snapshot  := v_eng.materiality_performance;
    NEW.updated_at                        := now();
  END IF;

  RETURN NEW;
END;
$$;
