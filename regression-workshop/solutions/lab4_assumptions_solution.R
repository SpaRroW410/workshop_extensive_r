# ═══════════════════════════════════════════════════════════════
# LAB 4 — Assumptions of linear regression
# Theory of Regression Analysis workshop | Session 4
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({
  library(tidyverse); library(gtsummary); library(broom); library(performance)
  library(see); library(car); library(lmtest); library(pROC)
})
theme_set(theme_minimal(base_size = 14))

csv_path <- c("data/ncd_survey.csv", "../data/ncd_survey.csv", "../../data/ncd_survey.csv")
csv_path <- csv_path[file.exists(csv_path)][1]
ncd <- read_csv(csv_path, show_col_types = FALSE) |>
  mutate(
    sex = factor(sex, levels = c("Female", "Male")),
    residence = factor(residence, levels = c("Urban", "Rural")),
    education = factor(education, levels = c("No schooling", "Primary", "Secondary", "Graduate+")),
    tobacco = factor(tobacco, levels = c("No", "Yes")),
    alcohol = factor(alcohol, levels = c("No", "Yes")),
    phys_act = factor(phys_act, levels = c("low", "moderate", "high")),
    htn_f = factor(htn, levels = 0:1, labels = c("No HTN", "HTN"))
  )

cc <- ncd |>
  drop_na(sbp, salt_g, age, bmi, waist, sex, residence, education, tobacco, alcohol, phys_act)

# The working model for this lab
m <- lm(sbp ~ salt_g + age + bmi + sex + residence + education +
          tobacco + alcohol + phys_act, data = cc)

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Produce the one-page panel of diagnostic plots (linearity,
# homogeneity of variance, influential points, normality of residuals,
# collinearity) for model m.
check_model(m)                                                   #@ check_model

# Q1. Which panels look worrying? Name the assumption each one tests.
#% A (Q1): reference line in "Linearity" curved (age), "Homogeneity" slopes upward (funnel), Q-Q slightly heavy tails, collinearity fine here (no waist).

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Plot residuals (y) against age (x) with a smooth curve through
# them, to see whether the age relationship is straight.
cc$res <- resid(m)                                               #@ resid
ggplot(cc, aes(x = age, y = res)) +
  geom_point(alpha = 0.4, colour = "#3498db") +
  geom_smooth(method = "loess", se = FALSE, colour = "#e74c3c") +   #@ "loess"
  geom_hline(yintercept = 0, linetype = "dashed")

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Test formally whether the residuals depart from a normal
# distribution.
check_normality(m)                                               #@ check_normality

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Test formally whether the residual variance is constant across
# fitted values (the Breusch-Pagan idea).
check_heteroscedasticity(m)                                      #@ check_heteroscedasticity

# Task 4b. The same idea, using the lmtest package.
bptest(m)                                                        #@ bptest

# Q2. What do the normality and heteroscedasticity tests say? With n≈550,
#     why should you not rely on p-values alone and look at the plots too?
#% A (Q2): heteroscedasticity flagged (p<0.05). Large n -> tests are sensitive to trivial departures; plots show size of the problem.

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Put BOTH BMI and waist circumference in the model together and
# check the variance inflation factors.
m_both <- lm(sbp ~ salt_g + age + bmi + waist, data = cc)
check_collinearity(m_both)                                       #@ check_collinearity

# Task 5b. Same VIFs from the car package.
vif(m_both)                                                      #@ vif

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Fix the collinearity by keeping only ONE of the two (BMI) and
# compare the BMI standard errors before and after.
m_bmi <- lm(sbp ~ salt_g + age + bmi, data = cc)                 #@ salt_g + age + bmi
bind_rows(
  both_in  = tidy(m_both) |> filter(term == "bmi"),
  waist_out = tidy(m_bmi)  |> filter(term == "bmi"),
  .id = "model"
)

#% A (Q3): VIF ~10 for both; SE of BMI roughly 2-3x larger when waist is also in. Fix: choose one (clinical reasoning), or combine/ratio, or centre — not "drop the variable with the highest p".

# Q3. How did the SE of the BMI coefficient change when waist was removed?
# Q4. What are two ways to handle strong collinearity? Which suits a
#     thesis where BMI is the exposure of interest?

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Fix the curvature in age by adding a squared age term to the
# model, then test whether the improvement is real by comparing the
# two models.
m_quad <- lm(sbp ~ salt_g + age + I(age^2) + bmi + sex + residence + education +   #@ I(age^2)
               tobacco + alcohol + phys_act, data = cc)
anova(m, m_quad)

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Handle non-constant variance by keeping the same coefficients
# but using robust (sandwich) standard errors.
coeftest(m, vcov. = sandwich::vcovHC(m, type = "HC3"))           #@ coeftest || vcovHC

# ── Task 9 ──────────────────────────────────────────────────────
# Goal: Look at the independence assumption. Boxplot the residuals of
# model m for each village and compute how much residual variation lies
# BETWEEN villages (intraclass correlation) from a one-way ANOVA.
ggplot(cc, aes(x = reorder(village, res, FUN = median), y = res)) +   #@ reorder
  geom_boxplot(fill = "#d6eaf8") +
  labs(x = "Village (ordered by median residual)", y = "Residual (mmHg)") +
  theme(axis.text.x = element_text(angle = 90))
a <- anova(lm(resid(m) ~ factor(cc$village)))                    #@ resid(m)
msb <- a$`Mean Sq`[1]; msw <- a$`Mean Sq`[2]; k <- mean(table(cc$village))
(msb - msw) / (msb + (k - 1) * msw)                              #@ (msb - msw)

#% A (Q5): ICC ~0.06 -> design effect ~ 1 + (k-1)*ICC ≈ 2.7; naive SEs are too small; solution: mixed model / cluster-robust SE (beyond today).

# Q5. Do residuals within a village look more alike than across villages?
#     What does that imply for the standard errors, and which models (from
#     today's flowchart) would handle it?
