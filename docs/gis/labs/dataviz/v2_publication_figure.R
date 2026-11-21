# ═══════════════════════════════════════════════════════════════
# DATA VIZ LAB V2 — A publication figure
# Medical Statistics in R · Data Visualization (Complete) · goes with: Module 4 — Advanced Best Practices
# Replace every ___ with the missing code. Hints describe the GOAL, not the answer.
# Save this file next to a folder called data/ that holds the dataset(s) named below
# (download them from the track home), or open the workshop RStudio project.
# ═══════════════════════════════════════════════════════════════

suppressPackageStartupMessages({library(dplyr); library(readr); library(ggplot2)})
p <- c("data/ncd_survey.csv", "../data/ncd_survey.csv", "../../data/ncd_survey.csv"); p <- p[file.exists(p)][1]
ncd <- read_csv(p, show_col_types = FALSE) |> mutate(phys_act = factor(phys_act, levels = c("low", "moderate", "high")))
suppressPackageStartupMessages(library(patchwork))
out <- tempdir()                                    # change to a folder of your own, e.g. "figures"

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Points first, then a linear trend line with its 95% band DRAWN ON TOP of the points.
p1 <- ggplot(ncd, aes(bmi, sbp)) + geom_point(alpha = 0.3) +
  ___(method = "lm", formula = y ~ x)
p1

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Mean SBP per physical-activity group as horizontal bars (flip the axes).
p2 <- ncd |> group_by(phys_act) |> summarise(sbp = mean(sbp)) |>
  ggplot(aes(phys_act, sbp)) + geom_col(fill = "grey60") + ___()
p2

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Labels with units, a caption with the data source, and the panel tags A and B.
fig <- (p1 + labs(x = "BMI (kg/m²)", y = "Systolic BP (mmHg)")) +
  (p2 + labs(x = NULL, y = "Mean systolic BP (mmHg)")) +
  plot_annotation(___, caption = "Source: NCD survey (simulated)")
fig

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Save it for a journal: 18 cm wide, 8 cm high, 600 dpi, as a TIFF.
ggsave(file.path(out, "figure1.tiff"), fig, width = 18, height = 8, ___, dpi = 600)
file.exists(file.path(out, "figure1.tiff"))

# Q1. Task 2 shows means as bars starting at 0. When would points with 95% CIs be the better choice?
