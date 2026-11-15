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
table(htn$programme)                                                #@ table
htn |> group_by(programme) |> summarise(n = n(), sbp_12m = mean(sbp_12m))
coef(lm(sbp_12m ~ programme, data = htn))[["programme"]]

# Q1
#% A (Q1): 1,229 of 3,000 enrolled (41%). Mean SBP 142 vs 143: a naive difference of only -1.4 mmHg. Not the effect: the groups were not comparable to begin with.. Can you read this difference as the effect of the programme? Why not?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Are the two groups comparable at baseline? Mean age, baseline SBP, diabetes and urban residence by programme.
htn |> group_by(programme) |> summarise(age = mean(age), baseline_sbp = mean(baseline_sbp), diabetes = mean(diabetes), urban = mean(urban), secondary = mean(education == "Secondary+"))   #@ group_by
#% A: the enrolled are older (57.8 vs 53.2), have a higher baseline SBP (157 vs 150), more diabetes (25% vs 13%), are more urban and more educated: confounding by indication.

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
adjustmentSets(g, exposure = "programme", outcome = "sbp_12m", effect = "total")   #@ adjustmentSets
#% A (Q4): two minimal sets: {age, baseline_sbp, bmi, diabetes, education} or {age, baseline_sbp, diabetes, education, urban}. adherent is a mediator (on the causal path) and clinic_visits a collider (a common effect): adjusting for either biases the total effect.

# Q4. Why are adherent and clinic_visits not in the adjustment set?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Classify each variable: list the paths from programme to sbp_12m and whether each is open.
paths(g, "programme", "sbp_12m")$paths |> head(8)                    #@ paths
#% A: causal paths: programme -> sbp_12m and programme -> adherent -> sbp_12m; the path through clinic_visits is closed (collider); paths starting with "programme <-" are back-door (confounding) paths.

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Which variables are descendants of the programme (affected by it)? These must not be adjusted for when the total effect is wanted.
descendants(g, "programme")                                         #@ descendants
#% A: programme itself, sbp_12m, clinic_visits and adherent.

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: The DAG also implies testable statements. List a few conditional independencies it implies.
impliedConditionalIndependencies(g) |> head(5)                      #@ impliedConditionalIndependencies
