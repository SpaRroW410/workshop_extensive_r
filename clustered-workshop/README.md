# Clustered and Repeated Data — workshop (A4)

Five reveal.js decks, five fill-in-the-blank R labs with facilitator solutions, self-check quizzes in every deck and a two-page cheat sheet.
Everything runs on one **synthetic cluster-randomised trial** (`data/bp_trial.csv`: 40 villages, 800 adults, SBP at 0, 3, 6 and 12 months, 13% of visits missing), built by `make_data.R`.
Part of the **advanced** profile (`quarto render --profile advanced`). Same pattern as `regression-workshop/`, `survival-workshop/`, `counts-workshop/` and `ordinal-workshop/`.

| Session | Deck | Student lab | Facilitator solution |
|---|---|---|---|
| 1 Clustered data: ICC and the design effect | `s1_clustered_data.qmd` | `labs/lab1_clusters.R` | `solutions/lab1_clusters_solution.R` |
| 2 Cluster-robust standard errors and GEE | `s2_robust_gee.qmd` | `labs/lab2_gee.R` | `solutions/lab2_gee_solution.R` |
| 3 Random-intercept (mixed) models | `s3_mixed_models.qmd` | `labs/lab3_mixed.R` | `solutions/lab3_mixed_solution.R` |
| 4 Repeated measures and trajectories | `s4_repeated_measures.qmd` | `labs/lab4_long.R` | `solutions/lab4_long_solution.R` |
| 5 Choosing, checking and reporting | `s5_choose_check_report.qmd` | `labs/lab5_report.R` | `solutions/lab5_report_solution.R` |

Plus `cheatsheet.qmd` (2 pages, A4). Suggested format: two half-days (Sessions 1 to 3, then 4 and 5), about 25 minutes of slides and 35 minutes of lab per session.

## Facilitator workflow

```r
Rscript clustered-workshop/make_data.R           # regenerate data/bp_trial.csv + feature check (stops if a teaching feature is lost)
Rscript clustered-workshop/run_solutions.R       # run all five solutions (or: ... run_solutions.R 3 4)
Rscript clustered-workshop/build_labs.R          # rebuild student labs from the solutions
Rscript regression-workshop/lint_quizzes.R clustered-workshop/s*.qmd   # quiz quality gate (0 hard failures required)
quarto render --profile advanced                 # build the site
```

Packages: `lme4`, `lmerTest`, `geepack`, `clubSandwich`, `sandwich`, `lmtest`, `performance` (plus the tidyverse).

### Editing a lab
Edit the **solution**, then run `build_labs.R`. In a solution `code  #@ piece1 || piece2` blanks the first occurrence of each piece **on that line**; `#% text` lines are facilitator-only answers. Hints describe the goal and never name the function that goes in the blank. **After changing code, re-run the solutions and check every `#%` answer against the real output.**

## Data features (verified by `make_data.R`)

Baseline ICC about 0.07, design effect about 2.4 (naive SE of the cluster-level programme effect too small, about 1.15 vs 1.6) · programme lowers SBP faster over time (months × arm about −0.39 per month; within-person effect, so the naive SE is too *large*) · dropout depends on age and the previous SBP (missing at random) · binary `controlled` (SBP below 140) where the programme effect is not clear (OR about 1.2, CI includes 1) · random slopes add nothing (teaching point: do not keep what the data do not support).

## Quizzes
Same engine as the regression workshop. Correct option never the longest, no absolutes only in distractors, every question explained, shuffled at run time. Key positions are balanced across decks.

## Next
A game world (Region 4) is built **after** the workshop has been run and corrected. Next module: A5 survey data and weights.
