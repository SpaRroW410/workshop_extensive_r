/* ═══════════════════════════════════════════════════════════════════════
 * skills.js — the skill tree (data) + mastery, review and recommender logic.
 * Pure functions of (state, tagmap, today): no DOM, unit-tested in Node
 * (tests/skills_test.js). quest.js draws the Campus page from this.
 *
 * A skill = { id, branch, name, req: [prerequisite ids], tags: [item tags] }.
 * Items carry tags; a skill's evidence is every recorded item with one of its tags.
 * Add a skill = add a row. Skills with no tags yet are shown as "no items yet".
 *
 * RQ_TAGMAP (emitted by campus.qmd from the bank) = { tag: { worldId: nItems } }
 * gives how many items exist per skill and in which worlds (for the
 * Proficient threshold and the "where to practise" links).
 * ═══════════════════════════════════════════════════════════════════════ */
(function (root) {
  'use strict';
  var BRANCHES = [
    ['B', 'Basics (Region 1)'], ['F', 'Foundations'], ['L', 'Linear'], ['I', 'Inference'], ['C', 'Confounding & adjustment'],
    ['M', 'Model building'], ['A', 'Assumptions'], ['G', 'Logistic'], ['K', 'Likelihood & fit'], ['R', 'Reporting']
  ];
  var PLANNED = ['N · Counts', 'O · Ordinal / nominal', 'S · Survival', 'V · Clusters', 'W · Survey', 'X · Curves & interaction', 'U · Missing data', 'P · Prediction', 'Z · Causal', 'Ω · Capstone'];
  var S = function (id, name, req, tags) { return { id: id, branch: id.charAt(0), name: name, req: req || [], tags: tags || [] }; };
  var SKILLS = [
    S('B6', 'Objects, vectors and types', [], ['r-objects']), S('B5', 'Projects, scripts and importing data', [], ['projects', 'import']),
    S('B2', 'Factors and levels', ['B6'], ['factors']), S('B4', 'Missing values', ['B6'], ['missing-values']),
    S('B1', 'Writing a dplyr pipeline', ['B5'], ['r-pipeline', 'summarise', 'mutate']), S('B7', 'Joining and stacking tables', ['B1'], ['joins']),
    S('B8', 'Choosing a plot', [], ['plot-choice']), S('B9', 'Building a ggplot', ['B8'], ['ggplot', 'plots']),
    S('B10', 'Choosing a test', [], ['test-choice']), S('B11', 'Running and reading a t-test or chi-square test', ['B10'], ['t-test', 'chi-square']),
    S('B3', 'Reading a summary() table', ['B1'], ['summary-table']),
    S('F1', 'What regression models', [], ['workflow']), S('F2', 'Outcome types', ['F1'], ['outcome-type']), S('F3', 'Model-choice flowchart', ['F2'], ['flowchart']),
    S('F4', 'Correlation vs regression', ['F1'], ['regression-vs-correlation']), S('F5', 'Variable roles', ['F1'], ['variable-roles']),
    S('F6', 'Missing data and complete cases', ['F1'], ['missing-data']), S('F7', 'Reading Table 1', ['F5'], ['table1']),
    S('L1', 'Slope in units', ['F4'], ['slope-units']), S('L2', 'Intercept and extrapolation', ['L1'], []), S('L3', 'Prediction', ['L1'], ['prediction']),
    S('L4', 'CI vs prediction interval', ['L3'], ['ci-pi']), S('L5', 'Residuals and OLS', ['L1'], ['residuals']), S('L6', 'R² vs adjusted R²', ['L5'], ['r-squared']),
    S('L7', 'Centring and scaling', ['L2'], ['centering']),
    S('I1', 'Hypothesis test for a slope', ['L1'], []), S('I2', 'What a p-value means', ['I1'], ['significance']), S('I3', 'Reading a CI', ['I1'], []),
    S('I4', 'Statistical vs clinical significance', ['I2', 'I3'], ['clinical-relevance']),
    S('C1', 'What a confounder is', ['I3'], ['confounding']), S('C2', 'Crude vs adjusted', ['C1'], ['crude-vs-adjusted']), S('C3', 'Interpreting adjusted estimates', ['C2'], []),
    S('C4', 'Dummy coding and reference', ['L1'], ['dummy-coding']), S('C5', 'DAG reasoning', ['C1'], ['dag', 'causation']), S('C6', 'Mediators and colliders', ['C5'], ['mediator']),
    S('M1', 'Purposeful selection', ['C2'], ['model-building']), S('M2', 'DAG-driven selection', ['C5'], ['dag']), S('M3', 'Stepwise: how and why not', ['M1'], ['stepwise']),
    S('M4', 'Screening pitfalls (p < 0.2)', ['M1'], []), S('M5', 'Events per variable', ['M1'], ['events-per-variable']),
    S('A1', 'Linearity', ['L5'], ['linearity']), S('A2', 'Independence and clustering', ['L5'], ['independence', 'clustering']), S('A3', 'Normality', ['L5'], ['normality']),
    S('A4', 'Equal variance', ['L5'], ['equal-variance']), S('A5', 'Collinearity and VIF', ['C3'], ['collinearity', 'vif']), S('A6', 'Influence', ['L5'], ['influence', 'outliers']),
    S('A7', 'Remedies', ['A1', 'A2', 'A3', 'A4', 'A5', 'A6'], ['remedies', 'diagnostics']),
    S('G1', 'Probability, odds, log-odds', ['F2'], ['odds', 'log-odds']), S('G2', 'The logit model', ['G1'], ['logistic']), S('G3', 'Why we exponentiate', ['G2'], []),
    S('G4', 'Reading an OR and its CI', ['G3'], ['odds-ratio', 'or']), S('G5', 'Crude vs adjusted OR', ['G4', 'C2'], []), S('G6', 'OR is not a risk ratio', ['G4'], ['or-vs-pr']),
    S('G7', 'Getting prevalence ratios', ['G6'], []),
    S('K1', 'Likelihood and deviance', ['G2'], []), S('K2', 'Likelihood-ratio test', ['K1'], ['model-comparison']), S('K3', 'Wald vs LR', ['K2'], []),
    S('K4', 'AIC', ['K1'], ['aic']), S('K5', 'Pseudo-R² honesty', ['K1'], ['pseudo-r2']), S('K6', 'Calibration', ['G2'], ['calibration']),
    S('K7', 'Discrimination and AUC', ['G2'], ['roc']), S('K8', 'Overfitting and validation', ['K7', 'M5'], ['overfitting']),
    S('R1', 'Annotated output', ['L1', 'G4'], []), S('R2', 'Results sentences', ['R1'], ['reporting']), S('R3', 'Methods paragraph', ['R1'], []),
    S('R4', 'Units and reference categories', ['C4'], []), S('R5', 'Association vs causation', ['C5'], ['causation']), S('R6', 'Tables and figures', ['R1'], []),
    S('R7', 'Reviewer replies', ['R2', 'R5'], ['reviewer-reply'])
  ];
  var BYID = {}; SKILLS.forEach(function (s) { BYID[s.id] = s; });
  // tuning (the bank is still thin; see ROADMAP): Proficient = this many first-try, no-hint solves, capped by items available
  var PROFICIENT_N = 3, FADE_DAYS = 30, PRACTISING_N = 2;

  function dayDiff(a, b) { return Math.round((new Date(b) - new Date(a)) / 864e5); }
  function clean(r) { return r.solved && !r.shown; }
  function firstTry(r) { return clean(r) && r.tries === 1 && !r.hints; }

  /* evidence for one skill: item records that carry any of its tags */
  function evidence(state, skill) {
    var out = [];
    for (var id in state.items) { var r = state.items[id], hit = false;
      for (var i = 0; i < (r.tags || []).length; i++) if (skill.tags.indexOf(r.tags[i]) >= 0) { hit = true; break; }
      if (hit) out.push(r); }
    return out;
  }
  /* items that exist in the bank for this skill, and the worlds that hold them */
  function bank(skill, tagmap) {
    var worlds = {}, n = 0;
    skill.tags.forEach(function (t) { var m = (tagmap || {})[t] || {}; for (var w in m) { worlds[w] = (worlds[w] || 0) + m[w]; n += m[w]; } });
    return { n: n, worlds: Object.keys(worlds).sort() };
  }
  /* level 0 unseen · 1 seen · 2 practising · 3 proficient (4 mastered needs spaced review mode: Phase 3).
     fading = proficient/practising but no correct activity for FADE_DAYS: shown, and queued for review. */
  function mastery(state, skill, tagmap, today) {
    var ev = evidence(state, skill), b = bank(skill, tagmap), solved = 0, first = 0, last = null;
    ev.forEach(function (r) { if (clean(r)) { solved++; if (r.last && (!last || r.last > last)) last = r.last; } if (firstTry(r)) first++; });
    var need = Math.max(1, Math.min(PROFICIENT_N, b.n || PROFICIENT_N)), level = 0;
    if (ev.length) level = 1;
    if (solved >= Math.min(PRACTISING_N, Math.max(1, b.n))) level = 2;
    if (first >= need && solved >= need) level = 3;
    var fading = level >= 2 && last && today && dayDiff(last, today) >= FADE_DAYS;
    return { level: level, solved: solved, first: first, need: need, seen: ev.length, items: b.n, worlds: b.worlds, last: last, fading: !!fading, empty: b.n === 0 };
  }
  function all(state, tagmap, today) { var m = {}; SKILLS.forEach(function (s) { m[s.id] = mastery(state, s, tagmap, today); }); return m; }
  /* unlocked = every prerequisite is Practising+ (or has no items yet, so it cannot block) */
  function unlocked(skill, m) { return skill.req.every(function (p) { return m[p].empty || m[p].level >= 2; }); }

  /* review queue: fading skills, oldest activity first */
  function dueReview(state, tagmap, today, cap) {
    var m = all(state, tagmap, today);
    return SKILLS.filter(function (s) { return m[s.id].fading; })
      .sort(function (a, b) { return (m[a.id].last < m[b.id].last) ? -1 : 1; }).slice(0, cap || 5)
      .map(function (s) { return { skill: s, m: m[s.id], why: 'No correct answer for ' + dayDiff(m[s.id].last, today) + ' days' }; });
  }
  /* what next? 1) weak tags from the pre-test, 2) lowest-level unlocked skills that have items.
     Within a tier: least-started first, then branch order. Skills already Proficient are skipped. */
  function recommend(state, tagmap, today, cap) {
    var m = all(state, tagmap, today), weak = {};
    var pre = state.tests && state.tests.pre;
    if (pre) for (var t in pre.byTag) if (pre.byTag[t][0] < pre.byTag[t][1]) weak[t] = true;
    var bi = {}; BRANCHES.forEach(function (b, i) { bi[b[0]] = i; });
    var cand = SKILLS.filter(function (s) { return !m[s.id].empty && m[s.id].level < 3 && unlocked(s, m); }).map(function (s) {
      var isWeak = s.tags.some(function (t) { return weak[t]; });
      return { skill: s, m: m[s.id], weak: isWeak, why: isWeak ? 'You missed this in the pre-test' : (m[s.id].level === 0 ? 'Not started yet' : 'Keep going: ' + m[s.id].first + ' of ' + m[s.id].need + ' first-try solves') };
    });
    cand.sort(function (a, b) { return (b.weak - a.weak) || (a.m.level - b.m.level) || (bi[a.skill.branch] - bi[b.skill.branch]) || (a.skill.id < b.skill.id ? -1 : 1); });
    return cand.slice(0, cap || 3);
  }
  /* skills behind the tags a test result got wrong (not already Proficient), earliest branch first */
  function missed(state, byTag, tagmap, today, cap) {
    var m = all(state, tagmap, today), bi = {}; BRANCHES.forEach(function (b, i) { bi[b[0]] = i; });
    var out = SKILLS.filter(function (s) { return !m[s.id].empty && m[s.id].level < 3 && s.tags.some(function (t) { return byTag[t] && byTag[t][0] < byTag[t][1]; }); })
      .sort(function (a, b) { return (bi[a.branch] - bi[b.branch]) || (a.id < b.id ? -1 : 1); });
    return out.slice(0, cap || 6).map(function (s) { return { skill: s, m: m[s.id] }; });
  }
  var api = { missed: missed, SKILLS: SKILLS, BYID: BYID, BRANCHES: BRANCHES, PLANNED: PLANNED, mastery: mastery, all: all, unlocked: unlocked, dueReview: dueReview, recommend: recommend, FADE_DAYS: FADE_DAYS };
  if (typeof module !== 'undefined' && module.exports) module.exports = api; else root.RQ_SK = api;
})(typeof window !== 'undefined' ? window : this);
