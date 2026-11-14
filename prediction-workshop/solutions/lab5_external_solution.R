# ═══════════════════════════════════════════════════════════════
# LAB 5 — External validation, decision curves and reporting
# Prediction models workshop | Session 5
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
m_all <- glm(f_all, data = dev, family = binomial)
x_all <- model.matrix(f_all, dev)[, -1]; xv_all <- model.matrix(f_all, val)[, -1]
set.seed(1); cv_r <- cv.glmnet(x_all, dev$diabetes, family = "binomial", alpha = 0); cv_l <- cv.glmnet(x_all, dev$diabetes, family = "binomial", alpha = 1)
# Facilitator note: the validation cohort is an older, less active district with a prevalence of about 25% and weaker predictor effects.

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Apply the ORIGINAL 8-predictor model to the validation cohort (no refitting!): the discrimination (AUC with a 95% CI).
val$risk <- predict(m_true, newdata = val, type = "response")       #@ newdata
roc_v <- roc(val$diabetes, val$risk, quiet = TRUE)
c(auc = as.numeric(auc(roc_v))); ci.auc(roc_v)
#% A (Q1): AUC 0.71 (95% CI 0.68 to 0.74): lower than the apparent 0.80 and the corrected 0.775: the model transports less well to a different district.

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Calibration-in-the-large: the mean predicted risk against the observed prevalence.
c(predicted = mean(val$risk), observed = mean(val$diabetes))         #@ observed
#% A (Q2): 17.9% predicted against 24.6% observed: the model UNDER-estimates risk in this district (higher baseline risk).

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: The calibration slope and the calibration intercept (calibration-in-the-large) of the model in the validation cohort.
lpv <- qlogis(val$risk)
c(slope = coef(glm(diabetes ~ lpv, data = val, family = binomial))[["lpv"]], intercept_offset = coef(glm(diabetes ~ offset(lpv), data = val, family = binomial))[[1]])   #@ offset
#% A (Q3): slope about 0.67 (predictions are too extreme: low risks are too low and high risks too high) and an intercept about +0.5 (risk is under-estimated on average).

# Q3. Explain a calibration slope of 0.67 in plain words.

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: The calibration plot in the validation cohort (deciles of predicted risk).
calv <- val |> mutate(decile = ntile(risk, 10)) |> group_by(decile) |> summarise(predicted = mean(risk), observed = mean(diabetes))   #@ ntile
ggplot(calv, aes(predicted, observed)) + geom_abline(linetype = 2) + geom_point(size = 3) + geom_line() + coord_equal(xlim = c(0, 0.7), ylim = c(0, 0.7))

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Compare four ways of building the model on the validation cohort: AUC and calibration slope for (a) ML 8 predictors, (b) ML with the noise markers, (c) ridge, (d) lasso.
slope_of <- function(lp) coef(glm(diabetes ~ lp, data = val, family = binomial))[["lp"]]
lps <- list(ML_8 = predict(m_true, val), ML_all = predict(m_all, val), ridge = as.numeric(predict(cv_r, xv_all, s = "lambda.min")), lasso = as.numeric(predict(cv_l, xv_all, s = "lambda.1se")))   #@ lambda.1se
sapply(lps, function(lp) c(auc = auc_of(val$diabetes, lp), slope = slope_of(lp))) |> t() |> round(3)
#% A (Q5): AUC 0.71 (8 predictors), 0.69 (all markers), 0.70 (ridge), 0.71 (lasso); calibration slopes 0.67, 0.53, 0.80 and 1.59: the all-markers ML model is the worst calibrated; ridge is the closest to 1 among the full models; the lasso at lambda.1se is over-shrunk (slope above 1: predictions too narrow). No model keeps its development performance in the new district.

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: RECALIBRATE the 8-predictor model to the new district: estimate a new intercept and slope on the validation cohort and compare the Brier scores before and after.
rec <- glm(diabetes ~ lpv, data = val, family = binomial)           #@ lpv
val$risk_rec <- predict(rec, type = "response")
c(before = mean((val$risk - val$diabetes)^2), after = mean((val$risk_rec - val$diabetes)^2))
#% A: Brier 0.170 before and 0.165 after recalibration; discrimination (AUC) does not change, only calibration.

# Q6. Why not simply refit the whole model in the new district?

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: DECISION CURVE (net benefit) for thresholds from 5% to 40%. Net benefit = TP/n - FP/n x t/(1 - t). Compute it for the recalibrated model, "treat all" and "treat none" (= 0).
nb <- function(risk, y, t) { tp <- sum(risk >= t & y == 1); fp <- sum(risk >= t & y == 0); tp / length(y) - fp / length(y) * t / (1 - t) }
ts <- seq(0.05, 0.40, 0.05)
tibble(threshold = ts, model = sapply(ts, \(t) nb(val$risk_rec, val$diabetes, t)), treat_all = sapply(ts, \(t) mean(val$diabetes) - (1 - mean(val$diabetes)) * t / (1 - t))) |> mutate(across(-threshold, \(x) round(x, 3)))   #@ treat_all
#% A (Q7): the model has the same net benefit as treat-all up to a threshold of 10% (0.206 and 0.162) and a clearly higher one from 15% (0.126 vs 0.112) to 40% (0.027 vs -0.258); treat-all becomes harmful above 25%.

# Q7. How do you read a net benefit of 0.10 at a threshold of 20%?

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: A one-sentence summary for a TRIPOD-style report.
cat("The model (logistic regression, 8 predictors, 84 events in 700 adults) had an apparent AUC of 0.80 (bootstrap-corrected 0.775); in an external cohort of 2,000 adults the AUC was 0.71, the calibration slope 0.67 and risk was under-estimated (mean 17.9% vs 24.6% observed).\n")   #@ external
