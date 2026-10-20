"""Publish a source-checked sequence review using existing native photographs."""
from pathlib import Path
import hashlib, html, json, shutil
import markdown

R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-10-swarm-sequence-review'
C='../2026-10-10-swarm-complete-readings/'

def write(p,s):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_bytes(s.encode('utf8'))
def read(p): return json.loads(p.read_text(encoding='utf8'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def md(s): return markdown.markdown(s,extensions=['extra','sane_lists'])

evidence=read(O/'sequence-checks.json')
assert evidence['passed'] and evidence['completed'] and evidence['same_pointbody_all_seven']
names=['Physarum','Flow Fields','Boids','Agent-Based Modeling','Ant Colony','Particle Swarm','Population Support']
focus=['A trace outside the body','A direction supplied to the body','Nearby bodies as a reference','A state carried by the body','Two channels in the ground','A position remembered for its score','An account of what sustains the population']
models=['trail.gd','field.gd','flock.gd','foragers.gd','colony.gd','swarm.gd','account.gd']
images=['student-trace','student-turn','three-requests','carrying','among-points','memory','support']
implementation=[
 'Existing Physarum colony retained. New small teaching model: trail.gd; it omits the exhibit’s diffusion and anchors.',
 'Existing FlowFieldMain retained. New small teaching model: field.gd; prepared direction patches replace the exhibit’s route-building scenarios.',
 'Existing open flock, aquarium and controls retained. New small teaching model: flock.gd; its shared snapshot, bounds and formulas are declared choices.',
 'Existing colony retained. New small teaching model: foragers.gd; finite food and recruitment are omitted to isolate state transitions.',
 'New permanent ant_colony_walk artifact replaces the AntColonyV2 placement here. Its colony.gd is a teaching model; the original artifact source is preserved.',
 'New permanent particle_swarm_walk tutorial artifact. Existing fitness and self-organization displays remain as comparisons. swarm.gd is new teaching code.',
 'New population_account_walk display and observer around the existing ecosystem.gd simulation. The ecosystem algorithm is reused unchanged; account.gd is the new learning operation.'
]
summaries=[
 'Start beside the existing colony. Bring the familiar point and addressed grid; add a scalar trace that survives the body that deposited it. Predict the three sensor readings, move a point and leave a mark, then compare retention from the same start. The tutorial makes read, fade and deposit executable. The reflection asks how an abandoned route remains available. Carry the body and field lookup onward; the next field will contain directions supplied from outside.',
 'Keep the point and grid address, replace the scalar trail with a vector, and use the velocity integration learned in Forces. Desired minus current velocity gives a bounded correction. Change one cell and let two points read it; their passage must leave it unchanged. Reverse the patch and predict the first turn. The reflection distinguishes received organisation from collective agreement. Carry steering onward; neighbours will provide its input next.',
 'Keep bounded steering but remove the direction grid. Select neighbours, exclude self, and calculate separation, alignment and cohesion from one shared snapshot. Move a point across a radius, then halve one weight and predict the next velocity. The reflection follows conflicting requests and different boundaries, including the flock beyond the museum walls. Keep these tools available; the next study retains the body and update discipline while setting the flocking requests aside.',
 'Return to Physarum’s shared trace with the same point class. Add one Boolean: searching or carrying food. Contact changes which information the point uses, and a carried green cube makes that state visible. Compare replacing the agents with clearing their environment; test a slower return from a stated starting state. The reflection stays with inherited traces and the difference between a response and an intention. The navigator companion is optional. Carry the state and trace into two-channel coordination.',
 'Walk among the enlarged points. Keep the carry flag and three sensors; split the ground into home and food fields. A searcher reads food and writes home; a returner does the reverse. Replace bodies while preserving their marks, and independently halve a deposit. The tutorial exposes indirect coordination; the reflection asks what a traveller inherits and which visitor actions the field ignores. No shortest-route result is claimed. Next, replace the trails with scored memories while keeping PointBody.',
 'Keep the sphere, position, velocity and weighted vector operations. Replace colony state with personal and shared best-position records. Score the starting population before moving, then change the objective while keeping current bodies and resetting their memories. Remove the social pull and predict the changed displacement. The reflection asks what “best” permits and excludes. Keep record inspection for the final hall; that hall supplies another model rather than extending this optimizer.',
 'Enter the supplied ecosystem with the same PointBody representation. The new work is a short account: initial population plus births, minus losses, plus supplied bodies. Store copied events and reconcile the result with the visible population. Omit supply from the calculation and predict the gap while the gold-ringed bodies remain. The reflection makes support visible without treating dependence as failure. This is the sequence’s accounting capstone; the distinction between kinds of relation carries into Graph Theory.'
]
transfer=[
 'Move one starting position; predict its three sampled cells.',
 'Reverse the direction patch; predict the sign of the first turn.',
 'Halve alignment’s weight; predict velocity (0.95, 0.1).',
 'Halve return speed; predict position (7.9925, 8).',
 'Halve deposit; distinguish 0.25 directly from 0.249375 on a tick.',
 'Remove social pull; predict (0.185, 0.1) in the stated fixture.',
 'Omit supplied bodies; predict gap 5 in the account fixture.'
]
cards=[]
table='| Hall | New operation | Independent change | Fresh checks |\n| --- | --- | --- | --- |\n'
review='''# Swarm — where coordination lives

The seven-hall sequence holds. Each lesson changes the information available to a recognisable point: trace, supplied direction, neighbours, internal state, two traces, scored memory, then a population account. It builds capacity by returning to earlier tools for a different purpose. It does not need another algorithm to fill a gap.

The strongest continuous passage is ABM → Ant Colony: the carry flag changes which field is read and written. The largest changes are Boids → ABM and PSO → Population Support. These are deliberate changes of model. The revised handoffs now say what is kept and what is set aside.

## Existing artifacts or new ones?

Both. The first four halls retain their existing exhibits and add smaller teaching reconstructions. Ant Colony and PSO introduce new permanent tutorial artifacts. Population Support adds a new display and account around the existing ecosystem algorithm, which remains unchanged. The exact status is stated on every hall card below.

The same PointBody file is reused throughout; that does not mean that every original artifact’s simulation code is reused. The 265 fresh checks execute the printed reconstructions. They are not a claim that every existing exhibit was reconstructed by the student or retested in this pass.

## Earlier handoff corrections

Six short prose corrections: the opening now returns to the actual Soft Bodies ending; Boids no longer implies that its neighbour selector runs in ABM; Ant Colony explicitly gives way to scored memories; both PSO texts point to the population account; the closing release description respects paused playback. Three editable plan handoffs are updated. Printed GDScript, museum geometry, algorithms, plan decisions and baseline records are unchanged.

## What the student brings

This sequence follows the earlier museum work. PointBody, pickup, local coordinates, vectors, velocity integration, arrays, loops, conditions, state, signals and seeded comparisons are available tools. The old/next update distinction returns from Cellular Automata. Keep the prepared museum and named XRTools/button dependencies; these files do not form an empty-project starter.

## Seven lesson summaries

'''
plan=read(R/'doc/book/course/execution-plan/plan.json')
rows=[]
for i,(h,name,subject,summary,variation,model,img) in enumerate(zip(evidence['halls'],names,focus,summaries,transfer,models,images),1):
    id=h['hall'];source=R/'commons/maps'/id
    assert sha(source/'tutorial.md')==h['tutorial_sha256']
    assert sha(source/'final.md')==h['final_sha256']
    report=R/'doc/book/iterations'/h['report']
    (O/'assets').mkdir(exist_ok=True)
    shutil.copy2(report/'assets'/(img+'.png'),O/'assets'/f'{i}-encounter.png')
    above=report/'assets/above-after.png'
    if i==3: above=R/'doc/book/iterations/2026-10-10-boids-observation-balcony/assets/above.png'
    shutil.copy2(above,O/'assets'/f'{i}-above.png')
    size=len((R/'doc/book/studies/swarm-through-the-hands'/id/model).read_text(encoding='utf8').splitlines())
    stage='Temporary learner study beside the existing exhibit.' if i<5 else 'Permanent full-size tutorial installation.'
    row=next(r for r in plan['lessons'] if r['id']==id)
    rows.append(row)
    review+=f'### {i}. {name} — {subject}\n\n{summary}\n\n**Artifact and code:** {implementation[i-1]}\n\n'
    review+=f'![{name}: existing native museum capture](assets/{i}-encounter.png)\n\n*{stage} Photograph from the recorded hall run; no new room render in this review.*\n\n'
    table+=f'| {i}. {name} | {subject} | {variation} | {h["checks"]} |\n'
    cards.append(f'''<article id="{html.escape(id)}"><div class="kicker">HALL {i} / 7 · {h['checks']} CHECKS</div>
<h2>{name}</h2><h3>{subject}</h3><p>{summary}</p><p class="carry"><strong>Artifact and code</strong><br>{implementation[i-1]}</p>
<figure><img loading="lazy" src="assets/{i}-encounter.png" alt="{name}: native encounter"><figcaption>{stage}</figcaption></figure>
<details><summary>See the room from above</summary><img loading="lazy" src="assets/{i}-above.png" alt="{name}: overhead museum capture"></details>
<div class="carry"><strong>Try independently</strong><p>{variation}</p></div>
<p class="meta">New model: {model}, {size} lines. Complete rendering and interaction host supplied separately. Current plan decision: {html.escape(row['decision'])}.</p>
<p><a href="{C}tutorial.html#{id}">Full tutorial</a> · <a href="{C}final.html#{id}">Reflection</a> · <a href="http://localhost:3003/tutorial-plan?view=summaries&amp;map={id}">Edit plan</a></p></article>''')

assessment='''## Density and remaining work

The short models range from 28 to 112 lines; their complete hosts add 125–210 lines. Focus comes from separating the new operation from the carried body and supplied display. A learner should first predict one change in the model, then use the complete host to inspect it. Passing the checks does not establish that those explanations are easy for a first-time reader.

The final hall is an accounting capstone. Reconstructing its entire ecosystem would introduce feeding, reproduction and support at once and overload the lesson. Keep that source explicitly supplied, with the observer and its limits available to inspect. Likewise, keep the ABM navigator as a separate optional study.

Spatial consistency remains uneven. The first four learner reconstructions are small comparison studies beside existing exhibits; the last three run as permanent full-size installations. Boids has its separate full-size flock and observation balcony. Making all four earlier lesson hosts permanent is a further implementation task, not something this review claims to have done.

The reflections hold a distinct line: what persists, who supplies direction, who counts as near, what a state can explain, what is inherited, who defines better, and what support makes continuation possible. They need no extra code. The tutorial tests make the corresponding operations inspectable; they cannot settle the reflective questions for the reader.

## Fresh verification

All seven printed tutorials were reconstructed and executed in Godot 4.6 in spine order: **265 checks passed**. Every hall includes an independent code variation and three deliberately faulty versions that the checks detect: 7 variations and 21 faulty versions. PointBody is byte-identical across the seven lessons. Prose changes leave every printed GDScript block unchanged.

This is an author-operated reconstruction, not a second independent AI or a physical headset session. The runs test numerical predictions, model invariants and synthetic XR interactions. Existing native room photographs and room-test reports are retained as earlier evidence; this run did not traverse every portal or recapture the museum. Existing UID/Jolt warnings remain; no script or parse errors occurred in these seven runs.

The next useful review is to give an independent reader the complete tutorial and reflection, ask them to make each stated variation, and record the first assumption they cannot reconstruct. Physical headset comfort, reach and readability need a separate player pass. Keep the order provisional while those observations arrive.

## Short instruction for the next reader

Museum supplied. PointBody unchanged. Read→predict→run→vary. Trace→direction→neighbours→state→two trails→scored memory→population account. Name kept/replaced/supplied/new. No universal agent accumulating all behaviours. Tutorial executable; reflection encounter-led. 265 author-run checks; 7 variations; 21 detected faults. Native photos are earlier evidence. Headset + independent-reader review open. Graph Theory follows, then ML.
'''
review+=assessment+'\n## Transfer checks by hall\n\n'+table
feedback=R/'doc/book/iterations/2026-10-10-swarm-feedback'
if (feedback/'RESPONSE.md').exists():
    assert read(feedback/'sequence-checks.json')==evidence, 'Refresh the feedback receipt first'
    note='''## Response to the external reading

The latest [feedback response](../2026-10-10-swarm-feedback/index.html) adds seven short passages across five tutorials: the changing model behind PointBody, concrete returns to the first four exhibits, the population-level change of question, and an optional investigation with the existing Particle Swarm model. All seven reflections and every printed code block remain unchanged in that pass. The checks below were rerun against these current texts. Room-integration issues remain open.

'''
    review=review.replace('## Existing artifacts or new ones?',note+'## Existing artifacts or new ones?',1)
write(O/'REVIEW.md',review)
write(O/'lesson-plan.json',json.dumps(rows,ensure_ascii=False,indent=2)+'\n')
write(O/'review-data.json',json.dumps([{'hall':h['hall'],'name':n,'focus':f,'summary':s,'variation':v,'implementation':a} for h,n,f,s,v,a in zip(evidence['halls'],names,focus,summaries,transfer,implementation)],ensure_ascii=False,indent=2)+'\n')
changes=read(O/'changes.json')
diff='<h2>Earlier six handoff corrections</h2>'+''.join('<section class="diff"><p class="meta">'+html.escape(c['path'])+'</p><div><p><strong>Before</strong><br>'+html.escape(c['before'])+'</p><p><strong>After</strong><br>'+html.escape(c['after'])+'</p></div></section>' for c in changes)
css='''*{box-sizing:border-box}body{margin:0;background:#f4f1e9;color:#183b40;font:18px/1.65 Georgia,serif}main{max-width:1200px;margin:auto;padding:44px 28px 90px}nav{padding:15px 26px;background:#16383e;color:white;font:14px/1.5 system-ui}nav a{color:#ddf4ef;margin-right:20px}a{color:#12596b}h1{font-size:clamp(38px,5vw,70px);line-height:1.08;max-width:850px}h2{font-size:30px;line-height:1.2}h3{font-size:20px;line-height:1.3;font-weight:normal}p{max-width:900px}.kicker,.meta,figcaption{font:13px/1.55 system-ui}.kicker{letter-spacing:.1em;color:#617b76}.route{border-top:1px solid #aabbb3;border-bottom:1px solid #aabbb3;padding:20px 0;font:17px/1.8 system-ui}.status,.carry{padding:18px;background:#e3ede4;border-left:4px solid #739575}.grid{display:grid;grid-template-columns:1fr 1fr;gap:30px}article{background:white;padding:25px;margin:25px 0}article p{font-size:17px}article h2{margin-bottom:8px}figure{margin:24px 0 12px}img{max-width:100%;height:auto}figcaption{padding-top:8px}details{margin:16px 0;font:14px/1.6 system-ui}summary{cursor:pointer;padding:10px 0}.carry p{margin:8px 0;font-size:15px}.diff{border-bottom:1px solid #b8c2bb;padding:10px 0}.diff div{display:grid;grid-template-columns:1fr 1fr;gap:30px}.diff p{font-size:16px}.diff strong{font:12px system-ui;text-transform:uppercase}table{width:100%;border-collapse:collapse;font:14px/1.5 system-ui}td,th{padding:12px;border-bottom:1px solid #bbb;text-align:left}@media(max-width:780px){.grid,.diff div{display:block}main{padding:25px 16px}article{padding:18px}}'''
body='<div class="kicker">ENDLESS MUSEUM · SWARM INTELLIGENCE · SEQUENCE REVIEW</div><h1>Where coordination lives</h1><p>Seven halls. One recognisable point. A changing relation to what it reads, keeps and leaves behind.</p><p class="route">Trace → direction → neighbours → state → two trails → scored memory → support</p><p class="status"><strong>265 fresh code checks passed.</strong> Museum code unchanged. Seven independent variations and 21 faulty versions tested. Physical headset and independent-reader review remain open.</p>'+md(review.split('## Seven lesson summaries')[0].split('\n',1)[1])+'<div class="grid">'+''.join(cards)+'</div>'+md(assessment)+diff+'<h2>Transfer checks</h2>'+md(table)
page='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Swarm · sequence review</title><style>'+css+'</style></head><body><nav><a href="'+C+'index.html">Complete sequence</a><a href="'+C+'tutorial.html">Tutorial</a><a href="'+C+'final.html">Reflection</a><a href="'+C+'swarm-review.zip">Review ZIP</a><a href="REVIEW.md">Review text</a><a href="sequence-checks.json">Fresh receipts</a></nav><main>'+body+'</main></body></html>'
write(O/'index.html',page)
print('Published seven-hall review with canonical hashes, editable-plan links and existing native images.')
