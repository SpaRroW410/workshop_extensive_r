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
ggplot(women, aes(sample = height)) + stat_qq() + stat_qq_line(colour = "red")      #@ stat_qq() || stat_qq_line
ggplot(p, aes(sample = glucose_level_mg_d_l)) + stat_qq() + stat_qq_line(colour = "red")
#% A (Q1): all adults: two humps (women and men mixed), so not normal as a whole; women only: on the line (roughly normal); glucose curves sharply upward at the right: a long right tail with outliers.

# Q1. Describe each Q-Q plot in one sentence.

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Shapiro-Wilk for height (all adults, then women), Lilliefors and Anderson-Darling for women; then age.
shapiro.test(p$height)$p.value                                      #@ shapiro.test
shapiro.test(women$height)$p.value
lillie.test(women$height)$p.value                                   #@ lillie.test
ad.test(women$height)$p.value
shapiro.test(p$age_of_participants)$p.value
skew(p$age_of_participants)
#% A (Q2): height of all adults: Shapiro-Wilk p = 0.003 (a mixture of two groups); height of women: p = 0.47, Lilliefors 0.28, Anderson-Darling 0.14 (compatible with normal). Age: p < 0.001 with skewness 0.7. With 631 adults the test flags a mild departure; a t-test on age is still reasonable (large groups, central limit theorem). For a comparison by sex, what must be normal is height within each sex.

# Q2. Age gives p < 0.001 but a skewness of 0.7. Can you still use a t-test on age? Why?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: The KS trap. Compare ks.test() with and without the mean and SD.
ks.test(women$height, "pnorm")$p.value
ks.test(women$height, "pnorm", mean = mean(women$height), sd = sd(women$height))$p.value   #@ mean(women$height) || sd(women$height)
#% A (Q3): without mean and SD the comparison is with a standard normal (mean 0, SD 1): p = 0 for any height. With them, p = 0.72; with estimated parameters use the Lilliefors version (p = 0.28).

# Q3. Why is the first p-value 0?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: For a PAIRED comparison of fasting glucose (presentation vs 6 months), check the DIFFERENCES.
d <- p$fbs_presentation - p$fbs_6_months                            #@ p$fbs_presentation - p$fbs_6_months
skew(d)
ggplot(tibble(d), aes(sample = d)) + stat_qq() + stat_qq_line(colour = "red")
#% A (Q4): the differences are symmetric (skewness -0.04) and lie on the line: the paired t-test assumption holds.

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Equal spread of weight in women and men; then Welch vs Student.
p |> group_by(sex_of_participants) |> summarise(sd = sd(weight))
leveneTest(weight ~ sex_of_participants, data = p)                  #@ leveneTest
t.test(weight ~ sex_of_participants, data = p)$conf.int                       # Welch (R's default)
t.test(weight ~ sex_of_participants, data = p, var.equal = TRUE)$conf.int     # Student   #@ var.equal = TRUE
#% A (Q5): SDs 9.8 (women) and 12.5 kg (men); Levene p < 0.001, yet the ratio is only 1.3. Welch 95% CI -8.75 to -5.21, Student -8.73 to -5.23: with similar group sizes they agree; Welch stays correct when spreads and sizes differ, so use it by default.

# Q5. Why not run Levene first and then pick Student or Welch?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Does a log transform make glucose symmetric?
c(raw = skew(p$glucose_level_mg_d_l), log = skew(log(p$glucose_level_mg_d_l)))   #@ log(p$glucose_level_mg_d_l)
#% A (Q6): skewness falls from 3.6 to 1.9: better but still skewed (the diabetic values form a long tail). Use a rank-based test and report medians (IQR).
