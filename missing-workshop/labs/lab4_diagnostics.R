# ═══════════════════════════════════════════════════════════════
# LAB 4 — Diagnostics, derived variables and the number of imputations
# Missing data workshop | Session 4
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(mice); library(naniar) })
theme_set(theme_minimal(base_size = 14))

p <- c("data/ncd_missing.csv", "../data/ncd_missing.csv", "../../data/ncd_missing.csv"); p <- p[file.exists(p)][1]
ncd <- read_csv(p, show_col_types = FALSE) |> mutate(sex = factor(sex), education = factor(education, levels = c("None", "Primary", "Secondary+")))
dat <- ncd |> select(-id)                          # the id must not enter the imputation model

dat2 <- dat |> mutate(smoker = factor(smoker, labels = c("No", "Yes")))
imp <- mice(dat2, m = 20, maxit = 10, seed = 2038, printFlag = FALSE)

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: The fraction of missing information (fmi) and lambda for each coefficient of the pooled model.
fit <- with(imp, lm(sbp ~ age + sex + bmi + smoker + activity))
summary(pool(fit))
pool(fit)$pooled[, c("term", "___", "lambda")]

# Q1. What does an fmi of 0.3 mean?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: How many imputations are needed? Repeat the whole imputation with m = 5 and with m = 50 for SIX different seeds and compare the range of the pooled SE of BMI.
se_bmi <- function(m, seed) { i <- mice(dat2, m = m, maxit = 10, seed = seed, printFlag = FALSE); s <- summary(pool(with(i, lm(sbp ~ age + sex + bmi + smoker + activity)))); s$std.error[s$term == "bmi"] }
___(c(m5 = 5, m50 = 50), function(m) round(range(sapply(1:6, function(seed) se_bmi(m, seed))), 3))

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: A DERIVED variable: hypertension (SBP of 140 or more). Impute SBP first and derive hypertension INSIDE each completed data set; then fit a logistic model with the pooled result.
long <- complete(imp, "long", ___ = TRUE) |> mutate(htn = as.integer(sbp >= 140))
imp_h <- ___(long)
fit_h <- with(imp_h, glm(htn ~ age + sex + bmi + smoker, family = binomial))
summary(pool(fit_h), conf.int = TRUE, exponentiate = TRUE) |> select(term, estimate, `2.5 %`, `97.5 %`) |> mutate(across(where(is.numeric), \(x) round(x, 2)))

# Q3. Why is it wrong to dichotomise SBP BEFORE imputation?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Test an INTERACTION in imputed data: does the BMI effect on SBP differ by sex? Fit the models with and without the product term in each data set and compare them with the pooled Wald test (D1).
fit_full <- with(imp, lm(sbp ~ age + ___ + smoker + activity))
fit_red <- with(imp, lm(sbp ~ age + sex + bmi + smoker + activity))
D1(fit_full, fit_red)

# Q4. Why should the imputation model include the interactions that you plan to test?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: AUXILIARY variables: HbA1c is not in the SBP model but predicts BMI and SBP. Impute WITHOUT hba1c in the imputation model and compare the BMI coefficient with the full imputation.
imp_no <- mice(dat2 |> select(-___), m = 20, maxit = 10, seed = 2038, printFlag = FALSE)
b_no <- summary(pool(with(imp_no, lm(sbp ~ age + sex + bmi + smoker + activity))))
b_full <- summary(pool(fit))
c(without_aux = b_no$estimate[b_no$term == "bmi"], with_aux = b_full$estimate[b_full$term == "bmi"])
