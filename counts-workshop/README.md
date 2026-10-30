# Counts and rates — workshop

Five reveal.js decks, five fill-in-the-blank R labs with facilitator solutions, a self-check quiz in every deck and a two-page cheat sheet.
Everything runs on one **synthetic dengue surveillance dataset** (`data/dengue_wards.csv`: 30 wards x 36 months = 1,080 ward-months, built by `counts-workshop/make_data.R`; no real data).
Part of the **advanced** profile ("Advanced Analysis" branch, module A2 in `SITE_PLAN.md`): `quarto render --profile advanced`.
Same pattern as `regression-workshop/`, `gis-workshop/` and `survival-workshop/`.

| Session | Deck | Student lab | Facilitator solution |
|---|---|---|---|
| 1 Counts, rates and the Poisson idea | `s1_counts_rates.qmd` | `labs/lab1_counts.R` | `solutions/lab1_counts_solution.R` |
| 2 Poisson regression: log link, rate ratios, the offset | `s2_poisson_regression.qmd` | `labs/lab2_poisson.R` | `solutions/lab2_poisson_solution.R` |
| 3 Overdispersion: quasi-Poisson, negative binomial, robust SE | `s3_overdispersion.qmd` | `labs/lab3_overdisp.R` | `solutions/lab3_overdisp_solution.R` |
| 4 Excess zeros and model checking | `s4_zeros_checking.qmd` | `labs/lab4_zeros.R` | `solutions/lab4_zeros_solution.R` |
| 5 Reporting and extensions: cases averted, Poisson for prevalence ratios | `s5_reporting_extensions.qmd` | `labs/lab5_report.R` | `solutions/lab5_report_solution.R` |

Plus `cheatsheet.qmd` (2 pages, prints to A4). Suggested format: one full day (Sessions 1-3 in the morning, 4-5 after lunch).
**Prerequisite:** the regression workshop (multiple and logistic regression, reading coefficients).

## Facilitator workflow

```r
Rscript counts-workshop/make_data.R              # regenerate data/dengue_wards.csv + feature check (stops if a teaching feature is lost)
Rscript counts-workshop/run_solutions.R          # run all five solutions (or: ... run_solutions.R 3 4)
Rscript counts-workshop/build_labs.R             # rebuild student labs from the solutions
Rscript regression-workshop/lint_quizzes.R counts-workshop/s*.qmd    # quiz quality gate (0 hard failures)
quarto render --profile advanced                 # build the site
node counts-workshop/tests/quiz_all.js docs/advanced/counts-workshop/s*.html     # browser quiz test (needs Playwright)
node counts-workshop/tests/overflow.js docs/advanced/counts-workshop/s*.html     # no slide runs off the page
```

Editing a lab: edit the **solution**, then `build_labs.R`. `code  #@ piece1 || piece2` blanks the first occurrence of each piece **on that line** (make the piece long enough that it cannot match inside a longer name); `#% text` is facilitator-only.

## R packages
`MASS` (negative binomial), `pscl` (zero-inflated and hurdle models), `sandwich` + `lmtest` (robust SEs), `performance`, `broom`, `gtsummary`, `tidyverse`.

## Data features (verified by `make_data.R`)
Counts depend on ward **population** (an offset is needed), **rain in the previous month** (rate ratio about 1.3 per 100 mm), **slum** status (about 1.5-1.7), a mild upward trend and strong **monsoon seasonality** ·
**fogging** from month 25 in 15 wards lowers the rate (adjusted rate ratio about 0.65, crude about 0.86: season and trend confound the crude comparison) ·
**severe overdispersion** (Poisson dispersion about 8; the negative binomial AIC is about 4,900 points lower) ·
a few wards with **weak reporting** give excess (structural) zeros · modest residual autocorrelation within wards.

## Next: the game
Once this workshop has been run and corrected, a Dungeons & Dataframes **Count Country** world (Region 4) will be built on it.
