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
cox1 <- coxph(Surv(time_months, status) ~ hiv, data = tb)        #@ coxph || hiv
summary(cox1)

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Hazard ratio and its 95% CI for HIV-positive vs negative.
exp(cbind(HR = coef(cox1), confint(cox1)))                    #@ exp || confint
#% A (Q2): HR about 1.8 (95% CI about 1.1 to 2.9): at any time the hazard of death is about 80% higher in HIV-positive patients. A hazard ratio compares rates (hazards), not risks; it is not a risk ratio.

# Q2. Interpret the hazard ratio in one sentence. Is it a risk ratio?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Fit the adjusted model: age, sex, HIV, diabetes, smoking, BMI, MDR-TB and treatment.
cox_full <- coxph(Surv(time_months, status) ~ age + sex + hiv + diabetes + smoker + bmi + mdr_tb + treatment, data = tb)   #@ age + sex || mdr_tb
summary(cox_full)$coefficients

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: A publication table of hazard ratios with CIs and p-values.
tbl_regression(cox_full, exponentiate = TRUE)                       #@ tbl_regression || exponentiate

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Age is in years. Refit with age in 10-year units to get the HR per 10 years.
cox_age10 <- coxph(Surv(time_months, status) ~ I(age / 10) + hiv + mdr_tb + treatment, data = tb)   #@ I(age / 10)
exp(coef(cox_age10))["I(age/10)"]
#% A (Q5): about 1.16 per 10 years (HR per year about 1.015 compounded over 10 years).

# Q5. Why rescale age to 10-year units before reporting?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Number of events per estimated coefficient (a rule of thumb asks for about 10 or more).
sum(tb$status) / length(coef(cox_full))                             #@ length || coef
#% A (Q6): about 113 / 8 = 14: acceptable (the rule of thumb is about 10 events per coefficient). With too few events the estimates are unstable and the model overfits.

# Q6. What is the problem with too few events per variable?

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Does DOT lower the hazard after adjustment? Read the HR of treatment from the model.
exp(coef(cox_full))["treatmentDOT"]                                 #@ treatmentDOT
#% A (Q7): about 0.57: about 43% lower hazard of death with DOT than with self-administered treatment, holding the other variables fixed.

# Q7. Interpret the DOT hazard ratio (reference = self-administered).

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Compare the adjusted HR for HIV with the crude one. Did adjustment change it?
c(crude = exp(coef(cox1))[["hivPositive"]], adjusted = exp(coef(cox_full))[["hivPositive"]])   #@ hivPositive
#% A: crude about 1.8 and adjusted about 2.0: a modest change; HIV is only slightly confounded by the other measured variables.

# ── Task 9 ──────────────────────────────────────────────────────
# Goal: Predicted survival curve for a 40-year-old DOT patient without HIV, MDR-TB or diabetes.
nd <- data.frame(age = 40, sex = "Male", hiv = "Negative", diabetes = "No", smoker = "No", bmi = 20, mdr_tb = "No", treatment = "DOT")
nd[] <- lapply(names(nd), \(v) if (is.factor(tb[[v]])) factor(nd[[v]], levels = levels(tb[[v]])) else nd[[v]])
summary(survfit(cox_full, newdata = nd), times = c(12, 24))$surv    #@ survfit || newdata
