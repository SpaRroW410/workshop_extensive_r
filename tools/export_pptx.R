# ═══════════════════════════════════════════════════════════════
# export_pptx.R — a custom deck as an EDITABLE PowerPoint (CUSTOM_DECKS_PLAN.md §4.2, phase C5)
#
#   Rscript tools/export_pptx.R my_deck.json [out.pptx]
#
# my_deck.json: "⬇ For PowerPoint" on the Custom decks page (/decks). Run from the repository root,
# with the workshop packages installed (the same as for the labs). Nothing here runs another user's
# code: workshop slides are re-run from the workshop's own source, and code on your own slides is
# only run if you add --run-own.
#
# What becomes what (all editable in PowerPoint):
#   slide title, text, bullets, callout boxes  -> text boxes (fonts and alignment of own slides kept)
#   pipe tables in the slide, data frames R prints -> real tables (flextable)
#   ggplot charts                               -> vector shapes (rvg): recolour a bar, change a label
#   base-R plots                                -> vector shapes (rvg)
#   other R output                              -> a monospaced text box; the code above it likewise
#   quiz questions                              -> the question and options; the answer in the notes
#   your notes, own slides' notes               -> the speaker-notes pane
# ═══════════════════════════════════════════════════════════════
suppressPackageStartupMessages({ library(officer); library(flextable); library(rvg); library(jsonlite) })

args <- commandArgs(trailingOnly = TRUE)
run_own <- "--run-own" %in% args
args <- setdiff(args, "--run-own")
if (!length(args)) stop("usage: Rscript tools/export_pptx.R my_deck.json [out.pptx] [--run-own]")
deck <- fromJSON(args[1], simplifyVector = FALSE)
if (!identical(deck$format, "medstats-custom-deck")) stop("not a custom-deck file from the Custom decks page")
out_file <- if (length(args) >= 2) args[2] else sub("\\.json$", ".pptx", args[1])
ROOT <- normalizePath(".")
if (!file.exists(file.path(ROOT, "slides.lock.json"))) stop("run this from the repository root")

# ── A 16:9 template (officer's default is 4:3) ────────────────────
template_16x9 <- function() {
  src <- system.file("template", "template.pptx", package = "officer")
  dir <- tempfile("tpl"); dir.create(dir)
  utils::unzip(src, exdir = dir)
  pres <- file.path(dir, "ppt", "presentation.xml")
  x <- readLines(pres, warn = FALSE)
  x <- gsub('<p:sldSz[^>]*/>', '<p:sldSz cx="12192000" cy="6858000"/>', x)
  writeLines(x, pres)
  out <- tempfile(fileext = ".pptx")
  zip::zip(out, files = list.files(dir, recursive = TRUE, all.files = TRUE), root = dir)
  out
}
W <- 13.333; H <- 7.5; M <- 0.5                      # inches
COL <- list(ink = "#2C3E50", muted = "#5F6B76", blue = "#1565C0", key = "#EAF2F8", warn = "#FDEDEC", eq = "#FEF9E7", code = "#F4F6F8")
FONTS <- list(deck = "Georgia", sans = "Source Sans 3", lato = "Lato", merriweather = "Merriweather")
MONO <- "Consolas"

# ── Reading a slide from its .qmd ─────────────────────────────────
slide_source <- function(workshop, deck_name, id) {
  lines <- readLines(file.path(ROOT, workshop, paste0(deck_name, ".qmd")), warn = FALSE)
  fence <- FALSE; yaml <- identical(lines[1], "---"); heads <- integer(0)
  for (i in seq_along(lines)) {
    l <- lines[i]
    if (yaml) { if (i > 1 && l == "---") yaml <- FALSE; next }
    if (grepl("^(```|~~~)", l)) { fence <- !fence; next }
    if (!fence && grepl("^#{1,2} ", l)) heads <- c(heads, i)
  }
  at <- heads[grepl(paste0("\\{#", gsub(".", "\\.", id, fixed = TRUE), "[ }]"), lines[heads])]
  if (!length(at)) return(NULL)
  end <- c(heads[heads > at[1]], length(lines) + 1)[1] - 1
  list(title = trimws(sub("\\s*\\{.*\\}\\s*$", "", sub("^#{1,2} ", "", lines[at[1]]))),
       body = if (end > at[1]) lines[(at[1] + 1):end] else character(0), all = lines, start = at[1])
}

# All R chunks of a deck, in order, with options (as scripts/webr_manifests.mjs reads them)
deck_chunks <- function(lines) {
  out <- list(); i <- 1
  while (i <= length(lines)) {
    m <- regmatches(lines[i], regexec("^(`{3,})\\{r([^}]*)\\}\\s*$", lines[i]))[[1]]
    if (length(m)) {
      j <- i + 1
      while (j <= length(lines) && trimws(lines[j]) != m[2]) j <- j + 1
      body <- if (j > i + 1) lines[(i + 1):(j - 1)] else character(0)
      opt <- regmatches(body, regexec("^#\\|\\s*([\\w.-]+):\\s*(.*?)\\s*$", body, perl = TRUE))
      opts <- list(); for (o in opt) if (length(o)) opts[[o[2]]] <- o[3]
      falsy <- function(v) !is.null(v) && grepl("^(false|FALSE|F)$", v)
      code <- body[!grepl("^#\\|", body)]
      out[[length(out) + 1]] <- list(start = i, end = j, code = paste(code, collapse = "\n"),
        visible = !falsy(opts$echo) && !falsy(opts$include), include = !falsy(opts$include), eval = !falsy(opts$eval),
        quiz = any(grepl("quiz_(mcq|fill)\\(", code)), fig_w = as.numeric(opts[["fig-width"]] %||% NA), fig_h = as.numeric(opts[["fig-height"]] %||% NA))
      i <- j + 1
    } else i <- i + 1
  }
  out
}
`%||%` <- function(a, b) if (is.null(a)) b else a

# ── Running a deck's code (setup once, chunks in order) ───────────
envs <- list()
deck_env <- function(workshop, deck_name) {
  key <- paste(workshop, deck_name, sep = "/")
  if (!is.null(envs[[key]])) return(envs[[key]])
  e <- new.env(parent = globalenv())
  e$quiz_mcq <- function(qid, question, options, answer, explain = "", ...) structure(list(type = "mcq", q = question, options = options, answer = answer, explain = explain), class = "st_quiz")
  e$quiz_fill <- function(qid, question, accept, explain = "", ...) structure(list(type = "fill", q = question, accept = accept, explain = explain), class = "st_quiz")
  lines <- readLines(file.path(ROOT, workshop, paste0(deck_name, ".qmd")), warn = FALSE)
  envs[[key]] <<- list(env = e, chunks = deck_chunks(lines), ran = 0L, dir = file.path(ROOT, workshop))
  envs[[key]]
}
in_dir <- function(dir, expr) { old <- setwd(dir); on.exit(setwd(old)); force(expr) }
eval_capture <- function(code, env, dir) {
  # Each top-level result: printed text, a ggplot, a data frame, a quiz, or a base plot.
  res <- list()
  exprs <- tryCatch(parse(text = code), error = function(e) NULL)
  if (is.null(exprs)) return(list(list(kind = "text", text = "(code could not be parsed)")))
  for (ex in exprs) {
    rec <- NULL
    pdf(NULL); dev.control("enable")
    vis <- tryCatch(in_dir(dir, withVisible(eval(ex, env))), error = function(e) list(value = e, visible = TRUE, error = TRUE))
    if (!is.null(vis$error)) { res[[length(res) + 1]] <- list(kind = "text", text = paste("Error:", conditionMessage(vis$value))); dev.off(); next }
    if (dev.cur() > 1) { rec <- tryCatch(recordPlot(), error = function(e) NULL); dev.off() }
    v <- vis$value
    if (inherits(v, "st_quiz")) res[[length(res) + 1]] <- list(kind = "quiz", quiz = v)
    else if (vis$visible && inherits(v, "ggplot")) res[[length(res) + 1]] <- list(kind = "gg", plot = v)
    else if (vis$visible && is.data.frame(v) && nrow(v) <= 15 && ncol(v) <= 8) res[[length(res) + 1]] <- list(kind = "table", df = as.data.frame(v))
    else if (vis$visible) {
      txt <- paste(utils::capture.output(print(v)), collapse = "\n")
      if (nzchar(txt)) res[[length(res) + 1]] <- list(kind = "text", text = txt)
    }
    if (!is.null(rec) && !is.null(rec[[1]]) && length(rec[[1]]) > 0 && !inherits(v, "ggplot")) res[[length(res) + 1]] <- list(kind = "base", plot = rec)
  }
  res
}
run_upto <- function(de, upto) {
  while (de$ran < upto) {
    de$ran <- de$ran + 1L
    ch <- de$chunks[[de$ran]]
    if (ch$eval && !ch$quiz) {
      code <- gsub('source\\("assets/quiz.R"\\)', "", ch$code)
      suppressWarnings(suppressMessages(eval_capture(code, de$env, de$dir)))
    }
  }
  de
}

# ── Markdown of a slide body -> pieces ────────────────────────────
strip_md <- function(x) {
  x <- gsub("\\*\\*([^*]+)\\*\\*", "\\1", x); x <- gsub("(^|[^*])\\*([^*]+)\\*", "\\1\\2", x)
  x <- gsub("`([^`]+)`", "\\1", x); x <- gsub("\\[([^]]+)\\]\\([^)]*\\)", "\\1", x)
  x <- gsub("~([^~]+)~", "\\1", x)
  trimws(x)
}
inline_r <- function(x, env, dir) {
  m <- gregexpr("`r ([^`]+)`", x)
  regmatches(x, m) <- lapply(regmatches(x, m), function(hits) vapply(hits, function(h) {
    code <- sub("^`r ", "", sub("`$", "", h))
    v <- tryCatch(in_dir(dir, eval(parse(text = code), env)), error = function(e) "?")
    paste(format(v), collapse = ", ")
  }, ""))
  x
}
pipe_table <- function(rows) {
  rows <- rows[!grepl("^\\s*\\|?\\s*:?-{2,}", rows)]
  cells <- lapply(rows, function(r) trimws(strsplit(sub("^\\s*\\|", "", sub("\\|\\s*$", "", r)), "|", fixed = TRUE)[[1]]))
  n <- max(lengths(cells)); cells <- lapply(cells, function(r) c(r, rep("", n - length(r))))
  df <- as.data.frame(do.call(rbind, cells[-1]), stringsAsFactors = FALSE)
  names(df) <- make.unique(vapply(cells[[1]], function(h) if (nzchar(h)) strip_md(h) else " ", ""))
  df[] <- lapply(df, strip_md)
  df
}

# ── Placing things on a slide ─────────────────────────────────────
new_slide <- function(pres, title, font = FONTS$deck, align = "left", size = 30) {
  pres <- add_slide(pres, layout = "Blank", master = "Office Theme")
  if (nzchar(title)) pres <- ph_with(pres, fpar(ftext(title, fp_text(font.size = size, bold = TRUE, color = COL$ink, font.family = font)), fp_p = fp_par(text.align = align)),
    location = ph_location(left = M, top = 0.3, width = W - 2 * M, height = 0.9))
  pres
}
text_box <- function(pres, paras, top, height, font = FONTS$deck, size = 18, align = "left", fill = NULL, mono = FALSE, left = M, width = W - 2 * M) {
  fam <- if (mono) MONO else font
  ps <- lapply(paras, function(p) {
    bullet <- grepl("^\\s*([-*]|\\d+[.)]) ", p)
    txt <- if (bullet) paste0("•  ", sub("^\\s*([-*]|\\d+[.)]) ", "", p)) else p
    fpar(ftext(txt, fp_text(font.size = size, color = COL$ink, font.family = fam)), fp_p = fp_par(text.align = align, padding.left = if (bullet) 12 else 0))
  })
  loc <- ph_location(left = left, top = top, width = width, height = height, bg = fill)
  ph_with(pres, do.call(block_list, ps), location = loc)
}
lines_h <- function(n, size) n * size / 72 * 1.35 + 0.15

Slides <- R6ish <- NULL
add_pieces <- function(pres, title, pieces, notes, font = FONTS$deck, align = "left") {
  pres <- new_slide(pres, title, font, align)
  y <- 1.3; first <- TRUE
  place <- function(h) {
    if (y + h > H - 0.3 && !first) { pres <<- new_slide(pres, paste(title, "(continued)"), font, align); y <<- 1.3 }
    first <<- FALSE
    top <- y; y <<- y + h + 0.12; top
  }
  for (p in pieces) {
    if (p$kind == "text") {
      paras <- p$paras[nzchar(trimws(p$paras))]
      if (!length(paras)) next
      size <- p$size %||% 18
      wrap <- sum(ceiling(nchar(paras) / (120 * 18 / size)))
      h <- lines_h(max(wrap, length(paras)), size)
      pres <- text_box(pres, paras, place(min(h, H - 1.6)), min(h, H - 1.6), font = font, size = size, align = p$align %||% align,
        fill = switch(p$box %||% "", key = COL$key, warn = COL$warn, eq = COL$eq, NULL))
    } else if (p$kind == "code" || p$kind == "out") {
      ln <- strsplit(p$text, "\n")[[1]]
      if (length(ln) > 22) ln <- c(ln[1:21], "…")
      size <- if (p$kind == "code") 13 else 12
      h <- lines_h(length(ln), size)
      pres <- text_box(pres, ln, place(h), h, size = size, mono = TRUE, fill = if (p$kind == "code") COL$code else NULL)
    } else if (p$kind == "table") {
      df <- p$df
      df[] <- lapply(df, function(v) if (is.numeric(v)) format(signif(v, 3), drop0trailing = TRUE, scientific = 6, trim = TRUE) else v)
      ft <- flextable(df) |> fontsize(size = 12, part = "all") |>
        font(fontname = if (identical(font, FONTS$deck)) "Calibri" else font, part = "all") |> padding(padding = 2, part = "all") |> autofit()
      h <- 0.4 * (nrow(p$df) + 1) + 0.2
      pres <- ph_with(pres, ft, location = ph_location(left = M, top = place(h), width = W - 2 * M, height = h))
    } else if (p$kind == "gg" || p$kind == "base") {
      h <- 4.3
      top <- place(h)
      g <- if (p$kind == "gg") dml(ggobj = p$plot, bg = "white", editable = TRUE) else dml(code = replayPlot(p$plot), bg = "white", editable = TRUE)
      pres <- ph_with(pres, g, location = ph_location(left = M + 0.8, top = top, width = W - 2 * M - 1.6, height = h))
    }
  }
  if (length(notes) && any(nzchar(notes))) pres <- set_notes(pres, value = paste(notes[nzchar(notes)], collapse = "\n\n"), location = notes_location_type("body"))
  pres
}

# A workshop slide -> pieces
workshop_pieces <- function(ref) {
  parts <- strsplit(ref, "[/#]")[[1]]
  workshop <- parts[1]; deck_name <- parts[2]; id <- parts[3]
  src <- slide_source(workshop, deck_name, id)
  if (is.null(src)) return(list(title = paste("(slide removed:", ref, ")"), pieces = list(), notes = character(0)))
  de <- deck_env(workshop, deck_name)
  body_start <- src$start + 1; body_end <- src$start + length(src$body)
  # Run every chunk before this slide (setup included), then this slide's own chunks in order with their output.
  before <- which(vapply(de$chunks, function(ch) ch$start < body_start, logical(1)))
  de <- run_upto(de, if (length(before)) max(before) else 0L)
  pieces <- list(); notes <- character(0); buf <- character(0); in_div <- NULL; tbl <- character(0)
  flush <- function() {
    if (length(tbl)) { pieces[[length(pieces) + 1]] <<- list(kind = "table", df = pipe_table(tbl)); tbl <<- character(0) }
    if (length(buf)) { pieces[[length(pieces) + 1]] <<- list(kind = "text", paras = strip_md(inline_r(buf, de$env, de$dir)), box = in_div); buf <<- character(0) }
  }
  i <- body_start
  while (i <= body_end) {
    l <- src$all[i]
    ch_i <- which(vapply(de$chunks, function(ch) ch$start == i, logical(1)))
    if (length(ch_i)) {
      flush()
      ch <- de$chunks[[ch_i]]
      if (ch$visible && !ch$quiz) pieces[[length(pieces) + 1]] <- list(kind = "code", text = ch$code)
      if (ch$eval && ch$include) {
        res <- suppressWarnings(suppressMessages(eval_capture(gsub('source\\("assets/quiz.R"\\)', "", ch$code), de$env, de$dir)))
        for (r in res) {
          if (r$kind == "quiz") {
            q <- r$quiz
            opts <- if (q$type == "mcq") paste0(LETTERS[seq_along(q$options)], ".  ", q$options) else "(type your answer)"
            pieces[[length(pieces) + 1]] <- list(kind = "text", paras = c(q$q, "", opts), size = 18)
            ans <- if (q$type == "mcq") paste0(LETTERS[q$answer], ". ", q$options[q$answer]) else paste(q$accept, collapse = " / ")
            notes <- c(notes, paste0("Answer: ", ans, "\n", q$explain))
          } else if (r$kind == "text") pieces[[length(pieces) + 1]] <- list(kind = "out", text = r$text)
          else pieces[[length(pieces) + 1]] <- r
        }
      }
      de$ran <- max(de$ran, ch_i)
      i <- ch$end + 1; next
    }
    if (grepl("^:::+", l)) {                    # fenced divs: callouts keep a box; layout divs are dropped
      flush()
      cls <- regmatches(l, regexpr("\\{[^}]*\\}", l))
      in_div <- if (length(cls) && grepl("\\.(key|warn|eq)", cls)) sub(".*\\.(key|warn|eq).*", "\\1", cls) else if (length(cls)) in_div else NULL
      if (grepl("^:::+\\s*$", l)) in_div <- NULL
      i <- i + 1; next
    }
    if (grepl("^\\s*\\|", l)) { if (length(buf)) { tmp <- tbl; tbl <- character(0); flush(); tbl <- tmp }; tbl <- c(tbl, l); i <- i + 1; next }
    if (length(tbl)) flush()
    if (grepl("^<!--|^!\\[", l)) { i <- i + 1; next }
    if (nzchar(trimws(l))) buf <- c(buf, l) else if (length(buf)) flush()
    i <- i + 1
  }
  flush()
  envs[[paste(workshop, deck_name, sep = "/")]] <<- de
  list(title = strip_md(inline_r(src$title, de$env, de$dir)), pieces = pieces, notes = notes)
}

# An own slide (JSON, plan §5.2) -> pieces
own_pieces <- function(body) {
  font <- FONTS[[body$font %||% "deck"]] %||% FONTS$deck
  align <- body$align %||% "left"
  size_pt <- c(S = 14, M = 18, L = 22, XL = 27)
  pieces <- list()
  for (b in body$blocks) {
    sz <- size_pt[[b$size %||% "M"]] %||% 18
    if (b$type %in% c("text", "box")) pieces[[length(pieces) + 1]] <- list(kind = "text", paras = strip_md(strsplit(b$markdown %||% "", "\n")[[1]]), size = sz,
      align = b$align %||% align, box = if (b$type == "box") b$kind %||% "key" else NULL)
    else if (b$type == "table" && length(b$rows) > 1) {
      rows <- lapply(b$rows, function(r) unlist(r)); n <- max(lengths(rows)); rows <- lapply(rows, function(r) c(r, rep("", n - length(r))))
      df <- as.data.frame(do.call(rbind, rows[-1]), stringsAsFactors = FALSE); names(df) <- make.unique(ifelse(nzchar(rows[[1]]), rows[[1]], " "))
      pieces[[length(pieces) + 1]] <- list(kind = "table", df = df)
    } else if (b$type == "code") {
      if (!isFALSE(b$showCode)) pieces[[length(pieces) + 1]] <- list(kind = "code", text = b$code %||% "")
      if (run_own) {
        res <- suppressWarnings(suppressMessages(eval_capture(b$code %||% "", new.env(parent = globalenv()), ROOT)))
        for (r in res) pieces[[length(pieces) + 1]] <- if (r$kind == "text") list(kind = "out", text = r$text) else r
      } else if (!is.null(b$output$saved)) pieces[[length(pieces) + 1]] <- list(kind = "out", text = b$output$saved)
    }
  }
  list(title = body$title %||% "", pieces = pieces, notes = body$notes %||% character(0), font = font, align = align)
}

# ── Build ─────────────────────────────────────────────────────────
pres <- read_pptx(template_16x9())
pres <- add_slide(pres, layout = "Blank", master = "Office Theme")
pres <- ph_with(pres, fpar(ftext(deck$title, fp_text(font.size = 40, bold = TRUE, color = COL$ink, font.family = FONTS$deck)), fp_p = fp_par(text.align = "center")),
  location = ph_location(left = M, top = 2.6, width = W - 2 * M, height = 1.3))
pres <- ph_with(pres, fpar(ftext(sprintf("%d slides · Medical Statistics in R", length(deck$items)), fp_text(font.size = 18, color = COL$muted)), fp_p = fp_par(text.align = "center")),
  location = ph_location(left = M, top = 4, width = W - 2 * M, height = 0.6))
n_done <- 0
for (it in deck$items) {
  n_done <- n_done + 1
  if (identical(it$type, "own")) {
    body <- deck$own[[it$id]]
    if (is.null(body)) next
    sp <- own_pieces(body)
    pres <- add_pieces(pres, sp$title, sp$pieces, sp$notes, sp$font, sp$align)
  } else {
    wp <- tryCatch(workshop_pieces(it$ref), error = function(e) list(title = it$ref, pieces = list(list(kind = "text", paras = paste("Could not build this slide:", conditionMessage(e)))), notes = character(0)))
    user_note <- deck$notes[[it$ref]] %||% character(0)
    pres <- add_pieces(pres, wp$title, wp$pieces, c(user_note, wp$notes))
  }
  cat(sprintf("[%d/%d] %s\n", n_done, length(deck$items), if (identical(it$type, "own")) "your slide" else it$ref))
}
print(pres, target = out_file)
cat("Wrote", out_file, "\n")
