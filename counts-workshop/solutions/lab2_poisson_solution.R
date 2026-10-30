# ═══════════════════════════════════════════════════════════════
# LAB 2 — Poisson regression and rate ratios
# Counts and rates workshop | Session 2
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(broom); library(gtsummary); library(sandwich); library(lmtest); library(performance); library(pscl) })
theme_set(theme_minimal(base_size = 14))

dg_path <- c("data/dengue_wards.csv", "../data/dengue_wards.csv", "../../data/dengue_wards.csv")
dg_path <- dg_path[file.exists(dg_path)][1]
dg <- read_csv(dg_path, show_col_types = FALSE) |> mutate(slum = factor(slum, 0:1, c("Non-slum", "Slum")), fogging = factor(fogging, 0:1, c("No", "Yes")))
dg$ward <- factor(dg$ward)

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Fit a Poisson regression of cases on fogging, ignoring population. Store as m0.
m0 <- glm(cases ~ fogging, family = poisson, data = dg)             #@ poisson || fogging
exp(coef(m0))
#% A (Q1): the "rate ratio" here compares MEAN COUNTS per ward-month, not rates: wards differ greatly in population, so without an offset the comparison mixes population size with risk.

# Q1. Why is this model not the right one for a rate?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Fit the same model WITH an offset for the log of the population, so that it models the RATE.
m1 <- glm(cases ~ fogging + offset(log(population)), family = poisson, data = dg)   #@ offset || log(population)
round(exp(coef(m1)), 3)
#% A (Q2): exp(intercept) is the baseline rate per person-month (a tiny number, about 0.0003); exp(fogging coefficient) is the RATE RATIO (here about 0.86, crude).

# Q2. How do you read exp() of the fogging coefficient in a model with an offset?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Rate ratio for fogging with its 95% CI.
exp(cbind(RR = coef(m1), confint.default(m1)))["foggingYes", ]      #@ confint.default
#% A: crude RR about 0.86 (95% CI 0.82 to 0.91). It is only a crude comparison: fogging started in month 25 (a later, higher-incidence period), so adjustment for trend and season matters.

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Fit the ADJUSTED model: fogging, slum, rain in the previous month (rain_lag1), time trend (month_index) plus seasonality via sin and cos of month; keep the offset.
m2 <- glm(cases ~ fogging + slum + rain_lag1 + month_index + sin(2 * pi * month / 12) + cos(2 * pi * month / 12) + offset(log(population)), family = poisson, data = dg)   #@ rain_lag1 + month_index || sin
round(exp(coef(m2))[c("foggingYes", "slumSlum")], 2)
#% A (Q4): fogging RR about 0.64 (about 36% lower dengue rate, adjusted for ward type, rain, trend and season); slum RR about 1.7.

# Q4. Interpret the rate ratio for fogging in one sentence.

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Rate ratio per 100 mm more rain in the previous month.
exp(100 * coef(m2)["rain_lag1"])                                    #@ 100
#% A (Q5): about 1.3: each extra 100 mm of rain in the previous month goes with about 31% higher dengue rate.

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Predict the expected number of cases for a slum ward of 30,000 people, with no fogging, 150 mm of last month's rain, in month 20 (a July).
nd <- data.frame(fogging = factor("No", levels = c("No", "Yes")), slum = factor("Slum", levels = c("Non-slum", "Slum")), rain_lag1 = 150, month_index = 20, month = 7, population = 30000)
predict(m2, newdata = nd, type = "response")                        #@ type
#% A: about 29 cases: type = "response" gives expected counts (not log rates), including the offset.

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: A publication table of adjusted rate ratios.
tbl_regression(m2, exponentiate = TRUE)                             #@ exponentiate
