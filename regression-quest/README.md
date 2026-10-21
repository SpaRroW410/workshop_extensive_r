# Dungeons & Dataframes — gamified medical statistics in R

Track 1 (Regression) is under construction here.

A gamified, *tested* self-learning copy of the regression workshop. Playable now: **pre-test, World 1, World 2, World 3, post-test**, quest map, XP / streak / ranks / badges. Everything else is in [ROADMAP.md](ROADMAP.md) (16 worlds, 9 electives, 7 phases) and the site concept in [SITE_DESIGN.md](SITE_DESIGN.md) (skill tree, case files, arcade, hybrid R labs, state model).

```
regression-quest/
├── index.qmd, world1_*.qmd, world2_*.qmd, pretest.qmd, posttest.qmd, roadmap.qmd
├── bank/items.R        item bank: single source for worlds + pre (Form A) + post (Form B)
├── assets/quest.js     engine (5 item types, XP, hints, streak, ranks, badges, gates, test mode, export/import)
├── assets/quest.R      authoring helpers (salted hashes; markup order permuted so the source never lists the key first)
├── assets/worlds.js    registry of every world on the map
├── lint_bank.R         question-quality gate  (Rscript regression-quest/lint_bank.R)
└── tests/quest_e2e.js  Playwright end-to-end suite (44 checks)
```

## Question standards (linted — see ROADMAP §6.2)
Key never the longest option · no "all/none of the above" · **no function-recall questions** · answers never in stem/hints · every item explained, tagged and levelled · display order shuffled at run time **and** markup order permuted at build time.

## Add an item
Add a `mc()/nm()/fl()/od()/sp()` entry to `bank/items.R`, run `Rscript regression-quest/lint_bank.R`, then reference its id from a world page with `rq_render(...)`.
