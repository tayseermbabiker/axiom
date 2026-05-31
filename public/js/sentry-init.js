// Audexon — Sentry browser error tracking
//
// Setup steps for the user (one-time, ~5 min):
//   1. Go to https://sentry.io and create a free account
//   2. Create a new project: Platform = "Browser JavaScript"
//   3. Copy the DSN (looks like https://<key>@<id>.ingest.sentry.io/<project>)
//   4. Set it as window.SENTRY_DSN in this file (line below) OR via a
//      Netlify env-var-injected script tag in the HTML head
//
// Until SENTRY_DSN is set, this script is a silent no-op — safe to
// deploy without breaking anything.
//
// What you get when DSN is set:
//   - Every uncaught JS error captured with full stack trace
//   - Browser, OS, URL, user email, breadcrumbs (recent clicks/loads)
//   - Free tier: 5,000 events/month, plenty for pre-launch
//   - Email alert when a new error type appears
//   - Source map upload (optional) for un-minified stack traces

(function () {
  // === CHANGE THIS LINE WHEN YOU HAVE A SENTRY DSN ===
  window.SENTRY_DSN = window.SENTRY_DSN || '';
  // ===================================================

  if (!window.SENTRY_DSN) return;

  // Wait for Sentry CDN to load
  function initSentry() {
    if (typeof window.Sentry === 'undefined') {
      console.warn('[Audexon] Sentry CDN not loaded — skipping init');
      return;
    }
    window.Sentry.init({
      dsn: window.SENTRY_DSN,
      // Stage tag — auto-detect from hostname
      environment:
        location.hostname.includes('staging') ? 'staging' :
        location.hostname.includes('localhost') ? 'local' :
        location.hostname.includes('netlify') ? 'staging' :
        'production',
      // Browser version + URL on every event — no extra config needed
      sendDefaultPii: false,
      // Capture useful breadcrumbs
      tracesSampleRate: 0.0, // off — performance tracing is a separate cost
      // Filter noise
      ignoreErrors: [
        'ResizeObserver loop limit exceeded',
        'Non-Error promise rejection captured',
        // Chrome extension noise
        /chrome-extension:/,
        /moz-extension:/,
      ],
      beforeSend(event) {
        // Don't send events on local dev
        if (location.hostname === 'localhost' || location.hostname.startsWith('127.')) {
          console.warn('[Audexon Sentry] suppressed (local):', event);
          return null;
        }
        return event;
      },
    });

    // Set user context once auth loads — Supabase exposes it via
    // supabaseClient.auth.getUser() but we need to wait for that to
    // happen. Hook into a global event the app already fires when
    // currentUser is set.
    document.addEventListener('audexon:user-loaded', (e) => {
      if (e.detail && e.detail.email) {
        window.Sentry.setUser({
          email: e.detail.email,
          id:    e.detail.id,
        });
      }
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initSentry);
  } else {
    initSentry();
  }
})();
