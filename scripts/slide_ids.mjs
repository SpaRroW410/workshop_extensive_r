// Stable slide IDs for every workshop deck, and the slide catalogue (CUSTOM_DECKS_PLAN.md §3.2–3.3).
//
//   node scripts/slide_ids.mjs --add        one-off: write Quarto's current auto IDs into the .qmd as explicit {#id}
//   node scripts/slide_ids.mjs --update     after adding/removing slides: record new IDs, mark removed ones retired
//   node scripts/slide_ids.mjs --check      CI: every slide has an explicit, unique ID; no recorded ID vanished
//   node scripts/slide_ids.mjs --catalogue  write docs/slides.json (titles only) for the custom-deck builder
//
// Notes, saved code and custom decks refer to slides as "<workshop>/<deck>#<id>". An ID must never change or
// disappear silently: a removed slide stays in slides.lock.json as "retired" so saved decks can say so.
import { readFileSync, writeFileSync, readdirSync, existsSync, statSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { productFor } from '../cloud/src/products.js';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const LOCK = join(ROOT, 'slides.lock.json');

export function workshopDecks() {
  const out = [];
  for (const w of readdirSync(ROOT).filter((d) => d.endsWith('-workshop') && statSync(join(ROOT, d)).isDirectory()).sort()) {
    for (const f of readdirSync(join(ROOT, w)).filter((f) => /^s\d.*\.qmd$/.test(f)).sort()) out.push({ workshop: w, deck: f.replace(/\.qmd$/, '') });
  }
  return out;
}

/** Headings that make slides (# and ## at line start, outside code fences), with line numbers. */
export function slideHeadings(text) {
  const lines = text.split('\n');
  const out = []; let fence = null; let yaml = lines[0] === '---';
  lines.forEach((ln, i) => {
    if (yaml) { if (i > 0 && ln === '---') yaml = false; return; }
    const f = ln.match(/^(`{3,}|~{3,})/);
    if (f) { if (!fence) fence = f[1][0]; else if (ln.startsWith(fence)) fence = null; return; }
    if (fence) return;
    const m = ln.match(/^(#{1,2}) (.*?)\s*(\{[^}]*\})?\s*$/);
    if (!m) return;
    const attrs = m[3] || '';
    const id = (attrs.match(/(?:\{|\s)#([^\s}"]+)/) || [])[1] || null;
    out.push({ line: i, level: m[1].length, title: m[2].trim(), attrs, id });
  });
  return out;
}

const plainTitle = (t) => t.replace(/\*\*|__|`/g, '').replace(/\[([^\]]*)\]\([^)]*\)/g, '$1').trim();

function renderedIds(workshop, deck) {
  const docs = join(ROOT, 'docs');
  const profiles = readdirSync(docs).filter((p) => existsSync(join(docs, p, workshop, `${deck}.html`)));
  const p = profiles.find((x) => x !== 'dungeons') || profiles[0];
  if (!p) return null;
  const html = readFileSync(join(docs, p, workshop, `${deck}.html`), 'utf8');
  const all = [...html.matchAll(/<section id="([^"]+)" class="[^"]*\bslide\b[^"]*"/g)].map((m) => m[1]);
  // A chunk with `output-location: slide` adds "<id>-output" after its slide: part of that slide, not a heading.
  return all.filter((id, k) => !(k > 0 && id === `${all[k - 1]}-output`));
}

function primaryProfile(workshop, deck) {
  const docs = join(ROOT, 'docs');
  const profiles = readdirSync(docs).filter((p) => existsSync(join(docs, p, workshop, `${deck}.html`)));
  return profiles.find((x) => x !== 'dungeons') || profiles[0] || null;
}

function deckBody(text, headings, k) {
  const lines = text.split('\n');
  const end = k + 1 < headings.length ? headings[k + 1].line : lines.length;
  return lines.slice(headings[k].line + 1, end).join('\n');
}

const readLock = () => (existsSync(LOCK) ? JSON.parse(readFileSync(LOCK, 'utf8')) : {});
const writeLock = (lock) => writeFileSync(LOCK, JSON.stringify(lock, null, 1) + '\n');

function currentEntries(text) {
  return slideHeadings(text).map((h) => ({ id: h.id, title: plainTitle(h.title), level: h.level }));
}

const mode = process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1] ? process.argv[2] : null;


if (mode === '--add') {
  let added = 0;
  for (const { workshop, deck } of workshopDecks()) {
    const file = join(ROOT, workshop, `${deck}.qmd`);
    const text = readFileSync(file, 'utf8');
    const hs = slideHeadings(text);
    const ids = renderedIds(workshop, deck);
    if (!ids) { console.log(`skip ${workshop}/${deck}: not rendered`); continue; }
    if (ids.length !== hs.length) { console.error(`MISMATCH ${workshop}/${deck}: ${hs.length} headings, ${ids.length} rendered slides`); process.exitCode = 1; continue; }
    const lines = text.split('\n');
    hs.forEach((h, k) => {
      if (h.id) { if (h.id !== ids[k]) console.warn(`  ${workshop}/${deck}: heading has #${h.id}, rendered as #${ids[k]}`); return; }
      const hashes = '#'.repeat(h.level);
      const attrs = h.attrs ? `{#${ids[k]} ${h.attrs.slice(1)}` : `{#${ids[k]}}`;
      lines[h.line] = `${hashes} ${h.title} ${attrs}`;
      added++;
    });
    writeFileSync(file, lines.join('\n'));
  }
  console.log(`${added} IDs written`);
} else if (mode === '--update' || mode === '--check') {
  const lock = readLock(); const problems = []; let changed = false;
  for (const { workshop, deck } of workshopDecks()) {
    const key = `${workshop}/${deck}`;
    const cur = currentEntries(readFileSync(join(ROOT, workshop, `${deck}.qmd`), 'utf8'));
    const seen = new Set();
    for (const e of cur) {
      if (!e.id) problems.push(`${key}: slide "${e.title}" has no explicit {#id}`);
      else if (seen.has(e.id)) problems.push(`${key}: duplicate ID #${e.id}`);
      else if (!/^[A-Za-z][A-Za-z0-9_.-]*$/.test(e.id)) problems.push(`${key}: ID #${e.id} must be plain ASCII letters, digits, ., - or _`);
      seen.add(e.id);
    }
    const old = lock[key] || [];
    const oldIds = new Set(old.map((o) => o.id));
    for (const o of old) {
      if (!o.retired && !seen.has(o.id)) {
        if (mode === '--update') { o.retired = true; changed = true; }
        else problems.push(`${key}: #${o.id} ("${o.title}") was removed or renamed; restore it, or run --update to retire it`);
      }
    }
    for (const e of cur.filter((e) => e.id && !oldIds.has(e.id))) {
      if (mode === '--update') { old.push({ id: e.id, title: e.title }); changed = true; }
      else problems.push(`${key}: new slide #${e.id} not in slides.lock.json; run node scripts/slide_ids.mjs --update`);
    }
    if (mode === '--update') {
      for (const o of old) { const c = cur.find((e) => e.id === o.id); if (c && c.title !== o.title) { o.title = c.title; changed = true; } }
      lock[key] = old;
    }
  }
  if (mode === '--update') { writeLock(lock); console.log(changed ? 'slides.lock.json updated' : 'slides.lock.json already up to date'); }
  if (problems.length) { console.error(problems.join('\n')); console.error(`${problems.length} problem(s)`); process.exit(1); }
  if (mode === '--check') console.log(`All ${Object.values(lock).flat().filter((o) => !o.retired).length} workshop slides have stable IDs`);
} else if (mode === '--catalogue') {
  const decks = [];
  for (const { workshop, deck } of workshopDecks()) {
    const profile = primaryProfile(workshop, deck);
    if (!profile) continue;
    const text = readFileSync(join(ROOT, workshop, `${deck}.qmd`), 'utf8');
    const title = (text.match(/^title:\s*"?(.*?)"?\s*$/m) || [])[1] || deck;
    const hs = slideHeadings(text);
    const path = `/${profile}/${workshop}/${deck}.html`;
    decks.push({
      workshop, deck, title, profile, path, product: productFor(path),
      slides: hs.map((h, k) => {
        const body = deckBody(text, hs, k);
        return { id: h.id, title: plainTitle(h.title), level: h.level, ...(/output-location:\s*slide/.test(body) ? { output: `${h.id}-output` } : {}),
          code: /```\{r/.test(body) && !/quiz_(mcq|fill)\(/.test(body), quiz: /quiz_(mcq|fill)\(/.test(body) };
      }),
    });
  }
  writeFileSync(join(ROOT, 'docs', 'slides.json'), JSON.stringify({ built: new Date().toISOString().slice(0, 10), decks }));
  console.log(`docs/slides.json: ${decks.length} decks, ${decks.reduce((s, d) => s + d.slides.length, 0)} slides`);
} else if (mode !== null) {
  console.log('usage: node scripts/slide_ids.mjs --add | --update | --check | --catalogue');
  process.exit(2);
}
