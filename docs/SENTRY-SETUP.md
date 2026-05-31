# Sentry — activation guide (parked 2026-05-23)

Sentry browser SDK is wired but **inactive** (no DSN set). Current
state is a safe no-op — `public/js/sentry-init.js` early-exits when
`window.SENTRY_DSN` is empty. The CDN bundle still loads on every
page (~80KB, cached after first hit) but does nothing.

Activate when you have time to monitor a dashboard — there's no point
collecting errors no one will look at.

---

## 5-minute activation

### 1. Create the Sentry project
- Go to https://sentry.io/signup → free tier covers 5,000 events/month
- Click **Create Project**
- Platform: **Browser JavaScript**
- Project name: `audexon`
- Alert frequency: weekly (you can change later)

### 2. Copy the DSN
On the project setup page, look for the install snippet. The DSN is
the URL on the `dsn:` line. Format:

```
https://<key>@<org-id>.ingest.<region>.sentry.io/<project-id>
```

DSNs are **safe to commit publicly** — they only allow writes, not
reads. You can paste it directly into the file.

### 3. Wire the DSN
Open `public/js/sentry-init.js`. Around line 21 you'll see:

```js
window.SENTRY_DSN = window.SENTRY_DSN || '';
```

Replace the empty string with your DSN:

```js
window.SENTRY_DSN = window.SENTRY_DSN || 'https://your-dsn-here@o1234567.ingest.us.sentry.io/4506789';
```

### 4. Commit + push
```
git add public/js/sentry-init.js
git commit -m "chore: activate Sentry with production DSN"
git push origin staging
```

Wait for Netlify to redeploy (~1 min). Open the staging URL in a
browser, trigger a deliberate error (e.g. open DevTools console and
run `throw new Error('sentry test')`), and check Sentry dashboard
within 30 seconds — the error should appear.

---

## What you get when active

- Every uncaught JS error captured with full stack trace
- Browser, OS, URL, breadcrumbs (recent clicks + navigation)
- Logged-in user email attached automatically (via the
  `audexon:user-loaded` event hook in `auth.js`)
- Environment auto-tagged: `local` / `staging` / `production`
- Localhost errors suppressed (dev noise filtered out)
- Common noise filtered: ResizeObserver, promise rejections,
  Chrome extension errors

## What you DON'T get (deliberate)

- Performance tracing — disabled (`tracesSampleRate: 0`), costs more
- Session replay — separate Sentry product, costs extra
- Source maps — would need a build step, not feasible without
  bundler migration

---

## Maintenance

- Free tier = 5k events/month. If you spike, Sentry pauses
  collection until next month — won't bill surprise you.
- Set up email alerts in Sentry: Settings → Alerts → "New issue"
  → Email me. Lets you fix bugs before users report them.
- Check the dashboard weekly. If nothing new appears, it's working
  silently. If something appears, investigate within a day.

## To revert / fully remove

If you decide Sentry isn't worth it:
1. Set `window.SENTRY_DSN = ''` (back to no-op)
2. Optionally remove the `<script>` tags from `public/pages/*.html`
3. Delete `public/js/sentry-init.js` if you want a clean removal
