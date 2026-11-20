# ═══════════════════════════════════════════════════════════════
# BASIC LAB 3 — Joining and reshaping
# Medical Statistics in R · Basic track · goes with: Merging Datasets
# Replace every ___ with the missing code. Hints describe the GOAL, not the answer.
# Save this file next to a folder called data/ that holds the dataset(s) named below
# (download them from the track home), or open the workshop RStudio project.
# ═══════════════════════════════════════════════════════════════

suppressPackageStartupMessages({library(dplyr); library(tidyr)})
rd <- function(f) { p <- c(file.path("data", f), file.path("..", "data", f), file.path("..", "..", "data", f)); read.csv(p[file.exists(p)][1]) }
round1 <- rd("ncd_round1.csv"); round2 <- rd("ncd_round2.csv"); villages <- rd("villages.csv")

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Stack the two survey rounds into one data frame (same columns, more rows).
both <- ___(round1, round2)
nrow(round1); nrow(round2); nrow(both)

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Add the village information (district, distance to the PHC) to every person, keeping every person.
merged <- ___(both, villages, by = ___)
nrow(merged)

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Check that the join did not duplicate anyone: count rows per id.
merged |> count(id) |> filter(___)

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Reshape systolic and diastolic BP to long format: one row per person and measurement.
bp_long <- merged |> select(id, sbp, dbp) |>
  ___(cols = c(sbp, dbp), names_to = "measure", values_to = "mmHg")
head(bp_long)

# Q1. When would a left join ADD rows? What would you check first?
