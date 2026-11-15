# ═══════════════════════════════════════════════════════════════
# LAB 3 — Generalised additive models (GAM)
# Curves and interactions workshop | Session 3
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(splines); library(mgcv); library(emmeans) })
theme_set(theme_minimal(base_size = 14))

p <- c("data/ncd_curves.csv", "../data/ncd_curves.csv", "../../data/ncd_curves.csv"); p <- p[file.exists(p)][1]
ncd <- read_csv(p, show_col_types = FALSE) |> mutate(sex = factor(sex), smoker_f = factor(smoker, labels = c("Non-smoker", "Smoker")))

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: A GAM for SBP with smooth terms for age, BMI and activity, and linear terms for salt, sex and smoking. Use REML to choose the smoothness.
g1 <- gam(sbp ~ s(age) + s(bmi) + s(activity) + salt + sex + smoker, data = ncd, method = "REML")   #@ s(age) || REML
summary(g1)

#% A: edf about 3.9 (age), 4.1 (BMI) and 3.1 (activity): all clearly curved; adjusted R-squared about 0.31.
# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Plot all the smooth terms on one page.
plot(g1, pages = 1, shade = TRUE)                                   #@ pages
#% A (Q2): edf near 1 means the smooth is essentially a straight line; larger edf means a more wiggly curve.

# Q2. Read the estimated degrees of freedom (edf) of each smooth. What does edf close to 1 mean?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Is the GAM better than the straight-line model? Compare AIC.
m_l <- lm(sbp ~ age + bmi + salt + activity + sex + smoker, data = ncd)
AIC(m_l, g1)                                                        #@ AIC
#% A: the GAM is better (AIC 30,692 against 30,771).

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Check that the basis dimension k is large enough (look at the k-index and the p-value).
gam.check(g1)                                                       #@ gam.check
#% A (Q4): here k-index is about 1 with p about 0.4, so k = 10 is enough. A low k-index with a small p-value suggests that k is too low (the smooth is forced to be too simple): refit with a larger k.

# Q4. What does a low k-index with a small p-value suggest?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: A logistic GAM for the 10-year CVD event with smooth age and smooth BMI.
g2 <- gam(cvd10 ~ s(age) + s(bmi) + sex + smoker, data = ncd, family = binomial, method = "REML")   #@ family
summary(g2)$s.table
#% A (Q5): a very flexible smooth for BMI (edf about 5); the smooth for age is close to a straight line on the logit scale.

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Plot the BMI smooth on the probability scale (add the intercept and back-transform).
plot(g2, select = 2, trans = plogis, shift = coef(g2)[1], seWithMean = TRUE)   #@ trans
#% A: a U-shaped curve with its minimum near BMI 24 to 25.

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Let the age curve differ between men and women: a smooth of age separately by sex.
g3 <- gam(sbp ~ s(age, by = sex) + sex + s(bmi) + s(activity) + salt + smoker, data = ncd, method = "REML")   #@ by = sex
AIC(g1, g3)

#% A: a small gain (AIC 30,686 against 30,692): the age curve is similar in men and women; not worth the extra complexity.
# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Compare the GAM smooth for age with the natural spline with 4 df: predicted SBP at ages 30, 45 and 70 (other values at the mean, male, non-smoker).
nd <- data.frame(age = c(30, 45, 70), bmi = mean(ncd$bmi), salt = mean(ncd$salt), activity = mean(ncd$activity), sex = factor("Male", levels = levels(ncd$sex)), smoker = 0)
m_ns <- lm(sbp ~ ns(age, df = 4) + bmi + salt + activity + sex + smoker, data = ncd)
round(cbind(gam = predict(g1, nd), ns = predict(m_ns, nd)), 1)       #@ predict(g1
#% A: practically identical (107.7 vs 107.8, 112.5 vs 112.2, 126.0 vs 125.7 mmHg): a GAM and a spline with a few df give the same curve.
