/* ═══════════════════════════════════════════════════════════════════════
 * deck-pptx.js — a custom deck as a PowerPoint file, in the browser (decided 2026-11-28: open to all).
 * Used by the Custom decks page (/decks). PptxGenJS 3.12.0 is loaded on first use.
 *
 * Each slide is fetched as the player fetches it (through the gate: a slide the user may not open is left
 * out and listed), then turned into editable PowerPoint pieces:
 *   title, text, bullets, callout boxes -> text boxes        tables -> tables
 *   code and printed output             -> monospaced text   charts -> pictures (the decks hold them as images)
 *   quizzes -> question and options, answer in the speaker notes; your notes -> speaker notes; own slides -> as made
 * For charts as editable shapes, facilitators can still use tools/export_pptx.R.
 * ═════════════════════════════════════════════════════════════════════ */
(function () {
  'use strict';
  const LIB = 'https://cdn.jsdelivr.net/npm/pptxgenjs@3.12.0/dist/pptxgen.bundle.js';
  const W = 13.333, H = 7.5, M = 0.5, TOP = 1.25, BOTTOM = H - 0.35;
  const C = { ink: '2C3E50', muted: '5F6B76', code: 'F4F6F8', key: 'EAF2F8', warn: 'FDEDEC', eq: 'FEF9E7', line: 'CFD8DC' };
  const FONTS = { deck: 'Georgia', sans: 'Source Sans 3', lato: 'Lato', merriweather: 'Merriweather' };
  const MONO = 'Consolas';
  const SIZE = { S: 14, M: 18, L: 22, XL: 27 };

  function loadLib() {
    if (window.PptxGenJS) return Promise.resolve(window.PptxGenJS);
    return new Promise((res, rej) => {
      const s = document.createElement('script'); s.src = LIB; s.onload = () => res(window.PptxGenJS); s.onerror = () => rej(new Error('the PowerPoint library could not be loaded'));
      document.head.append(s);
    });
  }
  // reveal.js lazy-loads images: the picture is in data-src until the slide is shown
  const imgSrc = (img) => img.getAttribute('src') || img.getAttribute('data-src') || '';
  const clean = (t) => String(t || '').replace(/\s+/g, ' ').trim();
  const b64 = (s) => { try { return decodeURIComponent(escape(atob(s))); } catch (e) { return ''; } };

  // ── A slide's HTML -> pieces ────────────────────────────────────────
  // piece: {kind:'text', paras:[{text, bullet, level}], fill?} | {kind:'code'|'out', text} | {kind:'table', rows} | {kind:'img', src, w, h}
  function pieces(section, notesOut) {
    const out = [];
    const textOf = (n) => clean(n.textContent);
    const walk = (node, fill) => {
      for (const n of node.children) {
        const tag = n.tagName.toLowerCase();
        const cls = n.classList;
        if (/^h[12]$/.test(tag) || tag === 'aside' || cls.contains('st-own-badge') || cls.contains('quiz-score') || tag === 'script' || tag === 'style') continue;
        if (cls.contains('quiz-q')) {
          const q = n.cloneNode(true); q.querySelectorAll('ul,ol,button,.quiz-ui,input').forEach((x) => x.remove());
          const opts = [...n.querySelectorAll('li')].map((li, i) => ({ text: `${String.fromCharCode(65 + i)}.  ${textOf(li)}` }));
          out.push({ kind: 'text', paras: [{ text: textOf(q) }, ...opts] });
          const ans = b64(n.dataset.show || ''); const why = b64(n.dataset.explain || '');
          if (ans || why) notesOut.push(`Answer: ${clean(ans)}${why ? '\n' + clean(why) : ''}`);
          continue;
        }
        if (cls.contains('cell')) {
          for (const c of n.querySelectorAll('.cell-code pre, .cell-output pre, .cell-output-display img, .cell-output-display table, .st-saved-out pre, .st-own-code pre'))
            if (c.tagName === 'PRE') out.push({ kind: c.closest('.cell-code, .st-own-code') ? 'code' : 'out', text: c.textContent.replace(/\n$/, '') });
            else if (c.tagName === 'IMG') out.push({ kind: 'img', src: imgSrc(c), w: c.naturalWidth, h: c.naturalHeight });
            else out.push({ kind: 'table', rows: rowsOf(c) });
          continue;
        }
        if (tag === 'p') { const t = textOf(n); if (t) out.push({ kind: 'text', paras: [{ text: t }], fill }); continue; }
        if (tag === 'ul' || tag === 'ol') { out.push({ kind: 'text', paras: listItems(n, 0, tag === 'ol'), fill }); continue; }
        if (tag === 'table') { out.push({ kind: 'table', rows: rowsOf(n) }); continue; }
        if (tag === 'pre') { out.push({ kind: 'code', text: n.textContent.replace(/\n$/, '') }); continue; }
        if (tag === 'img') { out.push({ kind: 'img', src: imgSrc(n), w: n.naturalWidth, h: n.naturalHeight }); continue; }
        if (tag === 'blockquote') { const t = textOf(n); if (t) out.push({ kind: 'text', paras: [{ text: t }], fill: C.eq }); continue; }
        const box = cls.contains('key') ? C.key : cls.contains('warn') ? C.warn : cls.contains('eq') ? C.eq : /callout/.test(n.className) ? C.key : fill;
        walk(n, box);
      }
    };
    const listItems = (list, level, numbered) => {
      const paras = [];
      [...list.children].forEach((li, i) => {
        const own = li.cloneNode(true); own.querySelectorAll('ul,ol').forEach((x) => x.remove());
        paras.push({ text: (numbered ? `${i + 1}. ` : '') + clean(own.textContent), bullet: !numbered, level });
        li.querySelectorAll(':scope > ul, :scope > ol').forEach((sub) => paras.push(...listItems(sub, level + 1, sub.tagName === 'OL')));
      });
      return paras;
    };
    const rowsOf = (t) => [...t.querySelectorAll('tr')].slice(0, 25).map((tr) => [...tr.children].slice(0, 10).map((c) => clean(c.textContent)));
    walk(section);
    return out;
  }

  // ── Placing pieces on slides (continuation slides when full) ────────
  async function imageSize(src) {
    return new Promise((res) => { const i = new Image(); i.onload = () => res([i.naturalWidth, i.naturalHeight]); i.onerror = () => res([900, 460]); i.src = src; });
  }
  async function addSlides(pptx, title, list, notes, font) {
    let slide; let y = TOP;   // always call room() BEFORE slide.addX(): it may replace \`slide\`
    const newSlide = (cont) => {
      slide = pptx.addSlide();
      slide.addText(cont ? `${title} (continued)` : title, { x: M, y: 0.3, w: W - 2 * M, h: 0.8, fontFace: font, fontSize: 28, bold: true, color: C.ink, valign: 'middle' });
      if (notes.length) slide.addNotes(notes.join('\n\n'));
      y = TOP;
    };
    newSlide(false);
    const room = (h) => { if (y + h > BOTTOM && y > TOP) newSlide(true); const top = y; y += Math.min(h, BOTTOM - TOP) + 0.12; return top; };
    for (const p of list) {
      if (p.kind === 'text') {
        const size = p.size || 18;
        const chars = (W - 2 * M) * 72 / (size * 0.5);
        const lines = p.paras.reduce((n, q) => n + Math.max(1, Math.ceil(q.text.length / chars)), 0);
        const h = Math.min(lines * size / 72 * 1.4 + 0.2, BOTTOM - TOP);
        const top = room(h);
        slide.addText(p.paras.map((q) => ({ text: q.text, options: { bullet: q.bullet ? { indent: 18 } : false, indentLevel: q.level || 0, breakLine: true } })),
          { x: M, y: top, w: W - 2 * M, h, fontFace: font, fontSize: size, color: C.ink, valign: 'top', align: p.align || 'left',
            fill: p.fill ? { color: p.fill } : undefined, margin: 6 });
      } else if (p.kind === 'code' || p.kind === 'out') {
        let ln = p.text.split('\n'); if (ln.length > 22) ln = [...ln.slice(0, 21), '…'];
        const size = p.kind === 'code' ? 13 : 12;
        const h = ln.length * size / 72 * 1.25 + 0.15;
        const top = room(h);
        slide.addText(ln.join('\n'), { x: M, y: top, w: W - 2 * M, h, fontFace: MONO, fontSize: size, color: '1B2631', valign: 'top',
          fill: p.kind === 'code' ? { color: C.code } : undefined, margin: 6 });
      } else if (p.kind === 'table' && p.rows.length) {
        const h = 0.38 * p.rows.length + 0.1;
        const top = room(h);
        slide.addTable(p.rows.map((r, i) => r.map((c) => ({ text: c, options: { bold: i === 0, fontSize: 12, fontFace: font === FONTS.deck ? 'Calibri' : font } }))),
          { x: M, y: top, w: W - 2 * M, border: { type: 'solid', pt: 0.5, color: C.line }, autoPage: false });
      } else if (p.kind === 'img' && p.src) {
        const [iw, ih] = p.w && p.h ? [p.w, p.h] : await imageSize(p.src);
        let w = W - 2 * M - 1.5; let h = w * ih / iw;
        if (h > 4.4) { h = 4.4; w = h * iw / ih; }
        const left = BOTTOM - y;                       // shrink to the room left on this slide, down to a readable 2 in
        if (h > left && left >= 2.0) { h = left - 0.05; w = h * iw / ih; }
        const top = room(h);   // first: it may start a continuation slide
        slide.addImage({ data: p.src.startsWith('data:') ? p.src : undefined, path: p.src.startsWith('data:') ? undefined : p.src, x: (W - w) / 2, y: top, w, h });
      }
    }
  }

  // An own slide (JSON, plan §5.2) -> pieces
  function ownPieces(body) {
    const list = [];
    for (const b of body.blocks || []) {
      const size = SIZE[b.size] || 18;
      const align = b.align || body.align || 'left';
      if (b.type === 'text' || b.type === 'box') {
        const paras = String(b.markdown || '').split('\n').filter((l) => l.trim()).map((l) => {
          const m = l.match(/^\s*([-*]|\d+[.)]) (.*)/);
          return { text: (m ? m[2] : l).replace(/\*\*|__|`/g, '').replace(/(^|[^*])\*([^*]+)\*/g, '$1$2').replace(/\[([^\]]+)\]\([^)]*\)/g, '$1'), bullet: !!(m && /[-*]/.test(m[1])) };
        });
        if (paras.length) list.push({ kind: 'text', paras, size, align, fill: b.type === 'box' ? ({ key: C.key, warn: C.warn, eq: C.eq }[b.kind] || C.key) : undefined });
      } else if (b.type === 'table' && Array.isArray(b.rows)) list.push({ kind: 'table', rows: b.rows });
      else if (b.type === 'code') {
        if (b.showCode !== false) list.push({ kind: 'code', text: b.code || '' });
        if (b.output && b.output.saved) list.push({ kind: 'out', text: b.output.saved });
      }
    }
    return list;
  }

  /**
   * deck = { title, items, own: {id: body} }, cat = slides.json decks, notes = {"<ref>": {text}}.
   * Returns { file, skipped: [titles] }.
   */
  async function build(deck, cat, notes, progress) {
    const PptxGenJS = await loadLib();
    const pptx = new PptxGenJS();
    pptx.layout = 'LAYOUT_WIDE'; pptx.title = deck.title; pptx.company = 'Medical Statistics in R';
    const byRef = {}; for (const d of cat) for (const s of d.slides) byRef[`${d.workshop}/${d.deck}#${s.id}`] = { d, s };
    const pages = new Map();
    const fetchDeck = (path) => {
      if (!pages.has(path)) pages.set(path, (async () => {
        const r = await fetch(path, { credentials: 'same-origin' });
        if (!r.ok || /\/account/.test(new URL(r.url).pathname) || !(r.headers.get('content-type') || '').includes('html')) return null;
        return new DOMParser().parseFromString(await r.text(), 'text/html');
      })());
      return pages.get(path);
    };
    const t = pptx.addSlide();
    t.addText(deck.title, { x: M, y: 2.6, w: W - 2 * M, h: 1.2, fontFace: FONTS.deck, fontSize: 40, bold: true, color: C.ink, align: 'center' });
    t.addText(`${deck.items.length} slides · Medical Statistics in R`, { x: M, y: 3.9, w: W - 2 * M, h: 0.6, fontSize: 18, color: C.muted, align: 'center' });
    const skipped = [];
    let k = 0;
    for (const item of deck.items) {
      k++; if (progress) progress(k, deck.items.length);
      if (item.type === 'own') {
        const body = deck.own && deck.own[item.id];
        if (!body) continue;
        await addSlides(pptx, body.title || '', ownPieces(body), body.notes ? [body.notes] : [], FONTS[body.font] || FONTS.deck);
        continue;
      }
      const hit = byRef[item.ref];
      if (!hit) continue;
      const doc = await fetchDeck(hit.d.path);
      const id = item.ref.split('#')[1];
      const sec = doc && doc.getElementById(id);
      if (!sec) { skipped.push(hit.s.title); continue; }
      const extra = []; const cont = doc.getElementById(id + '-output');
      const list = pieces(sec, extra);
      if (cont) list.push(...pieces(cont, extra));
      const n = notes[item.ref] ? [notes[item.ref].text] : [];
      await addSlides(pptx, hit.s.title, list, [...n, ...extra], FONTS.deck);
    }
    const name = (deck.title || 'deck').replace(/[^\w-]+/g, '_') + '.pptx';
    await pptx.writeFile({ fileName: name });
    return { file: name, skipped };
  }
  window.DeckPptx = { build, pieces };
})();
