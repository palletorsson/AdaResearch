from pathlib import Path
import json,html,re,shutil,hashlib,zipfile
import markdown
R=Path(__file__).resolve().parents[1];ID='SwarmIntelligence_Swarm_Intelligence_Algorithms'
O=R/'doc/book/iterations/2026-10-10-swarm-who-keeps-the-count';M=R/'commons/maps'/ID
S=R/'doc/book/studies/swarm-through-the-hands'/ID;A=R/'commons/artifacts/population_account_walk'
RUN=R/'ada_run/encounter_pilot'/ID/'account-room';BEFORE=RUN.parent/'account-before'
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
assert (O/'before/ecosystem.gd').read_bytes()==(R/'algorithms/emergentsystems/ecosystemsimulation/ecosystem.gd').read_bytes()
assert (S/'point_body.gd').read_bytes()==(S.parent/'SwarmIntelligence_Particle_Swarm_Optimization/point_body.gd').read_bytes()
summary='''Walk among the existing ecosystem enlarged into a twelve-metre field of the carried PointBody spheres. Hold one to pause and move it while retaining its recorded arrival. Reuse arrays, dictionaries and loops to account separately for births, losses and supplied organisms; compare initial plus born minus lost plus supplied with the actual population. Connect the account to observations of the existing simulation, whose movement and support rules remain unchanged. Filter supplied entries from the displayed calculation and predict the gap while the bodies and complete event record remain. Keep outside food and predator-pressure receipts distinct from creature counts. Carry an accountable but partial record of relationships into Graph Theory, followed by Machine Learning.'''
short='''Swarm7/7. Primary=population_account_walk;17x21hall/12mfield,startsPAUSED. SamePointBodyasPSO;55initialprey50/pred5,greenfood100. Blueprey/pinkpred/goldring=supplied. Model=existingecosystem.gd unchanged; observed.gd subclass: births in check_for_mate, supplied other postinitialspawns, losses afterspeciespasses inclnewarrivals, carefood/pressureseparate. Accountbaseline+birth-loss+supply; eventdict copied; filteredcounter omitsupply, actualpopulation+eventsretained; gap=omittedsupply. Sourcewrap. Modeldisplay(x*15,.8+y*3,z*15);51cmmarkers != feedingradius. Fixed60Hz; handpauseall/movelocal/zerov, heldtriggerinspect; restartwaitsheld/resetmodelseed+account. Studentobject=account; suppliedecology declared+sourceincluded. 34printedcode checks incl2400update sourceequivalence, actualbirth/loss/supply, filteredvariation,3faults,syntheticXR. Nativefloor19/control8 samples+captures. Noheadset/independentlearnerclaim. Next=GraphTheory, notChamber. AllsevenSwarmhalls implemented forreview.'''
write(O/'SUMMARY.md','# Swarm — one paragraph\n\n'+summary+'\n\n## Compressed instruction\n\n'+short+'\n')
plan_path=R/'doc/book/course/execution-plan/plan.json';plan=read(plan_path);before_plan=read(O/'before/execution-plan.json')
row=next(x for x in plan['lessons'] if x['id']==ID)
row.update(summary=summary,object='An event account beside full-size carried PointBodies in the existing ecosystem.',
 change='A population increase acquires a source: births and supplied bodies are recorded separately; a filtered account exposes the unexplained difference.',
 reuses='PointBody unchanged from PSO; arrays, dictionaries, loops, model/view coordinates, event signals, hold-to-pause and a shared record.',
 given='Existing ecosystem.gd with Creature.gd and food.gd; museum floor/player/camera/light; XRTools; push_button.tscn. Complete account, observation adapter, carried PointBody and host printed.',
 later='No ecological realism claim, causal explanation of every death, care-disabled counterfactual, evolutionary algorithm tutorial or generic interface survey.',
 checks=[f"{len(code['checks'])} exact printed-code checks: real births/losses/support,2400-step source equivalence, filtered variation,three executed faults and synthetic XR.",f"{len(native['checks'])} native checks and captures: permanent saved hall,19 central walking samples,eight control approaches,actual count filtering and provenance markers."],
 transfer='Begin10prey/2predators; prey birth2,loss3,supply5 gives14. Omit supply: expected9,actual14,gap5. Food does not directly increment either creature count.',
 carry='A count can reconcile while its account remains partial. Name relation and support before drawing a network.',
 next='Review all seven Swarm tutorial/reflection pairs. Graph Theory follows Swarm, then Machine Learning.',
 notes='Implemented for review; decision and baseline preserved. Real existing ecosystem observed without modifying its source. See2026-10-10-swarm-who-keeps-the-count. Physical headset and independent ghost student remain separate evaluations.')
for a,b in zip(before_plan['lessons'],plan['lessons']):
 if a['id']!=ID:assert a==b
 else:assert a['decision']==b['decision'] and a['baseline']==b['baseline']
dump(plan_path,plan);dump(O/'lesson-plan.json',row)
sequence_path=R/'commons/maps/sequences/swarmintelligence.json'
if not (O/'before/swarmintelligence.json').exists():shutil.copy2(sequence_path,O/'before/swarmintelligence.json')
seq=read(sequence_path)
for groups in [seq['artifact_groups'],seq['sequences']['swarmintelligence']['artifact_groups']]:
 for group in groups:
  if group['map']==ID:group.update(artifacts=['population_account_walk'],size_budget='world_scale',rationale='Existing ecosystem at body scale; an event account separates births, losses and supplied support.')
dump(sequence_path,seq)
technical=f'''# Swarm — reconstruction and evidence

## Scope

The closing lesson teaches an event account. It does not reimplement the ecosystem or add a generic algorithm-interface survey. The supplied source is algorithms/emergentsystems/ecosystemsimulation/ecosystem.gd, Creature.gd and food.gd. Their movement, mating, health, food and balancing rules remain unchanged. The source hash equals the saved before copy. A subclass calls the original operations and emits observations; birth context comes from check_for_mate, later other spawns are supplied, and losses compare membership after each species pass. New arrivals within a pass are included in the removal comparison. Existing queue_free defers destruction until after these receipts. Supplied-creature care callbacks are not counted again. Outside-food and pressure callbacks remain separate.

Loss receipts are emitted at update-pass boundaries; receipt serials are not a proof of exact internal chronology. Compare counts at completed-step boundaries. The record describes population membership, not the cause of every death. It also does not register a player's relocation as a birth or loss. Holding is nevertheless an intervention.

## Runtime

Permanent population_account_walk replaces the old plinth placement in this hall only. The original ecosystem remains on disk for other users and is the live source of this lesson. Map and corresponding em_plan row become 17 × 21, flat and open; artifact cell (8, 10), yaw 180, scale 1. The 12 m model field has control banks at local z±6.9,x∓3.1,y.95. The central walk remains open. Other em_plan rows compare equal to their before snapshot. Sequence metadata changes only this hall's artifact/size description in both lists.

The carried PointBody is unchanged from PSO. Visual sphere and grab shape both enlarge by 3 to 0.51 m diameter, root unscaled. Model display scales x/z by 15 and y by 3 with 0.8 m offset: view size is not contact size. Bodies overlap and wrap at model boundaries. Food is a batched non-grabbable marker; hidden original rendering remains in the supplied model.55 initial creature proxies are created, added or removed to match the actual lists. Gold rings follow supplied organisms; white marks the selected body.

Starts paused. RUN uses 60 fixed updates/second; stalls beyond 0.1 seconds per rendered frame slow the display. The original source has per-update force, pressure and random-food operations, so update rate is part of this demonstrator's declared conditions. The observer does not normalize those existing rules. Holding pauses the whole model, maps the hand through the host transform, and zeros that body's velocity. Release resumes if Run was active. A held trigger selects the readout. Restart waits for release, resets source seed/model and account together. SUPPLY ROW changes only the calculation shown, not care or stored events.

## Executed checks

{len(code['checks'])} exact printed-code checks pass in a fresh Godot 4.6 process. Every fenced script is extracted from tutorial.md and compared with study and exportable runtime copies. Tests reconstruct 10 + 2 - 3 + 5 = 14; distinguish species and food/pressure; require immutable event copies; exercise actual mating, health loss, predation and both replacement rules. A 40-second / 2,400-update comparison against the unmodified source matches organism positions, velocities, health, DNA, support counts and RNG state while both population equations reconcile after every step. An independent filtered-default edit predicts gap 5. Three executed faulty copies reverse loss sign, double supply and alias mutable history; tests reject each. Synthetic XRTools pickup/release uses a translated and rotated host, verifies pause/local coordinates/selection, then requires stable body identity and count reconciliation after release.

{len(native['checks'])} saved-museum checks/captures pass. Nineteen centre-route samples and eight control approaches have actual floor and capsule clearance. Both button banks operate the same model. After 1,800 source updates the pictured run has prey 50 + 0 born - 49 lost + 10 supplied = 11, predators 5 + 0 born - 5 lost + 0 supplied = 0. There were no births in that captured interval; the code test exercises valid mating separately. The image does not claim all named processes happened in that run. Filtering changes expected prey to 1 while actual remains 11; restoring the row reconciles them. Gold markers match surviving supplied organisms.

The images are native Godot captures of the permanent placement, including eye-level and overhead before/after. No physical headset, Quest-performance, independent learner or actual player portal-crossing certification. Existing project UID and Jolt solver-bias warnings remain; final logs contain no GDScript errors. No APK built.

## Replay

python tools/write_swarm_account.py
python tools/place_swarm_account.py
python tools/test_swarm_account.py
python tools/run_encounter_probe.py {ID} --sequence swarmintelligence --render --no-bridges --output-tag account-room --probe tools/probes/swarm_account_room.gd
python tools/publish_swarm_account.py

The review ZIP is a lesson in the prepared museum, not an empty standalone project. It includes the three supplied ecosystem sources for inspection and all four printed scripts. Runtime copies are local because export presets exclude doc/**. Approval decision remains draft. Only this execution-plan row changes; all other rows and baseline/decision fields are preserved.
'''
write(M/'technical.md',technical)
for folder in ['assets','museum','probes','tools','runtime','supplied','after']:(O/folder).mkdir(exist_ok=True)
for name in ['tutorial.md','final.md','technical.md']:
 shutil.copy2(M/name,O/name);shutil.copy2(M/name,O/'after'/name)
shutil.copy2(M/'map_data.json',O/'after/map_data.json')
for base in [RUN,BEFORE]:
 for p in base.glob('*.png'):shutil.copy2(p,O/'assets'/p.name)
for name in ['report.json','engine.log','source_manifest.json']:shutil.copy2(RUN/name,O/'museum'/name)
for name in ['swarm_account_student.gd','swarm_account_room.gd','swarm_account_before.gd','transformation_encounters.gd']:shutil.copy2(R/'tools/probes'/name,O/'probes'/name)
for name in ['write_swarm_account.py','place_swarm_account.py','test_swarm_account.py','publish_swarm_account.py']:shutil.copy2(R/'tools'/name,O/'tools'/name)
for p in A.iterdir():
 if p.suffix in ['.gd','.tscn']:shutil.copy2(p,O/'runtime'/p.name)
for name in ['ecosystem.gd','Creature.gd','food.gd']:shutil.copy2(R/'algorithms/emergentsystems/ecosystemsimulation'/name,O/'supplied'/name)
write(O/'changes.md','''# Swarm — before and after

| Before | Now |
| --- | --- |
| A small ecosystem on a plinth. | A 12 m field of grabbable PointBodies in a 17 × 21 m hall. |
| Abstract interface tutorial with empty methods. | Runnable account connected to the actual supplied ecosystem. |
| Reflection names support, tutorial does not construct its record. | Birth/loss/supply counts reconcile with actual populations. |
| Moving crowd suggests a recovery. | Gold rings and a population equation identify provision. |
| No concrete missing-evidence exercise. | Omit the supply row while retaining bodies and history; predict the gap. |
| Ending points to a deferred chamber. | Carry accountable relations into Graph Theory. |

The original ecosystem rules and PointBody class remain unchanged. The student's new object is an account, with a complete observer and museum host printed beside it. Counts do not certify ecological realism or complete causal knowledge.
''')
CSS='''*{box-sizing:border-box}body{margin:0;background:#f4f2eb;color:#202a2b;font:18px/1.65 Georgia,serif}nav{position:sticky;top:0;background:#142c34;color:white;padding:12px 4vw;z-index:2;font:14px/1.6 system-ui}nav a{color:#c6ede9;margin-right:20px}main{max-width:1180px;margin:40px auto;padding:0 25px 70px}h1{font-size:clamp(34px,5vw,62px);line-height:1.08;max-width:900px}h2{font:600 26px/1.2 system-ui;margin-top:50px}p{max-width:850px}a{color:#126071}img{display:block;width:100%;border-radius:3px}figure{margin:25px 0}figcaption,.tag,.meta{font:14px/1.5 system-ui;color:#53676c;margin-top:8px}.grid,.parallel{display:grid;grid-template-columns:1fr 1fr;gap:28px}.parallel{max-width:1700px}.parallel article{min-width:0}pre{overflow:auto;background:#142c34;color:#e1edeb;padding:20px;font:13px/1.6 Consolas,monospace}code{font: .86em Consolas,monospace}details{border:1px solid #b5c9c8;padding:15px;margin:20px 0}summary{cursor:pointer;font-family:system-ui}.notice{border-left:4px solid #c99a49;background:#fffaf0;padding:20px}table{border-collapse:collapse;width:100%}td,th{border-bottom:1px solid #bdcccc;text-align:left;padding:12px;vertical-align:top}@media(max-width:850px){.grid,.parallel{grid-template-columns:1fr}nav{position:static}}@media print{nav{display:none}details{display:block}pre{white-space:pre-wrap}figure{break-inside:avoid}}'''
def render(s):return markdown.markdown(s,extensions=['extra','sane_lists'])
def page(name,title,body,klass=''):
 write(O/name,'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+CSS+'</style></head><body><nav><a href="index.html">Museum</a><a href="parallel.html">Facing pages</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="technical.html">Evidence</a><a href="changes.html">Before / after</a><a href="swarm-account-review.zip">Review ZIP</a></nav><main class="'+klass+'">'+body+'</main></body></html>')
for n in ['tutorial','final','technical','changes']:page(n+'.html','Swarm · '+n,render(text(O/(n+'.md'))))
page('parallel.html','Swarm · tutorial and reflection','<article>'+render(text(O/'tutorial.md'))+'</article><article>'+render(text(O/'final.md'))+'</article>','parallel')
page('before.html','Previous Swarm tutorial',render(text(O/'before/tutorial.md')))
def fig(name,caption):return '<figure><img loading="lazy" src="assets/'+name+'.png" alt="'+html.escape(caption)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
body='<div class="tag">Endless Museum / Swarm Intelligence / 7 of 7</div><h1>Who keeps the count?</h1><p>A population can recover through birth, or through bodies supplied from outside. The room lets you see the difference.</p><p class="notice"><strong>Saved in the museum.</strong> Walk among the carried PointBodies. Hold one to pause and inspect it. Gold rings identify supplied organisms.</p>'
body+=fig('eye-level','The permanent ecosystem at eye level. Blue spheres are prey, pink spheres predators; small green points mark food. Starts paused.')
body+='<h2>The closing lesson</h2><p>'+summary+'</p><details><summary>Compressed instruction</summary><p>'+short+'</p></details><p><a href="parallel.html">Tutorial left, reflection right</a> · <a href="SUMMARY.md">One-paragraph summary</a> · <a href="http://localhost:3003/tutorial-plan?map='+ID+'&amp;view=summaries">Editable plan</a></p>'
body+=fig('support','After 30 seconds of actual model updates, supplied survivors carry gold rings. The display enlarges the original model; visible sphere size is not its contact radius.')
body+='<h2>Ten bodies missing from the account</h2><p>The captured run contains no births: 50 initial prey minus 49 lost plus 10 supplied leaves 11. The filtered calculation sees only one. Its ten-body gap belongs to the description; the organisms remain.</p><div class="grid">'+fig('account','Full record: 50 +0 -49 +10 =11. Actual 11; gap 0.')+fig('filtered','Supplied row omitted: expected 1, actual 11; gap 10. Restoring it closes the gap.')+'</div>'
body+='<h2>Before and after</h2><div class="grid">'+fig('eye-before','Before: a small ecosystem on a plinth.')+fig('eye-level','After: the visitor stands among its enlarged bodies.')+'</div><div class="grid">'+fig('above-before','Before: 13 × 13 m hall and one small display.')+fig('above-after','After: 17 × 21 m open hall, one primary field and controls at each end. Central walking route retained.')+'</div>'
body+=f'<h2>Tested against the source</h2><p><strong>{len(code["checks"])} printed-code checks and {len(native["checks"])} native room/capture checks pass.</strong> The observer matches the original ecosystem over 2,400 updates. Tests exercise real births, losses and replenishment, a predicted missing-row variation, three faulty copies and synthetic XR pickup.</p><p>These are author-operated tests and actual Godot captures. Physical headset comfort and performance remain to be tested.</p><p><a href="technical.html">Exact test scope</a> · <a href="swarm-account-review.zip">Download this hall for review</a></p><h2>The seven-hall route is ready to read</h2><p><a href="http://localhost:3003/book-review/doc/book/iterations/2026-10-10-swarm-complete-readings/index.html">Open all seven tutorial and reflective texts</a>. The next sequence in the spine is Graph Theory, then Machine Learning.</p>'
page('index.html','Swarm · who keeps the count?',body)
write(O/'README.md','# Swarm closing hall review\n\nOpen index.html or parallel.html. Full tutorial, reflection, extracted code, supplied ecosystem source, permanent runtime, test receipts and native images. Requires prepared Ada museum/XRTools; not standalone. No physical-headset or independent-learner claim.\n')
dump(O/'source-check.json',{'same_point_as_PSO':True,'runtime_equals_printed':True,'supplied_ecosystem_unchanged':True,'other_runtime_rows_unchanged':True,'other_execution_rows_unchanged':True,'decisions_preserved':True,'permanent':True,'tutorial_sha256':code['tutorial_sha256']})
with zipfile.ZipFile(O/'swarm-account-review.zip','w',zipfile.ZIP_DEFLATED) as z:
 for p in O.rglob('*'):
  if p.is_file() and p.suffix not in ['.zip','.uid'] and not (p.parent.name=='before' and p.name in ['em_plan.json','execution-plan.json','SWARM-HANDOFF.md']):z.write(p,p.relative_to(O))
write(R/'doc/book/course/storyboards/SWARM-HANDOFF.md',f'''# Swarm / 10 October2026 / seven halls implemented for review

Latest: doc/book/iterations/2026-10-10-swarm-who-keeps-the-count/index.html. {len(code['checks'])} exactprinted/{len(native['checks'])} native checks pass. Full tutorial/final/parallel, SUMMARY.md,swarm-account-review.zip. All seven readings:2026-10-10-swarm-complete-readings. Next useful step=review whole sequence; GraphTheory already developed and followsSwarm thenML. Do not silently restartGraphTheory. User continues onehallatatime, fullsize encounters.

{short}

Sourcefiles: studies/swarm-through-the-hands/{ID}/account.gd,observed.gd,study.gd,point_body.gd. Runtimecopies incommons/artifacts/population_account_walk; originalecosystem.gd byteunchanged. Observereventorder receiptorder; compareendsteps. Handinterventionposition isnotpopulationevent. Account onlyorganismcounts,notfoodbalance. Seeded30scapture haszero births;codefixture explicitlytestsrealreproduction. Livepredators extinctby30sinthisseed;noecologicalstabilityclaim. Two-sidedcontrolsnearhand. Source per-updatebehavior kept, host60Hz declared.

Replaywrite_swarm_account.py→place_swarm_account.py→test_swarm_account.py→run_encounter_probe.py {ID} --sequence swarmintelligence --render --no-bridges --output-tag account-room --probe tools/probes/swarm_account_room.gd→publish_swarm_account.py. Snapshotbefore/runaccount-before. Nativeimagesinspected. Nocodeerrors; existingUID/Joltwarnings. Noheadset/independentstudent/actualportal-crossingclaim.

USERrules: Museumexists; PointBodylineage; fullrunnableprintedcode; separatefinalreflection; currentencounterbeforehistory; actualnativeeye+overheadimages; editableplanapprovalretained. Noagents/commits/reverts. Preservehugeunrelateddirtytree. Planchangedonlythisrowbaseline/decisionpreserved;em_planonlythisrow;seqmetadataownartifactgroupbothlists.

## Prior progress (six-hall snapshot)

'''+text(O/'before/SWARM-HANDOFF.md'))
print('Published final Swarm hall; preserved other hall rows and review decisions.')
