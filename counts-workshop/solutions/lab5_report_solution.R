# ═══════════════════════════════════════════════════════════════
# LAB 5 — Reporting, predictions and extensions
# Counts and rates workshop | Session 5
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(broom); library(gtsummary); library(sandwich); library(lmtest); library(performance); library(pscl) })
theme_set(theme_minimal(base_size = 14))

dg_path <- c("data/dengue_wards.csv", "../data/dengue_wards.csv", "../../data/dengue_wards.csv")
dg_path <- dg_path[file.exists(dg_path)][1]
dg <- read_csv(dg_path, show_col_types = FALSE) |> mutate(slum = factor(slum, 0:1, c("Non-slum", "Slum")), fogging = factor(fogging, 0:1, c("No", "Yes")))
dg$ward <- factor(dg$ward)

f <- cases ~ fogging + slum + rain_lag1 + month_index + sin(2 * pi * month / 12) + cos(2 * pi * month / 12) + offset(log(population))
m_nb <- MASS::glm.nb(f, data = dg)

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Adjusted rate ratios with 95% CI for fogging and slum, rounded to 2 decimals.
round(exp(cbind(RR = coef(m_nb), confint.default(m_nb)))[c("foggingYes", "slumSlum"), ], 2)   #@ confint.default
#% A: fogging about 0.66 (0.54 to 0.80); slum about 1.53 (1.35 to 1.72).

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Percentage reduction in the dengue rate with fogging: (1 - RR) x 100.
round((1 - exp(coef(m_nb)[["foggingYes"]])) * 100)                  #@ 1 -
#% A (Q2): about 34%: "fogging was associated with a 34% lower dengue rate".

# Q2. Why say "associated with", and not "caused"?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Counterfactual: expected cases in the fogged ward-months IF fogging had not been done (set fogging to "No").
fogged <- dg |> filter(fogging == "Yes")
cf <- fogged |> mutate(fogging = factor("No", levels = levels(dg$fogging)))
c(observed_model = sum(predict(m_nb, newdata = fogged, type = "response")), without_fogging = sum(predict(m_nb, newdata = cf, type = "response")))   #@ newdata
#% A (Q3): about 1,360 expected with fogging vs about 2,070 without it: roughly 700 cases averted (about a third), under the model's assumptions.

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Poisson regression with robust standard errors also estimates PREVALENCE RATIOS for a binary outcome (the log-binomial alternative). Fit it for "any dengue in the ward-month" (cases > 0).
pr <- glm(I(cases > 0) ~ fogging + slum, family = poisson, data = dg)   #@ poisson
coeftest(pr, vcov = vcovCL(pr, cluster = dg$ward))                  #@ vcovCL
#% A (Q4): Poisson with robust SE gives a risk (prevalence) ratio, not an odds ratio; with a common outcome this avoids the OR-overstates problem from the regression workshop.

# Q4. Why is this useful when the outcome is common?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: A publication table with the negative binomial rate ratios.
tbl_regression(m_nb, exponentiate = TRUE)                           #@ exponentiate
