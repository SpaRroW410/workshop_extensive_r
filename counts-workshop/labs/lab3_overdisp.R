# ═══════════════════════════════════════════════════════════════
# LAB 3 — Overdispersion: quasi-Poisson and negative binomial
# Counts and rates workshop | Session 3
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(broom); library(gtsummary); library(sandwich); library(lmtest); library(performance); library(pscl) })
theme_set(theme_minimal(base_size = 14))

dg_path <- c("data/dengue_wards.csv", "../data/dengue_wards.csv", "../../data/dengue_wards.csv")
dg_path <- dg_path[file.exists(dg_path)][1]
dg <- read_csv(dg_path, show_col_types = FALSE) |> mutate(slum = factor(slum, 0:1, c("Non-slum", "Slum")), fogging = factor(fogging, 0:1, c("No", "Yes")))
dg$ward <- factor(dg$ward)

m2 <- glm(cases ~ fogging + slum + rain_lag1 + month_index + sin(2 * pi * month / 12) + cos(2 * pi * month / 12) + offset(log(population)), family = poisson, data = dg)

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Dispersion statistic: sum of squared Pearson residuals / residual df. About 1 for a good Poisson fit.
sum(residuals(m2, type = "___")^2) / ___(m2)

# Q1. What does a dispersion of 8 mean for the standard errors and p-values of the Poisson model?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: The same check with a function from the performance package.
___(m2)

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Fit a QUASI-Poisson model (same coefficients, standard errors scaled by the dispersion).
m_q <- glm(formula(m2), family = ___, data = dg)
round(summary(m_q)$dispersion, 1)
round(cbind(Poisson_SE = summary(m2)$coefficients[, 2], Quasi_SE = summary(m_q)$coefficients[, 2])[2:3, ], 3)

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Fit a NEGATIVE BINOMIAL model (MASS::glm.nb) with the same formula.
m_nb <- MASS::___(formula(m2), data = dg)
round(m_nb$theta, 2)

# Q4. What does the dispersion parameter theta represent?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Compare Poisson and negative binomial by AIC.
___(m2, m_nb)

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Fogging rate ratio with 95% CI from the negative binomial model.
exp(cbind(RR = coef(m_nb), confint.default(m_nb)))["___", ]

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Poisson with ROBUST standard errors clustered by ward (the same ward is measured 36 times).
coeftest(m2, vcov = ___(m2, ___ = dg$ward))

# Q7. Why cluster the standard errors by ward?
