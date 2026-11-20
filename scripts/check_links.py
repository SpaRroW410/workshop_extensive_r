#!/usr/bin/env python3
"""Check every internal link in the rendered site (docs/).

Usage (repository root):  python3 scripts/check_links.py [docs]
Fails (exit 1) on
  * a link or src to a file that does not exist, and
  * any href that ends in .qmd: Quarto rewrites links to pages it renders into .html, so a .qmd
    link means the target page is not rendered in that track (this hid 18 dead gallery decks).
External links (http:, mailto:, ...), in-page anchors and data: URIs are not checked.
"""
import html.parser, os, re, sys
from urllib.parse import unquote, urlsplit

ROOT = sys.argv[1] if len(sys.argv) > 1 else 'docs'


class Links(html.parser.HTMLParser):
    def __init__(self):
        super().__init__()
        self.found = []

    def handle_starttag(self, tag, attrs):
        # The navbar brand's href is rewritten in the browser (see include-after-body in _quarto.yml):
        # Quarto writes logo-href unchanged, so it is wrong on disk on every nested page.
        if tag == 'a' and 'navbar-brand' in (dict(attrs).get('class') or ''):
            return
        for k, v in attrs:
            if v and ((k == 'href' and tag in ('a', 'link')) or (k == 'src' and tag in ('img', 'script', 'iframe', 'source'))):
                self.found.append(v)


bad, qmd, n = [], [], 0
for d, _, files in os.walk(ROOT):
    for f in files:
        if not f.endswith('.html') or f.endswith('-include.html'):   # include fragments are not pages
            continue
        page = os.path.join(d, f)
        p = Links()
        try:
            p.feed(open(page, encoding='utf-8', errors='replace').read())
        except Exception:
            continue
        for link in p.found:
            if re.match(r'^[a-zA-Z][\w+.-]*:', link) or link.startswith(('#', '//', 'data:')):
                continue
            path = unquote(urlsplit(link).path)
            if not path:
                continue
            n += 1
            if path.endswith('.qmd'):
                qmd.append((page, link))
                continue
            target = os.path.normpath(os.path.join(ROOT if path.startswith('/') else d, path.lstrip('/')))
            if os.path.isdir(target):
                target = os.path.join(target, 'index.html')
            if not os.path.exists(target):
                bad.append((page, link))

def report(title, rows):
    if rows:
        print(f'{title}: {len(rows)}')
        seen = {}
        for page, link in rows:
            seen.setdefault(link, []).append(page)
        for link, pages in sorted(seen.items())[:60]:
            print(f'  {link}  <- {len(pages)} page(s), e.g. {pages[0]}')

report('Links to pages not rendered in that track (.qmd)', qmd)
report('Links to missing files', bad)
print(f'{n} internal links checked in {ROOT}/: {len(qmd)} .qmd, {len(bad)} missing')
sys.exit(1 if (qmd or bad) else 0)
