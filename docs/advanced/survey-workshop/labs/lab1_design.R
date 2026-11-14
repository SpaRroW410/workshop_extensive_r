# ═══════════════════════════════════════════════════════════════
# LAB 1 — Survey design: strata, PSUs and weights
# Survey data and weights workshop | Session 1
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


# ── Task 1 ──────────────────────────────────────────────────────
# Goal: How many adults were sampled, how many responded, and what is the response rate?
___(adults$responded)
mean(adults$responded)

# Q1. Why must a survey report the response rate?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Look at the design variables: how many strata and how many PSUs (clusters) are there among the respondents?
___(resp$stratum)
n_distinct(resp$psu)

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: The UNWEIGHTED (raw) prevalence of hypertension among respondents.
___(resp$hypertension)

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: The WEIGHTED prevalence of hypertension using the survey weights.
___(resp$hypertension, resp$weight)

# Q4. Why do the two prevalences differ? Which one describes the population?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Compare the share of urban adults in the sample (unweighted) with the weighted share.
round(100 * prop.table(table(resp$residence)), 1)
round(100 * prop.table(___(weight ~ residence, data = resp)), 1)

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Declare the survey design: PSUs as clusters, strata and weights (nest = TRUE says that PSU labels only need to be unique within a stratum).
des <- svydesign(___ = ~psu, ___ = ~stratum, weights = ~weight, data = resp, nest = TRUE)
summary(des)

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: The sum of the weights estimates the number of adults in the population.
___(weights(des))

# Q7. What does a weight of 200 mean?

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: The prevalence with the survey design, giving a design-based standard error.
___(~hypertension, des)

# ── Task 9 ──────────────────────────────────────────────────────
# Goal: The naive standard error of a proportion, treating respondents as a simple random sample: sqrt(p (1 - p) / n).
p <- mean(resp$hypertension)
___(p * (1 - p) / nrow(resp))
