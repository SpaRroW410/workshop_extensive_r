# Runs every base-module facilitator solution end to end, from the repository root.
# Usage:  Rscript scripts/run_base_labs.R [pattern]
options(width = 110)
if (requireNamespace("gtsummary", quietly = TRUE))
  registerS3method("print", "gtsummary", function(x, ...) { print(as.data.frame(gtsummary::as_tibble(x, col_labels = FALSE)), right = FALSE); invisible(x) }, envir = asNamespace("gtsummary"))
args  <- commandArgs(trailingOnly = TRUE)
files <- sort(Sys.glob("labs/*/solutions/*_solution.R"))
if (length(args)) files <- files[grepl(args[1], files)]
pdf(NULL)
for (f in files) {
  cat("\n▶▶▶ ", f, "\n", sep = "")
  res <- tryCatch({ source(f, local = new.env(), echo = FALSE, print.eval = TRUE); "OK" },
                  error = function(e) paste("ERROR:", conditionMessage(e)))
  cat("◀◀◀ ", f, ": ", res, "\n", sep = "")
  if (res != "OK") quit(status = 1)
}
cat("\nAll base-module solutions ran without errors.\n")
