// grant.mjs: give, list and revoke a product by hand.
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { startSite, testSignIn } from './helpers.js';

const GRANT = new URL('../grant.mjs', import.meta.url).pathname;
let site;
before(async () => { site = await startSite(); });
after(async () => { await site?.stop(); });

const grant = (...a) => spawnSync(process.execPath, [GRANT, ...a, '--local', '--persist-to', site.persist], { encoding: 'utf8' });

test('give, list, revoke', async () => {
  const cookie = await testSignIn(site.base, 'meera@example.test', 'Meera');
  const me = async () => (await (await fetch(site.base + '/api/me', { headers: { cookie } })).json()).products;

  let r = grant('meera@example.test', 'gis', '--days', '30');
  assert.equal(r.status, 0, r.stderr);
  assert.deepEqual(await me(), ['gis']);

  r = grant('Meera@Example.test', '--list');
  assert.match(r.stdout, /gis\s+until \d{4}-\d\d-\d\d/);

  r = grant('meera@example.test', 'gis', '--revoke');
  assert.equal(r.status, 0, r.stderr);
  assert.deepEqual(await me(), []);
});

test('refuses unknown products, unknown users and odd input', () => {
  assert.match(grant('meera@example.test', 'everything').stderr, /Unknown product/);
  assert.match(grant('nobody@example.test', 'gis').stderr, /No account/);
  assert.match(grant("x'; drop table user; --@a.b", 'gis').stderr, /Usage/);
  assert.match(grant('meera@example.test', 'gis', '--days', '1; drop').stderr, /whole number/);
});
