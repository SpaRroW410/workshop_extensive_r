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

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Is mean fasting glucose at presentation different from 100 mg/dL?
t.test(p$fbs_presentation, mu = 100)                                #@ mu = 100
#% A (Q1): mean 109.0 (95% CI 107.9 to 110.1), p < 0.001: on average 9 mg/dL above the 100 mg/dL threshold for impaired fasting glucose.

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Fasting glucose at presentation, women vs men: in all adults, then only in adults with diabetes. Compare the CIs.
t.test(fbs_presentation ~ sex_of_participants, data = p)
dm <- filter(p, past_history_of_diabetes == "yes")
t.test(fbs_presentation ~ sex_of_participants, data = dm)           #@ data = dm
#% A (Q2): all adults: 108.9 vs 109.1 mg/dL, 95% CI for women - men -2.4 to 2.0, p = 0.85: precise, any difference is under about 2.4 mg/dL. Adults with diabetes (14 women, 13 men): 142.8 vs 150.7, 95% CI -17.5 to 1.8, p = 0.11: imprecise, women could be up to 17 mg/dL lower. Same verdict "not significant", very different information.

# Q2. Both tests are "not significant". Which one tells you more, and why?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Age by diabetes history: Welch t-test and Cohen's d.
p |> group_by(past_history_of_diabetes) |> summarise(n = n(), mean = mean(age_of_participants), sd = sd(age_of_participants))
t.test(age_of_participants ~ past_history_of_diabetes, data = p)    #@ age_of_participants ~ past_history_of_diabetes
cohens_d(age_of_participants ~ past_history_of_diabetes, data = p, pooled_sd = FALSE)   #@ cohens_d
#% A (Q3): 53.8 vs 42.9 years; difference 10.9 years (95% CI 6.4 to 15.4), Welch p < 0.001; d = 0.97 (large). Welch matters here: 27 vs 604 adults.

# Q3. Write the sentence (direction, difference, 95% CI, test, p, d).

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Glucose (skewed) by diabetes history: medians (IQR), Mann-Whitney with the Hodges-Lehmann shift, and r.
p |> group_by(past_history_of_diabetes) |> summarise(median = median(glucose_level_mg_d_l), q1 = quantile(glucose_level_mg_d_l, .25), q3 = quantile(glucose_level_mg_d_l, .75))
wilcox.test(glucose_level_mg_d_l ~ past_history_of_diabetes, data = p, conf.int = TRUE)   #@ conf.int = TRUE
wilcox_effsize(p, glucose_level_mg_d_l ~ past_history_of_diabetes)
#% A (Q4): medians 200 vs 106 mg/dL; Hodges-Lehmann shift 94 mg/dL (95% CI 71 to 115), p < 0.001; r = 0.30. Say that glucose tends to be higher, not that the medians differ, unless the shapes are similar.

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Paired t-test of fasting glucose at presentation and 6 months. Check the differences first.
d <- p$fbs_presentation - p$fbs_6_months
c(mean = mean(d), sd = sd(d), skew = skew(d))
t.test(p$fbs_presentation, p$fbs_6_months, paired = TRUE)          #@ paired = TRUE
mean(d) / sd(d)                                                     #@ mean(d) / sd(d)
cor(p$fbs_presentation, p$fbs_6_months)
t.test(p$fbs_presentation, p$fbs_6_months)$conf.int                # WRONG here: ignores the pairing
#% A (Q5): mean fall 10.4 mg/dL (95% CI 9.9 to 10.9), p < 0.001; dz = 1.58 (large). The differences are symmetric, so the paired t-test fits. The visits correlate (r = 0.91), so ignoring the pairing gives a CI of 8.8 to 12.0, three times wider.

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Systolic pressure at presentation and 6 months (right-skewed): Wilcoxon signed-rank.
wilcox.test(p$sbp_presentation, p$sbp_6_months, paired = TRUE, conf.int = TRUE)   #@ wilcox.test
#% A (Q6): pseudo-median fall 8 mmHg (95% CI 7 to 8.5), p < 0.001.

# Q6. Why is a Mann-Whitney test wrong here?
#% A: the two measurements come from the same adults (paired); Mann-Whitney assumes independent groups.
