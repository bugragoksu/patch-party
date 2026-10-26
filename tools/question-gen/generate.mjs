#!/usr/bin/env node
// FR-40: generates the shared-question pool with Gemini, offline, before the
// event. Output is reviewed by a human before it ships (docs/content/).
//   node tools/question-gen/generate.mjs [staging|prod]
// Reads GEMINI_API_KEY (and optional GEMINI_MODEL) from .env.<env>; the key
// is sent only in a request header and never printed.
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { loadEnv } from '../env.mjs';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const env = loadEnv(process.argv[2] ?? 'staging');
const key = env.GEMINI_API_KEY;
if (!key) throw new Error('GEMINI_API_KEY is empty in the env file');
const API = 'https://generativelanguage.googleapis.com/v1beta';

const catalog = JSON.parse(readFileSync(resolve(root, 'shared/catalog/interests.json'), 'utf8'));
const label = Object.fromEntries(catalog.interests.map((i) => [i.id, i.label]));
const ids = catalog.interests.map((i) => i.id).sort();

const pairs = [];
for (let i = 0; i < ids.length; i++) for (let j = i; j < ids.length; j++) pairs.push([ids[i], ids[j]]);

async function api(path, body, attempts = 4) {
  for (let attempt = 1; ; attempt++) {
    const res = await fetch(`${API}/${path}`, {
      method: body ? 'POST' : 'GET',
      headers: { 'content-type': 'application/json', 'x-goog-api-key': key },
      body: body ? JSON.stringify(body) : undefined,
    });
    if (res.ok) return res.json();
    const text = (await res.text()).slice(0, 300);
    // Busy models are retried with backoff; quota errors are final.
    if (res.status === 503 && attempt < attempts) {
      await new Promise((r) => setTimeout(r, 5000 * attempt));
      continue;
    }
    throw new Error(`${path}: HTTP ${res.status} ${text}`);
  }
}

/**
 * Picks the strongest stable text model this key can actually call: candidates
 * are ranked by version (pro before flash) and probed with a tiny request, so
 * models without free-tier quota are skipped.
 */
async function pickModel() {
  if (env.GEMINI_MODEL) return env.GEMINI_MODEL;
  const { models = [] } = await api('models?pageSize=200');
  const names = models
    .filter((m) => m.supportedGenerationMethods?.includes('generateContent'))
    .map((m) => m.name.replace('models/', ''));
  const score = (n) => {
    const m = /^gemini-(\d+(?:\.\d+)?)-(pro|flash)$/.exec(n);
    if (m) return Number(m[1]) * 10 + (m[2] === 'pro' ? 2 : 1);
    if (n === 'gemini-pro-latest') return 1000;
    if (n === 'gemini-flash-latest') return 999;
    return -1;
  };
  const candidates = names.filter((n) => score(n) >= 0).sort((a, b) => score(b) - score(a));
  for (const name of candidates) {
    try {
      await api(`models/${name}:generateContent`, { contents: [{ role: 'user', parts: [{ text: 'ok' }] }] }, 1);
      return name;
    } catch (error) {
      console.log(`skip ${name}: ${String(error.message).slice(0, 60)}`);
    }
  }
  throw new Error('no usable Gemini model for this key');
}

const organizer = env.APP_ORGANIZER_NAME ? ` (${env.APP_ORGANIZER_NAME})` : '';
const STYLE = `Sen bir teknoloji topluluğu etkinliği${organizer} için tanışma sorusu yazan bir editörsün.
Katılımcıların çoğu öğrenci ya da yeni başlayan; iş deneyimi varsayma.
Kurallar:
- Türkçe, samimi ama saygılı, "siz" değil "ikiniz/siz ikiniz" hitabı yok; soru iki kişiye birlikte sorulur ("...neydi?", "...ne yapardınız?").
- Her soru en fazla 110 karakter, tek cümle, sonunda soru işareti.
- Evet/hayır ile cevaplanmayan, kişisel bir deneyim ya da hikâye anlattıran sorular.
- Kişisel/hassas konular yok (din, siyaset, sağlık, maaş, ilişkiler, yaş). Alay ya da iğneleme yok.
- Klişe ve jenerik değil, ama giriş seviyesinde: PR, deploy, prod, ekip, müşteri, sprint gibi iş kavramları yok; hiç yapmamış biri de cevaplayabilmeli.
- Net Türkçe: çeviri kokan kalıp yok, cümle bağlamını kendi taşısın.
- Emoji yok.`;

async function generate(model, items, count) {
  const list = items
    .map(([a, b], n) =>
      a === b
        ? `${n + 1}. key="${a}|${b}": iki kişinin de ortak ilgi alanı "${label[a]}".`
        : `${n + 1}. key="${a}|${b}": biri "${label[a]}", diğeri "${label[b]}" ile ilgileniyor; sorular iki dünyayı buluştursun.`,
    )
    .join('\n');
  const body = {
    contents: [{ role: 'user', parts: [{ text: `${STYLE}\n\nHer key için ${count} farklı soru yaz:\n${list}` }] }],
    generationConfig: {
      temperature: 0.9,
      responseMimeType: 'application/json',
      responseSchema: {
        type: 'ARRAY',
        items: {
          type: 'OBJECT',
          properties: { key: { type: 'STRING' }, questions: { type: 'ARRAY', items: { type: 'STRING' } } },
          required: ['key', 'questions'],
        },
      },
    },
  };
  const out = await api(`models/${model}:generateContent`, body);
  const text = out.candidates?.[0]?.content?.parts?.map((p) => p.text).join('') ?? '[]';
  return JSON.parse(text);
}

async function generateGeneral(model, count) {
  const body = {
    contents: [{ role: 'user', parts: [{ text: `${STYLE}\n\nİlgi alanından bağımsız, bir teknoloji etkinliğinde herkese uyan ${count} farklı tanışma sorusu yaz.` }] }],
    generationConfig: {
      temperature: 0.9,
      responseMimeType: 'application/json',
      responseSchema: { type: 'ARRAY', items: { type: 'STRING' } },
    },
  };
  const out = await api(`models/${model}:generateContent`, body);
  return JSON.parse(out.candidates?.[0]?.content?.parts?.map((p) => p.text).join('') ?? '[]');
}

const clean = (q) => q.replace(/\s+/g, ' ').trim();
const valid = (q) => q.length >= 15 && q.length <= 130 && q.endsWith('?') && !/[\u{1F300}-\u{1FAFF}]/u.test(q);

const model = await pickModel();
console.log(`model: ${model}, pairs: ${pairs.length}`);
const pools = {};
for (let i = 0; i < pairs.length; i += 13) {
  const batch = pairs.slice(i, i + 13);
  const result = await generate(model, batch, 3);
  for (const { key: k, questions } of result) {
    if (!batch.some(([a, b]) => `${a}|${b}` === k)) continue;
    pools[k] = [...new Set(questions.map(clean).filter(valid))].slice(0, 3);
  }
  console.log(`batch ${i / 13 + 1}/${Math.ceil(pairs.length / 13)} done`);
}
pools.general = [...new Set((await generateGeneral(model, 35)).map(clean).filter(valid))].slice(0, 35);

const missing = pairs.map(([a, b]) => `${a}|${b}`).filter((k) => (pools[k]?.length ?? 0) < 2);
const total = Object.values(pools).reduce((n, l) => n + l.length, 0);
const payload = { version: 1, model, generatedAt: new Date().toISOString(), reviewed: false, pools };
writeFileSync(resolve(root, 'app/assets/content/questions.json'), `${JSON.stringify(payload, null, 2)}\n`);

mkdirSync(resolve(root, 'docs/content'), { recursive: true });
const md = [
  '# Soru Havuzu: Gözden Geçirme',
  '',
  `- Model: \`${model}\` · Üretim: ${payload.generatedAt} · Toplam ${total} soru`,
  `- Eksik (2'den az soru) ikililer: ${missing.length ? missing.join(', ') : 'yok'}`,
  '- Uygunsuz ya da zayıf bir soruyu `app/assets/content/questions.json` içinden silin; her ikilide en az 2 soru kalmalı.',
  '',
  ...Object.entries(pools).flatMap(([k, qs]) => [
    `## ${k === 'general' ? 'Genel' : k.split('|').map((x) => label[x]).join(' × ')}`,
    '',
    ...qs.map((q) => `- ${q}`),
    '',
  ]),
].join('\n');
writeFileSync(resolve(root, 'docs/content/questions-review.md'), md);
console.log(`wrote ${total} questions; missing pairs: ${missing.length}`);
