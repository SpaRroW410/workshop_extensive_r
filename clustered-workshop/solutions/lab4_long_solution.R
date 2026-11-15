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
table(table(bp$person))                                             #@ table
#% A (Q1): about 59% of people (474 of 800) have all 4 visits; about 13% of the planned visits are missing.

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Mean SBP at each visit by arm, as a plot with one line per arm.
bp |> group_by(arm, months) |> summarise(mean_sbp = mean(sbp), .groups = "drop") |> ggplot(aes(months, mean_sbp, colour = arm)) + geom_line() + geom_point()   #@ group_by || geom_line
#% A (Q2): similar at baseline; the programme arm falls over time and the control arm hardly moves.

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Fit a mixed model with time (months), arm and their INTERACTION, adjusted for age, sex and BMI, with random intercepts for village and for person within village.
m_t <- lmer(sbp ~ months * arm + age + sex + bmi + (1 | village / person), data = bp)   #@ months * arm
round(summary(m_t)$coefficients["months:armProgramme", ], 3)
#% A (Q3): about -0.39 mmHg per month (SE about 0.07): the programme arm declines about 0.4 mmHg per month faster than control, so about 4.6 mmHg more by 12 months.

# Q3. Interpret the interaction term in one sentence.

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: The difference between arms at 12 months: arm effect + 12 x interaction. Compute the point estimate from the coefficients.
fe <- fixef(m_t)
fe[["armProgramme"]] + 12 * fe[["months:armProgramme"]]             #@ 12
#% A: about -4.4 mmHg at 12 months (arm term plus 12 times the interaction).

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: A random SLOPE for months within person (people differ in their trend).
m_s <- lmer(sbp ~ months * arm + age + sex + bmi + (1 | village) + (months | person), data = bp, control = lmerControl(optimizer = "bobyqa"))   #@ (months | person)
anova(m_t, m_s)
#% A (Q5): the random slope does not improve the fit (likelihood-ratio p about 0.7): people do not differ much in their trend here, so the simpler model is enough.

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: GEE with an AR(1) working correlation for repeated visits within a person (data sorted by person and time; this GEE ignores the village level).
d <- bp |> arrange(person, months)
g_ar <- geeglm(sbp ~ months * arm + age + sex + bmi, id = person, waves = months, data = d, family = gaussian, corstr = "ar1")   #@ ar1
round(summary(g_ar)$coefficients["months:armProgramme", ], 3)
#% A (Q6): close to the mixed-model estimate (about -0.34 vs -0.39); a marginal (population-averaged) model.

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Missing visits: compare a COMPLETE-CASE analysis (people with all 4 visits) with the mixed model on all available data. Count the complete cases first.
complete <- bp |> group_by(person) |> filter(n() == 4) |> ungroup()
n_distinct(complete$person)                                         #@ n_distinct
round(fixef(lmer(sbp ~ months * arm + age + sex + bmi + (1 | village / person), data = complete))["months:armProgramme"], 3)
#% A (Q7): the complete-case estimate (about -0.43, from 474 people) is in the same range here, but dropout depends on age and on earlier SBP, so only the mixed model on all available data is valid under missing at random.

# Q7. Why can the mixed model use incomplete data under missing at random, but the complete-case analysis not?
