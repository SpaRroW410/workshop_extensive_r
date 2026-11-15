# ═══════════════════════════════════════════════════════════════
# LAB 4 — Inverse probability weighting
# Causal inference workshop | Session 4
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(dagitty); library(MatchIt); library(cobalt); library(sandwich); library(lmtest); library(EValue) })
theme_set(theme_minimal(base_size = 14))

p <- c("data/htn_programme.csv", "../data/htn_programme.csv", "../../data/htn_programme.csv"); p <- p[file.exists(p)][1]
htn <- read_csv(p, show_col_types = FALSE) |> mutate(sex = factor(sex), education = factor(education, levels = c("None", "Primary", "Secondary+")))
f_out <- sbp_12m ~ programme + age + sex + education + urban + bmi + diabetes + baseline_sbp       # outcome model with the confounders
f_ps  <- programme ~ age + sex + education + urban + bmi + diabetes + baseline_sbp                 # propensity-score model

ps_model <- glm(f_ps, data = htn, family = binomial)
htn$ps <- predict(ps_model, type = "response")

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Inverse probability weights for the ATE: 1 / ps for the enrolled and 1 / (1 - ps) for the others. Look at their distribution.
htn$w <- ifelse(htn$programme == 1, ___, 1 / (1 - htn$ps))
summary(htn$w)

# Q1. Who gets a large weight? Why?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: STABILISED weights: multiply by the overall probability of the group actually received. Their mean should be close to 1.
pt <- mean(htn$programme)
htn$sw <- ifelse(htn$programme == 1, ___, (1 - pt) / (1 - htn$ps))
summary(htn$sw)

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Balance in the weighted sample (standardised mean differences).
bal.tab(f_ps, data = htn, ___ = "sw", un = TRUE, s.d.denom = "pooled")$Balance[, c("Diff.Un", "Diff.Adj")] |> round(2)

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: The weighted estimate of the ATE with a robust (sandwich) standard error.
fit_w <- lm(sbp_12m ~ programme, data = htn, ___)
coeftest(fit_w, vcov. = vcovHC(fit_w, type = "HC3"))["programme", ]

# Q4. Why is a robust standard error needed with weights?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Weights for the ATT: 1 for the enrolled and ps / (1 - ps) for the others. Estimate the effect.
htn$w_att <- ifelse(htn$programme == 1, 1, ___)
fit_att <- lm(sbp_12m ~ programme, data = htn, weights = w_att)
coeftest(fit_att, vcov. = vcovHC(fit_att, type = "HC3"))["programme", 1:2]

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Truncate extreme weights at the 1st and 99th percentile and re-estimate the ATE.
q <- quantile(htn$sw, c(0.01, 0.99))
htn$sw_t <- ___(pmax(htn$sw, q[1]), q[2])
coef(lm(sbp_12m ~ programme, data = htn, weights = sw_t))[["programme"]]

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: DOUBLY ROBUST: a weighted regression that also includes the confounders (outcome model + weights).
fit_dr <- lm(___, data = htn, weights = sw)
coeftest(fit_dr, vcov. = vcovHC(fit_dr, type = "HC3"))["programme", 1:2]

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: One table of the estimates so far: naive, regression, IPW, IPW truncated, doubly robust.
round(c(naive = coef(lm(sbp_12m ~ programme, data = htn))[["programme"]], regression = coef(lm(f_out, data = htn))[["programme"]], ipw = coef(fit_w)[["programme"]],
        ipw_truncated = coef(lm(sbp_12m ~ programme, data = htn, weights = sw_t))[["programme"]], ___ = coef(fit_dr)[["programme"]]), 2)
