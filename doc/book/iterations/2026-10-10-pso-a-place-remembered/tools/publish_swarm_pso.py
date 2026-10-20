"""Publish the saved PSO encounter, not a screenshot-only reconstruction."""
from pathlib import Path
import json,html,re,shutil,hashlib,zipfile
import markdown
R=Path(__file__).resolve().parents[1];ID='SwarmIntelligence_Particle_Swarm_Optimization'
O=R/'doc/book/iterations/2026-10-10-pso-a-place-remembered';M=R/'commons/maps'/ID
S=R/'doc/book/studies/swarm-through-the-hands'/ID;A=R/'commons/artifacts/particle_swarm_walk'
RUN=R/'ada_run/encounter_pilot'/ID/'pso-ready';BEFORE=RUN.parent/'pso-before'
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
assert (S/'point_body.gd').read_bytes()==(S.parent/'SwarmIntelligence_Ant_Colony_Optimization/point_body.gd').read_bytes()
summary='''Walk among the same PointBody spheres on a twelve-metre score field. Carry position and weighted motion, but exchange Ant Colony's shared trail for personal and shared best-position records. Evaluate the starting population, predict one movement from inertia and two pulls, then hold a point elsewhere and watch its remembered place remain. Release and step to evaluate the new candidate. Change CENTER to EDGE or RIDGE: current bodies and velocities stay, while memories restart under the new rule. Independently remove the social pull and test the predicted displacement. Keep novelty's changing archive as a rear comparison, without claiming that the best found is a proven optimum. Carry the distinction between a shared trace, a neighbour and a scored record into the final Swarm hall.'''
short='''PSO6/7. Permanent12mfield/24 PointBodies51cm,rootunscaled,0.8mhigh; startsPAUSED. SamePointBodyasACO. No carryflag/trail; personalbest(position,score),sharedbest. MaximizeCENTER=-r²,EDGE=+r²,RIDGE=-(x-y)²/2. Evaluateinitialall. Step: scorehandcandidates; snapshotshared; v=.6v+1.5r1(pbest-p)+1.5r2(gbest-p); cap.35; bounded±6; stopoutwardcomponent; commitall; remember. Strict>; tiesretain. Displacement/iteration; playback.1s; seed101006. Holdpauseall/zerov/movelocal/retainmemory; triggerselect; release+step evaluates. Objectivechange keepsp/v/tick/RNG, resetsmemories/pauses. Restart resetsseed/population/memories/tick; keepsobjective/coeffs. White=current;blue=personal;gold=shared. Cylinders=unweighted position differences. Zero-social variation predicts(.185,.1). Printed=study=runtime. No globaloptimum/physical-force/headsetclaim. Existingnovelty+selforgrearcomparison. Nextcapstone compareinformation supports.'''
write(O/'SUMMARY.md','# Particle Swarm — one paragraph\n\n'+summary+'\n\n## Compressed instruction\n\n'+short+'\n')
plan_path=R/'doc/book/course/execution-plan/plan.json';plan=read(plan_path);before_plan=read(O/'before/execution-plan.json')
row=next(x for x in plan['lessons'] if x['id']==ID)
row.update(summary=summary,object='The carried grabbable PointBody, its personal best position/score and a shared best record, in a permanent12m field.',
 change='A declared score chooses which position to remember. The same population can be judged by another objective; old best records then restart.',
 reuses='Unchanged PointBody from ACO, position, velocity, vector differences, weighted sums, seeded randomness, arrays, hold-to-pause and scoped resets.',
 given='Endless Museum player, floor, camera, light, XRTools and push_button.tscn. Complete swarm model, carried PointBody and host are printed; permanent runtime copies match.',
 later='Novelty archive is a separate existing comparison; higher-dimensional search, performance tuning and optimum guarantees are outside this first model.',
 checks=[f"{len(code['checks'])} exact printed-code checks: initial scoring, old shared snapshot, objective reset, independent zero-social variation, three executed faulty variants, synthetic XR and connector endpoints.",f"{len(native['checks'])} native room/capture checks: saved full-size instance,21 central walking samples,12 control approaches, score display, state retention and rear comparisons."],
 transfer='Set social_pull=0.0. With p(.2,.1),v(.1,0),pbest(.1,.1),gbest(0,0),r1=.5,r2=.25, nextp(.185,.1), compared with(.11,.0625). Predict before executing.',
 carry='Accountable position/score pairs; shared records differ from trails and neighbours. A score depends on a stated objective.',
 next='Final Swarm Intelligence Algorithms hall: compare what the same body reads, stores and leaves; retain full-size primary encounters.',
 notes='Implemented for review; approval decision retained. Fresh Godot tests and native images, not physical-headset or independent learner certification. See doc/book/iterations/2026-10-10-pso-a-place-remembered/index.html. Full code ends false optimum promise and unevaluated initialization. Existing novelty algorithm preserved.')
for a,b in zip(before_plan['lessons'],plan['lessons']):
 if a['id']!=ID:assert a==b
 else:assert a['decision']==b['decision'] and a['baseline']==b['baseline']
dump(plan_path,plan);dump(O/'lesson-plan.json',row)
technical=f'''# Particle Swarm — reconstruction and evidence

The primary operation is remembering a position because it earned a score. The same PointBody class travels from ACO unchanged. Its previous carry flag and shared trail are not retained in this optimizer: continuity belongs to the object and learned tools, not to accumulating every earlier behavior.

## What changed

The previous tutorial offered disconnected Rastrigin/particle snippets, began moving toward an unevaluated global record, left global reset incomplete and promised the global minimum. The replacement prints complete executable code and teaches one fixed objective before introducing objective changes. The model uses the same three fixed objective ideas as the existing display, with squared-distance scores and simultaneous shared-record updates. It is an explicit teaching variant, not a claim that the original algorithm is reproduced byte-for-byte.

The map expands from13×11 to17×23. Interior partitions are removed. particle_swarm_walk stands at cell8,9, yaw180, scale1. Existing fitness_landscape_politics and self_organizing_patterns move to4,19 and12,19; tick_flock becomes a wall-margin plate at1,13. The duplicate ant_colony_v2 placement is removed from this hall; its source is preserved, and the previous hall remains the full-size colony encounter. The original before run instantiated only3 of its4 authored placements. Final native run finds the new primary artifact and both rear comparisons.

Only this map and its em_plan row are changed. The publisher asserts equality for every other hall row. It also updates only this execution-plan lesson and preserves its decision and baseline hashes.

## Model boundary

24 candidates; model coordinates[-6,6]²; starting scatter[-5.5,5.5]²; seed101006. CENTER=-squared radius; EDGE=+squared radius; RIDGE=-(x-y)²/2. Larger scores win. The coordinates map to local(x,0.8,-y), one unit per metre. The coloured floor is flat and shows a sampled score, not a physical height field or pheromone.

Initial candidates are scored before movement. Each personal best is a position/score pair. Strict greater-than retains the earlier position on ties. Before an iteration, hand-placed candidates are evaluated. Then every point sees one snapshot of shared best. Inertia0.6 plus personal/social coefficients1.5, each pull with its own uniform random scalar, produces a displacement capped at0.35 per iteration. Positions commit together; memories are evaluated afterward. Boundary crossing clamps position and zeros the outward velocity component. No wrapping, collision avoidance, physical mass or force integration is implied.

Playback is ten iterations per second, starts paused, and caps a single frame's accumulated time at0.5s. Under long rendering stalls this is a slowed demonstration, not real-time physical integration. Restart resets the seed, population, records and iteration count but retains objective and coefficients. Objective change preserves position, velocity, clock and random stream; it resets records to the current candidates and pauses. Neither action runs while a point is held.

Holding pauses every candidate, zeros the held point's velocity, records its position in the host's local plane, and retains its previous best. Release alone is not a scored iteration; the next step evaluates the current candidate before calculating its motion. If Run was active before pickup, release resumes playback. A held trigger selects the witness. White ring=current selected body, blue=personal best, gold=shared best. The two thin cylinders show unweighted position differences, not random weighted forces or future trajectories.

Original fitness_landscape_politics is retained unchanged as a smaller contextual exhibit: its scores use ordinary distance, motion updates sequentially and NOVELTY compares an evolving bounded archive. The new lesson's full source covers fixed objectives and explicit objective reset. Its reflection discusses the archive as a comparison, not a hidden dependency.

## Runtime and printed source

Study: doc/book/studies/swarm-through-the-hands/{ID}/study.tscn. Runtime: commons/artifacts/particle_swarm_walk/particle_swarm_walk.tscn. Both export presets exclude doc/**, so the permanent scene inherits local runtime copies. All three scripts are byte-identical to the study and to the fenced blocks extracted from canonical tutorial.md. The copied PointBody itself is unchanged from ACO. Its visual child and spherical grab collision are enlarged together to0.51m diameter; its rigid-body root stays unscaled. Rendering uses one256-cell MultiMesh,24 spheres, three rings and two cylinders.

The museum and XRTools are explicit prerequisites. The example does not supply a player or lighting in an empty standalone Godot project. The review ZIP contains the study files; reconstruct inside a working copy of the prepared hall and replace the installed example. No APK or packaged desktop export was built here.

## Evidence and repairs

**{len(code['checks'])} fresh printed-code checks pass.** They include exact numerical scores and velocity contributions, an independent zero-social edit, deterministic replay,1800 bounded iterations across the three objectives, boundary behavior, tie retention and objective-scoped records. Three faulty programs are executed: unevaluated initial scores, stale records on objective change, and sharing a new discovery halfway through an iteration. A designed two-point fixture catches the last fault; the same fixture passes against the printed model. Synthetic XRTools pickup/release runs under a translated and rotated host. It verifies retained memory, local coordinates, trigger selection, reset guards and evaluation after release.

The first code pass exposed weaknesses in two test expectations: headless rendering does not provide usable GPU colour readback, and negative zero formats as -0.00. Field colours are therefore asserted in the rendered native run; memory markers are checked against their actual coordinates. A cylinder transform error found during visual inspection was corrected and now has an endpoint assertion.

**{len(native['checks'])} native saved-room and capture checks pass.** Twenty-one centre-route samples and twelve control approaches have physical floor support and capsule clearance. These are samples, not an exhaustive navigation proof. Actual button signals change the model and the displayed objective. The first arrangement put front controls too near the wall; moving the main field inward then revealed an overlap with the rear comparison controls. The latter moved back one metre. Earlier failed spatial reports remain under pso-lesson and pso-final; the published run is pso-ready.

Eye-level, overhead, displaced-memory, EDGE, RIDGE, control and comparison images are actual Godot captures. The displaced-memory image uses a scripted placement equivalent to the separately tested hand action; it is not a photograph of a headset session. The native probe also verifies rendered frozen bodies remain aligned to their model after physics frames.

No GDScript errors in final code or native logs. Existing project UID and Jolt solver-bias warnings remain. No physical-headset comfort, Quest performance, real controller tracking, independent ghost student, global optimum or actual portal-crossing certification is claimed.

Replay: python tools/write_swarm_pso.py; python tools/place_swarm_pso.py; python tools/test_swarm_pso.py. Then run tools/run_encounter_probe.py {ID} --sequence swarmintelligence --render --no-bridges --output-tag pso-ready --probe tools/probes/swarm_pso_room.gd, and python tools/publish_swarm_pso.py.
'''
write(M/'technical.md',technical)
for folder in ['assets','museum','probes','tools','runtime','after']:(O/folder).mkdir(exist_ok=True)
for name in ['tutorial.md','final.md','technical.md']:
 shutil.copy2(M/name,O/name);shutil.copy2(M/name,O/'after'/name)
shutil.copy2(M/'map_data.json',O/'after/map_data.json')
for p in RUN.glob('*.png'):shutil.copy2(p,O/'assets'/p.name)
for p in BEFORE.glob('*.png'):shutil.copy2(p,O/'assets'/p.name)
for name in ['report.json','engine.log','source_manifest.json']:shutil.copy2(RUN/name,O/'museum'/name)
for name in ['swarm_pso_student.gd','swarm_pso_room.gd','swarm_pso_before.gd','transformation_encounters.gd']:shutil.copy2(R/'tools/probes'/name,O/'probes'/name)
for name in ['write_swarm_pso.py','place_swarm_pso.py','test_swarm_pso.py','publish_swarm_pso.py']:shutil.copy2(R/'tools'/name,O/'tools'/name)
for p in A.iterdir():
 if p.suffix in ['.gd','.tscn']:shutil.copy2(p,O/'runtime'/p.name)
write(O/'changes.md','''# Particle Swarm — before and after

| Before | Now |
| --- | --- |
| Internal walls obscure the small display. | Open17×23m hall;12m primary field; rear comparisons. |
| Unrelated incomplete Rastrigin fragments. | Complete scored-position model using the carried PointBody. |
| A global best is assumed before being evaluated. | Initial population evaluated; score and position paired. |
| Reset and update order unclear. | Shared record held fixed for each iteration; reset scope visible. |
| Convergence to the global optimum promised. | Best encountered under a stated objective; no guarantee. |
| Objects inspected from outside. |24 half-metre grabbable points; hold to pause, relocate and inspect memory. |
| One room mixes duplicate ant content and several controls. | Primary lesson first; original novelty and self-organization comparisons beyond. |

Both tutorial.md and final.md are updated. Tutorial reconstructs the operation in runnable code; reflection asks what a score permits and excludes. Museum instances run exact copies of the printed scripts. Other hall rows and approval decisions remain unchanged.
''')
css=text(R/'doc/book/iterations/2026-10-10-swarm-a-trace-outside/style.css')+'table{border-collapse:collapse;width:100%;font:15px/1.5 system-ui}td,th{padding:12px;border-bottom:1px solid #ccc;text-align:left;vertical-align:top}details{background:#e5e9e8;padding:16px;margin:20px 0}summary{cursor:pointer;font-family:system-ui}.parallel article{overflow-wrap:anywhere}pre{tab-size:4}'
nav='<nav><a href="index.html">The room</a><a href="parallel.html">Facing pages</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Changes</a><a href="technical.html">Evidence</a><a href="pso-review.zip">Review ZIP</a></nav>'
def render(md):return markdown.markdown(md,extensions=['fenced_code','tables','footnotes'])
def page(name,title,body,cls=''):
 write(O/name,'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style>'+nav+'<main class="'+cls+'">'+body+'</main></html>')
for name in ['tutorial','final','technical','changes']:page(name+'.html','Particle Swarm · '+name,render(text(O/(name+'.md'))))
page('parallel.html','Particle Swarm · tutorial beside reflection','<article>'+render(text(O/'tutorial.md'))+'</article><article>'+render(text(O/'final.md'))+'</article>','parallel')
page('before.html','Particle Swarm · previous tutorial',render(text(O/'before/tutorial.md')))
def fig(name,caption):return '<figure><img loading="lazy" src="assets/'+name+'.png" alt="'+html.escape(caption)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
body='<div class="tag">Endless Museum / Swarm Intelligence / 6 of 7</div><h1>A place remembered</h1><p>Twenty-four familiar spheres in a twelve-metre field. Each remembers a place; the group shares a scored discovery.</p><p class="notice"><strong>Saved in the museum.</strong> Start paused, walk among the points, then set the rule in motion. Hold one away from the others: its memory stays visible.</p>'
body+=fig('eye-level','Actual Godot museum at eye level, after six iterations. Black and pale spheres retain the PointBody construction; the floor shows scores, not traces.')
body+='<h2>What this hall adds</h2><p>'+html.escape(summary)+'</p><details><summary>Compressed instruction</summary><p>'+html.escape(short)+'</p></details><p><a href="parallel.html">Full tutorial left, reflection right</a> · <a href="SUMMARY.md">One-paragraph summary</a> · <a href="http://localhost:3003/tutorial-plan?map='+ID+'&amp;view=summaries">Editable lesson plan</a></p>'
body+=fig('memory','One point has been placed away from its earlier answer. White follows the body, blue marks its personal best, gold marks the shared best. Cylinders show the position differences.')
body+='<h2>One population, another question</h2><div class="grid">'+fig('edge','EDGE rewards squared distance from the centre. Points can succeed at the same corner; it does not measure diversity.')+fig('ridge','RIDGE rewards the diagonal. Many positions have equal value, yet the shared history can still gather points in one place.')+'</div>'
body+='<h2>Before and after</h2><div class="grid">'+fig('eye-before','Before: partitions hide much of the small display.')+fig('eye-level','After: the primary operation occupies the room at the scale of the visitor.')+'</div><div class="grid">'+fig('above-before','Before: intersecting internal walls and isolated artifacts.')+fig('above-after','After: open primary field, control banks at its ends and rear comparisons. The centre route remains clear.')+'</div>'
body+='<h2>Inspect, then continue</h2>'+fig('controls','Both banks control the same model. Grabbing pauses it anywhere; the held trigger selects the point whose record is shown.')+fig('comparisons','The original smaller objective display remains beyond the large field, alongside the self-organization comparison.')
body+=f'<h2>Executed evidence</h2><p><strong>{len(code["checks"])} printed-code checks and {len(native["checks"])} native room/capture checks pass.</strong> The independent change removes the social pull. Three faulty versions are executed and rejected. The room test checks walking support, control approaches, live state changes and rendered positions.</p><p>Printed source, study and permanent runtime copies match. Images are Godot captures. Physical headset comfort and performance still need a player test.</p><p><a href="technical.html">Exact scope and replay</a> · <a href="changes.html">Change summary</a> · <a href="pso-review.zip">Download the complete review ZIP</a></p><p class="meta">Next: the final Swarm hall. Compare what a body reads, remembers and leaves.</p>'
page('index.html','Particle Swarm · a place remembered',body)
write(O/'README.md','# Particle Swarm review\n\nOpen index.html or parallel.html. Complete tutorial and reflection, runnable extracted scripts, runtime copies, actual native images and test receipts. Requires the prepared Ada museum/XRTools environment. Not a standalone empty Godot project. No physical headset or independent learner certification.\n')
dump(O/'source-check.json',{'same_point_as_ACO':True,'runtime_equals_printed':True,'other_runtime_rows_unchanged':True,'other_execution_rows_unchanged':True,'decisions_preserved':True,'permanent':True,'tutorial_sha256':code['tutorial_sha256'],'museum_source_manifest':'museum/source_manifest.json'})
write(R/'doc/book/course/storyboards/SWARM-HANDOFF.md',f'''# Swarm / 10 October2026 / six halls complete

Latest: PSO, doc/book/iterations/2026-10-10-pso-a-place-remembered/index.html. Full tutorial/final/parallel, SUMMARY.md,pso-review.zip. {len(code['checks'])} printed-code/{len(native['checks'])} native checks pass. Next: SwarmIntelligence_Swarm_Intelligence_Algorithms7/7. Continue full-size permanent encounters.

USER: same carried PointBody, museum already exists, whole runnable printed code, focused lesson + separate reflection, actual eye/above views. Onehallatatime. Noindependentghost/headsetclaimfromsyntheticchecks. Noagents/commits/reverts; preservehugeunrelateddirtytree.

{short}

Permanent particle_swarm_walk runtimecopieslocal (exportsexcludedoc). Registered; map+onlyem_planrow17x23flat, nointernalwalls; at8,9yaw180scale1. Controls z±6.7,x∓3.2,y.95,6buttons each. Originalfitness4,19yaw180;selforg12,19yaw180offset.65scale.35;tickwall1,13yaw90offset1.4. Removedduplicateant_colony_v2placementonly. Otherrows/decisions/baselinesassertunchanged. FullsizefieldstartsPAUSEDtocounterinstantclustering.

Tests:39 exactprinted,zero-social independentedit,3executedfaults(initialscores/objectivereset/asynchronousshared); syntheticXRtranslatedrotatedhost. Native23 including21centre/12controlapproaches. Earlypso-lessonwallconflict;pso-finalrearbuttonconflict; fixedmoveprimary+1z,rearcomparisons+1z. Cylinderlengthtransformfixed/endpointtested. Finaltagpso-ready;code/nativefreeofSCRIPTERROR,existingUID/Joltwarnings. Screenshotsreviewed. NoAPK/headset/portal-crossingclaim.

Replay: write_swarm_pso.py→place_swarm_pso.py→test_swarm_pso.py→run_encounter_probe.py {ID} --sequence swarmintelligence --render --no-bridges --output-tag pso-ready --probe tools/probes/swarm_pso_room.gd→publish_swarm_pso.py. Publisherwritesonlyownlessonplanrow;decisiondraftretained.

## Previous record (status superseded above)

'''+text(O/'before/SWARM-HANDOFF.md'))
with zipfile.ZipFile(O/'pso-review.zip','w',zipfile.ZIP_DEFLATED) as z:
 for p in O.iterdir():
  if p.is_file() and p.suffix in ['.md','.html','.json','.log']:z.write(p,p.name)
 for folder in ['printed','variation','fault-initial','fault-objective','fault-shared','assets','museum','runtime','tools','probes','after']:
  for p in (O/folder).rglob('*'):
   if p.is_file() and p.suffix!='.uid':z.write(p,p.relative_to(O))
 for name in ['tutorial.md','final.md','map_data.json']:z.write(O/'before'/name,'before/'+name)
with zipfile.ZipFile(O/'pso-review.zip') as z:assert z.testzip() is None
print(f'Published PSO: {len(code["checks"])} code / {len(native["checks"])} native. Six of seven Swarm halls complete.')
