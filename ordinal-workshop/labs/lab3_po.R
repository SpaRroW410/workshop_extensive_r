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
br <- ___(m2)
br

# Q1. Which variable violates proportional odds, and how do you know?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: See the violation directly: fit three binary logistic models for "Mild or worse", "Moderate or worse" and "Severe", then compare the odds ratio for tribal.
cuts <- c("Mild", "Moderate", "Severe")
or_tribal <- sapply(cuts, \(k) exp(coef(glm(I(as.numeric(mat$anaemia) >= which(levels(mat$anaemia) == k)) ~ wealth + tribal, family = ___, data = mat))["tribalYes"]))
round(or_tribal, 2)

# Q2. What would the proportional-odds model assume about these three odds ratios?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: The same comparison for wealth (the assumption should hold).
or_wealth <- sapply(cuts, \(k) exp(coef(glm(I(as.numeric(mat$anaemia) >= which(levels(mat$anaemia) == k)) ~ wealth + tribal, family = binomial, data = mat))___))
round(or_wealth, 2)

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Fit the PARTIAL proportional-odds model that frees tribal only: ordinal::clm with nominal = ~ tribal.
m_ppo <- ordinal::clm(anaemia ~ wealth + education + bmi + anc_visits + parity + age + residence, ___ = ~ tribal, data = mat)

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Compare the proportional-odds model with the partial one by a likelihood-ratio test.
m_po <- ordinal::clm(anaemia ~ wealth + education + bmi + anc_visits + parity + age + tribal + residence, data = mat)
___(m_po, m_ppo)

# Q5. What does the result of the likelihood-ratio test tell you?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: AIC of the two models.
___(m_po, m_ppo)

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: With the violation, a single odds ratio for tribal from the ordinary model is misleading. Print it, and then the three cut-specific values from the partial model.
exp(coef(m_po))["tribalYes"]
round(1 / exp(coef(m_ppo)[___("tribal", names(coef(m_ppo)))]), 2)

# Q7. Why should you not report a single odds ratio for tribal here?
