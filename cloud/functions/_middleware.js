// The gate (LAUNCH_PLAN.md §5). Cloudflare runs this only on paid paths and /api (see _routes.json,
// written from src/products.js), so free pages never reach it.
import { productFor, holds, normalisePath } from '../src/products.js';
import { HIDDEN } from '../src/layout.js';
import { PAID_ROOT } from '../src/generated/paid-root.js';
import { currentUser, productsOf } from '../src/auth.js';

export async function onRequest({ request, env, next }) {
  const url = new URL(request.url);
  if (url.pathname.startsWith('/api/')) return next();
  // The hidden folder is only ever read by this Function (env.ASSETS.fetch), never asked for directly.
  if (url.pathname.startsWith(HIDDEN)) return new Response('Not found', { status: 404 });

  const product = productFor(url.pathname);
  if (!product) {
    // Free, but not excluded in _routes.json (Cloudflare's 100-rule limit): serve it.
    const res = await next();
    return marked(res, 'free');
  }

  let user = null;
  let held = [];
  try {
    user = await currentUser(request, env);
    held = user ? await productsOf(env, user.id) : [];
  } catch (e) {
    // Fail closed: if the database cannot be read, paid pages are not served.
    console.error('gate: session lookup failed', e);
    return new Response('Sign-in is unavailable for a moment. Please try again shortly.', {
      status: 503, headers: { 'retry-after': '60', 'cache-control': 'no-store' },
    });
  }

  if (holds(held, product)) {
    const res = await servePaid(request, env, url);
    const out = marked(res, 'pass');
    // Paid content must never sit in a shared cache.
    out.headers.set('cache-control', 'private, no-store');
    return out;
  }

  const isPage = (request.method === 'GET' || request.method === 'HEAD') &&
    (request.headers.get('accept') || '').includes('text/html');
  if (isPage) {
    const to = new URL('/account', url);
    to.searchParams.set('need', product);
    to.searchParams.set('next', url.pathname + url.search);
    return new Response(null, { status: 302, headers: { location: to.pathname + to.search, 'cache-control': 'no-store', 'x-gate': 'locked' } });
  }
  return new Response(user ? 'Your account does not include this.' : 'Sign in to open this.', {
    status: user ? 403 : 401,
    headers: { 'content-type': 'text/plain; charset=utf-8', 'cache-control': 'no-store', 'x-gate': 'locked' },
  });
}

/** Fetch a paid file from the hidden folder, and keep the folder name out of any redirect. */
async function servePaid(request, env, url) {
  const path = normalisePath(url.pathname); // the gate already refused paths it cannot normalise
  const inner = new URL(HIDDEN + PAID_ROOT + encodeURI(path) + url.search, url);
  const res = await env.ASSETS.fetch(new Request(inner, { method: request.method, headers: request.headers, redirect: 'manual' }));
  const hidden = HIDDEN + PAID_ROOT;
  const loc = res.headers.get('location');
  if (loc) {
    // Pages redirects "page.html" to "page" and "dir" to "dir/": translate back to the public path.
    const to = new URL(loc, inner);
    const out = new Response(null, res);
    out.headers.set('location', to.pathname.startsWith(hidden) ? to.pathname.slice(hidden.length) + to.search : '/');
    return out;
  }
  return res;
}

/** Tag a response with what the gate decided (used by the tests; harmless in production). */
function marked(res, how) {
  const out = new Response(res.body, res);
  out.headers.set('x-gate', how);
  return out;
}
