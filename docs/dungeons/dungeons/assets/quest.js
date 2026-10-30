/* ═══════════════════════════════════════════════════════════════════════
 * quest.js — gamified self-learning engine (vanilla JS, offline, no deps)
 * ---------------------------------------------------------------------
 * Extends the idea of regression-workshop/assets/quiz.js:
 *   • 6 item types: mcq (shuffled) · fill · num · order · spot · code (R typed or pasted,
 *     checked by assets/rcheck.js against several accepted solutions; no R is run)
 *   • XP (difficulty x attempt factor − hint cost), daily streak, ranks, badges
 *   • world gates (unlock after a pass mark), boss items, tag mastery
 *   • TEST MODE (pre/post): no feedback while answering, confidence rating,
 *     per-tag breakdown, calibration, pre→post gain
 *   • progress kept in localStorage; export / import / reset
 *
 * ITEM MARKUP (emitted by quest.R — never hand-written; answers are salted
 * hashes, explanations / hints / reveal text are base64):
 *
 *  ::: {.rq-item data-id="w1-03" data-world="w1" data-type="mcq" data-diff="2"
 *       data-tags="outcome-type,flowchart" data-hash="…" data-show="b64"
 *       data-explain="b64" data-hints="b64(JSON array)" [data-boss="1"] [data-form="A"]}
 *  stem (markdown; may contain a code block = "output-reading" item)
 *
 *  - option / step / sentence   (a list for mcq, order, spot)
 *  :::
 *
 *  mcq   data-hash   hash(id|authoredIndex). Display order is shuffled.
 *  fill  data-hashes hash(id|normalised text) for every accepted answer
 *  num   data-hashes hash(id|value.toFixed(dp)) ; data-dp = decimals
 *  order data-hash   hash(id|"0-1-2-3" authored order); list is shuffled
 *  spot  data-hash   hash(id|"1,3" sorted indices of the FLAWED sentences)
 *
 * PAGE WRAPPERS
 *  <div class="rq-world" data-world="w1" data-total="9"
 *       data-requires="w0:70"></div>      → gate + progress for a world page
 *  <div class="rq-test" data-test="pre"></div>  → wrap items to run in TEST MODE
 *  <div id="rq-map"></div>                → quest map (needs assets/worlds.js)
 *  <span class="rq-xp|rq-rank|rq-streak"> → live counters anywhere
 *
 * HASH: two polynomial rolling hashes, base-36 (must equal quest.R / quiz.js).
 * Hashing only stops casual view-source; it is not security. For scores that
 * count formally use a server (see ROADMAP.md, Phase 6).
 * ═══════════════════════════════════════════════════════════════════════ */
(function () {
  'use strict';
  var M1 = 2147483629, M2 = 2147483587, KEY = 'rq:v1';

  /* ── hashing / encoding ─────────────────────────────────────────────── */
  function hash(str) {
    var a = 5381, b = 52711;
    for (var i = 0; i < str.length; i++) { var c = str.charCodeAt(i); a = (a * 131 + c) % M1; b = (b * 137 + c) % M2; }
    return a.toString(36) + '.' + b.toString(36);
  }
  function normalise(s) { return String(s).toLowerCase().replace(/`/g, '').replace(/\s+/g, ' ').trim().replace(/\(\s*\)$/, '').trim(); }
  function numKey(s, dp) {
    var t = String(s).replace(/[,\s]/g, '').replace(/^[±+]|^\+\/-/, '').replace(/−/g, '-').replace(/%$/, '');
    var v = parseFloat(t); if (isNaN(v)) return null; return v.toFixed(dp);
  }
  function b64(s) { if (!s) return ''; try { var bin = atob(s), u = new Uint8Array(bin.length); for (var i = 0; i < bin.length; i++) u[i] = bin.charCodeAt(i); return new TextDecoder('utf-8').decode(u); } catch (e) { return ''; } }
  function esc(s) { return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;'); }
  function lite(s) { return esc(s).replace(/`([^`]+)`/g, '<code>$1</code>'); }
  function shuffle(a) { for (var k = a.length - 1; k > 0; k--) { var r = Math.floor(Math.random() * (k + 1)), t = a[k]; a[k] = a[r]; a[r] = t; } return a; }
  function today() { var d = window.RQ_NOW ? new Date(window.RQ_NOW) : new Date(); return d.getFullYear() + '-' + ('0' + (d.getMonth() + 1)).slice(-2) + '-' + ('0' + d.getDate()).slice(-2); }
  function dayDiff(a, b) { return Math.round((new Date(b) - new Date(a)) / 864e5); }

  /* ── state ──────────────────────────────────────────────────────────── */
  var BASE = { 1: 10, 2: 20, 3: 30 }, BOSS_BONUS = 50, HINT_COST = [3, 5, 8];
  var RANKS = [[0, 'Field Volunteer'], [100, 'Health Worker'], [250, 'Medical Officer'], [500, 'Epidemiologist'], [900, 'Senior Epidemiologist'], [1500, 'Chief Biostatistician']];
  var state = load();
  function blank() { return { v: 1, items: {}, badges: {}, streak: { last: null, count: 0, best: 0 }, tests: {}, settings: {}, created: today() }; }
  function load() { try { var s = JSON.parse(localStorage.getItem(KEY)); if (s && s.v === 1) { s.settings = s.settings || {}; return s; } } catch (e) {} return blank(); }
  function save() { try { localStorage.setItem(KEY, JSON.stringify(state)); } catch (e) {} }
  function attemptFactor(t) { return t <= 1 ? 1 : t === 2 ? 0.5 : 0.25; }
  function itemXP(r) {
    if (!r || !r.solved || r.shown) return 0;
    var cost = 0; for (var i = 0; i < (r.hints || 0); i++) cost += HINT_COST[Math.min(i, 2)];
    return Math.max(0, Math.round((BASE[r.diff] || 10) * attemptFactor(r.tries) - cost) + (r.boss ? BOSS_BONUS : 0));
  }
  function totalXP() { var x = 0; for (var k in state.items) x += itemXP(state.items[k]); return x; }
  function rankOf(xp) { var r = RANKS[0], next = null; for (var i = 0; i < RANKS.length; i++) { if (xp >= RANKS[i][0]) { r = RANKS[i]; next = RANKS[i + 1] || null; } } return { name: r[1], from: r[0], next: next }; }
  function solvedIn(world) { var n = 0; for (var k in state.items) { var r = state.items[k]; if (r.world === world && r.solved) n++; } return n; }
  function worldPct(world, total) { return total ? Math.round(100 * solvedIn(world) / total) : 0; }
  function tagCount(tag) { var n = 0; for (var k in state.items) { var r = state.items[k]; if (r.solved && !r.shown && (r.tags || []).indexOf(tag) >= 0) n++; } return n; }

  /* ── badges (rules are data: add rows to extend) ────────────────────── */
  var BADGES = [
    { id: 'first-blood', icon: '🎯', name: 'First Blood', desc: 'Solve your first item', test: function () { return nSolved() >= 1; } },
    { id: 'no-hints-10', icon: '🧠', name: 'Unaided', desc: '10 items solved first try with no hints', test: function () { var n = 0; for (var k in state.items) { var r = state.items[k]; if (r.solved && r.tries === 1 && !r.hints && !r.shown) n++; } return n >= 10; } },
    { id: 'streak-3', icon: '🔥', name: 'On a Roll', desc: '3-day streak', test: function () { return state.streak.best >= 3; } },
    { id: 'streak-7', icon: '🌋', name: 'Week of Fire', desc: '7-day streak', test: function () { return state.streak.best >= 7; } },
    { id: 'confounder', icon: '🕵️', name: 'Confounder Catcher', desc: 'Master 3 confounding items', test: function () { return tagCount('confounding') >= 3; } },
    { id: 'collinear', icon: '🗡️', name: 'VIF Vanquisher', desc: 'Master 2 collinearity items', test: function () { return tagCount('collinearity') >= 2; } },
    { id: 'odds', icon: '🎲', name: 'Odds Whisperer', desc: 'Master 3 odds-ratio items', test: function () { return tagCount('odds-ratio') >= 3; } },
    { id: 'pitfall', icon: '🔍', name: 'Pitfall Spotter', desc: 'Solve 3 spot-the-error items', test: function () { var n = 0; for (var k in state.items) { var r = state.items[k]; if (r.solved && r.type === 'spot') n++; } return n >= 3; } },
    { id: 'pre', icon: '📋', name: 'Baseline Set', desc: 'Complete the pre-test', test: function () { return !!state.tests.pre; } },
    { id: 'post', icon: '📈', name: 'Growth Mindset', desc: 'Complete the post-test', test: function () { return !!state.tests.post; } },
    { id: 'r1grad', icon: '🎒', name: 'Basics Graduate', desc: 'Score 70% or more in the Region 1 post-test', test: function () { return !!state.tests.r1post && state.tests.r1post.pct >= 70; } },
    { id: 'r2grad', icon: '🧰', name: 'Moderate Graduate', desc: 'Score 70% or more in the Region 2 post-test', test: function () { return !!state.tests.r2post && state.tests.r2post.pct >= 70; } },
    { id: 'gain', icon: '🚀', name: 'Big Gain', desc: 'Post-test beats pre-test by 20+ points', test: function () { return state.tests.pre && state.tests.post && (state.tests.post.pct - state.tests.pre.pct) >= 20; } }
  ];
  function nSolved() { var n = 0; for (var k in state.items) if (state.items[k].solved) n++; return n; }
  var worldBadgeDone = {};
  function checkBadges() {
    var gained = [];
    BADGES.forEach(function (b) { if (!state.badges[b.id] && b.test()) { state.badges[b.id] = today(); gained.push(b); } });
    (window.RQ_WORLDS || []).forEach(function (w) {          // world-clear badges
      var id = 'clear-' + w.id;
      if (!state.badges[id] && w.total && solvedIn(w.id) >= w.total && bossSolved(w.id)) { state.badges[id] = today(); gained.push({ icon: w.icon || '🏁', name: w.title + ' — Cleared', desc: 'All items solved incl. the boss' }); }
    });
    gained.forEach(function (b) { toast(b.icon + ' Badge unlocked: <b>' + esc(b.name) + '</b><br><small>' + esc(b.desc) + '</small>'); });
    return gained;
  }
  function bossSolved(world) { var any = false, all = true; for (var k in state.items) { var r = state.items[k]; if (r.world === world && r.boss) { any = true; if (!r.solved) all = false; } } return !any || all; }

  /* ── HUD / toast ────────────────────────────────────────────────────── */
  var toastBox;
  function toast(html) {
    if (!toastBox) { toastBox = document.createElement('div'); toastBox.className = 'rq-toasts'; document.body.appendChild(toastBox); }
    var t = document.createElement('div'); t.className = 'rq-toast'; t.innerHTML = html; toastBox.appendChild(t);
    setTimeout(function () { t.classList.add('out'); setTimeout(function () { t.remove(); }, 500); }, 3600);
  }
  var hud;
  function renderHUD() {
    if (!document.body.classList.contains('rq-page')) return;
    if (!hud) { hud = document.createElement('div'); hud.className = 'rq-hud'; document.body.insertBefore(hud, document.body.firstChild); }
    var xp = totalXP(), rk = rankOf(xp), pct = rk.next ? Math.round(100 * (xp - rk.from) / (rk.next[0] - rk.from)) : 100;
    hud.innerHTML = '<a class="rq-home" href="' + (window.RQ_HOME || 'index.html') + '">🗺️ Quest map</a><a href="campus.html">🏛️ Campus</a>' +
      '<span class="rq-pill">🔥 <b class="rq-streak">' + state.streak.count + '</b>-day streak</span>' +
      '<span class="rq-pill">⭐ <b class="rq-xp">' + xp + '</b> XP</span>' +
      '<span class="rq-pill rq-rankpill"><b class="rq-rank">' + esc(rk.name) + '</b><span class="rq-bar"><i style="width:' + pct + '%"></i></span>' +
      '<small>' + (rk.next ? (rk.next[0] - xp) + ' XP to ' + esc(rk.next[1]) : 'max rank') + '</small></span>' +
      '<span class="rq-pill">🏅 ' + Object.keys(state.badges).length + '</span>';
    document.querySelectorAll('.rq-xp:not(.rq-hud .rq-xp)').forEach(function (e) { e.textContent = xp; });
  }
  function touchStreak() {
    var t = today(), s = state.streak;
    if (s.last === t) return;
    s.count = (s.last && dayDiff(s.last, t) === 1) ? s.count + 1 : 1; s.last = t; s.best = Math.max(s.best || 0, s.count);
  }

  /* ── recording an attempt ───────────────────────────────────────────── */
  function rec(q) {
    var id = q.getAttribute('data-id');
    if (!state.items[id]) state.items[id] = {
      world: q.getAttribute('data-world') || '', type: q.getAttribute('data-type'), diff: parseInt(q.getAttribute('data-diff') || '1', 10),
      tags: (q.getAttribute('data-tags') || '').split(',').filter(Boolean), boss: q.getAttribute('data-boss') === '1', tries: 0, hints: 0, solved: false, shown: false };
    return state.items[id];
  }
  function commit(q, ok) {
    var r = rec(q), before = totalXP(), rkBefore = rankOf(before).name;
    if (!r.solved) { r.tries++; if (ok) { r.solved = true; r.last = today(); } }
    touchStreak(); save();
    var gained = totalXP() - before;
    if (ok && gained > 0) toast('+' + gained + ' XP');
    var rkAfter = rankOf(totalXP()).name; if (rkAfter !== rkBefore) toast('🎖️ Rank up: <b>' + esc(rkAfter) + '</b>');
    checkBadges(); save(); renderHUD(); updateWorldBars();
  }
  function feedback(q, ok, extra) {
    var fb = q.querySelector('.rq-feedback'); fb.className = 'rq-feedback ' + (ok ? 'is-correct' : 'is-wrong');
    var ex = b64(q.getAttribute('data-explain'));
    fb.innerHTML = (ok ? '✔ Correct. ' : '✘ Not quite — try again or use a hint. ') + (ok && ex ? lite(ex) : '') + (extra || '');
  }

  /* ── common widgets: hints, show answer, feedback ───────────────────── */
  function common(q, testMode) {
    var fb = document.createElement('div'); fb.className = 'rq-feedback'; fb.setAttribute('aria-live', 'polite'); q.appendChild(fb);
    if (testMode) return { fb: fb };
    var bar = document.createElement('div'); bar.className = 'rq-actions'; q.appendChild(bar);
    var hints = []; try { hints = JSON.parse(b64(q.getAttribute('data-hints')) || '[]'); } catch (e) {}
    var hb = null;
    if (hints.length) {
      hb = document.createElement('button'); hb.type = 'button'; hb.className = 'rq-btn rq-ghost'; bar.appendChild(hb);
      var box = document.createElement('div'); box.className = 'rq-hintbox'; q.appendChild(box);
      var upd = function () { var r = rec(q), n = r.hints || 0; hb.textContent = n >= hints.length ? 'No more hints' : '💡 Hint ' + (n + 1) + '/' + hints.length + ' (−' + HINT_COST[Math.min(n, 2)] + ' XP)'; hb.disabled = n >= hints.length || r.solved; };
      hb.addEventListener('click', function () { var r = rec(q); if (r.solved || (r.hints || 0) >= hints.length) return; r.hints = (r.hints || 0) + 1; save(); box.innerHTML = hints.slice(0, r.hints).map(function (h, i) { return '<div>💡 ' + (i + 1) + '. ' + lite(h) + '</div>'; }).join(''); upd(); });
      var r0 = rec(q); if (r0.hints) box.innerHTML = hints.slice(0, r0.hints).map(function (h, i) { return '<div>💡 ' + (i + 1) + '. ' + lite(h) + '</div>'; }).join('');
      upd();
    }
    var sb = document.createElement('button'); sb.type = 'button'; sb.className = 'rq-btn rq-ghost'; sb.textContent = 'Show answer (0 XP)'; bar.appendChild(sb);
    return { fb: fb, show: sb, hintBtn: hb };
  }
  function revealText(q) { return b64(q.getAttribute('data-show')); }
  function showAnswer(q, c, lockFn) {
    c.show.addEventListener('click', function () {
      var r = rec(q); if (!r.solved) { r.shown = true; r.solved = true; r.tries = Math.max(r.tries, 1); } save();
      var fb = q.querySelector('.rq-feedback'); fb.className = 'rq-feedback is-info';
      fb.innerHTML = (q.getAttribute('data-type') === 'code' ? 'One correct answer:<pre class="rq-sol">' + esc(revealText(q)) + '</pre>' : 'Answer: <strong>' + lite(revealText(q)) + '</strong><br>') + lite(b64(q.getAttribute('data-explain')));
      if (lockFn) lockFn(); checkBadges(); save(); renderHUD(); updateWorldBars();
    });
  }
  function prior(q) { var r = state.items[q.getAttribute('data-id')]; return r && r.solved ? r : null; }

  /* ── item types ─────────────────────────────────────────────────────── */
  function initMCQ(q, tm) {
    var id = q.getAttribute('data-id'), want = q.getAttribute('data-hash'), list = q.querySelector('ul,ol'); if (!list) return;
    var items = Array.prototype.slice.call(list.children).map(function (li, i) { return { li: li, i: i }; });
    if (q.getAttribute('data-shuffle') !== '0') shuffle(items);
    var wrap = document.createElement('div'); wrap.className = 'rq-options';
    var btns = items.map(function (it, pos) { var b = document.createElement('button'); b.type = 'button'; b.className = 'rq-option'; b.setAttribute('data-i', it.i);
      b.innerHTML = '<span class="rq-letter">' + String.fromCharCode(65 + pos) + '</span><span>' + it.li.innerHTML + '</span>'; wrap.appendChild(b); return b; });
    list.parentNode.replaceChild(wrap, list);
    var c = common(q, tm), ok = function (i) { return hash(id + '|' + i) === want; }, orig = function (b) { return parseInt(b.getAttribute('data-i'), 10); };
    var lock = function () { btns.forEach(function (x) { x.disabled = true; if (ok(orig(x))) x.classList.add('is-correct'); }); };
    if (tm) { btns.forEach(function (b) { b.addEventListener('click', function () { btns.forEach(function (x) { x.classList.remove('is-picked'); }); b.classList.add('is-picked'); q._answer = { ok: ok(orig(b)), given: orig(b) }; }); }); return; }
    btns.forEach(function (b) { b.addEventListener('click', function () { var good = ok(orig(b)); b.classList.add(good ? 'is-correct' : 'is-wrong'); b.disabled = true; commit(q, good); feedback(q, good); if (good) lock(); }); });
    showAnswer(q, c, lock);
    var p = prior(q); if (p) { lock(); feedback(q, true); }
  }
  function textLike(q, tm, kind) {
    var id = q.getAttribute('data-id'), acc = (q.getAttribute('data-hashes') || '').split(','), dp = parseInt(q.getAttribute('data-dp') || '0', 10);
    var row = document.createElement('div'); row.className = 'rq-fill';
    var inp = document.createElement('input'); inp.type = 'text'; inp.className = 'rq-input'; inp.placeholder = kind === 'num' ? 'type a number…' : 'type your answer…';
    inp.setAttribute('autocomplete', 'off'); inp.setAttribute('spellcheck', 'false'); if (kind === 'num') inp.setAttribute('inputmode', 'decimal');
    var chk = document.createElement('button'); chk.type = 'button'; chk.className = 'rq-btn'; chk.textContent = 'Check'; row.appendChild(inp); if (!tm) row.appendChild(chk); q.appendChild(row);
    var c = common(q, tm), good = function () { var k = kind === 'num' ? numKey(inp.value, dp) : normalise(inp.value); return k !== null && k !== '' && acc.indexOf(hash(id + '|' + k)) >= 0; };
    ['keydown', 'keyup', 'keypress'].forEach(function (ev) { inp.addEventListener(ev, function (e) { e.stopPropagation(); if (ev === 'keydown' && e.key === 'Enter' && !tm) go(); }); });
    if (tm) { inp.addEventListener('input', function () { q._answer = { ok: good(), given: inp.value, blank: !inp.value.trim() }; }); return; }
    function go() { if (!inp.value.trim()) return; var g = good(); inp.classList.remove('is-correct', 'is-wrong'); inp.classList.add(g ? 'is-correct' : 'is-wrong'); commit(q, g); feedback(q, g); if (g) { inp.disabled = true; chk.disabled = true; } }
    chk.addEventListener('click', go);
    showAnswer(q, c, function () { inp.disabled = true; chk.disabled = true; });
    var p = prior(q); if (p) { inp.value = revealText(q); inp.disabled = true; chk.disabled = true; inp.classList.add('is-correct'); feedback(q, true); }
  }
  /* code: learner types/pastes R; RCheck normalises it and compares with the author's solutions (no R is run) */
  function initCode(q, tm) {
    var sols = []; try { sols = JSON.parse(b64(q.getAttribute('data-sol')) || '[]'); } catch (e) {}
    var opts = {}; try { opts = JSON.parse(b64(q.getAttribute('data-opts')) || '{}') || {}; } catch (e) {}
    var ta = document.createElement('textarea'); ta.className = 'rq-code'; ta.rows = parseInt(q.getAttribute('data-lines') || '6', 10);
    ta.setAttribute('spellcheck', 'false'); ta.setAttribute('autocapitalize', 'off'); ta.setAttribute('autocomplete', 'off'); ta.setAttribute('aria-label', 'Your R code');
    ta.placeholder = '# type or paste your R code here'; ta.value = b64(q.getAttribute('data-starter')) || '';
    var chk = document.createElement('button'); chk.type = 'button'; chk.className = 'rq-btn'; chk.textContent = 'Check code';
    var row = document.createElement('div'); row.className = 'rq-coderow'; row.appendChild(ta); if (!tm) row.appendChild(chk); q.appendChild(row);
    var c = common(q, tm);
    var run = function () { if (!window.RCheck) return { ok: false, msg: 'The code checker did not load.' }; try { return window.RCheck.check(ta.value, sols, opts); } catch (e) { return { ok: false, msg: 'The checker could not handle this code.' }; } };
    ta.addEventListener('keydown', function (e) {
      e.stopPropagation();
      if (e.key === 'Tab' && !e.shiftKey) { e.preventDefault(); var a = ta.selectionStart; ta.value = ta.value.slice(0, a) + '  ' + ta.value.slice(ta.selectionEnd); ta.selectionStart = ta.selectionEnd = a + 2; }
      if (e.key === 'Enter' && (e.ctrlKey || e.metaKey) && !tm) { e.preventDefault(); go(); }
    });
    if (tm) { ta.addEventListener('input', function () { q._answer = { ok: !!run().ok, given: ta.value, blank: !ta.value.trim() }; }); return; }
    function go() {
      if (!ta.value.trim()) return;
      var r = run(), fb = q.querySelector('.rq-feedback');
      ta.classList.remove('is-correct', 'is-wrong');
      if (!r.ok && /^Could not read/.test(r.msg)) { fb.className = 'rq-feedback is-info'; fb.innerHTML = '⚠ ' + lite(r.msg) + ' <small>(not counted as a try)</small>'; return; }
      ta.classList.add(r.ok ? 'is-correct' : 'is-wrong'); commit(q, r.ok); feedback(q, r.ok, r.ok ? '' : '<br>' + lite(r.msg));
      if (r.ok) { ta.readOnly = true; chk.disabled = true; }
    }
    chk.addEventListener('click', go);
    showAnswer(q, c, function () { ta.readOnly = true; chk.disabled = true; });
    var p = prior(q); if (p) { ta.value = revealText(q); ta.readOnly = true; chk.disabled = true; ta.classList.add('is-correct'); feedback(q, true); }
  }
  function initOrder(q, tm) {
    var id = q.getAttribute('data-id'), want = q.getAttribute('data-hash'), list = q.querySelector('ul,ol'); if (!list) return;
    var items = Array.prototype.slice.call(list.children).map(function (li, i) { return { html: li.innerHTML, i: i }; });
    var correct = items.map(function (x) { return x.i; }).join('-'), tries = 0;
    do { shuffle(items); tries++; } while (items.map(function (x) { return x.i; }).join('-') === correct && tries < 20 && items.length > 1);
    var ol = document.createElement('ol'); ol.className = 'rq-order';
    function draw() { ol.innerHTML = ''; items.forEach(function (it, pos) {
      var li = document.createElement('li'); li.setAttribute('data-i', it.i); li.innerHTML = '<span class="rq-step">' + it.html + '</span><span class="rq-mv"><button type="button" aria-label="move up">▲</button><button type="button" aria-label="move down">▼</button></span>';
      var bs = li.querySelectorAll('button');
      bs[0].disabled = pos === 0; bs[1].disabled = pos === items.length - 1;
      bs[0].addEventListener('click', function () { var t = items[pos - 1]; items[pos - 1] = items[pos]; items[pos] = t; draw(); sync(); });
      bs[1].addEventListener('click', function () { var t = items[pos + 1]; items[pos + 1] = items[pos]; items[pos] = t; draw(); sync(); });
      ol.appendChild(li); }); }
    var key = function () { return hash(id + '|' + items.map(function (x) { return x.i; }).join('-')); };
    function sync() { if (tm) q._answer = { ok: key() === want, given: items.map(function (x) { return x.i; }).join('-') }; }
    list.parentNode.replaceChild(ol, list); draw(); sync();
    var c = common(q, tm); if (tm) return;
    var chk = document.createElement('button'); chk.type = 'button'; chk.className = 'rq-btn'; chk.textContent = 'Check order'; q.insertBefore(chk, q.querySelector('.rq-feedback'));
    var lock = function () { chk.disabled = true; ol.querySelectorAll('button').forEach(function (b) { b.disabled = true; }); };
    chk.addEventListener('click', function () { var g = key() === want; commit(q, g); feedback(q, g); if (g) lock(); });
    showAnswer(q, c, function () { lock(); items.sort(function (a, b) { return a.i - b.i; }); draw(); ol.querySelectorAll('button').forEach(function (b) { b.disabled = true; }); });
    if (prior(q)) { items.sort(function (a, b) { return a.i - b.i; }); draw(); lock(); feedback(q, true); }
  }
  function initSpot(q, tm) {
    var id = q.getAttribute('data-id'), want = q.getAttribute('data-hash'), list = q.querySelector('ul,ol'); if (!list) return;
    var sel = {}, wrap = document.createElement('div'); wrap.className = 'rq-spot';
    var btns = Array.prototype.slice.call(list.children).map(function (li, i) { var b = document.createElement('button'); b.type = 'button'; b.className = 'rq-sentence'; b.innerHTML = '<span class="rq-flag">⚑</span><span>' + li.innerHTML + '</span>'; wrap.appendChild(b);
      b.addEventListener('click', function () { if (b.disabled) return; sel[i] = !sel[i]; b.classList.toggle('is-flagged', !!sel[i]); sync(); }); return b; });
    list.parentNode.replaceChild(wrap, list);
    var key = function () { return hash(id + '|' + Object.keys(sel).filter(function (k) { return sel[k]; }).map(Number).sort(function (a, b) { return a - b; }).join(',')); };
    function sync() { if (tm) q._answer = { ok: key() === want, given: Object.keys(sel).filter(function (k) { return sel[k]; }).join(',') }; }
    var hintTxt = document.createElement('div'); hintTxt.className = 'rq-hintline'; hintTxt.textContent = 'Flag EVERY flawed sentence (click to flag), then check.'; q.insertBefore(hintTxt, wrap);
    var c = common(q, tm); if (tm) return;
    var chk = document.createElement('button'); chk.type = 'button'; chk.className = 'rq-btn'; chk.textContent = 'Check flags'; q.insertBefore(chk, q.querySelector('.rq-feedback'));
    var lock = function () { chk.disabled = true; btns.forEach(function (b) { b.disabled = true; }); };
    chk.addEventListener('click', function () { var g = key() === want; commit(q, g); feedback(q, g); if (g) lock(); });
    showAnswer(q, c, lock);
    if (prior(q)) { lock(); feedback(q, true); }
  }

  /* ── test mode (pre / post) ─────────────────────────────────────────── */
  function practiseNext(r) {
    var SK = window.RQ_SK; if (!SK || !window.RQ_TAGMAP) return '';
    var list = SK.missed(state, r.byTag, window.RQ_TAGMAP, today(), 6);
    if (!list.length) return '<p><b>Practise next:</b> nothing flagged. Try the next world on the <a href="campus.html">Campus</a>.</p>';
    return '<h4>Practise next</h4><ul class="rq-practise">' + list.map(function (x) { return '<li><b>' + esc(x.skill.id + ' · ' + x.skill.name) + '</b>' + (x.m.worlds.length ? ' — ' + worldLinks(x.m.worlds) : '') + '</li>'; }).join('') + '</ul><p class="rq-small">See the whole picture on the <a href="campus.html">Campus</a>.</p>';
  }
  function readyAdvice(r) {
    var weak = Object.keys(r.byTag).filter(function (t) { return r.byTag[t][0] < r.byTag[t][1]; }).sort().join(', ');
    var tier = r.pct >= 80 ? ['Ready', 'You can skip Regions 1–2: take the <a href="pretest.html">pre-test</a>, then start <b>Region 3 · Regression</b> on the <a href="index.html">map</a>.']
      : r.pct >= 50 ? ['Nearly ready', 'Brush up on <b>' + esc(weak) + '</b> with the library pages (<a href="../r-foundations/data-wrangling.html">Data Wrangling</a>, <a href="../r-foundations/getting-started.html">Getting Started</a>), then take the <a href="pretest.html">pre-test</a>.']
      : ['Not yet', 'Start at <b>Region 1 · Basics</b> on the <a href="index.html">map</a>. Until its worlds open, read <a href="../r-foundations/getting-started.html">Getting Started</a> and <a href="../r-foundations/data-wrangling.html">Data Wrangling</a>, then retake this check.'];
    return '<p class="rq-gain"><b>' + tier[0] + '.</b> ' + tier[1] + '</p><p class="rq-small">This check is advice only; nothing is locked. The two coding tasks are checked without running R: any correct way of writing the code passes.</p>';
  }
  function initTest(box) {
    var kind = box.getAttribute('data-test'), items = box.querySelectorAll('.rq-item');
    items.forEach(function (q) {
      var conf = document.createElement('div'); conf.className = 'rq-conf'; conf.innerHTML = 'How sure are you? ' +
        ['Guess|1', 'Probably|2', 'Certain|3'].map(function (x) { var p = x.split('|'); return '<label><input type="radio" name="c-' + q.getAttribute('data-id') + '" value="' + p[1] + '"> ' + p[0] + '</label>'; }).join(' ');
      q.appendChild(conf);
    });
    var done = state.tests[kind];
    var sub = document.createElement('button'); sub.type = 'button'; sub.className = 'rq-btn rq-big'; sub.textContent = done ? 'Retake: submit again' : 'Submit test'; box.appendChild(sub);
    var res = document.createElement('div'); res.className = 'rq-results'; box.appendChild(res);
    function showResult(r) {
      var pre = /post$/.test(kind) ? state.tests[kind.replace(/post$/, 'pre')] : null, gain = pre ? '<p class="rq-gain">Pre-test ' + pre.pct + '% → Post-test ' + r.pct + '% (<b>' + (r.pct - pre.pct >= 0 ? '+' : '') + (r.pct - pre.pct) + ' points</b>)</p>' : '';
      var tags = Object.keys(r.byTag).sort().map(function (t) { var v = r.byTag[t]; return '<tr><td>' + esc(t) + '</td><td>' + v[0] + ' / ' + v[1] + '</td><td><span class="rq-bar"><i style="width:' + Math.round(100 * v[0] / v[1]) + '%"></i></span></td></tr>'; }).join('');
      var cal = r.confN ? '<p>Confidence check: you were “certain” on ' + r.certain + ' answers and ' + r.certainRight + ' were right' + (r.certain && r.certainRight < r.certain ? ' — keep an eye on over-confidence.' : '.') + '</p>' : '';
      res.innerHTML = '<h3>' + r.score + ' / ' + r.total + ' (' + r.pct + '%)</h3>' + gain + cal + '<table class="rq-tagtable"><thead><tr><th>Skill</th><th>Right</th><th></th></tr></thead><tbody>' + tags + '</tbody></table>' +
        (kind === 'ready' ? readyAdvice(r) : '<p class="rq-small">Answers are not shown in test mode.</p>' + practiseNext(r));
    }
    if (done) showResult(done);
    sub.addEventListener('click', function () {
      var score = 0, byTag = {}, certain = 0, certainRight = 0, confN = 0;
      items.forEach(function (q) { var a = q._answer || { ok: false }, ok = !!a.ok; if (ok) score++;
        var cv = (q.querySelector('input[type=radio]:checked') || {}).value; if (cv) { confN++; if (cv === '3') { certain++; if (ok) certainRight++; } }
        (q.getAttribute('data-tags') || 'other').split(',').filter(Boolean).forEach(function (t) { byTag[t] = byTag[t] || [0, 0]; byTag[t][1]++; if (ok) byTag[t][0]++; }); });
      var r = { score: score, total: items.length, pct: Math.round(100 * score / items.length), byTag: byTag, certain: certain, certainRight: certainRight, confN: confN, ts: today() };
      state.tests[kind] = r; if (state.tests.pre && state.tests.post) {} touchStreak(); save(); showResult(r); checkBadges(); save(); renderHUD();
      toast('📋 ' + (/pre$/.test(kind) ? 'Baseline' : kind === 'ready' ? 'Placement' : 'Post-test') + ' saved: ' + r.pct + '%');
    });
  }

  /* ── world pages: gate + progress ───────────────────────────────────── */
  function worldCfg(id) { var w = (window.RQ_WORLDS || []).filter(function (x) { return x.id === id; })[0]; return w || null; }
  /* requires: "a:60" one condition · "a:60|b:80" any of · "a:60;b:1" all of (";" binds loosest) */
  function gateMet(req) {
    if (!req) return { ok: true };
    var unmet = [];
    req.split(';').forEach(function (term) {
      var alts = term.split('|').map(gateOne); if (alts.some(function (g) { return g.ok; })) return;
      unmet.push(alts.map(function (g) { return g.msg; }).join(' <i>or</i> '));
    });
    return unmet.length ? { ok: false, msg: unmet.join(' <i>and</i> ') } : { ok: true };
  }
  function gateOne(req) {
    var p = req.split(':'), id = p[0], need = parseInt(p[1] || '70', 10), w = worldCfg(id), have = worldPct(id, w ? w.total : 0);
    if (id === 'pre') return { ok: !!state.tests.pre, msg: 'Complete the <b>pre-test</b> first.' };
    if (id === 'ready') return { ok: !!state.tests.ready && state.tests.ready.pct >= need, msg: 'Score <b>' + need + '%</b> in the <a href="readiness.html"><b>placement check</b></a>' + (state.tests.ready ? ' (you have ' + state.tests.ready.pct + '%)' : '') + '.' };
    var rt = /^r(\d)(pre|post)$/.exec(id);                                  // a region test: r1pre, r1post, r2pre, r2post …
    if (rt) { var tr = state.tests[id], pre = rt[2] === 'pre', nm = 'Region ' + rt[1] + (pre ? ' pre-test' : ' post-test'), hr = id.replace(/pre$/, 'pretest').replace(/post$/, 'posttest') + '.html';
      return { ok: pre ? !!tr : !!tr && tr.pct >= need, msg: pre ? 'Take the <a href="' + hr + '"><b>' + nm + '</b></a> first (a baseline, not graded).' : 'Reach <b>' + need + '%</b> in the <a href="' + hr + '"><b>' + nm + '</b></a>' + (tr ? ' (you have ' + tr.pct + '%)' : '') + '.' }; }
    return { ok: have >= need, msg: 'Reach <b>' + need + '%</b> in <b>' + esc(w ? w.title : id) + '</b> (you have ' + have + '%).' };
  }
  function initWorld(el) {
    var req = el.getAttribute('data-requires'), g = gateMet(req);
    var total = parseInt(el.getAttribute('data-total') || '0', 10), id = el.getAttribute('data-world');
    el.innerHTML = '<div class="rq-worldbar"><span>World progress</span><span class="rq-bar"><i></i></span><b></b></div>';
    var wc = worldCfg(id); if (wc && wc.read && wc.read.length) el.insertAdjacentHTML('beforeend', '<p class="rq-read">📖 <b>Read first:</b> ' + readLinks(wc) + '</p>');
    el.setAttribute('data-ready', '1');
    if (!g.ok) {
      var lock = document.createElement('div'); lock.className = 'rq-lock'; lock.innerHTML = '🔒 <b>Locked.</b> ' + g.msg + ' <button class="rq-btn rq-ghost" id="rq-skip">I know this — unlock anyway</button>';
      el.appendChild(lock); document.body.classList.add('rq-locked');
      lock.querySelector('#rq-skip').addEventListener('click', function () { document.body.classList.remove('rq-locked'); lock.remove(); });
    }
    updateWorldBars();
  }
  function updateWorldBars() {
    document.querySelectorAll('.rq-world[data-ready]').forEach(function (el) {
      var id = el.getAttribute('data-world'), total = parseInt(el.getAttribute('data-total') || '0', 10), pct = worldPct(id, total);
      el.querySelector('.rq-bar i').style.width = pct + '%'; el.querySelector('b').textContent = solvedIn(id) + ' / ' + total + ' (' + pct + '%)';
    });
  }

  /* ── quest map ──────────────────────────────────────────────────────── */
  function readLinks(w) { return (w.read || []).map(function (r) { return '<a href="' + r[0] + '">' + esc(r[1]) + '</a>'; }).join(' · '); }
  function worldCard(w) {
    var pct = w.total ? worldPct(w.id, w.total) : 0, g = w.status === 'playable' ? gateMet(w.requires) : { ok: false }, st = w.status !== 'playable' ? 'soon' : (pct >= 100 ? 'cleared' : (g.ok ? 'open' : 'locked'));
    return '<div class="rq-card rq-' + st + '"><div class="rq-ico">' + (w.icon || '★') + '</div><div class="rq-ct"><h3>' + esc(w.title) + '</h3><p>' + esc(w.blurb) + '</p>' +
      (w.status === 'playable' ? '<span class="rq-bar"><i style="width:' + pct + '%"></i></span><small>' + solvedIn(w.id) + ' / ' + w.total + ' items · ' + (st === 'locked' ? '🔒 locked' : st === 'cleared' ? '✔ cleared' : 'open') + '</small>' : '<small>🚧 coming soon (' + esc(w.phase || 'see roadmap') + ')</small>') +
      (w.read && w.read.length ? '<small class="rq-read">📖 Read first: ' + readLinks(w) + '</small>' : '') +
      '</div>' + (w.status === 'playable' ? '<a class="rq-btn" href="' + w.href + '">' + (st === 'locked' ? 'Preview' : pct ? 'Continue' : 'Start') + '</a>' : '') + '</div>';
  }
  function initMap(el) {
    var W = window.RQ_WORLDS || [], R = window.RQ_REGIONS || [{ id: undefined, title: '', blurb: '' }], html = '';
    R.forEach(function (r) {
      var ws = W.filter(function (w) { return w.region === r.id; }); if (!ws.length) return;
      var playable = ws.filter(function (w) { return w.status === 'playable'; }).length;
      html += '<section class="rq-region"><h2>' + esc(r.title) + (playable ? '' : ' <small>coming soon</small>') + '</h2><p>' + esc(r.blurb) + '</p>' + ws.map(worldCard).join('') + '</section>';
    });
    el.innerHTML = html;
    var sh = document.getElementById('rq-badges');
    if (sh) sh.innerHTML = BADGES.map(function (b) { var got = state.badges[b.id]; return '<div class="rq-badge' + (got ? ' got' : '') + '" title="' + esc(b.desc) + '"><span>' + (got ? b.icon : '❔') + '</span><small>' + esc(b.name) + '</small></div>'; }).join('') +
      (window.RQ_WORLDS || []).filter(function (w) { return state.badges['clear-' + w.id]; }).map(function (w) { return '<div class="rq-badge got" title="World cleared"><span>' + (w.icon || '🏁') + '</span><small>' + esc(w.title) + '</small></div>'; }).join('');
  }
  function initData() {
    var ex = document.getElementById('rq-export'), im = document.getElementById('rq-import'), rs = document.getElementById('rq-reset');
    if (ex) ex.addEventListener('click', function () { var a = document.createElement('a'); a.href = URL.createObjectURL(new Blob([JSON.stringify(state, null, 1)], { type: 'application/json' })); a.download = 'dungeons-progress.json'; a.click(); });
    if (im) im.addEventListener('change', function () { var f = im.files[0]; if (!f) return; var fr = new FileReader(); fr.onload = function () { try { var s = JSON.parse(fr.result); if (s && s.v === 1) { state = s; save(); location.reload(); } else toast('Not a progress file'); } catch (e) { toast('Could not read file'); } }; fr.readAsText(f); });
    if (rs) rs.addEventListener('click', function () { if (confirm('Erase all progress on this device?')) { state = blank(); save(); location.reload(); } });
  }

  /* ── dataset bar: a download button beside every question that needs data ── */
  function addDataBar(q) {
    var ids = (q.getAttribute('data-data') || '').split(',').filter(Boolean), reg = window.RQ_DATA || {};
    ids = ids.filter(function (d) { return reg[d]; }); if (!ids.length || q.querySelector('.rq-data')) return;
    var bar = document.createElement('div'); bar.className = 'rq-data';
    bar.innerHTML = '<span class="rq-data-t">📎 Data for this question</span>' + ids.map(function (d) {
      var r = reg[d];
      return '<span class="rq-data-i"><a class="rq-btn rq-ghost" href="../data/' + r.file + '" download="' + r.file + '">⬇ ' + esc(r.file) + '</a>' +
        '<small>' + esc(r.label) + ' · load with <code>' + esc(r.obj) + ' &lt;- read_csv("data/' + esc(r.file) + '")</code> · columns: ' + esc(r.cols) + '</small></span>';
    }).join('');
    var anchor = q.querySelector('.rq-options, .rq-fill, .rq-order, .rq-spot, .rq-coderow, ul, ol');
    if (anchor) anchor.parentNode.insertBefore(bar, anchor); else q.appendChild(bar);
  }

  /* ── campus: recommender, review queue, skill tree, profile, settings ─── */
  function worldLinks(worlds) {
    return worlds.map(function (id) { var w = worldCfg(id); return w && w.href ? '<a href="' + w.href + '">' + esc(w.title.replace(/^World \d+ · /, '')) + '</a>' : ''; }).filter(Boolean).join(', ');
  }
  function initCampus(el) {
    var SK = window.RQ_SK, tm = window.RQ_TAGMAP || {}, t = today(), m = SK.all(state, tm, t), html = '';
    var rec3 = SK.recommend(state, tm, t, 3), due = SK.dueReview(state, tm, t, 5), xp = totalXP(), rk = rankOf(xp);
    var card = function (x, tag) { return '<div class="rq-rec"><b>' + esc(x.skill.id + ' · ' + x.skill.name) + '</b><small>' + esc(x.why) + '</small>' +
      (x.m.worlds.length ? '<span>Practise in: ' + worldLinks(x.m.worlds) + '</span>' : '') + '</div>'; };
    html += '<h2>What next?</h2>' + (rec3.length ? '<div class="rq-recs">' + rec3.map(card).join('') + '</div>' : '<p>Nothing recommended yet: start with the <a href="readiness.html">placement check</a> and the <a href="pretest.html">pre-test</a>, then open World 1.</p>');
    html += '<h2>Daily review</h2>' + (due.length ? '<div class="rq-recs">' + due.map(card).join('') + '</div>' : '<p>Nothing is fading. Skills you have not used for ' + SK.FADE_DAYS + ' days appear here.</p>');
    html += '<h2>Skill tree</h2><p class="rq-small">Level 0 unseen · 1 seen · 2 practising · 3 proficient (first-try solves, no hints). Greyed skills have no items yet. Hover a skill for its prerequisites.</p>';
    SK.BRANCHES.forEach(function (b) {
      var sk = SK.SKILLS.filter(function (s) { return s.branch === b[0]; });
      html += '<h3>' + esc(b[0] + ' · ' + b[1]) + '</h3><div class="rq-tree">' + sk.map(function (s) {
        var x = m[s.id], st = x.empty ? 'none' : (SK.unlocked(s, m) ? 'l' + x.level : 'lock');
        var req = s.req.length ? 'Needs: ' + s.req.join(', ') : 'No prerequisites';
        return '<div class="rq-skill rq-' + st + (x.fading ? ' rq-fading' : '') + '" title="' + esc(req + (x.empty ? ' · no items yet' : ' · ' + x.first + '/' + x.need + ' first-try')) + '"><small>' + s.id + '</small><b>' + esc(s.name) + '</b>' +
          '<span class="rq-pips">' + [1, 2, 3].map(function (i) { return '<i' + (x.level >= i ? ' class="on"' : '') + '></i>'; }).join('') + '</span>' + (x.fading ? '<em>fading</em>' : '') + '</div>';
      }).join('') + '</div>';
    });
    html += '<p class="rq-small"><b>Coming in later phases:</b> ' + SK.PLANNED.map(esc).join(' · ') + '</p>';
    var n = Object.keys(state.items).filter(function (k) { return state.items[k].solved; }).length, tests = ['ready', 'pre', 'post'].filter(function (k) { return state.tests[k]; }).map(function (k) { return k + ' ' + state.tests[k].pct + '%'; });
    html += '<h2>Profile</h2><p>' + esc(rk.name) + ' · ⭐ ' + xp + ' XP · 🔥 ' + state.streak.count + '-day streak (best ' + state.streak.best + ') · ' + n + ' items solved · ' + Object.keys(state.badges).length + ' badges' + (tests.length ? ' · tests: ' + esc(tests.join(', ')) : '') + '</p>' +
      '<h2>Settings</h2><label><input type="checkbox" id="rq-calm"' + (state.settings.calm ? ' checked' : '') + '> Calm mode: hide streaks and pop-up toasts</label>';
    el.innerHTML = html;
    var c = el.querySelector('#rq-calm'); if (c) c.addEventListener('change', function () { state.settings.calm = c.checked; applySettings(); save(); });
  }
  function applySettings() { document.body.classList.toggle('rq-calm', !!state.settings.calm); }

  /* ── boot ───────────────────────────────────────────────────────────── */
  function init() {
    if (!document.body.classList.contains('rq-page')) document.body.classList.add('rq-page');
    document.querySelectorAll('.rq-item').forEach(function (q) {
      if (q.getAttribute('data-ready')) return; q.setAttribute('data-ready', '1');
      var tm = !!q.closest('.rq-test'), t = q.getAttribute('data-type');
      if (!tm) rec(q);
      if (t === 'mcq') initMCQ(q, tm); else if (t === 'fill') textLike(q, tm, 'fill'); else if (t === 'num') textLike(q, tm, 'num');
      else if (t === 'order') initOrder(q, tm); else if (t === 'spot') initSpot(q, tm); else if (t === 'code') initCode(q, tm);
    });
    document.querySelectorAll('.rq-item').forEach(addDataBar);
    document.querySelectorAll('.rq-test').forEach(initTest);
    document.querySelectorAll('.rq-world').forEach(initWorld);
    var m = document.getElementById('rq-map'); if (m) initMap(m);
    var cp = document.getElementById('rq-campus'); if (cp && window.RQ_SK) initCampus(cp);
    applySettings();
    initData(); renderHUD(); save();
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init); else init();
  window.Quest = { today: today, hash: hash, normalise: normalise, numKey: numKey, state: function () { return state; }, totalXP: totalXP, rankOf: rankOf, BADGES: BADGES, itemXP: itemXP };
})();
