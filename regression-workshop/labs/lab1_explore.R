# ═══════════════════════════════════════════════════════════════
# LAB 1 — Meet the data: import, explore, Table 1
# Theory of Regression Analysis workshop | Session 1
# Dataset: simulated adult NCD survey (n = 600, ~20 villages)
# How to work: run each task top-to-bottom. Replace every ___ with
# the missing code. Hints describe the GOAL, not the answer.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({
  library(tidyverse)
  library(gtsummary)
  library(broom)
  library(performance)
  library(see)
  library(car)
  library(lmtest)
  library(pROC)
})
theme_set(theme_minimal(base_size = 14))

# The data file lives in the repo's data/ folder. This finds it whether
# you opened the script from the repo root, regression-workshop/, or labs/.
csv_path <- c("data/ncd_survey.csv", "../data/ncd_survey.csv", "../../data/ncd_survey.csv")
csv_path <- csv_path[file.exists(csv_path)][1]

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Import the survey from the comma-separated file at csv_path
# into a data frame called ncd.
ncd <- ___(csv_path)

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Get a compact overview that lists every column with its type
# and its first few values. How many people and variables are there?
___(ncd)

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Count the missing values in each column. (Which variables
# have missing data, and roughly what percentage is that?)
ncd |>
  summarise(across(everything(), ~ sum(___(.x))))


# Q1. Which variables have missing values, and what share of 600 is missing?
#     What would "complete-case analysis" do to your sample size in a model
#     that uses all three?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Tell R which columns are categorical. The code below converts
# text columns into categorical variables with a sensible order of
# levels. Fill in the function that does the conversion.
ncd <- ncd |>
  mutate(
    sex       = ___(sex, levels = c("Female", "Male")),
    residence = ___(residence, levels = c("Urban", "Rural")),
    education = ___(education, levels = c("No schooling", "Primary", "Secondary", "Graduate+")),
    tobacco   = factor(tobacco, levels = c("No", "Yes")),
    alcohol   = factor(alcohol, levels = c("No", "Yes")),
    phys_act  = factor(phys_act, levels = c("low", "moderate", "high")),
    htn_f     = factor(htn, levels = 0:1, labels = c("No HTN", "HTN"))
  )

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Build "Table 1": summarise age, sex, residence, education, BMI,
# salt intake, tobacco, alcohol and physical activity, with one column
# per hypertension group, and add an overall column and p-values.
table1 <- ncd |>
  select(age, sex, residence, education, bmi, salt_g, tobacco, alcohol, phys_act, htn_f) |>
  ___(
    by = ___,
    missing_text = "(Missing)"
  ) |>
  ___() |>
  ___()
table1


# Q2. Look at the HTN vs No-HTN columns. Which characteristics differ the most?
#     Can Table 1 tell you whether salt *causes* hypertension? Why / why not?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Plot systolic BP (y) against daily salt intake (x) as points,
# and overlay a fitted straight-line trend with its uncertainty band.
ggplot(ncd, aes(x = salt_g, y = sbp)) +
  ___(alpha = 0.5, colour = "#3498db") +
  geom_smooth(method = ___, colour = "#e74c3c") +
  labs(x = "Salt intake (g/day)", y = "Systolic BP (mmHg)")

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Compute the correlation between SBP and salt intake. Some rows
# have missing salt values, so tell the function to keep only the rows
# where both values are present.
___(ncd$sbp, ncd$salt_g, ___ = "complete.obs")

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Produce the full correlation matrix for the numeric
# measurements age, bmi, waist, salt_g, sbp and dbp (round to 2 dp).
ncd |>
  select(age, bmi, waist, salt_g, sbp, dbp) |>
  ___(use = "pairwise.complete.obs") |>
  round(2)


# Q3. Which pair of variables is most strongly correlated? Why might that
#     matter later when both go into one regression model?
# Q4. Correlation between SBP and salt is a single number. What extra thing
#     will regression give you that correlation cannot?
