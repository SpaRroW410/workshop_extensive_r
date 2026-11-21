# ═══════════════════════════════════════════════════════════════
# MODERATE LAB 6 — Reports and export
# Medical Statistics in R · Moderate track · goes with: Quarto (intermediate), Exporting Plots
# Replace every ___ with the missing code. Hints describe the GOAL, not the answer.
# Save this file next to a folder called data/ that holds the dataset(s) named below
# (download them from the track home), or open the workshop RStudio project.
# ═══════════════════════════════════════════════════════════════

suppressPackageStartupMessages({library(ggplot2); library(readr)})
p <- c("data/ncd_survey.csv", "../data/ncd_survey.csv", "../../data/ncd_survey.csv"); p <- p[file.exists(p)][1]
ncd <- read_csv(p, show_col_types = FALSE)
out <- tempdir()                                    # change to a folder of your own, e.g. "figures"

g <- ggplot(ncd, aes(bmi, sbp)) + geom_point(alpha = 0.4) +
  labs(x = "BMI (kg/m²)", y = "Systolic BP (mmHg)")

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Save the plot as a PNG for print: 7 x 5 inches at 300 dpi.
ggsave(file.path(out, "bmi_sbp.png"), g, width = 7, height = 5, ___)

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Save the same plot as a vector PDF (it stays sharp at any size).
ggsave(file.path(out, "___"), g, width = 7, height = 5)

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: One PNG per residence group, from a loop (the same idea as a parameterised report).
for (r in unique(ncd$residence)) {
  gr <- ggplot(subset(ncd, ___), aes(bmi, sbp)) + geom_point() + ggtitle(r)
  ggsave(file.path(out, paste0("bmi_sbp_", r, ".png")), gr, width = 6, height = 4, dpi = 150)
}
list.files(out, pattern = "bmi_sbp")

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: The sentence a report would print inline: the mean SBP, rounded to 1 decimal.
sprintf("Mean systolic BP was %.1f mmHg.", ___(ncd$sbp, na.rm = TRUE))

# Q1. A journal asks for 600 dpi TIFF. Which arguments of ggsave() change?
