#!/usr/bin/env Rscript
# Regenerate _quarto-<profile>.yml from curriculum.yml.
#   Rscript scripts/build_profiles.R           write the files
#   Rscript scripts/build_profiles.R --check   only verify they are up to date (exit 1 if not)
suppressMessages(library(yaml))
suppressMessages(library(jsonlite))

args  <- commandArgs(trailingOnly = TRUE)
check <- "--check" %in% args
# curriculum.yml has non-ASCII titles; in a non-UTF-8 locale R stops reading at the first one.
if (!l10n_info()$`UTF-8`) invisible(suppressWarnings(Sys.setlocale("LC_CTYPE", "C.UTF-8")))
cur   <- read_yaml("curriculum.yml", fileEncoding = "UTF-8")

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

# ── Which pages each track renders ────────────────────────────────────────────
# A track renders ONLY: the pages every track has (SHARED), the pages in its own menus, and its
# project-extra render globs. (Until 2026-11-20 every shared page was rendered into every track, so the
# free Basic site served all of Moderate's pages too.) A link to a page another track owns is pointed
# into that track by _filters/crosstrack.lua, using _filters/pages.json written below.
SHARED <- c("index.qmd", "welcome.qmd", "contact.qmd", "downloads.qmd", "references.qmd")
# The track a page "belongs to" when several render it: the first one in this order (cheapest first).
HOME_ORDER <- c("basic", "moderate", "regression", "dataviz-base", "dataviz-complete", "gis", "advanced", "dungeons")

menu_paths <- function(p) {
  x <- unlist(lapply(c(p$left, p$right), function(m)
    c(m$href, vapply(m$items, function(i) if (is.character(i)) i else i$path, ""))))
  unique(setdiff(x, "---"))
}
extra_globs <- function(p) as.character(unlist(p$`project-extra`$render))
glob <- function(g) if (length(g)) Sys.glob(g) else character()
sorted <- function(x) sort(unique(x), method = "radix")
# Sub-decks: .qmd files that a menu page links to but that are not themselves listed in curriculum.yml
# (the plot-gallery hubs link to 18 decks). A track renders the sub-decks of its own menu pages, so the
# hub's links work. Before 2026-11-20 they were rendered nowhere and every gallery link was dead.
sub_pages <- function(paths) {
  out <- character()
  for (p in paths) {
    if (!file.exists(p)) next
    txt <- paste(readLines(p, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    links <- regmatches(txt, gregexpr("\\]\\(([^)#[:space:]]+\\.qmd)", txt))[[1]]
    links <- sub("^\\]\\(", "", links)
    for (l in links) {
      tgt <- normalizePath(file.path(dirname(p), l), mustWork = FALSE)
      tgt <- sub(paste0("^", normalizePath("."), "/"), "", tgt)
      if (file.exists(tgt) && !tgt %in% names(cur$pages) && !tgt %in% SHARED) out <- c(out, tgt)
    }
  }
  sorted(out)
}
pages_of <- function(p) sorted(c(SHARED, menu_paths(p), sub_pages(menu_paths(p)), glob(extra_globs(p))))

build <- function(prof) {
  p <- cur$profiles[[prof]]
  # as.list(): keep one-element render/resources lists as YAML sequences (Quarto rejects a bare string there)
  extra <- p$`project-extra`
  globbed <- glob(extra_globs(p))
  extra$render <- c(extra_globs(p), sorted(setdiff(c(menu_paths(p), sub_pages(menu_paths(p))), c(SHARED, globbed))))
  proj <- c(list(`output-dir` = p$`output-dir`), lapply(extra, as.list))
  list(
    project = proj,
    website = list(
      title = p$title, `site-url` = ".", search = TRUE,
      navbar = list(
        `logo-href` = p$`logo-href`,
        left  = Filter(Negate(is.null), lapply(p$left,  entry, prof = prof)),
        right = Filter(Negate(is.null), lapply(p$right, entry, prof = prof))
      )
    ),
    # Marks a page as rendered inside a track site. index.qmd uses it (when-meta) to show a
    # redirect to the track home instead of a second copy of the landing page with dead links.
    `ws-track` = TRUE
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
# Page lists for _filters/crosstrack.lua
profiles <- setNames(lapply(names(cur$profiles), function(pr) pages_of(cur$profiles[[pr]])), names(cur$profiles))
home <- list()
for (pr in intersect(HOME_ORDER, names(profiles))) for (pg in profiles[[pr]]) if (is.null(home[[pg]]) && !pg %in% SHARED) home[[pg]] <- pr
home <- lapply(home[sorted(names(home))], unbox)   # plain strings, not one-element arrays
pj <- toJSON(list(profiles = profiles, home = home), auto_unbox = FALSE, pretty = TRUE)
pj <- sub('"home": \\[\\]', '"home": {}', pj)
pj_lines <- c(strsplit(as.character(pj), "\n", fixed = TRUE)[[1]])
pj_file <- "_filters/pages.json"
pj_same <- file.exists(pj_file) && identical(readLines(pj_file, warn = FALSE), pj_lines)
if (check) { if (!pj_same) bad <- c(bad, pj_file) } else {
  if (!pj_same) writeLines(pj_lines, pj_file, useBytes = TRUE)
  cat(sprintf("%-18s %s\n", pj_file, if (pj_same) "unchanged" else "written"))
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
