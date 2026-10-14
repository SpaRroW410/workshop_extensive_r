## 1. Vision and principles

**Goal:** turn the one-day *Theory of Regression Analysis* workshop into a **game for learning medical statistics in R** (**Dungeons & Dataframes**): a self-paced, gamified, *tested* environment for community-medicine residents and faculty. The platform is organised into **tracks**; **Track 1 is Regression** (the worlds in §3), and further tracks follow (§1.1). Within Regression, a learner goes from "I can run `lm()`" to "I can plan, run, check and report the right regression for my thesis", and on into the models the workshop only names.

**Scope decisions (v3):**

* **Platform = medical statistics in R; regression is its first track.** Name: **Dungeons & Dataframes** (deliberately not regression-specific). Worlds can be presented as *dungeons*.
* **R basics are a prerequisite.** Learners are assumed to have basic-to-moderate R (import data, tidyverse verbs, simple plots, run a model and read `summary()`); a short **readiness check** (§2.3) advises anyone who is not ready (it points to the repo's existing R Foundations track).
* **English only.** It is a coding place; no translation work is planned.
* **Certificate: later.** Completion certificates are a later-phase priority (Phase 6, with accounts and server verification).
* **Reviewer:** content and statistics are reviewed by the author (community-medicine faculty); an optional external statistician check can be added before wide release.
* **Hosting:** static now, accounts later. R practice: hybrid (§7).

The full site design (information architecture, game modes, skill tree, hybrid R labs, state model) is in [Site design](site-design.qmd).

| Principle | What it means in practice |
|---|---|
| **Learning first, game second** | Points reward *understanding* (first-try accuracy, no hints), never time spent or guessing. |
| **Test what matters** | Interpretation, judgement and error-spotting beat function recall. No "which function does X?" items. |
| **Honest assessment** | No giveaways: balanced option lengths, no "all of the above", shuffled display, no key-first markup, explanations only after an attempt. Enforced by a linter in CI. |
| **Real public-health context** | Indian community-medicine scenarios and datasets (NCD survey, TB cohort, dengue counts, NFHS-type surveys). |
| **Depth over breadth, track by track** | No detours into general R teaching; each track goes deep (Track 1: modelling, interpretation, checking and reporting) before the next opens. |
| **Three ways to practise** | *Quests* (guided path), *Case files* (realistic thesis scenarios with decisions), *Arcade* (short repeatable drills): so mastery comes from varied retrieval, not one pass. |
| **Real R, hybrid** | Learners also run real R on the project datasets; the game checks results through verifiable codes (no server needed), with in-browser R as an optional later mode. |
| **Works anywhere** | Static files, offline-capable, no login needed for the core path; optional server features come later. |
| **Evidence of gain** | Every learner gets a baseline (pre-test) and a parallel post-test; the project measures learning gain, not just completion. |
| **Reproducible content** | One source of truth per item and per lab; everything built and verified by scripts. |

**Non-goals (for now):** replacing a biostatistician, covering every statistical method in the first release, teaching R itself, translations, high-stakes certification (that needs proctoring and a server).

---

### 1.1 Platform tracks

The skill tree and engine are **track-agnostic**: a track is a set of worlds, skills, items, case files and arcade games.

| Track | Focus | Status |
|---|---|---|
| **1 · Regression** | Linear, logistic, counts, survival, clusters, surveys, missing data, prediction, causal (Worlds 1–16, §3) | ✅ started (Worlds 1–2 playable) |
| **2 · Comparing groups** | t-tests, non-parametric tests, chi-square/Fisher, ANOVA, choosing a test, multiple testing, effect sizes | ⬜ planned |
| **3 · Epidemiological measures** | Risk/odds/rate ratios, attributable fractions, standardisation, confounding by stratification (Mantel–Haenszel), screening metrics | ⬜ planned |
| **4 · Study design & sample size** | Sampling, power and precision, randomisation, bias catalogue, cluster designs, reporting standards | ⬜ planned |
| **5 · Survey & health-systems analytics** | Complex surveys, weights, small-area rates, time series for surveillance | ⬜ planned |
| **6 · Evidence synthesis & diagnostics** | Meta-analysis, heterogeneity, diagnostic accuracy, decision curves | ⬜ planned |
| **7 · Reproducible reporting** | Quarto, tables/figures, STROBE/CONSORT, thesis workflow | ⬜ planned |

Tracks unlock independently after the readiness check; a learner can start in any track whose prerequisite skills they hold.

---

## 2. Audience and learning outcomes

### 2.1 Personas

| Persona | Needs | Path |
|---|---|---|
| **Resident writing a thesis** | Right model, correct interpretation, reviewer-proof write-up | Core worlds 1–6, then 10, 11, 13, capstone |
| **Faculty / examiner** | Judge others' analyses; spot pitfalls | Pitfall bosses, reporting world, spot-the-error items |
| **Public-health programme officer** | Count and survey data, dashboards | Worlds 7, 11, 14 |
| **Self-taught R user** | Concepts behind the code | Readiness check, pre-test, then skip to weak skills |
| **Facilitator** | Run a cohort, see who is stuck | Cohort mode and instructor dashboard (Phase 6) |

### 2.2 Programme-level outcomes (ILOs)

After the full path a learner can:

1. **Choose** a regression family from the outcome type and study design, and justify it.
2. **Fit and interpret** linear, logistic, count, ordinal/nominal and survival models in units, with CIs.
3. **Adjust** for confounding using causal reasoning (DAGs) rather than significance filtering.
4. **Diagnose** and respond to violations (linearity, independence, variance, normality, collinearity, influence, proportional hazards).
5. **Evaluate** models (likelihood ratio, AIC, calibration, discrimination, validation).
6. **Handle** real-data problems: clustering, complex survey design, missing data, non-linearity, interaction.
7. **Report** to publication standards (STROBE/TRIPOD, units, reference categories, honest language).
8. **Critique** published analyses and **avoid** the nine standard pitfalls.

Outcomes are mapped to Bloom levels (remember → evaluate) per world in §3 and drive the item mix in §6.

### 2.3 Prerequisites and the readiness check

**Assumed:** basic-to-moderate R: projects/scripts, `read_csv`, `dplyr` verbs (filter, mutate, group/summarise), factors, `ggplot2` basics, running `lm()`/`glm()` and printing `summary()`. **Not assumed:** any regression theory.

**Readiness check (≈ 10 minutes, ungraded):** 8 short items (reading a `mutate`/`summarise` pipeline, spotting a factor-level problem, interpreting a plot, reading a `summary()` table) plus 2 hands-on R tasks. Outcome: **Ready** → straight to the pre-test; **Nearly** → a 5-item brush-up list of skills plus links to the existing R Foundations pages; **Not yet** → R Foundations first. The check never blocks anyone: it advises.

---

## 3. Curriculum map (all worlds)

**Status:** ✅ playable now · 🟡 content exists as workshop slides/labs, needs gamified conversion · ⬜ new content. Worlds are *story containers*; the real unit of progress is the **skill** (see the skill tree in [Site design](site-design.qmd)), and every world's items, case files and arcade drills are tagged to skills.

| # | World | Core topics | Key dataset | Boss (capstone item) | Phase | Status |
|---|---|---|---|---|---|---|
| – | *Readiness check* (replaces former World 0) | R prerequisites only; routes learners (§2.3) | NCD survey (raw) | n/a (advisory) | 2 | ⬜ |
| 1 | **The Outcome Detective** | What regression is; outcome types; flowchart; correlation vs regression; Table 1; missing data | NCD survey | Table 1 write-up inspector | 1 | ✅ |
| 2 | **The Straight Line** | Slope in units; prediction; CI vs PI; residuals/OLS; R²/adj R²; centring/scaling | NCD survey | Interpretation inspector | 1 | ✅ |
| 3 | **Confounding Caves** | β/p/CI; statistical vs clinical significance; confounding; adjustment; dummy coding; model-building (DAG vs stepwise) | NCD survey | Rebuild a confounded analysis | 2 | 🟡 |
| 4 | **Assumption Ruins** | Linearity, independence, normality, equal variance, collinearity, influence; remedies | NCD survey | Diagnose five residual-plot "crime scenes" | 2 | 🟡 |
| 5 | **Odds Arena** | Odds/log-odds; why exponentiate; likelihood, LRT, AIC; pseudo-R²; calibration/ROC; OR vs PR | NCD survey | Convert an OR story into a PR story | 2 | 🟡 |
| 6 | **The Reporting Guild** | Annotated output; results/methods wording; nine pitfalls; reviewer replies | NCD survey | Reviewer #2 simulator | 2 | 🟡 |
| 7 | **Count Country** | Poisson; overdispersion; negative binomial; offsets and rates; zero inflation (mention) | Dengue counts per ward-month | Rate ratio for a ward-level intervention | 3 | ⬜ |
| 8 | **Ordinal & Nominal Outcomes** | Ordinal logistic; proportional-odds check; multinomial logistic; baseline category logic | BP stage; place-of-delivery survey | Choose and interpret ordinal vs multinomial | 3 | ⬜ |
| 9 | **Survival Summit** | Censoring; Kaplan–Meier; log-rank; Cox; hazard ratios; PH assumption; time-varying covariates (mention) | DOTS TB cohort | Fix a violated PH assumption | 3 | ⬜ |
| 10 | **Villages & Clusters** | ICC, design effect; random intercepts (`lme4`); GEE (`geepack`); cluster-robust SE; repeated measures | NCD survey (villages) + repeated BP visits | Compare naive vs mixed vs GEE | 3 | ⬜ |
| 11 | **Survey Science** | Weights, strata, PSUs; `survey`/`srvyr`; weighted proportions and regression; NFHS-style design | NFHS-type synthetic survey | Weighted vs unweighted prevalence ratios | 3 | ⬜ |
| 12 | **Curves & Interactions** | Splines, GAMs, polynomials; effect modification; centred interactions; plotting predictions | NCD survey | Is the salt effect different by sex? | 4 | ⬜ |
| 13 | **Missing Data** | MCAR/MAR/MNAR; complete-case bias; multiple imputation (`mice`); sensitivity analysis | NCD survey with MAR missingness | Imputation report card | 4 | ⬜ |
| 14 | **Prediction Models** | Apparent vs validated performance; bootstrap/CV; calibration; shrinkage; lasso/ridge (`glmnet`); sample size for prediction; TRIPOD | Diabetes screening cohort | Build, validate and report a risk score | 4 | ⬜ |
| 15 | **Causal Thinking** | DAGs; confounder/mediator/collider; propensity scores; IPW; mediation basics; E-values | Observational programme-evaluation data | Draw the DAG, then pick the estimator | 5 | ⬜ |
| 16 | **Capstone: Your Thesis** | Analysis plan, SAP template, run, check, report, peer review | Learner's own (de-identified) or provided | Peer-reviewed mini-manuscript | 5 | ⬜ |

### 3.1 Elective track (any time after World 5)

| Elective | Topics |
|---|---|
| **E1 Sample size & power for regression** | Events-per-variable, precision-based planning, simulation-based power |
| **E2 Diagnostic accuracy** | Sensitivity/specificity, ROC, likelihood ratios, decision curves |
| **E3 Interrupted time series** | Segmented regression, autocorrelation, seasonality |
| **E4 Meta-regression & evidence synthesis** | Random-effects models, heterogeneity, meta-regression basics |
| **E5 Bayesian regression** | Priors, posteriors, `brms`, credible vs confidence intervals |
| **E6 Regression vs machine learning** | Trees/forests/boosting vs GLMs; when interpretability wins |
| **E7 Reproducible regression reporting** | Quarto, dynamic tables with `gtsummary`/`modelsummary`, STROBE checklists (R-basics refreshers are out of scope) |
| **E8 Spatial and small-area analysis** | Mapping rates, spatial autocorrelation, hierarchical smoothing |
| **E9 Quasi-experiments** | Difference-in-differences, regression discontinuity, synthetic controls (intro) |

### 3.2 Per-world design template (every world must provide)

1. **Briefing** (≤ 600 words + live R output): concept, one worked example, one common misconception.
2. **Levels** (3–4): ≥ 8 items per world at difficulty 1–3, mixed types (MCQ, numeric, order, spot-the-error, output-reading).
3. **Boss**: one multi-part or spot-the-error item, 50 bonus XP.
4. **Case file**: at least one realistic thesis scenario with decision points (§5.4 and Site design §5).
5. **Arcade drills**: ≥ 2 repeatable drill generators tied to the world's skills.
6. **Lab**: hybrid R lab (fill-in script + verifiable result codes; Phase 4).
7. **Misconception log**: 3–5 documented wrong beliefs, each with ≥ 1 diagnostic item.
8. **Parallel items** for the pre/post forms (≥ 2 per world).
9. **Facilitator notes**: answer keys, timing, discussion prompts.

---

## 4. Datasets plan

| Dataset | Used in | Built-in teaching features | Status |
|---|---|---|---|
| **NCD survey** (n = 600, 20 villages) | Worlds 0–6, 10, 12, 13 | Confounding, collinearity, heteroscedasticity, curvature, clustering, common outcome, 3% missing | ✅ exists (`make_data.R`) |
| **Dengue ward-month counts** | World 7 | Overdispersion, exposure offset (population), seasonality, zero inflation | ⬜ |
| **BP-stage and delivery-site survey** | World 8 | Ordinal (proportional odds holds/fails), nominal outcome | ⬜ |
| **DOTS TB cohort** | World 9 | Censoring, non-proportional hazards for one covariate, competing outcome (mention) | ⬜ |
| **Repeated-visit BP clinic data** | World 10 | Within-person correlation, random slopes, missing visits | ⬜ |
| **NFHS-style complex survey** | World 11 | Stratification, PSUs, unequal weights, design effects | ⬜ |
| **Missing-data variants of NCD** | World 13 | MCAR vs MAR vs MNAR versions of the same data | ⬜ |
| **Diabetes screening cohort** | World 14 | Many candidate predictors, low EPV trap, optimism | ⬜ |
| **Programme evaluation (observational)** | World 15 | Known confounding structure and ground-truth causal effect | ⬜ |

**Rules for every dataset:** simulated with a documented seed; a `make_data_*.R` that **prints a feature check and fails if a teaching feature disappears**; a data dictionary; "ground truth" parameters stored for facilitators; no real patient data in the public repo.

**Per-learner variation (Phase 4):** a learner seed changes sample draws so numeric answers differ; hashes then depend on the seed (see §9.3).

---

## 5. Gamification design

### 5.1 XP economy

| Element | Rule |
|---|---|
| Base XP | Difficulty ★ = 10, ★★ = 20, ★★★ = 30 |
| Attempt factor | First try ×1, second ×0.5, later ×0.25 |
| Hints | Tiered (−3, −5, −8 XP); a world's hints never reveal the answer text |
| Show answer | 0 XP (never punished beyond that) |
| Boss | +50 XP bonus |
| Streak | Daily; bonus badges at 3 and 7 days; **no XP for streak itself** (avoids grinding) |
| Cap | An item pays out once (re-solving gives nothing) |

### 5.2 Ranks

Field Volunteer (0) → Health Worker (100) → Medical Officer (250) → Epidemiologist (500) → Senior Epidemiologist (900) → Chief Biostatistician (1500). Thresholds are retuned from pilot data so a median learner reaches *Epidemiologist* by the end of World 6.

### 5.3 Badge catalogue (rules are data in `quest.js`)

* **Progress:** First Blood, world-clear badges (one per world), Elective Explorer
* **Mastery (tag-based):** Confounder Catcher, VIF Vanquisher, Odds Whisperer, Calibration Captain, Residual Reader, Weight Watcher (survey), Hazard Handler, Imputation Inspector
* **Behaviour:** Unaided (10 first-try, no hints), Pitfall Spotter (spot-the-error), Honest Estimator (well-calibrated confidence)
* **Growth:** Baseline Set, Growth Mindset (post-test done), Big Gain (+20 points)
* **Community (Phase 6):** Peer Reviewer, Mentor

### 5.4 Game modes, bosses and events

The site has **three play modes** (details in [Site design](site-design.qmd) §4–6):

* **Quests:** the guided world-by-world path (briefing → levels → boss).
* **Case files:** 15–25 minute branching investigations (e.g. *"The salt study reviewer"*, *"The village anomaly"*): read output, choose actions, defend choices; scored by rubric.
* **Arcade:** short repeatable drills built from generators (*Residual Reader*, *Interval Invaders*, *OR↔PR Converter*, *Spot the Pitfall* …) so a skill can be rehearsed with fresh numbers each time.
* **Daily review:** a spaced queue (Leitner boxes) of the skills that are due or fading.
* **Boss fights:** each world ends with a multi-part scenario; failing is cheap, retrying free.
* **Seasonal events (optional):** e.g. *Thesis Month* with double-XP review quests.

### 5.5 Social, optional and safe

Cohort leaderboards are **opt-in and off by default** for residents; show relative *growth*, not just totals; team quests (pair review of each other's analysis plan). No public ranking of identifiable learners without consent.

### 5.6 Anti-gaming

* Hashing is anti-peeking only. For anything that counts (certificates), use server-side checking with signed attempts (Phase 6).
* Randomised option order; per-learner numeric seeds; item pools (several parallel versions of each item).
* Rate-limited hints; "show answer" forfeits XP; first-try rule stops trial-and-error farming.
* Analytics flag implausibly fast completions.

### 5.7 Inclusive game design

All feedback is colour-independent (icons and text); `prefers-reduced-motion` honoured; keyboard-operable everything; a **"calm mode"** with no streaks, toasts or ranks for learners who find gamification stressful.

---

## 6. Assessment design and the item bank

### 6.1 Item types

| Type | Best for | Status |
|---|---|---|
| **MCQ** (single best answer, shuffled) | Concepts, interpretation | ✅ |
| **Output-reading MCQ** (code/output in stem) | Reading real output | ✅ |
| **Numeric** (rounded tolerance) | Calculation: odds, PR, VIF, predictions, df | ✅ |
| **Fill-in (short text)** | Naming a concept (never a function recall) | ✅ |
| **Order the steps** | Workflows, derivations | ✅ |
| **Spot the error** (flag flawed sentences) | Reporting pitfalls, interpretation | ✅ |
| **Click-the-plot** (hotspot on a diagnostic plot) | Diagnostics | ⬜ Phase 3 |
| **Slider / parameter play** | OR vs PR, CI width, R² vs n | ⬜ Phase 3 |
| **Match** (drag outcome type to model) | Flowchart | ⬜ Phase 3 |
| **Free-text with rubric** | Write-ups (self-check against model answer; instructor scoring later) | ⬜ Phase 4 |
| **Code lab check** (auto-graded R) | Applied skills | ⬜ Phase 4 |
| **Multi-select (select all that apply)** | Assumption checklists | ⬜ Phase 3 |

### 6.2 Item-writing standards (hard rules, linted)

1. **Never** make the key the longest option; keep option lengths within ±25% and within a 2.5× overall ratio.
2. **No** "all/none/both of the above"; no absolute words (*always, never, only, exactly*) in distractors alone.
3. **No function-recall questions** (e.g. "which function does `mutate`?", "which argument gives odds ratios?"). Ask what a result **means**, what to **do**, or **compute** something.
4. Answers must not appear in the stem, in a hint, or be implied by stem-key word overlap.
5. Key position is irrelevant: markup order is permuted at build time (so the source never lists the key first) and display order is shuffled at run time.
6. Every distractor is a **real misconception** from the world's misconception log, not a throwaway.
7. Every item has: world, 1–3 skill tags, difficulty 1–3, an explanation that teaches, and 1–3 non-revealing hints.
8. Stems are self-contained, in a public-health context, and avoid trick wording or double negatives.
9. Numeric items use values away from rounding ties; state the rounding in the stem.
10. Explanations appear only after an attempt or an explicit *Show answer*.

### 6.3 Quality gates

* `lint_quizzes.R` (workshop decks) and `lint_bank.R` (quest bank) must pass in CI: zero hard failures.
* Peer review checklist for each new item (two reviewers: a content expert and a "naïve" learner).
* **Hash-parity tests** between R and JS for every item type; Playwright tests for every interaction.

### 6.4 Pre-/post-testing

* Two **parallel forms** (A/B), 12 items each, mapped to the same skill tags; difficulty-balanced.
* Confidence rating per answer (Guess/Probably/Certain) → calibration feedback ("you were certain and wrong on 3 items").
* Output: skill-by-skill profile → recommended next worlds → **post-test gain** (percentage points and normalised gain).
* Planned extension: Form C for a delayed (3-month) retention test.

### 6.5 Psychometrics (once ≥ 100 learners)

* Item difficulty (p-value), discrimination (point-biserial), **distractor analysis** (is any distractor never chosen?), time-on-item.
* Retire or rewrite items with discrimination < 0.15 or difficulty outside 0.2–0.9.
* Differential item functioning by background (R vs no-R experience) to detect unfair items.
* Mastery model: a skill is "mastered" after 3 correct first-try items across ≥ 2 sessions (spaced).

---

## 7. Auto-graded R labs (the biggest build)

### 7.1 Options

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| **`learnr` + `gradethis`** (Shiny) | Mature, real R, hints/solutions built in | Needs a Shiny server or shinyapps.io | Good for cohort deployments |
| **webR / Quarto-live** | R in the browser, static hosting, offline | Some packages unavailable/heavy (check `gtsummary`, `performance`) | Optional later mode (Phase 5), after a package-compatibility spike |
| **Local scripts + verifiable result codes (hybrid)** | Real RStudio workflow, real packages, no server, works offline | Codes can be shared unless seeded per learner | **Chosen for Phases 3–4** |

### 7.1b The hybrid design (chosen)

Learners work in their own R (RStudio/Posit Cloud) on the repo's labs. A tiny helper package/script (`rqlab`) provides `rq_start(seed)`, `rq_check("task-3", obj)` for instant local feedback, and `rq_submit()` which prints a **short result code** (task results hashed with the learner's seed and a lab version). The learner pastes the code into the site; the site verifies it and awards XP. No server, works offline, and the per-learner seed makes codes non-transferable. Details: [Site design](site-design.qmd) §6.

### 7.2 Pipeline (reuses what exists)

1. Solution scripts remain the single source of truth (`#@` markers define blanks).
2. A **grader generator** produces `testthat`/gradethis checks per task: object exists, class/formula correct, estimate within tolerance, output text pattern.
3. **Tiered hints** per task (concept → structure → near-answer), each costing XP.
4. **Tolerance policy:** numeric checks use relative tolerance (e.g. 1%); string checks normalise case and whitespace; accept equivalent formulas (`y ~ x1 + x2` ≡ `y ~ x2 + x1`).
5. **Seeded variants:** the learner seed regenerates the dataset, and checks compute expected values from the same seed.
6. CI runs every solution through the grader to prove *solution ⇒ all checks pass* and *blank lab ⇒ checks fail*.

### 7.3 Fairness and safety

Sandboxed execution only (webR runs in the browser); time limits; no network; clear, non-punitive error messages ("your model has the right outcome but the wrong predictor").

---

## 8. Platform architecture

### 8.1 Today (static, serverless)

```
Quarto pages (html)  →  quest.js (engine)  →  localStorage (progress)
        ↑                      ↑
  bank/items.R ──render──> hashed markup (answers never in source)
```

* Hosting: GitHub Pages (already used by the repo); decks and pages work offline once downloaded.
* Progress: per-browser; export/import JSON backup.

### 8.1b Hosting decision (v2): static now, accounts later

Phases 1–5 stay fully static on GitHub Pages. To make accounts a *later add-on rather than a rewrite*, the engine must be built now around a **storage adapter** (`load/save/sync`), an **append-only event log**, **XP and mastery recomputed from events/items** (never stored as authoritative totals), and **versioned state with migrations**. Specified in [Site design](site-design.qmd) §8.

### 8.2 Target architecture (phased)

| Layer | Phase 1–3 | Phase 5–6 |
|---|---|---|
| Content | Quarto + R item bank | + item metadata DB, versioned item IDs |
| Engine | `quest.js`, localStorage | + sync adapter (same state schema) |
| Identity | None | Optional sign-in (institutional SSO / magic link) |
| Storage | Browser | Postgres/Supabase (or Firebase) with row-level security |
| Grading | Client hashes | Server-side check for credentialed attempts; signed results |
| Analytics | None | Privacy-preserving event log, instructor dashboard |
| Interop | None | xAPI/LRS or LTI 1.3 for LMS embedding |

### 8.3 Cross-cutting requirements

* **State schema versioning** (`v` field already present) with migration functions.
* **Privacy:** India's DPDP Act 2023 and institutional ethics: explicit consent, data minimisation, pseudonymous IDs, export/delete on request, no health data from learners.
* **Accessibility:** WCAG 2.2 AA (contrast, focus order, keyboard-only play, screen-reader labels, no colour-only cues), automated axe checks plus manual audit.
* **Performance and offline:** each page under ~1 MB of JS/CSS; optional PWA for full offline use in low-connectivity settings.
* **Language:** English only. Keep strings in one place for maintainability, but no translation work is planned.
* **Mobile first:** all item types operable by touch (order-items need drag + buttons).
* **Security:** no secrets client-side; CSP headers; never execute learner code outside the sandbox.

---

## 9. Engineering and QA

### 9.1 Repository layout (target)

```
regression-quest/
  bank/           items by world (one file each), metadata, form definitions
  worlds/         one qmd per world + briefings
  labs/           student labs, graders, solutions (generated)
  assets/         quest.js, quest.R, css, worlds.js
  tools/          lint_bank.R, parity tests, build scripts, analytics notebooks
  tests/          Playwright E2E, unit tests (hash/XP/streak/badge logic)
  ROADMAP.md      this file
```

### 9.2 Continuous integration (GitHub Actions)

1. `Rscript lint_bank.R` and `lint_quizzes.R` → fail on any hard rule.
2. `Rscript run_solutions.R` and every dataset's `make_data_*.R` feature check.
3. R↔JS **hash parity** test across all item types.
4. Render all pages (Quarto) with warnings as errors.
5. Playwright E2E: engine behaviour, shuffling, XP/streak/badges, gates, test mode, export/import, **no answers in page source**.
6. axe accessibility scan; link check; bundle-size budget.
7. Publish to Pages only if all green.

### 9.3 Engine test matrix (must pass before each release)

| Area | Tests |
|---|---|
| Hash parity | R and JS produce identical hashes for MCQ/fill/num/order/spot |
| Shuffle | Display order varies; key still validated by authored index; markup order never key-first |
| XP rules | First/second/third try factors; hint costs; show-answer = 0; boss bonus; idempotent re-load |
| Streaks | Same day, next day, gap reset (mocked clock) |
| Badges | Each rule fires once; persists; world-clear needs the boss |
| Gates | Locked until pass mark; override works; map shows state |
| Test mode | No feedback; confidence; per-tag breakdown; pre→post gain |
| Persistence | Reload keeps state; export→import round trip; corrupt file rejected |
| Leak scan | Page source contains no answers, explanations or hint text in clear |

### 9.4 Statistical correctness review

Every briefing, item and explanation is reviewed by the author (community-medicine faculty) for correctness, with an optional external statistician check before wide release; numeric answers are *computed in R in the build* (never hand-typed) wherever they depend on data; and any claim about data ("OR 5.1, PR 3.1") is generated from the dataset at render time.

---

## 10. Content production workflow

1. **Spec** the world (objectives, misconceptions, dataset, boss).
2. **Draft** briefing + items in the bank; run the linters locally.
3. **Review**: content expert + learner-pilot read-through; fix ambiguity.
4. **Build** the world page and lab; run solutions and graders.
5. **Pilot** with 5–10 residents (think-aloud); collect item stats.
6. **Release** behind a feature flag; monitor item analytics for two weeks.
7. **Maintain**: yearly review for R/package changes and clinical-example currency.

**Style guide highlights:** units always stated; reference category always named; "associated with" not "causes"; Indian public-health examples (NFHS, NCD screening, TB, dengue, ANC); gender-neutral language; short sentences.

---

## 11. Phased roadmap

Effort is in person-weeks (PW) for one developer + one content author/reviewer (community-medicine faculty); timelines assume part-time academic capacity and can compress with more people.

### Phase 0 — Done: foundation (✔)
* Full-day workshop: 6 decks, 6 labs with solutions, quiz engine, simulated NCD dataset, cheat sheet.
* Quiz quality gate (`lint_quizzes.R`) and shuffled options in the existing decks.

### Phase 1 — Quest engine and first worlds (✔ built in this folder, ~6 PW)
* `quest.js`: five item types, XP, hints, streaks, ranks, badges, gates, test mode, export/import.
* Item bank + linter; Worlds 1–2; pre-test (Form A) and post-test (Form B); quest map and roadmap page.
* **Exit criteria:** linter 0 failures; engine test matrix green; a pilot of 5 learners completes Worlds 1–2 without help.

### Phase 2 — Core curriculum conversion and the Campus shell (Q1–Q2, ~14 PW)
* Convert Worlds 3–6 from the workshop (briefings, ≥ 8 items each, bosses).
* **Site shell:** Campus home, skill tree, profile, daily-review queue, storage adapter + state v2 with migration (see Site design §8, §12).
* Readiness check (replaces the former World 0).
* Complete pre/post forms across all core worlds; add per-skill recommendations.
* Cheat-sheet and facilitator pack unified under the quest brand.
* **Exit:** 56+ new items, all linted; pre/post gain measured on a pilot of 20+ residents.

### Phase 3 — Arcade, case files and new models (Q2–Q3, ~18 PW)
* **Arcade** with 6+ drill generators; **case-file engine** (branching YAML scenarios) with 4 case files.
* New item types: click-the-plot, slider/parameter-play, match, multi-select.
* Worlds 7–11 (counts, ordinal/nominal, survival, clusters, surveys) with their datasets.
* Spaced-retrieval "daily five"; mastery model by tag.
* **Exit:** item analytics dashboard (notebook) running on pilot data; accessibility audit passed.

### Phase 4 — Hybrid R labs and personalisation (Q3–Q4, ~14 PW)
* `rqlab` helper package, result-code verification on the site, a lab for every world; grader generated from solutions; tiered hints.
* Per-learner seeds and item pools; free-text rubric self-check.
* Worlds 12–14 (curves/interactions, missing data, prediction models).
* **Exit:** all labs gradeable; CI proves solution passes and blank fails; webR package compatibility documented.

### Phase 5 — Causal thinking, capstone and electives (Q4–Q5, ~14 PW)
* World 15 (causal), World 16 capstone with analysis-plan template and peer review.
* Electives E1–E9 (prioritised by demand).
* Case-file quests; reviewer-simulator bosses.
* **Exit:** 10 learners complete the capstone; rubric inter-rater agreement measured.

### Phase 6 — Cohort mode and credentials (Q5–Q6, ~16 PW)
* Optional sign-in, sync, instructor dashboard, cohort leaderboards (opt-in), xAPI/LTI.
* Server-side grading and signed attempts for certificates.
* **Completion certificate** (needs accounts + server verification), PWA/offline bundle, calm mode refinements.
* **Exit:** a department runs a full cohort with the dashboard; DPDP/ethics review documented.

### Phase 7 — Evaluate, publish, sustain (continuous)
* Learning-gain study (pre/post, 3-month retention), gamification A/B (e.g. streaks vs calm mode).
* Publication in a medical-education journal; open-licence the item bank; contribution guide.
* Yearly content and dependency refresh.

### Timeline at a glance

| Quarter | Milestones |
|---|---|
| Q0 | Workshop + quest engine + Worlds 1–2 + pre/post (**now**) |
| Q1 | Campus shell + skill tree + review queue; Worlds 3–4; readiness check; pilot 1 |
| Q2 | Worlds 5–6; arcade + case-file engine; Worlds 7–8 |
| Q3 | Worlds 9–11; analytics; accessibility audit |
| Q4 | Hybrid R labs (`rqlab`); Worlds 12–14 |
| Q5 | Causal + capstone; electives start; cohort-mode design |
| Q6 | Sign-in, dashboard, certificate/credentials; study write-up |

---

## 12. Risks and mitigations

| Risk | Likelihood / impact | Mitigation |
|---|---|---|
| **Gamification replaces learning** (chasing XP) | Medium / High | First-try rule, no streak XP, calm mode, mastery-based unlocks, track learning gain not points |
| **Leaky or guessable items** | High / High | Linter in CI, balanced options, shuffled display and markup, peer review, distractor analysis |
| **Answers shared** (static hashes) | High / Medium | Item pools, per-learner seeds, server grading for credentials |
| **webR package gaps** | Medium / High | Early compatibility spike (`gtsummary`, `performance`, `see`, `pROC`); fall back to learnr or local graders |
| **Content errors** (statistics) | Medium / High | Statistician review, computed (not typed) numbers, errata process |
| **Authoring bottleneck** | High / Medium | Templates, linters, item generators for numeric families, community contributions |
| **Low engagement / drop-off** | Medium / Medium | Short levels, daily five, pilots, cohort mode, instructor nudges |
| **Accessibility gaps** | Medium / Medium | WCAG checks in CI, manual audits, keyboard-only testing |
| **Privacy/regulatory** | Low–Medium / High | Local-first default, consent, minimal data, DPDP review before any server |
| **R/package drift** | High / Low–Medium | Pin versions in CI (`renv`), yearly refresh, solution-runner regression tests |
| **Scope creep** | High / Medium | Phase gates with exit criteria; electives only after core is stable |

---

## 13. Success metrics

| Metric | Target |
|---|---|
| **Learning gain** (post − pre, percentage points) | ≥ +25 median; normalised gain ≥ 0.4 |
| Core-path completion (Worlds 1–6) | ≥ 60% of those who start World 1 |
| 3-month retention (Form C vs post) | ≤ 10-point drop |
| Item health | ≥ 90% of items with discrimination ≥ 0.2 after 100 learners |
| Over-confidence | Share of "certain but wrong" answers falls pre → post |
| Accessibility | 0 critical axe violations; keyboard-only completion verified |
| Quality | 0 hard linter failures on `main`; CI green before every publish |
| Satisfaction | ≥ 4/5 usefulness; ≥ 80% would recommend |
| Reach | Departments/institutions using it; capstones completed |

---

## 14. Backlog / idea parking lot

* "Reviewer #2" simulator: a bot-free scripted rebuttal game with scored replies.
* **Mistake museum:** a gallery of real-world (anonymised) analysis errors to diagnose.
* Interactive confounding sandbox: draw a DAG, simulate, watch crude vs adjusted estimates.
* Live **OR ↔ PR** and **CI ↔ PI** explorers.
* Printable certificates and a skills passport (tags mastered).
* Pair-programming quests; instructor "spot check" mode for classroom use.
* Voice-over/short video briefings; transcript for every clip.
* Teaching-assistant chatbot restricted to the item bank's explanations (with safeguards).
* Open data challenge: learners contribute new simulated scenarios with feature checks.
* Dark mode and large-text themes.

---

## 15. Definitions of done

**An item is done when:** it passes the linter; has world, tags, difficulty, explanation and hints; distractors map to real misconceptions; two reviewers approved it; numeric answers are computed in R; the hash-parity test passes; and a pilot learner read it without clarification questions.

**A world is done when:** briefing + ≥ 8 items (all types appropriate to the topic) + boss + lab with grader + two parallel items for the pre/post forms; objectives mapped to ILOs; statistician sign-off; accessibility checked; pilot with ≥ 5 learners; analytics shows no broken items.

**A phase is done when:** its exit criteria are met, CI is green, the roadmap is updated, and a short retrospective is recorded.

---

## 16. Next four weeks

1. Pilot Worlds 1–2 and the pre/post forms with 5 residents; capture think-aloud notes and item timings.
2. Write the World 3 (*Confounding Caves*) bank: ≥ 8 items, boss, misconception log.
3. Prototype `rqlab` (`rq_start`, `rq_check`, `rq_submit`) for one lab and the code-verification box on the site.
4. Add the Playwright suite and the R↔JS parity test to CI.
5. Draft the **readiness check** (8 items + 2 R tasks) and the skill-tree node list; prototype the skill tree page on the existing 40 items.
6. Decide the hosting/privacy stance for Phase 6 (local-first stays the default).
