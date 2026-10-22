// lint_bank.js — Node mirror of lint_bank.R (same H/S rules) PLUS extra "obvious answer" checks (N rules).
// Reads bank/items.R with the R parser in assets/rcheck.js, so it runs where R is not installed.
// Usage: node dungeons/tests/lint_bank.js [--strict]      (--strict: warnings also fail; use for new items)
// Exit 1 on any hard failure (or warning with --strict).
const fs = require('fs'), path = require('path');
const R = require('../assets/rcheck.js');
const src = fs.readFileSync(path.join(__dirname, '..', 'bank', 'items.R'), 'utf8');
const start = src.indexOf('ITEMS <- list(');
const ast = R.parse(src.slice(start))[0].r;            // ITEMS <- list(...)

// ── evaluate literal R values ──
function val(n) {
  switch (n.k) {
    case 'str': case 'num': return n.v;
    case 'id': return n.v === 'TRUE' || n.v === 'T' ? true : n.v === 'FALSE' || n.v === 'F' ? false : n.v === 'NULL' ? null : { sym: n.v };
    case 'un': return n.op === '-' ? -val(n.x) : val(n.x);
    case 'call': {
      const f = n.fn.v, a = n.args;
      if (f === 'c') return [].concat(...a.map(x => val(x.v)));
      if (f === 'list') { const named = a.some(x => x.name); if (!named) return a.map(x => val(x.v)); const o = {}; a.forEach(x => o[x.name] = val(x.v)); return o; }
      throw new Error('cannot evaluate call ' + f);
    }
    case 'bin': if (n.op === ':') { const o = []; for (let i = val(n.l); i <= val(n.r); i++) o.push(i); return o; } break;
  }
  throw new Error('cannot evaluate ' + n.k);
}
const SIGS = { mc: ['id', 'world', 'diff', 'tags', 'stem', 'options', 'answer', 'explain'], nm: ['id', 'world', 'diff', 'tags', 'stem', 'accept', 'dp', 'explain'],
  fl: ['id', 'world', 'diff', 'tags', 'stem', 'accept', 'explain'], od: ['id', 'world', 'diff', 'tags', 'stem', 'steps', 'explain'],
  sp: ['id', 'world', 'diff', 'tags', 'stem', 'sentences', 'flawed', 'explain'], cx: ['id', 'world', 'diff', 'tags', 'stem', 'solutions', 'explain'] };
const TYPE = { mc: 'mcq', nm: 'num', fl: 'fill', od: 'order', sp: 'spot', cx: 'code' };
const ITEMS = ast.args.map(a => {
  const f = a.v.fn.v, sig = SIGS[f]; if (!sig) throw new Error('unknown helper ' + f);
  const it = { type: TYPE[f] }; let i = 0;
  a.v.args.forEach(x => { if (x.name) it[x.name] = val(x.v); else it[sig[i++]] = val(x.v); });
  ['tags', 'options', 'accept', 'steps', 'sentences', 'flawed', 'solutions', 'hints'].forEach(k => { if (it[k] !== undefined && it[k] !== null && !Array.isArray(it[k])) it[k] = [it[k]]; });
  return it;
});
module.exports = { ITEMS };
if (require.main !== module) return;

// ── rules ──
const STOP = new Set(['which', 'that', 'this', 'with', 'what', 'from', 'than', 'their', 'have', 'does', 'your', 'when', 'each', 'into', 'about', 'after', 'other', 'there', 'these', 'those', 'would', 'should', 'could', 'model', 'models', 'regression']);
const words = s => s.toLowerCase().replace(/[^a-z0-9_ ]/g, ' ').split(/\s+/).filter(w => w.length > 3 && !STOP.has(w));
const ABS = ['always', 'never', 'only', 'exactly', 'guarantees', 'guarantee', 'every', 'must', 'completely', 'entirely', 'impossible', 'proves'];
const HEDGE = ['usually', 'often', 'may', 'might', 'can', 'likely', 'typically', 'generally', 'approximately', 'about', 'roughly', 'tends'];
const has = (s, list) => list.some(w => new RegExp('\\b' + w + '\\b', 'i').test(s));
const CUEWORDS = ['therefore', 'proves', 'always', 'never', 'every', 'causes', 'cause', 'exactly', 'clearly', 'definitely'];
const mean = a => a.reduce((x, y) => x + y, 0) / a.length;
const esc = s => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const strict = process.argv.includes('--strict');
let fails = 0, warns = 0; const ids = ITEMS.map(x => x.id);
const counts = {}; ITEMS.forEach(x => counts[x.type] = (counts[x.type] || 0) + 1);
console.log(`${ITEMS.length} items | types: ${Object.entries(counts).map(e => e.join(' ')).join(', ')}`);
const dup = ids.filter((x, i) => ids.indexOf(x) !== i); if (dup.length) { console.log('H8 duplicate ids:', dup.join(' ')); fails++; }
for (const it of ITEMS) {
  const H = [], S = [];
  if (!String(it.explain || '').trim()) H.push('H4 no explanation');
  if (!it.world || !(it.tags || []).length || ![1, 2, 3].includes(it.diff)) H.push('H4 missing world/tags/diff');
  if (/which (\w+ )?(function|argument|package|command)|what (function|argument)|what does `?[A-Za-z_.]+\(\)`? (do|return)|did you use in (task|lab)|name of the (function|argument)/i.test(it.stem)) H.push('H3 function/argument recall');
  let ans = '';
  if (it.type === 'mcq') {
    const o = it.options, nc = o.map(x => x.length), k = it.answer - 1, others = nc.filter((_, i) => i !== k);
    if (o.length < 4) H.push('H7 fewer than 4 options');
    const mx = Math.max(...nc);
    if (nc[k] === mx && nc.filter(x => x === mx).length === 1) H.push(`H1 key strictly longest (${nc[k]} vs ${others.join('/')})`);
    else if (nc[k] > 1.25 * mean(others)) H.push(`H1 key ${Math.round(100 * (nc[k] / mean(others) - 1))}% longer than distractor mean`);
    if (o.some(x => /(all|none|both) of the (above|these)/i.test(x))) H.push('H2 all/none of the above');
    if (mx / Math.min(...nc) >= 2.5) H.push(`H5 lengths differ ${(mx / Math.min(...nc)).toFixed(1)}x`);
    const sw = words(it.stem), ov = o.map(x => words(x).filter(w => sw.includes(w)).length), ovo = ov.filter((_, i) => i !== k);
    if (ov[k] === Math.max(...ov) && ov[k] - Math.max(0, ...ovo) >= 2) S.push('S1 key overlaps stem');
    const ab = o.map(x => has(x, ABS)); if (!ab[k] && ab.filter((v, i) => i !== k && v).length >= 2) S.push('S2 absolutes only in distractors');
    // N rules (extra cues)
    const mn = Math.min(...nc); if (nc[k] === mn && nc.filter(x => x === mn).length === 1 && nc[k] < 0.8 * mean(others)) S.push('N1 key strictly shortest by a wide margin');
    const m = /\b(an?)\s*(…|\.\.\.)?\s*$/i.exec(it.stem.trim()); if (m) { const vow = x => /^[aeiou]/i.test(x.trim()); const fit = o.map(x => (m[1].toLowerCase() === 'an') === vow(x)); if (fit[k] && fit.filter(Boolean).length === 1) S.push('N2 only the key fits "' + m[1] + '" grammatically'); }
    const norm = x => x.toLowerCase().replace(/\s+/g, ' ').trim(); if (new Set(o.map(norm)).size < o.length) H.push('N3 duplicate options');
    const hd = o.map(x => has(x, HEDGE)); if (hd[k] && hd.filter((v, i) => i !== k && v).length === 0 && ab.filter((v, i) => i !== k && v).length >= 1) S.push('N5 only the key is hedged');
    const firstWord = o.map(x => x.split(/\s+/)[0].toLowerCase()); if (firstWord.filter(w => w === firstWord[k]).length === 1 && new Set(firstWord.filter((_, i) => i !== k)).size === 1) S.push('N6 key alone breaks the shared opening of the other options');
    ans = o[k].toLowerCase();
  } else if (it.type === 'fill' || it.type === 'num') {
    ans = String(it.accept[0]).toLowerCase();
    for (const a of it.accept.map(String)) if (a.length >= 3 && new RegExp('(^|[^a-z0-9])' + esc(a.toLowerCase()) + '([^a-z0-9]|$)').test(it.stem.toLowerCase())) H.push(`H6 answer '${a}' appears in stem`);
    if (it.type === 'fill' && it.accept.every(a => /^[A-Za-z_.][A-Za-z0-9_.:]*(\(\))?$/.test(a)) && /function|argument/i.test(it.stem)) H.push('H3 identifier answer to function/argument question');
  } else if (it.type === 'order') { if (it.steps.length < 4) H.push('H7 order needs >=4 steps'); ans = it.steps.join(' ').toLowerCase();
  } else if (it.type === 'spot') {
    if (it.sentences.length < 4 || !it.flawed.length || it.flawed.length >= it.sentences.length) H.push('H7 spot needs >=4 sentences and some (not all) flawed');
    const cue = it.sentences.map(x => has(x, CUEWORDS)), fl = it.flawed.map(i => i - 1);
    if (fl.every(i => cue[i]) && !cue.some((c, i) => c && !fl.includes(i))) S.push('N8 every flawed sentence (and no sound one) carries a cue word (therefore/proves/always/causes…)');
  } else if (it.type === 'code') {
    if (!(it.solutions || []).length || !it.solutions.every(x => String(x).trim())) H.push('H7 code item needs at least one solution');
    for (const sol of it.solutions || []) {
      try { R.canon(sol, it.opts || {}); } catch (e) { H.push('C1 solution does not parse: ' + e.message); }
      if (it.stem.replace(/\s+/g, '').includes(String(sol).replace(/\s+/g, ''))) H.push('C2 the solution is written in the stem');
      const fns = [...new Set((String(sol).match(/[A-Za-z_.][A-Za-z0-9_.]*(?=\()/g) || []))];
      const named = fns.filter(f => new RegExp(esc(f) + '\\s*\\(').test(it.stem));
      if (fns.length >= 2 && named.length >= Math.min(2, fns.length) && named.length >= fns.length - 1) S.push('C3 the stem names the solution\'s functions (' + named.join(', ') + ')');
    }
    if (it.hints) for (const h of it.hints) for (const sol of it.solutions) { try { if (R.check(h, [sol], it.opts || {}).ok) H.push('C4 a hint is itself a correct answer'); } catch (e) {} }
  }
  if ((it.hints || []).length && ans && (it.type === 'fill' || it.type === 'num')) for (const h of it.hints) if (h.toLowerCase().includes(ans)) H.push('H8 hint contains the answer');
  if (it.type === 'mcq' && (it.hints || []).length) for (const h of it.hints) if (h.toLowerCase().includes(ans)) H.push('H8 hint contains the key text');
  if (H.length) fails++; if (S.length) warns++;
  if (H.length || S.length) console.log(`  ${H.length ? 'FAIL' : 'warn'} ${it.id.padEnd(8)} ${[...H, ...S].join(' | ')}`);
}
console.log(`${fails} hard failures, ${warns} with warnings`);
process.exit(fails > 0 || (strict && warns > 0) ? 1 : 0);
