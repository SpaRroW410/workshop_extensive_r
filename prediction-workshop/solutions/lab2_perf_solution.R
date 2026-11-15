# ═══════════════════════════════════════════════════════════════
# LAB 2 — Discrimination and calibration
# Prediction models workshop | Session 2
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

m1 <- glm(f_true, data = dev, family = binomial)
dev$risk <- predict(m1, type = "response")

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: The ROC curve and the area under it (AUC) with a 95% confidence interval.
roc1 <- roc(dev$diabetes, dev$risk, quiet = TRUE)                    #@ roc
auc(roc1)
ci.auc(roc1)
#% A (Q1): AUC 0.80 (95% CI 0.75 to 0.85): a randomly chosen adult with diabetes has a higher risk than one without about 80% of the time.

# Q1. How do you read an AUC of 0.80?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Plot the ROC curve.
plot(roc1, legacy.axes = TRUE)                                      #@ legacy.axes

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: A threshold: classify adults with a predicted risk of 15% or more as "screen positive". Cross-tabulate with the real outcome and compute sensitivity and specificity.
tab <- table(predicted = dev$risk >= 0.15, diabetes = dev$diabetes)  #@ 0.15
tab
c(sensitivity = tab["TRUE", "1"] / sum(tab[, "1"]), specificity = tab["FALSE", "0"] / sum(tab[, "0"]))
#% A: sensitivity about 0.62 and specificity about 0.78 at a threshold of 15%.

# Q3. What happens to sensitivity and specificity if you lower the threshold to 5%?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Positive and negative predictive values at the same threshold.
c(PPV = tab["TRUE", "1"] / sum(tab["TRUE", ]), NPV = tab["FALSE", "0"] / sum(tab["FALSE", ]))   #@ NPV
#% A: PPV about 0.28 and NPV about 0.94; predictive values depend on the prevalence.

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: A calibration plot: group the adults into deciles of predicted risk, then plot the mean predicted risk against the observed proportion with diabetes.
cal <- dev |> mutate(decile = ntile(risk, 10)) |> group_by(decile) |> summarise(predicted = mean(risk), observed = mean(diabetes))   #@ ntile
ggplot(cal, aes(predicted, observed)) + geom_abline(linetype = 2) + geom_point(size = 3) + geom_line() + coord_equal(xlim = c(0, 0.6), ylim = c(0, 0.6))

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Calibration slope and intercept: a logistic regression of the outcome on the linear predictor (log-odds of the predicted risk).
lp <- qlogis(dev$risk)
coef(glm(diabetes ~ lp, data = dev, family = binomial))             #@ lp
#% A (Q6): intercept 0 and slope 1.00 exactly: in the data used to fit a logistic model, the apparent calibration is perfect. It tells you nothing: calibration must be checked in NEW data.

# Q6. Why is the apparent calibration slope always exactly 1?

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: The Brier score (mean squared difference between risk and outcome) and the scaled Brier score (1 minus Brier divided by the Brier score of a model that predicts the prevalence for everybody).
brier <- mean((dev$risk - dev$diabetes)^2)
brier_null <- mean((mean(dev$diabetes) - dev$diabetes)^2)           #@ mean(dev$diabetes)
c(brier = brier, scaled = 1 - brier / brier_null)
#% A: Brier about 0.089; scaled Brier about 0.15.

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: The added value of a predictor: the AUC of an age-only model compared with the full model.
auc_of(dev$diabetes, predict(glm(diabetes ~ age, data = dev, family = binomial), type = "response"))   #@ age
#% A: about 0.68 for age alone against 0.80 for the full model.
