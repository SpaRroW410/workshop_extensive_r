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
round(100 * colMeans(is.na(ncd)), 1)                                #@ colMeans
#% A (Q1): BMI 26.4%, HbA1c 20.5%, activity 12.2%, smoking 9.2%, SBP 5.9%; age, sex and education are complete.

# Q1. Which variables have missing values, and which have none?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: How many adults have complete data on every variable? What percentage is that?
sum(complete.cases(ncd))                                            #@ complete.cases
mean(complete.cases(ncd))
#% A (Q2): 905 adults (45%) are complete: complete-case analysis throws away more than half of the sample.

# Q2. What happens to the sample if you analyse only the complete cases?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: The missing-data PATTERNS: which combinations of missing variables occur, and how often?
md.pattern(dat, plot = FALSE)                                       #@ md.pattern
#% A: 26 patterns; the commonest after the complete one (905) is BMI alone missing (296), then HbA1c alone (196).

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: A summary table of missingness per variable, sorted by the percentage missing.
miss_var_summary(dat)                                               #@ miss_var_summary

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Plot the missing data: an UpSet plot of the most common combinations.
gg_miss_upset(dat, nsets = 5)                                       #@ gg_miss_upset

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Compare adults with and without BMI on the OBSERVED variables: mean age, mean SBP and share of men.
dat |> group_by(bmi_missing = is.na(bmi)) |> summarise(n = n(), age = mean(age), sbp = mean(sbp, na.rm = TRUE), men = mean(sex == "Male"))   #@ is.na(bmi)

#% A (Q6): adults with missing BMI are older (54 vs 45 years), more often men (63% vs 44%) and have a higher SBP (135 vs 121): not MCAR; missingness depends on observed variables, which is compatible with MAR.

# Q6. Is the missingness of BMI completely at random? What does the comparison suggest?

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Model the missingness of BMI (1 = missing) with a logistic model on age, sex, education and SBP.
m_miss <- glm(is.na(bmi) ~ age + sex + education + sbp, data = dat, family = binomial)   #@ family
round(summary(m_miss)$coefficients, 3)
#% A: age, male sex and especially SBP (0.106 per mmHg, z = 16) predict a missing BMI; education does not.

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Little's test of MCAR on the numeric variables (a small p-value rejects MCAR).
dat |> mutate(male = as.integer(sex == "Male")) |> select(age, male, bmi, smoker, activity, sbp, hba1c) |> mcar_test()   #@ mcar_test
#% A (Q8): p < 0.001: MCAR is rejected. No: rejecting MCAR does not prove MAR; MNAR cannot be tested from the observed data.

# Q8. If the test rejects MCAR, does that prove the data are MAR?

# ── Task 9 ──────────────────────────────────────────────────────
# Goal: HbA1c is missing for about one adult in five. Can you find out from the data whether the missing values are high or low? Compare the distribution of HbA1c among adults whose BMI is observed and missing (a hint only).
dat |> group_by(bmi_missing = is.na(bmi)) |> summarise(mean_hba1c = mean(hba1c, na.rm = TRUE), hba1c_missing = mean(is.na(hba1c)))   #@ mean(hba1c, na.rm = TRUE)
#% A: adults with a missing BMI have a higher observed HbA1c (5.48 vs 5.31) and more often a missing HbA1c (25% vs 19%): that is MAR information. But the data cannot show whether the missing HbA1c values themselves are high: MNAR cannot be tested from the observed data.
