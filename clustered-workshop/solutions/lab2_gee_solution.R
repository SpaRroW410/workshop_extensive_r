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
m_lm <- lm(sbp ~ arm + age + sex + bmi, data = bp12)                #@ lm || arm
round(summary(m_lm)$coefficients["armProgramme", ], 3)

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: The same coefficients with CLUSTER-ROBUST standard errors (cluster = village).
coeftest(m_lm, vcov = vcovCL(m_lm, cluster = bp12$village))["armProgramme", ]   #@ vcovCL || cluster
#% A (Q2): same estimate; the standard error is about 40% larger than the naive one (about 1.59 vs 1.15).

# Q2. What changes when you use cluster-robust standard errors, and what stays the same?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: A GEE with an EXCHANGEABLE working correlation (geepack needs the data sorted by cluster and no missing values in the model).
d12 <- bp12 |> arrange(village)
g1 <- geeglm(sbp ~ arm + age + sex + bmi, id = village, data = d12, family = gaussian, corstr = "exchangeable")   #@ geeglm || exchangeable
round(summary(g1)$coefficients["armProgramme", ], 3)
#% A (Q3): the estimate (about -3.6) and robust SE (about 1.5) are close to the cluster-robust lm; the working correlation is only a device for efficiency.

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: The estimated within-village correlation (alpha) of the exchangeable structure.
summary(g1)$corr                                                    #@ corr
#% A (Q4): alpha about 0.06, in line with the ICC.

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: GEE for the BINARY outcome "controlled BP" (SBP below 140) with a logit link, clusters = villages.
g2 <- geeglm(controlled ~ arm + age + sex + bmi, id = village, data = d12, family = binomial, corstr = "exchangeable")   #@ binomial
round(exp(cbind(OR = coef(g2), confint.default(g2)))["armProgramme", ], 2)
#% A (Q5): an odds ratio of about 1.2 with a wide 95% CI (about 0.7 to 2.0) that includes 1: no clear evidence of an effect on controlled BP; the interpretation is POPULATION-AVERAGED.

# Q5. How do you interpret this odds ratio? Is it a person-specific or a population-averaged effect?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Compare working correlation structures for the effect of the programme: independence vs exchangeable.
g_ind <- geeglm(sbp ~ arm + age + sex + bmi, id = village, data = d12, family = gaussian, corstr = "independence")   #@ independence
c(independence = coef(g_ind)[["armProgramme"]], exchangeable = coef(g1)[["armProgramme"]])
#% A (Q6): the estimates are close (about -3.4 vs -3.6) and the robust standard errors similar: the choice of working structure matters little for a cluster-level exposure.

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Few clusters (here 40) can make robust SEs too small. Use the small-sample CR2 correction with clubSandwich and Satterthwaite degrees of freedom.
coef_test(m_lm, vcov = "CR2", cluster = bp12$village)["armProgramme", ]   #@ CR2
#% A (Q7): a slightly larger SE (about 1.62) and a t-test with about 37 df instead of a z-test: more honest with 40 clusters.

# Q7. When are cluster-robust standard errors unreliable?
