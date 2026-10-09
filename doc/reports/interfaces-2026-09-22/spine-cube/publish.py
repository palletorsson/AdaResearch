from pathlib import Path
import hashlib
import html
import json
import shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
OUT = ROOT / 'doc/book/iterations/2026-09-22-interface-spine-cube-review'
OUT.mkdir(parents=True, exist_ok=True)
hall = json.loads((HERE/'after/cube/report.json').read_text(encoding='utf-8'))
functional = json.loads((HERE/'after/functional-checks.json').read_text(encoding='utf-8'))
assert hall['passed'] and not functional['failures']
for variant in ['before', 'after']:
    for shot in ['builder-0-encounter', 'builder-0-controls', 'builder-1-encounter']:
        shutil.copy2(HERE/variant/'cube'/f'{shot}.png', OUT/f'{variant}-{shot}.png')
    for source, name in [('report.json','checks.json'),('run.log','log.txt'),('sources.json','sources.json')]:
        shutil.copy2(HERE/variant/'cube'/source, OUT/f'{variant}-{name}')
shutil.copy2(HERE/'after/cube/builder-0-held.png', OUT/'after-held.png')
shutil.copy2(HERE/'after/functional-checks.json', OUT/'functional-checks.json')
shutil.copy2(HERE/'after/functional.log', OUT/'functional-log.txt')
paths = ['commons/primitives/animatedcubebuilder/animatedcubebuilder.gd',
         'commons/ui/cube_experiment_panel.gd', 'commons/ui/data_instrument_surface.gd',
         'commons/testing/probe_cube_interfaces.gd', 'commons/testing/probe_cube_primary.gd',
         'commons/maps/Point_Animatedcube/map_data.json', 'commons/maps/Point_Animatedcube/final.md',
         'ada_run/em_plan.json']
(OUT/'sources.json').write_text(json.dumps({p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in paths}, indent=2), encoding='utf-8')
style = (ROOT/'doc/book/iterations/2026-09-21-interface-scalar-review/index.html').read_text(encoding='utf-8').split('<style>')[1].split('</style>')[0]

def figure(name, caption):
    return f'<figure><a href="{name}"><img src="{name}" alt="{html.escape(caption)}" loading="lazy"></a><figcaption>{html.escape(caption)}</figcaption></figure>'

button_height = hall['controls'][0]['height']
reach_min = min(c['horizontal_distance'] for c in hall['controls'])
reach_max = max(c['horizontal_distance'] for c in hall['controls'])
grip_min = min(c['height'] for c in hall['grab_poses'])
grip_max = max(c['height'] for c in hall['grab_poses'])
page = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A cube within reach · Ada Research</title><style>'''+style+'''</style></head><body><main>
<div class="eyebrow">Ada Research · Interfaces along the spine · 22 September 2026</div>
<h1>A cube within reach.</h1>
<p class="lead">Replay the assembly. Pause when you recognise the cube. Move one corner and keep the other builder unchanged. The interface supports this comparison, while the form itself remains something to touch.</p>
'''+f'<span class="badge">{len(hall["checks"])} actual-hall checks</span><span class="badge">{functional["checks"]} experiment checks</span>'+'''
<span class="badge pending">Headset test remains</span>
<h2>In front of the work</h2>
<p>Each builder now has a supported, inclined console in front of it. The readout shrinks from 110 × 96 cm to 76 × 32 cm. Four physical buttons sit 19 cm apart on one backplate. Their captions are flat textures; the readout is a 2D screen in the room.</p>
<div class="pair">'''+figure('before-builder-0-encounter.png','Before: a large floating side panel, with the upper buttons 1.44 m above the floor.')+figure('after-builder-0-encounter.png','After: a lower cube, visible corner grips, and a compact console on its own support.')+'''
</div><p>The console height is independent of the specimen height. The case is excluded from automatic specimen seating, so changing the interface cannot raise the cube. Its readout remains below the intact cube from the tested operating eye position.</p>
'''+figure('after-builder-0-controls.png','Standing view of the four physical controls: replay, pause/resume, restore cube, and diagonals.')+'''
<h2>The corner must be reachable too</h2>
<p>The original upper corners were just over 2 m high. Both builders now stand on 55 cm plinths and retain their one-metre geometry. The visible grips grow from 1.2 to 2.8 cm radius inside the existing grab colliders. The room still contains both builders and its supporting works.</p>
<table><thead><tr><th>Target</th><th>Measured height / distance</th></tr></thead><tbody>
'''+f'<tr><td>Button centres above the floor</td><td>{button_height:.2f} m</td></tr><tr><td>Buttons from the operating pose, horizontally</td><td>{reach_min:.2f}–{reach_max:.2f} m</td></tr><tr><td>Corner centres above the floor</td><td>{grip_min:.2f}–{grip_max:.2f} m</td></tr>'+'''
<tr><td>Each corner from its tested near-grab pose</td><td>Within 0.70 m horizontally, with floor support and a clear ray</td></tr>
</tbody></table>
<p>The console pose and the corner-grab poses are different. Walk around the object to reach its far corners; this is not a claim that eight corners can be reached from one place.</p>
<h2>Let go, then replay</h2>
<p>Replay keeps the changed vertex positions. Restore returns the original cube. While a corner is held, replay and restore dim and the readout asks for release; the existing owner guards prevent either action from taking the corner out of the hand. Pause becomes a lit RESUME control. The diagonal control becomes available after assembly and lights when the six face diagonals are shown.</p>
'''+figure('after-held.png','Native grab test: v6 moves, the triangle connectivity stays fixed, and the readout asks for release before replay or restore.')+'''
<p>The readout counts the visible points, edges and triangle patches. Its displacement number is measured from the original vertices in local metres. Text changes request a screen redraw; an unchanged readout does not redraw continuously.</p>
<h2>Keep the comparison</h2>
'''+figure('after-builder-1-encounter.png','The second builder has the same console. Both remain in the hall so one can serve as an unchanged comparison.')+'''
<p>The book keeps its argument: coordinates may move while connections persist. Only its reference to a side instrument changes to a front instrument. The artifact selection and primary roles remain intact.</p>
<h2>A pattern for the next halls</h2>
<p>Give the specimen and its controls their own working heights. Place a compact control strip in front, keep the sightline open, show which actions are available, and preserve a way back after an experiment. This console reuses the shared cased data surface, baked lettering and native push buttons already used by the earlier interface passes.</p>
<h2>Evidence and remaining scope</h2>
<p><a href="after-checks.json">Actual-hall measurements and interaction checks</a> · <a href="functional-checks.json">Assembly, geometry and comparison regression</a> · <a href="before-checks.json">Baseline measurements</a> · <a href="sources.json">Current source hashes</a></p>
<p><a href="after-log.txt">Hall log</a> · <a href="functional-log.txt">Experiment log</a> · <a href="before-log.txt">Baseline log</a></p>
<div class="note">These are actual Godot museum renders and desktop tests. A standing capsule and the museum walker reach each console; supplied near-grab poses fit around each cube. Native XRTools grab and pointer callbacks exercise the controls and mesh updates. Overview cameras follow the specimen height, so the before/after overview is not the same eye position. The controls view uses a 1.65 m eye. Headset comfort, seated reach, controller tracking and Quest performance still need an in-headset pass. The project still reports an existing unrecognised UID at startup.</div>
<p>Next along the spine: <strong>Primitives_Ignorance</strong> — what the polygon can and cannot hold.</p>
<footer><a href="../2026-09-21-interface-spine-polyhedra-review/index.html">Previous: Polyhedra</a> · <a href="/necklace/thread?map=Point_Animatedcube&amp;role=primary">Cube artifacts</a> · <a href="/book?map=Point_Animatedcube&amp;section=final">Book text</a></footer>
</main></body></html>'''
(OUT/'index.html').write_text(page, encoding='utf-8')
print(OUT)
