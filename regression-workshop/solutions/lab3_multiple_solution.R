# ═══════════════════════════════════════════════════════════════
# LAB 3 — Inference and multiple linear regression
# Theory of Regression Analysis workshop | Session 3
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

# Complete cases: model comparison and step() need EXACTLY the same rows
# in every model, so we keep only people with no missing model variable.
cc <- ncd |>
  drop_na(sbp, salt_g, age, bmi, waist, sex, residence, education, tobacco, alcohol, phys_act)
nrow(cc)

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Fit the CRUDE model: SBP explained by salt intake alone (use cc).
m_crude <- lm(sbp ~ salt_g, data = cc)                           #@ sbp ~ salt_g

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Fit an ADJUSTED model: SBP explained by salt intake while also
# accounting for age, BMI, sex, residence, education, tobacco, alcohol
# and physical activity.
m_adj <- lm(sbp ~ salt_g + age + bmi + sex + residence + education +   #@ salt_g + age + bmi
              tobacco + alcohol + phys_act, data = cc)

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Get the 95% confidence intervals for every coefficient of the
# adjusted model.
confint(m_adj)                                                   #@ confint

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Compare the salt coefficient in the crude and adjusted models,
# and compute by what percentage it changed.
b_crude <- coef(m_crude)["salt_g"]
b_adj   <- coef(m_adj)["salt_g"]                                 #@ coef
c(crude = b_crude, adjusted = b_adj)
100 * (b_crude - b_adj) / b_crude                                #@ b_crude - b_adj

#% A (Q1): 3.4 -> 1.8 mmHg/g, about a 46% drop. Age and BMI confound salt->SBP (older/heavier people eat more salt AND have higher SBP).

# Q1. By how much did the salt β shrink after adjustment? Which variables
#     caused it, and why does that fit the way the data were generated?
# Q2. In the adjusted model, interpret the salt β in one sentence with units.

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Build a table of CRUDE results (each covariate on its own against
# SBP, one model per covariate) and a table for the ADJUSTED model, then
# place them side by side with spanners "Crude" and "Adjusted".
t_crude <- cc |>
  select(sbp, salt_g, age, bmi, sex, residence, education, tobacco, alcohol, phys_act) |>
  tbl_uvregression(method = lm, y = sbp)                          #@ tbl_uvregression || y = sbp
t_adj <- tbl_regression(m_adj)                                    #@ tbl_regression
tbl_merge(                                                        #@ tbl_merge
  tbls = list(t_crude, t_adj),
  tab_spanner = c("**Crude**", "**Adjusted**")
)

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Look at the dummy-coded categorical variables in m_adj.
# Which level is the reference for education? Then change the reference
# to the highest education level and refit; watch how coefficients move.
levels(cc$education)
cc$education2 <- relevel(cc$education, ref = "Graduate+")        #@ relevel
m_adj2 <- lm(sbp ~ salt_g + age + bmi + sex + residence + education2 +
               tobacco + alcohol + phys_act, data = cc)
tidy(m_adj2) |> filter(str_detect(term, "education"))

#% A (Q3): ref was "No schooling"; the new coefficients compare each level with Graduate+ (signs flip, same fit, same salt β).

# Q3. Did the overall fit or the salt β change when the reference changed?
#     What changed, and why does the reference matter for reporting?

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Run automated selection (guided by AIC) that STARTS from an
# intercept-only model and can only ADD terms. Candidate predictors: the
# adjusted-model variables PLUS waist circumference (a close cousin of BMI).
m_null <- lm(sbp ~ 1, data = cc)
m_full <- lm(sbp ~ salt_g + age + bmi + waist + sex + residence + education +
               tobacco + alcohol + phys_act, data = cc)
fwd <- step(m_null, scope = formula(m_full), direction = "forward", trace = 0)   #@ forward

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Run automated selection (guided by AIC) that STARTS from the full
# model and can only REMOVE terms.
bwd <- step(m_full, direction = "backward", trace = 0)           #@ backward

# ── Task 9 ──────────────────────────────────────────────────────
# Goal: Run automated selection that starts from the full model and, at
# each step, may add a term back OR remove one.
both <- step(m_full, direction = "both", trace = 0)              #@ both

# ── Task 10 ─────────────────────────────────────────────────────
# Goal: Compare which variables each approach kept, plus the AIC, the
# salt coefficient and its standard error from each final model.
sel <- list(forward = fwd, backward = bwd, both = both, full = m_full)
map_dfr(sel, ~ tibble(
  n_terms = length(coef(.x)) - 1,
  AIC     = AIC(.x),
  salt_b  = coef(.x)["salt_g"],
  salt_se = summary(.x)$coefficients["salt_g", "Std. Error"]
), .id = "strategy")
map(sel, ~ formula(.x))

#% A (Q4): forward keeps waist, backward/both keep bmi (they are near-duplicates); AIC differs by ~1. The salt β is stable (~1.8) because salt is retained either way, but WHICH adiposity variable "wins" is arbitrary. The selection path ignores confounding logic: a confounder with a weak p can be dropped.

# Q4. Do the three strategies keep the same variables? Which adiposity
#     measure did each choose, and is the AIC difference meaningful?
# Q5. Give two reasons why you should NOT present step() output as "the"
#     model in your thesis. What would you do instead?
