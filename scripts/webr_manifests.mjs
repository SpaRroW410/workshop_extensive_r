// Per-deck manifests for running workshop code in the browser with webR (CUSTOM_DECKS_PLAN.md §3.1).
//   node scripts/webr_manifests.mjs          write docs/<track>/<workshop>/<deck>.webr.json next to every rendered deck
//   node scripts/webr_manifests.mjs --check  exit 1 if a deck's visible chunks cannot be matched (used by tests)
//
// A manifest holds what the deck's hidden setup did when it was rendered: the workshop's assets/setup.R (inline),
// the data files it reads (fetched from the track's data/ folder), the packages it loads, and every R chunk in
// order. In Edit mode, slide-tools.js runs the setup, then the chunks before the one the reader runs, then theirs.
import { readFileSync, writeFileSync, readdirSync, existsSync } from 'node:fs';
import { join, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import { workshopDecks } from './slide_ids.mjs';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const BASE_PKGS = new Set('base compiler datasets graphics grDevices grid methods parallel splines stats stats4 tcltk tools utils'.split(' '));

/** R chunks of a .qmd, with their #| options. */
export function chunks(text) {
  const out = []; let cur = null;
  for (const ln of text.split('\n')) {
    if (!cur) {
      const m = ln.match(/^(`{3,})\{r([^}]*)\}\s*$/);
      if (m) cur = { fence: m[1], header: m[2], lines: [] };
      continue;
    }
    if (ln.startsWith(cur.fence) && ln.trim() === cur.fence) {
      const opts = {};
      for (const l of cur.lines) { const o = l.match(/^#\|\s*([\w.-]+):\s*(.*?)\s*$/); if (o) opts[o[1]] = o[2]; }
      for (const o of cur.header.split(',')) { const kv = o.match(/^\s*([\w.]+)\s*=\s*(\w+)/); if (kv) opts[kv[1].replace('.', '-')] = kv[2].toLowerCase(); }
      const code = cur.lines.filter((l) => !/^#\|/.test(l)).join('\n');
      const falsy = (v) => v !== undefined && /^(false|FALSE|F)$/.test(v);
      out.push({ code, visible: !falsy(opts.echo) && !falsy(opts.include), eval: !falsy(opts.eval), quiz: /quiz_(mcq|fill)\(/.test(code) });
      cur = null; continue;
    }
    cur.lines.push(ln);
  }
  return out;
}

export function packagesIn(code) {
  const s = new Set();
  for (const m of code.matchAll(/\b(?:library|require|requireNamespace)\(\s*["']?([A-Za-z][\w.]*)["']?/g)) s.add(m[1]);
  for (const m of code.matchAll(/\b([A-Za-z][\w.]*)::/g)) s.add(m[1]);
  return [...s].filter((p) => !BASE_PKGS.has(p)).sort();
}

const dataFilesIn = (code) => [...new Set([...code.matchAll(/["'](?:\.\.\/)*(data\/[\w./-]+\.(?:csv|xlsx|xls|geojson|gpkg|rds|json|txt))["']/g)].map((m) => m[1]))];

export function manifest(workshop, deck) {
  const text = readFileSync(join(ROOT, workshop, `${deck}.qmd`), 'utf8');
  const all = chunks(text).filter((c) => !c.quiz);
  const setupFile = join(ROOT, workshop, 'assets', 'setup.R');
  const setupR = existsSync(setupFile) ? readFileSync(setupFile, 'utf8') : '';
  const k = all.findIndex((c) => /source\(\s*["']assets\/setup\.R["']\s*\)/.test(c.code));
  const setupChunk = k >= 0 ? all.splice(k, 1)[0].code.split('\n').filter((l) => !/assets\/quiz\.R/.test(l)).join('\n') : '';
  const everything = [setupR, setupChunk, ...all.map((c) => c.code)].join('\n');
  return {
    version: 1, workshop, deck,
    packages: packagesIn(everything),
    files: setupR ? { 'assets/setup.R': setupR } : {},
    data: dataFilesIn(everything),                 // fetched from "../<path>" relative to the deck
    setup: setupChunk,
    chunks: all.map(({ code, visible, eval: ev }) => ({ code, visible, eval: ev })),
  };
}

const isMain = process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1];
if (isMain) {
  const docs = join(ROOT, 'docs'); let n = 0; const problems = [];
  for (const { workshop, deck } of workshopDecks()) {
    const m = manifest(workshop, deck);
    for (const p of readdirSync(docs)) {
      const html = join(docs, p, workshop, `${deck}.html`);
      if (!existsSync(html)) continue;
      const h = readFileSync(html, 'utf8');
      // One chunk = one <div class="cell">; knitr may split its code into several blocks inside it.
      const cells = h.split('<div class="cell"').slice(1).filter((seg) => seg.split('<div class="cell"')[0].slice(0, seg.search(/<\/section>/) > 0 ? seg.search(/<\/section>/) : undefined).includes('sourceCode cell-code')).length;
      const visible = m.chunks.filter((c) => c.visible).length;
      if (cells !== visible) problems.push(`${p}/${workshop}/${deck}: ${visible} visible chunks, ${cells} code cells in the HTML`);
      for (const d of m.data) if (!existsSync(join(docs, p, d))) problems.push(`${p}/${workshop}/${deck}: data file ${d} is not published in docs/${p}/`);
      if (process.argv[2] !== '--check') { writeFileSync(join(docs, p, workshop, `${deck}.webr.json`), JSON.stringify(m)); n++; }
    }
  }
  if (process.argv[2] !== '--check') console.log(`${n} webR manifests written`);
  if (problems.length) { console.error(problems.join('\n')); console.error(`${problems.length} problem(s)`); process.exit(1); }
  else console.log('All decks: visible chunks match the code cells; data files published');
}
