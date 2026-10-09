"""Build the Grid pilot from canonical prose, tested code and Godot captures."""
from pathlib import Path
import difflib
import hashlib
import html
import json
import re
import xml.etree.ElementTree as ET
import markdown

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
STARTER = ROOT / 'doc/book/studies/ada-xr-starter'
SOURCE = OUT / 'Point_Line_Grid.tutorial.md' # Frozen earlier review; see the release/replay correction.
after = SOURCE.read_text(encoding='utf-8')
before = (OUT / 'before/tutorial.md').read_text(encoding='utf-8')
code = (OUT / 'grid.gd').read_text(encoding='utf-8')
blocks = re.findall(r'```gdscript\n(.*?)```', after, re.S)
assert len(blocks) == 4
for block in blocks:
    assert block.strip() in code
assert '$' not in code and 'get_node' not in code and 'NodePath' not in code
reference = ET.parse(ROOT.parent / 'godot_reference_4.6/doc/classes/@GlobalScope.xml').getroot()
assert reference.find("methods/method[@name='roundi']/return").get('type') == 'int'
check = json.loads((OUT / 'verification.json').read_text())
assert check['passed'] and all(c['passed'] for c in check['checks'])
(OUT / 'grid.gd').write_text(code, encoding='utf-8')
for name in ('point_handle.gd', 'segment.gd', 'trace_drawing.gd', 'grid_ruling.gd'):
    (OUT / name).write_text((STARTER / 'prepared' / name).read_text(encoding='utf-8'), encoding='utf-8')
(OUT / 'Point_Line_Grid.tutorial.md').write_text(after, encoding='utf-8')
(OUT / 'Point_Line_Grid.tutorial.diff').write_text(''.join(difflib.unified_diff(before.splitlines(True), after.splitlines(True), fromfile='before/Point_Line_Grid/tutorial.md', tofile='commons/maps/Point_Line_Grid/tutorial.md')), encoding='utf-8')
contract = {
    'map': 'Point_Line_Grid', 'status': 'author_review_pilot',
    'inherits': ['Point One: a position and a visible sphere', 'Coordinates/Lines: shared frame and supplied PointHandle', 'Trace: Array[Vector3], append, indexing, size, capacity and adjacent-pair traversal'],
    'introduces': ['divide coordinate by spacing to count intervals', 'roundi: nearest integer, halfway away from zero', 'Vector3i: integer lattice address', 'Vector3(address) times spacing: placement in metres', 'is_empty and !=: seed record, then admit changes', 'array index names a visit; grid address names a place'],
    'supplied': ['GridRuling: finite XY section at local Z=0, labelled in grid indices', 'PointHandle and TraceDrawing: inherited hold and drawing', 'Day Zero room, lighting and player'],
    'learner_actions': ['change X from 0.12 to 0.13', 'repeat with negative X', 'move within and between addresses', 'return to a previous address', 'change spacing from 0.25 to 0.5', 'move in depth beyond the XY ruling'],
    'museum_relation': 'Core nearest-lattice operation from grab_sphere_point_snap; larger visible spacing in Study-local coordinates, separate input and output, no release alignment',
    'deferred': ['nested loops for a floor plan', 'transforming a received drawing', 'headset/body choice for a walking trace', 'release alignment', 'Triangle: boundary, face and collision'],
    'coordinates_rewrite_pending': True, 'printed_code_matches_download': True,
    'source_sha256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(), 'physical_headset_tested': False,
}
(OUT / 'lesson-contract.json').write_text(json.dumps(contract, indent=2) + '\n', encoding='utf-8')
reading = markdown.markdown(after.replace('../../../doc/book/studies/ada-xr-starter/README.md','../2026-10-03-ada-xr-starter/index.html#guide'), extensions=['fenced_code'])
reading = reading.replace('<h2>1. Count steps from an origin</h2>', '<figure><a href="before-boundary.png"><img src="before-boundary.png" alt="Pink free input at x=0.12 metres beside the white output at zero; separate input, address and placement readings inside the Godot starter"></a><figcaption>The free point and its placed marker. Actual Godot desktop view inside the shared starter.</figcaption></figure><h2>1. Count steps from an origin</h2>')
reading = reading.replace('<h2>3. Keep an order of visits</h2>', '<div class="pair"><figure><a href="before-boundary.png"><img src="before-boundary.png" alt="X 0.12 maps to address zero" loading="lazy"></a><figcaption>Input X 0.12 m → address X 0 → placed X 0 m.</figcaption></figure><figure><a href="after-boundary.png"><img src="after-boundary.png" alt="X 0.13 maps to address one" loading="lazy"></a><figcaption>Input X 0.13 m → address X 1 → placed X 0.25 m.</figcaption></figure></div><h2>3. Keep an order of visits</h2>')
reading += f'<div class="pair"><figure><a href="quarter.png"><img src="quarter.png" alt="The retained route at quarter-metre spacing" loading="lazy"></a><figcaption>Spacing 0.25 m · {check["quarter_metre_visits"]} recorded visits.</figcaption></figure><figure><a href="half.png"><img src="half.png" alt="The same movement recorded at half-metre spacing" loading="lazy"></a><figcaption>Same scripted movement, spacing 0.5 m · {check["half_metre_visits"]} visits.</figcaption></figure></div>'
page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Point Grid — a place to return to</title><link rel="stylesheet" href="style.css"></head><body><main><header><p>ADA / ONE TUTORIAL AT A TIME · 3 October 2026</p><nav><a href="#reading">Read Point Grid</a><a href="#code">Complete script</a><a href="#lineage">What it adds</a><a href="Point_Line_Grid.tutorial.diff">Text diff</a></nav></header><article id="reading">{reading}<p><a class="download" href="../2026-10-03-ada-xr-starter/ada-xr-starter.zip" download>Download the starter with Point Grid</a></p><p class="small">Open point_grid.tscn · Run Current Scene (F6).</p></article><details id="code"><summary>grid.gd · the complete working lesson</summary><div><pre><code>{html.escape(code)}</code></pre><p>The output sphere reuses Point One's construction. The new ruling helper supplies only the reference lines; the calculation that gives a position its address is visible in the learner code.</p><p><a href="grid.gd" download>Download grid.gd</a> · <a href="grid_ruling.gd">Supplied GridRuling</a> · <a href="trace_drawing.gd">TraceDrawing</a> · <a href="point_handle.gd">PointHandle</a> · <a href="segment.gd">Segment</a></p></div></details><section id="lineage" class="lineage"><h2>A place and a visit have different names.</h2><p>A position in Point One. A relation between two positions in Lines. An ordered record in Trace. Now a grid address makes nearby positions agree, and the record can retain separate visits to the same address.</p><p>The flat ruling is a section of the three-dimensional calculation. Moving in depth still changes the third address component. Neither the ruling nor the retained line supplies collision.</p><p>Triangle comes next: close a boundary, then add a face. Coordinates keeps its earlier place in the spine; its shared-starter writing pass remains pending.</p><p class="small">The canonical tutorial and executable companion are updated. The critical manuscript and live museum are unchanged. The hall's release alignment and floor-plan construction remain separate encounters.</p></section><details id="checked"><summary>{len(check['checks'])} checks passed · evidence and limits</summary><div><p>Fresh ZIP import and native Godot 4.6 checks cover positive and negative rounding boundaries, halfway values, all three coordinates, unchanged input, repeated visits, diagonal jumps, spacing changes, capacity, desktop pickup and synthetic XR grip.</p><p>Every printed excerpt matches the downloadable code. Images are actual desktop renders using scripted positions for comparison. A physical headset and beginner reading trial remain pending.</p><p><a href="depth.png">View a connection in depth</a> · <a href="verification.json">Native results</a> · <a href="lesson-contract.json">Teaching scope</a> · <a href="DECISIONS.md">Editorial decisions</a></p></div></details></main><script>function reveal(){{const el=document.getElementById(location.hash.slice(1));if(el?.tagName==='DETAILS')el.open=true}}addEventListener('hashchange',reveal);reveal();</script></body></html>'''
(OUT / 'index.html').write_text(page, encoding='utf-8')
print(json.dumps({'words_including_code':len(after.split()),'native_checks':len(check['checks']),'printed_code_matches':True}))
