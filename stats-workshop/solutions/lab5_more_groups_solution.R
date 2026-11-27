# ═══════════════════════════════════════════════════════════════
# LAB 5 — More groups, repeated measures, correlation
# Statistical analysis workshop | Session 5
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
# Goal: One-way ANOVA of BMI by wealth index; check residuals and spread; Welch ANOVA; Tukey; eta squared.
p |> group_by(wealth_index_of_participants) |> summarise(n = n(), mean = mean(bmi), sd = sd(bmi))
a <- aov(bmi ~ wealth_index_of_participants, data = p)             #@ aov
summary(a)
ggplot(tibble(r = residuals(a)), aes(sample = r)) + stat_qq() + stat_qq_line(colour = "red")
leveneTest(bmi ~ wealth_index_of_participants, data = p)
oneway.test(bmi ~ wealth_index_of_participants, data = p)          #@ oneway.test
TukeyHSD(a)                                                         #@ TukeyHSD
eta_squared(a)
#% A (Q1): mean BMI rises from 21.3 (poorest) to 24.9 kg/m2 (richest); F(4, 626) = 12.3, p < 0.001; eta squared 0.07 (medium: wealth explains about 7% of the variation). Residuals normal; Levene p = 0.035 but SDs 3.3 to 4.4; Welch ANOVA p < 0.001 agrees. Tukey: every group is heavier than the poorest (richest - poorest 3.6, 95% CI 2.1 to 5.1); the richest also differ from poorer and middle.

# Q1. Write the result: how big is the effect, and which groups differ?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Kruskal-Wallis of systolic pressure at presentation by marital status; Dunn post hoc; then look at age.
p |> group_by(marital_status_of_participants) |> summarise(median = median(sbp_presentation), mean_age = mean(age_of_participants))
kruskal.test(sbp_presentation ~ marital_status_of_participants, data = p)   #@ kruskal.test
dunn_test(p, sbp_presentation ~ marital_status_of_participants, p.adjust.method = "holm")   #@ "holm"
#% A (Q2): p = 0.008; medians 124 (never), 127 (currently), 136 mmHg (formerly married). Dunn (Holm): formerly vs never p = 0.006, formerly vs currently p = 0.026. But the formerly married are older (mean age 55 vs 43 and 34), and SBP rises with age: the difference may be age, which needs regression to separate.

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Repeated-measures ANOVA of fasting glucose at presentation, 3 and 6 months; then PAIRED post hoc tests.
fbs_long <- p |> select(s_no, fbs_presentation, fbs_3_months, fbs_6_months) |>
  pivot_longer(-s_no, names_to = "time", values_to = "fbs")        #@ pivot_longer
anova_test(data = fbs_long, dv = fbs, wid = s_no, within = time)   #@ within = time
pairwise.t.test(fbs_long$fbs, fbs_long$time, paired = TRUE, p.adjust.method = "bonferroni")   #@ paired = TRUE
#% A (Q3): means 109.0, 102.8, 98.6; Mauchly p < 0.001 (sphericity violated), so use the Greenhouse-Geisser result: epsilon 0.80, F(1.61, 1012) = 659, p < 0.001; generalised eta squared 0.08 (people differ from each other far more than from visit to visit). Every pair differs (paired, Bonferroni-adjusted).

# Q3. What does paired = TRUE change, and why is it required here?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Friedman test of systolic pressure over the three visits, with Kendall's W.
sbp_long <- p |> select(s_no, sbp_presentation, sbp_3_months, sbp_6_months) |>
  pivot_longer(-s_no, names_to = "time", values_to = "sbp")
friedman.test(sbp ~ time | s_no, data = sbp_long)                  #@ friedman.test
friedman_effsize(sbp_long, sbp ~ time | s_no)
#% A (Q4): p < 0.001; medians 127, 123, 120 mmHg; Kendall's W = 0.27 (small to moderate).

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Correlation of age with systolic pressure (Pearson) and with glucose (Spearman); r squared.
ct <- cor.test(p$age_of_participants, p$sbp_in_mm_hg)               #@ cor.test
ct
ct$estimate^2                                                       #@ ^2
cor.test(p$age_of_participants, p$glucose_level_mg_d_l, method = "spearman", exact = FALSE)   #@ method = "spearman"
#% A (Q5): r = 0.35 (95% CI 0.27 to 0.41), p < 0.001; r squared 0.12: age explains about 12% of the variation in SBP: a moderate association. Spearman for glucose (skewed): rho = 0.26.

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Holm adjustment for three p-values from planned comparisons.
p.adjust(c(0.012, 0.030, 0.041), method = "holm")                   #@ method = "holm"
#% A (Q6): 0.036, 0.060, 0.060: only the first stays below 0.05 after adjustment.
