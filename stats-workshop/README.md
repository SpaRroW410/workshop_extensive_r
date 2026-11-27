# Statistical analysis — workshop

Five reveal.js decks, five fill-in-the-blank R labs with facilitator solutions, a self-check quiz in every deck and a two-page cheat sheet.
It takes the tests of the Basic track's **Test Selection Guide** and **Data Analysis** pages (and the facilitator script `data_analysis.R`)
and adds what those pages leave out: **checking assumptions** properly and **interpreting** each result (effect size, 95% CI, a sentence to write).
Everything runs on the **same practice dataset** as the Data Analysis page: `data/prac_modded.xlsx` (631 adults, 26 variables).
Track: **Statistical Analysis** (`quarto render --profile statistics`). Same pattern as `regression-workshop/` and the A1–A9 workshops.

| Session | Deck | Student lab | Facilitator solution |
|---|---|---|---|
| 1 Know your data, choose your test | `s1_know_your_data.qmd` | `labs/lab1_describe.R` | `solutions/lab1_describe_solution.R` |
| 2 Checking assumptions | `s2_assumptions.qmd` | `labs/lab2_assumptions.R` | `solutions/lab2_assumptions_solution.R` |
| 3 Categorical outcomes: chi-square, Fisher, McNemar | `s3_categorical.qmd` | `labs/lab3_categorical.R` | `solutions/lab3_categorical_solution.R` |
| 4 Two groups: t-tests, Mann–Whitney, Wilcoxon | `s4_two_groups.qmd` | `labs/lab4_two_groups.R` | `solutions/lab4_two_groups_solution.R` |
| 5 More groups, repeated measures, correlation, reporting | `s5_groups_correlation_reporting.qmd` | `labs/lab5_more_groups.R` | `solutions/lab5_more_groups_solution.R` |

Plus `cheatsheet.qmd` (2 pages, prints to A4). Suggested format: one full day (Sessions 1–3 in the morning, 4–5 after lunch).
**Prerequisite:** R basics (Basic track: Getting Started, Data Wrangling).

## What this workshop corrects in the earlier material

| Earlier material | Here |
|---|---|
| `ks.test(x, "pnorm")` | compares with mean 0, SD 1, so it rejects any real variable; use `nortest::lillie.test()` |
| Shapiro–Wilk on a random 50 rows | the verdict changes with the draw; check the right thing (differences, residuals) with plots |
| z-test when n > 30 | t-test whenever the SD comes from the sample |
| Levene first, then `var.equal = TRUE` | Welch by default |
| `pairwise.t.test()` after repeated-measures ANOVA | must have `paired = TRUE`; Mauchly / Greenhouse–Geisser added |
| "≥ 5 in ≥ 75% of cells" | Cochran: ≥ 80% of **expected** counts ≥ 5 and none < 1; Fisher for a 2 × 2 with any below 5 |
| `chisq.test(table_htn_gender)` | that object never existed; the table is built in the lab |

## Data notes (shown to participants in Session 1)

The blood pressure columns have recording problems: 104 adults with SBP below DBP, a median DBP of 108 mmHg, follow-up SBP
from 38 to 387 mmHg. They are kept on purpose for the rank-based tests and the "check before you test" lesson; the parametric
examples use the cleaner variables (height, weight, fasting glucose, age). In this practice file the three visits are barely
correlated, so paired and unpaired intervals come out similar; the decks say so.

## Facilitator workflow

```r
Rscript stats-workshop/run_solutions.R          # run all five solutions (or: ... run_solutions.R 3 4)
Rscript stats-workshop/build_labs.R             # rebuild student labs from the solutions
Rscript regression-workshop/lint_quizzes.R stats-workshop/s*.qmd    # quiz quality gate (0 hard failures)
quarto render --profile statistics              # build the track
node stats-workshop/tests/quiz_all.js docs/statistics/stats-workshop/s*.html     # browser quiz test (needs Playwright)
node stats-workshop/tests/overflow.js docs/statistics/stats-workshop/s*.html     # no slide runs off the page
```

Editing a lab: edit the **solution**, then `build_labs.R`. `code  #@ piece1 || piece2` blanks the first occurrence of each piece **on that line**; `#% text` is facilitator-only.

## R packages
`tidyverse`, `readxl`, `janitor`, `rstatix`, `effectsize`, `car`, `nortest` (Lilliefors, Anderson–Darling), `exact2x2` (exact McNemar).
