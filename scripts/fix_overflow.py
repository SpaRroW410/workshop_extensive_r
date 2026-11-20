#!/usr/bin/env python3
"""Mark overflowing slides of a deck: pass 1 adds .smaller, pass 2 (still overflowing) adds .scrollable.

Usage (repository root): python3 scripts/fix_overflow.py <pass: smaller|scrollable> <deck.qmd>=<rendered.html> ...
Runs tests/overflow.js on each rendered deck and edits the matching '## Title' lines in the .qmd.
Re-render between the two passes.
"""
import os, re, subprocess, sys

mode = sys.argv[1]
assert mode in ('smaller', 'scrollable')
env = dict(os.environ, PLAYWRIGHT_PATH=os.environ.get('PLAYWRIGHT_PATH', '/opt/node-tools/node_modules/playwright'))
for pair in sys.argv[2:]:
    qmd, html = pair.split('=')
    out = subprocess.run(['node', 'tests/overflow.js', os.path.abspath(html)], capture_output=True, text=True, env=env).stdout
    titles = re.findall(r'^\s+#\d+ "(.*)" bottom=', out, re.M)   # not SCROLL lines
    lines = open(qmd).read().split('\n'); changed = 0
    for t in titles:
        hits = [i for i, l in enumerate(lines) if re.match(r'^##? ' + re.escape(t.strip()) + r'(\s*\{.*\})?\s*$', l)]
        for i in hits:
            l = lines[i]; m = re.match(r'^(##? .*?)\s*\{(.*)\}\s*$', l)
            attrs = m.group(2) if m else ''
            want = ['.smaller'] + (['.scrollable'] if mode == 'scrollable' else [])
            new_attrs = (attrs + ' ' + ' '.join(w for w in want if w not in attrs)).strip()
            if new_attrs != attrs.strip():
                lines[i] = f'{m.group(1) if m else l.rstrip()} {{{new_attrs}}}'; changed += 1
    open(qmd, 'w').write('\n'.join(lines))
    print(f'{qmd}: {len(titles)} overflowing, {changed} headings marked {mode}')
