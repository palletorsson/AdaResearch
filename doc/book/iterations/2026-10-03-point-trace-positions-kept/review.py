"""Build the one-lesson Trace review from canonical prose and tested learner code."""
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
SOURCE = OUT / 'Point_Trace.tutorial.md' # Frozen earlier review; see the release/replay correction.
after = SOURCE.read_text(encoding='utf-8')
before = (OUT / 'before/tutorial.md').read_text(encoding='utf-8')
code = (OUT / 'trace.gd').read_text(encoding='utf-8')
blocks = re.findall(r'```gdscript\n(.*?)```', after, re.S)
assert len(blocks) == 5
for block in blocks:
    assert block.strip() in code
assert '$' not in code and 'get_node' not in code and 'NodePath' not in code
reference = ET.parse(ROOT.parent / 'godot_reference_4.6/doc/classes/Array.xml').getroot()
for method in ('append', 'size', 'pop_front'):
    assert reference.find(f"methods/method[@name='{method}']") is not None
check = json.loads((OUT / 'verification.json').read_text())
assert check['passed'] and all(c['passed'] for c in check['checks'])
(OUT / 'trace.gd').write_text(code, encoding='utf-8')
for name in ('point_handle.gd', 'segment.gd', 'trace_drawing.gd'):
    (OUT / name).write_text((STARTER / 'prepared' / name).read_text(encoding='utf-8'), encoding='utf-8')
(OUT / 'Point_Trace.tutorial.md').write_text(after, encoding='utf-8')
(OUT / 'Point_Trace.tutorial.diff').write_text(''.join(difflib.unified_diff(before.splitlines(True), after.splitlines(True), fromfile='before/Point_Trace/tutorial.md', tofile='commons/maps/Point_Trace/tutorial.md')), encoding='utf-8')
contract = {
    'map': 'Point_Trace', 'status': 'author_review_pilot',
    'inherits': ['Point Zero: ready/process, variables, Label3D and str()', 'Point One: Vector3 position and value', 'Lines: subtraction, length, PointHandle and Segment'],
    'introduces': ['Array[Vector3]: ordered one-dimensional list of positions', 'append, index (including last entry), size', 'if and >=: admission by minimum separation', 'for/range: traverse neighbouring index pairs', 'pop_front: remove oldest when capacity is exceeded'],
    'supplied': ['TraceDrawing.clear and join: pooled segments and sample markers', 'PointHandle: desktop and XR Tools pickup, frozen release', 'Day Zero room, lighting and player'],
    'learner_actions': ['move, pause and inspect unchanged count', 'increase spacing from 0.08 to 0.25', 'follow three adjacent pairs through four entries', 'set capacity to 32 and displace the oldest position'],
    'museum_relation': 'Reduced continuous centre-position recorder; no grid snapping, nib offset, stroke separation or TraceData export',
    'deferred': ['Grid: assign kept positions to cells', 'whole-array copying and persistence', 'pen nib and multiple strokes', 'physics of the ramp ball'],
    'coordinates_rewrite_pending': True, 'printed_code_matches_download': True,
    'source_sha256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
    'physical_headset_tested': False,
}
(OUT / 'lesson-contract.json').write_text(json.dumps(contract, indent=2) + '\n', encoding='utf-8')
reading = markdown.markdown(after.replace('../../../doc/book/studies/ada-xr-starter/README.md','../2026-10-03-ada-xr-starter/index.html#guide'), extensions=['fenced_code'])
reading = reading.replace('<h2>1. Give positions somewhere to stay</h2>', '<figure><a href="fine.png"><img src="fine.png" alt="A pale trace with pink saved positions forms a loop in the Godot room; the readout shows 47 positions kept"></a><figcaption>Inside the shared starter. A scripted movement leaves 47 positions at eight-centimetre spacing. Actual Godot render.</figcaption></figure><h2>1. Give positions somewhere to stay</h2>')
reading = reading.replace('<h2>4. Change what the route can retain</h2>', '<div class="pair"><figure><a href="fine.png"><img src="fine.png" alt="Fine sampling keeps 47 positions" loading="lazy"></a><figcaption>Spacing 0.08 m · 47 positions.</figcaption></figure><figure><a href="coarse.png"><img src="coarse.png" alt="Coarse sampling keeps 17 positions and visibly cuts corners" loading="lazy"></a><figcaption>The same movement, spacing 0.25 m · 17 positions.</figcaption></figure></div><h2>4. Change what the route can retain</h2>')
reading += '<figure><a href="memory.png"><img src="memory.png" alt="The trace holds 32 recent positions; the older portion of the loop has disappeared" loading="lazy"></a><figcaption>Capacity 32 · recent positions remain; the earlier part of the route has gone. A capacity limit acts when another position arrives.</figcaption></figure>'
page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Point Trace — positions kept</title><link rel="stylesheet" href="style.css"></head><body><main><header><p>ADA / ONE TUTORIAL AT A TIME · 3 October 2026</p><nav><a href="#reading">Read Point Trace</a><a href="#code">Complete script</a><a href="#lineage">What it adds</a><a href="Point_Trace.tutorial.diff">Text diff</a></nav></header><article id="reading">{reading}<p><a class="download" href="../2026-10-03-ada-xr-starter/ada-xr-starter.zip" download>Download the starter with Point Trace</a></p><p class="small">Open point_trace.tscn · Run Current Scene (F6).</p></article><details id="code"><summary>trace.gd · the complete working lesson</summary><div><pre><code>{html.escape(code)}</code></pre><p>The construction reuses PointHandle and Label3D. The new display helper draws each pair the student's loop passes to it.</p><p><a href="trace.gd" download>Download trace.gd</a> · <a href="trace_drawing.gd">Supplied TraceDrawing</a> · <a href="point_handle.gd">PointHandle</a> · <a href="segment.gd">Segment</a></p></div></details><section id="lineage" class="lineage"><h2>The route outlasts its point.</h2><p>A position in Point One. A relation between two positions in Lines. In Trace, a list keeps positions and a loop follows their order. The student can now make a record, choose what enters it and determine how much survives.</p><p>The for loop traverses the retained list when another position is added. The engine's process callback offers another opportunity to sample each frame. Repetition through a collection and repetition over time are different operations.</p><p>Grid will ask what changes when a saved position is assigned to a cell. Coordinates still retains its earlier place in the spine; its shared-starter writing pass remains pending.</p><p class="small">The canonical tutorial and executable companion are updated. The critical manuscript and live museum are unchanged. This is one continuous centre-position study; the museum pens have additional rules for nib position, snapping and separate strokes.</p></section><details id="checked"><summary>{len(check['checks'])} checks passed · evidence and limits</summary><div><p>Fresh ZIP import and native Godot 4.6 checks cover retention, the distance threshold, ordered drawing, changed spacing, bounded memory, waiting, geometry reuse, desktop pickup and synthetic XR grip. Every printed code excerpt matches the downloadable script.</p><p>The images show the same scripted route for comparison. They are actual desktop renders, not a recorded visitor gesture. A physical headset and beginner reading trial remain pending.</p><p><a href="verification.json">Native results</a> · <a href="lesson-contract.json">Teaching scope</a> · <a href="DECISIONS.md">Editorial decisions</a></p></div></details></main><script>function reveal(){{const el=document.getElementById(location.hash.slice(1));if(el?.tagName==='DETAILS')el.open=true}}addEventListener('hashchange',reveal);reveal();</script></body></html>'''
(OUT / 'index.html').write_text(page, encoding='utf-8')
print(json.dumps({'words_including_code':len(after.split()), 'native_checks':len(check['checks']), 'printed_code_matches':True}))
