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
a <- ___(height ~ marital_status_of_participants, data = p)
summary(a)
ggplot(tibble(r = residuals(a)), aes(sample = r)) + stat_qq() + stat_qq_line(colour = "red")
leveneTest(height ~ marital_status_of_participants, data = p)
___(height ~ marital_status_of_participants, data = p)
___(a)
eta_squared(a)

# Q1. Write the result. Is "a trend towards significance" a fair description?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Kruskal-Wallis of systolic pressure at presentation by marital status.
___(sbp_presentation ~ marital_status_of_participants, data = p)

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Repeated-measures ANOVA of fasting glucose at presentation, 3 and 6 months; then PAIRED post hoc tests.
fbs_long <- p |> select(s_no, fbs_presentation, fbs_3_months, fbs_6_months) |>
  ___(-s_no, names_to = "time", values_to = "fbs")
anova_test(data = fbs_long, dv = fbs, wid = s_no, ___)
pairwise.t.test(fbs_long$fbs, fbs_long$time, ___, p.adjust.method = "bonferroni")

# Q3. What does paired = TRUE change, and why is it required here?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Friedman test of systolic pressure over the three visits, with Kendall's W.
sbp_long <- p |> select(s_no, sbp_presentation, sbp_3_months, sbp_6_months) |>
  pivot_longer(-s_no, names_to = "time", values_to = "sbp")
___(sbp ~ time | s_no, data = sbp_long)
friedman_effsize(sbp_long, sbp ~ time | s_no)

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Correlation of age with systolic pressure (Pearson) and with glucose (Spearman); r squared.
ct <- ___(p$age_of_participants, p$sbp_in_mm_hg)
ct
ct$estimate___
cor.test(p$age_of_participants, p$glucose_level_mg_d_l, ___, exact = FALSE)

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Holm adjustment for three p-values from planned comparisons.
p.adjust(c(0.012, 0.030, 0.041), method = ___)
