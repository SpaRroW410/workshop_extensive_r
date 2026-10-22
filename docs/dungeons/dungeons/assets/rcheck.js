/* ═══════════════════════════════════════════════════════════════════════
 * rcheck.js — checks pasted R code WITHOUT running R.
 *
 * parse → normalise → compare with the author's solutions. Two programs are
 * "the same" when they reduce to the same canonical form. The normaliser
 * knows the ways people legitimately write the same analysis:
 *   • pipes: x |> f(a) ≡ x %>% f(a) ≡ f(x, a)  (incl. the . and _ placeholders)
 *   • intermediate objects: d <- filter(ncd, …); summarise(d, …) are inlined
 *   • dplyr: filter(a & b) ≡ filter(a, b) ≡ filter(filter(x, a), b); condition
 *     order; 50 <= age ≡ age >= 50; summarize ≡ summarise; .by = ≡ group_by();
 *     count(x, g) ≡ summarise(group_by(x, g), n = n()); trailing ungroup();
 *     subset() and x[cond, ] ≡ filter(); consecutive mutate()s merged
 *   • new column names are free by default (mean_sbp = … ≡ m = …), and later
 *     references to them follow the rename
 *   • arguments by position or by name (lm(f, d) ≡ lm(formula = f, data = d)),
 *     named-argument order, pkg:: prefixes, T/TRUE, 50/50L/50.0, quote style
 *   • formulas: term order (sbp ~ age + salt ≡ sbp ~ salt + age);
 *     family = binomial ≡ binomial() ≡ "binomial"
 *   • ggplot: aes(x, y) ≡ aes(x = , y = ), aes in ggplot() or in the layer,
 *     layer order; library()/print()/View() lines are ignored
 * Options per item: { free_names: true, ignore: ["na.rm"], data: "ncd" }.
 * Pure functions, no DOM: unit-tested in tests/rcheck_test.js.
 * ═══════════════════════════════════════════════════════════════════════ */
(function (root) {
  'use strict';

  /* ── tokenizer ─────────────────────────────────────────────────────── */
  var OPS = ['<<-', '->>', '|>', '<-', '->', '<=', '>=', '==', '!=', '&&', '||', ':::', '::', '[[', '+', '-', '*', '/', '^', '<', '>', '!', '&', '|', '~', '=', '$', '@', ':', '?', ',', '(', ')', '[', ']', '{', '}', '\\', ';'];
  function RErr(msg, line) { var e = new Error(msg); e.rline = line; e.rcheck = true; return e; }
  function tokenize(src) {
    var toks = [], i = 0, line = 1, depth = [], n = src.length;
    function push(t, v) { toks.push({ t: t, v: v, line: line }); }
    while (i < n) {
      var c = src[i];
      if (c === '\n') { line++; i++; if (!depth.length || depth[depth.length - 1] === '{') push('nl'); continue; }
      if (c === ' ' || c === '\t' || c === '\r') { i++; continue; }
      if (c === '#') { while (i < n && src[i] !== '\n') i++; continue; }
      if (c === '"' || c === "'") {
        var q = c, s = ''; i++;
        while (i < n && src[i] !== q) { if (src[i] === '\\' && i + 1 < n) { var esc1 = src[i + 1]; s += esc1 === 'n' ? '\n' : esc1 === 't' ? '\t' : esc1; i += 2; } else { if (src[i] === '\n') line++; s += src[i++]; } }
        if (i >= n) throw RErr('A string is missing its closing quote', line);
        i++; push('str', s); continue;
      }
      if (c === '`') { var b = ''; i++; while (i < n && src[i] !== '`') b += src[i++]; i++; push('id', b); continue; }
      if (/[0-9]/.test(c) || (c === '.' && /[0-9]/.test(src[i + 1] || ''))) {
        var m = /^(0[xX][0-9a-fA-F]+|(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?)(L|i)?/.exec(src.slice(i));
        push('num', Number(m[1])); i += m[0].length; continue;
      }
      if (/[A-Za-z._]/.test(c)) { var mm = /^[A-Za-z._][A-Za-z0-9._]*/.exec(src.slice(i)); push('id', mm[0]); i += mm[0].length; continue; }
      if (c === '%') { var e = src.indexOf('%', i + 1); if (e < 0) throw RErr('An operator like %>% is not closed', line); push('op', src.slice(i, e + 1)); i = e + 1; continue; }
      var op = null; for (var k = 0; k < OPS.length; k++) if (src.substr(i, OPS[k].length) === OPS[k]) { op = OPS[k]; break; }
      if (!op) throw RErr('Unexpected character "' + c + '"', line);
      if (op === '[[' ) depth.push('[[');
      else if (op === '(' || op === '[' || op === '{') depth.push(op);
      else if (op === ')' || op === ']' || op === '}') {
        if (op === ']' && depth[depth.length - 1] === '[[') { if (src[i + 1] === ']') { depth.pop(); push('op', ']]'); i += 2; continue; } }
        if (!depth.length) throw RErr('There is an extra "' + op + '"', line);
        depth.pop();
      }
      push('op', op); i += op.length;
    }
    if (depth.length) throw RErr('A "' + depth[depth.length - 1] + '" is never closed', line);
    push('eof');
    return toks;
  }

  /* ── parser (Pratt) ────────────────────────────────────────────────── */
  var BIN = { '?': [0, 'l'], '=': [1, 'r'], '<-': [2, 'r'], '<<-': [2, 'r'], '->': [3, 'l'], '->>': [3, 'l'], '~': [4, 'l'], '||': [5, 'l'], '|': [5, 'l'], '&&': [6, 'l'], '&': [6, 'l'],
    '==': [8, 'l'], '!=': [8, 'l'], '<': [8, 'l'], '>': [8, 'l'], '<=': [8, 'l'], '>=': [8, 'l'], '+': [9, 'l'], '-': [9, 'l'], '*': [10, 'l'], '/': [10, 'l'], '|>': [11, 'l'], ':': [12, 'l'], '^': [14, 'r'], '$': [15, 'l'], '@': [15, 'l'] };
  function parse(src) {
    var toks = tokenize(src), p = 0;
    function peek() { return toks[p]; }
    function next() { return toks[p++]; }
    function isOp(v) { var t = toks[p]; return t.t === 'op' && t.v === v; }
    function expect(v) { var t = next(); if (t.t !== 'op' || t.v !== v) throw RErr('Expected "' + v + '"' + (t.t === 'eof' ? ' before the end' : ' near "' + (t.v === undefined ? t.t : t.v) + '"'), t.line); return t; }
    function skipNl() { while (peek().t === 'nl') p++; }
    function binInfo(t) { if (t.t !== 'op') return null; if (/^%.*%$/.test(t.v)) return [11, 'l']; return BIN[t.v] || null; }
    function args(close) {
      var out = []; skipNl();
      if (isOp(close)) { next(); return out; }
      while (true) {
        skipNl();
        if (isOp(',')) { out.push({ name: null, v: { k: 'miss' } }); next(); continue; }
        if (isOp(close)) { out.push({ name: null, v: { k: 'miss' } }); next(); return out; }
        var name = null, t = peek(), t2 = toks[p + 1];
        if ((t.t === 'id' || t.t === 'str') && t2.t === 'op' && t2.v === '=') { name = t.v; p += 2; skipNl(); }
        var v = (isOp(',') || isOp(close)) ? { k: 'miss' } : expr(1.5);
        out.push({ name: name, v: v }); skipNl();
        if (isOp(',')) { next(); skipNl(); if (isOp(close) || isOp(']]')) { out.push({ name: null, v: { k: 'miss' } }); next(); return out; } continue; }
        if (close === ']]') { expect(']]'); return out; }
        expect(close); return out;
      }
    }
    function primary() {
      skipNl();
      var t = next();
      if (t.t === 'num') return { k: 'num', v: t.v };
      if (t.t === 'str') return { k: 'str', v: t.v };
      if (t.t === 'id') {
        if (t.v === 'function') { expect('('); var ps = args(')'); skipNl(); return { k: 'fn', params: ps.map(function (a) { return a.name || (a.v.k === 'id' ? a.v.v : '_'); }), body: expr(2) }; }
        if (t.v === 'if' || t.v === 'for' || t.v === 'while' || t.v === 'repeat') throw RErr('This checker reads data-analysis code; "' + t.v + '" is not supported in these tasks', t.line);
        return { k: 'id', v: t.v };
      }
      if (t.t === 'op') {
        if (t.v === '(') { var e = expr(0); skipNl(); expect(')'); return e; }
        if (t.v === '{') { var st = []; while (true) { skipNl(); if (isOp('}')) { next(); break; } st.push(expr(0)); if (isOp(';')) next(); } return { k: 'block', stmts: st }; }
        if (t.v === '\\') { expect('('); var ps2 = args(')'); return { k: 'fn', params: ps2.map(function (a) { return a.name || (a.v.k === 'id' ? a.v.v : '_'); }), body: expr(2) }; }
        if (t.v === '-' || t.v === '+') return { k: 'un', op: t.v, x: expr(13) };
        if (t.v === '!') return { k: 'un', op: '!', x: expr(7) };
        if (t.v === '~') return { k: 'bin', op: '~', l: { k: 'miss' }, r: expr(4.5) };
      }
      throw RErr(t.t === 'eof' ? 'The code ends too early (an operator or comma with nothing after it?)' : 'Unexpected "' + t.v + '"', t.line);
    }
    function expr(minBp) {
      var left = primary();
      while (true) {
        var t = peek();
        if (t.t === 'op' && (t.v === '(' || t.v === '[' || t.v === '[[') ) {     // postfix: call / index
          next();
          if (t.v === '(') left = { k: 'call', fn: left, args: args(')') };
          else left = { k: 'idx', x: left, dbl: t.v === '[[', args: args(t.v === '[' ? ']' : ']]') };
          continue;
        }
        if (t.t === 'op' && (t.v === '::' || t.v === ':::')) { next(); var r0 = next(); left = { k: 'id', v: r0.v }; continue; }
        var bi = binInfo(t); if (!bi || bi[0] < minBp) break;
        next(); skipNl();
        var right = expr(bi[1] === 'r' ? bi[0] : bi[0] + 0.5);
        left = { k: 'bin', op: t.v, l: left, r: right };
      }
      return left;
    }
    var stmts = [];
    while (true) { skipNl(); if (peek().t === 'eof') break; stmts.push(expr(0)); var t = peek(); if (t.t === 'op' && t.v === ';') next(); else if (t.t !== 'nl' && t.t !== 'eof') throw RErr('Unexpected "' + t.v + '" (two statements on one line?)', t.line); }
    return stmts;
  }

  /* ── normaliser ────────────────────────────────────────────────────── */
  var ALIAS = { summarize: 'summarise', '%>%': '|>', 'read.csv': 'read_csv', 'subset': 'filter', 'n_distinct': 'n_distinct', 'tally': 'count', 'as.factor': 'factor', 'as_factor': 'factor', ifelse: 'if_else', rbind: 'bind_rows', cbind: 'bind_cols', color: 'colour' };
  var SIG = { lm: ['formula', 'data'], glm: ['formula', 'family', 'data'], ggplot: ['data', 'mapping'], aes: ['x', 'y'], mean: ['x'], median: ['x'], sd: ['x'], sum: [], read_csv: ['file'],
    summary: ['object'], tidy: ['x'], head: ['x', 'n'], factor: ['x', 'levels', 'labels'], 't.test': ['formula', 'data'], 'chisq.test': ['x', 'y'], table: [] };
  var VERBS = { filter: 1, select: 1, mutate: 1, summarise: 1, group_by: 1, arrange: 1, count: 1, ungroup: 1, rename: 1, distinct: 1, slice: 1, transmute: 1, relocate: 1, left_join: 1, inner_join: 1, right_join: 1, full_join: 1, pull: 1, drop_na: 1 };
  var IGNORE_FNS = { library: 1, require: 1, suppressMessages: 1, suppressPackageStartupMessages: 1, 'install.packages': 1, setwd: 1, rm: 1, options: 1, theme_set: 1 };
  var FAMILIES = { binomial: 1, gaussian: 1, poisson: 1, quasipoisson: 1, quasibinomial: 1, Gamma: 1 };
  var FLIP = { '<': '>', '>': '<', '<=': '>=', '>=': '<=' };

  function C(name, args) { return { k: 'call', name: name, args: args }; }
  function A(v, name) { return { name: name || null, v: v }; }
  function ser(n) {
    if (!n) return '∅';
    switch (n.k) {
      case 'num': return String(n.v); case 'str': return JSON.stringify(n.v); case 'id': return n.v; case 'bool': return n.v ? 'TRUE' : 'FALSE';
      case 'miss': return '∅'; case 'null': return 'NULL';
      case 'fn': return 'λ(' + n.params.join(',') + ')' + ser(n.body);
      case 'call': return n.name + '(' + n.args.map(function (a) { return (a.name ? a.name + '=' : '') + ser(a.v); }).join(',') + ')';
    }
    return '?';
  }
  function fnName(f) { if (f.k === 'id') return f.v; if (f.k === 'str') return f.v; return null; }
  function sortBy(arr, f) { return arr.slice().sort(function (a, b) { var x = f(a), y = f(b); return x < y ? -1 : x > y ? 1 : 0; }); }
  function isLit(n) { return n.k === 'num' || n.k === 'str' || n.k === 'bool'; }
  function flat(n, op) { return n.k === 'call' && n.name === op ? n.args.reduce(function (o, a) { return o.concat(flat(a.v, op)); }, []) : [n]; }

  function Normaliser(opts) {
    opts = opts || {};
    var free = opts.free_names !== false, ignore = {}; [].concat(opts.ignore || []).forEach(function (x) { ignore[x] = 1; });

    /* ctx: { env: assigned objects, cols: renamed columns, params: lambda params } */
    function norm(n, ctx) {
      switch (n.k) {
        case 'num': case 'str': case 'miss': return n;
        case 'id':
          if (n.v === 'TRUE' || n.v === 'T') return { k: 'bool', v: true };
          if (n.v === 'FALSE' || n.v === 'F') return { k: 'bool', v: false };
          if (n.v === 'NULL') return { k: 'null' };
          if (ctx.params && ctx.params[n.v]) return { k: 'id', v: ctx.params[n.v] };
          if (ctx.cols && ctx.cols[n.v]) return { k: 'id', v: ctx.cols[n.v] };
          if (ctx.env && ctx.env[n.v]) return ctx.env[n.v];
          return n;
        case 'block': var last = null; n.stmts.forEach(function (s) { last = norm(s, ctx); }); return last || { k: 'null' };
        case 'fn':
          var ps = {}, pl = []; n.params.forEach(function (p, i) { ps[p] = '.p' + (i + 1); pl.push('.p' + (i + 1)); });
          return { k: 'fn', params: pl, body: norm(n.body, { env: ctx.env, cols: ctx.cols, params: Object.assign({}, ctx.params, ps) }) };
        case 'un':
          var x = norm(n.x, ctx);
          if (n.op === '-' && x.k === 'num') return { k: 'num', v: -x.v };
          if (n.op === '+') return x;
          return C(n.op === '-' ? 'u-' : '!', [A(x)]);
        case 'idx': return normIdx(n, ctx);
        case 'call': return normCall(n, ctx);
        case 'bin': return normBin(n, ctx);
      }
      return n;
    }
    function pipeInto(lhs, rhs, op, ctx) {
      // lhs |> rhs : put lhs into rhs's first slot (or the . / _ placeholder)
      if (rhs.k === 'id') rhs = { k: 'call', fn: rhs, args: [] };
      if (rhs.k === 'fn') return norm({ k: 'call', fn: rhs, args: [A(lhs)] }, ctx);
      if (rhs.k === 'bin' && rhs.op === '$') return norm({ k: 'bin', op: '$', l: lhs, r: rhs.r }, ctx);
      if (rhs.k !== 'call') throw RErr('The right side of a pipe must be a function call');
      var ph = op === '|>' ? '_' : '.', used = false;
      var args2 = rhs.args.map(function (a) { if (a.v.k === 'id' && a.v.v === ph) { used = true; return A(lhs, a.name); } return a; });
      if (!used) args2 = [A(lhs)].concat(rhs.args);
      return norm({ k: 'call', fn: rhs.fn, args: args2 }, ctx);
    }
    function normBin(n, ctx) {
      var op = n.op;
      if (op === '|>' || op === '%>%') return pipeInto(n.l, n.r, op, ctx);
      if (op === '<-' || op === '<<-' || op === '=') return norm(n.r, ctx);
      if (op === '->' || op === '->>') return norm(n.l, ctx);
      if (op === '+' && isGg(n)) return normGg(n, ctx);
      if (op === '$' || op === '@') return C('$', [A(norm(n.l, ctx)), A(n.r.k === 'str' ? { k: 'id', v: n.r.v } : n.r)]);
      if (op === '~') return normFormula(n, ctx);
      var l = norm(n.l, ctx), r = norm(n.r, ctx);
      if (op === '&&') op = '&'; if (op === '||') op = '|';
      if (FLIP[op] && isLit(l) && !isLit(r)) { var t = l; l = r; r = t; op = FLIP[op]; }
      if (op === '&' || op === '|' || op === '+' || op === '*') {
        var parts = flat(l, op).concat(flat(r, op));
        return C(op, sortBy(parts, ser).map(function (v) { return A(v); }));
      }
      if (op === '==' || op === '!=') { var pr = sortBy([l, r], ser); return C(op, [A(pr[0]), A(pr[1])]); }
      return C(op, [A(l), A(r)]);
    }
    function normFormula(n, ctx) {
      var lhs = n.l.k === 'miss' ? { k: 'miss' } : norm(n.l, { env: {}, cols: ctx.cols });
      var terms = flatTerms(n.r).map(function (t) { return norm(t, { env: {}, cols: ctx.cols }); });
      return C('~', [A(lhs), A(C('+', sortBy(terms, ser).map(function (v) { return A(v); })))]);
    }
    function flatTerms(n) { return n.k === 'bin' && n.op === '+' ? flatTerms(n.l).concat(flatTerms(n.r)) : [n]; }
    function normIdx(n, ctx) {
      // x[cond, ]  →  filter(x, cond)   (with x$col → col)
      if (!n.dbl && n.args.length === 2 && n.args[1].v.k === 'miss' && n.args[0].v.k !== 'miss') {
        var base = n.x; var bn = base.k === 'id' ? base.v : null;
        var cond = bn ? strip$(n.args[0].v, bn) : n.args[0].v;
        return normCall({ k: 'call', fn: { k: 'id', v: 'filter' }, args: [A(base), A(cond)] }, ctx);
      }
      if (n.dbl && n.args.length === 1 && n.args[0].v.k === 'str') return C('$', [A(norm(n.x, ctx)), A({ k: 'id', v: n.args[0].v.v })]);
      return C(n.dbl ? '[[' : '[', [A(norm(n.x, ctx))].concat(n.args.map(function (a) { return A(norm(a.v, ctx), a.name); })));
    }
    function strip$(n, base) {
      if (n.k === 'bin' && n.op === '$' && n.l.k === 'id' && n.l.v === base) return n.r;
      if (n.k === 'bin') return { k: 'bin', op: n.op, l: strip$(n.l, base), r: strip$(n.r, base) };
      if (n.k === 'un') return { k: 'un', op: n.op, x: strip$(n.x, base) };
      if (n.k === 'call') return { k: 'call', fn: n.fn, args: n.args.map(function (a) { return A(strip$(a.v, base), a.name); }) };
      return n;
    }
    function isGg(n) { while (n.k === 'bin' && n.op === '+') n = n.l; if (n.k === 'bin' && (n.op === '|>' || n.op === '%>%')) n = n.r; return n.k === 'call' && fnName(n.fn) === 'ggplot'; }
    function normGg(n, ctx) {
      var layers = []; while (n.k === 'bin' && n.op === '+') { layers.unshift(n.r); n = n.l; }
      var base = norm(n, ctx), aes = {}, rest = [];
      var take = function (call) { // pull aes() mappings out of a call into the shared set
        var keep = [];
        call.args.forEach(function (a) { if (a.v.k === 'call' && a.v.name === 'aes' && (a.name === 'mapping' || !a.name)) a.v.args.forEach(function (m) { aes[m.name] = m.v; }); else keep.push(a); });
        return C(call.name, keep);
      };
      base = take(base);
      layers.forEach(function (l) { var ln = norm(l, ctx); rest.push(ln.k === 'call' ? take(ln) : ln); });
      var am = C('aes', sortBy(Object.keys(aes), function (x) { return x; }).map(function (k) { return A(aes[k], k); }));
      return C('ggplot+', [A(base), A(am)].concat(sortBy(rest, ser).map(function (v) { return A(v); })));
    }

    function normCall(n, ctx) {
      var name = fnName(n.fn);
      if (n.fn.k === 'fn') { // immediately-applied lambda: (\(x) …)(y)
        var f = norm(n.fn, ctx); return C('λcall', [A(f)].concat(n.args.map(function (a) { return A(norm(a.v, ctx), a.name); })));
      }
      if (!name) return C('?call', [A(norm(n.fn, ctx))].concat(n.args.map(function (a) { return A(norm(a.v, ctx), a.name); })));
      name = ALIAS[name] || name;
      var args = n.args.filter(function (a) { return !(a.name && ignore[a.name]); })
        .map(function (a) { return a.name === 'color' ? A(a.v, 'colour') : a; });
      // between(x, a, b) → x >= a & x <= b
      if (name === 'between' && args.length === 3) return norm({ k: 'bin', op: '&', l: { k: 'bin', op: '>=', l: args[0].v, r: args[1].v }, r: { k: 'bin', op: '<=', l: args[0].v, r: args[2].v } }, ctx);
      // case_when(…, .default = v) → case_when(…, TRUE ~ v)
      if (name === 'case_when') args = args.map(function (a) { return a.name === '.default' ? A({ k: 'bin', op: '~', l: { k: 'id', v: 'TRUE' }, r: a.v }) : a; });
      // joins: join_by(k) / c("k") → "k"; right_join(x, y) → left_join(y, x); merge(x, y, by, all.x/all.y/all)
      if (/_join$/.test(name) || name === 'merge') {
        args = args.map(function (a) { if (a.name !== 'by') return a; var v = a.v;
          if (v.k === 'call' && (fnName(v.fn) === 'join_by' || fnName(v.fn) === 'c') && v.args.length === 1) v = v.args[0].v;
          if (v.k === 'id') v = { k: 'str', v: v.v }; return A(v, 'by'); });
        var posn = args.filter(function (a) { return !a.name; }), named = args.filter(function (a) { return a.name; });
        if (name === 'merge') {
          var flag = function (k) { var f = named.filter(function (a) { return a.name === k; })[0]; return f && f.v.k === 'id' && (f.v.v === 'TRUE' || f.v.v === 'T'); };
          var kind = flag('all') || (flag('all.x') && flag('all.y')) ? 'full_join' : flag('all.x') ? 'left_join' : flag('all.y') ? 'right_join' : 'inner_join';
          named = named.filter(function (a) { return !/^all(\.x|\.y)?$/.test(a.name); }); name = kind;
        }
        if (name === 'right_join' && posn.length >= 2) { posn = [posn[1], posn[0]].concat(posn.slice(2)); name = 'left_join'; }
        var jout = posn.map(function (a) { return A(norm(a.v, ctx)); }).concat(sortBy(named.map(function (a) { return A(norm(a.v, ctx), a.name); }), function (a) { return a.name; }));
        return C(name, jout);
      }
      // positional → named, from the signature
      var sig = VERBS[name] ? ['.data'] : SIG[name];
      if (sig) {
        var used = {}; args.forEach(function (a) { if (a.name) used[a.name] = 1; });
        var free = sig.filter(function (s) { return !used[s]; }), fi = 0;
        args = args.map(function (a) { if (!a.name && fi < free.length && a.v.k !== 'miss') return A(a.v, free[fi++]); return a; });
        if (name === 'count' || name === 'pull' || name === 'drop_na') args = args.map(function (a) { return a.name === 'x' ? A(a.v, '.data') : a; });
      }
      if (VERBS[name]) return normVerb(name, args, ctx);
      if (name === 'glm' || name === 'lm') args = args.map(function (a) { return a.name === 'family' ? A(familyOf(a.v), 'family') : a; });
      var out = args.map(function (a) { return A(norm(a.v, ctx), a.name); });
      var pos = out.filter(function (a) { return !a.name; }), nam = sortBy(out.filter(function (a) { return a.name; }), function (a) { return a.name; });
      return C(name, pos.concat(nam));
    }
    function familyOf(v) {
      if (v.k === 'str' && FAMILIES[v.v]) return { k: 'id', v: v.v };
      if (v.k === 'call' && fnName(v.fn) && FAMILIES[fnName(v.fn)]) { var link = v.args.filter(function (a) { return (a.name === 'link' || !a.name); })[0]; if (!link || (link.v.k === 'str' && /^(logit|log|identity)$/.test(link.v.v) && ((fnName(v.fn) === 'binomial' && link.v.v === 'logit') || (fnName(v.fn) === 'poisson' && link.v.v === 'log') || (fnName(v.fn) === 'gaussian' && link.v.v === 'identity')))) return { k: 'id', v: fnName(v.fn) }; }
      return v;
    }
    function dataOf(args) { var d = args.filter(function (a) { return a.name === '.data'; })[0]; return d ? d.v : null; }
    function rest(args) { return args.filter(function (a) { return a.name !== '.data'; }); }
    function verbNode(name, data, args, cols) { var nd = C(name, [A(data, '.data')].concat(args)); nd.cols = cols; return nd; }

    function normVerb(name, args, ctx) {
      var rawData = dataOf(args), others = rest(args);
      var data = rawData ? norm(rawData, ctx) : { k: 'miss' };
      var cols = Object.assign({}, data.cols || {}), cctx = { env: ctx.env, cols: cols, params: ctx.params };
      if (name === 'summarise' || name === 'mutate' || name === 'transmute') {
        var by = others.filter(function (a) { return a.name === '.by'; })[0];
        if (by && name !== 'mutate') { others = others.filter(function (a) { return a !== by; }); var byVars = by.v.k === 'call' && fnName(by.v.fn) === 'c' ? by.v.args : [A(by.v)]; data = normVerb('group_by', [A(rawData || data, '.data')].concat(byVars), ctx); cols = Object.assign({}, data.cols || {}); cctx.cols = cols; }
        others = others.filter(function (a) { return a.name !== '.groups'; });
        var defs = [];
        if (name === 'mutate' && data.k === 'call' && data.name === 'mutate') { defs = data.args.slice(1); data = data.args[0].v; }
        var newCols = Object.assign({}, cols);
        others.forEach(function (a) {
          var v = norm(a.v, { env: ctx.env, cols: newCols, params: ctx.params });
          var nm = free ? 'col:' + ser(v) : (a.name || ser(v));
          if (a.name) newCols[a.name] = nm;
          defs.push(A(v, nm));
        });
        defs = sortBy(defs, function (a) { return a.name; });
        return verbNode(name, data, defs, newCols);
      }
      if (name === 'count') {
        var gv = others.filter(function (a) { return !a.name || (a.name !== 'name' && a.name !== 'sort' && a.name !== 'wt'); });
        var g = normVerb('group_by', [A(rawData, '.data')].concat(gv), ctx);
        var cname = free ? 'col:n()' : 'n'; var nc = Object.assign({}, g.cols); nc.n = cname;
        return verbNode('summarise', g, [A(C('n', []), cname)], nc);
      }
      var vals = others.map(function (a) { return A(norm(a.v, cctx), a.name); });
      if (name === 'filter') {
        var conds = []; vals.forEach(function (a) { conds = conds.concat(flat(a.v, '&')); });
        if (data.k === 'call' && data.name === 'filter') { conds = conds.concat(data.args.slice(1).map(function (a) { return a.v; })); data = data.args[0].v; }
        return verbNode('filter', data, sortBy(conds, ser).map(function (v) { return A(v); }), cols);
      }
      if (name === 'group_by') {
        vals = vals.filter(function (a) { return a.name !== '.groups' && a.name !== '.add'; });
        if (data.k === 'call' && data.name === 'group_by') data = data.args[0].v;     // a second group_by replaces the first
        return verbNode('group_by', data, sortBy(vals, function (a) { return ser(a.v); }), cols);
      }
      if (name === 'select' || name === 'distinct' || name === 'drop_na') return verbNode(name, data, sortBy(vals, function (a) { return ser(a.v); }), cols);
      if (name === 'ungroup') return data;   // harmless in these tasks
      if (name === 'rename') {
        vals.forEach(function (a) { if (a.name && a.v.k === 'id') { cols[a.name] = a.v.v; } });
        return Object.assign({}, data, { cols: cols });
      }
      return verbNode(name, data, vals, cols);
    }

    function program(src) {
      var stmts = parse(src), env = {}, last = null;
      stmts.forEach(function (s) {
        if (s.k === 'call' && IGNORE_FNS[fnName(s.fn)]) return;
        if (s.k === 'call' && (fnName(s.fn) === 'print' || fnName(s.fn) === 'View') && s.args.length) s = s.args[0].v;
        if (s.k === 'bin' && (s.op === '<-' || s.op === '<<-' || s.op === '=') && (s.l.k === 'id' || s.l.k === 'str')) { var v = norm(s.r, { env: env }); env[s.l.v] = v; last = v; return; }
        if (s.k === 'bin' && (s.op === '->' || s.op === '->>') && s.r.k === 'id') { var v2 = norm(s.l, { env: env }); env[s.r.v] = v2; last = v2; return; }
        last = norm(s, { env: env });
      });
      if (!last) throw RErr('There is no code to check yet');
      return last;
    }
    return { program: program, ser: ser };
  }

  /* spine = the chain of steps from the data outwards (for feedback) */
  function spine(n) { var out = []; while (n && n.k === 'call') { out.unshift(n.name); var d = n.args.filter(function (a) { return a.name === '.data' || a.name === 'data'; })[0] || n.args[0]; if (!d) break; n = d.v; } if (n && n.k === 'id') out.unshift(n.v); return out; }
  function lev(a, b) { var d = []; for (var i = 0; i <= a.length; i++) { d[i] = [i]; for (var j = 1; j <= b.length; j++) d[i][j] = i ? Math.min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1)) : j; } return d[a.length][b.length]; }
  function stepAt(n, name) { while (n && n.k === 'call') { if (n.name === name) return n; var d = n.args.filter(function (a) { return a.name === '.data' || a.name === 'data'; })[0] || n.args[0]; if (!d) break; n = d.v; } return null; }
  function pretty(s) { return s === 'ggplot+' ? 'ggplot()' : /^[A-Za-z_.][\w.]*$/.test(s) ? s + '()' : s; }

  /* check(answer, solutions[], opts) → { ok, msg, canon } */
  function check(answer, solutions, opts) {
    var N = Normaliser(opts), mine;
    try { mine = N.program(answer); } catch (e) { if (!e.rcheck) throw e; return { ok: false, msg: 'Could not read your code' + (e.rline ? ' (line ' + e.rline + ')' : '') + ': ' + e.message + '.' }; }
    var me = ser(mine), best = null;
    for (var i = 0; i < solutions.length; i++) {
      var sol = N.program(solutions[i]), s = ser(sol);
      if (s === me) return { ok: true, msg: '', canon: me };
      var sp = spine(sol), d = lev(spine(mine), sp);
      if (!best || d < best.d) best = { d: d, sol: sol, sp: sp };
    }
    var ms = spine(mine), sp2 = best.sp, msg;
    var missing = sp2.filter(function (x, i) { return i > 0 && ms.indexOf(x) < 0; }), extra = ms.filter(function (x, i) { return i > 0 && sp2.indexOf(x) < 0; });
    if (ms[0] !== sp2[0] && sp2[0] && /^[A-Za-z]/.test(sp2[0])) msg = 'Start from the right data: `' + sp2[0] + '`.';
    else if (missing.length) msg = 'Something is missing: you still need ' + missing.map(function (x) { return '`' + pretty(x) + '`'; }).join(' and ') + '.';
    else if (extra.length) msg = extra.map(function (x) { return '`' + pretty(x) + '`'; }).join(' and ') + (extra.length > 1 ? ' are' : ' is') + ' not needed for this task.';
    else if (ms.join('>') !== sp2.join('>')) msg = 'The steps are right but in a different order. Think about which has to happen first.';
    else {
      var wrong = sp2.slice(1).filter(function (x) { var a = stepAt(mine, x), b = stepAt(best.sol, x); return a && b && ser(stripData(a)) !== ser(stripData(b)); });
      msg = wrong.length ? 'Look again at what goes inside ' + wrong.map(function (x) { return '`' + pretty(x) + '`'; }).join(' and ') + '.' : 'Close, but not the same result. Check names, values and arguments.';
    }
    return { ok: false, msg: msg, canon: me };
  }
  function stripData(n) { return C(n.name, n.args.filter(function (a) { return a.name !== '.data' && a.name !== 'data'; })); }

  var api = { tokenize: tokenize, parse: parse, Normaliser: Normaliser, check: check, canon: function (src, opts) { return ser(Normaliser(opts).program(src)); } };
  if (typeof module !== 'undefined' && module.exports) module.exports = api; else root.RCheck = api;
})(typeof window !== 'undefined' ? window : this);
