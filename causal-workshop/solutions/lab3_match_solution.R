# ═══════════════════════════════════════════════════════════════
# LAB 3 — Propensity scores and matching
# Causal inference workshop | Session 3
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(dagitty); library(MatchIt); library(cobalt); library(sandwich); library(lmtest); library(EValue) })
theme_set(theme_minimal(base_size = 14))

p <- c("data/htn_programme.csv", "../data/htn_programme.csv", "../../data/htn_programme.csv"); p <- p[file.exists(p)][1]
htn <- read_csv(p, show_col_types = FALSE) |> mutate(sex = factor(sex), education = factor(education, levels = c("None", "Primary", "Secondary+")))
f_out <- sbp_12m ~ programme + age + sex + education + urban + bmi + diabetes + baseline_sbp       # outcome model with the confounders
f_ps  <- programme ~ age + sex + education + urban + bmi + diabetes + baseline_sbp                 # propensity-score model

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Estimate the propensity score: the probability of enrolment given the baseline confounders (logistic regression with f_ps).
ps_model <- glm(f_ps, data = htn, family = binomial)                #@ binomial
htn$ps <- predict(ps_model, type = "response")
htn |> group_by(programme) |> summarise(min = min(ps), mean = mean(ps), max = max(ps))

#% A: mean propensity score 0.49 in the enrolled and 0.35 in the others; ranges 0.07 to 0.97 and 0.04 to 0.87.
# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Check OVERLAP (positivity): plot the distribution of the propensity score in the two groups.
ggplot(htn, aes(ps, fill = factor(programme))) + geom_density(alpha = 0.5) + labs(fill = "Programme")   #@ geom_density
#% A (Q2): the distributions overlap over almost the whole range: good. Without overlap some adults have no comparable counterpart and the effect cannot be estimated for them without extrapolation (positivity violation).

# Q2. What would it mean if the two distributions hardly overlapped?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Balance BEFORE matching: standardised mean differences of the covariates between the groups.
bal.tab(f_ps, data = htn, un = TRUE, s.d.denom = "pooled")$Balance[, "Diff.Un", drop = FALSE] |> round(2)   #@ bal.tab
#% A: large imbalance for baseline SBP (0.63) and age (0.43); several others above 0.1.

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: 1:1 nearest-neighbour matching on the propensity score with a caliper of 0.2 standard deviations.
m_out <- matchit(f_ps, data = htn, method = "nearest", distance = "glm", caliper = 0.2)   #@ matchit || caliper
m_out

#% A: 2,114 matched adults (1,057 pairs): 172 of the 1,229 enrolled found no match within the caliper.
# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Balance AFTER matching (standardised mean differences should be below 0.1).
bal.tab(m_out, un = TRUE)$Balance[, c("Diff.Un", "Diff.Adj")] |> round(2)   #@ m_out
#% A: all standardised differences are below 0.1 after matching (largest: baseline SBP 0.06).

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: A love plot of the balance before and after matching.
love.plot(m_out, thresholds = 0.1, abs = TRUE)                      #@ love.plot

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: The effect in the matched sample: a regression of SBP on the programme in the matched data, with a cluster-robust SE on the matched pair.
md <- match.data(m_out)                                             #@ match.data
fit_m <- lm(sbp_12m ~ programme, data = md, weights = weights)
coeftest(fit_m, vcov. = vcovCL, cluster = ~subclass)["programme", ]

#% A (Q7): -5.9 mmHg (SE 0.51). Matching the enrolled estimates the ATT, here for the 1,057 enrolled adults who could be matched (172 dropped), so the target population has changed a little.
# Q7. Which effect does 1:1 matching of the enrolled estimate: the ATE or the ATT? How many enrolled adults were dropped?
