// Unit tests for assets/cohort.js. Run: node dungeons/tests/cohort_test.js
const C = require('../assets/cohort.js');
let fails = 0; const ok = (c, m) => { console.log((c ? 'PASS ' : 'FAIL ') + m); if (!c) fails++; };
const it = (o) => Object.assign({ world: 'w1', diff: 2, tries: 1, hints: 0, solved: true, shown: false, boss: false, tags: [] }, o);
const A = { v: 1, items: { a: it({}), b: it({ diff: 3, tries: 2 }), c: it({ world: 'w2', boss: true }), d: it({ shown: true }), e: it({ hints: 1 }) },
  tests: { pre: { pct: 40, byTag: { confounding: [0, 1], odds: [1, 1] } }, post: { pct: 70 }, ready: { pct: 90 } }, streak: { best: 3 } };
const B = { v: 1, items: { a: it({ solved: false, tries: 0 }) }, tests: { pre: { pct: 60, byTag: { confounding: [0, 1], odds: [0, 1] } } }, streak: {} };
ok(C.itemXP(A.items.a) === 20 && C.itemXP(A.items.b) === 15 && C.itemXP(A.items.c) === 70 && C.itemXP(A.items.d) === 0 && C.itemXP(A.items.e) === 17, 'XP rules match the engine (20, 15, 70 boss, 0 shown, 17 hinted)');
const s = C.summarise([{ name: 'dr-a', state: A }, { name: 'dr-b', state: B }, { name: 'bad', state: { v: 9 } }, { name: 'empty', state: null }]);
ok(s.n === 2, 'invalid files are skipped (read ' + s.n + ')');
const ra = s.rows[0];
ok(ra.xp === 122 && ra.solved === 5 && ra.worlds === 2 && ra.bosses === 1 && ra.gain === 30 && ra.ready === 90 && ra.streak === 3, 'learner row: ' + JSON.stringify(ra));
ok(s.rows[1].gain === null && s.rows[1].post === null, 'missing post-test → null gain');
const T = C.totals(s); ok(T.pre === 50 && T.post === 70 && T.gain === 30, 'cohort means ignore missing values: ' + JSON.stringify(T));
const W = C.weakest(s, 5); ok(W.length === 0, 'weakest() needs ≥ 3 answers per tag before listing');
const many = C.summarise([A, B, A].map((x, i) => ({ name: 'p' + i, state: x }))); const W2 = C.weakest(many, 5);
ok(W2[0].tag === 'confounding' && W2[0].pct === 0 && W2[1].tag === 'odds' && W2[1].pct === 67, 'weakest skills sorted by % right: ' + JSON.stringify(W2));
const csv = C.csv(s).split('\n'); ok(csv.length === 3 && csv[0].startsWith('name,xp,rank') && csv[1].startsWith('dr-a,122'), 'CSV has header + one row per learner');
ok(C.csv(C.summarise([{ name: 'a,"b"', state: B }])).includes('"a,""b"""'), 'CSV quotes commas and quotes');
console.log(fails ? `\n${fails} FAILURES` : '\nALL COHORT TESTS PASSED'); process.exit(fails ? 1 : 0);
