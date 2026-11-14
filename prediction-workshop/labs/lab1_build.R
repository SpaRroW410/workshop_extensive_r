# ═══════════════════════════════════════════════════════════════
# LAB 1 — Building a risk model
# Prediction models workshop | Session 1
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(pROC); library(glmnet) })
theme_set(theme_minimal(base_size = 14))

rd <- function(f) { p <- c(file.path("data", f), file.path("..", "data", f), file.path("..", "..", "data", f)); read_csv(p[file.exists(p)][1], show_col_types = FALSE) |> mutate(sex = factor(sex)) }
dev <- rd("diabetes_dev.csv")          # development cohort (700 adults)
val <- rd("diabetes_valid.csv")        # external validation cohort (2,000 adults) - used in Lab 5 only
f_true <- diabetes ~ age + sex + bmi + waist + fam_history + hypertension + activity + smoker       # the 8 real predictors
f_all  <- update(f_true, . ~ . + m1 + m2 + m3 + m4 + m5 + m6 + m7 + m8 + m9 + m10)                  # plus 10 extra lab markers
auc_of <- function(y, p) as.numeric(pROC::auc(y, p, quiet = TRUE))

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: How many adults are in the development cohort, how many have diabetes, and what is the prevalence?
___(dev)
sum(dev$diabetes)
mean(dev$diabetes)

# Q1. What limits the number of predictors you can use: the number of adults or the number of events?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Events per variable (EPV): the number of events divided by the number of candidate predictor parameters of the 8-predictor model (sex is one parameter).
sum(dev$diabetes) ___

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Fit a logistic regression with the 8 real predictors (f_true) and show the odds ratios.
m1 <- glm(___, data = dev, family = binomial)
round(exp(coef(m1)), 3)

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: The predicted RISK of diabetes of every adult, and its distribution.
dev$risk <- predict(m1, type = "___")
summary(dev$risk)
mean(dev$risk)

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: The risk for a NEW patient: a 55-year-old man with BMI 29, waist 100 cm, a family history, hypertension, 2 hours of activity per week, non-smoker.
new <- data.frame(age = 55, sex = factor("Male", levels = levels(dev$sex)), bmi = 29, waist = 100, fam_history = 1, hypertension = 1, activity = 2, smoker = 0)
predict(m1, ___ = new, type = "response")

# Q5. Why is a predicted risk more useful to a clinician than an odds ratio?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Risk groups: below 5%, 5 to 15%, and 15% or more; count the adults and the observed prevalence of diabetes in each group.
dev |> mutate(group = ___(risk, c(0, 0.05, 0.15, 1), labels = c("low", "medium", "high"), include.lowest = TRUE)) |> group_by(group) |> summarise(n = n(), observed = mean(diabetes))

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Why the apparent performance is optimistic: compare the distribution of the predictors (age, BMI) between the development and the validation cohorts.
___(development = c(age = mean(dev$age), bmi = mean(dev$bmi), prevalence = mean(dev$diabetes)), validation = c(age = mean(val$age), bmi = mean(val$bmi), prevalence = mean(val$diabetes)))
