# Survey Data and Weights — workshop (A5)

Five reveal.js decks, five fill-in-the-blank R labs with facilitator solutions, self-check quizzes in every deck and a two-page cheat sheet.
Everything runs on one **synthetic adult health survey** (`data/survey_adults.csv`: two-stage stratified sample, 8 strata × 6 PSUs, 2,504 adults sampled, 1,853 respondents) plus the known population margins in `data/survey_population.csv`, both built by `make_data.R`.
Part of the **advanced** profile (`quarto render --profile advanced`). Same pattern as the other advanced workshops.

| Session | Deck | Student lab | Facilitator solution |
|---|---|---|---|
| 1 Survey design and weights | `s1_survey_design.qmd` | `labs/lab1_design.R` | `solutions/lab1_design_solution.R` |
| 2 Descriptive estimates | `s2_descriptive.qmd` | `labs/lab2_describe.R` | `solutions/lab2_describe_solution.R` |
| 3 Regression with survey data | `s3_survey_regression.qmd` | `labs/lab3_regression.R` | `solutions/lab3_regression_solution.R` |
| 4 Nonresponse, raking and replicate weights | `s4_nonresponse_raking.qmd` | `labs/lab4_weights.R` | `solutions/lab4_weights_solution.R` |
| 5 Choosing, checking and reporting | `s5_choose_check_report.qmd` | `labs/lab5_report.R` | `solutions/lab5_report_solution.R` |

Plus `cheatsheet.qmd` (2 pages, A4). Packages: `survey`, `srvyr` (plus the tidyverse).

## Facilitator workflow

```r
Rscript survey-workshop/make_data.R            # regenerate the data + feature check (stops if a teaching feature is lost)
Rscript survey-workshop/run_solutions.R        # run all five solutions (or: ... run_solutions.R 3 4)
Rscript survey-workshop/build_labs.R           # rebuild student labs from the solutions
Rscript regression-workshop/lint_quizzes.R survey-workshop/s*.qmd   # quiz quality gate (0 hard failures required)
quarto render --profile advanced               # build the site
```

Editing a lab: edit the **solution**, then run `build_labs.R`. `code  #@ piece1 || piece2` blanks the first occurrence of each piece on that line; `#% text` lines are facilitator-only answers. **After changing code, re-run the solutions and check every `#%` answer against the real output.**

## Data features (verified by `make_data.R`)

Urban strata are over-sampled (50% of the sample, 28% of the population) and have more hypertension, so the **unweighted** prevalence (23.3%) is biased against the weighted one (20.0%; true population value 20.7%) · clustering plus unequal weights give a design effect of about 2.6 for hypertension (naive SE 0.0098 vs design SE 0.0149) · response is 74% overall (men 69%, women 79%) and lower for young and more educated adults, so weights are adjusted in age × sex × residence cells and can be raked to the population margins · small subgroups (e.g. diabetes under age 45) leave strata with a single PSU (lonely PSUs) · a bootstrap replicate design reproduces the Taylor SE.

## Quizzes
Same engine and lint as the other workshops (correct option never the longest, no absolutes only in distractors, every question explained, shuffled at run time).

## Next
A game world (Region 4) is built **after** the workshop has been run and corrected. Next module: A6 curves and non-linearity.
