import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readdirSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';
import { productFor, holds, routesJson, FREE, ruleMatches } from '../src/products.js';

const DOCS = new URL('../../docs/', import.meta.url).pathname;

test('free paths stay free', () => {
  for (const p of [
    '/', '/index.html', '/basic/welcome.html', '/basic/plot-gallery/advanced.html',
    '/regression/', '/regression/welcome.html', '/regression/welcome', '/regression/site_libs/bootstrap/x.css',
    '/regression/regression-workshop/s1_foundations.html', '/regression/regression-workshop/s1_foundations',
    '/regression/regression-workshop/cheatsheet', '/regression/regression-workshop/labs/lab1_explore.R',
    '/regression/data/ncd_survey.csv',
    '/advanced/survival-workshop/s1_time_to_event.html', '/advanced/causal-workshop/labs/lab1_dag.R',
    '/advanced/causal-workshop/cheatsheet.html', '/advanced/data/htn_programme.csv', '/advanced/advanced-workshops',
    '/gis/gis-workshop/s1_spatial_data', '/gis/gis/spatial_data_sf.html', '/gis/data/gis/facilities.csv',
    '/dungeons/dungeons/', '/dungeons/dungeons/index.html', '/dungeons/dungeons/b1_first_script',
    '/dungeons/dungeons/b4_first_plots_files/figure-html/x.png', '/dungeons/dungeons/r1pretest',
    '/dungeons/dungeons/r1posttest.html', '/dungeons/dungeons/campus', '/dungeons/dungeons/roadmap.html',
    '/dungeons/r-foundations/getting-started.html',
  ]) assert.equal(productFor(p), null, p);
});

test('paid paths need their product', () => {
  const cases = {
    '/moderate/r-foundations/iteration.html': 'moderate',
    '/moderate': 'moderate',
    '/dataviz-base/plot-gallery/basic.html': 'moderate',
    '/dataviz-complete/plot-gallery/advanced': 'advanced',
    '/regression/regression-workshop/s2_simple_regression.html': 'regression',
    '/regression/regression-workshop/s2_simple_regression': 'regression',
    '/regression/regression-workshop/labs/lab2_simple.R': 'regression',
    '/regression/search.json': 'regression',
    '/gis/gis-workshop/s3_global_autocorrelation': 'gis',
    '/gis/gis/morans_i.html': 'gis',
    '/advanced/survival-workshop/s2_kaplan_meier.html': 'advanced',
    '/advanced/causal-workshop/labs/lab3_match.R': 'advanced',
    '/advanced/causal-workshop/make_data.R': 'advanced',
    '/dungeons/dungeons/m1_messy_data_dungeon.html': 'game-full',
    '/dungeons/dungeons/world3_confounding_caves': 'game-full',
    '/dungeons/dungeons/pretest': 'game-full',
    '/dungeons/dungeons/r2pretest.html': 'game-full',
    '/dungeons/dungeons/facilitator.html': 'game-full',
    '/dungeons/regression-workshop/s4_assumptions.html': 'regression',
  };
  for (const [p, want] of Object.entries(cases)) assert.equal(productFor(p), want, p);
});

test('encoded and traversal paths cannot reach a paid page through a free rule', () => {
  for (const p of [
    '/advanced/survival-workshop/s1_time_to_event/../s2_kaplan_meier.html',
    '/advanced/survival-workshop/s1_time_to_event%2F..%2Fs2_kaplan_meier.html',
    '/advanced/survival-workshop/%2e%2e/causal-workshop/s2_adjustment_standardisation',
    '/regression/./regression-workshop/s2_simple_regression',
    '/regression/%E0%A4%A', // malformed escape
  ]) assert.notEqual(productFor(p), null, p);
  // Doubled slashes are collapsed before matching, so they cannot dodge a paid rule.
  assert.equal(productFor('/regression//regression-workshop/s2_simple_regression'), 'regression');
});

test('holding a product, and all-access', () => {
  assert.equal(holds([], null), true);
  assert.equal(holds([], 'gis'), false);
  assert.equal(holds(['gis'], 'gis'), true);
  assert.equal(holds(['regression'], 'gis'), false);
  assert.equal(holds(['all-access'], 'game-full'), true);
});

test('_routes.json fits Cloudflare limits', () => {
  const r = routesJson();
  const rules = [...r.include, ...r.exclude];
  assert.ok(r.include.length >= 1);
  assert.ok(rules.length <= 100, `${rules.length} rules; Cloudflare allows 100`);
  for (const rule of rules) {
    assert.ok(rule.length <= 100, `rule longer than 100 characters: ${rule}`);
    assert.ok(rule.startsWith('/'), rule);
    assert.ok(!rule.slice(0, -1).includes('*'), `wildcard only at the end: ${rule}`);
  }
});

test('every free rule points at something that exists in docs/', () => {
  const files = [];
  (function walk(d) {
    for (const f of readdirSync(d)) {
      const p = join(d, f);
      if (statSync(p).isDirectory()) walk(p); else files.push('/' + relative(DOCS, p).split('\\').join('/'));
    }
  })(DOCS);
  const urls = new Set();
  for (const f of files) {
    urls.add(f);
    if (f.endsWith('.html')) urls.add(f.slice(0, -5));
    if (f.endsWith('/index.html')) urls.add(f.slice(0, -10));
  }
  const missing = FREE.filter((rule) => ![...urls].some((u) => ruleMatches(u, rule)));
  assert.deepEqual(missing, [], 'free rules that match no published file (renamed page?)');
});
