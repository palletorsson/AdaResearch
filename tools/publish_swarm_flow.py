"""Publish one tested Swarm hall, keeping future halls as plans."""
from pathlib import Path
import json,hashlib,html,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-10-flow-directions-already-here'
M=R/'commons/maps/SwarmIntelligence_FlowFields'
S=R/'doc/book/studies/swarm-through-the-hands/SwarmIntelligence_FlowFields'
RUN=R/'ada_run/encounter_pilot/SwarmIntelligence_FlowFields/flow-lesson'
BASE=R/'ada_run/encounter_pilot/SwarmIntelligence_FlowFields/flow-baseline'
PREVIOUS=R/'doc/book/iterations/2026-10-10-swarm-a-trace-outside'
def read(p):return json.loads(p.read_text(encoding='utf8'))
def text(p):return p.read_text(encoding='utf8')
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf8')
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
code=read(O/'checks.json');room=read(RUN/'report.json')
assert code['passed'] and code['completed'] and room['passed'] and room['completed']
assert 'SCRIPT ERROR' not in text(O/'code.log') and 'SCRIPT ERROR' not in text(RUN/'engine.log')
assert hashlib.sha256(text(M/'tutorial.md').encode()).hexdigest()==code['tutorial_sha256']
for name,source in re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',text(M/'tutorial.md'),re.S):
 assert source+'\n'==text(S/name)==text(O/'printed'/name)
assert (S/'point_body.gd').read_bytes()==(R/'doc/book/studies/swarm-through-the-hands/SwarmIntelligence_PhysarumColony/point_body.gd').read_bytes()

# Scope audit: only this museum placement uses the new bounded token.
registry=read(R/'commons/artifacts/registry/algorithms_misc.json')
old_registry=read(O/'before/commons/artifacts/registry/algorithms_misc.json')
assert registry['artifacts']['FlowFieldMain']==old_registry['artifacts']['FlowFieldMain']
for k,v in old_registry['artifacts'].items():assert registry['artifacts'][k]==v
planpath=R/'commons/data/museum/em_plan.json';current=read(planpath);old=read(O/'before/commons/data/museum/em_plan.json')
assert len(current['plans'])==len(old['plans'])
for a,b in zip(current['plans'],old['plans']):
 if a.get('map')!='SwarmIntelligence_FlowFields':assert a==b
placement=next(x for x in current['plans'] if x.get('map')=='SwarmIntelligence_FlowFields')
assert next(x for x in placement['artifacts'] if x['token']=='flow_field_table')['cell']==[4,2]
assert read(M/'map_data.json')['layers']['interactables'][2][4]=='flow_field_table:90'
source_hashes={str(p.relative_to(R)):hashlib.sha256(p.read_bytes()).hexdigest() for p in (R/'algorithms/pathfinding/flow_field').glob('*') if p.suffix in ['.gd','.tscn']}
dump(O/'source-check.json',{'carried_point_unchanged':True,'original_registry_entries_unchanged':True,'other_runtime_halls_unchanged':True,'authored_runtime_placement_agree':True,'production_source_hashes':source_hashes})

summary='''In the existing FlowFields hall, read a direction near a moving body and predict its turn. Carry PointBody and the field address from Physarum; replace scalar trail strength with a supplied vector and give each point a velocity. In the six-point study, compare desired and current velocity, limit the steering acceleration, and let a central patch turn or brake the same bodies. Hold a point to edit one address, then show that another point reads the same unchanged instruction. Reverse the patch direction as an independent code variation. Keep route construction in the larger exhibit as context for later Graph Theory. Carry the body and bounded steering into Boids, where nearby points supply the desired movement.'''
short='''FlowFields: same PointBody + address; scalar trace → supplied Vector2. Read only during motion. Desired=unit(sample)*speed; acceleration=(desired−velocity)/response, capped; fixed dt; periodic bounds. Zero→brake (exhibit zero→wander). Visitor edits one cell/patch; reset clears field+motion and pauses. Predict/reverse patch. Next Boids: same steering, neighbours supply direction. Museum host/XR/button declared; full printed code tested; no headset claim.'''
write(O/'SUMMARY.md','# FlowFields — lesson paragraph\n\n'+summary+'\n\n## Short instruction\n\n'+short+'\n')
ep=R/'doc/book/course/execution-plan/plan.json';plan=read(ep)
backup=O/'before/execution-plan.json'
if not backup.exists():shutil.copy2(ep,backup)
row=next(x for x in plan['lessons'] if x['id']=='SwarmIntelligence_FlowFields')
row.update(summary=summary,object='The carried PointBody reading a supplied vector field.',
 change='Sample a direction; compare desired/current velocity; apply bounded steering. Edit one address and compare turn with zero-vector braking.',
 reuses='Physarum PointBody unchanged; flat field addresses, local metre conversion; velocity integration from Forces.',
 given='Prepared Ada museum/XRTools/player/camera/light and named push_button.tscn. All three student scripts are printed in full.',
 later='Route construction, collision avoidance and production wandering remain exhibit context. Graph Theory later owns BFS, Dijkstra and A-star.',
 transfer='Reverse the supplied patch from (0,1) to (0,-1), predict the first y-velocity sign, then execute the changed model.',
 carry='Same point, explicit velocity and bounded desired-minus-current steering; field lookup is read-only during motion.',
 next='Boids: derive desired motion from neighbours, read one shared snapshot, separate separation/alignment/cohesion, exclude self and handle zero neighbours.',
 checks=[f"{len(code['checks'])} exact printed-code Godot checks, independent direction edit, three detected faults, synthetic XRTools pickup/trigger/release.",f"{len(room['checks'])} native checks including captures, retained original simulation, local approach, sightlines and turn/brake controls. Existing portal warnings remain outside this local pass."],
 notes='Implemented draft for review. 200-agent exhibit preserved in private world on a new hall-specific table token; old full-size token and other placements unchanged. Student study is temporarily inserted for captures, not permanently installed. No independent learner/headset/full-hall traversal claim.')
dump(ep,plan)
dump(O/'lesson-plan.json',row)

technical=f'''# FlowFields — test and placement record

## What is now runnable

The canonical `tutorial.md` prints field.gd, study.gd and the byte-identical PointBody from Physarum. `tools/test_swarm_flow.py` extracts the printed code, verifies equality with the saved study, and starts a fresh Godot 4.6 process. {len(code['checks'])} checks pass. They cover the exact first tick (velocity0.3 cells/s; displacement0.015 cells), steady motion, bounded reversal, a turn with retained momentum, zero-vector braking and rest, periodic bounds, unchanged field after1,500 steps, update-order independence, deterministic reset, local edits and preservation of body identity.

A separately generated patch points south; its first velocity is checked against an independent expected value. Three executed faulty variants are rejected: missing current-velocity subtraction, missing acceleration cap, and writing into the supplied field during movement. Actual button signals and synthetic XRTools pickup/trigger/release run with a translated/rotated study. This is author-operated reconstruction evidence. It is not an independent learner review, physical Quest usability test or hardware-performance measurement.

## Museum placement

Baseline captures show the existing50m ground and its agents crossing the13×10 hall boundaries. This hall now uses the new `flow_field_table` token at authored cell(4,2), yaw90, with matching em_plan placement. The table has a2.8m live screen on a2.95m body. Its private SubViewport/World3D holds the original40×40 field,200 agents and original route/wind/noise tour. FlowFieldMain.gd, FlowGrid.gd, FlowAgent.gd and their scene/visualizer remain unchanged. The original `FlowFieldMain` registry entry and its other placements are preserved. The table forwards existing scenario/display configuration and names its current scenario.

The full printed learner study is temporarily instantiated beside it at map/world(8.5,0,2.5), yaw−90, for the native run. It is supplied as study.tscn, not permanently installed in the hall. Its six spheres are kinematic teaching objects. Neither simulation is represented as a calibrated fluid model, shortest-route proof or biological reconstruction.

{len(room['checks'])} native checks pass, including seven images, original-agent movement, private-world separation, control effects, clear sightlines and a supported study-bay approach. Overhead, elevated detail and1.7m eye-height views are supplied. Turn and brake screenshots use the same reset start and tick42. These are native Godot images, not generated illustrations.

## Limits found, not erased

The initial approach check continued through a pre-existing central wedge at map/world z3.5. Its collider names and failed report are retained in approach-investigation.json. The final approach test explicitly covers the study bay from z1 through3 plus its controls; it does not certify walking through that wedge.

Both the baseline and final native logs report blocked authored entry/exit and a fallback arrival in this hall. Portal traversal needs a separate repair before this hall can be called ready for an uninterrupted VR walkthrough. The long-standing unresolved UID `uid://rwex60pqapc` also appears at startup. Neither is counted as a passing lesson assertion. The headless code log contains the existing Jolt custom-solver-bias warning. No GDScript/parse errors occur in the final code or native run.

The production zero-vector behaviour remains random wandering. The tutorial deliberately brakes. Model units are cells, cells/s and cells/s²; display size is0.16m/cell. Both model bounds and input-edit semantics are explicitly explained. The response time is0.5s, acceleration cap6cells/s², speed3cells/s and step0.05s. Patch changes retain body state; Reset clears all edits, restores bodies and pauses. Holding clears that point's velocity and pauses everyone until release.

## Reproduce

1. `python tools/write_swarm_flow.py`
2. `python tools/test_swarm_flow.py`
3. `python tools/seat_swarm_flow.py`
4. `python tools/run_encounter_probe.py SwarmIntelligence_FlowFields --sequence swarmintelligence --render --no-bridges --output-tag flow-lesson --probe tools/probes/swarm_flow_room.gd`
5. `python tools/publish_swarm_flow.py`

The code and probe files are included for inspection. The ZIP is a review bundle for the prepared Ada project, not a standalone game export.
'''
# Keep technical prose readable while preserving code identifiers.
for a,b in [('including seven images','including native images'),('after1,500','after 1,500'),('existing50m','existing 50 m'),('the13×10','the 13 × 10'),('a2.8m','a 2.8 m'),('a2.95m','a 2.95 m'),('original40×40','original 40 × 40'),('field,200','field, 200'),('and1.7m','and 1.7 m'),('tick42','tick 42'),('velocity0.3','velocity 0.3'),('displacement0.015','displacement 0.015'),('cell(4,2)','cell (4,2)'),('yaw90','yaw 90'),('yaw−90','yaw −90'),('world(8.5','world (8.5'),('z3.5','z 3.5'),('from z1 through3','from z 1 through 3'),('is0.16m','is 0.16 m'),('is0.5s','is 0.5 s'),('cap6cells','cap 6 cells'),('speed3cells','speed 3 cells'),('step0.05s','step 0.05 s')]:technical=technical.replace(a,b)
write(M/'technical.md',technical)
for folder in ['assets','museum','after','probes','prefab']:(O/folder).mkdir(exist_ok=True)
for p in RUN.glob('*.png'):shutil.copy2(p,O/'assets'/p.name)
for name in ['above-before.png','entry-before.png']:shutil.copy2(BASE/name,O/'assets'/name)
for name in ['report.json','engine.log','source_manifest.json','spec.json']:shutil.copy2(RUN/name,O/'museum'/name)
for name in ['report.json','engine.log']:shutil.copy2(BASE/name,O/'museum'/('baseline-'+name))
for name in ['swarm_flow_student.gd','swarm_flow_room.gd','transformation_encounters.gd']:shutil.copy2(R/'tools/probes'/name,O/'probes'/name)
for p in (R/'commons/artifacts/flow_museum').glob('*'):
 if p.suffix in ['.gd','.tscn']:shutil.copy2(p,O/'prefab'/p.name)
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
 shutil.copy2(M/name,O/'after'/name)
 if name.endswith('.md'):shutil.copy2(M/name,O/name)
write(O/'changes.md','''# One field, a different relation

| Before | Now |
| --- | --- |
| Partial field recipes and an undefined route helper. | Three complete scripts, extracted from the printed tutorial and run in Godot. |
| Direct acceleration from a direction, without the stated steering comparison. | Desired minus current velocity, response time, acceleration cap and visible units. |
| Little continuity with the preceding learner object. | Exactly the carried PointBody; the new work is in its relation to the field. |
| A50m ground and moving bodies extend through the hall. | Existing simulation contained in a live table; other placements retain the old token. |
| The reflection implies the Randomness comparison lies ahead. | The text compares the actual exhibit's zero-vector wandering with the study's braking. |

The field is supplied. The point does not write it. The visitor can change it. Those three roles remain distinct.

The new lesson tests the student's reconstructed operation. It does not certify the whole existing hall: authored portal entry/exit are still blocked in the native startup logs.
'''.replace('A50m','A 50 m'))

css=text(PREVIOUS/'style.css')
write(O/'style.css',css)
nav='<nav><a href="index.html">FlowFields</a><a href="parallel.html">Facing pages</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Changes</a><a href="technical.html">Tests & limits</a><a href="flow-field-review.zip">Review ZIP</a></nav>'
def render(md):return markdown.markdown(md,extensions=['fenced_code','tables','footnotes'])
def page(name,title,body,cls=''):
 write(O/name,'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style>'+nav+'<main class="'+cls+'">'+body+'</main></html>')
for name in ['tutorial','final','technical','changes']:page(name+'.html','FlowFields · '+name,render(text(O/(name+'.md'))))
page('parallel.html','FlowFields · tutorial beside reflection','<article>'+render(text(M/'tutorial.md'))+'</article><article>'+render(text(M/'final.md'))+'</article>','parallel')
page('before.html','FlowFields · previous tutorial',render(text(O/'before/tutorial.md')))
body=f'''<div class="tag">Endless Museum / Swarm Intelligence / 2 of 7</div><h1>Directions already here</h1><p>The same point reads a direction. It brings its previous velocity to the encounter. A turn is the difference between them, unfolding in time.</p><p class="notice"><strong>{len(code['checks'])} code checks pass.</strong> Complete runnable tutorial, carried PointBody, an independent variation and three rejected faults. The reflection sits on the right in <a href="parallel.html">facing pages</a>.</p><figure><img src="assets/student-turn.png" alt="Native museum view: carried points above a grid of cylinder arrows; pink point has entered the turning patch"><figcaption>Tick42. Desired velocity(0,3), current velocity(1.7,1.3) cells/s. The point is still carrying some eastward movement.</figcaption></figure><div class="grid"><section class="card"><h2>From Physarum</h2><p>Keep the sphere, field address and local coordinates. Replace a scalar trace that agents write with a direction that agents only read.</p></section><section class="card"><h2>Toward Boids</h2><p>Keep velocity and bounded steering. Next, nearby moving points supply the desired movement.</p></section></div><h2>The lesson paragraph</h2><p>{html.escape(summary)}</p><details><summary>Short instruction for the next pass</summary><p>{html.escape(short)}</p></details><h2>Turn / stop</h2><div class="grid"><figure><img src="assets/student-turn.png" alt="Point0 entering a northward patch"><figcaption>Turn: velocity gains a northward component.</figcaption></figure><figure><img src="assets/student-brake.png" alt="Same start and tick with a zero-vector patch"><figcaption>Stop: zero desired velocity produces bounded braking. Same initial positions and tick count.</figcaption></figure></div><h2>At standing height</h2><figure><img src="assets/student-eye-level.png" alt="Study seen from a camera at1.7 metres"><figcaption>Actual museum, camera at1.7m. Text names both velocities; cylinders show supplied directions. This capture is not a physical headset assessment.</figcaption></figure><h2>Give the existing simulation a place</h2><div class="grid"><figure><img src="assets/above-before.png" alt="Before: oversized field crosses room walls"><figcaption>Before: original full-size ground and agents spread outside the hall.</figcaption></figure><figure><img src="assets/above-after.png" alt="After: contained live field and temporary learner study"><figcaption>After: live exhibit at left; temporary student study at right.</figcaption></figure></div><figure><img src="assets/live-flow-table.png" alt="Live200-agent flow-field exhibit in a bounded table"><figcaption>The original simulation runs inside a private world. Its route, wind and noise rules are retained; the old token stays available at its other placements.</figcaption></figure><h2>Scope of this pass</h2><p>{len(room['checks'])} native checks cover the display, lesson controls, photographs, local approach and sightlines. The museum's existing authored entry/exit still report blocked portals; uninterrupted hall traversal remains unresolved. See <a href="technical.html">the evidence and limits</a>.</p><p><a href="before.html">Previous tutorial</a> · <a href="SUMMARY.md">Paragraph + short instruction</a> · <a href="http://localhost:3003/tutorial-plan?map=SwarmIntelligence_FlowFields&amp;view=summaries">Editable plan</a></p><p class="meta">Physarum and FlowFields are now implemented drafts. The remaining five Swarm halls retain their lesson plans. The learner study is supplied as code and was temporarily placed for these captures.</p>'''
for a,b in [('Tick42','Tick 42'),('velocity(0,3)','velocity (0,3)'),('velocity(1.7,1.3)','velocity (1.7,1.3)'),('at1.7','at 1.7'),('1.7m','1.7 m'),('Point0','Point 0'),('Live200','Live 200')]:body=body.replace(a,b)
page('index.html','FlowFields · directions already here',body)
write(O/'README.md','# FlowFields review\n\nOpen index.html. Full tutorial, full reflection and facing pages are included, with before/after native room images, printed code and test receipts. Requires prepared Ada museum/XRTools/button component. Not a standalone export. The lesson passes its tests; existing authored portal entry/exit still need repair.\n')
with zipfile.ZipFile(O/'flow-field-review.zip','w',zipfile.ZIP_DEFLATED) as z:
 for p in O.iterdir():
  if p.is_file() and p.suffix in ['.html','.md','.css','.json','.log']:z.write(p,p.name)
 for folder in ['printed','variation','fault-current','fault-cap','fault-write','assets','museum','probes','prefab']:
  for p in (O/folder).rglob('*'):
   if p.is_file() and p.suffix!='.uid':z.write(p,p.relative_to(O))
 z.write(O/'before/tutorial.md','before/tutorial.md')
 z.write(O/'before/final.md','before/final.md')
with zipfile.ZipFile(O/'flow-field-review.zip') as z:assert z.testzip() is None
write(R/'doc/book/course/storyboards/SWARM-HANDOFF.md',f'''# Swarm /10 October2026

Completed two halls: Physarum and FlowFields. Next: SwarmIntelligence_Boids_Algorithm. Seven-hall order retained; other five are plans, not passed lessons. Preserve Soft Bodies → Swarm → Graph Theory → Machine Learning. Canonical execution-plan/plan.json has all paragraphs; FlowFields row updated alone this turn, draft decision/baseline preserved.

Physarum report: doc/book/iterations/2026-10-10-swarm-a-trace-outside/index.html.33 code/20 native checks from preceding turn. Carried point exact from Topology_Entropy_Morphogenesis. Shared scalar trace,3sensors,strictside turn,tiesstraight,periodicbounds,retain.92/.55,cap8. Existing simulation via private table; rawlegacyalias retained.

FlowFields report: doc/book/iterations/2026-10-10-flow-directions-already-here/index.html; parallel.html full tutorial left/final right; SUMMARY.md paragraph+shortspeech; review ZIP. {len(code['checks'])} printed-source code checks and {len(room['checks'])} native checks pass. Three actual mutant models detected; independent southward patch; syntheticXRTools under translated/rotated host. Not independent learner/Quest evidence.

Sources: doc/book/studies/swarm-through-the-hands/SwarmIntelligence_FlowFields/{{point_body.gd,field.gd,study.gd,study.tscn}}. PointBody byte-identical to Physarum. Same16×16 lookup, .16m/cell,y→local−Z. Direction field defaults+X,32-cell patch+Y; button cycleszero/+X/+Y. Desired=normalised(sample)*3cells/s; a=(desired−v)/.5s capped6cells/s²; fixed.05s; positionswrap. Zero brakes. Motion never writes field; held point trigger cycles its one cell +X→+Y→zero→+X. Holding pausesall andclearsheldv; releaseprojectsplane/resumesifplaying. Reset allfield+state and pauses. Boids should reuse bounded steering but compute desired movement from neighbour snapshot. Start separation,thenalignment,thencohesion;self/coincident/zeroneighbours explicit;reverseorder test.

Permanent Flow hall-specific flow_field_table cell4,2 yaw90 matches map_data+em_plan. New privateworld wrapper commons/artifacts/flow_museum; original200agents/40×40grid/50mground/tour unchanged. Original FlowFieldMain registryentry and otherplacements unchanged. Learner temporarilyplacedworld8.5,0,2.5 yaw−90 inprobe,notpermanent. Canonical tutorial/final/technical updated. Baseline andfinal show existing blockedportalentry/exit; centralwedgeatworldz3.5 obstructsstraightaisle. Final localapproach scopez1..3only,sightlinesclear. approach-investigation.json retainsinitialfailure. Do not claimfullhalltraversal. ExistingUIDstartupwarning persists; noGDScripterrors. Native images inspected atoverhead/detail/1.7meyeheight.

Replay: tools/write_swarm_flow.py; test_swarm_flow.py; seat_swarm_flow.py; tools/run_encounter_probe.py SwarmIntelligence_FlowFields --sequence swarmintelligence --render --no-bridges --output-tag flow-lesson --probe tools/probes/swarm_flow_room.gd; publish_swarm_flow.py. Do not rerun oldPhysarumpublisher blindly—it resets future rows. Preserve hugeunrelateddirtytree; noagents/commits/reverts. Inline CSS required on localhost book-review pages.
''')
print('Published FlowFields: tutorial/reflection, native images, plan, ZIP and honest scope.')
