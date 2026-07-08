import { writeFileSync } from 'node:fs';

const url = process.env.SUPABASE_URL || process.env.VITE_SUPABASE_URL;
const anonKey = process.env.SUPABASE_ANON_KEY || process.env.VITE_SUPABASE_ANON_KEY;

if (!url || !anonKey) {
  throw new Error('Missing SUPABASE_URL or SUPABASE_ANON_KEY.');
}

writeFileSync(
  'supabase-config.js',
  `window.SUPABASE_CONFIG = ${JSON.stringify({ url, anonKey }, null, 2)};\n`,
);
