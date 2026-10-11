# ═══════════════════════════════════════════════════════════════
# LAB 5 — Logistic regression: odds ratios, likelihood, discrimination
# Theory of Regression Analysis workshop | Session 5
# Outcome: htn (1 = SBP ≥140 or DBP ≥90). Prevalence ≈ 32%.
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({
  library(tidyverse); library(gtsummary); library(broom); library(performance)
  library(see); library(car); library(lmtest); library(pROC)
})
theme_set(theme_minimal(base_size = 14))

csv_path <- c("data/ncd_survey.csv", "../data/ncd_survey.csv", "../../data/ncd_survey.csv")
csv_path <- csv_path[file.exists(csv_path)][1]
ncd <- read_csv(csv_path, show_col_types = FALSE) |>
  mutate(
    sex = factor(sex, levels = c("Female", "Male")),
    residence = factor(residence, levels = c("Urban", "Rural")),
    education = factor(education, levels = c("No schooling", "Primary", "Secondary", "Graduate+")),
    tobacco = factor(tobacco, levels = c("No", "Yes")),
    alcohol = factor(alcohol, levels = c("No", "Yes")),
    phys_act = factor(phys_act, levels = c("low", "moderate", "high")),
    htn_f = factor(htn, levels = 0:1, labels = c("No HTN", "HTN"))
  )

# Same rows in every model (needed for likelihood comparisons)
cc <- ncd |>
  drop_na(htn, salt_g, age, bmi, waist, sex, residence, education, tobacco, alcohol, phys_act)
table(cc$htn)

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Fit a CRUDE model of the probability of hypertension (htn)
# on salt intake alone, treating the outcome as binary.
m_crude <- glm(htn ~ salt_g, data = cc, family = binomial)       #@ glm || binomial

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Fit the ADJUSTED binary model: salt, age, BMI, sex, residence,
# education, tobacco, alcohol and physical activity.
m_adj <- glm(htn ~ salt_g + age + bmi + sex + residence + education +
               tobacco + alcohol + phys_act,
             data = cc, family = binomial)                       #@ binomial
summary(m_adj)

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Turn the log-odds coefficients of the adjusted model into odds
# ratios, with their 95% confidence limits on the odds-ratio scale.
tidy(m_adj, exponentiate = TRUE, conf.int = TRUE)                #@ exponentiate

# Task 3b. Do it by hand for salt: undo the log scale on the coefficient
# and on its confidence limits (confint() profiles the likelihood).
exp(coef(m_adj)["salt_g"])                                       #@ exp
exp(confint(m_adj)["salt_g", ])                                  #@ exp

#% A (Q1/Q2): adjusted OR per g salt = 1.24 (95% CI 1.11–1.39): each extra g/day multiplies the ODDS of HTN by 1.24, others held constant. CI is asymmetric on OR scale because it is symmetric on the log (β) scale. OR = 1 <-> β = 0 because exp(0) = 1 (no change in odds).

# Q1. Interpret the OR for salt_g in one sentence. Why is the CI not
#     symmetric around the OR?
# Q2. What value of β corresponds to an OR of exactly 1, and why?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Show crude (one predictor at a time) and adjusted odds ratios
# side by side in one publication-style table.
t_crude <- cc |>
  select(htn, salt_g, age, bmi, sex, residence, education, tobacco, alcohol, phys_act) |>
  tbl_uvregression(method = glm, y = htn,                       #@ tbl_uvregression || glm
                   method.args = list(family = binomial),
                   exponentiate = TRUE)                          #@ exponentiate
t_adj <- tbl_regression(m_adj, exponentiate = TRUE)              #@ exponentiate
tbl_merge(list(t_crude, t_adj), tab_spanner = c("**Crude**", "**Adjusted**"))

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Compare a smaller nested model (age, sex only) against the model
# that also contains salt, BMI, tobacco, alcohol and activity, using a
# chi-square comparison of how well the two models fit, built from
# their likelihoods.
m_small <- glm(htn ~ age + sex, data = cc, family = binomial)
m_big   <- glm(htn ~ age + sex + salt_g + bmi + tobacco + alcohol + phys_act,
               data = cc, family = binomial)
anova(m_small, m_big, test = "LRT")                              #@ "LRT"

# Task 5b. The same comparison, using a function from the lmtest package.
lrtest(m_small, m_big)                                           #@ lrtest

# Task 5c. Report the fit statistic equal to −2 × log-likelihood (up to a
# constant) for both models, then the log-likelihood of the bigger one.
deviance(m_small); deviance(m_big)                               #@ deviance || deviance
logLik(m_big)                                                    #@ logLik

#% A (Q3): H0 = the 6 extra coefficients (salt, BMI, tobacco, alcohol, 2 activity dummies) are all zero. Chi-square 56.6 on 6 df, p < 0.001 -> reject; deviance falls 568.3 -> 511.7.

# Q3. What is the null hypothesis of the LR test here? How many degrees of
#     freedom, and what is your conclusion?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Compare two NON-nested models (one with BMI, one with waist)
# using the criterion that penalises −2 × log-likelihood by 2 per
# estimated parameter. Lower is better.
m_bmi   <- glm(htn ~ age + sex + bmi,   data = cc, family = binomial)
m_waist <- glm(htn ~ age + sex + waist, data = cc, family = binomial)
AIC(m_bmi, m_waist)                                              #@ AIC

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Report the three pseudo-R-squared values for the adjusted model:
# McFadden, Nagelkerke and Tjur.
r2_mcfadden(m_adj)                                               #@ r2_mcfadden
r2_nagelkerke(m_adj)                                             #@ r2_nagelkerke
r2_tjur(m_adj)                                                   #@ r2_tjur

#% A (Q4): McFadden 0.26, Nagelkerke 0.38, Tjur 0.29 — all different scales. Not "% variance explained"; do not compare with linear R2. Compare models with LRT (nested) or AIC.

# Q4. Why can't you say "the model explains X% of the variance in
#     hypertension"? What would you use to compare two logistic models?

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Check calibration: do predicted risks match observed risks across
# groups of people? Use the Hosmer–Lemeshow test.
performance_hosmer(m_adj, n_bins = 10)                           #@ performance_hosmer

# ── Task 9 ──────────────────────────────────────────────────────
# Goal: Get each person's predicted PROBABILITY of hypertension, build
# the curve of sensitivity against specificity for the observed outcome,
# and report the area under that curve with its 95% CI.
cc$p_hat <- predict(m_adj, type = "response")                    #@ "response"
roc_obj  <- roc(cc$htn, cc$p_hat)                                #@ roc
auc(roc_obj)                                                     #@ auc
ci.auc(roc_obj)                                                  #@ ci.auc

ggroc(roc_obj, colour = "#e74c3c", linewidth = 1) +
  geom_abline(intercept = 1, slope = 1, linetype = "dashed") +
  labs(x = "Specificity", y = "Sensitivity")

#% A (Q5): AUC = 0.82 (95% CI 0.79–0.86): a randomly chosen hypertensive ranks higher than a randomly chosen normotensive 82% of the time. High AUC says nothing about calibration (HL p = 0.15 here, but HL has low power / depends on bins).

# Q5. Interpret the area under the curve in plain words. Does a high value
#     prove the model is well calibrated?

# ── Task 10 ─────────────────────────────────────────────────────
# Goal: Salt is continuous, so look at a COMMON-outcome example with a
# binary exposure: age 50+ vs <50 (use the full survey, ncd). Compute the odds ratio and the
# prevalence ratio. A model from the family usually used for counts,
# combined with robust standard errors, gives the prevalence ratio directly.
ncd$age50 <- as.integer(ncd$age >= 50)
m_or <- glm(htn ~ age50, data = ncd, family = binomial)
m_pr <- glm(htn ~ age50, data = ncd, family = poisson)           #@ poisson
exp(coef(m_or)["age50"])                                          #@ exp
exp(coef(m_pr)["age50"])
coeftest(m_pr, vcov. = sandwich::vcovHC(m_pr, type = "HC0"))     #@ vcovHC

#% A (Q6): OR = 5.1, PR = 3.1. Outcome is common (32%), so the OR is much farther from 1 than the PR. Quote the PR (Poisson-robust or log-binomial) for "x times as likely".

# Q6. Compare the OR with the PR. Which is larger, and why? Which would you
#     quote to say "50+ year-olds are ___ times as likely to have HTN"?
