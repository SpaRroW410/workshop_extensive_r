# ═══════════════════════════════════════════════════════════════
# LAB 3 — Global spatial autocorrelation: Moran's I and friends
# GIS and Spatial Statistics workshop | Session 3
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
# Goal: Run Moran's I (analytical test) for the dengue rate.
mi <- ___(blocks$dengue_per_100k, ___, zero.policy = TRUE)
mi

# Q1. What is the Moran's I statistic and what value would you expect with no pattern?
# Q2. Is the pattern clustered, random or dispersed?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Run the PERMUTATION version with 999 random shuffles.
set.seed(1)
mc <- ___(blocks$dengue_per_100k, lw, nsim = ___, zero.policy = TRUE)
mc$p.value

# Q3. Why can the permutation p-value never be below 0.001 with 999 shuffles?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Build the Moran scatterplot data: standardise the rate, then take
# the spatial lag of the standardised values.
blocks$z <- as.numeric(___(blocks$dengue_per_100k))
blocks$lag_z <- ___(lw, blocks$z, zero.policy = TRUE)

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Fit a straight line of lag_z on z. Its slope should equal Moran's I.
coef(___(lag_z ~ z, data = blocks))[["z"]]

# Q4. How is the slope of this line related to Moran's I?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Count how many blocks fall in each quadrant of the Moran scatterplot.
quad <- case_when(blocks$z > 0 & blocks$lag_z > 0 ~ "High-High", blocks$z < 0 & blocks$lag_z < 0 ~ "Low-Low",
                  blocks$z > 0 ~ "High-Low", TRUE ~ "Low-High")
___(quad)

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Run Geary's C. Is C below or above 1, and what does that mean?
___(blocks$dengue_per_100k, lw, zero.policy = TRUE)

# Q6. What does a Geary's C below 1 mean?

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Run the Getis-Ord General G test (it needs BINARY weights) to ask
# whether HIGH values cluster.
lw_b <- nb2listw(nb, style = ___, zero.policy = TRUE)
___(blocks$dengue_per_100k, lw_b, zero.policy = TRUE)

# Q7. Moran's I was positive. What extra does the General G tell you?

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Run a JOIN COUNT test for the binary variable high_burden.
___(blocks$high_burden, lw_b, zero.policy = TRUE)

# ── Task 9 ──────────────────────────────────────────────────────
# Goal: Check the result for a variable WITHOUT spatial structure: the
# block population. Run Moran's I by permutation.
set.seed(2)
moran.mc(blocks$___, lw, nsim = 999, zero.policy = TRUE)$p.value

# Q9. What does it tell you that population shows no spatial autocorrelation?

# ── Task 10 ─────────────────────────────────────────────────────
# Goal: Write the one-sentence result for a paper (edit the numbers).
cat("Dengue incidence was clustered (Moran's I =", round(mi$estimate[1], 2), ", queen weights, permutation p =", mc$p.value, ").\n")
