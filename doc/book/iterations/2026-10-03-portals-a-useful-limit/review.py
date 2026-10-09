from pathlib import Path
import difflib
import html
import json
import re

import markdown

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
STARTER = ROOT / 'doc/book/studies/ada-xr-starter'
MAP = ROOT / 'commons/maps/Primitives_Portals'
prose = (MAP / 'tutorial.md').read_text(encoding='utf-8')
code = (STARTER / 'studies/primitive_portals/perimeter.gd').read_text(encoding='utf-8')
blocks = re.findall(r'```gdscript\n(.*?)```', prose, re.S)
assert len(blocks) == 3 and all(block.strip() in code for block in blocks)
assert '$' not in code and 'get_node' not in code
report = json.loads((OUT / 'verification.json').read_text(encoding='utf-8'))
assert report['passed'] and all(c['passed'] for c in report['checks'])
assert (MAP / 'tutorial-previous.md').read_bytes() == (OUT / 'before/tutorial.md').read_bytes()
before = (OUT / 'before/tutorial.md').read_text(encoding='utf-8')
(OUT / 'tutorial.md').write_text(prose, encoding='utf-8')
(OUT / 'perimeter.gd').write_text(code, encoding='utf-8')
(OUT / 'tutorial.diff').write_text(''.join(difflib.unified_diff(before.splitlines(True), prose.splitlines(True), fromfile='before/tutorial.md', tofile='tutorial.md')), encoding='utf-8')
reading = markdown.markdown(prose.replace('../../../doc/book/studies/ada-xr-starter/README.md', '../../studies/ada-xr-starter/README.md'), extensions=['fenced_code'])

def figure(name, alt, caption):
    return f'<figure><a href="{name}"><img src="{name}" alt="{alt}"></a><figcaption>{caption}</figcaption></figure>'

reading = reading.replace('<h2>1. Follow the closed line</h2>', figure('sides-6.png', 'Pink hexagon inside a grey circular guide in the running student room, with perimeter and tolerance readouts.', 'Six segments. A closed line, measured from the same positions used to draw it.') + '<h2>1. Follow the closed line</h2>')
pair = '<div class="pair">' + figure('sides-12.png', 'Twelve-sided polygon approaching the fixed grey guide.', '12 sides. The straight edges remain visible.') + figure('sides-24.png', 'Twenty-four-sided polygon with a smaller gap to the guide.', '24 sides. Closer, but outside the chosen 0.01 m tolerance.') + '</div>'
reading = reading.replace('<h2>3. Choose what counts as enough</h2>', pair + '<h2>3. Choose what counts as enough</h2>')
pair = '<div class="pair">' + figure('sides-48.png', 'Forty-eight-sided polygon marked within tolerance at 0.01 metre.', '48 sides / tolerance 0.01 m. The comparison passes.') + figure('tighter-tolerance.png', 'Identical forty-eight-sided polygon marked outside tolerance at 0.001 metre.', 'Same positions / tolerance 0.001 m. The requirement changes.') + '</div>'
reading = reading.replace('<p>In exact geometry,', pair + '<p>In exact geometry,')
checks = len(report['checks'])
page = f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Portals — how close is useful?</title><link rel="stylesheet" href="style.css"></head><body><main>
<header><nav><a href="#reading">Read the lesson</a><a href="#code">Complete code</a><a href="#scope">Lineage and scope</a><a href="#checked">Checks</a><a href="../2026-10-03-primitives-a-rule-for-positions/index.html#reading">Previous: Primitives</a></nav><p>ADA / TUTORIAL PILOT / 3 OCTOBER 2026</p></header>
<article id="reading">{reading}<p><a class="download" href="../2026-10-03-ada-xr-starter/ada-xr-starter.zip" download>Download the updated starter</a></p><p class="small">Open primitive_portals.tscn with Run Current Scene. Click an image for its full native render.</p></article>
<details id="code"><summary>perimeter.gd · the complete lesson</summary><div><p>The learner computes a closed boundary length from an ordered list. CircleSamples supplies points; PolygonDisplay supplies segments, a fixed 256-segment reference and readouts. Their sources are included in the starter. All lesson objects are created in code with direct references.</p><pre><code>{html.escape(code)}</code></pre><p><a href="perimeter.gd" download>Complete script</a> · <a href="tutorial.md">Tutorial source</a> · <a href="tutorial.diff">Text diff</a></p></div></details>
<details id="scope"><summary>A short application, with a deliberate stopping criterion</summary><div><p>Lines taught distance, Trace taught traversal, and Primitives introduced a function returning data. Portals combines them in a list-to-number function. The new distinction is between more detail and enough detail for a stated requirement.</p><p>The grey guide is finite. The circumference number uses TAU × radius; it is not measured from that guide. The gap is a difference of boundary lengths, not maximum spatial error, torus accuracy, or frame time. These moderate counts do not stage floating-point saturation.</p><p>The <a href="../../../../commons/maps/Primitives_Portals/technical.md">museum's technical account</a> describes the separate planar instrument, rings and halving track. The previous tutorial introduced additional topics, including portal velocity, that were not implementations of these placed rings. It is preserved as an <a href="../../../../commons/maps/Primitives_Portals/tutorial-previous.md">archived previous draft</a>, not the current hall instructions.</p><p>No critical text or museum placement was edited. Trigonometric derivation, topology and automatic refinement are deferred. Next: Melencolia, an arrangement made from known forms. Coordinates still needs its earlier shared-starter pass. <a href="lesson-contract.json">Teaching contract</a> · <a href="DECISIONS.md">Decisions</a></p></div></details>
<details id="checked"><summary>{checks} native checks passed</summary><div><p>Fresh ZIP import; actual printed parameter edits; fixed radius; comparison against the independent chord formula; closing-edge accounting on a 3–4–5 triangle; input preservation; translation and scale checks; tolerance change without a geometry change; bounded redraw; construction on a bare Node3D.</p><p>The images are actual Godot 4.6 student-room renders. No new input system was added. Physical headset use and beginner comprehension remain untested.</p><p><a href="verification.json">Results</a> · <a href="verify.gd">Reproducible harness</a> · <a href="package-verification.json">Download checks</a></p></div></details>
</main><script>function reveal(){{const el=document.getElementById(location.hash.slice(1));if(el?.tagName==='DETAILS')el.open=true}}addEventListener('hashchange',reveal);reveal();</script></body></html>'''
(OUT / 'index.html').write_text(page, encoding='utf-8')
print(json.dumps({'checks': checks, 'printed_code_excerpts': len(blocks), 'tutorial_words_including_code': len(prose.split())}))
