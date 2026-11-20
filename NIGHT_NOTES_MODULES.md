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

## Progress
