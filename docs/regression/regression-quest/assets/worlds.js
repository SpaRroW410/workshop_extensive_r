/* worlds.js — registry of every world on the quest map (playable + planned).
   Add a world: append a row; set status:'playable' + total once its page exists.
   Keep in sync with ROADMAP.md (phase column). */
window.RQ_HOME = 'index.html';
window.RQ_WORLDS = [
  { id: 'w1', icon: '🕵️', title: 'World 1 · The Outcome Detective', blurb: 'What regression is, outcome types, choosing a model, Table 1, missing data.', status: 'playable', total: 8, href: 'world1_outcome_detective.html', requires: 'pre:1' },
  { id: 'w2', icon: '📏', title: 'World 2 · The Straight Line', blurb: 'Slope in units, prediction, CI vs PI, residuals, R², centering.', status: 'playable', total: 8, href: 'world2_straight_line.html', requires: 'w1:60' },
  { id: 'w3', icon: '🧩', title: 'World 3 · Confounding Caves', blurb: 'Inference, adjustment, dummy variables, model-building strategies.', status: 'playable', total: 9, href: 'world3_confounding_caves.html', requires: 'w2:60' },
  { id: 'w4', icon: '🩻', title: 'World 4 · Assumption Ruins', blurb: 'Linearity, independence, normality, variance, collinearity.', status: 'playable', total: 9, href: 'world4_assumption_ruins.html', requires: 'w3:60' },
  { id: 'w5', icon: '🎲', title: 'World 5 · Odds Arena', blurb: 'Logistic regression, likelihood, ROC, OR vs PR.', status: 'playable', total: 9, href: 'world5_odds_arena.html', requires: 'w4:60' },
  { id: 'w6', icon: '✍️', title: 'World 6 · The Reporting Guild', blurb: 'Annotated output, write-ups, pitfalls, reviewer-proofing.', status: 'playable', total: 9, href: 'world6_reporting_guild.html', requires: 'w5:60' },
  { id: 'w7', icon: '🔢', title: 'World 7 · Count Country', blurb: 'Poisson, negative binomial, offsets and rates.', status: 'soon', phase: 'Phase 3' },
  { id: 'w8', icon: '🪜', title: 'World 8 · Ordinal & Nominal Outcomes', blurb: 'Ordinal and multinomial logistic regression.', status: 'soon', phase: 'Phase 3' },
  { id: 'w9', icon: '⏳', title: 'World 9 · Survival Summit', blurb: 'Kaplan–Meier, Cox, proportional hazards.', status: 'soon', phase: 'Phase 3' },
  { id: 'w10', icon: '🏘️', title: 'World 10 · Villages & Clusters', blurb: 'Mixed models and GEE for clustered data.', status: 'soon', phase: 'Phase 3' },
  { id: 'w11', icon: '🧭', title: 'World 11 · Survey Science', blurb: 'Weights, strata, PSUs: NFHS-type complex surveys.', status: 'soon', phase: 'Phase 3' },
  { id: 'w12', icon: '🌀', title: 'World 12 · Curves & Interactions', blurb: 'Splines, GAMs, effect modification.', status: 'soon', phase: 'Phase 4' },
  { id: 'w13', icon: '🕳️', title: 'World 13 · Missing Data', blurb: 'MCAR/MAR/MNAR, multiple imputation, sensitivity.', status: 'soon', phase: 'Phase 4' },
  { id: 'w14', icon: '🔮', title: 'World 14 · Prediction Models', blurb: 'Validation, calibration, TRIPOD, penalised regression.', status: 'soon', phase: 'Phase 4' },
  { id: 'w15', icon: '🧭', title: 'World 15 · Causal Thinking', blurb: 'DAGs, propensity scores, IPW, mediation.', status: 'soon', phase: 'Phase 5' },
  { id: 'w16', icon: '🎓', title: 'World 16 · Capstone: Your Thesis', blurb: 'Plan, analyse and write up your own dataset, with peer review.', status: 'soon', phase: 'Phase 5' }
];
