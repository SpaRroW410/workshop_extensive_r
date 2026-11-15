# Missing Data — workshop (A7)

Five reveal.js decks, five fill-in-the-blank R labs with facilitator solutions, self-check quizzes in every deck and a two-page cheat sheet.
Everything runs on one **synthetic NCD cohort with missing data** (`data/ncd_missing.csv`: 2,000 adults), built by `make_data.R`: the complete data are generated first, then values are deleted by known mechanisms, so the truth is known to the facilitator.
Part of the **advanced** profile (`quarto render --profile advanced`). Same pattern as the other advanced workshops.

| Session | Deck | Student lab | Facilitator solution |
|---|---|---|---|
| 1 Patterns and mechanisms | `s1_patterns_mechanisms.qmd` | `labs/lab1_pattern.R` | `solutions/lab1_pattern_solution.R` |
| 2 Simple methods and why they fail | `s2_simple_methods.qmd` | `labs/lab2_simple.R` | `solutions/lab2_simple_solution.R` |
| 3 Multiple imputation with mice | `s3_multiple_imputation.qmd` | `labs/lab3_mice.R` | `solutions/lab3_mice_solution.R` |
| 4 Diagnostics, derived variables, number of imputations | `s4_mi_diagnostics.qmd` | `labs/lab4_diagnostics.R` | `solutions/lab4_diagnostics_solution.R` |
| 5 MNAR sensitivity analysis and reporting | `s5_mnar_reporting.qmd` | `labs/lab5_mnar.R` | `solutions/lab5_mnar_solution.R` |

Plus `cheatsheet.qmd` (2 pages, A4). Packages: `mice`, `naniar` (plus the tidyverse).

## Facilitator workflow

```r
Rscript missing-workshop/make_data.R           # regenerate data/ncd_missing.csv + feature check (stops if a teaching feature is lost)
Rscript missing-workshop/run_solutions.R       # run all five solutions (or: ... run_solutions.R 3 4)
Rscript missing-workshop/build_labs.R          # rebuild student labs from the solutions
Rscript regression-workshop/lint_quizzes.R missing-workshop/s*.qmd   # quiz quality gate (0 hard failures required)
quarto render --profile advanced               # build the site
```

Editing a lab: edit the **solution**, then run `build_labs.R`. `code  #@ piece1 || piece2` blanks the first occurrence of each piece on that line; `#% text` lines are facilitator-only answers. **After changing code, re-run the solutions and check every `#%` answer against the real output.** `mice` results depend on the random stream: all imputation calls in the labs and decks use fixed seeds, and changing `make_data.R` changes every number.

## Data features (verified by `make_data.R`)

Missing: BMI 26% (MAR: older, male, **high SBP**), HbA1c 21% (**MNAR**: high values missing), activity 12% (MAR on education), smoking 9% (MCAR), SBP 6% (MAR on age); 45% complete cases.
* BMI slope in the SBP model: truth 0.80 (0.855 in the complete data of this sample); **complete-case 0.69**, mean imputation 0.70, missing-indicator 0.68 (indicator coefficient 28 mmHg, an artefact), single imputation 0.75 with an SE too small (0.057), **multiple imputation 0.79** (SE 0.066).
* Mean HbA1c: truth 5.50, observed 5.35, after MAR imputation 5.38; delta about 0.55 recovers the truth. Share with HbA1c 6.5% or more: truth 4.4%, observed and MAR 0.4%, delta 0.5 gives 3.1%.
* m = 5 gives pooled SEs that move between seeds (0.063 to 0.089); m = 50 is stable (0.065 to 0.071).

## Quizzes
Same engine and lint as the other workshops (correct option never the longest, no absolutes only in distractors, every question explained, shuffled at run time).

## Next
A game world (Region 4) is built **after** the workshop has been run and corrected. Next module: A8 prediction models.
