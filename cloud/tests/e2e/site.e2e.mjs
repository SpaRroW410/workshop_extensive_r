// End-to-end check of the real site behind the gate, in a browser.
//   cd cloud && node stage.mjs && node tests/e2e/site.e2e.mjs
// Uses the staged folder (.deploy) with a fresh local database. Not part of `npm test`: it needs
// a full Quarto render and takes about a minute.
import { createRequire } from 'node:module';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';
import { startSite } from '../helpers.js';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const DEPLOY = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '.deploy');

const steps = [];
async function step(name, fn) {
  try { await fn(); steps.push(['ok', name]); console.log('ok  ', name); }
  catch (e) { steps.push(['FAIL', name, e.message]); console.log('FAIL', name, '\n     ' + e.message.split('\n').join('\n     ')); }
}

const site = await startSite({ siteDir: DEPLOY });
const browser = await chromium.launch();
const errors = [];
function watch(page) {
  page.on('pageerror', (e) => errors.push(`${page.url()}: ${e.message}`));
  page.on('response', (r) => {
    if (r.status() >= 400 && !r.url().includes('/api/') && !/fonts\.g|cdn\./.test(r.url())) errors.push(`${r.status()} ${r.url()}`);
  });
  return page;
}

try {
  const ctx = await browser.newContext({ viewport: { width: 1366, height: 900 } });
  const page = watch(await ctx.newPage());

  await step('landing page, signed out: free tracks open, paid ones say Sign in', async () => {
    await page.goto(site.base + '/', { waitUntil: 'networkidle' });
    const btn = (id) => page.locator(`.ws-card[data-profile="${id}"] .ws-btn`).innerText();
    assert.equal((await btn('basic')).trim(), 'Enter Track →');
    assert.equal((await btn('regression')).trim(), 'Sign in →');
    assert.equal(await page.locator('.ws-bar-profile').getAttribute('href'), '/account?next=%2F');
    assert.equal(await page.locator('#ws-modal-overlay').isVisible(), false);
  });

  await step('a locked track goes to the account page, not to a key box', async () => {
    await page.locator('.ws-card[data-profile="regression"] .ws-btn').click();
    await page.waitForURL(/\/account\?/);
    const u = new URL(page.url());
    assert.equal(u.searchParams.get('need'), 'regression');
    await page.waitForSelector('#out:not([hidden])');
    assert.match(await page.locator('#out-title').innerText(), /Sign in to open this page/);
    assert.match(await page.locator('#need-name').innerText(), /Regression track/);
  });

  await step('signed out: a paid deck URL lands on the account page; a free Session 1 deck opens', async () => {
    await page.goto(site.base + '/regression/regression-workshop/s2_simple_regression.html', { waitUntil: 'networkidle' });
    assert.match(page.url(), /\/account\?need=regression/);
    await page.goto(site.base + '/regression/regression-workshop/s1_foundations.html', { waitUntil: 'networkidle' });
    assert.match(page.url(), /s1_foundations/);
    assert.ok(await page.locator('.reveal .slides').count(), 'the Session 1 deck renders');
  });

  await step('sign in (test login), get regression: landing opens it, profile shows the name', async () => {
    const r = await page.evaluate(async () => (await fetch('/api/auth/sign-up/email', {
      method: 'POST', headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email: 'priya@example.test', password: 'correct-horse-battery', name: 'Priya Nair' }),
    })).status);
    assert.equal(r, 200);
    const id = site.sql(`select id from "user" where email = 'priya@example.test'`)[0].id;
    site.sql(`insert into entitlement values ('${id}', 'regression', null, 'manual', ${Date.now()})`);
    await page.goto(site.base + '/', { waitUntil: 'networkidle' });
    assert.equal((await page.locator('.ws-card[data-profile="regression"] .ws-btn').innerText()).trim(), 'Enter Track →');
    assert.equal((await page.locator('.ws-card[data-profile="gis"] .ws-btn').innerText()).trim(), 'How to unlock →');
    assert.equal(await page.locator('.ws-profile-name').innerText(), 'Priya Nair');
    assert.equal(await page.locator('.ws-bar-profile').getAttribute('href'), '/account');
    const row = page.locator('.ws-profile-tracks li[data-track="regression"] .ws-pt-link');
    assert.equal((await row.innerText()).trim(), 'Open →');
    assert.equal((await page.locator('.ws-profile-tracks li[data-track="gis"] .ws-pt-link').innerText()).trim(), '🔒 Locked');
  });

  await step('the paid deck now opens with its slides, styles and quiz engine', async () => {
    const before = errors.length;
    await page.goto(site.base + '/regression/regression-workshop/s2_simple_regression.html', { waitUntil: 'networkidle' });
    assert.match(page.url(), /s2_simple_regression/);
    assert.ok(await page.locator('.reveal .slides section').count() > 5, 'deck has slides');
    assert.deepEqual(errors.slice(before), [], 'no failed requests on the paid deck');
  });

  await step('a product the account lacks: account page says what to ask for', async () => {
    await page.goto(site.base + '/gis/gis-workshop/s2_neighbours_weights.html', { waitUntil: 'networkidle' });
    assert.match(page.url(), /\/account\?need=gis/);
    await page.waitForSelector('#lacks:not([hidden])');
    assert.match(await page.locator('#lacks').innerText(), /GIS and Spatial Statistics/);
    assert.match(await page.locator('#email').innerText(), /priya@example\.test/);
  });

  await step('a second device, same account: same products', async () => {
    const ctx2 = await browser.newContext();
    const p2 = watch(await ctx2.newPage());
    await p2.goto(site.base + '/', { waitUntil: 'networkidle' });
    await p2.evaluate(async () => fetch('/api/auth/sign-in/email', {
      method: 'POST', headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email: 'priya@example.test', password: 'correct-horse-battery' }),
    }));
    await p2.goto(site.base + '/', { waitUntil: 'networkidle' });
    assert.equal((await p2.locator('.ws-card[data-profile="regression"] .ws-btn').innerText()).trim(), 'Enter Track →');
    await ctx2.close();
  });

  await step('sign out from the account page', async () => {
    await page.goto(site.base + '/account', { waitUntil: 'networkidle' });
    await page.click('#signout');
    await page.waitForURL(site.base + '/');
    await page.waitForLoadState('networkidle');
    assert.equal((await page.locator('.ws-card[data-profile="regression"] .ws-btn').innerText()).trim(), 'Sign in →');
  });

  await step('encoded-path tricks find nothing on the real site', async () => {
    const title = 'Simple Linear Regression';
    for (const p of ['/%72egression/regression-workshop/s2_simple_regression',
                     '/basic%2F..%2Fregression%2Fregression-workshop%2Fs2_simple_regression.html',
                     '/regression/site_libs/..%2Fregression-workshop%2Fs2_simple_regression',
                     '/regression/regression-workshop/s1_foundations%2F..%2Fs2_simple_regression.html',
                     '/advanced/survival-workshop/s1_time_to_event%2F..%2Fs4_cox_regression.html']) {
      const r = await fetch(site.base + p, { redirect: 'manual' });
      const t = await r.text();
      assert.ok(!t.includes(title) && !t.includes('Cox Regression</h1>'), `${p} leaked (status ${r.status})`);
    }
  });

  await step('no failed requests or script errors anywhere', async () => {
    assert.deepEqual(errors, []);
  });
} finally {
  await browser.close();
  await site.stop();
}

const failed = steps.filter((s) => s[0] !== 'ok');
console.log(`\n${steps.length - failed.length} of ${steps.length} passed`);
process.exit(failed.length ? 1 : 0);
