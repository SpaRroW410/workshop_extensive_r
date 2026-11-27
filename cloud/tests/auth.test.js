// Phase 1: sign-in, D1 schema, /api/me (LAUNCH_PLAN.md §9).
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { startSite, testSignIn } from './helpers.js';

let site;
before(async () => { site = await startSite(); });
after(async () => { await site?.stop(); });

test('signed out, /api/me says so', async () => {
  const r = await fetch(site.base + '/api/me');
  assert.equal(r.status, 200);
  assert.equal(r.headers.get('cache-control'), 'no-store');
  const body = await r.json();
  assert.equal(body.user, null);
  assert.deepEqual(body.products, []);
  assert.deepEqual(body.open, { basic: true, moderate: false, regression: false, statistics: false, advanced: false, 'dataviz-base': false, 'dataviz-complete': false, gis: false, dungeons: true });
});

test('Sign in with Google starts at Google with our client id and callback', async () => {
  const r = await fetch(site.base + '/api/auth/sign-in/social', {
    method: 'POST',
    headers: { 'content-type': 'application/json', origin: site.base },
    body: JSON.stringify({ provider: 'google', callbackURL: '/' }),
  });
  assert.equal(r.status, 200, await r.clone().text());
  const { url } = await r.json();
  const u = new URL(url);
  assert.equal(u.origin, 'https://accounts.google.com');
  assert.equal(u.searchParams.get('client_id'), 'test-client-id.apps.googleusercontent.com');
  assert.equal(u.searchParams.get('redirect_uri'), site.base + '/api/auth/callback/google');
  assert.match(u.searchParams.get('scope'), /email/);
  assert.ok(u.searchParams.get('state'), 'state parameter protects the callback');
});

test('a callback that did not come from our own sign-in is refused', async () => {
  const r = await fetch(site.base + '/api/auth/callback/google?code=forged&state=forged', { redirect: 'manual' });
  // Better Auth redirects to its error page; it must not set a session cookie.
  assert.ok([302, 400, 401, 403].includes(r.status), `status ${r.status}`);
  assert.ok(!r.headers.getSetCookie().some((c) => c.includes('session_token=') && !c.includes('Max-Age=0')));
});

test('signed in, /api/me returns the user and no products; then the products granted', async () => {
  const cookie = await testSignIn(site.base, 'asha@example.test', 'Asha Verma');
  let me = await (await fetch(site.base + '/api/me', { headers: { cookie } })).json();
  assert.equal(me.user.name, 'Asha Verma');
  assert.equal(me.user.email, 'asha@example.test');
  assert.deepEqual(me.products, []);

  const id = me.user.id;
  const now = Date.now();
  site.sql(`insert into entitlement values ('${id}', 'regression', null, 'manual', ${now})`);
  site.sql(`insert into entitlement values ('${id}', 'gis', ${now - 1000}, 'manual', ${now})`); // already expired
  me = await (await fetch(site.base + '/api/me', { headers: { cookie } })).json();
  assert.deepEqual(me.products, ['regression']);
});

test('sign-out ends the session', async () => {
  const cookie = await testSignIn(site.base, 'ravi@example.test', 'Ravi');
  // Better Auth wants a JSON body here (415 otherwise); the browser code sends one too.
  const out = await fetch(site.base + '/api/auth/sign-out', {
    method: 'POST', headers: { cookie, origin: site.base, 'content-type': 'application/json' }, body: '{}',
  });
  assert.equal(out.status, 200);
  const me = await (await fetch(site.base + '/api/me', { headers: { cookie } })).json();
  assert.equal(me.user, null);
});

test('a forged session cookie is ignored', async () => {
  const me = await (await fetch(site.base + '/api/me', {
    headers: { cookie: 'better-auth.session_token=abc.def' },
  })).json();
  assert.equal(me.user, null);
});

test('the test-only email login is off on a real address, even with AUTH_TEST_MODE=1', async () => {
  const prod = await startSite({ vars: { BASE_URL: 'https://medstats.example' } });
  try {
    const r = await fetch(prod.base + '/api/auth/sign-up/email', {
      method: 'POST',
      headers: { 'content-type': 'application/json', origin: 'https://medstats.example' },
      body: JSON.stringify({ email: 'x@example.test', password: 'correct-horse-battery', name: 'X' }),
    });
    assert.ok(r.status >= 400, `sign-up answered ${r.status}`);
    assert.equal(prod.sql('select count(*) as n from "user"')[0].n, 0);
  } finally {
    await prod.stop();
  }
});
