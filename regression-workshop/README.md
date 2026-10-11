# Theory of Regression Analysis — full-day workshop

Six reveal.js decks, six fill-in-the-blank R labs, facilitator solutions, a reusable quiz engine and a cheat sheet.
Everything runs on one simulated adult NCD survey (`data/ncd_survey.csv`, n = 600, ~20 villages).
Part of the **regression** profile (`quarto render --profile regression`).

| Session | Deck | Student lab | Facilitator solution |
|---|---|---|---|
| 1 Foundations | `s1_foundations.qmd` | `labs/lab1_explore.R` | `solutions/lab1_explore_solution.R` |
| 2 Simple linear regression | `s2_simple_regression.qmd` | `labs/lab2_simple.R` | `solutions/lab2_simple_solution.R` |
| 3 Inference & multiple regression | `s3_multiple_regression.qmd` | `labs/lab3_multiple.R` | `solutions/lab3_multiple_solution.R` |
| 4 Assumptions | `s4_assumptions.qmd` | `labs/lab4_assumptions.R` | `solutions/lab4_assumptions_solution.R` |
| 5 Logistic regression | `s5_logistic_regression.qmd` | `labs/lab5_logistic.R` | `solutions/lab5_logistic_solution.R` |
| 6 Interpreting & reporting | `s6_reporting.qmd` | `labs/lab6_reporting.R` | `solutions/lab6_reporting_solution.R` |

Plus `cheatsheet.qmd` (2-page interpretation cheat sheet, prints to A4).

## Folder map

```
regression-workshop/
├── s1…s6_*.qmd, cheatsheet.qmd   decks / cheat sheet (reuse the repo's serif theme + assets/slide_deck.css)
├── make_data.R                   simulates the dataset, prints a feature check (set.seed(8))
├── labs/                         STUDENT scripts with ___ blanks  (generated — do not edit by hand)
├── solutions/                    FACILITATOR scripts (source of truth; never published to the site)
├── build_labs.R                  solutions/ -> labs/ generator
├── run_solutions.R               runs every solution end to end
└── assets/                       setup.R, workshop.css, cheatsheet.css, quiz.js, quiz.css, quiz.R, quiz-include.html
```

## Facilitator workflow

```r
Rscript regression-workshop/make_data.R        # regenerate data/ncd_survey.csv + feature check (stops if a teaching feature is lost)
Rscript regression-workshop/run_solutions.R    # run all six solutions (or: ... run_solutions.R 3 5)
Rscript regression-workshop/build_labs.R       # rebuild student labs from the solutions
quarto render --profile regression             # build the site (decks are self-contained, work offline)
```

### Editing a lab
Edit the **solution**, then run `build_labs.R`. In a solution:

* `code  #@ piece1 || piece2` — in the lab the first occurrence of each piece on that line becomes `___`
* `#% any text` — facilitator-only line (answers, notes); removed from the student lab

Hints in the lab must describe the *goal* and never name the function/argument/value that goes in the blank.

## Quizzes (`assets/quiz.js`)

Each deck ends with a 5–6 question self-check. Questions are written in plain text with R helpers
(`assets/quiz.R`), which emit a Pandoc fenced div carrying **salted hashes** (answers) and
**base64** (explanations) — so the answer is not readable in the page source:

```r
quiz_mcq("s1q1", "Which model suits a binary outcome?", c("Linear", "Logistic", "Cox"), answer = 2,
         explain = "Binary outcome -> logistic.")
quiz_fill("s1q4", "Which gtsummary function builds Table 1?", accept = c("tbl_summary", "tbl_summary()"),
          explain = "tbl_summary() summarises variables, optionally by a group.")
```

`quiz.js` needs no dependencies and works offline; the full syntax and hash scheme are documented in its header comment.
Hashing is an anti-peeking measure, not cryptography.

## Data features (verified by `make_data.R`)

Confounding (age, BMI → salt and SBP) · BMI/waist collinearity (VIF ≈ 10) · variance rising with age ·
mild age curvature · village clustering (ICC ≈ 0.06) · HTN prevalence ≈ 32% (OR ≠ PR) ·
~3% missing in `bmi`, `salt_g`, `education`.
