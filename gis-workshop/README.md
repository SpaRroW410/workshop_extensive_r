# GIS and Spatial Statistics — workshop

Five reveal.js decks, five fill-in-the-blank R labs with facilitator solutions, self-check quizzes in every deck and a two-page cheat sheet.
Everything runs on one **synthetic district** (`data/gis/district_blocks.geojson`, 79 blocks; `data/gis/facilities.csv`, 30 points), built by `gis/make_gis_data.R`.
Part of the **gis** profile (`quarto render --profile gis`), which also carries the advanced visualization pages and the seven reference pages in `gis/`.
It follows the same pattern as `regression-workshop/` (decks, labs, solutions, quiz engine, cheat sheet).

| Session | Deck | Student lab | Facilitator solution |
|---|---|---|---|
| 1 Spatial data and maps | `s1_spatial_data.qmd` | `labs/lab1_data.R` | `solutions/lab1_data_solution.R` |
| 2 Neighbours and spatial weights | `s2_neighbours_weights.qmd` | `labs/lab2_weights.R` | `solutions/lab2_weights_solution.R` |
| 3 Global spatial autocorrelation (Moran's I, Geary's C, G, join counts) | `s3_global_autocorrelation.qmd` | `labs/lab3_global.R` | `solutions/lab3_global_solution.R` |
| 4 Local clusters (LISA, Gi*, scan statistic) | `s4_local_clusters.qmd` | `labs/lab4_local.R` | `solutions/lab4_local_solution.R` |
| 5 Spatial regression and reporting | `s5_spatial_regression.qmd` | `labs/lab5_regression.R` | `solutions/lab5_regression_solution.R` |

Plus `cheatsheet.qmd` (2-page, prints to A4). Suggested format: one 3-hour half-day (Sessions 1 to 3) and a second half-day (Sessions 4 and 5), each session about 25 minutes of slides and 35 minutes of lab.

## Facilitator workflow

```r
Rscript gis/make_gis_data.R                    # regenerate data/gis/* + feature check (stops if a teaching feature is lost)
Rscript gis-workshop/run_solutions.R           # run all five solutions (or: ... run_solutions.R 3 4)
Rscript gis-workshop/build_labs.R              # rebuild student labs from the solutions
Rscript regression-workshop/lint_quizzes.R gis-workshop/s*.qmd     # quiz quality gate (0 hard failures required)
quarto render --profile gis                    # build the site (decks are self-contained)
```

### Editing a lab
Edit the **solution**, then run `build_labs.R`. In a solution:

* `code  #@ piece1 || piece2` — in the lab the first occurrence of each piece on that line becomes `___` (all pieces must be on that line)
* `#% any text` — facilitator-only line (answers, notes); removed from the student lab

Hints must describe the goal and never name the function, argument or value that goes in the blank.

## Quizzes
Same engine as the regression workshop (`assets/quiz.R`, `quiz.js`, `quiz.css` are copies). Questions follow the quiz standards in `regression-workshop/lint_quizzes.R`:
the correct option is never the longest, no "all of the above", every question explained, shuffled at run time.

## Data features (verified by `gis/make_gis_data.R`)

Positive spatial autocorrelation of dengue incidence (Moran's I about 0.5) · a **hot spot** in the south-east · a **cold spot** in the north-west · one **High-Low outlier** inside the cold area ·
poverty smooth in space, with residual autocorrelation after OLS · every block has at least one neighbour (no isolates) · `high_burden` for join counts · case counts and populations for the scan statistic.

## Next: the game
Once this workshop has been run and corrected, the Dungeons & Dataframes **GIS region** will be built on it (worlds tagged to these sessions; "Read first" links to the decks).
