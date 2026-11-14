# ═══════════════════════════════════════════════════════════════
# LAB 2 — Cluster-robust standard errors and GEE
# Clustered and repeated data workshop | Session 2
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
# Goal: The naive model at 12 months, adjusted for age, sex and BMI.
m____ <- lm(sbp ~ ___ + age + sex + bmi, data = bp12)
round(summary(m_lm)$coefficients["armProgramme", ], 3)

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: The same coefficients with CLUSTER-ROBUST standard errors (cluster = village).
coeftest(m_lm, vcov = ___(m_lm, ___ = bp12$village))["armProgramme", ]

# Q2. What changes when you use cluster-robust standard errors, and what stays the same?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: A GEE with an EXCHANGEABLE working correlation (geepack needs the data sorted by cluster and no missing values in the model).
d12 <- bp12 |> arrange(village)
g1 <- ___(sbp ~ arm + age + sex + bmi, id = village, data = d12, family = gaussian, corstr = "___")
round(summary(g1)$coefficients["armProgramme", ], 3)

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: The estimated within-village correlation (alpha) of the exchangeable structure.
summary(g1)$___

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: GEE for the BINARY outcome "controlled BP" (SBP below 140) with a logit link, clusters = villages.
g2 <- geeglm(controlled ~ arm + age + sex + bmi, id = village, data = d12, family = ___, corstr = "exchangeable")
round(exp(cbind(OR = coef(g2), confint.default(g2)))["armProgramme", ], 2)

# Q5. How do you interpret this odds ratio? Is it a person-specific or a population-averaged effect?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Compare working correlation structures for the effect of the programme: independence vs exchangeable.
g_ind <- geeglm(sbp ~ arm + age + sex + bmi, id = village, data = d12, family = gaussian, corstr = "___")
c(independence = coef(g_ind)[["armProgramme"]], exchangeable = coef(g1)[["armProgramme"]])

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Few clusters (here 40) can make robust SEs too small. Use the small-sample CR2 correction with clubSandwich and Satterthwaite degrees of freedom.
coef_test(m_lm, vcov = "___", cluster = bp12$village)["armProgramme", ]

# Q7. When are cluster-robust standard errors unreliable?
