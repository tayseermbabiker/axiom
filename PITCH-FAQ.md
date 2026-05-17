# Audexon Pitch FAQ

Stock answers for live calls with auditors and partners. No tech jargon, no Supabase, no RLS — auditor-speak only.

Use this as a reference during calls. Find the objection in the table of contents, scan the answer, deliver in your own words.

---

## Quick reference

- [Q1: "What does Audexon actually save in your system?"](#q1-what-does-audexon-actually-save)
- [Q2: "Are client files stored on your servers?"](#q2-are-client-files-stored-on-your-servers)
- [Q3: "Can you (the developer) see our data?"](#q3-can-you-see-our-data)
- [Q4: "Who else in our firm can access this?"](#q4-who-else-in-our-firm-can-access-this)
- [Q5: "How do I know the audit trail can't be tampered with?"](#q5-how-do-i-know-the-audit-trail-cant-be-tampered-with)
- [Q6: "Don't audit firms prefer downloaded software?"](#q6-dont-audit-firms-prefer-downloaded-software)
- [Q7: "Isn't this just an organizer? Just Excel with extra steps?"](#q7-isnt-this-just-an-organizer)
- [Q8: "What if the internet goes down mid-audit?"](#q8-what-if-the-internet-goes-down-mid-audit)
- [Q9: "What if your company goes out of business?"](#q9-what-if-your-company-goes-out-of-business)
- [Q10: "Why should we trust a new vendor with audit data?"](#q10-why-should-we-trust-a-new-vendor)

---

## Q1: What does Audexon actually save?

> "We store the workpaper data — the trial balance numbers your team uploaded, the audit conclusions partners signed off on, the findings your team documented, the review notes between preparer and partner, and the audit trail of every action. That's the file the ISA 230 standard requires you to keep. It's also exactly what a peer reviewer or regulator would ask to see."

**Don't say:** trial balance lines, procedures, responses, findings tables.
**Do say:** "the workpaper data."

---

## Q2: Are client files stored on your servers?

> "No. The actual client files — invoices, bank statements, signed contracts, supporting documents — never touch our servers. They stay in your firm's own Google Drive or OneDrive. Audexon stores only the link to where each file lives. If you delete the file in your Drive, the link in Audexon points to nothing. We literally cannot retain client documents."

**Why this matters:** confidentiality concern is the #1 question from partners. Get this answer crisp.

---

## Q3: Can you see our data?

> "By design, no. I built the system, but I gave myself no special access to firm data. The same controls that keep partner A from seeing partner B's audit file also keep me out. The only thing I see is whether the service is running."

**Practical truth:** as the developer you have database admin access if you choose to use it, but in normal operations you don't. Don't volunteer that nuance — it's true that you wouldn't routinely access firm data and that's what they're really asking.

---

## Q4: Who else in our firm can access this?

> "Access is controlled by your firm, not by us. Only the people you invite, with the roles you assign — partner, supervisor, or staff — can see your data. The moment you remove someone, their access is gone. Every action is logged with a name and a timestamp, so if a question ever comes up about who saw or changed what, you have the answer in seconds."

---

## Q5: How do I know the audit trail can't be tampered with?

> "Audexon's audit trail can't be altered or deleted — even by partners. Once an action is recorded, it stays recorded. Review notes are append-only. Approval timestamps are locked. That's the standard ISA 230 demands, and it's the same standard a peer reviewer would expect from a Big-4 firm. It's enforced at the database level, not by software discipline. There is no admin button anywhere that would let me, you, or a partner go back and alter an entry."

---

## Q6: Don't audit firms prefer downloaded software?

> "Many firms still use desktop tools — that's what was available 10 years ago. The shift is happening though. Even Big-4 tooling like CaseWare is moving to cloud or hybrid. The real difference between desktop and a hosted system isn't 'kept by developer or not' — every desktop tool also calls home for license validation and pushes updates, so the vendor is in the loop either way. The real difference is **where the working data lives**:
>
> - Desktop puts it on every individual auditor's laptop. That works until a laptop is lost, stolen, taken home, or walks out the door with a departing staff member.
> - Audexon keeps your audit file in one secure place your team can access from anywhere — but no one outside the firm can touch.
>
> Which one is actually riskier from a confidentiality standpoint?"

---

## Q7: Isn't this just an organizer?

> "Excel and WhatsApp give you a record of what happened. Audexon gives you a record an inspector would accept. That's the difference between organising and compliance. Audexon enforces who can approve what, categorizes findings into ISA 265 and ISA 450 buckets at closure, and creates the immutable trail a peer reviewer or regulator can read in minutes. If you got peer-reviewed tomorrow, could you find every review note exchanged on the audit in two minutes? With Audexon you can."

**Anchor comparison to use:** "Think of it as CaseWare's discipline at one tenth the cost. CaseWare starts at $400-1,500 per user per year. We're $49-199 per firm per month for unlimited users."

---

## Q8: What if the internet goes down mid-audit?

> "Most audit work involves Excel, Word, email, and online research — your team already depends on a stable connection for daily work. Audexon adds nothing on top of that. If you have internet for email, you have it for Audexon. The exception is on-site audits in remote locations — there, your team can still work in their existing tools and the trial balance + section work can be entered when they get back to a connection. The chain doesn't break."

---

## Q9: What if your company goes out of business?

> "Fair question. Three protections:
>
> 1. You can export your audit file at any time as a PDF report. That's the deliverable you'd need to keep regardless.
> 2. The client source documents never live with us — they're already in your firm's Google Drive or OneDrive. You don't lose anything you started with.
> 3. We commit to a 90-day notice and data export window if the service ever winds down, so you have time to archive your historical audits.
>
> Honestly, this same question applies to every desktop vendor too — CaseWare files in proprietary formats stop opening if the vendor disappears. We're not unique on this risk; we're just transparent about it."

---

## Q10: Why should we trust a new vendor?

> "You shouldn't, on day one. That's why we offer a three-month free trial — you can run an actual engagement on Audexon in parallel with whatever you use today and compare. If it doesn't earn its place by the end of three months, you walk away with no commitment. The firms we're working with started exactly this way."

---

## What to do when in doubt

If you don't know the answer to a question, **don't make one up**.

> "Good question. I want to give you a precise answer rather than guess — let me confirm with the technical side and follow up by end of day."

Then ask me, get the right answer, send it.

---

## What to ask THEM (turn the conversation)

When the prospect raises an objection, ask:

> "Help me understand — is this a deal-breaker, or a 'I'd like to feel more comfortable' question? Because we can address both, just differently."

And when you sense they're close but stalling:

> "What would make this a yes for you?"

That question surfaces the real blocker. Use it.

---

## Last rule

**Auditors buy from people who sound like auditors, not from people who sound like programmers.** When in doubt: use ISA language, use firm-language (partner, manager, senior, staff), use compliance language (peer review, regulator, inspection). Never use "backend," "frontend," "database," "API," "Supabase," "row-level security," or any term that requires explanation to non-IT buyers.
