// Phase 3: progress sync and last visit (LAUNCH_PLAN.md §6, §9).
// Plan proof: "solve an item on one device, see it on another".
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { startSite, testSignIn, cookieFrom } from './helpers.js';

let site;
before(async () => { site = await startSite(); });
after(async () => { await site?.stop(); });

const post = (cookie, body) => fetch(site.base + '/api/progress', {
  method: 'POST', headers: { cookie, 'content-type': 'application/json', origin: site.base }, body: JSON.stringify(body),
});
const game = (items, extra = {}) => ({ v: 1, items, badges: {}, streak: { last: null, count: 0, best: 0 }, tests: {}, settings: {}, created: '2026-11-19', ...extra });

async function signInAgain(email) {
  const r = await fetch(site.base + '/api/auth/sign-in/email', {
    method: 'POST', headers: { 'content-type': 'application/json', origin: site.base },
    body: JSON.stringify({ email, password: 'correct-horse-battery' }),
  });
  assert.equal(r.status, 200);
  return cookieFrom(r);
}

test('signed out: progress is refused', async () => {
  assert.equal((await fetch(site.base + '/api/progress')).status, 401);
  assert.equal((await post('', { set: {} })).status, 401);
});

test('an item solved on one device shows on another', async () => {
  const laptop = await testSignIn(site.base, 'dev@example.test', 'Dev');
  const phone = await signInAgain('dev@example.test');

  let r = await post(laptop, { set: { 'rq:v1': { value: game({ w1q1: { solved: true, tries: 1, diff: 2 } }), ts: Date.now() } } });
  assert.equal(r.status, 200);

  // The phone has its own, different progress; sending it merges both.
  r = await post(phone, { set: { 'rq:v1': { value: game({ w1q2: { solved: true, tries: 2, diff: 1 } }), ts: Date.now() } } });
  const { items } = await r.json();
  assert.deepEqual(Object.keys(items['rq:v1'].value.items).sort(), ['w1q1', 'w1q2']);

  // ...and the laptop sees the phone's item on its next sync.
  const back = await (await fetch(site.base + '/api/progress', { headers: { cookie: laptop } })).json();
  assert.ok(back.items['rq:v1'].value.items.w1q2.solved);
});

test('quiz answers and ticks sync by their own rules; delete removes a key', async () => {
  const c = await testSignIn(site.base, 'ticks@example.test', 'Ticks');
  const t0 = Date.now() - 10000;
  await post(c, { set: {
    'quiz-score:regression-workshop/s2_simple_regression': { value: { r2q1: false, r2q2: true }, ts: t0 },
    'ws-plan:basic': { value: { 0: 1, 1: 1 }, ts: t0 },
  } });
  const { items } = await (await post(c, { set: {
    'quiz-score:regression-workshop/s2_simple_regression': { value: { r2q1: true }, ts: t0 + 1 },
    'ws-plan:basic': { value: { 0: 1 }, ts: t0 + 1 }, // step 2 un-ticked later
  } })).json();
  assert.deepEqual(items['quiz-score:regression-workshop/s2_simple_regression'].value, { r2q1: true, r2q2: true });
  assert.deepEqual(items['ws-plan:basic'].value, { 0: 1 });

  const after = await (await post(c, { delete: ['ws-plan:basic'] })).json();
  assert.equal(after.items['ws-plan:basic'], undefined);
});

test('unknown keys, oversized values and clocks in the future are handled', async () => {
  const c = await testSignIn(site.base, 'odd@example.test', 'Odd');
  const r = await (await post(c, { set: {
    'ws-profile': { value: { name: 'x' }, ts: 1 },
    'ws-plan:basic': { value: { pad: 'x'.repeat(5000) }, ts: 1 },
    'ws-path-done': { value: { basic: 1 }, ts: Date.now() + 10 * 365 * 86400000 },
  } })).json();
  assert.deepEqual(r.refused.sort(), ['ws-plan:basic', 'ws-profile']);
  assert.ok(r.items['ws-path-done'].ts <= Date.now(), 'a future timestamp is clamped to now');
  assert.equal((await fetch(site.base + '/api/progress', {
    method: 'POST', headers: { cookie: c, 'content-type': 'text/plain', origin: site.base }, body: '{}',
  })).status, 415);
});

test('last visit: recorded by the sync call, returned by /api/me', async () => {
  const c = await testSignIn(site.base, 'visit@example.test', 'Visit');
  await post(c, { visit: { path: '/regression/regression-workshop/s3_multiple_regression', title: 'Session 3' } });
  await post(c, { visit: { path: '/', title: 'Landing' } }); // the landing page is not a place to continue from
  await post(c, { visit: { path: '//evil.example/x', title: 'x' } }); // not a site path
  const me = await (await fetch(site.base + '/api/me', { headers: { cookie: c } })).json();
  assert.equal(me.lastVisit.path, '/regression/regression-workshop/s3_multiple_regression');
  assert.equal(me.lastVisit.title, 'Session 3');
});

test('one user never sees another user\'s progress', async () => {
  const a = await testSignIn(site.base, 'a@example.test', 'A');
  const b = await testSignIn(site.base, 'b@example.test', 'B');
  await post(a, { set: { 'ws-path-done': { value: { basic: 1 }, ts: Date.now() } } });
  const theirs = await (await fetch(site.base + '/api/progress', { headers: { cookie: b } })).json();
  assert.deepEqual(theirs.items, {});
});

test('a reset on one device is not undone by an older copy on another', async () => {
  const phone = await testSignIn(site.base, 'reset@example.test', 'Reset');
  const laptop = await signInAgain('reset@example.test');
  const t0 = Date.now() - 60000;
  const old = game({ w1q1: { solved: true, tries: 1, diff: 3 } });
  await post(laptop, { set: { 'rq:v1': { value: old, ts: t0 }, 'quiz-score:regression-workshop/s2_simple_regression': { value: { r2q1: true }, ts: t0 } } });

  // Phone: game Reset (delete + empty state in one request) and quiz Reset (delete only).
  let r = await (await post(phone, { delete: ['rq:v1', 'quiz-score:regression-workshop/s2_simple_regression'],
    set: { 'rq:v1': { value: game({}), ts: Date.now() } } })).json();
  assert.deepEqual(r.items['rq:v1'].value.items, {});

  // Laptop still holds the old copies, last changed before the reset.
  r = await (await post(laptop, { set: { 'rq:v1': { value: old, ts: t0 }, 'quiz-score:regression-workshop/s2_simple_regression': { value: { r2q1: true }, ts: t0 } } })).json();
  assert.deepEqual(r.items['rq:v1'].value.items, {}, 'the game stays reset');
  assert.equal(r.items['quiz-score:regression-workshop/s2_simple_regression'], undefined, 'the quiz stays reset');
  assert.deepEqual(r.gone, ['quiz-score:regression-workshop/s2_simple_regression'], 'the laptop is told to drop its copy');

  // Progress made after the reset is kept as usual.
  r = await (await post(laptop, { set: { 'rq:v1': { value: game({ w1q2: { solved: true, tries: 1, diff: 1 } }), ts: Date.now() } } })).json();
  assert.deepEqual(Object.keys(r.items['rq:v1'].value.items), ['w1q2']);
  // The reset markers never reach the browser.
  assert.ok(!Object.keys(r.items).some((k) => k.startsWith('reset:')));
});
