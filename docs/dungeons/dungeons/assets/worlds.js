/* worlds.js — registry of every region and world on the quest map (playable + planned).
   The game starts from the basics: Region 1 → 2 → 3 → 4 (see SITE_PLAN.md Part 2 and ROADMAP.md).
   Add a world: append a row with its region; set status:'playable' + total once its page exists.
   `read` = the "📖 Read first" library pages (site-relative, rendered in this same site). */
window.RQ_HOME = 'index.html';
window.RQ_REGIONS = [
  { id: 'r1', title: 'Region 1 · Basics', blurb: 'Your first script, tidy data, joins, first plots and choosing a test. No statistics background needed.' },
  { id: 'r2', title: 'Region 2 · Moderate', blurb: 'Messy data, loops, exploring with pictures, Table 1 and tests in context.' },
  { id: 'r3', title: 'Region 3 · Regression', blurb: 'From "what is regression?" to reporting a logistic model for your thesis.' },
  { id: 'r4', title: 'Region 4 · Advanced', blurb: 'Survival, counts, clusters, surveys, missing data, prediction and causal thinking.' }
];
window.RQ_WORLDS = [
  // ── Region 1 · Basics (literature: Basic track) ──
  { id: 'b1', region: 'r1', icon: '📜', title: 'Your First Script', blurb: 'RStudio, projects, objects, reading a CSV, looking at data.', status: 'playable', total: 9, href: 'b1_first_script.html', requires: 'r1pre:1', read: [['../r-foundations/getting-started.html', 'Getting Started']] },
  { id: 'b2', region: 'r1', icon: '🍺', title: 'Tidy Tavern', blurb: 'filter, select, mutate, group and summarise; factors and missing values.', status: 'playable', total: 9, href: 'b2_tidy_tavern.html', requires: 'b1:60', read: [['../r-foundations/data-wrangling.html', 'Data Wrangling']] },
  { id: 'b3', region: 'r1', icon: '🔗', title: 'Join Junction', blurb: 'Joining and reshaping datasets without losing or duplicating rows.', status: 'playable', total: 9, href: 'b3_join_junction.html', requires: 'b2:60', read: [['../r-foundations/merging_dataset.html', 'Merging Datasets']] },
  { id: 'b4', region: 'r1', icon: '🎨', title: 'First Plots', blurb: 'The grammar of graphics; histogram, boxplot, bar and scatter: which and why.', status: 'playable', total: 9, href: 'b4_first_plots.html', requires: 'b3:60', read: [['../data-visualization/ggplot_grammar.html', 'Grammar of Graphics'], ['../plot-gallery/basic.html', 'Basic Plot Gallery']] },
  { id: 'b5', region: 'r1', icon: '⚖️', title: 'Which Test?', blurb: 'Matching question and data type to a test; reading a p-value and a CI.', status: 'playable', total: 9, href: 'b5_which_test.html', requires: 'b4:60', read: [['../statistical-analysis/statistical_tests.html', 'Test Selection Guide']] },
  // ── Region 2 · Moderate (literature: Moderate track) ──
  { id: 'm1', region: 'r2', icon: '🧹', title: 'Messy Data Dungeon', blurb: 'Cleaning real-world data: types, labels, duplicates, impossible values.', status: 'soon', phase: 'later' },
  { id: 'm2', region: 'r2', icon: '🌀', title: 'Loop Labyrinth', blurb: 'Doing the same thing to 20 variables: loops, across() and small functions.', status: 'soon', phase: 'later' },
  { id: 'm3', region: 'r2', icon: '🔭', title: 'Explore by Picture', blurb: 'Exploratory plots that find problems before models do.', status: 'soon', phase: 'later' },
  { id: 'm4', region: 'r2', icon: '🏛️', title: 'Table 1 Forge', blurb: 'Descriptive tables with gtsummary, and reading them honestly.', status: 'soon', phase: 'later', read: [['../gtsummary/gtsummary_tutorial.html', 'gtsummary Tables']] },
  { id: 'm5', region: 'r2', icon: '🧪', title: 'Tests in Context', blurb: 'Running and reporting tests on survey data, with assumptions.', status: 'soon', phase: 'later' },
  // ── Region 3 · Regression (literature: Regression track) ──
  { id: 'w1', region: 'r3', icon: '🕵️', title: 'World 1 · The Outcome Detective', blurb: 'What regression is, outcome types, choosing a model, Table 1, missing data.', status: 'playable', total: 8, href: 'world1_outcome_detective.html', requires: 'pre:1', read: [['../regression-workshop/s1_foundations.html', 'Session 1 deck']] },
  { id: 'w2', region: 'r3', icon: '📏', title: 'World 2 · The Straight Line', blurb: 'Slope in units, prediction, CI vs PI, residuals, R², centering.', status: 'playable', total: 8, href: 'world2_straight_line.html', requires: 'w1:60', read: [['../regression-workshop/s2_simple_regression.html', 'Session 2 deck']] },
  { id: 'w3', region: 'r3', icon: '🧩', title: 'World 3 · Confounding Caves', blurb: 'Inference, adjustment, dummy variables, model-building strategies.', status: 'playable', total: 9, href: 'world3_confounding_caves.html', requires: 'w2:60', read: [['../regression-workshop/s3_multiple_regression.html', 'Session 3 deck']] },
  { id: 'w4', region: 'r3', icon: '🩻', title: 'World 4 · Assumption Ruins', blurb: 'Linearity, independence, normality, variance, collinearity.', status: 'playable', total: 9, href: 'world4_assumption_ruins.html', requires: 'w3:60', read: [['../regression-workshop/s4_assumptions.html', 'Session 4 deck']] },
  { id: 'w5', region: 'r3', icon: '🎲', title: 'World 5 · Odds Arena', blurb: 'Logistic regression, likelihood, ROC, OR vs PR.', status: 'playable', total: 9, href: 'world5_odds_arena.html', requires: 'w4:60', read: [['../regression-workshop/s5_logistic_regression.html', 'Session 5 deck']] },
  { id: 'w6', region: 'r3', icon: '✍️', title: 'World 6 · The Reporting Guild', blurb: 'Annotated output, write-ups, pitfalls, reviewer-proofing.', status: 'playable', total: 9, href: 'world6_reporting_guild.html', requires: 'w5:60', read: [['../regression-workshop/s6_reporting.html', 'Session 6 deck'], ['../regression-workshop/cheatsheet.html', 'Cheat sheet']] },
  // ── Region 4 · Advanced (each module: workshop first, then worlds; SITE_PLAN §2.6) ──
  { id: 'w9', region: 'r4', icon: '⏳', title: 'Survival Summit', blurb: 'Kaplan–Meier, Cox, proportional hazards.', status: 'soon', phase: 'A1' },
  { id: 'w7', region: 'r4', icon: '🔢', title: 'Count Country', blurb: 'Poisson, negative binomial, offsets and rates.', status: 'soon', phase: 'A2' },
  { id: 'w8', region: 'r4', icon: '🪜', title: 'Ordinal & Nominal Outcomes', blurb: 'Ordinal and multinomial logistic regression.', status: 'soon', phase: 'A3' },
  { id: 'w10', region: 'r4', icon: '🏘️', title: 'Villages & Clusters', blurb: 'Mixed models and GEE for clustered data.', status: 'soon', phase: 'A4' },
  { id: 'w11', region: 'r4', icon: '🧭', title: 'Survey Science', blurb: 'Weights, strata, PSUs: NFHS-type complex surveys.', status: 'soon', phase: 'A5' },
  { id: 'w12', region: 'r4', icon: '〰️', title: 'Curves & Interactions', blurb: 'Splines, GAMs, effect modification.', status: 'soon', phase: 'A6' },
  { id: 'w13', region: 'r4', icon: '🕳️', title: 'Missing Data', blurb: 'MCAR/MAR/MNAR, multiple imputation, sensitivity.', status: 'soon', phase: 'A7' },
  { id: 'w14', region: 'r4', icon: '🔮', title: 'Prediction Models', blurb: 'Validation, calibration, TRIPOD, penalised regression.', status: 'soon', phase: 'A8' },
  { id: 'w15', region: 'r4', icon: '🧠', title: 'Causal Thinking', blurb: 'DAGs, propensity scores, IPW, mediation.', status: 'soon', phase: 'A9' },
  { id: 'w16', region: 'r4', icon: '🎓', title: 'Capstone: Your Thesis', blurb: 'Plan, analyse and write up your own dataset, with peer review.', status: 'soon', phase: 'Capstone' }
];
