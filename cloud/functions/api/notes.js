// /api/notes — the signed-in user's notes on workshop slides (CUSTOM_DECKS_PLAN.md §3.5, phase C2).
// GET  ?deck=<workshop>/<deck>  -> { notes: { "<slide id>": { text, ts } } }   (without ?deck or ?page: every note)
// GET  ?page=<folder>/<page>    -> { notes: { "<section or slide id>": { text, ts } } }   (Basic/Moderate pages)
// PUT  { slide: "<workshop>/<deck>#<id>" | "page:<folder>/<page>#<id>", text }  -> { ok, ts }   (empty text deletes)
import { currentUser, json } from '../../src/auth.js';
import { LIMITS, SLIDE_REF, DECK_REF, PAGE_NOTE_REF, PAGE_REF, writeRequest } from '../../src/userdata.js';

export async function onRequestGet({ request, env }) {
  const user = await currentUser(request, env);
  if (!user) return json({ error: 'signed out' }, 401);
  const params = new URL(request.url).searchParams;
  const deckParam = params.get('deck'); const pageParam = params.get('page');
  if (deckParam !== null && !DECK_REF.test(deckParam)) return json({ error: 'bad deck' }, 400);
  if (pageParam !== null && !PAGE_REF.test(pageParam)) return json({ error: 'bad page' }, 400);
  const deck = deckParam !== null ? deckParam : pageParam !== null ? 'page:' + pageParam : null;
  const q = deck
    ? env.DB.prepare('select "slide", "text", "updatedAt" from "note" where "userId" = ? and "slide" like ? escape \'\\\'').bind(user.id, deck.replace(/[\\%_]/g, '\\$&') + '#%')
    : env.DB.prepare('select "slide", "text", "updatedAt" from "note" where "userId" = ?').bind(user.id);
  const { results } = await q.all();
  const notes = {};
  for (const r of results) notes[deck ? r.slide.split('#')[1] : r.slide] = { text: r.text, ts: r.updatedAt };
  return json({ notes });
}

export async function onRequestPut({ request, env }) {
  const { user, body, error } = await writeRequest(request, env);
  if (error) return error;
  const { slide, text } = body;
  if (typeof slide !== 'string' || !(SLIDE_REF.test(slide) || PAGE_NOTE_REF.test(slide))) return json({ error: 'bad slide' }, 400);
  if (typeof text !== 'string' || text.length > LIMITS.noteChars) return json({ error: `a note holds up to ${LIMITS.noteChars} characters` }, 400);
  const now = Date.now();
  if (!text.trim()) {
    await env.DB.prepare('delete from "note" where "userId" = ? and "slide" = ?').bind(user.id, slide).run();
    return json({ ok: true, ts: now });
  }
  const { n } = await env.DB.prepare('select count(*) as n from "note" where "userId" = ? and "slide" != ?').bind(user.id, slide).first();
  if (n >= LIMITS.notesPerUser) return json({ error: `up to ${LIMITS.notesPerUser} notes per account` }, 403);
  await env.DB.prepare('insert into "note" ("userId", "slide", "text", "updatedAt") values (?, ?, ?, ?) ' +
    'on conflict ("userId", "slide") do update set "text" = excluded."text", "updatedAt" = excluded."updatedAt"')
    .bind(user.id, slide, text, now).run();
  return json({ ok: true, ts: now });
}
