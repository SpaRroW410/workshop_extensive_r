# ═══════════════════════════════════════════════════════════════
# build_labs.R — generate the STUDENT labs from the facilitator solutions.
#
# The solutions in solutions/ are the single source of truth (they run
# end-to-end). In them:
#   code  #@ piece1 || piece2    -> in the lab, the FIRST occurrence of each
#                                    piece on that line becomes  ___
#   #% any text                  -> facilitator-only line, dropped from the lab
#
# Usage (from repo root):  Rscript counts-workshop/build_labs.R
# ═══════════════════════════════════════════════════════════════
base <- if (dir.exists("counts-workshop")) "counts-workshop" else "."
files <- list.files(file.path(base, "solutions"), pattern = "_solution\\.R$", full.names = TRUE)

blank_line <- function(line) {
  if (!grepl("#@", line, fixed = TRUE)) return(list(line = line, blanks = character(0)))
  parts <- strsplit(line, "#@", fixed = TRUE)[[1]]
  code  <- parts[1]
  pieces <- trimws(strsplit(paste(parts[-1], collapse = "#@"), "||", fixed = TRUE)[[1]])
  for (p in pieces) {
    pos <- regexpr(p, code, fixed = TRUE)
    if (pos < 0) stop("Blank piece not found on line: ", line, " -> '", p, "'")
    code <- paste0(substr(code, 1, pos - 1), "___", substr(code, pos + attr(pos, "match.length"), nchar(code)))
  }
  list(line = sub("\\s+$", "", code), blanks = pieces)
}

for (f in files) {
  lines <- readLines(f, warn = FALSE)
  lines <- lines[!grepl("^\\s*#%", lines)]
  out <- character(0); n_blank <- 0
  for (ln in lines) {
    r <- blank_line(ln); out <- c(out, r$line); n_blank <- n_blank + length(r$blanks)
  }
  lab <- file.path(base, "labs", sub("_solution\\.R$", ".R", basename(f)))
  writeLines(out, lab)
  cat(sprintf("%-28s -> %-22s %d blanks\n", basename(f), basename(lab), n_blank))
}
