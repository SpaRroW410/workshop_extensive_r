# ═══════════════════════════════════════════════════════════════
# LAB 1 — Time-to-event data and censoring
# Survival analysis workshop | Session 1
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
# Goal: How many patients died and how many were censored? (status: 1 = died, 0 = censored)
___(tb$status)

# Q1. What fraction of patients is censored, and why can they not simply be dropped?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Give the percentage of patients who were censored.
round(100 * ___(tb$status == 0), 1)

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Among the censored patients, how many were lost to follow-up and
# how many were alive at the end of follow-up?
table(tb$___)

# Q3. Why does the reason for censoring matter for the analysis?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Build the survival object from follow-up time and the event indicator.
y <- ___(tb$time_months, tb$status)
head(y, 12)

# Q4. What does the + after a time mean?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: The WRONG way to summarise follow-up: the mean time of ALL patients.
# Compare it with the mean time of those who died.
c(all = ___(tb$time_months), died = mean(tb$time_months[tb$___ == 1]))

# Q5. Why is the mean follow-up time a poor summary of survival?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Total person-time at risk in person-YEARS (time is in months).
py <- ___(tb$time_months) / ___
round(py, 1)

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: The crude mortality RATE per 100 person-years: deaths / person-years x 100.
round(___(tb$status) / py * ___, 1)

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Median FOLLOW-UP time by the "reverse Kaplan-Meier" method: swap
# the meaning of event and censoring (1 - status).
rkm <- survfit(Surv(time_months, ___) ~ 1, data = tb)
summary(rkm)$table["median"]

# Q8. Why is the reverse Kaplan-Meier median a better description of follow-up than the median of the raw times?
