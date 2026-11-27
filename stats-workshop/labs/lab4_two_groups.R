# ═══════════════════════════════════════════════════════════════
# LAB 4 — Comparing two groups on a number
# Statistical analysis workshop | Session 4
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
skew <- function(x) { x <- x[!is.na(x)]; mean((x - mean(x))^3) / sd(x)^3 }

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Is mean fasting glucose at presentation different from 100 mg/dL?
t.test(p$fbs_presentation, ___)

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: The same test for age in the poorest adults vs the mean of all adults. Compare the CI with Task 1.
poor <- filter(p, wealth_index_of_participants == "poorest")
t.test(poor$age_of_participants, mu = ___)

# Q2. Both tests are "not significant". Which one tells you more, and why?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Age by diabetes history: Welch t-test and Cohen's d.
p |> group_by(past_history_of_diabetes) |> summarise(n = n(), mean = mean(age_of_participants), sd = sd(age_of_participants))
t.test(___, data = p)
___(age_of_participants ~ past_history_of_diabetes, data = p, pooled_sd = FALSE)

# Q3. Write the sentence (direction, difference, 95% CI, test, p, d).

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Glucose (skewed) by diabetes history: medians (IQR), Mann-Whitney with the Hodges-Lehmann shift, and r.
p |> group_by(past_history_of_diabetes) |> summarise(median = median(glucose_level_mg_d_l), q1 = quantile(glucose_level_mg_d_l, .25), q3 = quantile(glucose_level_mg_d_l, .75))
wilcox.test(glucose_level_mg_d_l ~ past_history_of_diabetes, data = p, ___)
wilcox_effsize(p, glucose_level_mg_d_l ~ past_history_of_diabetes)

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Paired t-test of fasting glucose at presentation and 6 months. Check the differences first.
d <- p$fbs_presentation - p$fbs_6_months
c(mean = mean(d), sd = sd(d), skew = skew(d))
t.test(p$fbs_presentation, p$fbs_6_months, ___)
___

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Systolic pressure at presentation and 6 months (skewed, outliers): Wilcoxon signed-rank.
___(p$sbp_presentation, p$sbp_6_months, paired = TRUE, conf.int = TRUE)

# Q6. Why is a Mann-Whitney test wrong here?
