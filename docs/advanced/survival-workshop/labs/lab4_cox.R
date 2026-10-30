# ═══════════════════════════════════════════════════════════════
# LAB 4 — Cox proportional hazards regression
# Survival analysis workshop | Session 4
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(survival); library(broom); library(gtsummary); library(ggsurvfit) })
theme_set(theme_minimal(base_size = 14))

tb_path <- c("data/tb_cohort.csv", "../data/tb_cohort.csv", "../../data/tb_cohort.csv")
tb_path <- tb_path[file.exists(tb_path)][1]
tb <- read_csv(tb_path, show_col_types = FALSE) |>
  mutate(sex = factor(sex, levels = c("Female", "Male")), hiv = factor(hiv, levels = c("Negative", "Positive")),
         diabetes = factor(diabetes, levels = c("No", "Yes")), smoker = factor(smoker, levels = c("No", "Yes")),
         mdr_tb = factor(mdr_tb, levels = c("No", "Yes")), smear = factor(smear, levels = c("Negative", "Positive")),
         treatment = factor(treatment, levels = c("Self-administered", "DOT")))

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Fit a Cox model with HIV status as the only predictor.
cox1 <- ___(Surv(time_months, status) ~ ___, data = tb)
summary(cox1)

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Hazard ratio and its 95% CI for HIV-positive vs negative.
___(cbind(HR = coef(cox1), ___(cox1)))

# Q2. Interpret the hazard ratio in one sentence. Is it a risk ratio?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Fit the adjusted model: age, sex, HIV, diabetes, smoking, BMI, MDR-TB and treatment.
cox_full <- coxph(Surv(time_months, status) ~ ___ + hiv + diabetes + smoker + bmi + ___ + treatment, data = tb)
summary(cox_full)$coefficients

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: A publication table of hazard ratios with CIs and p-values.
___(cox_full, ___ = TRUE)

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Age is in years. Refit with age in 10-year units to get the HR per 10 years.
cox_age10 <- coxph(Surv(time_months, status) ~ ___ + hiv + mdr_tb + treatment, data = tb)
exp(coef(cox_age10))["I(age/10)"]

# Q5. Why rescale age to 10-year units before reporting?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Number of events per estimated coefficient (a rule of thumb asks for about 10 or more).
sum(tb$status) / ___(___(cox_full))

# Q6. What is the problem with too few events per variable?

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Does DOT lower the hazard after adjustment? Read the HR of treatment from the model.
exp(coef(cox_full))["___"]

# Q7. Interpret the DOT hazard ratio (reference = self-administered).

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Compare the adjusted HR for HIV with the crude one. Did adjustment change it?
c(crude = exp(coef(cox1))[["___"]], adjusted = exp(coef(cox_full))[["hivPositive"]])

# ── Task 9 ──────────────────────────────────────────────────────
# Goal: Predicted survival curve for a 40-year-old DOT patient without HIV, MDR-TB or diabetes.
nd <- data.frame(age = 40, sex = "Male", hiv = "Negative", diabetes = "No", smoker = "No", bmi = 20, mdr_tb = "No", treatment = "DOT")
nd[] <- lapply(names(nd), \(v) if (is.factor(tb[[v]])) factor(nd[[v]], levels = levels(tb[[v]])) else nd[[v]])
summary(___(cox_full, ___ = nd), times = c(12, 24))$surv
