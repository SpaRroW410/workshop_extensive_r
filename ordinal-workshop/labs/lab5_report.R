# ═══════════════════════════════════════════════════════════════
# LAB 5 — Choosing, comparing and reporting
# Ordinal and multinomial outcomes workshop | Session 5
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

mat$delivery <- relevel(mat$delivery, ref = "Home")
mn <- nnet::multinom(delivery ~ wealth + education + anc_visits + residence + tribal, data = mat, trace = FALSE)
m_ord <- MASS::polr(anaemia ~ wealth + education + bmi + anc_visits + parity + age + tribal + residence, data = mat, Hess = TRUE)

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: An ORDINAL outcome can also be fitted as multinomial (ignoring the order). Fit both for anaemia on wealth and tribal, then compare their AIC.
a_ord <- MASS::polr(anaemia ~ wealth + tribal, data = mat, Hess = TRUE)
a_mn <- nnet::multinom(___ ~ wealth + tribal, data = mat, trace = FALSE)
c(ordinal = ___(a_ord), multinomial = AIC(a_mn))

# Q1. When would you choose the multinomial model for an ordered outcome?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Predicted probability of each anaemia category across the wealth quintiles for a typical non-tribal woman, as a table.
nd <- data.frame(wealth = 1:5, education = factor("Primary", levels = levels(mat$education)), bmi = 20.5, anc_visits = 3, parity = 2, age = 27, tribal = factor("No", levels = c("No", "Yes")), residence = factor("Rural", levels = c("Urban", "Rural")))
round(___(m_ord, newdata = nd, type = "probs"), 2)

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Plot those probabilities against wealth (one line per anaemia category).
pp <- cbind(wealth = 1:5, as.data.frame(predict(m_ord, newdata = nd, type = "probs"))) |> ___(-wealth, names_to = "anaemia", values_to = "probability")
ggplot(pp, aes(wealth, probability, colour = anaemia)) + geom_line()

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Predicted delivery-place probabilities across the wealth quintiles (urban, secondary education, 4 ANC visits).
nd2 <- data.frame(wealth = 1:5, education = factor("Secondary", levels = levels(mat$education)), anc_visits = 4, residence = factor("Urban", levels = c("Urban", "Rural")), tribal = factor("No", levels = c("No", "Yes")))
round(predict(mn, newdata = ___, type = "probs"), 2)

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Percentage of women correctly "classified" by the multinomial model (predicting the most likely place). Compare with always guessing the most common place.
pred <- predict(mn)
c(model = mean(pred == mat$delivery), always_most_common = ___(prop.table(table(mat$delivery))))

# Q5. Why is classification accuracy a weak summary here?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: A publication table of the relative risk ratios for the multinomial model.
tbl_regression(mn, ___ = TRUE)
