// Unit tests for assets/skills.js (mastery, fading, review queue, recommender). Run: node regression-quest/tests/skills_test.js
const SK = require('../assets/skills.js');
let fails = 0; const ok = (c, m) => { console.log((c ? 'PASS ' : 'FAIL ') + m); if (!c) fails++; };
const TM = { confounding: { w3: 1 }, 'crude-vs-adjusted': { w3: 1 }, 'slope-units': { w2: 4 }, 'regression-vs-correlation': { w1: 1 }, workflow: { w1: 1, w3: 1 } };
const item = (tags, o) => Object.assign({ world: 'w1', tags, solved: true, tries: 1, hints: 0, shown: false, last: '2026-03-01' }, o || {});
const st = items => ({ v: 1, items, badges: {}, streak: {}, tests: {} });
const L = (state, id, today) => SK.mastery(state, SK.BYID[id], TM, today || '2026-03-02');

ok(L(st({}), 'L1').level === 0, 'no records → level 0 (unseen)');
ok(L(st({ a: item(['slope-units'], { solved: false, tries: 0 }) }), 'L1').level === 1, 'record without a solve → level 1 (seen)');
const four = {}; for (let i = 0; i < 4; i++) four['s' + i] = item(['slope-units']);
ok(L(st(four), 'L1').level === 3, '≥3 first-try clean solves → level 3 (proficient)');
const hinted = {}; for (let i = 0; i < 4; i++) hinted['s' + i] = item(['slope-units'], { hints: 1 });
ok(L(st(hinted), 'L1').level === 2, 'solved but with hints → practising only');
const shown = {}; for (let i = 0; i < 4; i++) shown['s' + i] = item(['slope-units'], { shown: true });
ok(L(st(shown), 'L1').level === 1, 'show-answer solves give no mastery');
ok(L(st({ a: item(['confounding']) }), 'C1').level === 3, 'a skill with 1 item in the bank is proficient after 1 first-try solve (threshold capped by items available)');
ok(L(st({ a: item(['confounding'], { tries: 2 }) }), 'C1').level === 2, 'one second-try solve of a 1-item skill → practising, not proficient');
ok(L(st({}), 'I1').empty === true, 'skill without tags is flagged empty');

// fading
const old = st({ a: item(['confounding'], { last: '2026-01-01' }) });
ok(L(old, 'C1', '2026-03-02').fading === true, 'no correct answer for 60 days → fading');
ok(L(old, 'C1', '2026-01-20').fading === false, 'recent activity → not fading');
const due = SK.dueReview(old, TM, '2026-03-02', 5);
ok(due.length === 1 && due[0].skill.id === 'C1' && /60 days/.test(due[0].why), 'review queue lists the fading skill with a reason');
const o2 = st({ a: item(['confounding'], { last: '2026-01-01' }), b: item(['slope-units'], { last: '2025-12-01' }), c: item(['slope-units'], { last: '2025-12-01' }) });
const d2 = SK.dueReview(o2, TM, '2026-03-02', 5).map(x => x.skill.id);
ok(d2[0] === 'L1' && d2.includes('C1'), 'oldest activity is reviewed first: ' + d2);

// prerequisites and recommender
const m0 = SK.all(st({}), TM, '2026-03-02');
ok(SK.unlocked(SK.BYID.L1, m0) === false, 'L1 locked while F4 (has items) is unseen');
ok(SK.unlocked(SK.BYID.I1, m0) === false || SK.BYID.I1.req.every(r => m0[r].empty || m0[r].level >= 2), 'unlock rule consistent');
ok(SK.unlocked(SK.BYID.F1, m0) === true, 'skills without prerequisites are unlocked');
const r0 = SK.recommend(st({}), TM, '2026-03-02', 3).map(x => x.skill.id);
ok(r0.length > 0 && r0.every(id => SK.BYID[id].req.length === 0 || SK.BYID[id].req.every(p => m0[p].empty || m0[p].level >= 2)), 'fresh learner: only unlocked skills are recommended: ' + r0);
const weak2 = st({ f1: item(['workflow']), f4: item(['regression-vs-correlation']), f1b: item(['workflow'], { tries: 2 }) }); weak2.tests.pre = { byTag: { confounding: [0, 1] } };
const rw2 = SK.recommend(weak2, TM, '2026-03-02', 3);
ok(rw2[0] && rw2[0].skill.id === 'C1' && rw2[0].weak, 'a skill missed in the pre-test is ranked first: ' + rw2.map(x => x.skill.id));
const done = st({ a: item(['workflow']), a2: item(['workflow']), b: item(['regression-vs-correlation']) });
ok(!SK.recommend(done, TM, '2026-03-02', 20).some(x => x.skill.id === 'F1'), 'proficient skills are not recommended again');
ok(SK.SKILLS.every(s => s.req.every(r => SK.BYID[r])), 'every prerequisite exists');
ok(new Set(SK.SKILLS.map(s => s.id)).size === SK.SKILLS.length, 'skill ids are unique');
console.log(fails ? `\n${fails} FAILURES` : '\nALL SKILL TESTS PASSED'); process.exit(fails ? 1 : 0);
