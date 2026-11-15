# ═══════════════════════════════════════════════════════════════
# LAB 4 — Repeated measures: trajectories over time
# Clustered and repeated data workshop | Session 4
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
# Goal: How many visits per person were observed? (The study planned 4.)
___(table(bp$person))

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Mean SBP at each visit by arm, as a plot with one line per arm.
bp |> ___(arm, months) |> summarise(mean_sbp = mean(sbp), .groups = "drop") |> ggplot(aes(months, mean_sbp, colour = arm)) + ___() + geom_point()

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Fit a mixed model with time (months), arm and their INTERACTION, adjusted for age, sex and BMI, with random intercepts for village and for person within village.
m_t <- lmer(sbp ~ ___ + age + sex + bmi + (1 | village / person), data = bp)
round(summary(m_t)$coefficients["months:armProgramme", ], 3)

# Q3. Interpret the interaction term in one sentence.

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: The difference between arms at 12 months: arm effect + 12 x interaction. Compute the point estimate from the coefficients.
fe <- fixef(m_t)
fe[["armProgramme"]] + ___ * fe[["months:armProgramme"]]

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: A random SLOPE for months within person (people differ in their trend).
m_s <- lmer(sbp ~ months * arm + age + sex + bmi + (1 | village) + ___, data = bp, control = lmerControl(optimizer = "bobyqa"))
anova(m_t, m_s)

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: GEE with an AR(1) working correlation for repeated visits within a person (data sorted by person and time; this GEE ignores the village level).
d <- bp |> arrange(person, months)
g_ar <- geeglm(sbp ~ months * arm + age + sex + bmi, id = person, waves = months, data = d, family = gaussian, corstr = "___")
round(summary(g_ar)$coefficients["months:armProgramme", ], 3)

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Missing visits: compare a COMPLETE-CASE analysis (people with all 4 visits) with the mixed model on all available data. Count the complete cases first.
complete <- bp |> group_by(person) |> filter(n() == 4) |> ungroup()
___(complete$person)
round(fixef(lmer(sbp ~ months * arm + age + sex + bmi + (1 | village / person), data = complete))["months:armProgramme"], 3)

# Q7. Why can the mixed model use incomplete data under missing at random, but the complete-case analysis not?
