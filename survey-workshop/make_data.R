# ═══════════════════════════════════════════════════════════════
# make_data.R — synthetic two-stage stratified household survey for the survey data workshop (no real people)
# Rscript survey-workshop/make_data.R        (repository root; seed fixed)
# Builds a finite population of adults (8 strata = 4 regions x urban/rural, 75 PSUs per stratum), draws the survey sample the way an NFHS-type survey does
# (6 PSUs per stratum with probability proportional to size, then 40-60 adults per PSU), applies nonresponse, and writes:
#   data/survey_adults.csv      one row per SAMPLED adult (2,400): id, stratum, region, residence, psu, design_weight, responded, weight (nonresponse-adjusted, respondents only),
#                               age, sex, education, wealth (1-5), bmi, sbp, hypertension (0/1), diabetes (0/1), smoker (0/1); outcome columns are NA for non-respondents
#   data/survey_population.csv  known population (census-type) counts of adults by age group x sex and by education  (for raking in Session 4)
# Built-in structure (checked below; the script stops if a teaching feature is lost):
#   * urban strata are over-sampled (50% of the sample, about 28% of the population) and urban adults have more hypertension: the UNWEIGHTED prevalence is biased upwards
#   * clustering within PSUs gives a design effect well above 1; ignoring the design makes the standard error too small
#   * response is lower for men, young adults, urban residents and more educated adults (education unknown for non-respondents): weights must be adjusted
# ═══════════════════════════════════════════════════════════════
suppressMessages({ library(dplyr); library(tidyr); library(readr); library(survey) })
set.seed(2036)
regions <- c("North", "South", "East", "West")
strata <- expand_grid(region = regions, residence = c("Urban", "Rural")) |> mutate(stratum = paste(region, residence))
npsu_pop <- 75
psu <- strata |> slice(rep(seq_len(n()), each = npsu_pop)) |> mutate(psu_size = round(runif(n(), 150, 600)))
psu$psu <- paste0(substr(psu$region, 1, 1), ifelse(psu$residence == "Urban", "U", "R"), sprintf("%02d", rep(1:npsu_pop, nrow(strata))))
psu$u_h <- rnorm(nrow(psu), 0, 0.30); psu$u_d <- rnorm(nrow(psu), 0, 0.30)
# rural strata have more people per PSU (so 28% urban overall)
psu$psu_size <- ifelse(psu$residence == "Rural", round(psu$psu_size * 2.6), psu$psu_size)
pop <- psu |> slice(rep(seq_len(n()), psu_size))
n <- nrow(pop)
pop <- pop |> mutate(
  age = round(pmin(85, pmax(18, rnorm(n, 43, 15)))), sex = sample(c("Female", "Male"), n, TRUE),
  education = sample(c("None", "Primary", "Secondary+"), n, TRUE, prob = c(.3, .35, .35)))
pop <- pop |> mutate(education = ifelse(residence == "Urban" & runif(n) < .35 & education == "None", "Secondary+", education),
  education = ifelse(age > 55 & runif(n) < .25 & education == "Secondary+", "Primary", education),
  wealth = pmin(5, pmax(1, round(2.6 + 0.9 * (residence == "Urban") + 0.4 * (education == "Secondary+") - 0.3 * (education == "None") + rnorm(n, 0, 1.1)))),
  bmi = round(pmax(14, 21.5 + 0.045 * (age - 43) + 1.8 * (residence == "Urban") + 0.35 * (wealth - 3) + rnorm(n, 0, 3.4)), 1),
  smoker = rbinom(n, 1, plogis(-2.2 + 1.3 * (sex == "Male") - 0.4 * (education == "Secondary+"))))
pop <- pop |> mutate(
  sbp = round(125 + 0.45 * (age - 43) + 2.5 * (sex == "Male") + 0.75 * (bmi - 24) + 5 * (residence == "Urban") + 8 * u_h + rnorm(n, 0, 14)),
  hypertension = as.integer(sbp >= 140),
  diabetes = rbinom(n, 1, plogis(-2.9 + 0.035 * (age - 43) + 0.07 * (bmi - 24) + 0.55 * (residence == "Urban") + u_d)),
  age_grp = cut(age, c(17, 29, 44, 59, 120), labels = c("18-29", "30-44", "45-59", "60+")))
truth <- c(hypertension = mean(pop$hypertension), diabetes = mean(pop$diabetes), urban_share = mean(pop$residence == "Urban"))

# ── two-stage sample: 6 PSUs per stratum with probability proportional to size, then 40-60 adults per PSU ──
pop <- pop |> mutate(row = row_number())
Mh <- pop |> count(stratum, name = "Mh")
samp <- list()
for (s in strata$stratum) {
  p <- psu |> filter(stratum == s)
  chosen <- sample(p$psu, 6, prob = p$psu_size)
  for (cl in chosen) {
    mi <- sample(40:60, 1)
    idx <- pop$row[pop$psu == cl]
    samp[[length(samp) + 1]] <- pop[sample(idx, mi), ] |> mutate(n_psu_adults = mi)
  }
}
sm <- bind_rows(samp) |> left_join(Mh, by = "stratum") |>
  mutate(design_weight = (1 / (6 * psu_size / Mh)) * (psu_size / n_psu_adults))
# ── nonresponse ──
sm <- sm |> mutate(p_resp = plogis(1.7 - 0.55 * (sex == "Male") - 0.4 * (age < 30) + 0.35 * (age >= 60) - 0.35 * (residence == "Urban") - 0.45 * (education == "Secondary+")),
  responded = as.integer(runif(n()) < p_resp))
cells <- sm |> group_by(age_grp, sex, residence) |> summarise(rr = mean(responded), .groups = "drop")
sm <- sm |> left_join(cells, by = c("age_grp", "sex", "residence")) |> mutate(weight = ifelse(responded == 1, design_weight / rr, NA_real_))
sm <- sm |> mutate(id = sprintf("S%04d", row_number()),
  across(c(education, wealth, bmi, sbp, hypertension, diabetes, smoker), \(x) ifelse(responded == 1, x, NA)))
out <- sm |> mutate(design_weight = round(design_weight, 2), weight = round(weight, 2)) |> select(id, stratum, region, residence, psu, design_weight, responded, weight, age, sex, education, wealth, bmi, sbp, hypertension, diabetes, smoker)
write_csv(out, "data/survey_adults.csv")
popmargins <- bind_rows(pop |> count(variable = "age_group", level = as.character(age_grp)), pop |> count(variable = "sex", level = sex), pop |> count(variable = "education", level = education)) |> rename(adults = n)
write_csv(popmargins, "data/survey_population.csv")

# ── feature check ──
d <- read_csv("data/survey_adults.csv", show_col_types = FALSE) |> filter(responded == 1)
des <- svydesign(ids = ~psu, strata = ~stratum, weights = ~weight, data = d, nest = TRUE)
est <- svymean(~hypertension, des, deff = TRUE)
unw <- mean(d$hypertension); w <- coef(est)[[1]]; se_design <- SE(est)[[1]]; se_naive <- sqrt(unw * (1 - unw) / nrow(d))
resp_m <- mean(out$responded[out$sex == "Male"]); resp_f <- mean(out$responded[out$sex == "Female"])
cat(sprintf("sampled = %d | responded = %d (%.0f%%; men %.0f%%, women %.0f%%) | urban share: sample %.0f%%, population %.0f%%\n", nrow(out), nrow(d), 100 * mean(out$responded), 100 * resp_m, 100 * resp_f, 100 * mean(out$residence == "Urban"), 100 * truth[["urban_share"]]))
cat(sprintf("hypertension: truth %.3f | weighted %.3f (SE %.4f, deff %.2f) | unweighted %.3f (naive SE %.4f) | SE ratio %.2f\n", truth[["hypertension"]], w, se_design, deff(est)[[1]], unw, se_naive, se_design / se_naive))
cat(sprintf("diabetes: truth %.3f | weighted %.3f | unweighted %.3f | weights: min %.0f max %.0f CV %.2f\n", truth[["diabetes"]], coef(svymean(~diabetes, des))[[1]], mean(d$diabetes), min(d$weight), max(d$weight), sd(d$weight) / mean(d$weight)))
stopifnot(unw - truth[["hypertension"]] > 0.02, abs(w - truth[["hypertension"]]) < 0.02, se_design / se_naive > 1.3, deff(est)[[1]] > 1.4, deff(est)[[1]] < 4,
          mean(out$responded) > 0.70, mean(out$responded) < 0.88, resp_f - resp_m > 0.04, abs(mean(out$residence == "Urban") - 0.5) < 0.01, truth[["urban_share"]] < 0.35)
cat("feature check passed\n")
