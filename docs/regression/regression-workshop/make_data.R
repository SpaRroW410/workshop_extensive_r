# ═══════════════════════════════════════════════════════════════
# make_data.R — simulate the adult NCD survey used in the
# "Theory of Regression Analysis" workshop.
#
# Run from the repo root OR from regression-workshop/:
#     Rscript regression-workshop/make_data.R
# Output: data/ncd_survey.csv   (n = 600, ~20 villages)
#
# Teaching features built in ON PURPOSE (verified at the end):
#   1. Confounding        age & BMI drive both salt intake and SBP
#   2. Multicollinearity  waist ~ BMI (r ≈ 0.95)
#   3. Heteroscedasticity SBP variance rises with age
#   4. Mild curvature     small age^2 term in SBP
#   5. Clustering         village-level random shift in SBP
#   6. Common outcome     hypertension prevalence ≈ 32%
#   7. Missing values     ~3% missing in bmi, salt_g, education
# ═══════════════════════════════════════════════════════════════

suppressPackageStartupMessages({
  library(tidyverse)
  library(car)
  library(lmtest)
})

set.seed(8)
n <- 600
n_village <- 20

# ── Output location (works from repo root or from regression-workshop/) ──
out_dir  <- if (dir.exists("data")) "data" else if (dir.exists("../data")) "../data" else stop("Run from repo root or regression-workshop/")
out_file <- file.path(out_dir, "ncd_survey.csv")

# ── 1. Villages (clusters): unequal sizes, residence is a village trait ──
village_sizes <- 20 + as.vector(rmultinom(1, n - 20 * n_village, rep(1, n_village)))
village_id    <- rep(seq_len(n_village), village_sizes)
village_urban <- rep(c(TRUE, FALSE), times = c(7, 13))[sample(n_village)]  # 7 urban, 13 rural
village_shift <- rnorm(n_village, 0, 3.5)                                   # SBP random effect (mmHg)

# ── 2. Demographics ──
age <- round(pmin(69, pmax(30, rnorm(n, 49, 11))))
sex <- sample(c("Male", "Female"), n, replace = TRUE)
male <- as.integer(sex == "Male")
urban <- as.integer(village_urban[village_id])

# education: younger, urban, male -> more schooling
edu_score <- 0.9 * urban - 0.045 * (age - 49) + 0.35 * male + rnorm(n, 0, 1)
education <- cut(edu_score, breaks = c(-Inf, -0.6, 0.3, 1.1, Inf),
                 labels = c("No schooling", "Primary", "Secondary", "Graduate+"))

# ── 3. Anthropometry (BMI confounded with age; waist almost = f(BMI)) ──
bmi   <- pmax(15, 22.3 + 0.045 * (age - 49) + 1.3 * urban + 0.5 * (1 - male) + rnorm(n, 0, 3.4))
waist <- 22 + 2.45 * bmi + 4 * male + rnorm(n, 0, 2)      # r(bmi, waist) ≈ 0.95

# ── 4. Behaviours ──
salt_g  <- pmin(20, pmax(2, 7.2 + 0.06 * (age - 49) + 0.22 * (bmi - 24) +
                           0.7 * (1 - urban) + rnorm(n, 0, 2)))
tobacco <- rbinom(n, 1, plogis(-1.4 + 1.3 * male - 0.25 * (as.integer(education) - 2)))
alcohol <- rbinom(n, 1, plogis(-2.4 + 1.8 * male - 0.2 * (as.integer(education) - 2)))
pa_score <- 0.4 * urban * (-1) + 0.015 * (age - 49) * (-1) + rnorm(n, 0, 1) - 0.2 * (1 - male) * (-1)
phys_act <- cut(pa_score, breaks = c(-Inf, -0.45, 0.55, Inf),
                labels = c("high", "moderate", "low"))
phys_act <- factor(phys_act, levels = c("low", "moderate", "high"))

# ── 5. Blood pressure ──
# True structure: salt 1.8 mmHg/g, BMI 0.9 mmHg per kg/m2 (4.5 per 5 units),
# age 0.55 mmHg/yr + small curvature, male +3, tobacco/alcohol +1.5 each,
# activity -1.5 (moderate) / -3.5 (high), schooling gradient, village shift.
edu_eff <- c("No schooling" = 1.5, "Primary" = 0.8, "Secondary" = 0, "Graduate+" = -0.7)[as.character(education)]
pa_eff  <- c(low = 0, moderate = -1.5, high = -3.5)[as.character(phys_act)]

mu_sbp <- 1.8 * salt_g + 0.9 * (bmi - 24) +
  0.55 * (age - 49) + 0.013 * (age - 49)^2 +
  3 * male + 1.5 * tobacco + 1.5 * alcohol + pa_eff + edu_eff +
  village_shift[village_id]

sd_sbp  <- 5.5 + 0.16 * age                 # heteroscedastic: ~10.3 at 30 -> ~16.5 at 69
sbp_raw <- mu_sbp + rnorm(n, 0, sd_sbp)
dbp_raw <- 0.45 * sbp_raw + 0.12 * (age - 49) + rnorm(n, 0, 5)

# calibrate the overall level so hypertension prevalence is ≈ 32%
prev_at <- function(shift) mean(round(sbp_raw + shift) >= 140 | round(0.45 * shift + dbp_raw) >= 90)
shifts  <- seq(60, 140, by = 0.25)
shift   <- shifts[which.min(abs(sapply(shifts, prev_at) - 0.32))]
sbp <- round(sbp_raw + shift)
dbp <- round(dbp_raw + 0.45 * shift)
htn <- as.integer(sbp >= 140 | dbp >= 90)

# ── 6. Assemble, then introduce ~3% missingness (MCAR) in 3 variables ──
ncd <- tibble(
  id = seq_len(n),
  village = sprintf("V%02d", village_id),
  age, sex,
  residence = if_else(urban == 1, "Urban", "Rural"),
  education = as.character(education),
  bmi = round(bmi, 1), waist = round(waist, 1), salt_g = round(salt_g, 1),
  tobacco = if_else(tobacco == 1, "Yes", "No"),
  alcohol = if_else(alcohol == 1, "Yes", "No"),
  phys_act = as.character(phys_act),
  sbp, dbp, htn
)

set_na <- function(x, p) { x[sample(length(x), round(p * length(x)))] <- NA; x }
ncd <- ncd |>
  mutate(bmi = set_na(bmi, 0.03),
         salt_g = set_na(salt_g, 0.03),
         education = set_na(education, 0.025))

write_csv(ncd, out_file)
cat("Wrote", nrow(ncd), "rows to", out_file, "\n")

# ═══════════════════════════════════════════════════════════════
# CHECK SUMMARY — does every teaching feature actually show up?
# ═══════════════════════════════════════════════════════════════
d <- read_csv(out_file, show_col_types = FALSE) |>
  mutate(sex = factor(sex), residence = factor(residence), tobacco = factor(tobacco),
         alcohol = factor(alcohol), phys_act = factor(phys_act, c("low", "moderate", "high")),
         education = factor(education, c("No schooling", "Primary", "Secondary", "Graduate+")))

cc <- d |> drop_na(sbp, salt_g, age, bmi, sex, education)
crude <- lm(sbp ~ salt_g, data = cc)
adj   <- lm(sbp ~ salt_g + age + bmi + sex + residence + education + tobacco + alcohol + phys_act, data = cc)
b_crude <- coef(crude)["salt_g"]; b_adj <- coef(adj)["salt_g"]

vif_both <- vif(lm(sbp ~ salt_g + age + bmi + waist, data = cc))
bp   <- bptest(adj)
quad <- summary(lm(sbp ~ salt_g + age + I(age^2) + bmi + sex, data = cc))$coefficients["I(age^2)", ]
reset <- resettest(adj, power = 2, type = "regressor", data = cc)
res_by_village <- anova(lm(resid(adj) ~ factor(cc$village)))
msb <- res_by_village$`Mean Sq`[1]; msw <- res_by_village$`Mean Sq`[2]
k <- mean(table(cc$village))
icc <- (msb - msw) / (msb + (k - 1) * msw)
miss_pct <- d |> summarise(across(everything(), ~ round(100 * mean(is.na(.x)), 1))) |>
  pivot_longer(everything()) |> filter(value > 0)
age_hi <- as.integer(d$age >= 50)
prev_hi <- mean(d$htn[age_hi == 1]); prev_lo <- mean(d$htn[age_hi == 0])
or_hi <- (prev_hi / (1 - prev_hi)) / (prev_lo / (1 - prev_lo))

cat("\n══════════ FEATURE CHECK ══════════\n")
cat(sprintf("n = %d | villages = %d | mean SBP = %.1f (SD %.1f) | age range %d-%d\n",
            nrow(d), n_distinct(d$village), mean(d$sbp), sd(d$sbp), min(d$age), max(d$age)))
cat(sprintf("1. Confounding   : crude salt beta = %.2f | adjusted = %.2f | shrinkage = %.0f%%\n",
            b_crude, b_adj, 100 * (1 - b_adj / b_crude)))
cat(sprintf("   adjusted BMI beta = %.2f per kg/m2 (= %.1f per 5 units)\n",
            coef(adj)["bmi"], 5 * coef(adj)["bmi"]))
cat(sprintf("2. Collinearity  : r(bmi, waist) = %.2f | VIF bmi = %.1f, waist = %.1f\n",
            cor(d$bmi, d$waist, use = "complete.obs"), vif_both["bmi"], vif_both["waist"]))
cat(sprintf("3. Heterosced.   : Breusch-Pagan p = %.2g | SD of resid, age<45 = %.1f vs age>=55 = %.1f\n",
            bp$p.value, sd(resid(adj)[cc$age < 45]), sd(resid(adj)[cc$age >= 55])))
cat(sprintf("4. Curvature     : age^2 term = %.4f (p = %.3g) | RESET p = %.3g\n",
            quad["Estimate"], quad["Pr(>|t|)"], reset$p.value))
cat(sprintf("5. Clustering    : ICC of residuals by village = %.3f (design effect ≈ %.1f)\n",
            icc, 1 + (k - 1) * icc))
cat(sprintf("6. Common outcome: HTN prevalence = %.1f%% | age>=50: %.1f%% vs <50: %.1f%% -> PR = %.2f, OR = %.2f\n",
            100 * mean(d$htn), 100 * prev_hi, 100 * prev_lo, prev_hi / prev_lo, or_hi))
cat("7. Missing (%)   :", paste0(miss_pct$name, "=", miss_pct$value, collapse = ", "), "\n")
cat("═══════════════════════════════════\n")

stopifnot(
  "confounding: crude beta should be >=1.3x adjusted" = b_crude > 1.3 * b_adj,
  "salt effect should be a few mmHg per g"            = b_adj > 1 && b_crude < 5,
  "collinearity: both VIFs > 5"                       = all(vif_both[c("bmi", "waist")] > 5),
  "heteroscedasticity detectable (BP p < 0.05)"       = bp$p.value < 0.05,
  "age curvature detectable (p < 0.05)"               = quad["Pr(>|t|)"] < 0.05,
  "HTN prevalence 30-35%"                             = between(mean(d$htn), 0.30, 0.35),
  "missingness 2-4% in 3 variables"                   = nrow(miss_pct) == 3 && all(miss_pct$value > 2 & miss_pct$value < 4),
  "OR must visibly exceed PR"                         = or_hi > 1.3 * (prev_hi / prev_lo)
)
cat("All built-in features verified ✔\n")
