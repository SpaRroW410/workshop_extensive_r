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
m1 <- lmer(sbp ~ arm + age + sex + bmi + (1 | village), data = bp12)   #@ lmer || (1 | village)
summary(m1)$coefficients
#% A (Q1): the programme coefficient is about -3.6 (SE about 1.6, Satterthwaite df about 39).

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: The variance components: the between-village and the residual variance.
VarCorr(m1)                                                         #@ VarCorr
#% A: village SD about 3.6, residual SD about 14.2.

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: The adjusted ICC from the model.
icc(m1)                                                             #@ icc
#% A (Q3): about 0.06 (adjusted for the covariates).

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Test whether the village random effect is needed (likelihood-ratio test from lmerTest).
ranova(m1)                                                          #@ ranova
#% A (Q4): a small p-value (about 0.0005): villages differ beyond chance, so the random intercept is needed.

# Q4. Why should you not decide that clustering is ignorable just because the ICC is small?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: The predicted village effects (best linear unbiased predictors, BLUPs): extract and show the largest and smallest.
re <- ranef(m1)$village[, 1]                                        #@ ranef
range(round(re, 1))
#% A (Q5): about -5 to +6 mmHg; these are SHRUNK towards 0 compared with the raw village means, especially for small villages.

# Q5. What does shrinkage do to a village estimate, and why is it useful?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: A caterpillar-style plot of the village effects, ordered from lowest to highest.
tibble(village = rownames(ranef(m1)$village), re = ranef(m1)$village[, 1]) |> arrange(re) |> mutate(village = fct_inorder(village)) |>
  ggplot(aes(re, village)) + geom_point()                           #@ geom_point

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Compare the programme effect and its standard error with the naive lm and the cluster-robust lm.
m_lm <- lm(sbp ~ arm + age + sex + bmi, data = bp12)
rbind(naive = summary(m_lm)$coefficients["armProgramme", 1:2], robust = coeftest(m_lm, vcov = vcovCL(m_lm, cluster = bp12$village))["armProgramme", 1:2],
      mixed = summary(m1)$coefficients["armProgramme", 1:2])        #@ mixed
#% A (Q7): all three give similar point estimates; the naive SE is too small and the other two agree with each other.

# Q7. When do the mixed model and the cluster-robust analysis give different answers?
