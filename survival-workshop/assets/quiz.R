# ═══════════════════════════════════════════════════════════════
# quiz.R — authoring helpers for quiz.js
# Takes PLAIN-TEXT questions/answers and prints the fenced-div
# markup with hashed answers + base64 explanations.
# Use inside a chunk with:  #| echo: false  and  #| output: asis
# Syntax is documented in the header of quiz.js.
# ═══════════════════════════════════════════════════════════════

# Must match hash()/normalise() in quiz.js exactly -------------------------
.quiz_to_base36 <- function(x) {
  digits <- c(0:9, letters)
  if (x == 0) return("0")
  out <- character(0)
  while (x > 0) { out <- c(digits[(x %% 36) + 1], out); x <- x %/% 36 }
  paste(out, collapse = "")
}

quiz_hash <- function(str) {
  a <- 5381; b <- 52711
  for (cc in utf8ToInt(str)) {
    a <- (a * 131 + cc) %% 2147483629
    b <- (b * 137 + cc) %% 2147483587
  }
  paste0(.quiz_to_base36(a), ".", .quiz_to_base36(b))
}

quiz_normalise <- function(s) {
  s <- tolower(s)
  s <- gsub("`", "", s, fixed = TRUE)
  s <- trimws(gsub("\\s+", " ", s))
  s <- trimws(sub("\\(\\s*\\)$", "", s))
  s
}

.quiz_b64 <- function(s) jsonlite::base64_enc(charToRaw(enc2utf8(s)))
.quiz_attr <- function(x) gsub('"', "&quot;", x, fixed = TRUE)

# MCQ: `answer` is the 1-based position of the correct option ---------------
quiz_mcq <- function(qid, question, options, answer, explain = "") {
  stopifnot(answer >= 1, answer <= length(options))
  cat(sprintf(
    '\n::: {.quiz-q data-qid="%s" data-type="mcq" data-hash="%s" data-show="%s" data-explain="%s"}\n%s\n\n%s\n:::\n',
    qid, quiz_hash(paste0(qid, "|", answer - 1)),
    .quiz_attr(.quiz_b64(options[answer])), .quiz_attr(.quiz_b64(explain)),
    question, paste0("- ", options, collapse = "\n")
  ))
  invisible(NULL)
}

# Fill-in: `accept` = every answer you are willing to accept ----------------
quiz_fill <- function(qid, question, accept, explain = "") {
  hashes <- vapply(accept, function(a) quiz_hash(paste0(qid, "|", quiz_normalise(a))), "")
  cat(sprintf(
    '\n::: {.quiz-q data-qid="%s" data-type="fill" data-hashes="%s" data-show="%s" data-explain="%s"}\n%s\n:::\n',
    qid, paste(unique(hashes), collapse = ","),
    .quiz_attr(.quiz_b64(accept[1])), .quiz_attr(.quiz_b64(explain)), question
  ))
  invisible(NULL)
}
