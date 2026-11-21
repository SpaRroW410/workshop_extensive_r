# ═══════════════════════════════════════════════════════════════
# MODERATE LAB 1 — Cleaning messy data
# Medical Statistics in R · Moderate track · goes with: Cleaning Messy Data
# Replace every ___ with the missing code. Hints describe the GOAL, not the answer.
# Save this file next to a folder called data/ that holds the dataset(s) named below
# (download them from the track home), or open the workshop RStudio project.
# ═══════════════════════════════════════════════════════════════

suppressPackageStartupMessages({library(dplyr); library(readr); library(janitor); library(stringr)})
p <- c("data/ncd_messy.csv", "../data/ncd_messy.csv", "../../data/ncd_messy.csv"); p <- p[file.exists(p)][1]
raw <- read_csv(p, show_col_types = FALSE)

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Make the column names lower case with underscores (no spaces or brackets).
d <- raw |> ___()
names(d)

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Look at every spelling of sex, then recode them to "Male" and "Female".
count(d, sex)
d <- d |> mutate(sex = case_when(str_to_lower(sex) %in% c("m", "male") ~ "Male",
                                 ___(sex) %in% c("f", "female") ~ "Female"))
count(d, sex)

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Turn age and salt into numbers; the salt values carry a unit ("7.2 g").
d <- d |> mutate(age = ___(age_yrs), salt_g = parse_number(salt_g_day))
summary(d$salt_g)

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: 999 means "age unknown". Set it to missing, then count the missing ages.
d <- d |> mutate(age = ___(age, ___))
sum(is.na(d$age))

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Remove rows that are exact copies of another row, and compare the row counts.
nrow(d); d <- ___(d); nrow(d)

# Q1. Why set impossible values to NA rather than delete the row?
