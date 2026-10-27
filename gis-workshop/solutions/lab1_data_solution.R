# ═══════════════════════════════════════════════════════════════
# LAB 1 — Spatial data, coordinate systems and maps
# GIS and Spatial Statistics workshop | Session 1
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
# Goal: Show the class of the object. Which two classes does an sf object have?
class(blocks)                                                       #@ class
#% A (Q1): "sf" and "data.frame" (plus tbl for some readers): an sf object is a data frame with a geometry column.

# Q1. Which classes does `blocks` have, and what is special about it compared with a plain data frame?

# ── Task 2 ──────────────────────────────────────────────────────
# Goal: Print the coordinate reference system of blocks (name and EPSG).
st_crs(blocks)$input                                                #@ st_crs
#% A (Q2): WGS 84 (EPSG:4326): longitude and latitude in degrees.

# Q2. Is this a geographic or a projected CRS? Would you measure areas in it?

# ── Task 3 ──────────────────────────────────────────────────────
# Goal: Transform blocks to the projected UTM zone 44N system (EPSG 32644).
blocks_utm <- st_transform(blocks, 32644)                           #@ st_transform || 32644
st_crs(blocks_utm)$input

# ── Task 4 ──────────────────────────────────────────────────────
# Goal: Compute each block's area in square kilometres from the geometry
# (use the projected version). Store it as area_calc.
blocks_utm$area_calc <- as.numeric(st_area(blocks_utm)) / 1e6       #@ st_area || 1e6
summary(round(blocks_utm$area_calc - blocks_utm$area_km2, 1))
#% A (Q4): differences are about 0: the recorded area_km2 was computed the same way. In degrees the numbers would be meaningless.

# Q4. Why must you transform to a projected CRS before calling st_area() or st_distance()?

# ── Task 5 ──────────────────────────────────────────────────────
# Goal: Keep only the blocks of the "South-East" district and count them.
se <- blocks |> filter(district == "South-East")                    #@ filter || South-East
nrow(se)                                                            #@ nrow
#% A: 22 blocks in the South-East district.

# ── Task 6 ──────────────────────────────────────────────────────
# Goal: Draw a choropleth of dengue cases per 100,000 (dengue_per_100k)
# using a sequential colour scale.
ggplot(blocks) +
  geom_sf(aes(fill = dengue_per_100k)) +                            #@ geom_sf || dengue_per_100k
  scale_fill_viridis_c(name = "per 100,000")

# ── Task 7 ──────────────────────────────────────────────────────
# Goal: Draw the same map for the raw COUNT of cases (dengue_cases) and
# compare it with the rate map.
ggplot(blocks) +
  geom_sf(aes(fill = dengue_cases)) +                               #@ dengue_cases
  scale_fill_viridis_c(name = "cases")
#% A (Q7): the count map is driven by population size; populous blocks look bad even at average risk. Map rates for risk.

# Q7. Which map is better for judging risk, and why?

# ── Task 8 ──────────────────────────────────────────────────────
# Goal: Turn the facilities table into an sf object of points. Its
# coordinates are in columns easting_m and northing_m, in UTM zone 44N.
fac_path <- sub("district_blocks.geojson", "facilities.csv", geo_path, fixed = TRUE)
fac <- read_csv(fac_path, show_col_types = FALSE) |>
  st_as_sf(coords = c("easting_m", "northing_m"), crs = 32644)      #@ st_as_sf || crs
nrow(fac)

# ── Task 9 ──────────────────────────────────────────────────────
# Goal: Count the facilities inside each block (zero where there are none)
# and show how many blocks have no facility.
blocks_utm$n_fac <- lengths(st_intersects(blocks_utm, fac))         #@ lengths || st_intersects
table(blocks_utm$n_fac)
sum(blocks_utm$n_fac == 0)

# ── Task 10 ─────────────────────────────────────────────────────
# Goal: Distance (km) from each block centroid to its NEAREST facility.
cen <- st_centroid(blocks_utm)
blocks_utm$km_to_fac <- apply(st_distance(cen, fac), 1, min) / 1000 #@ st_distance || min
summary(round(blocks_utm$km_to_fac, 1))
