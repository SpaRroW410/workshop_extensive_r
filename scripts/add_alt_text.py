#!/usr/bin/env python3
"""F7 / D6: add a `#| fig-alt:` to plot chunks that have none, built from the chunk's code.

The text describes what is DRAWN (chart type, variables, title), never what the data show,
so it cannot be wrong about a result. Chunks the script cannot describe are listed for a person.
Usage: python3 scripts/add_alt_text.py [--dry] file.qmd ...
"""
import re, sys

GEOMS = [  # first match wins, most specific first
    (r"ggbetweenstats", "Violin and box plots with the test result in the subtitle"),
    (r"ggwithinstats", "Paired violin and box plots for repeated measurements with the test result"),
    (r"ggscatterstats", "Scatter plot with a regression line, marginal histograms and the correlation test"),
    (r"gghistostats", "Histogram with a one-sample test result"),
    (r"ggbarstats", "Stacked percentage bar chart with a chi-square test result"),
    (r"ggpiestats", "Pie chart of proportions with a test result"),
    (r"ggcorrmat", "Correlation matrix heat map"),
    (r"ggdotplotstats", "Dot plot of values with a test result"),
    (r"leaflet\(", "Interactive map"),
    (r"plot_ly\(|ggplotly\(", "Interactive chart"),
    (r"geom_sf\(", "Map"),
    (r"geom_tile\(|geom_raster\(", "Heat map"),
    (r"geom_density_ridges|stat_density_ridges", "Ridgeline density plot"),
    (r"geom_violin\(", "Violin plot"),
    (r"geom_boxplot\(|boxplot\(", "Box plot"),
    (r"geom_histogram\(|hist\(", "Histogram"),
    (r"geom_density\(", "Density plot"),
    (r"geom_area\(", "Area chart"),
    (r"geom_line\(|geom_path\(", "Line chart"),
    (r"geom_smooth\(", "Scatter plot with a fitted trend line"),
    (r"geom_point\(|geom_jitter\(", "Scatter plot"),
    (r"geom_col\(|geom_bar\(|barplot\(", "Bar chart"),
    (r"geom_segment\(", "Dot or lollipop chart"),
    (r"geom_text\(|annotate\(", "Annotated chart"),
    (r"qqnorm\(|stat_qq|geom_qq", "Normal Q-Q plot"),
    (r"pie\(|coord_polar", "Pie or polar chart"),
    (r"plot\(", "Plot"),
]

def split_top(text):
    """Split at commas that are not inside brackets or quotes."""
    parts, depth, cur, q = [], 0, "", None
    for ch in text:
        if q:
            cur += ch; q = None if ch == q else q; continue
        if ch in "\"'": q = ch
        elif ch in "([{": depth += 1
        elif ch in ")]}": depth -= 1
        if ch == "," and depth == 0: parts.append(cur); cur = ""
        else: cur += ch
    parts.append(cur)
    return [p.strip() for p in parts if p.strip()]

def balanced(text, start):
    """The text inside the brackets that open at text[start]."""
    depth = 0
    for i in range(start, len(text)):
        if text[i] == "(": depth += 1
        elif text[i] == ")":
            depth -= 1
            if depth == 0: return text[start + 1:i]
    return text[start + 1:]

def nice(v):
    v = v.strip().strip("`").strip()
    m = re.match(r"^(?:factor|as\.factor|reorder|fct_\w+|forcats::\w+)\((.*)\)$", v, re.S)
    if m: v = split_top(m.group(1))[0]
    if re.match(r"^[-\d.\"']*$", v): return None            # literal numbers or "" are not variables
    return v.replace("_", " ")

def describe(code):
    kind = next((d for p, d in GEOMS if re.search(p, code)), None)
    if not kind:
        return None
    a = re.search(r"\baes\(", code)
    args = split_top(balanced(code, a.end() - 1)) if a else []
    named = {k.strip(): v for k, _, v in (p.partition("=") for p in args if re.match(r"^\w+\s*=[^=]", p))}
    pos = [p for p in args if not re.match(r"^\w+\s*=[^=]", p)]
    def get(name, i=None):
        if name in named: return nice(named[name])
        if i is not None and len(pos) > i: return nice(pos[i])
        return None
    x, y = get("x", 0), get("y", 1)
    if not (x or y):  # ggstatsplot style: x = , y = as arguments
        mx = re.search(r"\bx\s*=\s*([\w.]+)", code); my = re.search(r"\by\s*=\s*([\w.]+)", code)
        x, y = (nice(mx.group(1)) if mx else None), (nice(my.group(1)) if my else None)
    col = named.get("colour") or named.get("color") or named.get("fill")
    fac = re.search(r"facet_(?:wrap|grid)\(\s*(?:vars\()?~?\s*([\w. ~+]+)", code)
    title = re.search(r"\btitle\s*=\s*\"([^\"]{3,90})\"", code)
    t, _, extra = kind.partition(" with ")
    if y and x: t += f" of {y} against {x}"
    elif x: t += f" of {x}"
    elif y: t += f" of {y}"
    if col:
        hl = re.match(r"^\s*(\w+)\s*==\s*[\"'](.+)[\"']\s*$", col)
        if hl: t += f", with {hl.group(2)} highlighted"
        else:
            c = nice(col)
            if c and c not in (x, y): t += f", coloured by {c}"
    if extra: t += f", with {extra}"
    if fac: t += f", one panel per {nice(fac.group(1).replace('~', ' and ')) or 'group'}"
    if title: t += f", titled '{title.group(1)}'"
    return t.replace('"', "'") + "."

PLOT = re.compile(r"ggplot\(|plot\(|hist\(|ggbetweenstats|ggscatterstats|gghistostats|ggwithinstats|ggbarstats|ggpiestats|ggcorrmat|leaflet\(|plot_ly|ggplotly|qqnorm|boxplot\(|barplot\(")

def main(files, dry):
    todo = []
    for f in files:
        s = open(f).read(); out = []; pos = 0; n = 0
        for m in re.finditer(r"```\{r([^}]*)\}\n(.*?)```", s, re.S):
            head, body = m.group(1), m.group(2)
            opts = re.match(r"((?:#\|.*\n)*)", body).group(1)
            if "fig-alt" in body or "output: asis" in opts or not PLOT.search(body) or re.search(r"eval: *false|include: *false", opts) \
               or re.search(r"eval *= *FALSE|include *= *FALSE", head):
                continue
            alt = describe(body)
            if not alt:
                todo.append(f"{f}: chunk at char {m.start()}"); continue
            ins = m.start(2) + len(opts)
            out.append(s[pos:ins] + f'#| fig-alt: "{alt}"\n'); pos = ins; n += 1
            if dry: print(f"{f}: {alt}")
        out.append(s[pos:])
        if not dry and n: open(f, "w").write("".join(out))
        print(f"{n:3d} alt texts  {f}", file=sys.stderr)
    for t in todo: print("NEEDS A PERSON:", t, file=sys.stderr)

if __name__ == "__main__":
    args = sys.argv[1:]; dry = "--dry" in args
    main([a for a in args if a != "--dry"], dry)
