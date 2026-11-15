# ═══════════════════════════════════════════════════════════════
# LAB 4 — Interaction and effect modification
# Curves and interactions workshop | Session 4
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(splines); library(mgcv); library(emmeans) })
theme_set(theme_minimal(base_size = 14))

p <- c("data/ncd_curves.csv", "../data/ncd_curves.csv", "../../data/ncd_curves.csv"); p <- p[file.exists(p)][1]
ncd <- read_csv(p, show_col_types = FALSE) |> mutate(sex = factor(sex), smoker_f = factor(smoker, labels = c("Non-smoker", "Smoker")))

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Does the effect of salt on SBP depend on age? Fit a model with the product of salt and age (the * operator adds the main effects too).
m_i <- lm(sbp ~ ___ + bmi + activity + sex + smoker, data = ncd)
round(summary(m_i)$coefficients["salt:age", ], 4)

# Q1. Interpret the interaction coefficient in words.

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: The effect of salt (mmHg per g/day) at age 30, 45 and 60: the salt coefficient plus age times the interaction coefficient.
b <- coef(m_i)
sapply(c(30, 45, 60), function(a) b[["salt"]] + a * ___)

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: The same slopes with confidence intervals using emmeans (estimated trends).
___(m_i, ~ age, var = "salt", at = list(age = c(30, 45, 60)))

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Centre age at 45 so that the main effect of salt is the effect at age 45, and refit.
ncd <- ncd |> mutate(age45 = ___)
m_c <- lm(sbp ~ salt * age45 + bmi + activity + sex + smoker, data = ncd)
round(coef(m_c)[["salt"]], 3)

# Q4. Why does the "salt" coefficient change when age is centred?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: A plot of predicted SBP against salt at ages 30, 45 and 60 (other variables at the mean; male; non-smoker).
g <- expand.grid(salt = seq(3, 18, 1), age = c(30, 45, 60)) |> mutate(bmi = mean(ncd$bmi), activity = mean(ncd$activity), sex = factor("Male", levels = levels(ncd$sex)), smoker = 0)
g$fit <- ___(m_i, g)
ggplot(g, aes(salt, fit, colour = factor(age))) + geom_line()

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: A categorical interaction: smoking and sex for the 10-year CVD event (logistic, with age and BMI as a quadratic).
g_ss <- glm(cvd10 ~ age + bmi + I(bmi^2) + ___, data = ncd, family = binomial)
round(summary(g_ss)$coefficients["sexMale:smoker", ], 3)

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: The odds ratio for smoking WITHIN each sex.
emmeans(g_ss, ~ smoker | sex, type = "response") |> ___(reverse = TRUE)

# Q7. Smoking is clearly harmful in men but not in women. Does that prove effect modification by sex?

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Look at the interaction on the ADDITIVE scale: the predicted 10-year risk by sex and smoking (age 50, BMI 25), and the risk difference for smoking in each sex.
nd <- expand.grid(sex = factor(c("Female", "Male"), levels = levels(ncd$sex)), smoker = c(0, 1), age = 50, bmi = 25)
nd$risk <- predict(g_ss, nd, ___ = "response")
nd

