# ═══════════════════════════════════════════════════════════════
# make_data.R — the practice dataset data/prac_modded.xlsx (SYNTHETIC; no real people)
#
# Used by the Basic track's Data Analysis page, the facilitator script data_analysis.R and the
# Statistical Analysis workshop (stats-workshop/). Column names and category labels are kept exactly
# as in the original practice file so that every script that reads it still runs.
#
# Story: 631 adults screened for NCDs in a community block, then followed for 6 months in a
# lifestyle and foot-care programme (fasting glucose, systolic pressure and foot pain at
# presentation, 3 and 6 months). Effects are set to be medically plausible:
#   height: men about 13 cm taller · BMI higher with wealth · SBP rises about 0.5 mmHg per year of age,
#   with BMI and in men · known diabetes about 6%, more with age, BMI and known hypertension ·
#   glucose strongly right-skewed (diabetes) · formerly married (mostly widowed) adults older and poorer ·
#   screening more common in older, richer and female adults · the programme lowers fasting glucose,
#   SBP and foot pain, and repeated measurements are correlated within a person.
# Four records have SBP and DBP swapped and one weight lost its decimal point (7.2 for 72 kg):
# planted entry errors for the "check before you test" lesson (Session 1).
#
# Usage (repo root):  Rscript stats-workshop/make_data.R   — writes the file, then runs the feature check
# ═══════════════════════════════════════════════════════════════
suppressPackageStartupMessages({ library(dplyr); library(writexl) })
set.seed(20261127)
n <- 631

sex    <- ifelse(runif(n) < 0.55, "female", "male")
male   <- sex == "male"
age    <- pmin(85, round(18 + rgamma(n, shape = 4.5, scale = 6)))           # right-skewed, 18-85

# Marital status from age and sex; widowhood is more common in older women
u <- runif(n)
p_never    <- ifelse(age < 25, 0.75, ifelse(age < 35, 0.20, 0.04))
p_formerly <- ifelse(age < 45, 0.04, ifelse(age < 60, 0.10, ifelse(male, 0.22, 0.48)))
marital <- ifelse(u < p_never, "never married", ifelse(u < p_never + p_formerly, "formerly/ever married", "currently married"))
formerly <- marital == "formerly/ever married"

# Wealth: quintile-like groups from a latent score; formerly married households are poorer
w_lat  <- rnorm(n) - 0.7 * formerly
cuts   <- quantile(w_lat, c(0.12, 0.30, 0.52, 0.77))
w      <- 1 + findInterval(w_lat, cuts)                           # 1 = poorest ... 5 = richest
wealth <- c("poorest", "poorer", "middle", "richer", "richest")[w]
bpl    <- ifelse(runif(n) < c(0.75, 0.45, 0.15, 0.05, 0.02)[w], "yes", "no")

# Body size
height <- round(ifelse(male, rnorm(n, 167, 6.5), rnorm(n, 154, 6)) - 0.06 * pmax(age - 50, 0), 1)
bmi    <- rnorm(n, 22.5, 3.6) + 0.9 * (w - 3) + 0.05 * pmin(age - 40, 20) + 0.6 * !male
weight <- round(bmi * (height / 100)^2, 1)
bmi    <- weight / (height / 100)^2

# Blood pressure at screening
sbp <- round(pmin(220, pmax(88, 102 + 0.5 * age + 0.9 * (bmi - 23) + 4 * male + rnorm(n, 0, 16))))
dbp <- round(pmin(sbp - 18, pmax(55, 20 + 0.42 * sbp + 0.3 * (bmi - 23) + rnorm(n, 0, 6))))
htn_measured <- sbp >= 140 | dbp >= 90
known_htn <- ifelse(htn_measured, runif(n) < 0.32, runif(n) < 0.02)       # about a third are aware

# Diabetes and glucose
dm  <- runif(n) < plogis(-4.8 + 0.045 * (age - 40) + 0.12 * (bmi - 23) + 1.5 * known_htn + 0.15 * (w - 3) + 1.2 * (age > 45))
glu <- round(ifelse(dm, exp(rnorm(n, log(195), 0.33)),
                    exp(rnorm(n, log(104), 0.12)) + 0.25 * (age - 40) + 0.9 * (bmi - 23)))
glu <- pmax(glu, 62)

# Screening history
scr_bp  <- runif(n) < plogis(0.25 + 0.03 * (age - 40) + 0.35 * (w - 3) + 0.4 * !male + 1.5 * known_htn)
scr_glu <- runif(n) < plogis(-0.35 + 0.03 * (age - 40) + 0.35 * (w - 3) + 2.5 * dm)

# Foot pain before and after the foot-care programme
pain_b <- runif(n) < plogis(-0.9 + 0.03 * (age - 40) + 0.07 * (bmi - 23) + 1.1 * dm)
pain_a <- ifelse(pain_b, runif(n) < 0.55, runif(n) < 0.05)

# Fasting glucose over the programme: a person-level effect keeps the visits correlated
fbs0 <- 106 + 0.25 * (age - 40) + 1.1 * (bmi - 23) + 34 * dm + rnorm(n, 0, 10)
fbs3 <- fbs0 - 6.5 + rnorm(n, 0, 6)
fbs6 <- fbs0 - 10.5 + rnorm(n, 0, 7)

# Systolic pressure over the programme (right-skewed at presentation)
sbp0 <- round(pmin(230, sbp + rnorm(n, 0, 6) + ifelse(htn_measured, rexp(n, 1 / 10), 0)))
sbp3 <- round(sbp0 - 5 - 0.12 * (sbp0 - 130) + rnorm(n, 0, 7))
sbp6 <- round(sbp0 - 8 - 0.18 * (sbp0 - 130) + rnorm(n, 0, 8))

yn <- function(x) ifelse(x, "yes", "no")
YN <- function(x) ifelse(x, "Yes", "No")
d <- tibble(
  `S.no` = seq_len(n),
  ID = 90000000000 + seq_len(n),                                   # synthetic identifiers
  `Date of screenig` = as.POSIXct("2021-01-01", tz = "UTC") + (seq_len(n) - 1) * 86400,
  `Current date` = as.POSIXct("2024-11-01", tz = "UTC"),
  `Wealth index of participants` = wealth,
  `Below poverty line` = bpl,
  `Sex of participants` = sex,
  `Age of participants` = age,
  `Marital status of participants` = marital,
  `SBP (in mmHg)` = sbp,
  `DBP (in mmHg)` = dbp,
  `Ever screened for BP` = yn(scr_bp),
  `Past history of hypertension` = yn(known_htn),
  `Ever screened for glucose` = yn(scr_glu),
  `Past history of diabetes` = yn(dm),
  `Glucose level (mg/dL)` = glu,
  pain_foot_bfr = YN(pain_b),
  pain_foot_aftr = YN(pain_a),
  height = height,
  weight = weight,
  fbs_presentation = round(fbs0, 2),
  fbs_3_months = round(fbs3, 2),
  fbs_6_months = round(fbs6, 2),
  sbp_presentation = sbp0,
  sbp_3_months = sbp3,
  sbp_6_months = sbp6
)

# Planted entry errors (Session 1): four SBP/DBP swaps and one weight without its decimal point
swap <- c(57, 212, 388, 540)
d[swap, c("SBP (in mmHg)", "DBP (in mmHg)")] <- d[swap, c("DBP (in mmHg)", "SBP (in mmHg)")]
d$weight[301] <- round(d$weight[301] / 10, 1)

out <- c("data/prac_modded.xlsx", "../data/prac_modded.xlsx")[c(dir.exists("data"), !dir.exists("data"))][1]
write_xlsx(d, out)
cat("Wrote", out, "\n")

# ── Feature check: stop if a teaching feature is lost ─────────────────────────
x <- d; names(x) <- janitor::make_clean_names(names(x))
x$weight[x$weight < 20] <- x$weight[x$weight < 20] * 10                 # the corrections Session 1 teaches
sw <- x$sbp_in_mm_hg < x$dbp_in_mm_hg
x[sw, c("sbp_in_mm_hg", "dbp_in_mm_hg")] <- x[sw, c("dbp_in_mm_hg", "sbp_in_mm_hg")]
skw <- function(v) mean((v - mean(v))^3) / sd(v)^3
t_htn_dm <- table(x$past_history_of_hypertension, x$past_history_of_diabetes)
mcn <- mcnemar.test(table(x$pain_foot_bfr, x$pain_foot_aftr))
mw  <- table(x$marital_status_of_participants, x$wealth_index_of_participants)
age_dm <- t.test(age_of_participants ~ past_history_of_diabetes, data = x)
paired_w   <- diff(t.test(x$fbs_presentation, x$fbs_6_months, paired = TRUE)$conf.int)
unpaired_w <- diff(t.test(x$fbs_presentation, x$fbs_6_months)$conf.int)
checks <- c(
  "631 rows, no missing values"            = nrow(d) == 631 && !anyNA(d),
  "4 SBP < DBP and 1 weight < 20 planted"  = sum(d$`SBP (in mmHg)` < d$`DBP (in mmHg)`) == 4 && sum(d$weight < 20) == 1,
  "men 10-16 cm taller"                    = between(diff(tapply(x$height, x$sex_of_participants, mean)), 10, 16),
  "known diabetes 4-9%"                    = between(mean(x$past_history_of_diabetes == "yes"), 0.04, 0.09),
  "known hypertension 6-13%"               = between(mean(x$past_history_of_hypertension == "yes"), 0.06, 0.13),
  "measured hypertension 18-35%"           = between(mean(x$sbp_in_mm_hg >= 140 | x$dbp_in_mm_hg >= 90), 0.18, 0.35),
  "HTN x DM: an expected count below 5"    = min(suppressWarnings(chisq.test(t_htn_dm))$expected) < 5,
  "HTN x DM: Fisher OR > 3, p < 0.01"      = fisher.test(t_htn_dm)$estimate > 3 && fisher.test(t_htn_dm)$p.value < 0.01,
  "diabetics older by > 6 years, p < 0.01" = diff(age_dm$estimate) > 6 && age_dm$p.value < 0.01,
  "glucose skewness > 2"                   = skw(x$glucose_level_mg_d_l) > 2,
  "foot pain falls, McNemar p < 0.001"     = mcn$p.value < 0.001 && mean(x$pain_foot_aftr == "Yes") < mean(x$pain_foot_bfr == "Yes"),
  "formerly married over-represented among poorest" = chisq.test(mw)$p.value < 0.01 && chisq.test(mw)$stdres["formerly/ever married", "poorest"] > 2,
  "FBS visits correlated (r > 0.6)"        = cor(x$fbs_presentation, x$fbs_6_months) > 0.6,
  "FBS falls 7-14 mg/dL by 6 months"       = between(mean(x$fbs_presentation - x$fbs_6_months), 7, 14),
  "pairing narrows the FBS CI by half"     = paired_w < 0.5 * unpaired_w,
  "SBP at presentation right-skewed"       = skw(x$sbp_presentation) > 0.3,
  "age and SBP: r 0.25-0.50"               = between(cor(x$age_of_participants, x$sbp_in_mm_hg), 0.25, 0.50),
  "weight differs by wealth (ANOVA p < 0.001)" = summary(aov(weight ~ wealth_index_of_participants, x))[[1]][1, 5] < 0.001
)
print(data.frame(ok = checks))
if (!all(checks)) stop("Feature check failed: ", paste(names(checks)[!checks], collapse = "; "))
cat("All teaching features present.\n")
