/* ═══════════════════════════════════════════════════════════════════════
 * page-notes.js — your notes on the Basic and Moderate pages (decided 2026-11-28; CUSTOM_DECKS_PLAN.md C2)
 * Added by cloud/stage.mjs to the pages of the Basic/Moderate folders, in whichever track shows them.
 *
 * Reading pages: a 📝 button on each section heading; your note sits under the heading.
 * Slide pages (reveal.js): a 📝 Note button; the note is kept per slide, as in the workshop decks.
 * Notes are keyed by the page, not the track: "page:<folder>/<page>#<section or slide id>".
 * Signed in ('ws-account'): saved to the account (/api/notes). Otherwise: this device only.
 * A note whose heading was renamed is not lost: it is listed at the end of the page.
 * ═════════════════════════════════════════════════════════════════════ */
(function () {
  'use strict';
  if (window.PageNotes) return;
  const m = location.pathname.match(/^\/[a-z0-9-]+\/([a-z0-9_-]+)\/([\w.-]+?)(?:\.html)?$/);
  if (!m) return;
  const PAGE = `${m[1]}/${m[2]}`;
  const PREFIX = `page:${PAGE}#`;
  const store = {
    get(k) { try { return localStorage.getItem(k); } catch (e) { return null; } },
    set(k, v) { try { localStorage.setItem(k, v); } catch (e) { /* private mode */ } },
  };
  const account = () => !!store.get('ws-account');
  const PN = window.PageNotes = { notes: {} };
  const el = (tag, attrs, ...kids) => {
    const e = document.createElement(tag);
    for (const [k, v] of Object.entries(attrs || {})) {
      if (v === undefined || v === null || v === false) continue;
      if (k === 'class') e.className = v; else if (k.startsWith('on')) e.addEventListener(k.slice(2), v); else e.setAttribute(k, v === true ? '' : v);
    }
    for (const c of kids) if (c !== null && c !== undefined) e.append(c);
    return e;
  };

  async function load() {
    if (account()) {
      try {
        const r = await fetch('/api/notes?page=' + encodeURIComponent(PAGE), { credentials: 'same-origin' });
        if (r.ok) { PN.notes = (await r.json()).notes; return; }
      } catch (e) { /* this device */ }
    }
    let all = {}; try { all = JSON.parse(store.get('st-notes')) || {}; } catch (e) { /* */ }
    PN.notes = {};
    for (const [k, v] of Object.entries(all)) if (k.startsWith(PREFIX)) PN.notes[k.slice(PREFIX.length)] = v;
  }
  const timers = {};
  function save(id, text, status) {
    if (text.trim()) PN.notes[id] = { text, ts: Date.now() }; else delete PN.notes[id];
    status.textContent = 'Saving…';
    clearTimeout(timers[id]);
    timers[id] = setTimeout(async () => {
      if (account()) {
        try {
          const r = await fetch('/api/notes', { method: 'PUT', credentials: 'same-origin', headers: { 'content-type': 'application/json' },
            body: JSON.stringify({ slide: PREFIX + id, text }) });
          status.textContent = r.ok ? 'Saved to your account' : 'Not saved: ' + ((await r.json().catch(() => ({}))).error || r.status);
        } catch (e) { status.textContent = 'Not saved: offline'; }
      } else {
        let all = {}; try { all = JSON.parse(store.get('st-notes')) || {}; } catch (e) { /* */ }
        if (text.trim()) all[PREFIX + id] = PN.notes[id]; else delete all[PREFIX + id];
        store.set('st-notes', JSON.stringify(all));
        status.textContent = 'Saved on this device · sign in to keep notes on every device';
      }
    }, 900);
  }
  function editor(id, onclose) {
    const ta = el('textarea', { class: 'pn-text', 'aria-label': 'Your note', placeholder: 'Your note…' });
    ta.value = PN.notes[id] ? PN.notes[id].text : '';
    const status = el('span', { class: 'pn-status', role: 'status' });
    ta.addEventListener('input', () => save(id, ta.value, status));
    ta.addEventListener('keydown', (e) => e.stopPropagation());
    const box = el('div', { class: 'pn-box pn-edit' }, el('div', { class: 'pn-head' }, '📝 My note',
      el('button', { type: 'button', class: 'pn-close', 'aria-label': 'Close the note', onclick: onclose }, 'Done')), ta, status);
    setTimeout(() => ta.focus(), 0);
    return box;
  }
  const view = (id, onedit) => el('div', { class: 'pn-box pn-view' },
    el('div', { class: 'pn-head' }, '📝 My note', el('button', { type: 'button', class: 'pn-close', 'aria-label': 'Edit the note', onclick: onedit }, 'Edit')),
    el('div', { class: 'pn-read' }, PN.notes[id].text));

  // ── Reading pages: one note per section ──────────────────────────────
  function readingPage() {
    const sections = [...document.querySelectorAll('main section.level2[id], main section.level3[id], #quarto-content section.level2[id], #quarto-content section.level3[id]')]
      .filter((s, i, a) => a.indexOf(s) === i);
    const known = new Set(sections.map((s) => s.id));
    for (const sec of sections) {
      const h = sec.querySelector(':scope > h2, :scope > h3');
      if (!h) continue;
      const slot = el('div', { class: 'pn-slot' });
      h.after(slot);
      const show = (editing) => {
        if (editing) slot.replaceChildren(editor(sec.id, () => show(false)));
        else slot.replaceChildren(...(PN.notes[sec.id] ? [view(sec.id, () => show(true))] : []));
      };
      h.append(el('button', { type: 'button', class: 'pn-add', title: 'Add or edit your note on this section', 'aria-label': `Your note on “${h.textContent.trim()}”`, onclick: () => show(true) }, '📝'));
      show(false);
    }
    // Notes on sections that no longer exist (heading renamed): listed at the end, never lost
    const orphans = Object.keys(PN.notes).filter((id) => !known.has(id));
    if (orphans.length) {
      const main = document.querySelector('main') || document.body;
      main.append(el('section', { class: 'pn-orphans' }, el('h2', {}, 'Your notes on sections that have changed'),
        ...orphans.map((id) => el('div', { class: 'pn-box pn-view' }, el('div', { class: 'pn-head' }, `📝 (was: ${id})`), el('div', { class: 'pn-read' }, PN.notes[id].text)))));
    }
  }

  // ── Slide pages: one note per slide ──────────────────────────────────
  function slidePage() {
    const panel = el('aside', { class: 'st-notes', hidden: true, 'aria-label': 'Your note on this slide' });
    let open = false;
    const btn = el('button', { type: 'button', class: 'st-toggle pn-slide-btn', 'aria-pressed': 'false', title: 'Your note on this slide' }, '📝 Note');
    const render = () => {
      const s = Reveal.getCurrentSlide();
      const id = s && s.id;
      if (!id) { panel.hidden = true; return; }
      if (open) {
        const status = el('div', { class: 'st-note-status' });
        const ta = el('textarea', { class: 'st-note-text', 'aria-label': 'Your note on this slide', placeholder: 'Your note on this slide…' });
        ta.value = PN.notes[id] ? PN.notes[id].text : '';
        ta.addEventListener('input', () => save(id, ta.value, status));
        ta.addEventListener('keydown', (e) => e.stopPropagation());
        panel.className = 'st-notes st-notes-edit'; panel.hidden = false;
        panel.replaceChildren(el('div', { class: 'st-note-head' }, '📝 My note'), ta, status);
      } else if (PN.notes[id]) {
        panel.className = 'st-notes st-notes-view'; panel.hidden = false;
        panel.replaceChildren(el('div', { class: 'st-note-head' }, '📝 My note'), el('div', { class: 'st-note-read' }, PN.notes[id].text));
      } else panel.hidden = true;
    };
    btn.addEventListener('click', () => { open = !open; btn.setAttribute('aria-pressed', String(open)); render(); });
    document.body.append(btn, panel);
    Reveal.on('slidechanged', render);
    render();
  }

  async function start() {
    await load();
    if (document.querySelector('.reveal .slides') && window.Reveal) {
      if (Reveal.isReady && !Reveal.isReady()) Reveal.on('ready', slidePage); else slidePage();
    } else readingPage();
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start); else start();
})();
