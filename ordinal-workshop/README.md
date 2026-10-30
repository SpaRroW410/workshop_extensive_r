# Ordinal and multinomial outcomes — workshop

Five reveal.js decks, five fill-in-the-blank R labs with facilitator solutions, a self-check quiz in every deck and a two-page cheat sheet.
Everything runs on one **synthetic maternal health survey** (`data/maternal_survey.csv`: 1,500 women, built by `ordinal-workshop/make_data.R`; no real women).
Part of the **advanced** profile ("Advanced Analysis" branch, module A3 in `SITE_PLAN.md`): `quarto render --profile advanced`.
Same pattern as the regression, GIS, survival and counts workshops.

| Session | Deck | Student lab | Facilitator solution |
|---|---|---|---|
| 1 Categorical outcomes: nominal or ordered? | `s1_categorical_outcomes.qmd` | `labs/lab1_outcomes.R` | `solutions/lab1_outcomes_solution.R` |
| 2 Ordinal logistic regression (proportional odds) | `s2_ordinal_logistic.qmd` | `labs/lab2_ordinal.R` | `solutions/lab2_ordinal_solution.R` |
| 3 Checking proportional odds (Brant, partial PO) | `s3_proportional_odds_check.qmd` | `labs/lab3_po.R` | `solutions/lab3_po_solution.R` |
| 4 Multinomial logistic regression | `s4_multinomial_logistic.qmd` | `labs/lab4_multinom.R` | `solutions/lab4_multinom_solution.R` |
| 5 Choosing, comparing and reporting | `s5_choosing_reporting.qmd` | `labs/lab5_report.R` | `solutions/lab5_report_solution.R` |

Plus `cheatsheet.qmd` (2 pages, prints to A4). Suggested format: one full day. **Prerequisite:** the regression workshop (logistic regression, odds ratios).

## Facilitator workflow

```r
Rscript ordinal-workshop/make_data.R              # regenerate data/maternal_survey.csv + feature check (stops if a teaching feature is lost)
Rscript ordinal-workshop/run_solutions.R          # run all five solutions (or: ... run_solutions.R 3 4)
Rscript ordinal-workshop/build_labs.R             # rebuild student labs from the solutions
Rscript regression-workshop/lint_quizzes.R ordinal-workshop/s*.qmd    # quiz quality gate (0 hard failures)
quarto render --profile advanced                  # build the site
node ordinal-workshop/tests/quiz_all.js docs/advanced/ordinal-workshop/s*.html     # browser quiz test (needs Playwright)
node ordinal-workshop/tests/overflow.js docs/advanced/ordinal-workshop/s*.html     # no slide runs off the page
```

**When you edit a quiz option list, check the marked answer**: `answer =` is the position of the correct option, so move the key text to that position (the same slip once marked wrong answers correct in the counts workshop).
Editing a lab: edit the **solution**, then `build_labs.R` (`code  #@ piece1 || piece2` blanks the first occurrence of each piece on that line; `#% text` is facilitator-only).

## R packages
`MASS` (`polr`), `nnet` (`multinom`), `ordinal` (`clm` with `nominal =`), `brant` (the test), `broom`, `gtsummary`, `tidyverse`. `VGAM` is installed for follow-up work (`vglm`, parallel = FALSE).

## Data features (verified by `make_data.R`)
Anaemia is ordered (None 54%, Mild 27%, Moderate 12%, Severe 7%); **no sparse categories** · wealth, education, BMI and antenatal visits are protective with a **proportional-odds** structure (OR about 0.76 per wealth quintile adjusted, 0.57 unadjusted) ·
**tribal group violates proportional odds**: almost no effect on mild anaemia, a large one on severe (cut-point ORs about 1.1, 1.0, 3.2; Brant p about 0; single OR about 1.1) ·
place of delivery is nominal (Home 27%, PHC 30%, Public 33%, Private 10%): wealth, education and antenatal visits raise institutional delivery, wealth most strongly towards **private** care, rural residence lowers private care.

## Next: the game
Once this workshop has been run and corrected, a Dungeons & Dataframes **Ordinal and Nominal Outcomes** world (Region 4) will be built on it.
