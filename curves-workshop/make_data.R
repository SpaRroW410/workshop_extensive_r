# ═══════════════════════════════════════════════════════════════
# make_data.R — synthetic NCD risk-factor survey for the curves and interactions workshop (no real people)
# Rscript curves-workshop/make_data.R        (repository root; seed fixed)
# Writes data/ncd_curves.csv : 4,000 adults aged 18-80
#   age, sex, bmi, salt (g/day), activity (hours/week of moderate activity), smoker (0/1), sbp (mmHg), cvd10 (0/1: cardiovascular event within 10 years)
# Built-in structure (checked below; the script stops if a teaching feature is lost):
#   * SBP rises slowly with age until about 45 and about 2.5 times faster afterwards (a bend a straight line misses)
#   * SBP rises with BMI with diminishing returns (a saturating curve) and falls with activity with diminishing returns
#   * salt raises SBP more steeply in older adults: salt x age interaction (effect modification)
#   * 10-year CVD risk is U-shaped (J-shaped) in BMI: higher in the underweight and the obese; a straight BMI term shows no effect at all
#   * smoking raises CVD risk more in men than in women: smoker x sex interaction
# ═══════════════════════════════════════════════════════════════
suppressMessages({ library(dplyr); library(readr); library(mgcv); library(splines) })
set.seed(2037)
n <- 4000
age <- round(pmin(80, pmax(18, rnorm(n, 44, 14))))
sex <- sample(c("Female", "Male"), n, TRUE)
bmi <- round(pmin(46, pmax(14.5, rnorm(n, 24.2 + 0.03 * (age - 44) - 0.3 * (sex == "Male"), 4.6))), 1)
salt <- round(pmin(20, pmax(3, rnorm(n, 9 + 0.8 * (sex == "Male"), 2.5))), 1)
activity <- round(pmin(25, rgamma(n, 1.6, 0.45) * ifelse(age > 60, 0.7, 1)), 1)
smoker <- rbinom(n, 1, plogis(-1.7 + 1.1 * (sex == "Male") - 0.01 * (age - 44)))
f_age <- ifelse(age < 45, 0.22 * (age - 18), 0.22 * 27 + 0.55 * (age - 45))
f_bmi <- 16 * (1 - exp(-(bmi - 14) / 8))
f_act <- -7 * (1 - exp(-activity / 3))
sbp <- round(96 + f_age + f_bmi + f_act + 0.7 * (salt - 9) + 0.055 * (salt - 9) * (age - 44) + 3 * (sex == "Male") + 1.5 * smoker + rnorm(n, 0, 11))
lp <- -3.6 + 0.075 * (age - 44) + 0.03 * (bmi - 24.6)^2 + 0.75 * smoker * (sex == "Male") + 0.0 * smoker * (sex == "Female") + 0.35 * (sex == "Male") + 0.014 * (sbp - 125)
cvd10 <- rbinom(n, 1, plogis(lp))
d <- data.frame(id = sprintf("N%04d", 1:n), age, sex, bmi, salt, activity, smoker, sbp, cvd10)
write_csv(d, "data/ncd_curves.csv")

# ── feature check ──
d <- read_csv("data/ncd_curves.csv", show_col_types = FALSE) |> mutate(sex = factor(sex))
l1 <- lm(sbp ~ age + bmi + salt + activity + sex + smoker, d)
l2 <- lm(sbp ~ ns(age, 4) + bmi + salt + activity + sex + smoker, d)
p_age <- anova(l1, l2)$`Pr(>F)`[2]
hinge <- sapply(30:60, function(k) AIC(lm(sbp ~ age + pmax(age - k, 0) + bmi + salt + activity + sex + smoker, d))); k_best <- (30:60)[which.min(hinge)]
g1 <- glm(cvd10 ~ age + bmi + sex + smoker, binomial, d); g2 <- glm(cvd10 ~ age + bmi + I(bmi^2) + sex + smoker, binomial, d)
p_bmi_lin <- summary(g1)$coefficients["bmi", 4]; p_bmi_sq <- summary(g2)$coefficients["I(bmi^2)", 4]
m_int <- lm(sbp ~ ns(age, 4) + bmi + salt * age + activity + sex + smoker, d); p_int <- summary(m_int)$coefficients["salt:age", 4]
g3 <- glm(cvd10 ~ ns(age, 3) + poly(bmi, 2) + sex * smoker, binomial, d); p_ss <- summary(g3)$coefficients[grep("sexMale:smoker", rownames(summary(g3)$coefficients)), 4]
ga <- gam(cvd10 ~ s(age) + s(bmi) + sex + smoker, family = binomial, data = d, method = "REML"); edf_bmi <- summary(ga)$s.table["s(bmi)", "edf"]
cat(sprintf("cvd10 = %.1f%% | age nonlinearity p = %.1e, best hinge knot = %d | BMI linear p = %.2f vs squared p = %.1e (GAM edf %.1f) | salt:age p = %.1e (coef %.3f) | sex x smoker p = %.3f\n",
            100 * mean(d$cvd10), p_age, k_best, p_bmi_lin, p_bmi_sq, edf_bmi, p_int, coef(m_int)["salt:age"], p_ss))
stopifnot(p_age < 1e-6, abs(k_best - 45) <= 5, p_bmi_lin > 0.05, p_bmi_sq < 0.001, edf_bmi > 2, p_int < 0.001, p_ss < 0.1, mean(d$cvd10) > 0.07, mean(d$cvd10) < 0.2)
cat("feature check passed\n")
