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
adults |> group_by(sex) |> summarise(n = n(), response_rate = mean(responded))   #@ summarise
adults |> group_by(age_grp) |> summarise(n = n(), response_rate = mean(responded))
#% A (Q1): men respond less (about 69%) than women (about 79%); the youngest adults respond least.

# Q1. What bias can result if nonresponse is ignored?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: The nonresponse ADJUSTMENT: divide the design weight by the response rate in cells of age group x sex x residence. Compare with the weight in the file.
cells <- adults |> group_by(age_grp, sex, residence) |> summarise(rr = mean(responded), .groups = "drop")
adj <- adults |> filter(responded == 1) |> left_join(cells, by = c("age_grp", "sex", "residence")) |> mutate(w_new = design_weight / rr)   #@ design_weight
all.equal(adj$w_new, adj$weight, tolerance = 0.001)
#% A (Q2): TRUE (to rounding): the weight in the file is the design weight adjusted for nonresponse.

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Weight diagnostics: the coefficient of variation of the weights and Kish effective sample size, (sum w)^2 / sum(w^2).
w <- weights(des)
c(cv = sd(w) / mean(w), n_eff = sum(w)^2 / sum(w^2))                #@ sum(w)^2
#% A (Q3): CV about 0.43; the Kish n_eff is about 1,560 of 1,853 respondents, so unequal weights cost about 16% of the sample.

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Compare the education distribution in the weighted sample with the known population (census) distribution.
pop <- read_csv(c("data/survey_population.csv", "../data/survey_population.csv", "../../data/survey_population.csv")[file.exists(c("data/survey_population.csv", "../data/survey_population.csv", "../../data/survey_population.csv"))][1], show_col_types = FALSE)
pop_edu <- pop |> filter(variable == "education")
rbind(sample = prop.table(svytable(~education, des)), population = setNames(pop_edu$adults / sum(pop_edu$adults), pop_edu$level)[levels(resp$education)]) |> round(3)   #@ svytable
#% A (Q4): close but not equal: 28.6% / 36.4% / 35.0% in the weighted sample against 27.2% / 36.9% / 36.0% in the population (slightly too many with no education, because the more educated respond less).

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: RAKE (iterative proportional fitting) the weights to the population margins of age group, sex and education.
pop_age <- pop |> filter(variable == "age_group") |> transmute(age_grp = level, Freq = adults)
pop_sex <- pop |> filter(variable == "sex") |> transmute(sex = level, Freq = adults)
pop_edu <- pop |> filter(variable == "education") |> transmute(education = level, Freq = adults)
des_r <- rake(des, list(~age_grp, ~sex, ~education), list(pop_age, pop_sex, pop_edu))   #@ rake
round(rbind(before = coef(svymean(~hypertension, des)), after = coef(svymean(~hypertension, des_r))), 4)
#% A (Q5): the prevalence changes little (about 0.1995 to 0.1974), but the weights now reproduce the population margins exactly.

# Q5. When is raking worth the extra complexity?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Check that the raked weights reproduce the population age distribution.
round(prop.table(svytable(~age_grp, des_r)), 3)                     #@ des_r
#% A: 0.183, 0.355, 0.326, 0.136, the population shares.

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: TRIM extreme weights to at most 1.5 times the median to limit variance (then compare the effective sample size).
des_t <- trimWeights(des_r, upper = 1.5 * median(weights(des_r)), strict = TRUE)   #@ trimWeights
c(before = sum(weights(des_r))^2 / sum(weights(des_r)^2), after = sum(weights(des_t))^2 / sum(weights(des_t)^2))
#% A: the effective sample size rises a little; trimming trades a little bias for less variance.

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Replicate weights: convert the design to a bootstrap replicate design and compare the SE of the prevalence.
set.seed(1)
rep_des <- as.svrepdesign(des, type = "bootstrap", replicates = 200)   #@ as.svrepdesign
c(taylor = SE(svymean(~hypertension, des)), bootstrap = SE(svymean(~hypertension, rep_des)))
#% A (Q8): similar SEs (about 0.0149 Taylor against 0.015 for the bootstrap): replicate weights are another way to get the variance, needed when data providers release replicate weights.
