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
m0 <- glm(cases ~ ___, family = ___, data = dg)
exp(coef(m0))

# Q1. Why is this model not the right one for a rate?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Fit the same model WITH an offset for the log of the population, so that it models the RATE.
m1 <- glm(cases ~ fogging + ___(___), family = poisson, data = dg)
round(exp(coef(m1)), 3)

# Q2. How do you read exp() of the fogging coefficient in a model with an offset?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Rate ratio for fogging with its 95% CI.
exp(cbind(RR = coef(m1), ___(m1)))["foggingYes", ]

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Fit the ADJUSTED model: fogging, slum, rain in the previous month (rain_lag1), time trend (month_index) plus seasonality via sin and cos of month; keep the offset.
m2 <- glm(cases ~ fogging + slum + ___ + ___(2 * pi * month / 12) + cos(2 * pi * month / 12) + offset(log(population)), family = poisson, data = dg)
round(exp(coef(m2))[c("foggingYes", "slumSlum")], 2)

# Q4. Interpret the rate ratio for fogging in one sentence.

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Rate ratio per 100 mm more rain in the previous month.
exp(___ * coef(m2)["rain_lag1"])

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Predict the expected number of cases for a slum ward of 30,000 people, with no fogging, 150 mm of last month's rain, in month 20 (a July).
nd <- data.frame(fogging = factor("No", levels = c("No", "Yes")), slum = factor("Slum", levels = c("Non-slum", "Slum")), rain_lag1 = 150, month_index = 20, month = 7, population = 30000)
predict(m2, newdata = nd, ___ = "response")

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: A publication table of adjusted rate ratios.
tbl_regression(m2, ___ = TRUE)
