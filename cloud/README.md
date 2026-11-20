# cloud/ — the site on Cloudflare: sign-in, paid access, saved progress

This folder carries out phases 0 to 3 of [`LAUNCH_PLAN.md`](../LAUNCH_PLAN.md). Nothing here is live yet:
GitHub Pages keeps serving `docs/` exactly as before until you switch.

## How it fits together

```
Quarto renders docs/            (on your machine, as today)
      │
node stage.mjs                  copies docs/ to cloud/.deploy and:
      │                           • moves paid files out of their public paths (src/layout.js says why)
      │                           • writes _routes.json: Functions run only on paid paths and /api
      │                           • adds ws-sync.js (progress sync) to every page
      │                           • removes the workshop keys from config.json, adds gate: "server"
      │                           • refuses to continue if facilitator solutions or files > 25 MiB are present
bash deploy.sh                  uploads cloud/.deploy to Cloudflare Pages (direct upload, no Git connection)
```

| File | Job |
|---|---|
| `src/products.js` | **The one place** that says which paths are paid, for which product, and what stays free |
| `functions/_middleware.js` | The gate: paid page + right product → page; otherwise → `/account` (or 401/403) |
| `functions/api/me.js` | Who is signed in, products held, which tracks are open, last page visited |
| `functions/api/progress.js` | Saved progress: merges what a browser has with the account (`src/merge.js`) |
| `functions/api/auth/[[path]].js` | Google sign-in (Better Auth) |
| `static/account.html` | Sign in / signed in / "your account does not include X — ask your organiser" |
| `static/ws-sync.js` | In the browser: syncs the game, quiz scores and study-plan ticks when signed in |
| `grant.mjs` | Give or take away a product by hand (replaces the shared keys until payments exist) |
| `migrations/` | The database tables (D1) |

Free without sign-in: the Basic track, every track's home page, Session 1 + lab 1 + cheat sheet of every
workshop, the synthetic datasets, and Region 1 of the game. This is the plan's proposal (§5) and still
needs your confirmation.

## Tests

```sh
cd cloud
npm ci
npm test                 # 42 tests: product map, staging checks, sign-in, gate, progress (local Cloudflare + D1)
npm run test:e2e         # stages the real site and drives it in a browser (needs a rendered docs/)
node tests/e2e/sync.e2e.mjs   # two devices, a reset, a shared computer
```

The tests sign in with an email + password login that exists only when `AUTH_TEST_MODE=1` **and** the
address is `localhost`; on any real address it is off (a test checks this).

## Going live — needs your accounts (plan, phases 0 and 1)

1. **Cloudflare** (free plan). `cd cloud && npx wrangler login`
2. **Database.** `npx wrangler d1 create medstats` and paste the `database_id` it prints into `wrangler.toml`.
3. **Pages project.** `npx wrangler pages project create medstats --production-branch main`
4. **Google sign-in.** In Google Cloud Console → APIs & Services → Credentials, create an *OAuth client ID*
   (Web application). Authorised redirect URI: `https://medstats.pages.dev/api/auth/callback/google`
   (and later the same on your own domain).
5. **Secrets.**
   ```sh
   openssl rand -base64 32 | npx wrangler pages secret put BETTER_AUTH_SECRET --project-name medstats
   npx wrangler pages secret put GOOGLE_CLIENT_ID --project-name medstats
   npx wrangler pages secret put GOOGLE_CLIENT_SECRET --project-name medstats
   ```
6. **First deploy, to a preview address:** `bash deploy.sh --preview`. Sign in with Google there, then give
   yourself a product: `node grant.mjs you@gmail.com all-access`.
7. When happy: `bash deploy.sh` (production). Set `BASE_URL` in `wrangler.toml` when the custom domain is added.

For the GitHub Action (`.github/workflows/deploy.yml`, manual only), add the repository secrets
`CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`.

## Still to find out before taking money

- What Cloudflare does when the 100,000 daily Function requests run out (plan §2). Free pages are
  plain static files and do not count; paid pages and signed-in syncing do.
- Whether production Cloudflare decodes paths the way `wrangler pages dev` does. It does not matter for
  safety any more (paid files are not at their public paths), but it is worth knowing.
- Plan §8: repository private, expert review, legal pages, cheat-sheet licences.
