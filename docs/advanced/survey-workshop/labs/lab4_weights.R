# ═══════════════════════════════════════════════════════════════
# LAB 4 — Nonresponse, post-stratification and replicate weights
# Survey data and weights workshop | Session 4
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
# Goal: Response rate by sex and by age group among ALL sampled adults.
adults <- adults |> mutate(age_grp = cut(age, c(17, 29, 44, 59, 120), labels = c("18-29", "30-44", "45-59", "60+")))
adults |> group_by(sex) |> ___(n = n(), response_rate = mean(responded))
adults |> group_by(age_grp) |> summarise(n = n(), response_rate = mean(responded))

# Q1. What bias can result if nonresponse is ignored?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: The nonresponse ADJUSTMENT: divide the design weight by the response rate in cells of age group x sex x residence. Compare with the weight in the file.
cells <- adults |> group_by(age_grp, sex, residence) |> summarise(rr = mean(responded), .groups = "drop")
adj <- adults |> filter(responded == 1) |> left_join(cells, by = c("age_grp", "sex", "residence")) |> mutate(w_new = ___ / rr)
all.equal(adj$w_new, adj$weight, tolerance = 0.001)

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Weight diagnostics: the coefficient of variation of the weights and Kish effective sample size, (sum w)^2 / sum(w^2).
w <- weights(des)
c(cv = sd(w) / mean(w), n_eff = ___ / sum(w^2))

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Compare the education distribution in the weighted sample with the known population (census) distribution.
pop <- read_csv(c("data/survey_population.csv", "../data/survey_population.csv", "../../data/survey_population.csv")[file.exists(c("data/survey_population.csv", "../data/survey_population.csv", "../../data/survey_population.csv"))][1], show_col_types = FALSE)
pop_edu <- pop |> filter(variable == "education")
rbind(sample = prop.table(___(~education, des)), population = setNames(pop_edu$adults / sum(pop_edu$adults), pop_edu$level)[levels(resp$education)]) |> round(3)

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: RAKE (iterative proportional fitting) the weights to the population margins of age group, sex and education.
pop_age <- pop |> filter(variable == "age_group") |> transmute(age_grp = level, Freq = adults)
pop_sex <- pop |> filter(variable == "sex") |> transmute(sex = level, Freq = adults)
pop_edu <- pop |> filter(variable == "education") |> transmute(education = level, Freq = adults)
des_r <- ___(des, list(~age_grp, ~sex, ~education), list(pop_age, pop_sex, pop_edu))
round(rbind(before = coef(svymean(~hypertension, des)), after = coef(svymean(~hypertension, des_r))), 4)

# Q5. When is raking worth the extra complexity?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Check that the raked weights reproduce the population age distribution.
round(prop.table(svytable(~age_grp, ___)), 3)

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: TRIM extreme weights to at most 1.5 times the median to limit variance (then compare the effective sample size).
des_t <- ___(des_r, upper = 1.5 * median(weights(des_r)), strict = TRUE)
c(before = sum(weights(des_r))^2 / sum(weights(des_r)^2), after = sum(weights(des_t))^2 / sum(weights(des_t)^2))

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Replicate weights: convert the design to a bootstrap replicate design and compare the SE of the prevalence.
set.seed(1)
rep_des <- ___(des, type = "bootstrap", replicates = 200)
c(taylor = SE(svymean(~hypertension, des)), bootstrap = SE(svymean(~hypertension, rep_des)))
