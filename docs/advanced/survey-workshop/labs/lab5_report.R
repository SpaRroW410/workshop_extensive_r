# ═══════════════════════════════════════════════════════════════
# LAB 5 — Choosing, checking and reporting
# Survey data and weights workshop | Session 5
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
# Goal: A table of the prevalence of hypertension and its SE under three analyses: unweighted/naive, weighted only (ignoring clusters), and the full design.
p0 <- mean(resp$hypertension)
des_w <- svydesign(ids = ___, weights = ~weight, data = resp)
tab <- tibble(analysis = c("naive (no design)", "weights only", "full design"),
  estimate = c(p0, coef(svymean(~hypertension, des_w))[[1]], coef(svymean(~hypertension, des))[[1]]),
  se = c(sqrt(p0 * (1 - p0) / nrow(resp)), SE(svymean(~hypertension, des_w))[[1]], SE(svymean(~hypertension, des))[[1]]))
tab |> mutate(across(where(is.numeric), \(x) round(x, 4)))

# Q1. Which of the three is correct for a national report, and why?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Design effects for several outcomes.
sapply(c("hypertension", "diabetes", "smoker"), function(v) ___(svymean(as.formula(paste0("~", v)), des, deff = TRUE))[[1]])

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Sample size planning. A simple random sample needs 1,000 respondents for the precision wanted. With a design effect of 2.2, how many respondents does this survey need?
1000 * ___

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: The effective sample size of the survey for hypertension: n / design effect.
___(resp) / deff(svymean(~hypertension, des, deff = TRUE))[[1]]

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Why subset() and not filter()? Count the PSUs per stratum among adults younger than 45 who have diabetes (a small group), and note the strata with fewer than two PSUs.
resp |> filter(diabetes == 1, age < 45) |> ___(stratum, psu) |> count(stratum)

# Q5. What does options(survey.lonely.psu = "adjust") do, and what should you do about lonely PSUs?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: A reporting table: the weighted prevalence of hypertension, with 95% CI, by region, plus the unweighted number of respondents.
resp |> as_survey_design(ids = psu, strata = stratum, weights = weight, nest = TRUE) |> group_by(region) |>
  summarise(n = ___(n()), prevalence = survey_mean(hypertension, vartype = "ci"))

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: A one-sentence result with the right ingredients.
est <- svyciprop(~I(hypertension == 1), des, method = "logit")
cat(sprintf("Weighted prevalence of hypertension was %.1f%% (95%% CI %.1f to %.1f; design effect 2.6; %d respondents in 48 PSUs).\n",
            100 * coef(est), 100 * ___(est)[1], 100 * confint(est)[2], nrow(resp)))
