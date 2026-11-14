# Shared setup for the five decks + cheat sheet (labs carry their own inline copy so each lab stays a standalone script).
suppressPackageStartupMessages({ library(tidyverse); library(dagitty); library(MatchIt); library(cobalt); library(sandwich); library(lmtest); library(EValue) })
theme_set(theme_minimal(base_size = 16))
p <- c("data/htn_programme.csv", "../data/htn_programme.csv", "../../data/htn_programme.csv"); p <- p[file.exists(p)][1]
htn <- read_csv(p, show_col_types = FALSE) |> mutate(sex = factor(sex), education = factor(education, levels = c("None", "Primary", "Secondary+")))
f_out <- sbp_12m ~ programme + age + sex + education + urban + bmi + diabetes + baseline_sbp       # outcome model with the confounders
f_ps  <- programme ~ age + sex + education + urban + bmi + diabetes + baseline_sbp                 # propensity-score model
col_blue <- "#3498db"; col_red <- "#e74c3c"; col_navy <- "#2c3e50"; col_green <- "#27ae60"
