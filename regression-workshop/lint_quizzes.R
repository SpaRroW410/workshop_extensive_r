# ═══════════════════════════════════════════════════════════════
# lint_quizzes.R — quality gate for quiz questions (decks and the quest bank)
# Usage: Rscript regression-workshop/lint_quizzes.R [file.qmd ...]
#        (default: every s*.qmd deck in regression-workshop/)
# Exit status 1 if any question fails a HARD rule.
#
# HARD rules (fail)                          SOFT rules (warn)
#  H1 correct option is not strictly the      S1 stem words overlap the correct
#     longest, nor > 1.25x the mean length       option noticeably more than the
#     of the distractors (the "longest           distractors
#     answer is right" tell)                  S2 absolute words (always/never/only/
#  H2 no "all/none of the above", "both"         exactly/guarantees) appear in
#  H3 no trivial function-recall fill-ins        distractors but not in the key
#     (e.g. "which function did you use")     S3 an MCQ has fewer than 4 options
#  H4 every question has an explanation      S4 answer-position skew across the set
#  H5 MCQ options differ in length by < 2.5x
# ═══════════════════════════════════════════════════════════════
args <- commandArgs(trailingOnly = TRUE)
base <- if (dir.exists("regression-workshop")) "regression-workshop" else "."
files <- if (length(args)) args else sort(list.files(base, pattern = "^s[0-9].*\\.qmd$", full.names = TRUE))

captured <- list()
quiz_mcq  <- function(qid, question, options, answer, explain = "", ...) captured[[length(captured) + 1]] <<- list(id = qid, type = "mcq", stem = question, options = options, answer = answer, explain = explain)
quiz_fill <- function(qid, question, accept, explain = "", ...) captured[[length(captured) + 1]] <<- list(id = qid, type = "fill", stem = question, accept = accept, explain = explain)

extract_quiz_code <- function(path) {
  x <- readLines(path, warn = FALSE); out <- character(0); inchunk <- FALSE; buf <- character(0)
  for (ln in x) {
    if (!inchunk && grepl("^```\\{r", ln)) { inchunk <- TRUE; buf <- character(0); next }
    if (inchunk && grepl("^```\\s*$", ln)) { inchunk <- FALSE; if (any(grepl("quiz_(mcq|fill)\\(", buf))) out <- c(out, buf[!grepl("^#\\|", buf)]); next }
    if (inchunk) buf <- c(buf, ln)
  }
  out
}
words <- function(s) { w <- tolower(unlist(strsplit(gsub("[^A-Za-z0-9_ ]", " ", s), "\\s+"))); setdiff(w[nchar(w) > 3], c("which", "that", "this", "with", "what", "from", "than", "their", "have", "does", "your", "when", "each", "into", "about", "after", "other", "there", "these", "those", "would", "should", "could", "model", "models")) }
absolutes <- c("always", "never", "only", "exactly", "guarantees", "guarantee", "every", "any", "must", "completely", "entirely", "impossible", "proves")

fails <- 0; warns <- 0; pos <- c()
for (f in files) {
  captured <- list(); eval(parse(text = extract_quiz_code(f)))
  cat(sprintf("\n── %s (%d questions)\n", basename(f), length(captured)))
  for (q in captured) {
    msg_h <- character(0); msg_s <- character(0)
    if (!nzchar(trimws(q$explain))) msg_h <- c(msg_h, "H4 no explanation")
    if (q$type == "mcq") {
      o <- q$options; key <- o[q$answer]; dis <- o[-q$answer]; nc <- nchar(o); pos <- c(pos, q$answer)
      if (nc[q$answer] == max(nc) && sum(nc == max(nc)) == 1 && length(o) > 1) msg_h <- c(msg_h, sprintf("H1 correct option is the strictly longest (%d vs %s chars)", nc[q$answer], paste(nc[-q$answer], collapse = "/")))
      else if (nc[q$answer] > 1.25 * mean(nc[-q$answer])) msg_h <- c(msg_h, sprintf("H1 correct option %.0f%% longer than the distractor mean", 100 * (nc[q$answer] / mean(nc[-q$answer]) - 1)))
      if (any(grepl("(all|none|both) of the (above|these)|\\bboth (a|b)\\b", tolower(o)))) msg_h <- c(msg_h, "H2 all/none/both of the above")
      if (max(nc) / min(nc) >= 2.5) msg_h <- c(msg_h, sprintf("H5 option lengths differ %.1fx", max(nc) / min(nc)))
      ov <- sapply(o, function(x) length(intersect(words(q$stem), words(x)))); 
      if (ov[q$answer] == max(ov) && ov[q$answer] - max(c(ov[-q$answer], 0)) >= 2) msg_s <- c(msg_s, "S1 key shares many words with the stem")
      ab <- sapply(o, function(x) any(sapply(absolutes, function(a) grepl(paste0("\\b", a, "\\b"), tolower(x)))))
      if (!ab[q$answer] && sum(ab[-q$answer]) >= 2) msg_s <- c(msg_s, "S2 only distractors contain absolute words")
      if (length(o) < 4) msg_s <- c(msg_s, "S3 fewer than 4 options")
    } else {
      isid <- any(grepl("^[A-Za-z_.][A-Za-z0-9_.:]*(\\(\\))?$", q$accept))
      if (grepl("which (\\w+ )?(function|argument|package|value|command)|what (function|argument)|did you use|name of the (function|argument)|\\bLab [0-9]", q$stem, ignore.case = TRUE) && isid) msg_h <- c(msg_h, "H3 trivial function/argument recall")
    }
    status <- if (length(msg_h)) "FAIL" else if (length(msg_s)) "warn" else "ok  "
    if (length(msg_h)) fails <- fails + 1; if (length(msg_s)) warns <- warns + 1
    cat(sprintf("  %s %-7s %s\n", status, q$id, paste(c(msg_h, msg_s), collapse = " | ")))
  }
}
if (length(pos)) { tb <- table(factor(pos, 1:4)); cat("\nKey position counts (A–D):", paste(tb, collapse = " / "), "\n"); if (max(tb) > 0.4 * sum(tb)) cat("  S4 warn: answer positions are skewed (runtime shuffling hides this from learners)\n") }
cat(sprintf("\n%d hard failures, %d questions with warnings\n", fails, warns))
quit(status = as.integer(fails > 0))
