// Audexon — lightweight i18n loader (Phase 1).
//
// How it works:
//   - UI strings live in /i18n/en.json and /i18n/ar.json (same keys).
//   - Markup opts in with attributes:
//       data-i18n="key"              → sets textContent
//       data-i18n-html="key"         → sets innerHTML (use sparingly, trusted strings only)
//       data-i18n-placeholder="key"  → sets the placeholder attribute
//       data-i18n-title="key"        → sets the title attribute
//   - Active language is remembered in localStorage('audexon_lang'), default 'en'.
//   - Switching to Arabic sets <html lang="ar" dir="rtl"> so rtl.css takes over.
//
// IMPORTANT: this only swaps DISPLAY strings. It never touches audit data,
// trial-balance figures, or Supabase records — those stay language-neutral.

(function () {
  const STORAGE_KEY = 'audexon_lang';
  const DEFAULT_LANG = 'en';
  const SUPPORTED = ['en', 'ar'];

  // Resolve the /i18n/ folder relative to THIS script's location, so it works
  // from /pages/*.html (../js/i18n.js) and from root *.html (js/i18n.js) alike.
  const thisScript = document.currentScript;
  const base = thisScript
    ? thisScript.src.replace(/js\/i18n\.js.*$/, 'i18n/')
    : 'i18n/';

  const cache = {};   // lang -> dictionary
  let active = readLang();

  function readLang() {
    try {
      const v = localStorage.getItem(STORAGE_KEY);
      return SUPPORTED.includes(v) ? v : DEFAULT_LANG;
    } catch (_) {
      return DEFAULT_LANG;
    }
  }

  async function loadDict(lang) {
    if (cache[lang]) return cache[lang];
    try {
      const res = await fetch(base + lang + '.json', { cache: 'no-cache' });
      if (!res.ok) throw new Error('HTTP ' + res.status);
      cache[lang] = await res.json();
    } catch (err) {
      console.warn('[i18n] could not load', lang, err);
      cache[lang] = {};
    }
    return cache[lang];
  }

  function lookup(dict, key) {
    // supports dotted keys: "nav.dashboard"
    return key.split('.').reduce((o, k) => (o == null ? o : o[k]), dict);
  }

  function applyTo(root, dict) {
    const scope = root || document;

    scope.querySelectorAll('[data-i18n]').forEach((el) => {
      const val = lookup(dict, el.getAttribute('data-i18n'));
      if (typeof val === 'string') el.textContent = val;
    });
    scope.querySelectorAll('[data-i18n-html]').forEach((el) => {
      const val = lookup(dict, el.getAttribute('data-i18n-html'));
      if (typeof val === 'string') el.innerHTML = val;
    });
    scope.querySelectorAll('[data-i18n-placeholder]').forEach((el) => {
      const val = lookup(dict, el.getAttribute('data-i18n-placeholder'));
      if (typeof val === 'string') el.setAttribute('placeholder', val);
    });
    scope.querySelectorAll('[data-i18n-title]').forEach((el) => {
      const val = lookup(dict, el.getAttribute('data-i18n-title'));
      if (typeof val === 'string') el.setAttribute('title', val);
    });
  }

  function applyDir(lang) {
    const html = document.documentElement;
    html.setAttribute('lang', lang);
    html.setAttribute('dir', lang === 'ar' ? 'rtl' : 'ltr');
  }

  // Public API ------------------------------------------------------------
  async function setLang(lang) {
    if (!SUPPORTED.includes(lang)) lang = DEFAULT_LANG;
    active = lang;
    try { localStorage.setItem(STORAGE_KEY, lang); } catch (_) {}
    applyDir(lang);
    const dict = await loadDict(lang);
    applyTo(document, dict);
    // let pages react (e.g. re-render dynamic content) if they want
    document.dispatchEvent(new CustomEvent('i18n:changed', { detail: { lang } }));
  }

  function toggleLang() {
    return setLang(active === 'ar' ? 'en' : 'ar');
  }

  function t(key) {
    const val = lookup(cache[active] || {}, key);
    return typeof val === 'string' ? val : key;
  }

  function getLang() { return active; }

  // Translate a freshly-inserted DOM subtree (for dynamic content)
  async function translate(root) {
    const dict = await loadDict(active);
    applyTo(root, dict);
  }

  window.I18n = { setLang, toggleLang, t, getLang, translate };

  // Apply on first paint. dir is already set by the inline bootstrap in <head>;
  // here we load the dictionary and swap the strings.
  document.addEventListener('DOMContentLoaded', () => setLang(active));
})();
