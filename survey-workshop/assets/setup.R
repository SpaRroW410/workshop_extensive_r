# Shared setup for the five decks + cheat sheet (labs carry their own inline copy so each lab stays a standalone script).
suppressPackageStartupMessages({ library(tidyverse); library(survey); library(srvyr) })
theme_set(theme_minimal(base_size = 16))
options(survey.lonely.psu = "adjust")
p <- c("data/survey_adults.csv", "../data/survey_adults.csv", "../../data/survey_adults.csv"); p <- p[file.exists(p)][1]
adults <- read_csv(p, show_col_types = FALSE)
resp <- adults |> filter(responded == 1) |> mutate(across(c(region, residence, sex), factor), education = factor(education, levels = c("None", "Primary", "Secondary+")),
  age_grp = cut(age, c(17, 29, 44, 59, 120), labels = c("18-29", "30-44", "45-59", "60+")))
des <- svydesign(ids = ~psu, strata = ~stratum, weights = ~weight, data = resp, nest = TRUE)
col_blue <- "#3498db"; col_red <- "#e74c3c"; col_navy <- "#2c3e50"; col_green <- "#27ae60"
