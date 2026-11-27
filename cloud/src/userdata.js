// Shared rules for what users write (CUSTOM_DECKS_PLAN.md §3.5–3.6): limits, validation, ids.
import { currentUser, json } from './auth.js';

export const LIMITS = {
  noteChars: 20000, notesPerUser: 2000,
  decksPerUser: 20, itemsPerDeck: 300, titleChars: 120,
  slidesPerUser: 200, slideBytes: 100 * 1024,
  body: 512 * 1024,
};

/** "<workshop>/<deck>#<id>", the stable slide reference. */
export const SLIDE_REF = /^[a-z0-9-]+-workshop\/s\d[\w]*#[A-Za-z][\w.-]{0,150}$/;
export const DECK_REF = /^[a-z0-9-]+-workshop\/s\d[\w]*$/;
export const ID = /^[A-Za-z0-9_-]{10,40}$/;

export function newId() {
  const b = crypto.getRandomValues(new Uint8Array(15));
  return btoa(String.fromCharCode(...b)).replace(/\+/g, '-').replace(/\//g, '_');
}

/** Signed-in user and parsed JSON body for a write; or a Response to return. */
export async function writeRequest(request, env) {
  const user = await currentUser(request, env);
  if (!user) return { error: json({ error: 'signed out' }, 401) };
  // JSON only: a form on another site cannot send this without the browser asking us first (CORS).
  if (!(request.headers.get('content-type') || '').startsWith('application/json')) return { error: json({ error: 'send JSON' }, 415) };
  const text = await request.text();
  if (text.length > LIMITS.body) return { error: json({ error: 'too large' }, 413) };
  let body;
  try { body = JSON.parse(text); } catch { return { error: json({ error: 'not JSON' }, 400) }; }
  if (!body || typeof body !== 'object') return { error: json({ error: 'not an object' }, 400) };
  return { user, body };
}

/** Items of a custom deck, checked. Returns null if any item is malformed. */
export function cleanItems(items) {
  if (!Array.isArray(items) || items.length > LIMITS.itemsPerDeck) return null;
  const out = [];
  for (const it of items) {
    if (it && it.type === 'slide' && typeof it.ref === 'string' && SLIDE_REF.test(it.ref)) out.push({ type: 'slide', ref: it.ref });
    else if (it && it.type === 'own' && typeof it.id === 'string' && ID.test(it.id)) out.push({ type: 'own', id: it.id });
    else return null;
  }
  return out;
}

const BLOCK_TYPES = new Set(['text', 'code', 'table', 'box']);
/** An own slide's JSON (§5.2): structure checked, sizes capped. Text stays text: the browser renders it safely. */
export function cleanSlide(s) {
  if (!s || typeof s !== 'object' || Array.isArray(s)) return null;
  const raw = JSON.stringify(s);
  if (raw.length > LIMITS.slideBytes) return null;
  if (typeof s.title !== 'string' || s.title.length > 300) return null;
  if (!Array.isArray(s.blocks) || s.blocks.length > 20) return null;
  if (!s.blocks.every((b) => b && BLOCK_TYPES.has(b.type))) return null;
  return JSON.parse(raw);
}
