# ═══════════════════════════════════════════════════════════════
# LAB 3 — Regression with survey data
# Survey data and weights workshop | Session 3
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(survey); library(srvyr) })
theme_set(theme_minimal(base_size = 14))
options(survey.lonely.psu = "adjust")      # one-PSU strata (e.g. in subgroups) are handled instead of stopping

p <- c("data/survey_adults.csv", "../data/survey_adults.csv", "../../data/survey_adults.csv"); p <- p[file.exists(p)][1]
adults <- read_csv(p, show_col_types = FALSE)
resp <- adults |> filter(responded == 1) |> mutate(across(c(region, residence, sex), factor), education = factor(education, levels = c("None", "Primary", "Secondary+")),
  age_grp = cut(age, c(17, 29, 44, 59, 120), labels = c("18-29", "30-44", "45-59", "60+")))
des <- svydesign(ids = ~psu, strata = ~stratum, weights = ~weight, data = resp, nest = TRUE)

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: A logistic regression of hypertension on age, sex, residence, BMI and wealth that respects the design (quasibinomial family).
m_svy <- ___(hypertension ~ age + sex + residence + bmi + wealth, design = des, family = ___())
round(summary(m_svy)$coefficients, 3)

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Odds ratios with 95% CIs.
round(exp(cbind(OR = coef(m_svy), ___(m_svy))), 2)

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Fit the same model ignoring the design (an ordinary glm) and compare the SE of the urban coefficient.
m____ <- glm(hypertension ~ age + sex + residence + bmi + wealth, data = resp, family = binomial)
rbind(glm = summary(m_glm)$coefficients["residenceUrban", 1:2], svyglm = summary(m_svy)$coefficients["residenceUrban", 1:2])

# Q3. Why are the estimates close but the SEs different?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: A weighted-only glm (weights but no clusters) also gives a SE that is too small. Fit it with the weights argument.
m_w <- glm(hypertension ~ age + sex + residence + bmi + wealth, data = resp, family = quasibinomial, ___ = weight / mean(weight))
round(summary(m_w)$coefficients["residenceUrban", 1:2], 3)

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Linear regression of SBP on the same predictors (design-based).
m_lin <- ___(sbp ~ age + sex + residence + bmi + wealth, design = des)
round(summary(m_lin)$coefficients, 2)

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Test whether education as a whole improves the model (a Wald test with the design) after adding it.
m_edu <- svyglm(hypertension ~ age + sex + residence + bmi + wealth + education, design = des, family = quasibinomial())
___(m_edu, ~education)

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Predicted probability of hypertension for a 50-year-old man in urban and rural areas, BMI 26, wealth 3.
nd <- data.frame(age = 50, sex = factor("Male", levels = levels(resp$sex)), residence = factor(c("Rural", "Urban"), levels = levels(resp$residence)), bmi = 26, wealth = 3)
round(___(m_svy, newdata = nd, type = "response"), 2)

# Q7. Why is a predicted probability easier to communicate than an odds ratio?
