# ═══════════════════════════════════════════════════════════════
# LAB 2 — Adjustment, bad controls and standardisation
# Causal inference workshop | Session 2
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
# Goal: The effect of the programme on 12-month SBP adjusted for the confounders (f_out), with a 95% CI.
m_adj <- lm(___, data = htn)
round(c(coef(m_adj)[["programme"]], confint(m_adj)["programme", ]), 2)

# Q1. Compare with the naive difference. In which direction was the naive estimate biased, and why?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: A BAD control: add the mediator (adherent) to the model. What happens to the programme coefficient?
m_med <- update(m_adj, . ~ . + ___)
round(coef(m_med)[["programme"]], 2)

# Q2. What does the coefficient mean now?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Another bad control: add the collider (clinic_visits). What happens?
m_col <- update(m_adj, . ~ . + ___)
round(coef(m_col)[["programme"]], 2)

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: A table of the four estimates: naive, confounder-adjusted, plus mediator, plus collider.
round(c(___ = coef(lm(sbp_12m ~ programme, data = htn))[["programme"]], adjusted = coef(m_adj)[["programme"]], plus_mediator = coef(m_med)[["programme"]], plus_collider = coef(m_col)[["programme"]]), 2)

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Allow the effect to differ by baseline SBP: add an interaction of the programme with baseline SBP (centred at 150).
htn <- htn |> mutate(bsbp_c = baseline_sbp - 150)
m_int <- lm(sbp_12m ~ ___ + age + sex + education + urban + bmi + diabetes, data = htn)
round(summary(m_int)$coefficients[c("programme", "programme:bsbp_c"), 1:2], 3)

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: STANDARDISATION (g-computation): predict the SBP of EVERY adult twice with the interaction model, once with programme = 1 and once with programme = 0; the mean difference is the average treatment effect (ATE).
p1 <- predict(m_int, ___(htn, programme = 1)); p0 <- predict(m_int, transform(htn, programme = 0))
mean(p1 - p0)

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: The effect in those who enrolled (ATT): the same difference averaged over the enrolled adults only.
mean((p1 - p0)[___])

# Q7. Why is the ATT larger (more negative) than the ATE here? Which one answers "should we extend the programme to everybody"?
