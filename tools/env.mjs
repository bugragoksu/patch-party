#!/usr/bin/env node
// Single configuration source (architecture §13).
//   node tools/env.mjs app <staging|prod>    writes app/.env.app.<env> with APP_* keys only
//   node tools/env.mjs check <staging|prod>  lists required keys that are still empty
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');

const REQUIRED = {
  staging: ['APP_ENV', 'APP_EVENT_ID', 'FIREBASE_PROJECT_ID', 'APP_FIREBASE_API_KEY', 'APP_FIREBASE_APP_ID',
    'APP_FIREBASE_PROJECT_ID', 'APP_FIREBASE_AUTH_DOMAIN', 'APP_FIREBASE_MESSAGING_SENDER_ID'],
  prod: ['APP_ENV', 'APP_EVENT_ID', 'FIREBASE_PROJECT_ID', 'APP_FIREBASE_API_KEY', 'APP_FIREBASE_APP_ID',
    'APP_FIREBASE_PROJECT_ID', 'APP_FIREBASE_AUTH_DOMAIN', 'APP_FIREBASE_MESSAGING_SENDER_ID', 'APP_SENTRY_DSN',
    'ADMIN_EMAILS', 'PROJECTOR_EMAILS', 'ALERT_EMAILS', 'EVENT_DISPLAY_NAME'],
};

export function loadEnv(envName) {
  const file = resolve(root, `.env.${envName}`);
  if (!existsSync(file)) throw new Error(`.env.${envName} not found: copy .env.example first`);
  const values = {};
  for (const line of readFileSync(file, 'utf8').split('\n')) {
    const m = /^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/.exec(line);
    if (!m) continue;
    let v = m[2];
    if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) v = v.slice(1, -1);
    values[m[1]] = v;
  }
  return values;
}

function main() {
  const [command, envName] = process.argv.slice(2);
  if (!['app', 'check'].includes(command) || !['staging', 'prod'].includes(envName)) {
    console.error('usage: node tools/env.mjs <app|check> <staging|prod>');
    process.exit(2);
  }
  const env = loadEnv(envName);
  if (command === 'check') {
    const missing = REQUIRED[envName].filter((k) => !env[k]);
    if (missing.length) {
      console.error(`missing in .env.${envName}:\n  ${missing.join('\n  ')}`);
      process.exit(1);
    }
    console.log(`.env.${envName}: all required keys set`);
    return;
  }
  const lines = Object.entries(env)
    .filter(([k]) => k.startsWith('APP_'))
    .map(([k, v]) => `${k}=${v}`);
  const out = resolve(root, `app/.env.app.${envName}`);
  writeFileSync(out, `${lines.join('\n')}\n`);
  console.log(`wrote ${lines.length} APP_ keys to app/.env.app.${envName}`);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) main();
