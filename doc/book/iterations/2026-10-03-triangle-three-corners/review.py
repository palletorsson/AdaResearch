from pathlib import Path
import difflib
import html
import json
import re

import markdown

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
STARTER = ROOT / 'doc/book/studies/ada-xr-starter'
prose = (ROOT / 'commons/maps/Point_Triangle_Context/tutorial.md').read_text(encoding='utf-8')
code = (STARTER / 'studies/point_triangle/triangle.gd').read_text(encoding='utf-8')
blocks = re.findall(r'```gdscript\n(.*?)```', prose, re.S)
assert len(blocks) == 4 and all(block.strip() in code for block in blocks)
assert '$' not in code and 'get_node' not in code
report = json.loads((OUT / 'verification.json').read_text(encoding='utf-8'))
assert report['passed'] and all(c['passed'] for c in report['checks'])
before = (OUT / 'before/tutorial.md').read_text(encoding='utf-8')
(OUT / 'tutorial.md').write_text(prose, encoding='utf-8')
(OUT / 'triangle.gd').write_text(code, encoding='utf-8')
(OUT / 'tutorial.diff').write_text(''.join(difflib.unified_diff(before.splitlines(True), prose.splitlines(True), fromfile='before/tutorial.md', tofile='tutorial.md')), encoding='utf-8')
museum = (ROOT / 'commons/maps/Point_Triangle_Context/tutorial-museum.md').read_text(encoding='utf-8')
(OUT / 'tutorial-museum.md').write_text(museum, encoding='utf-8')
reading = markdown.markdown(prose.replace('../../../doc/book/studies/ada-xr-starter/README.md', '../../studies/ada-xr-starter/README.md'), extensions=['fenced_code'])
pair = '''<div class="pair"><figure><img src="outline.png" alt="Three pink corners joined by dark edges, with an empty centre."><figcaption>The same trace supplies three corners. Closing their boundary adds no face.</figcaption></figure><figure><img src="face.png" alt="The same corners and edges, now surrounding one off-white triangular face."><figcaption>One explicit triangle submission. The corner positions and viewpoint are unchanged.</figcaption></figure></div>'''
reading = reading.replace('<h2>3. Add the face</h2>', pair + '<h2>3. Add the face</h2>')
reading += '''<figure><img src="collinear.png" alt="The three corners now lie along one line; no triangle area remains."><figcaption>Move the third corner onto the baseline: the submitted triangle has zero area. These are native views from the shared student room, using the same 41-position synthetic XR release record tested in Trace and Grid.</figcaption></figure>'''
checks = len(report['checks'])
page = f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Triangle — three corners, then a face</title><link rel="stylesheet" href="style.css"></head><body><main>
<header><nav><a href="#reading">Read the lesson</a><a href="#code">Complete code</a><a href="#scope">Lineage and scope</a><a href="#checked">Checks</a><a href="../2026-10-03-trace-return-to-grid/index.html#reading">Previous: Trace returns in Grid</a></nav><p>ADA / TUTORIAL PILOT / 3 OCTOBER 2026</p></header>
<article id="reading">{reading}<p><a class="download" href="../2026-10-03-ada-xr-starter/ada-xr-starter.zip" download>Download the updated starter</a></p><p class="small">Release a drawing in point_trace.tscn first. Then open point_triangle.tscn with Run Current Scene. The shared starter contains both lessons.</p></article>
<details id="code"><summary>triangle.gd · the complete lesson</summary><div><p>Every lesson object is constructed in this script. PointHandle, Segment and TraceMemory are the same supplied components already used; the two material resources set appearance. The missing-record guard and readout support the lesson.</p><pre><code>{html.escape(code)}</code></pre><p><a href="triangle.gd" download>Download triangle.gd</a> · <a href="tutorial.md">Tutorial source</a> · <a href="tutorial.diff">Text diff</a></p></div></details>
<details id="scope"><summary>What this adds to the lineage</summary><div><p>Point stores a position. Lines connect two positions. Trace retains positions in order. Grid maps that original list into a second list. Triangle returns to the same original and chooses three positions, then gives their relationship an explicit surface.</p><p>Selection is by list index. It does not recognise corners, space them evenly by distance, project a drawing into a plane or reconstruct the entire gesture. We keep these limits visible. Editing a corner changes a copy; it does not overwrite Trace.</p><p>The new mesh operation belongs to the learner. Appearance, pickup and file transport remain named supplied parts. The next lesson can reuse a triangular face to ask about enclosure.</p><p>The longer hall walkthrough and concave-fan experiment are preserved as a <a href="tutorial-museum.md">museum return</a>. The critical chapter and live hall are unchanged. Coordinates retains its earlier place in the spine; its shared-starter writing pass is still pending.</p><p><a href="lesson-contract.json">Teaching contract</a> · <a href="DECISIONS.md">Decisions</a></p></div></details>
<details id="checked"><summary>{checks} native checks passed</summary><div><p>Checked in a freshly extracted starter with Godot 4.6: exact saved-source selection, no face before submission, unchanged source, face rebuilding after mouse and simulated XR grip movement, release, collinear and coincident corners, recovery, no surface accumulation, no interior collision, empty state, minimum record and construction on a bare Node3D.</p><p>All four printed code excerpts match the tested script. The images show the actual native student room. Synthetic controller poses and injected mouse events exercise the real pickup path; physical headset use and beginner comprehension remain untested.</p><p><a href="verification.json">Results</a> · <a href="verify.gd">Reproducible harness</a> · <a href="back.png">Back view</a> · <a href="empty.png">Missing-record state</a></p></div></details>
</main><script>function reveal(){{const el=document.getElementById(location.hash.slice(1));if(el?.tagName==='DETAILS')el.open=true}}addEventListener('hashchange',reveal);reveal();</script></body></html>'''
(OUT / 'index.html').write_text(page, encoding='utf-8')
print(json.dumps({'checks': checks, 'printed_code_excerpts': len(blocks), 'tutorial_words_including_code': len(prose.split())}))
