# Dungeons & Dataframes — gamified medical statistics in R

The game is its own site (profile `dungeons`, output `docs/dungeons/`, open-access card on the landing page). It starts from the basics: **Region 1 · Basics → Region 2 · Moderate → Region 3 · Regression → Region 4 · Advanced**; the workshop tracks are its library ("📖 Read first" links). Playable now: **Region 3 Worlds 1–6**, placement check, pre/post tests, Campus (skill tree), facilitator pack and cohort tool. Everything else is in [ROADMAP.md](ROADMAP.md) (16 worlds, 9 electives, 7 phases) and the site concept in [SITE_DESIGN.md](SITE_DESIGN.md) (skill tree, case files, arcade, hybrid R labs, state model).

```
dungeons/
├── index.qmd, world*.qmd, readiness.qmd (placement), pretest.qmd, posttest.qmd, campus.qmd, facilitator.qmd, cohort.qmd
├── bank/items.R        item bank: single source for worlds + pre (Form A) + post (Form B)
├── assets/quest.js     engine (5 item types, XP, hints, streak, ranks, badges, gates, test mode, export/import)
├── assets/quest.R      authoring helpers (salted hashes; markup order permuted so the source never lists the key first)
├── assets/worlds.js    regions + worlds on the map, with their "Read first" library pages
├── assets/skills.js    skill tree, mastery, review, recommender (tests/skills_test.js)
├── assets/cohort.js    facilitator cohort summary (tests/cohort_test.js)
├── lint_bank.R         question-quality gate  (Rscript dungeons/lint_bank.R)
└── tests/quest_e2e.js  Playwright end-to-end suite (44 checks)
```

## Question standards (linted — see ROADMAP §6.2)
Key never the longest option · no "all/none of the above" · **no function-recall questions** · answers never in stem/hints · every item explained, tagged and levelled · display order shuffled at run time **and** markup order permuted at build time.

## Add an item
Add a `mc()/nm()/fl()/od()/sp()` entry to `bank/items.R`, run `Rscript dungeons/lint_bank.R`, then reference its id from a world page with `rq_render(...)`.
