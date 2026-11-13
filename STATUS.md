# Project status snapshot

Saved 2026-11-13 from branch `prediction-workshop`. This file is a save point: what exists, where it lives, what was checked, and what is still open.
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
| A9 Causal inference | not built | | | |
| A10 Advanced survival | not built (later) | | | |

Each built module has 5 decks, 5 labs with facilitator solutions, a 5-question quiz per deck, a cheat sheet, a README and a `make_data.R` with a feature check.

**The A4 to A8 branches are stacked**: each contains the ones before it. `prediction-workshop` holds all five. Merging that one branch into `main` brings in A4 to A8 together; or merge in order A4, A5, A6, A7, A8.

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
| Quiz lint, all 10 workshops (`regression-workshop/lint_quizzes.R`) | 0 hard failures, 0 warnings in each |
| Game bank lint (`dungeons/lint_bank.R`, `dungeons/tests/lint_bank.js --strict`) | 0 hard failures, 0 warnings |
| Files named in `welcome.qmd` downloads and `curriculum.yml` resources | all exist |
| Student labs rebuilt from solutions | one stale file found and fixed (see section 4) |
| Quiz and slide-overflow browser tests, all 51 decks (regression, GIS, advanced) | all quizzes pass; two old regression slides overflow slightly (section 5) |
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
| `main` is five modules behind the branches | **open**: needs your merge decision |

## 5. Still open

1. **Merge to `main`.** `prediction-workshop` holds A4 to A8 and every change listed above.
2. **Expert review.** No statistical content in A1 to A8 has been reviewed by a subject expert. Region 4 worlds should follow that review.
3. **Deck generators are not in the repository.** The `.qmd` files are the source of truth; edit them directly.
4. **Two slides in the older regression decks overflow by 6 to 7 pixels** (`s1_foundations` slide 5, `s5_logistic_regression` slide 33). Not caused by these changes.
5. **`build_profiles.R` prints a notice** that sessions 2 to 5 of the advanced modules are in no menu. That is intended: they are reached from the landing page.
6. **A9 Causal inference** is the next module to build.

## 6. How to re-verify

```sh
Rscript scripts/build_profiles.R --check
bash scripts/sync_workshop_assets.sh --check
for w in regression survival counts ordinal gis clustered survey curves missing prediction; do
  Rscript regression-workshop/lint_quizzes.R $w-workshop/s*.qmd | tail -1
done
Rscript dungeons/lint_bank.R && node dungeons/tests/lint_bank.js --strict
Rscript prediction-workshop/run_solutions.R      # same script exists in every workshop folder
quarto render --profile advanced
```
