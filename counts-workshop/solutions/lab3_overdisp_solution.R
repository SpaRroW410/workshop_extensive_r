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
sum(residuals(m2, type = "pearson")^2) / df.residual(m2)            #@ pearson || df.residual
#% A (Q1): about 8: severe overdispersion. The Poisson standard errors are too small by about the square root of the dispersion (a factor of 2.8), so p-values and CIs are far too optimistic.

# Q1. What does a dispersion of 8 mean for the standard errors and p-values of the Poisson model?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: The same check with a function from the performance package.
check_overdispersion(m2)                                            #@ check_overdispersion

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Fit a QUASI-Poisson model (same coefficients, standard errors scaled by the dispersion).
m_q <- glm(formula(m2), family = quasipoisson, data = dg)           #@ quasipoisson
round(summary(m_q)$dispersion, 1)
round(cbind(Poisson_SE = summary(m2)$coefficients[, 2], Quasi_SE = summary(m_q)$coefficients[, 2])[2:3, ], 3)
#% A (Q3): the point estimates are identical, and the standard errors are about 2.8 times larger (the square root of the dispersion).

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Fit a NEGATIVE BINOMIAL model (MASS::glm.nb) with the same formula.
m_nb <- MASS::glm.nb(formula(m2), data = dg)                        #@ glm.nb
round(m_nb$theta, 2)
#% A (Q4): theta about 1.4: the lower theta, the more overdispersion (variance = mu + mu^2 / theta).

# Q4. What does the dispersion parameter theta represent?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Compare Poisson and negative binomial by AIC.
AIC(m2, m_nb)                                                       #@ AIC
#% A (Q5): the negative binomial AIC is about 4,900 points lower (5,898 vs 10,745): it fits far better.

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Fogging rate ratio with 95% CI from the negative binomial model.
exp(cbind(RR = coef(m_nb), confint.default(m_nb)))["foggingYes", ]  #@ foggingYes
#% A: about 0.66 (0.54 to 0.80): the rate ratio is close to the Poisson one (0.64) but the CI is about three times wider.

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Poisson with ROBUST standard errors clustered by ward (the same ward is measured 36 times).
coeftest(m2, vcov = vcovCL(m2, cluster = dg$ward))                  #@ vcovCL || cluster
#% A (Q7): the robust standard error for fogging is about 0.12 vs 0.03 naive: repeated months in the same ward are correlated, so there is less information than 1,080 independent observations.

# Q7. Why cluster the standard errors by ward?
