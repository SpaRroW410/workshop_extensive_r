#!/usr/bin/env node
// Give or take away a product by hand (until payments exist, this replaces the workshop keys).
//
//   node grant.mjs asha@example.com regression            give, no expiry
//   node grant.mjs asha@example.com regression --days 90  give for 90 days
//   node grant.mjs asha@example.com regression --revoke   take away
//   node grant.mjs asha@example.com --list                show what the user holds
//   add --local to act on the local test database instead of the live one
//
// The user must have signed in once (with Google) so that their account exists.
import { spawnSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { PRODUCTS } from './src/products.js';

const HERE = dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const flag = (f) => args.includes(f);
const opt = (f) => { const i = args.indexOf(f); return i >= 0 ? args[i + 1] : undefined; };
const [email, product] = args.filter((a, i) => !a.startsWith('--') && args[i - 1] !== '--days' && args[i - 1] !== '--persist-to');

function fail(msg) { console.error(msg); process.exit(1); }
if (!email || !/^[^\s@']+@[^\s@']+$/.test(email)) fail('Usage: node grant.mjs <email> <product> [--days N] [--revoke] [--list] [--local]');

const where = flag('--local') ? ['--local', ...(opt('--persist-to') ? ['--persist-to', opt('--persist-to')] : [])] : ['--remote'];
function sql(statement) {
  const r = spawnSync(join(HERE, 'node_modules', '.bin', 'wrangler'),
    ['d1', 'execute', 'medstats', ...where, '--json', '--command', statement],
    { cwd: HERE, encoding: 'utf8', env: { ...process.env, CI: '1' } });
  if (r.status !== 0) fail(r.stderr || r.stdout);
  return JSON.parse(r.stdout)[0].results;
}

const users = sql(`select "id", "name" from "user" where lower("email") = lower('${email}')`);
if (!users.length) fail(`No account for ${email}. They need to sign in once first.`);
const { id, name } = users[0];

if (flag('--list')) {
  const rows = sql(`select "product", "expiresAt", "source" from "entitlement" where "userId" = '${id}'`);
  console.log(`${name} <${email}>`);
  for (const r of rows) console.log(`  ${r.product.padEnd(12)} ${r.expiresAt ? 'until ' + new Date(r.expiresAt).toISOString().slice(0, 10) : 'no expiry'}  (${r.source})`);
  if (!rows.length) console.log('  no products');
  process.exit(0);
}

if (!PRODUCTS[product]) fail(`Unknown product "${product}". One of: ${Object.keys(PRODUCTS).join(', ')}`);

if (flag('--revoke')) {
  sql(`delete from "entitlement" where "userId" = '${id}' and "product" = '${product}'`);
  console.log(`Removed ${product} from ${name} <${email}>`);
} else {
  const days = opt('--days');
  if (days !== undefined && !/^\d+$/.test(days)) fail('--days takes a whole number');
  const expires = days ? Date.now() + Number(days) * 86400000 : 'null';
  sql(`insert into "entitlement" ("userId", "product", "expiresAt", "source", "createdAt") values ('${id}', '${product}', ${expires}, 'manual', ${Date.now()})
       on conflict ("userId", "product") do update set "expiresAt" = excluded."expiresAt", "source" = 'manual'`);
  console.log(`Gave ${product} to ${name} <${email}>${days ? ` for ${days} days` : ''}`);
}
