// /api/decks — the signed-in user's custom decks (CUSTOM_DECKS_PLAN.md §3.5, phase C3).
// GET                       -> { decks: [{ id, title, count, shared, updatedAt }] }
// POST { title, items }     -> { id }
import { currentUser, json } from '../../../src/auth.js';
import { LIMITS, cleanItems, newId, writeRequest } from '../../../src/userdata.js';

export async function onRequestGet({ request, env }) {
  const user = await currentUser(request, env);
  if (!user) return json({ error: 'signed out' }, 401);
  const { results } = await env.DB.prepare('select "id", "title", "items", "share", "updatedAt" from "custom_deck" where "userId" = ? order by "updatedAt" desc').bind(user.id).all();
  return json({ decks: results.map((r) => ({ id: r.id, title: r.title, count: JSON.parse(r.items).length, shared: !!r.share, updatedAt: r.updatedAt })) });
}

export async function onRequestPost({ request, env }) {
  const { user, body, error } = await writeRequest(request, env);
  if (error) return error;
  const title = typeof body.title === 'string' ? body.title.trim().slice(0, LIMITS.titleChars) : '';
  const items = cleanItems(body.items ?? []);
  if (!title) return json({ error: 'a deck needs a title' }, 400);
  if (!items) return json({ error: 'bad items' }, 400);
  const { n } = await env.DB.prepare('select count(*) as n from "custom_deck" where "userId" = ?').bind(user.id).first();
  if (n >= LIMITS.decksPerUser) return json({ error: `up to ${LIMITS.decksPerUser} custom decks per account` }, 403);
  const id = newId(); const now = Date.now();
  await env.DB.prepare('insert into "custom_deck" ("id", "userId", "title", "items", "share", "createdAt", "updatedAt") values (?, ?, ?, ?, null, ?, ?)')
    .bind(id, user.id, title, JSON.stringify(items), now, now).run();
  return json({ id }, 201);
}
