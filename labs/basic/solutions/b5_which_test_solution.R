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
t.test(sbp ~ sex, data = ncd)                                      #@ t.test
#% A: women 130.3, men 134.1 mmHg; difference 3.8 mmHg (95% CI 1.1 to 6.5), p = 0.006

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Is hypertension (htn) associated with tobacco use? Both are categorical: make the table, then test it.
tab <- table(ncd$tobacco, ncd$htn)                                 #@ table
tab
chisq.test(tab)                                                    #@ chisq.test
#% A: hypertension in 41% of tobacco users (74/180) vs 28% of non-users (118/420); chi-square p = 0.002

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Compare systolic BP across the three physical-activity levels (more than two groups).
summary(aov(sbp ~ phys_act, data = ncd))                           #@ aov
#% A: F = 0.05, p = 0.95: no evidence that mean SBP differs by activity level

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Correlation between BMI and systolic BP (two continuous variables), with a confidence interval.
cor.test(ncd$bmi, ncd$sbp)                                         #@ cor.test
#% A: r = 0.33 (95% CI 0.26 to 0.40), p < 0.001

# Q1. For Task 1: write one sentence with the difference, its 95% CI and the p-value.
# Q2. Which test would you use if systolic BP were very skewed? (two groups; more than two groups)
#% A: Wilcoxon rank-sum (wilcox.test) for two groups; Kruskal-Wallis (kruskal.test) for more than two
