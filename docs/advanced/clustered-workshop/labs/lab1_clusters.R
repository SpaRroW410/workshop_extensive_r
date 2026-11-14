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
___(bp$village)
n_distinct(bp$person)
___(bp)

# Q1. Which units are clustered inside which? What is repeated?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: At baseline, the mean SBP of each village: how much do the village means vary (range and SD)?
vm <- bp |> filter(months == 0) |> ___(village) |> ___ = mean(sbp))
range(vm$mean_sbp)
sd(vm$mean_sbp)

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Estimate the intra-class correlation (ICC) of baseline SBP with a model that has only a random intercept for village.
b <- bp |> filter(months == 0)
m0 <- ___(sbp ~ 1 + ___, data = b)
vc <- as.data.frame(VarCorr(m0))$vcov
vc[1] / sum(vc)

# Q3. Explain the ICC in words. What would ICC = 0 and ICC = 1 mean?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: The same ICC with the performance package.
___(m0)

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: DESIGN EFFECT = 1 + (m - 1) x ICC, with m = 20 people per village.
deff <- 1 + (20 - 1) * ___
deff

# Q5. What does a design effect of 2.4 mean for the sample size you really have?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: The EFFECTIVE sample size of the 800 baseline measurements: n / design effect.
800 / ___

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: The naive analysis at 12 months: a linear model of SBP on arm that ignores villages. Get the standard error of the programme effect.
summary(___(sbp ~ ___, data = bp12))$coefficients["armProgramme", ]

# Q7. Why is the standard error of a cluster-level exposure (the arm) understated by the naive model?

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: A valid simple analysis: compare the VILLAGE means (one number per village) between the arms with a t-test.
vm12 <- bp12 |> group_by(village, arm) |> summarise(mean_sbp = mean(sbp), .groups = "drop")
___(mean_sbp ~ arm, data = vm12)
