/* cohort.js — facilitator tool: combine learners' exported progress files in the browser.
   Nothing is uploaded. summarise() is pure (unit-tested in tests/cohort_test.js). */
(function (root) {
  'use strict';
  var RANKS = [[0, 'Field Volunteer'], [100, 'Health Worker'], [250, 'Medical Officer'], [500, 'Epidemiologist'], [900, 'Senior Epidemiologist'], [1500, 'Chief Biostatistician']];
  var BASE = { 1: 10, 2: 20, 3: 30 }, HINT_COST = [3, 5, 8];
  function itemXP(r) {
    if (!r || !r.solved || r.shown) return 0;
    var cost = 0; for (var i = 0; i < (r.hints || 0); i++) cost += HINT_COST[Math.min(i, 2)];
    var f = r.tries <= 1 ? 1 : r.tries === 2 ? 0.5 : 0.25;
    return Math.max(0, Math.round((BASE[r.diff] || 10) * f - cost) + (r.boss ? 50 : 0));
  }
  function rank(xp) { var n = RANKS[0][1]; RANKS.forEach(function (r) { if (xp >= r[0]) n = r[1]; }); return n; }
  function pct(t) { return t && typeof t.pct === 'number' ? t.pct : null; }
  /* files: [{ name, state }]  → { rows, tags, n } */
  function summarise(files) {
    var rows = [], tags = {};
    files.forEach(function (f) {
      var s = f.state; if (!s || s.v !== 1 || !s.items) return;
      var xp = 0, solved = 0, worlds = {}, bosses = {};
      Object.keys(s.items).forEach(function (k) { var r = s.items[k]; xp += itemXP(r); if (r.solved) { solved++; worlds[r.world] = (worlds[r.world] || 0) + 1; } if (r.boss && r.solved) bosses[r.world] = true; });
      var pre = pct(s.tests && s.tests.pre), post = pct(s.tests && s.tests.post);
      rows.push({ name: f.name, xp: xp, rank: rank(xp), solved: solved, worlds: Object.keys(worlds).filter(function (w) { return /^w\d+$/.test(w); }).length,
        bosses: Object.keys(bosses).length, ready: pct(s.tests && s.tests.ready), pre: pre, post: post, gain: pre !== null && post !== null ? post - pre : null, streak: (s.streak && s.streak.best) || 0 });
      var t = s.tests && s.tests.pre;
      if (t && t.byTag) Object.keys(t.byTag).forEach(function (g) { tags[g] = tags[g] || [0, 0]; tags[g][0] += t.byTag[g][0]; tags[g][1] += t.byTag[g][1]; });
    });
    return { rows: rows, tags: tags, n: rows.length };
  }
  function mean(a) { a = a.filter(function (x) { return x !== null; }); return a.length ? Math.round(10 * a.reduce(function (x, y) { return x + y; }, 0) / a.length) / 10 : null; }
  function totals(sum) { var r = sum.rows; return { n: sum.n, pre: mean(r.map(function (x) { return x.pre; })), post: mean(r.map(function (x) { return x.post; })), gain: mean(r.map(function (x) { return x.gain; })), xp: mean(r.map(function (x) { return x.xp; })) }; }
  function weakest(sum, k) { return Object.keys(sum.tags).filter(function (g) { return sum.tags[g][1] >= 3; }).map(function (g) { return { tag: g, right: sum.tags[g][0], total: sum.tags[g][1], pct: Math.round(100 * sum.tags[g][0] / sum.tags[g][1]) }; })
    .sort(function (a, b) { return a.pct - b.pct || (a.tag < b.tag ? -1 : 1); }).slice(0, k || 8); }
  function csv(sum) {
    var cols = ['name', 'xp', 'rank', 'solved', 'worlds', 'bosses', 'ready', 'pre', 'post', 'gain', 'streak'];
    var q = function (v) { v = v === null || v === undefined ? '' : String(v); return /[",\n]/.test(v) ? '"' + v.replace(/"/g, '""') + '"' : v; };
    return [cols.join(',')].concat(sum.rows.map(function (r) { return cols.map(function (c) { return q(r[c]); }).join(','); })).join('\n');
  }
  var api = { summarise: summarise, totals: totals, weakest: weakest, csv: csv, itemXP: itemXP };
  if (typeof module !== 'undefined' && module.exports) module.exports = api; else root.RQ_COHORT = api;
  /* UI: <div id="rq-cohort"></div> */
  if (typeof document !== 'undefined') document.addEventListener('DOMContentLoaded', function () {
    var el = document.getElementById('rq-cohort'); if (!el) return;
    el.innerHTML = '<p><input type="file" id="rq-cf" accept="application/json,.json" multiple> <button class="rq-btn" id="rq-ccsv" disabled>Download CSV</button></p><div id="rq-cout"></div>';
    var last = null, out = el.querySelector('#rq-cout'), esc = function (s) { return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;'); }, f = function (v, u) { return v === null ? '–' : v + (u || ''); };
    el.querySelector('#rq-cf').addEventListener('change', function (e) {
      var fs = Array.prototype.slice.call(e.target.files), got = [];
      Promise.all(fs.map(function (file) { return file.text().then(function (t) { try { got.push({ name: file.name.replace(/\.json$/i, ''), state: JSON.parse(t) }); } catch (x) {} }); })).then(function () {
        last = summarise(got); var T = totals(last), W = weakest(last, 8);
        out.innerHTML = '<p><b>' + last.n + '</b> learners read (' + (fs.length - last.n) + ' files skipped). Mean pre ' + f(T.pre, '%') + ' · post ' + f(T.post, '%') + ' · gain ' + f(T.gain, ' points') + ' · XP ' + f(T.xp) + '</p>' +
          '<table class="rq-tagtable"><thead><tr><th>Learner</th><th>Rank</th><th>XP</th><th>Solved</th><th>Bosses</th><th>Ready</th><th>Pre</th><th>Post</th><th>Gain</th></tr></thead><tbody>' +
          last.rows.map(function (r) { return '<tr><td>' + esc(r.name) + '</td><td>' + esc(r.rank) + '</td><td>' + r.xp + '</td><td>' + r.solved + '</td><td>' + r.bosses + '</td><td>' + f(r.ready, '%') + '</td><td>' + f(r.pre, '%') + '</td><td>' + f(r.post, '%') + '</td><td>' + f(r.gain) + '</td></tr>'; }).join('') + '</tbody></table>' +
          (W.length ? '<h3>Weakest skills in the pre-test (cohort)</h3><table class="rq-tagtable"><tbody>' + W.map(function (w) { return '<tr><td>' + esc(w.tag) + '</td><td>' + w.right + ' / ' + w.total + '</td><td><span class="rq-bar"><i style="width:' + w.pct + '%"></i></span></td></tr>'; }).join('') + '</tbody></table>' : '');
        el.querySelector('#rq-ccsv').disabled = !last.n;
      });
    });
    el.querySelector('#rq-ccsv').addEventListener('click', function () { if (!last) return; var a = document.createElement('a'); a.href = URL.createObjectURL(new Blob([csv(last)], { type: 'text/csv' })); a.download = 'cohort-summary.csv'; a.click(); });
  });
})(typeof window !== 'undefined' ? window : this);
