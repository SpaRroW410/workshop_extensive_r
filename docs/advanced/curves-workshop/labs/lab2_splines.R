# ═══════════════════════════════════════════════════════════════
# LAB 2 — Splines: linear splines and natural splines
# Curves and interactions workshop | Session 2
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(splines); library(mgcv); library(emmeans) })
theme_set(theme_minimal(base_size = 14))

p <- c("data/ncd_curves.csv", "../data/ncd_curves.csv", "../../data/ncd_curves.csv"); p <- p[file.exists(p)][1]
ncd <- read_csv(p, show_col_types = FALSE) |> mutate(sex = factor(sex), smoker_f = factor(smoker, labels = c("Non-smoker", "Smoker")))

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: A piecewise-linear model (hinge) with a knot at age 45: age plus the amount of age above 45.
m_h <- lm(sbp ~ age + ___(age - 45, 0) + bmi + salt + activity + sex + smoker, data = ncd)
round(coef(m_h)[2:3], 3)

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: The slope before the knot and the slope after the knot (the sum of the two coefficients).
c(before = coef(m_h)[["age"]], after = coef(m_h)[["age"]] + ___)

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Search for the best knot: refit for knots from 30 to 60 and keep the AIC of each.
aic_k <- ___(30:60, function(k) AIC(lm(sbp ~ age + pmax(age - k, 0) + bmi + salt + activity + sex + smoker, data = ncd)))
(30:60)[which.min(aic_k)]

# Q3. What is the danger of choosing the knot from the data?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: A natural cubic spline for age with 4 degrees of freedom, compared with the straight-line model using an F test.
m____ <- lm(sbp ~ ns(age, df = 4) + bmi + salt + activity + sex + smoker, data = ncd)
m_l <- lm(sbp ~ age + bmi + salt + activity + sex + smoker, data = ncd)
anova(m_l, m_ns)

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Choose the number of degrees of freedom for the age spline: compare AIC for df = 1 to 8.
sapply(1:8, function(k) AIC(lm(sbp ~ ns(age, ___) + bmi + salt + activity + sex + smoker, data = ncd)))

# Q5. Why not use the largest number of degrees of freedom?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: A PREDICTION PLOT: predicted SBP and a 95% band across age, with the other variables held at typical values (mean BMI, salt, activity; male; non-smoker).
grid <- data.frame(age = 18:80, bmi = mean(ncd$bmi), salt = mean(ncd$salt), activity = mean(ncd$activity), sex = factor("Male", levels = levels(ncd$sex)), smoker = 0)
pr <- predict(m_ns, newdata = grid, ___ = TRUE)
grid |> mutate(fit = pr$fit, lo = fit - 1.96 * pr$se.fit, hi = fit + 1.96 * pr$se.fit) |>
  ggplot(aes(age, fit)) + ___(aes(ymin = lo, ymax = hi), alpha = 0.25) + geom_line()

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: The same idea for the binary outcome: a logistic model with a natural spline for BMI (4 df), compared with the linear BMI term by a likelihood-ratio test.
g_ns <- glm(cvd10 ~ age + ___ + sex + smoker, data = ncd, family = binomial)
g_l <- glm(cvd10 ~ age + bmi + sex + smoker, data = ncd, family = binomial)
anova(g_l, g_ns, test = "Chisq")

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Predicted probability of a CVD event by BMI (age 50, male, non-smoker), as a plot.
gb <- data.frame(bmi = seq(15, 45, 0.5), age = 50, sex = factor("Male", levels = levels(ncd$sex)), smoker = 0)
gb$p <- predict(g_ns, newdata = gb, ___ = "response")
ggplot(gb, aes(bmi, p)) + geom_line()
