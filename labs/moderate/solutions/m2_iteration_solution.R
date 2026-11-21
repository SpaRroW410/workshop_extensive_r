# ═══════════════════════════════════════════════════════════════
# MODERATE LAB 2 — Iteration
# Medical Statistics in R · Moderate track · goes with: Iteration
# Replace every ___ with the missing code. Hints describe the GOAL, not the answer.
# Save this file next to a folder called data/ that holds the dataset(s) named below
# (download them from the track home), or open the workshop RStudio project.
# ═══════════════════════════════════════════════════════════════

suppressPackageStartupMessages({library(dplyr); library(readr); library(purrr)})
p <- c("data/ncd_survey.csv", "../data/ncd_survey.csv", "../../data/ncd_survey.csv"); p <- p[file.exists(p)][1]
ncd <- read_csv(p, show_col_types = FALSE)

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: The mean of sbp, dbp and bmi in one summarise() call, ignoring missing values.
ncd |> summarise(across(c(sbp, dbp, bmi), \(x) mean(x, na.rm = TRUE)))   #@ across
#% A: sbp 132, dbp 59.7, bmi 23.0

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: A loop that prints the median of each column whose name is in `vars`.
vars <- c("sbp", "dbp", "bmi")
for (v in vars) cat(v, median(ncd[[v]], na.rm = TRUE), "\n")       #@ ncd[[v]]

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: One Welch t-test per outcome (by sex), collected into one table.
map_dfr(vars, \(y) {                                               #@ map_dfr
  t <- t.test(reformulate("sex", y), data = ncd)
  tibble(outcome = y, p = t$p.value)
})

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: A function that returns the percentage of values at or above a cut-off.
pct_above <- function(x, cut) mean(x >= cut, na.rm = TRUE) * 100   #@ function
pct_above(c(1, 5, 10, 20), 10)                                     # check: should be 50
pct_above(ncd$sbp, 140)
#% A: 32% of people have SBP of 140 or more

# Q1. You ran a t-test for 12 outcomes. What should you keep in mind about the p-values?
#% A: about 1 in 20 tests is "significant" by chance; adjust (p.adjust) or pre-specify the main outcome.
