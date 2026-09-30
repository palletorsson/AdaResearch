"""Publish the saved editorial comparison; no museum or tutorial changes."""
from pathlib import Path
import difflib
import hashlib
import html
import json
import re
import shutil

import markdown
from bs4 import BeautifulSoup

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
PATHS = {"point-zero": "commons/maps/Point_Zero/final.md", "preface": "doc/book/preface.md"}
read = lambda p: p.read_text(encoding="utf-8-sig")
old = {k: read(OUT / "before" / p) for k, p in PATHS.items()}
new = {k: read(ROOT / p) for k, p in PATHS.items()}


def render(text, prefix):
    text = re.sub(r"~~([^~\n]+)~~", r"<del>\1</del>", text)
    soup = BeautifulSoup(markdown.markdown(text, extensions=["extra"]), "html.parser")
    for node in soup.find_all(id=True):
        node["id"] = prefix + "-" + node["id"]
    for link in soup.find_all("a", href=True):
        if link["href"].startswith("#"):
            link["href"] = "#" + prefix + "-" + link["href"][1:]
        elif link["href"] == "day-zero.md":
            link["href"] = "/book-review/doc/book/day-zero.md"
    return str(soup)


def words(text):
    text = re.sub(r"```.*?```|<!--.*?-->", "", text, flags=re.S)
    text = re.sub(r"^\[\^.+|^#.*", "", text, flags=re.M)
    return len(re.sub(r"\[\^[^\]]+\]", "", text).split())


for key, rel in PATHS.items():
    destination = OUT / "after" / rel
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / rel, destination)
    (OUT / (key + ".diff")).write_text("".join(difflib.unified_diff(
        old[key].splitlines(True), new[key].splitlines(True),
        fromfile="before/" + rel, tofile="after/" + rel)), encoding="utf-8")

catalog_path = ROOT / "commons/data/museum_core_encounters.json"
catalog = json.loads(read(catalog_path))
room = catalog["rooms"]["Point_Zero"]
room["text_sha256"] = hashlib.sha256((ROOT / PATHS["point-zero"]).read_bytes()).hexdigest()
room["local_review"] = OUT.relative_to(ROOT).as_posix() + "/index.html"
catalog_path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

decisions = """# Point Zero — room to read

30 September 2026. Applied to canonical final.md and preface.md.

- Keep the fall, Alice, counter, ten folding frames, origin and carried word. Keep the line about the first number, which returns in Melencolia.
- Remove the second announcement that the room is already running.
- Preserve the author's inherited-work paragraph. Move its final borrowing question into the preface, immediately after the supplied environment and player have been named.
- Separate repeated calls from retained state. Keep every code excerpt, the distinction between counting calls and elapsed time, and the distinction between a local count and the engine total.
- Let the giants and fog stand without explaining their meaning again.
- Describe the folding frames as a repeating construction rather than implying that their program stores a journey.
- Let carrying the crossed-out you open the question. Remove the general conclusion about the purpose of an address. Retain the Ahmed note.

Museum arrangements, artifact implementations and tutorials were not changed. This is an editorial pass; no new runtime or headset claim. The exact originals and supplied feedback are preserved here.
"""
(OUT / "DECISIONS.md").write_text(decisions, encoding="utf-8")

panels = []
for key in PATHS:
    panels.append(f'<details><summary>{html.escape(key)} — original beside revised</summary>'
                  f'<div class="pair"><div><p class="eyebrow">Before</p>{render(old[key],key+"-old")}</div>'
                  f'<div><p class="eyebrow">Revised</p>{render(new[key],key+"-new")}</div></div>'
                  f'<p><a href="{key}.diff">Exact text diff</a></p></details>')

css = """
*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:24px}
body{margin:0;background:#f5f1e9;color:#2c2a2c;font:19px/1.78 Georgia,serif}
main{max-width:1120px;margin:auto;padding:52px 26px 90px}header{padding-bottom:32px;border-bottom:1px solid #d5cfc5}
h1,h2{font-weight:400;line-height:1.2}header h1{font-size:clamp(40px,6vw,68px);max-width:900px}h2{font-size:29px}
a{color:#874964;text-underline-offset:4px}nav{display:flex;flex-wrap:wrap;gap:12px 24px}
.eyebrow,nav,summary,footer{font:13px/1.6 system-ui,sans-serif}.eyebrow{color:#6d6269;letter-spacing:.05em}
header p{max-width:760px}article{max-width:740px;margin:65px auto}article h1{font-size:36px}p{margin:0 0 23px}
pre{background:#e9e3db;padding:20px;overflow:auto;line-height:1.55}code{font:.86em Consolas,monospace}pre code{font-size:14px}
.footnote{font-size:15px;overflow-wrap:anywhere}.footnote p{margin-bottom:14px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:34px;font-size:16px;margin-top:28px}.pair>div{min-width:0}.pair h1{font-size:25px}
details{border-top:1px solid #d5cfc5;padding:22px 0}summary{cursor:pointer;font-size:16px}footer{border-top:1px solid #d5cfc5;padding-top:20px;margin-top:50px}
:focus-visible{outline:3px solid #874964;outline-offset:4px}@media(max-width:760px){main{padding:30px 20px}.pair{grid-template-columns:1fr}}
@media print{nav,details,footer,#decisions{display:none}body{background:white;font-size:12pt}main{padding:0}}
"""
page = f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Point Zero · room to read</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">ADA RESEARCH · POINT ZERO · 30 SEPTEMBER 2026</p><h1>Let the word come away<br>from its sentence.</h1>
<p>A focused edit of the opening: less repeated explanation around the images, more room between the steps of the counter.</p>
<p class="eyebrow">Main prose: {words(old['point-zero'])} → {words(new['point-zero'])} words, excluding headings, notes and code.</p>
<nav><a href="#reading">Read Point Zero</a><a href="#preface">Borrowing in the preface</a><a href="#changes">Before / after</a><a href="/compose/sources?map=Point_Zero&amp;doc=final">Read and comment on current source</a></nav></header>
<article id="reading">{render(new['point-zero'],'reading')}</article>
<article id="preface"><p class="eyebrow">THE RELOCATED QUESTION · PREFACE</p>
{render(next(p for p in new['preface'].split(chr(10)*2) if p.startswith('Even “Hello, world”')) + chr(10)*2 + 'What are we forced to borrow for now, and what must we understand to make the work our own?','preface-excerpt')}
<p><a href="/book-review/doc/book/preface.md">Read the full current preface</a></p></article>
<article id="decisions">{render(decisions,'decisions')}</article>
<section id="changes"><h2>Original and revised</h2>{''.join(panels)}</section>
<footer>Promoted to the canonical manuscripts. This page preserves the 30 September reading; the comment link opens the latest source. <a href="verification.json">Publication checks</a> · <a href="/book-review/doc/book/captures/primitives/primitives-book.md">Current Primitives capture</a></footer>
</main></body></html>"""

assert re.findall(r"```.*?```|<!--.*?-->", old['point-zero'], re.S) == re.findall(r"```.*?```|<!--.*?-->", new['point-zero'], re.S)
assert re.findall(r"^\[\^.+", old['point-zero'], re.M) == re.findall(r"^\[\^.+", new['point-zero'], re.M)
assert 'Its first number for you is not its first number.' in new['point-zero']
assert 'Who gets to decide which questions can wait?' in new['point-zero']
soup = BeautifulSoup(page, "html.parser")
ids = [n['id'] for n in soup.find_all(id=True)]
assert len(ids) == len(set(ids))
assert all(a['href'][1:] in ids for a in soup.find_all('a',href=True) if a['href'].startswith('#'))
assert soup.select_one('#reading del').get_text() == 'you'
assert not re.search(r"\[\^[^\]]+\]", soup.get_text())
(OUT / "index.html").write_text(page, encoding="utf-8")
(OUT / "verification.json").write_text(json.dumps({
    "scope": "Editorial and HTML checks; no runtime or headset test",
    "code_anchors_and_footnote_definitions_preserved": True,
    "reading_links_and_footnotes_resolve": True,
    "main_prose_words": {"before": words(old['point-zero']), "after": words(new['point-zero'])},
    "sources_sha256": {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in PATHS.values()}
}, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"page": str(OUT / 'index.html'), "words_before": words(old['point-zero']), "words_after": words(new['point-zero'])}))
