# Shared setup for the six decks + cheat sheet (labs carry their own inline copy
# of this block so each lab stays a standalone script).
suppressPackageStartupMessages({
  library(tidyverse)
  library(gtsummary)
  library(broom)
  library(performance)
  library(see)
  library(car)
  library(lmtest)
  library(pROC)
})

csv_path <- c("data/ncd_survey.csv", "../data/ncd_survey.csv", "../../data/ncd_survey.csv")
csv_path <- csv_path[file.exists(csv_path)][1]

ncd <- read_csv(csv_path, show_col_types = FALSE) |>
  mutate(
    sex       = factor(sex, levels = c("Female", "Male")),
    residence = factor(residence, levels = c("Urban", "Rural")),
    education = factor(education, levels = c("No schooling", "Primary", "Secondary", "Graduate+")),
    tobacco   = factor(tobacco, levels = c("No", "Yes")),
    alcohol   = factor(alcohol, levels = c("No", "Yes")),
    phys_act  = factor(phys_act, levels = c("low", "moderate", "high")),
    htn_f     = factor(htn, levels = 0:1, labels = c("No HTN", "HTN")),
    age50     = factor(if_else(age >= 50, "50+ y", "<50 y"), levels = c("<50 y", "50+ y"))
  )

# complete cases for every model that uses the full covariate set
cc <- ncd |> drop_na(sbp, salt_g, age, bmi, sex, residence, education, tobacco, alcohol, phys_act)

theme_set(theme_minimal(base_size = 16))
suppressMessages(invisible(theme_gtsummary_compact(set_theme = TRUE)))
col_blue <- "#3498db"; col_red <- "#e74c3c"; col_navy <- "#2c3e50"; col_green <- "#27ae60"
