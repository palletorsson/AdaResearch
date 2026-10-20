"""Render the situated-voice note and author toolbox as static reading pages."""
from pathlib import Path
import html
import json
import re

import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
LIBRARY = ROOT / "doc/book/course/writing-patterns/AUTHOR_STRATEGIES.md"
ALLOWED = {
    "doc/book/course/WRITING_ROLES_AND_DECISIONS.md",
    "doc/book/course/writing-patterns/PROVENANCE.md",
}


def render(source):
    content = markdown.markdown(source.read_text(encoding="utf-8"), extensions=["tables", "toc"])

    def link(match):
        href, label = html.unescape(match[1]), match[2]
        if href.startswith(("https://", "http://", "#")):
            return match[0]
        file_part, separator, fragment = href.partition("#")
        target = (source.parent / file_part).resolve()
        if not target.is_file():
            raise FileNotFoundError(target)
        if target == LIBRARY:
            url = "strategies.html"
        elif target == HERE / "README.md":
            url = "index.html"
        else:
            relative = target.relative_to(ROOT).as_posix()
            if relative.startswith("doc/book/iterations/") or relative in ALLOWED:
                url = "/book-review/" + relative
            else:
                return f'<span class="local" title="Repository reference: {html.escape(relative, quote=True)}">{label}</span>'
        if separator:
            url += "#" + fragment
        return f'<a href="{html.escape(url, quote=True)}">{label}</a>'

    content = re.sub(r'<a href="([^"]+)">(.*?)</a>', link, content, flags=re.S)
    content = content.replace("<table>", '<div class="table-wrap" tabindex="0"><table>').replace("</table>", "</table></div>")
    return content.replace("<!-- sample:start -->", '<section class="sample" aria-label="Short bridge trial">').replace("<!-- sample:end -->", "</section>")


CSS = """
:root{color-scheme:light;--paper:#f8f5ed;--ink:#23332f;--accent:#266557;--edge:#d4d8ce}
*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:19px/1.65 Georgia,serif}
header{padding:22px max(24px,calc((100vw - 1160px)/2));border-bottom:1px solid var(--edge);font:15px/1.6 system-ui,sans-serif}
header strong{display:block;font-size:20px;margin-bottom:10px}nav{display:flex;flex-wrap:wrap;gap:10px 24px}
main{max-width:1208px;margin:auto;padding:28px 24px 90px}h1{font-size:clamp(30px,4vw,46px);line-height:1.15;max-width:28ch;font-weight:normal}
h2{font-size:27px;line-height:1.3;margin-top:46px}h3{font-size:22px}p,ol,ul{max-width:74ch}li{padding-bottom:8px}
a{color:var(--accent);text-underline-offset:3px}a:focus-visible,.table-wrap:focus-visible{outline:3px solid var(--accent);outline-offset:4px}
.table-wrap{overflow-x:auto;margin:24px 0;border:1px solid var(--edge);border-radius:5px}table{border-collapse:collapse;width:100%;min-width:800px;font:16px/1.55 system-ui,sans-serif}
th,td{padding:16px;text-align:left;vertical-align:top;border-bottom:1px solid var(--edge)}th{background:#e7ece3}td:first-child{min-width:165px}tr:last-child td{border:0}
.sample{max-width:72ch;padding:22px 28px;background:#edf1e8;border-left:4px solid #6d9989;font-size:21px;line-height:1.75;margin:24px 0}
.sample p:last-child{margin-bottom:0}code{font-size:.84em;overflow-wrap:anywhere}.local{border-bottom:1px dotted #84918b}blockquote{border-left:3px solid #8d9d93;margin-left:0;padding-left:24px}
@media(max-width:600px){body{font-size:18px}.sample{font-size:19px;padding:16px}main{padding:18px}h2{font-size:24px}}
@media print{header{display:none}.table-wrap{overflow:visible}table{min-width:0;font-size:9pt}body{font-size:11pt}.sample{font-size:12pt}}
"""

for source, filename, title in [
    (HERE / "README.md", "index.html", "What the voice can know here"),
    (LIBRARY, "strategies.html", "Authors' strategies · Ada Research"),
]:
    output = f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title><style>{CSS}</style></head>
<body><header><strong>Ada Research · shared voice, changing attention</strong><nav><a href="index.html">Working proposal and passage</a><a href="strategies.html">Author toolbox</a><a href="../2026-10-15-435-witness-trial/compare.html">Complete chapter comparison</a></nav></header>
<main>{render(source)}</main></body></html>'''
    (HERE / filename).write_text(output, encoding="utf-8")

note = (HERE / "README.md").read_text(encoding="utf-8")
sample = note.split("<!-- sample:start -->")[1].split("<!-- sample:end -->")[0]
count = len(sample.split())
(HERE / "counts.json").write_text(json.dumps({"bridge_words": count, "scope": "Short bridge only; not a complete chapter or adopted replacement."}, indent=2) + "\n", encoding="utf-8")
print(f"Rendered working note and author toolbox; bridge: {count} words. Local references checked.")
