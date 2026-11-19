// Where paid files sit in the uploaded folder.
//
// Why: Cloudflare decides whether to run the gate by matching the RAW request path against
// _routes.json, but its static file server DECODES the path ("%2F" -> "/", "%72" -> "r") and
// resolves "..". So "/%72egression/..." or "/basic%2F..%2Fregression/..." skips the gate and the
// static server still finds the paid file. Seen with wrangler pages dev, 2026-11-19 (NIGHT_NOTES.md).
//
// So paid files are not uploaded at their public paths at all. stage.mjs moves each one to
// /_p/<root>/<public path>, where <root> is 128 random bits chosen afresh for every deploy and baked
// into that deploy's Function bundle (src/generated/paid-root.js). The gate, after checking the user,
// fetches the file from there. A request that bypasses the gate finds nothing at the public path.
import { readdirSync, statSync, mkdirSync, renameSync, writeFileSync } from 'node:fs';
import { join, relative, dirname } from 'node:path';
import { randomBytes } from 'node:crypto';
import { productFor } from './products.js';

export const HIDDEN = '/_p/';

/** The URL a file is served at (Pages drops ".html" and serves "x/index.html" at "x/"). */
export function canonicalUrl(rel) {
  const p = '/' + rel;
  if (p.endsWith('/index.html')) return p.slice(0, -'index.html'.length);
  if (p.endsWith('.html')) return p.slice(0, -'.html'.length);
  return p;
}

/** A file stays at its public path when either the file path or the URL it is served at is free. */
export function isPublicFile(rel) {
  return productFor('/' + rel) === null || productFor(canonicalUrl(rel)) === null;
}

function walk(dir, out = []) {
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);
    if (statSync(p).isDirectory()) walk(p, out); else out.push(p);
  }
  return out;
}

/**
 * Move every paid file in `out` under /_p/<root>/ and write src/generated/paid-root.js.
 * Returns { root, moved }.
 */
export function hidePaidFiles(out, generatedDir, fixedRoot) {
  // fixedRoot is for the tests only: real deploys always get a fresh random folder name.
  const root = fixedRoot || randomBytes(16).toString('hex');
  let moved = 0;
  for (const abs of walk(out)) {
    const rel = relative(out, abs).split('\\').join('/');
    if (rel.startsWith('_p/') || rel === '_routes.json') continue;
    if (isPublicFile(rel)) continue;
    const to = join(out, '_p', root, rel);
    mkdirSync(dirname(to), { recursive: true });
    renameSync(abs, to);
    moved++;
  }
  mkdirSync(generatedDir, { recursive: true });
  writeFileSync(join(generatedDir, 'paid-root.js'),
    '// Written by stage.mjs for one deploy. Not a setting: do not edit or commit.\n' +
    `export const PAID_ROOT = '${root}';\n`);
  return { root, moved };
}
