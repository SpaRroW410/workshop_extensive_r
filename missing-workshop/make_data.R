# ═══════════════════════════════════════════════════════════════
# make_data.R — synthetic NCD cohort with missing data for the missing data workshop (no real people)
# Rscript missing-workshop/make_data.R        (repository root; seed fixed)
# Writes data/ncd_missing.csv : 2,000 adults
#   id, age, sex, education (None/Primary/Secondary+), bmi, smoker (0/1), activity (hours/week), sbp (mmHg), hba1c (%)
# The COMPLETE data are generated first, then values are deleted with known mechanisms:
#   * smoker   : 8% missing completely at random (MCAR)
#   * activity : missing at random (MAR), more often when education is low (observed)
#   * sbp      : missing at random, more often in older adults (observed)
#   * bmi      : MAR, more often in older adults, in men, and when SBP is HIGH (observed) -> a complete-case regression of SBP on BMI is biased
#   * hba1c    : MNAR: high values are more often missing (those with high values do not attend the lab); the mean of the observed values is too low
# Built-in structure (checked below; the script stops if a teaching feature is lost):
#   * the BMI coefficient in the SBP model (true 0.80) is biased downwards by complete-case analysis and recovered by multiple imputation
#   * only a minority of adults is complete (about 55%), so complete-case analysis also loses a lot of data
#   * the observed mean HbA1c is clearly lower than the true mean, and MAR imputation does not repair it (needs a sensitivity analysis)
# ═══════════════════════════════════════════════════════════════
suppressMessages({ library(dplyr); library(readr); library(mice) })
set.seed(2038)
n <- 2000
age <- round(pmin(80, pmax(18, rnorm(n, 48, 13))))
sex <- sample(c("Female", "Male"), n, TRUE)
education <- sample(c("None", "Primary", "Secondary+"), n, TRUE, prob = c(.3, .35, .35))
bmi <- round(pmax(15, 24.5 + 0.03 * (age - 48) - 0.4 * (sex == "Male") + 0.5 * (education == "Secondary+") + rnorm(n, 0, 4.5)), 1)
smoker <- rbinom(n, 1, plogis(-1.8 + 1.2 * (sex == "Male")))
activity <- round(pmax(0, rgamma(n, 1.8, 0.5) + 0.8 * (education == "Secondary+") - 0.5 * (age > 60)), 1)
sbp <- round(124 + 0.40 * (age - 48) + 0.80 * (bmi - 24.5) + 3 * (sex == "Male") + 2 * smoker - 0.5 * activity + rnorm(n, 0, 11))
hba1c <- round(5.5 + 0.015 * (age - 48) + 0.05 * (bmi - 24.5) + rgamma(n, 2, 3.2) - 0.62, 1)
full <- data.frame(id = sprintf("C%04d", 1:n), age, sex, education, bmi, smoker, activity, sbp, hba1c)
d <- full
mi_bmi <- runif(n) < plogis(-1.7 + 0.025 * (age - 48) + 0.5 * (sex == "Male") + 0.10 * (sbp - mean(sbp)))   # uses the observed SBP (deleted last)
d$smoker[runif(n) < 0.08] <- NA
d$activity[runif(n) < plogis(-1.9 - 0.9 * (education == "Secondary+") + 0.6 * (education == "None"))] <- NA
d$bmi[mi_bmi] <- NA
d$sbp[runif(n) < plogis(-2.8 + 0.03 * (age - 48))] <- NA
d$hba1c[runif(n) < plogis(-1.3 + 4.5 * (hba1c - 5.7))] <- NA
write_csv(d, "data/ncd_missing.csv")

# ── feature check ──
form <- sbp ~ age + sex + bmi + smoker + activity
true_b <- coef(lm(form, full))[["bmi"]]
cc_fit <- lm(form, d); cc_b <- coef(cc_fit)[["bmi"]]
dd <- d |> mutate(sex = factor(sex), education = factor(education))
imp <- mice(dd |> select(-id), m = 30, printFlag = FALSE, seed = 1, maxit = 15)
mi_b <- summary(pool(with(imp, lm(sbp ~ age + sex + bmi + smoker + activity))))
mi_b <- mi_b$estimate[mi_b$term == "bmi"]
complete_share <- mean(complete.cases(d))
mean_obs <- mean(d$hba1c, na.rm = TRUE); mean_true <- mean(full$hba1c)
mean_mar <- mean(sapply(1:30, function(i) mean(complete(imp, i)$hba1c)))
miss <- sapply(d[-1], \(x) round(100 * mean(is.na(x)), 1))
cat("missing %:", paste(names(miss), miss, collapse = ", "), "\n")
cat(sprintf("complete cases = %.0f%% | BMI coef: true(full data) %.3f | complete-case %.3f (n = %d) | MI %.3f\n", 100 * complete_share, true_b, cc_b, nobs(cc_fit), mi_b))
cat(sprintf("HbA1c mean: true %.2f | observed %.2f | after MAR imputation %.2f | share >= 6.5: true %.1f%%, observed %.1f%%\n", mean_true, mean_obs, mean_mar, 100 * mean(full$hba1c >= 6.5), 100 * mean(d$hba1c >= 6.5, na.rm = TRUE)))
stopifnot(true_b - cc_b > 0.08, abs(mi_b - true_b) < abs(cc_b - true_b) * 0.6, complete_share > 0.4, complete_share < 0.7,
          mean_true - mean_obs > 0.15, mean_true - mean_mar > 0.08, miss[["hba1c"]] > 20, miss[["bmi"]] > 15)
cat("feature check passed\n")
