# ═══════════════════════════════════════════════════════════════
# DATA VIZ LAB V4 — Interactive plots
# Medical Statistics in R · Data Visualization (Complete) · goes with: Interactive Plots
# Replace every ___ with the missing code. Hints describe the GOAL, not the answer.
# Save this file next to a folder called data/ that holds the dataset(s) named below
# (download them from the track home), or open the workshop RStudio project.
# ═══════════════════════════════════════════════════════════════

suppressPackageStartupMessages({library(dplyr); library(readr); library(ggplot2)})
p <- c("data/ncd_survey.csv", "../data/ncd_survey.csv", "../../data/ncd_survey.csv"); p <- p[file.exists(p)][1]
ncd <- read_csv(p, show_col_types = FALSE) |> mutate(phys_act = factor(phys_act, levels = c("low", "moderate", "high")))
suppressPackageStartupMessages({library(plotly); library(DT)})
out <- tempdir()

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Make this ggplot interactive, with a tooltip showing the id and SBP only.
p <- ggplot(ncd, aes(age, sbp, colour = sex, text = paste0("id ", id, "<br>SBP ", sbp))) + geom_point()
w1 <- ___(p, tooltip = ___)
w1

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: A native plotly histogram of BMI with one colour per sex, overlaid.
w2 <- plot_ly(ncd, x = ~bmi, color = ~sex, type = ___, alpha = 0.6) |>
  layout(barmode = "overlay")
w2

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: A searchable table of id, age, sex and sbp with a filter box above each column.
datatable(select(ncd, id, age, sex, sbp), rownames = FALSE, ___)

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Save the widget from Task 1 as a stand-alone HTML file you can e-mail.
htmlwidgets::___(w1, file.path(out, "sbp_age.html"), selfcontained = FALSE)
file.exists(file.path(out, "sbp_age.html"))

# Q1. Your paper goes to a journal as PDF. What do you do with the interactive figure?
