# Shared setup for the five decks + cheat sheet (labs carry their own inline copy so each lab stays a standalone script).
suppressPackageStartupMessages({ library(tidyverse); library(splines); library(mgcv); library(emmeans) })
theme_set(theme_minimal(base_size = 16))
p <- c("data/ncd_curves.csv", "../data/ncd_curves.csv", "../../data/ncd_curves.csv"); p <- p[file.exists(p)][1]
ncd <- read_csv(p, show_col_types = FALSE) |> mutate(sex = factor(sex), smoker_f = factor(smoker, labels = c("Non-smoker", "Smoker")))
col_blue <- "#3498db"; col_red <- "#e74c3c"; col_navy <- "#2c3e50"; col_green <- "#27ae60"
