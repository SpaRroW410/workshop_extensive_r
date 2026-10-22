#!/usr/bin/env Rscript
# Regenerate _quarto-<profile>.yml from curriculum.yml.
#   Rscript scripts/build_profiles.R           write the files
#   Rscript scripts/build_profiles.R --check   only verify they are up to date (exit 1 if not)
suppressMessages(library(yaml))

args  <- commandArgs(trailingOnly = TRUE)
check <- "--check" %in% args
cur   <- read_yaml("curriculum.yml")

item <- function(i, prof) {
  if (is.character(i) && i == "---") return(list(text = "---"))
  path <- if (is.character(i)) i else i$path
  title <- cur$pages[[path]]$title
  if (is.null(title)) stop(sprintf("[%s] '%s' is not listed under pages:", prof, path), call. = FALSE)
  if (!file.exists(path)) stop(sprintf("[%s] '%s' does not exist", prof, path), call. = FALSE)
  list(text = if (is.list(i) && !is.null(i$text)) i$text else title, href = path)
}

tidy <- function(items) {
  # drop leading, trailing and doubled separators
  is_sep <- vapply(items, function(i) identical(i$text, "---"), logical(1))
  keep <- rep(TRUE, length(items))
  for (k in seq_along(items)) if (is_sep[k] && (k == 1 || k == length(items) || is_sep[k - 1] || all(is_sep[k:length(items)]))) keep[k] <- FALSE
  items[keep]
}

entry <- function(m, prof) {
  e <- list(text = m$text)
  if (!is.null(m$icon)) e$icon <- m$icon
  if (!is.null(m$href)) e$href <- m$href
  if (!is.null(m$items)) e$menu <- tidy(lapply(m$items, item, prof = prof))
  if (is.null(m$href) && length(e$menu) == 0) return(NULL)   # empty menu: drop the entry
  e
}

build <- function(prof) {
  p <- cur$profiles[[prof]]
  # as.list(): keep one-element render/resources lists as YAML sequences (Quarto rejects a bare string there)
  proj <- c(list(`output-dir` = p$`output-dir`), lapply(p$`project-extra`, as.list))
  list(
    project = proj,
    website = list(
      title = p$title, `site-url` = ".", search = TRUE,
      navbar = list(
        `logo-href` = p$`logo-href`,
        left  = Filter(Negate(is.null), lapply(p$left,  entry, prof = prof)),
        right = Filter(Negate(is.null), lapply(p$right, entry, prof = prof))
      )
    )
  )
}

header <- function(prof) c(
  "# ═══════════════════════════════════════════════════════════════",
  sprintf("# _quarto-%s.yml — GENERATED from curriculum.yml. DO NOT EDIT BY HAND.", prof),
  "# Edit curriculum.yml, then run:  Rscript scripts/build_profiles.R",
  sprintf("# Render with:  quarto render --profile %s", prof),
  "# ═══════════════════════════════════════════════════════════════", "")

bad <- character()
for (prof in names(cur$profiles)) {
  new  <- build(prof)
  file <- sprintf("_quarto-%s.yml", prof)
  body <- as.yaml(new, indent.mapping.sequence = TRUE, line.sep = "\n")
  # as.yaml writes TRUE as 'yes'; Quarto reads either, but keep it explicit
  body <- gsub("(?m): yes$", ": true", body, perl = TRUE)
  body <- gsub("(?m): no$", ": false", body, perl = TRUE)
  text <- c(header(prof), strsplit(body, "\n", fixed = TRUE)[[1]], "")   # same bytes as writeLines(c(header, body))
  same <- file.exists(file) && identical(readLines(file, encoding = "UTF-8", warn = FALSE), enc2utf8(text))
  if (check) {
    if (!same) bad <- c(bad, prof)
  } else {
    if (!same) writeLines(text, file, useBytes = TRUE)
    cat(sprintf("%-18s %s\n", prof, if (same) "unchanged" else "written"))
  }
}
if (check) {
  if (length(bad)) { cat("Out of date:", paste(bad, collapse = ", "), "\n"); quit(status = 1) }
  cat("All profile files match curriculum.yml\n")
}

# Coverage: which profiles show each page
if (!check) {
  prof_pages <- lapply(cur$profiles, function(p) {
    unlist(lapply(c(p$left, p$right), function(m)
      c(m$href, vapply(m$items, function(i) if (is.character(i)) i else i$path, ""))))
  })
  unused <- setdiff(names(cur$pages), unique(unlist(prof_pages)))
  if (length(unused)) cat("Pages listed but in no profile menu:", paste(unused, collapse = ", "), "\n")
}
