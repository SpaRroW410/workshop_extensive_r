# ═══════════════════════════════════════════════════════════════
# LAB 2 — Simple methods and why they fail
# Missing data workshop | Session 2
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(mice); library(naniar) })
theme_set(theme_minimal(base_size = 14))

p <- c("data/ncd_missing.csv", "../data/ncd_missing.csv", "../../data/ncd_missing.csv"); p <- p[file.exists(p)][1]
ncd <- read_csv(p, show_col_types = FALSE) |> mutate(sex = factor(sex), education = factor(education, levels = c("None", "Primary", "Secondary+")))
dat <- ncd |> select(-id)                          # the id must not enter the imputation model

# Truth for the facilitator: the BMI coefficient in the SBP model is 0.80 (0.855 in the complete data of this sample).

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: The substantive model: SBP on age, sex, BMI, smoking and activity, using complete cases (lm drops incomplete rows by default). How many adults are used?
m_cc <- lm(sbp ~ age + sex + bmi + smoker + activity, data = dat)   #@ lm
nobs(m_cc)
round(summary(m_cc)$coefficients["bmi", ], 3)

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: MEAN imputation of BMI: replace missing BMI by the mean of the observed values. Compare the standard deviation before and after.
d_mean <- dat |> mutate(bmi_m = ifelse(is.na(bmi), mean(bmi, na.rm = TRUE), bmi))   #@ mean(bmi, na.rm = TRUE)
c(before = sd(dat$bmi, na.rm = TRUE), after = sd(d_mean$bmi_m))
#% A (Q2): SD falls from about 4.3 to about 3.7: mean imputation shrinks the variance.

# Q2. Why does mean imputation shrink the variance and weaken the associations?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: The SBP model with the mean-imputed BMI. Compare the coefficient and its standard error with the complete-case model.
m_mean <- lm(sbp ~ age + sex + bmi_m + smoker + activity, data = d_mean)   #@ bmi_m
rbind(complete_case = summary(m_cc)$coefficients["bmi", 1:2], mean_imputed = summary(m_mean)$coefficients["bmi_m", 1:2])
#% A: both about 0.69 (the truth is about 0.80 to 0.86): the coefficient is biased downwards, and the SE is not valid for mean imputation.

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: The MISSING INDICATOR method: set missing BMI to 0 and add an indicator variable for missingness. Fit the model.
d_ind <- dat |> mutate(bmi_miss = as.integer(is.na(bmi)), bmi0 = ifelse(is.na(bmi), 0, bmi))   #@ ifelse
m_ind <- lm(sbp ~ age + sex + bmi0 + bmi_miss + smoker + activity, data = d_ind)
round(summary(m_ind)$coefficients[c("bmi0", "bmi_miss"), 1:2], 3)
#% A: the BMI coefficient is 0.68 (still biased) and the missing indicator absorbs a large 'effect' of 28 mmHg: it is an artefact of the missing values being filled with 0.

# Q4. Why is the missing-indicator method biased even when the data are missing at random?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: A single STOCHASTIC regression imputation of BMI with mice (m = 1), then the model. Notice the standard error.
imp1 <- mice(dat, m = 1, maxit = 10, seed = 1, printFlag = FALSE)   #@ m = 1
m_single <- lm(sbp ~ age + sex + bmi + smoker + activity, data = complete(imp1))
round(summary(m_single)$coefficients["bmi", 1:2], 3)
#% A: estimate 0.75 (closer to the truth), but SE 0.057: SMALLER than the complete-case SE although a quarter of the BMI values were made up; a single imputation treats imputed values as real.

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: A summary table of the BMI coefficient and SE from the four simple approaches.
tibble(method = c("complete case", "mean imputation", "missing indicator", "single imputation"),
  estimate = c(coef(m_cc)[["bmi"]], coef(m_mean)[["bmi_m"]], coef(m_ind)[["bmi0"]], coef(m_single)[["bmi"]]),
  se = c(summary(m_cc)$coefficients["bmi", 2], summary(m_mean)$coefficients["bmi_m", 2], summary(m_ind)$coefficients["bmi0", 2], summary(m_single)$coefficients["bmi", 2])) |>
  mutate(across(where(is.numeric), \(x) round(x, 3)))             #@ mutate

# Q6. Which of these approaches gives a valid standard error? Why not?
