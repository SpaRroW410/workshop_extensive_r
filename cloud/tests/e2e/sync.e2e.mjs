// End-to-end check of progress sync (phase 3) on the real staged site, in a browser.
//   cd cloud && node stage.mjs && node tests/e2e/sync.e2e.mjs
// Plan proof: "solve an item on one device, see it on another".
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
  catch (e) { steps.push(['FAIL', name]); console.log('FAIL', name, '\n     ' + e.message.split('\n').join('\n     ')); }
}

const site = await startSite({ siteDir: DEPLOY });
const browser = await chromium.launch();
const errors = [];
async function device() {
  const ctx = await browser.newContext({ viewport: { width: 1366, height: 900 } });
  const page = await ctx.newPage();
  page.on('pageerror', (e) => errors.push(`${page.url()}: ${e.message}`));
  page.on('dialog', (d) => d.accept());
  return page;
}
const go = (page, path) => page.goto(site.base + path, { waitUntil: 'networkidle' });
// Sign in with the test-only login, then open /account as the Google callback would.
async function signIn(page, email, name, create) {
  await go(page, '/');
  const status = await page.evaluate(async ([email, name, create]) => (await fetch(create ? '/api/auth/sign-up/email' : '/api/auth/sign-in/email', {
    method: 'POST', headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ email, name, password: 'correct-horse-battery' }),
  })).status, [email, name, create]);
  assert.equal(status, 200);
  await go(page, '/account?after=signin&next=%2F');
  await page.waitForURL(site.base + '/');
  await page.waitForLoadState('networkidle');
}
// A game state as quest.js saves it: one solved item (30 XP + 50 boss bonus = 80 XP).
const GAME = JSON.stringify({ v: 1, items: { b1boss: { world: 'b1', diff: 3, boss: true, tries: 1, hints: 0, solved: true, shown: false, tags: [] } },
  badges: { first: '2026-11-19' }, streak: { last: '2026-11-19', count: 1, best: 1 }, tests: { r1pre: { pct: 45, ts: '2026-11-19' } }, settings: {}, created: '2026-11-19' });

try {
  const laptop = await device();

  await step('signed out: nothing is sent to the server', async () => {
    const calls = [];
    laptop.on('request', (r) => { if (r.url().includes('/api/progress')) calls.push(r.url()); });
    await go(laptop, '/basic/welcome');
    await laptop.locator('.ws-plan-tick').nth(0).check();
    await laptop.evaluate((g) => localStorage.setItem('rq:v1', g), GAME);
    await laptop.waitForTimeout(2000);
    assert.deepEqual(calls, []);
  });

  await step('signing in uploads what was done before signing in', async () => {
    await signIn(laptop, 'kiran@example.test', 'Kiran Rao', true);
    await laptop.waitForTimeout(1500);
    const id = site.sql(`select id from "user" where email = 'kiran@example.test'`)[0].id;
    const keys = site.sql(`select "key" from progress where "userId" = '${id}' order by "key"`).map((r) => r.key);
    assert.deepEqual(keys, ['rq:v1', 'ws-plan:basic']);
  });

  const phone = await device();
  await step('a second device shows the same XP, ticks and pre-test score', async () => {
    await signIn(phone, 'kiran@example.test', 'Kiran Rao', false);
    await phone.waitForTimeout(1500); // the sync answer arrives, the page reloads once with it
    await phone.waitForLoadState('networkidle');
    assert.equal(await phone.locator('#ws-profile-xp').innerText(), '80');
    assert.match(await phone.locator('.ws-profile-tracks li[data-track="basic"] em').innerText(), /^1\//);
    assert.equal(await phone.locator('.ws-profile-tracks li[data-track="basic"] [data-test="r1pre"]').innerText(), '45%');
    assert.equal(await phone.locator('.ws-profile-name').innerText(), 'Kiran Rao');
  });

  await step('un-ticking on the phone reaches the laptop', async () => {
    await go(phone, '/basic/welcome');
    await phone.locator('.ws-plan-tick').nth(0).uncheck();
    await phone.waitForTimeout(2500); // debounced send
    await go(laptop, '/basic/welcome');
    await laptop.waitForTimeout(1500);
    await laptop.waitForLoadState('networkidle');
    assert.equal(await laptop.locator('.ws-plan-tick').nth(0).isChecked(), false);
  });

  await step('a quiz answer on one device counts on the other', async () => {
    await go(laptop, '/basic/welcome');
    await laptop.evaluate(() => localStorage.setItem('quiz-score:regression-workshop/s1_foundations', JSON.stringify({ r1q1: true })));
    await laptop.waitForTimeout(2500);
    await go(phone, '/');
    await phone.waitForTimeout(1500);
    const v = await phone.evaluate(() => localStorage.getItem('quiz-score:regression-workshop/s1_foundations'));
    assert.deepEqual(JSON.parse(v), { r1q1: true });
  });

  await step('a score saved by the old quiz engine (deck name only) is still shown, under the new key', async () => {
    await go(laptop, '/basic/welcome');
    await laptop.evaluate(() => {
      localStorage.removeItem('quiz-score:regression-workshop/s1_foundations');
      localStorage.setItem('quiz-score:s1_foundations', JSON.stringify({ s1q1: true, s1q2: false, zz9: true }));
    });
    await go(laptop, '/regression/regression-workshop/s1_foundations');
    const saved = await laptop.evaluate(() => JSON.parse(localStorage.getItem('quiz-score:regression-workshop/s1_foundations')));
    assert.deepEqual(saved, { s1q1: true, s1q2: false }, 'only this deck\'s questions are carried over');
  });

  await step('continue where you left off', async () => {
    await go(laptop, '/regression/regression-workshop/s1_foundations');
    await laptop.waitForTimeout(1000);
    await go(phone, '/');
    await phone.waitForSelector('#ws-continue:not([hidden])');
    assert.equal(await phone.locator('#ws-continue').getAttribute('href'), '/regression/regression-workshop/s1_foundations');
    assert.match(await phone.locator('#ws-continue-title').innerText(), /Foundations/);
  });

  await step('the game reset clears the saved copy too', async () => {
    await go(phone, '/dungeons/dungeons/');
    await phone.click('#rq-reset'); // confirm() is accepted; the page reloads
    await phone.waitForLoadState('networkidle');
    await phone.waitForTimeout(1500);
    await go(laptop, '/');
    await laptop.waitForTimeout(1500);
    await laptop.waitForLoadState('networkidle');
    assert.equal(await laptop.locator('#ws-profile-xp').innerText(), '0');
  });

  await step('sign out on a shared computer: the next person does not get Kiran\'s progress', async () => {
    await go(laptop, '/basic/welcome');
    await laptop.locator('.ws-plan-tick').nth(2).check();
    await go(laptop, '/account');
    await laptop.click('#signout');
    await laptop.waitForURL(site.base + '/');
    const left = await laptop.evaluate(() => Object.keys(localStorage).filter((k) => /^(rq:|quiz-score:|ws-plan:|ws-path-done)/.test(k)));
    assert.deepEqual(left, [], 'synced progress removed from this browser');
    await signIn(laptop, 'neha@example.test', 'Neha', true);
    await laptop.waitForTimeout(1500);
    const id = site.sql(`select id from "user" where email = 'neha@example.test'`)[0].id;
    assert.equal(site.sql(`select count(*) as n from progress where "userId" = '${id}'`)[0].n, 0);
    // ...and the tick made just before signing out was saved to Kiran's account.
    const kiran = site.sql(`select value from progress p join "user" u on u.id = p."userId" where u.email = 'kiran@example.test' and p."key" = 'ws-plan:basic'`)[0];
    assert.ok(JSON.parse(kiran.value)['2'], 'pending tick was flushed before sign-out');
  });

  await step('no script errors', async () => { assert.deepEqual(errors, []); });
} finally {
  await browser.close();
  await site.stop();
}

const failed = steps.filter((s) => s[0] !== 'ok');
console.log(`\n${steps.length - failed.length} of ${steps.length} passed`);
process.exit(failed.length ? 1 : 0);
