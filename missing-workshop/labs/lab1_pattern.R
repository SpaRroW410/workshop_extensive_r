# ═══════════════════════════════════════════════════════════════
# LAB 1 — Describing missing data and its mechanism
# Missing data workshop | Session 1
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(mice); library(naniar) })
theme_set(theme_minimal(base_size = 14))

p <- c("data/ncd_missing.csv", "../data/ncd_missing.csv", "../../data/ncd_missing.csv"); p <- p[file.exists(p)][1]
ncd <- read_csv(p, show_col_types = FALSE) |> mutate(sex = factor(sex), education = factor(education, levels = c("None", "Primary", "Secondary+")))
dat <- ncd |> select(-id)                          # the id must not enter the imputation model

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: The percentage of missing values in each variable.
round(100 * ___(is.na(ncd)), 1)

# Q1. Which variables have missing values, and which have none?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: How many adults have complete data on every variable? What percentage is that?
sum(___(ncd))
mean(complete.cases(ncd))

# Q2. What happens to the sample if you analyse only the complete cases?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: The missing-data PATTERNS: which combinations of missing variables occur, and how often?
___(dat, plot = FALSE)

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: A summary table of missingness per variable, sorted by the percentage missing.
___(dat)

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Plot the missing data: an UpSet plot of the most common combinations.
___(dat, nsets = 5)

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Compare adults with and without BMI on the OBSERVED variables: mean age, mean SBP and share of men.
dat |> group_by(bmi_missing = ___) |> summarise(n = n(), age = mean(age), sbp = mean(sbp, na.rm = TRUE), men = mean(sex == "Male"))


# Q6. Is the missingness of BMI completely at random? What does the comparison suggest?

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Model the missingness of BMI (1 = missing) with a logistic model on age, sex, education and SBP.
m_miss <- glm(is.na(bmi) ~ age + sex + education + sbp, data = dat, ___ = binomial)
round(summary(m_miss)$coefficients, 3)

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Little's test of MCAR on the numeric variables (a small p-value rejects MCAR).
dat |> mutate(male = as.integer(sex == "Male")) |> select(age, male, bmi, smoker, activity, sbp, hba1c) |> ___()

# Q8. If the test rejects MCAR, does that prove the data are MAR?

# ── Task 9 ──────────────────────────────────────────────────────
# Goal: HbA1c is missing for about one adult in five. Can you find out from the data whether the missing values are high or low? Compare the distribution of HbA1c among adults whose BMI is observed and missing (a hint only).
dat |> group_by(bmi_missing = is.na(bmi)) |> summarise(mean_hba1c = ___, hba1c_missing = mean(is.na(hba1c)))
