# ═══════════════════════════════════════════════════════════════
# make_gis_data.R — synthetic district for the GIS track (no real boundaries, no real people)
# Rscript gis/make_gis_data.R        (run from the repository root; seed fixed)
# Writes: data/gis/district_blocks.geojson   ~80 block polygons (Voronoi cells inside a district outline), WGS84
#         data/gis/facilities.csv            30 health facilities (easting_m, northing_m in UTM 44N)
# Built-in structure (checked below; the script stops if a teaching feature is lost):
#   * dengue incidence is positively spatially autocorrelated (global Moran's I clearly > 0)
#   * a HOT SPOT in the south-east, a COLD SPOT in the north-west, one spatial OUTLIER (high block inside a cold area)
#   * poverty_index is smooth in space and explains part of incidence; residuals keep some autocorrelation
# ═══════════════════════════════════════════════════════════════
suppressMessages({ library(sf); library(dplyr); library(spdep) })
set.seed(2026)
# Coordinates are metres in UTM zone 44N (EPSG:32644), placed near 26.7°N 80°E; the shape and everything in it is invented.
x0 <- 420000; y0 <- 2950000
outline <- st_polygon(list(sweep(rbind(c(5, 0), c(95, 4), c(100, 55), c(92, 100), c(40, 96), c(0, 70), c(5, 0)) * 1000, 2, c(x0, y0), "+"))) |> st_sfc(crs = 32644)
pts <- st_sample(outline, 80, type = "hexagonal") |> st_cast("POINT")
pts <- pts[seq_len(min(80, length(pts)))]
# slightly jitter so cells are irregular but still tile the outline
xy <- st_coordinates(pts)
pts <- st_sfc(lapply(seq_len(nrow(xy)), function(i) st_point(c(xy[i, 1] + rnorm(1, 0, 2200), xy[i, 2] + rnorm(1, 0, 2200)))), crs = 32644)
vor <- st_voronoi(st_union(pts), envelope = st_bbox(c(xmin = x0 - 20000, ymin = y0 - 20000, xmax = x0 + 120000, ymax = y0 + 120000), crs = 32644) |> st_as_sfc()) |>
  st_collection_extract("POLYGON") |> st_sfc(crs = 32644)
cells <- st_intersection(st_sf(geometry = vor), st_sf(geometry = outline)) |> st_cast("POLYGON") |> st_make_valid()
cells <- cells[st_geometry_type(cells) == "POLYGON", ]
cells <- cells[order(st_coordinates(st_centroid(cells))[, 2], decreasing = TRUE), ]      # north to south
blk <- cells |> mutate(block_id = sprintf("B%02d", row_number()))
cen <- st_coordinates(st_centroid(blk)); x <- (cen[, 1] - x0) / 1000; y <- (cen[, 2] - y0) / 1000     # km from the district's south-west corner

# smooth spatial surfaces on the centroids
smooth <- function(f) as.numeric(scale(f))
poverty <- smooth(0.012 * (100 - y) + 0.006 * x + rnorm(nrow(blk), 0, 0.16))
hot  <- exp(-((x - 78)^2 + (y - 25)^2) / (2 * 14^2))           # south-east hot spot
cold <- exp(-((x - 22)^2 + (y - 78)^2) / (2 * 14^2))           # north-west cold spot
w0 <- poly2nb(blk, queen = TRUE, snap = 1); lw0 <- nb2listw(w0, style = "W", zero.policy = TRUE)
noise <- as.numeric(scale(lag.listw(lw0, rnorm(nrow(blk)))))     # spatially smoothed noise
lat <- 0.35 * poverty + 1.1 * hot - 1.0 * cold + 0.35 * noise + rnorm(nrow(blk), 0, 0.12)
out_i <- which.min(abs(x - 22) + abs(y - 78))                  # a block in the middle of the cold spot...
nb_out <- w0[[out_i]]; target <- nb_out[1]
lat[target] <- lat[target] + 2.4                                # ...made unusually high: a spatial outlier (HL)
pop <- round(runif(nrow(blk), 9000, 42000), -2)
rate <- exp(log(40) + 0.55 * lat)                               # dengue per 100,000
cases <- rpois(nrow(blk), rate * pop / 1e5)
blk <- blk |> mutate(
  block_name = paste("Block", block_id), district = case_when(y >= 50 & x < 50 ~ "North-West", y >= 50 ~ "North-East", x < 50 ~ "South-West", TRUE ~ "South-East"),
  population = pop, poverty_index = round(50 + 12 * poverty, 1), literacy_pct = round(pmin(98, pmax(40, 78 - 6 * poverty + rnorm(n(), 0, 4))), 1),
  dengue_cases = cases, dengue_per_100k = round(1e5 * cases / pop, 1),
  high_burden = if_else(dengue_per_100k >= quantile(dengue_per_100k, 0.7), "High", "Not high"),
  area_km2 = round(as.numeric(st_area(geometry)) / 1e6, 1))
blk <- blk |> st_transform(4326) |> select(block_id, block_name, district, population, poverty_index, literacy_pct, area_km2, dengue_cases, dengue_per_100k, high_burden)
dir.create("data/gis", showWarnings = FALSE, recursive = TRUE)
if (file.exists("data/gis/district_blocks.geojson")) file.remove("data/gis/district_blocks.geojson")
st_write(blk, "data/gis/district_blocks.geojson", quiet = TRUE)

fp <- st_sample(outline, 30) |> st_coordinates()
fac <- tibble(facility_id = sprintf("F%02d", 1:30), type = sample(c("PHC", "CHC", "Sub-centre"), 30, TRUE, prob = c(.4, .2, .4)),
              easting_m = round(fp[, 1]), northing_m = round(fp[, 2]))      # UTM 44N metres: use st_as_sf(coords = c("easting_m", "northing_m"), crs = 32644)
write.csv(fac, "data/gis/facilities.csv", row.names = FALSE)

# ── feature check ──
b <- st_read("data/gis/district_blocks.geojson", quiet = TRUE); nb <- poly2nb(b, snap = 1e-4); lw <- nb2listw(nb, style = "W", zero.policy = TRUE)
mi <- moran.test(b$dengue_per_100k, lw, zero.policy = TRUE); I <- unname(mi$estimate[1])
cat(sprintf("blocks: %d | isolates: %d | mean neighbours: %.1f | Moran's I = %.2f (p = %.4f)\n", nrow(b), sum(card(nb) == 0), mean(card(nb)), I, mi$p.value))
loc <- localmoran(b$dengue_per_100k, lw, zero.policy = TRUE)
stopifnot(nrow(b) >= 60, sum(card(nb) == 0) == 0, I > 0.25, mi$p.value < 0.01, sum(loc[, "Pr(z != E(Ii))"] < 0.05) >= 6)
cat("feature check passed\n")
