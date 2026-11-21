# ═══════════════════════════════════════════════════════════════
# DATA VIZ LAB V1 — Colours, scales and themes
# Medical Statistics in R · Data Visualization (Complete) · goes with: Module 3 — Colors, Scales & Themes
# Replace every ___ with the missing code. Hints describe the GOAL, not the answer.
# Save this file next to a folder called data/ that holds the dataset(s) named below
# (download them from the track home), or open the workshop RStudio project.
# ═══════════════════════════════════════════════════════════════

suppressPackageStartupMessages({library(dplyr); library(readr); library(ggplot2)})
p <- c("data/ncd_survey.csv", "../data/ncd_survey.csv", "../../data/ncd_survey.csv"); p <- p[file.exists(p)][1]
ncd <- read_csv(p, show_col_types = FALSE) |> mutate(phys_act = factor(phys_act, levels = c("low", "moderate", "high")))

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Colour the points by physical activity with a colour-blind-safe discrete palette.
ggplot(ncd, aes(age, sbp, colour = phys_act)) + geom_point(alpha = 0.6) +
  ___()

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Your own colours for sex: Female = "#B8336A", Male = "#2C5F8D".
ggplot(ncd, aes(sex, fill = sex)) + geom_bar() +
  ___(values = c(Female = "#B8336A", Male = "#2C5F8D"))

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Colour by the distance of SBP from 140: blue below, red above, white at 140.
ggplot(ncd, aes(age, bmi, colour = sbp)) + geom_point() +
  scale_colour_gradient2(low = "blue", mid = "white", high = "red", ___)

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: A report theme: minimal, no minor grid lines, legend at the bottom.
theme_report <- theme_minimal(base_size = 12) +
  theme(panel.grid.minor = ___(), legend.position = ___)

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Make theme_report the default for every later plot in this session.
___(theme_report)
ggplot(ncd, aes(bmi, sbp, colour = sex)) + geom_point(alpha = 0.5)

# Q1. Print Task 1 in greyscale (or view it with a colour-blindness simulator). Can you still tell the groups apart?
