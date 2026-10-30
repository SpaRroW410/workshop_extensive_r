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
ols <- ___(dengue_per_100k ~ ___ + literacy_pct, data = blocks)
summary(ols)$coefficients

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Test the RESIDUALS of the model for spatial autocorrelation.
___(ols, lw, zero.policy = TRUE)

# Q2. What does a significant Moran's I of the residuals mean for the model?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Map the residuals with a diverging colour scale centred on zero.
blocks$res_ols <- ___(ols)
ggplot(blocks) + geom_sf(aes(fill = res_ols)) +
  scale_fill_gradient2(low = "#2166ac", mid = "white", high = "#b2182b", ___ = 0)

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Run the Lagrange multiplier tests (plain and robust, error and lag).
___(ols, lw, test = c("RSerr", "RSlag", "adjRSerr", "___"), zero.policy = TRUE)

# Q4. Which model do the tests point to, and what does that model assume?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Fit the SPATIAL ERROR model.
sem <- ___(dengue_per_100k ~ poverty_index + literacy_pct, data = blocks, listw = lw, zero.policy = TRUE)
round(sem$lambda, 3)

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Fit the SPATIAL LAG model.
sar <- ___(dengue_per_100k ~ poverty_index + literacy_pct, data = blocks, listw = lw, zero.policy = TRUE)
round(sar$rho, 3)

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Compare the three models by AIC.
___(ols, sem, sar)

# Q7. Which model fits best by AIC? Is the improvement large?

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Check the residual Moran's I of the spatial error model.
moran.test(___(sem), lw, zero.policy = TRUE)$estimate[1]

# ── Task 9 ──────────────────────────────────────────────────────
# Goal: For the LAG model, get the direct, indirect and total effects.
set.seed(6)
imp <- ___(sar, listw = lw, R = 199)
summary(imp, zstats = TRUE, short = TRUE)

# Q9. Why is the lag-model coefficient not the full effect of poverty?
