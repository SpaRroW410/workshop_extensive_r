# ═══════════════════════════════════════════════════════════════
# LAB 3 — Comparing survival curves: the log-rank test
# Survival analysis workshop | Session 3
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
# Goal: Log-rank test of survival by HIV status.
lr1 <- survdiff(Surv(time_months, status) ~ hiv, data = tb)      #@ survdiff || hiv
lr1
#% A (Q1): chi-square about 5.6 on 1 df, p about 0.02: survival differs by HIV status. Null: the survival curves are the same in the groups.

# Q1. What does the log-rank test compare, and what is its null hypothesis?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Extract the p-value from the test object.
1 - pchisq(lr1$chisq, df = 1)                                    #@ pchisq || chisq

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Compare observed and expected deaths in each HIV group.
cbind(observed = lr1[["obs"]], expected = round(lr1[["exp"]], 1))   #@ "obs" || "exp"
#% A (Q3): HIV-positive patients had more deaths than expected under "no difference"; HIV-negative fewer.

# Q3. How do the observed and expected deaths show the direction of the difference?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Log-rank test by sex. Is there evidence of a difference?
survdiff(Surv(time_months, status) ~ sex, data = tb)                #@ sex
#% A (Q4): no evidence of a difference (p about 0.6): sex does not affect survival in this cohort.

# Q4. Does p = 0.6 prove that men and women have the same survival?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Log-rank test of survival by MDR-TB status.
survdiff(Surv(time_months, status) ~ mdr_tb, data = tb)             #@ mdr_tb

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: A log-rank test of HIV status STRATIFIED by treatment arm (compare within DOT and
# self-administered patients, then combine).
survdiff(Surv(time_months, status) ~ hiv + strata(treatment), data = tb)   #@ strata
#% A (Q6): still significant (p about 0.02): HIV is associated with worse survival within each treatment group. Stratifying compares like with like when another variable also affects survival.

# Q6. Why stratify a log-rank test?

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: The WRONG test: a t-test of follow-up time by HIV status ignores censoring.
# Get its p-value.
t.test(time_months ~ hiv, data = tb)$p.value                        #@ t.test || time_months
#% A (Q7): the t-test compares observed follow-up times that mix deaths and censoring, so it answers the wrong question and can mislead.

# Q7. What goes wrong when a t-test is used on survival times?

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Plot the Kaplan-Meier curves by treatment arm.
survfit2(Surv(time_months, status) ~ treatment, data = tb) |> ggsurvfit()   #@ survfit2 || ggsurvfit
#% A: DOT patients survive longer.
