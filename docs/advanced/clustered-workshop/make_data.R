# ═══════════════════════════════════════════════════════════════
# make_data.R — synthetic cluster-randomised BP trial for the clustered and repeated data workshop (no real people)
# Rscript clustered-workshop/make_data.R        (repository root; seed fixed)
# Writes data/bp_trial.csv : 40 villages x 20 adults x 4 visits (baseline, 3, 6, 12 months) = 3,200 planned rows (some visits missing).
#   village      cluster (randomised, 20 villages "Programme" = salt-reduction + screening, 20 "Control")
#   person       adult id (nested in village), visit months 0/3/6/12, sbp, controlled (SBP < 140), plus age, sex, bmi, village_size
# Built-in structure (checked below; the script stops if a teaching feature is lost):
#   * villages cluster: ICC of baseline SBP about 0.08  (design effect about 2.5 with 20 per village)
#   * the same person is correlated over visits (random intercept; weak random slope)
#   * the programme lowers SBP over time (about -5 mmHg at 12 months): a time x arm interaction
#   * ~15% of visits are missing, more often for older adults and those with higher earlier SBP (missing at random, not completely)
#   * ignoring clustering gives a standard error for the programme effect far too small
# ═══════════════════════════════════════════════════════════════
suppressMessages({ library(dplyr); library(tidyr); library(readr); library(lme4) })
set.seed(2035)
nv <- 40; np <- 20
vill <- tibble(village = sprintf("V%02d", 1:nv), arm = sample(rep(c("Control", "Programme"), each = nv / 2)), v_eff = rnorm(nv, 0, 4.2), village_size = round(runif(nv, 400, 2500), -1))
people <- vill |> slice(rep(seq_len(nv), each = np)) |> mutate(person = sprintf("%s-P%02d", village, rep(seq_len(np), nv)),
  age = round(pmin(80, pmax(25, rnorm(n(), 48, 11)))), sex = sample(c("Female", "Male"), n(), TRUE), bmi = round(pmax(15, rnorm(n(), 25, 4)), 1),
  p_eff = rnorm(n(), 0, 11), p_slope = rnorm(n(), 0, 0.25))
d <- people |> slice(rep(seq_len(n()), each = 4)) |> mutate(months = rep(c(0, 3, 6, 12), n() / 4))
trend <- ifelse(d$arm == "Programme", -0.45 * d$months, -0.05 * d$months)        # mmHg per month (programme about -5.4 at 12 months vs control -0.6)
d$sbp <- round(128 + 0.30 * (d$age - 48) + 3.0 * (d$sex == "Male") + 0.6 * (d$bmi - 25) + d$v_eff + d$p_eff + trend + d$p_slope * d$months + rnorm(nrow(d), 0, 8.5))
# missing visits: dropout depends on age and on the previous (observed) SBP, not on the current one -> MAR
d <- d |> group_by(person) |> mutate(prev = lag(sbp)) |> ungroup()
pmiss <- plogis(-1.9 + 0.035 * (d$age - 48) + 0.03 * pmax(0, d$prev - 130, na.rm = TRUE) * (d$months > 0)) * (d$months > 0)
d$missing <- runif(nrow(d)) < pmiss
d <- d |> filter(!missing | months == 0) |> select(village, arm, village_size, person, age, sex, bmi, months, sbp)
d$controlled <- as.integer(d$sbp < 140)
write_csv(d, "data/bp_trial.csv")

# ── feature check ──
m <- read_csv("data/bp_trial.csv", show_col_types = FALSE) |> mutate(arm = factor(arm, levels = c("Control", "Programme")))
b <- m |> filter(months == 0)
icc0 <- as.data.frame(VarCorr(lmer(sbp ~ 1 + (1 | village), b)))$vcov; icc0 <- icc0[1] / sum(icc0)
fit <- lmer(sbp ~ months * arm + age + sex + bmi + (1 | village / person), m, REML = TRUE)
vc <- as.data.frame(VarCorr(fit)); fe <- fixef(fit)
naive <- summary(lm(sbp ~ months * arm + age + sex + bmi, m))$coefficients["months:armProgramme", ]
miss_rate <- 1 - nrow(m) / (nv * np * 4)
m12 <- m |> filter(months == 12)
se_naive12 <- summary(lm(sbp ~ arm + age + sex + bmi, m12))$coefficients["armProgramme", 2]
f12 <- lmer(sbp ~ arm + age + sex + bmi + (1 | village), m12); se_mixed12 <- summary(f12)$coefficients["armProgramme", 2]
eff12 <- fixef(f12)["armProgramme"]
cat(sprintf("rows = %d (%.0f%% of visits missing) | baseline ICC = %.3f | design effect = %.2f | months x arm = %.2f (SE %.3f) vs naive lm SE %.3f\n",
            nrow(m), 100 * miss_rate, icc0, 1 + (np - 1) * icc0, fe["months:armProgramme"], summary(fit)$coefficients["months:armProgramme", 2], naive[2]))
cat(sprintf("12-month arm effect = %.2f | naive SE %.2f vs mixed-model SE %.2f (ratio %.2f)\n", eff12, se_naive12, se_mixed12, se_mixed12 / se_naive12))
stopifnot(se_mixed12 > 1.3 * se_naive12, eff12 < -2, icc0 > 0.05, icc0 < 0.14, fe["months:armProgramme"] < -0.25, fe["months:armProgramme"] > -0.6, miss_rate > 0.08, miss_rate < 0.25, nrow(m) > 2400)
cat("feature check passed\n")
