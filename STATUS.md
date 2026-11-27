# Project status snapshot

Saved 2026-11-13 from branch `causal-workshop`. This file is a save point: what exists, where it lives, what was checked, and what is still open.
Update it whenever a module is merged or a new one is built. The long-term plan stays in `SITE_PLAN.md` and `dungeons/ROADMAP.md`.

## 1. Workshops

| Module | Folder | Data | Branch | On `main`? |
|---|---|---|---|---|
| Regression (core) | `regression-workshop/` | `data/ncd_survey.csv` | main | yes |
| GIS and spatial statistics | `gis-workshop/` | `data/gis/` | main | yes |
| A1 Survival | `survival-workshop/` | `data/tb_cohort.csv` | main | yes |
| A2 Counts and rates | `counts-workshop/` | `data/dengue_wards.csv` | main | yes |
| A3 Ordinal and multinomial | `ordinal-workshop/` | `data/maternal_survey.csv` | main | yes |
| A4 Clustered and repeated data | `clustered-workshop/` | `data/bp_trial.csv` | `clustered-workshop` | **no** |
| A5 Survey data and weights | `survey-workshop/` | `data/survey_adults.csv`, `data/survey_population.csv` | `survey-workshop` | **no** |
| A6 Curves and interactions | `curves-workshop/` | `data/ncd_curves.csv` | `curves-workshop` | **no** |
| A7 Missing data | `missing-workshop/` | `data/ncd_missing.csv` | `missing-workshop` | **no** |
| A8 Prediction models | `prediction-workshop/` | `data/diabetes_dev.csv`, `data/diabetes_valid.csv` | `prediction-workshop` | **no** |
| A9 Causal inference | `causal-workshop/` | `data/htn_programme.csv` | `causal-workshop` | **no** |
| A10 Advanced survival | not built (later) | | | |

Each built module has 5 decks, 5 labs with facilitator solutions, a 5-question quiz per deck, a cheat sheet, a README and a `make_data.R` with a feature check.

**The A4 to A9 branches are stacked**: each contains the ones before it. `causal-workshop` holds all six and every change in section 4. Merging that one branch into `main` brings in everything; or merge in order A4 to A9.

## 2. The game (Dungeons & Dataframes, `dungeons/`)

| Part | State |
|---|---|
| Region 1, basics (b1 to b5) | playable, own pre and post test |
| Region 2, moderate (m1 to m5) | playable, own pre and post test |
| Region 3, regression (worlds 1 to 6) | playable, pre and post test |
| Region 4, advanced analysis | **not built**; waits until each workshop has been run and corrected |
| GIS region | not built; same rule |
| Item bank | 232 items (132 multiple choice, 45 numeric, 30 code, 16 spot-the-error, 9 ordering) |
| Player progress | kept in the browser; export, import and reset buttons already exist on the campus page |
| Real R in the browser (webR) | deferred to a later phase; code items use the static checker `rcheck.js` |

## 3. Checks run for this snapshot

| Check | Result |
|---|---|
| `Rscript scripts/build_profiles.R --check` | all 8 profile files match `curriculum.yml` |
| Quiz lint, all 11 workshops (`regression-workshop/lint_quizzes.R`) | 0 hard failures, 0 warnings in each |
| Game bank lint (`dungeons/lint_bank.R`, `dungeons/tests/lint_bank.js --strict`) | 0 hard failures, 0 warnings |
| Files named in `welcome.qmd` downloads and `curriculum.yml` resources | all exist |
| Student labs rebuilt from solutions | one stale file found and fixed (see section 4) |
| Quiz and slide-overflow browser tests, all 56 decks (regression, GIS, advanced) | all quizzes pass; two old regression slides overflow slightly (section 5) |
| Save score, reload and reset in a browser test | works |
| Rendered pages in `docs/advanced/` | 6 pages for each of the 8 advanced workshops |

Not re-run for this snapshot: the game end-to-end test (`dungeons/tests/quest_e2e.js`) and a render of the profiles other than regression, GIS and advanced.

## 4. Inconsistencies found, and what was done

| Item | State |
|---|---|
| `survey-workshop/labs/lab1_design.R` was older than its solution | fixed |
| Root `README.md` described only the visualization site and the regression workshop | fixed: sections for the advanced and GIS workshops and the game |
| `dungeons/ROADMAP.md` listed old datasets for worlds 10 to 14 | fixed: worlds and the dataset table now name the workshop datasets |
| Advanced navbar had 14 top-level menus | fixed: one "Advanced Workshops" menu and the page `advanced-workshops.qmd` that lists every session |
| Quiz engine copied into ten folders with no guard | `scripts/sync_workshop_assets.sh` copies the master (`regression-workshop/assets/`) to the others; `--check` fails if a copy differs |
| No automatic checks | `.github/workflows/checks.yml`: profile check, asset check, quiz lint, labs in sync, game bank lint (not yet seen running on GitHub) |
| Deck quiz scores were lost on reload | fixed: scores are kept in the browser per deck; **Save score** downloads a text file, **Reset** clears it |
| Every track home showed one track's content (Basic opened the GIS home) | fixed 2026-11-16: `welcome.qmd` built its content in an R chunk from `QUARTO_PROFILE`, and `freeze: auto` keeps one cached result per file for all profiles. The page is now plain markdown with one `when-profile` block per track, so nothing is frozen |
| Download links on the track homes pointed at files that do not exist (`downloads/basic_r_foundations.R`, `workshop_data.csv`, …) | fixed: each track home links only to files in the repository |
| `docs/<track>/index.html` was a second copy of the landing page with dead links | fixed: inside a track `index.qmd` renders a redirect to the track home (`ws-track: true` in the generated profile files) |
| `assets/fitty-init.js` was requested with a wrong path on every nested page (404) and is not used by any HTML page | fixed: include removed from `_quarto.yml` |
| GIS sources and labs were copied into the other tracks' output | fixed: caused by the frozen GIS welcome page; stale copies removed from `docs/` |
| Landing page footer links (Downloads, Contact, References) were dead; game card listed Region 4 as playable | fixed |
| `data-visualization/plot_data.qmd` names `custom-theme.css`, which does not exist | **open**: harmless 404; fixing it means re-running the deck in R |
| `main` is six modules behind the branches | **open**: needs your merge decision |

## 5. Still open

1. **Merge to `main`.** `causal-workshop` holds A4 to A9 and every change listed above.
2. **Expert review.** No statistical content in A1 to A9 has been reviewed by a subject expert. Region 4 worlds should follow that review.
3. **Deck generators are not in the repository.** The `.qmd` files are the source of truth; edit them directly.
4. **Two slides in the older regression decks overflow by 6 to 7 pixels** (`s1_foundations` slide 5, `s5_logistic_regression` slide 33). Not caused by these changes.
5. **`build_profiles.R` prints a notice** that sessions 2 to 5 of the advanced modules are in no menu. That is intended: they are reached from the landing page.
6. **The planned series A1 to A9 is complete.** Next options: Region 4 of the game (after the workshops have been run), or A10 advanced survival.

## 5b. Launch plan (LAUNCH_PLAN.md), 2026-11-19

Phases 0 to 3 are built and tested locally in `cloud/` (see `cloud/README.md` and `NIGHT_NOTES.md`):
deploy tooling, Google sign-in, the gate on paid paths, progress sync and "continue where you left off".
Not live: it needs your Cloudflare account, Google OAuth client and a first deploy. Phases 4 (Razorpay)
and 5 (seat codes, cohorts) are not started. GitHub Pages still serves `docs/` with the workshop keys.

## 5c. Tracks and modules, 2026-11-20

- **Each track now renders only its own pages** (decision "a"): Moderate has 15 pages Basic lacks, Data Viz
  Foundations 9, Complete 16; links to another track's pages point into that track (`_filters/crosstrack.lua`).
  A test in `cloud/` fails if a page a paid track sells reappears in `/basic/`.
- Free tier and product list confirmed as built (`cloud/src/products.js`).
- `MODULES_PLAN.md`: the plan for bringing every module to one standard. U0 (consistency) done except the items
  that need you; next are U1 (Basic: quizzes and labs), U2 (Moderate) and U3 (expert review before charging).
- Full re-render of all eight tracks: no broken internal links; 62 deck quizzes, game e2e, cloud tests and both
  browser suites pass.

## 5d. Statistical Analysis track, 2026-11-27 (branch `statistical-analysis`)

- New elective track `statistics` (`docs/statistics/`, product `statistics`, key `STATISTICS` in `config.json`): the Basic track's
  test pages plus `stats-workshop/`, five sessions on choosing tests, **checking assumptions** and **interpreting results**,
  on `data/prac_modded.xlsx`. Labs and solutions run; quizzes lint clean; all 67 deck quizzes pass in a browser.
- Corrects the earlier material: KS against N(0,1), Shapiro on a random subsample, z when n > 30, Levene-then-Student,
  unpaired post hoc tests after repeated measures, the expected-count rule, and a script bug (`table_htn_gender`).
- `_routes.json` now 96 of 100 rules: workshop `assets/` folders are free through the Function (decks embed their
  CSS; only the cheat sheets load a stylesheet).
- **Practice data made medically meaningful** (same day): `data/prac_modded.xlsx` is now generated by
  `stats-workshop/make_data.R` (synthetic; same 26 column names and category labels, so the Basic track's Data Analysis
  page and `data_analysis.R` run unchanged) with plausible effects and a feature check: SBP rises with age (r 0.35), BMI with
  wealth, known diabetes ~4% and linked to age and hypertension (Fisher, OR ~6), foot pain falls after the programme
  (McNemar), fasting glucose and SBP fall over correlated visits (paired CI 3x narrower than unpaired). Four SBP/DBP swaps
  and one weight typo are planted for Session 1 and corrected in `assets/setup.R` / Lab 1. Decks, quizzes (numbers now
  computed from the data), labs, solutions, cheat sheet and README updated; the quiz lint now runs a deck's setup chunk
  when a question is computed from the data. The original file is in git history (commit 4040a8e and earlier).

## 6. How to re-verify

```sh
(cd cloud && npm ci && npm test)                   # sign-in, gate and sync, against a local Cloudflare
Rscript scripts/build_profiles.R --check
bash scripts/sync_workshop_assets.sh --check
for w in regression stats survival counts ordinal gis clustered survey curves missing prediction causal; do
  Rscript regression-workshop/lint_quizzes.R $w-workshop/s*.qmd | tail -1
done
Rscript dungeons/lint_bank.R && node dungeons/tests/lint_bank.js --strict
Rscript prediction-workshop/run_solutions.R      # same script exists in every workshop folder
quarto render --profile advanced
```
