# Runs every facilitator solution end to end (console-friendly tables, plots to a null device).
# Usage (repo root):  Rscript regression-workshop/run_solutions.R [lab-number ...]
options(width = 110)
registerS3method("print", "gtsummary", function(x, ...) { print(as.data.frame(gtsummary::as_tibble(x, col_labels = FALSE)), right = FALSE); invisible(x) }, envir = asNamespace("gtsummary"))
base  <- if (dir.exists("regression-workshop")) "regression-workshop" else "."
args  <- commandArgs(trailingOnly = TRUE)
files <- sort(list.files(file.path(base, "solutions"), pattern = "_solution\\.R$", full.names = TRUE))
if (length(args)) files <- files[grepl(paste0("lab(", paste(args, collapse = "|"), ")_"), basename(files))]
pdf(NULL)
for (f in files) {
  cat("\n▶▶▶ ", basename(f), "\n", sep = "")
  res <- tryCatch({ source(f, local = new.env(), echo = FALSE, print.eval = TRUE); "OK" },
                  error = function(e) paste("ERROR:", conditionMessage(e)))
  cat("◀◀◀ ", basename(f), ": ", res, "\n", sep = "")
  if (res != "OK") quit(status = 1)
}
cat("\nAll solutions ran without errors.\n")
