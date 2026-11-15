# ═══════════════════════════════════════════════════════════════
# LAB 2 — Descriptive estimates with svy functions
# Survey data and weights workshop | Session 2
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(survey); library(srvyr) })
theme_set(theme_minimal(base_size = 14))
options(survey.lonely.psu = "adjust")      # one-PSU strata (e.g. in subgroups) are handled instead of stopping

p <- c("data/survey_adults.csv", "../data/survey_adults.csv", "../../data/survey_adults.csv"); p <- p[file.exists(p)][1]
adults <- read_csv(p, show_col_types = FALSE)
resp <- adults |> filter(responded == 1) |> mutate(across(c(region, residence, sex), factor), education = factor(education, levels = c("None", "Primary", "Secondary+")),
  age_grp = cut(age, c(17, 29, 44, 59, 120), labels = c("18-29", "30-44", "45-59", "60+")))
des <- svydesign(ids = ~psu, strata = ~stratum, weights = ~weight, data = resp, nest = TRUE)

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Mean systolic blood pressure with a 95% confidence interval.
m <- svymean(~sbp, des)
___(m)

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Prevalence of hypertension with a logit-transformed CI (better for proportions).
___(~I(hypertension == 1), des, method = "___")

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Estimated TOTAL number of adults with hypertension in the population.
___(~hypertension, des)

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Prevalence of hypertension by residence (urban/rural), with standard errors.
___(~hypertension, ~residence, des, svymean)

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Prevalence by region with confidence intervals (use the vartype option).
svyby(~hypertension, ~region, des, svymean, ___ = c("se", "ci"))

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: The median and quartiles of SBP.
___(~sbp, des, quantiles = c(0.25, 0.5, 0.75))

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: The design effect for the prevalence: how much larger is the variance than under simple random sampling?
svymean(~hypertension, des, ___ = TRUE)

# Q7. What does DEFF = 2.6 mean for the effective sample size?

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: A SUBPOPULATION analysis: hypertension among women aged 30 or older. Use subset() on the DESIGN, not filter() on the data.
des_w30 <- ___(des, sex == "Female" & age >= 30)
svymean(~hypertension, des_w30)

# Q8. Why is subset() on the design better than filtering the data and declaring the design again?

# ── Task 9 ──────────────────────────────────────────────────────
# Goal: A weighted cross-table of hypertension by education, with a design-based test of independence (Rao-Scott).
svytable(~education + hypertension, des)
___(~education + hypertension, des)

# ── Task 10 ─────────────────────────────────────────────────────
# Goal: The same prevalence by residence with srvyr (tidy syntax).
resp |> as_survey_design(ids = psu, strata = stratum, weights = weight, nest = TRUE) |> group_by(residence) |>
  summarise(prev = ___(hypertension, vartype = "ci"))
