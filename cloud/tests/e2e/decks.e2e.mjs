// Custom decks, notes and own slides in a browser, on the staged site (CUSTOM_DECKS_PLAN.md C2–C4).
//   cd cloud && node stage.mjs && node tests/e2e/decks.e2e.mjs
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
  catch (e) { steps.push(['FAIL', name]); console.log('FAIL', name, '\n     ' + e.message.split('\n').slice(0, 3).join('\n     ')); }
}
const site = await startSite({ siteDir: DEPLOY });
// webR packages come from repo.r-wasm.org: use the session's proxy if there is one (the site itself is local)
const browser = await chromium.launch(process.env.HTTPS_PROXY ? { proxy: { server: process.env.HTTPS_PROXY, bypass: 'localhost,127.0.0.1' } } : {});
const errors = [];
const watch = (page) => {
  page.on('pageerror', (e) => errors.push(`${page.url()}: ${e.message}`));
  page.on('dialog', (d) => d.accept());
  return page;
};
const FREE1 = 'stats-workshop/s1_know_your_data#where-we-are';
const FREE2 = 'stats-workshop/s1_know_your_data#four-kinds-of-variable';
const PAID = 'regression-workshop/s2_simple_regression#the-equation';
const slideCount = (page) => page.evaluate(() => document.querySelectorAll('.reveal .slides > section').length);

async function addFromLibrary(page, ref) {
  // Search by the slide's title, then press its + button
  const title = await page.evaluate((ref) => { const [wd, id] = ref.split('#'); const [w, d] = wd.split('/');
    return fetch('/slides.json').then((r) => r.json()).then((c) => c.decks.find((x) => x.workshop === w && x.deck === d).slides.find((s) => s.id === id).title); }, ref);
  await page.fill('#q', title);
  await page.locator('#lib ul.slides li', { hasText: title }).first().locator('button.add').click();
  return title;
}

try {
  const ctx = await browser.newContext({ viewport: { width: 1366, height: 900 } });
  const page = watch(await ctx.newPage());
  let paidTitle;

  await step('the slide catalogue is public and lists every workshop slide', async () => {
    const r = await fetch(site.base + '/slides.json');
    assert.equal(r.status, 200);
    const c = await r.json();
    assert.ok(c.decks.length >= 60 && c.decks.reduce((n, d) => n + d.slides.length, 0) > 1000);
  });

  await step('signed out: build a deck on this device, with a paid slide shown locked', async () => {
    await page.goto(site.base + '/decks', { waitUntil: 'networkidle' });
    await addFromLibrary(page, FREE1);
    await addFromLibrary(page, FREE2);
    paidTitle = await addFromLibrary(page, PAID);
    assert.equal(await page.locator('#items li').count(), 3);
    assert.match(await page.locator('#items li.locked').innerText(), /🔒/);
    await page.fill('#title', 'Revision on this device');
    await page.click('#save');
    await page.waitForSelector('.msg.ok');
    assert.match(await page.locator('#where').innerText(), /this device only/);
  });

  await step('play it: one deck, the free slides in full, the paid slide as a locked card', async () => {
    const [player] = await Promise.all([ctx.waitForEvent('page'), page.click('#play')]);
    watch(player);
    await player.waitForFunction(() => window.Reveal && Reveal.isReady && Reveal.isReady(), null, { timeout: 60000 });
    assert.equal(await slideCount(player), 4, 'title + 3');
    assert.ok(await player.locator('section[data-st-id="where-we-are"]').count());
    const locked = player.locator('section.st-locked');
    assert.equal(await locked.count(), 1);
    assert.match(await locked.innerText(), new RegExp(paidTitle.slice(0, 20).replace(/[.*+?^${}()|[\]\\]/g, '\\$&')));
    assert.match(await locked.innerText(), /Unlock/);
    assert.doesNotMatch(await player.content(), /slope/i, 'no paid content in the page');
    await player.close();
  });

  // Sign in (test login), hold the regression track
  const r = await page.evaluate(async () => (await fetch('/api/auth/sign-up/email', { method: 'POST', headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ email: 'meera@example.test', password: 'correct-horse-battery', name: 'Meera Rao' }) })).status);
  assert.equal(r, 200);
  const uid = site.sql(`select id from "user" where email = 'meera@example.test'`)[0].id;
  site.sql(`insert into entitlement values ('${uid}', 'regression', null, 'manual', ${Date.now()})`);
  await page.evaluate((id) => localStorage.setItem('ws-account', id), uid);

  let shareUrl;
  await step('signed in: an own slide made in the editor, saved with a deck to the account', async () => {
    await page.goto(site.base + '/decks', { waitUntil: 'networkidle' });
    assert.match(await page.locator('#who').innerText(), /Meera Rao/);
    await page.selectOption('#pick', '');
    await addFromLibrary(page, FREE1);
    await addFromLibrary(page, PAID);
    assert.equal(await page.locator('#items li.locked').count(), 0, 'regression is unlocked for this account');
    await page.click('#new-slide');
    const dlg = page.locator('dialog.st-editor');
    await dlg.locator('input[aria-label="Slide title"]').fill('My take-home');
    await dlg.locator('select[aria-label="Font"]').selectOption('lato');
    await dlg.locator('button[title="Alignment: center"]').click();
    await dlg.locator('textarea[aria-label="Text"]').fill('- Welch by **default**\n- <script>alert(1)</script> stays text');
    await dlg.locator('button[data-add="table"]').click();
    await dlg.locator('textarea[aria-label="Table rows"]').fill('Test | Use\nFisher | small counts');
    assert.match(await dlg.locator('.st-preview').innerText(), /Welch by default/);
    assert.equal(await dlg.locator('.st-preview script').count(), 0);
    await dlg.locator('button.st-primary').click();
    await page.waitForSelector('dialog.st-editor', { state: 'detached' });
    assert.equal(await page.locator('#items li.own').count(), 1);
    await page.fill('#title', 'Account deck');
    await page.click('#save');
    await page.waitForSelector('.msg.ok');
    assert.match(await page.locator('#where').innerText(), /your account/);
    const api = await page.evaluate(() => fetch('/api/decks').then((r) => r.json()));
    assert.equal(api.decks.length, 1); assert.equal(api.decks[0].count, 3);
    await page.click('#share');
    await page.waitForSelector('#share-box:not([hidden])');
    shareUrl = await page.locator('#share-url').inputValue();
    assert.match(shareUrl, /\/deck\?id=.+&share=.+/);
  });

  await step('the owner plays it: the paid slide is unlocked; the own slide renders safely in its font', async () => {
    const [player] = await Promise.all([ctx.waitForEvent('page'), page.click('#play')]);
    watch(player);
    await player.waitForFunction(() => window.Reveal && Reveal.isReady && Reveal.isReady() && window.SlideTools, null, { timeout: 60000 });
    await player.waitForSelector('section.st-own', { state: 'attached' });
    assert.equal(await player.locator('section.st-locked').count(), 0);
    assert.ok(await player.locator(`section[data-st-src*="regression-workshop/s2_simple_regression"]`).count());
    const own = player.locator('section.st-own');
    assert.match(await own.first().getAttribute('class'), /st-font-lato/);
    assert.match(await own.first().getAttribute('class'), /st-align-center/);
    assert.equal(await own.locator('script').count(), 0, 'the <script> stayed text');
    assert.match(await own.locator('table').innerText(), /Fisher/);
    await player.close();
  });

  await step('a viewer with the share link (another account, no regression): deck opens, paid slide locked', async () => {
    const ctx2 = await browser.newContext();
    const v = watch(await ctx2.newPage());
    await v.goto(shareUrl.replace(/^https?:\/\/[^/]+/, site.base), { waitUntil: 'load' });
    await v.waitForFunction(() => window.Reveal && Reveal.isReady && Reveal.isReady(), null, { timeout: 60000 });
    assert.equal(await v.locator('section.st-locked').count(), 1);
    assert.match(await v.locator('section.st-own').first().innerText(), /My take-home/);
    await ctx2.close();
  });

  await step('PDF: the player opens in reveal.js print layout and calls print', async () => {
    const p = watch(await ctx.newPage());
    await p.addInitScript(() => { window.print = () => { window.__printed = true; }; });
    const id = new URL(shareUrl).searchParams.get('id');
    await p.goto(`${site.base}/deck?id=${encodeURIComponent(id)}&print-pdf`, { waitUntil: 'load' });
    await p.waitForFunction(() => window.Reveal && Reveal.isReady && Reveal.isReady(), null, { timeout: 60000 });
    await p.waitForFunction(() => window.__printed === true || document.querySelector('.pdf-page'), null, { timeout: 15000 });
    assert.ok(await p.locator('.pdf-page').count() >= 3, 'one page per slide');
    await p.close();
  });

  await step('in a workshop deck: a note written in Edit mode is saved to the account and shown in View mode', async () => {
    const d = watch(await ctx.newPage());
    await d.goto(site.base + '/statistics/stats-workshop/s1_know_your_data.html#/where-we-are', { waitUntil: 'load' });
    await d.waitForFunction(() => window.Reveal && Reveal.isReady() && window.SlideTools);
    await d.click('.st-toggle');
    await d.fill('.st-note-text', 'Start with the data dictionary.');
    await d.waitForFunction(() => /Saved to your account/.test(document.querySelector('.st-note-status').textContent), null, { timeout: 10000 });
    const notes = await d.evaluate(() => fetch('/api/notes').then((r) => r.json()));
    assert.equal(notes.notes['stats-workshop/s1_know_your_data#where-we-are'].text, 'Start with the data dictionary.');
    await d.click('.st-toggle');
    await d.reload(); await d.waitForFunction(() => window.Reveal && Reveal.isReady() && window.SlideTools);
    await d.waitForSelector('.st-notes-view', { timeout: 10000 });
    assert.match(await d.locator('.st-notes-view').innerText(), /data dictionary/);
    await d.close();
  });

  await step('in a workshop deck: "Add slide after this" puts your slide right after it, for you only', async () => {
    const d = watch(await ctx.newPage());
    await d.goto(site.base + '/statistics/stats-workshop/s1_know_your_data.html#/where-we-are', { waitUntil: 'load' });
    await d.waitForFunction(() => window.Reveal && Reveal.isReady() && window.SlideTools);
    await d.click('.st-toggle');
    await d.locator('.st-actions button', { hasText: 'Add slide after this' }).click();
    const dlg = d.locator('dialog.st-editor');
    await dlg.locator('input[aria-label="Slide title"]').fill('My extra example');
    await dlg.locator('textarea[aria-label="Text"]').fill('Weight differs by sex.');
    await dlg.locator('button.st-primary').click();
    await d.waitForSelector('section.st-own');
    const order = await d.evaluate(() => [...document.querySelectorAll('.reveal .slides > section')].map((s) => s.id || (s.classList.contains('st-own') ? 'OWN' : '')));
    assert.equal(order[order.indexOf('where-we-are') + 1], 'OWN');
    const mine = await d.evaluate(() => fetch('/api/slides?anchor=stats-workshop/s1_know_your_data').then((r) => r.json()));
    assert.equal(mine.slides.length, 1); assert.equal(mine.slides[0].anchor, 'stats-workshop/s1_know_your_data#where-we-are');
    await d.click('.st-toggle');
    await d.close();
    // Signed out, the deck has no such slide
    const ctx3 = await browser.newContext();
    const o = watch(await ctx3.newPage());
    await o.goto(site.base + '/statistics/stats-workshop/s1_know_your_data.html', { waitUntil: 'load' });
    await o.waitForFunction(() => window.Reveal && Reveal.isReady() && window.SlideTools);
    assert.equal(await o.locator('section.st-own').count(), 0);
    await ctx3.close();
  });

  await step('on Cloudflare: Run uses the self-hosted webR, the deck manifest and the data through the site', async () => {
    const d = watch(await ctx.newPage());
    const webrUrls = [];
    d.on('request', (q) => { if (/webr/.test(q.url())) webrUrls.push(q.url()); });
    await d.goto(site.base + '/statistics/stats-workshop/s1_know_your_data#/our-data', { waitUntil: 'load' });
    await d.waitForFunction(() => window.Reveal && Reveal.isReady() && window.SlideTools);
    if (!(await d.locator('.st-box').count())) await d.click('.st-toggle');
    const box = d.locator('section#our-data .st-box').first();
    await box.locator('.st-code').fill('nrow(p)');
    await box.locator('.st-run').click();
    await d.waitForFunction(() => /\[1\] 631/.test((document.querySelector('section#our-data .st-out') || {}).textContent || ''), null, { timeout: 600000 });
    assert.ok(webrUrls.some((u) => u.startsWith(site.base + '/webr/') && /R\.wasm|webr-worker\.js/.test(u)), 'webR (R.wasm, worker) loaded from our own domain:\n' + webrUrls.join('\n'));
    await d.click('.st-toggle');
    await d.close();
  });

  await step('no script errors anywhere', async () => assert.deepEqual(errors, []));
} finally {
  await browser.close();
  await site.stop();
}
const failed = steps.filter((s) => s[0] !== 'ok');
console.log(`\n${steps.length - failed.length} of ${steps.length} passed`);
process.exit(failed.length ? 1 : 0);
