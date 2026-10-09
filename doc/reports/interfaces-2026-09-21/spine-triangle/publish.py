from pathlib import Path
import hashlib
import json
import shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
OUT = ROOT / 'doc/book/iterations/2026-09-21-interface-spine-triangle-review'
OUT.mkdir(parents=True, exist_ok=True)
for variant in ['before', 'after']:
    for subject in ['puzzle', 'drawing']:
        for shot in ['reading', 'encounter']:
            shutil.copy2(HERE / variant / subject / (shot + '.png'), OUT / f'{variant}-{subject}-{shot}.png')
        shutil.copy2(HERE / variant / subject / 'report.json', OUT / f'{variant}-{subject}-checks.json')
        shutil.copy2(HERE / variant / subject / 'run.log', OUT / f'{variant}-{subject}-log.txt')
shutil.copy2(ROOT / 'ada_run/triangle_primary/checks.json', OUT / 'triangle-checks.json')
shutil.copy2(HERE / 'after/console-checks.json', OUT / 'console-checks.json')
for source in ['probe_triangle_primary', 'test_triangle_console']:
    shutil.copy2(HERE / 'after' / (source + '.log'), OUT / (source + '-log.txt'))

sources = [
    'commons/ui/triangle_experiment_panel.gd',
    'commons/ui/data_instrument_surface.gd',
    'commons/primitives/line/puzzles/triangle_line_puzzle.gd',
    'commons/primitives/point/draw_triangle_faces.gd',
    'commons/maps/Point_Triangle_Context/map_data.json',
    'commons/testing/probe_triangle_primary.gd',
    'commons/testing/test_triangle_console.gd',
    'commons/testing/probe_spine_triangle_interfaces.gd',
    'commons/scenes/endless_museum.gd',
    'ada_run/em_plan.json', 'ada_run/em_overrides.json', 'ada_run/necklace_hand.json',
]
(OUT / 'sources.json').write_text(json.dumps({p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in sources}, indent=2), encoding='utf-8')


def figure(file, caption):
    return f'<figure><a href="{file}"><img src="{file}" alt="{caption}" loading="lazy"></a><figcaption>{caption}</figcaption></figure>'


style = (ROOT / 'doc/book/iterations/2026-09-21-interface-scalar-review/index.html').read_text(encoding='utf-8').split('<style>')[1].split('</style>')[0]
html = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Triangle, within reach · Ada Research</title><style>''' + style + '''</style></head><body><main>
<div class="eyebrow">Ada Research · Interfaces along the spine · 21 September 2026</div>
<h1>Triangle,<br>within reach.</h1>
<p class="lead">Two primary works in Point_Triangle_Context: close a boundary, then discover what a triangle fan does to an outline. Their consoles now stand lower, with compact physical controls and flat text.</p>
<span class="badge">61 functional checks</span><span class="badge">28 actual-hall checks</span><span class="badge pending">Headset test remains</span>
<h2>Close the boundary before asking for a face</h2>
<p>The puzzle retains its three movable edges. Closing them makes Fill available; it does not create a surface automatically. The physical cap turns green when the fill is visible. An open boundary leaves it dimmed.</p>
<div class="pair">''' + figure('before-puzzle-reading.png', 'Before: the taller puzzle readout and separate button presentation.') + figure('after-puzzle-reading.png', 'After: an inclined, bounded screen with its physical Fill button on a shared backplate.') + '''</div>
''' + figure('after-puzzle-encounter.png', 'Actual museum placement, viewed from a tested approach beside the console. The triangle remains visible beyond the instrument.') + '''
<h2>One outline, different fills</h2>
<p>The drawing station brings NEW OUTLINE, SHIFT START and SHOW / HIDE FILL onto the same plate, with 25 cm between button centres. The screen reports corners, triangles, the starting corner and the drawing tip’s coordinates. Corner numbers are flat labels in space.</p>
<div class="pair">''' + figure('before-drawing-reading.png', 'Before: the drawing console was raised by the museum’s plinth-placement calculation.') + figure('after-drawing-reading.png', 'After: the console stays lower, its three buttons share one mount, and the outline remains visible above it.') + '''</div>
<p>The fan’s limitation remains part of the experiment. With a supplied six-corner L-shaped outline, Shift Start changes the generated fill while leaving the boundary untouched. Some starts produce triangles outside the intended region. Six shifts return to the original fill. Hiding the surface preserves the edges; starting a new outline preserves completed faces.</p>
''' + figure('after-drawing-encounter.png', 'The drawing console and its outline in the authored hall, approached from the side around the nearby column.') + '''
<h2>Mount the interface without lifting the work</h2>
<p>The shared data instrument provides a 76 × 42 cm screen. A separate backplate carries native 3D push buttons beneath it. The console tilts 30 degrees, while its support remains upright. It follows the artifact’s position and orientation, retains full-size controls when the artifact is scaled, and is excluded from the museum’s calculation of the exhibit’s lowest point.</p>
<table><thead><tr><th>Measured in the hall</th><th>Puzzle</th><th>Drawing</th></tr></thead><tbody>
<tr><td>Screen centre above floor</td><td>1.20 m</td><td>1.165 m</td></tr>
<tr><td>Button centre above floor</td><td>0.98 m</td><td>0.945 m</td></tr>
<tr><td>Horizontal button distance from tested operating pose</td><td>0.39 m</td><td>0.39–0.47 m</td></tr>
</tbody></table>
<p>Standing capsules fit at the tested operating positions, and collision rays reach every button. The drawing station has two clear, supported side approaches. A straight approach from directly in front begins inside a nearby column; the images and checks document the usable routes instead.</p>
<h2>Evidence and next pass</h2>
<p>These are Godot renders of the production museum builder using supplied endpoint positions and a reproducible drawing. Functional checks dispatch native pointer events and inspect the actual resulting meshes. They also cover held-pen guards, selected and unavailable states, rotated and scaled owners, stable mounting, and text bounds.</p>
<p><a href="triangle-checks.json">28 triangle checks</a> · <a href="console-checks.json">33 console checks</a> · <a href="after-puzzle-checks.json">10 puzzle hall checks</a> · <a href="after-drawing-checks.json">18 drawing hall checks</a> · <a href="sources.json">Source snapshot hashes</a></p>
<p>Logs: <a href="probe_triangle_primary-log.txt">triangle</a> · <a href="test_triangle_console-log.txt">console</a> · <a href="after-puzzle-log.txt">puzzle hall</a> · <a href="after-drawing-log.txt">drawing hall</a>.</p>
<div class="note">The reading camera follows each console; before and after use different operating distances (70 cm and 55 cm). These are layout and behavior checks. Headset legibility, seated reach, real-hand operation and Quest frame time remain untested. Existing UID and audio warnings remain in the logs. No manuscript, artifact-role or sequence changes were made in this pass.</div>
<p>Next along the spine: Primitives_Polythedra. Check its controls against the forms and passages they are meant to help the visitor examine.</p>
<footer><a href="../2026-09-21-interface-spine-primitives-review/index.html">Previous: Trace and Grid</a> · <a href="/necklace/thread?map=Point_Triangle_Context&amp;role=primary">Triangle artifacts</a> · <a href="/book?map=Point_Triangle_Context&amp;section=final">Triangle book text</a></footer>
</main></body></html>'''
(OUT / 'index.html').write_text(html, encoding='utf-8')
print(OUT)
