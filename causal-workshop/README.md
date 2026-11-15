# Causal Inference — workshop (A9)

Five reveal.js decks, five fill-in-the-blank R labs with facilitator solutions, self-check quizzes in every deck and a two-page cheat sheet.
Everything runs on one **synthetic observational programme evaluation** (`data/htn_programme.csv`: 3,000 adults with hypertension, 41% enrolled in a community health-worker programme), built by `make_data.R`. Both potential outcomes are simulated, so the true effects are known to the facilitator.
Part of the **advanced** profile (`quarto render --profile advanced`). Same pattern as the other advanced workshops.

| Session | Deck | Student lab | Facilitator solution |
|---|---|---|---|
| 1 Causal questions and DAGs | `s1_causal_questions_dags.qmd` | `labs/lab1_dag.R` | `solutions/lab1_dag_solution.R` |
| 2 Adjustment, bad controls and standardisation | `s2_adjustment_standardisation.qmd` | `labs/lab2_adjust.R` | `solutions/lab2_adjust_solution.R` |
| 3 Propensity scores and matching | `s3_propensity_matching.qmd` | `labs/lab3_match.R` | `solutions/lab3_match_solution.R` |
| 4 Inverse probability weighting | `s4_ipw.qmd` | `labs/lab4_ipw.R` | `solutions/lab4_ipw_solution.R` |
| 5 Sensitivity analysis and reporting | `s5_sensitivity_reporting.qmd` | `labs/lab5_sens.R` | `solutions/lab5_sens_solution.R` |

Plus `cheatsheet.qmd` (2 pages, A4). Packages: `dagitty`, `MatchIt`, `cobalt`, `EValue`, `sandwich`, `lmtest` (plus the tidyverse).

## Facilitator workflow

```r
Rscript causal-workshop/make_data.R            # regenerate data/htn_programme.csv + feature check (stops if a teaching feature is lost)
Rscript causal-workshop/run_solutions.R        # run all five solutions (or: ... run_solutions.R 3 4)
Rscript causal-workshop/build_labs.R           # rebuild student labs from the solutions
Rscript regression-workshop/lint_quizzes.R causal-workshop/s*.qmd   # quiz quality gate (0 hard failures required)
quarto render --profile advanced               # build the site
```

Editing a lab: edit the **solution**, then run `build_labs.R`. `code  #@ piece1 || piece2` blanks the first occurrence of each piece on that line; `#% text` lines are facilitator-only answers. **After changing code, re-run the solutions and check every `#%` answer against the real output.**

## Data features (verified by `make_data.R`)

* **Truth**: ATE −5.77 mmHg, ATT −6.17 mmHg (the effect grows with baseline SBP, and the enrolled have a higher baseline SBP).
* **Confounding by indication**: the enrolled are older, have a higher baseline SBP (157 vs 150) and more diabetes; the **naive difference is −1.4**.
* Confounder-adjusted regression −6.3 (CI −7.1 to −5.4); with the **mediator** (adherence) −3.0; with the **collider** (clinic visits) −8.8.
* Standardisation: ATE −6.2, ATT −6.6. Matching (1:1, caliper 0.2): 1,057 pairs, 172 enrolled unmatched, −5.9. IPW: −5.7; truncated −5.6; ATT weights −6.6; doubly robust −6.0.
* An **unmeasured** factor (motivation) leaves a residual bias of about 0.4 mmHg in every method. E-value for controlled BP (RR 1.57): 2.5, and 2.2 for the confidence limit.

## Quizzes
Same engine and lint as the other workshops. The master copy of the quiz engine is in `regression-workshop/assets/` (`scripts/sync_workshop_assets.sh`).

## Next
A game world (Region 4) is built **after** the workshop has been run and corrected. This is the last module of the planned advanced series (A10, advanced survival, is marked "later").
