# ═══════════════════════════════════════════════════════════════
# LAB 1 — The linear assumption and simple fixes
# Curves and interactions workshop | Session 1
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(splines); library(mgcv); library(emmeans) })
theme_set(theme_minimal(base_size = 14))

p <- c("data/ncd_curves.csv", "../data/ncd_curves.csv", "../../data/ncd_curves.csv"); p <- p[file.exists(p)][1]
ncd <- read_csv(p, show_col_types = FALSE) |> mutate(sex = factor(sex), smoker_f = factor(smoker, labels = c("Non-smoker", "Smoker")))

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Plot SBP against age with a straight line AND a flexible (loess) smoother, to see whether a straight line is adequate.
ggplot(ncd, aes(age, sbp)) + geom_point(alpha = 0.15) + geom_smooth(method = "lm", colour = "red", se = FALSE) + geom_smooth(method = "loess", colour = "blue", se = FALSE)   #@ method = "lm" || loess
#% A: the red line misses the bend: SBP rises slowly before about 45 and faster after; the blue smoother shows it.

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Fit a linear model of SBP on age, BMI, salt, activity, sex and smoking, then plot the residuals against age with a smoother.
m_lin <- lm(sbp ~ age + bmi + salt + activity + sex + smoker, data = ncd)   #@ lm
ggplot(data.frame(age = ncd$age, res = resid(m_lin)), aes(age, res)) + geom_point(alpha = 0.15) + geom_smooth(se = FALSE) + geom_hline(yintercept = 0)   #@ resid
#% A (Q2): the residuals are not flat around 0: positive in the middle and at the end, negative at both ends, so a straight line is the wrong shape.

# Q2. What does a curved residual smoother tell you?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Add a quadratic term for age (use poly with degree 2) and compare the two models with an F test and AIC.
m_quad <- lm(sbp ~ poly(age, 2) + bmi + salt + activity + sex + smoker, data = ncd)   #@ poly
anova(m_lin, m_quad)
AIC(m_lin, m_quad)

#% A: the quadratic is better (F test p about 2e-9; AIC 30,737 against 30,771).
# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Categorise age into groups (under 30, 30-44, 45-59, 60 and over) and compare the model fit (AIC) with the continuous-age models.
ncd <- ncd |> mutate(age_grp = cut(age, c(0, 29, 44, 59, 100), labels = c("<30", "30-44", "45-59", "60+")))   #@ cut
m_cat <- lm(sbp ~ age_grp + bmi + salt + activity + sex + smoker, data = ncd)
AIC(m_lin, m_quad, m_cat)

#% A (Q4): the four age groups fit WORSE (AIC 30,810) than even a straight line: steps throw away information and put artificial jumps at the cut-points.
# Q4. Why is categorising a continuous variable usually a poor idea?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Activity has diminishing returns. Use log(1 + activity) in place of activity and compare AIC with the linear version.
m_log <- lm(sbp ~ age + bmi + salt + log1p(activity) + sex + smoker, data = ncd)   #@ log1p
AIC(m_lin, m_log)

#% A: the log version is better (AIC 30,750 against 30,771): diminishing returns.
# ── Task 6 ──────────────────────────────────────────────────────
# Goal: A binary outcome: 10-year CVD event (cvd10). Fit a logistic model with a LINEAR BMI term and read the BMI odds ratio.
g_lin <- glm(cvd10 ~ age + bmi + sex + smoker, data = ncd, family = binomial)   #@ binomial
round(exp(cbind(OR = coef(g_lin), confint.default(g_lin)))["bmi", ], 3)

#% A: OR about 1.007 (95% CI 0.98 to 1.03): "no effect of BMI", which is wrong, because the effect is U-shaped.
# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Add a quadratic BMI term (raw terms bmi and I(bmi^2)) and compare with the linear model.
g_quad <- glm(cvd10 ~ age + bmi + I(bmi^2) + sex + smoker, data = ncd, family = binomial)   #@ I(bmi^2)
anova(g_lin, g_quad, test = "Chisq")

#% A: the quadratic term is hugely significant (deviance drop about 231 on 1 df).
# ── Task 8 ──────────────────────────────────────────────────────
# Goal: The BMI with the lowest predicted risk (the turning point of the parabola): -b / (2c), from the two coefficients.
b <- coef(g_quad)
-b[["bmi"]] / (2 * b[["I(bmi^2)"]])                                  #@ 2
#% A: about BMI 24.5, the lowest-risk BMI.
