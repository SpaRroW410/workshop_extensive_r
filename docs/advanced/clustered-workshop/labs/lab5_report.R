# ═══════════════════════════════════════════════════════════════
# LAB 5 — Choosing, checking and reporting
# Clustered and repeated data workshop | Session 5
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(lme4); library(lmerTest); library(geepack); library(sandwich); library(lmtest); library(performance); library(clubSandwich) })
theme_set(theme_minimal(base_size = 14))

bp_path <- c("data/bp_trial.csv", "../data/bp_trial.csv", "../../data/bp_trial.csv")
bp_path <- bp_path[file.exists(bp_path)][1]
bp <- read_csv(bp_path, show_col_types = FALSE) |> mutate(arm = factor(arm, levels = c("Control", "Programme")), sex = factor(sex), village = factor(village), person = factor(person))
bp12 <- bp |> filter(months == 12)

bp12 <- bp |> filter(months == 12)

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Build one table of the 12-month programme effect and its standard error from all approaches: naive lm, cluster-robust lm, village-level t-test (difference of means) and mixed model.
m_lm <- lm(sbp ~ arm + age + sex + bmi, data = bp12)
m_mx <- lmer(sbp ~ arm + age + sex + bmi + (1 | village), data = bp12)
tab <- tibble(method = c("naive lm", "cluster-robust lm", "mixed model"),
  estimate = c(coef(m_lm)[["armProgramme"]], coef(m_lm)[["armProgramme"]], fixef(m_mx)[["armProgramme"]]),
  se = c(summary(m_lm)$coefficients["armProgramme", 2], coeftest(m_lm, vcov = ___(m_lm, cluster = bp12$village))["armProgramme", 2], summary(m_mx)$coefficients["armProgramme", 2]))
tab |> mutate(across(where(is.numeric), \(x) round(x, 2)))

# Q1. Which standard error would you report, and why not the naive one?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: The design effect for planning a new trial: a cluster-randomised trial needs a simple-random-sample size multiplied by 1 + (m - 1) x ICC. With an individually randomised sample size of 300 per arm, m = 25 per village and ICC = 0.07, how many people per arm?
300 * (1 + (25 - 1) * ___)

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: How many villages (clusters) per arm does that need? (people per arm / people per village)
___(804 / 25)

# Q3. Why does increasing the number of people per village help less than adding villages?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Check the model: a normal quantile plot of the village random effects.
___(ranef(m_mx)$village[, 1]); qqline(ranef(m_mx)$village[, 1])

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Check the residuals of the mixed model against the fitted values.
plot(fitted(m_mx), ___(m_mx)); abline(h = 0, col = "red")

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: The mixed model has a CONDITIONAL meaning (within a village); a GEE has a MARGINAL meaning (the average over villages). For a continuous outcome with an identity link they coincide. State the programme effect with its 95% CI from the mixed model (Satterthwaite).
round(___(m_mx, method = "Wald")["armProgramme", ], 2)

# Q6. Write the one-sentence result for a paper.
