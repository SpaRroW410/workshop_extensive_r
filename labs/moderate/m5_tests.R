# ═══════════════════════════════════════════════════════════════
# MODERATE LAB 5 — Tests in context
# Medical Statistics in R · Moderate track · goes with: Data Analysis
# Replace every ___ with the missing code. Hints describe the GOAL, not the answer.
# Save this file next to a folder called data/ that holds the dataset(s) named below
# (download them from the track home), or open the workshop RStudio project.
# ═══════════════════════════════════════════════════════════════

suppressPackageStartupMessages({library(readxl); library(janitor)})
p <- c("data/prac_modded.xlsx", "../data/prac_modded.xlsx", "../../data/prac_modded.xlsx"); p <- p[file.exists(p)][1]
d <- clean_names(read_excel(p))

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: A table of sex by past history of diabetes, and a chi-square test of association.
tab <- table(d$sex_of_participants, d$past_history_of_diabetes)
tab
___(tab)

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Foot pain was asked before and after, in the SAME people. Use the paired test.
paired <- table(before = d$pain_foot_bfr, after = d$pain_foot_aftr)
paired
___(paired)

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Check whether systolic BP looks roughly normal with a Q-Q plot.
___(d$sbp_in_mm_hg); ___(d$sbp_in_mm_hg, col = "red")

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Mean systolic BP at presentation, 3 and 6 months, in one call.
___(d[c("sbp_presentation", "sbp_3_months", "sbp_6_months")], mean, na.rm = TRUE)

# Q1. Why is a chi-square test of association wrong for the before/after foot-pain table?
