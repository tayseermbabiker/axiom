// Audexon — Supabase connection config.
// One file, two environments. The right Supabase project is picked
// based on the browser's hostname so you cannot accidentally point
// staging code at the production database (or vice versa).
//
//   localhost / 127.0.0.1               → staging
//   staging--auditsaas.netlify.app      → staging   (Netlify branch deploy)
//   any hostname containing "staging"   → staging   (catch-all)
//   anything else (incl. auditsaas...)  → production
//
// Both keys below are publishable / anon — safe to ship in browser code.
// RLS on every table enforces actual access control.

const AUDEXON_ENV = (() => {
  const host = window.location.hostname.toLowerCase();
  if (host === 'localhost' || host === '127.0.0.1')     return 'staging';
  if (host.startsWith('staging--'))                     return 'staging';
  if (host.includes('staging'))                         return 'staging';
  return 'production';
})();

const AUDEXON_CONFIG = {
  production: {
    SUPABASE_URL: 'https://gimnahydujdlgnqwyadk.supabase.co',
    SUPABASE_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdpbW5haHlkdWpkbGducXd5YWRrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4ODc2NTEsImV4cCI6MjA4ODQ2MzY1MX0.H-_wjPWAbXLGnWyfU8GDMkbDaID8ocs7yr8ADQaMvHE',
  },
  staging: {
    SUPABASE_URL: 'https://lbwowlvajgpdxsdpudem.supabase.co',
    SUPABASE_KEY: 'sb_publishable_0crMhY3XjbgGA2p3ehMv-w_HaAy-Lqs',
  },
};

const SUPABASE_URL = AUDEXON_CONFIG[AUDEXON_ENV].SUPABASE_URL;
const SUPABASE_KEY = AUDEXON_CONFIG[AUDEXON_ENV].SUPABASE_KEY;

const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);

// Tiny visual cue in dev console so you can see which env is loaded
console.log('[Audexon] environment:', AUDEXON_ENV, '→', SUPABASE_URL);
