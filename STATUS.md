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
| Rendered pages in `docs/advanced/` | 6 pages for each of the 8 advanced workshops |

Not re-run for this snapshot: the game end-to-end test (`dungeons/tests/quest_e2e.js`), a full `render-all-profiles.sh`, and the per-deck quiz and overflow browser tests for workshops already on `main`.

## 4. Inconsistencies found

| Item | State |
|---|---|
| `survey-workshop/labs/lab1_design.R` was older than its solution (a garbled hint comment in Task 6) | fixed in this commit, also in `docs/advanced/` |
| `main` is five modules behind the branches | open; needs a merge decision |
| Root `README.md` describes only the visualization site and the regression workshop | open |
| `dungeons/ROADMAP.md` lists Curves, Missing Data and Prediction worlds as using the NCD survey; the workshops now use their own datasets | open; update when Region 4 is built |

## 5. Suggestions

1. **Navbar of the advanced profile.** It now has 14 top-level menus, 8 of them workshops. It will wrap on a laptop screen. Options: one "Advanced Workshops" menu that links to Session 1 and the cheat sheet of each module, or a landing page with one card per module.
2. **Expert review before the game.** No statistical content in A1 to A8 has been reviewed by a subject expert. Region 4 worlds should follow that review, as planned.
3. **One shared quiz and lab toolkit.** Every workshop carries its own copy of `assets/quiz.*`, `build_labs.R`, `run_solutions.R` and the two browser tests. A fix must be made ten times. Moving them to one shared folder would remove that risk.
4. **Deck generators are not in the repository.** The decks of A4 to A8 were written by scripts kept outside the repo; the `.qmd` files are the source of truth from now on. Edit the `.qmd` directly.
5. **A continuous-integration check.** A GitHub Action that runs the profile check, both linters and `run_solutions.R` would catch stale labs and broken keys on every push.
6. **Quiz progress in decks is not saved.** Deck quizzes reset on reload. If participants should keep or hand in their scores, an export button like the game's could be added.

## 6. How to re-verify

```sh
Rscript scripts/build_profiles.R --check
for w in regression survival counts ordinal gis clustered survey curves missing prediction; do
  Rscript regression-workshop/lint_quizzes.R $w-workshop/s*.qmd | tail -1
done
Rscript dungeons/lint_bank.R && node dungeons/tests/lint_bank.js --strict
Rscript prediction-workshop/run_solutions.R      # same script exists in every workshop folder
quarto render --profile advanced
```
