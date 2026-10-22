// Unit tests for assets/rcheck.js. Run: node dungeons/tests/rcheck_test.js
const R = require('../assets/rcheck.js');
let fails = 0; const ok = (c, m) => { console.log((c ? 'PASS ' : 'FAIL ') + m); if (!c) fails++; };
const same = (sol, variants, opts) => variants.forEach(v => { const r = R.check(v, [sol], opts); ok(r.ok, 'accepts: ' + v.replace(/\n/g, ' ⏎ ') + (r.ok ? '' : '  → ' + r.msg + '\n      mine=' + r.canon + '\n      want=' + R.canon(sol, opts))); });
const diff = (sol, variants, opts, re) => variants.forEach(v => { const r = R.check(v, [sol], opts); ok(!r.ok && (!re || re.test(r.msg)), 'rejects: ' + v.replace(/\n/g, ' ⏎ ') + '  → ' + r.msg); });

// ── 1. filter + group + summarise: pipes, nesting, objects, names ─────────
const S1 = 'ncd |> filter(age >= 50) |> group_by(sex) |> summarise(mean_sbp = mean(sbp))';
same(S1, [
  'ncd %>% filter(age >= 50) %>% group_by(sex) %>% summarise(mean_sbp = mean(sbp))',
  'summarise(group_by(filter(ncd, age >= 50), sex), mean_sbp = mean(sbp))',
  'summarize(group_by(filter(ncd, 50 <= age), sex), m = mean(sbp))',
  'old <- filter(ncd, age >= 50)\nby_sex <- group_by(old, sex)\nsummarise(by_sex, avg = mean(sbp))',
  'library(dplyr)\nres <- ncd |>\n  filter(age >= 50) |>\n  group_by(sex) |>\n  summarise(mean_sbp = mean(sbp)) # comment\nres',
  'ncd |> summarise(mean_sbp = mean(sbp), .by = sex) |> identity()'.replace(' |> identity()', '').replace('ncd |>', 'ncd |> filter(age >= 50) |>'),
  'ncd %>% filter(age >= 50) %>% group_by(sex) %>% summarise(mean_sbp = mean(x = sbp), .groups = "drop")',
  'dplyr::summarise(dplyr::group_by(dplyr::filter(ncd, age >= 50), sex), mean_sbp = mean(sbp)) |> ungroup()',
  'ncd |> filter(age >= 50.0) |> group_by(sex) |> summarise(mean_sbp = mean(sbp)) -> out\nprint(out)',
  'ncd %>% filter(., age >= 50) %>% group_by(sex) %>% summarise(mean_sbp = mean(sbp))',
  'ncd |> filter(.data = _, age >= 50) |> group_by(sex) |> summarise(mean_sbp = mean(sbp))',
  'ncd[ncd$age >= 50, ] |> group_by(sex) |> summarise(mean_sbp = mean(sbp))',
  'subset(ncd, age >= 50) %>% group_by(sex) %>% summarise(mean_sbp = mean(sbp))'
]);
diff(S1, ['ncd |> filter(age > 50) |> group_by(sex) |> summarise(m = mean(sbp))'], {}, /filter/);
diff(S1, ['ncd |> filter(age >= 50) |> summarise(m = mean(sbp))'], {}, /group_by/);
diff(S1, ['ncd |> filter(age >= 50) |> group_by(residence) |> summarise(m = mean(sbp))'], {}, /group_by/);
diff(S1, ['ncd |> filter(age >= 50) |> group_by(sex) |> summarise(m = median(sbp))'], {}, /summarise/);
diff(S1, ['ncd |> group_by(sex) |> summarise(m = mean(sbp))'], {}, /filter/);
diff(S1, ['ncd |> filter(age >= 50) |> group_by(sex) |> summarise(m = mean(sbp)) |> arrange(m)'], {}, /arrange/);
diff(S1, ['other |> filter(age >= 50) |> group_by(sex) |> summarise(m = mean(sbp))'], {}, /ncd/);

// names can be required
diff(S1, ['ncd |> filter(age >= 50) |> group_by(sex) |> summarise(m = mean(sbp))'], { free_names: false });
same(S1, ['ncd |> filter(age >= 50) |> group_by(sex) |> summarise(mean_sbp = mean(sbp))'], { free_names: false });

// ── 2. several filter conditions ─────────────────────────────────────────
const S2 = 'filter(ncd, age >= 50, sex == "Male")';
same(S2, ['filter(ncd, sex == "Male" & age >= 50)', "ncd |> filter(sex == 'Male') |> filter(age >= 50)", 'filter(ncd, "Male" == sex, age >= 50)', 'ncd %>% filter(age >= 50 && sex == "Male")']);
diff(S2, ['filter(ncd, age >= 50 | sex == "Male")', 'filter(ncd, age >= 50, sex == "Female")']);

// ── 3. mutate and later use of the new column ────────────────────────────
const S3 = 'ncd |> mutate(bmi = wt / (ht / 100)^2) |> filter(bmi >= 30)';
same(S3, ['ncd |> mutate(body_mass = wt / (ht / 100)^2) |> filter(body_mass >= 30)', 'filter(mutate(ncd, b = wt/(ht/100)^2), b >= 30)', 'd <- mutate(ncd, bmi = wt / (ht/100)^2)\nd[d$bmi >= 30, ]']);
diff(S3, ['ncd |> mutate(bmi = wt / ht^2) |> filter(bmi >= 30)', 'ncd |> mutate(bmi = wt / (ht / 100)^2) |> filter(bmi > 30)']);
same('ncd |> mutate(a = age / 10, b = sbp - 120)', ['ncd |> mutate(b = sbp - 120) |> mutate(a = age / 10)', 'ncd |> mutate(x = sbp - 120, y = age / 10)']);

// ── 4. count ≡ group_by + summarise(n()) ─────────────────────────────────
same('ncd |> count(sex)', ['ncd |> group_by(sex) |> summarise(n = n())', 'count(ncd, sex)', 'ncd %>% group_by(sex) %>% tally()'.replace('tally()', 'summarise(n = n())')]);
diff('ncd |> count(sex)', ['ncd |> count(residence)']);

// ── 5. models ────────────────────────────────────────────────────────────
const S5 = 'lm(sbp ~ salt_g + age, data = ncd)';
same(S5, ['lm(sbp ~ age + salt_g, ncd)', 'lm(data = ncd, formula = sbp ~ salt_g + age)', 'ncd |> lm(formula = sbp ~ salt_g + age)', 'm <- lm(sbp ~ salt_g + age, data = ncd)\nm', 'ncd %>% lm(sbp ~ age + salt_g, data = .)']);
diff(S5, ['lm(sbp ~ salt_g, data = ncd)', 'lm(salt_g ~ sbp + age, data = ncd)', 'glm(sbp ~ salt_g + age, data = ncd)']);
const S5b = 'glm(htn ~ salt_g + age, family = binomial, data = ncd)';
same(S5b, ['glm(htn ~ age + salt_g, data = ncd, family = "binomial")', 'glm(htn ~ salt_g + age, binomial(), ncd)', 'glm(htn ~ salt_g + age, family = binomial(link = "logit"), data = ncd)']);
diff(S5b, ['glm(htn ~ salt_g + age, family = poisson, data = ncd)', 'glm(htn ~ salt_g + age, data = ncd)']);
same('summary(lm(sbp ~ salt_g, data = ncd))', ['m <- lm(sbp ~ salt_g, data = ncd)\nsummary(m)', 'ncd |> lm(formula = sbp ~ salt_g) |> summary()']);

// ── 6. ggplot ────────────────────────────────────────────────────────────
const S6 = 'ggplot(ncd, aes(x = salt_g, y = sbp)) + geom_point() + geom_smooth(method = "lm")';
same(S6, ['ggplot(ncd, aes(salt_g, sbp)) + geom_point() + geom_smooth(method = "lm")', 'ncd |> ggplot(aes(salt_g, sbp)) + geom_point() + geom_smooth(method = "lm")', 'ggplot(data = ncd) + geom_point(aes(x = salt_g, y = sbp)) + geom_smooth(aes(salt_g, sbp), method = "lm")', 'ggplot(ncd, aes(salt_g, sbp)) + geom_smooth(method = \'lm\') + geom_point()', 'p <- ggplot(ncd, aes(y = sbp, x = salt_g))\np + geom_point() + geom_smooth(method = "lm")'.replace('p + geom', 'ggplot(ncd, aes(y = sbp, x = salt_g)) + geom')]);
diff(S6, ['ggplot(ncd, aes(sbp, salt_g)) + geom_point() + geom_smooth(method = "lm")', 'ggplot(ncd, aes(salt_g, sbp)) + geom_point()', 'ggplot(ncd, aes(salt_g, sbp)) + geom_point() + geom_smooth()']);

// ── 7. na.rm, ignore option, T/TRUE ──────────────────────────────────────
same('mean(ncd$sbp, na.rm = TRUE)', ['mean(ncd$sbp, na.rm = T)', 'mean(x = ncd$sbp, na.rm = TRUE)', 'mean(ncd[["sbp"]], na.rm = TRUE)', 'ncd$sbp |> mean(na.rm = TRUE)']);
diff('mean(ncd$sbp, na.rm = TRUE)', ['mean(ncd$sbp)']);
same('mean(ncd$sbp, na.rm = TRUE)', ['mean(ncd$sbp)'], { ignore: ['na.rm'] });
same('mean(ncd$sbp, na.rm = TRUE)', ['mean(ncd$sbp)'], { ignore: 'na.rm' });   // R's toJSON(auto_unbox) sends a single string

// ── 8. several accepted solutions (e.g. base R and dplyr) ────────────────
const multi = ['ncd |> filter(sex == "Male") |> nrow()', 'sum(ncd$sex == "Male")'];
ok(R.check('sum(ncd$sex == "Male")', multi).ok && R.check('nrow(filter(ncd, sex == "Male"))', multi).ok, 'any of several author solutions can match');

// ── 9. parse errors give a readable message with a line number ───────────
const pe = R.check('ncd |> filter(age >= 50 |> summarise(m = mean(sbp))', [S1]); ok(!pe.ok && /never closed|Expected/.test(pe.msg), 'unclosed bracket → ' + pe.msg);
const pe2 = R.check('ncd |>\n  filter(age >= 50) |>\n', [S1]); ok(!pe2.ok && /ends too early/.test(pe2.msg), 'dangling pipe → ' + pe2.msg);
const pe3 = R.check('ncd |> filter(age >= 50))', [S1]); ok(!pe3.ok && /extra/.test(pe3.msg) && /line 1/.test(pe3.msg), 'extra bracket → ' + pe3.msg);
const pe4 = R.check('', [S1]); ok(!pe4.ok && /no code/.test(pe4.msg), 'empty answer → ' + pe4.msg);
const pe5 = R.check('for (i in 1:3) print(i)', [S1]); ok(!pe5.ok && /not supported/.test(pe5.msg), 'loops are reported, not crashed on → ' + pe5.msg);
ok(R.check("x <- 'it\\'s'\nx", ["'it\\'s'"]).ok, 'escaped quotes in strings');
ok(R.check('ncd |> filter(`age group` == "50+")', ['filter(ncd, `age group` == "50+")']).ok, 'backtick names');

// ── 10. order of steps matters when it changes the result ────────────────
diff('ncd |> group_by(sex) |> summarise(m = mean(sbp)) |> filter(m > 130)', ['ncd |> filter(sbp > 130) |> group_by(sex) |> summarise(m = mean(sbp))']);

// ── 11. Region 1 forms: between, ifelse/case_when, joins, colour, glimpse ──
same('ncd |> filter(age >= 40, age <= 59)', ['ncd |> filter(between(age, 40, 59))', 'filter(ncd, age <= 59 & age >= 40)']);
const S11 = 'mutate(ncd, bmi_cat = if_else(bmi >= 30, "Obese", "Not obese"))';
same(S11, ['ncd |> mutate(bmi_cat = ifelse(bmi >= 30, "Obese", "Not obese"))'], { free_names: false });
same('mutate(ncd, c = case_when(bmi >= 30 ~ "Obese", TRUE ~ "Not obese"))', ['mutate(ncd, c = case_when(bmi >= 30 ~ "Obese", .default = "Not obese"))', 'mutate(ncd, c = case_when(bmi >= 30 ~ "Obese", T ~ "Not obese"))']);
const S12 = 'left_join(ncd, villages, by = "village")';
same(S12, ['ncd |> left_join(villages, by = join_by(village))', 'right_join(villages, ncd, by = "village")', 'merge(ncd, villages, by = "village", all.x = TRUE)', 'left_join(ncd, villages, by = c("village"))']);
diff(S12, ['inner_join(ncd, villages, by = "village")', 'merge(ncd, villages, by = "village")', 'left_join(villages, ncd, by = "village")']);
same('bind_rows(round1, round2)', ['rbind(round1, round2)']);
diff('bind_rows(round1, round2)', ['bind_rows(round2, round1)']);
same('ggplot(ncd, aes(salt_g, sbp, colour = sex)) + geom_point()', ['ggplot(ncd, aes(x = salt_g, y = sbp, color = sex)) + geom_point()', 'ggplot(ncd) + geom_point(aes(salt_g, sbp, color = sex))']);
diff('glimpse(ncd)', ['ncd', 'print(ncd)']);

console.log(fails ? `\n${fails} FAILURES` : '\nALL RCHECK TESTS PASSED'); process.exit(fails ? 1 : 0);
