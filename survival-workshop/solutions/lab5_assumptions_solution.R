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
zph <- cox.zph(cox_full)                                            #@ cox.zph
zph
#% A (Q1): smear has a very small p-value (about 0.0001): its effect is not constant over time. The global test is significant. Age and BMI show marginal p-values (about 0.02 and 0.05): with nine terms tested, borderline results can be chance, so look at the plots before acting.

# Q1. Which variable violates proportional hazards, and how do you know?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Plot the Schoenfeld residuals for smear only (a flat line means proportional).
plot(zph[6])                                                        #@ zph[6]
abline(h = 0, col = "red")
#% A (Q2): the smoothed curve slopes down: the log hazard ratio for smear changes over time (large early, near 0 or negative later).

# Q2. What does a sloping curve tell you about the effect of smear status?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: See it directly: Kaplan-Meier curves by smear status, with the log-log plot on the
# next line (parallel lines would mean proportional hazards).
plot(survfit(Surv(time_months, status) ~ smear, data = tb), fun = "cloglog", col = c("blue", "red"), xlab = "time (log scale)", ylab = "log(-log(S))")   #@ cloglog

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Fix 1: STRATIFY by smear status (a separate baseline hazard in each group;
# no HR is estimated for smear itself).
cox_strat <- coxph(Surv(time_months, status) ~ age + sex + hiv + diabetes + smoker + bmi + mdr_tb + treatment + strata(smear), data = tb)   #@ strata
round(exp(coef(cox_strat)), 2)
#% A (Q4): the other HRs are almost unchanged.

# Q4. When is stratification a good fix, and what do you lose?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Fix 2: split follow-up at 6 months and estimate a separate hazard ratio for smear
# in each period.
tb_split <- survSplit(Surv(time_months, status) ~ ., data = tb, cut = 6, episode = "period")   #@ survSplit || cut
tb_split$smear_pos <- as.numeric(tb_split$smear == "Positive")
cox_split <- coxph(Surv(tstart, time_months, status) ~ age + sex + hiv + diabetes + smoker + bmi + mdr_tb + treatment + smear_pos:factor(period), data = tb_split)   #@ smear_pos:factor(period)
round(exp(coef(cox_split))[c("smear_pos:factor(period)1", "smear_pos:factor(period)2")], 2)
#% A (Q5): the smear HR is about 3 in the first 6 months and about 0.6 afterwards, so a single HR hides a reversal.

# Q5. Report the two smear hazard ratios in one sentence.

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Is censoring plausibly uninformative? Compare the proportion lost to
# follow-up by HIV status.
tb |> group_by(hiv) |> summarise(pct_lost = round(100 * mean(censor_reason %in% "Lost to follow-up"), 1))   #@ group_by
#% A (Q6): about 17% and 16%: similar in the two groups here. If the sickest patients were lost, censoring would be informative and the curves optimistic.

# Q6. Why does informative censoring bias a Kaplan-Meier estimate?

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Final results table (smear removed from the main model because of the PH violation).
tbl_regression(cox_strat, exponentiate = TRUE)                      #@ exponentiate
