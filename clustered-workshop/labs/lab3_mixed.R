# ═══════════════════════════════════════════════════════════════
# LAB 3 — Random-intercept (mixed) models
# Clustered and repeated data workshop | Session 3
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(lme4); library(lmerTest); library(geepack); library(sandwich); library(lmtest); library(performance); library(clubSandwich) })
theme_set(theme_minimal(base_size = 14))

bp_path <- c("data/bp_trial.csv", "../data/bp_trial.csv", "../../data/bp_trial.csv")
bp_path <- bp_path[file.exists(bp_path)][1]
bp <- read_csv(bp_path, show_col_types = FALSE) |> mutate(arm = factor(arm, levels = c("Control", "Programme")), sex = factor(sex), village = factor(village), person = factor(person))
bp12 <- bp |> filter(months == 12)

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: A random-intercept model at 12 months: programme, age, sex, BMI, and a random intercept for village.
m1 <- ___(sbp ~ arm + age + sex + bmi + ___, data = bp12)
summary(m1)$coefficients

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: The variance components: the between-village and the residual variance.
___(m1)

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: The adjusted ICC from the model.
___(m1)

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Test whether the village random effect is needed (likelihood-ratio test from lmerTest).
___(m1)

# Q4. Why should you not decide that clustering is ignorable just because the ICC is small?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: The predicted village effects (best linear unbiased predictors, BLUPs): extract and show the largest and smallest.
re <- ___(m1)$village[, 1]
range(round(re, 1))

# Q5. What does shrinkage do to a village estimate, and why is it useful?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: A caterpillar-style plot of the village effects, ordered from lowest to highest.
tibble(village = rownames(ranef(m1)$village), re = ranef(m1)$village[, 1]) |> arrange(re) |> mutate(village = fct_inorder(village)) |>
  ggplot(aes(re, village)) + ___()

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Compare the programme effect and its standard error with the naive lm and the cluster-robust lm.
m_lm <- lm(sbp ~ arm + age + sex + bmi, data = bp12)
rbind(naive = summary(m_lm)$coefficients["armProgramme", 1:2], robust = coeftest(m_lm, vcov = vcovCL(m_lm, cluster = bp12$village))["armProgramme", 1:2],
      ___ = summary(m1)$coefficients["armProgramme", 1:2])

# Q7. When do the mixed model and the cluster-robust analysis give different answers?
