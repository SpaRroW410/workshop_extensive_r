# ═══════════════════════════════════════════════════════════════
# LAB 1 — Clustered data: ICC and the design effect
# Clustered and repeated data workshop | Session 1
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
# Goal: How many villages, people and rows (visits) are there?
n_distinct(bp$village)                                              #@ n_distinct
n_distinct(bp$person)
nrow(bp)                                                            #@ nrow
#% A (Q1): 40 villages, 800 people, about 2,780 rows (4 planned visits each; some missing).

# Q1. Which units are clustered inside which? What is repeated?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: At baseline, the mean SBP of each village: how much do the village means vary (range and SD)?
vm <- bp |> filter(months == 0) |> group_by(village) |> summarise(mean_sbp = mean(sbp))   #@ group_by || summarise(mean_sbp
range(vm$mean_sbp)
sd(vm$mean_sbp)
#% A (Q2): village means range from about 120 to 141 (SD about 5.5): villages differ much more than 20 random people per village would.

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Estimate the intra-class correlation (ICC) of baseline SBP with a model that has only a random intercept for village.
b <- bp |> filter(months == 0)
m0 <- lmer(sbp ~ 1 + (1 | village), data = b)                       #@ lmer || (1 | village)
vc <- as.data.frame(VarCorr(m0))$vcov
vc[1] / sum(vc)
#% A (Q3): ICC about 0.07: about 7% of the variation in baseline SBP is between villages.

# Q3. Explain the ICC in words. What would ICC = 0 and ICC = 1 mean?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: The same ICC with the performance package.
icc(m0)                                                             #@ icc

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: DESIGN EFFECT = 1 + (m - 1) x ICC, with m = 20 people per village.
deff <- 1 + (20 - 1) * 0.074                                        #@ 0.074
deff
#% A (Q5): about 2.4: the variance of an estimate is about 2.4 times larger than a simple random sample of the same size would give.

# Q5. What does a design effect of 2.4 mean for the sample size you really have?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: The EFFECTIVE sample size of the 800 baseline measurements: n / design effect.
800 / deff                                                          #@ deff
#% A (Q6): about 330: the 800 people carry the information of only about 330 independent people.

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: The naive analysis at 12 months: a linear model of SBP on arm that ignores villages. Get the standard error of the programme effect.
summary(lm(sbp ~ arm, data = bp12))$coefficients["armProgramme", ]   #@ lm || arm
#% A (Q7): an estimate of about -4.0 with a standard error of about 1.2: too small, because it treats every person as independent.

# Q7. Why is the standard error of a cluster-level exposure (the arm) understated by the naive model?

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: A valid simple analysis: compare the VILLAGE means (one number per village) between the arms with a t-test.
vm12 <- bp12 |> group_by(village, arm) |> summarise(mean_sbp = mean(sbp), .groups = "drop")
t.test(mean_sbp ~ arm, data = vm12)                                 #@ t.test
#% A (Q8): the village-level t-test has only 40 observations (villages): the difference is about 4.3 mmHg with a 95% CI of about 1.0 to 7.5 (p about 0.01).
