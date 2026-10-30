// Usage: node counts-workshop/tests/quiz_all.js <rendered deck .html files...>   (set PLAYWRIGHT_PATH / CHROME_PATH if needed)
const { chromium } = require(process.env.PLAYWRIGHT_PATH || 'playwright');
const fs = require('fs');
(async () => {
  const files = process.argv.slice(2);
  const browser = await chromium.launch({ executablePath: process.env.CHROME_PATH || undefined, args: ['--no-sandbox'] });
  let totalFail = 0;
  for (const file of files) {
    const src = fs.readFileSync(file, 'utf8');
    const fails = []; const note = [];
    const divs = [...src.matchAll(/<div class="quiz-q"([^>]*)>/g)].map(m => m[1]);
    const attr = (a, n) => ((a.match(new RegExp(n + '="([^"]*)"')) || [])[1] || '');
    const dec = s => Buffer.from(s.replace(/&quot;/g, '"'), 'base64').toString('utf8');
    for (const a of divs) {
      const ex = dec(attr(a, 'data-explain')), show = dec(attr(a, 'data-show'));
      if (ex.length < 20) fails.push('explanation missing');
      // plain explanation text must not appear anywhere in the page source
      if (src.includes(ex.slice(0, 45))) fails.push('explanation leaked: ' + ex.slice(0, 40));
      const key = attr(a, 'data-hash') || attr(a, 'data-hashes');
      if (!key || (show.length >= 4 && key.includes(show))) fails.push('hash attr leaks answer');
    }
    const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
    const errs = []; page.on('pageerror', e => errs.push(String(e))); page.on('requestfailed', r => errs.push('REQFAIL ' + r.url().slice(0, 80)));
    await page.goto('file://' + file);
    await page.waitForFunction(() => window.Quiz && Reveal.isReady());
    const qs = page.locator('.quiz-q'); const n = await qs.count();
    if (n !== divs.length) fails.push(`count mismatch ${n} vs ${divs.length}`);
    if (n < 4 || n > 6) fails.push(`question count ${n} not in 4–6`);
    const go = async i => { await page.evaluate(i => { const s = document.querySelectorAll('.quiz-q')[i].closest('section'); const ix = Reveal.getIndices(s); Reveal.slide(ix.h, ix.v); }, i); await page.waitForTimeout(80); };
    let mcq = 0, fill = 0;
    for (let i = 0; i < n; i++) {
      await go(i); const q = qs.nth(i); const type = await q.getAttribute('data-type');
      if (type === 'mcq') {
        mcq++; const opts = q.locator('.quiz-option'); const k = await opts.count(); let corrects = 0;
        for (let j = 0; j < k; j++) { const o = opts.nth(j); if (await o.isDisabled()) continue; await o.click(); if ((await o.getAttribute('class')).includes('is-correct')) corrects++; }
        if (corrects !== 1) fails.push(`Q${i + 1} mcq has ${corrects} correct options`);
      } else {
        fill++; await q.locator('.quiz-btn-ghost').click();
        const txt = await q.locator('.quiz-feedback').innerText(); const m = txt.match(/Answer:\s*(.+?)\.\s/);
        if (!m) { fails.push(`Q${i + 1} no revealed answer: ${txt.slice(0, 50)}`); continue; }
        const inp = q.locator('.quiz-input'); await inp.fill('  ' + m[1].toUpperCase() + '  '); await inp.press('Enter');
        if (!(await q.locator('.quiz-feedback').getAttribute('class')).includes('is-correct')) fails.push(`Q${i + 1} revealed answer "${m[1]}" not accepted`);
        await inp.fill('zzz-wrong'); await inp.press('Enter');
        if (!(await q.locator('.quiz-feedback').getAttribute('class')).includes('is-wrong')) fails.push(`Q${i + 1} wrong text accepted`);
      }
    }
    const score = (await page.locator('.quiz-score').first().innerText()).trim();
    if (!/^\d+ \/ \d+$/.test(score)) fails.push('score format ' + score);
    if (errs.length) fails.push('browser errors: ' + JSON.stringify(errs));
    console.log(`${fails.length ? 'FAIL' : 'PASS'}  ${file.split('/').pop()}  questions=${n} (mcq ${mcq}, fill ${fill}) score="${score}" ${fails.join(' | ')}`);
    totalFail += fails.length; await page.close();
  }
  await browser.close(); process.exit(totalFail ? 1 : 0);
})();
