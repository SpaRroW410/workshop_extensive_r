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
m_svy <- svyglm(hypertension ~ age + sex + residence + bmi + wealth, design = des, family = quasibinomial())   #@ svyglm || quasibinomial
round(summary(m_svy)$coefficients, 3)
#% A (Q1): odds increase with age, BMI and urban residence.

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Odds ratios with 95% CIs.
round(exp(cbind(OR = coef(m_svy), confint(m_svy))), 2)               #@ confint
#% A (Q2): per year of age OR about 1.06; urban vs rural about 2.1 (CI 1.4 to 3.1); per BMI unit about 1.10.

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Fit the same model ignoring the design (an ordinary glm) and compare the SE of the urban coefficient.
m_glm <- glm(hypertension ~ age + sex + residence + bmi + wealth, data = resp, family = binomial)   #@ glm
rbind(glm = summary(m_glm)$coefficients["residenceUrban", 1:2], svyglm = summary(m_svy)$coefficients["residenceUrban", 1:2])
#% A (Q3): the SE is larger with the design (about 0.19 vs 0.13); the estimates are close (0.73 vs 0.67).

# Q3. Why are the estimates close but the SEs different?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: A weighted-only glm (weights but no clusters) also gives a SE that is too small. Fit it with the weights argument.
m_w <- glm(hypertension ~ age + sex + residence + bmi + wealth, data = resp, family = quasibinomial, weights = weight / mean(weight))   #@ weights
round(summary(m_w)$coefficients["residenceUrban", 1:2], 3)
#% A (Q4): the weights change the estimate (here rescaled to mean 1 so that the fit converges), but the SE ignores clustering and stays too small.

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Linear regression of SBP on the same predictors (design-based).
m_lin <- svyglm(sbp ~ age + sex + residence + bmi + wealth, design = des)   #@ svyglm
round(summary(m_lin)$coefficients, 2)
#% A (Q5): about +0.45 mmHg per year of age, +0.8 mmHg per BMI unit and +5.8 mmHg for urban residence.

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Test whether education as a whole improves the model (a Wald test with the design) after adding it.
m_edu <- svyglm(hypertension ~ age + sex + residence + bmi + wealth + education, design = des, family = quasibinomial())
regTermTest(m_edu, ~education)                                      #@ regTermTest
#% A (Q6): F-test p about 0.09: no clear evidence of an education effect once age, BMI and wealth are in the model.

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Predicted probability of hypertension for a 50-year-old man in urban and rural areas, BMI 26, wealth 3.
nd <- data.frame(age = 50, sex = factor("Male", levels = levels(resp$sex)), residence = factor(c("Rural", "Urban"), levels = levels(resp$residence)), bmi = 26, wealth = 3)
round(predict(m_svy, newdata = nd, type = "response"), 2)           #@ predict
#% A (Q7): about 0.26 (rural) and 0.42 (urban).

# Q7. Why is a predicted probability easier to communicate than an odds ratio?
