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
mean(dnbinom(0, mu = fitted(m_nb), size = m_nb$theta))              #@ dnbinom || theta
mean(dg$cases == 0)
#% A (Q1): the model expects about 19% zeros; 20% are observed: a small excess.

# Q1. Is the excess of zeros large here? What would worry you more?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Zero counts per ward: which wards have many zero months?
dg |> group_by(ward) |> summarise(zero_months = sum(cases == 0)) |> arrange(desc(zero_months)) |> head(6)   #@ arrange || desc
#% A (Q2): a few wards (W14, W02, W04, W23) have 18 to 24 zero months of 36: weak surveillance (structural zeros), not true absence of dengue.

# Q2. Why might a ward report zero dengue cases for many months?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Fit a zero-inflated negative binomial model: the count part and a zero-inflation part (just an intercept).
m_zinb <- zeroinfl(cases ~ fogging + slum + rain_lag1 + month_index + sin(2 * pi * month / 12) + cos(2 * pi * month / 12) + offset(log(population)) | 1, data = dg, dist = "negbin")   #@ zeroinfl || negbin
round(plogis(coef(m_zinb, "zero")), 3)
#% A: about 0.06: roughly 6% of ward-months are "structural" zeros.

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Compare the negative binomial and the zero-inflated negative binomial by AIC.
AIC(m_nb, m_zinb)                                                   #@ m_zinb
#% A (Q4): the zero-inflated model is better (AIC about 5,871 vs 5,898) but the gain is modest; first look for a covariate that explains the zeros (a reporting-quality indicator) before adding a mixture.

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Plot observed monthly district totals against the totals predicted by the negative binomial model.
dg |> mutate(pred = fitted(m_nb)) |>   #@ fitted
  group_by(date) |> summarise(observed = sum(cases), predicted = sum(pred)) |>
  pivot_longer(c(observed, predicted)) |> ggplot(aes(date, value, colour = name)) + geom_line()   #@ pivot_longer
#% A (Q5): the model follows the seasonal pattern well.

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Check for leftover correlation in time: the autocorrelation of the Pearson residuals of ONE ward over months.
w1 <- dg$ward == levels(dg$ward)[1]
acf(residuals(m_nb, type = "pearson")[w1], plot = FALSE)$acf[2]     #@ acf
#% A (Q6): about 0.13 at lag 1: modest positive autocorrelation. Consecutive months are not independent, so standard errors are somewhat optimistic; robust (clustered) SEs, random effects or time-series terms would handle this.

# Q6. Why does autocorrelation matter, and what could you do about it?
