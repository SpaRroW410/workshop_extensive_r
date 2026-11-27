# ═══════════════════════════════════════════════════════════════
# LAB 3 — Categorical outcomes
# Statistical analysis workshop | Session 3
# Replace every ___ with the missing code. Hints describe the GOAL.
# Data: data/prac_modded.xlsx (the practice dataset of the Basic track)
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(readxl); library(janitor); library(rstatix); library(effectsize); library(car) })
theme_set(theme_minimal(base_size = 14))
p_path <- c("data/prac_modded.xlsx", "../data/prac_modded.xlsx", "../../data/prac_modded.xlsx")
p_path <- p_path[file.exists(p_path)][1]
p <- read_excel(p_path) |> clean_names() |>
  mutate(
    wealth_index_of_participants   = factor(wealth_index_of_participants, levels = c("poorest", "poorer", "middle", "richer", "richest")),
    marital_status_of_participants = factor(marital_status_of_participants, levels = c("never married", "currently married", "formerly/ever married")),
    sex_of_participants            = factor(sex_of_participants),
    across(c(pain_foot_bfr, pain_foot_aftr), \(x) factor(x, levels = c("No", "Yes")))
  )
# Session 1 found two entry errors (SBP and DBP swapped in 4 records; one weight without its decimal point),
# confirmed and corrected here as in Lab 1. BMI is added for Lab 5.
p <- p |>
  mutate(swapped = sbp_in_mm_hg < dbp_in_mm_hg,
         sbp = if_else(swapped, dbp_in_mm_hg, sbp_in_mm_hg),
         dbp_in_mm_hg = if_else(swapped, sbp_in_mm_hg, dbp_in_mm_hg),
         sbp_in_mm_hg = sbp,
         weight = if_else(weight < 20, weight * 10, weight),
         bmi = weight / (height / 100)^2) |>
  select(-swapped, -sbp)
skew <- function(x) { x <- x[!is.na(x)]; mean((x - mean(x))^3) / sd(x)^3 }
suppressPackageStartupMessages(library(exact2x2))

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: The proportion ever screened for blood pressure, with its 95% CI.
n_yes <- sum(p$ever_screened_for_bp == "yes")
___(n_yes, nrow(p))

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Diabetes by sex. Look at the EXPECTED counts first, then test.
t_sex <- table(p$sex_of_participants, p$past_history_of_diabetes)
t_sex
chisq.test(t_sex)___
chisq.test(t_sex, correct = FALSE)

# Q2. Which rule decides between chi-square and Fisher here?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: The effect: percentage with diabetes in each sex and the difference with its 95% CI.
___(t_sex[, "yes"], rowSums(t_sex))

# Q3. Write the result as one sentence for a thesis.

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Diabetes by past hypertension. Check expected counts and choose the test.
t_htn <- table(hypertension = p$past_history_of_hypertension, diabetes = p$past_history_of_diabetes)
t_htn
round(chisq.test(t_htn)$expected, 1)
___(t_htn)
prop.table(t_htn, 1)

# Q4. Why is the confidence interval for the odds ratio so wide?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Marital status by wealth (3 x 5): test, then find which cells drive it.
t_mw <- table(p$marital_status_of_participants, p$wealth_index_of_participants)
x <- chisq.test(t_mw)
x
round(x___, 1)
___(t_mw)

# Q5. Describe the association in words: how strong, and where?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Foot pain before and after (same adults): McNemar, and the exact version.
t_pain <- table(before = p$pain_foot_bfr, after = p$pain_foot_aftr)
t_pain
___(t_pain)
mcnemar.exact(t_pain)
