"""Publish P1 with actual native captures, extracted code and failed mutations."""
from pathlib import Path
import json,re,shutil,hashlib,html,zipfile,difflib,ast
import markdown
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-09-the-same-throw-different-steps'
A=R/'algorithms/forces/euler_drift';M=R/'commons/maps/VFM_05_Launch';run=R/'ada_run/encounter_pilot/VFM_05_Launch'
core=json.loads((O/'checks.json').read_text());native=json.loads((run/'report.json').read_text());printed=json.loads((O/'printed-validation.json').read_text())
assert core['passed'] and native['passed'] and printed['runs'][0]['exit']==0
assert not any(s in (run/'engine.log').read_text(encoding='utf-8') for s in ['SCRIPT ERROR','Parse Error'])
sources=[A/'step_model.gd',R/'doc/book/studies/forces-point-lineage/point_body.gd',A/'display_point.gd',A/'step_study.gd',A/'step_study.tscn']
for p in sources:assert hashlib.sha256(p.read_bytes()).hexdigest()==printed['source_hashes'][p.relative_to(R).as_posix()],p
for name in ['code','museum']:(O/name).mkdir(exist_ok=True)
for p in sources+[A/'euler_drift.gd',A/'euler_drift.tscn']:shutil.copy2(p,O/'code'/p.name)
for p in run.iterdir():
 if p.suffix=='.png' or p.name in ['report.json','engine.log','source_manifest.json']:shutil.copy2(p,O/'museum'/p.name)
for name in ['tutorial.md','final.md']:shutil.copy2(M/name,O/('hall-'+name))
shutil.copy2(A/'tutorial.md',O/'tutorial.md')
reflection=(M/'final.md').read_text(encoding='utf-8').split('## A difference between steps')[-1]
(O/'reflection.md').write_text('# A difference between steps\n'+reflection,encoding='utf-8')
old=json.loads((O/'before/map_data.json').read_bytes());new=json.loads((M/'map_data.json').read_bytes())
assert old['layers']['structure']==new['layers']['structure'] and old['layers']['utilities']==new['layers']['utilities']
tokens=0;changed=[]
for z,row in enumerate(old['layers']['interactables']):
 for x,c in enumerate(row):
  if c.strip():assert new['layers']['interactables'][z][x]==c;tokens+=1
  if c!=new['layers']['interactables'][z][x]:changed.append([x,z])
assert changed==[[29,6]]
diff=[]
for name in ['map_data.json','tutorial.md','final.md','euler_drift.gd']:
 left=(O/'before'/name).read_text(encoding='utf-8');right=((A if name.endswith('.gd') else M)/name).read_text(encoding='utf-8')
 diff.extend(difflib.unified_diff(left.splitlines(True),right.splitlines(True),fromfile='before/'+name,tofile='after/'+name))
(O/'changes.diff').write_text(''.join(diff),encoding='utf-8')
(O/'measurements.json').write_text(json.dumps(core['observations'],indent=2),encoding='utf-8')
report=f'''# P1 — The same throw, different steps

Installed in **VFM_05_Launch**, cell (29,6), rotated 180° toward entry. The existing registered `euler_drift` gains an opt-in `lesson:step_study` mode; no duplicate registry entry. All {tokens} previous placement tokens, wall cells and utilities remain. Only this map's generated plan row was rederived. The original launch chamber remains the primary encounter.

## What changes

Both calculated spheres use the earlier PointBody class. One uses the analytic constant-acceleration formula; the other uses explicit Euler, position first and velocity second. The hand slider selects 10, 20 or 40 updates over exactly one simulated second. Five nearby buttons fire/pause, advance one step, replay, choose another throw and reset. Both paths occupy one display plane; their visible displacement preserves the calculated difference vector. The spheres coincide at the start and partly overlap when the error is small. The reference is drawn with 80 line segments independently of the solver count.

Start (-2, 0.75, 0) m; initial velocity (4, 4.9, 0) m/s; gravity (0, -9.8, 0) m/s². The analytic endpoint is (2, 0.75, 0) m. The older launch lesson uses a different gravity and stopping rule; the optional tutorial explicitly introduces this fixture's changed conditions.

| Euler steps | Interval (s) | Signed y difference after 1 s (m) |
|---|---|---|
| 10 | 0.100 | +0.4900 |
| 20 | 0.050 | +0.2450 |
| 40 | 0.025 | +0.1225 |

Difference means Euler minus reference. Reversing the update order reverses the error vector in this fixture: magnitude alone cannot detect that change. This is a discrete calculation on a constant-acceleration model, not a Jolt collision or tunnelling experiment. Global physics settings, player movement and the existing catapults remain unchanged.

## Evidence

- **{len(core['checks'])} native core/scene checks pass**, including the three exact fixtures, signed difference, shared elapsed time, alternate acceleration/launch, changed render cadence, bounded history, preserved snapshots, controls, rendered-frame position retention and legacy-mode selection.
- **{printed['runs'][0]['checks']} checks pass on five files freshly extracted from the printed tutorial.** Only internal resource paths are relocated. The two additional original-source checks test legacy/opt-in selection and do not apply to the isolated learner scene. This is executable reconstruction, not a blind learner review.
- **Two deliberately faulty programs are detected:** velocity-first integration and returning the original history array instead of a copy. Their code and failed assertions remain in the package.
- **{len(native['checks'])} native museum checks pass**, including five actual desktop pointer buttons, a pickup/movement/release through the supplied XRTools slider, endpoint retention after rendering, and {native['observations']['route_samples']} supported capsule-route samples from entry to controls. This count includes capture-camera assertions.
- At most 40 solver updates and 41 saved states per run. The trail only rebuilds on a changed tick. This is a bound, not a Quest performance benchmark.

The first parse found a method name colliding with RefCounted.reference; it is now reference_at. One early test process then passed its assertions but crashed during shutdown. The scene harness now waits after constructing the opt-in scene and completes cleanup inside its own function; subsequent accepted processes exit cleanly. The engine-level crash cause is not established; both failed logs are retained.

The first image exposed frozen points reverting after the test advanced time. A small extension of PointBody now projects the saved state every physics frame, even while paused; the assertions wait for later frames before checking. The first thicker trace had back-face culling and was not visible from the visitor's side. It is now explicitly two-sided, with a corresponding check. An angled view also showed that separating the paths in depth distorted the comparison through parallax. Both now occupy the same plane, and an assertion checks their full difference vector. Failed captures are retained, not offered as successful evidence.

The existing room's width is 44 m; the plan normalizer still reports its pre-existing 13–19 m preferred-width warning. This work did not widen the room. Existing UID/texture diagnostics occur in baseline museum logs too; accepted new-code runs contain no SCRIPT ERROR or Parse Error. A neighbouring Bubble Blaster label draws through the board from the straight-on sightline; the angled capture shows it beside the panel. Its source has not been changed by this work.

Physical headset reach/readability, Quest performance, independent learner comprehension and a full portal journey remain untested. Browser rendering was not tested; local links and ZIP integrity are checked separately. Actual Godot captures were visually inspected, with current walls retained.

## Two texts, one local addition

[The tutorial](tutorial.html) contains the complete model, carried point, display extension, stage and scene. It separates the small calculation from supplied museum display code, explains update order and ends with an independent two-axis acceleration exercise. The complete optional text is appended to the hall's tutorial.md.

[The reflection](reflection.html) follows a difference produced by intervals, without treating accuracy as aesthetic judgment. Three paragraphs are appended to the existing final.md. The original small Euler board keeps its geometry; its misleading tunnelling caption is corrected to identify a visual marker with no collision test.

P1 is built alongside G0, G1 and G2. The next original package is P3: sample budget on the existing Monte Carlo dartboard. P2, P3, P4, P5 and P6 remain proposals, not implementations.
'''
(O/'REPORT.md').write_text(report,encoding='utf-8')
(O/'README.md').write_text('''# P1 review

Open index.html. tutorial.html and reflection.html are separate readings; hall-tutorial.md and hall-final.md preserve their complete hall context. code/ has the working sources. reconstruction/ includes fresh printed code and intentionally faulty variants. Measurements, before/after native images, failed captures, logs, hashes and canonical changes are retained.

This is a review package, not a standalone game. The five learner files run inside the existing Ada 4.6 museum with its player, camera, lighting, XRTools and ControlConsole. Resource paths are printed explicitly. Extracted variant paths are test-only ada_run locations; use the tutorial and code/ for installation. No tracked-headset or blind-student result is claimed.
''',encoding='utf-8')
tree=ast.parse((R/'tools/publish_pendulum_noise.py').read_text(encoding='utf-8'))
style=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='style' for t in n.targets))
nav='<nav><a href="index.html">Museum</a><a href="tutorial.html">Tutorial + code</a><a href="reflection.html">Reflection</a><a href="report.html">Evidence</a><a href="euler-step-review.zip">Review ZIP</a></nav>'
def md(s):return markdown.markdown(s,extensions=['fenced_code','tables'])
def page(name,title,body):
 (O/name).write_text(f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title><style>{style}</style></head><body><header><p>ENDLESS MUSEUM · P1 · 9 OCTOBER 2026</p><h1>{html.escape(title)}</h1>{nav}</header><main>{body}</main><footer>Actual museum captures / native Godot tests / headset and independent learner checks remain open</footer></body></html>',encoding='utf-8')
def fig(src,caption):return f'<figure><a href="{src}"><img src="{src}" alt="{html.escape(caption)}" loading="lazy"></a><figcaption>{html.escape(caption)}</figcaption></figure>'
body='<p>Keep the beginning and the force. Change the interval through which the point moves.</p>'
body+=f'<div class="badge">{len(core["checks"])} core checks · {printed["runs"][0]["checks"]} printed-code checks · 2 rejected mutations · {len(native["checks"])} museum checks</div>'
body+=fig('museum/comparison.png','In the existing launch hall: the reference, the stepped point and nearby hand controls. Forty updates over the same second.')
body+='<h2>One second, two resolutions</h2><div class="pair">'+fig('museum/steps-10.png','10 steps: +0.4900 m above the reference.')+fig('museum/steps-40.png','40 steps: +0.1225 m above the reference. The markers partly overlap as their centres converge.')+'</div>'
body+='<h2>The existing room, before and after</h2><div class="pair">'+fig('before/front-overhead.png','Before: launch chamber on the left; open bay near entry on the right.')+fig('museum/front-overhead.png','After: one optional comparison in that bay. The central route and all previous works remain.')+'</div>'
body+='<div class="pair">'+fig('before/bay.png','Before, at visitor eye height.')+fig('museum/bay.png','After, same camera and current walls.')+'</div>'
body+='<details><summary>Controls and wider room views</summary>'+fig('museum/controls.png','Step-count slider and five adjacent controls, exercised in the native museum probe.')+'<div class="pair">'+fig('before/raised.png','Before, raised view of the front court.')+fig('museum/raised.png','After: the panel faces arriving visitors; here its back is visible.')+'</div></details>'
body+='<h2>Read and reconstruct</h2><p><a href="tutorial.html">Full tutorial and working code</a> · <a href="reflection.html">A difference between steps</a> · <a href="report.html">Measurements, corrections and limits</a></p>'
page('index.html','The same throw, different steps',body)
page('tutorial.html','The same throw, different steps',md((O/'tutorial.md').read_text(encoding='utf-8')))
page('reflection.html','A difference between steps',md((O/'reflection.md').read_text(encoding='utf-8')))
page('report.html','What was built and checked',md(report)+'<p><a href="checks.json">Core receipt</a> · <a href="printed-validation.json">Printed reconstruction</a> · <a href="museum/report.json">Museum receipt</a> · <a href="changes.diff">Canonical changes</a> · <a href="hall-tutorial.md">Full hall tutorial</a> · <a href="hall-final.md">Full hall final</a></p>')
manifest={p.relative_to(R).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sources+[A/'euler_drift.gd',A/'tutorial.md',M/'map_data.json',M/'tutorial.md',M/'final.md',R/'tools/probes/euler_step_test.gd',R/'tools/probes/euler_step_room.gd']}
(O/'source-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
with zipfile.ZipFile(O/'euler-step-review.zip','w',zipfile.ZIP_DEFLATED) as z:
 for p in O.rglob('*'):
  if p.is_file() and p.suffix!='.zip' and p.name!='validation.json':z.write(p,p.relative_to(O))
links=0
for p in O.glob('*.html'):
 for target in re.findall(r'(?:href|src)="([^"]+)"',p.read_text(encoding='utf-8')):
  if target.startswith(('http:','https:')):continue
  assert (p.parent/target.partition('#')[0]).exists(),(p,target);links+=1
with zipfile.ZipFile(O/'euler-step-review.zip') as z:
 assert z.testzip() is None
 for name in ['index.html','tutorial.html','reflection.html','report.html']:
  for target in re.findall(r'(?:href|src)="([^"]+)"',z.read(name).decode('utf-8')):
   if target.startswith(('http:','https:')) or target.endswith('.zip'):continue
   assert target.partition('#')[0] in z.namelist(),target
validation={'core_checks':len(core['checks']),'printed_checks':printed['runs'][0]['checks'],'mutants_rejected':2,'museum_checks':len(native['checks']),'route_samples':native['observations']['route_samples'],'local_links':links,'zip_valid':True,'old_placements_kept':tokens,'only_cell_changed':changed,'browser_render_tested':False}
(O/'validation.json').write_text(json.dumps(validation,indent=2),encoding='utf-8')
print(json.dumps(validation));print('ZIP bytes', (O/'euler-step-review.zip').stat().st_size)
