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
m_cc <- ___(sbp ~ age + sex + bmi + smoker + activity, data = dat)
nobs(m_cc)
round(summary(m_cc)$coefficients["bmi", ], 3)

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: MEAN imputation of BMI: replace missing BMI by the mean of the observed values. Compare the standard deviation before and after.
d_mean <- dat |> mutate(bmi_m = ifelse(is.na(bmi), ___, bmi))
c(before = sd(dat$bmi, na.rm = TRUE), after = sd(d_mean$bmi_m))

# Q2. Why does mean imputation shrink the variance and weaken the associations?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: The SBP model with the mean-imputed BMI. Compare the coefficient and its standard error with the complete-case model.
m_mean <- lm(sbp ~ age + sex + ___ + smoker + activity, data = d_mean)
rbind(complete_case = summary(m_cc)$coefficients["bmi", 1:2], mean_imputed = summary(m_mean)$coefficients["bmi_m", 1:2])

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: The MISSING INDICATOR method: set missing BMI to 0 and add an indicator variable for missingness. Fit the model.
d_ind <- dat |> mutate(bmi_miss = as.integer(is.na(bmi)), bmi0 = ___(is.na(bmi), 0, bmi))
m_ind <- lm(sbp ~ age + sex + bmi0 + bmi_miss + smoker + activity, data = d_ind)
round(summary(m_ind)$coefficients[c("bmi0", "bmi_miss"), 1:2], 3)

# Q4. Why is the missing-indicator method biased even when the data are missing at random?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: A single STOCHASTIC regression imputation of BMI with mice (m = 1), then the model. Notice the standard error.
imp1 <- mice(dat, ___, maxit = 10, seed = 1, printFlag = FALSE)
m_single <- lm(sbp ~ age + sex + bmi + smoker + activity, data = complete(imp1))
round(summary(m_single)$coefficients["bmi", 1:2], 3)

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: A summary table of the BMI coefficient and SE from the four simple approaches.
tibble(method = c("complete case", "mean imputation", "missing indicator", "single imputation"),
  estimate = c(coef(m_cc)[["bmi"]], coef(m_mean)[["bmi_m"]], coef(m_ind)[["bmi0"]], coef(m_single)[["bmi"]]),
  se = c(summary(m_cc)$coefficients["bmi", 2], summary(m_mean)$coefficients["bmi_m", 2], summary(m_ind)$coefficients["bmi0", 2], summary(m_single)$coefficients["bmi", 2])) |>
  ___(across(where(is.numeric), \(x) round(x, 3)))

# Q6. Which of these approaches gives a valid standard error? Why not?
