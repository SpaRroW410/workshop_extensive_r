// How saved progress from two places is combined (LAUNCH_PLAN.md §6).
// The server runs these when a browser sends what it has; the result is stored and sent back.
//
// Keys and their rule:
//   rq:v1              the game     -> keep the better result per item (progress only ever adds up)
//   quiz-score:<deck>  deck quizzes -> union of answered questions; a question right anywhere stays right
//   ws-path-done       landing page steps   } ticks can be undone, so the newer copy wins
//   ws-plan:<track>    a track's study plan }   (by the time the browser says it changed them)

/** Keys that are synced, and the longest value accepted for each (bytes of JSON). */
export const SYNCED = [
  [/^rq:v1$/, 512 * 1024],
  [/^quiz-score:[A-Za-z0-9_\-/.]{1,120}$/, 16 * 1024],
  [/^ws-path-done$/, 4 * 1024],
  [/^ws-plan:[a-z0-9-]{1,40}$/, 4 * 1024],
];

export function limitFor(key) {
  const hit = SYNCED.find(([re]) => re.test(key));
  return hit ? hit[1] : 0;
}

export function ruleFor(key) {
  if (key === 'rq:v1') return 'game';
  if (key.startsWith('quiz-score:')) return 'union';
  return 'newest';
}

// Same XP rule as dungeons/assets/quest.js (BASE, HINT_COST, BOSS_BONUS, attemptFactor).
function itemXP(r) {
  if (!r || !r.solved || r.shown) return 0;
  let cost = 0;
  for (let i = 0; i < (r.hints || 0); i++) cost += [3, 5, 8][Math.min(i, 2)];
  const factor = r.tries <= 1 ? 1 : r.tries === 2 ? 0.5 : 0.25;
  return Math.max(0, Math.round(({ 1: 10, 2: 20, 3: 30 }[r.diff] || 10) * factor - cost) + (r.boss ? 50 : 0));
}

/** Higher is better: solved for XP > solved by showing the answer > attempted > untouched. */
function itemRank(r) {
  if (!r || typeof r !== 'object') return [-1, 0];
  if (r.solved && !r.shown) return [3, itemXP(r)];
  if (r.solved) return [2, 0];
  return [1, r.tries || 0];
}

function better(a, b) {
  const [ra, xa] = itemRank(a);
  const [rb, xb] = itemRank(b);
  if (ra !== rb) return ra > rb ? a : b;
  return xb > xa ? b : a;
}

const isObj = (x) => x && typeof x === 'object' && !Array.isArray(x);
const minDate = (a, b) => (!a ? b : !b ? a : a < b ? a : b);

/** Pre-tests are a baseline: the first one counts. Other tests keep the best score. */
function betterTest(kind, a, b) {
  if (!isObj(a)) return b;
  if (!isObj(b)) return a;
  if (/pre$/.test(kind)) return (b.ts || '') < (a.ts || '') ? b : a;
  if ((b.pct ?? -1) !== (a.pct ?? -1)) return (b.pct ?? -1) > (a.pct ?? -1) ? b : a;
  return (b.ts || '') > (a.ts || '') ? b : a;
}

/** Combine two game states (quest.js, version 1). `local` wins on settings. */
export function mergeGame(server, local) {
  if (!isObj(server) || server.v !== 1) return local;
  if (!isObj(local) || local.v !== 1) return server;
  const items = { ...server.items };
  for (const [id, r] of Object.entries(local.items || {})) items[id] = id in items ? better(items[id], r) : r;

  const badges = { ...server.badges };
  for (const [id, d] of Object.entries(local.badges || {})) badges[id] = minDate(badges[id], d);

  const tests = { ...server.tests };
  for (const [kind, t] of Object.entries(local.tests || {})) tests[kind] = betterTest(kind, tests[kind], t);

  const s1 = server.streak || {};
  const s2 = local.streak || {};
  const later = (s2.last || '') > (s1.last || '') ? s2 : (s1.last || '') > (s2.last || '') ? s1 : ((s2.count || 0) >= (s1.count || 0) ? s2 : s1);
  const streak = { last: later.last || null, count: later.count || 0, best: Math.max(s1.best || 0, s2.best || 0, later.count || 0) };

  return {
    ...server,
    ...local,
    v: 1,
    items,
    badges,
    tests,
    streak,
    settings: { ...(server.settings || {}), ...(local.settings || {}) },
    created: minDate(server.created, local.created),
  };
}

/** Quiz answers: { questionId: true|false }. A question answered right on either side stays right. */
export function mergeUnion(server, local) {
  if (!isObj(server)) return local;
  if (!isObj(local)) return server;
  const out = { ...server };
  for (const [k, v] of Object.entries(local)) out[k] = k in out ? !!(out[k] || v) : v;
  return out;
}

/**
 * Combine one key. `server` and `local` are { value, ts } or undefined; ts is milliseconds.
 * Returns { value, ts }.
 */
export function mergeKey(key, server, local) {
  if (!local) return server;
  if (!server) return local;
  const rule = ruleFor(key);
  if (rule === 'newest') return local.ts >= server.ts ? local : server;
  const value = rule === 'game' ? mergeGame(server.value, local.value) : mergeUnion(server.value, local.value);
  return { value, ts: Math.max(server.ts, local.ts) };
}
