# ═══════════════════════════════════════════════════════════════
# LAB 2 — Ordinal logistic regression (proportional odds)
# Ordinal and multinomial outcomes workshop | Session 2
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(broom); library(gtsummary); library(nnet); library(ordinal); library(brant) })
theme_set(theme_minimal(base_size = 14))

mat_path <- c("data/maternal_survey.csv", "../data/maternal_survey.csv", "../../data/maternal_survey.csv")
mat_path <- mat_path[file.exists(mat_path)][1]
mat <- read_csv(mat_path, show_col_types = FALSE) |>
  mutate(education = factor(education, levels = c("None", "Primary", "Secondary", "Higher")), residence = factor(residence, levels = c("Urban", "Rural")), tribal = factor(tribal, levels = c("No", "Yes")),
         anaemia = factor(anaemia, levels = c("None", "Mild", "Moderate", "Severe"), ordered = TRUE), delivery = factor(delivery, levels = c("Home", "PHC", "Public hospital", "Private hospital")))

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Fit a proportional-odds model of anaemia on wealth. Use MASS::polr with Hess = TRUE.
m1 <- MASS::polr(anaemia ~ wealth, data = mat, Hess = TRUE)         #@ polr || Hess
summary(m1)

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: The odds ratio per quintile of wealth and its 95% CI.
exp(cbind(OR = coef(m1), confint(m1)))                              #@ confint
#% A (Q2): unadjusted OR about 0.57 (95% CI 0.53 to 0.63): each wealth quintile higher multiplies the odds of being in a WORSE anaemia category by about 0.57 (a 43% reduction), the same at every cut-point. In polr a coefficient above 0 means a higher (worse) category.

# Q2. Interpret the odds ratio for wealth in one sentence. Which direction does a coefficient above 0 mean?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: The threshold (intercept) estimates: the log-odds of each cut-point. Show them.
m1$zeta                                                             #@ zeta
#% A (Q3): three thresholds (None|Mild, Mild|Moderate, Moderate|Severe): they set the baseline cumulative probabilities.

# Q3. Why are there three thresholds for four categories?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Fit the adjusted model: wealth, education, BMI, antenatal visits, parity, age, tribal group and residence.
m2 <- MASS::polr(anaemia ~ wealth + education + bmi + anc_visits + parity + age + tribal + residence, data = mat, Hess = TRUE)   #@ anc_visits + parity || tribal
round(exp(coef(m2)), 2)
#% A (Q4): wealth (0.76), higher education (0.46 vs none), BMI (0.93) and antenatal visits (0.90) are protective (OR below 1). The single OR for tribal group is only about 1.1: it averages a large effect on severe anaemia and almost none on mild (see Lab 3).

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Publication table of odds ratios.
tbl_regression(m2, exponentiate = TRUE)                             #@ exponentiate

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Predicted PROBABILITIES of the four anaemia categories for a poorest-quintile and a richest-quintile woman, with other covariates at typical values.
nd <- data.frame(wealth = c(1, 5), education = factor("Primary", levels = levels(mat$education)), bmi = 20.5, anc_visits = 3, parity = 2, age = 27, tribal = factor("No", levels = c("No", "Yes")), residence = factor("Rural", levels = c("Urban", "Rural")))
round(predict(m2, newdata = nd, type = "probs"), 3)                 #@ probs
#% A (Q6): for the poorest quintile: None 38%, Mild 34%, Moderate 18%, Severe 10%; for the richest: None 65%, Mild 24%, Moderate 8%, Severe 3%. Probabilities are easier to explain because they are on the scale people think in.

# Q6. Why are predicted probabilities often easier to explain than odds ratios?

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Compare with an ordinary binary logistic model for ANY anaemia (None vs the rest). Does wealth have a similar odds ratio?
exp(coef(glm(I(anaemia != "None") ~ wealth, family = binomial, data = mat)))["wealth"]   #@ binomial
#% A (Q7): about 0.57, the same as the ordinal model, because here the proportional-odds pattern holds; the ordinal model uses ALL the information (the severity), not only yes/no, and so gives more precise estimates.
