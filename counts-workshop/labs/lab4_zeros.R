# ═══════════════════════════════════════════════════════════════
# LAB 4 — Excess zeros and checking the model
# Counts and rates workshop | Session 4
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(broom); library(gtsummary); library(sandwich); library(lmtest); library(performance); library(pscl) })
theme_set(theme_minimal(base_size = 14))

dg_path <- c("data/dengue_wards.csv", "../data/dengue_wards.csv", "../../data/dengue_wards.csv")
dg_path <- dg_path[file.exists(dg_path)][1]
dg <- read_csv(dg_path, show_col_types = FALSE) |> mutate(slum = factor(slum, 0:1, c("Non-slum", "Slum")), fogging = factor(fogging, 0:1, c("No", "Yes")))
dg$ward <- factor(dg$ward)

f <- cases ~ fogging + slum + rain_lag1 + month_index + sin(2 * pi * month / 12) + cos(2 * pi * month / 12) + offset(log(population))
m_nb <- MASS::glm.nb(f, data = dg)

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: How many zeros does the negative binomial model expect? Use its fitted means and theta.
mean(___(0, mu = fitted(m_nb), size = m_nb$___))
mean(dg$cases == 0)

# Q1. Is the excess of zeros large here? What would worry you more?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Zero counts per ward: which wards have many zero months?
dg |> group_by(ward) |> summarise(zero_months = sum(cases == 0)) |> ___(___(zero_months)) |> head(6)

# Q2. Why might a ward report zero dengue cases for many months?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Fit a zero-inflated negative binomial model: the count part and a zero-inflation part (just an intercept).
m_zinb <- ___(cases ~ fogging + slum + rain_lag1 + month_index + sin(2 * pi * month / 12) + cos(2 * pi * month / 12) + offset(log(population)) | 1, data = dg, dist = "___")
round(plogis(coef(m_zinb, "zero")), 3)

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Compare the negative binomial and the zero-inflated negative binomial by AIC.
AIC(m_nb, ___)

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Plot observed monthly district totals against the totals predicted by the negative binomial model.
dg |> mutate(pred = ___(m_nb)) |>
  group_by(date) |> summarise(observed = sum(cases), predicted = sum(pred)) |>
  ___(c(observed, predicted)) |> ggplot(aes(date, value, colour = name)) + geom_line()

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Check for leftover correlation in time: the autocorrelation of the Pearson residuals of ONE ward over months.
w1 <- dg$ward == levels(dg$ward)[1]
___(residuals(m_nb, type = "pearson")[w1], plot = FALSE)$acf[2]

# Q6. Why does autocorrelation matter, and what could you do about it?
