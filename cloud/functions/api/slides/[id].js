// /api/slides/:id — PUT { body?, anchor? } or DELETE one of the signed-in user's own slides.
import { currentUser, json } from '../../../src/auth.js';
import { ID, SLIDE_REF, cleanSlide, writeRequest } from '../../../src/userdata.js';

async function mine(env, id, userId) {
  if (!ID.test(id)) return null;
  const row = await env.DB.prepare('select * from "own_slide" where "id" = ?').bind(id).first();
  return row && row.userId === userId ? row : null;
}

export async function onRequestPut({ request, env, params }) {
  const { user, body, error } = await writeRequest(request, env);
  if (error) return error;
  const row = await mine(env, params.id, user.id);
  if (!row) return json({ error: 'not found' }, 404);
  let text = row.body; let anchor = row.anchor;
  if (body.body !== undefined) { const s = cleanSlide(body.body); if (!s) return json({ error: 'bad slide' }, 400); text = JSON.stringify(s); }
  if (body.anchor !== undefined) {
    if (body.anchor !== null && (typeof body.anchor !== 'string' || !SLIDE_REF.test(body.anchor))) return json({ error: 'bad anchor' }, 400);
    anchor = body.anchor;
  }
  const now = Date.now();
  await env.DB.prepare('update "own_slide" set "body" = ?, "anchor" = ?, "updatedAt" = ? where "id" = ?').bind(text, anchor, now, row.id).run();
  return json({ ok: true, updatedAt: now });
}

export async function onRequestDelete({ request, env, params }) {
  const user = await currentUser(request, env);
  if (!user) return json({ error: 'signed out' }, 401);
  const row = await mine(env, params.id, user.id);
  if (!row) return json({ error: 'not found' }, 404);
  await env.DB.prepare('delete from "own_slide" where "id" = ?').bind(row.id).run();
  return json({ ok: true });
}
