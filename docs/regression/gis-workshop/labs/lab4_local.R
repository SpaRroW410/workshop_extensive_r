# ═══════════════════════════════════════════════════════════════
# LAB 4 — Local clusters: LISA, Getis-Ord Gi* and the scan statistic
# GIS and Spatial Statistics workshop | Session 4
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
# Goal: Compute LOCAL Moran's I for the dengue rate.
loc <- ___(blocks$dengue_per_100k, lw, zero.policy = TRUE)
head(round(loc, 3))

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Check that the average of the local values equals the global I.
mean(loc[, "___"])
unname(moran.test(blocks$dengue_per_100k, lw, zero.policy = TRUE)$estimate[1])

# Q2. How are the local and global Moran's I related?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Take the p-value column and count the blocks with p < 0.05.
p <- loc[, "___"]
sum(p < ___)

# Q3. Roughly how many of 79 blocks would be "significant" by chance alone at 5%?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Classify each block as High-High, Low-Low, High-Low, Low-High or
# Not significant, using the standardised value, its lag and p < 0.05.
z <- as.numeric(scale(blocks$dengue_per_100k))
lag_z <- lag.listw(lw, z, zero.policy = TRUE)
blocks$lisa <- case_when(p >= 0.05 ~ "Not significant",
                         z > 0 & lag_z > 0 ~ "___", z < 0 & lag_z < 0 ~ "___",
                         z > 0 & lag_z < 0 ~ "High-Low", TRUE ~ "Low-High")
table(blocks$lisa)

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Map the LISA classes.
ggplot(blocks) + geom_sf(aes(fill = ___), colour = "white") +
  scale_fill_manual(values = c("High-High" = "#d7191c", "Low-Low" = "#2c7bb6", "High-Low" = "#fdae61", "Low-High" = "#abd9e9", "Not significant" = "grey90"))

# Q5. Where are the hot spots, the cold spots and the spatial outliers?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Adjust the 79 p-values for multiple testing with the false
# discovery rate and count what is left.
p_adj <- ___(p, method = "___")
sum(p_adj < 0.05)

# Q6. Why adjust, and what happened to the number of significant blocks?

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Getis-Ord Gi*: include each block in its own neighbourhood, use
# binary weights and compute the z-scores.
lw_self <- nb2listw(___(nb), style = "B", zero.policy = TRUE)
blocks$gi <- as.numeric(___(blocks$dengue_per_100k, lw_self, zero.policy = TRUE))
sum(blocks$gi > 1.96); sum(blocks$gi < -1.96)

# Q7. How does Gi* differ from the LISA classification?

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Run the Kulldorff spatial scan statistic. It needs centroid
# coordinates in km, the case counts and the populations.
cen_km <- st_coordinates(st_centroid(st_transform(blocks, 32644))) / 1000
set.seed(5)
sc <- ___(coords = cen_km, ___ = blocks$dengue_cases, pop = blocks$population, nsim = 499, alpha = 0.05)
summary(sc)

# Q8. What does the scan statistic report that LISA does not?

# ── Task 9 ──────────────────────────────────────────────────────
# Goal: Which blocks are in the most likely cluster? Show their names.
in_cluster <- sc$clusters[[1]]$___
head(blocks$block_id[in_cluster])
length(in_cluster)
