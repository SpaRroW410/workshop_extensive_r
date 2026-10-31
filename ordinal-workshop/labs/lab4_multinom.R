# ═══════════════════════════════════════════════════════════════
# LAB 4 — Multinomial logistic regression
# Ordinal and multinomial outcomes workshop | Session 4
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
# Goal: Make Home the reference category and check it (it is the first level already).
mat$delivery <- ___(mat$delivery, ___ = "Home")
levels(mat$delivery)

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Fit a multinomial model of delivery place on wealth, education, antenatal visits, residence and tribal group.
mn <- nnet::___(delivery ~ wealth + education + anc_visits + residence + tribal, data = mat, ___ = FALSE)
round(coef(mn), 2)

# Q2. Why are there three rows of coefficients and not one?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Relative risk ratios (exponentiated coefficients) for wealth in each comparison.
round(___(coef(mn)[, "wealth"]), 2)

# Q3. Interpret the 2.1 for private hospital in one sentence.

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: z statistics and p-values (multinom does not print them): coefficient / standard error.
s <- summary(mn)
z <- s$coefficients / s$___
round(2 * pnorm(-abs(z)), 4)[, "wealth"]

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: A likelihood-ratio test for the WHOLE effect of education (all three comparisons together): compare the model with and without it.
mn0 <- nnet::multinom(delivery ~ wealth + anc_visits + residence + tribal, data = mat, trace = FALSE)
___(mn0, mn)

# Q5. Why use a likelihood-ratio test for a variable in a multinomial model?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Predicted probabilities of the four places for an urban, non-tribal woman with secondary education and 4 antenatal visits, in the poorest and richest quintile.
nd <- data.frame(wealth = c(1, 5), education = factor("Secondary", levels = levels(mat$education)), anc_visits = 4, residence = factor("Urban", levels = c("Urban", "Rural")), tribal = factor("No", levels = c("No", "Yes")))
round(predict(mn, newdata = nd, ___ = "probs"), 2)

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Change the reference to Public hospital and refit. Which results change and which stay the same?
mat2 <- mat |> mutate(delivery = relevel(delivery, ref = "Public hospital"))
mn2 <- nnet::multinom(delivery ~ wealth + education + anc_visits + residence + tribal, data = ___, trace = FALSE)
round(exp(coef(mn2)[, "wealth"]), 2)

# Q7. Does the choice of reference category change the model fit?
