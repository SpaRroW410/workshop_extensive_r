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
nrow(mat)                                                           #@ nrow
levels(mat$anaemia)                                                 #@ levels
levels(mat$delivery)

# Q1. Which outcome is ordered and which is nominal? Does the order of the delivery categories mean anything?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Percentage of women in each anaemia category.
round(100 * prop.table(table(mat$anaemia)), 1)                      #@ prop.table
#% A (Q2): None 54.4%, Mild 26.5%, Moderate 12.2%, Severe 6.9%: the categories are ordered, with fewer women in the worse ones.

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: CUMULATIVE percentages: the proportion with anaemia at least this severe or less (P(Y <= k)).
round(100 * cumsum(prop.table(table(mat$anaemia))), 1)              #@ cumsum
#% A (Q3): 54, 81, 93, 100. 81% of women have mild anaemia or better (None or Mild). The proportional-odds model works with these cumulative proportions.

# Q3. What does the cumulative proportion of 81% at "Mild" mean?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Is the anaemia variable stored as an ORDERED factor? Check its class.
class(mat$anaemia)                                                  #@ class
#% A: "ordered" "factor": the ordering is explicit.

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Percentage in each anaemia category by wealth quintile (rows add to 100).
round(100 * prop.table(table(mat$wealth, mat$anaemia), 1), 1)       #@ prop.table || 1)
#% A (Q5): the share with no anaemia rises from about 30% (poorest) to 78% (richest), and the share with severe anaemia falls from about 17% to under 1%.

# Q5. Describe how the anaemia distribution changes from the poorest to the richest quintile.

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Plot the delivery place by wealth as 100% stacked bars.
ggplot(mat, aes(factor(wealth), fill = delivery)) + geom_bar(position = "fill") + labs(x = "Wealth quintile", y = "Proportion")   #@ position
#% A (Q6): home deliveries fall and private hospital deliveries rise with wealth.

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: The WRONG way: code anaemia as 1-4 and fit linear regression on wealth. Look at the coefficient, then say what is wrong with it.
coef(lm(as.numeric(anaemia) ~ wealth, data = mat))["wealth"]        #@ as.numeric
#% A (Q7): the slope is about -0.24 'categories' per quintile, but it assumes the gap between None and Mild equals the gap between Moderate and Severe (equal spacing), and an average category number is not interpretable; a proportional-odds model needs no such assumption.

# Q7. Name one problem with treating the 4 categories as numbers 1 to 4.

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: The sparse-category check: the smallest category must not be tiny. Print the counts for both outcomes.
table(mat$anaemia)
table(mat$delivery)
min(table(mat$anaemia))                                             #@ min
#% A: the smallest anaemia group (Severe) has about 103 women: enough for a model.
