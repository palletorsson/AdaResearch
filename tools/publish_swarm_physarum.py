"""Publish the first Swarm lesson with explicit status for the remaining six halls."""
from pathlib import Path
import json,hashlib,html,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-10-swarm-a-trace-outside'
M=R/'commons/maps/SwarmIntelligence_PhysarumColony'
S=R/'doc/book/studies/swarm-through-the-hands/SwarmIntelligence_PhysarumColony'
RUN=R/'ada_run/encounter_pilot/SwarmIntelligence_PhysarumColony/swarm-first-lesson'
def read(p):return json.loads(p.read_text(encoding='utf8'))
def text(p):return p.read_text(encoding='utf8')
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(s.encode('utf8'))
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
code=read(O/'checks.json');room=read(RUN/'report.json')
assert code['passed'] and code['completed'] and room['passed'] and room['completed']
assert 'SCRIPT ERROR' not in text(O/'code.log') and 'SCRIPT ERROR' not in text(RUN/'engine.log')
assert hashlib.sha256(text(M/'tutorial.md').encode()).hexdigest()==code['tutorial_sha256']
for name,source in re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',text(M/'tutorial.md'),re.S):
 assert source+'\n'==text(S/name)==text(O/'printed'/name)
assert (S/'point_body.gd').read_bytes()==(R/'doc/book/studies/soft-bodies-through-the-hands/Topology_Entropy_Morphogenesis/point_body.gd').read_bytes()

route=[
 ('SwarmIntelligence_PhysarumColony','A trace outside the point','PhysarumColony','Sense → turn → move → deposit; retain a fraction of the field.',
  'In PhysarumColony, watch a trace remain after a point moves away. Carry the familiar PointBody into a six-agent study: sample left, ahead and right, turn toward a strictly stronger side, then move and deposit into an addressed field. Everyone reads the old field before its decay and the new deposits. Compare 92% and 55% retention from the same start; move one starting point and predict its first three samples. Test that a second point responds after the depositing point has left. Carry the body and field lookup into FlowFields; the record now lives outside the body.'),
 ('SwarmIntelligence_FlowFields','Directions supplied','FlowFieldMain','Read a vector at an address; desired velocity and bounded steering.',
  'Meet the existing flow field with the same point and addressed space. Replace scalar trace strength with a direction vector at each cell; show the vector sampled by one point before releasing the small population. Reuse velocity integration and introduce desired minus current velocity as a bounded steering change. Edit one region, predict the first turn and test the zero-vector case. These points read the field without depositing into it. Keep obstacle pathfinding as context for the later graph search lessons. Carry bounded steering into a neighbourhood of moving points.'),
 ('SwarmIntelligence_Boids_Algorithm','Neighbours become the field','boids_aquarium / film_boid_neighbour','Neighbourhood → separation / alignment / cohesion → weighted steering.',
  'Follow one point in the aquarium and make its chosen neighbours visible. Carry the steering calculation from FlowFields, but obtain desired motion from nearby bodies: first separation, then alignment, then cohesion. Read all positions and velocities from one snapshot, exclude the point itself, handle coincident positions and no neighbours, then commit next states together. Vary one weight and predict a local change before looking at the flock. Test that reversing iteration order does not change the result. Carry a distinction between an individual rule and a collective pattern.'),
 ('SwarmIntelligence_Agent_Based_Modeling_ABM','The traveller changes state','ant_colony_optimization / stigmergy_grid','State and event; replace agents versus clear their environment.',
  'Return to a small foraging population in the existing colony display. Reuse sensing and movement; add an explicit outward/returning state whose destination event changes what a point does next. Keep one trace channel for this first state lesson. Predict the transition, replace the agents while retaining their field, then perform a full reset that clears both. Test those two operations separately. The lesson concerns accountable state and reset scope, not a generic simulation of society. Carry the returning flag and shared field into the two-channel colony.'),
 ('SwarmIntelligence_Ant_Colony_Optimization','Directions for the return','AntColonyV2','Two trace channels; read one, write the other; destination transition.',
  'Watch outward and returning traffic in AntColonyV2. Keep the state transition from ABM and give the shared field separate home and food channels. An outward point reads food and leaves home information; a returning point reverses that relationship. Show one destination event and predict the next read and deposit before running many agents. Test that the other channel is untouched and that reset clears both. This is demonstrated foraging coordination; the hall title does not establish a shortest-tour guarantee. Carry the question of where useful information is stored into particle memory.'),
 ('SwarmIntelligence_Particle_Swarm_Optimization','Remembered positions, chosen scores','fitness_landscape_politics','Position + score; inertia / personal best / shared best; objective.',
  'Keep the sphere and weighted motion, now as a candidate on the existing fitness landscape. Evaluate a small repeatable population before its first move, storing each best position beside its score and the objective that produced it. Add inertia, a pull toward personal best and a pull toward shared best in separate passes. Predict and test a one-step update; change the objective and re-evaluate or explicitly restart the remembered records. Treat the novelty archive as a later comparison, not part of the first formula. Carry an account of what the system calls improvement, without promising a global optimum.'),
 ('SwarmIntelligence_Swarm_Intelligence_Algorithms','What keeps a population going','ecosystem_simulation','Birth / loss / supplied replenishment; event accounting and limits.',
  'Observe an apparent recovery in the ecosystem display. Reuse agent states and event arrays to keep births, losses and supplied replenishment separate. Reconstruct the population count from a short declared event stream before interpreting a moving crowd; predict what one missing support event would change. Bind that stream to the actual exhibit before claiming a live explanation. This closing lesson composes earlier tools rather than surveying more algorithms. Carry into Graph Theory the question of which relations are recorded and which conditions keep them possible; Machine Learning follows the graph sequence.'),
]
planpath=R/'doc/book/course/execution-plan/plan.json';plan=read(planpath)
byid={row['id']:row for row in plan['lessons']}
for mid,title,artifact,focus,summary in route:
 row=byid[mid];row['summary']=summary
 if mid==route[0][0]:
  row.update(object='The carried PointBody reading and writing a shared trace.',change=focus,
   reuses='Unchanged PointBody from the soft-body hand studies; addressed state, local/world conversion and separate update phases.',
   given='Prepared Ada museum with XRTools and player/camera/light; named push_button.tscn component. Three complete student scripts are printed.',
   later='Diffusion, food, anchor emission and random wandering remain exhibit context. No shortest-path or biological reconstruction claim.',
   transfer='Move the first initial position from (4,8) to (6,8); predict sensor addresses, then run and inspect. A separate generated variation is tested.',
   carry='The same sphere, a position-to-field interface and a shared trace that survives its author.',
   next='FlowFields: keep body and lookup, replace scalar memory with supplied directions; add bounded steering.',
   checks=[f"{len(code['checks'])} exact printed-code Godot checks, independent edit, three rejected faults and synthetic XRTools pickup/trigger/release.",f"{len(room['checks'])} native checks: contained original simulation, learner placement, controls and approaches. Physical headset experience remains open."],
   notes='Implemented draft for review. Earlier missing helpers are replaced by complete scripts. The model uses periodic boundaries, straight ties and no diffusion; the production colony is explicitly richer. No independent learner or headset validation claim.')
  if 'Topology_Entropy_Morphogenesis' not in row['dependsOn']:row['dependsOn'].append('Topology_Entropy_Morphogenesis')
 else:
  row['next']='Next implementation step: bind the minimal carried study to this exhibit, print its complete code, execute assertions and an independent change; do not count this paragraph as a tested lesson.'
  row['checks']=row.get('checks',[])
  if mid==route[-1][0]:row['carry']='An event account with external support named; carry it into Graph Theory, then Machine Learning.'
seq=next(x for x in plan['sequences'] if x['id']=='swarmintelligence')
seq['aim']='Distinguish where coordination lives: shared trace, supplied direction, neighbourhood, individual state, paired channels, evaluated memory and continuing support.'
seq['carry']='Keep the point and explicit update records. Carry selected relations and their conditions into Graph Theory; Machine Learning follows.'
dump(planpath,plan)
dump(O/'sequence-plan.json',[byid[x[0]] for x in route])

synopsis='# Swarm — where coordination lives\n\nOne point returns in seven different relations. The order is retained. **Physarum is implemented and tested here; the other six paragraphs are plans for the next lessons.** Existing drafts remain available but are not certified by this review.\n\n'
for index,(mid,title,artifact,focus,summary) in enumerate(route,1):
 synopsis+=f'## {index}. {title}\n\n**Hall:** {mid}  \n**Encounter:** {artifact}  \n**Learning elements:** {focus}\n\n{summary}\n\n'
synopsis+='''## Keep the divisions useful

ABM introduces an individual state and reset scope; Ant adds a second trace channel. Boids divides its three forces into successive passes. PSO begins with a fixed objective before discussing a changing novelty archive. Ecology closes with a small event account. These boundaries prevent every hall from becoming another complete swarm framework.

The seven paragraphs are editable in `doc/book/course/execution-plan/plan.json` and visible through the tutorial-plan interface. The sequence does not need reordering to make this progression. Artifact membership does not imply that every exhibit must be taught.
'''
write(O/'sequence-plan.md',synopsis)

p=M/'final.md';f=text(p)
needle='Choose one bright connection in the colony and follow it with your eyes.'
replacement='The live table gives you an overhead view of the colony. Choose one bright connection and follow it with your eyes.'
if needle in f:write(p,f.replace(needle,replacement))
technical=f'''# Physarum — a trace outside the point

The existing `PhysarumColony` museum token now opens a 2.95 m table with a live private-viewport view of the original 50 m colony. Its 300-agent scene, scripts, terrain, per-agent seeds, diffusion and 20-second anchor carousel are unchanged. The private world prevents those physics bodies and the relief surface spilling into neighbouring halls. The lowercase legacy registry alias still opens the original full-size scene. The caption identifies this as a live overhead view. The table occupies map cell (4,2), yaw 90; map_data and em_plan agree.

The student study is a separate six-PointBody construction in the museum. It is temporarily instantiated in the native probe at world/map (8.5,0,3.0), yaw -90; it is supplied as study.tscn and is not permanently added to the hall. The inherited point source is byte-identical to the preceding soft-body hand study. Cells are 0.16 m, field coordinates map y to local -Z, sampling distance is 1.5 cells, and each 0.15-second tick moves 0.45 cells. All agents read old field values, then the field retains 0.92 or 0.55 of each value and accepts deposits capped at 8. The learner chooses periodic boundaries and straight ties; there is no diffusion, food, anchor emission or random wandering. This is a declared reduction, not an exact reconstruction of the whole production colony.

{len(code['checks'])} exact-source Godot checks pass, including deterministic tick40 replay, reversed agent order, 1,500 variation steps, three deliberately faulty models, real button signals and synthetic XRTools pickup/trigger/release in a transformed host. {len(room['checks'])} native checks pass, covering private-world separation, retained original parameters, actual deposition, complete learner construction, comparable control runs and supported approaches. Native photographs show both the live table and the temporary learner study.

Testing caught a GDScript built-in name collision and an unused Label3D allocation; both are fixed. Room captures caught initial overlap with a wall and the assumption that the centre line was a clear aisle. The two displays now face the shared aisle in the entry bay. Approach samples are checked; this is not a certification of every passage, teleport or headset experience. A pre-existing UID-resolution error and engine shutdown warnings remain in the native startup log; there are no GDScript errors in the final run. Independent learner comprehension and physical Quest performance remain untested.

Reproduce: `python tools/write_swarm_physarum.py`, `python tools/test_swarm_physarum.py`, `python tools/seat_swarm_physarum.py`, then `python tools/run_encounter_probe.py SwarmIntelligence_PhysarumColony --sequence swarmintelligence --render --no-bridges --output-tag swarm-first-lesson --probe tools/probes/swarm_physarum_room.gd`, then `python tools/publish_swarm_physarum.py`.
'''
write(M/'technical.md',technical)
for folder in ['assets','museum','after']:(O/folder).mkdir(exist_ok=True)
for p in RUN.glob('*.png'):shutil.copy2(p,O/'assets'/p.name)
baseline=R/'ada_run/encounter_pilot/SwarmIntelligence_PhysarumColony/swarm-baseline'
for name in ['above-before.png','entry-before.png','colony-before.png']:shutil.copy2(baseline/name,O/'assets'/name)
for name in ['report.json','engine.log','source_manifest.json','spec.json']:shutil.copy2(RUN/name,O/'museum'/name)
shutil.copy2(baseline/'report.json',O/'museum/baseline-report.json')
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
 shutil.copy2(M/name,O/'after'/name)
 if name.endswith('.md'):shutil.copy2(M/name,O/name)

css='''*{box-sizing:border-box}body{margin:0;background:#f3f1eb;color:#262930;font:18px/1.6 Georgia,serif}nav{position:sticky;top:0;background:#252d35;padding:12px 4vw;z-index:9;display:flex;gap:22px;flex-wrap:wrap;font:14px/1.4 system-ui}nav a{color:#fff}main{max-width:1140px;margin:auto;padding:45px 35px}h1{font-size:clamp(32px,5vw,62px);line-height:1.06;max-width:880px}h2{font-size:30px;line-height:1.2;margin-top:48px}h3{font:700 21px system-ui}a{color:#285c72}p{max-width:78ch}pre{padding:22px;background:#15232c;color:#e5ecec;overflow:auto;font:13px/1.6 Consolas,monospace}code{font-family:Consolas,monospace}img{max-width:100%;display:block}figure{margin:25px 0}figcaption,.meta{font:14px/1.55 system-ui;color:#576773;margin:12px 0}.grid{display:grid;grid-template-columns:1fr 1fr;gap:28px}.card{background:#fff;border-top:4px solid #91a6a6;padding:20px}.card h2{font-size:24px;margin-top:5px}.done{border-color:#529f79}.tag{font:700 12px system-ui;letter-spacing:.09em;color:#61717b;text-transform:uppercase}.parallel{max-width:1800px;display:grid;grid-template-columns:1.1fr 1fr;gap:48px}.parallel article{min-width:0}.parallel h1{font-size:34px}.parallel pre{font-size:12px}.notice{padding:20px;background:#dee8e4;border-left:4px solid #40866d}@media(max-width:850px){.grid,.parallel{display:block}.card{margin:15px 0}main{padding:25px 18px}nav{position:static}}'''
write(O/'style.css',css)
nav='<nav><a href="index.html">Swarm</a><a href="sequence.html">Seven-hall plan</a><a href="tutorial.html">Full tutorial</a><a href="final.html">Reflection</a><a href="parallel.html">Facing pages</a><a href="technical.html">Tests & scope</a><a href="swarm-first-review.zip">Review ZIP</a></nav>'
def render(md):return markdown.markdown(md,extensions=['fenced_code','tables','footnotes'])
def page(name,title,body,cls=''):
 write(O/name,'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style>'+nav+'<main class="'+cls+'">'+body+'</main></html>')
for name in ['tutorial','final','technical']:page(name+'.html','Swarm · '+name,render(text(O/(name+'.md'))))
page('sequence.html','Swarm · seven-hall plan',render(synopsis))
page('parallel.html','Swarm · tutorial beside reflection','<article>'+render(text(M/'tutorial.md'))+'</article><article>'+render(text(M/'final.md'))+'</article>','parallel')
cards=''
for i,(mid,title,artifact,focus,summary) in enumerate(route):
 cards+=f'<article class="card {"done" if i==0 else ""}"><div class="tag">{i+1} / {"Tested draft" if i==0 else "Next lesson plan"}</div><h2>{html.escape(title)}</h2><p>{html.escape(focus)}</p><div class="meta">{html.escape(artifact)}</div><details><summary>Lesson paragraph</summary><p>{html.escape(summary)}</p></details></article>'
body=f'''<div class="tag">Endless Museum / Swarm Intelligence / 10 October 2026</div><h1>A trace outside the point</h1><p>The same sphere now meets a record left by another sphere. Its next turn can depend on something that happened before it arrived.</p><p class="notice">First hall implemented: <strong>{len(code['checks'])} code checks and {len(room['checks'])} native checks pass</strong>. The other six halls have focused lesson plans; their complete tutorials will follow one at a time.</p><figure><img src="assets/student-trace.png" alt="Six-point student study in the real Physarum museum hall"><figcaption>Exact printed student code, temporarily placed in the museum. The points are inherited; the shared trace is new.</figcaption></figure><h2>One body, seven relations</h2><p>Trace → supplied direction → neighbours → state → two channels → scored memory → continuing support. Then Graph Theory, followed by Machine Learning.</p><div class="grid">{cards}</div><h2>Give the colony room</h2><p>The original 50-metre relief crossed the hall's walls. Its existing simulation now runs in a private world, shown on a live tabletop. The student study occupies a separate bay for these captures.</p><div class="grid"><figure><img src="assets/above-before.png" alt="Before: oversized colony across the hall"><figcaption>Before — actual museum capture.</figcaption></figure><figure><img src="assets/above-after.png" alt="After: two bounded displays in the hall"><figcaption>After — live colony at left; temporary learner study at right.</figcaption></figure></div><figure><img src="assets/live-colony-table.png" alt="Original Physarum colony viewed live on a table"><figcaption>The 300-agent exhibit keeps its original movement, field and anchor carousel. This is a live view, not a baked picture.</figcaption></figure><h2>Change what the ground keeps</h2><div class="grid"><figure><img src="assets/student-trace.png" alt="Tick40 retaining 92percent"><figcaption>Tick 40 / 92% retention.</figcaption></figure><figure><img src="assets/student-short-memory.png" alt="Tick40 retaining 55percent"><figcaption>Tick 40 / 55% retention. Same starting positions; different persistence.</figcaption></figure></div><h2>What changed in the writing</h2><p>The incomplete fragments and shortest-path promise are replaced by three complete scripts, a declared boundary and tie rule, a visible readout, and a testable hand experiment. The reflection keeps its focus on environmental memory; its unsupported agent count is removed and its opening now names the live table.</p><p><a href="sequence-plan.md">Download all seven lesson paragraphs</a> · <a href="http://localhost:3003/tutorial-plan?map=SwarmIntelligence_PhysarumColony&view=summaries">Open the editable tutorial plan</a></p><p class="meta">Author-operated engine tests and synthetic XRTools interaction. Physical headset usability and independent learner understanding remain open. Approach checks cover these displays, not every museum passage.</p>'''
page('index.html','Swarm · a trace outside the point',body)
write(O/'README.md','# Swarm first review\n\nOpen index.html. Tutorial and final are separate and side by side. sequence-plan.md contains all seven paragraphs. Only Physarum is implemented and tested in this package.\n\nThe printed scripts depend on the prepared Ada project, XRTools and the named museum push_button scene; this ZIP is a review bundle, not a standalone exported game.\n')
with zipfile.ZipFile(O/'swarm-first-review.zip','w',zipfile.ZIP_DEFLATED) as z:
 for name in ['README.md','index.html','sequence.html','sequence-plan.md','sequence-plan.json','tutorial.html','tutorial.md','final.html','final.md','parallel.html','technical.html','technical.md','style.css','checks.json','code.log']:
  z.write(O/name,name)
 for folder in ['printed','assets','museum']:
  for p in (O/folder).rglob('*'):
   if p.is_file():z.write(p,p.relative_to(O))
write(R/'doc/book/course/storyboards/SWARM-HANDOFF.md',f'''# Swarm / 10 October 2026

User: make Swarm sequence after GT→ML reordering. Seven halls retained. First full lesson: Physarum; next FlowFields. See `doc/book/iterations/2026-10-10-swarm-a-trace-outside/sequence-plan.md` for all paragraphs; canonical editable plan.json updated. Other six are plans, not passed tutorials.

Carry exact PointBody from Topology_Entropy_Morphogenesis. First study samples three cells, strict strongest-side turn, moves .45 cells, wraps 16×16, retains .92/.55, deposits cap8. No diffusion/food/anchors/random tie. Positions and headings are per agent; trace is shared. Display uses .16m cells and named supplied buttons. Holding pauses all; trigger stamps; release projects to local XZ plane. {len(code['checks'])} code / {len(room['checks'])} native checks pass. Three faults rejected; synthetic XR only.

Existing PhysarumColony token now points to a bounded tabletop adapter; original raw scene/scripts unchanged and isolated in a private viewport. Lowercase legacy alias still raw. Map/em_plan cell4,2 yaw90. Learner study temporarily placed at8.5,0,3.0 yaw-90 in captures, not permanently installed. Scope/practical limits are in technical.md. Use tools/write_swarm_physarum.py, test_swarm_physarum.py, seat_swarm_physarum.py, probes/swarm_physarum_room.gd, publish_swarm_physarum.py. Preserve unrelated work.
''')
print('Published first Swarm review, seven paragraphs, facing pages and ZIP.')
