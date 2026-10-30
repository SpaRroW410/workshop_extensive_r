# ═══════════════════════════════════════════════════════════════
# LAB 5 — Checking assumptions and reporting
# Survival analysis workshop | Session 5
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

cox_full <- coxph(Surv(time_months, status) ~ age + sex + hiv + diabetes + smoker + bmi + mdr_tb + smear + treatment, data = tb)

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Test the proportional hazards assumption for every term with Schoenfeld residuals.
zph <- ___(cox_full)
zph

# Q1. Which variable violates proportional hazards, and how do you know?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Plot the Schoenfeld residuals for smear only (a flat line means proportional).
plot(___)
abline(h = 0, col = "red")

# Q2. What does a sloping curve tell you about the effect of smear status?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: See it directly: Kaplan-Meier curves by smear status, with the log-log plot on the
# next line (parallel lines would mean proportional hazards).
plot(survfit(Surv(time_months, status) ~ smear, data = tb), fun = "___", col = c("blue", "red"), xlab = "time (log scale)", ylab = "log(-log(S))")

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Fix 1: STRATIFY by smear status (a separate baseline hazard in each group;
# no HR is estimated for smear itself).
cox_strat <- coxph(Surv(time_months, status) ~ age + sex + hiv + diabetes + smoker + bmi + mdr_tb + treatment + ___(smear), data = tb)
round(exp(coef(cox_strat)), 2)

# Q4. When is stratification a good fix, and what do you lose?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Fix 2: split follow-up at 6 months and estimate a separate hazard ratio for smear
# in each period.
tb_split <- ___(Surv(time_months, status) ~ ., data = tb, ___ = 6, episode = "period")
tb_split$smear_pos <- as.numeric(tb_split$smear == "Positive")
cox_split <- coxph(Surv(tstart, time_months, status) ~ age + sex + hiv + diabetes + smoker + bmi + mdr_tb + treatment + ___, data = tb_split)
round(exp(coef(cox_split))[c("smear_pos:factor(period)1", "smear_pos:factor(period)2")], 2)

# Q5. Report the two smear hazard ratios in one sentence.

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Is censoring plausibly uninformative? Compare the proportion lost to
# follow-up by HIV status.
tb |> ___(hiv) |> summarise(pct_lost = round(100 * mean(censor_reason %in% "Lost to follow-up"), 1))

# Q6. Why does informative censoring bias a Kaplan-Meier estimate?

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Final results table (smear removed from the main model because of the PH violation).
tbl_regression(cox_strat, ___ = TRUE)
