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
m_all <- glm(f_all, data = dev, family = binomial)                  #@ f_all
c(true = auc_of(dev$diabetes, fitted(m_true)), all = auc_of(dev$diabetes, fitted(m_all)))
length(coef(m_all)) - 1
sum(dev$diabetes) / (length(coef(m_all)) - 1)
#% A (Q1): the apparent AUC rises from 0.796 to 0.821 although the 10 markers are pure noise; 18 parameters leave only about 4.7 events per parameter.

# Q1. Why does adding noise variables improve the apparent AUC?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: A random 70/30 split: fit the all-markers model on 70% and compute the AUC in the other 30%.
set.seed(1)
idx <- sample(nrow(dev), 0.7 * nrow(dev))                           #@ sample
fit_s <- glm(f_all, data = dev[idx, ], family = binomial)
auc_of(dev$diabetes[-idx], predict(fit_s, dev[-idx, ], type = "response"))
#% A (Q2): about 0.74 with this seed (it changes noticeably with the split seed): a third of an already small sample is wasted and the estimate is noisy.

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: 10-fold cross-validation: for each fold fit on the other nine and predict the held-out tenth; then compute one AUC on all the held-out predictions. Do it for both models.
set.seed(1)
fold <- sample(rep(1:10, length.out = nrow(dev)))
cv_auc <- function(form) { p <- numeric(nrow(dev)); for (k in 1:10) p[fold == k] <- predict(glm(form, data = dev[fold != k, ], family = binomial), dev[fold == k, ], type = "response"); auc_of(dev$diabetes, p) }   #@ fold != k
c(true = cv_auc(f_true), all = cv_auc(f_all))
#% A (Q3): about 0.77 for the 8-predictor model and 0.76 for the all-markers model: honest estimates, lower than the apparent 0.80 and 0.82; the markers bring no gain.

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: BOOTSTRAP optimism correction: repeat 200 times: draw a bootstrap sample, fit the model, compute the AUC in the bootstrap sample (apparent) and in the original data (test); the optimism is the mean difference. Corrected AUC = apparent - optimism.
optimism <- function(form, B = 200) { set.seed(7); mean(replicate(B, { i <- sample(nrow(dev), replace = TRUE); f <- glm(form, data = dev[i, ], family = binomial)
  auc_of(dev$diabetes[i], fitted(f)) - auc_of(dev$diabetes, predict(f, dev, type = "response")) })) }   #@ type = "response"
o_true <- optimism(f_true); o_all <- optimism(f_all)
c(optimism_true = o_true, optimism_all = o_all)
#% A (Q4): about 0.020 for the 8 predictors and 0.042 for the all-markers model.

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: The optimism-corrected AUC of both models.
c(true = auc_of(dev$diabetes, fitted(m_true)) - o_true, all = auc_of(dev$diabetes, fitted(m_all)) - o_all)   #@ - o_true
#% A: about 0.776 and 0.779: the same; the ten markers add nothing real, the apparent gain (0.796 to 0.821) was optimism.

# Q5. Which AUC should you report for a development study?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Optimism in the calibration slope: in each bootstrap sample, fit the model, then compute the slope of the linear predictor in the ORIGINAL data (the average of these slopes is a shrinkage factor).
slope_boot <- function(form, B = 200) { set.seed(7); mean(replicate(B, { i <- sample(nrow(dev), replace = TRUE); f <- glm(form, data = dev[i, ], family = binomial)
  coef(glm(diabetes ~ lp, data = transform(dev, lp = predict(f, dev)), family = binomial))[["lp"]] })) }   #@ lp
c(true = slope_boot(f_true), all = slope_boot(f_all))
#% A (Q6): about 0.90 for the 8 predictors and 0.80 for the all-markers model: the all-markers model is more overfitted: its predictions are too extreme (a slope of 0.8 means 20% shrinkage is needed).
