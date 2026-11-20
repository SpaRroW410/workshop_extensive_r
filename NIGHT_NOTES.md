# Night notes — launch plan, phases 0 to 3 (2026-11-19)

## ❓ Questions for you (nothing is waiting on them; I carried on)

**Q1. Moderate and the two Data Viz tracks sell nothing that Basic does not already give away.**
Every shared page (iteration, best practices, ggplot modules 1–4, all plot galleries, gtsummary…) is rendered
into *every* track site, including the free `basic/` one; the navbar only hides them. I checked: `moderate/`,
`dataviz-base/` and `dataviz-complete/` contain **no page** that `basic/` lacks. Gating `/moderate/` therefore
stops nobody who types `/basic/…`. Options:
- **(a) recommended:** render into each track only the pages in its own menu (a change to `_quarto.yml` /
  `curriculum.yml` and a full re-render). Then Basic holds only Basic pages and Moderate has something to sell.
- (b) make Moderate and Data Viz free and sell only Regression, GIS, Advanced and the full game.
- (c) leave it; accept that Moderate is a convenience, not a lock.

**Q2. Confirm the free tier and product list** (plan, phase 2 "needs from you"). What I built is the plan's
proposal plus D8–D10 below: every track's home page free, Session 1 = slides + lab 1 + cheat sheet + data,
Data Viz Foundations → `moderate`, Data Viz Complete → `advanced`. All of it lives in `cloud/src/products.js`.

## ✅ Finished (all committed and pushed to `claude/eager-newton-ai0u3z`, CI green on every push)

| Phase | What works | Proof |
|---|---|---|
| 0 Deploy | `cloud/stage.mjs` + `cloud/deploy.sh` (direct upload, never on push), manual GitHub Action, CI check that facilitator solutions stay out | unit tests; real site served by local Cloudflare, no 404s |
| 1 Sign-in | Google sign-in (Better Auth on D1), `/api/me`, `grant.mjs` to give products by hand | Google redirect, forged callback/cookie refused, sign-out, grants |
| 2 Gate | Paid pages only for holders; `/account` explains what to do; landing page lock badges from `/api/me`; keys kept on GitHub Pages | 16 path tricks, signed-out refusal, browser test on the real site 10/10 |
| 3 Sync | Game, quiz scores and study-plan ticks follow the account; last visit → "Continue where you left off"; quiz results per workshop on the profile card | the plan's proof (item on one device, seen on another), reset, shared computer: 10/10 |

Tests: `cd cloud && npm test` → **41 pass**. Browser: `site.e2e` 10/10, `sync.e2e` 10/10. Repo checks (profiles,
quiz assets, quiz lint, labs, item bank) pass; `quiz_all.js` passes on all 56 decks; the game's `quest_e2e.js` 115/115.

## ⚠️ What broke, or is not done

- **Found and fixed: a way round the gate.** Locally, Cloudflare picks "run the gate or not" on the *raw* path,
  but serves files from the *decoded* path, so `/%72egression/…` opened paid pages with no sign-in. Fixed by
  moving paid files out of their public paths at deploy time (D13). Production may differ; the fix holds either way.
- **Found and fixed: Quarto copied 26 files from `cloud/.deploy` into `docs/cloud/`** (one commit, removed in
  the next; no keys or secrets). `_quarto.yml` now excludes `cloud/` — so the next `render-all-profiles.sh`
  re-renders everything (it needs the full R package set).
- **Not tested against real Cloudflare or real Google** — that needs your accounts (start below).
- **Unknown, as the plan says:** what Cloudflare does when the 100,000 daily Function requests run out.
- **Phases 4 (Razorpay) and 5 (seat codes, cohorts) not started**: they need your Razorpay account, prices and legal pages.
- **The repository is still public**, so paid pages can be read on GitHub (plan §8.1). Your decision, after the switch.
- Nothing is parked on a broken branch: everything that was built works and is committed.

## ☕ Start here (about 15 minutes)

1. Answer **Q1** (one line is enough: a, b or c).
2. Skim `cloud/README.md` — one page: what each file does, and the 7 steps to go live.
3. If you want to see it running: steps 1–6 of "Going live" in `cloud/README.md` put it on a **preview**
   address (`bash cloud/deploy.sh --preview`); the live GitHub Pages site is not touched.

## Decisions taken, and why

| # | Decision | Why |
|---|---|---|
| D1 | "The plan" = `LAUNCH_PLAN.md` (branch `launch-plan`), merged into `claude/eager-newton-ai0u3z`. | It is the only plan with phases; it builds on the profile card from the last session. |
| D2 | Phases 0 to 3 tonight, only the parts that need no account of yours. | The plan says phases 0 to 3 cost nothing and take no payment. Cloudflare, Google and Razorpay accounts, the domain, and making the repository private are yours to do. |
| D3 | All Cloudflare code lives in `cloud/` with its own `package.json`. | Keeps the Quarto project at the root untouched; one folder to read. |
| D4 | Pinned the newest releases that are at least two weeks old (wrangler 4.157.0, better-auth 1.7.17). | Releases from the last few days are the ones most likely to be pulled or patched. |
| D5 | Better Auth is the auth library. | Plan §4 asks for an established open-source library on our own database. Better Auth runs on Workers and talks to D1 directly (no extra adapter), and is where Auth.js development moved. |
| D6 | Free and paid paths are written once, in `cloud/src/products.js`, in Cloudflare's own `_routes.json` syntax. | The gate and Cloudflare must agree on what is free; one list means they cannot drift. |
| D7 | Only a trailing `*` in rules. | Cloudflare documents nothing else. Pages redirects `page.html` to `/page`, so page rules are written `page*` to cover both. |
| D8 | Every paid track's home page (`welcome`) and its CSS/JS (`site_libs`, `assets`) are free. | The plan's free list does not mention them, but without them a locked visitor sees nothing of what they would buy, and every paid page view would cost ~20 Function calls (one per stylesheet). |
| D9 | "Session 1 is free" includes Session 1's lab file and the synthetic datasets. | The free slides point to the lab; the lab needs the data. The data is synthetic. |
| D10 | Data Viz Foundations → `moderate`, Data Viz Complete → `advanced`. | They are not in the plan's product list; this matches what they contain. See Q1. |
| D11 | `_routes.json` uses 99 of 100 rules; `make_gis_data.R`, the game's roadmap and site-design pages are free but run the Function. | Cloudflare's 100-rule limit. A test fails if a change goes over. |
| D12 | The workshop keys are removed from `config.json` only in the copy uploaded to Cloudflare. | GitHub Pages still serves `docs/` with keys until you switch. Removing them from `docs/` now would lock everyone out of the live site. |
| D13 | Paid files are moved, at staging, out of their public paths into `/_p/<128 random bits>/`, new each deploy. The gate fetches them from there after checking the user. | Found tonight: locally, Cloudflare matches `_routes.json` against the **raw** path while its file server **decodes** it. `/%72egression/…`, `/basic%2F..%2Fregression/…` and similar served paid pages with no gate at all. Whether production behaves the same is unknown, so I assumed it does. With the files gone from their public paths, those tricks find nothing; 16 of them are now tests. The plan's design (gate on paid paths only, free pages static) is unchanged. |
| D14 | Signed-out visitors to a paid page go to `/account`, which offers Google sign-in, or (signed in) says which product to ask the organiser for. | The plan says "refused"; a page that explains why and what to do beats a bare 401 for a learner. Non-page requests (files, `search.json`) do get a plain 401/403. |
| D15 | The landing page switches to the account service only when the published `config.json` says `gate: "server"` (added at staging). | GitHub Pages never calls `/api/me` and keeps working with keys exactly as today; tested in a browser. |
| D16 | Test-only email + password sign-in. | Real Google sign-in cannot be completed without your Google client. Test login is on only when `AUTH_TEST_MODE=1` **and** the site runs on localhost; a test proves it stays off on a real address. |
| D17 | Excluded `cloud/` from Quarto resources (`_quarto.yml`). | A bare `config.json` resource pattern copied 26 harmless files from the staging folder into `docs/cloud/` (committed once, removed in the next commit; no keys or secrets in them). Side effect: the next `render-all-profiles.sh` re-renders every profile in full. |
| D18 | Progress sync lives in one script, `ws-sync.js`, added to every page at staging. It watches the localStorage keys the pages already write. | No change to how the game, quizzes or plan pages save; GitHub Pages never gets the script. |
| D19 | It syncs only when signed in (a flag set by `/account` and the landing page). | Signed-out visitors cost no Function requests, keeping the plan's rule that free pages work whatever happens to the quota. |
| D20 | Merge rules: game = better result per item; quiz answers = union; study-plan ticks = newest copy wins. | The plan says "keep the better result per item" for the game. Ticks can be undone, so a union would make un-ticking impossible. |
| D21 | A Reset leaves a timestamped marker on the server; copies changed before it are not merged back. | Found by the sync test: without it, a reset on the phone was undone by the laptop's old copy. |
| D22 | Signing out clears that browser's synced progress (after saving anything pending). A different account signing in on the same browser never receives the previous person's progress. | Workshops run on shared lab computers. Progress made before ever signing in is merged into the account on first sign-in, as the plan says. |
| D23 | Quiz scores are now stored per workshop folder and deck (`quiz-score:survey-workshop/s5_…`); the old key is read once for the deck's own questions. The 56 rendered decks were patched with the new engine text instead of re-rendered. | Deck names repeat across workshops. A real render re-runs R (missing packages here) and would change every deck; the engine is inlined verbatim, so a text replacement equals what a render produces. `quiz_all.js` passes on all 56. |
| D24 | After a sync brings newer progress, the page reloads once (per page, per tab session). | Simpler and safer than teaching every page to redraw itself. |
