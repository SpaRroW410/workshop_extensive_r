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
htn$w <- ifelse(htn$programme == 1, 1 / htn$ps, 1 / (1 - htn$ps))    #@ 1 / htn$ps
summary(htn$w)

#% A (Q1): weights from 1.0 to 15.2. Large weights go to adults who received the option that was unlikely for them (e.g. a low-risk adult who enrolled): they stand for many similar adults.
# Q1. Who gets a large weight? Why?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: STABILISED weights: multiply by the overall probability of the group actually received. Their mean should be close to 1.
pt <- mean(htn$programme)
htn$sw <- ifelse(htn$programme == 1, pt / htn$ps, (1 - pt) / (1 - htn$ps))   #@ pt / htn$ps
summary(htn$sw)

#% A: mean 1.0, range 0.42 to 6.2: the same information with less extreme values.
# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Balance in the weighted sample (standardised mean differences).
bal.tab(f_ps, data = htn, weights = "sw", un = TRUE, s.d.denom = "pooled")$Balance[, c("Diff.Un", "Diff.Adj")] |> round(2)   #@ weights
#% A: all differences at most 0.03 after weighting.

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: The weighted estimate of the ATE with a robust (sandwich) standard error.
fit_w <- lm(sbp_12m ~ programme, data = htn, weights = sw)           #@ weights = sw
coeftest(fit_w, vcov. = vcovHC(fit_w, type = "HC3"))["programme", ]

#% A (Q4): ATE -5.7 mmHg (robust SE 0.55). Weights make observations count unequally and are themselves estimated, so the model-based SE is wrong; the sandwich SE is the simple (slightly conservative) fix.
# Q4. Why is a robust standard error needed with weights?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Weights for the ATT: 1 for the enrolled and ps / (1 - ps) for the others. Estimate the effect.
htn$w_att <- ifelse(htn$programme == 1, 1, htn$ps / (1 - htn$ps))    #@ htn$ps / (1 - htn$ps)
fit_att <- lm(sbp_12m ~ programme, data = htn, weights = w_att)
coeftest(fit_att, vcov. = vcovHC(fit_att, type = "HC3"))["programme", 1:2]

#% A: ATT -6.6 mmHg (SE 0.60).
# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Truncate extreme weights at the 1st and 99th percentile and re-estimate the ATE.
q <- quantile(htn$sw, c(0.01, 0.99))
htn$sw_t <- pmin(pmax(htn$sw, q[1]), q[2])                           #@ pmin
coef(lm(sbp_12m ~ programme, data = htn, weights = sw_t))[["programme"]]

#% A: -5.6: little change, so the result does not hang on a few extreme weights.
# ── Task 7 ──────────────────────────────────────────────────────
# Goal: DOUBLY ROBUST: a weighted regression that also includes the confounders (outcome model + weights).
fit_dr <- lm(f_out, data = htn, weights = sw)                        #@ f_out
coeftest(fit_dr, vcov. = vcovHC(fit_dr, type = "HC3"))["programme", 1:2]

#% A: -6.0 mmHg (SE 0.46): more precise; consistent if either the propensity model or the outcome model is right.
# ── Task 8 ──────────────────────────────────────────────────────
# Goal: One table of the estimates so far: naive, regression, IPW, IPW truncated, doubly robust.
round(c(naive = coef(lm(sbp_12m ~ programme, data = htn))[["programme"]], regression = coef(lm(f_out, data = htn))[["programme"]], ipw = coef(fit_w)[["programme"]],
        ipw_truncated = coef(lm(sbp_12m ~ programme, data = htn, weights = sw_t))[["programme"]], doubly_robust = coef(fit_dr)[["programme"]]), 2)   #@ doubly_robust
#% A: naive -1.4; regression -6.3; IPW -5.7; truncated -5.6; doubly robust -6.0 (truth -5.8): every method that uses the confounders agrees; only the naive one is far off.
