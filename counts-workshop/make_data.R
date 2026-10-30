# ═══════════════════════════════════════════════════════════════
# make_data.R — synthetic dengue ward-month surveillance data for the counts workshop (no real data)
# Rscript counts-workshop/make_data.R        (repository root; seed fixed)
# Writes data/dengue_wards.csv : 30 wards x 36 months (Jan 2023 - Dec 2025) = 1080 rows.
#   cases      dengue cases notified in the ward that month      population   ward population (varies 8,000 - 60,000)
#   rain_mm    monthly rainfall      temp_c  mean temperature     fogging  1 = ward under fogging/larval control that month (from month 25, 15 wards)
#   slum       1 = informal settlement ward
# Built-in structure (checked below; the script stops if a teaching feature is lost):
#   * counts depend on POPULATION (so an offset is needed) and rise with rain (lag 1 month) and slum status
#   * strong SEASONALITY (monsoon peak) and a mild upward trend
#   * fogging lowers the rate (rate ratio about 0.7)
#   * OVERDISPERSION: variance well above the mean (Poisson dispersion > 2); negative binomial fits far better
#   * EXCESS ZEROS in a few small wards with weak reporting (zero count above the Poisson/NB expectation)
# ═══════════════════════════════════════════════════════════════
suppressMessages({ library(dplyr); library(readr); library(MASS); library(pscl) })
set.seed(2029)
nw <- 30; nm <- 36
wards <- tibble(ward = sprintf("W%02d", 1:nw), population = round(exp(rnorm(nw, log(24000), 0.55)), -2),
                slum = rbinom(nw, 1, 0.35), reporting = sample(c("good", "weak"), nw, TRUE, prob = c(.8, .2)),
                fog_ward = c(rep(1, 15), rep(0, 15))[sample(nw)], ward_eff = rnorm(nw, 0, 0.25))
wards$population <- pmin(60000, pmax(8000, wards$population))
d <- tidyr::expand_grid(wards, month_index = 1:nm) |>
  mutate(date = as.Date("2023-01-01") + round((month_index - 1) * 30.4375), year = as.integer(format(date, "%Y")), month = as.integer(format(date, "%m")))
season <- sin(2 * pi * (d$month - 4) / 12)                    # peak around July-August
d$rain_mm <- round(pmax(0, 90 + 140 * season + rnorm(nrow(d), 0, 40) + ifelse(d$month %in% 6:9, 60, 0)))
d$temp_c <- round(27 + 4 * sin(2 * pi * (d$month - 3) / 12) + rnorm(nrow(d), 0, 0.8), 1)
d <- d |> group_by(ward) |> arrange(month_index, .by_group = TRUE) |> mutate(rain_lag1 = lag(rain_mm, default = 90)) |> ungroup()
d$fogging <- as.integer(d$fog_ward == 1 & d$month_index > 24)
mu_rate <- exp(log(15 / 1e5) + 0.0035 * (d$rain_lag1 - 120) + 0.35 * d$slum + 0.012 * d$month_index + 0.9 * season - 0.36 * d$fogging + d$ward_eff)   # per person
mu <- mu_rate * d$population
d$cases <- rnbinom(nrow(d), mu = mu, size = 2.2)
d$cases[d$reporting == "weak" & runif(nrow(d)) < 0.35] <- 0L          # surveillance gaps: structural zeros
out <- d |> transmute(ward, date, year, month, month_index, population, slum, cases, rain_mm, rain_lag1, temp_c, fogging)
write_csv(out, "data/dengue_wards.csv")

# ── feature check ──
m <- read_csv("data/dengue_wards.csv", show_col_types = FALSE)
pf <- glm(cases ~ offset(log(population)) + rain_lag1 + slum + fogging + month_index + sin(2 * pi * month / 12) + cos(2 * pi * month / 12), family = poisson, data = m)
disp <- sum(residuals(pf, "pearson")^2) / pf$df.residual
nb <- glm.nb(cases ~ offset(log(population)) + rain_lag1 + slum + fogging + month_index + sin(2 * pi * month / 12) + cos(2 * pi * month / 12), data = m)
zero_obs <- mean(m$cases == 0); zero_pois <- mean(dpois(0, fitted(pf))); zero_nb <- mean(dnbinom(0, mu = fitted(nb), size = nb$theta))
cat(sprintf("rows = %d | mean cases = %.1f | var = %.0f | Poisson dispersion = %.1f | AIC Poisson %.0f vs NB %.0f | RR fogging = %.2f | RR slum = %.2f | rain RR/100mm = %.2f\n",
            nrow(m), mean(m$cases), var(m$cases), disp, AIC(pf), AIC(nb), exp(coef(nb)["fogging"]), exp(coef(nb)["slum"]), exp(100 * coef(nb)["rain_lag1"])))
cat(sprintf("zeros: observed %.1f%% | expected Poisson %.1f%% | expected NB %.1f%%\n", 100 * zero_obs, 100 * zero_pois, 100 * zero_nb))
stopifnot(nrow(m) == 1080, disp > 2, AIC(nb) < AIC(pf) - 200, exp(coef(nb)["fogging"]) < 0.85, exp(coef(nb)["fogging"]) > 0.5, exp(coef(nb)["slum"]) > 1.2, zero_obs > zero_nb + 0.015)
cat("feature check passed\n")
