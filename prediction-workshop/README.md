# Prediction Models — workshop (A8)

Five reveal.js decks, five fill-in-the-blank R labs with facilitator solutions, self-check quizzes in every deck and a two-page cheat sheet.
Everything runs on two **synthetic diabetes-screening cohorts**: a development cohort (`data/diabetes_dev.csv`, 700 adults, 84 events) and an external validation cohort from another district (`data/diabetes_valid.csv`, 2,000 adults), both built by `make_data.R`.
Part of the **advanced** profile (`quarto render --profile advanced`). Same pattern as the other advanced workshops.

| Session | Deck | Student lab | Facilitator solution |
|---|---|---|---|
| 1 Building a risk model | `s1_building_model.qmd` | `labs/lab1_build.R` | `solutions/lab1_build_solution.R` |
| 2 Discrimination and calibration | `s2_discrimination_calibration.qmd` | `labs/lab2_perf.R` | `solutions/lab2_perf_solution.R` |
| 3 Overfitting and internal validation | `s3_overfitting_internal.qmd` | `labs/lab3_internal.R` | `solutions/lab3_internal_solution.R` |
| 4 Shrinkage and variable selection | `s4_shrinkage_selection.qmd` | `labs/lab4_shrink.R` | `solutions/lab4_shrink_solution.R` |
| 5 External validation, decision curves, reporting | `s5_external_reporting.qmd` | `labs/lab5_external.R` | `solutions/lab5_external_solution.R` |

Plus `cheatsheet.qmd` (2 pages, A4). Packages: `pROC`, `glmnet` (plus the tidyverse). Decision curves are computed by hand (`dcurves` is optional).

## Facilitator workflow

```r
Rscript prediction-workshop/make_data.R         # regenerate both cohorts + feature check (stops if a teaching feature is lost)
Rscript prediction-workshop/run_solutions.R     # run all five solutions (or: ... run_solutions.R 3 4)
Rscript prediction-workshop/build_labs.R        # rebuild student labs from the solutions
Rscript regression-workshop/lint_quizzes.R prediction-workshop/s*.qmd   # quiz quality gate (0 hard failures required)
quarto render --profile advanced                # build the site
```

Editing a lab: edit the **solution**, then run `build_labs.R`. `code  #@ piece1 || piece2` blanks the first occurrence of each piece on that line; `#% text` lines are facilitator-only answers. **After changing code, re-run the solutions and check every `#%` answer against the real output.** The bootstrap, cross-validation and `cv.glmnet` calls use fixed seeds; changing `make_data.R` changes every number.

## Data features (verified by `make_data.R`)

* Development: prevalence 12.0% (84 events); the 8-predictor model has an **apparent AUC 0.796** (CI 0.745 to 0.847); apparent calibration slope exactly 1.
* **Ten pure-noise markers** raise the apparent AUC to 0.821 (18 parameters, 4.7 events per parameter); bootstrap optimism 0.020 vs 0.042, **corrected AUC 0.776 vs 0.779** (no real gain); 10-fold CV 0.768 vs 0.763; bootstrap slope 0.90 vs 0.80.
* Backward stepwise keeps four noise markers (m6, m8, m9, m10); bootstrap inclusion 12% to 82%; ridge shrinks to about 60 to 70% of the ML coefficients; lasso at lambda.1se keeps only age, waist and family history.
* **Validation district**: older, less active, prevalence 24.6%, weaker predictor effects. The development model has AUC **0.709** (CI 0.682 to 0.736), calibration slope **0.67**, intercept +0.50 (mean predicted 17.9% vs observed 24.6%). Models: ML all markers slope 0.53, ridge 0.80, lasso 1.59 (over-shrunk). Recalibration: Brier 0.170 to 0.165. Decision curve: the model beats treat-all from a 15% threshold.

## Quizzes
Same engine and lint as the other workshops (correct option never the longest, no absolutes only in distractors, every question explained, shuffled at run time).

## Next
A game world (Region 4) is built **after** the workshop has been run and corrected. Next module: A9 causal inference.
