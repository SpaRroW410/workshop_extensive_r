# ═══════════════════════════════════════════════════════════════
# LAB 3 — Propensity scores and matching
# Causal inference workshop | Session 3
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(dagitty); library(MatchIt); library(cobalt); library(sandwich); library(lmtest); library(EValue) })
theme_set(theme_minimal(base_size = 14))

p <- c("data/htn_programme.csv", "../data/htn_programme.csv", "../../data/htn_programme.csv"); p <- p[file.exists(p)][1]
htn <- read_csv(p, show_col_types = FALSE) |> mutate(sex = factor(sex), education = factor(education, levels = c("None", "Primary", "Secondary+")))
f_out <- sbp_12m ~ programme + age + sex + education + urban + bmi + diabetes + baseline_sbp       # outcome model with the confounders
f_ps  <- programme ~ age + sex + education + urban + bmi + diabetes + baseline_sbp                 # propensity-score model

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Estimate the propensity score: the probability of enrolment given the baseline confounders (logistic regression with f_ps).
ps_model <- glm(f_ps, data = htn, family = ___)
htn$ps <- predict(ps_model, type = "response")
htn |> group_by(programme) |> summarise(min = min(ps), mean = mean(ps), max = max(ps))

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Check OVERLAP (positivity): plot the distribution of the propensity score in the two groups.
ggplot(htn, aes(ps, fill = factor(programme))) + ___(alpha = 0.5) + labs(fill = "Programme")

# Q2. What would it mean if the two distributions hardly overlapped?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Balance BEFORE matching: standardised mean differences of the covariates between the groups.
___(f_ps, data = htn, un = TRUE, s.d.denom = "pooled")$Balance[, "Diff.Un", drop = FALSE] |> round(2)

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: 1:1 nearest-neighbour matching on the propensity score with a caliper of 0.2 standard deviations.
m_out <- ___(f_ps, data = htn, method = "nearest", distance = "glm", ___ = 0.2)
m_out

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Balance AFTER matching (standardised mean differences should be below 0.1).
bal.tab(___, un = TRUE)$Balance[, c("Diff.Un", "Diff.Adj")] |> round(2)

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: A love plot of the balance before and after matching.
___(m_out, thresholds = 0.1, abs = TRUE)

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: The effect in the matched sample: a regression of SBP on the programme in the matched data, with a cluster-robust SE on the matched pair.
md <- ___(m_out)
fit_m <- lm(sbp_12m ~ programme, data = md, weights = weights)
coeftest(fit_m, vcov. = vcovCL, cluster = ~subclass)["programme", ]

# Q7. Which effect does 1:1 matching of the enrolled estimate: the ATE or the ATT? How many enrolled adults were dropped?
