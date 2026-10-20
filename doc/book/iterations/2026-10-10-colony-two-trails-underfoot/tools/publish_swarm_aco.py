"""Publish the fifth Swarm encounter, with its real saved room and test receipts."""
from pathlib import Path
import json,html,re,shutil,hashlib,zipfile
import markdown
R=Path(__file__).resolve().parents[1];ID='SwarmIntelligence_Ant_Colony_Optimization'
O=R/'doc/book/iterations/2026-10-10-colony-two-trails-underfoot';M=R/'commons/maps'/ID
S=R/'doc/book/studies/swarm-through-the-hands'/ID;A=R/'commons/artifacts/ant_colony_walk'
RUN=R/'ada_run/encounter_pilot'/ID/'aco-exportable';BEFORE=RUN.parent/'aco-before'
def text(p):return p.read_text(encoding='utf8')
def read(p):return json.loads(text(p))
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(s.encode('utf8'))
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
code=read(O/'checks.json');native=read(RUN/'report.json')
assert code['passed'] and code['completed'] and native['passed'] and native['completed']
assert 'SCRIPT ERROR' not in text(O/'code.log') and 'SCRIPT ERROR' not in text(RUN/'engine.log')
assert code['tutorial_sha256']==hashlib.sha256(text(M/'tutorial.md').encode()).hexdigest()
for name,source in re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',text(M/'tutorial.md'),re.S):
 assert source+'\n'==text(S/name)==text(A/name)==text(O/'printed'/name)
old=read(O/'before/em_plan.json');now=read(R/'commons/data/museum/em_plan.json')
assert old.keys()==now.keys() and len(old['plans'])==len(now['plans'])
for a,b in zip(old['plans'],now['plans']):
 if a.get('map')!=ID:assert a==b
assert (S/'point_body.gd').read_bytes()==(R/'doc/book/studies/swarm-through-the-hands/SwarmIntelligence_Agent_Based_Modeling_ABM/point_body.gd').read_bytes()
summary='''Walk among the same PointBody spheres in a twelve-metre field. Carry the ABM point's position, velocity and carrying flag; split the shared trace into home and food. A searching point reads food and leaves home; contact with food reverses that relationship. Hold one body, move it to a destination, release and step, predicting the channel it will read and write. Replace the population while retaining both traces, then clear them. Independently halve deposit strength and test the changed amount without writing the other channel. This is a two-channel foraging model, with no shortest-route guarantee. Carry the distinction between shared traces and a body's own remembered state into Particle Swarm Optimization.'''
short='''ACO5/7. Museum permanent walk-in12m;24 PointBodies,51cmdiameter,0.8mhigh. Sameclass asABM/Boids. Add home/food arrays; SEARCHreadfood/writehome; RETURNreadhome/writefood. Contact<1cell beforemotion flipsflag/reversesv/renewsenergy. No directhomesteering. Threeoldsamples; tiesstraight; stoppedfallbackE/W. Commitall; fade.995; deposit.5*energy cap8; replenish ownsourcecell8. Energy−.0025/tick.16²periodic; .05s; .75m/cell. Holdpauseall/relocate/zerov/preservecarry+energy; triggerselect. Replacekeepsfields/tally/clock; Clearresetsrecords retainsparams. Halfdepositpredict.249375tick. TwoMultiMeshes. Exactprintedcode=runtimecopies. Nooptimality/biology/headsetclaim. NextPSOpersonalbest/score. Keepfullscale forremaininghalls.'''
write(O/'SUMMARY.md','# Ant Colony — one paragraph\n\n'+summary+'\n\n## Compressed instruction\n\n'+short+'\n')
plan_path=R/'doc/book/course/execution-plan/plan.json';plan=read(plan_path)
plan_before=json.loads(json.dumps(plan));row=next(x for x in plan['lessons'] if x['id']==ID)
row.update(summary=summary,object='The same grabbable PointBody in a permanent room-scale two-channel field.',
 change='Destination contact switches the field a point reads and the field it writes; replace direct home steering with local samples.',
 reuses='Unchanged PointBody class from ABM/Boids, carrying flag, velocity, bounded steering, three samples, shared-field arrays and scoped resets.',
 given='Existing Endless Museum, player/camera/light/XRTools/button scene. Complete model, unchanged PointBody and room host printed. Host batches floor strips into two MultiMeshes.',
 later='Shortest-route comparison, probabilistic tour construction, diffusion and ant biology are outside this minimal foraging lesson.',
 transfer='Halve deposit_amount to0.25. Away from destination cells, a direct energy1 deposit is0.25; after one tick energy.9975 gives0.249375. Other channel stays untouched by deposit.',
 carry='Same body, state-dependent read/write channels, shared environmental history, source renewal, evaporation and evidence boundaries.',
 next='Particle Swarm Optimization: give the carried sphere a remembered best position and distinguish that position from its score. Keep the primary encounter room-scale.',
 checks=[f"{len(code['checks'])} fresh exact printed-code checks, independent half-deposit variation, three executed faulty variants, synthetic XRTools pickup/release.",f"{len(native['checks'])} native saved-room checks: permanent24 bodies,12m field, both control banks, floor clearance, field elevation, rendered position and screenshots."],
 notes='Implemented review draft. Permanent ant_colony_walk replaces scaled AntColonyV2 only in this map/runtime row. Original AntColonyV2 source/registry retained elsewhere. Native scene uses byte-identical copies of printed code under commons/artifacts because doc is excluded from exports. No physical headset/performance or independent learner claim. Before/after and overhead report: doc/book/iterations/2026-10-10-colony-two-trails-underfoot/index.html.')
for a,b in zip(plan_before['lessons'],plan['lessons']):
 if a['id']!=ID:assert a==b
 else:assert a['decision']==b['decision'] and a['baseline']==b['baseline']
dump(plan_path,plan);dump(O/'lesson-plan.json',row)
technical=f'''# Ant Colony — reconstruction and room evidence

## One carried operation

The previous tutorial used an unrelated travelling-tour graph and an undefined tour_length. It did not reconstruct the two-channel foraging exhibit. The new tutorial prints a complete model and host, carrying PointBody byte-for-byte from ABM and Boids. The carrying flag now selects one field to read and the other to write. Returning no longer steers directly toward a known home coordinate.

This lesson is a simplified foraging reconstruction. It is not the full AntColonyV2 simulation: it uses24 spheres, a16×16 field, deterministic starting headings and strict strongest-sample steering. It omits production diffusion, random wandering and collision-based destination Areas. Contact is a numerical distance check. We do not infer optimality from a bright path.

## The room is permanent

ant_colony_walk is registered at commons/artifacts/registry/ant_colony_walk.json and placed at cell8,8, yaw180°, scale1 in this hall's map_data.json and em_plan row. It replaces AntColonyV2:0:0:0.22 here; the original scene, algorithm and other placements are retained. All other runtime hall rows compare equal to the saved before state.

The field is12×12m, with controls on opposite ends, offset to keep the central doorway view open. Each model cell is0.75m.24 sphere bodies are0.51m across and move at0.8m height. Their mesh and collision radius are enlarged together; the RigidBody3D root remains unscaled. They are model-driven frozen pickables with mask0 and do not obstruct the walking route. Home and food rings have0.75m contact radius. A green cube indicates carrying and a gold ring identifies the selected witness.

Blue and rose strips are paired within each cell, not separate navigational lanes.512 strips are drawn by two MultiMeshInstance3Ds. Their surfaces sit above the supplied museum floor, removing the old coplanar/displaced display interference. The display is visual; the museum provides walking support. Controls are0.95m high. Holding any point pauses the whole model so the selected body can be moved without a chase; the held trigger selects the witness.

The initial control banks crossed the doorway view. Visual inspection led to moving each bank3.5m sideways and reducing nearby labels. Earlier captures remain in ada_run under aco-lesson and aco-final; the published images use the final exportable artifact run. No artificial diagram is presented as an engine image.

## Printed code and export copies

Study: doc/book/studies/swarm-through-the-hands/{ID}/study.tscn. The tutorial prints colony.gd, point_body.gd and study.gd in full, with carried/host files folded for reading. Students work in a copy of the prepared museum hall, replacing the existing artifact rather than superimposing a second one. There are no hidden dollar mesh references. The supplied button and XRTools dependencies are named explicitly.

Both existing export presets exclude doc/**. The permanent scene therefore inherits commons/artifacts/ant_colony_walk/study.gd with local colony.gd and point_body.gd dependencies. The test runner and publisher require these copies to be byte-identical to the study and exact extracted tutorial blocks. No doc path remains in the runtime dependency chain. An exported APK or desktop package was not built in this pass.

## Exact boundaries

16×16 periodic position/sample field;24 agents;0.05s tick;3cells/s speed cap;0.5s response;6cells/s² acceleration cap. Home(3,8), food(12,8), contact strictly less than1cell, tested before motion. Destination distance is direct, not a wrapped shortest distance. The maximum0.15cell movement per tick is less than the contact radius.

Contact reverses model velocity once, flips state and restores energy1. This is an explicit model event, not a physical collision. The ordinary bounded steering resumes between contacts. Equal samples keep heading; stationary points choose east while searching and west while returning. No random generator or global pathfinder is concealed here.

Every point reads old fields. All positions and velocities commit before either field is faded or written. Both retain99.5% per tick. Energy falls0.0025 each tick and stops at zero. Deposit is0.5×energy, capped at8. Searching deposits home; returning deposits food. Finally the home cell's home value and the food cell's food value are set to8; no other source cells are renewed. Food is inexhaustible.

Replace restores the24 agent records and energies, retaining both fields, tally and clock. Clear resets those records too while preserving retention and deposit settings. The visible empty fields are replenished at the two source cells on the next tick. Hold zeros velocity, preserves cargo/energy and pauses all ticks; both resets ignore a held point. Release returns it to the model's plane. The same scene instances survive these operations.

## Executed checks

{len(code['checks'])} checks pass in a fresh Godot4.6 process using code extracted from tutorial.md. They cover isolated channel reads/writes, unchanged opposite-channel deposits, saturation, evaporation, source renewal, energy decay, contact timing, one delivery, one reversal, wrapping, reset scopes, reversed traversal,2000 finite bounded ticks and an unassisted delivery cycle. The independent half-deposit edit produces0.25 directly and0.249375 after tick energy decay. Three faulty variants execute and fail the relevant expectations: wrong read channel, wrong write channel, and destructive population replacement.

The host checks instantiate actual XRTools pickup machinery under a translated/rotated host, move and release the same sphere, trigger selection, test held reset guards and verify visible cargo and channel captions. These are author-operated reconstruction tests, not an independent ghost-student or physical headset assessment.

{len(native['checks'])} native checks pass in the actual saved ACO museum hall. These include both control banks,24 bodies, two256-instance field batches,15 centre-route floor/clearance samples, eight control approaches, visible field elevation, replacement/reset scope and rendered rigid-body position across physics frames. The unassisted model has delivered9 items by tick260 in this capture. The receipt includes screenshot-camera checks. Actual player portal crossing, headset comfort and headset frame rate remain untested.

The final logs have no GDScript errors. They retain the project's pre-existing unrecognized resource UID and Jolt solver-bias warning. Neither is presented as repaired here. The sequence's referenced ant_colony_axioms.md and stigmergy_axioms.md are absent; no content was inferred from those missing files.

## Replay

1. python tools/write_swarm_aco.py
2. python tools/place_swarm_aco.py
3. python tools/test_swarm_aco.py
4. python tools/run_encounter_probe.py {ID} --sequence swarmintelligence --render --no-bridges --output-tag aco-exportable --probe tools/probes/swarm_aco_room.gd
5. python tools/publish_swarm_aco.py

The initial state is preserved under before/. The report includes complete texts, code, receipts, source hashes and real museum images. Next: Particle Swarm Optimization, hall6/7; retain this room-scale approach and the same sphere.
'''
write(M/'technical.md',technical)
write(A/'README.md','# Two trails underfoot\n\nPermanent12m walk-in colony,24 grabbable PointBodies, two-channel field. Scene: ant_colony_walk.tscn. Script copies are byte-identical to the printed learner code and validated by tools/test_swarm_aco.py. Runtime dependencies stay under commons/ because exports exclude doc/.\n\nRegenerate in order: write_swarm_aco.py → place_swarm_aco.py → test_swarm_aco.py. Then run the native room probe and publisher. See this hall\'s technical.md for units, simplifications and evidence limits.\n')
for folder in ['assets','museum','probes','tools','runtime','after']:(O/folder).mkdir(exist_ok=True)
for name in ['tutorial.md','final.md','technical.md']:
 shutil.copy2(M/name,O/name);shutil.copy2(M/name,O/'after'/name)
shutil.copy2(M/'map_data.json',O/'after/map_data.json')
for p in RUN.glob('*.png'):shutil.copy2(p,O/'assets'/p.name)
for p in BEFORE.glob('*.png'):shutil.copy2(p,O/'assets'/p.name)
for name in ['report.json','engine.log','source_manifest.json']:shutil.copy2(RUN/name,O/'museum'/name)
for name in ['swarm_aco_student.gd','swarm_aco_room.gd','swarm_aco_before.gd','transformation_encounters.gd']:shutil.copy2(R/'tools/probes'/name,O/'probes'/name)
for name in ['write_swarm_aco.py','place_swarm_aco.py','test_swarm_aco.py','publish_swarm_aco.py']:shutil.copy2(R/'tools'/name,O/'tools'/name)
for p in A.iterdir():
 if p.suffix in ['.gd','.tscn','.md']:shutil.copy2(p,O/'runtime'/p.name)
write(O/'changes.md','''# Ant Colony — before and after

| Before | Now |
| --- | --- |
| Tiny ants on a scaled field; trail surface intersects the museum floor. | 24 half-metre carried spheres over a clearly separated 12 m floor display. |
| An exhibit to inspect from its edge. | Walk among the bodies; hold a point to pause and relocate it. |
| No focused two-channel student reconstruction. | Complete printed model, carried PointBody and room host; the permanent artifact runs identical code. |
| Incomplete travelling-tour tutorial. | Read food/write home; contact switches read/write; no shortest-route claim. |
| Reset scope left implicit. | Replace bodies keeps both fields; Clear All clears them. |
| One display caption. | Selected-point readout, visible cargo, three samples and controls at both ends. |

The original AntColonyV2 implementation remains available. Only its placement in this hall is replaced. All other hall rows and execution-plan decisions are preserved. This is a saved museum installation, not a temporary screenshot-only student table.
''')
css=text(R/'doc/book/iterations/2026-10-10-swarm-a-trace-outside/style.css')+'table{border-collapse:collapse;width:100%;font:15px/1.5 system-ui}td,th{padding:12px;border-bottom:1px solid #ccc;text-align:left;vertical-align:top}details{background:#e5e9e8;padding:16px;margin:20px 0}summary{cursor:pointer;font-family:system-ui}.parallel article{overflow-wrap:anywhere}pre{tab-size:4}'
nav='<nav><a href="index.html">Walk-in colony</a><a href="parallel.html">Facing pages</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Changes</a><a href="technical.html">Evidence</a><a href="colony-review.zip">Review ZIP</a></nav>'
def render(md):return markdown.markdown(md,extensions=['fenced_code','tables','footnotes'])
def page(name,title,body,cls=''):
 write(O/name,'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style>'+nav+'<main class="'+cls+'">'+body+'</main></html>')
for name in ['tutorial','final','technical','changes']:page(name+'.html','Ant Colony · '+name,render(text(O/(name+'.md'))))
page('parallel.html','Ant Colony · tutorial beside reflection','<article>'+render(text(O/'tutorial.md'))+'</article><article>'+render(text(O/'final.md'))+'</article>','parallel')
page('before.html','Ant Colony · previous tutorial',render(text(O/'before/tutorial.md')))
def fig(name,caption):return '<figure><img loading="lazy" src="assets/'+name+'.png" alt="'+html.escape(caption)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
body=f'''<div class="tag">Endless Museum / Swarm Intelligence / 5 of 7</div><h1>Two trails underfoot</h1><p>A full-size colony to walk among. Twenty-four half-metre spheres carry the familiar point into a twelve-metre shared field.</p><p class="notice"><strong>Saved in the actual museum.</strong> Hold a point to pause and move it. Contact with food or home changes which trail it reads and which it leaves.</p>'''
body+=fig('eye-level','Actual Godot museum, at standing eye level. Blue and rose strips show separate home and food values; green cubes show carrying points.')
body+='<h2>One lesson carried onward</h2><p>'+html.escape(summary)+'</p><details><summary>Compressed instruction for the next pass</summary><p>'+html.escape(short)+'</p></details>'
body+='<p><a href="parallel.html">Complete tutorial on the left, reflection on the right</a> · <a href="SUMMARY.md">Summary file</a> · <a href="http://localhost:3003/tutorial-plan?map='+ID+'&amp;view=summaries">Editable lesson plan</a></p>'
body+='<h2>Stand inside the example</h2><div class="grid">'+fig('among-points','The spheres use the same PointBody class. Their geometry and grab shape are enlarged together.')+fig('carrying-close','The selected point has found food. It keeps its body, gains a visible carrying flag, reads home and leaves food.')+'</div>'
body+='<h2>The room, before and after</h2><div class="grid">'+fig('eye-before','Before: small ants; the displaced field intersects the floor and breaks up the trail image.')+fig('eye-level','After: readable floor fields and bodies large enough to meet at the scale of your hand.')+'</div>'
body+='<div class="grid">'+fig('above-before','Before from above: a scaled colony occupies the centre.')+fig('above-after','After from above: a 12 m field, clear centre route and offset controls at both ends. The hall architecture is retained.')+'</div>'
body+='<h2>Two different beginnings</h2><div class="grid">'+fig('trails-kept','REPLACE POINTS restores the starting population and retains every value in both fields.')+fig('clear-all','CLEAR ALL clears both traces, deliveries and clock. Source cells replenish only on the next tick.')+'</div>'
body+=fig('controls','Both banks operate the same model. These controls remain close to the field; holding a sphere pauses it wherever you stand.')
body+=f'''<h2>Code that was actually run</h2><p><strong>{len(code['checks'])} printed-code checks and {len(native['checks'])} native museum checks pass.</strong> The code test includes an independent half-deposit edit and three executed faulty versions. The room test checks the permanent installation, actual control signals, walking support, clearance and rendered positions.</p><p>Images are engine captures. The source scripts printed in the tutorial match the scripts in the museum. Physical headset comfort and performance have not been tested.</p><p><a href="technical.html">Evidence, simplifications and replay</a> · <a href="changes.html">Changes per hall</a> · <a href="before.html">Previous tutorial</a> · <a href="colony-review.zip">Download review ZIP</a></p><p class="meta">Next: Particle Swarm Optimization. Keep the full-size point; add a remembered best position and a stated way of scoring it.</p>'''
page('index.html','Ant Colony · two trails underfoot',body)
write(O/'README.md','# Ant Colony review\n\nOpen index.html or parallel.html. Full tutorial, reflection, exact extracted code, runtime copies, actual Godot before/after/overhead images and test receipts. Requires the prepared Ada museum/XRTools environment. Permanent room-scale installation; no physical headset or independent ghost-student certification.\n')
dump(O/'source-check.json',{'same_point_class_as_ABM':True,'runtime_equals_printed':True,'other_runtime_rows_unchanged':True,'other_execution_rows_unchanged':True,'decisions_preserved':True,'permanent':True,'tutorial_sha256':code['tutorial_sha256'],'museum_source_manifest':'museum/source_manifest.json'})
handoff=R/'doc/book/course/storyboards/SWARM-HANDOFF.md'
write(handoff,f'''# Swarm / 10 October2026 / five halls complete

Latest: ACO, doc/book/iterations/2026-10-10-colony-two-trails-underfoot/index.html. Full tutorial/final/parallel, SUMMARY.md, colony-review.zip. {len(code['checks'])} printed-code/{len(native['checks'])} native checks pass. Next: SwarmIntelligence_Particle_Swarm_Optimization6/7; then SwarmIntelligence_Swarm_Intelligence_Algorithms7/7.

USER STEERING: wants full-size permanent examples to stand among, like Boids. Keep this scale for remaining halls. Same PointBody lineage; museum already exists. Do not create only temporary mini tables. One primary tutorial operation, completeprintedcode and separate encounter reflection. Actual native images including overhead. No physical headset/independent learner claim from synthetic checks.

ACO permanent ant_colony_walk replaces AntColonyV2 atcell8,8,yaw180,scale1 in map+em_plan only. Original AntColonyV2 source/registry preserved elsewhere. Same PointBodybyteforbyte asABM; host triplesmesh/grabshape rootunscaled.24points,.51mdiameter,.8mheight;12mfield/.75mcell; two256-instance MultiMeshes; buttons .95mhigh, z±6.5,bankx∓3.5. Noarchitecturechange. Nativefloor/clearancecentre15+controls8 pass. Twochanneldisplayabovefloor fixesoldintersection.9deliveries by260ticks.

Model colony.gd:16²periodic;.05s;speed3;response.5;accelcap6. SEARCHreadfood/writehome; RETURNreadhome/writefood. Contactbeforemotion<1cell HOME3,8FOOD12,8 flipsflag,reversesv,energy1. Threeoldsamples/tiesstraight/stationaryfallbackE/W. Commitallmotion; fade.995; deposit.5*energy cap8; sourceowncell8. Energy−.0025/tick. No diffusion/randomness/collisionants/finitefood/optimalityclaim. Replacekeepsfieldstallyclock; Clearresetrecords retainsparams. Holdpauseall/relocate/zerov preservecarryenergy; heldtriggerselect; resetsignoredheld. Independenthalfdeposit.25direct/.249375tick; wrongread/write/destructivereplace executedanddetected; syntheticXRundertransform.42checks.

Source study: doc/book/studies/swarm-through-the-hands/{ID}/{{colony.gd,point_body.gd,study.gd,study.tscn}}. Runtimecopies undercommons/artifacts/ant_colony_walk; wrapperextendslocalstudy.gd because BOTH exportpresets excludedoc/**. Runner/publisherassertexactequality. APKnotbuilt. Nativefinaltagaco-exportable (earlieraco-lesson/aco-final retained). NoGDScripterrors; existingUID/Joltwarningspersist. Canonicaltutorial/final/technical and ownexecutionplanrow updated, decisions/baselines/allotherrowspreserved.

Replay: write_swarm_aco.py → place_swarm_aco.py → test_swarm_aco.py → run_encounter_probe.py {ID} --sequence swarmintelligence --render --no-bridges --output-tag aco-exportable --probe tools/probes/swarm_aco_room.gd → publish_swarm_aco.py. Keep huge unrelateddirtytree. Noagents/commits/reverts. Missing ant_colony_axioms/stigmergy_axioms paths were noted, no inventedcontents.

## Previous record (status superseded above)

'''+text(O/'before/SWARM-HANDOFF.md'))
with zipfile.ZipFile(O/'colony-review.zip','w',zipfile.ZIP_DEFLATED) as z:
 for p in O.iterdir():
  if p.is_file() and p.suffix in ['.md','.html','.json','.log']:z.write(p,p.name)
 for folder in ['printed','variation','fault-read','fault-write','fault-replace','assets','museum','runtime','tools','probes','after']:
  for p in (O/folder).rglob('*'):
   if p.is_file() and p.suffix!='.uid':z.write(p,p.relative_to(O))
 for name in ['tutorial.md','final.md','map_data.json']:z.write(O/'before'/name,'before/'+name)
with zipfile.ZipFile(O/'colony-review.zip') as z:assert z.testzip() is None
print(f'Published ACO: {len(code["checks"])} code / {len(native["checks"])} native; permanent walk-in installation.')
