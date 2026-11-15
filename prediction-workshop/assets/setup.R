# Shared setup for the five decks + cheat sheet (labs carry their own inline copy so each lab stays a standalone script).
suppressPackageStartupMessages({ library(tidyverse); library(pROC); library(glmnet) })
theme_set(theme_minimal(base_size = 16))
rd <- function(f) { p <- c(file.path("data", f), file.path("..", "data", f), file.path("..", "..", "data", f)); read_csv(p[file.exists(p)][1], show_col_types = FALSE) |> mutate(sex = factor(sex)) }
dev <- rd("diabetes_dev.csv"); val <- rd("diabetes_valid.csv")
f_true <- diabetes ~ age + sex + bmi + waist + fam_history + hypertension + activity + smoker
f_all  <- update(f_true, . ~ . + m1 + m2 + m3 + m4 + m5 + m6 + m7 + m8 + m9 + m10)
auc_of <- function(y, p) as.numeric(pROC::auc(y, p, quiet = TRUE))
col_blue <- "#3498db"; col_red <- "#e74c3c"; col_navy <- "#2c3e50"; col_green <- "#27ae60"
