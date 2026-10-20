"""Publish the Flow Fields spatial pass with native evidence and exact scope checks."""
from pathlib import Path
import copy, hashlib, html, json, shutil
import markdown

R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-11-flow-room-to-move'
H='SwarmIntelligence_FlowFields'
RUN=R/f'ada_run/encounter_pilot/{H}'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
receipts={name:read(RUN/tag/'report.json') for name,tag in [('room','flow-room-final'),('portals','flow-room-portals'),('point','flow-room-point')]}
assert all(r['passed'] for r in receipts.values()),receipts
for tag in ['flow-room-final','flow-room-portals','flow-room-point']:
    log=(RUN/tag/'stdout.log').read_text(encoding='utf-8')
    assert not any(s in log for s in ['SCRIPT ERROR','SHADER ERROR','blocked authored entry','blocked t exit','AntColonyV2 seals']),tag
preserved=read(O/'before/preserved-hashes.json')
assert all(sha(R/p)==v for p,v in preserved.items()),'original source or text changed'
old=read(O/f'before/commons/maps/{H}/map_data.json')
new=read(R/f'commons/maps/{H}/map_data.json')
expected=copy.deepcopy(old)
for x,z in [(10,3),(2,7),(6,7),(10,7)]:expected['layers']['structure'][z][x]='1'
for x,z,t in [(1,1,''),(6,1,'sp'),(6,2,'s'),(9,7,''),(6,8,'t'),(9,8,'')]:expected['layers']['utilities'][z][x]=t
for x,z,t in [(9,2,'ant_colony_table:0:0:1#plinth:0#pin:1'),(9,4,''),(1,6,''),(2,7,'flow_ecosystem_stand:0:0:1#plinth:0#pin:1')]:expected['layers']['interactables'][z][x]=t
expected['map_info']['museum']['portal_exit']={'approach':'from_hall'}
expected['map_info']['museum']['sculpture_clear_rects']=[[1,1,12,9],[11,1,32,14]]
expected['map_info']['description']='A hand-written direction field beside a contained Ant Colony V2 comparison. An open route joins the table, the ecosystem plinth and the walk-in crowd. Entry and exit align with the north and south openings.'
assert expected==new,'undeclared map change'
oldplan=read(O/'before/commons/data/museum/em_plan.json')
newplan=read(R/'commons/data/museum/em_plan.json')
expected=copy.deepcopy(oldplan)
row=next(r for r in expected['plans'] if r['map']==H)
row['tile']=[['4' if c=='w' else '0' if not c else c for c in cells] for cells in new['layers']['structure']]
row['interior_count']=sum(c=='1' for cells in row['tile'] for c in cells)
for source,token,cell in [('AntColonyV2','ant_colony_table',[9,2]),('ecosystem_simulation','flow_ecosystem_stand',[2,7])]:
    a=next(a for a in row['artifacts'] if a['token']==source)
    a.update(token=token,cell=cell,tile_cell=cell,rotation=0,support_height_m=0.0,config={'plinth':'0','pin':'1'})
    a['ruled']['cell']=cell
assert expected==newplan,'undeclared museum-plan change'
for token in ['ant_colony_table','flow_ecosystem_stand']:
    hits=[p for p in (R/'commons/artifacts/registry').glob('*.json') if token in read(p).get('artifacts',{})]
    assert len(hits)==1,(token,hits)
for f in ['assets','evidence']:(O/f).mkdir(exist_ok=True)
for view in ['above','gallery','passage']:
    for label,tag in [('before','flow-room-before'),('after','flow-room-final')]:shutil.copy2(RUN/tag/f'{view}.png',O/'assets'/f'{view}-{label}.png')
for view in ['ant-table','ecosystem']:shutil.copy2(RUN/'flow-room-final'/f'{view}.png',O/'assets'/f'{view}.png')
for name,tag in [('room','flow-room-final'),('portals','flow-room-portals'),('point','flow-room-point')]:
    for src,suffix in [('report.json','checks.json'),('stdout.log','log'),('source_manifest.json','sources.json')]:shutil.copy2(RUN/tag/src,O/'evidence'/f'{name}-{suffix}')
total=sum(len(r['checks']) for r in receipts.values())
counts={k:len(v['checks']) for k,v in receipts.items()}
samples=sum(r['samples'] for r in receipts['room']['observations']['routes'].values())
report=f'''# Room to move

Endless Museum · Flow Fields · 11 October 2026

The hand-written field now has room around it. An oversized ant simulation is contained on a live table, the ecosystem has a low stand, and an open route joins the displays to the full-size crowd court.

## Walk the room

Enter through the north opening. The familiar point and drawing table remain on the west side. Draw a direction and watch the original bodies follow it. Across the room, the ant table gives a different account of a field: its travellers leave the trails that subsequent movement can read. Its pause/play button is at the front-right.

Continue through the east opening to the existing crowd court. Here the field is large enough to walk through. The original crowd, destination point and controls remain. The small ecosystem is an optional comparison on a stand near the south exit. Leave through that exit to Boids; the next hall asks who is near rather than supplying one common direction.

These are different relations between a body and its surroundings. Similar movement is a reason to compare their rules, not evidence that they use the same rule.

## Changes in the actual museum

- **Ant Colony V2:** replaced its oversized room placement with a 1.8 m live table at cell (9, 2). The original 100 ants still run on their 50 m terrain in a private physics world. Rendering their camera view at table size preserves that scale and their existing behaviour.
- **Ecosystem:** moved the unchanged scene to cell (2, 7) on an explicit 80 cm stand. The first attempt used a structural cell that became a full-height post; the native test caught it, and the final stand has clear access.
- **Circulation:** cleared four interior posts, kept the existing ramp, and limited automatic sculptures in the comparison room. The north entry and south exit now align with the existing wall openings. Dimensions and the east crowd court stay the same.
- **Continuity:** the carried point, direction-table code, crowd code, all fourteen canonical tutorial/reflection texts and the sequence order are unchanged. Only the Flow Fields row of the museum plan changed.

## Evidence

**{total}/{total} checks passed:** {counts['room']} room/ant checks, {counts['portals']} portal checks and {counts['point']} repeated point-interaction checks. The room probe sampled {samples} positions across five routes for floor support and standing-capsule clearance. A real CharacterBody walked from entry to the table and exit with gravity enabled.

The portal coordinator completed Flow Fields → Boids → Flow Fields, with supported arrivals and one resident hall. These were supplied crossing requests. The point test used a supplied desktop pickup and stroke, then checked movement after release and retention of the written directions. The ant table advanced through actual physics ticks; pause/resume retained its state.

All {len(preserved)} recorded source/text hashes match. The publisher checks the exact map and plan changes, including preservation of every other hall. No script or shader errors appear in the final runs. Existing UID, Jolt, renderer, loading-time and shutdown warnings remain in the evidence logs. Headset interaction and Quest performance have not been tested.

The before/after photographs use the same cameras in the native Godot museum. Simulation states differ because the systems are running. Reload **Swarm Intelligence → Flow Fields** to try the arrangement.
'''
(O/'REPORT.md').write_text(report,encoding='utf-8')
css='''*{box-sizing:border-box}body{margin:0;background:#121e28;color:#e2ebed;font:17px/1.65 system-ui}nav{display:flex;flex-wrap:wrap;gap:22px;padding:18px 4vw;background:#22323f}a{color:#96e2df}main{max-width:1460px;margin:auto;padding:36px 26px 70px}h1{font:clamp(44px,7vw,80px)/1.05 Georgia,serif;margin:16px 0;color:#f3cf8c}h2{font:32px Georgia,serif;margin:38px 0 20px}.eyebrow{text-transform:uppercase;font-size:13px;letter-spacing:.15em;color:#f3cf8c}p{max-width:960px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:18px}figure{margin:12px 0;background:#22323f;padding:10px}img{display:block;width:100%}figcaption{padding:10px;font-size:14px}article{max-width:950px;margin-top:44px}strong{color:#f3cf8c}@media(max-width:800px){.pair{grid-template-columns:1fr}main{padding:20px 12px}}'''
def fig(name,caption):return f'<figure><a href="assets/{name}.png"><img src="assets/{name}.png" alt="{html.escape(caption)}" loading="lazy"></a><figcaption>{html.escape(caption)}</figcaption></figure>'
body='<p class="eyebrow">Endless Museum / Flow Fields / native Godot captures</p><h1>Room to move</h1><p>The same point. A contained colony. An open route into the crowd.</p>'
body+=fig('gallery-after','After: the direction table and ant comparison sit within the room, with floor space between them.')
for view,title,caption in [('above','From above','The comparison room connects to the larger crowd court on the right.'),('gallery','The comparison room','The ant world now has a physical table footprint.'),('passage','Into the crowd','The east opening leads to the existing walk-in field.')]:
    body+=f'<section id="{view}"><h2>{title}</h2><p>{caption}</p><div class="pair">'+fig(view+'-before','Before — '+caption)+fig(view+'-after','After — '+caption)+'</div></section>'
body+='<section id="displays"><h2>Two existing simulations, given a place</h2><div class="pair">'+fig('ant-table','Original Ant Colony V2. A 1.8 m view of its unchanged 50 m world; pause/play is beside your hand.')+fig('ecosystem','Original ecosystem on an 80 cm stand. The east approach has floor and standing clearance.')+'</div></section>'
body+='<article id="report">'+markdown.markdown(report,extensions=['extra'])+'</article><p>'+' · '.join(f'<a href="evidence/{k}-checks.json">{k.title()} checks</a>' for k in receipts)+'</p>'
(O/'index.html').write_text('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Room to move — Flow Fields</title><style>'+css+'</style></head><body><nav><a href="#above">Above: before / after</a><a href="#gallery">Room</a><a href="#displays">Displays</a><a href="#report">Report & tests</a><a href="REPORT.md">Editable report</a><a href="../2026-10-11-flow-a-direction-left-behind/index.html">The point interaction</a></nav><main>'+body+'</main></body></html>',encoding='utf-8')
sources=[R/f'commons/maps/{H}/map_data.json',R/'commons/data/museum/em_plan.json',R/'commons/artifacts/registry/ant_colony_table.json',R/'tools/place_flow_room.py',R/'tools/publish_flow_room.py']
for p in ['commons/artifacts/ant_colony_table','commons/artifacts/flow_comparison_stands']:sources+=list((R/p).glob('*'))
sources+=list((R/'tools/probes').glob('flow_room_*.gd'))
(O/'evidence/source-hashes.json').write_text(json.dumps({p.relative_to(R).as_posix():sha(p) for p in sources if p.is_file()},indent=2)+'\n',encoding='utf-8')
print(f'Published {total}/{total} checks, {len(preserved)} preserved hashes, eight native views; exact scope verified.')
