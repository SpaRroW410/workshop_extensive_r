# ═══════════════════════════════════════════════════════════════
# LAB 1 — Categorical outcomes: nominal or ordered?
# Ordinal and multinomial outcomes workshop | Session 1
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
# Goal: How many women, and what are the categories of the two outcomes?
___(mat)
___(mat$anaemia)
levels(mat$delivery)

# Q1. Which outcome is ordered and which is nominal? Does the order of the delivery categories mean anything?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Percentage of women in each anaemia category.
round(100 * ___(table(mat$anaemia)), 1)

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: CUMULATIVE percentages: the proportion with anaemia at least this severe or less (P(Y <= k)).
round(100 * ___(prop.table(table(mat$anaemia))), 1)

# Q3. What does the cumulative proportion of 81% at "Mild" mean?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Is the anaemia variable stored as an ORDERED factor? Check its class.
___(mat$anaemia)

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Percentage in each anaemia category by wealth quintile (rows add to 100).
round(100 * ___(table(mat$wealth, mat$anaemia), ___, 1)

# Q5. Describe how the anaemia distribution changes from the poorest to the richest quintile.

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Plot the delivery place by wealth as 100% stacked bars.
ggplot(mat, aes(factor(wealth), fill = delivery)) + geom_bar(___ = "fill") + labs(x = "Wealth quintile", y = "Proportion")

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: The WRONG way: code anaemia as 1-4 and fit linear regression on wealth. Look at the coefficient, then say what is wrong with it.
coef(lm(___(anaemia) ~ wealth, data = mat))["wealth"]

# Q7. Name one problem with treating the 4 categories as numbers 1 to 4.

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: The sparse-category check: the smallest category must not be tiny. Print the counts for both outcomes.
table(mat$anaemia)
table(mat$delivery)
___(table(mat$anaemia))
