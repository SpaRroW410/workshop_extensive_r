# Shared setup for the GIS pages (sourced by each page; keep pages runnable on their own).
suppressPackageStartupMessages({ library(tidyverse); library(sf); library(spdep) })
sf_use_s2(FALSE)                      # planar geometry: simple and fast for a small synthetic district
theme_set(theme_minimal(base_size = 14))
.p <- function(f) c(file.path("data/gis", f), file.path("../data/gis", f))
blocks <- st_read(.p("district_blocks.geojson")[file.exists(.p("district_blocks.geojson"))][1], quiet = TRUE)
facilities <- read_csv(.p("facilities.csv")[file.exists(.p("facilities.csv"))][1], show_col_types = FALSE)
blocks$high_burden <- factor(blocks$high_burden, levels = c("Not high", "High"))
nb <- poly2nb(blocks, queen = TRUE, snap = 1e-4)                    # queen contiguity
lw <- nb2listw(nb, style = "W", zero.policy = TRUE)                 # row-standardised weights
