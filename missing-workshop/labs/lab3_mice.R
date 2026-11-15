# ═══════════════════════════════════════════════════════════════
# LAB 3 — Multiple imputation with mice
# Missing data workshop | Session 3
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(mice); library(naniar) })
theme_set(theme_minimal(base_size = 14))

p <- c("data/ncd_missing.csv", "../data/ncd_missing.csv", "../../data/ncd_missing.csv"); p <- p[file.exists(p)][1]
ncd <- read_csv(p, show_col_types = FALSE) |> mutate(sex = factor(sex), education = factor(education, levels = c("None", "Primary", "Secondary+")))
dat <- ncd |> select(-id)                          # the id must not enter the imputation model

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Look at the default setup WITHOUT imputing: the imputation method of each variable and the predictor matrix.
ini <- mice(dat, ___, printFlag = FALSE)
ini$method
ini$predictorMatrix

# Q1. Which method does mice use for a continuous variable? What does a 1 in the predictor matrix mean?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Make smoker a factor so that it is imputed with logistic regression, and re-check the methods.
dat2 <- dat |> mutate(smoker = ___(smoker, labels = c("No", "Yes")))
mice(dat2, maxit = 0, printFlag = FALSE)$method

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Run the imputation: 20 imputed data sets, 10 iterations, a fixed seed.
imp <- mice(dat2, ___, maxit = 10, ___ = 2038, printFlag = FALSE)
imp

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Check CONVERGENCE: plot the mean and SD of the imputed values by iteration for each variable (the lines should mix, with no trend).
___(imp)

# Q4. What would a trend in these lines suggest?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Compare observed and imputed values of BMI: a density plot (observed in blue, imputed in red).
___(imp, ~ bmi)

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Fit the substantive model in EACH imputed data set and POOL the results with Rubin's rules.
fit <- ___(imp, lm(sbp ~ age + sex + bmi + smoker + activity))
___ed <- pool(fit)
summary(pooled, conf.int = TRUE)

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Compare the BMI coefficient from multiple imputation with the complete-case analysis.
m_cc <- lm(sbp ~ age + sex + bmi + smoker + activity, data = dat)
s <- summary(pooled, conf.int = TRUE)
rbind(complete_case = summary(m_cc)$coefficients["bmi", 1:2], multiple_imputation = unlist(s[s$term == "bmi", c("estimate", "___")]))
