// Phase 2: the gate on paid paths (LAUNCH_PLAN.md §5 and §9).
// Proof asked by the plan: "signed-out request to a paid URL is refused; free pages work with Functions disabled".
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { startSite, testSignIn, TEST_ROOT } from './helpers.js';

let site;
before(async () => { site = await startSite(); });
after(async () => { await site?.stop(); });

const HTML = { accept: 'text/html,application/xhtml+xml' };
const get = (path, headers = {}) => fetch(site.base + path, { headers, redirect: 'manual' });

async function userWith(email, products) {
  const cookie = await testSignIn(site.base, email, email.split('@')[0]);
  const me = await (await fetch(site.base + '/api/me', { headers: { cookie } })).json();
  for (const [p, expires] of products) {
    site.sql(`insert into entitlement values ('${me.user.id}', '${p}', ${expires ?? 'null'}, 'manual', ${Date.now()})`);
  }
  return cookie;
}

test('signed out: a paid page sends the browser to the account page', async () => {
  const r = await get('/regression/regression-workshop/s2_simple_regression', HTML);
  assert.equal(r.status, 302);
  const to = new URL(r.headers.get('location'), site.base);
  assert.equal(to.pathname, '/account');
  assert.equal(to.searchParams.get('need'), 'regression');
  assert.equal(to.searchParams.get('next'), '/regression/regression-workshop/s2_simple_regression');
  assert.equal((await get(to.pathname + to.search, HTML)).status, 200, 'the account page itself is served');
});

test('signed out: paid files, search index and the .html form are refused too', async () => {
  for (const p of ['/regression/regression-workshop/labs/lab2_simple.R', '/regression/search.json',
                   '/regression/regression-workshop/s2_simple_regression.html', '/dungeons/dungeons/m1_messy_data_dungeon',
                   '/advanced/survival-workshop/s2_kaplan_meier.html']) {
    const r = await get(p);
    assert.equal(r.status, 401, p);
    assert.doesNotMatch(await r.text(), /paid|Session 2|Region 2/, p);
  }
});

test('free pages are served without running the Function', async () => {
  for (const p of ['/', '/basic/welcome', '/regression/', '/regression/welcome',
                   '/regression/regression-workshop/s1_foundations', '/regression/site_libs/x.css',
                   '/dungeons/dungeons/', '/dungeons/dungeons/b1_first_script']) {
    const r = await get(p, HTML);
    assert.equal(r.status, 200, p);
    // The middleware tags everything it touches with x-gate; excluded paths never reach it.
    assert.equal(r.headers.get('x-gate'), null, `${p} went through the Function`);
  }
  // Free, but over Cloudflare's rule limit: served through the Function.
  const r = await get('/gis/gis/make_gis_data.R');
  assert.equal(r.status, 200);
  assert.equal(r.headers.get('x-gate'), 'free');
});

test('a user who holds the product gets the page, not cached by shared caches', async () => {
  const cookie = await userWith('reg@example.test', [['regression']]);
  const r = await get('/regression/regression-workshop/s2_simple_regression', { ...HTML, cookie });
  assert.equal(r.status, 200);
  assert.match(await r.text(), /Session 2 paid/);
  assert.equal(r.headers.get('x-gate'), 'pass');
  assert.equal(r.headers.get('cache-control'), 'private, no-store');
  // ...but not another product
  const g = await get('/dungeons/dungeons/m1_messy_data_dungeon', { ...HTML, cookie });
  assert.equal(g.status, 302);
  assert.equal(new URL(g.headers.get('location'), site.base).searchParams.get('need'), 'game-full');
  assert.equal((await get('/advanced/survival-workshop/s2_kaplan_meier.html', { cookie })).status, 403);
});

test('all-access opens everything; an expired grant opens nothing', async () => {
  const all = await userWith('all@example.test', [['all-access']]);
  for (const p of ['/regression/regression-workshop/s2_simple_regression', '/dungeons/dungeons/m1_messy_data_dungeon',
                   '/advanced/survival-workshop/s2_kaplan_meier']) {
    assert.equal((await get(p, { ...HTML, cookie: all })).status, 200, p);
  }
  const old = await userWith('old@example.test', [['regression', Date.now() - 60000]]);
  assert.equal((await get('/regression/regression-workshop/s2_simple_regression', { ...HTML, cookie: old })).status, 302);
});

test('tricks with the path do not get past the gate', async () => {
  // Each of these served the paid Session 2 before paid files were moved out of their public paths:
  // Cloudflare matches _routes.json on the raw path, its static server decodes it.
  for (const p of ['/regression/regression-workshop/s1_foundations/../s2_simple_regression',
                   '/regression/regression-workshop/s1_foundations%2F..%2Fs2_simple_regression',
                   '/regression/site_libs/..%2Fregression-workshop%2Fs2_simple_regression',
                   '/regression/site_libs%2F..%2Fregression-workshop%2Fs2_simple_regression',
                   '/basic%2F..%2Fregression%2Fregression-workshop%2Fs2_simple_regression',
                   '/%72egression/regression-workshop/s2_simple_regression',
                   '/%72egression/regression-workshop/s2_simple_regression.html',
                   '/regression%2Fregression-workshop%2Fs2_simple_regression',
                   '/x/..%2Fregression/regression-workshop/s2_simple_regression',
                   '/regression//regression-workshop/s2_simple_regression',
                   '/REGRESSION/regression-workshop/s2_simple_regression',
                   '/regression/regression-workshop/S2_SIMPLE_REGRESSION',
                   '/regression/regression-workshop/s2_simple_regression%2F',
                   '/regression/regression-workshop%2Fs2_simple_regression',
                   '/regression/regression-workshop/labs/lab2_simple%2ER',
                   '/%2572egression/regression-workshop/s2_simple_regression']) {
    const r = await get(p);
    assert.ok(!/Session 2 paid|paid lab/.test(await r.text()), `${p} served paid content (status ${r.status})`);
  }
});

test('the hidden folder cannot be asked for directly, even with its name', async () => {
  for (const p of [`/_p/${TEST_ROOT}/regression/regression-workshop/s2_simple_regression`,
                   `/_p/${TEST_ROOT}/regression/regression-workshop/s2_simple_regression.html`]) {
    const r = await get(p);
    assert.equal(r.status, 404, p);
  }
});

test('a paid .html address redirects to the clean address without revealing the hidden folder', async () => {
  const cookie = await userWith('redir@example.test', [['regression']]);
  const r = await get('/regression/regression-workshop/s2_simple_regression.html', { ...HTML, cookie });
  assert.equal(r.status, 308);
  assert.equal(r.headers.get('location'), '/regression/regression-workshop/s2_simple_regression');
  assert.doesNotMatch(JSON.stringify([...r.headers]), new RegExp(TEST_ROOT));
});

test('/api/me reports which tracks are open', async () => {
  const cookie = await userWith('gis@example.test', [['gis']]);
  const me = await (await fetch(site.base + '/api/me', { headers: { cookie } })).json();
  assert.deepEqual(me.open, { basic: true, moderate: false, regression: false, statistics: false, advanced: false,
    'dataviz-base': false, 'dataviz-complete': false, gis: true, dungeons: true });
  assert.equal(me.catalog.gis, 'GIS and Spatial Statistics');
});
