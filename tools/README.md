# tools/

## export_pptx.R — a custom deck as an editable PowerPoint (facilitators)

1. On the site, open **Custom decks** (`/decks`), build or open a deck, and click **⬇ For PowerPoint**. You get a `.json` file
   (the slide list, your own slides and your notes).
2. From the repository root, with the workshop packages installed (as for the labs) plus `officer`, `flextable`, `rvg`:

   ```sh
   Rscript tools/export_pptx.R my_deck.json            # writes my_deck.pptx next to it
   Rscript tools/export_pptx.R my_deck.json out.pptx --run-own   # also run the code on your own slides
   ```

Everything is editable in PowerPoint: titles and text are text boxes, tables are tables, ggplot and base-R charts are vector
shapes (recolour a bar, change a label), quiz slides show the question with the answer in the speaker notes, and your notes go
into the speaker-notes pane. Workshop slides are re-run from the workshop's own source; code on your own slides runs only with
`--run-own` (otherwise its saved output is used).

Test: `Rscript tools/tests/test_export.R` (11 checks on `tools/tests/sample_deck.json`).
