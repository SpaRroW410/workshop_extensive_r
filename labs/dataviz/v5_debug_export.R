# ═══════════════════════════════════════════════════════════════
# DATA VIZ LAB V5 — Debugging and exporting
# Medical Statistics in R · Data Visualization (Complete) · goes with: Debugging Plots and Advanced Exporting
# Replace every ___ with the missing code. Hints describe the GOAL, not the answer.
# Save this file next to a folder called data/ that holds the dataset(s) named below
# (download them from the track home), or open the workshop RStudio project.
# ═══════════════════════════════════════════════════════════════

suppressPackageStartupMessages({library(dplyr); library(readr); library(ggplot2)})
p <- c("data/ncd_survey.csv", "../data/ncd_survey.csv", "../../data/ncd_survey.csv"); p <- p[file.exists(p)][1]
ncd <- read_csv(p, show_col_types = FALSE) |> mutate(phys_act = factor(phys_act, levels = c("low", "moderate", "high")))
out <- tempdir()

# ── Task 1 ──────────────────────────────────────────────────────
# Bug: the points come out red with a legend that says "blue". Fix it so all points are blue.
# Broken:  ggplot(ncd, aes(age, sbp, colour = "blue")) + geom_point()
ggplot(ncd, aes(age, sbp)) + geom_point(___)

# ── Task 2 ──────────────────────────────────────────────────────
# Bug: "Discrete value supplied to continuous scale". htn is 0/1 numbers; make it a category first.
# Broken:  ggplot(ncd, aes(htn, sbp, fill = htn)) + geom_boxplot() + scale_fill_manual(values = c(No = "grey70", Yes = "firebrick"))
ncd2 <- mutate(ncd, htn = ___(htn, levels = 0:1, labels = c("No", "Yes")))
ggplot(ncd2, aes(htn, sbp, fill = htn)) + geom_boxplot() +
  scale_fill_manual(values = c(No = "grey70", Yes = "firebrick"))

# ── Task 3 ──────────────────────────────────────────────────────
# Bug: the layer after the line break is ignored. Where must the + go?
# Broken:  ggplot(ncd, aes(bmi, sbp))
#            + geom_point()
ggplot(ncd, aes(bmi, sbp)) ___
  geom_point()

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: One PNG per physical-activity group, named after the group, from a loop.
for (g in levels(ncd$phys_act)) {
  pg <- ggplot(filter(ncd, phys_act == g), aes(bmi, sbp)) + geom_point() + ggtitle(g)
  ggsave(file.path(out, ___("sbp_bmi_", g, ".png")), pg, width = 5, height = 4, dpi = 150)
}
list.files(out, pattern = "^sbp_bmi_")

# Q1. A plot looks wrong but gives no error. What do you check first?
