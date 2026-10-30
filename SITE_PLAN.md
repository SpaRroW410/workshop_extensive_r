# Site plan: workshop profiles + Dungeons & Dataframes quest

**Status:** v4 · **Date:** 2026-10-16
**Part 1** restructures the workshop (one source, many profiles). **Part 2** builds the quest on top of it.

---

# Part 1 · Workshop architecture

## 1.1 Principle: write once, show at many levels

The site is **one set of `.qmd` topic pages**. Profiles do not copy pages. They **include the same page and show more of it the higher the level**. A histogram is taught **once**; Basic R, DataViz and Regression all point to that one page, or include that one snippet.

Two mechanisms do this (the second is already used in the repo):

| Mechanism | Use when | Example |
|---|---|---|
| **Level blocks inside a page** | Same topic, deeper at higher levels | `data_analysis.qmd`: descriptives for Moderate, extra models for Advanced |
| **Shared partials** (`_partials/*.qmd` + `{{< include >}}`) | The same small piece is needed on several different pages | `_partials/histogram.qmd` included in getting-started, the plot gallery and the regression diagnostics page |

### Fix: make level blocks cumulative

Today, pages use `when-profile="moderate"`. That is an **exact** match, so Moderate content disappears in Advanced unless it is tagged again; e.g. `data_analysis.qmd` repeats blocks for each profile. Instead, each profile sets **cumulative level flags**:

```yaml
# _quarto-moderate.yml
metadata:
  lvl-basic: true
  lvl-moderate: true
```

```markdown
::: {.content-visible when-meta="lvl-moderate"}
Shown in Moderate, Regression and Advanced, written once.
:::
```

| Profile | lvl-basic | lvl-moderate | lvl-regression | lvl-advanced |
|---|---|---|---|---|
| basic | ✔ | | | |
| moderate | ✔ | ✔ | | |
| regression | ✔ | ✔ | ✔ | |
| advanced | ✔ | ✔ | ✔ | ✔ |

Separate ladders (DataViz, Publication, Contributing) get their own flags (`viz-base`, `viz-complete`, `pub`, …). `when-profile` stays only for content that truly belongs to one profile.

*To verify in Phase 0:* `when-meta` behaves as expected with profile metadata on Quarto 1.10.

## 1.2 Profile structure

### Main ladder (gated in the quest)

```
Basic ──► Moderate ──► Regression ──► Advanced
                                        ├── Advanced Analysis   (post-regression stats: survival, counts, …; Part 2 §2.7)
                                        ├── Advanced Visualization (draws on the DataViz pages)
                                        ├── Documentation        (draws on the Publication pages)
                                        └── Programming for Analysis (functions, iteration, pipelines)
```

### Separate ladders (independent, never gated)

| Ladder | Profiles | Content |
|---|---|---|
| **DataViz** | `dataviz-base` → `dataviz-complete` | Grammar of graphics, gallery, colour/themes, interactive, exporting |
| **Publication-quality output** *(new)* | `publication` | gtsummary, flextable, gt, Quarto (docs, slides, manuscripts), bookdown, citation (full workflow), journal templates, exporting tables/figures |
| **Contributing** *(new)* | `contributing` | How to add a page, level blocks and partials, style guide, data scripts, lint/tests, quest item authoring, Git/GitHub workflow |

Advanced branches **reuse** pages from the separate ladders, so nothing is written twice. The Advanced → Documentation menu links the same `gtsummary/…` and `quarto_repro_w/…` pages that the Publication profile renders.

**Decision for Phase 0:** should Advanced be **one profile with four branch menus** (recommended: one build, less output on disk) or **four profiles** (`advanced-analysis`, …)?

## 1.3 Content changes

| Change | Where | Notes |
|---|---|---|
| **`data_analysis.qmd` levels** | Moderate (descriptives, tests, Table 1) → Advanced Analysis (multivariable, model comparison) | Rewrite with cumulative blocks; remove duplicated sections |
| **ANOVA vs regression** *(new page or section)* | Regression | t-test = `lm` with a binary predictor; ANOVA = `lm` with a factor; ANCOVA; same p-values side by side; when to report which |
| **Loops and iteration** *(new topic: `r-foundations/iteration.qmd`)* | Moderate: why code beats point-and-click; `for` loops over variables/files; `across()`; writing a small function. Advanced → Programming: `purrr::map`, many models at once (`nest` + `map` + `broom`), error handling (`possibly`), reusable analysis functions, parameterised Quarto reports | Medical examples: run the same test on 20 variables; univariable screening table; one report per district |
| **Histogram, boxplot, etc. as partials** | `_partials/` | Included in Basic R, DataViz, statistical tests and regression diagnostics |
| **gtsummary / Quarto / flextable / bookdown** | Publication profile (and Advanced → Documentation) | Existing `gtsummary_tutorial`, `quarto_*` pages move here; **flextable** and **bookdown** pages are new |
| **Contributing guide** *(new)* | Contributing profile | Documents §1.1 so others can add content without creating duplicates |
| **Citation** *(new topic: `publication/citation.qmd`, cumulative level blocks)* | Full depth in Publication; each profile shows the level it needs (table below) | One page, written once; other profiles include it or link to their level |

### Citation by profile (one page, level blocks)

| Profile | What citation means there |
|---|---|
| Basic | Why cite R and packages; `citation()`, `citation("ggplot2")`; R version and package versions in methods |
| Moderate | Quarto citations: `.bib` file, `[@key]`, bibliography and CSL style; `grateful` to cite all packages used; citing datasets |
| Regression | Citing methods and reporting guidelines (STROBE, TRIPOD); a methods paragraph with software/version citations |
| Advanced | Citations in parameterised and multi-document reports; citing specialist packages (`survival`, `lme4`, `mice`, …) |
| DataViz | Citing data sources and packages in figure captions/notes |
| Publication | Full workflow: Zotero + Better BibTeX, journal CSL styles, cross-references, bookdown/manuscript citations, reference checks |
| Contributing | How to add references to the site's shared `references.bib` |

## 1.4 Curriculum map: one file drives everything

Today the 6 profile YAMLs list pages by hand and drift apart. Proposal: **`curriculum.yml`**, one row per topic page:

```yaml
- page: statistical-analysis/data_analysis.qmd
  title: Data Analysis
  levels: [moderate, advanced]      # which main-ladder profiles show it
  ladders: [publication]            # separate ladders that also show it
  menu: Statistics
  skills: [desc.table1, test.choose]  # used by the quest
```

A small script (`scripts/build_profiles.R`) generates each profile's `render:` list and navbar from it. The **same file is the quest's literature registry** (Part 2 §2.4), so the workshop and the quest can never disagree about what is taught where.

## 1.5 Speed and disk

* **Source:** single copy of every page (the goal).
* **Output:** each profile still writes its own HTML (that's how profiles work). Advanced as one profile, not four, keeps this down.
* **Execution:** level blocks hide content but code inside them **still runs**, and the R results are identical in every profile. So `execute: freeze: auto` can compute each page **once** and reuse it for all profiles. That would make renders much faster, but **Tested (Phase 0):** works across profiles; see Phase 0 notes.
* **Incremental render:** `render-all-profiles.sh` already skips unchanged pages. Phase 0 adds: a changed `_partials/*.qmd` re-renders the pages that include it, and a changed `curriculum.yml` re-renders the affected profiles.

---



## 1.6 Audience profiles (later)

Beyond level-based profiles, later we add **audience profiles**: the same pages, but a different **selection, order and examples** for a specific kind of learner. They are built from `curriculum.yml` (an `audiences:` field per page), so they cost almost no new writing.

| Audience profile | Who | Emphasis |
|---|---|---|
| `residents` | PG residents writing a thesis | Basic → Regression path, Table 1, reporting, citation, thesis workflow |
| `faculty` | Faculty and examiners | Critiquing analyses, reporting standards, teaching-ready decks and cheat sheets |
| `programme` | Public-health programme officers | Dashboards, counts and rates, surveys, simple reporting |
| `students` | UG / MPH students | Gentler pace, more practice, fewer packages |
| `facilitators` | Workshop instructors | Solutions, timings, discussion prompts, cohort mode |

Rules: no copied pages; audience profiles are **views** (a page list plus optional `when-audience` blocks, handled by the same filter as levels). Ordering matters less than selection. Start only after the main ladder and `curriculum.yml` are stable (Phase 11).

---

# Part 2 · Dungeons & Dataframes (the quest)

## 2.1 The idea

The quest is **its own site** (`docs/dungeons/`, profile `dungeons`, own landing card; folder `dungeons/`), built **on top of** the workshop. **Workshop pages are its literature**: each world links "📖 Read first" to the pages that teach it.

> **Coverage rule:** the quest only tests what the workshop teaches. A missing topic is added to the workshop first.

## 2.2 Decisions

| # | Topic | Decision |
|---|---|---|
| 1 | Advanced | Post-regression, with branches (Part 1 §1.2) |
| 2 | DataViz | Separate ladder → **side quest**; core plots stay in the main quest |
| 3 | Later topics | Advanced Analysis roadmap (§2.7) |
| 4 | Gating | Yes: region post-test **≥ 70%** unlocks the next; **retakes allowed** after a cooldown; placement test can unlock directly |
| 5 | Name | Dungeons & Dataframes |
| 6 | Old URLs | Redirect `docs/regression/regression-quest/*` → `docs/dungeons/dungeons/*` (stubs written by `render-all-profiles.sh`) |
| 7 | Advanced before A1 exists | Publish it with a **roadmap ("coming soon") page** |

## 2.3 Regions

| Region | Literature | Gate | Candidate worlds |
|---|---|---|---|
| **1 · Basic** | Basic profile | ✔ | Your First Script · Tidy Tavern · Join Junction · First Plots · Which Test? |
| **2 · Moderate** | Moderate profile | ✔ | Messy Data Dungeon · **Loop Labyrinth** (iteration) · Explore by Picture · Table 1 Forge · Tests in Context |
| **3 · Regression** | Regression profile | ✔ | Worlds 1–6 + **ANOVA meets Regression** |
| **4 · Advanced** | Advanced branches | per branch | Analysis: one world-group per module (§2.7) · Programming: Map Mountain · Documentation: from the Publication side quest |
| *side* · Plot Workshop | DataViz ladder | — | from DataViz Foundations / Complete |
| *side* · The Scriptorium | Publication ladder | after R1 gate | gtsummary, flextable, Quarto, bookdown, citation |
| *end* · Capstone | all | — | Your Thesis |

Core visualisation stays in the main regions: R1 basic plots; R2 exploratory plots; R3 diagnostic/forest/effect plots; R4 KM, rate and calibration plots.

## 2.4 Literature, technically

* Uses **`curriculum.yml`** (Part 1 §1.4): a world's skills → the pages that teach them → links to the **lowest profile showing that level**.
* **`quest/check_literature.R`** (CI): every world has literature; every linked page is rendered in its profile; every item's skill is taught somewhere; outputs a **gap report** (the workshop to-do list).

## 2.5 Restructuring the existing quest code

| Today | After |
|---|---|
| `regression-quest/` in the regression profile | ✔ `dungeons/` + `_quarto-dungeons.yml` → `docs/dungeons/` (2026-10-22) |
| `bank/items.R` | `bank/r1_basic.R`, `r2_moderate.R`, `r3_regression.R`, `r4_<branch>.R`, `side_dataviz.R`, `side_publication.R` |
| `worlds.js` flat W1–W16 | ✔ Regions (gates per region still to do); side quests separate |
| One pre/post (regression) | Per-region pre/post (post = gate) + placement test |
| Progress key `rq:v1` | `dd:v2` + one-time migration |
| Quest menu in Regression navbar | ✔ removed from Regression; the game has its own navbar with a 📖 Library menu and per-world "Read first" links. Still to do: "🎮 Practise in the Quest" link in every workshop navbar |
| `regression-quest/ROADMAP.md`, `SITE_DESIGN.md` | Kept as the engine and Region 3 detail; this file is the umbrella |

## 2.6 Advanced Analysis modules (post-regression)

Every module follows the Regression pattern, workshop **first**:
- dataset script;
- decks;
- labs and solutions;
- cheat sheet;
- quizzes.

Then its quest worlds.

| # | Module | Core topics | Dataset (synthetic, Indian context) | Needs | Order |
|---|---|---|---|---|---|
| A1 | **Survival analysis** | Censoring; KM; log-rank; Cox, HRs; PH checks and fixes; reporting | DOTS TB cohort | Regression | 1 |
| A2 | Counts and rates | Poisson, offsets, rate ratios; overdispersion, NB; zero inflation (intro) | Dengue ward-month | Regression | 2 |
| A3 | Ordinal and multinomial | Proportional odds and its check; multinomial | BP stage; delivery place | Regression | 3 |
| A4 | Clustered and repeated data | ICC, design effect; `lme4`; GEE; repeated measures | NCD villages + BP visits | Regression | 4 |
| A5 | Complex surveys | Weights, strata, PSUs; `survey`/`srvyr` | NFHS-style survey | A4 | 5 |
| A6 | Non-linearity and interaction | Splines, GAM intro, effect modification, prediction plots | NCD survey | Regression | 6 |
| A7 | Missing data | MCAR/MAR/MNAR; `mice`; sensitivity | NCD with missingness | A6 | 7 |
| A8 | Prediction models | Validation, calibration, shrinkage, TRIPOD | Diabetes screening | A6, A7 | 8 |
| A9 | Causal inference | DAGs; PS, IPW; E-values | Programme evaluation | A6 | 9 |
| A10 | Advanced survival | Competing risks, time-varying covariates, parametric | TB cohort (ext.) | A1 | later |

**Electives, added only when chosen:**
- power and sample size;
- diagnostic accuracy;
- interrupted time series;
- meta-analysis;
- Bayesian;
- spatial;
- quasi-experiments.

**Done means:**
- data script;
- ≥ 4 decks;
- labs and solutions run clean;
- cheat sheet;
- quiz lint passes;
- pages in `curriculum.yml`;
- quest worlds pass `lint_bank.R` and `check_literature.R`;
- e2e tests pass.

**Effort:** about 2–3 weeks of workshop work and 1–2 weeks of quest work per module.

---

# Phases (both parts)

| Phase | Deliverable |
|---|---|
| **0 · Foundations** | Test `when-meta` level flags and `freeze`; `curriculum.yml` + profile generator; partial-aware incremental render |
| **1 · Restructure profiles** | Cumulative level blocks on existing pages (start with `data_analysis`, `regression`, `getting-started`); Advanced with branch menus + roadmap page; new `publication` profile (move gtsummary/Quarto pages); landing page shows the main ladder + separate ladders |
| **2 · Quest split-out** | ✔ `dungeons` profile, regions, redirects, landing card (2026-10-22). Still to do: per-region gates, `dd:v2` migration, workshop navbar links |
| **3 · New workshop content** | ANOVA vs regression; iteration page (Moderate + Advanced); citation page (all levels); flextable and bookdown pages; contributing profile |
| **4 · Literature layer** | `check_literature.R` + gap report in CI |
| **5 · Quest Region 3 complete** | Worlds 3–6 + ANOVA world + gate |
| **6 · Quest Regions 1–2 + placement** | |
| **7 · Side quests** | Plot Workshop, Scriptorium |
| **8 · A1 Survival** | Workshop, then quest |
| **9 · A2 → A9** | One module at a time |
| **10 · Capstone** | |
| **11 · Audience profiles** | `audiences:` field in `curriculum.yml`; `residents`, `faculty`, `programme`, `students`, `facilitators` views (§1.6) |

# Decided (v4)

1. Advanced = **one profile with four branch menus**.
2. Iteration in **both**: a Moderate quest world (Loop Labyrinth) and the Advanced Programming branch.
3. Publication requires **at least Basic** first (stated on its landing page; the Scriptorium side quest unlocks after the Region 1 gate).
4. **Citation** is a cross-profile topic (Part 1 §1.3).

---

# Added profiles

| Profile | Output | Content | Key |
|---|---|---|---|
| `dungeons` | `docs/dungeons/` | The game (open access) | none |
| `gis` (8th track, 2026-10-27) | `docs/gis/` | The advanced visualization pages (grammar modules 1–4, all galleries, specialized, exporting) plus `gis/*.qmd`: spatial data with sf, maps and choropleths, neighbours and weights, global Moran's I, local Moran's I (LISA), Geary's C / Getis-Ord G and Gi* / join counts / scan statistic, spatial regression and residual tests. Synthetic district of 79 blocks (`gis/make_gis_data.R`, `data/gis/`) with a planted hot spot, cold spot and spatial outlier | `GIS-SPATIAL` (in `config.json`; change it there) |

**GIS workshop** (`gis-workshop/`, 2026-10-27): 5 decks, 5 labs with facilitator solutions, quizzes (lint clean), cheat sheet, same pattern as the regression workshop; the Dungeons & Dataframes GIS region comes **after** the workshop has been run and corrected.

Ideas to add later: raster data with `terra`, spatial interpolation (kriging), a GIS region in the game.

**Counts and rates workshop (A2)** (`counts-workshop/`, 2026-10-30): 5 decks, 5 labs with facilitator solutions, quizzes (lint clean), cheat sheet, synthetic dengue ward-month data (`data/dengue_wards.csv`); lives in the `advanced` profile. Region 4 game world **after** the workshop has been run and corrected. Next: A3 ordinal and multinomial outcomes, A4 clustered data.
