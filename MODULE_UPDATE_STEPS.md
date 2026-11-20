# Module update: step-by-step, before the Cloudflare launch

Written 2026-11-20 from a fresh inventory of `main` (`MODULE_INVENTORY.md`, regenerate with
`python3 scripts/module_inventory.py > MODULE_INVENTORY.md`). This turns `MODULES_PLAN.md` (phases U0–U7) into a
work list where every page has its own line, so nothing is missed. Tick a box only when its **check** passes.

## 0. What the inventory found

| # | Finding | Size | Where |
|---|---|---|---|
| F1 | **The 18 plot-gallery decks are not published in any track.** The gallery pages link to `basic/0_foundation.qmd` etc., which are never rendered: every gallery link is dead (the earlier link check only looked at `.html` links) | 18 decks, 86 links | `plot-gallery/{basic,moderate,advanced}/` |
| F2 | **Three pages are outlines only** (bullet lists, no code, no plots) but sit in paid menus | 3 pages | `specialized/merge_visuals`, `plot_stats`, `interactive` |
| F3 | **Code shown, never run**: readers see code but no plot or table | 11 pages | `ggstatsplot_intro`, `_moderate`, `_advanced`; `quarto_moderate`; `practical_application`; advanced gallery 3.2–3.7 |
| F4 | **No base module has a quiz, a lab or a cheat sheet** (the workshops all do) | 41 menu pages + 18 gallery decks | every track except the workshops |
| F5 | **Four datasets have no generator script; origin unknown** | `PublicHealth_BP_Dataset.xlsx` (21 pages), `Healthcare_Network_Dataset.xlsx` (2), `prac_modded.xlsx` (1), `health_dataset_dm.xlsx` (unused) | `data/` |
| F6 | **Headers inconsistent**: most base pages have no author and no date; a few still say "Sparrow"; module 4 is dated `today` | ~35 pages | base modules |
| F7 | **Figures have no alt text** (2 uses of `fig-alt` in the whole site) | all pages with plots | everywhere |
| F8 | **No record of package versions**, so "the lab runs on a fresh machine" cannot be checked (no `renv.lock`) | whole repo | |
| F9 | **Third-party PDFs** in `downloads/cheatsheets/` (10 files): licence and attribution not recorded | 10 files | `downloads/` |
| F10 | Open from U0: overlapping downloads lists (item 11), `ggmosaic` in module 4 (item 12), two regression slides overflow (item 7) | 3 items | |
| F11 | **No workshop has been reviewed by a subject expert** (11 workshops, 283 quiz questions) | 11 | `*-workshop/` |
| F12 | Game Region 4 (10 worlds) is "soon"; Regions 1–3 point their "Read first" links at base pages that will change in U1/U2 | 10 worlds | `dungeons/` |

Everything else checked out: all 141 listed pages exist, every rendered page is newer than its source, all 11
workshops have 5–6 decks, labs, solutions, a cheat sheet, a README and a data script.

## 1. The standard every unit must meet ("definition of done")

A **unit** is one session: a workshop deck, or one base-module session (one or more existing pages grouped together, §3).

| | Check | How it is checked |
|---|---|---|
| D1 | Content complete: no outline-only page, every plot and table shown | inventory shows no `stub` / `no-output` flag |
| D2 | Header: title, both authors, fixed date of last content change | inventory "Author" = yes, date not `today` |
| D3 | Quiz: 3–5 questions (base) or 4–6 (workshop), ids unique across the site | `lint_quizzes.R` 0 hard failures; `quiz_all.js` passes |
| D4 | Lab: one script with 3–6 blanks + facilitator solution, from the unit's dataset | `run_solutions.R` runs; `build_labs.R` leaves no diff |
| D5 | Data: synthetic or of documented origin, built by a script or documented in `data/README.md` | inventory shows no `ext-data` |
| D6 | Figures have alt text | `grep fig-alt` count = plots in the unit |
| D7 | Listed: `curriculum.yml`, the track home's study plan, `cloud/src/products.js` (free or paid) | `build_profiles.R --check`; `cloud` tests |
| D8 | Linked both ways with its game world (if one exists) | world's "Read first" points here; page links to the world |
| D9 | Rendered in its track, no dead links (including `.qmd` links), no slide overflow | link check (§6, step V3); `overflow.js` |
| D10 | Workshop units only: reviewed by a subject expert (MODULES_PLAN §5 checklist), version and reviewer on the workshop home | README "Reviewed by" line |

## 2. Order of work

| Step | Phase | What | Blocks |
|---|---|---|---|
| 1 | **U0-fix** | §4: dead gallery links, stubs, unrun code, headers, data origin, tooling | everything; the live site is broken without it |
| 2 | **U1** | Basic track, 6 units (§3.1) | free launch (Basic is the shop window) |
| 3 | **U2** | Moderate track, 6 units (§3.2) | charging for Moderate |
| 4 | **U7** | Data Viz electives (§3.3), after your decision | charging for them |
| 5 | **U-GIS / U-ADV** | GIS reading pages and the advanced-only base pages (§3.4, §3.5) | charging for GIS / Advanced |
| 6 | **U3** (in parallel from step 1) | expert review, one workshop at a time, Regression first (§3.6) | charging for that workshop |
| 7 | **U-GAME** | update "Read first" links of Regions 1–3 after U1/U2 (§3.7) | |
| 8 | **V** | final verification (§6) | launch |
| 9 | **Launch** | `LAUNCH_PLAN.md` section 0, steps 1–6 | |

Region 4 of the game (U5) and new content (U6) come **after** launch; they are not needed to go live.

## 3. Unit by unit

Each line is one unit. "Existing pages" stay; the unit adds what the standard lacks. The game world in brackets is
the one that already practises it.

### 3.1 U1 · Basic track (free) — 6 units

| Unit | Existing pages | To do | Dataset |
|---|---|---|---|
| B1 Your First Script (b1) | `r-foundations/getting-started` (deck) | header D2; quiz; lab 1 (read a CSV, look at it); alt text | `ncd_survey.csv` |
| B2 Tidy Data (b2) | `r-foundations/data-wrangling` (deck, 2,266 lines), `data_wrangling_prac_s` (practice) | split the deck into two parts (B2a select/filter/mutate; B2b group/summarise/factors/NA); quiz each; turn the practice slides into lab 2 + solution | `ncd_survey.csv` |
| B3 Joining Data (b3) | `r-foundations/merging_dataset` (84 lines) | **expand** (joins that lose or duplicate rows, `pivot_longer/wider`, as the world teaches); quiz; lab 3 | `ncd_round1/2.csv`, `villages.csv` |
| B4 First Plots (b4) | `data-visualization/ggplot_grammar` (hub), `plot-gallery/basic` (hub) + 5 gallery decks (1.1–1.4, 0) | after F1 fix: quiz on choosing a plot; lab 4 (histogram, boxplot, bar, scatter); alt text on gallery plots | `ncd_survey.csv` (replace F5 data) |
| B5 Which Test? (b5) | `statistical-analysis/statistical_tests`, `ggstatsplot/ggstatsplot_intro` | F3: run the ggstatsplot code; quiz; lab 5 | `ncd_survey.csv` |
| B6 Reporting basics | `statistical-analysis/regression` (bridge), `quarto_repro_w/reproducible_writing` | quiz; lab 6 (a short Quarto report); decide whether `regression.qmd` stays in Basic or moves to Regression | `ncd_survey.csv` |
| Track | — | **Basic cheat sheet**; track home study plan lists B1–B6 with quiz and lab; downloads per track (U0 item 11) | |

### 3.2 U2 · Moderate track (paid) — 6 units

| Unit | Existing pages | To do |
|---|---|---|
| M1 Messy Data (m1) | `r-foundations/cleaning_messy_data` | quiz; lab (on `ncd_messy.csv`); header |
| M2 Iteration (m2) | `r-foundations/iteration` | quiz; lab |
| M3 Explore by Picture (m3) | `data-visualization/best_practices`, `plot_data`, ggplot modules 1–2, `plot-gallery/moderate` + 6 gallery decks, `specialized/merge_visuals`, `specialized/plot_stats` | **write the two stub pages** (F2) or drop them from the menu; gallery decks published (F1); quiz per module; one lab |
| M4 Table 1 (m4) | `gtsummary/gtsummary_tutorial`, `ggstatsplot/ggstatsplot_moderate` | F3: run the ggstatsplot code; quiz; lab |
| M5 Tests in Context (m5) | `statistical-analysis/data_analysis` | replace `PublicHealth_BP_Dataset`/`Healthcare_Network` (F5); quiz; lab |
| M6 Reports and Export | `quarto_repro_w/quarto_moderate`, `exporting_tools/exporting_plots`, `plotting_tools` | F3: run the Quarto examples or show their output as images; quiz; lab |
| Track | — | Moderate cheat sheet; study plan; product rule for "Session 1 free" in Moderate (decide) |

### 3.3 U7 · Data Viz electives (decision needed: views only, or full treatment)

`dataviz-base` = the visualization part of Moderate (14 pages, no new units). `dataviz-complete` adds:

| Unit | Existing pages | To do if "full treatment" |
|---|---|---|
| V1 Colours, scales, themes | ggplot module 3 | header; quiz; lab |
| V2 Advanced practice | ggplot module 4 | **`ggmosaic` fix first** (U0 item 12); date `today` → fixed; quiz; lab |
| V3 Advanced gallery | `plot-gallery/advanced` + 7 decks (3.1–3.7) | F1 publish; **F3: all 6 decks show no output**; F5 data; quiz |
| V4 Interactive | `specialized/interactive` (stub), `plot-gallery/practical_application` (unrun) | write the page; run the code |
| V5 Exporting and debugging | `exporting_tools/debugging_plots`, `advanced_exporting` | quiz; lab |

Even "views only" needs F1, F2, F3 and F5 fixed: those pages are in the menus today.

### 3.4 U-GIS · GIS reading pages

| Unit | Existing pages | To do |
|---|---|---|
| G-ref | `gis/spatial_data_sf`, `maps_choropleth`, `spatial_weights`, `morans_i`, `local_moran_lisa`, `other_spatial_tests`, `spatial_regression` | headers; a 3-question quiz per page; link each page to the GIS workshop session that teaches it (they are the reference companion; no labs needed, the workshop has them) |

### 3.5 U-ADV · Base pages only in the Advanced track

| Page | To do |
|---|---|
| `ggstatsplot/ggstatsplot_advanced` | F3: run the code; header; quiz |
| `quarto_repro_w/quarto_advanced` | header; quiz; decide whether it belongs in Advanced or in a future Publication track |

### 3.6 U3 · Workshops (11) — review, not rewrite

For each, in this order: **Regression, Survival, Counts, Ordinal, Clustered, Survey, Curves, Missing, Prediction, Causal, GIS**.

1. Reviewer works through MODULES_PLAN §5 checklist (numbers match the solutions; methods current; quiz keys; labs from a fresh R session; cheat sheet consistent).
2. Fixes made; quiz lint and `run_solutions.R` re-run; facilitator answers re-checked against output.
3. Alt text added to the deck figures (F7).
4. `README.md` gets "Reviewed by …, date, version 1.0"; the version also on the workshop's landing card.
5. Regression only: the two overflowing slides (s1 slide 5, s5 slide 33).

### 3.7 U-GAME · Game links

1. After U1 and U2: every world's "Read first" points at the new unit pages (`dungeons/assets/worlds.js`).
2. Each unit page links to its world (D8).
3. `quest_e2e.js` (115 checks) and both bank linters pass.

## 4. U0-fix: do first (no new content)

| # | Item | Check |
|---|---|---|
| 1 | **F1** Render the 18 gallery decks in every track that lists their hub (add them to each profile's render list in `curriculum.yml`), so `.qmd` links become `.html` | link check finds 0 `.qmd` links in `docs/` |
| 2 | Add `.qmd`-link detection to the repository link check (and CI), so F1 cannot recur | CI fails on a `.qmd` href |
| 3 | **F5** Find out where the four `.xlsx` datasets come from. If not synthetic and licensed for teaching, write `make_data` scripts for synthetic replacements with the same columns, and switch the 24 pages | `data/README.md` lists every file's origin |
| 4 | Delete `health_dataset_dm.xlsx` (unused) once confirmed | inventory |
| 5 | **F6** One header block for all base pages: title, both authors, fixed date | inventory: no `—` in Author/Date |
| 6 | **F8** `renv.lock` (or a package list with versions per track) so labs can be checked on a fresh machine | a fresh R library installs and `run_solutions.R` passes in every workshop |
| 7 | **F9** Record licence and attribution for each PDF in `downloads/cheatsheets/`; remove any that cannot be redistributed | `downloads/cheatsheets/LICENSES.md` |
| 8 | MODULES_PLAN U0 items 7, 11, 12 (overflow, downloads lists, `ggmosaic`) | as listed there |
| 9 | Inventory script in CI: fail on a `stub` or `no-output` page in a menu once U1/U2/U7 are done | CI |

## 5. What each step needs from you

| Item | When |
|---|---|
| Origin of the four `.xlsx` datasets (F5): who made them, from what, may they be published? | U0-fix item 3, **first** |
| Base modules: add quiz + lab to existing pages (recommended) or rebuild as decks | before U1 |
| `regression.qmd` in Basic or in Regression | U1 unit B6 |
| Data Viz electives: views only or full treatment | before U7 |
| Is Session 1 of each Moderate unit free, like the workshops? | before U2 is listed in `products.js` |
| Reviewer(s) for U3, starting with Regression | now: it is the longest wait |
| Check each drafted unit (Claude drafts, you approve) | per unit |

## 6. Final verification before launch (V)

| Step | Check |
|---|---|
| V1 | `python3 scripts/module_inventory.py`: no `stub`, `no-output` or `ext-data` in any menu page; every header complete |
| V2 | `Rscript scripts/build_profiles.R --check`; `bash scripts/sync_workshop_assets.sh --check` |
| V3 | Full render of all eight tracks; link check over `docs/` finds no dead `.html` and no `.qmd` link |
| V4 | Quiz lint on every unit; `quiz_all.js` and `overflow.js` on every deck in every track |
| V5 | `run_solutions.R` and `build_labs.R` (no diff) for every workshop and every new base lab, from a fresh R library |
| V6 | Game: `quest_e2e.js`, `lint_bank.R`, `lint_bank.js --strict` |
| V7 | `cd cloud && npm test` and both browser suites; `products.js` lists every new unit as free or paid |
| V8 | Spot check on a phone: one deck, one lab download, one game world per track |
| V9 | `STATUS.md` updated; every workshop to be sold shows "Reviewed by" |

## 7. Rough size

| Phase | Units | Claude | You / reviewer |
|---|---|---|---|
| U0-fix | 9 items | 2–3 sessions | dataset origin, licences |
| U1 Basic | 6 units + cheat sheet | 1–2 weeks | approve each unit |
| U2 Moderate | 6 units + cheat sheet (2 stub pages to write) | ~2 weeks | approve each unit |
| U7 Data Viz | 5 units if full | ~1 week | decision |
| U-GIS, U-ADV | 7 + 2 pages | 2–3 days | |
| U3 Review | 11 workshops | fixes after each review | ~1 day per workshop for the reviewer |
| V | 9 checks | 1 session | phone spot check |
