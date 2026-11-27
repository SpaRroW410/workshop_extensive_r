# Medical Statistics in R

**Maintainers:** Dr. Mukul Maheshwari · Dr. Rudresh Negi, Department of Community Medicine

A Quarto site that teaches medical statistics in R, from a first script to causal inference, as a
self-study plan of tracks, hands-on workshops and a game (*Dungeons & Dataframes*). All datasets are synthetic.

## What is on the site

| Part | Folders | Profile(s) |
|---|---|---|
| Landing page: the game, the four-step study plan, electives, profile | `index.qmd`, `assets/landing.css` | none (renders to `docs/`) |
| Track home pages (one block per track) | `welcome.qmd` | every profile |
| **Core tracks** Basic → Moderate → Regression → Advanced | `r-foundations/`, `data-visualization/`, `plot-gallery/`, `specialized/`, `statistical-analysis/`, `ggstatsplot/`, `gtsummary/`, `quarto_repro_w/`, `exporting_tools/` | `basic`, `moderate`, `regression`, `advanced` |
| **Electives** Data Visualization (Foundations, Complete), Statistical Analysis, GIS | the visualization folders, `stats-workshop/`, `gis/` | `dataviz-base`, `dataviz-complete`, `statistics`, `gis` |
| **Workshops**: 5–6 decks with quizzes, fill-in labs with facilitator solutions, cheat sheet, `make_data.R` | `regression-workshop/`, `stats-workshop/` (statistical tests: assumptions and interpretation), `gis-workshop/`, `survival-` `counts-` `ordinal-` `clustered-` `survey-` `curves-` `missing-` `prediction-` `causal-workshop/` (A1–A9) | `regression`, `statistics`, `gis`, `advanced` |
| **The game**, Regions 1–3 | `dungeons/` | `dungeons` |
| **Cloudflare**: sign-in, paid-path gate, progress sync | `cloud/` (see [`cloud/README.md`](cloud/README.md)) | — |

`advanced-workshops.qmd` lists every session of A1–A9.

## How the tracks are built

- **`curriculum.yml` is the single source** for every track's menus. `Rscript scripts/build_profiles.R` turns it into
  `_quarto-<track>.yml` (never edit those by hand) and `_filters/pages.json`.
- **Each track renders only the pages in its own menus** (plus the five shared pages: landing redirect, home,
  contact, downloads, references). A link to a page another track owns is pointed into that track by
  `_filters/crosstrack.lua`.
- `bash render-all-profiles.sh` renders the landing page and all eight tracks into `docs/` (incremental; `--force`
  re-executes all R code). R results are frozen in `_freeze/`; the game's pages always re-run.
- The quiz engine has one master copy in `regression-workshop/assets/`; `bash scripts/sync_workshop_assets.sh` copies it
  to every workshop.

## Requirements

R ≥ 4.3 with the packages listed in `scripts/cloud_setup.sh`, Quarto 1.10, and Node 22 for the tests and `cloud/`.
`scripts/cloud_setup.sh` installs all of it on Ubuntu.

## Checks

```sh
Rscript scripts/build_profiles.R --check          # track files match curriculum.yml
bash scripts/sync_workshop_assets.sh --check      # quiz engine copies match the master
(cd cloud && npm ci && npm test)                  # sign-in, gate, sync; and no paid page leaks into /basic/
node regression-workshop/tests/quiz_all.js docs/*/*-workshop/s*.html   # every deck quiz in a browser
node dungeons/tests/quest_e2e.js <url of docs/dungeons/dungeons>       # the game
```

CI (`.github/workflows/checks.yml`) runs the fast ones on every push.

## Plans and status

- [`LAUNCH_PLAN.md`](LAUNCH_PLAN.md): Cloudflare, accounts, saved progress, paid access.
- [`MODULES_PLAN.md`](MODULES_PLAN.md): bringing every module to one standard, and expert review.
- [`SITE_PLAN.md`](SITE_PLAN.md): the long-term structure of tracks and the game; [`dungeons/ROADMAP.md`](dungeons/ROADMAP.md).
- [`STATUS.md`](STATUS.md): what exists, what was checked, what is open.

## Contact

Please contact Dr. Mukul Maheshwari (GitHub [SpaRroW410](https://github.com/SpaRroW410)) with ideas, corrections or
collaboration requests.
