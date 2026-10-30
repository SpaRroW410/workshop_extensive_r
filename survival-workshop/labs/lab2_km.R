# ═══════════════════════════════════════════════════════════════
# LAB 2 — Kaplan-Meier survival curves
# Survival analysis workshop | Session 2
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
# Goal: Fit the overall Kaplan-Meier curve: time and event on the left, 1 on the right.
km <- ___(Surv(time_months, status) ~ ___, data = tb)
km

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Survival probability (with 95% CI) at 6, 12 and 18 months. (No one is followed
# beyond about 24 months, so R cannot report survival at 24.)
summary(km, ___ = c(6, 12, 18))

# Q2. Read the survival probability at 12 months and explain it in one sentence.

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: What is the median survival time? Why is it not reported?
summary(km)$table["___"]

# Q3. Why is the median survival NA?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Plot the overall curve with its confidence band.
___(km) + ___()

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Fit separate curves by HIV status.
km_grp <- survfit(Surv(time_months, status) ~ ___, data = tb)
km_grp

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Survival at 12 months in each HIV group.
summary(km_grp, times = 12)$___

# Q6. Which group does better by 12 months, and by how much?

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Plot both curves with a risk table underneath.
ggsurvfit(km_grp) + ___()

# Q7. What does the risk table show, and why look at it?

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Convert survival to the cumulative probability of dying by 18 months (1 - S).
___ summary(km, times = 18)$surv
