/* ═══════════════════════════════════════════════════════════════════════
 * slide-tools.js — Edit mode, notes and own slides for workshop decks (CUSTOM_DECKS_PLAN.md)
 * Master copy: regression-workshop/assets/ (scripts/sync_workshop_assets.sh copies it to every workshop;
 * cloud/stage.mjs also publishes it as /st/slide-tools.js for the custom-deck builder and player).
 *
 * View (default): the deck is exactly as rendered. Your notes and slides show if you have any.
 * Edit (✎ button, top right; remembered):
 *   - every R chunk becomes editable with Run / Reset. Run starts webR (R in the browser) once, installs
 *     the deck's packages, runs its hidden setup and the chunks before this one, then the edited code.
 *     What a deck needs is in <deck>.webr.json (scripts/webr_manifests.mjs).
 *   - a note panel for the current slide (C2);
 *   - "＋ Add slide after this": your own slide, shown only to you (C4).
 * Notes and own slides are saved to the account when signed in ('ws-account' flag), otherwise on this device.
 * ═════════════════════════════════════════════════════════════════════ */
(function () {
  'use strict';
  if (window.SlideTools) return;
  const WEBR_VERSION = '0.6.1';
  const WEBR_CDN = `https://webr.r-wasm.org/v${WEBR_VERSION}/`;
  const FIG = { width: 900, height: 460 };          // the decks' fig-width 9 × fig-height 4.6 at 100 dpi
  const BASE_PKGS = new Set('base compiler datasets graphics grDevices grid methods parallel splines stats stats4 tcltk tools utils'.split(' '));
  const store = {
    get(k) { try { return localStorage.getItem(k); } catch (e) { return null; } },
    set(k, v) { try { localStorage.setItem(k, v); } catch (e) { /* private mode */ } },
    json(k, fallback) { try { return JSON.parse(this.get(k)) || fallback; } catch (e) { return fallback; } },
  };
  const online = /^https?:$/.test(location.protocol);
  const signedIn = () => online && !!store.get('ws-account');

  const ST = window.SlideTools = { editing: false, R: { webR: null, deck: null, ranUpTo: -1 }, notes: null, own: {}, hooks: [] };

  function el(tag, attrs, ...kids) {
    const e = document.createElement(tag);
    for (const [k, v] of Object.entries(attrs || {})) {
      if (v === undefined || v === null || v === false) continue;
      if (k === 'class') e.className = v; else if (k.startsWith('on')) e.addEventListener(k.slice(2), v); else e.setAttribute(k, v === true ? '' : v);
    }
    for (const c of kids) if (c !== null && c !== undefined) e.append(c);
    return e;
  }
  ST.el = el;
  function randomId() {
    const b = crypto.getRandomValues(new Uint8Array(15));
    return btoa(String.fromCharCode(...b)).replace(/\+/g, '-').replace(/\//g, '_');
  }

  // ── Which deck a slide or cell came from ─────────────────────────────
  // In a deck: this page. In the custom-deck player: each section carries data-st-src="/<track>/<workshop>/<deck>.html".
  const srcOf = (node) => { const s = node && node.closest && node.closest('section[data-st-src]'); return s ? s.dataset.stSrc : location.pathname; };
  // Cloudflare Pages serves "deck.html" at "deck" (no extension): accept both.
  const refOfSrc = (src) => { const m = (src || '').match(/\/([a-z0-9-]+-workshop)\/(s\d\w*)(?:\.html)?$/); return m ? `${m[1]}/${m[2]}` : null; };
  ST.deckRef = refOfSrc(location.pathname);

  // ── Manifests ────────────────────────────────────────────────────────
  const manifests = new Map();
  function manifestFor(src) {
    if (!manifests.has(src)) {
      manifests.set(src, (async () => {
        if (!online || !refOfSrc(src)) return null;
        try {
          const r = await fetch(src.replace(/(\.html)?$/, '.webr.json'), { credentials: 'same-origin' });
          if (r.ok && (r.headers.get('content-type') || '').includes('json')) return await r.json();
        } catch (e) { /* offline */ }
        return null;
      })());
    }
    return manifests.get(src);
  }

  // ── Cells: one per visible R chunk (or an own slide's code block) ───
  function findCells(root) {
    const cells = [...(root || document).querySelectorAll('.reveal .slides div.cell')].filter((c) => c.querySelector('.cell-code') || c.dataset.stCode !== undefined);
    const count = {};
    for (const c of cells) {
      if (c.dataset.stCode !== undefined) continue;          // own-slide code: no position in a deck
      const src = srcOf(c);
      count[src] = count[src] || 0;
      if (c.dataset.stK === undefined) c.dataset.stK = String(count[src]);
      count[src] = Number(c.dataset.stK) + 1;
    }
    return cells;
  }
  const originalCode = (cell) => cell.dataset.stCode !== undefined
    ? cell.dataset.stCode
    : [...cell.querySelectorAll('.cell-code code')].map((c) => c.textContent).join('\n');

  // ── webR ─────────────────────────────────────────────────────────────
  function setStatus(msg) {
    document.querySelectorAll('.st-status').forEach((s) => { s.textContent = msg; s.hidden = !msg; });
  }
  async function webRBase() {
    if (online) { try { const r = await fetch('/webr/webr.mjs', { method: 'HEAD' }); if (r.ok) return '/webr/'; } catch (e) { /* not self-hosted */ } }
    return WEBR_CDN;
  }
  let starting = null;
  function startR() {
    if (starting) return starting;
    starting = (async () => {
      const base = await webRBase();
      setStatus('Starting R in your browser (about 20 MB the first time)…');
      const { WebR, ChannelType } = await import(base + 'webr.mjs');
      const webR = new WebR({ baseUrl: base, channelType: ChannelType.PostMessage });
      await webR.init();
      ST.R.webR = webR;
      setStatus('');
      return webR;
    })().catch((e) => { starting = null; setStatus(''); throw e; });
    return starting;
  }
  ST.startR = startR;
  const installed = new Set();
  async function install(pkgs) {
    const todo = pkgs.filter((p) => !installed.has(p) && !BASE_PKGS.has(p));
    for (const [i, pkg] of todo.entries()) {
      setStatus(`Installing R packages (${i + 1}/${todo.length}): ${pkg}…`);
      await ST.R.webR.installPackages([pkg], { quiet: true });
      installed.add(pkg);
    }
  }
  function packagesIn(code) {
    const s = new Set();
    for (const m of code.matchAll(/\b(?:library|require|requireNamespace)\(\s*["']?([A-Za-z][\w.]*)["']?/g)) s.add(m[1]);
    for (const m of code.matchAll(/\b([A-Za-z][\w.]*)::/g)) s.add(m[1]);
    return [...s];
  }
  async function capture(code) {
    const shelter = await new ST.R.webR.Shelter();
    try {
      return await shelter.captureR(code, { withAutoprint: true, captureStreams: true, captureConditions: false,
        captureGraphics: { width: FIG.width, height: FIG.height } });
    } finally { shelter.purge(); }
  }
  // Load a deck's setup into the R session (once; again only when switching to another deck's slides).
  async function prepareDeck(src, m) {
    if (ST.R.deck === src) return;
    const webR = ST.R.webR;
    await install(m.packages);
    await webR.FS.mkdir('assets').catch(() => {});
    for (const [path, text] of Object.entries(m.files)) await webR.FS.writeFile(path, new TextEncoder().encode(text));
    for (const d of m.data) {
      setStatus(`Loading data: ${d}`);
      const parts = d.split('/');
      for (let k = 1; k < parts.length; k++) await webR.FS.mkdir(parts.slice(0, k).join('/')).catch(() => {});
      const r = await fetch(new URL('../' + d, location.origin + src), { credentials: 'same-origin' });
      if (!r.ok) throw new Error(`could not load ${d} (${r.status})`);
      await webR.FS.writeFile(d, new Uint8Array(await r.arrayBuffer()));
    }
    setStatus('Running the deck setup…');
    if (m.setup) await capture(m.setup);
    ST.R.deck = src; ST.R.ranUpTo = -1;
  }
  const chunkIndex = (m, k) => { let seen = -1; for (let i = 0; i < m.chunks.length; i++) if (m.chunks[i].visible && ++seen === k) return i; return -1; };

  async function run(cell) {
    const out = cell.querySelector('.st-out');
    const box = cell.querySelector('.st-code');
    const code = box ? box.value : originalCode(cell);
    out.replaceChildren(el('div', { class: 'st-running' }, 'Running…'));
    try {
      await startR();
      const src = srcOf(cell);
      const m = cell.dataset.stCode === undefined ? await manifestFor(src) : null;
      if (m) {
        await prepareDeck(src, m);
        const target = chunkIndex(m, Number(cell.dataset.stK));
        if (target < 0) throw new Error('this chunk is not in the deck manifest; reload after the site is rebuilt');
        // Bring R up to this chunk: every chunk before it in the deck (hidden ones too), in order, once.
        for (let i = ST.R.ranUpTo + 1; i < target; i++) {
          if (!m.chunks[i].eval) continue;
          setStatus('Running the slides before this one…');
          await capture(m.chunks[i].code).catch(() => {});
        }
        ST.R.ranUpTo = Math.max(ST.R.ranUpTo, target);
      } else {
        await install(packagesIn(code));
      }
      setStatus('');
      show(out, await capture(code));
    } catch (e) {
      setStatus('');
      out.replaceChildren(el('pre', { class: 'st-err' }, String((e && e.message) || e)));
    }
    cell.dispatchEvent(new CustomEvent('st-ran', { bubbles: true }));
  }
  ST.run = run;

  function show(out, res) {
    const kids = []; let text = '';
    const flush = () => { if (text) { kids.push(el('pre', { class: 'st-text' }, text.replace(/\n$/, ''))); text = ''; } };
    for (const o of res.output) {
      if (o.type === 'stdout') text += o.data + '\n';
      else if (o.type === 'stderr') { flush(); kids.push(el('pre', { class: 'st-msg' }, o.data)); }
    }
    flush();
    for (const img of res.images) {
      const c = el('canvas', { class: 'st-plot', width: img.width, height: img.height });
      c.getContext('2d').drawImage(img, 0, 0);
      kids.push(c);
    }
    if (!kids.length) kids.push(el('div', { class: 'st-none' }, 'Done (no output).'));
    out.replaceChildren(...kids);
  }

  // ── Edit mode on / off ───────────────────────────────────────────────
  function editCell(cell) {
    if (cell.querySelector('.st-box')) return;
    const code = el('textarea', { class: 'st-code', spellcheck: 'false', 'aria-label': 'R code (editable)' });
    code.value = originalCode(cell);
    const fit = () => { code.rows = Math.min(14, code.value.split('\n').length + 1); };
    fit();
    code.addEventListener('input', fit);
    code.addEventListener('keydown', (e) => {
      e.stopPropagation();
      if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') { e.preventDefault(); run(cell); }
      if (e.key === 'Tab') { e.preventDefault(); code.setRangeText('  ', code.selectionStart, code.selectionEnd, 'end'); }
    });
    const runBtn = el('button', { class: 'st-run', type: 'button', title: 'Run in your browser (Ctrl+Enter)', onclick: () => run(cell) }, '▶ Run');
    if (!online) { runBtn.disabled = true; runBtn.title = 'Open this deck from the website to run code'; }
    const bar = el('div', { class: 'st-bar' }, runBtn,
      el('button', { class: 'st-reset', type: 'button', title: 'Back to the original code',
        onclick: () => { code.value = originalCode(cell); fit(); cell.querySelector('.st-out').replaceChildren(); } }, '↺ Reset'),
      el('span', { class: 'st-status', hidden: true }, ''));
    cell.append(el('div', { class: 'st-box' }, bar, code, el('div', { class: 'st-out', 'aria-live': 'polite' })));
    cell.classList.add('st-editing');
  }
  function enterEdit() {
    findCells().forEach(editCell);
    document.documentElement.classList.add('st-edit-on');
    ST.editing = true;
    ST.hooks.forEach((h) => h(true));
  }
  function leaveEdit() {
    document.querySelectorAll('.st-box').forEach((b) => b.remove());
    document.querySelectorAll('.st-editing').forEach((c) => c.classList.remove('st-editing'));
    document.documentElement.classList.remove('st-edit-on');
    ST.editing = false;
    ST.hooks.forEach((h) => h(false));
  }
  let btn = null;
  function toggle() {
    if (ST.editing) leaveEdit(); else enterEdit();
    store.set('st-edit', ST.editing ? '1' : '0');
    btn.setAttribute('aria-pressed', String(ST.editing));
    btn.textContent = ST.editing ? '✎ Editing' : '✎ Edit';
    if (window.Reveal && Reveal.layout) Reveal.layout();
  }
  ST.toggle = toggle;

  // ── Current slide's stable reference ─────────────────────────────────
  function currentRef() {
    const sec = window.Reveal && Reveal.getCurrentSlide();
    if (!sec || !sec.id || sec.dataset.stOwn !== undefined || sec.classList.contains('st-locked')) return null;
    const deck = refOfSrc(srcOf(sec));
    return deck ? `${deck}#${(sec.dataset.stId || sec.id).replace(/-output$/, '')}` : null;
  }
  ST.currentRef = currentRef;

  // ── Notes (C2): { "<workshop>/<deck>#<id>": { text, ts } } ──────────
  ST.mode = () => (signedIn() ? 'account' : 'device');
  async function loadNotes() {
    if (ST.notes) return ST.notes;
    ST.notes = {};
    if (ST.mode() === 'account') {
      try {
        const q = ST.deckRef ? '?deck=' + encodeURIComponent(ST.deckRef) : '';
        const r = await fetch('/api/notes' + q, { credentials: 'same-origin' });
        if (r.ok) {
          for (const [k, v] of Object.entries((await r.json()).notes)) ST.notes[ST.deckRef ? `${ST.deckRef}#${k}` : k] = v;
          return ST.notes;
        }
      } catch (e) { /* fall back to this device */ }
    }
    Object.assign(ST.notes, store.json('st-notes', {}));
    return ST.notes;
  }
  ST.loadNotes = loadNotes;
  let saveTimer = null;
  function saveNote(ref, text) {
    if (text.trim()) ST.notes[ref] = { text, ts: Date.now() }; else delete ST.notes[ref];
    noteStatus('Saving…');
    clearTimeout(saveTimer);
    saveTimer = setTimeout(async () => {
      if (ST.mode() === 'account') {
        try {
          const r = await fetch('/api/notes', { method: 'PUT', credentials: 'same-origin', headers: { 'content-type': 'application/json' },
            body: JSON.stringify({ slide: ref, text }) });
          noteStatus(r.ok ? 'Saved to your account' : 'Not saved: ' + ((await r.json().catch(() => ({}))).error || r.status));
        } catch (e) { noteStatus('Not saved: offline'); }
      } else {
        const all = store.json('st-notes', {});
        if (text.trim()) all[ref] = ST.notes[ref]; else delete all[ref];
        store.set('st-notes', JSON.stringify(all));
        noteStatus('Saved on this device' + (online ? ' · sign in to keep notes on every device' : ''));
      }
    }, 1000);
  }
  function noteStatus(t) { const s = document.querySelector('.st-note-status'); if (s) s.textContent = t; }
  const panel = el('aside', { class: 'st-notes', hidden: true, 'aria-label': 'Your note on this slide' });
  function renderNote() {
    const ref = currentRef();
    const note = ref && ST.notes && ST.notes[ref];
    if (ST.editing && ref) {
      panel.hidden = false; panel.className = 'st-notes st-notes-edit';
      const ta = el('textarea', { class: 'st-note-text', 'aria-label': 'Your note on this slide', placeholder: 'Your note on this slide…' });
      ta.value = note ? note.text : '';
      ta.addEventListener('input', () => saveNote(ref, ta.value));
      ta.addEventListener('keydown', (e) => e.stopPropagation());
      panel.replaceChildren(el('div', { class: 'st-note-head' }, '📝 My note'), ta, el('div', { class: 'st-note-status' }, ''));
    } else if (note) {
      panel.hidden = false; panel.className = 'st-notes st-notes-view';
      panel.replaceChildren(el('div', { class: 'st-note-head' }, '📝 My note'), el('div', { class: 'st-note-read' }, note.text));
    } else panel.hidden = true;
    renderSlideActions();
  }
  ST.renderNote = renderNote;

  // ── Own slides (C4): rendering ───────────────────────────────────────
  // Text is Markdown-lite, escaped first, so a shared slide can never inject HTML.
  const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  function inline(s) {
    return esc(s)
      .replace(/`([^`]+)`/g, '<code>$1</code>')
      .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
      .replace(/__([^_]+)__/g, '<u>$1</u>')
      .replace(/(^|[^*])\*([^*]+)\*/g, '$1<em>$2</em>')
      .replace(/\[([^\]]+)\]\(((?:https?:\/\/|\/)[^\s)"]+)\)/g, (m, t, u) => `<a href="${u}" target="_blank" rel="noopener noreferrer">${t}</a>`);
  }
  function md(src) {
    const out = []; let list = null;
    const close = () => { if (list) { out.push(`</${list}>`); list = null; } };
    for (const line of String(src || '').split('\n')) {
      const b = line.match(/^\s*[-*] (.*)/); const n = line.match(/^\s*\d+[.)] (.*)/);
      if (b || n) {
        const kind = b ? 'ul' : 'ol';
        if (list !== kind) { close(); out.push(`<${kind}>`); list = kind; }
        out.push(`<li>${inline((b || n)[1])}</li>`);
      } else if (!line.trim()) close();
      else { close(); out.push(`<p>${inline(line)}</p>`); }
    }
    close();
    return out.join('');
  }
  ST.md = md;
  const SIZES = ['S', 'M', 'L', 'XL'];
  const FONTS = { deck: 'Deck default', sans: 'Source Sans 3', lato: 'Lato', merriweather: 'Merriweather' };
  const LAYOUTS = { title: 'Title only', text: 'Title + text', 'two-col': 'Two columns', 'code-output': 'Code + output', table: 'Table', section: 'Section break' };
  const pick = (v, allowed, d) => (allowed.includes(v) ? v : d);
  let fontsLoaded = false;
  function needFonts(font) {
    if (fontsLoaded || font === 'deck' || !online) return;
    fontsLoaded = true;
    document.head.append(el('link', { rel: 'stylesheet', href: 'https://fonts.googleapis.com/css2?family=Lato:wght@400;700&family=Merriweather:wght@400;700&family=Source+Sans+3:wght@400;700&display=swap' }));
  }
  function renderBlock(b) {
    const size = pick(b.size, SIZES, 'M');
    const align = b.align ? ` st-align-${pick(b.align, ['left', 'center', 'right', 'justify'], 'left')}` : '';
    if (b.type === 'text') { const d = el('div', { class: `st-blk st-size-${size}${align}` }); d.innerHTML = md(b.markdown); return d; }
    if (b.type === 'box') {
      const kind = pick(b.kind, ['key', 'warn', 'eq'], 'key');
      const d = el('div', { class: `${kind} st-blk st-size-${size}${align}` }); d.innerHTML = md(b.markdown); return d;
    }
    if (b.type === 'table') {
      const rows = Array.isArray(b.rows) ? b.rows.slice(0, 30) : [];
      const t = el('table', { class: `st-blk st-table st-size-${size}` });
      rows.forEach((r, i) => {
        const tr = el('tr');
        (Array.isArray(r) ? r.slice(0, 10) : []).forEach((c, j) => {
          const td = el(i === 0 && b.header !== false ? 'th' : 'td');
          td.innerHTML = inline(c);
          const a = Array.isArray(b.align) ? b.align[j] : null;
          if (a) td.style.textAlign = pick(a, ['left', 'center', 'right'], 'left');
          tr.append(td);
        });
        t.append(tr);
      });
      return t;
    }
    if (b.type === 'code') {
      const o = b.output || {};
      const place = pick(o.place, ['below', 'beside'], 'below');
      const space = pick(o.space, ['auto', 'S', 'M', 'L', 'lines'], 'auto');
      const cell = el('div', { class: `cell st-own-cell st-place-${place} st-size-${size}` });
      cell.dataset.stCode = b.code || '';
      const pre = el('pre', { class: 'sourceCode r' }, el('code', { class: 'sourceCode r' }, b.code || ''));
      if (b.showCode === false) pre.hidden = true;
      const lines = space === 'lines' ? Math.max(1, Math.min(40, Number(o.lines) || 6)) : { auto: 0, S: 4, M: 8, L: 14 }[space];
      const outArea = el('div', { class: 'st-saved-out' });
      if (lines) outArea.style.minHeight = `${lines * 1.35}em`;
      if (o.saved) outArea.append(el('pre', { class: 'st-text' }, String(o.saved)));
      cell.append(el('div', { class: 'cell-code st-own-code' }, pre), outArea);
      return cell;
    }
    return el('div');
  }
  /** An own slide (JSON, plan §5.2) as a reveal.js <section>. */
  function renderOwn(body, id) {
    body = body || {};
    const layout = pick(body.layout, Object.keys(LAYOUTS), 'text');
    const font = pick(body.font, Object.keys(FONTS), 'deck');
    needFonts(font);
    const sec = el('section', { class: `slide level2 st-own st-font-${font} st-align-${pick(body.align, ['left', 'center', 'right', 'justify'], 'left')} st-valign-${pick(body.valign, ['top', 'middle'], 'top')} st-layout-${layout}` });
    sec.dataset.stOwn = id || '';
    if (body.title || layout !== 'section') sec.append(el(layout === 'section' || layout === 'title' ? 'h1' : 'h2', { class: `st-title st-size-${pick(body.titleSize, SIZES, 'M')}` }, body.title || ''));
    const blocks = Array.isArray(body.blocks) ? body.blocks : [];
    if (layout === 'two-col') {
      const split = pick(String(body.split || '50'), ['50', '60', '40'], '50');
      const c1 = el('div', { class: 'st-col' }); const c2 = el('div', { class: 'st-col' });
      blocks.forEach((b) => (Number(b.col) === 2 ? c2 : c1).append(renderBlock(b)));
      sec.append(el('div', { class: `st-cols st-split-${split}` }, c1, c2));
    } else if (layout !== 'title' && layout !== 'section') {
      const inner = el('div', { class: 'st-own-body' });
      blocks.forEach((b) => inner.append(renderBlock(b)));
      sec.append(inner);
    }
    if (body.notes) sec.append(el('aside', { class: 'notes' }, String(body.notes)));
    sec.append(el('div', { class: 'st-own-badge', title: 'Only you see this slide' }, 'Your slide'));
    return sec;
  }
  ST.renderOwn = renderOwn;
  ST.OPTIONS = { SIZES, FONTS, LAYOUTS };

  // ── Own slides: storage ──────────────────────────────────────────────
  // account: /api/slides; device: localStorage 'st-own' = { id: { body, anchor } }
  ST.ownStore = {
    async list(deckRef) {
      if (ST.mode() === 'account') {
        const r = await fetch('/api/slides' + (deckRef ? '?anchor=' + encodeURIComponent(deckRef) : ''), { credentials: 'same-origin' });
        if (r.ok) return (await r.json()).slides;
      }
      const all = store.json('st-own', {});
      return Object.entries(all).filter(([, v]) => !deckRef || (v.anchor || '').startsWith(deckRef + '#')).map(([id, v]) => ({ id, ...v }));
    },
    async save(id, body, anchor) {
      if (ST.mode() === 'account') {
        const r = await fetch('/api/slides' + (id ? '/' + id : ''), { method: id ? 'PUT' : 'POST', credentials: 'same-origin',
          headers: { 'content-type': 'application/json' }, body: JSON.stringify(id ? { body } : { body, anchor: anchor || null }) });
        const j = await r.json().catch(() => ({}));
        if (!r.ok) throw new Error(j.error || `not saved (${r.status})`);
        return id || j.id;
      }
      const all = store.json('st-own', {});
      const nid = id || 'local-' + randomId();
      all[nid] = { body, anchor: id ? (all[id] || {}).anchor || anchor || null : anchor || null };
      store.set('st-own', JSON.stringify(all));
      return nid;
    },
    async remove(id) {
      if (ST.mode() === 'account' && !id.startsWith('local-')) {
        const r = await fetch('/api/slides/' + id, { method: 'DELETE', credentials: 'same-origin' });
        if (!r.ok) throw new Error('not deleted');
        return;
      }
      const all = store.json('st-own', {}); delete all[id]; store.set('st-own', JSON.stringify(all));
    },
  };

  // ── Own slides in a workshop deck: after their anchor slide ──────────
  async function placeOwnSlides() {
    if (!ST.deckRef || !window.Reveal) return;
    let slides = [];
    try { slides = await ST.ownStore.list(ST.deckRef); } catch (e) { return; }
    ST.own = Object.fromEntries(slides.map((s) => [s.id, s]));
    document.querySelectorAll('section.st-own').forEach((s) => s.remove());
    for (const s of slides) {
      const anchorId = (s.anchor || '').split('#')[1];
      const after = anchorId && document.getElementById(anchorId);
      if (!after) continue;
      let at = document.getElementById(anchorId + '-output') || after;   // after an output continuation slide, if any
      while (at.nextElementSibling && at.nextElementSibling.classList.contains('st-own')) at = at.nextElementSibling;
      at.after(renderOwn(s.body, s.id));
    }
    Reveal.sync();
    if (ST.editing) findCells().forEach(editCell);
  }
  ST.placeOwnSlides = placeOwnSlides;

  // ── Slide actions in Edit mode: add a slide after this one, edit / delete your slide ──
  const actions = el('div', { class: 'st-actions', hidden: true });
  function renderSlideActions() {
    const sec = window.Reveal && Reveal.getCurrentSlide();
    if (!ST.editing || !sec || !ST.deckRef) { actions.hidden = true; return; }
    const own = sec.dataset.stOwn;
    const kids = [];
    if (own) {
      kids.push(el('button', { type: 'button', class: 'st-act', onclick: () => openEditor({ id: own, body: (ST.own[own] || {}).body }) }, '✎ Edit my slide'));
      kids.push(el('button', { type: 'button', class: 'st-act st-act-danger', onclick: async () => {
        if (!confirm('Delete this slide of yours?')) return;
        await ST.ownStore.remove(own); await placeOwnSlides(); renderNote();
      } }, '🗑 Delete'));
    }
    const ref = currentRef() || (own ? (ST.own[own] || {}).anchor : null);
    if (ref) kids.push(el('button', { type: 'button', class: 'st-act', onclick: () => openEditor({ anchor: ref }) }, '＋ Add slide after this'));
    actions.replaceChildren(...kids);
    actions.hidden = !kids.length;
  }

  // ── The own-slide editor (C4) ────────────────────────────────────────
  const BLOCK_DEFAULTS = {
    text: () => ({ type: 'text', size: 'M', markdown: '' }),
    box: () => ({ type: 'box', kind: 'key', size: 'M', markdown: '' }),
    code: () => ({ type: 'code', size: 'S', code: '', showCode: true, output: { place: 'below', space: 'auto' } }),
    table: () => ({ type: 'table', size: 'M', header: true, rows: [['Column 1', 'Column 2'], ['', '']] }),
  };
  function select(label, value, options, onchange) {
    const s = el('select', { 'aria-label': label });
    for (const [v, t] of Object.entries(options)) s.append(el('option', { value: v, selected: String(v) === String(value) }, t));
    s.addEventListener('change', () => onchange(s.value));
    return el('label', { class: 'st-field' }, el('span', {}, label), s);
  }
  function seg(label, value, options, onchange) {
    const g = el('div', { class: 'st-seg', role: 'group', 'aria-label': label });
    for (const [v, t] of Object.entries(options)) {
      const b = el('button', { type: 'button', 'aria-pressed': String(v === value), title: `${label}: ${v}` }, t);
      b.addEventListener('click', () => { g.querySelectorAll('button').forEach((x) => x.setAttribute('aria-pressed', 'false')); b.setAttribute('aria-pressed', 'true'); onchange(v); });
      g.append(b);
    }
    return el('div', { class: 'st-field' }, el('span', {}, label), g);
  }
  const ALIGN = { left: '⯇ Left', center: '≡ Centre', right: 'Right ⯈', justify: '☰ Justify' };
  const sizeOpts = Object.fromEntries(SIZES.map((s) => [s, s]));
  const checkbox = (label, checked, onchange) => {
    const c = el('input', { type: 'checkbox', checked });
    c.addEventListener('change', () => onchange(c.checked));
    return el('label', { class: 'st-field st-check' }, c, el('span', {}, label));
  };
  /**
   * Open the editor. opts: { id?, body?, anchor?, onsave?(id, body) }.
   * In a deck, a new slide is anchored after the current slide; the builder passes onsave instead.
   */
  function openEditor(opts) {
    const body = JSON.parse(JSON.stringify(opts.body || { title: '', layout: 'text', font: 'deck', align: 'left', valign: 'top', blocks: [BLOCK_DEFAULTS.text()] }));
    body.blocks = Array.isArray(body.blocks) ? body.blocks : [];
    const dlg = el('dialog', { class: 'st-editor', 'aria-label': 'Your slide' });
    const preview = el('div', { class: 'st-preview' });
    const warn = el('div', { class: 'st-overflow', hidden: true }, '⚠ The slide is taller than the screen: shorten the text or use a smaller size.');
    const form = el('div', { class: 'st-form' });
    const stage = el('div', { class: 'st-preview-stage reveal' }, el('div', { class: 'slides' }, preview));
    function refresh() {
      const sec = renderOwn(body, 'preview');
      sec.classList.add('present');
      preview.replaceChildren(sec);
      requestAnimationFrame(() => {
        const w = stage.parentElement && stage.parentElement.clientWidth;
        if (w) stage.style.transform = `scale(${w / 1280})`;
        warn.hidden = sec.scrollHeight <= 720 + 4;
      });
    }
    function blockEditor(b, i) {
      const wrap = el('fieldset', { class: 'st-block' });
      wrap.append(el('legend', {}, { text: 'Text', box: 'Box', code: 'Code + output', table: 'Table' }[b.type]),
        el('div', { class: 'st-block-tools' },
          el('button', { type: 'button', title: 'Move up', 'aria-label': 'Move up', disabled: i === 0, onclick: () => { body.blocks.splice(i - 1, 0, body.blocks.splice(i, 1)[0]); build(); } }, '↑'),
          el('button', { type: 'button', title: 'Move down', 'aria-label': 'Move down', disabled: i === body.blocks.length - 1, onclick: () => { body.blocks.splice(i + 1, 0, body.blocks.splice(i, 1)[0]); build(); } }, '↓'),
          el('button', { type: 'button', title: 'Remove this block', 'aria-label': 'Remove this block', onclick: () => { body.blocks.splice(i, 1); build(); } }, '✕')));
      const row = el('div', { class: 'st-row' });
      row.append(select('Size', b.size || 'M', sizeOpts, (v) => { b.size = v; refresh(); }));
      if (b.type === 'text' || b.type === 'box') row.append(select('Align', b.align || '', { '': 'As the slide', left: 'Left', center: 'Centre', right: 'Right', justify: 'Justify' }, (v) => { b.align = v || undefined; refresh(); }));
      if (body.layout === 'two-col') row.append(select('Column', String(b.col || 1), { 1: 'Left', 2: 'Right' }, (v) => { b.col = Number(v); refresh(); }));
      if (b.type === 'box') row.append(select('Kind', b.kind || 'key', { key: 'Key point', warn: 'Warning', eq: 'Sentence / equation' }, (v) => { b.kind = v; refresh(); }));
      wrap.append(row);
      if (b.type === 'text' || b.type === 'box') {
        const ta = el('textarea', { rows: 4, 'aria-label': 'Text', placeholder: 'Text. **bold**, *italic*, __underline__, `code`, - bullet, 1. numbered, [link](https://…)' });
        ta.value = b.markdown || '';
        ta.addEventListener('input', () => { b.markdown = ta.value; refresh(); });
        wrap.append(ta);
      } else if (b.type === 'code') {
        const ta = el('textarea', { rows: 5, class: 'st-mono', spellcheck: 'false', 'aria-label': 'R code', placeholder: 'R code, e.g. t.test(weight ~ sex, data = p)' });
        ta.value = b.code || '';
        ta.addEventListener('input', () => { b.code = ta.value; refresh(); });
        b.output = b.output || {};
        const o = b.output;
        let linesField = null;
        if (o.space === 'lines') {
          const n = el('input', { type: 'number', min: 1, max: 40, value: o.lines || 6, 'aria-label': 'Lines' });
          n.addEventListener('input', () => { o.lines = Number(n.value); refresh(); });
          linesField = el('label', { class: 'st-field' }, el('span', {}, 'Lines'), n);
        }
        const r2 = el('div', { class: 'st-row' },
          select('Output', o.place || 'below', { below: 'Below the code', beside: 'Beside the code' }, (v) => { o.place = v; refresh(); }),
          select('Output space', o.space || 'auto', { auto: 'Fits the output', S: 'Small (4 lines)', M: 'Medium (8 lines)', L: 'Large (14 lines)', lines: 'Number of lines…' }, (v) => { o.space = v; build(); }),
          linesField, checkbox('Show the code', b.showCode !== false, (v) => { b.showCode = v; refresh(); }));
        const runOut = el('div', { class: 'st-out' });
        const runBtn = el('button', { type: 'button', class: 'st-run', disabled: !online, title: online ? 'Run with R in your browser and keep the text output on the slide' : 'Open from the website to run code' }, '▶ Run and keep the output');
        runBtn.addEventListener('click', async () => {
          runOut.replaceChildren(el('div', { class: 'st-running' }, 'Running…'));
          try {
            await startR(); await install(packagesIn(b.code || ''));
            setStatus('');
            const res = await capture(b.code || '');
            show(runOut, res);
            o.saved = res.output.filter((x) => x.type === 'stdout').map((x) => x.data).join('\n').slice(0, 20000) || undefined;
            refresh();
          } catch (e) { setStatus(''); runOut.replaceChildren(el('pre', { class: 'st-err' }, String(e.message || e))); }
        });
        wrap.append(ta, r2, el('div', { class: 'st-row' }, runBtn, el('span', { class: 'st-status', hidden: true })), runOut,
          el('p', { class: 'st-hint' }, 'Text output is saved with the slide, so viewers see it without running anything. Plots appear when the slide is run.'));
      } else if (b.type === 'table') {
        const ta = el('textarea', { rows: 4, class: 'st-mono', 'aria-label': 'Table rows', placeholder: 'One row per line, cells separated by |' });
        ta.value = (b.rows || []).map((r) => r.join(' | ')).join('\n');
        ta.addEventListener('input', () => { b.rows = ta.value.split('\n').map((l) => l.split('|').map((c) => c.trim())); refresh(); });
        wrap.append(ta, checkbox('First row is a header', b.header !== false, (v) => { b.header = v; refresh(); }));
      }
      return wrap;
    }
    function build() {
      const title = el('input', { type: 'text', value: body.title || '', placeholder: 'Slide title', 'aria-label': 'Slide title', maxlength: 200 });
      title.addEventListener('input', () => { body.title = title.value; refresh(); });
      const notes = el('textarea', { rows: 2, 'aria-label': 'Speaker notes', placeholder: 'Speaker notes (optional; in the speaker view and the PowerPoint notes)' });
      notes.value = body.notes || '';
      notes.addEventListener('input', () => { body.notes = notes.value; });
      const add = el('div', { class: 'st-row st-add' }, el('span', {}, 'Add:'),
        ...Object.entries({ text: '¶ Text', box: '▣ Box', code: '⌨ Code + output', table: '▦ Table' }).map(([t, label]) =>
          el('button', { type: 'button', 'data-add': t, onclick: () => { body.blocks.push(BLOCK_DEFAULTS[t]()); build(); } }, label)));
      form.replaceChildren(
        el('label', { class: 'st-field st-wide' }, el('span', {}, 'Title'), title),
        el('div', { class: 'st-row' },
          select('Layout', body.layout || 'text', LAYOUTS, (v) => { body.layout = v; build(); }),
          select('Font', body.font || 'deck', FONTS, (v) => { body.font = v; refresh(); }),
          select('Title size', body.titleSize || 'M', sizeOpts, (v) => { body.titleSize = v; refresh(); }),
          body.layout === 'two-col' ? select('Columns', String(body.split || '50'), { 50: '50 / 50', 60: '60 / 40', 40: '40 / 60' }, (v) => { body.split = v; refresh(); }) : null),
        el('div', { class: 'st-row' },
          seg('Alignment', body.align || 'left', ALIGN, (v) => { body.align = v; refresh(); }),
          seg('Vertical', body.valign || 'top', { top: '⤒ Top', middle: '↕ Middle' }, (v) => { body.valign = v; refresh(); })),
        ...body.blocks.map(blockEditor), add,
        el('label', { class: 'st-field st-wide' }, el('span', {}, 'Notes'), notes));
      refresh();
    }
    const status = el('span', { class: 'st-save-status', role: 'status' });
    const save = el('button', { type: 'button', class: 'st-primary' }, 'Save slide');
    save.addEventListener('click', async () => {
      save.disabled = true; status.textContent = 'Saving…';
      try {
        const id = await ST.ownStore.save(opts.id, body, opts.anchor);
        dlg.close(); dlg.remove();
        if (opts.onsave) opts.onsave(id, body);
        else {
          await placeOwnSlides();
          const s = document.querySelector(`section.st-own[data-st-own="${CSS.escape(id)}"]`);
          if (s) { const i = Reveal.getIndices(s); Reveal.slide(i.h, i.v); }
          renderNote();
        }
      } catch (e) { status.textContent = e.message; save.disabled = false; }
    });
    const where = opts.onsave ? '' : (ST.mode() === 'account' ? 'Saved to your account; only you see it.' : 'Saved on this device; only you see it.');
    dlg.append(
      el('div', { class: 'st-editor-head' }, el('h2', {}, opts.id ? 'Edit your slide' : 'New slide'), el('span', { class: 'st-hint' }, where)),
      el('div', { class: 'st-editor-main' }, form, el('div', { class: 'st-preview-col' }, el('div', { class: 'st-preview-box' }, stage), warn)),
      el('div', { class: 'st-editor-foot' }, status,
        el('button', { type: 'button', onclick: () => { dlg.close(); dlg.remove(); } }, 'Cancel'), save));
    dlg.addEventListener('keydown', (e) => e.stopPropagation());
    dlg.addEventListener('cancel', () => dlg.remove());
    document.body.append(dlg);
    build();
    dlg.showModal();
    return dlg;
  }
  ST.openEditor = openEditor;

  // ── Start ────────────────────────────────────────────────────────────
  function initDeck() {
    if (document.querySelector('.st-toggle') || !document.querySelector('.reveal .slides')) return;
    // Own slides handed over by the custom-deck player as JSON placeholders
    document.querySelectorAll('section[data-st-own-json]').forEach((ph) => {
      let body = null; try { body = JSON.parse(ph.dataset.stOwnJson); } catch (e) { /* skip */ }
      const sec = renderOwn(body, ph.dataset.stOwnId || '');
      sec.querySelector('.st-own-badge').remove();
      ph.replaceWith(sec);
    });
    if (window.Reveal && Reveal.sync) Reveal.sync();
    btn = el('button', { class: 'st-toggle', type: 'button', 'aria-pressed': 'false',
      title: 'Edit mode: change and run the code, add notes and your own slides' }, '✎ Edit');
    btn.addEventListener('click', toggle);
    document.body.append(btn, panel, actions);
    if (window.Reveal) Reveal.on('slidechanged', renderNote);
    ST.hooks.push(() => loadNotes().then(renderNote));
    const have = (k) => { const v = store.get(k); return v && v !== '{}'; };
    if (have('st-notes') || signedIn()) loadNotes().then(renderNote);
    if (ST.deckRef && (have('st-own') || signedIn())) placeOwnSlides();
    if (store.get('st-edit') === '1') toggle();
  }
  ST.initDeck = initDeck;
  const whenReady = () => {
    if (!document.querySelector('.reveal .slides')) return;           // used as a library (builder page)
    if (window.Reveal && Reveal.isReady && !Reveal.isReady()) Reveal.on('ready', initDeck); else initDeck();
  };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', whenReady); else whenReady();
})();
