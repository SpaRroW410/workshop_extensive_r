# ═══════════════════════════════════════════════════════════════
# LAB 1 — Counts, rates and the Poisson idea
# Counts and rates workshop | Session 1
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(broom); library(gtsummary); library(sandwich); library(lmtest); library(performance); library(pscl) })
theme_set(theme_minimal(base_size = 14))

dg_path <- c("data/dengue_wards.csv", "../data/dengue_wards.csv", "../../data/dengue_wards.csv")
dg_path <- dg_path[file.exists(dg_path)][1]
dg <- read_csv(dg_path, show_col_types = FALSE) |> mutate(slum = factor(slum, 0:1, c("Non-slum", "Slum")), fogging = factor(fogging, 0:1, c("No", "Yes")))
dg$ward <- factor(dg$ward)

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Look at the data: how many ward-months, and how many wards?
___(dg)
___(dg$ward)

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Total dengue cases, and the crude incidence per 100,000 PERSON-MONTHS
# (cases / sum of the ward populations over all ward-months x 100,000).
___(dg$cases)
___(dg$cases) / sum(dg$population) * ___

# Q2. Why is the denominator person-months and not the number of wards?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Mean and variance of the monthly count per ward. A Poisson count has variance = mean.
c(mean = mean(dg$cases), variance = ___)

# Q3. What does a variance 40 times the mean tell you about the Poisson assumption?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Incidence per 100,000 by ward type (slum or not): total cases / total population-months x 100,000.
dg |> ___(slum) |> ___ = sum(cases), person_months = sum(population), rate_per_100k = cases / person_months * 1e5)

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: The RATE RATIO slum vs non-slum, straight from the table above (rate of slum / rate of non-slum).
rates <- dg |> group_by(slum) |> summarise(rate = sum(cases) / sum(population))
___ / rates$rate[1]

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Plot the distribution of monthly cases as a histogram.
ggplot(dg, aes(cases)) + ___(binwidth = 2)

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: What proportion of ward-months have zero cases, and what would a Poisson with the same mean expect?
c(observed = mean(dg$cases == 0), poisson_expected = ___(0, mean(dg$cases)))

# Q7. What might explain so many zeros?

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Cases per month for the whole district: add up the cases over wards for each month, and plot against time.
dg |> group_by(date) |> ___(cases = sum(cases)) |> ggplot(aes(date, cases)) + ___()
