# Night notes — module update (MODULE_UPDATE_STEPS.md), 2026-11-20 → 21

Branch: `module-update-plan`. Your answers this evening: datasets simulated and publishable; base modules get a
quiz + lab on the existing pages, questions must not leak answers; Data Viz electives get the full treatment;
reviewer later.

## ☕ Morning summary (start here)

**Finished and pushed** (branch `module-update-plan`, every step rendered and tested before its commit):

- **U2 Moderate track**: 53 quiz questions on 15 pages, 6 labs (`labs/moderate/`), a Moderate cheat sheet, the two
  stub pages written, unit M1 set as the free taster (N16).
- **U7 Data Viz electives, full treatment**: 23 questions on 7 pages, 4 labs (`labs/dataviz/`), the six advanced
  gallery decks now run on real data, the Interactive page written, `ggmosaic` replaced.
- **Slide overflow** fixed on 16 decks. **U-GIS** (7 pages) and **U-ADV** (2 pages) quizzes; `ggstatsplot_advanced` runs.
- **U-GAME**: each unit page now links to its game world (the worlds already linked back).
- **F7 alt text**: 199 figures got alt text, generated from each chunk's code (chart type, variables, title).
- **F8**: `PACKAGES.md`, every package the site uses with its version, per track.

**Broken / not done**: nothing is left broken. Not done: U3 (the 11 workshops: they need your reviewer), the
and the final verification V1–V9 as one pass.

**Where to start (15 minutes)**: open the Moderate home and click through M1 → M2 (a quiz and a lab each), then
`plot-gallery/advanced/3.4` (the dengue forecasts). Then read decisions **N16** (M1 free) and **N29** (generated
alt text) below: those are the two calls you may want to change.

## ❓ Questions for you
(none: nothing needed stopping)

## Decisions taken, and why

| # | Decision | Why |
|---|---|---|
| N1 | `Tidyverse_Cheat_Sheet.pdf` removed from the repo, the site and `downloads.qmd` | It is DataCamp's and shows no licence; the nine Posit sheets show CC BY-SA and stay, with attribution (`downloads/cheatsheets/LICENSES.md`) |
| N2 | The four `.xlsx` datasets are documented as simulated in `data/README.md` instead of getting generator scripts | Your answer: simulated, publishable. A generator would change every gallery plot for no gain |
| N3 | Sub-decks linked from a menu page are rendered in the same tracks as that page (`build_profiles.R`) | Fixes F1 (18 gallery decks rendered nowhere) without listing 18 decks by hand in 6 menus |
| N4 | New `scripts/check_links.py` fails on any `.qmd` link and on missing files; include fragments (`*-include.html`) are skipped | The old check missed F1; fragments are not pages |

| N5 | `ggmosaic` replaced: two-way mosaic with `productplots`, three-way with plain `geom_rect` | `ggmosaic` is off CRAN and its last version fails with ggplot2 4.0.4 ("unused arguments"); GitHub installs are blocked here. `productplots` cannot rename its axes, so the three-way plot is drawn as rectangles (10 lines, no extra package) |
| N6 | Seven gallery "OBSERVATION / INTERPRETATION" blocks rewritten from the data | Six of the seven stated things the plots do not show (e.g. a BP "rebound" that does not exist; a positive age–BP correlation that is r = −0.09; ">70% non-smokers" that is 60%) |
| N7 | Gallery decks render one track at a time (full profile), never several files in one `quarto render a.qmd b.qmd` call | Quarto 1.11 then looks for the second file in the wrong folder ("withBinaryFile: does not exist"); a full profile render works |
| N8 | Quiz engine on base pages is written in by an `asis` chunk (`assets/quiz-engine.R`), not `include-after-body` | A page-level include-after-body may replace the site-wide one in `_quarto.yml`, which fixes the navbar brand link |
| N9 | Link checker skips the navbar brand link | Its href is fixed in the browser by the site-wide script; on disk it is always wrong on nested pages (100 false alarms) |
| N10 | Base-module labs live in `labs/<track>/` (solutions in `labs/<track>/solutions/`), built by `scripts/build_base_labs.R` | Same `#@` / `#%` markers as the workshops; one place per track |
| N11 | Gallery slide overflow (155 slides in 15 decks) is fixed in the unit steps (B4, M3, V3), not in F1 | The decks were never rendered before; F1's job was to publish them and make them correct |
| N13 | `data-wrangling.qmd` (2,266 lines) is **not** split into two decks; it gets one quiz at the end covering both halves | Splitting changes every link to it (game, track homes, other tracks) and its frozen results, for little gain; the plan's split is noted as a later option |
| N14 | Long slides that still overflow after `.smaller` become `.scrollable` (marked automatically by `scripts/fix_overflow.py`); the shared `tests/overflow.js` lists them as SCROLL, not as failures | Content stays reachable; rewriting 150+ code slides by hand is not worth it. Workshop decks keep their own stricter test |
| N15 | Base-page quizzes load `quiz.R` in a separate `include: false` chunk | The quiz linter runs every chunk that contains questions from the repository root, where `../assets/quiz.R` does not exist |
| N16 | Moderate: unit M1 (Cleaning Messy Data + its lab, data and the track cheat sheet) is free; M2–M6 are paid | Mirrors "Session 1 free" of the workshops (plan §5 open question). The four rules go in `FREE_VIA_FUNCTION`, because `_routes.json` is near Cloudflare's 100-rule limit. Easy to undo: delete 4 lines in `cloud/src/products.js` |
| N17 | One Moderate lab per unit (6), not per page; the M3 lab serves the 7 visualization pages | D4 asks for one lab per unit; seven plotting labs would repeat each other |
| N18 | `data_analysis` keeps `prac_modded.xlsx` (F5 said "replace") | You confirmed the xlsx files are simulated and publishable, so replacing them is no longer needed; origin is in `data/README.md` |
| N19 | `scripts/add_unit_quiz.py` adds the lab link + quiz from a JSON spec | Same layout on every page, and idempotent; specs are kept in `scripts/quiz_specs/` (first drafts; the pages hold the final, lint-balanced wording) |
| N20 | Advanced gallery 3.4 (time series) uses the monthly dengue series, not the BP trial | The trial has 3 visits: STL, ARIMA, Prophet and change points need many equally spaced points. 3.5 uses the provider network, 3.6 the GIS blocks |
| N21 | 3.6: isochrones replaced by straight-line distance bands; kriging by IDW | Isochrones need a routing server (network at render time); kriging stays in the GIS track. Both are named on the slide |
| N22 | 3.7 and practical_application: flexdashboard/Quarto/Shiny templates shown as `markdown` / `r` display blocks, not `eval: false` R chunks | They are documents and apps, not code that can run inside a slide; the plotly and publication-figure examples do run |
| N23 | `plot_data` deck: every content slide gets `.smaller .scrollable` | 31 of its slides overflow and their headings contain colour spans the fix script cannot match; deck-level `scrollable:` is not honoured by Quarto |
| N24 | Workshop quiz ids such as `s1q1` repeat across workshops: left as is | Scores are saved per deck, so they do not collide; renaming belongs to U3 (workshops). New base-module ids are unique |
| N25 | `quarto_advanced` stays in the Advanced track | The plan asked to decide Advanced vs a future Publication track; nothing else would go in that track yet, so moving it now would leave an empty track. Easy to move later |
| N26 | `ggstatsplot_advanced` runs on the simulated BP trial; its Bayes-factor wording uses the real numbers (BF₁₀ ≈ 10⁵ at 6 months, 0.19 at baseline) | The page referred to `overall_up`, a dataset that is not in the repo, and quoted invented BFs |
| N27 | GIS reading pages get no lab; each links to the GIS workshop session that teaches it | As the plan says: the workshop has the labs |
| N28 | Game: worlds' "Read first" links already point at the unit pages (paths unchanged), so only the other direction (D8) was added: each unit page's lab paragraph links to its world | `scripts/add_game_links.py`; the link climbs to the site root, so it works from every track |
| N29 | Alt text (F7) generated from code by `scripts/add_alt_text.py`: it names the chart type, variables and title, never the finding | 207 figures; writing each from the image would take days. Describing structure cannot misstate a result. Worth a human pass on the key figures; workshop decks are left for U3 |
| N30 | F8 as a versioned package list (`PACKAGES.md`, `scripts/package_versions.R`), not `renv.lock` | renv is not installed here and a lockfile written from this container would pin its odd mix (R 4.3.3, a 2025 snapshot for ggstatsplot). The list gives the same information and can seed `renv::snapshot()` on your machine |
| N31 | Caveat flash cards (`data-visualization/caveats.qmd`, 70 cards from `caveats.yml`) follow the topic list of data-to-viz.com, in our own words with links back | The cards themselves are in github.com/holtzy/dataviz-caveat-flashcards under CC BY-NC 4.0 (non-commercial), so they cannot go into paid tracks; no text or image is copied; each card links to its data-to-viz page and to the course page that teaches it |
| N32 | Showcase (`plot-gallery/showcase.qmd`) builds 7 inspiration-style figures from our own datasets, plus the final-output brief | dataviz-inspiration.com loads by JavaScript and shows other authors' images; we link to it for ideas instead of copying. Every title was checked against the data (two drafts were wrong and were changed) |
| N12 | R 4.3.3 (Ubuntu) cannot install `ggstatsplot` 1.1.4 (needs R ≥ 4.5): 0.13.0 from a dated snapshot is used | No newer R is available from the system packages here |

## Progress

| Step | State | Checks |
|---|---|---|
| U0 F5 dataset origins, F9 licences | ✅ committed | `data/README.md`, `downloads/cheatsheets/LICENSES.md` |
| U0 F1 gallery published + correct | ✅ committed (`852193b`) | links 0 `.qmd` / 0 missing; 56 workshop decks quiz test pass; cloud 42/42 |
| U1 Basic track | ✅ committed (`2df4d14`) | 33 quiz questions lint clean, keys read; 8 pages pass the quiz test; labs run; overflow OK; game e2e pass |
| U1 left open | alt text on plots (D6) moves to one pass over all base pages (F7); game "Read first" links (U-GAME) | |
| U2 Moderate track | ✅ committed (`3c3bce6`, `a1e2cf7`) | 53 questions on 15 pages, lint clean, keys read; 15 pages pass quiz test; 6 labs run; cheat sheet; M1 free (N16); 6 tracks render; links 0/0; cloud 43/43 |
| U7 Data Viz electives (full) | ✅ committed (`80b7193`) | 23 questions on 7 pages; 4 labs run; advanced gallery 3.2–3.7 run on real data; interactive page written; ggmosaic replaced (U0 item 12) |
| Slide overflow, M3 + V decks | ✅ committed | 16 decks OK in overflow.js (only .scrollable slides left); 6 tracks render exit 0 |
| U-GIS (7 pages) + U-ADV (2 pages) | ✅ committed | 27 questions, lint 0 hard failures (1 wording warning), keys read; 9 pages pass quiz test; ggstatsplot_advanced runs |
| U-GAME D8 page → world links | ✅ committed | 12 unit pages; 7 tracks render exit 0; links 0/0; cloud 43/43; quest e2e and bank lint pass |
| F7 alt text (base pages) | ✅ committed | 199 figures on 32 pages (N29); 7 tracks render exit 0, no warnings; 39 quiz pages pass; links 0/0; cloud 43/43; quest e2e pass |
| F8 package list | ✅ committed | `PACKAGES.md`: 104 packages with versions per track (N30) |
| U0 item 9 + CI | ✅ committed | CI now also checks: base labs in sync, base-module quiz lint, dead/.qmd links, no stub/no-output menu page (`module_inventory.py --check`); all pass locally. Inventory: 0 flagged pages; documented datasets no longer flagged ext-data |
| Left for you | U3 workshops (needs the reviewer), V1–V9 as one final pass before launch | |
