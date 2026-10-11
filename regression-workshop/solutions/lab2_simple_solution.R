# ═══════════════════════════════════════════════════════════════
# LAB 2 — Simple linear regression and model performance
# Theory of Regression Analysis workshop | Session 2
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({
  library(tidyverse); library(gtsummary); library(broom); library(performance)
  library(see); library(car); library(lmtest); library(pROC)
})
theme_set(theme_minimal(base_size = 14))

csv_path <- c("data/ncd_survey.csv", "../data/ncd_survey.csv", "../../data/ncd_survey.csv")
csv_path <- csv_path[file.exists(csv_path)][1]
ncd <- read_csv(csv_path, show_col_types = FALSE) |>
  mutate(
    sex = factor(sex, levels = c("Female", "Male")),
    residence = factor(residence, levels = c("Urban", "Rural")),
    education = factor(education, levels = c("No schooling", "Primary", "Secondary", "Graduate+")),
    tobacco = factor(tobacco, levels = c("No", "Yes")),
    alcohol = factor(alcohol, levels = c("No", "Yes")),
    phys_act = factor(phys_act, levels = c("low", "moderate", "high")),
    htn_f = factor(htn, levels = 0:1, labels = c("No HTN", "HTN"))
  )

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Fit a model with systolic BP as the outcome and daily salt
# intake as the only predictor. Store it as m_salt.
m_salt <- lm(sbp ~ salt_g, data = ncd)                  #@ lm || sbp ~ salt_g

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Print the full model report: coefficients with standard errors,
# t-values, p-values, residual standard error, R-squared and the F-test.
summary(m_salt)                                         #@ summary

#% A (Q1/Q2): slope 3.39 -> each extra 1 g/day of salt goes with 3.4 mmHg higher mean SBP (crude). Intercept 107 = mean SBP at 0 g salt: outside the data, not a real person.

# Q1. In mmHg terms, what does the coefficient for salt_g mean?
# Q2. What does the intercept represent? Is that a sensible person?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Get the coefficients as a data frame with one row per term,
# including the lower and upper limits of the 95% interval.
tidy(m_salt, conf.int = TRUE)                           #@ tidy || conf.int

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Predict the MEAN systolic BP of people who eat 5, 8 and 12 g of
# salt per day, together with the 95% interval for that mean.
new_salt <- data.frame(salt_g = c(5, 8, 12))
predict(m_salt, newdata = new_salt, interval = "confidence")   #@ "confidence"

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Now predict for a SINGLE new individual at the same salt
# intakes, with the interval that covers an individual's likely SBP.
predict(m_salt, newdata = new_salt, interval = "prediction")   #@ "prediction"

#% A (Q3/Q4): at 8 g: CI 133-136 (precision of the MEAN) vs PI 105-164 (an INDIVIDUAL); PI adds residual SD (~15 mmHg). Prediction interval answers Q4.

# Q3. Compare the two intervals at 8 g/day. Which is wider, and why?
# Q4. Which interval answers: "What range of SBP might the next patient have?"

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Add the fitted values and residuals to the data used in the
# model, then plot residuals (y) against fitted values (x) with a
# horizontal reference line at zero.
m_df <- augment(m_salt)                                  #@ augment
ggplot(m_df, aes(x = .fitted, y = .resid)) +             #@ .resid
  geom_point(alpha = 0.5, colour = "#3498db") +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "#e74c3c") +   #@ geom_hline
  labs(x = "Fitted SBP (mmHg)", y = "Residual (mmHg)")

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Report R-squared (and its adjusted version) for the model using
# the performance package.
r2(m_salt)                                               #@ r2

#% A (Q5): R2 = 0.20 -> salt alone accounts for about 20% of the variability in SBP. Low/moderate R2 does not make the slope unimportant (and high R2 does not make a model correct).

# Q5. Salt "explains" what share of the variation in SBP? Does a low R²
#     mean the salt effect is unimportant?

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Create age centred at 50 years (so 0 means "a 50-year-old") and
# salt centred at the sample mean. Then refit the model of SBP on both
# centred variables.
ncd <- ncd |>
  mutate(age_c  = age - 50,
         salt_c = salt_g - mean(salt_g, na.rm = TRUE))   #@ mean(salt_g, na.rm = TRUE)
m_centred <- lm(sbp ~ age_c + salt_c, data = ncd)        #@ age_c + salt_c
summary(m_centred)$coefficients

#% A (Q6): intercept = expected SBP for a 50-year-old with average salt intake (133 mmHg). Slopes are identical; only the intercept changed (86 -> 133).

# Q6. How does the intercept now read? Compare slopes with an uncentred
#     version of the same model: what changed, and what did not?
m_raw <- lm(sbp ~ age + salt_g, data = ncd)
cbind(raw = coef(m_raw), centred = coef(m_centred))
