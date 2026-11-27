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
#% A (Q2): poorest 76 (12.0%), poorer 113 (17.9%), middle 139 (22.0%), richer 158 (25.0%), richest 145 (23.0%). The order comes from factor(levels = ...) in the setup; without it R sorts alphabetically.

# Q2. Why does the order of the levels matter for an ordinal variable?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Mean (SD) and median (IQR) for age and for glucose.
p |> summarise(mean = mean(age_of_participants), sd = sd(age_of_participants),
               median = median(age_of_participants), iqr = IQR(age_of_participants))   #@ median || IQR
p |> summarise(mean = mean(glucose_level_mg_d_l), sd = sd(glucose_level_mg_d_l),
               median = median(glucose_level_mg_d_l), iqr = IQR(glucose_level_mg_d_l))
c(age = skew(p$age_of_participants), glucose = skew(p$glucose_level_mg_d_l))           #@ skew(p$glucose_level_mg_d_l)
#% A (Q3): age: mean 43.4 (SD 11.5), median 42 (IQR 16); glucose: mean 110 (SD 26), median 106 (IQR 19). Glucose is strongly skewed (3.6): report median (IQR). Age is mildly skewed (0.7): either is acceptable; mean (SD) is common.

# Q3. Which summary would you report for glucose, and why?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Look for impossible or suspicious values: SBP below DBP, implausible weights, extreme glucose.
sum(p$sbp_in_mm_hg < p$dbp_in_mm_hg)                                #@ p$dbp_in_mm_hg
p |> filter(sbp_in_mm_hg < dbp_in_mm_hg | weight < 20) |>           #@ weight < 20
  select(s_no, sbp_in_mm_hg, dbp_in_mm_hg, height, weight)
range(p$glucose_level_mg_d_l)                                       #@ range
#% A (Q4): 4 adults have SBP below DBP (S.no 57, 212, 388, 540: the two columns were swapped at entry), and S.no 301 weighs 5.6 kg at 161 cm (decimal point lost: 56 kg). Query the case sheets, correct what is confirmed (below), report it, and run a sensitivity analysis. A glucose of 291 mg/dL is high but possible in uncontrolled diabetes: keep it.

# Q4. What would you do before using these columns in a thesis?

# The case sheets confirmed both errors, so correct them (Labs 2-5 start from this corrected data):
p <- p |>
  mutate(swapped = sbp_in_mm_hg < dbp_in_mm_hg,
         sbp = if_else(swapped, dbp_in_mm_hg, sbp_in_mm_hg),
         dbp_in_mm_hg = if_else(swapped, sbp_in_mm_hg, dbp_in_mm_hg),
         sbp_in_mm_hg = sbp,
         weight = if_else(weight < 20, weight * 10, weight)) |>
  select(-swapped, -sbp)
sum(p$sbp_in_mm_hg < p$dbp_in_mm_hg)                                # now 0

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Choose a test for each question (write the name; no code).
# a) Is diabetes more common in men than in women?
# b) Did foot pain change after the intervention (same adults, yes/no before and after)?
# c) Does mean weight differ between women and men?
# d) Does glucose (skewed) differ between adults with and without a history of diabetes?
# e) Did fasting glucose change across presentation, 3 and 6 months?
#% A (Q5): a) chi-square (Fisher if an expected count < 5); b) McNemar; c) Welch t-test; d) Mann-Whitney U; e) repeated-measures ANOVA (Friedman if skewed).
