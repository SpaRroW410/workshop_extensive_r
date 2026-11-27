// Edit mode in a real deck: toggle, edit a chunk, run it with webR, reset, leave.
//   node scripts/tests/edit_mode.e2e.mjs [deck path under docs/]   (needs network for webR and its packages)
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { join, extname, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';
import assert from 'node:assert/strict';
const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const DOCS = join(dirname(fileURLToPath(import.meta.url)), '..', '..', 'docs');
const DECK = process.argv[2] || 'statistics/stats-workshop/s4_two_groups.html';
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.css': 'text/css', '.json': 'application/json', '.xlsx': 'application/octet-stream', '.csv': 'text/csv' };
const server = createServer(async (req, res) => {
  const p = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  try { const b = await readFile(join(DOCS, p)); res.writeHead(200, { 'content-type': TYPES[extname(p)] || 'application/octet-stream' }); res.end(req.method === 'HEAD' ? undefined : b); }
  catch { res.writeHead(404); res.end(); }
}).listen(0);
const base = `http://localhost:${server.address().port}/`;
const proxy = process.env.HTTPS_PROXY ? { server: process.env.HTTPS_PROXY, bypass: 'localhost,127.0.0.1' } : undefined;
const browser = await chromium.launch({ proxy });
const steps = []; const errors = [];
const step = async (name, fn) => { try { await fn(); steps.push(1); console.log('ok  ', name); } catch (e) { steps.push(0); console.log('FAIL', name, '\n     ' + e.message.split('\n')[0]); } };
try {
  const page = await browser.newPage({ viewport: { width: 1366, height: 800 } });
  page.on('pageerror', (e) => errors.push(e.message));
  await page.goto(base + DECK, { waitUntil: 'load' });
  await page.waitForFunction(() => window.Reveal && Reveal.isReady());
  const cellsJs = "[...document.querySelectorAll('.reveal .slides div.cell')].filter((c) => c.querySelector('.cell-code'))";
  const goTo = (k) => page.evaluate((k) => { const i = Reveal.getIndices(document.querySelectorAll('.st-box')[k].closest('section')); Reveal.slide(i.h, i.v); }, k).then(() => page.waitForTimeout(400));
  await step('View mode: deck unchanged, no webR requested, Edit button shown', async () => {
    assert.equal(await page.locator('.st-toggle').innerText(), '✎ Edit');
    assert.equal(await page.locator('.st-box').count(), 0);
    assert.equal(await page.evaluate(() => !!window.SlideTools.R.webR), false);
  });
  await step('Edit on: every R chunk becomes an editor with Run and Reset', async () => {
    await page.click('.st-toggle');
    const cells = await page.evaluate((js) => eval(js).length, cellsJs);
    assert.ok(cells > 0);
    assert.equal(await page.locator('.st-code').count(), cells);
    assert.equal(await page.locator('.st-run').count(), cells);
  });
  await step('Run an edited chunk in the browser (webR): output appears', async () => {
    const cell = page.locator('.st-box').first();
    await goTo(0);
    await cell.locator('.st-code').fill('t.test(p$fbs_presentation, mu = 105)$p.value < 0.001\nnrow(p)');
    await cell.locator('.st-run').click();
    await page.waitForFunction(() => { const o = document.querySelector('.st-out'); return o && /\[1\]/.test(o.textContent); }, null, { timeout: 600000 });
    const out = await cell.locator('.st-out').innerText();
    assert.match(out, /\[1\] TRUE/); assert.match(out, /\[1\] 631/);
  });
  await step('A later chunk runs after the earlier ones (shared R session) and draws nothing wrong', async () => {
    const k = await page.evaluate(() => document.querySelectorAll('.st-box').length - 1);
    const cell = page.locator('.st-box').nth(k);
    await goTo(k);
    await cell.locator('.st-run').click();
    await page.waitForFunction((k) => { const o = document.querySelectorAll('.st-out')[k]; return o && o.textContent && !/Running/.test(o.textContent); }, k, { timeout: 300000 });
    const out = await cell.locator('.st-out').innerText();
    assert.doesNotMatch(out, /Error/i, out.slice(0, 200));
  });
  await goTo(0);
  await step('Reset restores the original code and clears the output', async () => {
    const cell = page.locator('.st-box').first();
    await cell.locator('.st-reset').click();
    assert.match(await cell.locator('.st-code').inputValue(), /mu = 100/);
    assert.equal(await cell.locator('.st-out').innerText(), '');
  });
  await step('Edit off: the original rendering is back; the choice is remembered', async () => {
    await page.click('.st-toggle');
    assert.equal(await page.locator('.st-box').count(), 0);
    assert.equal(await page.locator('.cell.st-editing').count(), 0);
    await page.reload(); await page.waitForFunction(() => window.Reveal && Reveal.isReady());
    assert.equal(await page.locator('.st-box').count(), 0);
  });
  await step('no script errors', async () => assert.deepEqual(errors, []));
} finally { await browser.close(); server.close(); }
const failed = steps.filter((s) => !s).length;
console.log(`\n${steps.length - failed} of ${steps.length} passed`);
process.exit(failed ? 1 : 0);
