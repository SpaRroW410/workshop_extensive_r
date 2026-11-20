# ═══════════════════════════════════════════════════════════════
# BASIC LAB 5 — Which test?
# Medical Statistics in R · Basic track · goes with: Test Selection Guide and ggstatsplot — Intro
# Replace every ___ with the missing code. Hints describe the GOAL, not the answer.
# Save this file next to a folder called data/ that holds the dataset(s) named below
# (download them from the track home), or open the workshop RStudio project.
# ═══════════════════════════════════════════════════════════════

p <- c("data/ncd_survey.csv", "../data/ncd_survey.csv", "../../data/ncd_survey.csv"); p <- p[file.exists(p)][1]
ncd <- read.csv(p)

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Compare mean systolic BP between men and women (two groups, continuous outcome).
___(sbp ~ sex, data = ncd)

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Is hypertension (htn) associated with tobacco use? Both are categorical: make the table, then test it.
tab <- ___(ncd$tobacco, ncd$htn)
tab
___(tab)

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Compare systolic BP across the three physical-activity levels (more than two groups).
summary(___(sbp ~ phys_act, data = ncd))

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Correlation between BMI and systolic BP (two continuous variables), with a confidence interval.
___(ncd$bmi, ncd$sbp)

# Q1. For Task 1: write one sentence with the difference, its 95% CI and the p-value.
# Q2. Which test would you use if systolic BP were very skewed? (two groups; more than two groups)
