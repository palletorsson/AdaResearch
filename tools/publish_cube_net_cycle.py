"""Publish the cube's native museum cycle and matching book passage."""
from pathlib import Path
import hashlib
import html
import json
import markdown

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-04-cube-another-one'
HALL = ROOT / 'commons/maps/Point_Animatedcube'
report = json.loads((OUT / 'evidence.json').read_text())
assert report['passed'] and all(c['passed'] for c in report['checks'])
assert (OUT / 'cycle.mp4').stat().st_size > 10000

STYLE = '''
:root{color-scheme:light;--ink:#302c32;--paper:#f2eee6;--rose:#c65b86}
*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:18px/1.6 Georgia,serif}
main{max-width:1160px;margin:auto;padding:46px 30px 80px}a{color:inherit;text-underline-offset:4px}
nav,.kicker,figcaption,.sequence,summary,footer{font:13px/1.65 system-ui,sans-serif}
nav{display:flex;gap:24px;flex-wrap:wrap;border-bottom:1px solid #cfc4c8;padding-bottom:14px}
.kicker{text-transform:uppercase;letter-spacing:.14em;color:#83556b;margin-top:42px}
h1{font-weight:400;font-size:clamp(42px,6vw,78px);line-height:1.06;margin:10px 0 22px}
h2{font-weight:400;font-size:32px;margin-top:46px}.lede{max-width:690px;font-size:23px}
video{display:block;width:100%;background:#292630;aspect-ratio:3/2;max-height:76vh}
figure{margin:30px 0}figcaption{margin:10px 0;color:#665b61}img{width:100%;display:block}
.sequence{letter-spacing:.05em;border-block:1px solid #cfc4c8;padding:18px 0;text-align:center}
.strip{display:grid;grid-template-columns:repeat(3,1fr);gap:18px}.strip figure{margin:0}
article{max-width:690px;margin:48px auto}article p{margin:0 0 22px}details{margin:26px 0}
summary{cursor:pointer}pre{overflow:auto;padding:20px;background:#e7e1db;font-size:13px}
table{border-collapse:collapse;width:100%;font:15px/1.5 system-ui,sans-serif}td,th{border-bottom:1px solid #ccc;padding:10px;text-align:left}
footer{border-top:1px solid #cfc4c8;margin-top:60px;padding-top:20px}
@media(max-width:650px){main{padding:24px 16px}.strip{grid-template-columns:1fr}.lede{font-size:20px}}
'''

def page(title, body):
    return f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{html.escape(title)}</title><style>{STYLE}</style><main><nav>
<a href="index.html#museum">The museum</a><a href="index.html#reading">The passage</a>
<a href="making.html">Museum companion</a><a href="technical.html">How it works</a>
</nav>{body}<footer>Point_Animatedcube · Primitives · 4 October 2026<br>
Native Godot captures from the endless museum. <a href="evidence.json">{len(report['checks'])} checks</a> · <a href="source-hashes.json">Source record</a></footer></main></html>'''

final = (HALL / 'final.md').read_text(encoding='utf-8')
passage = final.split('<!-- @polyhedron_nets_cube -->', 1)[1].split('<!-- @ -->', 1)[0].strip()
body = f'''<p class="kicker">The animated cube / a surface becomes a body</p>
<h1>Another one.</h1>
<p class="lede">The net folds. The cube shrinks and drops. A moment to think — then a fresh net opens above it. Each cycle leaves another cube on the floor.</p>
<figure id="museum"><video controls autoplay muted loop playsinline preload="metadata" poster="folding.png" aria-label="Cube net folding, falling and reopening in the endless museum"><source src="cycle.mp4" type="video/mp4"></video>
<figcaption>A continuous native recording inside Point_Animatedcube. Press play or pause to inspect the fold. The recording retains the measured intervals between captured frames.</figcaption></figure>
<p class="sequence">OPEN → FOLD → SHRINK → DROP → PAUSE → ANOTHER NET</p>
<div class="strip"><figure><img src="open.png" alt="Six flat squares suspended in the Animated Cube hall"><figcaption>01 / Six squares. One face is pink.</figcaption></figure>
<figure><img src="folding.png" alt="The numbered square faces turning at their hinges"><figcaption>02 / Each face stays rigid as the hinges turn.</figcaption></figure>
<figure><img src="collection.png" alt="Two small cubes stay on the floor below the reopened net"><figcaption>03 / Two cycles. Two cubes left behind.</figcaption></figure></div>
<article id="reading"><p class="kicker">In the book</p>{markdown.markdown(passage)}
<h2>Find it in the museum</h2><p>Go to <strong>Primitives → Cube Assembly from Primitives</strong> (Point_Animatedcube), after Primitives Polythedra and before Primitives Ignorance. This upgrades the existing folding net near the end of the main hall, beside the glove chamber and the passage towards the next hall. The prefab box library is in the adjoining gallery.</p>
<details><summary>What changed and what was checked</summary><p>The net keeps its existing grid cell, (4,10). Five off-white faces and one pink face have dark edges and numbers. The 0.7 m cube shrinks to 0.315 m before falling.</p>
<p>The release copies the closed six-face geometry into a separate rigid body. The fallen copy stays while the working net grows and unfolds above it. Each copy has collision and a small sideways release velocity. The floor collection holds up to 24 cubes, retiring the oldest as production continues.</p>
<p>{len(report['checks'])} native checks pass, including two natural cycles, correct shrink size, six-face copies, floor contact, two independent cubes, collection limits, live reconfiguration and all four existing net layouts. A separate <a href="collection-stress.json">26-cycle physics run</a> checks continued production past the 24-body limit. Physical headset behavior remains untested.</p></details></article>'''
(OUT / 'index.html').write_text(page('Another one — the cube net', body), encoding='utf-8')

for source, dest, title in [('tutorial-museum.md','making.html','Follow the cube through the room'), ('technical.md','technical.html','Hinges, gravity and a return')]:
    text = (HALL / source).read_text(encoding='utf-8')
    content = markdown.markdown(text, extensions=['tables','fenced_code','footnotes'])
    (OUT / dest).write_text(page(title, '<article>'+content+'</article>'), encoding='utf-8')

sources = ['commons/infoboards_3d/visualizations/polyhedron_nets.gd',
           'commons/infoboards_3d/visualizations/cube_net_cycle.gd',
           'commons/testing/capture_cube_net_cycle.gd',
           'commons/testing/probe_cube_net_collection.gd',
           'tools/capture_cube_net_cycle.py', 'tools/publish_cube_net_cycle.py']
sources += ['commons/maps/Point_Animatedcube/'+s for s in ['map_data.json','final.md','tutorial.md','tutorial-museum.md','technical.md','artifacts.md','intent.md','critical.md','summary.md','field_notes.md']]
manifest = {p: hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources}
(OUT / 'source-hashes.json').write_text(json.dumps(manifest,indent=2)+'\n', encoding='utf-8')
(OUT / 'STATUS.md').write_text('''# Another one — 2026-10-04

Implemented in the existing Point_Animatedcube net at grid (4,10).
Six faces fold into a cube, shrink to 45 percent, and are copied into a rigid body.
The cube stays on the floor; after 2.2 seconds the working net grows and reopens.
Each cycle leaves another cube. Collection bounded to 24 bodies, oldest retired.
Native checks: 29 passed, two complete cycles. Physical headset untested.
Separate physics fixture: 26 drops settled, 24 bodies retained at the limit.
Main text, museum companion, technical notes and inventory updated. Student lesson retained.

Reproduce:
```
python tools/capture_cube_net_cycle.py
python tools/publish_cube_net_cycle.py
python tools/export_book_captures.py --sequence primitives
```

The private capture project isolates museum control files and saves native frames.
FFmpeg encodes the measured frame intervals. Page contains no JavaScript.
The sibling ada_encyclopedia review route now serves MP4 with byte-range seeking,
using its existing audio range handler. No changes committed in this pass.
''', encoding='utf-8')
print('Published:', OUT / 'index.html')
