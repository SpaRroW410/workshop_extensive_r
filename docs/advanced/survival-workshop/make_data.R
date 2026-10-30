# ═══════════════════════════════════════════════════════════════
# make_data.R — synthetic DOTS tuberculosis cohort for the survival workshop (no real patients)
# Rscript survival-workshop/make_data.R        (repository root; seed fixed)
# Writes data/tb_cohort.csv : 600 adults starting TB treatment, followed up to 24 months.
#   time_months  follow-up time to death or censoring        status  1 = died, 0 = censored
#   censor_reason  "Alive at end of follow-up" / "Lost to follow-up" (censored rows only)
# Built-in structure (checked below; the script stops if a teaching feature is lost):
#   * about a quarter die, the rest are censored (administrative end or lost to follow-up)
#   * HIV, MDR-TB, diabetes, age raise the hazard; DOT (supervised treatment) and BMI lower it; sex has NO effect
#   * smear-positive disease raises the hazard strongly in the first 6 months and not afterwards (proportional hazards is VIOLATED for smear)
#   * overall median survival is NOT reached within follow-up (so KM median = NA is a teaching point)
# ═══════════════════════════════════════════════════════════════
suppressMessages({ library(dplyr); library(readr); library(survival) })
set.seed(2028)
n <- 600
age <- round(pmin(85, pmax(15, rnorm(n, 42, 14))))
sex <- sample(c("Male", "Female"), n, TRUE, prob = c(.6, .4))
hiv <- rbinom(n, 1, plogis(-2.2 - 0.03 * (age - 42)))
diabetes <- rbinom(n, 1, plogis(-3.2 + 0.04 * (age - 42)))
smoker <- rbinom(n, 1, ifelse(sex == "Male", .45, .12))
bmi <- round(pmax(13, rnorm(n, 19.8 - 1.0 * hiv, 3)), 1)
mdr <- rbinom(n, 1, 0.10)
smear <- rbinom(n, 1, 0.55)
dot <- rbinom(n, 1, 0.65)
lp <- 0.025 * (age - 42) + 0.75 * hiv + 0.45 * diabetes + 0.25 * smoker - 0.10 * (bmi - 19.8) + 0.9 * mdr - 0.65 * dot
h0 <- 0.0085
r1 <- h0 * exp(lp) * ifelse(smear == 1, 4, 1)      # first 6 months: smear-positive hazard x4
r2 <- h0 * exp(lp) * ifelse(smear == 1, 0.7, 1)    # after month 6: smear-positive hazard x0.7 (the effect reverses: non-proportional)
t1 <- rexp(n, r1); t_event <- ifelse(t1 < 6, t1, 6 + rexp(n, r2))
admin <- runif(n, 14, 24)                            # staggered enrolment: administrative censoring at 14-24 months
ltfu <- rexp(n, 0.012)                               # loss to follow-up
time <- pmin(t_event, admin, ltfu)
status <- as.integer(t_event <= pmin(admin, ltfu))
cens_reason <- ifelse(status == 1, NA, ifelse(ltfu < admin, "Lost to follow-up", "Alive at end of follow-up"))
d <- tibble(id = sprintf("TB%03d", 1:n), age = age, sex = sex, hiv = c("Negative", "Positive")[hiv + 1],
            diabetes = c("No", "Yes")[diabetes + 1], smoker = c("No", "Yes")[smoker + 1], bmi = bmi,
            mdr_tb = c("No", "Yes")[mdr + 1], smear = c("Negative", "Positive")[smear + 1],
            treatment = c("Self-administered", "DOT")[dot + 1], time_months = round(pmax(0.1, time), 1), status = status, censor_reason = cens_reason)
write_csv(d, "data/tb_cohort.csv")

# ── feature check ──
m <- read_csv("data/tb_cohort.csv", show_col_types = FALSE) |> mutate(across(c(sex, hiv, diabetes, smoker, mdr_tb, smear, treatment), factor))
m$hiv <- relevel(m$hiv, "Negative"); m$treatment <- relevel(m$treatment, "Self-administered")
ev <- sum(m$status); cp <- coef(coxph(Surv(time_months, status) ~ age + sex + hiv + diabetes + smoker + bmi + mdr_tb + smear + treatment, m))
zph <- cox.zph(coxph(Surv(time_months, status) ~ age + sex + hiv + diabetes + smoker + bmi + mdr_tb + smear + treatment, m))$table
sf <- survfit(Surv(time_months, status) ~ 1, m); lr_sex <- survdiff(Surv(time_months, status) ~ sex, m)
cat(sprintf("n = %d | deaths = %d (%.0f%%) | lost to follow-up = %d | median survival = %s\n", nrow(m), ev, 100 * ev / nrow(m), sum(m$censor_reason == "Lost to follow-up", na.rm = TRUE), format(summary(sf)$table["median"])))
cat(sprintf("HR hiv %.2f | mdr %.2f | diabetes %.2f | DOT %.2f | age/yr %.3f | smear %.2f | zph smear p = %.3f | log-rank sex p = %.2f\n",
            exp(cp["hivPositive"]), exp(cp["mdr_tbYes"]), exp(cp["diabetesYes"]), exp(cp["treatmentDOT"]), exp(cp["age"]), exp(cp["smearPositive"]), zph["smear", "p"], 1 - pchisq(lr_sex$chisq, 1)))
stopifnot(ev >= 110, ev <= 200, ev / nrow(m) < .35, is.na(summary(sf)$table["median"]), exp(cp["hivPositive"]) > 1.4, exp(cp["mdr_tbYes"]) > 1.6, exp(cp["treatmentDOT"]) < 0.8,
          zph["smear", "p"] < 0.05, 1 - pchisq(lr_sex$chisq, 1) > 0.1, sum(m$censor_reason == "Lost to follow-up", na.rm = TRUE) >= 40)
cat("feature check passed\n")
