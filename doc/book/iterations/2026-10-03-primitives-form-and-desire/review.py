from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import difflib
import html
import json
import os
import re
import markdown

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
MAPS = ['Primitives_Ignorance', 'Primitives_Portals', 'Primitives_Melencolia']
panels = []
counts = {}

def render(text):
    # The manuscript uses the local review server; this review also opens as a file.
    text = re.sub(r'\]\(/book-review/([^)]*)\)',
                  lambda m: '](' + os.path.relpath(ROOT / m[1], OUT).replace('\\', '/') + ')', text)
    text = text.replace('](/book?', '](http://localhost:3003/book?')
    return markdown.markdown(text, extensions=['fenced_code', 'footnotes', 'tables'])

for name in MAPS:
    before = (OUT / 'before' / name / 'final.md').read_text(encoding='utf-8')
    after = (ROOT / 'commons/maps' / name / 'final.md').read_text(encoding='utf-8')
    assert re.findall(r'<!--.*?-->', before, re.S) == re.findall(r'<!--.*?-->', after, re.S)
    assert re.findall(r'```.*?```', before, re.S) == re.findall(r'```.*?```', after, re.S)
    references = set(re.findall(r'\[\^([^]]+)\](?!:)', after))
    definitions = set(re.findall(r'^\[\^([^]]+)\]:', after, re.M))
    assert references == definitions, (name, references ^ definitions)
    target = OUT / name
    target.mkdir(exist_ok=True)
    (target / 'final.md').write_text(after, encoding='utf-8')
    diff = ''.join(difflib.unified_diff(before.splitlines(True), after.splitlines(True),
                   fromfile=name + '/before/final.md', tofile=name + '/final.md'))
    (target / 'final.diff').write_text(diff, encoding='utf-8')
    styled = '\n'.join('<span class="' + ('add' if line.startswith('+') else 'remove' if line.startswith('-') else '') + '">' + html.escape(line) + '</span>' for line in diff.splitlines())
    counts[name] = {'before_words': len(before.split()), 'after_words': len(after.split())}
    panels.append(f'<section id="{name}"><article>{render(after)}</article><details><summary>What changed in {name}</summary><pre>{styled}</pre><p><a href="{name}/final.diff">Text diff</a> · <a href="{name}/final.md">Revised source</a> · <a href="before/{name}/final.md">Before</a></p></details></section>')

lineage = '''<article id="lineage"><h1>What do we want a form to give us?</h1>
<p>The closing Primitives rooms move from making a body to choosing what matters about it. The tools become more useful while their purpose remains ours to decide.</p>
<table><thead><tr><th>Encounter</th><th>Making</th><th>Reading</th></tr></thead><tbody>
<tr><td>Ignorance and the columns</td><td>A rule, a profile, parameters.</td><td>Why seek regularity? What makes a body seem worth revering?</td></tr>
<tr><td>Portals</td><td>A measurement and a tolerance.</td><td>Enough for which purpose? What remains to choose?</td></tr>
<tr><td>Melencolia</td><td>Compose with the constructions we know.</td><td>What did we hope a correct answer would resolve?</td></tr>
</tbody></table><p>This is a small pass in the three canonical <code>final.md</code> files. Existing encounters, code excerpts and historical examples remain. The single-column tutorial is the next proposed exercise; its scope is recorded in the <a href="../../course/PRIMITIVES-CLOSING-LINEAGE.md">closing lineage agreement</a>.</p>
<p><a href="#Primitives_Ignorance">Read Ignorance</a> · <a href="#Primitives_Portals">Read Portals</a> · <a href="#Primitives_Melencolia">Read Melencolia</a></p></article>'''

gallery = '<article id="gallery"><h2>The column companion</h2><p class="small">Existing native Godot capture of the revised gallery. Its physical place in the museum is still to be chosen.</p><figure><img src="../2026-10-03-resolution-colonnade/colonnade.png" alt="Different pale column profiles and heights in the red-walled Rings of Ash gallery."><figcaption>The varied composition. The equal-form arrangement remains available for a controlled comparison.</figcaption></figure>' + render((OUT / 'colonnade-passage.md').read_text(encoding='utf-8')) + '<p><a href="../2026-10-03-resolution-colonnade/index.html">Walkable gallery and download</a></p></article>'

css = (OUT.parent / '2026-10-03-primitives-a-rule-for-positions/style.css').read_text(encoding='utf-8')
css += '\ntable{border-collapse:collapse;width:100%;font:16px/1.5 system-ui,sans-serif;margin:25px 0}td,th{text-align:left;vertical-align:top;padding:12px;border-bottom:1px solid #cdc6bd}pre{white-space:pre-wrap;overflow-wrap:anywhere}.add{background:#e1ecdd}.remove{background:#f3dddd}section{border-top:1px solid #cdc6bd}details p{font:14px/1.5 system-ui,sans-serif}.footnote{font-size:15px}'
(OUT / 'style.css').write_text(css, encoding='utf-8')
page = '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Primitives — form and desire</title><link rel="stylesheet" href="style.css"></head><body><main><header><nav><a href="#lineage">Closing progression</a><a href="#gallery">Column passage</a><a href="#reading">Read the chapters</a><a href="SOURCE-NOTES.md">Sources and decisions</a></nav><p>ADA / MANUSCRIPT PASS / 3 OCTOBER 2026</p></header>' + lineage + gallery + '<div id="reading">' + ''.join(panels) + '</div></main></body></html>'
(OUT / 'index.html').write_text(page, encoding='utf-8')

class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
    def handle_starttag(self, tag, attrs):
        self.links.extend(v for k, v in attrs if k in ('href', 'src'))

links = Links()
links.feed(page)
local = 0
for link in links.links:
    url = urlsplit(link)
    if url.scheme or not url.path:
        continue
    assert (OUT / unquote(url.path)).exists(), link
    local += 1
report = {'manuscripts_updated': counts, 'encounter_markers_unchanged': True,
          'code_blocks_unchanged': True, 'footnotes_resolve': True,
          'local_links_resolve': local, 'tutorials_changed': False,
          'spine_placement_changed': False, 'runtime_changed': False}
(OUT / 'review-checks.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report))
