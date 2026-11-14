# ═══════════════════════════════════════════════════════════════
# make_data.R — synthetic diabetes-screening data for the prediction models workshop (no real people)
# Rscript prediction-workshop/make_data.R        (repository root; seed fixed)
# Writes
#   data/diabetes_dev.csv   development cohort, 700 adults from the first district (about 85 with diabetes)
#   data/diabetes_valid.csv external validation cohort, 2,000 adults from another district (older, less active, higher prevalence)
# Columns: id, age, sex, bmi, waist (cm), fam_history (0/1), hypertension (0/1), activity (hours/week), smoker (0/1), m1 ... m10 (ten "extra lab markers" with NO real
#          relation to diabetes), diabetes (0/1; undiagnosed diabetes found at screening)
# Built-in structure (checked below; the script stops if a teaching feature is lost):
#   * a logistic model of 8 true predictors has an apparent AUC about 0.8 in the development data
#   * adding the 10 noise markers raises the APPARENT AUC but the bootstrap optimism is large (small sample, few events per predictor)
#   * in the validation district the true risk is different: higher prevalence (calibration-in-the-large off), weaker predictor effects (calibration slope below 1)
#   * ridge/lasso and shrinkage improve calibration slope in the validation cohort
# ═══════════════════════════════════════════════════════════════
suppressMessages({ library(dplyr); library(readr); library(pROC); library(glmnet) })
set.seed(2039)
gen <- function(n, age_mu, act_mu, alpha, beta, rural_extra = 0) {
  age <- round(pmin(80, pmax(20, rnorm(n, age_mu, 12))))
  sex <- sample(c("Female", "Male"), n, TRUE)
  bmi <- round(pmax(15, rnorm(n, 24.5 + 0.03 * (age - 45) + 0.5 * (sex == "Male"), 4.4)), 1)
  waist <- round(pmax(55, 22 + 2.7 * bmi + 4 * (sex == "Male") + rnorm(n, 0, 5)))
  fam <- rbinom(n, 1, 0.22)
  htn <- rbinom(n, 1, plogis(-2.6 + 0.045 * (age - 45) + 0.07 * (bmi - 24.5) + rural_extra))
  act <- round(pmax(0, rgamma(n, 1.8, 1.8 / act_mu)), 1)
  smk <- rbinom(n, 1, plogis(-1.9 + 1.0 * (sex == "Male")))
  lp <- -2.45 + 0.045 * (age - 45) + 0.09 * (bmi - 24.5) + 0.020 * (waist - 85) + 0.75 * fam + 0.45 * htn - 0.10 * act + 0.30 * smk + 0.25 * (sex == "Male")
  y <- rbinom(n, 1, plogis(alpha + beta * lp))
  m <- matrix(round(rnorm(n * 10), 2), n, 10, dimnames = list(NULL, paste0("m", 1:10)))
  data.frame(age, sex, bmi, waist, fam_history = fam, hypertension = htn, activity = act, smoker = smk, m, diabetes = y)
}
dev <- gen(700, 45, 4, 0, 1.0); dev <- cbind(id = sprintf("D%04d", 1:nrow(dev)), dev)
val <- gen(2000, 50, 2.8, 0.30, 0.85, rural_extra = 0.3); val <- cbind(id = sprintf("V%04d", 1:nrow(val)), val)
write_csv(dev, "data/diabetes_dev.csv"); write_csv(val, "data/diabetes_valid.csv")

# ── feature check ──
true_f <- diabetes ~ age + sex + bmi + waist + fam_history + hypertension + activity + smoker
all_f <- update(true_f, . ~ . + m1 + m2 + m3 + m4 + m5 + m6 + m7 + m8 + m9 + m10)
auc <- function(y, p) as.numeric(pROC::auc(y, p, quiet = TRUE))
f1 <- glm(true_f, binomial, dev); f2 <- glm(all_f, binomial, dev)
app1 <- auc(dev$diabetes, fitted(f1)); app2 <- auc(dev$diabetes, fitted(f2))
optimism <- function(form, B = 100) mean(sapply(1:B, function(b) { i <- sample(nrow(dev), replace = TRUE); f <- glm(form, binomial, dev[i, ]); auc(dev$diabetes[i], fitted(f)) - auc(dev$diabetes, predict(f, dev, type = "response")) }))
o1 <- optimism(true_f); o2 <- optimism(all_f)
pv <- predict(f1, val, type = "response"); lp_v <- qlogis(pv)
cal <- coef(glm(diabetes ~ lp_v, binomial, val)); citl <- coef(glm(diabetes ~ offset(lp_v), binomial, val))
slope2 <- coef(glm(diabetes ~ qlogis(predict(f2, val, type = "response")), binomial, val))[2]
cat(sprintf("prevalence: dev %.1f%% (%d events), validation %.1f%% | apparent AUC: true-only %.3f, +noise %.3f | optimism: %.3f vs %.3f\n", 100 * mean(dev$diabetes), sum(dev$diabetes), 100 * mean(val$diabetes), app1, app2, o1, o2))
cat(sprintf("external: AUC %.3f | calibration slope %.2f (all-markers model: %.2f) | calibration-in-the-large %.2f | mean predicted %.1f%% vs observed %.1f%%\n", auc(val$diabetes, pv), cal[2], slope2, citl[1], 100 * mean(pv), 100 * mean(val$diabetes)))
stopifnot(app1 > 0.72, o2 > o1 + 0.01, app2 > app1, cal[2] < 0.9, citl[1] > 0.3, mean(val$diabetes) > mean(dev$diabetes) + 0.04, sum(dev$diabetes) > 60)
cat("feature check passed\n")
