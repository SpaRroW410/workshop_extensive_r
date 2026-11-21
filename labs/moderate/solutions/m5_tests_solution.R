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
chisq.test(tab)                                                     #@ chisq.test

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Foot pain was asked before and after, in the SAME people. Use the paired test.
paired <- table(before = d$pain_foot_bfr, after = d$pain_foot_aftr)
paired
mcnemar.test(paired)                                                #@ mcnemar.test
#% A: p = 0.65; McNemar uses only the discordant cells (yes->no and no->yes)

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Check whether systolic BP looks roughly normal with a Q-Q plot.
qqnorm(d$sbp_in_mm_hg); qqline(d$sbp_in_mm_hg, col = "red")         #@ qqnorm || qqline

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Mean systolic BP at presentation, 3 and 6 months, in one call.
sapply(d[c("sbp_presentation", "sbp_3_months", "sbp_6_months")], mean, na.rm = TRUE)   #@ sapply
#% A: 158, 137 and 127 mmHg

# Q1. Why is a chi-square test of association wrong for the before/after foot-pain table?
#% A: the two answers come from the same person, so they are not independent; McNemar accounts for the pairing.
