from pathlib import Path
import difflib
import html
import json
import re

import markdown

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
STARTER = ROOT / 'doc/book/studies/ada-xr-starter'
prose = (ROOT / 'commons/maps/Point_Animatedcube/tutorial.md').read_text(encoding='utf-8')
code = (STARTER / 'studies/point_cube/cube.gd').read_text(encoding='utf-8')
blocks = re.findall(r'```gdscript\n(.*?)```', prose, re.S)
assert len(blocks) == 5 and all(block.strip() in code for block in blocks[:4])
shifted = code.replace('var corner_shift := 0.0', 'var corner_shift := 0.35')
alternate = shifted.replace('[4, 5, 7], [5, 6, 7]', '[4, 5, 6], [4, 6, 7]').replace('var diagonal_pair := [5, 7]', 'var diagonal_pair := [4, 6]')
assert blocks[4].strip() in alternate
assert '$' not in code and 'get_node' not in code
assert 'TraceMemory' not in code and 'BoxMesh' not in code
report = json.loads((OUT / 'verification.json').read_text(encoding='utf-8'))
assert report['passed'] and all(c['passed'] for c in report['checks'])
before = (OUT / 'before/tutorial.md').read_text(encoding='utf-8')
(OUT / 'tutorial.md').write_text(prose, encoding='utf-8')
(OUT / 'cube.gd').write_text(code, encoding='utf-8')
(OUT / 'cube-shifted.gd').write_text(shifted, encoding='utf-8')
(OUT / 'cube-other-diagonal.gd').write_text(alternate, encoding='utf-8')
(OUT / 'tutorial.diff').write_text(''.join(difflib.unified_diff(before.splitlines(True), prose.splitlines(True), fromfile='before/tutorial.md', tofile='tutorial.md')), encoding='utf-8')
reading = markdown.markdown(prose.replace('../../../doc/book/studies/ada-xr-starter/README.md', '../../studies/ada-xr-starter/README.md'), extensions=['fenced_code'])
pair = '''<div class="pair"><figure><img src="cube.png" alt="Regular cube, with white and pink front triangles sharing an amber diagonal from 5 to 7."><figcaption>Two coplanar triangles cover one square. The guide names the shared edge.</figcaption></figure><figure><img src="creased.png" alt="The same cube with corner 6 moved forward. The pink patch tilts while the white front patch stays fixed."><figcaption>Corner 6 moves 0.35 metres. The white front triangle keeps all three of its original positions.</figcaption></figure></div>'''
reading = reading.replace('<h2>3. Choose the other diagonal</h2>', pair + '<h2>3. Choose the other diagonal</h2>')
second_pair = '''<div class="pair"><figure><img src="creased.png" alt="Deformed front face split along the 5 to 7 diagonal."><figcaption>Connection 5–7. One front triangle retains the original plane.</figcaption></figure><figure><img src="other-diagonal.png" alt="Identical corner positions split along the alternative 4 to 6 diagonal."><figcaption>Connection 4–6. The same four positions now define two tilted patches.</figcaption></figure></div>'''
reading = reading.replace('<h2>What remains a cube?</h2>', second_pair + '<h2>What remains a cube?</h2>')
checks = len(report['checks'])
page = f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Cube — the diagonal was already there</title><link rel="stylesheet" href="style.css"></head><body><main>
<header><nav><a href="#reading">Read the lesson</a><a href="#code">Complete code</a><a href="#scope">Lineage and scope</a><a href="#checked">Checks</a><a href="../2026-10-03-polyhedra-a-face-list/index.html#reading">Previous: Polyhedra</a></nav><p>ADA / TUTORIAL PILOT / 3 OCTOBER 2026</p></header>
<article id="reading">{reading}<p><a class="download" href="../2026-10-03-ada-xr-starter/ada-xr-starter.zip" download>Download the updated starter</a></p><p class="small">Open point_cube.tscn with Run Current Scene. All lesson geometry is constructed in code. This study starts from the authored eight-position cube; no saved gesture is required.</p></article>
<details id="code"><summary>cube.gd · the complete lesson</summary><div><p>The position and connection lists continue the preceding lesson. Each triangle gets its own ImmediateMesh surface so the second front patch can use a distinct supplied material. The position-copy and nested face-submission loops remain inspectable. Labels and the diagonal are display aids.</p><pre><code>{html.escape(code)}</code></pre><p><a href="cube.gd" download>Regular cube script</a> · <a href="cube-shifted.gd" download>Corner 6 shifted</a> · <a href="cube-other-diagonal.gd" download>Same shift, other diagonal</a> · <a href="tutorial.md">Tutorial source</a> · <a href="tutorial.diff">Text diff</a></p></div></details>
<details id="scope"><summary>From a face list to an exposed decision</summary><div><p>Polyhedra established positions and connections as separate data. Cube needs no new mesh factory: eight explicit positions, twelve boundary edges and twelve triangle rows reuse that construction. The new encounter is the diagonal concealed in a familiar square face.</p><p>Trace remains the source for the earlier gesture studies. Here we deliberately choose the arrangement of a regular cube and reuse the code, without claiming the cube was recovered from that gesture. Temporary handle edits are not saved.</p><p>The museum's assembly timing, replay, folding net and prefab collection remain in the <a href="../../../../commons/maps/Point_Animatedcube/tutorial-museum.md">museum return</a>. The critical chapter and live room are unchanged. A later lesson can generate position data by a short rule; the existing general GPU index and normal topics remain deferred.</p><p>Coordinates retains its earlier place and still needs its shared-starter writing pass. <a href="lesson-contract.json">Teaching contract</a> · <a href="DECISIONS.md">Decisions</a></p></div></details>
<details id="checked"><summary>{checks} native checks passed</summary><div><p>Checked in a freshly extracted Godot 4.6 starter: unit cube edges, closed triangle connectivity, initial shared plane, fixed and moving front patches, alternate diagonal with unchanged coordinates, printed script edits on a bare Node3D, repeatable startup shift, independent visibility controls, no surface collision, desktop mouse and synthetic XR pickup/movement/release, restoration and bounded drawing nodes.</p><p>Five printed excerpts match the default or tested edited script. Images are native student-room renders from a fixed elevated desktop camera. Physical headset use and beginner comprehension remain untested.</p><p><a href="verification.json">Results</a> · <a href="verify.gd">Reproducible harness</a> · <a href="wire.png">Wire comparison</a></p></div></details>
</main><script>function reveal(){{const el=document.getElementById(location.hash.slice(1));if(el?.tagName==='DETAILS')el.open=true}}addEventListener('hashchange',reveal);reveal();</script></body></html>'''
(OUT / 'index.html').write_text(page, encoding='utf-8')
print(json.dumps({'checks': checks, 'printed_code_excerpts': len(blocks), 'tutorial_words_including_code': len(prose.split())}))
