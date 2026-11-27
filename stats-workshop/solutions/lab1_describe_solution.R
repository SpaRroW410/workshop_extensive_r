# ═══════════════════════════════════════════════════════════════
# LAB 1 — Know your data, choose your test
# Statistical analysis workshop | Session 1
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
# Goal: How many adults, and how many variables?
dim(p)                                                              #@ dim
#% A: 631 adults, 26 variables.

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Count and percentage for the wealth index, in order from poorest to richest.
p |> count(wealth_index_of_participants) |> mutate(percent = round(100 * n / sum(n), 1))   #@ count || sum(n)
#% A (Q2): poorest 34 (5.4%), poorer 106 (16.8%), middle 147 (23.3%), richer 177 (28.1%), richest 167 (26.5%). The order comes from factor(levels = ...) in the setup; without it R sorts alphabetically.

# Q2. Why does the order of the levels matter for an ordinal variable?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Mean (SD) and median (IQR) for age and for glucose.
p |> summarise(mean = mean(age_of_participants), sd = sd(age_of_participants),
               median = median(age_of_participants), iqr = IQR(age_of_participants))   #@ median || IQR
p |> summarise(mean = mean(glucose_level_mg_d_l), sd = sd(glucose_level_mg_d_l),
               median = median(glucose_level_mg_d_l), iqr = IQR(glucose_level_mg_d_l))
c(age = skew(p$age_of_participants), glucose = skew(p$glucose_level_mg_d_l))           #@ skew(p$glucose_level_mg_d_l)
#% A (Q3): age: mean 43.8 (SD 17.4), median 42 (IQR 29); glucose: mean 121 (SD 44), median 111 (IQR 27.5). Glucose is strongly skewed (4.4): report median (IQR). Age is mildly skewed (0.4): either is acceptable; mean (SD) is common.

# Q3. Which summary would you report for glucose, and why?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Look for impossible or suspicious values in blood pressure.
sum(p$sbp_in_mm_hg < p$dbp_in_mm_hg)                                #@ p$dbp_in_mm_hg
range(c(p$sbp_presentation, p$sbp_3_months, p$sbp_6_months))       #@ range
median(p$dbp_in_mm_hg)
#% A (Q4): 104 adults have SBP below DBP (impossible); follow-up SBP spans 38 to 387 mmHg (implausible at both ends); the median DBP of 108 mmHg is implausibly high for a screening population. Query the source, decide exclusions before testing, report them, and run a sensitivity analysis.

# Q4. What would you do before using the blood pressure columns in a thesis?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Choose a test for each question (write the name; no code).
# a) Is diabetes more common in men than in women?
# b) Did foot pain change after the intervention (same adults, yes/no before and after)?
# c) Does mean weight differ between women and men?
# d) Does glucose (skewed) differ between adults with and without a history of diabetes?
# e) Did fasting glucose change across presentation, 3 and 6 months?
#% A (Q5): a) chi-square (Fisher if an expected count < 5); b) McNemar; c) Welch t-test; d) Mann-Whitney U; e) repeated-measures ANOVA (Friedman if skewed).
