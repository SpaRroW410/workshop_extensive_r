# Module update plan

Written 2026-11-20, alongside [`LAUNCH_PLAN.md`](LAUNCH_PLAN.md). Goal: every module meets one standard, in an order that
lets the site go live early (free) and start charging only for modules that are ready.

## 1. Where the modules stand

| Group | Modules | State | Main gap |
|---|---|---|---|
| **Workshops** | Regression; Statistical Analysis (added 2026-11-27); GIS; A1 Survival … A9 Causal | Each has 5–6 slide decks with quizzes, 5–6 fill-in labs with facilitator solutions, a cheat sheet and a synthetic dataset with a feature check. Quiz lint and labs-in-sync run in CI. | **No subject-expert review yet** (plan §8.2 says this comes before charging). Two regression slides overflow by 6–7 px. |
| **Base modules** | R Foundations (6 pages), Data Visualization (7), Plot Gallery (4), Specialized plots (3), Exporting (4), Statistics (3), ggstatsplot (3), gtsummary (1), Quarto (3) | Mixed: half are slide decks, half reading pages; 84 to 2,266 lines; **no quizzes, no labs, no cheat sheets**; authors written three ways; six decks dated `today`, so every render changes them. | Not at the workshop standard. Since 2026-11-20 each track renders only its own pages, so Basic and Moderate are now separate products and need to be worth their place. |
| **Game** | Regions 1–3 (16 worlds, 232 items), pre/post tests | Playable, linted, e2e tested (115 checks). | Region 4 (Advanced) and a GIS region not built: they wait for the workshop reviews. |
| **Site pages** | Landing, track homes, account, downloads, references, contact | Landing and track homes rebuilt; account system ready for Cloudflare. | `references.qmd` is an empty page; README describes the old Data Visualization site. |

## 2. The standard: when is a module "done"

The workshop pattern, slightly lighter for base modules.

| | Workshop session | Base module (new) |
|---|---|---|
| Teaching material | Slide deck | Slide deck **or** reading page (keep what exists) |
| Self-check | Quiz, 4–6 questions, `quiz.js` | **Quiz, 3–5 questions**, same engine (scores sync to the account) |
| Practice | Fill-in lab + facilitator solution | **Short lab** (one script, 3–6 blanks) + solution |
| Reference | Cheat sheet per workshop | One cheat sheet per **track** |
| Data | Synthetic, built by `make_data.R` | Reuse an existing synthetic dataset |
| Listed in | `curriculum.yml`, track home study plan, `products.js` free/paid | same |
| Checks | quiz lint, labs in sync, solutions run, e2e | same; plus the game world that practises it links back to it |

Header for every page: fixed date (last content change), authors "Dr. Mukul Maheshwari, Dr. Rudresh Negi".

## 3. Phases

| Phase | What | Size | Who | Needed before |
|---|---|---|---|---|
| **U0 · Consistency** | The small fixes in §4. No new content. | 1 session | Claude | going live (free) |
| **U1 · Basic track to standard** | 5 sessions matching game Region 1 (Your First Script, Tidy Tavern, Join Junction, First Plots, Which Test?): add a quiz and a short lab to each existing page; Basic cheat sheet. | 1–2 weeks | Claude drafts, you check | — (Basic is the free shop window: the better it is, the more people continue) |
| **U2 · Moderate track to standard** | 5–6 sessions matching Region 2 (Messy Data, Loop Labyrinth, Explore by Picture, Table 1 Forge, Tests in Context): same additions; split `data-wrangling.qmd` (2,266 lines) into two sessions. | 2 weeks | Claude drafts, you check | charging for Moderate |
| **U3 · Expert review of the workshops** | Regression, GIS, A1–A9: statistics checked by a subject expert with the checklist in §5; fixes; a version number per workshop. | 1 day per workshop for the reviewer | **an expert you choose** | charging for that workshop (LAUNCH_PLAN §8.2) |
| **U4 · Run and correct** | Run each workshop once with participants; fix what confused them. | per workshop | you | Region 4 world for it |
| **U5 · Game Region 4 + GIS region** | One world group per reviewed and run workshop; then a GIS region. | 1–2 weeks per module (SITE_PLAN estimate) | Claude | — |
| **U6 · New content** | From SITE_PLAN: ANOVA vs regression page, citation page (all levels), Publication profile, A10 Advanced survival, electives (power, diagnostic accuracy, ITS, meta-analysis …). | as chosen | Claude + reviewer | — |
| **U7 · Data Viz electives** | Decide: keep them as views of the visualization pages (no new content), or give them quizzes and a cheat sheet like U1/U2. | 1 week if done | Claude | charging for them |

## 4. U0: consistency fixes (before going live)

✅ = done 2026-11-20 (2: "Sparrow"; 4: researched and verified; 9: moved to `archive/`). Still open: 7, 11 and 12.

1. ✅ Six decks dated `today` → fixed dates (renders stop changing them): ggplot modules 1–4, data wrangling, practice slides. **Done 2026-11-20 for five; module 4 left as is** (see item 12).
2. ✅ Authors written "Sparrow", "SpaRroW", "Data Visualization Workshop" → the two authors' names everywhere.
3. ✅ `data-visualization/plot_data.qmd` loads `custom-theme.css`, which does not exist (a 404 on every view).
4. ✅ `references.qmd` is an empty page (in every track's menu): fill it (R and package citations, the textbooks the workshops lean on) or take it out of the menus. *Needs your list of references.*
5. ✅ Contact page: the email is shown as `*[ryan00700@gmail.com]*`; make it a link and match the landing page footer.
6. ✅ Empty "Applied Examples" menus in the two Data Viz tracks (`curriculum.yml`) are dropped silently; remove them or fill them.
7. Two regression slides overflow (s1 slide 5, s5 slide 33).
8. ✅ `navigation.json` / `navigation.yml` are only copied into the site, never used (superseded by `curriculum.yml`): delete.
9. ✅ Pages no longer rendered by any track (they were orphans before): `gtsummary_teaching_slides`, `quarto_teaching_slides`, `data_analysis_slides`, `data_wrang_tasks`. Either put them in a menu or move them to `archive/`.
10. ✅ README.md: rewrite for the current site (tracks, workshops, game, cloud/), not the old Data Visualization site.
11. `downloads.qmd` and the track homes list overlapping files; make the Downloads page list per track, generated from the same lists.
12. **ggplot module 4 cannot be re-run on a fresh machine:** it loads `ggmosaic`, which CRAN removed and whose last CRAN release no longer
    loads with current ggplot2. Its frozen results still render. Either install `ggmosaic` from GitHub yourself
    (`remotes::install_github("haleyjeppson/ggmosaic")`, as the deck says) or rewrite its two mosaic plots with base
    `mosaicplot()` / `productplots`. Until then, do not change that file (any edit forces a re-run).

## 5. Review checklist for U3 (one per workshop)

- Every number in the slides matches the output of the lab solution on the published dataset.
- Methods and interpretation correct and current (e.g. reporting guidelines named: STROBE, TRIPOD, RECORD).
- Quiz answers correct and explanations right; no question answerable two ways.
- Labs run clean from a fresh R session with the listed packages and versions.
- Cheat sheet consistent with the slides.
- Reviewer's name, date and the workshop version on the workshop home page.

## 6. How this fits the launch

| Launch step (LAUNCH_PLAN) | Modules needed |
|---|---|
| Go live **free** on Cloudflare (phases 0–3; sign-in, sync, gate with manual grants) | U0 |
| Workshops with **manual grants** (organisers give access to participants, no payment) | U0; the workshop run as today |
| **Charging** for a product (phase 4, Razorpay) | U3 done for every workshop in that product; U2 for Moderate; U7 for the Data Viz electives |

## 7. Decisions needed

1. **Base modules:** add quiz + lab to the existing pages (recommended, keeps what works), or rebuild them as slide-deck sessions like the workshops?
2. **Reviewer** for U3, and which workshop first (Regression, as the most used, is the natural start).
3. **Data Viz electives** (U7): views only, or full treatment?

Decided 2026-11-20: next phase starts **from Basic** (U1).
