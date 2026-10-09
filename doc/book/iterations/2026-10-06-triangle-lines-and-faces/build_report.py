"""Bundle native museum views with their interaction checks."""
from pathlib import Path
import hashlib
import html
import json
import shutil

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
RUN = ROOT / 'ada_run/encounter_pilot/Point_Triangle_Context_line_faces_after'
BEFORE = ROOT / 'ada_run/encounter_pilot/Point_Triangle_Context_line_faces_before'
SHOTS = ['puzzle', 'puzzle-closed', 'two-scales', 'maker', 'large-face', 'corner-moved', 'added-face']
for name in SHOTS:
    shutil.copy2(RUN / f'{name}.png', OUT / f'{name}.png')
for name in ['puzzle', 'maker']:
    shutil.copy2(BEFORE / f'{name}.png', OUT / f'before-{name}.png')
shutil.copy2(RUN / 'report.json', OUT / 'report.json')
report = json.loads((OUT / 'report.json').read_text())
assert report['passed'] and not report['failures'], report['failures']
manifest = json.loads((RUN / 'source_manifest.json').read_text())
sources = [
    'commons/primitives/line/museum_line_style.gd',
    'commons/primitives/line/puzzles/triangle_line_puzzle.gd',
    'commons/primitives/line/snap_line_segment.gd',
    'commons/primitives/point/draw_triangle_faces.gd',
    'commons/ui/triangle_workbench.gd',
    'commons/artifacts/triangle_live_twin/triangle_live_twin.gd',
]
for name in sources:
    manifest['sources'][name] = hashlib.sha256((ROOT / name).read_bytes()).hexdigest()
(OUT / 'source_manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')

before = json.loads((OUT / 'before/map_data.json.txt').read_text(encoding='utf-8-sig'))
after = json.loads((ROOT / 'commons/maps/Point_Triangle_Context/map_data.json').read_text(encoding='utf-8-sig'))
changes = []
def compare(a, b, path=''):
    if type(a) is type(b) and isinstance(a, dict) and a.keys() == b.keys():
        for key in a: compare(a[key], b[key], f'{path}/{key}')
    elif type(a) is type(b) and isinstance(a, list) and len(a) == len(b):
        for i, (x, y) in enumerate(zip(a, b)): compare(x, y, f'{path}/{i}')
    elif a != b:
        changes.append({'path': path, 'before': a, 'after': b})
compare(before, after)
(OUT / 'placement-changes.json').write_text(json.dumps(changes, indent=2), encoding='utf-8')

def picture(name, caption):
    safe = html.escape(caption)
    return f'<figure><a href="{name}.png"><img src="{name}.png" alt="{safe}" loading="lazy"></a><figcaption>{safe}</figcaption></figure>'

page = '''<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Point Triangle · Edges become a face</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#f4f0e8;color:#28242b;font:17px/1.6 system-ui,sans-serif}
main{max-width:1320px;margin:auto;padding:45px 28px 80px}h1{font:clamp(38px,5vw,70px)/1.06 Georgia,serif;margin:.25em 0}h2{font:30px Georgia,serif;margin:2em 0 .6em}
.eyebrow{font-size:12px;letter-spacing:.18em;text-transform:uppercase;color:#75666c}.intro{max-width:870px;font-size:20px}a{color:#844968}nav{display:flex;gap:24px;margin:25px 0;flex-wrap:wrap}figure{margin:0 0 24px}img{display:block;width:100%;border-radius:3px}figcaption{font-size:14px;margin:8px 0 0;color:#5b5055}.grid{display:grid;grid-template-columns:1fr 1fr;gap:24px}.note{padding:20px 24px;background:#e9e1d7;border-left:4px solid #d584a9;margin:25px 0}.note p{margin:.4em 0}details{margin-top:24px}summary{cursor:pointer;font-weight:600}footer{margin-top:44px;font-size:14px;color:#655b5e}li{margin:.5em 0}@media(max-width:740px){.grid{grid-template-columns:1fr}main{padding:24px 16px}}
</style><main>
<div class="eyebrow">Endless Museum · Point Triangle · 6 October 2026</div>
<h1>Edges become a face.</h1>
<p class="intro">The pink line and white point continue into Triangle. Join three incomplete edges, move a corner of the small boundary, and watch the enlarged face follow. The same small instrument can add more faces.</p>
<nav><a href="#puzzle">Join the ends</a><a href="#twin">Two scales</a><a href="#drawing">Add a face</a><a href="#before">Before / after</a><a href="#checks">Checks</a></nav>
'''
page += picture('two-scales', 'Inside the actual museum: the small editable boundary and its larger filled twin, with matching pink edges and white corners.')
page += '<h2 id="puzzle">Three lines, almost meeting.</h2><p>The first puzzle has three segments already aligned with the triangle. Each stops short of its corners. Pick up a white endpoint, bring it to a white target ring, and release to snap. When all six ends meet, three shared corners remain. SHOW / HIDE FACE makes filling a separate choice.</p><div class="grid">'
page += picture('puzzle', 'Open: three short edges and three corner targets on an off-white plinth.')
page += picture('puzzle-closed', 'Closed, with the face switched on. RESET EDGES restores the gaps.')
page += '</div><h2 id="twin">One drawing, two scales.</h2><p>The small triangle begins 80 cm wide. Its face is visible in the larger twin, enlarged 3.3 times. Hold and move a small corner: both figures change while it is in your hand. Release to settle onto the drawing’s 5 cm grid. The surrounding floor remains open on both sides.</p>'
page += picture('corner-moved', 'The top corner has moved sideways and out of the original plane. The enlarged face follows the same stored positions.')
page += '<h2 id="drawing">A smaller drawing instrument.</h2><p>The white drawing point rests beside the small triangle. Its centre is the drawing position. The panel sits below the work, with explicit actions instead of timed placement.</p>'
page += picture('maker', 'PLACE POINT · CLOSE FACE · NEW FACE, followed by UNDO POINT · SHOW / HIDE FILL · SHIFT START · RESTORE.')
page += '<ol><li>Press <strong>NEW FACE</strong> and hold the drawing point.</li><li>Move to a corner and press the controller trigger, or use <strong>PLACE POINT</strong>. Near an existing corner, the new face shares that point.</li><li>After three corners, press <strong>CLOSE FACE</strong>. The enlarged surface appears immediately.</li><li>Use <strong>UNDO POINT</strong> for an unfinished corner. <strong>RESTORE</strong> returns the reference triangle and docks the released drawing point.</li></ol>'
page += picture('added-face', 'A second face added through the real pickup and trigger actions. It reuses two corners, so the two faces share an edge.')
page += '<p>Moving a shared corner changes every attached face. SHIFT START retains the existing fan construction: for a loop with four or more corners, it changes the fan’s starting corner and internal diagonals.</p>'
page += '<h2 id="before">Before / after.</h2><div class="grid">'
page += picture('before-puzzle', 'Before: the small puzzle was partly obstructed by the entrance structure.')
page += picture('puzzle', 'After: clearer placement, larger edge study, matching line materials and a low control panel.')
page += picture('before-maker', 'Before: the larger drawing controls occupied more of the view.')
page += picture('maker', 'After: a smaller starting triangle, compact controls and a docked drawing point. Camera framing was adjusted to show the whole panel.')
page += '</div><h2 id="checks">Tested in the museum.</h2><div class="note">'
page += f'<p><strong>{len(report["checks"])} native Godot checks passed.</strong> XRTools pickup/release and trigger actions were exercised with a supplied hand node. Checks cover snapping, reversed endpoint order, reset, live corner movement, shared vertices, face creation, duplicate prevention, undo, fill, fan order and walking clearance beside the plinths.</p>'
page += '<p>These are screenshots from the running Godot museum. Headset comfort and Quest performance still need a VR visit.</p></div>'
page += '<details><summary>Evidence and implementation</summary><p><a href="report.json">Check results</a> · <a href="source_manifest.json">Source hashes</a> · <a href="placement-changes.json">Placement changes</a> · <a href="probe.gd">Interaction probe</a> · <a href="run.py">Isolated museum runner</a></p><p>The drawing changes opt in through <code>#style:line</code>. Other drawing stations keep their existing timed/drop controls. A carried visitor trace remains available; an empty station starts with the reference triangle. Existing unrelated audio-name, material and resource-UID warnings remain in the museum run.</p></details>'
page += '<footer>Applied to Point_Triangle_Context. The small drawing and the large face share the existing triangle creator’s vertices and fan; no second independent drawing is introduced. Tutorial and reflective text are unchanged by this pass.</footer></main></html>'
(OUT / 'index.html').write_text(page, encoding='utf-8')
print(f'{len(report["checks"])} checks; {len(SHOTS)+2} museum images; {len(changes)} placement changes. {OUT / "index.html"}')
