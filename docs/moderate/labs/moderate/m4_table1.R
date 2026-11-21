# ═══════════════════════════════════════════════════════════════
# MODERATE LAB 4 — Table 1
# Medical Statistics in R · Moderate track · goes with: gtsummary and ggstatsplot (intermediate)
# Replace every ___ with the missing code. Hints describe the GOAL, not the answer.
# Save this file next to a folder called data/ that holds the dataset(s) named below
# (download them from the track home), or open the workshop RStudio project.
# ═══════════════════════════════════════════════════════════════

suppressPackageStartupMessages({library(dplyr); library(readr); library(gtsummary)})
p <- c("data/ncd_survey.csv", "../data/ncd_survey.csv", "../../data/ncd_survey.csv"); p <- p[file.exists(p)][1]
ncd <- read_csv(p, show_col_types = FALSE) |> mutate(htn = factor(htn, 0:1, c("No", "Yes")))

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: A Table 1 of age, sex, BMI and tobacco, with one column per hypertension group.
t1 <- ncd |> select(age, sex, bmi, tobacco, htn) |> ___(___)
t1

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Show the median (IQR) for the numbers and n (%) for the categories, and add a total column.
t2 <- ncd |> select(age, sex, bmi, tobacco, htn) |>
  tbl_summary(by = htn, statistic = list(all_continuous() ~ "{median} ({p25}, {p75})",
                                         all_categorical() ~ "{n} ({p}%)")) |>
  ___()
t2

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Add a p-value per variable (this is an observational survey, so they are descriptive).
t2 |> ___()

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: A logistic model of hypertension on age and BMI, shown as odds ratios.
m <- glm(htn ~ age + bmi, data = ncd, family = binomial)
tbl_regression(m, ___)

# Q1. Why would you NOT add p-values to Table 1 of a randomised trial?
