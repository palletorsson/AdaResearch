"""Publish real long-run comparisons and the installed three-scale encounter."""
from pathlib import Path
import json, html, shutil, hashlib
from PIL import Image
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-11-ants-time-and-scale'
H='SwarmIntelligence_Ant_Colony_Optimization'
RUN=R/f'ada_run/encounter_pilot/{H}/ants-scale-v2-controls'
V2RUN=R/f'ada_run/encounter_pilot/{H}/ants-v2-installed'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def esc(s):return html.escape(str(s),quote=True)
code=read(R/'ada_run/ant_scale_checks.json');native=read(RUN/'report.json')
v2=read(V2RUN/'report.json')
assert code['passed'] and native['passed'] and v2['passed']
for p in [R/'ada_run/ant-scale-checks.log',RUN/'stdout.log',V2RUN/'stdout.log']:
    assert not any(e in p.read_text(encoding='utf-8') for e in ['SCRIPT ERROR','SHADER ERROR','Invalid metadata identifier']),p
preserved=read(O/'before/preserved-hashes.json')
preserved.update(read(O/'before/v2-preserved-hashes.json'))
assert all(sha(R/p)==v for p,v in preserved.items())
old=read(O/'before/commons/data/museum/em_plan.json');new=read(R/'commons/data/museum/em_plan.json')
assert [r for r in old['plans'] if r['map']!=H]==[r for r in new['plans'] if r['map']!=H]
assert {k:v for k,v in old.items() if k!='plans'}=={k:v for k,v in new.items() if k!='plans'}
oldmap=read(O/f'before/commons/maps/{H}/map_data.json');newmap=read(R/f'commons/maps/{H}/map_data.json')
for layer in ['utilities','interactables']:
    assert all(c==newmap['layers'][layer][z][x] for z,line in enumerate(oldmap['layers'][layer]) for x,c in enumerate(line))
assert all(len(rows)==17 and all(len(row)==33 for row in rows) for rows in newmap['layers'].values())
for z,line in enumerate(oldmap['layers']['structure']):
    for x,c in enumerate(line):
        if (x,z) not in [(16,7),(16,8),(16,9)]:assert c==newmap['layers']['structure'][z][x]
longrun=read(O/'evidence/long-run-summary.json')
assert len(longrun)==14 and all(r['exit']==0 and not r['errors'] and r['last_image'] for r in longrun)
metadata={r['token']:r for r in read(R/'doc/book/iterations/2026-10-11-ant-simulations/manifest.json')}
notes={
 'ant_colony_art':'The large green terrain remains visually dominant. Individual ants need a closer view; this framing is not enough to rank the behaviour.',
 'AntColonyV2':'Added to the court. The original 100-ant colony now has a dark field, cyan home trails and rose food trails. New museum captures above show it at all three scales; these earlier isolated frames retain the original lighting.',
 'ant_colony_optimization':'Motion and trails are present, but the small scene occupies too little of this fixed frame for a useful room-scale comparison.',
 'ant_colony_walk':'Keep as the primary tutorial. Full-size PointBody spheres make the two trail channels and return trip readable.',
 'langton_toy':'A strong small-object candidate: the occupied patch spreads clearly during this run.',
 'langton_bench':'A dense pattern is already present on arrival. In these frames its overall silhouette changes little.',
 'langton_swarm':'Selected. A varied coloured surface remains active over time. The rule can be compared at hand, table and floor scale.',
 'grid2d_langtons_ant':'A good large field candidate: the purple occupied area expands toward the boundaries.',
 'stigmergy_toy':'Sparse at this scale and framing. Keep as a compact mechanism study rather than the main visual effect.',
 'stigmergy_bench':'Sparse in this run. Its few visible marks do not carry a large room well in the current presentation.',
 'stigmergy_grid':'Selected. Branches concentrate into a dominant path. Waiting changes the structure; it does not necessarily add visual density.',
 'stigmergy_room':'Several clusters persist. Worth retaining for destination comparison; less legible as an evolving image in these captures.',
 'pheromone_terrain':'Accumulated height becomes visible. Retain in Randomness: a different consequence of depositing a trace.',
 'PhysarumColony':'Strong yellow branching and looping. Retain in its existing Physarum hall; this is a slime-mould relative, not an ant simulation.',
}
for folder in ['assets','evidence']:(O/folder).mkdir(exist_ok=True)
figures=[
 ('table','The 1.8 m table and eight-metre floor share the exact same state. Ant silhouettes make the moving agents visible.'),
 ('hand','Carry the 45 cm tile by the familiar black PointBody. Its trigger pauses or continues all three displays.'),
 ('trails-above','Pheromone trails at three scales. Gold and cyan make the field legible; the original concentration data is unchanged.'),
 ('trails-walk-in','At visitor height, the large field becomes a ground to cross. Walking does not change the ant motion.'),
 ('turmites-above','The same installation running the existing coloured turmite rule. Its 900-step warm start is stated in the room.'),
 ('controls','Five upward-facing buttons within reach: Trails, Turmites, Ant Colony V2, Pause/Play and Restart. Selected buttons light cyan.'),
 ('hall-above','The original colony lesson remains on the left; the comparison court opens to its east. Both original sequence passages remain.')]
v2figures=[('v2-90','Ant Colony V2 after about 90 seconds: the original 100 ants and both trail channels shown at hand, table and room scale.'),('v2-table','The same V2 colony on the 1.8 m table. Gold ants forage; pink ants return from food.'),('v2-hand','The familiar PointBody carries a 45 cm view of the same V2 state. Trigger pauses or continues it.'),('v2-walk-in','Walk across the 8 m V2 field. Cyan marks home trails and rose marks food trails; three discs locate the original nest and food detectors.')]
for name,_ in v2figures:shutil.copy2(V2RUN/f'{name}.png',O/'assets'/f'{name}.png')
for name in ['v2-5','v2-30']:shutil.copy2(V2RUN/f'{name}.png',O/'assets'/f'{name}.png')
for name,_ in figures:shutil.copy2(RUN/f'{name}.png',O/'assets'/f'{name}.png')
for source,name in [(R/'ada_run/ant_scale_checks.json','code-checks.json'),(R/'ada_run/ant-scale-checks.log','code.log'),(RUN/'report.json','museum-checks.json'),(RUN/'stdout.log','museum.log'),(RUN/'source_manifest.json','museum-sources.json')]:shutil.copy2(source,O/'evidence'/name)
for source,name in [(V2RUN/'report.json','v2-museum-checks.json'),(V2RUN/'stdout.log','v2-museum.log'),(V2RUN/'source_manifest.json','v2-museum-sources.json')]:shutil.copy2(source,O/'evidence'/name)
records=[]
for token in notes:
    receipt=read(O/'long-run'/f'{token}.json')
    assert receipt['image_saved'] and receipt['geometry_found'] and receipt['camera_retained']
    assert len(receipt['timeline'])==3 and all(f['saved'] and f['wall_seconds']>=f['seconds']-.02 for f in receipt['timeline'])
    for seconds in [5,30,90]:
        p=O/'long-run'/f'{token}-{seconds}.png'
        image=Image.open(p).convert('RGB');image.thumbnail((960,640));image.save(O/'assets'/f'{token}-{seconds}.jpg',quality=87)
    records.append({'token':token,'title':metadata[token]['title'],'note':notes[token],'location':metadata[token]['location'],'scene':metadata[token]['scene'],'receipt':receipt})
(O/'evidence/comparisons.json').write_text(json.dumps(records,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
total=len(code['checks'])+len(native['checks'])+len(v2['checks'])
report=f'''# One pattern, three sizes

Endless Museum · 11 October 2026

Fourteen existing simulations ran for **about 90 seconds each**, with photographs requested at 5, 30 and 90 seconds. The clearest contrasting effects were the coloured turmite surface and the concentrating pheromone trail. Both appear in a comparison court beside the existing colony lesson. **Ant Colony V2 is now the third selectable model**, with a fresh 90-second museum run and clearer trail colours.

## Try it in the museum

Reload **Swarm Intelligence → Ant Colony Optimization**. From the original sphere-and-trail field, enter the new east opening. Three sizes show one live state:

- **45 cm:** take the tile by its black point. Trigger pauses or continues the pattern. It returns to its dock five seconds after release.
- **1.8 m:** lean over the table and follow an individual ant.
- **8 m:** walk across the same pattern at room scale.

The nearby buttons select **Trails**, **Turmites** or **Ant Colony V2**, pause/play, and restart the selected model. Each model keeps its history when you switch away. There is no automatic reset. Desktop uses the existing right-click carry/drop and left-click action.

## What changed

The two original simulation scripts still provide their own movement and cell-update rules. A new host gives them visible ant bodies, a clearer field palette, shared displays and the existing grabbable PointBody. The turmite view keeps the original 900-step warm start; a fixed seed makes its reset repeatable. The pheromone view begins empty and develops while you watch.

V2 runs its original scene once in a private physics world: 100 original SimpleAnt bodies, a 256 × 256 pheromone grid and the original food/home detectors. The 50 m simulation supplies all three smaller displays without rescaling its physics. Cyan shows home trails, rose shows food trails. Gold ants forage; pink ants are returning. This comparison uses a flat, dark, unlit field in place of the original terrain shading, avoiding the glare seen in the isolated capture. This is a new presentation of the original state, with no change to its movement or deposit rules. No fast-forward or hidden warmup is applied.

The main tutorial remains **Two trails underfoot**, with its carried spheres and separate home/food channels. This optional comparison court does not replace it or turn every display into a new lesson. Existing tutorial.md and final.md files remain unchanged.

The hall grows from 17 × 17 to 33 × 17 cells. Its north/south sequence passages and existing lesson position remain. A three-cell east opening leads into the new court. Automatic sculpture placement is excluded from the field and approach, after an overhead inspection exposed obstructions there.

## What the longer runs showed

More time does not always mean a richer image. In the pheromone-grid run, several branches condensed into one dominant route. The turmite surface kept a varied coloured pattern. The carried Langton toy visibly filled more of its surface. The yellow Physarum example made strong branches and loops; it stays in its own hall as a related mechanism.

These are selection observations from one run per scene, not a performance ranking. Original scene defaults and warm starts differ; some isolated scenes supply their own cameras or lighting. The old isolated V2 capture remains overexposed; the new museum views correct the display contrast. The optimization preview is too distant for detailed assessment. The original gallery remains linked for additional views. Individual ant components were not treated as independent simulations.

## Evidence

**{total}/{total} checks passed:** {len(code['checks'])} code/display checks and {len(native['checks'])+len(v2['checks'])} museum checks. The original trail engine and adapter match after 180 steps; the turmite state matches after its warmup and another 100 steps. Checks also cover shared state at all sizes, rendering without data mutation, preserving histories across selections, pause/resume, explicit reset, pickup/action/drop and return to the dock.

Native museum checks cover floor support, standing clearance along the approach and across the field, access to controls, hand height, live simulation advancement and thirteen real captures. V2 checks also cover isolation from museum collisions, its original food/home Area3D transitions, shared 100-agent views, pause and history preservation. In the 90-second museum run, ants reached food through their own movement. The receipt records wall time and actual physics ticks separately; this is not a 90 Hz headset performance test. The ant bodies are visual instances with static legs, not physical insects. Walking through them does not steer them.

The 90-second comparisons use real elapsed time at normal engine speed. They are not equal-step experiments or recorded continuous video. Select any of the three stills, labelled with their requested times; each card also lists actual elapsed times. Two malformed JSON envelopes were repaired around surviving measurements and checked against their logs; originals are retained in evidence/receipt-repairs.json. No script/shader errors occurred in the passing runs; pre-existing engine warnings remain in the logs. Physical headset use and Quest performance remain untested.
'''
(O/'REPORT.md').write_text(report,encoding='utf-8')
css='''*{box-sizing:border-box}body{margin:0;background:#111820;color:#f2ede1;font:17px/1.6 system-ui}main{max-width:1400px;margin:auto;padding:40px 26px 80px}h1{font:clamp(44px,6vw,82px)/1.04 Georgia,serif;color:#ffdb89}h2{font:34px/1.2 Georgia,serif;margin-top:45px}p{max-width:880px}nav{display:flex;gap:14px;flex-wrap:wrap;padding:18px 26px;background:#20313d;position:sticky;top:0;z-index:2}a{color:#8ed9e7;text-underline-offset:4px}figure{margin:25px 0;background:#1d2b38;padding:10px;border-radius:8px}figure img{width:100%;display:block}figcaption{font-size:14px;padding:12px 6px;color:#c4ced6}.grid{display:grid;grid-template-columns:1fr 1fr;gap:22px}.grid figure{margin:0}.gallery{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px}.card{background:#1d2b38;border:1px solid #405465;border-radius:8px;overflow:hidden}.card img{width:100%;display:block}.copy{padding:20px}.copy h3{margin:0;color:#ffdb89}.copy p{margin:10px 0}.meta{font-size:13px;color:#b5c1cb}button{padding:12px 20px;font:inherit;color:#eef1ed;background:#243b48;border:1px solid #7f9faa;border-radius:28px;cursor:pointer}button[aria-pressed=true]{background:#ffdb89;color:#192431;border-color:#ffdb89}.time-controls{display:flex;gap:10px;flex-wrap:wrap;margin:20px 0}.badge{font-size:13px;color:#ffdb89;text-transform:uppercase;letter-spacing:.12em}article{max-width:930px;margin-top:40px}.hero{padding:0}.hero figcaption{padding:15px}@media(max-width:760px){main{padding:26px 14px}.grid,.gallery{grid-template-columns:1fr}nav{position:static}.time-controls button{padding:10px 14px}}'''
body='<p class="badge">Endless Museum · native Godot views</p><h1>Give the pattern time.<br>Then change its size.</h1><p>Fourteen longer runs. Three selectable models. One live pattern you can hold, lean over and walk through.</p>'
body+='<figure class="hero"><img src="assets/v2-table.png" alt="Ant Colony V2 shared between the hand tile, table and walk-in museum floor"><figcaption>Installed in Ant Colony Optimization, beside the original tutorial field.</figcaption></figure>'
body+='<section id="v2"><h2>Ant Colony V2 — now in the court</h2><p>One original colony, 100 ants, three sizes. Select ANT COLONY V2 on the nearby controls. Cyan: home trail. Rose: food trail. The existing lesson remains beside this comparison.</p><div class="grid">'
for name,caption in v2figures:body+=f'<figure><a href="assets/{name}.png"><img loading="lazy" src="assets/{name}.png" alt="{esc(caption)}"></a><figcaption>{esc(caption)}</figcaption></figure>'
body+='</div><p><a href="assets/v2-5.png">V2 at 5 seconds</a> · <a href="assets/v2-30.png">30 seconds</a> · <a href="assets/v2-90.png">90 seconds</a> · <a href="evidence/v2-museum-checks.json">Run measurements and checks</a></p></section>'
body+='<section id="museum"><h2>Inside the museum</h2><div class="grid">'
for name,caption in figures[1:]:body+=f'<figure><a href="assets/{name}.png"><img loading="lazy" src="assets/{name}.png" alt="{esc(caption)}"></a><figcaption>{esc(caption)}</figcaption></figure>'
body+='</div></section><section id="time"><h2>What waiting changed</h2><p>Same camera within each run. Choose 5, 30 or 90 seconds for all fourteen comparisons. These are stills, not continuous footage.</p><div class="time-controls">'
for seconds in [5,30,90]:body+=f'<label><input type="radio" name="capture-time" value="{seconds}" '+('checked ' if seconds==90 else '')+f'> {seconds} seconds</label>'
body+='</div><div class="gallery">'
css+='''.time-controls label{padding:12px 20px;border:1px solid #7f9faa;border-radius:28px;cursor:pointer;background:#243b48}.time-controls label:has(input:checked){background:#ffdb89;color:#192431}.frame{display:none}#time:has(input[value="5"]:checked) .frame5,#time:has(input[value="30"]:checked) .frame30,#time:has(input[value="90"]:checked) .frame90{display:block}'''
for r in records:
    token=r['token'];times=' / '.join(f'{f["wall_seconds"]:.2f}' for f in r['receipt']['timeline'])
    frames=''.join(f'<a class="frame frame{t}" href="long-run/{token}-{t}.png"><img loading="lazy" src="assets/{token}-{t}.jpg" alt="{esc(r["title"])} at approximately {t} seconds"></a>' for t in [5,30,90])
    body+=f'<section class="card">{frames}<div class="copy"><h3>{esc(r["title"])}</h3><p>{esc(r["note"])}</p><p class="meta">{esc(r["location"])} · Actual elapsed: {times} s · <a href="long-run/{token}.json">Capture record</a></p></div></section>'
body+='</div></section><article id="report">'+markdown.markdown(report,extensions=['extra'])+'</article>'
(O/'index.html').write_text('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Ants — time and scale</title><style>'+css+'</style></head><body><nav><a href="#v2">Ant Colony V2</a><a href="#museum">Three sizes</a><a href="#time">5 → 30 → 90 seconds</a><a href="#report">What changed</a><a href="REPORT.md">Editable report</a><a href="../2026-10-11-ant-simulations/index.html">Original ant gallery</a><a href="evidence/museum-checks.json">Checks</a></nav><main>'+body+'</main></body></html>',encoding='utf-8')
sources=list((R/'commons/artifacts/ant_scale_atlas').glob('*'))+[R/'commons/artifacts/registry/ant_scale_atlas.json',R/f'commons/maps/{H}/map_data.json',R/'commons/data/museum/em_plan.json',R/'tools/probes/ant_scale_checks.gd',R/'tools/probes/ant_scale_museum.gd',R/'tools/probes/ant_v2_museum.gd']
(O/'evidence/source-hashes.json').write_text(json.dumps({p.relative_to(R).as_posix():sha(p) for p in sources if p.is_file()},indent=2)+'\n',encoding='utf-8')
print(f'Published {total} passing checks, 13 museum images, 42 longer-run images; preserved {len(preserved)} source/text hashes and all other hall plans.')
