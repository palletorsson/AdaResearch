"""Publish the Flow Fields hand encounter with native evidence and scope checks."""
from pathlib import Path
import hashlib, html, json, shutil, subprocess
import markdown

R = Path(__file__).resolve().parents[1]
O = R/'doc/book/iterations/2026-10-11-flow-a-direction-left-behind'
H = 'SwarmIntelligence_FlowFields'
RUN = R/f'ada_run/encounter_pilot/{H}/flow-direction-final'
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()

code = read(R/'ada_run/flow_painter_checks.json')
native = read(RUN/'report.json')
assert code['passed'] and native['passed']
for log in [R/'ada_run/flow-painter-checks.log', RUN/'stdout.log']:
    assert not any(s in log.read_text(encoding='utf-8') for s in ['SCRIPT ERROR', 'SHADER ERROR']), log
preserved = read(O/'before/preserved-hashes.json')
assert all(sha(R/p)==v for p,v in preserved.items())
before = read(O/'before/commons/data/museum/em_plan.json')
after = read(R/'commons/data/museum/em_plan.json')
assert [x for x in before['plans'] if x['map']!=H] == [x for x in after['plans'] if x['map']!=H]
assert {k:v for k,v in before.items() if k!='plans'}=={k:v for k,v in after.items() if k!='plans'}
old = next(x for x in before['plans'] if x['map']==H)
new = next(x for x in after['plans'] if x['map']==H)
expected = json.loads(json.dumps(old))
table = next(a for a in expected['artifacts'] if a['token']=='flow_field_table')
table.update(token='flow_direction_table', rotation=0, config={'plinth':'0','pin':'1'})
assert expected==new
oldmap = read(O/f'before/commons/maps/{H}/map_data.json')
newmap = read(R/f'commons/maps/{H}/map_data.json')
expected = json.loads(json.dumps(oldmap))
expected['layers']['interactables'][2][4]='flow_direction_table:0:0:1#plinth:0#pin:1'
if [3,1,9,4] not in expected['map_info']['museum']['sculpture_clear_rects']:
    expected['map_info']['museum']['sculpture_clear_rects'].append([3,1,9,4])
assert expected==newmap
recovered = {}
for ext in ['gd','tscn']:
    rel=f'commons/artifacts/flow_field_painter/flow_field_painter.{ext}'
    archive=R/'doc/book/iterations/2026-10-04-flow-wall-monitor/after/source'/rel
    assert (R/rel).read_bytes()==archive.read_bytes()
    head=subprocess.check_output(['git','show','HEAD:'+rel],cwd=R)
    assert head.replace(b'\r\n',b'\n')==(R/rel).read_bytes().replace(b'\r\n',b'\n')
    recovered[rel]={'sha256':sha(R/rel),'source':'Oct 4 archived source, also matches HEAD after newline normalization'}
registry_hits=[]
for p in (R/'commons/artifacts/registry').glob('*.json'):
    d=read(p)
    if isinstance(d,dict) and 'flow_direction_table' in d.get('artifacts',{}):registry_hits.append(str(p))
assert len(registry_hits)==1
priorlog=(R/f'ada_run/encounter_pilot/{H}/flow-crowd/stdout.log').read_text(encoding='utf-8')
for warning in ['AntColonyV2 seals','blocked authored entry','blocked t exit']:
    assert warning in priorlog and warning in (RUN/'stdout.log').read_text(encoding='utf-8')
for folder in ['assets','evidence']:(O/folder).mkdir(exist_ok=True)
figures=[
 ('table-before','The original table, now facing the room. A second, smaller view puts the same field within reach of the carried point.'),
 ('hand-controls','The final control arrangement: buttons to the left, point dock at the front-right. Standing routes avoid the existing ramp.'),
 ('directions-written','A scripted gesture with the actual held point changes a strip of cyan arrows to gold. Gold records edited cells, not a separate decorative line.'),
 ('field-close','The same 200 bodies and field viewed close up. The stroke points down, then curves left. Original steering reads these edited vectors.'),
 ('after-release','Six seconds after release and resume: bodies continue moving, and the written vectors remain unchanged. The point has returned to its dock.'),
 ('original-tour','The nearby Tour button returns to the original field scenarios. Returning to Draw clears the edits.'),
 ('hall-above','The hall from above. The hand table occupies the older room; the existing walk-in crowd remains in its larger court. Older oversized exhibits are still visible outside the room bounds.')]
for name,_ in figures:shutil.copy2(RUN/f'{name}.png',O/'assets'/f'{name}.png')
for src,name in [(R/'ada_run/flow_painter_checks.json','code-checks.json'),(R/'ada_run/flow-painter-checks.log','code.log'),(RUN/'report.json','museum-checks.json'),(RUN/'stdout.log','museum.log'),(RUN/'source_manifest.json','museum-sources.json')]:
    shutil.copy2(src,O/'evidence'/name)
total=len(code['checks'])+len(native['checks'])
report=f'''# Leave a direction

Endless Museum · Flow Fields · 11 October 2026

The point gains another use. In Physarum it left a deposit that the colony could change. Here your hand writes **directions**. The existing bodies read them, and the arrows remain after you release the point.

## Try it in the museum

Reload **Swarm Intelligence → Flow Fields**. Take the black point at the front-right of the table. Hold the trigger and move it above the smaller surface. A gold cursor locates your hand in both views. Move to write; holding still does not invent a direction. Release the trigger and watch the bodies respond.

The buttons to the left pause/play, reset the directions, and switch between Draw and the original Tour. Drawing still works while paused. Reset keeps the bodies and their current positions. Returning from Tour to Draw clears the edits. Dropping the point returns it after three seconds, keeping your field. Desktop uses the existing carry/drop and action controls.

## What returns, what changes

The original FlowFieldMain scene, FlowGrid and 200 FlowAgent bodies run inside the existing table host. A new host adds the familiar PointBody, a smaller view, nearby controls and cylinder arrows. Both surfaces share one running simulation. The agent code, steering, collisions and boundary response are unchanged. The existing walk-in crowd is still present in the adjoining court.

Draw begins with one rightward field. A stroke replaces the directions in a bounded strip of cells. The hand is now an additional author of the field. Agents read these instructions; they do not deposit, diffuse or erase them. The original Tour still visits its six scenarios and ends in animated noise.

This gives a concrete comparison across the halls: **a deposit sensed by agents → a direction supplied to agents → neighbours sensed by agents**. These can produce similar-looking collective movement while using different information. This optional encounter strengthens that distinction. The agreed tutorial objects, all fourteen canonical texts and the sequence order remain unchanged.

## The room

The table stays at cell (4, 2) and turns to face the room. The point dock moves to the front-right; controls sit on the left, clear of the existing ramp. A local exclusion rectangle limits automatic sculptures near the table. Room dimensions, utility cells, other artifact placements and all other museum-plan rows are preserved.

The overhead image also reveals an existing room problem: an oversized AntColonyV2 footprint and other exhibits extend beyond their intended space. The current run reports entry/exit fallback warnings also present in the earlier crowd run. The tested table approaches have floor support and capsule clearance; this does not certify the complete hall route. That spatial cleanup remains open.

## What was tested

**{total}/{total} checks passed**: {len(code['checks'])} production-scene checks and {len(native['checks'])} checks in the actual museum. They cover original resource reuse, shared views, private simulation visuals and physics, camera/input agreement, transformed hosts, held-action gating, stationary input, brush bounds, interrupted strokes, direction and colour, agent response, pause, reset, release, return and standing access.

The native run injected a desktop pickup and stroke into the actual PointBody. It edited {native['observations']['edited_cells']} cells. All {native['observations']['moved_bodies']} bodies moved after resume, while the edited vectors stayed intact. A separate controlled check verifies the original agent turns along an edited vector. The seven images are native Godot captures, with pauses for comparison; they are not a recorded headset session.

All {len(preserved)} recorded original source/text hashes match. Final runs contain no script or shader errors. Existing UID, Jolt and renderer-feature warnings remain in the logs. Physical headset interaction and Quest performance have not been tested.

## Repairs during the pass

The first access check found the ramp beside the buttons. The controls were moved and the checks repeated. An initially reused filename also collided with the older Change-sequence flow_field_painter. Its two files were restored byte-for-byte from the archived source, verified against HEAD with newline normalization. This encounter now has the distinct flow_direction_table name and registry entry.
'''
(O/'REPORT.md').write_text(report,encoding='utf-8')
css='''*{box-sizing:border-box}body{margin:0;background:#101c25;color:#e2edf0;font:17px/1.65 system-ui}nav{padding:18px 4vw;display:flex;gap:24px;flex-wrap:wrap;background:#1b2c36}a{color:#91e3ec;text-underline-offset:4px}main{max-width:1380px;margin:auto;padding:35px 24px 80px}h1{font:clamp(42px,6vw,76px)/1.1 Georgia,serif;color:#ffcf72;margin:.3em 0}h2{font:32px/1.2 Georgia,serif;margin-top:40px}p{max-width:930px}.eyebrow{font-size:13px;letter-spacing:.15em;text-transform:uppercase;color:#ffcf72}figure{margin:24px 0;background:#1b2c36;padding:10px}img{width:100%;display:block}figcaption{padding:10px;font-size:14px;color:#c4d3da}.grid{display:grid;grid-template-columns:1fr 1fr;gap:20px}.grid figure{margin:0}article{max-width:940px;margin-top:50px}@media(max-width:760px){.grid{grid-template-columns:1fr}main{padding:20px 12px}}'''
def figure(name,caption):
    return f'<figure><a href="assets/{name}.png"><img src="assets/{name}.png" alt="{html.escape(caption)}" loading="lazy"></a><figcaption>{html.escape(caption)}</figcaption></figure>'
body='<p class="eyebrow">Endless Museum · Flow Fields · native Godot views</p><h1>Leave a direction</h1><p>Take the point. Draw a turn. Release it. The bodies keep reading what your hand left.</p>'
body+=figure(*figures[2])
body+='<section id="hands"><h2>The point writes into the field</h2><div class="grid">'+''.join(figure(*f) for f in figures[:2])+'</div></section>'
body+='<section id="change"><h2>Written, then released</h2><div class="grid">'+''.join(figure(*f) for f in figures[3:5])+'</div>'+figure(*figures[5])+'</section>'
body+='<section id="room"><h2>The room and the remaining clutter</h2>'+figure(*figures[6])+'</section>'
body+='<article id="report">'+markdown.markdown(report,extensions=['extra'])+'</article><p><a href="evidence/code-checks.json">Code checks</a> · <a href="evidence/museum-checks.json">Museum checks</a> · <a href="evidence/museum.log">Native log</a></p>'
(O/'index.html').write_text('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Leave a direction — Flow Fields</title><style>'+css+'</style></head><body><nav><a href="#hands">Use the point</a><a href="#change">Before / after</a><a href="#room">Room from above</a><a href="#report">What changed</a><a href="REPORT.md">Editable report</a><a href="../2026-10-11-physarum-a-mark-left-behind/index.html">Previous: Physarum</a></nav><main>'+body+'</main></body></html>',encoding='utf-8')
sources=list((R/'commons/artifacts/flow_direction_table').glob('*'))+[R/'commons/artifacts/registry/flow_direction_table.json',R/f'commons/maps/{H}/map_data.json',R/'commons/data/museum/em_plan.json',R/'tools/probes/flow_painter_checks.gd',R/'tools/probes/flow_painter_museum.gd']
(O/'evidence/source-hashes.json').write_text(json.dumps({p.relative_to(R).as_posix():sha(p) for p in sources if p.is_file()},indent=2)+'\n',encoding='utf-8')
(O/'evidence/restoration.json').write_text(json.dumps(recovered,indent=2)+'\n',encoding='utf-8')
print(f'Published {total} passing checks, seven native views, {len(preserved)} unchanged source/text hashes; only the intended table placement changed.')
