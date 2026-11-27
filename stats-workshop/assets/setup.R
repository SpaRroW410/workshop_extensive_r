# Shared setup for the five decks + cheat sheet (labs carry their own inline copy so each lab stays a standalone script).
# Data: the practice dataset of the Basic track's Data Analysis page (data/prac_modded.xlsx), read as in its script.
suppressPackageStartupMessages({ library(tidyverse); library(readxl); library(janitor); library(rstatix); library(effectsize); library(car) })
theme_set(theme_minimal(base_size = 16))
p_path <- c("data/prac_modded.xlsx", "../data/prac_modded.xlsx", "../../data/prac_modded.xlsx")
p_path <- p_path[file.exists(p_path)][1]
p_raw <- read_excel(p_path) |> clean_names() |>
  mutate(
    wealth_index_of_participants   = factor(wealth_index_of_participants, levels = c("poorest", "poorer", "middle", "richer", "richest")),
    marital_status_of_participants = factor(marital_status_of_participants, levels = c("never married", "currently married", "formerly/ever married")),
    sex_of_participants            = factor(sex_of_participants),
    across(c(pain_foot_bfr, pain_foot_aftr), \(x) factor(x, levels = c("No", "Yes")))
  )
# Session 1 finds two entry errors in p_raw: SBP and DBP swapped in 4 records, one weight typed without its
# decimal point. Checked against the (synthetic) case sheets and corrected, as Lab 1 does; every later
# analysis uses the corrected data p.
p <- p_raw |>
  mutate(swapped = sbp_in_mm_hg < dbp_in_mm_hg,
         sbp = if_else(swapped, dbp_in_mm_hg, sbp_in_mm_hg),
         dbp_in_mm_hg = if_else(swapped, sbp_in_mm_hg, dbp_in_mm_hg),
         sbp_in_mm_hg = sbp,
         weight = if_else(weight < 20, weight * 10, weight),
         bmi = weight / (height / 100)^2) |>
  select(-swapped, -sbp)
col_blue <- "#3498db"; col_red <- "#e74c3c"; col_navy <- "#2c3e50"; col_green <- "#27ae60"
# p-value as text for slides: "p = 0.057", "p < 0.001"
fp <- function(x) ifelse(x < 0.001, "p < 0.001", paste("p =", formatC(x, format = "f", digits = 3)))
f  <- function(x, d = 1) formatC(x, format = "f", digits = d)
# Sample skewness (0 = symmetric; above about 1 in absolute value = clearly skewed)
skew <- function(x) { x <- x[!is.na(x)]; mean((x - mean(x))^3) / sd(x)^3 }
