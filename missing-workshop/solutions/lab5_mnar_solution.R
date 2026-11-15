# ═══════════════════════════════════════════════════════════════
# LAB 5 — MNAR sensitivity analysis and reporting
# Missing data workshop | Session 5
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(mice); library(naniar) })
theme_set(theme_minimal(base_size = 14))

p <- c("data/ncd_missing.csv", "../data/ncd_missing.csv", "../../data/ncd_missing.csv"); p <- p[file.exists(p)][1]
ncd <- read_csv(p, show_col_types = FALSE) |> mutate(sex = factor(sex), education = factor(education, levels = c("None", "Primary", "Secondary+")))
dat <- ncd |> select(-id)                          # the id must not enter the imputation model

dat2 <- dat |> mutate(smoker = factor(smoker, labels = c("No", "Yes")))
imp <- mice(dat2, m = 30, maxit = 10, seed = 2038, printFlag = FALSE)

# Truth for the facilitator: the mean HbA1c of the complete data is 5.50%.

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: The mean HbA1c from the observed values and after multiple imputation (assuming MAR).
obs <- mean(dat$hba1c, na.rm = TRUE)
mar <- summary(pool(with(imp, lm(hba1c ~ 1))))$estimate               #@ lm
c(observed = obs, MAR_imputation = mar)
#% A: 5.35 observed and 5.38 after MAR imputation (truth 5.50): MAR imputation barely moves it, because it cannot know that the values are missing for being high.

# Q1. Why does MAR imputation not repair the bias when high values are the ones that go missing?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: DELTA ADJUSTMENT: assume that missing HbA1c values are on average delta percentage points HIGHER than the MAR imputation. Run mice with a post-processing rule for delta = 0.2.
post <- make.post(dat2)                                             #@ make.post
post["hba1c"] <- "imp[[j]][, i] <- imp[[j]][, i] + 0.2"
imp_d <- mice(dat2, m = 30, maxit = 10, seed = 2038, post = post, printFlag = FALSE)   #@ post = post
summary(pool(with(imp_d, lm(hba1c ~ 1))))$estimate
#% A: about 5.42.

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: A TIPPING-POINT table: the pooled mean HbA1c for delta = 0, 0.2, 0.4, 0.6 and 0.8.
run_delta <- function(delta) { po <- make.post(dat2); po["hba1c"] <- paste0("imp[[j]][, i] <- imp[[j]][, i] + ", delta)
  i <- mice(dat2, m = 20, maxit = 5, seed = 2038, post = po, printFlag = FALSE); s <- summary(pool(with(i, lm(hba1c ~ 1)))); c(delta = delta, mean = s$estimate, se = s$std.error) }
do.call(rbind, lapply(c(0, 0.2, 0.4, 0.6, 0.8), run_delta)) |> round(3)   #@ lapply
#% A (Q3): the mean rises by about 0.045 for every 0.2 added (20% of the values are missing): 5.38, 5.42, 5.47, 5.51, 5.55. The facilitator truth of 5.50 corresponds to a delta of about 0.55.

# Q3. How do you decide which delta values to show? What does a delta of 0.5 mean?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Rubin's rules by hand for the mean HbA1c from the MAR imputation: the within-imputation variance W (mean of the variances), the between-imputation variance B (variance of the estimates), and the total T = W + (1 + 1/m) B.
fits <- with(imp, lm(hba1c ~ 1))
est <- sapply(fits$analyses, coef); vr <- sapply(fits$analyses, \(f) vcov(f)[1, 1])
m <- length(est); W <- mean(vr); B <- var(est)                       #@ var(est)
c(estimate = mean(est), W = W, B = B, total_se = sqrt(W + (1 + 1 / m) * B))

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: The prevalence of HbA1c of 6.5 or more (diabetes range), derived in each completed data set, under delta = 0 (MAR) and delta = 0.5.
prev <- function(i) mean(sapply(1:i$m, function(k) mean(complete(i, k)$hba1c >= 6.5)))
po5 <- make.post(dat2); po5["hba1c"] <- "imp[[j]][, i] <- imp[[j]][, i] + 0.5"
imp_5 <- mice(dat2, m = 20, maxit = 5, seed = 2038, post = po5, printFlag = FALSE)
round(c(MAR = prev(imp), delta_0.5 = prev(imp_5)), 3)                #@ prev
#% A: 0.4% under MAR (as observed) against 3.1% with delta = 0.5 (facilitator truth: 4.4%): the prevalence of the diabetes range is very sensitive to the MNAR assumption, because the missing values are the high ones.

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: A one-sentence description of the missing-data handling for a methods section.
cat("Missing values (BMI 26%, HbA1c 21%, activity 12%, smoking 9%, SBP 6%) were handled by multiple imputation by chained equations (20 imputations, predictive mean matching, outcome and auxiliary variables in the imputation model, estimates pooled by Rubin's rules); a delta-adjustment sensitivity analysis explored departures from missing at random for HbA1c.\n")   #@ chained
