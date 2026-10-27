# ═══════════════════════════════════════════════════════════════
# LAB 5 — Spatial regression and residual tests
# GIS and Spatial Statistics workshop | Session 5
# Replace every ___ with the missing code. Hints describe the GOAL.
# ═══════════════════════════════════════════════════════════════

# ── Setup ───────────────────────────────────────────────────────
suppressPackageStartupMessages({ library(tidyverse); library(sf); library(spdep); library(spatialreg); library(smerc) })
sf_use_s2(FALSE)
theme_set(theme_minimal(base_size = 14))

geo_path <- c("data/gis/district_blocks.geojson", "../data/gis/district_blocks.geojson", "../../data/gis/district_blocks.geojson")
geo_path <- geo_path[file.exists(geo_path)][1]
blocks <- st_read(geo_path, quiet = TRUE)
blocks$high_burden <- factor(blocks$high_burden, levels = c("Not high", "High"))

nb <- poly2nb(blocks, queen = TRUE, snap = 1e-4)
lw <- nb2listw(nb, style = "W", zero.policy = TRUE)

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Fit an ordinary regression of the dengue rate on poverty_index
# and literacy_pct. Store it as ols.
ols <- lm(dengue_per_100k ~ poverty_index + literacy_pct, data = blocks)   #@ lm || poverty_index
summary(ols)$coefficients

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Test the RESIDUALS of the model for spatial autocorrelation.
lm.morantest(ols, lw, zero.policy = TRUE)                           #@ lm.morantest
#% A (Q2): residual Moran's I about 0.27 with a small p-value: independence is violated; standard errors are probably too small.

# Q2. What does a significant Moran's I of the residuals mean for the model?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Map the residuals with a diverging colour scale centred on zero.
blocks$res_ols <- residuals(ols)                                    #@ residuals
ggplot(blocks) + geom_sf(aes(fill = res_ols)) +
  scale_fill_gradient2(low = "#2166ac", mid = "white", high = "#b2182b", midpoint = 0)   #@ midpoint

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Run the Lagrange multiplier tests (plain and robust, error and lag).
lm.RStests(ols, lw, test = c("RSerr", "RSlag", "adjRSerr", "adjRSlag"), zero.policy = TRUE)   #@ lm.RStests || adjRSlag
#% A (Q4): both plain tests are significant; the robust lag test is significant and the robust error test is not: a lag model is suggested.

# Q4. Which model do the tests point to, and what does that model assume?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Fit the SPATIAL ERROR model.
sem <- errorsarlm(dengue_per_100k ~ poverty_index + literacy_pct, data = blocks, listw = lw, zero.policy = TRUE)   #@ errorsarlm
round(sem$lambda, 3)

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Fit the SPATIAL LAG model.
sar <- lagsarlm(dengue_per_100k ~ poverty_index + literacy_pct, data = blocks, listw = lw, zero.policy = TRUE)   #@ lagsarlm
round(sar$rho, 3)

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Compare the three models by AIC.
AIC(ols, sem, sar)                                                  #@ AIC
#% A (Q7): the spatial models have clearly lower AIC than OLS; the lag and error models are close.

# Q7. Which model fits best by AIC? Is the improvement large?

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Check the residual Moran's I of the spatial error model.
moran.test(residuals(sem), lw, zero.policy = TRUE)$estimate[1]      #@ residuals
#% A: close to 0: the spatial model has absorbed the structure.

# ── Task 9 ──────────────────────────────────────────────────────
# Goal: For the LAG model, get the direct, indirect and total effects.
set.seed(6)
imp <- impacts(sar, listw = lw, R = 199)                            #@ impacts
summary(imp, zstats = TRUE, short = TRUE)
#% A (Q9): total effect is larger than the direct effect: a change in one block's poverty also changes its neighbours' rates.

# Q9. Why is the lag-model coefficient not the full effect of poverty?
