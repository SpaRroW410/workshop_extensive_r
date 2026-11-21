# ═══════════════════════════════════════════════════════════════
# MODERATE LAB 3 — Explore by picture
# Medical Statistics in R · Moderate track · goes with: Grammar of Graphics, Best Practices, Merged Visuals, Statistical Plots
# Replace every ___ with the missing code. Hints describe the GOAL, not the answer.
# Save this file next to a folder called data/ that holds the dataset(s) named below
# (download them from the track home), or open the workshop RStudio project.
# ═══════════════════════════════════════════════════════════════

suppressPackageStartupMessages({library(ggplot2); library(readr)})
p <- c("data/ncd_survey.csv", "../data/ncd_survey.csv", "../../data/ncd_survey.csv"); p <- p[file.exists(p)][1]
ncd <- read_csv(p, show_col_types = FALSE)

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: A scatter plot of systolic BP against age, coloured by sex (a mapped colour).
ggplot(ncd, aes(x = age, y = sbp, ___)) + geom_point(alpha = 0.5)

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: The same plot with one panel per residence (Urban / Rural).
ggplot(ncd, aes(age, sbp)) + geom_point(alpha = 0.5) + ___(~ residence)

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: A histogram of BMI with a density curve on the same scale.
ggplot(ncd, aes(bmi)) +
  geom_histogram(aes(y = ___), bins = 30, fill = "grey80") +
  geom_density(colour = "firebrick")

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Box plots of SBP by physical activity with the raw points jittered on top.
ggplot(ncd, aes(phys_act, sbp)) + geom_boxplot(outlier.shape = NA) +
  ___(width = 0.2, alpha = 0.3)

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Tidy labels and a plain theme for a report.
ggplot(ncd, aes(age, sbp)) + geom_point(alpha = 0.4) +
  ___(x = "Age (years)", y = "Systolic BP (mmHg)") + ___()

# Q1. Which plot answered "does SBP differ by activity?" best, and what would you add for a paper?
