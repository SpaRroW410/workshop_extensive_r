# Night notes — module update (MODULE_UPDATE_STEPS.md), 2026-11-20 → 21

Branch: `module-update-plan`. Your answers this evening: datasets simulated and publishable; base modules get a
quiz + lab on the existing pages, questions must not leak answers; Data Viz electives get the full treatment;
reviewer later.

## ❓ Questions for you
(none yet)

## Decisions taken, and why

| # | Decision | Why |
|---|---|---|
| N1 | `Tidyverse_Cheat_Sheet.pdf` removed from the repo, the site and `downloads.qmd` | It is DataCamp's and shows no licence; the nine Posit sheets show CC BY-SA and stay, with attribution (`downloads/cheatsheets/LICENSES.md`) |
| N2 | The four `.xlsx` datasets are documented as simulated in `data/README.md` instead of getting generator scripts | Your answer: simulated, publishable. A generator would change every gallery plot for no gain |
| N3 | Sub-decks linked from a menu page are rendered in the same tracks as that page (`build_profiles.R`) | Fixes F1 (18 gallery decks rendered nowhere) without listing 18 decks by hand in 6 menus |
| N4 | New `scripts/check_links.py` fails on any `.qmd` link and on missing files; include fragments (`*-include.html`) are skipped | The old check missed F1; fragments are not pages |

| N5 | `ggmosaic` replaced: two-way mosaic with `productplots`, three-way with plain `geom_rect` | `ggmosaic` is off CRAN and its last version fails with ggplot2 4.0.4 ("unused arguments"); GitHub installs are blocked here. `productplots` cannot rename its axes, so the three-way plot is drawn as rectangles (10 lines, no extra package) |
| N6 | Seven gallery "OBSERVATION / INTERPRETATION" blocks rewritten from the data | Six of the seven stated things the plots do not show (e.g. a BP "rebound" that does not exist; a positive age–BP correlation that is r = −0.09; ">70% non-smokers" that is 60%) |
| N7 | Gallery decks render one track at a time (full profile), never several files in one `quarto render a.qmd b.qmd` call | Quarto 1.11 then looks for the second file in the wrong folder ("withBinaryFile: does not exist"); a full profile render works |
| N8 | Quiz engine on base pages is written in by an `asis` chunk (`assets/quiz-engine.R`), not `include-after-body` | A page-level include-after-body may replace the site-wide one in `_quarto.yml`, which fixes the navbar brand link |
| N9 | Link checker skips the navbar brand link | Its href is fixed in the browser by the site-wide script; on disk it is always wrong on nested pages (100 false alarms) |
| N10 | Base-module labs live in `labs/<track>/` (solutions in `labs/<track>/solutions/`), built by `scripts/build_base_labs.R` | Same `#@` / `#%` markers as the workshops; one place per track |
| N11 | Gallery slide overflow (155 slides in 15 decks) is fixed in the unit steps (B4, M3, V3), not in F1 | The decks were never rendered before; F1's job was to publish them and make them correct |
| N12 | R 4.3.3 (Ubuntu) cannot install `ggstatsplot` 1.1.4 (needs R ≥ 4.5): 0.13.0 from a dated snapshot is used | No newer R is available from the system packages here |

## Progress

| Step | State | Checks |
|---|---|---|
| U0 F5 dataset origins, F9 licences | ✅ committed | `data/README.md`, `downloads/cheatsheets/LICENSES.md` |
| U0 F1 gallery published + correct | ✅ committed (`852193b`) | links 0 `.qmd` / 0 missing; 56 workshop decks quiz test pass; cloud 42/42 |
