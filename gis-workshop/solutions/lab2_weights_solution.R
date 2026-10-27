# ═══════════════════════════════════════════════════════════════
# LAB 2 — Neighbours and spatial weights
# GIS and Spatial Statistics workshop | Session 2
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

# ── Task 1 ──────────────────────────────────────────────────────
# Goal: Build QUEEN contiguity neighbours for the blocks.
nb_q <- poly2nb(blocks, queen = TRUE, snap = 1e-4)                  #@ poly2nb || TRUE
nb_q

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Print the summary: how many links, the average number of
# neighbours, and the least and most connected blocks.
summary(nb_q)                                                       #@ summary
#% A (Q2): 79 regions, about 5 neighbours on average; no regions without links (no isolates).

# Q2. Are there any blocks with no neighbours? Why would that matter?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Build ROOK neighbours and compare the total number of links with queen.
nb_r <- poly2nb(blocks, queen = FALSE, snap = 1e-4)                 #@ FALSE
c(queen = sum(card(nb_q)), rook = sum(card(nb_r)))                  #@ card
#% A (Q3): queen has equal or more links because corners count too.

# Q3. Which has more links, and why?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Get the block centroids as an x/y matrix and build the 5 nearest
# neighbours of every block.
cen <- st_coordinates(st_centroid(blocks))
nb_k5 <- knn2nb(knearneigh(cen, k = 5))                             #@ knn2nb || knearneigh
table(card(nb_k5))
#% A: every block has exactly 5 neighbours (that is the definition of k-nearest).

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Convert the queen neighbours into ROW-STANDARDISED weights.
lw <- nb2listw(nb_q, style = "W", zero.policy = TRUE)               #@ nb2listw || "W"
lw$weights[[1]]
sum(lw$weights[[1]])
#% A (Q5): each neighbour gets 1/(number of neighbours); the row sums to 1.

# Q5. What do the weights of block 1 add up to, and why?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Compute the SPATIAL LAG of the dengue rate: each block's weighted
# average of its neighbours' rates.
blocks$lag_rate <- lag.listw(lw, blocks$dengue_per_100k, zero.policy = TRUE)   #@ lag.listw
head(round(cbind(rate = blocks$dengue_per_100k, lag = blocks$lag_rate), 1))

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Check block 1's lag by hand: the plain mean of its neighbours' rates.
mean(blocks$dengue_per_100k[nb_q[[1]]])                             #@ nb_q[[1]]
blocks$lag_rate[1]
#% A (Q7): they match, because with row-standardised weights the lag is the neighbours' average.

# Q7. Why do the two numbers agree?

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Run Moran's I with FOUR different weight definitions and compare.
w_list <- list(queen = nb2listw(nb_q, style = "W", zero.policy = TRUE),
               rook = nb2listw(nb_r, style = "W", zero.policy = TRUE),
               knn5 = nb2listw(nb_k5, style = "W"))
sapply(w_list, \(w) unname(moran.test(blocks$dengue_per_100k, w, zero.policy = TRUE)$estimate[1]))   #@ moran.test || estimate
#% A (Q8): all clearly positive and close (about 0.45-0.5); the pattern is strong enough not to depend much on the weights.

# Q8. Do the conclusions depend on the neighbour definition here? When might they?
