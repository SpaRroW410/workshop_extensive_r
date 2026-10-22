## 1. Concept

**Dungeons & Dataframes** is a website for learning **medical statistics in R**, for community-medicine residents and faculty who already have **basic-to-moderate R**. It is organised into **tracks** (Track 1 = Regression, others planned: comparing groups, epidemiological measures, study design and sample size, surveys, evidence synthesis, reporting). It is not a course with a game bolted on; it is a place you *play in*: a map of worlds, a skill tree that shows what you can and cannot do yet, case files that feel like real thesis problems, an arcade for quick drills, and a lab bench where you run real R.

| Design goal | How the site delivers it |
|---|---|
| **Mastery, not completion** | Progress is measured per **skill** (≈ 70 nodes), with spaced review. Worlds are story containers. |
| **Varied retrieval** | Every skill is practised in three modes (Quest, Case file, Arcade) so it is learned, not memorised. |
| **Judgement over recall** | Items ask what a result *means*, what to *do*, or compute something. Never function recall (enforced by `lint_bank.R`). |
| **Real R, real data** | Hybrid R labs on the project datasets, verified by result codes (no server). |
| **Works anywhere** | Static site, offline-capable, local progress; accounts and dashboards can be added later without a rewrite. |
| **Kind to learners** | A **calm mode** removes streaks, toasts and ranks; hints are cheap; nothing locks permanently. |

**Audience assumption:** can import data, use `dplyr`/`ggplot2` basics, and run and print a model. A readiness check advises anyone who is not there yet (Roadmap §2.3).

---

## 2. Information architecture

```
Dungeons & Dataframes
├── 🏠 Campus (home)            today's plan, streak, daily review, continue, news
├── 🌳 Skill tree               ~70 skills in 16 branches; mastery levels; "what next?"
├── 🧭 Tracks                   Regression (live) · Comparing groups · Epi measures · …
├── 🗺️ Quests (worlds)          briefing → levels → boss        (guided path, per track)
├── 📁 Case files               branching thesis scenarios       (judgement)
├── 🕹️ Arcade                   short repeatable drills          (fluency)
├── 🧪 R Lab bench              downloadable labs + result-code check (real R)
├── 📚 Field guide              cheat sheets, flowchart, glossary, pitfalls, dataset dictionaries
├── 👤 Profile                  rank, XP, badges, skills radar, history, export/import, settings
├── 📋 Check-points             readiness check, pre-test, post-test, (delayed test)
├── 🧑‍🏫 Instructor (later)       cohorts, dashboards, item analytics
└── 🧭 Roadmap / About          roadmap, credits, versions, feedback
```

**Navigation rules:** one persistent top bar (HUD: streak, XP, rank, calm-mode toggle); every page shows "which skills does this train?"; every item links back to its skill; no dead ends: each result screen offers a next action ("review 3 weak skills", "start case file", "play arcade drill").

---

## 3. Key screens (wireframes)

### 3.1 Campus (home)

```
┌───────────────────────────────────────────────────────────────────────────┐
│ 🧭 Dungeons & Dataframes 🔥 5-day streak  ⭐ 640 XP  Epidemiologist ▓▓▓░  🏅 9 │
├───────────────────────────────────────────────────────────────────────────┤
│  Welcome back, Dr. A.            [ ▶ Continue: World 3 · Confounding Caves ]│
│                                                                           │
│  TODAY                                                                     │
│  ┌─ Daily review (5 items, ~6 min) ─┐ ┌─ Daily challenge ────────────────┐ │
│  │ due: VIF · centring · PI vs CI   │ │ Arcade: Interval Invaders  x2 XP │ │
│  │         [ Start review ]         │ │ Case file: "Village anomaly"  ▶  │ │
│  └──────────────────────────────────┘ └──────────────────────────────────┘ │
│  YOUR SKILLS  radar: Linear ■■■■□  Logistic ■■□□□  Assumptions ■■■□□ …     │
│  WORLD MAP  (0–16, current highlighted)                                    │
└───────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Skill tree

```
 Foundations ──► Linear ──► Inference ──► Confounding ──► Model building ──► Reporting
      │             │            │                                  ▲
      │             ├► Prediction/PI                                │
      │             └► R² / centring      Assumptions ──► Remedies ─┘
      └► Outcome types ──► Logistic ──► Likelihood ──► Calibration/ROC ──► OR vs PR
                    ├► Counts ──► Overdispersion ──► Rates/offsets
                    ├► Ordinal / Nominal
                    └► Survival ──► Cox ──► PH check
 (node colour = mastery: grey unseen · blue seen · amber practising · green proficient · gold mastered)
 click a node → what it means · prerequisites · items/case files/drills that train it · your history
```

### 3.3 Quest page (world)

```
┌ World 3 · Confounding Caves ───────────────── progress ▓▓▓▓░░ 5/9 ───────┐
│ Briefing (collapsible, live R output)                                      │
│ Level 1 ▸ items…   Level 2 ▸ items…   Level 3 ▸ items…   👑 Boss           │
│ Trains: confounding · crude-vs-adjusted · dummy coding · model building    │
│ Also in this world: [📁 Case file: The salt-study reviewer] [🕹️ Drills ×2] │
│ [🧪 Lab 3 (R)]                                                             │
└───────────────────────────────────────────────────────────────────────────┘
```

### 3.4 Case file

```
┌ 📁 CASE FILE 07 · "Reviewer #2 doesn't believe your odds ratio"  (20 min) ┐
│ Scenario: your cross-sectional NCD thesis reports "aOR 5.1: 50+ years are  │
│ 5 times as likely to be hypertensive". Evidence panel: [output] [Table 1]  │
│ Decision 1 of 5: What is the first problem you raise?      ○ … ○ … ○ …     │
│   → branch feedback ("Good: outcome prevalence is 32%, so …")              │
│ Decision 3: Write the corrected sentence (select the best from 4)          │
│ Score: judgement 4/5 · evidence used 3/4 · wording 5/5      +120 XP        │
└───────────────────────────────────────────────────────────────────────────┘
```

### 3.5 Arcade

```
 🕹️ ARCADE   [Residual Reader] [Interval Invaders] [OR↔PR Converter] [Spot the Pitfall] …
 Round 4/10   ⏱ optional   streak ×3
 ┌ plot (generated) ┐   Which assumption is violated?   ( ) linearity ( ) equal variance
 │ residuals vs fitted │   ( ) independence ( ) none     [ Lock in ]
 └────────────────────┘   score 340 · best 520 · skill: heteroscedasticity (proficient)
```

### 3.6 Profile

Rank + XP bar · skills radar and tree snapshot · badge shelf · pre/post gain chart · calibration (confidence vs accuracy) · activity heat-map · settings (calm mode, theme, text size, reduced motion) · **Export / Import / Reset** · (later) account, cohort.

---

## 4. The skill tree

### 4.1 Mastery model

| Level | Name | Rule |
|---|---|---|
| 0 | Unseen | No attempts |
| 1 | Seen | ≥ 1 attempt |
| 2 | Practising | ≥ 2 correct (any attempt count) |
| 3 | Proficient | ≥ 3 correct **first-try**, from ≥ 2 distinct items, ≥ 2 modes |
| 4 | Mastered | Proficient **and** one correct recall ≥ 7 days later |
| ↓ | Fading | No correct recall for 30 days → drops one level → enters the review queue |

Mastery uses **tags on items** (every item carries 1–3 skill ids), so quests, case-file decisions and arcade rounds all feed the same skill state.

### 4.2 Skill nodes (≈ 70; id = branch.node)

| Branch | Skills (prerequisites in brackets) |
|---|---|
| **F · Foundations** | F1 what regression models [–] · F2 outcome types [F1] · F3 model-choice flowchart [F2] · F4 correlation vs regression [F1] · F5 variable roles [F1] · F6 missing data & complete cases [F1] · F7 Table 1 reading [F5] |
| **L · Linear** | L1 slope in units [F4] · L2 intercept & extrapolation [L1] · L3 prediction [L1] · L4 CI vs PI [L3] · L5 residuals & OLS [L1] · L6 R² vs adjusted R² [L5] · L7 centring & scaling [L2] |
| **I · Inference** | I1 hypothesis test for β [L1] · I2 p-value meaning [I1] · I3 CI reading [I1] · I4 statistical vs clinical significance [I2, I3] |
| **C · Confounding & adjustment** | C1 confounder definition [I3] · C2 crude vs adjusted [C1] · C3 adjusted interpretation [C2] · C4 dummy coding & reference [L1] · C5 DAG reasoning [C1] · C6 mediator/collider [C5] |
| **M · Model building** | M1 purposeful selection [C2] · M2 DAG-driven selection [C5] · M3 stepwise: how & why not [M1] · M4 screening pitfalls (p < 0.2) [M1] · M5 events per variable [M1] |
| **A · Assumptions** | A1 linearity [L5] · A2 independence & clustering [L5] · A3 normality [L5] · A4 equal variance [L5] · A5 collinearity & VIF [C3] · A6 influence [L5] · A7 remedies (terms, robust SE, drop/combine) [A1–A6] |
| **G · Logistic** | G1 probability/odds/log-odds [F2] · G2 logit model [G1] · G3 why exponentiate [G2] · G4 OR & CI reading [G3] · G5 crude vs adjusted OR [G4, C2] · G6 OR ≠ risk (OR vs PR) [G4] · G7 getting PRs (Poisson-robust, log-binomial) [G6] |
| **K · Likelihood & fit** | K1 likelihood & deviance [G2] · K2 LR test [K1] · K3 Wald vs LR [K2] · K4 AIC [K1] · K5 pseudo-R² honesty [K1] · K6 calibration [G2] · K7 discrimination/ROC/AUC [G2] · K8 overfitting & validation [K7, M5] |
| **R · Reporting** | R1 annotated output [L1, G4] · R2 results sentences [R1] · R3 methods paragraph [R1] · R4 units & reference categories [C4] · R5 association vs causation [C5] · R6 tables & figures [R1] · R7 reviewer replies [R2–R6] |
| **N · Counts** | N1 count outcomes & Poisson [F3] · N2 rate ratios & offsets [N1] · N3 overdispersion [N1] · N4 negative binomial [N3] |
| **O · Ordinal / nominal** | O1 ordinal logistic [G4] · O2 proportional-odds check [O1] · O3 multinomial logistic [G4] |
| **S · Survival** | S1 censoring [F3] · S2 Kaplan–Meier [S1] · S3 Cox & hazard ratios [S2, G3] · S4 PH assumption [S3] |
| **V · Clusters** | V1 ICC & design effect [A2] · V2 random intercepts [V1] · V3 GEE & robust SE [V1] · V4 repeated measures [V2] |
| **W · Survey** | W1 weights, strata, PSUs [A2] · W2 weighted estimates [W1] · W3 design-based regression [W2] |
| **X · Curves & interaction** | X1 polynomials & splines [A1] · X2 effect modification [C3] · X3 plotting predictions [X1, X2] |
| **U · Missing data** | U1 MCAR/MAR/MNAR [F6] · U2 complete-case bias [U1] · U3 multiple imputation [U2] · U4 sensitivity analysis [U3] |
| **P · Prediction** | P1 apparent vs validated performance [K8] · P2 cross-validation/bootstrap [P1] · P3 shrinkage & penalised models [P2] · P4 risk-score reporting (TRIPOD) [P3] |
| **Z · Causal** | Z1 DAG building [C5] · Z2 propensity scores [Z1] · Z3 IPW [Z2] · Z4 mediation basics [C6] |
| **Ω · Capstone** | Ω1 analysis plan · Ω2 run & check · Ω3 write-up · Ω4 peer review [many] |

The tree is **data** (`skills.json`): adding a skill is a row, not code.

### 4.3 "What next?" recommender

1. Fading skills with the oldest due date → **daily review**.
2. Otherwise the unlocked skill with the lowest level whose prerequisites are ≥ Proficient.
3. Prefer a **mode the learner has used least** for that skill (Quest → Case file → Arcade).
4. Surface weak branches from the pre-test breakdown.

---

## 5. Game modes in detail

### 5.1 Quests (guided path)
Briefing (≤ 600 words, live R output) → 3–4 levels (≥ 8 items) → boss → world badge. Items types: MCQ, output-reading, numeric, order, spot-the-error (all built). Quests give the structure for first exposure.

### 5.2 Case files (judgement)

**Format:** YAML scenario → rendered as a branching page. Components: *scenario*, *evidence panels* (R output, Table 1, plot), *decision points* (single-choice, multi-select, "write the sentence"), *branch feedback*, *rubric scoring* (judgement / evidence used / wording), *debrief* with the expert path.

```yaml
id: cf-07
title: "Reviewer #2 doesn't believe your odds ratio"
skills: [G6, G7, R2, R5]
evidence: [{type: output, ref: or-vs-pr}, {type: table, ref: table1}]
decisions:
  - id: d1
    prompt: "What is the first problem you raise?"
    options: [ {text: "...", correct: true, feedback: "..."}, ... ]   # linter-checked like MCQs
    skills: [G6]
```

**Launch list (12 case files):**

| # | Case file | Skills | Hook |
|---|---|---|---|
| 1 | *The salt-study reviewer* | C2, C3, R5 | Crude vs adjusted; causal wording |
| 2 | *The village anomaly* | A2, V1 | Residuals cluster by village |
| 3 | *Two measures of fat* | A5, M2 | BMI + waist in one model |
| 4 | *The stepwise thesis* | M3, M4 | A thesis built on `step()` |
| 5 | *Reviewer #2 and the OR* | G6, G7, R2 | OR for a 32%-prevalence outcome |
| 6 | *Too many predictors* | M5, K8 | 60 variables, 40 events |
| 7 | *The curved age effect* | A1, X1 | U-shaped residuals |
| 8 | *Dengue by ward* | N2, N3 | Rates, offsets, overdispersion |
| 9 | *Time to treatment failure* | S1–S4 | Censoring, PH violation |
| 10 | *Weights in the NFHS table* | W1–W2 | Unweighted vs weighted prevalence |
| 11 | *Missing BMI* | U1–U3 | MAR missingness in the NCD survey |
| 12 | *Is the risk score any good?* | K6, K7, P1 | Apparent vs validated AUC |

### 5.3 Arcade (fluency)

Each game is a **generator** (new numbers/plots every round; deterministic from a seed) so skills can be drilled indefinitely. Rounds of 10; optional timer; difficulty adapts to mastery level.

| Game | Skill(s) | Mechanic |
|---|---|---|
| **Residual Reader** | A1, A3, A4, A6 | Generated residual plot → name the violated assumption |
| **Interval Invaders** | L4, L3 | Given CI/PI numbers and a question, shoot the right interval |
| **OR↔PR Converter** | G6 | Given prevalences, drag sliders to match OR and PR; learn how the gap grows |
| **Spot the Pitfall** | R2–R5, M4 | Flag flawed sentences in generated paragraphs (spot-the-error engine) |
| **Odds Dojo** | G1, G3 | Rapid conversion probability ↔ odds ↔ log-odds ↔ OR (numeric) |
| **VIF Duel** | A5 | From a correlation matrix choose which predictor to drop/keep |
| **Units Police** | L1, R4 | Fix reports lacking units/reference categories |
| **Model Match** | F2, F3 | Drag outcome descriptions onto the model flowchart |
| **DAG Builder** | C5, C6, Z1 | Place arrows from a story; the game computes the adjustment set |
| **Output Autopsy** | R1 | Click the number that answers a question in a long `summary()` |
| **p-value or not?** | I2, I4 | True/false rapid fire on p-value and CI statements |
| **Fit or Fade** | K2–K5 | Choose between models using LRT/AIC tables |

All arcade items obey the same quality standards (no recall, no giveaways) and feed skill mastery at a reduced weight (so drilling cannot "buy" mastery alone: Proficient needs ≥ 2 modes).

### 5.4 Daily review
Spaced queue: Leitner boxes with intervals 1–3–7–14–30 days; correct first-try promotes, otherwise demotes one box; capped at 5–8 items per day; shows *why* each skill is due.

---

## 6. The hybrid R lab bench

**Principle:** learners practise in **their own R** with the real packages; the site verifies via short **result codes**: no server, works offline, and codes are not transferable.

### 6.1 Flow

1. Open the world's **lab** (the existing fill-in-the-blank scripts, regenerated from solutions with `build_labs.R`).
2. `source("rqlab.R")` (or `library(rqlab)`) → `rq_start(seed = "dr-a-2026")`. The seed regenerates the dataset (or a subsample) so **numbers differ per learner**.
3. After each task: `rq_check("task-3", m_adj)` gives **instant local feedback** ("right outcome, wrong predictor") and costs nothing.
4. At the end: `rq_submit()` prints a **result code**, e.g. `RQ3-7F2K-91XA-Q0MD`: a hash of (lab id, lab version, seed, per-task results).
5. Paste the code into the site's **Lab bench** page; the page recomputes the hash from the task results encoded in the code's payload and awards XP + skill credit.

### 6.2 What is checked
Object exists and has the right class/formula; estimates within tolerance (relative 1%); required output produced; for write-up tasks a **self-check rubric** (checklist) instead of auto-grading.

### 6.3 Strengths and limits
* ✔ No server; real R; instant feedback; per-learner numbers.
* ✔ Same grader runs in CI against the solution (must pass) and the blank lab (must fail).
* ✖ A determined learner can forge a code (it is a hash, not a signature). Acceptable for self-learning; **credentialed attempts** use server-side verification in the accounts phase.
* Optional later: webR mode (R in the browser) after a package-compatibility spike; same checks, no copy-paste.

---

## 7. Progression and economy

| Source | XP |
|---|---|
| Quest items | ★ 10 / 20 / 30 × attempt factor − hints |
| Boss | +50 |
| Case file | up to 150 by rubric (judgement, evidence, wording) |
| Arcade round | up to 40, **diminishing returns** after 3 rounds/day per game |
| Daily review | 5 per correct first-try, no penalty for misses |
| Lab | 40–80 per verified lab |
| Pre/post tests | participation badge only (no XP, to keep them honest) |

* **Ranks** (6 now, extendable): Field Volunteer → … → Chief Biostatistician.
* **Daily challenge:** one case file or arcade game at ×2 XP (cap 1/day).
* **Streaks** with one **freeze** per week; calm mode hides streaks entirely.
* **Cosmetics only** for unlocks (themes, avatar frames, guide-character outfits): never gating learning.
* **Anti-grind:** XP per item pays once; arcade has diminishing returns; mastery needs ≥ 2 modes.

---

## 8. State and data design (static now, accounts later)

### 8.1 Principles
1. **Events are truth, totals are derived.** Store an append-only **event log** (attempt, hint, show-answer, review result, lab submitted, test submitted); recompute XP, mastery, rank and badges from it. This makes sync and re-balancing safe.
2. **Storage adapter interface** `{ load(), append(events), snapshot(), sync?() }` with a `LocalAdapter` today; `RemoteAdapter` later (same interface).
3. **Versioned schema + migrations** (`v: 2` …); import validates and migrates.
4. **Idempotent items:** an item pays XP once; replays are recorded but pay 0.
5. **Pseudonymous IDs**; no personal health data from learners.

### 8.2 Schema v2 (sketch)

```jsonc
{
  "v": 2, "learner": {"id": "uuid", "seed": "dr-a-2026", "created": "2026-10-14"},
  "settings": {"calm": false, "theme": "light", "reducedMotion": false, "textSize": 1},
  "events": [ {"t": 1760400000, "type": "attempt", "item": "w3-04", "mode": "quest", "ok": true, "hints": 1, "tries": 1},
              {"t": …, "type": "review", "skill": "A5", "ok": true},
              {"t": …, "type": "lab", "lab": "lab3", "code": "RQ3-…", "tasks": {"t1": true}},
              {"t": …, "type": "test", "kind": "pre", "score": 6, "total": 12, "byTag": {…}, "conf": {…}} ],
  "derived": {"xp": 640, "rank": "Epidemiologist", "badges": {…}, "skills": {"A5": {"level": 3, "box": 2, "due": "2026-10-21"}}}
}
```
`derived` is a cache that can always be rebuilt from `events`.

### 8.3 Accounts later: what changes (and what does not)
* **Unchanged:** content, engine logic, item markup, skills.json, event schema.
* **Added:** `RemoteAdapter` (sign-in via magic link/SSO), server endpoints for event append and snapshot, conflict policy (union of events by `(t, id)`; derived recomputed), instructor read-only views, server-side lab/code verification, consent and data-deletion endpoints (DPDP Act 2023).

---

## 9. Content specification

| Content type | Format | Source of truth | Quality gate |
|---|---|---|---|
| Items | R list in `bank/*.R` | bank + `skills.json` | `lint_bank.R` (standards in Roadmap §6.2) |
| Item generators (arcade) | R/JS pairs with seed | `bank/generators/` | Unit tests: deterministic, answer recomputed in R |
| Case files | YAML | `bank/casefiles/` | Linter: every decision lints as an item; evidence refs resolve; ≥ 3 skills |
| Briefings | Quarto text with live R | `worlds/` | Review + render |
| Labs | Solution scripts with `#@` markers | `solutions/` | CI: solution passes, blank fails |
| Skills | `skills.json` | one file | Graph check: acyclic, every skill has ≥ 8 items across ≥ 2 modes |
| Datasets | `make_data_*.R` | scripts | Feature checks must pass |

**Content targets by end of Phase 5 (Track 1 only):** 70 skills · ≥ 8 items each (≈ 600 items) · 12 case files · 12 arcade games · 16 quests · 16 hybrid labs · 2 parallel test forms per world.

---

## 10. Technology

* **Stay static and vanilla:** Quarto pages + modular ES modules (`engine/`, `modes/`, `ui/`) bundled without a framework; no runtime dependencies; offline-first; optional PWA.
* **Refactor `quest.js`** into modules in Phase 2: `state` (events, derive), `items` (renderers), `modes` (quest, casefile, arcade, review), `skills` (graph, recommender), `adapters` (local, remote), `ui` (HUD, toasts, tree).
* **Skill-tree rendering:** inline SVG generated from `skills.json` (no library), keyboard navigable.
* **Arcade generators:** plots pre-generated as SVG/PNG variants at build time (R) for the first release; client-side generation later for numeric games.
* **Accessibility:** WCAG 2.2 AA; all interactions keyboard operable; no colour-only cues; reduced-motion honoured; screen-reader labels for tree nodes and drag-like items (button alternatives exist).
* **Performance budget:** < 150 KB JS, < 60 KB CSS per page; pages usable on low-end phones.
* **English only:** strings kept in one place for maintainability; no translation planned.

---

## 11. Look, feel and voice

* A friendly guide character (**"Dr. Beta"**) gives hints and debriefs: short, kind, never sarcastic about mistakes.
* Visual style: clean field-medicine palette (navy/teal/amber), generous spacing, large touch targets, one accent for "correct", one for "try again" (never red-only).
* Microcopy: feedback explains *why* (“The OR is 5.1 but 50% of the exposed group have the outcome, so …”) before saying *do this*.
* **Calm mode:** no streaks, ranks, toasts or timers; XP hidden; mastery shown as plain checkmarks.

---

## 12. Build plan for the site (maps onto Roadmap phases)

| Step | Deliverable | Roadmap phase | Exit criteria |
|---|---|---|---|
| **A. Foundations** | `skills.json`; tag all 40 current items with skills; state v2 (events + derived); `LocalAdapter`; migration from v1 | 2 | v1 progress migrates; mastery recomputes identically from events |
| **B. Campus shell** | Home, profile, skill tree (SVG), daily-review queue, recommender, settings (calm mode) | 2 | Tree reflects mastery; review queue works with a mocked clock; E2E tests green |
| **C. Content wave 1** | Worlds 3–6 quests; readiness check; 2 case files | 2 | ≥ 8 items/skill for F, L, I, C, M, A, G, K, R branches; linter clean |
| **D. Arcade** | Engine + 6 games (Residual Reader, Interval Invaders, OR↔PR Converter, Spot the Pitfall, Odds Dojo, Model Match) | 3 | Generators deterministic; answers recomputed in R; diminishing returns tested |
| **E. Case-file engine** | YAML → page renderer, rubric scoring, linter, 4 case files | 3 | Branching tested; rubric XP verified |
| **F. Hybrid labs** | `rqlab` helper, result-code verification page, labs for worlds 1–6 | 4 | CI proves solution ⇒ code verifies; blank lab ⇒ fails |
| **G. Content wave 2** | Worlds 7–14 + case files 5–12 + remaining arcade games | 3–4 | Dataset feature checks pass; statistician sign-off |
| **H. Causal + capstone** | World 15–16, DAG Builder, peer-review flow | 5 | Pilot capstones completed |
| **I. Accounts & instructor** | `RemoteAdapter`, dashboard, server verification | 6 | Cohort pilot; privacy review |

**Testing at every step:** extend the existing suites (hash parity, quest E2E, leak scan, linters); add *tree/mastery unit tests*, *review-queue clock tests*, *case-file branching tests*, *arcade generator determinism tests*, and *accessibility scans*.

---

## 13. Open questions

1. ~~Name~~ **Decided: Dungeons & Dataframes** (D&D pun; tagline: *medical statistics in R, one dungeon at a time*). Not checked for trademark/domain availability.
2. ~~Language scope~~ **Decided: English only.**
3. ~~Who reviews statistics~~ **Decided: the author (community-medicine faculty)**; optional external statistician check before wide release.
4. **Pilot cohort:** which residents/department, and when can a first cohort test Worlds 1–2 and the pre/post forms?
5. ~~Credentialing~~ **Decided: completion certificate is a later priority** (needs accounts and server verification; Phase 6).
6. **R environment:** Posit Cloud, local RStudio, or both, for the hybrid labs?
7. **Dataset licensing:** open-license the simulated datasets and item bank?
