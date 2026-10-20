"""Package the fourth Swarm hall without rewriting other lesson decisions."""
from pathlib import Path
import json,html,re,shutil,hashlib,zipfile
import markdown
R=Path(__file__).resolve().parents[1];ID='SwarmIntelligence_Agent_Based_Modeling_ABM'
O=R/'doc/book/iterations/2026-10-10-abm-what-the-point-carries';M=R/'commons/maps'/ID
S=R/'doc/book/studies/swarm-through-the-hands'/ID
RUN=R/'ada_run/encounter_pilot'/ID/'abm-lesson';BEFORE=RUN.parent/'abm-before'
def text(p):return p.read_text(encoding='utf8')
def read(p):return json.loads(text(p))
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(s.encode('utf8'))
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
code=read(O/'checks.json');native=read(RUN/'report.json')
assert code['passed'] and code['completed'] and native['passed'] and native['completed']
assert 'SCRIPT ERROR' not in text(O/'code.log') and 'SCRIPT ERROR' not in text(RUN/'engine.log')
assert code['tutorial_sha256']==hashlib.sha256(text(M/'tutorial.md').encode()).hexdigest()
for name,source in re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',text(M/'tutorial.md'),re.S):
 assert source+'\n'==text(S/name)==text(O/'printed'/name)
old=read(O/'before/em_plan.json');now=read(R/'commons/data/museum/em_plan.json')
assert old.keys()==now.keys() and len(old['plans'])==len(now['plans'])
for a,b in zip(old['plans'],now['plans']):
 if a.get('map')!=ID:assert a==b
assert (S/'point_body.gd').read_bytes()==(R/'doc/book/studies/swarm-through-the-hands/SwarmIntelligence_Boids_Algorithm/point_body.gd').read_bytes()
summary='''In the ABM hall, follow one point reaching food and returning to the nest. Carry the same PointBody, velocity and bounded steering from Boids, plus Physarum's three trail samples. Add one Boolean: searching points read the shared trace; carrying points request home and deposit. At each contact, predict which state and response the next tick will use. Hold the point, place it by food, release and step; move that same carrying body home and count one delivery. Replace the agent records while retaining the field, then clear both. Independently halve return speed and predict the first velocity and position. Carry the state transition and reset distinction into the next colony's separate home and food channels.'''
short='''ABM: same PointBody; six planar agents. Add carrying bool. SEARCH: three old-field samples, strongest wins/ties straight; food contact→RETURN. RETURN: known home, deposit; home contact→deliver once, SEARCH/east launch. Contact<1cell before motion. Bounded steering retained. Commit bodies, fade .92/tick, deposit returners +1 cap8. Infinite food; no collision/quality/recruitment; not full colony. Hold pauses/relocates/zerosv, preservescargo; trigger selects. Replace records keeps field/tick/delivered; ClearAll clears them, keeps parameters. Predict; half return speed; test faults. Next two channels. Museum supplied; exact printed code; no physical headset/independent learner claim.'''
write(O/'SUMMARY.md','# ABM — one paragraph\n\n'+summary+'\n\n## Compressed instruction\n\n'+short+'\n')
ep=R/'doc/book/course/execution-plan/plan.json';plan=read(ep)
row=next(x for x in plan['lessons'] if x['id']==ID)
row.update(summary=summary,object='The same PointBody with a visible carrying flag and one shared trace.',
 change='Contact switches searching/returning behaviour; distinguish replacing agent records from clearing shared history.',
 reuses='Unchanged PointBody from Boids; bounded steering, velocity and old/next state; Physarum three samples and shared scalar field.',
 given='Prepared museum, player, camera, lights, XRTools and explicit push_button.tscn. Complete model, PointBody and host printed.',
 later='Separate home/food channels in the next hall. Finite food, quality, random wandering and recruitment remain production exhibit context.',
 transfer='Halve return_speed to1.5. At(8,8), v0, carrying: predict v(-.15,0) and position(7.9925,8), then execute.',
 carry='PointBody, explicit carry state, destination contact, state-dependent reading/writing, shared field and scoped reset.',
 next='SwarmIntelligence_Ant_Colony_Optimization: same body/state; separate home and food channels, read one/write the other.',
 checks=[f"{len(code['checks'])} exact printed-code checks; half-speed variation; three executed faulty models detected; synthetic XR pickup/trigger/release.",f"{len(native['checks'])} native checks including existing colony reset, learner controls, rendered body position, central route clearance, before/after captures."],
 notes='Implemented review draft. Same sphere class byte-identical. Learner scene supplied and temporarily inserted in the native captures, not a new registered exhibit. ABM-only spatial changes: five interior wall seeds removed, colony rotated180, exit marker moved to perimeter6,9. Pre-existing physarum_colony token still has no living scene. No headset or independent-student claim.')
dump(ep,plan);dump(O/'lesson-plan.json',row)
warnings=[s for s in text(RUN/'engine.log').splitlines() if 'blocked ' in s and 'exit' in s]
technical=f'''# ABM — reconstruction and evidence

## What is now taught

The previous tutorial introduced unrelated FORAGING/FOLLOWING/RESTING states with undeclared dominant_state and initialise_swarm helpers. The replacement teaches a state change visible in the existing foraging exhibit: collect, return, deliver. Boids was already an agent-based model; adding a Boolean is a new behaviour, not the definition of ABM.

All three student scripts are printed in tutorial.md. PointBody is byte-identical to Boids. The host constructs the display and uses the explicitly supplied museum/XRTools/button environment. No hidden sphere scene or dollar reference. The study is saved at doc/book/studies/swarm-through-the-hands/{ID}/study.tscn. Add it to a working Node3D in the prepared Ada museum. The report's native placement is map position(8.8,0,6.5), yaw−90°; it is temporary, not registered as another production artifact.

## Actual code execution

{len(code['checks'])} checks pass in a fresh Godot4.6 process. The runner extracts the three marked blocks from canonical tutorial.md, compares them with source files, writes printed copies, then runs those copies. It checks contact timing, pickup without instantaneous reversal, single delivery, search-only sensing, return-only deposition, saturation, wrapping, finite bounded movement, reversed traversal, full reset replay, and both reset scopes. A self-running arrangement completes a delivery cycle.

The independent return-speed edit produces the stated first velocity and position. Three faulty variants are executed: never acquiring food, erasing the field during replacement, and counting delivery repeatedly. Each violates its relevant condition. Actual button signals and synthetic XRTools pickup/trigger/release are exercised under a translated, rotated host. The sphere instance is retained through resets and interactions. This is author-operated reconstruction evidence, not an independent student or a physical headset assessment.

The first harness run called max() directly on a PackedFloat32Array, which Godot does not provide. The harness now converts that value to Array for the maximum check. The student model needed no correction for this error. Final logs retain the project's existing unresolved resource UID and Jolt solver-bias warning; no GDScript errors remain.

## Exact model boundaries

Six points;16×16 periodic plane;0.16m/cell;0.05s tick;3cells/s maximum speed;0.5s response;6cells/s² acceleration cap. Home(3,8), food(12,8), strictly less than1cell for contact, checked before movement. Sampling positions and movement wrap; destination distance is direct, not shortest distance across the seam. The default contact radius exceeds the maximum0.15cell step; independently changing those parameters could allow a point to skip the ring.

Searching reuses the three samples. Returners ignore them and know the home coordinate. Returning points deposit after all movement commits and after92% retention. A new pickup deposits this tick; a delivery does not. Delivery requests east for one tick, then search sampling resumes. A stationary searcher also uses east as its fallback. Food is inexhaustible and therefore needs no shared stock allocation. The points can overlap; frozen XR bodies represent a planar model, not a collision-based ant simulation. There is no shortest-path guarantee.

Replace restores the six position/velocity/carry records but retains field, deliveries and tick count. Clear All clears those shared records as well. Both preserve retention and return_speed. While held, all ticks pause and the held velocity is zeroed; cargo persists. Reset and replacement ignore input while any point is held. The held trigger chooses the witness, not a new state. Model food is acquired by contact on a tick.

## Native museum checks

{len(native['checks'])} checks pass. The actual colony still has40 agents and its original simulation. Population replacement retains a seeded mark and full reset clears it. The learner controls trigger pickup, draw cargo, preserve the exact field on replacement and clear it on full reset. The rendered rigid sphere is checked across physics frames; the normal host update stays active during capture. An earlier paused-host capture showed stale rigid-body rendering despite a correct model position; that investigation is preserved, not presented as final evidence.

The initial room had five isolated authored wall cells that generated obstructing cross-room runs. Removing those five seeds opens the floor between displays. The existing colony faces180° so its projection is no longer backed by the optional navigator. The next marker moves from7,7 to the existing south perimeter opening6,9. Map data and this hall's em_plan row agree; every other runtime hall row is unchanged. The final log {'still reports a blocked exit' if warnings else 'does not report a blocked exit'}. Capsule probes test floor and body clearance along ten centre-route samples, plus the working approach; two rays test the label and far grid. This does not test a physical player crossing the portal.

An initial study position put its Run button in the centre route. Moving the temporary study0.8m east cleared it. Native images were visually inspected after these repairs. The pre-existing lower-case physarum_colony token has no living scene in this hall; the log records5 of6 requested placements. This is not a regression from the spatial edits and is not counted as a working exhibit here. The original colony and navigator remain present; the optional navigator text is preserved and its prior companion is linked, not re-certified by these tests.

## Replay

- python tools/write_swarm_abm.py
- python tools/test_swarm_abm.py
- python tools/run_encounter_probe.py {ID} --sequence swarmintelligence --render --no-bridges --output-tag abm-lesson --probe tools/probes/swarm_abm_room.gd
- python tools/publish_swarm_abm.py

Hashes and engine logs accompany this report. Changes to the code or tutorial require fresh tests before republishing. Next: Ant Colony Optimization, two channels carried by the same point.
'''
write(M/'technical.md',technical)
for name in ['tutorial.md','final.md','technical.md']:
 shutil.copy2(M/name,O/name)
for name in ['tutorial.md','final.md','technical.md','map_data.json']:shutil.copy2(M/name,(O/'after'/name).parent.mkdir(parents=True,exist_ok=True) or O/'after'/name)
for folder in ['assets','museum','probes','tools']:(O/folder).mkdir(exist_ok=True)
for p in RUN.glob('*.png'):shutil.copy2(p,O/'assets'/p.name)
for p in BEFORE.glob('*.png'):shutil.copy2(p,O/'assets'/p.name)
for name in ['report.json','engine.log','source_manifest.json']:shutil.copy2(RUN/name,O/'museum'/name)
for name in ['swarm_abm_student.gd','swarm_abm_room.gd','swarm_abm_before.gd','transformation_encounters.gd']:shutil.copy2(R/'tools/probes'/name,O/'probes'/name)
for name in ['write_swarm_abm.py','test_swarm_abm.py','publish_swarm_abm.py']:shutil.copy2(R/'tools'/name,O/'tools'/name)
shutil.copy2(R/'commons/artifacts/navigator_noise/tutorial.md',O/'navigator.md')
write(O/'changes.md','''# What changed in this hall

| Before | Now |
| --- | --- |
| Incomplete generic society/state snippets. | Complete tested foraging reconstruction, tied to the colony in the room. |
| A new agent class obscures the carried object. | The exact PointBody from Boids; a carry flag selects new behaviour. |
| Reset scope is implicit. | Replace agent records keeps shared traces; Clear All erases both. |
| A broad account of collective patterns. | Reflection follows one returning point, then asks what a new population inherits. |
| Cross-room wall runs and a fallback portal obstruct displays. | Five interior wall seeds removed; next marker at the existing perimeter opening. |
| Colony and navigator images overlap from the working side. | Colony turned180° towards a clearer backdrop. |

The small student scene is temporarily placed for the report and supplied as runnable code. Existing production simulation algorithms are unchanged. The optional navigator companion remains a separate lesson. One pre-existing unresolved Physarum token still does not load; see the evidence note.
''')
css=text(R/'doc/book/iterations/2026-10-10-swarm-a-trace-outside/style.css')
css+='table{border-collapse:collapse;width:100%;font:15px/1.5 system-ui}td,th{padding:12px;border-bottom:1px solid #ccc;text-align:left;vertical-align:top}details{background:#e5e9e8;padding:16px;margin:20px 0}summary{cursor:pointer;font-family:system-ui}.parallel article{overflow-wrap:anywhere}pre{tab-size:4}'
nav='<nav><a href="index.html">ABM</a><a href="parallel.html">Facing pages</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Changes</a><a href="technical.html">Evidence</a><a href="abm-review.zip">Review ZIP</a></nav>'
def render(md):return markdown.markdown(md,extensions=['fenced_code','tables','footnotes']).replace('../../artifacts/navigator_noise/tutorial.md','navigator.html')
def page(name,title,body,cls=''):
 write(O/name,'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style>'+nav+'<main class="'+cls+'">'+body+'</main></html>')
for name in ['tutorial','final','technical','changes','navigator']:page(name+'.html','ABM · '+name,render(text(O/(name+'.md'))))
page('parallel.html','ABM · tutorial beside reflection','<article>'+render(text(O/'tutorial.md'))+'</article><article>'+render(text(O/'final.md'))+'</article>','parallel')
page('before.html','ABM · previous tutorial',render(text(O/'before/tutorial.md')))
def fig(name,caption):return '<figure><img loading="lazy" src="assets/'+name+'.png" alt="'+html.escape(caption)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
body=f'''<div class="tag">Endless Museum / Swarm Intelligence / 4 of 7</div><h1>What the point carries</h1><p>The same body searches, collects and returns. One stored condition changes what it does next.</p><p class="notice"><strong>{len(code['checks'])} printed-code checks and {len(native['checks'])} native checks pass.</strong> <a href="parallel.html">Read the complete tutorial beside the reflection.</a></p>'''
body+=fig('carrying','Native Godot: the pink PointBody has reached food. Its green cube shows the carry state; the first return tick gives velocity −0.30 cells/s.')
body+='<h2>One lesson, carried from the previous rooms</h2><p>'+html.escape(summary)+'</p><details><summary>Compressed instruction</summary><p>'+html.escape(short)+'</p></details>'
body+='<h2>New travellers, old marks</h2><div class="grid">'+fig('trace-kept','Returning points leave a shared trace. The model has now delivered one item.')+fig('new-agents','REPLACE AGENTS restores the original six records. Every field value remains unchanged.')+'</div>'+fig('clear-all','CLEAR ALL clears agents, field, deliveries and clock. These two resets do different work.')
body+='<h2>The encounter in the museum</h2><div class="grid">'+fig('colony-before','Before: the fallback portal cuts through the colony view; the optional navigator sits behind it.')+fig('colony-after','After: colony turned180°, portal placed at the perimeter, obstructing interior wall runs removed. Production foraging rules are unchanged.')+'</div>'
body+='<h2>Arrangement from above</h2><div class="grid">'+fig('above-before','Before: cross-room walls interrupt the floor and sightlines.')+fig('above-after','After: central route open. The temporary learner study sits to the east, its controls clear of the route.')+'</div>'
body+='<p>The small learner scene is supplied with the tutorial and was temporarily inserted for these captures. The hall architecture and colony orientation are saved in the museum. The report distinguishes those changes from a new permanently registered artifact.</p>'
body+=f'''<h2>What was tested</h2><p>{len(code['checks'])} fresh Godot assertions cover the exact printed code, numerical predictions, a slower-return variation, three deliberately broken versions and synthetic XRTools pickup. {len(native['checks'])} native checks cover the existing colony, student controls, rendered positions, walking clearance and images. Physical headset play has not been tested.</p><p><a href="technical.html">Evidence and limits</a> · <a href="SUMMARY.md">One paragraph + short instruction</a> · <a href="http://localhost:3003/tutorial-plan?map={ID}&amp;view=summaries">Editable plan</a> · <a href="before.html">Previous tutorial</a></p><p class="meta">Next: Ant Colony Optimization. Keep this body and its state; separate the home and food channels.</p>'''
page('index.html','ABM · what the point carries',body)
write(O/'README.md','# ABM review\n\nOpen index.html or parallel.html. Full tutorial and reflection, extracted runnable scripts, actual Godot images and receipts. Requires prepared Ada project with XRTools and push_button.tscn. Student study temporary in captures; hall architecture changes permanent. No independent student or physical headset certification. Next: Ant Colony Optimization.\n')
dump(O/'source-check.json',{'same_point_body_as_boids':True,'other_runtime_plan_rows_unchanged':True,'tutorial_sha256':code['tutorial_sha256'],'museum_source_manifest':'museum/source_manifest.json','existing_unresolved_artifact':'physarum_colony','student_scene_permanently_registered':False})
handoff=R/'doc/book/course/storyboards/SWARM-HANDOFF.md'
previous=text(O/'before/SWARM-HANDOFF.md')
head=f'''# Swarm / 10 October 2026 / four halls complete

Latest: ABM, doc/book/iterations/2026-10-10-abm-what-the-point-carries/index.html. Full tutorial/final/parallel, SUMMARY.md, abm-review.zip. {len(code['checks'])} exact printed-code and {len(native['checks'])} native checks pass. Next: SwarmIntelligence_Ant_Colony_Optimization (AntColonyV2): keep this PointBody/carrying flag, split home/food channels; no travelling-salesperson detour. Three Swarm halls remain. Other execution-plan rows/decisions preserved.

Sources: doc/book/studies/swarm-through-the-hands/{ID}/{{foragers.gd,study.gd,point_body.gd,study.tscn}}. PointBody byte-identical to Boids. Six points,16×16plane,.16m/cell,.05stick,boundedsteering. Boolcarrying. SEARCH3oldfield samples; food<1cell→RETURN knownhome/deposit. Home<1→single delivery/eastdeparture. Contactbeforemotion; finitevelocityturn. Infinitefood. Nextstatecommit, retention.92,returnersdeposit1cap8. Replaceagents keepsfield/tick/delivered; ClearAll resetsall keepsparameters. Holdpauseall/relocate/zerov preservescargo; triggerselect; resetignoreheld. Tests transition/contactboundaries/oldfield/reversedorder/cycle/1800ticks/reset/halfreturnspeed/3faults/syntheticXR.

Museum ABM only: five interior wall seeds(2,3),(6,3),(10,3),(6,7),(10,7) removed; colonyyaw180; t7,7→6,9 existingperimeter. em_plan matching. Nativecentralroute10samples+approach+sightlines pass; no blockedexitwarning, no playercrossing/headsetclaim. Temporary learner at(8.8,0,6.5),yaw−90; notregistered. Initial8,0,6.5buttonblockedroute; preservedinvestigation. Keep host _process enabled (playingfalse) during captures: frozenRigidBody rendering otherwise stale despitechangedmodel, nativecheck now guards. Productionalgorithmsunchanged. Existinglowercasephysarum_colony hasno living scene5/6 placed, preexistingnotregression. Navigatorcompanion preserved/notretested. Initialtestharness packedarray.max mistakefixedwithArray conversion; nofinalGDScript errors; existingUID/Joltwarningsremain.

Replay: write_swarm_abm.py; test_swarm_abm.py; run_encounter_probe.py {ID} --sequence swarmintelligence --render --no-bridges --output-tag abm-lesson --probe tools/probes/swarm_abm_room.gd; publish_swarm_abm.py. Preservehuge unrelateddirtytree. Noagents/commits/reverts.

## Previous record (status superseded above)

'''
write(handoff,head+previous)
with zipfile.ZipFile(O/'abm-review.zip','w',zipfile.ZIP_DEFLATED) as z:
 for p in O.iterdir():
  if p.is_file() and p.suffix in ['.md','.html','.json','.log']:z.write(p,p.name)
 for folder in ['printed','variation','fault-pickup','fault-replace','fault-delivery','assets','museum','tools','probes']:
  for p in (O/folder).rglob('*'):
   if p.is_file() and p.suffix!='.uid':z.write(p,p.relative_to(O))
 for name in ['tutorial.md','final.md','map_data.json']:z.write(O/'before'/name,'before/'+name)
with zipfile.ZipFile(O/'abm-review.zip') as z:assert z.testzip() is None
print(f'ABM published: {len(code["checks"])} code / {len(native["checks"])} native checks.')
