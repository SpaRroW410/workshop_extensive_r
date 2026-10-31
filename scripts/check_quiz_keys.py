#!/usr/bin/env python3
"""Sanity check for quiz answer keys in the workshop decks (run from the repository root).
For each quiz_mcq(), the EXPLANATION should talk about the marked answer. This prints REVIEW hints where another option shares
more words with the explanation than the marked one does (a hint that `answer =` points at the wrong option), or with --list
prints every question with its marked answer for a human read. Usage: python3 scripts/check_quiz_keys.py [--list] [deck.qmd ...]"""
import re, sys, glob
STOP = set("that this with from than their have does your when each into about after other there these those would should could which what where while because between under over more most some such only also been being were will just very much many than then them they its it's are for and the not but can may".split())
def words(t): return {w for w in re.findall(r"[a-z0-9]+", t.lower()) if len(w) > 3 and w not in STOP}
args = [a for a in sys.argv[1:] if not a.startswith("--")]; show = "--list" in sys.argv
files = args or sorted(glob.glob("*-workshop/s[0-9]_*.qmd") + glob.glob("regression-workshop/s[0-9]_*.qmd"))
bad = 0
for f in files:
    s = open(f, encoding="utf-8").read()
    for m in re.finditer(r'quiz_mcq\("(\w+)",\s*"((?:[^"\\]|\\.)*)",\s*c\((.*?)\),\s*answer\s*=\s*(\d)(?:,\s*explain\s*=\s*"((?:[^"\\]|\\.)*)")?', s, re.S):
        qid, stem, optblock, ans, expl = m.groups(); opts = re.findall(r'"((?:[^"\\]|\\.)*)"', optblock); k = int(ans) - 1
        if show: print(f"{f.split('/')[0][:8]:8} {qid:6} [{ans}] {opts[k][:90]}")
        if not expl: continue
        ew = words(expl); sc = [len(ew & words(o)) for o in opts]
        if sc[k] < max(sc) and sc[k] + 1 <= max(sc) and max(sc) >= 2:
            bad += 1; print(f"REVIEW {f} {qid}: marked option {ans} overlaps the explanation {sc[k]}, option {sc.index(max(sc)) + 1} overlaps {max(sc)}\n   marked : {opts[k][:100]}\n   other  : {opts[sc.index(max(sc))][:100]}")
print(f"{bad} question(s) to look at" if not show else "")
sys.exit(0)   # a review aid, not a gate: similar distractors cause false alarms
