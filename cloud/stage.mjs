#!/usr/bin/env node
// Prepare the folder that is uploaded to Cloudflare Pages.
//
//   node stage.mjs           copy ../docs to .deploy/, add _routes.json and the gate's pages, run the checks
//   node stage.mjs --check   run the checks on ../docs only (used by CI; copies nothing)
//   --docs <dir>             check another folder instead of ../docs (used by the tests)
//
// docs/ itself is never changed: GitHub Pages keeps serving it exactly as today until you switch over.
import { cpSync, rmSync, readdirSync, statSync, writeFileSync, readFileSync, existsSync, mkdirSync } from 'node:fs';
import { join, relative, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';
import { routesJson } from './src/products.js';
import { hidePaidFiles } from './src/layout.js';

const HERE = dirname(fileURLToPath(import.meta.url));
const argDocs = process.argv.indexOf('--docs');
const DOCS = argDocs > 0 ? process.argv[argDocs + 1] : join(HERE, '..', 'docs');
const OUT = join(HERE, '.deploy');
const STATIC = join(HERE, 'static');

// Cloudflare Pages free plan (checked 2026-11-15, LAUNCH_PLAN.md §2)
const MAX_FILES = 20000;
const MAX_FILE_BYTES = 25 * 1024 * 1024;

// Files that must never be published: facilitator solutions (plan §8.4).
const FORBIDDEN = [
  /(^|\/)solutions\//i,
  /_solution\.[A-Za-z]+$/i,
  /(^|\/)run_solutions\.R$/i,
  /(^|\/)\.deploy\//, // a staging copy rendered into docs/ by mistake
  /(^|\/)\.dev\.vars$/,
];
// Files that are build leftovers and are not copied.
const SKIP = [/(^|\/)\.render-stamp$/];

function walk(dir, out = []) {
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);
    if (statSync(p).isDirectory()) walk(p, out); else out.push(p);
  }
  return out;
}

function check(root) {
  const problems = [];
  const files = walk(root).map((p) => [p, relative(root, p).split('\\').join('/')]);
  if (files.length > MAX_FILES) problems.push(`${files.length} files; Cloudflare Pages allows ${MAX_FILES}`);
  for (const [abs, rel] of files) {
    if (FORBIDDEN.some((re) => re.test(rel))) problems.push(`facilitator material would be published: ${rel}`);
    const size = statSync(abs).size;
    if (size > MAX_FILE_BYTES) problems.push(`${rel} is ${(size / 1048576).toFixed(1)} MiB; the limit is 25 MiB`);
  }
  return { problems, count: files.length };
}

const checkOnly = process.argv.includes('--check');

if (checkOnly) {
  const { problems, count } = check(DOCS);
  if (problems.length) { console.error(problems.join('\n')); process.exit(1); }
  console.log(`docs/: ${count} files, no facilitator material, no file above 25 MiB`);
  process.exit(0);
}

if (!existsSync(join(DOCS, 'index.html'))) {
  console.error('docs/index.html not found: render the site first (bash render-all-profiles.sh).');
  process.exit(1);
}

rmSync(OUT, { recursive: true, force: true });
cpSync(DOCS, OUT, {
  recursive: true,
  filter: (src) => !SKIP.some((re) => re.test(relative(DOCS, src).split('\\').join('/'))),
});

// Pages that belong to the cloud side (sign-in, locked page) and are not rendered by Quarto.
if (existsSync(STATIC)) cpSync(STATIC, OUT, { recursive: true });

// Workshop keys: on Cloudflare the gate decides who sees a paid page, so the plain-text keys in
// config.json are not published there (plan §5). docs/config.json keeps them for GitHub Pages.
for (const file of walk(OUT).filter((p) => p.endsWith('/config.json'))) {
  let cfg;
  try { cfg = JSON.parse(readFileSync(file, 'utf8')); } catch { continue; }
  if (!cfg.profiles) continue;
  for (const p of Object.values(cfg.profiles)) delete p.key;
  cfg.gate = 'server';
  writeFileSync(file, JSON.stringify(cfg, null, 2) + '\n');
}

// Progress sync for signed-in learners: one script on every page (only on Cloudflare).
let injected = 0;
for (const file of walk(OUT).filter((p) => p.endsWith('.html'))) {
  const html = readFileSync(file, 'utf8');
  const at = html.lastIndexOf('</body>');
  if (at < 0 || html.includes('/ws-sync.js')) continue;
  writeFileSync(file, html.slice(0, at) + '<script src="/ws-sync.js" defer></script>\n' + html.slice(at));
  injected++;
}

// The slide tools (Edit mode, notes, own slides) for the custom-deck builder and player: /st/.
// The decks embed their own copy; the master is regression-workshop/assets/.
mkdirSync(join(OUT, 'st'), { recursive: true });
for (const f of ['slide-tools.js', 'slide-tools.css']) cpSync(join(HERE, '..', 'regression-workshop', 'assets', f), join(OUT, 'st', f));

// webR (R in the browser, for Edit mode in the decks) served from our own domain: /webr/.
// Pinned to the version slide-tools.js asks for; downloaded once into .cache/ (not committed: ~45 MB).
// The decks fall back to webR's own server when /webr/ is absent (GitHub Pages, files opened offline).
const WEBR_VERSION = '0.6.1';
const webrSkipped = await stageWebR(join(OUT, 'webr'));

// Paid files leave their public paths (see src/layout.js for why).
const { moved } = hidePaidFiles(OUT, join(HERE, 'src', 'generated'));

writeFileSync(join(OUT, '_routes.json'), JSON.stringify(routesJson(), null, 2) + '\n');

const { problems, count } = check(OUT);
if (problems.length) {
  console.error('Not staged — fix these first:\n' + problems.join('\n'));
  rmSync(OUT, { recursive: true, force: true });
  process.exit(1);
}
mkdirSync(OUT, { recursive: true });
if (webrSkipped) console.warn(`webR not staged (${webrSkipped}); decks will load it from webr.r-wasm.org`);
console.log(`Staged ${count} files in cloud/.deploy (${moved} paid files hidden, sync script on ${injected} pages, _routes.json written)`);

async function stageWebR(dest) {
  // The browser build is the GitHub release archive (the npm package is webR's Node.js build).
  const cache = join(HERE, '.cache', `webr-${WEBR_VERSION}`);
  const dist = join(cache, `webr-${WEBR_VERSION}`);
  if (!existsSync(join(dist, 'R.wasm'))) {
    try {
      mkdirSync(cache, { recursive: true });
      const r = await fetch(`https://github.com/r-wasm/webr/releases/download/v${WEBR_VERSION}/webr-${WEBR_VERSION}.tar.gz`);
      if (!r.ok) return `download failed: ${r.status}`;
      const tgz = join(cache, 'webr.tgz');
      writeFileSync(tgz, Buffer.from(await r.arrayBuffer()));
      execFileSync('tar', ['-xzf', tgz, '-C', cache]);
    } catch (e) { return e.message; }
  }
  const keep = (src) => {
    const rel = relative(dist, src).split('\\').join('/');
    return !/^(assets|tests)(\/|$)|^repl\.|^index\.html$|\.map$/.test(rel);
  };
  cpSync(dist, dest, { recursive: true, filter: keep });
  return null;
}
