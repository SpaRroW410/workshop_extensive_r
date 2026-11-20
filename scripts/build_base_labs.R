# ═══════════════════════════════════════════════════════════════
# build_base_labs.R — generate the student labs of the BASE modules (outside the workshops)
# from their facilitator solutions, exactly like each workshop's build_labs.R:
#   labs/<track>/solutions/<name>_solution.R   ->   labs/<track>/<name>.R
# In a solution:
#   code  #@ piece1 || piece2    -> the FIRST occurrence of each piece on that line becomes ___
#   #% any text                  -> facilitator-only line (answers), dropped from the lab
# Usage (repo root):  Rscript scripts/build_base_labs.R
# ═══════════════════════════════════════════════════════════════
files <- sort(Sys.glob("labs/*/solutions/*_solution.R"))

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
  for (ln in lines) { r <- blank_line(ln); out <- c(out, r$line); n_blank <- n_blank + length(r$blanks) }
  lab <- file.path(dirname(dirname(f)), sub("_solution\\.R$", ".R", basename(f)))
  writeLines(out, lab)
  cat(sprintf("%-40s -> %-34s %d blanks\n", f, lab, n_blank))
}
