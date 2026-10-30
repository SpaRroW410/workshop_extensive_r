# Survival analysis — workshop

Five reveal.js decks, five fill-in-the-blank R labs with facilitator solutions, a self-check quiz in every deck and a two-page cheat sheet.
Everything runs on one **synthetic TB cohort** (`data/tb_cohort.csv`: 600 adults starting treatment, followed up to 24 months, built by `survival-workshop/make_data.R`; no real patients).
Part of the **advanced** profile ("Advanced Analysis" branch, module A1 in `SITE_PLAN.md`): `quarto render --profile advanced`.
Same pattern as `regression-workshop/` and `gis-workshop/`.

| Session | Deck | Student lab | Facilitator solution |
|---|---|---|---|
| 1 Time-to-event data: censoring, Surv, person-time, follow-up | `s1_time_to_event.qmd` | `labs/lab1_data.R` | `solutions/lab1_data_solution.R` |
| 2 Kaplan-Meier curves, medians, landmarks, risk tables | `s2_kaplan_meier.qmd` | `labs/lab2_km.R` | `solutions/lab2_km_solution.R` |
| 3 Comparing survival: the log-rank test | `s3_logrank.qmd` | `labs/lab3_logrank.R` | `solutions/lab3_logrank_solution.R` |
| 4 Cox regression: hazard ratios, adjustment, prediction | `s4_cox_regression.qmd` | `labs/lab4_cox.R` | `solutions/lab4_cox_solution.R` |
| 5 Assumptions and reporting: PH, fixes, censoring, checklist | `s5_assumptions_reporting.qmd` | `labs/lab5_assumptions.R` | `solutions/lab5_assumptions_solution.R` |

Plus `cheatsheet.qmd` (2 pages, prints to A4). Suggested format: one full day (Sessions 1–3 in the morning, 4–5 after lunch), each session about 25 minutes of slides and 35 to 40 minutes of lab.
**Prerequisite:** the regression workshop (or equivalent): multiple regression and reading coefficients.

## Facilitator workflow

```r
Rscript survival-workshop/make_data.R              # regenerate data/tb_cohort.csv + feature check (stops if a teaching feature is lost)
Rscript survival-workshop/run_solutions.R          # run all five solutions (or: ... run_solutions.R 4 5)
Rscript survival-workshop/build_labs.R             # rebuild student labs from the solutions
Rscript regression-workshop/lint_quizzes.R survival-workshop/s*.qmd    # quiz quality gate (0 hard failures)
quarto render --profile advanced                   # build the site
node survival-workshop/tests/quiz_all.js docs/advanced/survival-workshop/s*.html     # browser quiz test (needs Playwright)
node survival-workshop/tests/overflow.js docs/advanced/survival-workshop/s*.html     # no slide runs off the page
```

### Editing a lab
Edit the **solution**, then run `build_labs.R`. In a solution: `code  #@ piece1 || piece2` blanks the **first occurrence** of each piece **on that line** (do not let a piece match inside a longer name); `#% text` is a facilitator-only line removed from the lab.

## R packages
`survival`, `ggsurvfit` (curves, risk tables), `broom`, `gtsummary`, `tidyverse`. Competing risks are only mentioned (`tidycmprsk`, `cmprsk`).

## Data features (verified by `make_data.R`)
About 19% die and the rest are censored (administrative end or lost to follow-up, with the reason recorded) · **median survival is not reached** (a teaching point) ·
HIV (HR about 2), MDR-TB (about 2.3), diabetes and age raise the hazard; DOT (about 0.57) and BMI lower it · **sex has no effect** (a null log-rank) ·
**smear-positive disease raises the hazard about threefold in the first 6 months and not afterwards, so proportional hazards is violated** (the Session 5 example) · no follow-up beyond about 24 months (survival at 24 months cannot be estimated).

## Next: the game
Once this workshop has been run and corrected, the Dungeons & Dataframes **Survival Summit** world (Region 4) will be built on it, with "Read first" links to the decks and code tasks.
