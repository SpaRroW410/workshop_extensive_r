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
mi <- moran.test(blocks$dengue_per_100k, lw, zero.policy = TRUE)    #@ moran.test || lw
mi
#% A (Q1/Q2): I about 0.50, expectation about -0.013, p < 0.001: strong positive spatial autocorrelation.

# Q1. What is the Moran's I statistic and what value would you expect with no pattern?
# Q2. Is the pattern clustered, random or dispersed?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Run the PERMUTATION version with 999 random shuffles.
set.seed(1)
mc <- moran.mc(blocks$dengue_per_100k, lw, nsim = 999, zero.policy = TRUE)     #@ moran.mc || 999
mc$p.value
#% A (Q3): 0.001, the smallest possible with 999 shuffles (1/1000): the real I beat all of them.

# Q3. Why can the permutation p-value never be below 0.001 with 999 shuffles?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Build the Moran scatterplot data: standardise the rate, then take
# the spatial lag of the standardised values.
blocks$z <- as.numeric(scale(blocks$dengue_per_100k))               #@ scale
blocks$lag_z <- lag.listw(lw, blocks$z, zero.policy = TRUE)         #@ lag.listw

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Fit a straight line of lag_z on z. Its slope should equal Moran's I.
coef(lm(lag_z ~ z, data = blocks))[["z"]]                           #@ lm
#% A (Q4): slope = Moran's I (about 0.50).

# Q4. How is the slope of this line related to Moran's I?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Count how many blocks fall in each quadrant of the Moran scatterplot.
quad <- case_when(blocks$z > 0 & blocks$lag_z > 0 ~ "High-High", blocks$z < 0 & blocks$lag_z < 0 ~ "Low-Low",
                  blocks$z > 0 ~ "High-Low", TRUE ~ "Low-High")
table(quad)                                                         #@ table

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Run Geary's C. Is C below or above 1, and what does that mean?
geary.test(blocks$dengue_per_100k, lw, zero.policy = TRUE)          #@ geary.test
#% A (Q6): C about 0.47, well below 1: positive autocorrelation (neighbours similar). Opposite direction to Moran's I.

# Q6. What does a Geary's C below 1 mean?

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Run the Getis-Ord General G test (it needs BINARY weights) to ask
# whether HIGH values cluster.
lw_b <- nb2listw(nb, style = "B", zero.policy = TRUE)               #@ "B"
globalG.test(blocks$dengue_per_100k, lw_b, zero.policy = TRUE)      #@ globalG.test
#% A (Q7): G is above its expectation with p < 0.01: high values cluster.

# Q7. Moran's I was positive. What extra does the General G tell you?

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Run a JOIN COUNT test for the binary variable high_burden.
joincount.test(blocks$high_burden, lw_b, zero.policy = TRUE)        #@ joincount.test
#% A: for "High", observed same-colour joins are far above expected: high-burden blocks touch each other.

# ── Task 9 ──────────────────────────────────────────────────────
# Goal: Check the result for a variable WITHOUT spatial structure: the
# block population. Run Moran's I by permutation.
set.seed(2)
moran.mc(blocks$population, lw, nsim = 999, zero.policy = TRUE)$p.value       #@ population
#% A (Q9): large p-value; population was drawn at random for each block.

# Q9. What does it tell you that population shows no spatial autocorrelation?

# ── Task 10 ─────────────────────────────────────────────────────
# Goal: Write the one-sentence result for a paper (edit the numbers).
cat("Dengue incidence was clustered (Moran's I =", round(mi$estimate[1], 2), ", queen weights, permutation p =", mc$p.value, ").\n")
