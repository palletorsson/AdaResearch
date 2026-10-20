"""Publish the expanded sampling hall without changing its executable lesson."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlparse,unquote
import copy,hashlib,html,json,re,shutil
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-more-shapes-kept'
M=R/'commons/maps/SoftBodies_Playground_of_Joy'
RUN=R/'ada_run/encounter_pilot'/M.name/'gallery-final'
KEY='softbodies|softbodies playground of joy'
def text(p):return p.read_text(encoding='utf8')
def read(p):return json.loads(text(p))
def write(p,s):p.write_bytes(s.encode())
def dump(p,v):write(p,json.dumps(v,ensure_ascii=False,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
receipt=read(RUN/'report.json')
assert receipt['passed'] and all(c['passed'] for c in receipt['checks'])
assert 'SCRIPT ERROR' not in text(RUN/'engine.log') and 'Parse Error' not in text(RUN/'engine.log')
for name,digest in read(O/'before/source-hashes.json').items():assert sha(R/name)==digest,name
for name,digest in read(O/'gallery-source-hashes.json').items():assert sha(R/name)==digest,name
for folder in ['assets','validation','source']:(O/folder).mkdir(exist_ok=True)
for p in RUN.glob('*.png'):shutil.copyfile(p,O/'assets'/p.name)
shutil.copyfile(R/'ada_run/encounter_pilot'/M.name/'sampling-verified/above.png',O/'assets/before-above.png')
for name in ['report.json','engine.log','source_manifest.json']:shutil.copyfile(RUN/name,O/'validation'/name)
for p in (R/'commons/artifacts/soft_snapshot_gallery').iterdir():
 if p.suffix in ['.gd','.tscn','.json']:shutil.copyfile(p,O/'source'/p.name)
for name in ['snapshot_examples.gd','sampling_gallery_room.gd','bake_sampling_gallery.gd']:shutil.copyfile(R/'tools/probes'/name,O/'source'/name)

# Short museum guidance; the full runnable lesson and its scope stay the same.
intro='''## Other shapes in this hall

Four comparison stations extend this encounter. In the first, choose which four moments of one simulation remain. In the second, pull the black point sideways and release: three matching constructions receive opposite lateral pulls. In the third, show the saved surface's triangle edges. Hiding the skin changes its appearance; its contact surface remains.

At **From the soft body gallery**, NEXT selects another group of three examples. POSE, or the held point's trigger, switches between starting and captured geometry: cloth, a lattice, a branch, a cellular-automata net and two mould experiments. Each pair keeps the same display frame. These are saved shapes; the controls do not resume their simulations. Cloth and sphere-grid skins are drawn over their saved connections; other examples show the spring network. A mould constrains particles in this model; it is not a simulation of molten glass.

Use these examples to ask what was retained. The tutorial below still builds one operation: copy the vessel's positions and face indices while its source continues.

'''
p=M/'tutorial.md';s=text(p)
if '## Other shapes in this hall' not in s:s=s.replace('## Build beside the encounter\n',intro+'## Build beside the encounter\n')
assert re.findall(r'```gdscript\n(.*?)\n```',s,re.S)==re.findall(r'```gdscript\n(.*?)\n```',text(O/'before/tutorial.md'),re.S)
write(p,s)
p=M/'final.md';s=text(p)
addition='''The row of four shapes lets the stop remain visible as a choice. At another bench, the same stop receives another pull. Beside them, a skin gives way to its triangle edges. Changing the display does not change the recorded positions. It changes what we can notice about them.

The gallery brings back a branch and a cellular rule. Their connections have become something that can bend or hang. A branch recipe supplies an arrangement; it does not tell us how that arrangement will bear its own weight. Switch back to the starting shape. What looked like a finished sculpture becomes one state among others again.

'''
if addition not in s:s=s.replace('Next, the room offers bodies that look alive.',addition+'Next, the room offers bodies that look alive.')
write(p,s)
p=M/'technical.md';s=text(p);marker='\n## More shapes kept — 9 October 2026\n'
s=s.split(marker)[0]+marker+'''
Four permanent comparison stations added. soft_capture_times at [15,18], soft_capture_gravity at [7,27], soft_capture_skin at [22,32], soft_sampled_gallery at [21,41], all yaw180. Existing artifacts and the primary tutorial code are retained. The first three use the unchanged frozen_glass_vessel construction (9 sculptures). The fourth displays six actual research configurations three at a time, captured through the unchanged render_soft_body builders and solver; all six repeated runs produced identical positions. It adds display skins for cloth/sphere grids and thickens springs into batched cylinders. Configs and exact initial/saved positions are in gallery_samples.json. No dynamic simulation or glass-fluid fidelity is claimed for this cabinet. Both states use identical combined-bound framing.

Native Godot museum checks: 64/64; six source configurations independently reproduced twice. Pointer controls, synthetic XRTools grabs/triggers, actual geometry, wire endpoints, replaced resources, supported approaches and the outer walking route passed. Physical headset comfort and Quest performance remain untested. New comparison stations are additional museum exploration, not additional prerequisite lessons. The main tutorial still teaches a copied surface with an unchanged PointBody.

Report: doc/book/iterations/2026-10-09-more-shapes-kept/index.html. Reproduce museum checks: python tools/run_encounter_probe.py SoftBodies_Playground_of_Joy --sequence softbodies --render --no-bridges --output-tag gallery-final --probe tools/probes/sampling_gallery_room.gd. Bake gallery data: Godot --headless --path . --script res://tools/probes/bake_sampling_gallery.gd.
'''
write(p,s)

# Reconcile this hall only; compare other rows before each shared-file write.
plan=next(x for x in read(R/'commons/data/museum/em_plan.json')['plans'] if x['map']==M.name)
row=read(RUN/'em_layout_walk.json')['halls'][KEY]
for rel in ['ada_run/em_layout_walk.json','commons/data/museum/em_layout_walk.json']:
 p=R/rel;stamp=p.stat().st_mtime_ns;d=read(p);old=copy.deepcopy(d)
 if not (O/'before'/p.name).exists():dump(O/'before'/p.name,d.get('halls',{}).get(KEY))
 d['halls'][KEY]=row
 assert {k:v for k,v in d['halls'].items() if k!=KEY}=={k:v for k,v in old['halls'].items() if k!=KEY}
 assert stamp==p.stat().st_mtime_ns;dump(p,d)
p=R/'commons/data/long_museum.json';stamp=p.stat().st_mtime_ns;d=read(p);old=copy.deepcopy(d)
segment=next(x for x in d['segments'] if x['name']==M.name)
if not (O/'before/long-museum-segment.json').exists():dump(O/'before/long-museum-segment.json',segment)
prior=len(segment['artifacts']);segment['artifacts']=[{'x':a['cell'][0],'z':a['cell'][1],'token':a['token'],'rot':a.get('rotation',0)} for a in plan['artifacts']]
delta=len(segment['artifacts'])-prior;d['totals']['artifacts']+=delta;next(c for c in d['chapters'] if c['sequence']=='softbodies')['artifacts']+=delta
assert [x for x in d['segments'] if x['name']!=M.name]==[x for x in old['segments'] if x['name']!=M.name]
assert stamp==p.stat().st_mtime_ns;write(p,json.dumps(d,ensure_ascii=False,separators=(',',':')))
p=R/'doc/book/course/execution-plan/plan.json';stamp=p.stat().st_mtime_ns;d=read(p);old=copy.deepcopy(d)
lesson=next(x for x in d['lessons'] if x['id']==M.name)
lesson['museumExpansion']={'report':'doc/book/iterations/2026-10-09-more-shapes-kept/index.html','stations':[a['token'] for a in plan['artifacts'] if a['token'].startswith(('soft_capture','soft_sampled'))],'focus':'Additional sampled forms; existing snapshot lesson unchanged.','checks':64,'headsetTested':False}
assert [x for x in d['lessons'] if x['id']!=M.name]==[x for x in old['lessons'] if x['id']!=M.name]
assert stamp==p.stat().st_mtime_ns;dump(p,d)

for k in ['tutorial','final']:shutil.copyfile(M/(k+'.md'),O/(k+'.md'))
css='''*{box-sizing:border-box}body{margin:0;background:#f4f0e8;color:#282a2d;font:18px/1.65 Georgia,serif}header,main,footer{max-width:1350px;margin:auto;padding:28px}header{border-bottom:1px solid #c6b9ae}nav{display:flex;gap:20px;flex-wrap:wrap;font:14px/1.5 system-ui}a{color:#73354d}h1{font-size:clamp(38px,5vw,68px);line-height:1.06;margin:18px 0}h2{font-size:29px;line-height:1.2}.eyebrow{font:12px/1.4 system-ui;letter-spacing:.13em}figure{margin:20px 0}img{width:100%;display:block;border-radius:3px}figcaption{font:14px/1.5 system-ui;margin:9px 0;color:#5d5a59}.pair,.spread{display:grid;grid-template-columns:1fr 1fr;gap:28px}.spread{max-width:1800px}article{min-width:0}pre{font:13px/1.5 monospace;background:#22252b;color:#eee;padding:20px;overflow:auto}table{border-collapse:collapse;width:100%;font:16px/1.5 system-ui}td,th{padding:12px;border-bottom:1px solid #c8bdb4;text-align:left}p{max-width:85ch}.note{background:#e7d7df;padding:16px}footer{font:13px system-ui}@media(max-width:800px){.pair,.spread{grid-template-columns:1fr}header,main{padding:20px}}'''
def md(s):return markdown.markdown(s,extensions=['fenced_code','tables'])
def page(title,body):return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+title+'</title><style>'+css+'</style><header><p class="eyebrow">ENDLESS MUSEUM / SOFT BODIES / 09 OCTOBER 2026</p><nav><a href="index.html">The expanded room</a><a href="parallel.html">Tutorial + reflection</a><a href="http://localhost:3003/soft-body-gallery">Source gallery</a><a href="validation/report.json">64 checks</a></nav></header>'+body+'<footer>Actual Godot museum captures. Synthetic XR input; physical headset testing remains open.</footer></html>'
def fig(name,caption):return '<figure><img loading="lazy" src="assets/'+name+'.png" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+caption+'</figcaption></figure>'
report='''# More shapes kept

Four new interactive stations in **SoftBodies_Playground_of_Joy**. They add nine vessel comparisons and six source-gallery studies (three shown at a time). The map now has ten registered artifact placements, including its six previous exhibits.

| Station | What you can do | What to notice |
| --- | --- | --- |
| Four moments, one recipe | CHANGE / held point trigger selects four stops | The same construction becomes different shapes over time. Starts at steps 0, 10, 40, 200. |
| The same stop, another pull | Pull point sideways; release to reconstruct | Three copies receive opposite lateral pulls at step 200. |
| One surface, two readings | Toggle skin, skin + edges, or edges only | The saved geometry and collision stay; the display changes. |
| From the soft body gallery | NEXT selects a trio; POSE / point trigger switches start and kept | Cloth, lattice, branch, CA net, box mould and sphere obstacle use real saved experiment data. |

The tutorial still teaches one new operation: copy positions and face indices while their source continues. The same PointBody supplies the interaction. A short exploration passage and two reflective paragraphs connect the new objects to that lesson; its four complete code blocks are unchanged.

The source gallery contains 24 configurations. These six were rerun using its existing builders; each repeated result matched exactly. Thick spring cylinders and cloth/sphere-grid skins make them readable in the room. The research captions contain analogies to glass; these are particle constraints and saved geometry, not molten-glass simulation.

**Validation:** 64/64 native museum checks passed. Real desktop pointer controls, synthetic XRTools grab/trigger, resource replacement, unchanged snapshots, matching display frames and route support/clearance were checked. Six bake checks also passed. Source algorithms and previous exhibits were preserved. Physical headset comfort and Quest performance remain open. The wider project still emits existing UID, registry and renderer warnings; this run had no script or parse errors.
'''
write(O/'REPORT.md',report)
body='<main><p class="eyebrow">HALL 06 / SAMPLING</p><h1>A gallery of moments kept.</h1><p>Change the stop. Change the pull. Return to a starting shape. The room gives you several ways to see what a saved form carries.</p>'
body+=fig('gallery-kept','Cloth, lattice and branch: actual source-gallery results inside the museum.')
body+='<div class="pair">'+fig('gallery-start','POSE returns to starting geometry. Scale and placement stay fixed.')+fig('gallery-moulds','NEXT brings the cellular-automata net and the two mould experiments.')+'</div>'
body+=fig('time-row','Four moments of one construction. The first stop keeps the starting sphere.')
body+='<div class="pair">'+fig('gravity-row','Same stop, opposite pulls. The black point controls the strength.')+fig('edges-only','The right copy shows the saved triangle edges. Its contact skin is still present.')+'</div>'
body+='<h2>Room before and after</h2><div class="pair">'+fig('before-above','Before: the existing six exhibits and open court.')+fig('above','After: four comparison stations, with space left to approach and walk onward.')+'</div>'
body+=md(report)+'<p><a href="tutorial.md">Tutorial Markdown</a> · <a href="final.md">Reflective Markdown</a> · <a href="source/gallery_samples.json">Six saved experiments</a></p></main>'
write(O/'index.html',page('More shapes kept',body))
write(O/'parallel.html',page('A shape kept — parallel texts','<main class="spread"><article><p class="eyebrow">TUTORIAL</p>'+md(text(O/'tutorial.md'))+'</article><article><p class="eyebrow">REFLECTION</p>'+md(text(O/'final.md'))+'</article></main>'))
for k in ['tutorial','final']:write(O/(k+'.html'),page(k,'<main><article>'+md(text(O/(k+'.md')))+'</article></main>'))
dump(O/'validation/source-hashes.json',{p.relative_to(R).as_posix():sha(p) for p in [*list((R/'commons/artifacts/soft_snapshot_gallery').glob('*.gd')),*list((R/'commons/artifacts/soft_snapshot_gallery').glob('*.tscn')),M/'tutorial.md',M/'final.md',M/'map_data.json']})
dump(O/'validation/placements.json',plan)

class Links(HTMLParser):
 def handle_starttag(self,tag,attrs):
  for name,value in attrs:
   if name in ['href','src'] and value and not urlparse(value).scheme and not value.startswith('#'):assert (O/unquote(value.split('#')[0])).exists(),value
for p in O.glob('*.html'):Links().feed(text(p))
oldpage=R/'doc/book/iterations/2026-10-09-sampling-a-shape-kept/index.html'
s=text(oldpage);banner='<p class="note"><a href="../2026-10-09-more-shapes-kept/index.html">New: more examples in this room, including six studies from the soft-body gallery.</a></p>'
if banner not in s:write(oldpage,s.replace('<main>','<main>'+banner,1))
print('Published four stations, 15 forms, 64 passed museum checks; four printed code blocks unchanged; local links verified.')
