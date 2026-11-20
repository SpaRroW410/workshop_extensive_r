import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { spawnSync } from 'node:child_process';

const STAGE = new URL('../stage.mjs', import.meta.url).pathname;
const run = (dir) => spawnSync(process.execPath, [STAGE, '--check', '--docs', dir], { encoding: 'utf8' });

function site(files) {
  const d = mkdtempSync(join(tmpdir(), 'stage-'));
  for (const [rel, body] of Object.entries(files)) {
    mkdirSync(join(d, rel, '..'), { recursive: true });
    writeFileSync(join(d, rel), body);
  }
  return d;
}

test('a clean site passes', () => {
  const d = site({ 'index.html': '<p>hi', 'regression/regression-workshop/labs/lab1_explore.R': 'x <- ___' });
  const r = run(d);
  rmSync(d, { recursive: true });
  assert.equal(r.status, 0, r.stderr);
});

test('facilitator solutions are refused', () => {
  for (const bad of ['regression/regression-workshop/solutions/lab1_explore_solution.R',
                     'advanced/causal-workshop/labs/lab2_adjust_solution.R',
                     'regression/regression-workshop/run_solutions.R']) {
    const d = site({ 'index.html': 'x', [bad]: 'answers' });
    const r = run(d);
    rmSync(d, { recursive: true });
    assert.equal(r.status, 1, bad);
    assert.match(r.stderr, /facilitator material/);
  }
});

test('a file above 25 MiB is refused', () => {
  const d = site({ 'index.html': 'x' });
  writeFileSync(join(d, 'big.bin'), Buffer.alloc(25 * 1024 * 1024 + 1));
  const r = run(d);
  rmSync(d, { recursive: true });
  assert.equal(r.status, 1);
  assert.match(r.stderr, /25 MiB/);
});

test('the real docs/ passes', () => {
  const r = spawnSync(process.execPath, [STAGE, '--check'], { encoding: 'utf8' });
  assert.equal(r.status, 0, r.stderr);
});
