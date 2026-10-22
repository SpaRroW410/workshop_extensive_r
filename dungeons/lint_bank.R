# ═══════════════════════════════════════════════════════════════
# lint_bank.R — quality gate for dungeons/bank/items.R
# Usage (repo root):  Rscript dungeons/lint_bank.R
# Question-writing standards enforced here (see ROADMAP.md §Assessment):
#  H1 MCQ key not the strictly longest option, nor >1.25x the distractor mean
#  H2 no "all/none/both of the above"
#  H3 no function/argument-recall stems ("which function…", "what does f() do")
#  H4 every item has an explanation, tags, difficulty 1–3 and a world
#  H5 MCQ option lengths within 2.5x of each other
#  H6 fill/num answers must not appear verbatim in the stem
#  H7 MCQ/order/spot need >=4 options/steps/sentences; spot needs a flawed set; code needs >=1 solution
#  H8 ids unique; hints (if any) never contain the answer text
#  S1 stem/key word overlap · S2 absolutes only in distractors · S4 key-position skew
# ═══════════════════════════════════════════════════════════════
base <- if (dir.exists("dungeons")) "dungeons" else "."
source(file.path(base, "bank", "items.R"))
words <- function(s) { w <- tolower(unlist(strsplit(gsub("[^A-Za-z0-9_ ]", " ", s), "\\s+"))); setdiff(w[nchar(w) > 3], c("which","that","this","with","what","from","than","their","have","does","your","when","each","into","about","after","other","there","these","those","would","should","could","model","models","regression")) }
absolutes <- c("always","never","only","exactly","guarantees","guarantee","every","must","completely","entirely","impossible","proves")
fails <- 0; warns <- 0; pos <- c(); ids <- vapply(ITEMS, function(x) x$id, "")
cat(sprintf("%d items | types: %s\n", length(ITEMS), paste(names(table(vapply(ITEMS, function(x) x$type, ""))), table(vapply(ITEMS, function(x) x$type, "")), collapse = ", ")))
if (anyDuplicated(ids)) { cat("H8 duplicate ids:", ids[duplicated(ids)], "\n"); fails <- fails + 1 }
for (it in ITEMS) {
  H <- character(0); S <- character(0)
  if (!nzchar(trimws(it$explain %||% ""))) H <- c(H, "H4 no explanation")
  if (is.null(it$world) || !length(it$tags) || !(it$diff %in% 1:3)) H <- c(H, "H4 missing world/tags/diff")
  if (grepl("which (\\w+ )?(function|argument|package|command)|what (function|argument)|what does `?[A-Za-z_.]+\\(\\)`? (do|return)|did you use in (task|lab)|name of the (function|argument)", it$stem, ignore.case = TRUE)) H <- c(H, "H3 function/argument recall")
  if (it$type == "mcq") {
    o <- it$options; nc <- nchar(o); k <- it$answer; pos <- c(pos, k)
    if (length(o) < 4) H <- c(H, "H7 fewer than 4 options")
    if (nc[k] == max(nc) && sum(nc == max(nc)) == 1) H <- c(H, sprintf("H1 key strictly longest (%d vs %s)", nc[k], paste(nc[-k], collapse = "/")))
    else if (nc[k] > 1.25 * mean(nc[-k])) H <- c(H, sprintf("H1 key %.0f%% longer than distractor mean", 100 * (nc[k] / mean(nc[-k]) - 1)))
    if (any(grepl("(all|none|both) of the (above|these)", tolower(o)))) H <- c(H, "H2 all/none of the above")
    if (max(nc) / min(nc) >= 2.5) H <- c(H, sprintf("H5 lengths differ %.1fx", max(nc) / min(nc)))
    ov <- sapply(o, function(x) length(intersect(words(it$stem), words(x)))); if (ov[k] == max(ov) && ov[k] - max(c(ov[-k], 0)) >= 2) S <- c(S, "S1 key overlaps stem")
    ab <- sapply(o, function(x) any(sapply(absolutes, function(a) grepl(paste0("\\b", a, "\\b"), tolower(x))))); if (!ab[k] && sum(ab[-k]) >= 2) S <- c(S, "S2 absolutes only in distractors")
    ans_txt <- tolower(o[k])
  } else if (it$type %in% c("fill", "num")) {
    ans_txt <- tolower(as.character(it$accept[1]))
    for (a in as.character(it$accept)) if (nchar(a) >= 3 && grepl(paste0("(^|[^a-z0-9])", tolower(gsub("([.|()\\^{}+$*?\\[\\]])", "\\\\\\1", a)), "([^a-z0-9]|$)"), tolower(it$stem))) H <- c(H, paste0("H6 answer '", a, "' appears in stem"))
    if (it$type == "fill" && all(grepl("^[A-Za-z_.][A-Za-z0-9_.:]*(\\(\\))?$", it$accept)) && grepl("function|argument", it$stem, ignore.case = TRUE)) H <- c(H, "H3 identifier answer to function/argument question")
  } else if (it$type == "order") { if (length(it$steps) < 4) H <- c(H, "H7 order needs >=4 steps"); ans_txt <- tolower(paste(it$steps, collapse = " "))
  } else if (it$type == "code") { if (!length(it$solutions) || !all(nzchar(trimws(it$solutions)))) H <- c(H, "H7 code item needs at least one solution"); ans_txt <- ""
  } else if (it$type == "spot") { if (length(it$sentences) < 4 || !length(it$flawed) || length(it$flawed) >= length(it$sentences)) H <- c(H, "H7 spot needs >=4 sentences and some (not all) flawed"); ans_txt <- "" }
  if (length(it$hints) && nzchar(ans_txt) && it$type %in% c("fill", "num")) for (h in it$hints) if (grepl(ans_txt, tolower(h), fixed = TRUE)) H <- c(H, "H8 hint contains the answer")
  st <- if (length(H)) "FAIL" else if (length(S)) "warn" else "ok  "
  if (length(H)) fails <- fails + 1; if (length(S)) warns <- warns + 1
  if (st != "ok  ") cat(sprintf("  %s %-8s %s\n", st, it$id, paste(c(H, S), collapse = " | ")))
}
if (length(pos)) { tb <- table(factor(pos, 1:4)); cat("Authored key positions A–D:", paste(tb, collapse = " / "), "(display order is shuffled at runtime)\n") }
cat(sprintf("%d hard failures, %d with warnings\n", fails, warns)); quit(status = as.integer(fails > 0))
