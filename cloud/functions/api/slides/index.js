// /api/slides — slides the signed-in user made (CUSTOM_DECKS_PLAN.md §5, phase C4).
// GET [?anchor=<workshop>/<deck>]  -> { slides: [{ id, body, anchor, updatedAt }] }  (anchor: only those placed in that deck)
// POST { body, anchor? }           -> { id }   anchor = "<workshop>/<deck>#<id>": shown after that slide, to this user only
import { currentUser, json } from '../../../src/auth.js';
import { LIMITS, SLIDE_REF, DECK_REF, cleanSlide, newId, writeRequest } from '../../../src/userdata.js';

export async function onRequestGet({ request, env }) {
  const user = await currentUser(request, env);
  if (!user) return json({ error: 'signed out' }, 401);
  const deck = new URL(request.url).searchParams.get('anchor');
  if (deck !== null && !DECK_REF.test(deck)) return json({ error: 'bad anchor' }, 400);
  const q = deck
    ? env.DB.prepare('select * from "own_slide" where "userId" = ? and "anchor" like ? escape \'\\\' order by "createdAt"').bind(user.id, deck.replace(/[\\%_]/g, '\\$&') + '#%')
    : env.DB.prepare('select * from "own_slide" where "userId" = ? order by "createdAt"').bind(user.id);
  const { results } = await q.all();
  return json({ slides: results.map((r) => ({ id: r.id, body: JSON.parse(r.body), anchor: r.anchor, updatedAt: r.updatedAt })) });
}

export async function onRequestPost({ request, env }) {
  const { user, body, error } = await writeRequest(request, env);
  if (error) return error;
  const slide = cleanSlide(body.body);
  if (!slide) return json({ error: 'bad slide' }, 400);
  const anchor = body.anchor ?? null;
  if (anchor !== null && (typeof anchor !== 'string' || !SLIDE_REF.test(anchor))) return json({ error: 'bad anchor' }, 400);
  const { n } = await env.DB.prepare('select count(*) as n from "own_slide" where "userId" = ?').bind(user.id).first();
  if (n >= LIMITS.slidesPerUser) return json({ error: `up to ${LIMITS.slidesPerUser} own slides per account` }, 403);
  const id = newId(); const now = Date.now();
  await env.DB.prepare('insert into "own_slide" ("id", "userId", "body", "anchor", "createdAt", "updatedAt") values (?, ?, ?, ?, ?, ?)')
    .bind(id, user.id, JSON.stringify(slide), anchor, now, now).run();
  return json({ id }, 201);
}
