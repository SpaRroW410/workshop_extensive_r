# Regenerates the extra practice files used by Region 1 tasks (from data/ncd_survey.csv; seed documented).
# Rscript dungeons/make_data_region1.R   (run from the repository root)
suppressMessages({ library(readr); library(dplyr) })
ncd <- read_csv("data/ncd_survey.csv", show_col_types = FALSE)
set.seed(2026)
villages <- tibble(village = sprintf("V%02d", 1:20), district = rep(c("North", "South", "East", "West"), each = 5),
                   distance_to_phc_km = round(runif(20, 1, 25), 1)) |>
  mutate(phc_in_village = if_else(distance_to_phc_km < 8, "Yes", "No"))
stopifnot(setequal(villages$village, ncd$village))
write_csv(villages, "data/villages.csv")
write_csv(slice(ncd, 1:300), "data/ncd_round1.csv")       # survey round 1: same columns as round 2, different people
write_csv(slice(ncd, 301:600), "data/ncd_round2.csv")
