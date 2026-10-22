# ═══════════════════════════════════════════════════════════════
# quest.R — authoring helpers for quest.js (self-contained copy)
# An ITEM is a plain R list (see bank/items.R). rq_render() prints the
# fenced-div markup with salted hashes (answers) and base64 (explain/hints/
# reveal text). Use in a chunk with  #| echo: false  and  #| output: asis
# ═══════════════════════════════════════════════════════════════
.rq_b36 <- function(x) { d <- c(0:9, letters); if (x == 0) return("0"); o <- character(0); while (x > 0) { o <- c(d[(x %% 36) + 1], o); x <- x %/% 36 }; paste(o, collapse = "") }
rq_hash <- function(str) { a <- 5381; b <- 52711; for (cc in utf8ToInt(str)) { a <- (a * 131 + cc) %% 2147483629; b <- (b * 137 + cc) %% 2147483587 }; paste0(.rq_b36(a), ".", .rq_b36(b)) }
rq_norm <- function(s) { s <- tolower(s); s <- gsub("`", "", s, fixed = TRUE); s <- trimws(gsub("\\s+", " ", s)); trimws(sub("\\(\\s*\\)$", "", s)) }
.rq_b64 <- function(s) gsub("[\r\n]", "", jsonlite::base64_enc(charToRaw(enc2utf8(s))))
.rq_q   <- function(x) gsub('"', "&quot;", x, fixed = TRUE)
.rq_perm <- function(id, n) {            # deterministic non-identity permutation seeded by the item id
  seed <- sum(utf8ToInt(id) * seq_along(utf8ToInt(id))) %% 100000L + 17L; set.seed(seed)
  repeat { p <- sample.int(n); if (n < 2 || !identical(p, seq_len(n))) return(p) }
}
.rq_numkey <- function(v, dp) sprintf(paste0("%.", dp, "f"), round(v, dp))

rq_item_md <- function(it) {
  id <- it$id; type <- it$type
  a <- list(`data-id` = id, `data-world` = it$world %||% "", `data-type` = type, `data-diff` = it$diff %||% 1,
            `data-tags` = paste(it$tags %||% character(0), collapse = ","))
  if (!is.null(it$form)) a[["data-form"]] <- it$form
  if (isTRUE(it$boss)) a[["data-boss"]] <- "1"
  body <- it$stem
  if (type == "mcq") {
    stopifnot(it$answer >= 1, it$answer <= length(it$options))
    # Markup order is permuted (deterministically per id) so the page SOURCE never lists the key first.
    # quest.js then shuffles the DISPLAY order again at run time; the hash is on the listed index.
    pm <- .rq_perm(id, length(it$options)); opts <- it$options[pm]; new_ans <- which(pm == it$answer)
    a[["data-hash"]] <- rq_hash(paste0(id, "|", new_ans - 1)); show <- it$options[it$answer]
    body <- paste0(body, "\n\n", paste0("- ", opts, collapse = "\n"))
  } else if (type == "fill") {
    a[["data-hashes"]] <- paste(unique(vapply(it$accept, function(x) rq_hash(paste0(id, "|", rq_norm(x))), "")), collapse = ","); show <- it$accept[1]
  } else if (type == "num") {
    dp <- it$dp %||% 0; a[["data-dp"]] <- dp
    a[["data-hashes"]] <- paste(unique(vapply(it$accept, function(x) rq_hash(paste0(id, "|", .rq_numkey(x, dp))), "")), collapse = ",")
    show <- .rq_numkey(it$accept[1], dp)
  } else if (type == "order") {
    n <- length(it$steps); pm <- .rq_perm(id, n)          # listed[j] = steps[pm[j]]
    correct_listed <- vapply(seq_len(n), function(r) which(pm == r) - 1, 0)   # listed index holding rank r
    a[["data-hash"]] <- rq_hash(paste0(id, "|", paste(correct_listed, collapse = "-"))); show <- paste(seq_len(n), it$steps, sep = ". ", collapse = "  ")
    body <- paste0(body, "\n\n", paste0("1. ", it$steps[pm], collapse = "\n"))
  } else if (type == "spot") {
    a[["data-hash"]] <- rq_hash(paste0(id, "|", paste(sort(it$flawed - 1), collapse = ","))); show <- paste("Flawed:", paste(it$flawed, collapse = ", "))
    body <- paste0(body, "\n\n", paste0("- ", it$sentences, collapse = "\n"))
  } else stop("unknown type ", type)
  a[["data-show"]] <- .rq_q(.rq_b64(show)); a[["data-explain"]] <- .rq_q(.rq_b64(it$explain %||% ""))
  if (length(it$hints)) a[["data-hints"]] <- .rq_q(.rq_b64(jsonlite::toJSON(it$hints, auto_unbox = FALSE)))
  attrs <- paste(sprintf('%s="%s"', names(a), vapply(a, as.character, "")), collapse = " ")
  sprintf("\n::: {.rq-item %s}\n%s\n:::\n", attrs, body)
}
`%||%` <- function(a, b) if (is.null(a)) b else a
rq_render <- function(ids, bank, test = NULL) { if (!is.null(test)) cat(sprintf('\n::: {.rq-test data-test="%s"}\n', test)); for (i in ids) { it <- Filter(function(x) x$id == i, bank); if (length(it) != 1) stop("item not found/unique: ", i); cat(rq_item_md(it[[1]])) }; if (!is.null(test)) cat("\n:::\n"); invisible(NULL) }
rq_total <- function(world, bank) sum(vapply(bank, function(x) identical(x$world, world), TRUE))

# Emit window.RQ_TAGMAP (tag -> world -> n items, world items only) for the Campus and the test result panels.
rq_tagmap <- function(bank) {
  rows <- do.call(rbind, lapply(Filter(function(x) grepl("^w[0-9]+$", x$world), bank), function(x) data.frame(tag = x$tags, world = x$world)))
  tm <- lapply(split(rows, rows$tag), function(d) as.list(table(d$world)))
  cat("\n```{=html}\n<script>window.RQ_TAGMAP=", jsonlite::toJSON(tm, auto_unbox = TRUE), ";</script>\n```\n", sep = "")
}
