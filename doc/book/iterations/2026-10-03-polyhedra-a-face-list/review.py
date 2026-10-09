from pathlib import Path
import difflib
import html
import json
import re

import markdown

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
STARTER = ROOT / 'doc/book/studies/ada-xr-starter'
prose = (ROOT / 'commons/maps/Primitives_Polythedra/tutorial.md').read_text(encoding='utf-8')
code = (STARTER / 'studies/point_polyhedra/polyhedra.gd').read_text(encoding='utf-8')
blocks = re.findall(r'```gdscript\n(.*?)```', prose, re.S)
assert len(blocks) == 4
assert all(block.strip() in code for block in blocks[:3])
edited_code = code.replace('    [0, 3, 1],', '    [0, 3, 1],\n    [1, 3, 2],')
assert blocks[3].strip() in edited_code
assert '$' not in code and 'get_node' not in code
report = json.loads((OUT / 'verification.json').read_text(encoding='utf-8'))
assert report['passed'] and all(c['passed'] for c in report['checks'])
before = (OUT / 'before/tutorial.md').read_text(encoding='utf-8')
(OUT / 'tutorial.md').write_text(prose, encoding='utf-8')
(OUT / 'polyhedra.gd').write_text(code, encoding='utf-8')
(OUT / 'polyhedra-closed.gd').write_text(edited_code, encoding='utf-8')
(OUT / 'tutorial.diff').write_text(''.join(difflib.unified_diff(before.splitlines(True), prose.splitlines(True), fromfile='before/tutorial.md', tofile='tutorial.md')), encoding='utf-8')
reading = markdown.markdown(prose.replace('../../../doc/book/studies/ada-xr-starter/README.md', '../../studies/ada-xr-starter/README.md'), extensions=['fenced_code'])
pair = '''<div class="pair"><figure><img src="open.png" alt="Three triangular faces meet at vertex zero behind the open rim. The four corners are numbered."><figcaption>Three faces share point 0. The opposite rim is open; you can look towards the faces behind it.</figcaption></figure><figure><img src="closed.png" alt="The same positions with a fourth face spanning the front rim."><figcaption>Add [1, 3, 2]. The opening closes while every position stays fixed. Number labels remain readable through the surfaces.</figcaption></figure></div>'''
reading = reading.replace('<h2>Keep two boundaries distinct</h2>', pair + '<h2>Keep two boundaries distinct</h2>')
checks = len(report['checks'])
page = f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Polyhedra — which faces make an inside?</title><link rel="stylesheet" href="style.css"></head><body><main>
<header><nav><a href="#reading">Read the lesson</a><a href="#code">Complete code</a><a href="#scope">Lineage and scope</a><a href="#checked">Checks</a><a href="../2026-10-03-triangle-three-corners/index.html#reading">Previous: Triangle</a></nav><p>ADA / TUTORIAL PILOT / 3 OCTOBER 2026</p></header>
<article id="reading">{reading}<p><a class="download" href="../2026-10-03-ada-xr-starter/ada-xr-starter.zip" download>Download the updated starter</a></p><p class="small">Open point_polyhedra.tscn with Run Current Scene. It needs a released Trace record on this device. The shared starter includes every lesson so far.</p></article>
<details id="code"><summary>polyhedra.gd · the complete lesson</summary><div><p>The learner creates all four handles, six segments and the mesh. The face list is ordinary GDScript data. A nested loop reads its indices into the position array; this is not yet a GPU index buffer. Readout and numbered labels are presentation aids. The original saved trace is never written.</p><pre><code>{html.escape(code)}</code></pre><p><a href="polyhedra.gd" download>Open-corner script</a> · <a href="polyhedra-closed.gd" download>Same script with the fourth row</a> · <a href="tutorial.md">Tutorial source</a> · <a href="tutorial.diff">Text diff</a></p></div></details>
<details id="scope"><summary>A new decision, using the previous construction</summary><div><p>Triangle made one face from three positions. This lesson adds one position and a list that says which triples belong to which faces. Moving a position and changing a connection now become independent operations. Cube can reuse this distinction next.</p><p>The earlier three positions come from the same original Trace record used by Grid and Triangle. Temporary edits in Triangle are not saved. The added point follows a declared negative-Z offset; it is not automatically placed perpendicular to the triangle. Four coplanar positions still have zero volume. The script displays the authored faces without claiming to validate every edited shape.</p><p>Collision stays a separate construction. The live museum's open trihedron has a convex hull that closes its visually missing side. That richer encounter remains in the <a href="../../../../commons/maps/Primitives_Polythedra/tutorial-museum.md">museum return</a>, the critical chapter and technical reference. No museum artifact or final.md changed.</p><p>The first lesson needs neither every room artifact nor a generic mesh factory. Normals, GPU indices, volume formulae and collision building are deferred. Coordinates still needs its earlier shared-starter writing pass.</p><p><a href="lesson-contract.json">Teaching contract</a> · <a href="DECISIONS.md">Decisions</a></p></div></details>
<details id="checked"><summary>{checks} native checks passed</summary><div><p>Godot 4.6 checked the actual saved-source selection, exact emitted vertices, open and closed face connectivity, printed one-row code edit, shared-vertex movement, unchanged opposite face, coplanar collapse and recovery, absence of mesh collision, mouse pickup and synthetic XR grip/release, unchanged saved data, restart and empty states.</p><p>All four printed excerpts match either the default script or the tested one-row edit. These images show the native student room, using the same 41-position synthetic XR release record as Trace, Grid and Triangle. Physical headset use and beginner comprehension remain untested.</p><p><a href="verification.json">Results</a> · <a href="verify.gd">Reproducible harness</a> · <a href="coplanar.png">Coplanar comparison</a> · <a href="empty.png">Missing-record state</a></p></div></details>
</main><script>function reveal(){{const el=document.getElementById(location.hash.slice(1));if(el?.tagName==='DETAILS')el.open=true}}addEventListener('hashchange',reveal);reveal();</script></body></html>'''
(OUT / 'index.html').write_text(page, encoding='utf-8')
print(json.dumps({'checks': checks, 'printed_code_excerpts': len(blocks), 'tutorial_words_including_code': len(prose.split())}))
