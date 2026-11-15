# ═══════════════════════════════════════════════════════════════
# LAB 4 — Shrinkage and variable selection
# Prediction models workshop | Session 4
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

x_all <- model.matrix(f_all, dev)[, -1]; y <- dev$diabetes

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Backward stepwise selection by AIC from the all-markers model. Which variables are kept?
m_all <- glm(f_all, data = dev, family = binomial)
m_step <- step(m_all, direction = "backward", trace = 0)            #@ backward
names(coef(m_step))[-1]
#% A (Q1): age, waist, family history, hypertension, activity and smoking are kept (BMI and sex are dropped) and also four noise markers: m6, m8, m9 and m10.

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: STABILITY of selection: in 50 bootstrap samples run the same stepwise selection and count how often each marker m1 to m10 is selected.
set.seed(3)
sel <- replicate(50, { i <- sample(nrow(dev), replace = TRUE); f <- suppressWarnings(step(glm(f_all, data = dev[i, ], family = binomial), direction = "backward", trace = 0)); paste0("m", 1:10) %in% names(coef(f)) })   #@ replicate
setNames(rowMeans(sel), paste0("m", 1:10))
#% A (Q2): every noise marker is selected in some bootstrap samples, from 12% (m5) to 82% (m10; m9 70%, m6 56%, m8 50%): the selected set is unstable and p-values after selection are not valid.

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Ridge regression (penalised logistic regression, alpha = 0) with the penalty chosen by 10-fold cross-validation.
set.seed(1)
cv_r <- cv.glmnet(x_all, y, family = "binomial", alpha = 0)         #@ alpha = 0
cv_r$lambda.min
#% A: lambda of about 0.036 (depends on the folds).

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Compare the coefficients of the ordinary logistic model and of the ridge model for the ten markers: the ridge coefficients are shrunk towards zero.
cbind(ML = coef(m_all)[paste0("m", 1:10)], ridge = as.numeric(coef(cv_r, s = "lambda.min"))[-1][match(paste0("m", 1:10), colnames(x_all))]) |> round(3)   #@ lambda.min
#% A (Q4): ridge coefficients are about 60 to 70% of the ML ones (e.g. m10 0.27 to 0.17): all coefficients shrink, none is exactly zero.

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: The LASSO (alpha = 1) with the largest penalty within one standard error of the minimum (lambda.1se). Which variables are kept?
set.seed(1)
cv_l <- cv.glmnet(x_all, y, family = "binomial", alpha = 1)
b_l <- coef(cv_l, s = "lambda.1se")                                 #@ lambda.1se
rownames(b_l)[as.numeric(b_l) != 0][-1]
#% A (Q5): only age, waist and family history remain: the lasso removed all the noise markers, but with lambda.1se it also dropped real predictors (hypertension, smoking, activity): a very sparse, probably over-shrunk model.

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: UNIFORM SHRINKAGE: multiply all the coefficients of the all-markers model by the bootstrap shrinkage factor (use 0.80) and re-estimate the intercept so that the mean predicted risk equals the prevalence.
lp0 <- predict(m_all, dev)
lp_s <- 0.80 * lp0                                                  #@ 0.80
b0 <- coef(glm(diabetes ~ offset(lp_s), data = dev, family = binomial))[[1]]
mean(plogis(lp_s + b0))
mean(dev$diabetes)
#% A: the mean predicted risk is again 0.120: the shrunken model has less extreme predictions but is correct on average.

# Q6. What is the effect of shrinkage on the spread of the predicted risks?
