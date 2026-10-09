from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import difflib
import html
import json
import re
import markdown

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
STUDY = ROOT / 'doc/book/studies/ada-xr-starter'
report = json.loads((OUT / 'verification.json').read_text(encoding='utf-8'))
package = json.loads((OUT / 'package-verification.json').read_text(encoding='utf-8'))
assert report['passed'] and package['passed']
assert all(c['passed'] for c in report['checks'])
column = (ROOT / 'commons/maps/Primitives_Ignorance/tutorial-column.md').read_text(encoding='utf-8')
composition = (ROOT / 'commons/maps/Primitives_Melencolia/tutorial.md').read_text(encoding='utf-8')
column_code = (STUDY / 'studies/primitive_column/column.gd').read_text(encoding='utf-8')
composition_code = (STUDY / 'studies/primitive_composition/arrangement.gd').read_text(encoding='utf-8')
code_blocks = 0
for prose, code in [(column, column_code), (composition, composition_code)]:
    blocks = re.findall(r'```gdscript\n(.*?)```', prose, re.S)
    assert all(block.strip() in code for block in blocks)
    assert '$' not in code and 'get_node' not in code and 'find_child' not in code
    code_blocks += len(blocks)

for name, source in [('column', column), ('composition', composition)]:
    (OUT / (name + '-tutorial.md')).write_text(source, encoding='utf-8')

museum = ROOT / 'commons/maps/Primitives_Melencolia/tutorial-museum.md'
assert museum.read_bytes() == (OUT / 'before/melencolia-tutorial.md').read_bytes()
diffs = []
for name, map_name in [('ignorance', 'Primitives_Ignorance'), ('melencolia', 'Primitives_Melencolia')]:
    before = (OUT / 'before' / (name + '-tutorial.md')).read_text(encoding='utf-8')
    after = (ROOT / 'commons/maps' / map_name / 'tutorial.md').read_text(encoding='utf-8')
    diff = ''.join(difflib.unified_diff(before.splitlines(True), after.splitlines(True), fromfile=map_name + '/before/tutorial.md', tofile=map_name + '/tutorial.md'))
    (OUT / (name + '.diff')).write_text(diff, encoding='utf-8')
    diffs.append(f'<p><a href="{name}.diff">{map_name}: exact diff</a></p>')

def render(text):
    text = text.replace('../../../doc/book/studies/ada-xr-starter/README.md', '../../studies/ada-xr-starter/README.md')
    text = text.replace('(tutorial-museum.md)', '(../../../../commons/maps/Primitives_Melencolia/tutorial-museum.md)')
    return markdown.markdown(text, extensions=['fenced_code', 'tables'])

def figure(filename, caption):
    return f'<figure><a href="{filename}"><img loading="lazy" src="{filename}" alt="{html.escape(caption)}"></a><figcaption>{html.escape(caption)}</figcaption></figure>'

def pair(a, caption_a, b, caption_b):
    return '<div class="pair">' + figure(a, caption_a) + figure(b, caption_b) + '</div>'

column_reading = render(column)
column_reading = column_reading.replace('<h2>1. Read the outline</h2>', figure('column.png', 'The column in the prepared student room: seven rings, eight positions around each ring.') + '<h2>1. Read the outline</h2>')
column_reading = column_reading.replace('<h2>2. Follow one entry into space</h2>', pair('column.png', 'Middle radius 0.22 m. The waist narrows.', 'bulge.png', 'Middle radius 0.55 m. Only that ring expands.') + '<h2>2. Follow one entry into space</h2>')
column_reading = column_reading.replace('<h2>4. Keep an outline of your own</h2>', pair('sides-4.png', 'Four sides. The profile and full height are unchanged.', 'sides-16.png', 'Sixteen sides. Additional divisions around each ring.') + '<h2>4. Keep an outline of your own</h2>')
composition_reading = render(composition)
composition_reading = composition_reading.replace('<h2>1. Place the same form three times</h2>', figure('arrangement.png', 'Three identical pyramids. The middle one begins farther away.') + '<h2>1. Place the same form three times</h2>')
composition_reading = composition_reading.replace('<h2>3. Change the distance between neighbours</h2>', pair('arrangement.png', 'Middle Z = −0.8: the body stands behind its neighbours.', 'forward.png', 'Middle Z = 0.8: the unchanged body moves forward.') + '<h2>3. Change the distance between neighbours</h2>')
composition_reading = composition_reading.replace('<h2>4. Make one arrangement to keep</h2>', pair('close.png', 'The outer bodies are closer together. View from the entrance.', 'side.png', 'The same arrangement seen from the side. No body moved.') + '<h2>4. Make one arrangement to keep</h2>')

complete = []
for path in ['studies/primitive_column/column.gd', 'studies/primitive_column/column_surface.gd', 'studies/primitive_composition/arrangement.gd', 'studies/primitive_composition/pyramid.gd']:
    text = (STUDY / path).read_text(encoding='utf-8')
    assert '$' not in text and 'get_node' not in text
    name = Path(path).name
    (OUT / name).write_text(text, encoding='utf-8')
    complete.append(f'<details><summary>{name}</summary><div><pre><code>{html.escape(text)}</code></pre><p><a href="{name}" download>Download {name}</a></p></div></details>')

css = (OUT.parent / '2026-10-03-primitives-a-rule-for-positions/style.css').read_text(encoding='utf-8')
css += '\n.chapter{border-top:1px solid #cdc6bd;padding-top:28px}.route{display:flex;flex-wrap:wrap;gap:16px;margin:26px 0;font:16px/1.5 system-ui,sans-serif}.route a{border:1px solid #c7b7ba;padding:12px 18px;text-decoration:none}.quiet{font:15px/1.6 system-ui,sans-serif;color:#655c60}.wide{max-width:950px}.step{letter-spacing:.08em;font:13px/1.5 system-ui,sans-serif;color:#84445f;text-transform:uppercase}'
(OUT / 'style.css').write_text(css, encoding='utf-8')
page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Primitives — make a form, choose an arrangement</title><link rel="stylesheet" href="style.css"></head><body><main>
<header><nav><a href="#reading">One column</a><a href="#portals">Portals</a><a href="#composition">Melencolia</a><a href="#code">Complete code</a><a href="#decisions">Lineage and checks</a></nav><p>ADA / TWO MAKING STUDIES / 3 OCTOBER 2026</p></header>
<article><p class="step">The end of Primitives</p><h1>Make a form.<br>Choose an arrangement.</h1><p>A list becomes a column. A measurement gives one way to decide when to stop. The forms we can construct become material for a composition.</p><p class="quiet">These lessons follow the existing octahedron function. Each uses the prepared student world. The critical chapters keep their own pace and historical questions.</p><div class="route"><a href="#reading">1 / Profile</a><a href="#portals">2 / Tolerance</a><a href="#composition">3 / Placement</a></div><a class="download" href="../2026-10-03-ada-xr-starter/ada-xr-starter.zip" download>Download the updated starter</a></article>
<article id="reading" class="chapter">{column_reading}<p class="quiet"><a href="column-tutorial.md">Tutorial source</a> · <a href="../2026-10-03-primitives-a-rule-for-positions/index.html#reading">Previous: a function returns positions</a></p></article>
<article id="portals" class="chapter"><p class="step">Between these two studies</p><h2>How close is useful?</h2><p>The existing Portals tutorial stays in place. Measure the closed polygon. Increase its side count. Then change the tolerance without changing the shape.</p><p><a href="../2026-10-03-portals-a-useful-limit/index.html#reading">Read Portals and run primitive_portals.tscn →</a></p><p class="quiet">Meeting a requirement, defining an exact form and deciding to keep an object are different acts.</p></article>
<article id="composition" class="chapter">{composition_reading}<p class="quiet"><a href="composition-tutorial.md">Tutorial source</a> · <a href="melencolia.diff">Before and after</a></p></article>
<section id="code"><article><h2>The code beside the lesson</h2><p>Read the small operation in the lesson. Open the complete script when you want to follow its attachments. The ZIP includes all helpers, materials and the prepared world.</p></article>{''.join(complete)}</section>
<details id="decisions"><summary>What changed, what was checked</summary><div><p>Ignorance gains a column companion; its existing function lesson gains one link. Melencolia gains a short composition tutorial; its earlier museum implementation notes are preserved. Portals is unchanged.</p><p>No critical manuscript or museum placement changed. The straight profile is an explicit reduction of the curved gallery. The pyramids study the museum's geometric court, not the Dürer tableau.</p><p>{len(report['checks'])} checks passed in Godot 4.6 against a freshly extracted starter. They include actual printed edits, closed meshes, independent volume, unchanged widths under height edits, placement without mesh deformation and camera projection. Screenshots are native renders from the running student room.</p><p>Physical headset use and beginner comprehension remain untested. Coordinates still needs its earlier starter pass. The local contracts do not certify the old numeric taxonomy.</p><p><a href="lesson-contract.json">Teaching contracts</a> · <a href="DECISIONS.md">Decisions and source</a> · <a href="verification.json">Runtime results</a> · <a href="package-verification.json">Package checks</a> · <a href="verify.gd">Test harness</a></p>{''.join(diffs)}</div></details>
</main><script>function reveal(){{const el=document.getElementById(location.hash.slice(1));if(el?.tagName==='DETAILS')el.open=true}}addEventListener('hashchange',reveal);reveal();</script></body></html>'''
(OUT / 'index.html').write_text(page, encoding='utf-8')

class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
        self.ids = set()
    def handle_starttag(self, tag, attrs):
        self.links.extend(v for k, v in attrs if k in ('href', 'src'))
        self.ids.update(v for k, v in attrs if k == 'id')

links = Links()
links.feed(page)
local = 0
for link in links.links:
    url = urlsplit(link)
    if url.scheme:
        continue
    if url.path:
        assert (OUT / unquote(url.path)).exists(), link
        local += 1
    elif url.fragment:
        assert url.fragment in links.ids, link
summary = {'printed_code_excerpts_match': code_blocks, 'local_links_resolve': local, 'runtime_checks': len(report['checks']), 'cold_download_checked': True, 'museum_notes_preserved_exactly': True, 'learner_scene_lookups': False, 'words_including_code': {'column': len(column.split()), 'composition': len(composition.split())}}
(OUT / 'review-checks.json').write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')
print(json.dumps(summary))
