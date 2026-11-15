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
table(adults$responded)                                             #@ table
mean(adults$responded)
#% A (Q1): 2,504 sampled, 1,853 responded: a response rate of about 74%.

# Q1. Why must a survey report the response rate?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Look at the design variables: how many strata and how many PSUs (clusters) are there among the respondents?
n_distinct(resp$stratum)                                            #@ n_distinct
n_distinct(resp$psu)
#% A (Q2): 8 strata and 48 PSUs (6 per stratum).

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: The UNWEIGHTED (raw) prevalence of hypertension among respondents.
mean(resp$hypertension)                                             #@ mean
#% A (Q3): about 0.233 (23.3%).

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: The WEIGHTED prevalence of hypertension using the survey weights.
weighted.mean(resp$hypertension, resp$weight)                       #@ weighted.mean
#% A (Q4): about 0.200 (20.0%): lower, because urban adults (more hypertension) are over-represented in the sample and get smaller weights.

# Q4. Why do the two prevalences differ? Which one describes the population?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Compare the share of urban adults in the sample (unweighted) with the weighted share.
round(100 * prop.table(table(resp$residence)), 1)
round(100 * prop.table(xtabs(weight ~ residence, data = resp)), 1)  #@ xtabs
#% A (Q5): about 50% urban in the sample, but only about 28% in the weighted (population) estimate.

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Declare the survey design: PSUs as clusters, strata and weights (nest = TRUE says that PSU labels only need to be unique within a stratum).
des <- svydesign(ids = ~psu, strata = ~stratum, weights = ~weight, data = resp, nest = TRUE)   #@ ids || strata
summary(des)
#% A (Q6): 48 clusters in 8 strata, weights from about 93 to 490.

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: The sum of the weights estimates the number of adults in the population.
sum(weights(des))                                                   #@ sum
#% A (Q7): about 414,000 adults (each respondent represents on average 220 adults).

# Q7. What does a weight of 200 mean?

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: The prevalence with the survey design, giving a design-based standard error.
svymean(~hypertension, des)                                         #@ svymean
#% A (Q8): about 0.200 with SE about 0.015.

# ── Task 9 ──────────────────────────────────────────────────────
# Goal: The naive standard error of a proportion, treating respondents as a simple random sample: sqrt(p (1 - p) / n).
p <- mean(resp$hypertension)
sqrt(p * (1 - p) / nrow(resp))                                      #@ sqrt
#% A (Q9): about 0.0098: about one third smaller than the design-based SE (0.015); ignoring the design makes the estimate look too precise.
