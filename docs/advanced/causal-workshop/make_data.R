# ═══════════════════════════════════════════════════════════════
# make_data.R — synthetic observational programme evaluation for the causal inference workshop (no real people)
# Rscript causal-workshop/make_data.R        (repository root; seed fixed)
# Writes data/htn_programme.csv : 3,000 adults with hypertension from 12 months of routine clinic records
#   id, age, sex, education (None/Primary/Secondary+), urban (0/1), bmi, diabetes (0/1), baseline_sbp,
#   programme (0/1: enrolled in a community health-worker hypertension programme; NOT randomised),
#   adherent (0/1: takes medication regularly at 6 months; a MEDIATOR), clinic_visits (visits in the year; a COLLIDER), sbp_12m, controlled (sbp_12m < 140)
# Both potential outcomes are simulated, so the TRUE effects are known (printed below, facilitator only):
#   * enrolment is more likely for older adults, those with diabetes, a higher baseline SBP, more education and urban residence: CONFOUNDING
#   * the naive difference in 12-month SBP is close to zero or positive, although the programme truly lowers SBP by about 6 mmHg
#   * about half of the effect goes through adherence: adjusting for the mediator gives the direct effect only
#   * clinic visits are caused by the programme AND by poor BP: adjusting for this collider biases the estimate
#   * the effect is larger for a higher baseline SBP, so the effect in the treated (ATT) is larger than the average effect (ATE)
#   * an unmeasured factor ("motivation") has a small influence on enrolment and outcome: a residual bias for the sensitivity analysis
# ═══════════════════════════════════════════════════════════════
suppressMessages({ library(dplyr); library(readr) })
set.seed(2040)
n <- 3000
age <- round(pmin(85, pmax(30, rnorm(n, 55, 11))))
sex <- sample(c("Female", "Male"), n, TRUE)
education <- sample(c("None", "Primary", "Secondary+"), n, TRUE, prob = c(.35, .35, .30))
urban <- rbinom(n, 1, 0.4)
bmi <- round(pmax(16, rnorm(n, 26 + 0.8 * urban, 4.2)), 1)
diabetes <- rbinom(n, 1, plogis(-1.6 + 0.03 * (age - 55) + 0.08 * (bmi - 26)))
motivation <- rnorm(n)                                             # unmeasured
baseline_sbp <- round(152 + 0.35 * (age - 55) + 0.5 * (bmi - 26) + 4 * diabetes + rnorm(n, 0, 11))
programme <- rbinom(n, 1, plogis(-0.9 + 0.03 * (age - 55) + 0.6 * diabetes + 0.045 * (baseline_sbp - 152) + 0.5 * (education == "Secondary+") + 0.5 * urban + 0.25 * motivation))
# mediator: adherence (under no programme and under programme)
p_adh0 <- plogis(-0.6 + 0.4 * (education == "Secondary+") + 0.3 * motivation); p_adh1 <- plogis(-0.6 + 1.3 + 0.4 * (education == "Secondary+") + 0.3 * motivation)
u_a <- runif(n); adh0 <- as.integer(u_a < p_adh0); adh1 <- as.integer(u_a < p_adh1)
e <- rnorm(n, 0, 10)
base <- 148 + 0.55 * (baseline_sbp - 152) + 0.15 * (age - 55) + 0.4 * (bmi - 26) + 3 * diabetes - 1.5 * (education == "Secondary+") - 1.0 * motivation
direct <- -3 - 0.08 * (baseline_sbp - 152)                         # direct effect, larger with higher baseline SBP
y0 <- base - 9 * adh0 + e
y1 <- base + direct - 9 * adh1 + e
adherent <- ifelse(programme == 1, adh1, adh0)
sbp_12m <- round(ifelse(programme == 1, y1, y0))
clinic_visits <- rpois(n, exp(0.9 + 0.5 * programme + 0.02 * (sbp_12m - 145)))
d <- data.frame(id = sprintf("H%04d", 1:n), age, sex, education, urban, bmi, diabetes, baseline_sbp, programme, adherent, clinic_visits, sbp_12m, controlled = as.integer(sbp_12m < 140))
write_csv(d, "data/htn_programme.csv")

# ── feature check ──
ate <- mean(y1 - y0); att <- mean((y1 - y0)[programme == 1])
naive <- coef(lm(sbp_12m ~ programme, d))[2]
adj <- coef(lm(sbp_12m ~ programme + age + sex + education + urban + bmi + diabetes + baseline_sbp, d))[2]
med <- coef(lm(sbp_12m ~ programme + adherent + age + sex + education + urban + bmi + diabetes + baseline_sbp, d))[2]
col <- coef(lm(sbp_12m ~ programme + clinic_visits + age + sex + education + urban + bmi + diabetes + baseline_sbp, d))[2]
cat(sprintf("enrolled %.0f%% | TRUE ATE %.2f, ATT %.2f | naive %.2f | adjusted %.2f | + mediator %.2f | + collider %.2f | baseline SBP: enrolled %.1f vs not %.1f\n",
            100 * mean(programme), ate, att, naive, adj, med, col, mean(baseline_sbp[programme == 1]), mean(baseline_sbp[programme == 0])))
stopifnot(ate < -5, ate > -8, att < ate - 0.3, naive > -2.5, abs(adj - ate) < 1.2, med > adj + 1.5, abs(col - ate) > 1.5, mean(programme) > 0.3, mean(programme) < 0.55)
cat("feature check passed\n")
