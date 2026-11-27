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
t.test(p$fbs_presentation, mu = 100)                                #@ mu = 100
#% A (Q1): mean 100.2 (95% CI 99.4 to 101.0), p = 0.61: the mean is close to 100; any difference is under about 1 mg/dL.

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: The same test for age in the poorest adults vs the mean of all adults. Compare the CI with Task 1.
poor <- filter(p, wealth_index_of_participants == "poorest")
t.test(poor$age_of_participants, mu = mean(p$age_of_participants))  #@ mean(p$age_of_participants)
#% A (Q2): n = 34; mean 49.1 vs 43.8; 95% CI 42.3 to 56.0, p = 0.13. Also not significant, but imprecise: a difference of up to 12 years is still compatible with the data.

# Q2. Both tests are "not significant". Which one tells you more, and why?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Age by diabetes history: Welch t-test and Cohen's d.
p |> group_by(past_history_of_diabetes) |> summarise(n = n(), mean = mean(age_of_participants), sd = sd(age_of_participants))
t.test(age_of_participants ~ past_history_of_diabetes, data = p)    #@ age_of_participants ~ past_history_of_diabetes
cohens_d(age_of_participants ~ past_history_of_diabetes, data = p, pooled_sd = FALSE)   #@ cohens_d
#% A (Q3): 52.3 vs 43.4 years; difference 8.9 years (95% CI 4.1 to 13.7), Welch p < 0.001; d = 0.57 (medium). Welch matters here: 34 vs 597 adults.

# Q3. Write the sentence (direction, difference, 95% CI, test, p, d).

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Glucose (skewed) by diabetes history: medians (IQR), Mann-Whitney with the Hodges-Lehmann shift, and r.
p |> group_by(past_history_of_diabetes) |> summarise(median = median(glucose_level_mg_d_l), q1 = quantile(glucose_level_mg_d_l, .25), q3 = quantile(glucose_level_mg_d_l, .75))
wilcox.test(glucose_level_mg_d_l ~ past_history_of_diabetes, data = p, conf.int = TRUE)   #@ conf.int = TRUE
wilcox_effsize(p, glucose_level_mg_d_l ~ past_history_of_diabetes)
#% A (Q4): medians 156 vs 109 mg/dL; Hodges-Lehmann shift 52 mg/dL (95% CI 35 to 81), p < 0.001; r = 0.27. Say that glucose tends to be higher, not that the medians differ, unless the shapes are similar.

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Paired t-test of fasting glucose at presentation and 6 months. Check the differences first.
d <- p$fbs_presentation - p$fbs_6_months
c(mean = mean(d), sd = sd(d), skew = skew(d))
t.test(p$fbs_presentation, p$fbs_6_months, paired = TRUE)          #@ paired = TRUE
mean(d) / sd(d)                                                     #@ mean(d) / sd(d)
#% A (Q5): mean fall 15.2 mg/dL (95% CI 14.1 to 16.3), p < 0.001; dz = 1.04 (large). The differences are symmetric, so the paired t-test fits.

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Systolic pressure at presentation and 6 months (skewed, outliers): Wilcoxon signed-rank.
wilcox.test(p$sbp_presentation, p$sbp_6_months, paired = TRUE, conf.int = TRUE)   #@ wilcox.test
#% A (Q6): pseudo-median fall 31 mmHg (95% CI 27 to 35), p < 0.001. Given the implausible SBP values (Session 1), repeat without them before trusting the size.

# Q6. Why is a Mann-Whitney test wrong here?
#% A: the two measurements come from the same adults (paired); Mann-Whitney assumes independent groups.
