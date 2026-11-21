#!/usr/bin/env python3
"""Add a 'Practise in R' link and a self-check quiz to a base-module page or deck.

Used for the U1/U2/U7 unit updates (MODULE_UPDATE_STEPS.md). Reads a JSON spec:
  [{"file": "...", "lab": ["labs/moderate/m1_cleaning.R", "Cleaning messy data"],
    "data": ["data/ncd_messy.csv"], "date": "2026-11-20",   # "lab" and "data" are optional
    "questions": [["cm1", "Question?", ["A", "B", "C", "D"], 2, "Explanation."], ...]}]
Idempotent: a page that already has a 'Self-check quiz' heading is skipped.
Usage: python3 scripts/add_unit_quiz.py spec.json
"""
import json, os, re, sys

AUTHOR = "Sparrow"


def rstr(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def qcall(q):
    qid, text, opts, ans, expl = q
    return (f"quiz_mcq({rstr(qid)}, {rstr(text)},\n"
            f"         c({', '.join(rstr(o) for o in opts)}), answer = {ans},\n"
            f"         explain = {rstr(expl)})")


def header(src, date):
    m = re.match(r"---\n(.*?)\n---\n", src, re.S)
    yml = m.group(1)
    lines = yml.split("\n")
    if not re.search(r"^author:", yml, re.M):
        i = next(i for i, l in enumerate(lines) if l.startswith("title:"))
        # keep a subtitle directly under the title
        while i + 1 < len(lines) and lines[i + 1].startswith("subtitle:"):
            i += 1
        lines.insert(i + 1, f'author: "{AUTHOR}"')
    if re.search(r"^date:", "\n".join(lines), re.M):
        lines = [f'date: "{date}"' if l.startswith("date:") else l for l in lines]
    else:
        i = next(i for i, l in enumerate(lines) if l.startswith("author:"))
        lines.insert(i + 1, f'date: "{date}"')
    return "---\n" + "\n".join(lines) + "\n---\n" + src[m.end():]


def block(spec, deck, up):
    out = []
    if spec.get("lab"):  # optional: a unit's lab is linked from its main pages
        lab, title = spec["lab"]
        data = " · ".join(f"[{os.path.basename(d)}]({up}{d})" for d in spec["data"])
        h = "## 🔧 Practise in R {.smaller}" if deck else "## Practise in R"
        out = [h, "",
               f"Download the lab **[{title}]({up}{lab})** and the data ({data}). "
               "Fill in the blanks (`___`); the comments say what each step should do.", ""]
    setup = ["```{r}", "#| include: false", f'source("{up}assets/quiz.R")', "```", ""]
    qs = spec["questions"]
    asis = ["```{r}", "#| echo: false", "#| output: asis"]
    if deck:
        for i, q in enumerate(qs, 1):
            out += [f"## Self-check quiz ({i}/{len(qs)}) {{.smaller}}", ""]
            if i == 1:
                out += setup
            out += asis + [qcall(q), "```", ""]
        out += ["## Score {.smaller}", ""]
    else:
        out += ["## Self-check quiz", ""] + setup + asis + [qcall(q) for q in qs] + ["```", ""]
    out += ["**Your score: <span class=\"quiz-score\"></span>** (first attempt counts)", "",
            "```{r}", "#| echo: false", "#| output: asis",
            f'source("{up}assets/quiz-engine.R"); quiz_engine()', "```", ""]
    return "\n".join(out)


def main(path):
    for spec in json.load(open(path)):
        f = spec["file"]
        src = open(f).read()
        if "Self-check quiz" in src:
            print("skip (has quiz):", f)
            continue
        deck = bool(re.search(r"^\s*revealjs:", src.split("\n---", 2)[0] + src[:600], re.M))
        up = "../" * f.count("/")
        src = header(src, spec.get("date", "2026-11-20"))
        b = block(spec, deck, up)
        m = re.search(r"^#{1,2} (Thank You!|Congratulations!).*$", src, re.M)
        if m:  # quiz goes before the closing slide
            src = src[:m.start()] + b + "\n" + src[m.start():]
        else:
            src = src.rstrip("\n") + "\n\n" + b
        open(f, "w").write(src)
        print(f"{'deck' if deck else 'page'} {len(spec['questions'])} Qs:", f)


if __name__ == "__main__":
    main(sys.argv[1])
