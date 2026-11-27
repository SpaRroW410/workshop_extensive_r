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
skew <- function(x) { x <- x[!is.na(x)]; mean((x - mean(x))^3) / sd(x)^3 }

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: One-way ANOVA of height by marital status; check residuals and spread; Welch ANOVA; Tukey; eta squared.
a <- aov(height ~ marital_status_of_participants, data = p)        #@ aov
summary(a)
ggplot(tibble(r = residuals(a)), aes(sample = r)) + stat_qq() + stat_qq_line(colour = "red")
leveneTest(height ~ marital_status_of_participants, data = p)
oneway.test(height ~ marital_status_of_participants, data = p)     #@ oneway.test
TukeyHSD(a)                                                         #@ TukeyHSD
eta_squared(a)
#% A (Q1): F(2, 628) = 2.89, p = 0.056; eta squared 0.009. Residuals normal, Levene p = 0.84, Welch p = 0.056. Weak evidence; marital status explains under 1% of the variation in height. Never vs currently married: 2.5 cm (95% CI -0.03 to 5.0).

# Q1. Write the result. Is "a trend towards significance" a fair description?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Kruskal-Wallis of systolic pressure at presentation by marital status.
kruskal.test(sbp_presentation ~ marital_status_of_participants, data = p)   #@ kruskal.test
#% A (Q2): p = 0.57, medians 149-153 mmHg. No evidence of a difference, so no post hoc tests.

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Repeated-measures ANOVA of fasting glucose at presentation, 3 and 6 months; then PAIRED post hoc tests.
fbs_long <- p |> select(s_no, fbs_presentation, fbs_3_months, fbs_6_months) |>
  pivot_longer(-s_no, names_to = "time", values_to = "fbs")        #@ pivot_longer
anova_test(data = fbs_long, dv = fbs, wid = s_no, within = time)   #@ within = time
pairwise.t.test(fbs_long$fbs, fbs_long$time, paired = TRUE, p.adjust.method = "bonferroni")   #@ paired = TRUE
#% A (Q3): means 100.2, 90.1, 85.0; F(2, 1260) = 361, p < 0.001; Mauchly p = 0.86 (sphericity holds), generalised eta squared 0.28. Every pair differs (paired, Bonferroni-adjusted).

# Q3. What does paired = TRUE change, and why is it required here?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Friedman test of systolic pressure over the three visits, with Kendall's W.
sbp_long <- p |> select(s_no, sbp_presentation, sbp_3_months, sbp_6_months) |>
  pivot_longer(-s_no, names_to = "time", values_to = "sbp")
friedman.test(sbp ~ time | s_no, data = sbp_long)                  #@ friedman.test
friedman_effsize(sbp_long, sbp ~ time | s_no)
#% A (Q4): p < 0.001; medians 151, 133, 121 mmHg; Kendall's W = 0.11 (small).

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Correlation of age with systolic pressure (Pearson) and with glucose (Spearman); r squared.
ct <- cor.test(p$age_of_participants, p$sbp_in_mm_hg)               #@ cor.test
ct
ct$estimate^2                                                       #@ ^2
cor.test(p$age_of_participants, p$glucose_level_mg_d_l, method = "spearman", exact = FALSE)   #@ method = "spearman"
#% A (Q5): r = 0.18 (95% CI 0.10 to 0.25), p < 0.001; r squared 0.03: age explains about 3% of the variation in SBP: real but weak. Spearman for glucose (skewed): rho = 0.11.

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Holm adjustment for three p-values from planned comparisons.
p.adjust(c(0.012, 0.030, 0.041), method = "holm")                   #@ "holm"
#% A (Q6): 0.036, 0.060, 0.060: only the first stays below 0.05 after adjustment.
