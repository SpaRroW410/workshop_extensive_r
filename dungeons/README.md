# Dungeons & Dataframes — gamified medical statistics in R

The game is its own site (profile `dungeons`, output `docs/dungeons/`, open-access card on the landing page). It starts from the basics: **Region 1 · Basics → Region 2 · Moderate → Region 3 · Regression → Region 4 · Advanced**; the workshop tracks are its library ("📖 Read first" links). Playable now: **Region 1 Worlds b1–b5** and **Region 2 Worlds m1–m5** (each region with its own pre/post tests), **Region 3 Worlds 1–6**, placement check, Region 3 pre/post tests, Campus (skill tree), facilitator pack and cohort tool. Everything else is in [ROADMAP.md](ROADMAP.md) (16 worlds, 9 electives, 7 phases) and the site concept in [SITE_DESIGN.md](SITE_DESIGN.md) (skill tree, case files, arcade, hybrid R labs, state model).

```
dungeons/
├── index.qmd, world*.qmd, readiness.qmd (placement), pretest.qmd, posttest.qmd, campus.qmd, facilitator.qmd, cohort.qmd
├── bank/items.R        item bank: single source for worlds + pre (Form A) + post (Form B)
├── assets/quest.js     engine (5 item types, XP, hints, streak, ranks, badges, gates, test mode, export/import)
├── assets/quest.R      authoring helpers (salted hashes; markup order permuted so the source never lists the key first)
├── assets/worlds.js    regions + worlds on the map, with their "Read first" library pages
├── assets/skills.js    skill tree, mastery, review, recommender (tests/skills_test.js)
├── assets/rcheck.js    checks typed/pasted R without running R: parse → normalise → compare (tests/rcheck_test.js)
├── assets/cohort.js    facilitator cohort summary (tests/cohort_test.js)
├── lint_bank.R         question-quality gate  (Rscript dungeons/lint_bank.R)
├── tests/lint_bank.js  same rules in Node + extra obvious-answer checks: node dungeons/tests/lint_bank.js --strict
└── tests/quest_e2e.js  Playwright end-to-end suite (44 checks)
```

## Question standards (linted — see ROADMAP §6.2)
No answer leaks and no giveaway options. Key never the longest option, nor much the shortest · no option alone breaks the shared opening · only-the-key-fits grammar (a/an) · hedged key vs absolute distractors · duplicate options · flawed spot sentences marked by cue words · code solutions written or named in the stem · hints that are themselves answers · · no "all/none of the above" · **no function-recall questions** · answers never in stem/hints · every item explained, tagged and levelled · display order shuffled at run time **and** markup order permuted at build time.

## Datasets
A question that names `ncd`, `villages`, `round1`, `round2`, `ncd_messy` or `bp_followup` (in its stem or a code solution) automatically gets a download button, load line and column list. Add a dataset: a row in `RQ_DATA` (`assets/worlds.js`), its id in `RQ_DATA_IDS` (`assets/quest.R`), the file under `data/` and in the `dungeons` profile `resources` (`curriculum.yml`).

## Code items (type or paste R)
`cx(id, world, diff, tags, stem, solutions = c("…"), explain, opts = list(ignore = "na.rm"))`. The learner's code is never run: `assets/rcheck.js` reduces it and each solution to one canonical form, so pipes vs nested calls, `%>%` vs `|>`, intermediate objects, any new-column name (unless `opts = list(free_names = FALSE)`), argument order, `filter(a & b)` vs `filter(a, b)`, `count()` vs `group_by()+summarise(n())`, base `x[cond, ]`/`subset()`, formula term order and ggplot `aes()` placement all count as the same answer. Give extra `solutions` for genuinely different approaches (e.g. base R and dplyr). Wrong answers get targeted feedback (missing/extra step, wrong data, which step's arguments differ); syntax errors are explained and not counted as a try.

## Add an item
Add a `mc()/nm()/fl()/od()/sp()/cx()` entry to `bank/items.R`, run `Rscript dungeons/lint_bank.R` **and** `node dungeons/tests/lint_bank.js --strict` (both must be clean), then reference its id from a world page with `rq_render(...)`.
