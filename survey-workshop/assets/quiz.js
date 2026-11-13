/* ═══════════════════════════════════════════════════════════════════════
 * quiz.js — tiny self-check quiz engine for reveal.js / any HTML page
 * ---------------------------------------------------------------------
 * Vanilla JS, zero dependencies, works offline (file://) and inside
 * Quarto reveal.js decks with embed-resources.
 *
 * SYNTAX (what lives in the .qmd — a Pandoc fenced div with data-attrs)
 * ---------------------------------------------------------------------
 *   MCQ (single answer)
 *   ::: {.quiz-q data-qid="s1q1" data-type="mcq" data-hash="<hash>"
 *         data-show="<base64>" data-explain="<base64>"}
 *   Which model suits a binary outcome?
 *
 *   - Linear regression
 *   - Logistic regression
 *   - Cox regression
 *   :::
 *
 *   Fill-in-the-blank
 *   ::: {.quiz-q data-qid="s1q4" data-type="fill" data-hashes="<h1>,<h2>"
 *         data-show="<base64>" data-explain="<base64>"}
 *   Which gtsummary function builds Table 1?
 *   :::
 *
 *   data-qid      unique id (it salts the hashes)
 *   data-hash     hash of the correct option INDEX (0-based) — mcq
 *   data-hashes   comma-separated hashes of each accepted answer — fill
 *   data-show     base64 of the text revealed by "Show answer"
 *   data-explain  base64 of the short explanation (basic `code` allowed)
 *
 * You never write those attributes by hand. Use the R helpers in
 * assets/quiz.R, which take PLAIN text and emit the fenced div:
 *
 *   ```{r}
 *   #| echo: false
 *   #| output: asis
 *   source("assets/quiz.R")
 *   quiz_mcq("s1q1", "Which model suits a binary outcome?",
 *            c("Linear", "Logistic", "Cox"), answer = 2,
 *            explain = "Binary outcome -> logit link -> logistic.")
 *   quiz_fill("s1q4", "Which gtsummary function builds Table 1?",
 *             accept = c("tbl_summary", "tbl_summary()"),
 *             explain = "tbl_summary() summarises variables, optionally by a group.")
 *   ```
 *
 * Optional: <span class="quiz-score"></span> anywhere shows "x / y", followed by
 *   "Save score" (downloads a text file) and "Reset" buttons. The first-attempt
 *   results are kept in localStorage per deck, so a reload keeps the score.
 *
 * BEHAVIOUR
 *   - MCQ: options are SHUFFLED at load (hash uses the authored index, so
 *     data-hash is unaffected; add data-shuffle="0" to keep authored order).
 *     Click an option -> instant ✔/✘; explanation appears after the
 *     attempt (or after "Show answer").
 *   - Fill: type + Enter / "Check". Answers are normalised (case,
 *     surrounding/duplicate whitespace, backticks, trailing "()") before
 *     hashing, so "  TBL_Summary() " matches "tbl_summary".
 *   - Answers are NOT in the page source: only salted hashes are, and the
 *     explanation / reveal text is base64-encoded. This stops casual
 *     view-source peeking; it is NOT cryptographic security.
 *
 * HASH (must match quiz.R exactly): two polynomial rolling hashes over
 *   the string  qid + "|" + value , base-36 encoded and concatenated.
 * ═══════════════════════════════════════════════════════════════════════ */
(function () {
  'use strict';

  var M1 = 2147483629, M2 = 2147483587;

  function hash(str) {
    var a = 5381, b = 52711;
    for (var i = 0; i < str.length; i++) {
      var c = str.charCodeAt(i);
      a = (a * 131 + c) % M1;
      b = (b * 137 + c) % M2;
    }
    return a.toString(36) + '.' + b.toString(36);
  }

  function normalise(s) {
    return String(s).toLowerCase()
      .replace(/`/g, '')
      .replace(/\s+/g, ' ')
      .trim()
      .replace(/\(\s*\)$/, '')   // "tbl_summary()" == "tbl_summary"
      .trim();
  }

  function b64(s) {
    if (!s) return '';
    try {
      var bin = atob(s), bytes = new Uint8Array(bin.length);
      for (var i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
      return new TextDecoder('utf-8').decode(bytes);
    } catch (e) { return ''; }
  }

  function esc(s) {
    return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }
  // escape first, then allow `code` only
  function lite(s) { return esc(s).replace(/`([^`]+)`/g, '<code>$1</code>'); }

  var state = { total: 0, correct: 0, scored: {} };

  // ── saved score ─────────────────────────────────────────────────────
  // The first-attempt result of each question is kept in the browser
  // (localStorage, one entry per deck file), so a reload keeps the score.
  // "Save score" downloads a small text file a participant can keep or
  // hand in; "Reset" clears the saved result for this deck.
  var deckName = (location.pathname.split('/').pop() || 'deck').replace(/\.html?$/, '');
  var STORE = 'quiz-score:' + deckName;
  function persist() { try { localStorage.setItem(STORE, JSON.stringify(state.scored)); } catch (e) {} }
  function restore() {
    try {
      var saved = JSON.parse(localStorage.getItem(STORE)) || {};
      var qs = document.querySelectorAll('.quiz-q');
      for (var i = 0; i < qs.length; i++) {
        var id = qs[i].getAttribute('data-qid');
        if (saved.hasOwnProperty(id)) { state.scored[id] = !!saved[id]; if (saved[id]) state.correct++; }
      }
    } catch (e) {}
  }
  function scoreText() {
    var lines = ['Quiz score', 'Deck: ' + (document.title || deckName), 'File: ' + deckName, 'Saved: ' + new Date().toLocaleString(),
                 'Score (first attempt): ' + state.correct + ' / ' + state.total, ''];
    var qs = document.querySelectorAll('.quiz-q');
    for (var i = 0; i < qs.length; i++) {
      var id = qs[i].getAttribute('data-qid');
      lines.push(id + ': ' + (state.scored.hasOwnProperty(id) ? (state.scored[id] ? 'correct' : 'not correct') : 'not attempted'));
    }
    return lines.join('\n') + '\n';
  }
  function download() {
    var a = document.createElement('a');
    a.href = 'data:text/plain;charset=utf-8,' + encodeURIComponent(scoreText());
    a.download = 'quiz_' + deckName + '.txt';
    document.body.appendChild(a); a.click(); a.remove();
  }
  function addScoreTools() {
    var els = document.querySelectorAll('.quiz-score');
    for (var i = 0; i < els.length; i++) {
      if (els[i].getAttribute('data-tools')) continue;
      els[i].setAttribute('data-tools', '1');
      var box = document.createElement('span'); box.className = 'quiz-score-tools';
      var sv = document.createElement('button'); sv.type = 'button'; sv.className = 'quiz-btn quiz-btn-ghost quiz-save'; sv.textContent = 'Save score';
      sv.addEventListener('click', download);
      var rs = document.createElement('button'); rs.type = 'button'; rs.className = 'quiz-btn quiz-btn-ghost quiz-reset'; rs.textContent = 'Reset';
      rs.addEventListener('click', function () { try { localStorage.removeItem(STORE); } catch (e) {} location.reload(); });
      box.appendChild(sv); box.appendChild(rs);
      els[i].parentNode.insertBefore(box, els[i].nextSibling);
    }
  }

  function updateScores() {
    var els = document.querySelectorAll('.quiz-score');
    for (var i = 0; i < els.length; i++) {
      els[i].textContent = state.correct + ' / ' + state.total;
    }
  }

  function record(qid, ok) {
    if (state.scored.hasOwnProperty(qid)) return;      // first attempt only
    state.scored[qid] = !!ok;
    if (ok) state.correct++;
    persist();
    updateScores();
  }

  function feedback(q, ok, msg) {
    var fb = q.querySelector('.quiz-feedback');
    fb.className = 'quiz-feedback ' + (ok ? 'is-correct' : 'is-wrong');
    fb.innerHTML = (ok ? '✔ Correct. ' : '✘ Not quite. ') + (msg ? lite(msg) : '');
  }

  function explanation(q) {
    var ex = b64(q.getAttribute('data-explain'));
    return ex;
  }

  function buildCommon(q) {
    var fb = document.createElement('div');
    fb.className = 'quiz-feedback';
    fb.setAttribute('aria-live', 'polite');
    q.appendChild(fb);

    var show = document.createElement('button');
    show.type = 'button';
    show.className = 'quiz-btn quiz-btn-ghost';
    show.textContent = 'Show answer';
    q.appendChild(show);
    return { fb: fb, show: show };
  }

  function initMCQ(q) {
    var qid = q.getAttribute('data-qid');
    var correctHash = q.getAttribute('data-hash');
    var list = q.querySelector('ul, ol');
    if (!list) return;
    // authored index is what the hash is built on; DISPLAY order is shuffled so the
    // answer position (and any length/position tell) cannot be learned.
    var items = Array.prototype.slice.call(list.children).map(function (li, i) { return { li: li, i: i }; });
    if (q.getAttribute('data-shuffle') !== '0') {
      for (var k = items.length - 1; k > 0; k--) {
        var r = Math.floor(Math.random() * (k + 1)), t = items[k]; items[k] = items[r]; items[r] = t;
      }
    }
    var wrap = document.createElement('div');
    wrap.className = 'quiz-options';
    var btns = items.map(function (it, pos) {
      var b = document.createElement('button');
      b.type = 'button';
      b.className = 'quiz-option';
      b.setAttribute('data-i', it.i);
      b.innerHTML = '<span class="quiz-letter">' + String.fromCharCode(65 + pos) + '</span>' + it.li.innerHTML;
      wrap.appendChild(b);
      return b;
    });
    list.parentNode.replaceChild(wrap, list);
    var c = buildCommon(q);

    function isCorrect(i) { return hash(qid + '|' + i) === correctHash; }
    function orig(b) { return parseInt(b.getAttribute('data-i'), 10); }
    function reveal() {
      btns.forEach(function (b) { if (isCorrect(orig(b))) b.classList.add('is-correct'); });
    }

    btns.forEach(function (b) {
      b.addEventListener('click', function () {
        var ok = isCorrect(orig(b));
        b.classList.add(ok ? 'is-correct' : 'is-wrong');
        record(qid, ok);
        feedback(q, ok, explanation(q));
        if (ok) btns.forEach(function (x) { x.disabled = true; });
      });
    });
    c.show.addEventListener('click', function () {
      reveal();
      record(qid, false);
      var ans = b64(q.getAttribute('data-show'));
      var fb = q.querySelector('.quiz-feedback');
      fb.className = 'quiz-feedback is-info';
      fb.innerHTML = 'Answer: <strong>' + lite(ans) + '</strong>. ' + lite(explanation(q));
      btns.forEach(function (x) { x.disabled = true; });
    });
  }

  function initFill(q) {
    var qid = q.getAttribute('data-qid');
    var accepted = (q.getAttribute('data-hashes') || '').split(',');
    var row = document.createElement('div');
    row.className = 'quiz-fill';
    var input = document.createElement('input');
    input.type = 'text';
    input.className = 'quiz-input';
    input.placeholder = 'type your answer…';
    input.setAttribute('autocomplete', 'off');
    input.setAttribute('autocapitalize', 'off');
    input.setAttribute('spellcheck', 'false');
    var check = document.createElement('button');
    check.type = 'button';
    check.className = 'quiz-btn';
    check.textContent = 'Check';
    row.appendChild(input);
    row.appendChild(check);
    q.appendChild(row);
    var c = buildCommon(q);

    function submit() {
      var v = normalise(input.value);
      if (!v) return;
      var ok = accepted.indexOf(hash(qid + '|' + v)) !== -1;
      input.classList.remove('is-correct', 'is-wrong');
      input.classList.add(ok ? 'is-correct' : 'is-wrong');
      record(qid, ok);
      feedback(q, ok, explanation(q));
    }
    check.addEventListener('click', submit);
    // keep reveal.js shortcuts (space, arrows, f, s, …) out of the text box
    ['keydown', 'keyup', 'keypress'].forEach(function (ev) {
      input.addEventListener(ev, function (e) {
        e.stopPropagation();
        if (ev === 'keydown' && e.key === 'Enter') submit();
      });
    });
    c.show.addEventListener('click', function () {
      record(qid, false);
      var fb = q.querySelector('.quiz-feedback');
      fb.className = 'quiz-feedback is-info';
      fb.innerHTML = 'Answer: <strong>' + lite(b64(q.getAttribute('data-show'))) + '</strong>. ' + lite(explanation(q));
    });
  }

  function init() {
    var qs = document.querySelectorAll('.quiz-q');
    state.total = qs.length;
    for (var i = 0; i < qs.length; i++) {
      var q = qs[i];
      if (q.getAttribute('data-quiz-ready')) continue;
      q.setAttribute('data-quiz-ready', '1');
      var type = q.getAttribute('data-type');
      if (type === 'mcq') initMCQ(q);
      else if (type === 'fill') initFill(q);
    }
    restore();
    addScoreTools();
    updateScores();
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();

  // exposed for tests / tooling
  window.Quiz = { hash: hash, normalise: normalise };
})();
