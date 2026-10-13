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
| # | Section | EN | AR | Seeding |
|---|---|---|---|---|
| 1 | Intangible Assets & Goodwill | ✅ | ⬜ | template only (dropdown) |
| 2 | Investments | ✅ | ⬜ | template only (dropdown) |
| 3 | Other Income | ✅ | ⬜ | template only (dropdown) |
| 4 | Financial Statement Disclosures | ✅ | ⬜ | auto-seeded on every new engagement |
| 5 | Trial Balance, Adjustments & Lead Schedules | ✅ | ⬜ | auto-seeded on every new engagement |

Rationale for seeding split: 4 and 5 apply to every audit; 1–3 only when the client
has those balances, so auto-seeding would clutter simple SME files.

Also fix in the same batch: Related Parties AR procedure 1 — «مملوكة بصرف خاص» →
«مملوكة ملكية خاصة» (translation glitch).

Format per line: `procedure — type — [assertions]`
Types (platform): test_of_detail · analytical · controls · other.
Assertions: existence, completeness, accuracy, valuation, cutoff, occurrence,
rights_obligations, classification, presentation, fs_level.

---

## Reconciliation log — Round 1 (Perplexity completeness benchmark, 2026-10-13)

**Adopted (substantive corrections):**
- All sections: add genuine *completeness* searches (schedule-to-GL agreement alone does not prove completeness — ISA 330 A45); ISA 510 only for initial audits.
- Full IFRS vs IFRS for SMEs branches where the accounting differs (SMEs amortise goodwill, expense internal R&D, Section 24 grants, Sections 11–15 investments).
- Intangibles: annual impairment test also covers intangibles *not yet available for use*; "no indicators" cannot replace the mandatory annual test; goodwill formula includes NCI + previously held interest; business combination vs asset acquisition; no reversal of goodwill impairment; revaluation model conditional.
- Investments: joint operation vs joint venture; equity-method detail (basis differences, distributions reduce the investment, unrealised profits, loss limits, long-term interests); SPPI only for debt; equity FVOCI election — no recycling, no ECL; impairment branched by measurement basis; ISA 600 cross-reference.
- Other Income: grant recognition = reasonable assurance (IAS 20) / performance-condition model (SMEs); write-backs need a legal/accounting basis, not age; contingent assets only when virtually certain; income-specific fraud assessment.
- Disclosures: confirm framework/edition first; non-GL disclosures need their own evidence; cash-flow statement tested against cash records (not just balance-sheet differences); ISA 720 covers inconsistency with audit knowledge too; issued-but-not-effective vs effective standards.
- TB/Lead: **examine material closing/top-side journals (ISA 330.20(b))**; "exactly one section" → one *primary* mapping + secondary links; out-of-scope justified on aggregation + qualitative factors; ISA 450 categories corrected (correction status vs clearly trivial), request correction, governance communication, written representation; later-TB-version re-testing.

**Rejected / adapted:**
- "`other` is an invalid type" — Perplexity assumed a 3-type taxonomy. The platform has 4 types incl. `other`; kept `other` for documentation/evaluation steps (this matches Perplexity's own point that they aren't substantive tests).
- Length: Perplexity's lines run 60–100 words with long paragraph lists. Condensed to the library's house style (1–3 lines, key paragraph refs only). Substance kept.
- Final analytical review in Disclosures: already in the Completion Memo (ISA 520) → worded as "perform, or cross-reference to the Completion Memo" to avoid duplicate work.
- IFRS 18 (effective 2027): referenced only where classification depends on it ("where adopted"); no IFRS 18-specific procedure yet.

---

## 1. Intangible Assets & Goodwill — ✅ EN LOCKED

1. Obtain the movement schedule for intangible assets and goodwill (opening, additions, disposals, amortisation, impairment, closing); test its accuracy, recompute, and reconcile to the GL/TB and prior-year closing balances; for an initial audit, perform opening-balance procedures (ISA 500, ISA 330.20, ISA 510). — test_of_detail — [completeness, accuracy]
2. Completeness: inspect acquisition agreements, project records, board minutes and selected expense accounts for unrecorded intangibles, expenditure wrongly capitalised, or assets requiring derecognition (ISA 330; IAS 38.18–23, .68–71). — test_of_detail — [completeness, classification, valuation]
3. (Conditional — additions) Vouch selected additions to contracts, invoices and implementation evidence; verify identifiability, control, probable future benefits, directly attributable cost and recognition date; exclude service arrangements that do not create a controlled asset (IAS 38.12–23, .27–32). — test_of_detail — [existence, rights_obligations, accuracy, valuation, cutoff]
4. (Conditional — internally generated) Full IFRS: research expensed; development capitalised only from the date all IAS 38.57 criteria are met; internally generated brands, customer lists and goodwill not capitalised. IFRS for SMEs: all internally generated intangible expenditure, including R&D, expensed (Section 18). — test_of_detail — [valuation, classification, accuracy, cutoff]
5. Inspect registrations, licences and contracts for continuing rights, renewal terms, expiry dates, restrictions and pledges; assess the effect on carrying amounts and useful lives (IAS 38). — test_of_detail — [rights_obligations, existence, valuation]
6. Evaluate useful lives, residual values, amortisation methods and available-for-use dates; recompute amortisation for a sample. Full IFRS: confirm goodwill and indefinite-life intangibles are not amortised and the indefinite-life assessment is reviewed annually. IFRS for SMEs: confirm intangibles and goodwill are amortised (IAS 38.88–109; IFRS for SMEs 18.19–24, 19.23). — test_of_detail — [valuation, accuracy, classification]
7. (Conditional — new goodwill) Assess whether the acquisition is a business combination or an asset acquisition; test acquisition-date fair values of identifiable net assets, consideration, non-controlling interest and any previously held interest; recompute goodwill (or bargain-purchase gain); under full IFRS, test allocation to cash-generating units (IFRS 3; IAS 36.80–87; IFRS for SMEs Section 19). — test_of_detail — [valuation, accuracy, classification]
8. Impairment: assess indicators for all intangibles. Under full IFRS, test the annual impairment test for goodwill, indefinite-life intangibles and intangibles not yet available for use, regardless of indicators. Evaluate method, key assumptions and data (forecasts, discount rate, growth rate, CGU composition) for management bias; recompute; perform sensitivity analysis where estimation uncertainty is high; verify any reversal is permitted and that goodwill impairment is not reversed (IAS 36.9–10, .90, .104–125; ISA 540; IFRS for SMEs Section 27). — test_of_detail — [valuation, accuracy]
9. (Conditional — disposals, abandonment or revaluation) Test derecognition date, removal of cost and accumulated amortisation, proceeds and gain/loss; if the revaluation model is used (full IFRS), verify an active market, class-wide application and surplus treatment (IAS 38.72–87, .112–117). — test_of_detail — [existence, occurrence, valuation, accuracy, cutoff]
10. Analytical: develop an expectation of the amortisation charge from cost and useful lives; investigate significant differences (ISA 520). — analytical — [accuracy, valuation]
11. Test disclosures against evidence: reconciliation by class, lives and methods, indefinite-life assets and reasons, restrictions and pledges, commitments, R&D expense, business-combination information, goodwill by CGU, and key impairment assumptions and sensitivities (IAS 38.118–128; IAS 36.126–137; IFRS 3.59–63; IFRS for SMEs 18.27–29, 19.25–26). — test_of_detail — [completeness, accuracy, presentation, classification]

---

## 2. Investments — ✅ EN LOCKED
(Subsidiaries, associates, joint arrangements, financial investments)

1. Obtain the investment movement schedule by investee/instrument (acquisitions, disposals, distributions, share of results/OCI, fair-value movements, impairment, FX); recompute and reconcile to the GL/TB and prior-year closing balances; inspect minutes, agreements and external records for unrecorded holdings (ISA 500, ISA 330.20; initial audit: ISA 510). — test_of_detail — [completeness, accuracy]
2. Verify existence and ownership of selected holdings: custodian/broker/registrar confirmations (ISA 505 — auditor-controlled, with follow-up of exceptions and non-responses), share certificates, investee registry records and purchase agreements. — test_of_detail — [existence, rights_obligations]
3. Assess control, significant influence and joint control from substantive rights and actual arrangements, not ownership percentage alone; classify as subsidiary (IFRS 10), associate (IAS 28), joint venture or joint operation (IFRS 11), or financial asset (IFRS 9); assess any claimed consolidation exemption and document the judgement. — test_of_detail — [classification, rights_obligations, completeness]
4. (Conditional — separate financial statements) Verify the measurement basis elected for subsidiaries, associates and joint ventures (cost / IFRS 9 / equity method) is permitted and applied consistently by category (IAS 27.10; IFRS for SMEs Section 9). — test_of_detail — [classification, valuation, accuracy]
5. (Conditional — equity method) Test initial cost and acquisition-date basis differences; assess the reliability of investee financial information; recompute the share of results and OCI, distributions (which reduce the investment), policy and reporting-date adjustments, unrealised-profit eliminations and loss-recognition limits including long-term interests (IAS 28.10, .14A, .26–39; IFRS for SMEs Sections 14–15). — test_of_detail — [valuation, accuracy, completeness]
6. (Conditional — financial investments) Debt instruments: test the business model and SPPI to confirm the category (amortised cost / FVOCI / FVTPL) and recompute effective interest. Equity instruments: confirm FVTPL, or for an irrevocable FVOCI election verify eligibility (not held for trading) and that gains are not recycled to profit or loss. Verify initial fair value and transaction-cost treatment (IFRS 9.4.1, .5.1.1, .5.7.5; IFRS for SMEs Sections 11–12). — test_of_detail — [classification, valuation, accuracy]
7. (Conditional — fair value) Agree quoted prices to independent sources, or evaluate the valuation technique, significant inputs and model calculations; assess estimation uncertainty and management bias; consider using an expert where needed (IFRS 13; ISA 540; ISA 620). — test_of_detail — [valuation, accuracy]
8. (Conditional — impairment) Debt at amortised cost/FVOCI: test the expected-credit-loss allowance (staging, forward-looking information) — not applicable to equity instruments. Cost-basis investments: assess IAS 36 indicators and test the recoverable amount where required. Equity-accounted investments: test impairment of the net investment (IFRS 9.5.5; IAS 36; IAS 28.40–43; ISA 540). — test_of_detail — [valuation, accuracy]
9. (Conditional — acquisitions, disposals, ownership changes) Vouch to agreements and bank; test recognition/derecognition dates, transaction costs, gain or loss and retained-interest measurement; distinguish changes without loss of control from loss of control or significant influence (IFRS 9.3.2; IFRS 10.23, .25, B96–B99; IAS 28.22–25). — test_of_detail — [occurrence, accuracy, valuation, cutoff, classification]
10. Test investment income: dividends to declarations, entitlement dates and bank; interest recomputed at contractual/effective rates; search for unrecorded accrued income; verify that dividends from equity-accounted investees reduce the investment rather than being recognised as income (IFRS 9.5.7.1A; IAS 27.12; IAS 28.10). — test_of_detail — [occurrence, completeness, accuracy, cutoff, classification]
11. (Conditional — group FS or joint operations) Group FS: cross-reference the ISA 600 group-audit work and test consolidation completeness, elimination of intra-group balances, transactions and unrealised profits, non-controlling interests and translation adjustments. Joint operations: test recognition of the entity's share of assets, liabilities, revenue and expenses (ISA 600 (Revised); IFRS 10.B86; IFRS 11.20–23; IAS 21). — test_of_detail — [fs_level, completeness, accuracy, classification]
12. Test current/non-current classification and disclosures against evidence: restrictions, pledges, commitments, related-party investees, interests in other entities, fair-value hierarchy, credit risk and ECL, and separate-FS disclosures (IAS 1; IAS 27.16–17; IFRS 12; IFRS 7; IFRS 13.93–99; IAS 24; IFRS for SMEs Sections 9, 11–15). — test_of_detail — [rights_obligations, completeness, accuracy, presentation, classification]

---

## 3. Other Income — ✅ EN LOCKED

1. Obtain an analysis of other income by nature and source (interest, dividends, rental, disposal gains, FX gains, grants, insurance claims, write-backs); recompute and agree to the GL/TB; identify material, unusual and related-party items (ISA 500). — test_of_detail — [completeness, accuracy]
2. Completeness: from deposits, investment holdings, leases, disposal records, grant and claim correspondence and post-year-end receipts, identify income entitlements not recorded and trace them to income, accruals or deferred income (ISA 330). — test_of_detail — [completeness, cutoff]
3. (Conditional — predictable streams) Develop an expectation for each stream from verified drivers (rates × balances, lease terms); investigate significant differences; do not rely on an aggregate prior-year comparison for one-off income (ISA 520). — analytical — [occurrence, completeness, accuracy]
4. Vouch selected material and risk-based items to agreements, declarations and settlement evidence; verify entitlement and that recognition criteria are met, not merely receipt of cash (ISA 500; IFRS 9, IFRS 15, IFRS 16 as applicable). — test_of_detail — [occurrence, accuracy, classification]
5. (Conditional — interest, dividends, rentals, disposals, FX) Recompute amounts and recognition periods, cross-referencing work already performed in the Investments, PPE and Cash sections and performing only incremental work (IFRS 9.5.4.1, .5.7.1A; IFRS 16.81; IAS 16.68–71; IAS 21). — test_of_detail — [accuracy, cutoff, classification]
6. (Conditional — government grants) Full IFRS: verify reasonable assurance of compliance with conditions and of receipt, systematic recognition, asset- vs income-related presentation and any repayment obligation (IAS 20). IFRS for SMEs: recognise when performance conditions are met; amounts received earlier are a liability (Section 24). — test_of_detail — [occurrence, accuracy, cutoff, classification, presentation]
7. (Conditional — insurance claims, reimbursements, write-backs) Verify evidence of entitlement and the recognition threshold (contingent assets only when virtually certain); verify the legal or accounting basis for derecognising payables or reversing provisions — age alone is not sufficient (IAS 37.31–35, .53, .59; IAS 16.65; IFRS 9.3.3.1). — test_of_detail — [occurrence, accuracy, classification]
8. Test cut-off of material items around year-end for correct accrual, deferral and period (ISA 500). — test_of_detail — [cutoff, completeness, occurrence]
9. Fraud risk: assess susceptibility by income stream; inspect unusual or manual credits, round sums, year-end entries and related-party items for business rationale and management bias; cross-reference Journal Entry Testing (ISA 240.26, .32). — test_of_detail — [occurrence, accuracy, cutoff, classification]
10. Test classification (other income vs revenue vs finance income vs OCI; IFRS 18 categories where adopted), prohibited offsetting, and disclosure of material items by nature, grants and related parties (IAS 1.32, .97; IAS 20.39; IAS 24.18). — test_of_detail — [completeness, accuracy, classification, presentation]

---

## 4. Financial Statement Disclosures — ✅ EN LOCKED

1. Confirm the applicable financial reporting framework and edition (full IFRS or IFRS for SMEs), the standards effective for the period and any early adoption; verify the basis-of-preparation note describes it accurately (ISA 700.15; IAS 1.16; IFRS for SMEs 3.3). — test_of_detail — [fs_level, presentation]
2. Agree primary-statement and note amounts derived from the ledger to the final adjusted TB and lead schedules; check casts and cross-references, and that the final version is used throughout (ISA 330.20(a)). — test_of_detail — [accuracy, completeness, presentation]
3. For disclosures not derived from the GL (commitments, contingencies, maturity analyses, sensitivities, narrative), test completeness and accuracy against contracts, minutes, legal letters, models and other audit evidence (ISA 330; ISA 500). — test_of_detail — [completeness, accuracy, presentation]
4. Complete the disclosure checklist for the applicable framework, linking each material requirement to the note and evidence; distinguish "not applicable" from "omitted as immaterial"; consider additional disclosures needed for fair presentation (ISA 700.13–14; IAS 1.31; IFRS for SMEs 3.2). — other — [completeness, presentation]
5. Test the statement of cash flows against cash records and supporting reconciliations: classification of operating, investing and financing flows, cash-equivalent composition, FX effects, exclusion of non-cash transactions, and the reconciliation of liabilities arising from financing activities (IAS 7; IFRS for SMEs Section 7). — test_of_detail — [completeness, accuracy, classification, presentation]
6. Verify that material accounting-policy information reflects the policies actually applied, and that significant judgements and sources of estimation uncertainty are disclosed consistently with the audit work (IAS 1.117–133; IAS 8; ISA 540.31, .36). — test_of_detail — [completeness, accuracy, presentation]
7. Verify that comparatives agree to the prior-year audited FS; test any restatement, reclassification or change in accounting policy and the required disclosures (ISA 710; IAS 1.38–44; IAS 8.42–49). — test_of_detail — [accuracy, completeness, classification, presentation]
8. Verify cross-cutting disclosures against completed audit work — related parties (IAS 24), contingencies and commitments (IAS 37), subsequent events (IAS 10), going concern and any material uncertainty (ISA 570), financial risk management (IFRS 7), capital management (IAS 1); resolve missing underlying evidence rather than only ticking the checklist (ISA 550; ISA 560). — test_of_detail — [completeness, accuracy, presentation]
9. (Conditional — new or amended standards, framework transition) Verify application and transition disclosures for standards effective in the period; separately check disclosure of standards issued but not yet effective (IAS 8.28, .30–31; IFRS 1 for first-time adoption). — test_of_detail — [accuracy, completeness, presentation]
10. (Conditional — statutory/regulatory disclosures or other information) Test any additional local statutory or regulatory disclosure requirements (ISA 250). Read the other information in the annual report for material inconsistencies with the FS and with knowledge obtained in the audit, and for apparent material misstatement (ISA 720.14–20). — other — [fs_level, completeness, presentation]
11. Perform, or cross-reference to the Completion Memo, the final analytical review using the final FS; investigate unexplained relationships and reassess risks where needed (ISA 520.6). — analytical — [fs_level]
12. Read the complete final FS for overall presentation, appropriate aggregation and terminology; accumulate disclosure misstatements in the misstatement schedule, evaluate their effect on the opinion and document the conclusion (ISA 330.24; ISA 700.13–15; ISA 450). — other — [fs_level, presentation]

---

## 5. Trial Balance, Adjustments & Lead Schedules — ✅ EN LOCKED

1. Obtain the year-end TB and GL; verify entity, period and currency; confirm the import is complete and accurate (control totals, debits equal credits) and investigate missing, duplicate or inconsistent accounts (ISA 500.9; ISA 330.20(a)). — test_of_detail — [completeness, accuracy]
2. Reconcile opening balances to the prior-year audited closing balances and explain differences, including prior-period corrections and reclassifications; for an initial audit, perform opening-balance procedures (ISA 510; ISA 710). — test_of_detail — [accuracy, completeness, classification]
3. Verify every TB account has one primary mapping to an FS caption and audit section (with secondary links where relevant); investigate unmapped, new and unusual accounts; justify accounts placed in "Out of Scope / Below Materiality" on aggregation and qualitative factors, not individual size alone (ISA 330.18; ISA 450.11). — test_of_detail — [completeness, classification]
4. Prepare or obtain a lead schedule for each section showing constituent accounts, current and prior-year balances, booked adjustments, uncorrected proposals and final balances; recompute and agree to the TB version and FS caption without double-counting adjustments (ISA 330.20(a); ISA 230). — test_of_detail — [accuracy, completeness, classification, presentation]
5. Analyse account movements using disaggregated data; corroborate management's explanations for significant variances and route any new risks to the relevant sections (ISA 315.14; ISA 520). — analytical — [fs_level, accuracy, completeness]
6. Examine material journal entries and other adjustments made in preparing the FS, including post-closing, consolidation and top-side entries outside the GL: inspect support, recompute, and test period and classification; cross-reference Journal Entry Testing (ISA 330.20(b); ISA 240.32(a)). — test_of_detail — [occurrence, accuracy, completeness, cutoff, classification]
7. Maintain the misstatement schedule in the working TB with reference, source section, affected accounts/disclosures and evidence; accumulate all misstatements other than clearly trivial ones, identifying factual, judgemental and projected misstatements (ISA 450.5, A2–A6). — other — [fs_level, accuracy, completeness]
8. Communicate accumulated misstatements to management and request correction; document the reasons for any refusal; for accepted corrections, verify they are posted in the books and reflected in the final FS (ISA 450.7–9). — test_of_detail — [accuracy, completeness, classification]
9. Reassess materiality against actual results; evaluate uncorrected misstatements (amounts and disclosures) individually and in aggregate, including qualitative factors and prior-period effects; communicate to those charged with governance and obtain the written representation (ISA 450.10–14; ISA 260; ISA 580). — other — [fs_level]
10. Agree the final adjusted TB and lead schedules to the final FS. (Conditional — later TB version) compare it with the version tested, test new or changed entries and update the affected procedures; retain the version supporting the signed report (ISA 330.20; ISA 230; ISA 700). — test_of_detail — [accuracy, completeness, classification, presentation]
11. Cross-reference each lead schedule to working papers, adjustments, findings and conclusions; confirm preparer and reviewer sign-off and that significant matters are resolved (ISA 230.8–9). — other — [fs_level]

---

## Perplexity prompt #2 — Arabic translation
See `specs/fsa-perplexity-prompt-2-arabic.txt` (prompt + all 56 locked procedures, ready to paste).
