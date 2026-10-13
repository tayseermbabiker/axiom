# FSA Circular Gaps — 5 New Procedure Sections (October 2026)

**Trigger:** A prospect's regulator (Financial Services Authority) circular requires
the audit firm's written policy to contain procedures for a fixed list of FS areas.
Audexon's library covered 14 of 19. This spec closes the remaining five so that every
area on the circular maps to a built-in Audexon section.

**Method (same as `procedure-library-revision-2026-06.md`):**
Claude drafts (EN) → **Perplexity benchmarks for completeness** (ISA + IFAC SMP guide,
proportionate for SMEs) → Claude reconciles → **Perplexity translates to Arabic**
(masdar style, glossary-consistent) → bilingual review → lock here → apply to
`public/js/audit-templates.js` (EN + AR + assertions), `engagement.html` (New Section
dropdown), `public/i18n/ar.json` (section names). Forward-only: affects new
engagements/sections only.

Status legend: ✅ locked · ⏳ in progress · ⬜ pending

## Targets (5)
1. ⏳ Intangible Assets & Goodwill — template (pick from dropdown; not auto-seeded)
2. ⏳ Investments — template (not auto-seeded)
3. ⏳ Other Income — template (not auto-seeded)
4. ⏳ Financial Statement Disclosures — **auto-seeded** on every new engagement
5. ⏳ Trial Balance, Adjustments & Lead Schedules — **auto-seeded** (covers circular items "Trial balance & adjustments" + "Lead schedules / account analysis")

Rationale for seeding split: 4 and 5 apply to every audit; 1–3 only when the client
has those balances, so auto-seeding would clutter simple SME files.

Also fix in the same batch: Related Parties AR procedure 1 — «مملوكة بصرف خاص» →
«مملوكة ملكية خاصة» (translation glitch).

Format per line: `procedure — type — [assertions]`
Types: test_of_detail · analytical · controls · other.
Assertions: existence, completeness, accuracy, valuation, cutoff, occurrence,
rights_obligations, classification, presentation, fs_level.

---

## 1. Intangible Assets & Goodwill — ⏳ DRAFT

1. Obtain the movement schedule for intangible assets and goodwill (opening, additions, disposals, amortisation, impairment, closing); agree to the TB/GL and prior-year audited balances (ISA 500, ISA 510). — test_of_detail — [completeness, accuracy]
2. Vouch a sample of additions to contracts/invoices; verify recognition criteria are met (identifiable, controlled, probable future economic benefits, reliably measurable) and that only directly attributable costs are capitalised (IAS 38). — test_of_detail — [existence, rights_obligations, valuation]
3. (If internally generated) Verify research costs are expensed and development costs are capitalised only when all IAS 38.57 criteria are demonstrated; internally generated brands, customer lists and goodwill are not capitalised (IAS 38). — test_of_detail — [existence, valuation, classification]
4. Verify ownership and legal rights: trademark/patent registrations, licence and software agreements, terms and expiry dates (ISA 500). — test_of_detail — [rights_obligations, existence]
5. Review useful lives (finite vs indefinite), residual values and amortisation method for reasonableness and consistency; recompute amortisation for a sample; confirm goodwill and indefinite-life assets are not amortised (IAS 38). — test_of_detail — [valuation, accuracy]
6. Goodwill: verify initial measurement on acquisition (consideration transferred vs fair value of identifiable net assets acquired) and allocation to cash-generating units (IFRS 3, IAS 36). — test_of_detail — [valuation, accuracy]
7. Impairment: obtain management's annual impairment test for goodwill and indefinite-life intangibles, and tests for any asset with impairment indicators; evaluate key assumptions (cash-flow forecasts, discount rate, growth rate), recompute, and perform sensitivity analysis; if no indicators, document the assessment (IAS 36, ISA 540). — test_of_detail — [valuation]
8. Test disposals/derecognition: removal from the register, proceeds traced to bank, gain/loss recomputed (IAS 38). — test_of_detail — [existence, accuracy]
9. Perform analytical procedures: amortisation charge vs average cost, additions vs approved budget, carrying amount trend vs prior year; investigate significant variances (ISA 520). — analytical — [accuracy, completeness]
10. Test presentation and disclosure: reconciliation of carrying amount by class, useful lives/methods, indefinite-life assets and reasons, goodwill by CGU, key impairment assumptions and sensitivities, pledged intangibles (IAS 38, IAS 36, IFRS 3). — test_of_detail — [presentation, classification]

Note: 3, 6, 7 (goodwill parts) are conditional → N/A where not applicable.

---

## 2. Investments — ⏳ DRAFT
(Subsidiaries, associates, joint arrangements, financial investments)

1. Obtain the investment schedule (opening, additions, disposals, share of results, fair-value movements, impairment, closing) by investee; agree to TB/GL and prior-year audited balances (ISA 500, ISA 510). — test_of_detail — [completeness, accuracy]
2. Verify existence and ownership: confirm holdings with custodians/brokers/registrars (ISA 505); inspect share certificates, investee commercial-register/partner records, and purchase agreements. — test_of_detail — [existence, rights_obligations]
3. Evaluate classification using ownership %, voting rights, board representation and shareholder agreements: subsidiary (control — IFRS 10), associate (significant influence — IAS 28), joint arrangement (IFRS 11), or financial asset (IFRS 9); document the judgement. — test_of_detail — [classification]
4. Associates/joint ventures: recompute the equity-method share of profit/OCI using investee financial statements (audited where available); adjust for accounting-policy and reporting-date differences; assess reliability of investee information (IAS 28, ISA 500). — test_of_detail — [valuation, accuracy]
5. Financial investments: verify measurement category (amortised cost / FVOCI / FVTPL) against the business model and SPPI test; recompute fair value from quoted prices or evaluate valuation models and inputs (IFRS 9, IFRS 13, ISA 540). — test_of_detail — [valuation, classification]
6. Debt instruments at amortised cost/FVOCI: test the expected-credit-loss allowance (IFRS 9). — test_of_detail — [valuation]
7. Subsidiaries/associates in separate financial statements: verify the measurement basis elected (cost / IFRS 9 / equity method — IAS 27); where impairment indicators exist, evaluate management's recoverable-amount assessment (IAS 36, ISA 540). — test_of_detail — [valuation]
8. Vouch additions and disposals to agreements and bank; recompute gains/losses on disposal and any loss/gain of control or significant influence (IFRS 10, IAS 28). — test_of_detail — [occurrence, accuracy, cutoff]
9. Test investment income: dividends to investee declarations and bank; interest recomputed at contractual/effective rates; correct period (IFRS 9, IAS 1). — test_of_detail — [occurrence, completeness, cutoff]
10. (If consolidated FS) Apply group-audit requirements: scoping of components, consolidation adjustments, elimination of intra-group balances and transactions (ISA 600, IFRS 10). — other — [fs_level, completeness]
11. Identify pledges, restrictions and commitments over investments; related-party investees (IAS 24, IFRS 7). — test_of_detail — [rights_obligations, presentation]
12. Test presentation and disclosure: interests in other entities (IFRS 12), financial-instrument and fair-value hierarchy disclosures (IFRS 7, IFRS 13), current/non-current split (IAS 1). — test_of_detail — [presentation, classification]

Note: 4, 6, 7, 10 are conditional → N/A where not applicable.

---

## 3. Other Income — ⏳ DRAFT

1. Obtain an analysis of other income by nature (e.g. interest, dividends, rental, gains on disposal, FX gains, government grants, insurance claims, write-backs); agree to TB/GL (ISA 500). — test_of_detail — [completeness, accuracy]
2. Perform analytical procedures vs prior year and expectations derived from related balances (e.g. interest vs average deposits, rent vs lease agreements); investigate significant variances (ISA 520). — analytical — [occurrence, completeness, accuracy]
3. Vouch a sample of material items to supporting evidence (contracts, bank advices, dividend resolutions, insurance settlements, grant letters) (ISA 500). — test_of_detail — [occurrence, accuracy]
4. Recompute income derived from other balances: interest, dividends, gains/losses on disposal of PPE/investments, FX gains (cross-reference the source sections) (IAS 21, IAS 16, IFRS 9). — test_of_detail — [accuracy]
5. Government grants: verify conditions are met and recognition/presentation is appropriate (deferred income vs netting) (IAS 20). — test_of_detail — [occurrence, classification, presentation]
6. Investigate unusual or one-off credits (write-backs of provisions/payables, round sums, year-end entries, related-party sources) for fraud or earnings-management indicators; cross-reference JET (ISA 240). — test_of_detail — [occurrence]
7. Test cut-off of material items around year-end (ISA 500). — test_of_detail — [cutoff]
8. Verify classification (operating vs other income vs finance income) and that income and expenses are not offset except where permitted (IAS 1). — test_of_detail — [classification, presentation]
9. Test disclosure of material items of other income by nature (IAS 1, IAS 20, IAS 24). — test_of_detail — [presentation]

---

## 4. Financial Statement Disclosures — ⏳ DRAFT

1. Agree all figures in the primary statements and notes to the adjusted (final) trial balance and lead schedules; check casts and cross-references between statements and notes (ISA 500). — test_of_detail — [accuracy, presentation]
2. Complete a disclosure checklist for the applicable framework (full IFRS or IFRS for SMEs) and document N/A rationale for omitted disclosures (ISA 700). — other — [presentation, completeness]
3. Verify the statement of cash flows: recompute from comparative balance sheets and P&L, verify classification of operating/investing/financing flows and non-cash transactions (IAS 7). — test_of_detail — [accuracy, classification, presentation]
4. Verify the accounting-policy note reflects policies actually applied, and that significant judgements and sources of estimation uncertainty are disclosed (IAS 1, IAS 8). — test_of_detail — [presentation]
5. Verify comparative information agrees to prior-year audited FS, and any restatement/reclassification is disclosed (ISA 710, IAS 8). — test_of_detail — [presentation, accuracy]
6. Verify key cross-cutting disclosures are complete and consistent with audit evidence: related parties (IAS 24), contingencies and commitments (IAS 37), subsequent events (IAS 10), going concern basis, financial risk management (IFRS 7), capital management (IAS 1). — test_of_detail — [presentation, completeness]
7. Verify new/amended standards effective for the period are applied or their impact disclosed (IAS 8). — test_of_detail — [presentation]
8. Verify local statutory and regulatory disclosure requirements applicable to the entity are met (ISA 250). — test_of_detail — [presentation, completeness]
9. Read the complete set of financial statements for overall presentation, structure and consistency with the auditor's understanding (ISA 700.13–15; ISA 520 final analytical review). — other — [fs_level, presentation]
10. Read other information in the annual report for material inconsistencies with the FS (ISA 720). — other — [fs_level]
11. Document the conclusion on disclosures, linking any omissions/misstatements to the misstatement schedule (ISA 450). — other — [fs_level]

---

## 5. Trial Balance, Adjustments & Lead Schedules — ⏳ DRAFT

1. Agree the uploaded trial balance to the general ledger; confirm it balances and agree opening balances to prior-year audited FS (ISA 510). — test_of_detail — [completeness, accuracy]
2. Confirm every TB account is mapped to exactly one audit section or to "Out of Scope / Below Materiality"; investigate unmapped, new or unusual accounts (ISA 315, ISA 500). — test_of_detail — [completeness, classification]
3. Prepare/obtain a lead schedule per section showing accounts, current and prior-year balances, adjustments and final balance; agree to TB and FS caption (ISA 230). — test_of_detail — [accuracy, presentation]
4. Perform account analysis on movements: investigate significant variances between years and obtain and corroborate management explanations (ISA 520). — analytical — [accuracy, completeness]
5. Record all proposed adjustments in the working TB with reference, source section and supporting evidence (ISA 230). — other — [accuracy]
6. Classify adjustments as corrected / uncorrected / clearly trivial; evaluate uncorrected misstatements individually and in aggregate against materiality (ISA 450). — other — [fs_level]
7. Obtain management's approval of corrected adjustments and agree the adjusted TB to the final financial statements (ISA 450, ISA 700). — test_of_detail — [accuracy, presentation]
8. Re-agree the final TB if management issues a later TB version; document the version used (ISA 230). — other — [accuracy]
9. Cross-reference lead schedules to detailed working papers and findings (ISA 230). — other — [presentation]

---

## Perplexity prompt #1 — Completeness benchmark (paste prompt + sections 1–5)

> You are an audit methodology reviewer with deep knowledge of the International
> Standards on Auditing (ISA), IFRS / IFRS for SMEs, and the IFAC *Guide to Using
> ISAs in the Audits of Small- and Medium-Sized Entities*. Below are five draft
> audit-procedure templates for an audit workpaper platform used by small and
> mid-size audit firms in the GCC. They must satisfy a regulator's requirement that
> the firm's audit policy contains procedures, per international auditing
> standards, for: intangible assets and goodwill; investments (subsidiaries,
> associates, joint ventures, financial investments); other income; review of
> financial statement disclosures; and trial balance, adjustments, lead schedules
> and account analysis.
>
> For EACH section:
> 1. Identify any procedure required or strongly expected by ISA/IFRS that is
>    MISSING (cite the paragraph).
> 2. Flag any procedure that is incorrect, over-engineered for an SME, or
>    duplicative.
> 3. Check the assertion tags and procedure type on each line.
> 4. Return the full revised list in the same format
>    (`procedure — type — [assertions]`), keeping it proportionate (8–12 procedures),
>    and mark conditional procedures.
> Keep it jurisdiction-agnostic: no country-specific rates, thresholds or authority
> names.

## Perplexity prompt #2 — Arabic translation (run AFTER #1 is reconciled & locked)

> You are a bilingual (Arabic/English) audit professional familiar with official
> Arabic translations of the ISAs and IFRS and with how GCC audit firms (SOCPA,
> UAE, Oman, Qatar) write audit working papers. Translate the procedures below
> into formal professional Arabic using masdar style (e.g. «الحصول على…»،
> «التحقق من…»، «مطابقة…»), consistent with this terminology: trial balance =
> ميزان المراجعة; general ledger = دفتر الأستاذ العام; lead schedule = الجدول
> الرئيسي; impairment = الانخفاض في القيمة; expected credit loss = الخسائر
> الائتمانية المتوقعة; cash-generating unit = الوحدة المولِّدة للنقد; significant
> influence = التأثير الجوهري; related parties = الأطراف ذات العلاقة; materiality
> = الأهمية النسبية; cut-off = الفصل الزمني. Keep standard references (ISA, IAS,
> IFRS, IFRIC paragraph numbers) in Latin script. Also translate the five section
> titles. Return a table: # | English | Arabic. Flag any term where Gulf
> practice differs from a literal translation.

---

## Reconciliation log
(Claude fills after each Perplexity round.)
