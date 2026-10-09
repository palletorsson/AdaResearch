from pathlib import Path
import hashlib, json, shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
OUT = ROOT / 'doc/book/iterations/2026-09-21-interface-spine-polyhedra-review'
OUT.mkdir(parents=True, exist_ok=True)
for case in ['pyramid', 'trihedron', 'tetrahedron']:
    for shot in ['reading', 'encounter']:
        shutil.copy2(HERE/'after'/case/(shot+'.png'), OUT/f'after-{case}-{shot}.png')
    shutil.copy2(HERE/'after'/case/'report.json', OUT/f'{case}-checks.json')
    shutil.copy2(HERE/'after'/case/'run.log', OUT/f'{case}-log.txt')
shutil.copy2(HERE/'after/pyramid/controls.png', OUT/'after-pyramid-controls.png')
shutil.copy2(HERE/'before/pyramid/encounter.png', OUT/'before-pyramid-encounter.png')
shutil.copy2(HERE/'after/functional-checks.json', OUT/'functional-checks.json')
shutil.copy2(HERE/'after/test_pyramid_workbench.log', OUT/'functional-log.txt')
sources = ['commons/primitives/pyramid/pyramid_edit.gd', 'commons/ui/vertex_recovery_panel.gd',
           'commons/ui/instrument_panel_case.gd', 'commons/primitives/trihedron/grab_trihedron.gd',
           'commons/primitives/tetrahedron/grab_tetrahedron.gd', 'commons/maps/Primitives_Polythedra/map_data.json',
           'commons/testing/probe_polyhedra_interfaces.gd', 'commons/testing/test_pyramid_workbench.gd',
           'commons/scenes/endless_museum.gd', 'ada_run/em_plan.json', 'ada_run/em_overrides.json', 'ada_run/necklace_hand.json']
(OUT/'sources.json').write_text(json.dumps({p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources},indent=2),encoding='utf-8')
style = (ROOT/'doc/book/iterations/2026-09-21-interface-scalar-review/index.html').read_text(encoding='utf-8').split('<style>')[1].split('</style>')[0]
def figure(file, caption):
    return f'<figure><a href="{file}"><img src="{file}" alt="{caption}" loading="lazy"></a><figcaption>{caption}</figcaption></figure>'
html = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Reach the corner · Ada Research</title><style>'''+style+'''</style></head><body><main>
<div class="eyebrow">Ada Research · Interfaces along the spine · 21 September 2026</div>
<h1>Reach the corner.</h1>
<p class="lead">In Primitives_Polythedra, the held form is already an interface. Turn an open corner, compare a closed solid, or pull one of the pyramid’s five vertices. This pass makes those encounters easier to approach and the editable form easier to recover.</p>
<span class="badge">46 functional checks</span><span class="badge">42 actual-hall checks</span><span class="badge pending">Headset test remains</span>
<h2>A shape you can reach</h2>
<p>The pyramid’s apex started about 2.10 m above the floor. Its apparent front faced the crowded side of the hall. It now faces the open aisle on a 65 cm micropod support, with the base grips at 71 cm and the apex at 1.51 m. The smaller support lets the visitor stand closer.</p>
<div class="pair">'''+figure('before-pyramid-encounter.png','Before: high plinth, tiny grips and a crowded approach. This diagnostic camera position was not a usable standing position.')+figure('after-pyramid-encounter.png','After: lower support, visible cyan corner grips, an amber apex, and a small reset station beside the form.')+'''</div>
<p>The visible grip radius grows from 1.2 to 2.8 cm inside the existing grab collider. All five handles still directly move vertices. The front corners and apex can be reached from the front; the two far corners have clear standing positions at the sides.</p>
<table><thead><tr><th>Target</th><th>Height above floor</th><th>Horizontal reach from its tested pose</th></tr></thead><tbody>
<tr><td>Four base grips</td><td>0.71 m</td><td>0.46 m, using front or side poses</td></tr>
<tr><td>Apex</td><td>1.51 m</td><td>0.65 m</td></tr>
<tr><td>Reset button</td><td>0.93 m</td><td>0.59 m</td></tr>
</tbody></table>
<h2>Let go, then try again</h2>
<p>A physical RESET SHAPE button sits on a cased backplate. Its lettering is flat text on planes, with no live viewport. The station stands beside the front corner, leaving the pyramid itself as the main control.</p>
'''+figure('after-pyramid-controls.png','Actual close view from the operating position: physical reset cap, flat captions, and an upright support beneath the inclined case.')+'''
<p>Reset restores the authored vertices after a deformation. While any handle is held, the cap dims and the caption asks the visitor to let go first. A reset press cannot pull a vertex out of the hand. The existing free, symmetric, apex-only and base-only rules remain available through configuration; reset preserves the active rule.</p>
<h2>Face the aisle</h2>
<p>The trihedron and tetrahedron also turn toward the aisle. Their authored geometry and native grab interaction remain intact. Each now has a clear supported approach, a valid standing position and an unobstructed grab ray. No additional console was added to either held solid.</p>
<div class="pair">'''+figure('after-trihedron-encounter.png','The open trihedral corner, approached from the aisle. Pick it up and turn it to inspect the missing side.')+figure('after-tetrahedron-encounter.png','The closed tetrahedron in the same hall. Its interface is the held object.')+'''</div>
<h2>A principle to carry forward</h2>
<p>Use the form itself when the action is spatial. Make its grips visible, give the body a place to stand, and provide recovery when an experiment can wander far from its starting state. A separate control earns its place by supporting that action.</p>
<p>The small recovery panel uses the existing casing, baked text and native push button. Other vertex-based artifacts can supply the same held-state and reset methods. The pyramid opts into it with <code>workbench:1</code>; other placements retain their existing presentation. The map and museum plan agree on all three orientations and the new pyramid support. The manuscript and curatorial roles were not changed.</p>
<h2>Evidence and remaining scope</h2>
<p><a href="functional-checks.json">46 functional checks</a> · <a href="pyramid-checks.json">28 pyramid hall checks</a> · <a href="trihedron-checks.json">7 trihedron checks</a> · <a href="tetrahedron-checks.json">7 tetrahedron checks</a> · <a href="sources.json">Source hashes</a></p>
<p>Logs: <a href="functional-log.txt">native input and constraints</a> · <a href="pyramid-log.txt">pyramid hall</a> · <a href="trihedron-log.txt">trihedron hall</a> · <a href="tetrahedron-log.txt">tetrahedron hall</a>.</p>
<div class="note">The renders use the production museum builder. Cameras follow the changed orientation; the before and after images are not the same viewpoint. Reach checks use supplied standing positions and a capsule. Native grab and pointer tests exercise the actual pyramid mesh, reset guard and constraint rules. Headset comfort, seated access and Quest performance remain untested. Existing UID and viewport-texture errors also occur in the baseline logs.</div>
<p>This is a pass on three direct-manipulation interfaces. The rock scanner’s unfinished cross-section display, the trihedron’s unassigned alternate material, and the rest of the hall’s supporting artifacts remain separate review items.</p>
<p>Next along the spine: Point_Animatedcube—follow the faces as they assemble.</p>
<footer><a href="../2026-09-21-interface-spine-triangle-review/index.html">Previous: Triangle</a> · <a href="/necklace/thread?map=Primitives_Polythedra&amp;role=primary">Polyhedra artifacts</a> · <a href="/book?map=Primitives_Polythedra&amp;section=final">Book text</a></footer>
</main></body></html>'''
(OUT/'index.html').write_text(html,encoding='utf-8')
print(OUT)
