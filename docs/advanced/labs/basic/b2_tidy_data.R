# ═══════════════════════════════════════════════════════════════
# BASIC LAB 2 — Tidy data with dplyr
# Medical Statistics in R · Basic track · goes with: Data Wrangling (Tidyverse) and Practice Slides
# Replace every ___ with the missing code. Hints describe the GOAL, not the answer.
# Save this file next to a folder called data/ that holds the dataset(s) named below
# (download them from the track home), or open the workshop RStudio project.
# ═══════════════════════════════════════════════════════════════

suppressPackageStartupMessages(library(dplyr))
p <- c("data/ncd_survey.csv", "../data/ncd_survey.csv", "../../data/ncd_survey.csv"); p <- p[file.exists(p)][1]
ncd <- read.csv(p)

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Keep only the columns id, age, sex, bmi and sbp.
small <- ncd |> ___(id, age, sex, bmi, sbp)
head(small)

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Keep only the adults aged 40 or older.
over40 <- ncd |> ___(age >= 40)
nrow(over40)

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Add a column "high_sbp" that is TRUE when systolic BP is 140 or more.
ncd <- ncd |> ___(high_sbp = sbp >= 140)
table(ncd$high_sbp)

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Mean systolic BP and number of people, by sex.
ncd |> ___(sex) |> ___(n = n(), mean_sbp = mean(sbp))

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: BMI has missing values. Mean BMI by residence, ignoring the missing values.
ncd |> group_by(residence) |> summarise(mean_bmi = mean(bmi, ___))
sum(is.na(ncd$bmi))

# Q1. What would mean(bmi) return without na.rm = TRUE, and why is that useful rather than annoying?
