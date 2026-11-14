# ═══════════════════════════════════════════════════════════════
# LAB 5 — Choosing, checking and reporting curves
# Curves and interactions workshop | Session 5
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(splines); library(mgcv); library(emmeans) })
theme_set(theme_minimal(base_size = 14))

p <- c("data/ncd_curves.csv", "../data/ncd_curves.csv", "../../data/ncd_curves.csv"); p <- p[file.exists(p)][1]
ncd <- read_csv(p, show_col_types = FALSE) |> mutate(sex = factor(sex), smoker_f = factor(smoker, labels = c("Non-smoker", "Smoker")))

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Compare four ways to model the age curve of SBP by 10-fold cross-validated RMSE: linear, hinge at 45, natural spline (df = 4) and a GAM.
set.seed(1)
fold <- sample(rep(1:10, length.out = nrow(ncd)))
cv_rmse <- function(fit_fun) sqrt(mean(sapply(1:10, function(k) { f <- fit_fun(ncd[fold != k, ]); mean((ncd$sbp[fold == k] - predict(f, ncd[fold == k, ]))^2) })))
c(linear = cv_rmse(function(d) lm(sbp ~ age + bmi + salt + activity + sex + smoker, d)),
  hinge  = cv_rmse(function(d) lm(sbp ~ age + pmax(age - 45, 0) + bmi + salt + activity + sex + smoker, d)),
  ns4    = cv_rmse(function(d) lm(sbp ~ ns(age, 4) + bmi + salt + activity + sex + smoker, d)),
  gam    = cv_rmse(function(d) gam(sbp ~ s(age) + s(bmi) + s(activity) + salt + sex + smoker, data = d, ___ = "REML")))

# Q1. Which model would you choose, and why?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Overfitting: a spline for age with 15 degrees of freedom. Compare its cross-validated RMSE with the one for 4 degrees of freedom.
cv_rmse(function(d) lm(sbp ~ ns(age, ___) + bmi + salt + activity + sex + smoker, d))

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: A marginal (standardised) prediction: the average predicted CVD risk at each BMI if EVERY adult in the sample had that BMI.
g_ns <- glm(cvd10 ~ age + ns(bmi, 4) + sex * smoker, data = ncd, family = binomial)
bmis <- c(18.5, 22, 25, 30, 35)
sapply(bmis, function(b) mean(predict(g_ns, ___(ncd, bmi = b), type = "response")))

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Extrapolation: the range of BMI in the data, and the number of adults with a BMI above 40.
___(ncd$bmi)
sum(ncd$bmi > 40)

# Q4. Why is it risky to use the model for a BMI of 50?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Odds ratios compared with a reference BMI of 24.6 for several BMI values (the reference row is the baseline).
ref <- predict(g_ns, transform(ncd[1, ], bmi = 24.6))
sapply(bmis, function(b) ___(predict(g_ns, transform(ncd[1, ], bmi = b)) - ref))

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: A one-sentence result for a paper.
cat("The 10-year risk of a cardiovascular event was ___ in BMI (nonlinearity LR test p < 0.001), lowest near a BMI of 24 to 25, and higher at both ends.\n")
