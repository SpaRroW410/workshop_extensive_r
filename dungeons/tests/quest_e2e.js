// Usage: node dungeons/tests/quest_e2e.js <rendered dungeons/ folder>   (needs `npm i playwright`; set PLAYWRIGHT_PATH / CHROME_PATH if not on the default path)
const { chromium } = require(process.env.PLAYWRIGHT_PATH || 'playwright');
const fs = require('fs'), path = require('path');
const DIR = process.argv[2];                       // .../docs/dungeons/dungeons
const SRCDIR = process.argv[3] || DIR;
const ITEM_PAGES = fs.readdirSync(SRCDIR).filter(f => f.endsWith('.html') && fs.readFileSync(path.join(SRCDIR, f), 'utf8').includes('class="rq-item"'));   // every page that carries items           // folder with the same pages on disk (needed when DIR is an http URL)
const url = f => /^https?:/.test(DIR) ? DIR.replace(/\/$/, '') + '/' + f : 'file://' + path.join(DIR, f);   // pass http://localhost:8080/dungeons/dungeons to avoid file:// module blocking
let fails = 0; const ok = (c, m) => { console.log((c ? 'PASS ' : 'FAIL ') + m); if (!c) fails++; };

// same hash as quest.js / quest.R
function hash(str) { let a = 5381, b = 52711; for (let i = 0; i < str.length; i++) { const c = str.charCodeAt(i); a = (a * 131 + c) % 2147483629; b = (b * 137 + c) % 2147483587; } return a.toString(36) + '.' + b.toString(36); }
const dec = s => Buffer.from(s.replace(/&quot;/g, '"'), 'base64').toString('utf8');

// helper injected in page: solve (correctly) or fail (wrongly) an item
const HELPERS = `
window.__solve = function (q, good) {
  const t = q.dataset.type, id = q.dataset.id, H = Quest.hash;
  const click = el => el.click();
  if (t === 'mcq') { const b = [...q.querySelectorAll('.rq-option')]; const key = b.find(x => H(id + '|' + x.dataset.i) === q.dataset.hash); click(good ? key : b.find(x => x !== key)); return; }
  if (t === 'fill' || t === 'num') { const inp = q.querySelector('.rq-input'); inp.value = good ? new TextDecoder().decode(Uint8Array.from(atob(q.dataset.show), c => c.charCodeAt(0))) : '-999zzz'; inp.dispatchEvent(new Event('input')); const c = q.querySelector('.rq-fill .rq-btn'); if (c) click(c); return; }
  if (t === 'code') { const ta = q.querySelector('.rq-code'); ta.value = good ? new TextDecoder().decode(Uint8Array.from(atob(q.dataset.show), c => c.charCodeAt(0))) : 'ncd |> nrow()'; ta.dispatchEvent(new Event('input')); const c = [...q.querySelectorAll('.rq-btn')].find(b => /Check code/.test(b.textContent)); if (c) click(c); return; }
  if (t === 'order') {
    const lis = () => [...q.querySelectorAll('.rq-order li')]; const n = lis().length; const idx = [...Array(n).keys()];
    let target = null; (function perm(a, k) { if (target) return; if (k === a.length) { if (H(id + '|' + a.join('-')) === q.dataset.hash) target = a.slice(); return; } for (let i = k; i < a.length; i++) { [a[k], a[i]] = [a[i], a[k]]; perm(a, k + 1); [a[k], a[i]] = [a[i], a[k]]; } })(idx.slice(), 0);
    if (good) { for (let p = 0; p < n; p++) { let cur = lis().findIndex(l => +l.dataset.i === target[p]); while (cur > p) { lis()[cur].querySelectorAll('button')[0].click(); cur--; } } }
    else { lis()[0].querySelectorAll('button')[1].click(); }
    const chk = [...q.querySelectorAll('.rq-btn')].find(b => /Check order/.test(b.textContent)); if (chk) click(chk); return; }
  if (t === 'spot') {
    const sb = [...q.querySelectorAll('.rq-sentence')]; const n = sb.length; let best = null;
    for (let m = 0; m < (1 << n); m++) { const s = []; for (let i = 0; i < n; i++) if (m & (1 << i)) s.push(i); if (H(id + '|' + s.join(',')) === q.dataset.hash) { best = s; break; } }
    sb.forEach(b => { if (b.classList.contains('is-flagged')) b.click(); }); if (good) best.forEach(i => sb[i].click()); else sb[0].click();
    const chk = [...q.querySelectorAll('.rq-btn')].find(b => /Check flags/.test(b.textContent)); if (chk) click(chk); return; }
};
window.__item = id => document.querySelector('.rq-item[data-id="' + id + '"]');
`;
const state = p => p.evaluate(() => JSON.parse(localStorage.getItem('rq:v1') || 'null'));
const hudXP = p => p.evaluate(() => +document.querySelector('.rq-hud .rq-xp').textContent);

(async () => {
  const browser = await chromium.launch({ executablePath: process.env.CHROME_PATH || undefined, args: ['--no-sandbox'] });
  const newCtx = async (extra) => { const c = await browser.newContext({ acceptDownloads: true, viewport: { width: 1200, height: 900 } }); if (extra) await c.addInitScript(extra); return c; };
  const open = async (c, f) => { const p = await c.newPage(); const errs = []; p.on('pageerror', e => errs.push(String(e))); p.on('requestfailed', r => { if (!/fitty-init/.test(r.url())) errs.push('REQFAIL ' + r.url().slice(-60)); }); await p.goto(url(f)); await p.waitForFunction(() => window.Quest); await p.evaluate(HELPERS); p._errs = errs; return p; };

  // ── 1. static page-source inspection (all pages with items) ──────────────
  let keyFirst = 0, mcqN = 0, orderIdent = 0, orderN = 0;
  for (const f of ITEM_PAGES) {
    const src = fs.readFileSync(path.join(SRCDIR, f), 'utf8');
    const items = [...src.matchAll(/<div class="rq-item"([^>]*)>([\s\S]*?)<\/div>/g)];
    const leak = [];
    for (const m of src.matchAll(/<div class="rq-item"([^>]*)>/g)) {
      const a = m[1], g = n => ((a.match(new RegExp(n + '="([^"]*)"')) || [])[1] || '');
      const ex = dec(g('data-explain')), sh = dec(g('data-show')); let hints = []; try { hints = JSON.parse(dec(g('data-hints')) || '[]'); } catch (e) {}
      for (const t of [ex, ...hints]) if (t.length > 25 && src.includes(t.slice(0, 30))) leak.push(g('data-id'));
      if (g('data-type') === 'fill' || g('data-type') === 'num') if (g('data-hashes').split(',').includes(sh)) leak.push(g('data-id') + ':hash');
    }
    ok(leak.length === 0, `${f}: no explanation/hint/answer text in page source ${leak.join(',')}`);
    ok(!/data-answer=/.test(src), `${f}: no plain data-answer`);
  }
  // key-first and in-order markup check using real DOM (fast path: parse with regex on rendered html)
  const ctx0 = await newCtx(); 
  for (const f of ITEM_PAGES) {
    const raw = fs.readFileSync(path.join(SRCDIR, f), 'utf8');
    const items = [...raw.matchAll(/<div class="rq-item"([^>]*)>([\s\S]*?)(?=<div class="rq-item"|<\/main>|<\/body>)/g)];
    for (const m of items) { const a = m[1], g = n => ((a.match(new RegExp(n + '="([^"]*)"')) || [])[1] || ''); const t = g('data-type'), id = g('data-id');
      if (t === 'mcq') { mcqN++; if (hash(id + '|0') === g('data-hash')) keyFirst++; }
      if (t === 'order') { orderN++; const n = (m[2].match(/<li>/g) || []).length; if (hash(id + '|' + [...Array(n).keys()].join('-')) === g('data-hash')) orderIdent++; } }
  }
  ok(mcqN >= 20 && keyFirst / mcqN < 0.5, `MCQ markup does not list the key first (${keyFirst}/${mcqN} key-first, expected ≈ 25%)`);
  ok(orderN >= 2 && orderIdent === 0, `order items are not listed in correct order in the source (${orderIdent}/${orderN})`);
  await ctx0.close();

  // ── 2. fresh learner: quest map, locks ───────────────────────────────────
  let ctx = await newCtx(); let p = await open(ctx, 'index.html');
  const cards = await p.locator('.rq-card').count();
  const nW = await p.evaluate(() => window.RQ_WORLDS.length), nSoon = await p.evaluate(() => window.RQ_WORLDS.filter(w => w.status !== 'playable').length);
  ok(cards === nW && (await p.locator('.rq-region').count()) === 4, `quest map shows every world (${cards}/${nW}) in 4 regions`);
  ok(await p.locator('.rq-card.rq-locked').count() >= 1 && await p.locator('.rq-card.rq-soon').count() === nSoon, `World 1 locked until pre-test; ${nSoon} worlds marked coming soon`);
  ok(await hudXP(p) === 0, 'HUD starts at 0 XP'); ok(p._errs.length === 0, 'index: no JS errors ' + p._errs.join());
  const w1 = await open(ctx, 'world1_outcome_detective.html');
  ok(await w1.evaluate(() => document.body.classList.contains('rq-locked')), 'World 1 is locked before the pre-test');
  await w1.close();

  // ── 3. pre-test (test mode) ──────────────────────────────────────────────
  p = await open(ctx, 'pretest.html');
  const nIt = await p.locator('.rq-item').count(); ok(nIt === 20, 'pre-test has 20 items');
  ok(await p.locator('.rq-item .rq-actions').count() === 0 && await p.locator('.rq-item .rq-hintbox').count() === 0, 'test mode: no hints / show-answer buttons');
  await p.evaluate(() => { document.querySelectorAll('.rq-item').forEach((q, i) => { window.__solve(q, i < 10); const r = q.querySelector('input[type=radio][value="' + (i % 2 ? 3 : 1) + '"]'); if (r) r.checked = true; }); });
  ok((await p.locator('.rq-feedback').allInnerTexts()).every(t => t.trim() === ''), 'test mode: no feedback shown while answering');
  await p.evaluate(() => [...document.querySelectorAll('.rq-big')].find(b => /Submit/.test(b.textContent)).click());
  let st = await state(p);
  ok(st.tests.pre && st.tests.pre.score === 10 && st.tests.pre.pct === 50, 'pre-test scored 10/20 = 50% and saved ' + JSON.stringify(st.tests.pre && [st.tests.pre.score, st.tests.pre.pct]));
  ok(Object.keys(st.tests.pre.byTag).length >= 8, 'per-skill breakdown recorded');
  ok(!!st.badges.pre, 'Baseline Set badge awarded');
  ok(/50%/.test(await p.locator('.rq-results').innerText()), 'result panel shown');
  await p.close();

  // ── 4. world 1: unlocked, XP rules ───────────────────────────────────────
  p = await open(ctx, 'world1_outcome_detective.html');
  ok(!(await p.evaluate(() => document.body.classList.contains('rq-locked'))), 'World 1 unlocked after pre-test');
  await p.evaluate(() => { window.__solve(__item('w1-08'), false); window.__solve(__item('w1-08'), true); });   // wrong then right, diff1 → 5 XP
  await p.evaluate(() => window.__solve(__item('w1-01'), true));                                              // first try diff1 → 10
  await p.evaluate(() => { const q = __item('w1-02'); q.querySelector('.rq-actions .rq-ghost').click(); window.__solve(q, true); });  // 1 hint (-3) diff2 → 17
  await p.evaluate(() => { const q = __item('w1-07'); [...q.querySelectorAll('.rq-actions .rq-ghost')].find(b => /Show answer/.test(b.textContent)).click(); });  // 0
  st = await state(p);
  ok(await hudXP(p) === 32, `XP rules: wrong→right (5) + first try (10) + hint (17) + shown (0) = 32, HUD ${await hudXP(p)}`);
  ok(st.items['w1-08'].tries === 2 && st.items['w1-02'].hints === 1 && st.items['w1-07'].shown === true, 'attempts, hints and show-answer recorded');
  ok(!!st.badges['first-blood'], 'First Blood badge awarded');
  ok(st.streak.count === 1, 'streak = 1 after first solve');
  await p.reload(); await p.waitForFunction(() => window.Quest); await p.evaluate(HELPERS);
  ok(await hudXP(p) === 32, 'XP persists after reload');
  ok(await p.locator('.rq-item[data-id="w1-01"] .rq-option.is-correct').count() === 1, 'solved item shown as solved after reload');

  // shuffle: option order varies across loads
  const orders = new Set();
  for (let i = 0; i < 8; i++) { await p.reload(); await p.waitForFunction(() => window.Quest); await p.evaluate(HELPERS); orders.add(await p.evaluate(() => [...document.querySelectorAll('.rq-item[data-id="w1-03"] .rq-option')].map(b => b.dataset.i).join(''))); }
  // item w1-03 is unsolved → shuffled each load
  ok(orders.size >= 3, `option order is shuffled at run time (${orders.size} distinct orders in 8 loads)`);

  await p.evaluate(HELPERS);
  // finish the world: order + spot (wrong then right) + remaining items
  await p.evaluate(() => { for (const id of ['w1-03', 'w1-04', 'w1-05', 'w1-06']) { window.__solve(__item(id), false); } });
  st = await state(p); ok(!st.items['w1-05'].solved && !st.items['w1-06'].solved && !st.items['w1-04'].solved, 'wrong order / flags / number are rejected');
  await p.evaluate(() => { for (const id of ['w1-03', 'w1-04', 'w1-05', 'w1-06']) { window.__solve(__item(id), true); } });
  st = await state(p);
  ok(['w1-03', 'w1-04', 'w1-05', 'w1-06'].every(i => st.items[i].solved), 'correct answers accepted for mcq, num, order and spot');
  ok(st.items['w1-06'].boss && !!st.badges['clear-w1'], 'boss solved → World 1 cleared badge');
  ok(st.items['w1-06'].tries === 2 && (await hudXP(p)) > 100, 'boss XP bonus counted (' + (await hudXP(p)) + ' XP)');
  ok(p._errs.length === 0, 'world 1: no JS errors ' + p._errs.join());
  await p.close();

  // world 2 gate + map
  p = await open(ctx, 'world2_straight_line.html'); ok(!(await p.evaluate(() => document.body.classList.contains('rq-locked'))), 'World 2 unlocked after clearing World 1'); await p.close();
  p = await open(ctx, 'index.html'); ok(await p.locator('.rq-card.rq-cleared').count() === 1, 'map marks World 1 cleared'); 
  ok(await p.locator('#rq-badges .rq-badge.got').count() >= 3, 'badge shelf shows earned badges');

  // export / import / reset
  const [dl] = await Promise.all([p.waitForEvent('download'), p.click('#rq-export')]); const exp = path.join('/tmp/claude-0', 'rq-export.json'); await dl.saveAs(exp);
  const exported = JSON.parse(fs.readFileSync(exp, 'utf8')); ok(exported.v === 1 && Object.keys(exported.items).length >= 8, 'export produced a valid progress file');
  p.once('dialog', d => d.accept()); await p.click('#rq-reset'); await p.waitForFunction(() => window.Quest); await p.waitForTimeout(300);
  ok((await state(p)).streak.count === 0 && await hudXP(p) === 0, 'reset clears progress');
  await p.setInputFiles('#rq-import', exp); await p.waitForTimeout(600); await p.waitForFunction(() => window.Quest);
  ok((await hudXP(p)) > 100, 'import restores progress (' + (await hudXP(p)) + ' XP)');
  await ctx.close();

  // ── 5. streak logic with a mocked clock ──────────────────────────────────
  const days = ['2026-03-01', '2026-03-02', '2026-03-02', '2026-03-05'], want = [1, 2, 2, 1];
  ctx = await newCtx(); let got = [];
  const ids = ['w1-08', 'w1-01', 'w1-04', 'w1-07'];
  for (let i = 0; i < days.length; i++) { await ctx.clearCookies(); const pg = await ctx.newPage(); await pg.addInitScript(d => { window.RQ_NOW = d + 'T12:00:00'; }, days[i]); await pg.goto(url('world1_outcome_detective.html')); await pg.waitForFunction(() => window.Quest); await pg.evaluate(HELPERS); await pg.evaluate(id => { document.body.classList.remove('rq-locked'); window.__solve(__item(id), true); }, ids[i]); got.push((await state(pg)).streak.count); await pg.close(); }
  ok(JSON.stringify(got) === JSON.stringify(want), `streak: next-day +1, same-day unchanged, gap resets → ${got} (expected ${want})`);
  await ctx.close();

  // ── 6. post-test shows gain ──────────────────────────────────────────────
  ctx = await newCtx(); p = await open(ctx, 'pretest.html');
  await p.evaluate(() => { document.querySelectorAll('.rq-item').forEach((q, i) => window.__solve(q, i < 5)); [...document.querySelectorAll('.rq-big')].find(b => /Submit/.test(b.textContent)).click(); }); await p.close();
  p = await open(ctx, 'posttest.html');
  await p.evaluate(() => { document.querySelectorAll('.rq-item').forEach(q => window.__solve(q, true)); [...document.querySelectorAll('.rq-big')].find(b => /Submit/.test(b.textContent)).click(); });
  const gainTxt = await p.locator('.rq-gain').innerText(); ok(/25%.*100%/.test(gainTxt) && /\+75/.test(gainTxt), 'post-test shows pre → post gain: ' + gainTxt);
  st = await state(p); ok(!!st.badges.post && !!st.badges.gain, 'Growth Mindset and Big Gain badges awarded');
  await ctx.close();

  // ── 7. Region 1: own pre/post, gate, code items, graduate badge ─────────
  ctx = await newCtx(); p = await open(ctx, 'b1_first_script.html');
  ok(await p.evaluate(() => document.body.classList.contains('rq-locked')), 'Region 1 world b1 is locked until the Region 1 pre-test');
  await p.close(); p = await open(ctx, 'r1pretest.html');
  ok(await p.locator('.rq-item').count() === 10 && await p.locator('.rq-item[data-type="code"]').count() >= 2, 'Region 1 pre-test: 10 items incl. code tasks');
  await p.evaluate(() => { document.querySelectorAll('.rq-item').forEach((q, i) => window.__solve(q, i < 4)); [...document.querySelectorAll('.rq-big')].find(b => /Submit/.test(b.textContent)).click(); });
  st = await state(p); ok(st.tests.r1pre && st.tests.r1pre.pct === 40, 'Region 1 pre-test scored 4/10 (code items graded in test mode): ' + (st.tests.r1pre && st.tests.r1pre.pct));
  await p.close(); p = await open(ctx, 'b1_first_script.html');
  ok(!(await p.evaluate(() => document.body.classList.contains('rq-locked'))), 'b1 unlocked after the Region 1 pre-test');
  ok(await p.locator('.rq-read a').count() >= 1, 'world page shows Read first library links');
  await p.evaluate(() => document.querySelectorAll('.rq-item').forEach(q => window.__solve(q, true)));
  st = await state(p); ok(Object.keys(st.items).filter(k => k.startsWith('b1-') && st.items[k].solved).length === 9 && !!st.badges['clear-b1'], 'all 9 b1 items solvable (incl. code) → b1 cleared');
  await p.close(); p = await open(ctx, 'r1posttest.html');
  await p.evaluate(() => { document.querySelectorAll('.rq-item').forEach(q => window.__solve(q, true)); [...document.querySelectorAll('.rq-big')].find(b => /Submit/.test(b.textContent)).click(); });
  const g1 = await p.locator('.rq-gain').first().innerText(); ok(/40%.*100%/.test(g1) && /\+60/.test(g1), 'Region 1 post-test shows gain: ' + g1);
  st = await state(p); ok(!!st.badges.r1grad, 'Basics Graduate badge awarded at ≥ 70%');
  ok(p._errs.length === 0, 'Region 1 pages: no JS errors ' + p._errs.join(','));
  await ctx.close();

  await browser.close(); console.log(fails ? `\n${fails} FAILURES` : '\nALL QUEST E2E TESTS PASSED'); process.exit(fails ? 1 : 0);
})();
