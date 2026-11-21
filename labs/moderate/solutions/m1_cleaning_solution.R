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
d <- raw |> clean_names()                                          #@ clean_names
names(d)

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Look at every spelling of sex, then recode them to "Male" and "Female".
count(d, sex)
d <- d |> mutate(sex = case_when(str_to_lower(sex) %in% c("m", "male") ~ "Male",
                                 str_to_lower(sex) %in% c("f", "female") ~ "Female"))   #@ str_to_lower
count(d, sex)
#% A: Female 151, Male 162 and no NA: every spelling was matched

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Turn age and salt into numbers; the salt values carry a unit ("7.2 g").
d <- d |> mutate(age = parse_number(age_yrs), salt_g = parse_number(salt_g_day))   #@ parse_number
summary(d$salt_g)

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: 999 means "age unknown". Set it to missing, then count the missing ages.
d <- d |> mutate(age = na_if(age, 999))                            #@ na_if || 999
sum(is.na(d$age))
#% A: 7 missing ages (3 "unknown" texts + 4 codes of 999); report them in the cleaning log

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Remove rows that are exact copies of another row, and compare the row counts.
nrow(d); d <- distinct(d); nrow(d)                                 #@ distinct
#% A: 313 -> 303 rows; repeated IDs with different values stay for checking

# Q1. Why set impossible values to NA rather than delete the row?
#% A: the other columns of that person are still valid; deleting the row biases the sample.
