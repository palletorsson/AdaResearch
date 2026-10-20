"""Render the two reading versions without scripts or external assets."""
from pathlib import Path
import hashlib
import html
import json
import re

import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
ORIGINAL_DIR = ROOT / "commons/maps/Random_Definition"


def words(text):
    body = re.split(r"^\[\^[^]]+\]:", text, maxsplit=1, flags=re.M)[0]
    body = re.sub(r"<!--[\s\S]*?-->|^#.*$", "", body, flags=re.M)
    body = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", body)
    body = re.sub(r"\[\^[^]]+\]", "", body)
    return len([word for word in body.split() if word != ">"])


def render(text, name):
    # The preserved current.md is byte-for-byte the chapter at the start of the trial.
    if name == "current":
        text = text.replace("../../../algorithms/randomness/seed_replay/opening_seed.json", "opening-receipt.json")
        text = text.replace("../../../doc/book/iterations/", "../")
    text = re.sub(r"<!-- @([^\s]+) -->", lambda m: '<span class="stop" id="' + name + '-' + m[1].replace('/', '-') + '"></span>', text)
    text = re.sub(r"<!-- @ -->", "", text)
    rendered = markdown.markdown(text, extensions=["footnotes", "tables"])
    rendered = re.sub(r'(id|href)="(#?)(fn[^\"]*)"', lambda m: f'{m[1]}="{m[2]}{name}-{m[3]}"', rendered)
    note_start = rendered.find('<div class="footnote">')
    if note_start >= 0:
        rendered = rendered[:note_start] + '<details class="sources"><summary>Sources and technical distinctions</summary>' + rendered[note_start:] + '</details>'
    return rendered


texts = {name: (HERE / f"{name}.md").read_text(encoding="utf-8") for name in ["current", "trial"]}
counts = {name + "_words": words(text) for name, text in texts.items()}
counts.update({"budget": [600, 1500], "counting": "Narrative and displayed receipt; excludes heading, footnotes and editorial notes.", "current_sha256": hashlib.sha256((HERE / "current.md").read_bytes()).hexdigest()})
(HERE / "counts.json").write_text(json.dumps(counts, indent=2) + "\n", encoding="utf-8")

CSS = """
:root{color-scheme:light;--ink:#202b32;--paper:#f8f5ed;--edge:#d6d2c8;--accent:#32665e}
*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink)}
header{padding:20px clamp(20px,4vw,60px);border-bottom:1px solid var(--edge);font:15px/1.55 system-ui,sans-serif}
header strong{display:block;font-size:18px}header p{max-width:850px;margin:6px 0 12px}nav{display:flex;gap:12px 24px;flex-wrap:wrap}
a{color:var(--accent);text-underline-offset:.18em}a:focus-visible,summary:focus-visible{outline:3px solid var(--accent);outline-offset:5px}
main{padding:32px clamp(20px,4vw,60px) 90px}article{max-width:66ch;margin:auto;font:21px/1.68 Georgia,serif}
article h1{font-size:clamp(28px,3.4vw,42px);line-height:1.16;margin:16px 0 34px;font-weight:normal}
article p{margin:0 0 1.25em}article .version{font:13px/1.5 system-ui,sans-serif;letter-spacing:.04em;text-transform:uppercase;color:#52645f}
blockquote{margin:24px 0 30px;padding:16px 22px;border-left:3px solid #75998b;background:#edf0e8;font-size:.94em}blockquote p:last-child{margin:0}
.stop{display:block;scroll-margin-top:25px;height:20px}.stop:first-of-type{height:0}sup{font:12px system-ui,sans-serif}
.sources{font:15px/1.65 system-ui,sans-serif;border-top:1px solid var(--edge);margin-top:42px;padding-top:16px}.sources summary{cursor:pointer}.sources hr{display:none}
.compare{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:clamp(30px,5vw,90px);max-width:1600px;margin:auto}
.compare article{font-size:18px;max-width:64ch;margin:0 auto;width:100%;align-self:start}.compare article h1{font-size:31px}
@media(max-width:850px){.compare{display:block}.compare article{font-size:19px}.compare article+article{border-left:0;padding-left:0;border-top:1px solid var(--edge);margin-top:55px;padding-top:35px}article{font-size:20px}}
@media print{header nav{display:none}body{background:white}main{padding:20px}article{font-size:12pt}.compare article{font-size:10pt}details.sources{display:block}}
"""


def page(compare=False):
    names = ["current", "trial"] if compare else ["trial"]
    articles = []
    for name in names:
        label = "Current chapter · preserved snapshot" if name == "current" else "Reading trial · not yet adopted"
        articles.append(f'<article><div class="version">{label} · {counts[name + "_words"]} words</div>{render(texts[name], name)}</article>')
    heading = "435 · two readings" if compare else "435 · a reading trial"
    return f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(heading)}</title><style>{CSS}</style></head>
<body><header><strong>{heading}</strong><p>One complete narrated encounter. The trial separates the display, recorded sound and acquisition receipt, then stops at the sphere’s compulsory return. It is a proposed literary version, not a report of a participant’s visit.</p>
<nav><a href="index.html">Read the trial</a><a href="compare.html">Compare both complete texts</a><a href="#trial-geiger_counter">Go to the changed middle</a><a href="README.md">Revision record</a></nav></header>
<main class="{'compare' if compare else 'reading'}">{''.join(articles)}</main></body></html>'''


(HERE / "index.html").write_text(page(), encoding="utf-8")
(HERE / "compare.html").write_text(page(True), encoding="utf-8")
print(json.dumps(counts))
