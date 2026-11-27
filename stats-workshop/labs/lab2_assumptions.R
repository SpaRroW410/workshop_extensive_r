# ═══════════════════════════════════════════════════════════════
# LAB 2 — Checking assumptions
# Statistical analysis workshop | Session 2
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
suppressPackageStartupMessages(library(nortest))

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Histogram and Q-Q plot for height (all adults, then women only) and for glucose.
ggplot(p, aes(height)) + geom_histogram(binwidth = 3, fill = "#3498db", colour = "white")
women <- filter(p, sex_of_participants == "female")
ggplot(women, aes(sample = height)) + ___ + ___(colour = "red")
ggplot(p, aes(sample = glucose_level_mg_d_l)) + stat_qq() + stat_qq_line(colour = "red")

# Q1. Describe each Q-Q plot in one sentence.

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Shapiro-Wilk for height (all adults, then women), Lilliefors and Anderson-Darling for women; then age.
___(p$height)$p.value
shapiro.test(women$height)$p.value
___(women$height)$p.value
ad.test(women$height)$p.value
shapiro.test(p$age_of_participants)$p.value
skew(p$age_of_participants)

# Q2. Age gives p < 0.001 but a skewness of 0.7. Can you still use a t-test on age? Why?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: The KS trap. Compare ks.test() with and without the mean and SD.
ks.test(women$height, "pnorm")$p.value
ks.test(women$height, "pnorm", mean = ___, sd = ___)$p.value

# Q3. Why is the first p-value 0?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: For a PAIRED comparison of fasting glucose (presentation vs 6 months), check the DIFFERENCES.
d <- ___
skew(d)
ggplot(tibble(d), aes(sample = d)) + stat_qq() + stat_qq_line(colour = "red")

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Equal spread of weight in women and men; then Welch vs Student.
p |> group_by(sex_of_participants) |> summarise(sd = sd(weight))
___(weight ~ sex_of_participants, data = p)
t.test(weight ~ sex_of_participants, data = p)$conf.int                       # Welch (R's default)
t.test(weight ~ sex_of_participants, data = p, ___)$conf.int     # Student

# Q5. Why not run Levene first and then pick Student or Welch?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Does a log transform make glucose symmetric?
c(raw = skew(p$glucose_level_mg_d_l), log = skew(___))
