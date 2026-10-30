# ═══════════════════════════════════════════════════════════════
# LAB 3 — Checking the proportional-odds assumption
# Ordinal and multinomial outcomes workshop | Session 3
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

m2 <- MASS::polr(anaemia ~ wealth + education + bmi + anc_visits + parity + age + tribal + residence, data = mat, Hess = TRUE)

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: The Brant test of proportional odds (overall and for each predictor).
br <- brant(m2)                                                     #@ brant
br
#% A (Q1): the omnibus p-value is very small, and only tribal group has a very small p-value (about 0); every other predictor has p between 0.25 and 0.72 (wealth 0.57).

# Q1. Which variable violates proportional odds, and how do you know?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: See the violation directly: fit three binary logistic models for "Mild or worse", "Moderate or worse" and "Severe", then compare the odds ratio for tribal.
cuts <- c("Mild", "Moderate", "Severe")
or_tribal <- sapply(cuts, \(k) exp(coef(glm(I(as.numeric(mat$anaemia) >= which(levels(mat$anaemia) == k)) ~ wealth + tribal, family = binomial, data = mat))["tribalYes"]))   #@ binomial
round(or_tribal, 2)
#% A (Q2): the OR for tribal is about 1.13 for "Mild or worse", 1.05 for "Moderate or worse" and 3.2 for "Severe": it is NOT constant across cut-points. Proportional odds would assume three equal odds ratios.

# Q2. What would the proportional-odds model assume about these three odds ratios?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: The same comparison for wealth (the assumption should hold).
or_wealth <- sapply(cuts, \(k) exp(coef(glm(I(as.numeric(mat$anaemia) >= which(levels(mat$anaemia) == k)) ~ wealth + tribal, family = binomial, data = mat))["wealth"]))   #@ ["wealth"]
round(or_wealth, 2)
#% A: roughly constant (0.58, 0.60, 0.61) across the three cuts: the assumption holds for wealth.

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Fit the PARTIAL proportional-odds model that frees tribal only: ordinal::clm with nominal = ~ tribal.
m_ppo <- ordinal::clm(anaemia ~ wealth + education + bmi + anc_visits + parity + age + residence, nominal = ~ tribal, data = mat)   #@ nominal
#% A: the other predictors keep one odds ratio each; tribal gets a separate effect at each threshold.

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Compare the proportional-odds model with the partial one by a likelihood-ratio test.
m_po <- ordinal::clm(anaemia ~ wealth + education + bmi + anc_visits + parity + age + tribal + residence, data = mat)
anova(m_po, m_ppo)                                                  #@ anova
#% A (Q5): chi-square about 37.6 on 2 df, p < 0.001: freeing tribal improves the fit a lot, so the proportional-odds assumption fails for it.

# Q5. What does the result of the likelihood-ratio test tell you?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: AIC of the two models.
AIC(m_po, m_ppo)                                                    #@ AIC
#% A: about 3,101 for the partial model vs 3,135 for the proportional-odds model: lower is better.

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: With the violation, a single odds ratio for tribal from the ordinary model is misleading. Print it, and then the three cut-specific values from the partial model.
exp(coef(m_po))["tribalYes"]
round(1 / exp(coef(m_ppo)[grepl("tribal", names(coef(m_ppo)))]), 2)     #@ grepl
#% A (Q7): the single OR (about 1.1) averages over almost no effect on mild or moderate anaemia and a large effect on severe anaemia. (In clm, nominal coefficients are threshold shifts, so 1 / exp(coef) is the odds ratio for a worse category: about 1.0, 0.9 and 2.8.)

# Q7. Why should you not report a single odds ratio for tribal here?
