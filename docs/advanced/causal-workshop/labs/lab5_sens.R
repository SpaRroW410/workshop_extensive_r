# ═══════════════════════════════════════════════════════════════
# LAB 5 — Sensitivity analysis and reporting
# Causal inference workshop | Session 5
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(dagitty); library(MatchIt); library(cobalt); library(sandwich); library(lmtest); library(EValue) })
theme_set(theme_minimal(base_size = 14))

p <- c("data/htn_programme.csv", "../data/htn_programme.csv", "../../data/htn_programme.csv"); p <- p[file.exists(p)][1]
htn <- read_csv(p, show_col_types = FALSE) |> mutate(sex = factor(sex), education = factor(education, levels = c("None", "Primary", "Secondary+")))
f_out <- sbp_12m ~ programme + age + sex + education + urban + bmi + diabetes + baseline_sbp       # outcome model with the confounders
f_ps  <- programme ~ age + sex + education + urban + bmi + diabetes + baseline_sbp                 # propensity-score model

m_adj <- lm(f_out, data = htn)
# Facilitator note: the data were simulated with both potential outcomes: the true ATE is -5.77 mmHg and the true ATT -6.17 mmHg. An unmeasured factor (motivation) leaves a small residual bias.

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: The binary outcome: controlled BP at 12 months. A risk ratio for the programme adjusted for the confounders (Poisson regression with robust SE gives a risk ratio for a common outcome).
m_rr <- glm(update(f_out, controlled ~ .), data = htn, family = ___)
ct <- coeftest(m_rr, vcov. = vcovHC(m_rr, type = "HC0"))
rr <- exp(c(RR = ct["programme", 1], lo = ct["programme", 1] - 1.96 * ct["programme", 2], hi = ct["programme", 1] + 1.96 * ct["programme", 2]))
round(rr, 2)

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: The E-VALUE for this risk ratio: how strongly would an unmeasured confounder have to be associated with both the programme and the outcome to explain the effect away?
___(est = rr[["RR"]], lo = rr[["lo"]], hi = rr[["hi"]])

# Q2. Interpret the E-value for the point estimate and for the confidence limit.

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: The E-value for the continuous outcome: the adjusted difference in SBP and its SE, with the SD of the outcome (uses a standardised effect size).
b <- summary(m_adj)$coefficients["programme", ]
___(est = b[["Estimate"]], se = b[["Std. Error"]], sd = sd(htn$sbp_12m))

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: How strong are the MEASURED confounders? The risk ratio of controlled BP for diabetes, as a benchmark for a plausible unmeasured confounder.
round(exp(coef(m_rr))[c("___", "educationSecondary+", "urban")], 2)

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: A simple bias analysis: leave out one measured confounder (baseline SBP) and see how far the estimate moves: this is what an unmeasured confounder of that strength does.
round(c(full = coef(m_adj)[["programme"]], without_baseline_sbp = coef(update(m_adj, . ~ . ___))[["programme"]]), 2)

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Positivity check: how many adults have a propensity score below 0.05 or above 0.95?
ps <- predict(glm(f_ps, data = htn, family = binomial), type = "response")
c(below_0.05 = ___(ps < 0.05), above_0.95 = sum(ps > 0.95))

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: A summary sentence for a paper.
cat(sprintf("After adjustment for age, sex, education, residence, BMI, diabetes and baseline SBP, enrolment was associated with a %.1f mmHg lower SBP at 12 months (95%% CI %.1f to %.1f); similar estimates were obtained by matching and weighting.\n",
            abs(coef(m_adj)[["programme"]]), abs(___(m_adj)["programme", 2]), abs(confint(m_adj)["programme", 1])))
