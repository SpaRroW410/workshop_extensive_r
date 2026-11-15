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
m_i <- lm(sbp ~ salt * age + bmi + activity + sex + smoker, data = ncd)   #@ salt * age
round(summary(m_i)$coefficients["salt:age", ], 4)

#% A (Q1): about +0.050 mmHg per g/day per year of age (p < 0.001): the effect of salt on SBP increases by 0.05 mmHg per g/day for every year older.
# Q1. Interpret the interaction coefficient in words.

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: The effect of salt (mmHg per g/day) at age 30, 45 and 60: the salt coefficient plus age times the interaction coefficient.
b <- coef(m_i)
sapply(c(30, 45, 60), function(a) b[["salt"]] + a * b[["salt:age"]])   #@ b[["salt:age"]]
#% A: about -0.01 (age 30), 0.74 (age 45) and 1.49 (age 60) mmHg per g/day: no effect at 30, twice as large at 60 as at 45.

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: The same slopes with confidence intervals using emmeans (estimated trends).
emtrends(m_i, ~ age, var = "salt", at = list(age = c(30, 45, 60)))   #@ emtrends
#% A: the same three slopes with 95% CIs: -0.21 to 0.18, 0.60 to 0.88, 1.27 to 1.71.

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Centre age at 45 so that the main effect of salt is the effect at age 45, and refit.
ncd <- ncd |> mutate(age45 = age - 45)                              #@ age - 45
m_c <- lm(sbp ~ salt * age45 + bmi + activity + sex + smoker, data = ncd)
round(coef(m_c)[["salt"]], 3)

#% A (Q4): 0.739: the salt coefficient is now the effect at age 45, because that is where age45 = 0. Without centring it is the effect at age 0, which is meaningless.
# Q4. Why does the "salt" coefficient change when age is centred?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: A plot of predicted SBP against salt at ages 30, 45 and 60 (other variables at the mean; male; non-smoker).
g <- expand.grid(salt = seq(3, 18, 1), age = c(30, 45, 60)) |> mutate(bmi = mean(ncd$bmi), activity = mean(ncd$activity), sex = factor("Male", levels = levels(ncd$sex)), smoker = 0)
g$fit <- predict(m_i, g)                                            #@ predict
ggplot(g, aes(salt, fit, colour = factor(age))) + geom_line()

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: A categorical interaction: smoking and sex for the 10-year CVD event (logistic, with age and BMI as a quadratic).
g_ss <- glm(cvd10 ~ age + bmi + I(bmi^2) + sex * smoker, data = ncd, family = binomial)   #@ sex * smoker
round(summary(g_ss)$coefficients["sexMale:smoker", ], 3)

#% A: coefficient about 0.82 (SE 0.30, p = 0.007): the smoking log-odds is larger in men.
# ── Task 7 ──────────────────────────────────────────────────────
# Goal: The odds ratio for smoking WITHIN each sex.
emmeans(g_ss, ~ smoker | sex, type = "response") |> pairs(reverse = TRUE)          #@ pairs
#% A (Q7): odds ratio for smoking about 1.0 in women and about 2.3 in men (reverse = TRUE gives smoker / non-smoker). Not proof: "significant in one, not in the other" is not a test of a difference; the interaction test (p = 0.007) is.

# Q7. Smoking is clearly harmful in men but not in women. Does that prove effect modification by sex?

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Look at the interaction on the ADDITIVE scale: the predicted 10-year risk by sex and smoking (age 50, BMI 25), and the risk difference for smoking in each sex.
nd <- expand.grid(sex = factor(c("Female", "Male"), levels = levels(ncd$sex)), smoker = c(0, 1), age = 50, bmi = 25)
nd$risk <- predict(g_ss, nd, type = "response")                      #@ type
nd

#% A: predicted risks about 4.1% (female non-smoker), 4.0% (female smoker), 5.1% (male non-smoker), 10.8% (male smoker): the risk difference for smoking is about 0 in women and 5.7 percentage points in men.