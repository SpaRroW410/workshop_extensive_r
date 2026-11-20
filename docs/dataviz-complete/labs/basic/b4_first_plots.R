# ═══════════════════════════════════════════════════════════════
# BASIC LAB 4 — First plots with ggplot2
# Medical Statistics in R · Basic track · goes with: Grammar of Graphics and the Basic Plot Gallery
# Replace every ___ with the missing code. Hints describe the GOAL, not the answer.
# Save this file next to a folder called data/ that holds the dataset(s) named below
# (download them from the track home), or open the workshop RStudio project.
# ═══════════════════════════════════════════════════════════════

suppressPackageStartupMessages(library(ggplot2))
p <- c("data/ncd_survey.csv", "../data/ncd_survey.csv", "../../data/ncd_survey.csv"); p <- p[file.exists(p)][1]
ncd <- read.csv(p)

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: The distribution of age, one continuous variable.
ggplot(ncd, aes(x = age)) + ___(binwidth = 5)

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Systolic BP compared between the categories of physical activity.
ggplot(ncd, aes(x = phys_act, y = sbp)) + ___()

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: How many people use tobacco, by sex (counts of two categorical variables).
ggplot(ncd, aes(x = sex, fill = tobacco)) + ___(position = "dodge")

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: The relationship between two continuous variables: BMI and systolic BP, with a straight trend line.
ggplot(ncd, aes(x = bmi, y = sbp)) + ___(alpha = 0.4) + geom_smooth(method = ___)

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Add a title and axis labels with units to the last plot.
ggplot(ncd, aes(x = bmi, y = sbp)) + geom_point(alpha = 0.4) +
  ___(title = "BMI and systolic blood pressure", x = "BMI (kg/m²)", y = "Systolic BP (mmHg)")

# Q1. For each plot, which type of variable (continuous or categorical) is on each axis?
