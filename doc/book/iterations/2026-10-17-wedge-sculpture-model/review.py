from pathlib import Path
import json,shutil,html,re,hashlib
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).parent;ROOM='Primitives_Polythedra';MAP=ROOT/'commons/maps'/ROOM
RUN=ROOT/'ada_run/encounter_pilot'/ROOM/'wedge-sculpture-model-v2'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
checks=[]
def check(name,ok):
    checks.append({'name':name,'passed':bool(ok)})
    assert ok,name
before=read(HERE/'before/commons/maps'/ROOM/'map_data.json');now=read(MAP/'map_data.json')
for layer in ['structure','museum','utilities']:check(layer+' unchanged',before['layers'][layer]==now['layers'][layer])
changed=[(x,z) for z,row in enumerate(now['layers']['interactables']) for x,t in enumerate(row) if t!=before['layers']['interactables'][z][x]]
check('only two platform placements added',changed==[(6,32),(13,32)])
old=read(HERE/'before/commons/data/museum/em_plan.json');new=read(ROOT/'commons/data/museum/em_plan.json')
check('other museum plan rows unchanged',[r for r in old['plans'] if r.get('map')!=ROOM]==[r for r in new['plans'] if r.get('map')!=ROOM])
old=read(HERE/'before/commons/artifacts/registry/primitive_encounters.json')['artifacts'];new=read(ROOT/'commons/artifacts/registry/primitive_encounters.json')['artifacts']
check('existing artifact registrations retained',all(new[k]==v for k,v in old.items()))
for k in ['wedge_column','wedge_mouse_model']:check(k+' scene resolves',(ROOT/new[k]['scene'].replace('res://','')).is_file())
old=read(HERE/'before/commons/data/artifact_roles.json');new=read(ROOT/'commons/data/artifact_roles.json')
check('other map curation retained',all({k:v for k,v in old[field].items() if k!=ROOM}=={k:v for k,v in new[field].items() if k!=ROOM} for field in ['roles','groups','order','notes','positions']))
old=read(HERE/'before/commons/data/spine_artifact_order.json');new=read(ROOT/'commons/data/spine_artifact_order.json')
check('other spine rows unchanged',[r for r in old['order'] if r['map']!=ROOM]==[r for r in new['order'] if r['map']!=ROOM])
markers=re.findall(r'<!-- @(\w+) -->',(MAP/'final.md').read_text(encoding='utf-8'))
sequence=['prism_block','wedge_palace','wedge_column','wedge_mouse_model','concrete_barrier']
check('final follows blocking climbing sculpture model descent',sorted(markers.index(k) for k in sequence)==[markers.index(k) for k in sequence])
runtime=read(RUN/'report.json');model=read(HERE/'model-report.json')
check('native hall runtime passed',runtime['passed']);check('player steering and contact tests passed',model['passed'])
(HERE/'data-checks.json').write_text(json.dumps({'passed':True,'checks':checks},indent=2),encoding='utf-8')
native=HERE/'native';native.mkdir(exist_ok=True)
for p in RUN.iterdir():
    if p.suffix=='.png' or p.name in ['report.json','engine.log','source_manifest.json']:shutil.copy2(p,native/p.name)
after=HERE/'after';after.mkdir(exist_ok=True);(after/'.gdignore').touch()
for name in ['map_data.json','final.md','tutorial.md','technical.md','summary.md','artifacts.md','intent.md']:shutil.copy2(MAP/name,after/name)
sources=HERE/'sources';sources.mkdir(exist_ok=True);(sources/'.gdignore').touch()
manifest={}
for name in ['wedge_column.gd','wedge_column.tscn','wedge_mouse_model.gd','wedge_mouse_model.tscn','piece.gd','geometry.gd']:
    p=ROOT/'commons/artifacts/primitive_encounters'/name;shutil.copy2(p,sources/name);manifest[str(p.relative_to(ROOT))]=hashlib.sha256(p.read_bytes()).hexdigest()
(HERE/'tested-sources.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
nc=len(runtime['checks']);nm=len(model['checks'])
summary=f'''# Blocking, climbing, sculpture — then a route in the hand

On the Primitives_Polythedra platform, six copies of the original prism_block make a 1.95 m sculptural column: three paired diamond modules. Its joints remain fixed. The side ramps, three-metre passages and descending route are unchanged.

The second addition is a 2.8 × 1.0 m plinth with a brown wedge mouse and cheese. The player steers the mouse using a returning joystick, and presses JUMP to leap in the last steered direction. Seven identical right-triangular pieces are grabbable: two stoppers, an incline, two platform halves and two landing halves. Turning and placing pieces changes contact and support. The cheese is a gravity-enabled body and falls if unsupported.

HOME returns only the mouse. RESTORE resets all seven construction pieces, the mouse and the cheese. Construction pieces remain where released; there is no persistent layout save. Hand grabbing, pointer dragging and poke/ray buttons use existing interaction components. These controls leave avatar input alone.

Final, tutorial, technical, summary, intent, inventory and this map's curation/spine order follow blocking → climbing → sculpture → small model → descent. Existing notes are retained. Other maps and museum plan rows are unchanged.

{nc}/{nc} native hall checks pass; {nm}/{nm} supplied-control model checks pass; {len(checks)} scoped data checks pass. The mouse is stationary without input, the central stoppers resist direct steering, a detour reaches the ramp, and a player-directed jump reaches the raised landing. Moving the ramp removes that ascent; removing the far support lowers the landing. HOME preserves edits and RESTORE returns the arrangement. Joystick pointer direction and release are checked. Native capture caught inward-facing button caps; they now face outwards and are checked explicitly.

The one-millimetre convex margin is important at this scale: the default four-centimetre rounding caused the small mouse to meet an artificially steep contact at the ramp foot. The miniature uses slowed gravity and is not a scaled model of real mouse mechanics. Fixed sculptural joints are not a balancing test.

Pathfinder: zero failures, with existing edge-teleporter and enclosed-rock-spawner warnings. Engine reports retain existing registry/renderer warnings. VR grip comfort, button reach and visitor interpretation still need a wearer. No commit or push requested.
'''
(HERE/'summary.md').write_text(summary,encoding='utf-8')
final=(MAP/'final.md').read_text(encoding='utf-8');passage=final[final.index('Five upright prisms'):final.index('<!-- @concrete_barrier -->')]
passage=re.sub(r'<!--.*?-->','',passage)
paras=''.join('<p>'+html.escape(p.strip())+'</p>' for p in passage.split('\n\n') if p.strip())
style='''*{box-sizing:border-box}body{margin:0;background:#f7f3eb;color:#302e36;font:18px/1.6 system-ui,sans-serif}main{max-width:1280px;margin:auto;padding:30px}h1{font:clamp(36px,4.3vw,58px)/1.1 Georgia,serif;margin:16px 0}h2{font:30px Georgia,serif;margin-top:38px}.kicker{text-transform:uppercase;letter-spacing:.1em;font-size:13px;color:#715778}.lead{font-size:22px;max-width:70ch}nav{display:flex;gap:22px;flex-wrap:wrap;border-block:1px solid #d3c8bb;padding:12px 0;margin:24px 0}a{color:#6e426f}figure{margin:22px 0}img{width:100%;border-radius:7px}figcaption{font-size:15px;color:#655d6b}.pair{display:grid;grid-template-columns:1fr 1fr;gap:22px}.proof{padding:20px;background:#e4eddf;border-left:4px solid #54754e}.prose{font:21px/1.75 Georgia,serif;max-width:75ch}li{margin:7px 0}code{font-size:.92em}@media(max-width:760px){main{padding:18px}.pair{grid-template-columns:1fr}}'''
page=f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Blocking, climbing, sculpture · Ada Research</title><style>{style}</style><main><div class="kicker">Polythedra · 17 October 2026</div><h1>Blocking. Climbing. Sculpture.</h1><p class="lead">The same standing prisms become a column on the platform. Beside it, a small wedge mouse gives us another body to steer through an arrangement we can change.</p><nav><a href="#model">Steer the mouse</a><a href="#route">Room sequence</a><a href="#text">Revised text</a><a href="summary.md">Saved summary</a></nav>
<figure><img src="native/sculpture-and-model.png" alt="Native Godot view of the wedge sculpture and mouse plinth on the shared platform"><figcaption>Actual Godot capture. Both additions sit behind the clear platform crossing; the basin and descent remain ahead.</figcaption></figure>
<section id="model"><h2>A small route, steered by the player</h2><figure><img src="native/mouse-model.png" alt="Brown wedge mouse, upright wedges, incline, paired platform and cheese on a plinth"><figcaption>Seven matching construction wedges. One brown mouse, a cheese wedge, and real contact between them.</figcaption></figure><ul><li><strong>Grip or drag the joystick</strong> to steer. Release to stop.</li><li><strong>JUMP</strong> leaps in the last steered direction. A grounded mouse can jump anywhere.</li><li><strong>Move and turn the wedges</strong> to change the course. Two complementary wedges make a platform; another exposes its inclined face.</li><li><strong>HOME</strong> returns only the mouse. <strong>RESTORE</strong> returns the whole model.</li></ul><p>In VR, grab and turn the pieces. On desktop, Q/E roll and R/F tilt while holding a piece. Construction pieces stay where released. The cheese falls when unsupported. This version keeps edits for the current visit; it does not save layouts to disk.</p><figure><img src="native/model-controls.png" alt="Joystick and outward-facing Jump, Home and Restore buttons"><figcaption>The controls sit on the plinth face and leave the small construction visible.</figcaption></figure></section>
<section id="route"><h2>The room makes the comparison</h2><div class="pair"><figure><img src="native/first-central-blockers.png" alt="Central collection of standing wedges"><figcaption>1. Walk around the standing wedges.</figcaption></figure><figure><img src="native/then-side-ramp.png" alt="Side wp ramp climbing onto platform"><figcaption>2. Climb the side ramp.</figcaption></figure></div><figure><img src="native/platform-sculpture.png" alt="Six original prisms paired into three diamond modules"><figcaption>3. Meet the original prisms again as a repeated sculptural form. The joints are fixed; this is not a physics balancing result.</figcaption></figure><p>The miniature follows on the same platform. The room and final text share this order, then descend to the basin and rock room.</p></section>
<h2>What was checked</h2><div class="proof"><strong>{nc} native hall checks and {nm} model checks passed.</strong> Both walking approaches, the platform crossing, descent, model contact, joystick steering, jump, reset and changed-support trials. {len(checks)} scoped data checks passed.</div><p>Grip comfort and unprompted understanding remain VR trials. Pathfinder has zero failures and retains the earlier teleporter/rock-enclosure warnings.</p><p><a href="native/report.json">Hall checks</a> · <a href="model-report.json">Model checks</a> · <a href="data-checks.json">Scoped data checks</a> · <a href="after/tutorial.md">Tutorial</a></p>
<section id="text"><h2>The revised passage</h2><div class="prose">{paras}</div><p><a href="after/final.md">Complete revised final</a> · <a href="before/commons/maps/Primitives_Polythedra/final.md">Previous final</a></p></section></main></html>'''
(HERE/'index.html').write_text(page,encoding='utf-8')
state=ROOT/'doc/book/STATE.md';heading='## Polythedra: wedge sculpture and player-steered mouse — 2026-10-17'
entry=heading+'\n\n'+summary[summary.index('On the Primitives'):]+ '\nReview: `iterations/2026-10-17-wedge-sculpture-model/index.html`. The user explicitly chose player steering; no autonomous route remains in production.\n\n'
old=state.read_text(encoding='utf-8')
if not old.startswith(heading):state.write_text(entry+old,encoding='utf-8')
print(f'Review saved: {nc} hall + {nm} model + {len(checks)} scoped data checks.')
