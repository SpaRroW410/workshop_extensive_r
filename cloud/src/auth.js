// Sign-in (LAUNCH_PLAN.md §4): Better Auth on Pages Functions, storing users and sessions in D1.
// Google is the only way in for real users. Email + password exists ONLY for the automated tests,
// and only when AUTH_TEST_MODE=1 AND the site runs on localhost (see testMode below).
import { betterAuth } from 'better-auth';

/** Test sign-in is allowed only on a local address, never on a real domain, whatever the variables say. */
export function testMode(env) {
  return env.AUTH_TEST_MODE === '1' && /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(env.BASE_URL || '');
}

const cache = new WeakMap();

/** One Better Auth instance per environment object (Cloudflare reuses env across requests in an isolate). */
export function getAuth(env) {
  let auth = cache.get(env);
  if (auth) return auth;
  if (!env.BETTER_AUTH_SECRET) throw new Error('BETTER_AUTH_SECRET is not set (wrangler pages secret put BETTER_AUTH_SECRET)');
  auth = betterAuth({
    database: env.DB,
    baseURL: env.BASE_URL,
    basePath: '/api/auth',
    secret: env.BETTER_AUTH_SECRET,
    telemetry: { enabled: false },
    socialProviders: env.GOOGLE_CLIENT_ID
      ? { google: { clientId: env.GOOGLE_CLIENT_ID, clientSecret: env.GOOGLE_CLIENT_SECRET, prompt: 'select_account' } }
      : {},
    emailAndPassword: { enabled: testMode(env) },
    session: {
      expiresIn: 60 * 60 * 24 * 30, // 30 days
      updateAge: 60 * 60 * 24, // refresh the expiry at most once a day
    },
    advanced: { useSecureCookies: (env.BASE_URL || '').startsWith('https://') },
  });
  cache.set(env, auth);
  return auth;
}

/** The signed-in user for a request, or null. */
export async function currentUser(request, env) {
  const s = await getAuth(env).api.getSession({ headers: request.headers });
  return s ? s.user : null;
}

/** Product ids the user holds now (expired rows are ignored). */
export async function productsOf(env, userId) {
  const { results } = await env.DB
    .prepare('select "product" from "entitlement" where "userId" = ? and ("expiresAt" is null or "expiresAt" > ?)')
    .bind(userId, Date.now())
    .all();
  return results.map((r) => r.product);
}

export function json(body, status = 200, headers = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store', ...headers },
  });
}
