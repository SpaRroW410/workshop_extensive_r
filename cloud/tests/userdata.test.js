// Notes, custom decks and own slides (CUSTOM_DECKS_PLAN.md phases C2–C4): stored per account, private,
// shared only by link, validated, capped.
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { startSite, testSignIn } from './helpers.js';

let site; let asha; let ravi;
before(async () => {
  site = await startSite();
  asha = await testSignIn(site.base, 'asha.notes@example.test', 'Asha');
  ravi = await testSignIn(site.base, 'ravi.notes@example.test', 'Ravi');
});
after(async () => { await site?.stop(); });

const call = (method, path, cookie, body) => fetch(site.base + path, {
  method, headers: { cookie: cookie || '', 'content-type': 'application/json', origin: site.base },
  body: body === undefined ? undefined : JSON.stringify(body),
});
const S = 'stats-workshop/s2_assumptions#compare-the-spreads';

test('signed out: every user-data API refuses', async () => {
  for (const [m, p] of [['GET', '/api/notes'], ['PUT', '/api/notes'], ['GET', '/api/decks'], ['POST', '/api/decks'], ['GET', '/api/slides'], ['POST', '/api/slides']]) {
    assert.equal((await call(m, p, '', m === 'GET' ? undefined : {})).status, 401, `${m} ${p}`);
  }
});

test('notes: write, read back by deck, edit, delete with empty text; private to the account', async () => {
  assert.equal((await call('PUT', '/api/notes', asha, { slide: S, text: 'Levene is oversensitive with large n' })).status, 200);
  assert.equal((await call('PUT', '/api/notes', asha, { slide: 'stats-workshop/s4_two_groups#reading-it', text: 'other deck' })).status, 200);
  let r = await (await call('GET', '/api/notes?deck=stats-workshop/s2_assumptions', asha)).json();
  assert.deepEqual(Object.keys(r.notes), ['compare-the-spreads']);
  assert.equal(r.notes['compare-the-spreads'].text, 'Levene is oversensitive with large n');
  await call('PUT', '/api/notes', asha, { slide: S, text: 'edited' });
  r = await (await call('GET', '/api/notes', asha)).json();
  assert.equal(r.notes[S].text, 'edited');
  r = await (await call('GET', '/api/notes?deck=stats-workshop/s2_assumptions', ravi)).json();
  assert.deepEqual(r.notes, {}, 'another account sees nothing');
  await call('PUT', '/api/notes', asha, { slide: S, text: '   ' });
  r = await (await call('GET', '/api/notes?deck=stats-workshop/s2_assumptions', asha)).json();
  assert.deepEqual(r.notes, {});
});

test('notes: bad slide references, oversized text and non-JSON bodies are refused', async () => {
  assert.equal((await call('PUT', '/api/notes', asha, { slide: '../etc/passwd', text: 'x' })).status, 400);
  assert.equal((await call('PUT', '/api/notes', asha, { slide: S, text: 'x'.repeat(20001) })).status, 400);
  assert.equal((await call('GET', '/api/notes?deck=a%25', asha)).status, 400);
  const form = await fetch(site.base + '/api/notes', { method: 'PUT', headers: { cookie: asha, 'content-type': 'application/x-www-form-urlencoded' }, body: 'slide=x' });
  assert.equal(form.status, 415);
});

test('custom decks: create, list, update, share by link (read-only), unshare, delete', async () => {
  const items = [{ type: 'slide', ref: 'stats-workshop/s1_know_your_data#where-we-are' }, { type: 'slide', ref: S }];
  let r = await call('POST', '/api/decks', asha, { title: 'My stats revision', items });
  assert.equal(r.status, 201);
  const { id } = await r.json();
  r = await (await call('GET', '/api/decks', asha)).json();
  assert.equal(r.decks.length, 1); assert.equal(r.decks[0].count, 2); assert.equal(r.decks[0].shared, false);
  assert.equal((await call('GET', `/api/decks/${id}`, ravi)).status, 404, 'not visible to another account');
  assert.equal((await call('PUT', `/api/decks/${id}`, ravi, { title: 'hijack' })).status, 404);
  r = await (await call('PUT', `/api/decks/${id}`, asha, { share: true, items: [...items].reverse() })).json();
  assert.ok(r.share);
  const viaLink = await (await call('GET', `/api/decks/${id}?share=${r.share}`, ravi)).json();
  assert.equal(viaLink.deck.title, 'My stats revision'); assert.equal(viaLink.deck.owner, false);
  assert.equal(viaLink.deck.items[0].ref, S); assert.equal(viaLink.deck.share, undefined, 'the token is not echoed to viewers');
  assert.equal((await call('GET', `/api/decks/${id}?share=${r.share}`, '')).status, 200, 'link works signed out');
  assert.equal((await call('GET', `/api/decks/${id}?share=wrongtoken123`, '')).status, 404);
  await call('PUT', `/api/decks/${id}`, asha, { share: false });
  assert.equal((await call('GET', `/api/decks/${id}?share=${r.share}`, '')).status, 404, 'unshared link stops working');
  assert.equal((await call('DELETE', `/api/decks/${id}`, asha)).status, 200);
  assert.equal((await call('GET', `/api/decks/${id}`, asha)).status, 404);
});

test('custom decks: malformed items and missing titles are refused', async () => {
  assert.equal((await call('POST', '/api/decks', asha, { title: 'x', items: [{ type: 'slide', ref: 'https://evil.example/' }] })).status, 400);
  assert.equal((await call('POST', '/api/decks', asha, { title: 'x', items: [{ type: 'html', html: '<script>' }] })).status, 400);
  assert.equal((await call('POST', '/api/decks', asha, { title: '  ', items: [] })).status, 400);
});

test('own slides: create (anchored after a workshop slide), list by deck, edit, use in a shared deck, delete', async () => {
  const body = { title: 'My Welch test', layout: 'code-output', font: 'deck', align: 'left',
    blocks: [{ type: 'text', size: 'M', markdown: 'Weight by **sex**' }, { type: 'code', code: 't.test(weight ~ sex, data = p)', output: { space: 'beside' } }] };
  let r = await call('POST', '/api/slides', asha, { body, anchor: S });
  assert.equal(r.status, 201);
  const { id } = await r.json();
  r = await (await call('GET', '/api/slides?anchor=stats-workshop/s2_assumptions', asha)).json();
  assert.equal(r.slides.length, 1); assert.equal(r.slides[0].body.title, 'My Welch test');
  assert.equal((await (await call('GET', '/api/slides?anchor=stats-workshop/s2_assumptions', ravi)).json()).slides.length, 0);
  assert.equal((await call('PUT', `/api/slides/${id}`, ravi, { body })).status, 404, 'another account cannot edit it');
  assert.equal((await call('PUT', `/api/slides/${id}`, asha, { body: { ...body, title: 'Renamed' } })).status, 200);
  // In a shared deck the viewer gets the slide's content with the deck.
  const d = await (await call('POST', '/api/decks', asha, { title: 'With my slide', items: [{ type: 'own', id }] })).json();
  const { share } = await (await call('PUT', `/api/decks/${d.id}`, asha, { share: true })).json();
  const shared = await (await call('GET', `/api/decks/${d.id}?share=${share}`, '')).json();
  assert.equal(shared.deck.own[id].title, 'Renamed');
  assert.equal((await call('DELETE', `/api/slides/${id}`, asha)).status, 200);
});

test('own slides: wrong structure and oversized slides are refused', async () => {
  assert.equal((await call('POST', '/api/slides', asha, { body: { title: 'x', blocks: [{ type: 'script', src: 'x' }] } })).status, 400);
  assert.equal((await call('POST', '/api/slides', asha, { body: { title: 'x', blocks: [{ type: 'text', markdown: 'y'.repeat(110 * 1024) }] } })).status, 400);
  assert.equal((await call('POST', '/api/slides', asha, { body: { title: 'x', blocks: [] }, anchor: 'nope' })).status, 400);
});
