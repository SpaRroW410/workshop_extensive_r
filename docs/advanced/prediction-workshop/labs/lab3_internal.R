# ═══════════════════════════════════════════════════════════════
# LAB 3 — Overfitting and internal validation
# Prediction models workshop | Session 3
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

m_true <- glm(f_true, data = dev, family = binomial)

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Add the ten extra markers (f_all) and compare the APPARENT AUC with the 8-predictor model. Count the number of parameters and the events per parameter.
m_all <- glm(___, data = dev, family = binomial)
c(true = auc_of(dev$diabetes, fitted(m_true)), all = auc_of(dev$diabetes, fitted(m_all)))
length(coef(m_all)) - 1
sum(dev$diabetes) / (length(coef(m_all)) - 1)

# Q1. Why does adding noise variables improve the apparent AUC?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: A random 70/30 split: fit the all-markers model on 70% and compute the AUC in the other 30%.
set.seed(1)
idx <- ___(nrow(dev), 0.7 * nrow(dev))
fit_s <- glm(f_all, data = dev[idx, ], family = binomial)
auc_of(dev$diabetes[-idx], predict(fit_s, dev[-idx, ], type = "response"))

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: 10-fold cross-validation: for each fold fit on the other nine and predict the held-out tenth; then compute one AUC on all the held-out predictions. Do it for both models.
set.seed(1)
fold <- sample(rep(1:10, length.out = nrow(dev)))
cv_auc <- function(form) { p <- numeric(nrow(dev)); for (k in 1:10) p[fold == k] <- predict(glm(form, data = dev[___, ], family = binomial), dev[fold == k, ], type = "response"); auc_of(dev$diabetes, p) }
c(true = cv_auc(f_true), all = cv_auc(f_all))

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: BOOTSTRAP optimism correction: repeat 200 times: draw a bootstrap sample, fit the model, compute the AUC in the bootstrap sample (apparent) and in the original data (test); the optimism is the mean difference. Corrected AUC = apparent - optimism.
optimism <- function(form, B = 200) { set.seed(7); mean(replicate(B, { i <- sample(nrow(dev), replace = TRUE); f <- glm(form, data = dev[i, ], family = binomial)
  auc_of(dev$diabetes[i], fitted(f)) - auc_of(dev$diabetes, predict(f, dev, ___)) })) }
o_true <- optimism(f_true); o_all <- optimism(f_all)
c(optimism_true = o_true, optimism_all = o_all)

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: The optimism-corrected AUC of both models.
c(true = auc_of(dev$diabetes, fitted(m_true)) ___, all = auc_of(dev$diabetes, fitted(m_all)) - o_all)

# Q5. Which AUC should you report for a development study?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Optimism in the calibration slope: in each bootstrap sample, fit the model, then compute the slope of the linear predictor in the ORIGINAL data (the average of these slopes is a shrinkage factor).
slope_boot <- function(form, B = 200) { set.seed(7); mean(replicate(B, { i <- sample(nrow(dev), replace = TRUE); f <- glm(form, data = dev[i, ], family = binomial)
  coef(glm(diabetes ~ ___, data = transform(dev, lp = predict(f, dev)), family = binomial))[["lp"]] })) }
c(true = slope_boot(f_true), all = slope_boot(f_all))
