// Test harness: a local Cloudflare Pages server (wrangler pages dev) with its own empty D1 database.
import { spawn, spawnSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync, cpSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { tmpdir } from 'node:os';
import { createServer } from 'node:net';
import { fileURLToPath } from 'node:url';
import { routesJson } from '../src/products.js';
import { hidePaidFiles } from '../src/layout.js';

/** The hidden folder name in tests (real deploys use a random one per deploy). */
export const TEST_ROOT = '0123456789abcdef0123456789abcdef';

const CLOUD = join(dirname(fileURLToPath(import.meta.url)), '..');
const WRANGLER = join(CLOUD, 'node_modules', '.bin', 'wrangler');
const ENV = { ...process.env, CI: '1', WRANGLER_SEND_METRICS: 'false', NO_COLOR: '1' };

/** A small site laid out like docs/: free and paid pages, plus _routes.json from products.js. */
export function fixtureSite() {
  const dir = mkdtempSync(join(tmpdir(), 'site-'));
  const page = (title) => `<!doctype html><html><head><title>${title}</title></head><body><h1>${title}</h1></body></html>`;
  const files = {
    'index.html': page('Landing'),
    'basic/welcome.html': page('Basic home'),
    'regression/index.html': page('Regression index'),
    'regression/welcome.html': page('Regression home'),
    'regression/site_libs/x.css': 'body{}',
    'regression/search.json': '[{"text":"paid text"}]',
    'regression/regression-workshop/s1_foundations.html': page('Session 1 free'),
    'regression/regression-workshop/s2_simple_regression.html': page('Session 2 paid'),
    'regression/regression-workshop/labs/lab2_simple.R': 'paid lab',
    'advanced/survival-workshop/s2_kaplan_meier.html': page('A1 session 2 paid'),
    'dungeons/dungeons/index.html': page('Quest map'),
    'dungeons/dungeons/b1_first_script.html': page('Region 1 free'),
    'dungeons/dungeons/m1_messy_data_dungeon.html': page('Region 2 paid'),
    'gis/gis/make_gis_data.R': 'free via function',
  };
  for (const [rel, body] of Object.entries(files)) {
    mkdirSync(dirname(join(dir, rel)), { recursive: true });
    writeFileSync(join(dir, rel), body);
  }
  cpSync(join(CLOUD, 'static'), dir, { recursive: true });
  hidePaidFiles(dir, join(CLOUD, 'src', 'generated'), TEST_ROOT);
  writeFileSync(join(dir, '_routes.json'), JSON.stringify(routesJson()));
  return dir;
}

function freePort() {
  return new Promise((resolve) => {
    const s = createServer();
    s.listen(0, '127.0.0.1', () => { const { port } = s.address(); s.close(() => resolve(port)); });
  });
}

/**
 * Start a local site. `vars` become Worker variables (BASE_URL is filled in automatically).
 * Returns { base, sql(statement), stop() }.
 */
export async function startSite({ siteDir = fixtureSite(), vars = {} } = {}) {
  const persist = mkdtempSync(join(tmpdir(), 'd1-'));
  const mig = spawnSync(WRANGLER, ['d1', 'migrations', 'apply', 'medstats', '--local', '--persist-to', persist],
    { cwd: CLOUD, env: ENV, encoding: 'utf8' });
  if (mig.status !== 0) throw new Error('migrations failed:\n' + mig.stdout + mig.stderr);

  const port = await freePort();
  const base = `http://127.0.0.1:${port}`;
  const all = {
    BASE_URL: base,
    BETTER_AUTH_SECRET: 'test-secret-test-secret-test-secret-0123456789',
    AUTH_TEST_MODE: '1',
    GOOGLE_CLIENT_ID: 'test-client-id.apps.googleusercontent.com',
    GOOGLE_CLIENT_SECRET: 'test-client-secret',
    ...vars,
  };
  const args = ['pages', 'dev', siteDir, '--port', String(port), '--ip', '127.0.0.1', '--persist-to', persist,
    '--inspector-port', String(await freePort()), '--show-interactive-dev-session=false'];
  for (const [k, v] of Object.entries(all)) args.push('--binding', `${k}=${v}`);
  const proc = spawn(WRANGLER, args, { cwd: CLOUD, env: ENV, stdio: ['ignore', 'pipe', 'pipe'] });
  let log = '';
  proc.stdout.on('data', (d) => { log += d; });
  proc.stderr.on('data', (d) => { log += d; });

  const deadline = Date.now() + 60000;
  for (;;) {
    if (proc.exitCode !== null) throw new Error('wrangler exited:\n' + log);
    try { await fetch(base + '/'); break; } catch { /* not up yet */ }
    if (Date.now() > deadline) { proc.kill(); throw new Error('wrangler did not start:\n' + log); }
    await new Promise((r) => setTimeout(r, 300));
  }

  return {
    base,
    persist,
    log: () => log,
    sql(statement) {
      const r = spawnSync(WRANGLER, ['d1', 'execute', 'medstats', '--local', '--persist-to', persist, '--json', '--command', statement],
        { cwd: CLOUD, env: ENV, encoding: 'utf8' });
      if (r.status !== 0) throw new Error('sql failed:\n' + r.stdout + r.stderr);
      return JSON.parse(r.stdout)[0].results;
    },
    async stop() {
      proc.kill('SIGTERM');
      await new Promise((r) => (proc.exitCode !== null ? r() : proc.once('exit', r)));
      rmSync(persist, { recursive: true, force: true });
      if (siteDir.startsWith(tmpdir())) rmSync(siteDir, { recursive: true, force: true });
    },
  };
}

/** Sign up and sign in with the test-only email login. Returns the Cookie header value. */
export async function testSignIn(base, email = 'learner@example.test', name = 'Test Learner') {
  const r = await fetch(base + '/api/auth/sign-up/email', {
    method: 'POST',
    headers: { 'content-type': 'application/json', origin: base },
    body: JSON.stringify({ email, password: 'correct-horse-battery', name }),
  });
  if (!r.ok) throw new Error(`test sign-up failed: ${r.status} ${await r.text()}`);
  return cookieFrom(r);
}

export function cookieFrom(res) {
  return res.headers.getSetCookie().map((c) => c.split(';')[0]).join('; ');
}
