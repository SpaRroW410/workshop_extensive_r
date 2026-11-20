# Launch plan: Cloudflare, user accounts, saved progress, paid access

Written 2026-11-15. Decisions taken: customers are **both institutions and individuals**, based in **India**; the repository is **public for now**; sign-in uses an **auth library on our own database**, not a paid hosted service.

## 1. Lessons from the Vercel launch, and how this plan avoids them

On Vercel every commit started a build that used the plan's quota, and the site was incomplete without the paid plan. Two rules prevent that here.

1. **Cloudflare never builds the site.** Quarto renders on your machine or in a session, as today. The finished `docs/` folder is uploaded with `wrangler pages deploy docs` (a direct upload). No Git connection, so a commit does not deploy anything and uses no build quota.
2. **Deploys are deliberate.** One command, or one manually started GitHub Action, publishes a release. Work in progress stays off the live site.

## 2. Free-plan limits (checked on Cloudflare's documentation, 2026-11-15)

| Limit | Free plan | Where we stand |
|---|---|---|
| Files per Pages site | 20,000 | 3,421 |
| Largest single file | 25 MiB | no file above 25 MB in `docs/` |
| Requests for static files | free and unlimited | all free-tier pages |
| Requests that run a Function (gate, API) | 100,000 per day, shared with Workers; resets at midnight UTC | each paid page view and each save counts as one |
| D1 rows read / written | 5 million / 100,000 per day | ample at launch |
| D1 storage | 5 GB | ample |
| Git-triggered builds | 500 per month | not used (direct upload) |

When the D1 daily limit is exceeded, queries fail until the reset. Cloudflare's page does not say what happens when the 100,000 Function requests are used up; **find this out before launch**, because the gate runs as a Function. Design consequence: free pages must never pass through the gate, so they keep working whatever happens to the quota.

Not checked: whether direct uploads count toward the 500 builds, and current prices of the paid plan.

## 3. Architecture

| Piece | Service | Job |
|---|---|---|
| Site | Cloudflare Pages, direct upload | serves `docs/` |
| Gate | Pages Functions middleware, on paid paths only | checks the session before serving a paid page |
| API | Pages Functions | `/api/me`, `/api/progress`, `/api/visit`, payment webhook |
| Database | D1 | users, sessions, entitlements, progress, visits |

## 4. Accounts

- **Sign-in with Google first.** It needs no email-sending service and no passwords. Email magic links are added later, when an email provider is chosen.
- **An established open-source auth library** running on Functions with D1. No per-user fee and no second vendor whose plan can cut the site off.
- Tables: `users`, `sessions`, `entitlements` (user, product, expires), `progress` (user, key, JSON, updated), `visits` (user, last page, last seen); later `orgs`, `cohorts`, `seat_codes`.

## 5. Locked and unlocked

- **Server side:** the middleware maps a path prefix to a product and serves the page only to a user who holds it. This replaces the plain-text keys in `config.json`, which anyone can read today.
- **Browser side:** `/api/me` returns the user's products; cards and menus show lock badges.
- **Free:** the basic profile, game Region 1, Session 1 and the cheat sheet of every workshop.
- **Paid products (proposal):** `moderate`, `regression`, `gis`, `advanced` (all nine modules), `game-full`, and an `all-access` bundle.

## 6. Saved progress and last visit

- **Game:** `quest.js` keeps one state object in the browser. On sign-in, merge the local and the server copy (keep the better result per item), then save on each change.
- **Workshop quizzes:** the per-deck score goes to the same endpoint; the welcome page shows decks done and scores.
- **Last visit:** one call per page load; the welcome page offers "Continue where you left off".
- Works signed-out exactly as today (browser only), so the free tier needs no account.

## 7. Payments (India)

- **Individuals:** Razorpay (UPI, cards, net banking, INR). A webhook writes the entitlement row. One-time purchase per product is simpler than subscriptions for a first launch.
- **Institutions:** invoice and bank transfer; you issue **seat codes** that staff and students redeem after signing in. A facilitator sees the cohort's progress.
- **To settle with an accountant before taking money:** GST registration and invoicing, and whether sales outside India are wanted (that needs a second provider).
- Razorpay's current fees and onboarding requirements were not checked.

## 8. Must be done before charging

1. **The repository must go private, or paid content must leave it.** While it is public, every paid page is free on GitHub. Planned for the end of Phase 0: once the site is served by Cloudflare, switch the repository to private and turn GitHub Pages off.
2. **Expert review** of the statistical content of A1 to A9.
3. **Answers are checked in the browser.** A four-option question can be solved by trying four values. Certificates need server-side checking.
4. **Facilitator solutions stay out of the deployed site** (they are not in `docs/` today); add a CI check.
5. **Legal pages:** terms, privacy policy, refund policy; India's data-protection law applies to the accounts.
6. **Third-party material:** the cheat-sheet PDFs in `downloads/` need a licence check. All datasets are synthetic.

## 9. Phases

| Phase | Deliverable | Proof it works | Needs from you |
|---|---|---|---|
| 0 | Cloudflare Pages project, direct-upload deploy script, custom domain; repo private | site loads from Cloudflare; a commit alone changes nothing live | Cloudflare account, domain, API token |
| 1 | Google sign-in, D1 schema, `/api/me` | same account on two devices | Google OAuth client |
| 2 | Gate on paid paths, lock badges, `config.json` keys removed | signed-out request to a paid URL is refused; free pages work with Functions disabled | product list and free tier confirmed |
| 3 | Progress sync, last visit, dashboard | solve an item on one device, see it on another | |
| 4 | Razorpay checkout, webhook, entitlements | test payment unlocks; refund locks | Razorpay account, prices, legal pages |
| 5 | Seat codes, cohorts, facilitator dashboard, certificates | a facilitator sees their group | |

Phases 0 to 3 cost nothing on the free plans and take no payment, so the site is complete and usable at each step.
