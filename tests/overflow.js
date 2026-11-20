// Shared slide-overflow check (base decks and workshops). Usage: node tests/overflow.js <deck .html files...>
// A slide marked .scrollable is reachable by scrolling: it is listed as SCROLL, not counted as overflow.
// Exit status 1 if any non-scrollable slide overflows.
const { chromium } = require(process.env.PLAYWRIGHT_PATH || 'playwright');
let failed = 0;
(async () => {
  const browser = await chromium.launch({ executablePath: process.env.CHROME_PATH || undefined, args: ['--no-sandbox'] });
  for (const file of process.argv.slice(2)) {
    const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
    await page.goto('file://' + file);
    await page.waitForFunction(() => window.Reveal && Reveal.isReady());
    await page.waitForTimeout(1200);
    await page.evaluate(() => Reveal.configure({ transition: 'none', backgroundTransition: 'none', fragments: false }));
    const n = await page.evaluate(() => Reveal.getTotalSlides());
    const bad = [], scrolled = [];
    for (let i = 0; i < n; i++) {
      await page.waitForTimeout(120);
      const r = await page.evaluate(() => {
        const s = Reveal.getCurrentSlide(); const sc = Reveal.getScale();
        const top = document.querySelector('.slides').getBoundingClientRect();
        let maxB = 0, el = '';
        s.querySelectorAll('*').forEach(e => { const b = e.getBoundingClientRect(); if (b.height > 0 && b.width > 0 && getComputedStyle(e).visibility !== 'hidden' && getComputedStyle(e).display !== 'none') { const bottom = (b.bottom - top.top) / sc; if (bottom > maxB && b.height < 2000) { maxB = bottom; el = e.tagName + '.' + (e.className || '').toString().slice(0, 30); } } });
        const h = s.querySelector('h1,h2'); return { maxB: Math.round(maxB), el, title: h ? h.innerText.slice(0, 50) : '', scroll: s.classList.contains('scrollable') };
      });
      // Reveal slide area is 720 high; flag content running below ~705
      if (r.maxB > 705) (r.scroll ? scrolled : bad).push(`#${i + 1} "${r.title}" bottom=${r.maxB} (${r.el})`);
      await page.evaluate(() => Reveal.next());
    }
    console.log(`${bad.length ? 'WARN' : 'OK  '} ${file.split('/').pop()} (${n} slides)` + (bad.length ? '\n   ' + bad.join('\n   ') : '') + (scrolled.length ? '\n   SCROLL ' + scrolled.join('\n   SCROLL ') : ''));
    failed += bad.length;
    await page.close();
  }
  await browser.close();
  process.exit(failed ? 1 : 0);
})();
