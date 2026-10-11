# ═══════════════════════════════════════════════════════════════
# LAB 6 — Reporting: a publication-ready table and a write-up
# Theory of Regression Analysis workshop | Session 6
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({
  library(tidyverse); library(gtsummary); library(broom); library(performance)
  library(see); library(car); library(lmtest); library(pROC)
})
theme_set(theme_minimal(base_size = 14))

csv_path <- c("data/ncd_survey.csv", "../data/ncd_survey.csv", "../../data/ncd_survey.csv")
csv_path <- csv_path[file.exists(csv_path)][1]
ncd <- read_csv(csv_path, show_col_types = FALSE) |>
  mutate(
    sex = factor(sex, levels = c("Female", "Male")),
    residence = factor(residence, levels = c("Urban", "Rural")),
    education = factor(education, levels = c("No schooling", "Primary", "Secondary", "Graduate+")),
    tobacco = factor(tobacco, levels = c("No", "Yes")),
    alcohol = factor(alcohol, levels = c("No", "Yes")),
    phys_act = factor(phys_act, levels = c("low", "moderate", "high")),
    htn_f = factor(htn, levels = 0:1, labels = c("No HTN", "HTN"))
  )

cc <- ncd |>
  drop_na(sbp, htn, salt_g, age, bmi, sex, residence, education, tobacco, alcohol, phys_act)

# Variable labels make the final table readable by a thesis examiner.
labs <- list(salt_g ~ "Salt intake (per 1 g/day)", age ~ "Age (per year)",
             bmi ~ "BMI (per kg/m²)", sex ~ "Sex", residence ~ "Residence",
             education ~ "Education", tobacco ~ "Tobacco use", alcohol ~ "Alcohol use",
             phys_act ~ "Physical activity")

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Fit the final adjusted LINEAR model (outcome SBP) and the final
# adjusted LOGISTIC model (outcome hypertension) with the same predictors.
m_lin <- lm(sbp ~ salt_g + age + bmi + sex + residence + education +   #@ lm
              tobacco + alcohol + phys_act, data = cc)
m_log <- glm(htn ~ salt_g + age + bmi + sex + residence + education +   #@ glm
               tobacco + alcohol + phys_act, data = cc, family = binomial)

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Make one nicely formatted table per model, showing the readable
# display names defined above. The logistic table must show odds ratios.
t_lin <- tbl_regression(m_lin, label = labs) |>                    #@ tbl_regression || label
  bold_labels()
t_log <- tbl_regression(m_log, exponentiate = TRUE, label = labs) |>   #@ exponentiate
  bold_labels()

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Combine the two tables side by side. Name the spanners
# "Systolic BP (β, mmHg)" and "Hypertension (OR)", and rename the
# estimate columns accordingly.
t_final <- tbl_merge(                                             #@ tbl_merge
  tbls = list(t_lin, t_log),
  tab_spanner = c("**Systolic BP (linear)**", "**Hypertension (logistic)**")
) |>
  modify_header(estimate_1 ~ "**β (mmHg)**", estimate_2 ~ "**OR**") |>   #@ modify_header
  modify_footnote(all_stat_cols() ~ "β = adjusted regression coefficient; OR = adjusted odds ratio; CI = 95% confidence interval")
t_final

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Pull the numbers for salt straight from the tables so your text
# is never retyped by hand (this avoids transcription errors).
inline_text(t_lin, variable = "salt_g")                          #@ inline_text
inline_text(t_log, variable = "salt_g")

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Collect model-performance numbers for the Methods/Results text:
# R² and adjusted R² of the linear model; AUC and Tjur R² of the logistic one.
r2(m_lin)                                                        #@ r2
performance::performance_roc(m_log)                              #@ performance_roc
r2_tjur(m_log)

# ── Task 6 (writing) ────────────────────────────────────────────
# Goal: Complete the structured write-up below IN THE COMMENTS (or in a
# Word/Quarto file). Use the table above — no answers are given here.
#
# METHODS
#   "We used ____ regression to examine the association between daily salt
#    intake (g/day) and ____ in ____ adults aged 30-69 years. Covariates
#    (____) were chosen a priori on the basis of ____ [DAG / literature],
#    not by automated selection. We checked ____ (list 3 assumptions).
#    Analyses were done in R version ____ using ____ [packages]."
#
# RESULTS (linear)
#   "Each 1 g/day higher salt intake was associated with a ____ mmHg higher
#    SBP (95% CI ____ to ____), after adjusting for ____. The model
#    explained ____% of the variance (adjusted R² = ____)."
#
# RESULTS (logistic)
#   "The odds of hypertension were ____ times higher (aOR ____; 95% CI ____
#    to ____) for each additional ____ of salt per day. The model showed
#    ____ discrimination (AUC = ____)."
#
# LIMITATIONS (one sentence)
#   "Because ____, we cannot infer ____."
#
#% A (model answers)
#%  Methods: "We used multiple linear regression ... in 600 adults aged 30-69 ... covariates age, BMI, sex, residence, education, tobacco, alcohol and physical activity chosen a priori from a DAG ... linearity, homoscedasticity, normality of residuals, collinearity (VIF) and independence (village clustering) were checked ... R 4.x with tidyverse, gtsummary, performance."
#%  Linear: "Each 1 g/day higher salt intake was associated with a 1.8 mmHg higher SBP (95% CI 1.2 to 2.4) after adjusting for ... The model explained 39% of the variance (adjusted R² = 0.37)."
#%  Logistic: "The odds of hypertension were 1.24 times higher (aOR 1.24; 95% CI 1.11 to 1.39) per additional g/day of salt. Discrimination was good (AUC = 0.82)."
#%  Limitations: "Because the survey is cross-sectional and villages are clustered, we cannot infer causation and CIs may be too narrow."

# Q1. Which two numbers from the table would a reader need to judge both the
#     size and the precision of the salt effect?
# Q2. Name two things this analysis did NOT address that a reviewer might ask about.
#% A (Q2): clustering by village (mixed model/GEE), residual confounding/measurement error in salt (self-report), selection/missing data (complete-case), causal direction.
