import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mergeGame, mergeUnion, mergeKey, limitFor, ruleFor } from '../src/merge.js';

const game = (o) => ({ v: 1, items: {}, badges: {}, streak: { last: null, count: 0, best: 0 }, tests: {}, settings: {}, created: '2026-11-01', ...o });

test('game: the better result per item is kept, from either side', () => {
  const server = game({ items: {
    a: { solved: true, tries: 1, diff: 2 },              // 20 XP
    b: { solved: false, tries: 2, diff: 1 },
    c: { solved: true, shown: true, tries: 1, diff: 3 }, // answer shown: 0 XP
  } });
  const local = game({ items: {
    a: { solved: true, tries: 3, diff: 2 },              // 5 XP: worse
    b: { solved: true, tries: 3, diff: 1, hints: 1 },    // solved: better than unsolved
    c: { solved: true, tries: 2, diff: 3 },              // solved for XP beats shown
    d: { solved: false, tries: 0, diff: 1 },             // only here
  } });
  const m = mergeGame(server, local);
  assert.equal(m.items.a.tries, 1);
  assert.equal(m.items.b.solved, true);
  assert.equal(m.items.c.shown, undefined);
  assert.ok(m.items.d);
  // order does not matter for items
  assert.deepEqual(mergeGame(local, server).items, m.items);
});

test('game: badges keep the earliest date, streak the latest day, tests by kind', () => {
  const server = game({
    badges: { first: '2026-11-03', boss: '2026-11-05' },
    streak: { last: '2026-11-10', count: 4, best: 6 },
    tests: { pre: { pct: 40, ts: '2026-11-01' }, post: { pct: 70, ts: '2026-11-09' }, r1post: { pct: 90, ts: '2026-11-02' } },
  });
  const local = game({
    badges: { first: '2026-11-02', gain: '2026-11-12' },
    streak: { last: '2026-11-12', count: 1, best: 2 },
    tests: { pre: { pct: 65, ts: '2026-11-08' }, post: { pct: 85, ts: '2026-11-12' }, r1post: { pct: 60, ts: '2026-11-11' } },
    created: '2026-10-20',
  });
  const m = mergeGame(server, local);
  assert.deepEqual(m.badges, { first: '2026-11-02', boss: '2026-11-05', gain: '2026-11-12' });
  assert.deepEqual(m.streak, { last: '2026-11-12', count: 1, best: 6 });
  assert.equal(m.tests.pre.pct, 40, 'the first pre-test is the baseline');
  assert.equal(m.tests.post.pct, 85, 'best post-test');
  assert.equal(m.tests.r1post.pct, 90, 'best post-test, even if older');
  assert.equal(m.created, '2026-10-20');
});

test('game: a missing or unknown version on one side gives the other side', () => {
  const g = game({ items: { a: { solved: true, tries: 1 } } });
  assert.equal(mergeGame(null, g), g);
  assert.equal(mergeGame(g, { v: 2 }), g);
});

test('quiz answers: right anywhere stays right', () => {
  assert.deepEqual(mergeUnion({ q1: false, q2: true }, { q1: true, q3: false }), { q1: true, q2: true, q3: false });
});

test('ticks: the newer copy wins, so un-ticking survives a sync', () => {
  const server = { value: { 0: 1, 1: 1 }, ts: 1000 };
  const local = { value: { 0: 1 }, ts: 2000 };
  assert.deepEqual(mergeKey('ws-plan:basic', server, local), local);
  assert.deepEqual(mergeKey('ws-plan:basic', { ...server, ts: 3000 }, local).value, { 0: 1, 1: 1 });
});

test('only known keys are synced, with a size limit', () => {
  assert.equal(ruleFor('rq:v1'), 'game');
  assert.ok(limitFor('rq:v1') > 100000);
  assert.ok(limitFor('quiz-score:survey-workshop/s5_choose_check_report'));
  assert.ok(limitFor('ws-plan:dataviz-base'));
  for (const k of ['ws-profile', 'ws-unlocked', 'ws-plan:../x', 'quiz-score:', 'rq:v2', 'anything']) assert.equal(limitFor(k), 0, k);
});
