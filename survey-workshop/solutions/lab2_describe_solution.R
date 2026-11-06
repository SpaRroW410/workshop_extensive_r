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
confint(m)                                                          #@ confint
#% A (Q1): mean SBP about 125.7 mmHg (95% CI 124.6 to 126.9).

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Prevalence of hypertension with a logit-transformed CI (better for proportions).
svyciprop(~I(hypertension == 1), des, method = "logit")             #@ svyciprop || logit
#% A (Q2): about 20.0% with a 95% CI of about 17.1% to 23.1%.

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Estimated TOTAL number of adults with hypertension in the population.
svytotal(~hypertension, des)                                        #@ svytotal
#% A (Q3): about 82,700 adults (SE about 6,000).

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Prevalence of hypertension by residence (urban/rural), with standard errors.
svyby(~hypertension, ~residence, des, svymean)                      #@ svyby
#% A (Q4): about 0.30 in urban and 0.16 in rural adults.

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Prevalence by region with confidence intervals (use the vartype option).
svyby(~hypertension, ~region, des, svymean, vartype = c("se", "ci"))   #@ vartype
#% A: prevalence is about 0.19 in three regions and 0.23 in the South; the CIs are wide (about +/- 0.07) because there are only 12 PSUs per region.

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: The median and quartiles of SBP.
svyquantile(~sbp, des, quantiles = c(0.25, 0.5, 0.75))              #@ svyquantile
#% A: median about 126 mmHg (quartiles 115 and 137).

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: The design effect for the prevalence: how much larger is the variance than under simple random sampling?
svymean(~hypertension, des, deff = TRUE)                            #@ deff
#% A (Q7): about 2.6: the design (clusters and unequal weights) multiplies the variance by 2.6.

# Q7. What does DEFF = 2.6 mean for the effective sample size?

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: A SUBPOPULATION analysis: hypertension among women aged 30 or older. Use subset() on the DESIGN, not filter() on the data.
des_w30 <- subset(des, sex == "Female" & age >= 30)                 #@ subset
svymean(~hypertension, des_w30)
#% A (Q8): about 0.22 among women aged 30 or over.

# Q8. Why is subset() on the design better than filtering the data and declaring the design again?

# ── Task 9 ──────────────────────────────────────────────────────
# Goal: A weighted cross-table of hypertension by education, with a design-based test of independence (Rao-Scott).
svytable(~education + hypertension, des)
svychisq(~education + hypertension, des)                            #@ svychisq
#% A (Q9): about 21% (none) and 22% (primary) against 17% (secondary or more); the Rao-Scott test is borderline (p about 0.05).

# ── Task 10 ─────────────────────────────────────────────────────
# Goal: The same prevalence by residence with srvyr (tidy syntax).
resp |> as_survey_design(ids = psu, strata = stratum, weights = weight, nest = TRUE) |> group_by(residence) |>
  summarise(prev = survey_mean(hypertension, vartype = "ci"))       #@ survey_mean
