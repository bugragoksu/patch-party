#!/usr/bin/env node
// Fills %SITE_URL% in app/build/web/index.html (link preview tags) with
// SITE_URL from .env.<env>, e.g. https://party.example.com. Run after
// `flutter build web`. Without SITE_URL the tags become root-relative,
// which some preview crawlers ignore.
//   node tools/web-meta.mjs <staging|prod>
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { loadEnv } from './env.mjs';

const envName = process.argv[2];
if (!['staging', 'prod'].includes(envName)) {
  console.error('usage: node tools/web-meta.mjs <staging|prod>');
  process.exit(2);
}
const site = (loadEnv(envName).SITE_URL || '').replace(/\/+$/, '');
const file = resolve(dirname(fileURLToPath(import.meta.url)), '../app/build/web/index.html');
const html = readFileSync(file, 'utf8');
writeFileSync(file, html.replaceAll('%SITE_URL%', site));
console.log(`link previews point at ${site || '(relative paths)'}`);
