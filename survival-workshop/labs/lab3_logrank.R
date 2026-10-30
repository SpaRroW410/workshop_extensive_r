# ═══════════════════════════════════════════════════════════════
# LAB 3 — Comparing survival curves: the log-rank test
# Survival analysis workshop | Session 3
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(survival); library(broom); library(gtsummary); library(ggsurvfit) })
theme_set(theme_minimal(base_size = 14))

tb_path <- c("data/tb_cohort.csv", "../data/tb_cohort.csv", "../../data/tb_cohort.csv")
tb_path <- tb_path[file.exists(tb_path)][1]
tb <- read_csv(tb_path, show_col_types = FALSE) |>
  mutate(sex = factor(sex, levels = c("Female", "Male")), hiv = factor(hiv, levels = c("Negative", "Positive")),
         diabetes = factor(diabetes, levels = c("No", "Yes")), smoker = factor(smoker, levels = c("No", "Yes")),
         mdr_tb = factor(mdr_tb, levels = c("No", "Yes")), smear = factor(smear, levels = c("Negative", "Positive")),
         treatment = factor(treatment, levels = c("Self-administered", "DOT")))

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Log-rank test of survival by HIV status.
lr1 <- ___(Surv(time_months, status) ~ ___, data = tb)
lr1

# Q1. What does the log-rank test compare, and what is its null hypothesis?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Extract the p-value from the test object.
1 - ___(lr1$___, df = 1)

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Compare observed and expected deaths in each HIV group.
cbind(observed = lr1[[___]], expected = round(lr1[[___]], 1))

# Q3. How do the observed and expected deaths show the direction of the difference?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Log-rank test by sex. Is there evidence of a difference?
survdiff(Surv(time_months, status) ~ ___, data = tb)

# Q4. Does p = 0.6 prove that men and women have the same survival?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Log-rank test of survival by MDR-TB status.
survdiff(Surv(time_months, status) ~ ___, data = tb)

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: A log-rank test of HIV status STRATIFIED by treatment arm (compare within DOT and
# self-administered patients, then combine).
survdiff(Surv(time_months, status) ~ hiv + ___(treatment), data = tb)

# Q6. Why stratify a log-rank test?

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: The WRONG test: a t-test of follow-up time by HIV status ignores censoring.
# Get its p-value.
___(___ ~ hiv, data = tb)$p.value

# Q7. What goes wrong when a t-test is used on survival times?

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Plot the Kaplan-Meier curves by treatment arm.
___(Surv(time_months, status) ~ treatment, data = tb) |> ___()
