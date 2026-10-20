"""Publish the Boids lesson, native evidence and the next handoff."""
from pathlib import Path
import json,re,hashlib,shutil,html,zipfile
import markdown
R=Path(__file__).resolve().parents[1];ID='SwarmIntelligence_Boids_Algorithm'
O=R/'doc/book/iterations/2026-10-10-boids-who-is-near';M=R/'commons/maps'/ID
S=R/'doc/book/studies/swarm-through-the-hands'/ID
RUN=R/'ada_run/encounter_pilot'/ID/'boids-lesson'
def text(p):return p.read_text(encoding='utf8')
def read(p):return json.loads(text(p))
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(s.encode('utf8'))
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
code=read(O/'checks.json');room=read(RUN/'report.json')
assert code['passed'] and code['completed'] and room['passed'] and room['completed']
assert 'SCRIPT ERROR' not in text(O/'code.log') and 'SCRIPT ERROR' not in text(RUN/'engine.log')
assert 'No vertices were added' not in text(RUN/'engine.log')
assert hashlib.sha256(text(M/'tutorial.md').encode()).hexdigest()==code['tutorial_sha256']
for name,source in re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',text(M/'tutorial.md'),re.S):
 assert source+'\n'==text(S/name)==text(O/'printed'/name)
assert (S/'point_body.gd').read_bytes()==(R/'doc/book/studies/swarm-through-the-hands/SwarmIntelligence_FlowFields/point_body.gd').read_bytes()
old=read(O/'before/commons/data/museum/em_plan.json');current=read(R/'commons/data/museum/em_plan.json')
assert len(old['plans'])==len(current['plans'])
for a,b in zip(old['plans'],current['plans']):
 if a.get('map')!=ID:assert a==b
controls=R/'commons/artifacts/flocking_controls/flocking_controls.gd'
def update_body(s):return s.split('func _update_boids(',1)[1].split('\nfunc ',1)[0]
assert update_body(text(controls))==update_body(text(O/'before/flocking_controls.gd'))
dump(O/'source-check.json',{'point_body_carried_byte_identical':True,'other_runtime_halls_unchanged':True,'production_controls_update_function_unchanged':True,'production_change':'Skip creating an empty ImmediateMesh surface when every displayed arrow is below the existing threshold.','student_model':'Separate explicit planar snapshot model with bounded steering; not substituted into existing exhibits.'})

summary='''In the Boids hall, find the ringed body and compare the three arrows before reading the whole flock. Carry the same PointBody and bounded steering from FlowFields; nearby points now supply the requests. Select neighbours by distance, exclude yourself, and build separation, alignment and cohesion one at a time before combining their weights. Read one old state and commit the next states together. Use six held points to change who is nearby; distinguish coasting with no neighbours from braking towards stationary neighbours. Predict the first tick, halve the alignment weight and test the result; reverse storage order to expose any accidental in-place update. Carry the local rule and the shared snapshot into Agent-Based Modeling, where an internal state can change how a point responds.'''
short='''Boids: carry PointBody + v + bounded steering. Six XZ points; radius selects indices, excludes self. SEP away/d² inside2cells → unit*speed; ALIGN mean neighbour velocity; COH mean offset → unit*speed. Weight/cap; read old arrays, commit next. None→coast; ALIGN mean0→brake; coincident skips separation division. Wrap motion; direct distances do not cross seam. Hold→pause/relocate; trigger→observe; reset bodies keeps rule/radius/weights. Predict first tick; halve ALIGN; reverse order. Next ABM: internal state. Full printed code, prepared museum/XR/button dependency. No headset claim.'''
write(O/'SUMMARY.md','# Boids — lesson paragraph\n\n'+summary+'\n\n## Short instruction\n\n'+short+'\n')
ep=R/'doc/book/course/execution-plan/plan.json';plan=read(ep)
if not (O/'before/execution-plan.json').exists():shutil.copy2(ep,O/'before/execution-plan.json')
row=next(x for x in plan['lessons'] if x['id']==ID)
row.update(summary=summary,object='The same PointBody, now responding to selected neighbours.',
 change='Select local neighbours; separate three requests; weight and cap; read a shared snapshot and commit next states.',
 reuses='FlowFields PointBody unchanged, velocity, response time and bounded steering; vector sums/averages; CA old/next state.',
 given='Prepared Ada museum/player/light/camera/XRTools and the named push_button.tscn. Three complete student scripts printed.',
 later='Spatial hashing, full3D motion and production aquarium update policy remain contextual comparisons. No collision avoidance or claim about consent.',
 transfer='Halve alignment weight, predict first velocity(0.95,0.1), execute. Change radius and explain which observations change.',
 carry='PointBody, local neighbour selector, three separately weighted requests, snapshot update, individual rule versus collective pattern.',
 next='Agent-Based Modeling: carry these same points and add explicit internal state rather than introducing an unrelated agent.',
 checks=[f"{len(code['checks'])} exact printed-code Godot checks; independent weight change; three faulty variants detected; synthetic XR pickup/trigger/release.",f"{len(room['checks'])} native checks; before/after overhead, working-height exhibits, local approach and diagram controls."],
 notes='Implemented draft for review, not independent student/headset certification. Six-point study temporarily inserted for captures, supplied as scene. Existing tank/panel lifted on plinths; exit moved to existing perimeter opening. Production flock rules retained; only empty-arrow rendering fixed.')
dump(ep,plan);dump(O/'lesson-plan.json',row)

technical=f'''# Boids — reconstruction and museum evidence

## Printed code

{len(code['checks'])} assertions pass in a fresh Godot 4.6 process. The test runner extracts the three marked code blocks from canonical tutorial.md and compares them with the saved study before execution. PointBody is byte-identical to FlowFields. The model and host are complete for the explicitly supplied Ada environment; this is not an empty-project export.

Checks include exact neighbour indices; three independently calculated requests; first separation velocity(0.7,0), alignment(0.9,0.2) and cohesion; the combined cap; strict radius; coincident points; no-neighbour coasting; stationary-neighbour braking; balanced requests; the periodic motion/direct-distance seam; reversed traversal over20 steps;1,500 finite bounded steps; deterministic reset; and the independent half-alignment edit(0.95,0.1).

Three faulty models are actually executed and rejected by the checks: self included, combined cap omitted, and in-place state updates. The last produces a different result when order is reversed. The host tests actual button signals, unchanged object identities, radius geometry and synthetic XRTools pickup/trigger/release under a translated and rotated host. Initial test harness compilation tried to resolve XRTools before its autoload; moving that type inspection to runtime fixed the harness. The final log has no GDScript errors.

## What the model promises

Six points on the familiar16×16 XZ plane,0.16m per cell. Speed cap3cells/s; response0.5s; acceleration cap6cells/s²; step0.05s. Neighbour radius3.5 or2cells; separation distance strictly below2cells, also restricted by the chosen neighbour radius. All rules read old arrays. Alignment uses the actual mean velocity, including its speed; separation/cohesion use normalised direction at maximum speed. Absent or balanced directional requests contribute nothing. An alignment average of zero brakes. Distinct coincident points remain neighbours but have no invented separation direction.

This is an explicitly different small model from the existing aquarium: planar, synchronous and bounded. The production aquarium uses3D, a spatial grid, sequential updates and boundary bounces. Both remain identified in the tutorial. The learner arrows are weighted accelerations, not distances or instantaneous velocities. The white arrow is their capped combination. Reset restores body state while retaining the selected rule, radius and weights. Holding pauses all and clears only the held body's velocity; release resumes if Run was active. Trigger selects the observed point.

## Inside the existing museum

{len(room['checks'])} native checks pass. The original100-agent open flock,30-agent aquarium and30-agent controls display are retained. The tank and panel were partly below the floor. This hall now requests plinth heights0.5m and0.85m; automatic mesh seating places their centres at approximately1.20m and1.32m. The actual separation slider is checked between0.8m and1.25m. Canonical map_data and em_plan agree; all other runtime hall rows are unchanged.

The old next-room marker at(10,10) shared the controls' approach. Raising the panel exposed that conflict and generated an obstructing fallback portal. The marker now uses the existing three-cell perimeter opening at(6,12). The report includes the investigation image; it is not used as a successful exhibit photograph. The final run's portal result is recorded separately below. No physical player crossing or Quest test is claimed.

The printed learner scene is temporarily placed at map/world(6,0,9), yaw0, for this native run. It is supplied as study.tscn, not permanently added to the artifact registry. Its supported approach and two sightlines pass. The first candidate at(9,0,5) intersected a visible wall even though two collision rays passed; its image and receipt are retained under placement-investigation. Native image inspection remains necessary in addition to assertions.

The original controls display repeatedly called ImmediateMesh.surface_end() with no vertices when all three forces were too small to draw. A guard now uses the same0.001 threshold as its existing arrow helper. A zero-force fixture produces no surface, and a nonzero fixture still produces an arrow. The production movement/update function is unchanged.

## Evidence limits

The test operator is the authoring assistant. These are reconstruction tests, not an independent ghost student's reading or proof of pedagogical success. Synthetic XR exercises the real pickup code but cannot establish hand comfort, hardware performance or headset legibility. Captures use the compatibility renderer; existing Forward+ lighting warnings and the unresolved startup UID remain in the engine log. The old tank-divergence figure is preserved as a dated25 September measurement, not rerun or generalised here. The final text now says so and distinguishes step count from equal elapsed time.

## Reproduce

1. `python tools/write_swarm_boids.py`
2. `python tools/test_swarm_boids.py`
3. `python tools/seat_swarm_boids.py`
4. `python tools/run_encounter_probe.py SwarmIntelligence_Boids_Algorithm --sequence swarmintelligence --render --no-bridges --output-tag boids-lesson --probe tools/probes/swarm_boids_room.gd`
5. `python tools/publish_swarm_boids.py`
6. `python tools/verify_swarm_boids_review.py`
'''
for a,b in [('velocity(0.7','velocity (0.7'),('alignment(0.9','alignment (0.9'),('edit(0.95','edit (0.95'),('over20','over 20'),(';1,500','; 1,500'),('familiar16','familiar 16'),(',0.16m',', 0.16 m'),('cap3cells','cap 3 cells'),('response0.5s','response 0.5 s'),('cap6cells','cap 6 cells'),('step0.05s','step 0.05 s'),('radius3.5 or2cells','radius 3.5 or 2 cells'),('below2cells','below 2 cells'),('uses3D','uses 3D'),('original100','original 100'),(',30-agent',', 30-agent'),('and30-agent','and 30-agent'),('heights0.5m and0.85m','heights 0.5 m and 0.85 m'),('approximately1.20m and1.32m','approximately 1.20 m and 1.32 m'),('between0.8m and1.25m','between 0.8 m and 1.25 m'),('at(10,10)','at (10,10)'),('at(6,12)','at (6,12)'),('world(6,0,9)','world (6,0,9)'),('yaw0','yaw 0'),('at(9,0,5)','at (9,0,5)'),('same0.001','same 0.001'),('dated25','dated 25')]:technical=technical.replace(a,b)
portal_lines=[s for s in text(RUN/'engine.log').splitlines() if '[em-portals]' in s and 'blocked' in s]
technical+='\n## Portal log\n\n'+('The final native startup reports blocked portal placement; whole-hall traversal remains unresolved.\n' if portal_lines else 'The final native startup contains no blocked-portal placement warning. This is a placement result, not a physical traversal test.\n')
write(M/'technical.md',technical)
for folder in ['assets','museum','after','probes','production-fix','tools']:(O/folder).mkdir(exist_ok=True)
for p in RUN.glob('*.png'):shutil.copy2(p,O/'assets'/p.name)
for name in ['above-before.png','aquarium.png','flocking-controls.png']:shutil.copy2(O/'room-before'/name,O/'assets'/('old-'+name))
for name in ['report.json','engine.log','source_manifest.json','spec.json']:shutil.copy2(RUN/name,O/'museum'/name)
for name in ['swarm_boids_student.gd','swarm_boids_room.gd','transformation_encounters.gd']:shutil.copy2(R/'tools/probes'/name,O/'probes'/name)
for name in ['write_swarm_boids.py','test_swarm_boids.py','seat_swarm_boids.py','publish_swarm_boids.py','verify_swarm_boids_review.py']:shutil.copy2(R/'tools'/name,O/'tools'/name)
shutil.copy2(controls,O/'production-fix/flocking_controls.gd')
shutil.copy2(R.parent/'ada_encyclopedia/public/book-images/figures/swarmintelligence/tank-two-runs-part.png',O/'assets/tank-two-runs-part.png')
shutil.copy2(R/'doc/book/iterations/claude-swarmintelligence-noc-reading-2026-09-25/probe_boids_tank_divergence.json',O/'museum/historical-tank-divergence.json')
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
 shutil.copy2(M/name,O/'after'/name)
 if name.endswith('.md'):write(O/name,text(M/name).replace('/book-images/figures/swarmintelligence/tank-two-runs-part.png','assets/tank-two-runs-part.png'))
write(O/'changes.md','''# Boids — what changed

| Before | Now |
| --- | --- |
| Partial snippets with an undefined host and in-place updates. | Three complete printed scripts, a carried PointBody and snapshot updates tested in Godot. |
| Three rules introduced together. | Select separation, alignment, cohesion, then their combination. |
| Movement without a local numerical witness. | Six known bodies, named neighbours, a radius ring, weighted arrows and velocity/acceleration readout. |
| Tank and controls partly below the floor. | Plinths bring both exhibits and their controls into view. |
| An empty ImmediateMesh surface generated repeated errors. | Zero arrows skip the surface; movement rules are unchanged. |
| Next marker overlaps the raised controls' approach. | Marker uses the existing perimeter opening. |
| Reflection makes universal claims from one divergence measurement. | The record is dated and scoped; reflection stays with neighbourhoods, boundaries and the limits of belonging as a metaphor. |

The learner study was temporarily placed for these photographs and is supplied as runnable code. Existing production flock rules remain intact. Other Swarm halls remain as they were.
''')
css=text(R/'doc/book/iterations/2026-10-10-swarm-a-trace-outside/style.css')
css+='table{border-collapse:collapse;width:100%;font:15px/1.5 system-ui}th,td{padding:12px;border-bottom:1px solid #ccd4d5;text-align:left;vertical-align:top}details{background:#e2e8e7;padding:16px;margin:22px 0}summary{cursor:pointer;font-family:system-ui}.parallel article{overflow-wrap:anywhere}'
nav='<nav><a href="index.html">Boids</a><a href="parallel.html">Facing pages</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Changes</a><a href="technical.html">Tests & limits</a><a href="boids-review.zip">Review ZIP</a></nav>'
def render(md):return markdown.markdown(md,extensions=['fenced_code','tables','footnotes'])
def page(name,title,body,cls=''):
 write(O/name,'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style>'+nav+'<main class="'+cls+'">'+body+'</main></html>')
for name in ['tutorial','final','technical','changes']:page(name+'.html','Boids · '+name,render(text(O/(name+'.md'))))
page('parallel.html','Boids · tutorial beside reflection','<article>'+render(text(O/'tutorial.md'))+'</article><article>'+render(text(O/'final.md'))+'</article>','parallel')
page('before.html','Boids · previous tutorial',render(text(O/'before/tutorial.md')))
def figure(name,caption):return '<figure><img loading="lazy" src="assets/'+name+'.png" alt="'+html.escape(caption)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
body=f'''<div class="tag">Endless Museum / Swarm Intelligence / 3 of 7</div><h1>Who is near?</h1><p>The same point keeps its velocity. Nearby bodies now supply three different requests.</p><p class="notice"><strong>{len(code['checks'])} printed-code checks pass.</strong> Complete tutorial, carried PointBody, independent variation and three detected faulty versions. <a href="parallel.html">Read tutorial left, reflection right.</a></p>'''
body+=figure('three-requests','Native Godot capture. Pink point 0 sees two neighbours. Red: separation. Blue: alignment. Green: cohesion. White: their capped combination.')
body+='<h2>One paragraph to guide the lesson</h2><p>'+html.escape(summary)+'</p><details><summary>Short instruction for the next pass</summary><p>'+html.escape(short)+'</p></details><h2>One request at a time</h2><div class="grid">'
for name,caption in [('separation','Separation: the close point makes a leftward correction. The body initially keeps moving right.'),('alignment','Alignment: both neighbours request velocity (0,2); the correction is (-2,4) cells/s².'),('cohesion','Cohesion: the local centre lies to the right and slightly away from the visitor.'),('one-neighbour','Radius reduced from 3.5 to 2 cells: point 2 no longer contributes. The rule stays; its input changes.')]:body+=figure(name,caption)
body+='</div><h2>Standing in the museum</h2>'+figure('eye-level','Camera at 1.7 m. The hand can move a point; its trigger selects which neighbourhood we inspect. This is not a physical headset assessment.')
body+='<h2>Give the existing controls a usable height</h2><div class="grid">'+figure('old-flocking-controls','Before: much of the small flock and its controls were below the floor.')+figure('flocking-controls','After: the existing sliders and agents are raised on a plinth. Their movement code is unchanged.')+'</div>'+figure('aquarium','The existing aquarium is also raised. The glass boundary and the numerical boundary remain different things.')
body+='<h2>Room arrangement</h2><div class="grid">'+figure('old-above-before','Before: existing Boids hall from above.')+figure('above-after','After: raised exhibits; temporary learner study in the open bay; next-room marker at the perimeter opening.')+'</div>'
body+=f'''<h2>What the evidence covers</h2><p>{len(room['checks'])} native checks cover the exhibits, diagram controls, local approach, sightlines and captures. The study is supplied as code and was temporarily inserted for these images. It is not permanently registered as another exhibit.</p><p>The full tutorial declares the supplied museum environment and explains every new rule. The reflection retains the encounter with the three existing flocks and sharpens its claims about boundaries and repeated runs. <a href="technical.html">Test details and limits</a> distinguish reconstruction, historical measurements and headset experience.</p><p><a href="SUMMARY.md">Paragraph + compressed instruction</a> · <a href="before.html">Previous tutorial</a> · <a href="http://localhost:3003/tutorial-plan?map=SwarmIntelligence_Boids_Algorithm&amp;view=summaries">Editable lesson plan</a></p><p class="meta">Next: Agent-Based Modeling. Carry the same points; add an internal state that changes their response.</p>'''
page('index.html','Boids · who is near?',body)
write(O/'README.md','# Boids review\n\nOpen index.html or parallel.html. Complete tutorial and reflection, three printed scripts, native before/after images, test receipts and probes. Requires prepared Ada project with XRTools and push_button.tscn. Author-operated reconstruction tests, not an independent student or physical Quest assessment. Next: Agent-Based Modeling.\n')
with zipfile.ZipFile(O/'boids-review.zip','w',zipfile.ZIP_DEFLATED) as z:
 for p in O.iterdir():
  if p.is_file() and p.suffix in ['.html','.md','.json','.log']:z.write(p,p.name)
 for folder in ['printed','variation','fault-self','fault-cap','fault-order','assets','museum','probes','production-fix','tools']:
  for p in (O/folder).rglob('*'):
   if p.is_file() and p.suffix!='.uid':z.write(p,p.relative_to(O))
 for name in ['tutorial.md','final.md']:z.write(O/'before'/name,'before/'+name)
with zipfile.ZipFile(O/'boids-review.zip') as z:assert z.testzip() is None
handoff=R/'doc/book/course/storyboards/SWARM-HANDOFF.md'
if not (O/'before/SWARM-HANDOFF.md').exists():shutil.copy2(handoff,O/'before/SWARM-HANDOFF.md')
write(handoff,f'''# Swarm / 10 October 2026

Completed Physarum, FlowFields, Boids (3 of7). Next: SwarmIntelligence_Agent_Based_Modeling_ABM. Carry PointBody, local observations and shared snapshot; add internal state. Do not replace the learner object. Other four halls remain plans. Soft Bodies → Swarm → Graph Theory → Machine Learning retained. One hall at a time; full runnable code in tutorial.md, reflection in final.md; native images including overhead, exact printed-code Godot assertions, independent change. No physical headset/independent learner claims from author-operated probes.

Latest report: doc/book/iterations/2026-10-10-boids-who-is-near/index.html; parallel.html, tutorial/final full readings, SUMMARY.md, boids-review.zip. {len(code['checks'])} code + {len(room['checks'])} native checks pass. Canonical execution-plan/plan.json Boids row updated alone; review decision/baseline preserved. Sources: doc/book/studies/swarm-through-the-hands/SwarmIntelligence_Boids_Algorithm/{{flock.gd,study.gd,point_body.gd,study.tscn}}. PointBody exact from FlowFields. Six XZ points; neighbours <3.5/2cells, self excluded; separation <2cells and noncoincident away/d² normalized*3; alignment actual mean velocity; cohesion mean offset normalized*3. Same .5s response,6cells/s² cap,.05s tick. Weight/cap; snapshot then commit. None→coast; ALIGN mean0→brake; balanced SEP/COH→none. Periodic motion but direct distances do not cross seam. Point0pink, goldradius, cyan neighbour rings, weighted red/blue/green arrows, cappedwhite. Hold pausesall, records local position, clears heldv; trigger selects witness; release plane/resume. Reset bodies keepsmode/radius/weights. 40 checks include firstticks, reverseorder20steps,1500bounded, independent halfalignment,3faults,syntheticXR under transformedhost.

Museum Boids: existing algorithms retained. Tank plinth.5m and controls plinth.85m bring centres~1.20/1.32m; automatic seating means do not add guessed Y offsets. map_data and em_plan match. Other runtime rows unchanged. Empty-force ImmediateMesh surface guard in flocking_controls is the only production code edit; update function identical. Next marker moved from10,10 (conflicts with raisedcontrols) to perimeter opening6,12. Student temporarily placed(6,0,9),yaw0, not permanentregistry. First position9,0,5 was visually blocked despite ray tests; images prove why visualinspection matters. Investigation retained. Portal status: {'blocked warning remains' if portal_lines else 'final log no blocked warning; not traversal tested'}. Existing startupUID/render warnings documented. Native code clean.

Final text tightened: no universal5-secondchaos claim;25September tankdivergence explicitlyhistorical, compared bystepcount; consent analogy kept distinct frommechanics. Historicalfigure copiedfrom siblingada_encyclopedia/public/book-images/figures/swarmintelligence/tank-two-runs-part.png. Originalrecord included. PrimaryReynolds link verified.

Replay tools: write_swarm_boids.py; test_swarm_boids.py; seat_swarm_boids.py; run_encounter_probe.py SwarmIntelligence_Boids_Algorithm --sequence swarmintelligence --render --no-bridges --output-tag boids-lesson --probe tools/probes/swarm_boids_room.gd; publish_swarm_boids.py; verify_swarm_boids_review.py. Do not rerun oldPhysarumpublisher (resetsfutureplanrows).

Prior reports: 2026-10-10-swarm-a-trace-outside (33code/20native); 2026-10-10-flow-directions-already-here (35code/21native). Flow's hall-specific privateworldtable preserves original200agents/grid/route. OriginalFlowFieldMain token otherplacements intact. Existing Flow authoredportal/wedge issues unresolved; don't claimglobalVRroutefixed. Previous fullhandoff preserved in latest report/before/SWARM-HANDOFF.md. InlineCSS for book-review. Huge unrelateddirtytree; noagents/commits/reverts.
''')
print(f'Published Boids: {len(code["checks"])} code / {len(room["checks"])} native checks, full readings, images, plan and ZIP.')
