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
both <- bind_rows(round1, round2)                                  #@ bind_rows
nrow(round1); nrow(round2); nrow(both)
#% A: 300 + 300 = 600 rows

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Add the village information (district, distance to the PHC) to every person, keeping every person.
merged <- left_join(both, villages, by = "village")                #@ left_join || "village"
nrow(merged)
#% A: the same number of rows as `both`: a left join never drops rows from the left table

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Check that the join did not duplicate anyone: count rows per id.
merged |> count(id) |> filter(n > 1)                               #@ n > 1
#% A: 0 rows: every id appears once (each village appears once in villages.csv)

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Reshape systolic and diastolic BP to long format: one row per person and measurement.
bp_long <- merged |> select(id, sbp, dbp) |>
  pivot_longer(cols = c(sbp, dbp), names_to = "measure", values_to = "mmHg")   #@ pivot_longer
head(bp_long)

# Q1. When would a left join ADD rows? What would you check first?
