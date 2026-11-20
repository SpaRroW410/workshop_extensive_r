// /api/progress — saved progress for the signed-in user (LAUNCH_PLAN.md §6).
//
// GET  -> { items: { key: { value, ts } } }
// POST { set: { key: { value, ts } }, delete: [key], visit: { path, title } }
//      -> deletes, then merges each key with what is stored (src/merge.js), records the visit,
//         and answers with every stored key, as GET does. One call per page load.
//
// A delete (the game's Reset, a quiz's Reset) leaves a marker "reset:<key>" with its time. A copy
// that another device last changed BEFORE that time is not merged back in; that device is told to
// drop it ("gone"). Without this, merging would bring reset progress straight back.
import { currentUser, json } from '../../src/auth.js';
import { limitFor, mergeKey } from '../../src/merge.js';

const MAX_BODY = 1024 * 1024;
const MAX_KEYS = 300;

async function stored(env, userId) {
  const { results } = await env.DB.prepare('select "key", "value", "updatedAt" from "progress" where "userId" = ?').bind(userId).all();
  const items = {};
  const resets = {};
  for (const r of results) {
    if (r.key.startsWith('reset:')) { resets[r.key.slice(6)] = r.updatedAt; continue; }
    try { items[r.key] = { value: JSON.parse(r.value), ts: r.updatedAt }; } catch { /* skip a damaged row */ }
  }
  return { items, resets };
}

export async function onRequestGet({ request, env }) {
  const user = await currentUser(request, env);
  if (!user) return json({ error: 'signed out' }, 401);
  return json({ items: (await stored(env, user.id)).items });
}

export async function onRequestPost({ request, env }) {
  const user = await currentUser(request, env);
  if (!user) return json({ error: 'signed out' }, 401);
  if (!(request.headers.get('content-type') || '').startsWith('application/json')) return json({ error: 'send JSON' }, 415);

  const text = await request.text();
  if (text.length > MAX_BODY) return json({ error: 'too large' }, 413);
  let body;
  try { body = JSON.parse(text); } catch { return json({ error: 'not JSON' }, 400); }
  if (!body || typeof body !== 'object') return json({ error: 'not an object' }, 400);

  const now = Date.now();
  const writes = [];
  const del = Array.isArray(body.delete) ? body.delete.filter((k) => typeof k === 'string' && limitFor(k)) : [];
  const upsert = 'insert into "progress" ("userId", "key", "value", "updatedAt") values (?, ?, ?, ?) ' +
    'on conflict ("userId", "key") do update set "value" = excluded."value", "updatedAt" = excluded."updatedAt"';
  for (const k of del) {
    writes.push(env.DB.prepare('delete from "progress" where "userId" = ? and "key" = ?').bind(user.id, k));
    writes.push(env.DB.prepare(upsert).bind(user.id, 'reset:' + k, 'null', now));
  }

  const { items, resets } = await stored(env, user.id);
  for (const k of del) { delete items[k]; resets[k] = now; }

  const refused = [];
  const gone = [];
  const set = body.set && typeof body.set === 'object' ? body.set : {};
  for (const [key, local] of Object.entries(set)) {
    const limit = limitFor(key);
    const raw = local && JSON.stringify(local.value);
    if (!limit || raw === undefined || raw.length > limit || typeof local.ts !== 'number') { refused.push(key); continue; }
    if (!(key in items) && Object.keys(items).length >= MAX_KEYS) { refused.push(key); continue; }
    // A browser clock running ahead must not make its copy win for ever.
    const incoming = { value: local.value, ts: Math.min(local.ts, now) };
    // Changed before a reset elsewhere: not merged back. (A delete and a set in this same request is a
    // reset done here, so the set is the fresh state and is kept.)
    if (resets[key] !== undefined && incoming.ts < resets[key] && !del.includes(key)) { if (!(key in items)) gone.push(key); continue; }
    const merged = mergeKey(key, items[key], incoming);
    const out = JSON.stringify(merged.value);
    if (items[key] && JSON.stringify(items[key].value) === out && items[key].ts === merged.ts) continue;
    items[key] = merged;
    writes.push(env.DB.prepare(upsert).bind(user.id, key, out, merged.ts));
  }

  const v = body.visit;
  if (v && typeof v.path === 'string' && /^\/(?!\/)/.test(v.path) && v.path.length <= 300 &&
      !['/', '/account', '/index.html'].includes(v.path)) {
    const title = typeof v.title === 'string' ? v.title.slice(0, 200) : '';
    writes.push(env.DB.prepare(
      'insert into "visit" ("userId", "path", "title", "seenAt") values (?, ?, ?, ?) ' +
      'on conflict ("userId") do update set "path" = excluded."path", "title" = excluded."title", "seenAt" = excluded."seenAt"',
    ).bind(user.id, v.path, title, now));
  }

  if (writes.length) await env.DB.batch(writes);
  const answer = { items };
  if (refused.length) answer.refused = refused;
  if (gone.length) answer.gone = gone;
  return json(answer);
}
