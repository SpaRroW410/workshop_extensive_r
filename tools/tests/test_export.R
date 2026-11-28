# Test for tools/export_pptx.R: run from the repository root.
#   Rscript tools/tests/test_export.R
suppressPackageStartupMessages(library(officer))
out <- tempfile(fileext = ".pptx")
status <- system2("Rscript", c("tools/export_pptx.R", "tools/tests/sample_deck.json", out), stdout = FALSE, stderr = FALSE)
ok <- function(cond, what) { cat(if (cond) "ok  " else "FAIL", what, "\n"); if (!cond) assign("failed", TRUE, globalenv()) }
failed <- FALSE
ok(status == 0 && file.exists(out), "the export runs and writes a .pptx")
x <- read_pptx(out); s <- pptx_summary(x)
ok(length(x) == 8, "a title slide and one slide per item (7)")
ok(isTRUE(all.equal(unlist(slide_size(x)), c(width = 13.333, height = 7.5), tolerance = 1e-3)), "16:9")
ok(sum(s$slide_id == 2) > 100, "the Q-Q plot is editable vector shapes, not a picture")
ok(any(s$content_type == "table cell" & s$slide_id == 7 & s$text == "salt_g"), "the data dictionary is a real table")
ok(any(grepl("The 6-month minus presentation differences per person", s$text) & s$slide_id == 6), "the quiz question and its options")
ok(any(grepl("Welch by default", s$text) & s$slide_id == 8), "the own slide's text")
files <- utils::unzip(out, list = TRUE)$Name
notes <- unlist(lapply(grep("notesSlides/notesSlide[0-9]+\\.xml$", files, value = TRUE), function(f) { d <- tempfile(); utils::unzip(out, f, exdir = d); paste(readLines(file.path(d, f), warn = FALSE), collapse = "") }))
ok(any(grepl("Ask the room which sign they expect", notes)), "the user's note is in the speaker notes")
ok(any(grepl("Answer: D", notes)), "the quiz answer is in the speaker notes")
ok(any(grepl("Say this slowly", notes)), "the own slide's notes are in the speaker notes")
ok(!any(grepl("Error:", s$text)), "no slide shows an R error")
if (failed) quit(status = 1) else cat("All export checks passed\n")
