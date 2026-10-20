from pathlib import Path
import json, html, shutil, hashlib, re
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
RUN=ROOT/'ada_run/encounter_pilot/Random_Entropy/hall-order-walk'
MAP=ROOT/'commons/maps/Random_Entropy'
report=json.loads((RUN/'report.json').read_text(encoding='utf8'))
assert report['passed']
placement=json.loads((HERE/'placement.json').read_text());obs=report['observations']
names={'shannon_entropy_meter':'Shannon ledger','entropy_jar_states':'Four mixing jars','entropy_jar':'Shakeable jar','entropy_sorting_table':'Four-cube sorting table','entropy_compartments':'Two compartments','entropy_axiom':'Displaced points','entropy_ruin':'Physical ruin','signal_room':'Signal room','prefab_disorder':'Hybrids + butterflies','hardware_entropy_decay':'Surface wear','weathering_wall':'Weathering wall'}
reasons=['Counts stay while neighbours change.','A place can be recorded in more than one way.','After watching mixtures, intervene directly.','Count every possibility before accepting a formula.','Expand four places to sixteen; preserve a full state.','Step into an arrangement and change viewpoint.','Change a support; let contact decide what follows.','Return to counts and neighbours at room scale.']
for name in ['hall-plan','arrival','first-bay','jar-approach','large-studies','ruin-and-wall','through-doorway']:
    shutil.copy2(RUN/(name+'.png'),HERE/(name+'.png'))
shutil.copy2(ROOT/'ada_run/encounter_pilot/Random_Entropy/hall-order-before/hall-plan.png',HERE/'before-hall.png')
shutil.copy2(RUN/'report.json',HERE/'museum-report.json')

# Diagram uses the installed meshes' measured envelopes and the native route.
# It is a plan, not a render or a claim about human comfort.
scale=18;ox=35;oy=50
def xy(x,z):return f'{ox+x*scale:.2f},{oy+z*scale:.2f}'
svg=['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 525 1270" role="img" aria-label="Entropy Workshop: enter at the top, eight main encounters, two side stops, doorway and exit at the bottom">',
'<defs><marker id="arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z" fill="#346658"/></marker></defs>',
'<rect width="525" height="1270" fill="#f4f1e9"/>']
def rect(x,z,w,h,fill,stroke='#a69f94'):
    svg.append(f'<rect x="{ox+x*scale:.2f}" y="{oy+z*scale:.2f}" width="{w*scale:.2f}" height="{h*scale:.2f}" fill="{fill}" stroke="{stroke}" stroke-width="1.4" rx="2"/>')
rect(0,0,25,66,'#e5dfd3');rect(1,1,23,32,'#faf8f2');rect(1,34,23,31,'#faf8f2');rect(11,33,3,1,'#faf8f2','#faf8f2')
for z in range(5,65,5):
    svg.append(f'<text x="12" y="{oy+z*scale}" font-family="system-ui" font-size="10" fill="#766e66">{z}</text>')
for key,box in obs['artifacts'].items():
    a=box['min'];b=box['max'];optional=key in placement['optional'] or key=='weathering_wall'
    rect(a[0],a[2],b[0]-a[0],b[2]-a[2],'#e4d5ed' if optional else '#d0e3d8')
pts=' '.join(xy(*p) for p in obs['ordered_route'])
svg.append(f'<polyline points="{pts}" fill="none" stroke="#346658" stroke-width="2.8" stroke-linejoin="round" marker-end="url(#arrow)"/>')
# Side paths start from a nearby main-route point, and are independently verified.
for key in ['hybrids','hardware wear','weathering wall']:
    path=obs['routes'][key];shared={tuple(p) for p in obs['ordered_route']}
    at=max(i for i,p in enumerate(path) if tuple(p) in shared)
    svg.append(f'<polyline points="{" ".join(xy(*p) for p in path[at:])}" fill="none" stroke="#8b639d" stroke-width="2" stroke-dasharray="4 4"/>')
for i,key in enumerate(placement['main_order']+placement['optional']+['weathering_wall']):
    box=obs['artifacts'][key];x=(box['min'][0]+box['max'][0])/2;z=(box['min'][2]+box['max'][2])/2
    number=str(i+1) if i<8 else ['A','B','C'][i-8]
    fill='#346658' if i<8 else '#805895'
    svg.append(f'<circle cx="{ox+x*scale}" cy="{oy+z*scale}" r="12" fill="{fill}" stroke="#fff" stroke-width="2"/><text x="{ox+x*scale}" y="{oy+z*scale+4}" text-anchor="middle" font-family="system-ui" font-size="13" font-weight="700" fill="#fff">{number}</text>')
svg+=['<g font-family="system-ui" font-size="13" fill="#2d473b">',f'<text x="{ox+8.5*scale}" y="28" text-anchor="middle">ENTER ↓</text>',f'<text x="{ox+12.5*scale}" y="{oy+33*scale-10}" text-anchor="middle">3 m doorway</text>',f'<text x="{ox+12.5*scale}" y="{oy+66*scale+25}" text-anchor="middle">EXIT ↓</text>','</g></svg>']
(HERE/'plan.svg').write_text(''.join(svg),encoding='utf8')

style='''*{box-sizing:border-box}body{margin:0;background:#f4f1e9;color:#296731;font:17px/1.55 system-ui}main{max-width:1420px;padding:24px;margin:auto}h1{font:42px/1.12 Georgia,serif;margin:0 0 12px}h2{font:28px/1.2 Georgia,serif;margin-top:34px}p{max-width:85ch}a{color:#625278}nav{display:flex;gap:22px;flex-wrap:wrap;margin:16px 0}.overview{display:grid;grid-template-columns:minmax(320px,.85fr) 1fr;gap:34px}.plan{width:100%;background:#f4f1e9}.sequence{list-style:none;padding:0}.sequence li{position:relative;padding:0 0 20px 44px}.badge{position:absolute;left:0;top:1px;background:#346658;color:#fff;border-radius:50%;width:30px;height:30px;text-align:center;font-size:17px;line-height:30px}.optional .badge{background:#805895}.sequence p{margin:2px 0;font-size:16px;color:#58635d}.note{border-left:4px solid #7f648b;padding:12px 18px;background:#ebe2ed}figure{margin:0}figure img{width:100%;display:block}figcaption{font-size:15px;background:#e5e0d5;padding:12px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}fieldset{border:0;padding:0;margin:16px 0}input{accent-color:#346658}label{display:inline-block;padding:7px 12px;margin:6px 10px 15px 2px;border:1px solid #aaa096;cursor:pointer}input:checked+label{background:#346658;color:white}.frames figure{display:none}#arrival:checked~.frames .arrival,#jars:checked~.frames .jars,#points:checked~.frames .points,#ruin:checked~.frames .ruin,#door:checked~.frames .door{display:block}.frames img{max-height:76vh;object-fit:contain;background:#303a42}details{margin-top:20px}summary{cursor:pointer;font-weight:600}pre{white-space:pre-wrap;font:17px/1.65 system-ui}@media(max-width:800px){main{padding:15px}.overview,.pair{grid-template-columns:1fr}.plan{max-width:525px}h1{font-size:33px}}'''
body='''<h1>One hall, a reason to continue</h1><p>Entropy Workshop has a route for all ten artifacts. Enter at the top; pass from counts and mixtures to arrangements and structural consequences, then through the doorway into the signal room.</p><nav><a href="/long-museum/writing-wall?map=Random_Entropy">Move the magnets in the writing wall</a><a href="#views">Native views</a><a href="#texts">Current text and plan</a></nav><div class="overview"><a href="plan.svg"><img class="plan" src="plan.svg" alt="Numbered plan with eight main encounters, three optional comparisons and the continuous walking route"></a><div><h2>Room and final share this order</h2><ol class="sequence">'''
for i,key in enumerate(placement['main_order']):
    body+=f'<li><span class="badge">{i+1}</span><strong>{names[key]}</strong><p>{reasons[i]}</p></li>'
body+='</ol><h2>Side encounters stay available</h2><ul class="sequence optional">'
for tag,key,reason in [('A','prefab_disorder','Compare intact objects, separated parts and seeded hybrids. Gallery, replay, rehearsal and the local butterflies stay with it.'),('B','hardware_entropy_decay','Movement changes surface wear. An optional comparison with no thermodynamic gauge.'),('C','weathering_wall','Beside the physical ruin: compare arranged dismantling with contact-driven collapse.')]:
    body+=f'<li><span class="badge">{tag}</span><strong>{names[key]}</strong><p>{reason}</p></li>'
body+='''</ul><p class="note">Green: the main walk. Purple dashes: optional approaches. Shapes show measured visible footprints, including stages and consoles. This diagram is a plan; the photographs below are actual Godot captures.</p><p>Both bays are 25 m wide. The ten-metre point enclosure has its own floor area; the ruin and weathering wall stand together. The first bay ends at a three-metre doorway. All ten artifact tokens and their experimental configurations are retained.</p><p><strong>Reload Random_Entropy to test.</strong> The museum now arrives before the ledger at (8,2), clear of the old threshold collision. The grid entrance remains at (8,0).</p></div></div><h2 id="views">Walk the views</h2><fieldset><legend>Native museum captures</legend>'''
shots=[('arrival','Arrival','arrival','The ledger introduces the route. Jars, the hand jar and the next tables remain visible beyond it.'),('jars','Jars','jar-approach','Four broad jars on their shared plinth, with clear viewing positions.'),('points','Point enclosure','large-studies','The large enclosure has its own floor area and open ends; the western side remains a bypass.'),('ruin','Ruin + wall','ruin-and-wall','Physical columns and the separately authored weathering wall can be compared without overlapping.'),('door','Through the doorway','through-doorway','The doorway frames the signal room. Its controls can be approached before taking either side passage.')]
for i,(key,title,shot,cap) in enumerate(shots):body+=f'<input type="radio" name="shot" id="{key}" {"checked" if i==0 else ""}><label for="{key}">{title}</label>'
body+='<div class="frames">'
for key,title,shot,cap in shots:body+=f'<figure class="{key}"><img src="{shot}.png" alt="{html.escape(cap)}"><figcaption>{cap}</figcaption></figure>'
body+='''</div></fieldset><h2>Before and after</h2><div class="pair"><figure><img src="before-hall.png" alt="Earlier narrow first bay with crowded point enclosure"><figcaption>Earlier: the point enclosure crowded the entrance studies and exceeded the narrow bay.</figcaption></figure><figure><img src="hall-plan.png" alt="New full-width first bay with separate study areas"><figcaption>Now: independent footprints, usable approaches and a continuous route. Cameras use different framing to show their respective layouts.</figcaption></figure></div><h2>What is verified</h2><p><strong>96 native checks pass.</strong> All ten artifacts and the wall load. Installed visible envelopes do not overlap. A 0.6 m wide, 1.8 m tall capsule reaches every tested approach; each route segment is checked every 0.1 m. Floor support, the authored entry, doorway, exit and the relocated hybrid rehearsal’s route to the ledger pass. Negative controls confirm that the walls and jar plinth block the probe. Grid pathfinding also passes with zero issues.</p><p>These checks concern the installed starting state. They do not prove headset comfort, performance or a compelling sequence. Freely carried stones can alter a route. The next human trial should record a missed object, blocked view, tiring gap, unwanted backtracking or the first encounter that fails to create a reason for the next.</p><p>The first 48-value seed bench remains the research pilot. No commit or push is included.</p><h2 id="texts">Room, writing wall and current text</h2>'''
for name in ['final.md','tutorial.md','plan.md','artifacts.md']:
    text=(MAP/name).read_text(encoding='utf8');(HERE/name).write_text(text,encoding='utf8')
    body+=f'<details><summary>{name}</summary><pre>{html.escape(text)}</pre></details>'
body+='<nav><a href="museum-report.json">Native check receipt</a><a href="README.md">Change record</a><a href="../2026-10-16-plinth-and-physical-ruin/index.html">Previous jars and ruin revision</a></nav>'
(HERE/'index.html').write_text('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Entropy Workshop · A route for every artifact</title><style>'+style+'</style><main>'+body+'</main></html>',encoding='utf8')
old=json.loads((HERE/'before-map_data.json').read_text(encoding='utf8'));now=json.loads((MAP/'map_data.json').read_text(encoding='utf8'))
def inventory(d):
    return {t.split(':')[0].split('#')[0]:[t.split('#')[0].split(':')[2:],t.split('#')[1:]] for r in d['layers']['interactables'] for t in r if t.strip()}
assert inventory(old)==inventory(now),'An artifact or configuration was lost'
order=re.findall(r'<!-- @([a-z_]+) -->',(MAP/'final.md').read_text(encoding='utf8'))
assert order==placement['main_order']
wall=json.loads((MAP/'writing_wall.json').read_text(encoding='utf8'));assert wall['order'][:8]==order
sources=[p for p in MAP.iterdir() if p.name in ['map_data.json','writing_wall.json','final.md','tutorial.md','artifacts.md','plan.md','intent.md','summary.md','technical.md','relationship.md']]+[ROOT/'commons/data/museum/em_plan.json',ROOT/'doc/book/course/text-plans/Random_Entropy/research-brief.md']
(HERE/'manifest.json').write_text(json.dumps({'checks':96,'grid_pathfinder':'1 OK, 0 FAIL, 0 issues','same_artifacts_and_hash_options':True,'final_and_wall_order_match':True,'sha256':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sources}},indent=2),encoding='utf8')
(HERE/'README.md').write_text('''# Entropy Workshop: a route for every artifact

Requested 16 October 2026: order the whole hall for all artifacts. Ten map artifacts and the separate architectural weathering wall are retained. Experimental parameters, seeds, gallery records, butterfly count and apparatus implementations are unchanged by this layout pass.

## Layout

Both bays are now 25 m wide. The first bay ends at row 33 with a three-metre doorway at columns 11–13. Main order: Shannon ledger (8,5), four jars (5,8), live jar (12,8), four-cube sorting table (5,14), two-compartment apparatus (11,14), point enclosure (17,21), ruin (8,29), signal room (12,48). Optional: hybrids (19,10), hardware wear (3,19). West weathering wall starts at row 26 for six metres. The map, this map's generated museum-plan row and writing wall agree. Current final anchors now include the four jars separately before the hand jar. Tutorial, plan, inventory, summary, intent, technical overview and research brief reflect the route.

The old museum arrival at grid s=(8,0) intersected threshold collision. A museum-specific sp=(8,2) puts the portal frame at z1.35 and the landing at z2.5, before the ledger. The legacy grid s remains. The exit t=(12,64) keeps the grid's void contract; museum.floor_cells supplies its supported floor. Grid pathfinding now passes without the earlier exit-height warning. Production portal checks confirm entry and exit without fallback.

## Evidence

`museum-report.json`: 96 native checks pass. All ten artifacts plus weathering wall are found in the actual museum. Visible mesh envelopes (excluding text labels) fit their room and do not overlap. A 0.6 m diameter, 1.8 m tall capsule with floor-support rays checks every named approach. A 0.5 m path grid finds routes, then every segment including endpoint connections is checked at intervals no larger than 0.1 m. The ordered route crosses the doorway and reaches the exit. Wall/plinth negative controls fail clearance as intended. The optional ghost's existing path planner still reaches the ledger. Native captures were inspected.

Earlier debug runs found a probe coordinate error: segment-local space includes a four-metre vestibule; map coordinates require that offset. The final probe uses map_world for all support/collision positions and room cameras. An early arrival assertion also defaulted a missing invalid flag incorrectly; the final test requires a nonempty authored sp entry with invalid=false, plus the production support check. These were probe errors, not hidden layout exemptions.

The route tests apply to the settled starting state. Moved stones and human activity can change it. Headset comfort, Quest performance, human understanding and whether one encounter creates a need for the next remain untested. The 48-value seed bench remains the first research pilot. No commit or push requested.

## Repeat

Run `python tools/run_encounter_probe.py Random_Entropy --sequence randomness --render --no-bridges --output-tag hall-order-walk --probe doc/book/iterations/2026-10-16-entropy-hall-order/walk_probe.gd`, then `python tools/map_pathfinder.py check Random_Entropy --verbose`, then this folder's `publish.py`. `arrange.py` is the layout migration; `update_texts.py` is the one-time editorial migration, with final copy edits applied afterward. Do not rerun the editorial migration on a later edition.
''',encoding='utf8')
state=ROOT/'doc/book/STATE.md';s=state.read_text(encoding='utf8')
heading='## A route for every Entropy Workshop artifact · 16 October 2026'
if heading not in s:
    entry=heading+'\n\nThe [hall-order review](iterations/2026-10-16-entropy-hall-order/index.html) widens the first bay to 25 m and gives all ten artifacts separate footprints. Shared room/final order: ledger → four jars → hand jar → four cubes → compartments → points → ruin → signal room. Hybrids with local butterflies and hardware wear remain side stops; the weathering wall stands beside the physical ruin. Museum arrival moves to sp=(8,2), before the ledger; the doorway at row 33 is three metres wide. All experimental configurations and the first 48-value pilot remain. 96 native layout, approach, route, portal and ghost-handoff checks pass; grid pathfinding has zero issues. Current text, writing wall and plan follow the placements. Next: walk it in VR and record the first missed encounter, tiring gap or transition without a reason to continue. No commit or push requested.\n\n'
    s=s.replace('# STATE — the book\'s re-entry point\n\n','# STATE — the book\'s re-entry point\n\n'+entry,1);state.write_text(s,encoding='utf8')
print('Published hall order: 96 native checks, ten artifacts retained, final/wall order synchronized.')
