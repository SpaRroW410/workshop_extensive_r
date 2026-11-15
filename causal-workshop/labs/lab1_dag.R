# ═══════════════════════════════════════════════════════════════
# LAB 1 — Causal questions and DAGs
# Causal inference workshop | Session 1
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
# Goal: How many adults enrolled in the programme? Compare the mean 12-month SBP of enrolled and not enrolled adults (the naive comparison).
___(htn$programme)
htn |> group_by(programme) |> summarise(n = n(), sbp_12m = mean(sbp_12m))
coef(lm(sbp_12m ~ programme, data = htn))[["programme"]]

# Q1

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Are the two groups comparable at baseline? Mean age, baseline SBP, diabetes and urban residence by programme.
htn |> ___(programme) |> summarise(age = mean(age), baseline_sbp = mean(baseline_sbp), diabetes = mean(diabetes), urban = mean(urban), secondary = mean(education == "Secondary+"))

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Write the causal diagram (DAG). Baseline variables cause both enrolment and the outcome; adherence lies on the path from programme to SBP; clinic visits are caused by the programme and by the SBP.
g <- dagitty("dag {
  programme -> sbp_12m
  programme -> adherent -> sbp_12m
  programme -> clinic_visits
  sbp_12m -> clinic_visits
  age -> programme ; age -> sbp_12m
  diabetes -> programme ; diabetes -> sbp_12m
  baseline_sbp -> programme ; baseline_sbp -> sbp_12m
  education -> programme ; education -> sbp_12m ; education -> adherent
  urban -> programme ; urban -> bmi
  bmi -> sbp_12m ; bmi -> baseline_sbp ; bmi -> diabetes
  age -> baseline_sbp ; age -> diabetes
}")
plot(graphLayout(g))

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Ask the DAG which variables to adjust for to estimate the TOTAL effect of the programme on SBP.
___(g, exposure = "programme", outcome = "sbp_12m", effect = "total")

# Q4. Why are adherent and clinic_visits not in the adjustment set?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Classify each variable: list the paths from programme to sbp_12m and whether each is open.
___(g, "programme", "sbp_12m")$paths |> head(8)

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Which variables are descendants of the programme (affected by it)? These must not be adjusted for when the total effect is wanted.
___(g, "programme")

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: The DAG also implies testable statements. List a few conditional independencies it implies.
___(g) |> head(5)
