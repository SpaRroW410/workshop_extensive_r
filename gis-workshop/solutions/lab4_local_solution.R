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
loc <- localmoran(blocks$dengue_per_100k, lw, zero.policy = TRUE)   #@ localmoran
head(round(loc, 3))

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Check that the average of the local values equals the global I.
mean(loc[, "Ii"])                                                   #@ Ii
unname(moran.test(blocks$dengue_per_100k, lw, zero.policy = TRUE)$estimate[1])
#% A (Q2): they are equal (about 0.50): the global statistic is the average of the local ones.

# Q2. How are the local and global Moran's I related?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Take the p-value column and count the blocks with p < 0.05.
p <- loc[, "Pr(z != E(Ii))"]                                        #@ Pr(z != E(Ii))
sum(p < 0.05)                                                       #@ 0.05
#% A (Q3): about 22 blocks.

# Q3. Roughly how many of 79 blocks would be "significant" by chance alone at 5%?

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Classify each block as High-High, Low-Low, High-Low, Low-High or
# Not significant, using the standardised value, its lag and p < 0.05.
z <- as.numeric(scale(blocks$dengue_per_100k))
lag_z <- lag.listw(lw, z, zero.policy = TRUE)
blocks$lisa <- case_when(p >= 0.05 ~ "Not significant",
                         z > 0 & lag_z > 0 ~ "High-High", z < 0 & lag_z < 0 ~ "Low-Low",   #@ High-High || Low-Low
                         z > 0 & lag_z < 0 ~ "High-Low", TRUE ~ "Low-High")
table(blocks$lisa)

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Map the LISA classes.
ggplot(blocks) + geom_sf(aes(fill = lisa), colour = "white") +      #@ lisa
  scale_fill_manual(values = c("High-High" = "#d7191c", "Low-Low" = "#2c7bb6", "High-Low" = "#fdae61", "Low-High" = "#abd9e9", "Not significant" = "grey90"))
#% A (Q5): a hot spot in the south-east, a cold spot in the north-west and one High-Low outlier inside the cold area.

# Q5. Where are the hot spots, the cold spots and the spatial outliers?

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Adjust the 79 p-values for multiple testing with the false
# discovery rate and count what is left.
p_adj <- p.adjust(p, method = "fdr")                                #@ p.adjust || fdr
sum(p_adj < 0.05)
#% A (Q6): fewer blocks survive (about 13): LISA is exploratory.

# Q6. Why adjust, and what happened to the number of significant blocks?

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Getis-Ord Gi*: include each block in its own neighbourhood, use
# binary weights and compute the z-scores.
lw_self <- nb2listw(include.self(nb), style = "B", zero.policy = TRUE)   #@ include.self
blocks$gi <- as.numeric(localG(blocks$dengue_per_100k, lw_self, zero.policy = TRUE))   #@ localG
sum(blocks$gi > 1.96); sum(blocks$gi < -1.96)
#% A (Q7): hot-spot blocks (z > 1.96) are in the south-east; cold-spot blocks (z < -1.96) in the north-west.

# Q7. How does Gi* differ from the LISA classification?

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Run the Kulldorff spatial scan statistic. It needs centroid
# coordinates in km, the case counts and the populations.
cen_km <- st_coordinates(st_centroid(st_transform(blocks, 32644))) / 1000
set.seed(5)
sc <- scan.test(coords = cen_km, cases = blocks$dengue_cases, pop = blocks$population, nsim = 499, alpha = 0.05)   #@ scan.test || cases
summary(sc)
#% A (Q8): one significant cluster of about 34 blocks with relative risk about 1.8 and p < 0.01.

# Q8. What does the scan statistic report that LISA does not?

# ── Task 9 ──────────────────────────────────────────────────────
# Goal: Which blocks are in the most likely cluster? Show their names.
in_cluster <- sc$clusters[[1]]$locids                               #@ locids
head(blocks$block_id[in_cluster])
length(in_cluster)
