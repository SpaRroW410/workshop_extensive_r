# ═══════════════════════════════════════════════════════════════
# LAB 1 — Time-to-event data and censoring
# Survival analysis workshop | Session 1
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(survival); library(broom); library(gtsummary); library(ggsurvfit) })
theme_set(theme_minimal(base_size = 14))

tb_path <- c("data/tb_cohort.csv", "../data/tb_cohort.csv", "../../data/tb_cohort.csv")
tb_path <- tb_path[file.exists(tb_path)][1]
tb <- read_csv(tb_path, show_col_types = FALSE) |>
  mutate(sex = factor(sex, levels = c("Female", "Male")), hiv = factor(hiv, levels = c("Negative", "Positive")),
         diabetes = factor(diabetes, levels = c("No", "Yes")), smoker = factor(smoker, levels = c("No", "Yes")),
         mdr_tb = factor(mdr_tb, levels = c("No", "Yes")), smear = factor(smear, levels = c("Negative", "Positive")),
         treatment = factor(treatment, levels = c("Self-administered", "DOT")))

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: How many patients died and how many were censored? (status: 1 = died, 0 = censored)
table(tb$status)                                                    #@ table
#% A (Q1): 113 died, 487 censored.

# Q1. What fraction of patients is censored, and why can they not simply be dropped?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Give the percentage of patients who were censored.
round(100 * mean(tb$status == 0), 1)                                #@ mean
#% A: about 81%.

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Among the censored patients, how many were lost to follow-up and
# how many were alive at the end of follow-up?
table(tb$censor_reason)                                             #@ censor_reason
#% A (Q3): about 103 lost to follow-up and about 384 alive at the end.

# Q3. Why does the reason for censoring matter for the analysis?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Build the survival object from follow-up time and the event indicator.
y <- Surv(tb$time_months, tb$status)                                #@ Surv
head(y, 12)
#% A (Q4): censored times are printed with a plus sign (for example 17.2+).

# Q4. What does the + after a time mean?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: The WRONG way to summarise follow-up: the mean time of ALL patients.
# Compare it with the mean time of those who died.
c(all = mean(tb$time_months), died = mean(tb$time_months[tb$status == 1]))   #@ mean || status
#% A (Q5): neither is a survival time: the mean of all mixes deaths and censored times; the mean among deaths ignores everyone still alive (biased downward).

# Q5. Why is the mean follow-up time a poor summary of survival?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Total person-time at risk in person-YEARS (time is in months).
py <- sum(tb$time_months) / 12                                      #@ sum || 12
round(py, 1)

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: The crude mortality RATE per 100 person-years: deaths / person-years x 100.
round(sum(tb$status) / py * 100, 1)                                 #@ sum || 100
#% A: about 15 deaths per 100 person-years (113 deaths in about 744 person-years).

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Median FOLLOW-UP time by the "reverse Kaplan-Meier" method: swap
# the meaning of event and censoring (1 - status).
rkm <- survfit(Surv(time_months, 1 - status) ~ 1, data = tb)        #@ 1 - status
summary(rkm)$table["median"]
#% A (Q8): about 18 months: the typical length of follow-up of the cohort. The ordinary median of the raw times mixes deaths (short) with censored times and understates follow-up.

# Q8. Why is the reverse Kaplan-Meier median a better description of follow-up than the median of the raw times?
