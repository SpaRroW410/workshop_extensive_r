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
m_h <- lm(sbp ~ age + pmax(age - 45, 0) + bmi + salt + activity + sex + smoker, data = ncd)   #@ pmax
round(coef(m_h)[2:3], 3)

#% A: slope 0.27 mmHg per year below 45, and 0.27 + 0.29 above it.
# ── Task 2 ──────────────────────────────────────────────────────
# Goal: The slope before the knot and the slope after the knot (the sum of the two coefficients).
c(before = coef(m_h)[["age"]], after = coef(m_h)[["age"]] + coef(m_h)[[3]])   #@ coef(m_h)[[3]]
#% A: about 0.27 before and 0.56 after 45: twice as fast.

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Search for the best knot: refit for knots from 30 to 60 and keep the AIC of each.
aic_k <- sapply(30:60, function(k) AIC(lm(sbp ~ age + pmax(age - k, 0) + bmi + salt + activity + sex + smoker, data = ncd)))   #@ sapply
(30:60)[which.min(aic_k)]

#% A (Q3): 45. Choosing the knot from the data makes the CI too narrow (the search is not counted); prefer a knot on subject-matter grounds or a smooth curve.
# Q3. What is the danger of choosing the knot from the data?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: A natural cubic spline for age with 4 degrees of freedom, compared with the straight-line model using an F test.
m_ns <- lm(sbp ~ ns(age, df = 4) + bmi + salt + activity + sex + smoker, data = ncd)   #@ ns
m_l <- lm(sbp ~ age + bmi + salt + activity + sex + smoker, data = ncd)
anova(m_l, m_ns)

#% A: the spline is better than a straight line (F test p about 8e-9).
# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Choose the number of degrees of freedom for the age spline: compare AIC for df = 1 to 8.
sapply(1:8, function(k) AIC(lm(sbp ~ ns(age, df = k) + bmi + salt + activity + sex + smoker, data = ncd)))   #@ df = k
#% A (Q5): df = 1 is the straight line (30,771); AIC drops to 30,735 at df = 2 and stays flat: 3 to 5 df are enough; more only adds wiggle.

# Q5. Why not use the largest number of degrees of freedom?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: A PREDICTION PLOT: predicted SBP and a 95% band across age, with the other variables held at typical values (mean BMI, salt, activity; male; non-smoker).
grid <- data.frame(age = 18:80, bmi = mean(ncd$bmi), salt = mean(ncd$salt), activity = mean(ncd$activity), sex = factor("Male", levels = levels(ncd$sex)), smoker = 0)
pr <- predict(m_ns, newdata = grid, se.fit = TRUE)                  #@ se.fit
grid |> mutate(fit = pr$fit, lo = fit - 1.96 * pr$se.fit, hi = fit + 1.96 * pr$se.fit) |>
  ggplot(aes(age, fit)) + geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.25) + geom_line()   #@ geom_ribbon

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: The same idea for the binary outcome: a logistic model with a natural spline for BMI (4 df), compared with the linear BMI term by a likelihood-ratio test.
g_ns <- glm(cvd10 ~ age + ns(bmi, 4) + sex + smoker, data = ncd, family = binomial)   #@ ns(bmi, 4)
g_l <- glm(cvd10 ~ age + bmi + sex + smoker, data = ncd, family = binomial)
anova(g_l, g_ns, test = "Chisq")

#% A: the likelihood-ratio test is highly significant (deviance 235 on 3 df): the linear BMI term is not enough.
# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Predicted probability of a CVD event by BMI (age 50, male, non-smoker), as a plot.
gb <- data.frame(bmi = seq(15, 45, 0.5), age = 50, sex = factor("Male", levels = levels(ncd$sex)), smoker = 0)
gb$p <- predict(g_ns, newdata = gb, type = "response")              #@ type
ggplot(gb, aes(bmi, p)) + geom_line()
