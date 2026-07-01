# Audexon — Arabic Audit Terminology Glossary (Phase 3)

**Purpose:** Master EN→AR glossary for the audit report deliverable (`report.html`),
which is the wedge for GCC/KSA sales. Every term below appears in the generated
audit report (section headings + table-header labels), all ISA-referenced.

**Workflow:**
1. Validate the Arabic column in **Perplexity Pro** (prompt below).
2. Paste corrections back here, or just reply with the corrected table.
3. Claude locks the validated Arabic into `public/i18n/ar.json` and wires
   `report.html` with `data-i18n` keys — no guessing, no rework.

The Arabic below is a **professional DRAFT** (SOCPA/IFAC-style ISA terminology),
not final. Perplexity's job is to confirm or correct each term against how Gulf
audit firms actually write it.

---

## Perplexity Pro prompt (paste this + the tables)

> You are a bilingual (Arabic/English) audit terminology expert familiar with the
> International Standards on Auditing (ISA) and how GCC audit firms (KSA SOCPA,
> UAE, Oman, Qatar) phrase audit working papers and reports in Arabic. Below is a
> glossary of English audit terms with a proposed Arabic translation and the
> relevant ISA reference. For each row: confirm the Arabic is the standard term a
> professional Arabic-language audit file would use, or correct it. Prefer the
> terminology used in official Arabic ISA translations and SOCPA materials. Keep
> standard references (ISA 700, IFRS, IESBA) in Latin script. Return the full
> corrected table. Flag any term where Gulf practice differs from a literal
> translation.

---

## Conventions
- **Leave untranslated** (codes / symbols / refs): `#`, `%`, `=`, `Σ`, `C`, `D`, `I`,
  `ML`, `IPTE`, `Ack`, `At`, `By`, `Adj.`, all `ISA 2xx` / `IFRS` / `IESBA` refs.
- ISA references stay in Latin script inside the Arabic heading, e.g.
  «قبول العميل / الاستمرار (ISA 220)».
- Numbers, dates, currency, and percentages always render left-to-right.

---

## 1. Section headings

| ISA ref | English | Arabic (DRAFT) |
|---|---|---|
| ISA 220 | Client Acceptance / Continuance | قبول العميل / الاستمرار في التعامل |
| ISA 510 | Opening balances | الأرصدة الافتتاحية |
| — | AML / KYC — Client Due Diligence | مكافحة غسل الأموال / اعرف عميلك — العناية الواجبة بالعميل |
| — | Beneficial owners | المستفيدون الحقيقيون |
| ISA 210 | Engagement Letter | خطاب الارتباط |
| ISA 210.10 | ISA 210.10 minimum elements attested | الحد الأدنى من عناصر خطاب الارتباط المُقرّة |
| ISA 700 | Reporting considerations | اعتبارات إعداد التقرير |
| ISA 220 R + IESBA | Independence & Ethics | الاستقلال وقواعد السلوك المهني |
| IESBA | IESBA threats assessed | التهديدات المُقيّمة وفق قواعد IESBA |
| — | Non-audit services | الخدمات بخلاف المراجعة |
| ISA 300 + 315 | Audit Planning | تخطيط المراجعة |
| — | Team, specialists, EQR | الفريق والخبراء وفاحص جودة الارتباط |
| — | Budget by team member | الموازنة حسب عضو الفريق |
| ISA 315.14 | Risk assessment procedures performed | إجراءات تقييم المخاطر المُنفّذة |
| ISA 240.17 | Fraud team discussion | مناقشة فريق المراجعة بشأن الاحتيال |
| — | PBC — Prepared-By-Client requests | طلبات المستندات المُعدّة من قِبل العميل (PBC) |
| ISA 320 | Materiality | الأهمية النسبية |
| ISA 320.A1 | Qualitative considerations | الاعتبارات النوعية |
| ISA 320.10 | Specific materiality | الأهمية النسبية المحددة |
| ISA 320.12 | Planning vs revised materiality | الأهمية النسبية التخطيطية مقابل المُعدّلة |
| ISA 315 / 330 | Risk Assessment | تقييم المخاطر |
| — | Risk assessment attestations | إقرارات تقييم المخاطر |
| ISA 315 / 330 | Risk Assessment Recap | ملخص تقييم المخاطر |
| — | Summary of Findings | ملخص الملاحظات |
| ISA 450.11 | Aggregate evaluation vs materiality | التقييم الإجمالي مقابل الأهمية النسبية |
| ISA 540 | Significant Accounting Estimates | التقديرات المحاسبية المهمة |
| ISA 505 | External Confirmations | المصادقات الخارجية |
| ISA 530 | Audit Sampling Documentation | توثيق العيّنات في المراجعة |
| — | Work-done summary | ملخص العمل المُنجز |
| — | Section Workpapers | أوراق عمل القسم |
| — | Procedures & Work Performed | الإجراءات والعمل المُنفّذ |
| — | Documents Referenced | المستندات المرجعية |
| — | Finding Details | تفاصيل الملاحظة |
| — | Review Notes | ملاحظات الفحص |
| — | Management Letter Points | نقاط خطاب الإدارة |
| ISA 700 | Engagement Completion Memorandum | مذكرة إتمام الارتباط |
| ISA 570 | Going concern | الاستمرارية |
| ISA 560 | Subsequent events | الأحداث اللاحقة |
| ISA 520 | Final analytical review | الإجراءات التحليلية النهائية |
| ISA 450 | Uncorrected misstatements evaluation | تقييم التحريفات غير المُصحّحة |
| ISA 220 / IESBA | Final independence conclusion | الاستنتاج النهائي بشأن الاستقلال |
| ISA 580 | Management representation letter | خطاب إقرارات الإدارة |
| ISA 260 | Communication with TCWG | التواصل مع المكلفين بالحوكمة |
| — | Other matters | أمور أخرى |
| — | Partner attestations | إقرارات الشريك |
| — | Trial Balance Summary | ملخص ميزان المراجعة |
| ISA 450 | Adjusted Trial Balance | ميزان المراجعة المُعدّل |
| ISA 450 | Summary of Uncorrected Misstatements | ملخص التحريفات غير المُصحّحة |

---

## 2. Common labels (used across many sections)

| English | Arabic (DRAFT) |
|---|---|
| Status | الحالة |
| Date | التاريخ |
| Name | الاسم |
| Type | النوع |
| Conclusion | الاستنتاج |
| Rationale | المسوّغ / المبرر |
| Note | ملاحظة |
| Notes / Approach / notes | النهج / ملاحظات |
| Description | الوصف |
| Category | الفئة |
| Amount | المبلغ |
| Account | الحساب |
| Section | القسم |
| Area | المجال |
| Assertion | الإقرار (التوكيد) |
| Reviewer | الفاحص |
| Reviewer comments | ملاحظات الفاحص |
| Result / Results | النتيجة / النتائج |
| Method | الطريقة |
| Source | المصدر |
| Reason | السبب |
| Recommendation | التوصية |
| Procedure | الإجراء |
| Procedures done / performed | الإجراءات المُنفّذة |
| Risk | المخاطر |
| Risk tier | درجة المخاطر |
| Severity | الخطورة |
| Priority | الأولوية |
| Impact | الأثر |
| Grade | التقدير |
| Code | الرمز |
| Item | البند |
| Phase | المرحلة |
| Assessment | التقييم |
| Assessment date | تاريخ التقييم |
| Assessment status | حالة التقييم |
| Attestation | الإقرار |
| File Name | اسم الملف |
| File reference | مرجع الملف |
| Finding | الملاحظة |
| Finding Title | عنوان الملاحظة |
| Findings | الملاحظات |
| Work Performed | العمل المُنفّذ |

---

## 3. AML / KYC labels

| English | Arabic (DRAFT) |
|---|---|
| AML risk rating | تصنيف مخاطر غسل الأموال |
| CDD date | تاريخ العناية الواجبة |
| Engagement basis | أساس الارتباط |
| Client legal name | الاسم القانوني للعميل |
| Legal form / reg. no. | الشكل القانوني / رقم السجل |
| Country / activity | الدولة / النشاط |
| Trade licence — evidence | الرخصة التجارية — الدليل |
| Ownership structure understood | فهم هيكل الملكية |
| Screening performed | تنفيذ الفحص (التحري) |
| Screening result | نتيجة الفحص |
| PEP | شخص سياسي ممثّل للمخاطر (PEP) |
| PEP involved | وجود شخص سياسي ممثّل للمخاطر |
| Suspicious activity | نشاط مشبوه |
| Risk rationale | مسوّغ المخاطر |
| Nationality | الجنسية |

---

## 4. Acceptance / Engagement Letter / Independence labels

| English | Arabic (DRAFT) |
|---|---|
| Decision | القرار |
| Decision date | تاريخ القرار |
| Conditions | الشروط |
| Integrity conclusion | الاستنتاج بشأن النزاهة |
| Competence & resources | الكفاءة والموارد |
| Letter date | تاريخ الخطاب |
| Signed date | تاريخ التوقيع |
| Signed file | الملف الموقّع |
| Client signatory | المُوقّع عن العميل |
| Reporting framework | إطار إعداد التقارير |
| Audit period | فترة المراجعة |
| Anticipated report type | نوع التقرير المتوقع |
| Report delivery target | الموعد المستهدف لتسليم التقرير |
| Modification risk notes | ملاحظات مخاطر التعديل |
| Partner attestation | إقرار الشريك |
| Fee % of firm total | نسبة الأتعاب من إجمالي أتعاب المكتب |
| Fee dependence safeguards | ضمانات الاعتماد على الأتعاب |
| Prior-year fees | أتعاب السنة السابقة |
| Overdue-fee threat & safeguard | تهديد الأتعاب المتأخرة والضمان |
| Partner tenure (years) | مدة ارتباط الشريك (بالسنوات) |
| Rotation action | إجراء التدوير |
| Non-audit services | الخدمات بخلاف المراجعة |
| Threat | التهديد |
| Threat category | فئة التهديد |
| Safeguards | الضمانات |
| Prohibited? | محظور؟ |
| Service | الخدمة |

---

## 5. Planning / Materiality labels

| English | Arabic (DRAFT) |
|---|---|
| Team composition | تشكيل الفريق |
| Team member | عضو الفريق |
| Specialists | الخبراء |
| EQR required | فحص جودة الارتباط مطلوب |
| Budgeted hours | الساعات المُقدّرة |
| Hours | الساعات |
| Benchmark | المؤشر المرجعي |
| Benchmark amount | مبلغ المؤشر المرجعي |
| Reason for benchmark | سبب اختيار المؤشر المرجعي |
| Percentage applied | النسبة المطبّقة |
| Overall materiality | الأهمية النسبية الكلية |
| Performance materiality | الأهمية النسبية التنفيذية |
| Materiality (overall / performance) | الأهمية النسبية (الكلية / التنفيذية) |
| Clearly trivial threshold | حد التفاهة الواضحة |
| Reason for non-current period | سبب اعتماد فترة غير حالية |
| Discussion held | تمت المناقشة |
| Attendees | الحاضرون |
| Present? | حاضر؟ |

---

## 6. Risk / Findings / Misstatements labels

| English | Arabic (DRAFT) |
|---|---|
| Risk of material misstatement | مخاطر التحريف الجوهري |
| Significant risks | المخاطر المهمة |
| Total risks identified | إجمالي المخاطر المُحددة |
| Risks with linked procedures | المخاطر المرتبطة بإجراءات |
| Unlinked significant risks | المخاطر المهمة غير المرتبطة |
| Addresses risk | يعالج المخاطر |
| Linked procs | الإجراءات المرتبطة |
| Linked section | القسم المرتبط |
| Sig? | مهم؟ |
| Control | الرقابة |
| Reliance | الاعتماد |
| Classification | التصنيف |
| Class / account / disclosure | الفئة / الحساب / الإفصاح |
| Misstatement | التحريف |
| Projected misstatement | التحريف المُسقَط |
| Effect on profit | الأثر على الربح |
| Uncorrected misstatements (Σ) | التحريفات غير المُصحّحة (Σ) |
| Uncorrected vs materiality | التحريفات غير المُصحّحة مقابل الأهمية النسبية |
| Uncorrected as % of overall materiality | التحريفات غير المُصحّحة كنسبة من الأهمية النسبية الكلية |
| Management's rationale for not correcting | مسوّغ الإدارة لعدم التصحيح |
| Auditor's conclusion | استنتاج المراجع |
| Auditor's evaluation | تقييم المراجع |
| Opinion type | نوع الرأي |
| Opinion basis | أساس الرأي |
| Overall conclusion | الاستنتاج العام |

---

## 7. Estimates / Confirmations / Sampling labels (ISA 540 / 505 / 530)

| English | Arabic (DRAFT) |
|---|---|
| Method used (540.13(a)) | الطريقة المستخدمة (540.13(أ)) |
| Data sources (540.13(b)) | مصادر البيانات (540.13(ب)) |
| Key assumptions (540.13(c)) | الافتراضات الرئيسية (540.13(ج)) |
| Sensitivity analysis (540.15) | تحليل الحساسية (540.15) |
| D&I conclusion | الاستنتاج بشأن التطوير والتنفيذ |
| Counterparty | الطرف المقابل |
| Sent | أُرسلت |
| Received | وردت |
| Returned | أُعيدت |
| Obtained | تم الحصول عليها |
| Alternative procedures (505.12) | إجراءات بديلة (505.12) |
| Population | المجتمع |
| Sample / Population | العيّنة / المجتمع |
| Selection basis | أساس الاختيار |
| Rate | المعدل |

---

## 8. Completion / TCWG labels (ISA 260 / 560 / 570 / 580)

| English | Arabic (DRAFT) |
|---|---|
| Events identified | الأحداث المُحددة |
| Reviewed through date | تاريخ المراجعة حتى |
| Communicated | تم إبلاغه |
| Communication date | تاريخ الإبلاغ |
| Matters communicated | الأمور المُبلّغة |
| TCWG response | رد المكلفين بالحوكمة |
| Sections approved | الأقسام المعتمدة |
| File assembly (ISA 230) | تجميع الملف (ISA 230) |
| Adjusting Entry | قيد التسوية |
| Adjusting entries (posted / unposted) | قيود التسوية (مُرحّلة / غير مُرحّلة) |
| Posted? | مُرحّل؟ |
| Narration | البيان |
| Total Balance | إجمالي الرصيد |
| Audited | المُدقّق |
| Original | الأصلي |
| Change | التغير |
| Cost | التكلفة |
| Due | المستحق |
| Lines | البنود |

---

**Status:** DRAFT — awaiting Perplexity Pro validation. Once locked, Claude applies
to `ar.json` + wires `report.html` (and reuses the same keys for
`completion-memo.html`).
