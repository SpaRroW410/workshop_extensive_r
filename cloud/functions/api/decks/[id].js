// /api/decks/:id — one custom deck.
// GET                 owner: { deck }; anyone with ?share=<token>: the same, read-only (owner fields left out)
//                     deck = { id, title, items, share?, own: { "<own slide id>": body } }
// PUT { title?, items?, share?: true|false }   owner only; share:true makes (or keeps) a link token, false removes it
// DELETE              owner only
import { currentUser, json } from '../../../src/auth.js';
import { LIMITS, ID, cleanItems, newId, writeRequest } from '../../../src/userdata.js';

async function load(env, id) {
  if (!ID.test(id)) return null;
  return env.DB.prepare('select * from "custom_deck" where "id" = ?').bind(id).first();
}

async function ownSlides(env, userId, items) {
  const ids = items.filter((i) => i.type === 'own').map((i) => i.id);
  if (!ids.length) return {};
  const { results } = await env.DB.prepare(`select "id", "body" from "own_slide" where "userId" = ? and "id" in (${ids.map(() => '?').join(',')})`)
    .bind(userId, ...ids).all();
  return Object.fromEntries(results.map((r) => [r.id, JSON.parse(r.body)]));
}

export async function onRequestGet({ request, env, params }) {
  const row = await load(env, params.id);
  const token = new URL(request.url).searchParams.get('share');
  const user = await currentUser(request, env);
  const owner = row && user && row.userId === user.id;
  const viaLink = row && token && row.share && token === row.share;
  if (!owner && !viaLink) return json({ error: 'not found' }, 404);
  const items = JSON.parse(row.items);
  const deck = { id: row.id, title: row.title, items, own: await ownSlides(env, row.userId, items), owner: !!owner };
  if (owner) deck.share = row.share;
  return json({ deck });
}

export async function onRequestPut({ request, env, params }) {
  const { user, body, error } = await writeRequest(request, env);
  if (error) return error;
  const row = await load(env, params.id);
  if (!row || row.userId !== user.id) return json({ error: 'not found' }, 404);
  let { title, items, share } = row;
  if (body.title !== undefined) {
    title = typeof body.title === 'string' ? body.title.trim().slice(0, LIMITS.titleChars) : '';
    if (!title) return json({ error: 'a deck needs a title' }, 400);
  }
  if (body.items !== undefined) {
    const clean = cleanItems(body.items);
    if (!clean) return json({ error: 'bad items' }, 400);
    items = JSON.stringify(clean);
  }
  if (body.share === true && !share) share = newId();
  if (body.share === false) share = null;
  const now = Date.now();
  await env.DB.prepare('update "custom_deck" set "title" = ?, "items" = ?, "share" = ?, "updatedAt" = ? where "id" = ?').bind(title, items, share, now, row.id).run();
  return json({ ok: true, share, updatedAt: now });
}

export async function onRequestDelete({ request, env, params }) {
  const user = await currentUser(request, env);
  if (!user) return json({ error: 'signed out' }, 401);
  const row = await load(env, params.id);
  if (!row || row.userId !== user.id) return json({ error: 'not found' }, 404);
  await env.DB.prepare('delete from "custom_deck" where "id" = ?').bind(row.id).run();
  return json({ ok: true });
}
