# Shared setup for the five decks + cheat sheet (labs carry their own inline copy so each lab stays a standalone script).
suppressPackageStartupMessages({ library(tidyverse); library(mice); library(naniar) })
theme_set(theme_minimal(base_size = 16))
p <- c("data/ncd_missing.csv", "../data/ncd_missing.csv", "../../data/ncd_missing.csv"); p <- p[file.exists(p)][1]
ncd <- read_csv(p, show_col_types = FALSE) |> mutate(sex = factor(sex), education = factor(education, levels = c("None", "Primary", "Secondary+")))
dat <- ncd |> select(-id)                          # the id must not enter the imputation model
col_blue <- "#3498db"; col_red <- "#e74c3c"; col_navy <- "#2c3e50"; col_green <- "#27ae60"
