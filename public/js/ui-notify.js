// Shared in-app notifications — replaces native alert()/confirm() so the app
// never shows the unprofessional "audexon.com says…" browser dialog.
//   showToast(message, type)   — non-blocking toast (type: info|success|error; auto-detected if omitted)
//   confirmDialog(msgOrOpts)   — styled confirm, returns Promise<boolean>
// Self-contained: injects its own CSS + DOM. Load before the page's inline script.
(function () {
  if (window.__uiNotifyLoaded) return;
  window.__uiNotifyLoaded = true;

  var css = ''
    + '.uin-toast-wrap{position:fixed;top:18px;left:50%;transform:translateX(-50%);z-index:100000;display:flex;flex-direction:column;gap:8px;align-items:center;pointer-events:none;max-width:92vw;}'
    + '.uin-toast{pointer-events:auto;min-width:240px;max-width:480px;padding:12px 16px;border-radius:10px;font-size:14px;line-height:1.45;color:#fff;box-shadow:0 8px 24px rgba(0,0,0,.18);display:flex;align-items:flex-start;gap:10px;opacity:0;transform:translateY(-8px);transition:opacity .18s ease,transform .18s ease;}'
    + '.uin-toast.show{opacity:1;transform:translateY(0);}'
    + '.uin-toast.info{background:#1f2937;}.uin-toast.success{background:#047857;}.uin-toast.error{background:#b91c1c;}'
    + '.uin-toast-ico{font-size:15px;line-height:1.4;}'
    + '.uin-toast-x{margin-left:auto;cursor:pointer;opacity:.8;font-size:16px;line-height:1;}'
    + '.uin-confirm-overlay{position:fixed;inset:0;background:rgba(15,23,42,.45);z-index:100001;display:none;align-items:center;justify-content:center;padding:20px;}'
    + '.uin-confirm-overlay.show{display:flex;}'
    + '.uin-confirm{background:#fff;border-radius:14px;max-width:440px;width:100%;box-shadow:0 20px 60px rgba(0,0,0,.28);overflow:hidden;}'
    + '.uin-confirm-body{padding:22px 22px 8px;}'
    + '.uin-confirm-title{font-size:16px;font-weight:700;color:#0f172a;margin:0 0 8px;}'
    + '.uin-confirm-msg{font-size:14px;color:#475569;line-height:1.55;margin:0;white-space:pre-line;}'
    + '.uin-confirm-foot{display:flex;justify-content:flex-end;gap:8px;padding:16px 22px 20px;}'
    + '.uin-btn{padding:8px 16px;border-radius:8px;font-size:14px;font-weight:600;cursor:pointer;border:1px solid transparent;}'
    + '.uin-btn-cancel{background:#fff;border-color:#e2e8f0;color:#334155;}'
    + '.uin-btn-ok{background:#2563eb;color:#fff;}.uin-btn-ok.danger{background:#dc2626;}';
  var style = document.createElement('style');
  style.textContent = css;
  (document.head || document.documentElement).appendChild(style);

  function toastWrap() {
    var w = document.getElementById('uin-toast-wrap');
    if (!w) { w = document.createElement('div'); w.id = 'uin-toast-wrap'; w.className = 'uin-toast-wrap'; (document.body || document.documentElement).appendChild(w); }
    return w;
  }

  function detectType(msg) {
    var m = String(msg == null ? '' : msg).toLowerCase();
    if (/error|failed|could not|cannot|can't|denied|invalid|not allowed|please |required|no permission|must /.test(m)) return 'error';
    if (/saved|success|added|created|updated|deleted|removed|sent|confirmed|posted|complete|done|approved/.test(m)) return 'success';
    return 'info';
  }

  window.showToast = function (message, type) {
    try {
      var wrap = toastWrap();
      var t = type || detectType(message);
      var el = document.createElement('div');
      el.className = 'uin-toast ' + t;
      var ico = document.createElement('span'); ico.className = 'uin-toast-ico';
      ico.textContent = t === 'error' ? '⚠' : (t === 'success' ? '✓' : 'ℹ');
      var txt = document.createElement('span'); txt.style.flex = '1';
      txt.textContent = String(message == null ? '' : message);
      var x = document.createElement('span'); x.className = 'uin-toast-x'; x.textContent = '×';
      el.appendChild(ico); el.appendChild(txt); el.appendChild(x);
      wrap.appendChild(el);
      requestAnimationFrame(function () { el.classList.add('show'); });
      var remove = function () { el.classList.remove('show'); setTimeout(function () { if (el.parentNode) el.parentNode.removeChild(el); }, 220); };
      x.addEventListener('click', remove);
      setTimeout(remove, t === 'error' ? 6000 : 3500);
    } catch (e) { /* a notifier must never throw */ }
  };

  var confirmEl = null, confirmResolve = null;
  function finishConfirm(val) {
    if (confirmEl) confirmEl.classList.remove('show');
    var r = confirmResolve; confirmResolve = null;
    if (r) r(val);
  }
  function buildConfirm() {
    var ov = document.createElement('div'); ov.className = 'uin-confirm-overlay'; ov.id = 'uin-confirm-overlay';
    ov.innerHTML = '<div class="uin-confirm" role="dialog" aria-modal="true">'
      + '<div class="uin-confirm-body"><h3 class="uin-confirm-title" id="uin-confirm-title"></h3><p class="uin-confirm-msg" id="uin-confirm-msg"></p></div>'
      + '<div class="uin-confirm-foot"><button type="button" class="uin-btn uin-btn-cancel" id="uin-confirm-cancel"></button><button type="button" class="uin-btn uin-btn-ok" id="uin-confirm-ok"></button></div></div>';
    (document.body || document.documentElement).appendChild(ov);
    ov.querySelector('#uin-confirm-cancel').addEventListener('click', function () { finishConfirm(false); });
    ov.querySelector('#uin-confirm-ok').addEventListener('click', function () { finishConfirm(true); });
    ov.addEventListener('click', function (e) { if (e.target === ov) finishConfirm(false); });
    return ov;
  }
  // confirmDialog('message')  OR  confirmDialog({ title, message, okLabel, cancelLabel, okClass })
  window.confirmDialog = function (opts) {
    if (typeof opts === 'string') opts = { message: opts };
    opts = opts || {};
    if (!confirmEl) confirmEl = buildConfirm();
    confirmEl.querySelector('#uin-confirm-title').textContent = opts.title || 'Please confirm';
    confirmEl.querySelector('#uin-confirm-msg').textContent = opts.message || '';
    confirmEl.querySelector('#uin-confirm-cancel').textContent = opts.cancelLabel || 'Cancel';
    var ok = confirmEl.querySelector('#uin-confirm-ok');
    ok.textContent = opts.okLabel || 'OK';
    var danger = opts.danger || (opts.okClass && /danger|delete|red|remove/i.test(opts.okClass)) || /delete|remove/i.test(opts.okLabel || '');
    ok.className = 'uin-btn uin-btn-ok' + (danger ? ' danger' : '');
    confirmEl.classList.add('show');
    return new Promise(function (res) { confirmResolve = res; });
  };
})();
