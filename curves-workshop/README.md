# Curves and Interactions — workshop (A6)

Five reveal.js decks, five fill-in-the-blank R labs with facilitator solutions, self-check quizzes in every deck and a two-page cheat sheet.
Everything runs on one **synthetic NCD risk-factor survey** (`data/ncd_curves.csv`: 4,000 adults, SBP and 10-year CVD event), built by `make_data.R`.
Part of the **advanced** profile (`quarto render --profile advanced`). Same pattern as the other advanced workshops.

| Session | Deck | Student lab | Facilitator solution |
|---|---|---|---|
| 1 Is it really a straight line? | `s1_beyond_linear.qmd` | `labs/lab1_linear.R` | `solutions/lab1_linear_solution.R` |
| 2 Splines | `s2_splines.qmd` | `labs/lab2_splines.R` | `solutions/lab2_splines_solution.R` |
| 3 Generalised additive models | `s3_gam.qmd` | `labs/lab3_gam.R` | `solutions/lab3_gam_solution.R` |
| 4 Interaction and effect modification | `s4_interaction.qmd` | `labs/lab4_interaction.R` | `solutions/lab4_interaction_solution.R` |
| 5 Choosing, checking and reporting | `s5_choose_check_report.qmd` | `labs/lab5_report.R` | `solutions/lab5_report_solution.R` |

Plus `cheatsheet.qmd` (2 pages, A4). Packages: `splines` (base), `mgcv`, `emmeans` (plus the tidyverse).

## Facilitator workflow

```r
Rscript curves-workshop/make_data.R            # regenerate data/ncd_curves.csv + feature check (stops if a teaching feature is lost)
Rscript curves-workshop/run_solutions.R        # run all five solutions (or: ... run_solutions.R 3 4)
Rscript curves-workshop/build_labs.R           # rebuild student labs from the solutions
Rscript regression-workshop/lint_quizzes.R curves-workshop/s*.qmd   # quiz quality gate (0 hard failures required)
quarto render --profile advanced               # build the site
```

Editing a lab: edit the **solution**, then run `build_labs.R`. `code  #@ piece1 || piece2` blanks the first occurrence of each piece on that line; `#% text` lines are facilitator-only answers. **After changing code, re-run the solutions and check every `#%` answer against the real output.**

## Data features (verified by `make_data.R`)

SBP rises 0.27 mmHg/year before age 45 and 0.56 after (best hinge knot 45; a straight line misses it) · BMI and activity act with diminishing returns (log/saturating) · **salt × age interaction** (salt effect about 0 at age 30, 0.74 at 45, 1.5 mmHg per g/day at 60) · 10-year CVD risk is **U-shaped in BMI** (minimum near 24.5; the linear-term OR is 1.007, p = 0.55, while the quadratic term has p below 1e-50) · **smoking × sex interaction** (OR about 2.3 in men and 1.0 in women) · age effect on CVD is linear on the logit scale (GAM edf 1).

## Quizzes
Same engine and lint as the other workshops (correct option never the longest, no absolutes only in distractors, every question explained, shuffled at run time).

## Next
A game world (Region 4) is built **after** the workshop has been run and corrected. Next module: A7 missing data.
