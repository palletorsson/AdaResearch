from pathlib import Path
from html.parser import HTMLParser
import copy,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1];ID='GT_Foundations'
O=R/'doc/book/iterations/2026-10-10-graph-two-orders';M=R/'commons/maps'/ID
S=R/'doc/book/studies/graphs-through-the-hands'/ID
RUN=R/'ada_run/encounter_pilot'/ID/'graph-final';KEY='graphtheory|gt foundations'
def read(p):return json.loads(p.read_text(encoding='utf8'))
def text(p):return p.read_text(encoding='utf8')
def write(p,s):p.write_bytes(s.encode('utf8'))
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def preserve(p):
 q=O/'before'/p.relative_to(R);q.parent.mkdir(parents=True,exist_ok=True)
 if not q.exists():shutil.copy2(p,q)
code=read(O/'checks.json');room=read(RUN/'report.json')
assert code['passed'] and code['completed'] and room['passed']
assert any(c['name']=='All planned graph room checks completed' and c['passed'] for c in room['checks'])
for p in [O/'code.log',RUN/'engine.log']:assert 'SCRIPT ERROR' not in text(p) and 'Parse Error' not in text(p)
assert hashlib.sha256(text(M/'tutorial.md').encode()).hexdigest()==code['tutorial_sha256']
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',text(M/'tutorial.md'),re.S)
assert len(blocks)==3
for name,source in blocks:
 assert source+'\n'==text(S/name)==text(O/'printed'/name)
 assert hashlib.sha256((source+'\n').encode()).hexdigest()==code['printed_hashes'][name]
protected=['commons/maps/sequences/graphtheory.json','commons/artifacts/two_travelers/two_travelers.gd','commons/artifacts/two_travelers/two_travelers.tscn','doc/book/studies/soft-bodies-through-the-hands/Topology_Entropy_Morphogenesis/point_body.gd']
for name in protected:assert (R/name).read_bytes()==(O/'before'/name).read_bytes(),name
assert (S/'point_body.gd').read_bytes()==(R/protected[-1]).read_bytes()
registry=read(R/'commons/artifacts/registry/graphtheory.json');prior=read(O/'before/commons/artifacts/registry/graphtheory.json')
prior['artifacts']['two_travelers'].update(lookup_name='two_travelers',map_ready=True)
assert registry==prior
plan=next(p for p in read(R/'commons/data/museum/em_plan.json')['plans'] if p.get('map')==ID)
oldplans=read(O/'before/commons/data/museum/em_plan.json')['plans']
assert [p for p in read(R/'commons/data/museum/em_plan.json')['plans'] if p.get('map')!=ID]==[p for p in oldplans if p.get('map')!=ID]
for folder in ['assets','museum','before-museum','after','probes']:(O/folder).mkdir(exist_ok=True)
for p in RUN.glob('*.png'):shutil.copyfile(p,O/'assets'/p.name)
for name in ['report.json','engine.log','source_manifest.json']:shutil.copyfile(RUN/name,O/'museum'/name)
for name in ['above.png','entry.png','report.json','engine.log']:
 shutil.copyfile(RUN.parent/'graph-baseline'/name,O/'before-museum'/name)
count=len(code['checks']);native=len(room['checks'])
technical=f'''# Two orders — implementation and verification

The primary artifact is commons/artifacts/two_travelers/two_travelers.gd. Its fifteen-vertex child lists, BFS/DFS computations, lamp geometry and replay timing are unchanged. The registry entry previously lacked map_ready, so the museum omitted it. This pass adds map_ready=true and an explicit lookup_name for this entry only.

GT_Foundations formerly replayed an older necklace stamp with three oversized graph exhibits. The actual baseline had no TwoTravellers despite the sequence and final text naming it. The map now declares artifact_placement=map, preserving the old stamp on disk but bypassing it for this hall. The 13x12 footprint and two openings remain; a continuous floor replaces the islands. Only TwoTravellers at (9,7),yaw180,scale1 and the supporting bridge model at (3,8),yaw180,scale.10 are placed. Registry scenes for the omitted graphspace, graphspace3d and synthesis stand remain available. They are not learner prerequisites. The old bridge display contains a simplified Euler-condition label; it is not used as a proof or as this lesson's algorithm.

The learner at doc/book/studies/graphs-through-the-hands/GT_Foundations has three complete scripts and a one-node scene. traversal.gd is the new operation; study.gd supplies the seven-lamp renderer/input; point_body.gd is byte-identical to the carried Morphogenesis point. XRTools remains a project dependency. No camera, light, player, hidden child reference or replacement museum is made.

The installed exhibit is a fifteen-node directed child tree. The learner deliberately uses seven vertices with reciprocal adjacency. It is a reconstruction of queue/stack traversal, not an assertion of identical graph data. pending may contain repeated candidates on cyclic graphs; the guard discards already visited IDs when removing them. A copied reversed neighbour list gives DFS the first listed neighbour first without changing adjacency. Only the component reachable from vertex0 is visited. Edges are unweighted. No shortest-path reconstruction, priority queue, Euler walk or asymptotic performance lesson is claimed here; Array.pop_front is appropriate for this tiny inspectable example.

The study is temporary in the native capture and test, at map-local (3.5,0,4.5),yaw180. The isolated hall root is four metres before map zero, so root-local z=8.5. Place one instance there in the existing museum project. Held trigger advances one visit; after completion, the next trigger prepares the other order. Release parks the point after process callbacks and preserves the record. Keyboard1 advances,2 switches,R restarts. Geometry positions never enter the traversal procedure. The next lesson can reuse this adjacency while changing its drawing.

{count}/{count} checks pass on freshly extracted printed code: initialized scene, expected queue/stack orders, pending state, cycles, a disconnected vertex and self-loop, unchanged source adjacency, real key dispatch, echo filtering, restart, rod endpoints, transformed-host synthetic XRTools, independent neighbour-order edit, and three executed faulty variants. The checker catches the wrong queue end, reversing the source list in place and revisiting a duplicate candidate. A first release check sampled before process had parked the point; the corrected checker waits four frame pairs. Learner code did not change to hide that timing.

{native}/{native} native museum checks pass. Both approaches and {room['observations']['route_samples']} central aisle samples have floor and capsule clearance. The first .12 bridge scale clipped one aisle sample; .10 clears it. Installed fifteen-lamp data and the printed seven-lamp interaction were exercised; native queue/stack and above captures were inspected. Camera capture positions were moved inside the room after a front wall obscured part of the initial image. Existing UID/Jolt/renderer warnings remain, with no script or parse errors in these final runs. This is an author-operated ghost reconstruction, not an independent reader or a physical headset test. Quest performance, comfort and a continuous portal crossing are not tested.

Reproduce: python tools/test_graph_foundations.py

Native: python tools/run_encounter_probe.py GT_Foundations --sequence graphtheory --render --no-bridges --output-tag graph-final --probe tools/probes/graph_foundations_room.gd
'''
write(M/'technical.md',technical)
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
 shutil.copyfile(M/name,O/'after'/name)
 if name.endswith('.md'):shutil.copyfile(M/name,O/name)
# Update only this hall in the two layout views and long-museum summary.
layout=read(RUN/'em_layout_walk.json')['halls'][KEY]
for rel in ['ada_run/em_layout_walk.json','commons/data/museum/em_layout_walk.json']:
 p=R/rel;preserve(p);stamp=p.stat().st_mtime_ns;data=read(p);old=copy.deepcopy(data)
 data['halls'][KEY]=layout
 assert {k:v for k,v in data['halls'].items() if k!=KEY}=={k:v for k,v in old['halls'].items() if k!=KEY}
 assert stamp==p.stat().st_mtime_ns;dump(p,data)
p=R/'commons/data/long_museum.json';preserve(p);stamp=p.stat().st_mtime_ns;data=read(p);old=copy.deepcopy(data)
row=next(x for x in data['segments'] if x['name']==ID);old_count=len(row['artifacts'])
row['artifacts']=[{'x':a['cell'][0],'z':a['cell'][1],'token':a['token'],'rot':a['rotation'],'scale':a['scale']} for a in plan['artifacts']]
row.update(structure=read(M/'map_data.json')['layers']['structure'],tile=plan['tile'],tile_w=13,tile_h=12,tile_source='map')
row['built']=True
delta=len(row['artifacts'])-old_count;data['totals']['artifacts']+=delta
next(c for c in data['chapters'] if c['sequence']=='graphtheory')['artifacts']+=delta
assert [x for x in data['segments'] if x['name']!=ID]==[x for x in old['segments'] if x['name']!=ID]
assert stamp==p.stat().st_mtime_ns;write(p,json.dumps(data,ensure_ascii=False,separators=(',',':')))
p=R/'doc/book/course/execution-plan/plan.json';preserve(p);stamp=p.stat().st_mtime_ns;data=read(p);old=copy.deepcopy(data)
row=next(x for x in data['lessons'] if x['id']==ID)
row.update(object='Carried PointBody advances a seven-vertex graph; the museum supplies the fifteen-lamp encounter.',change='Write reciprocal adjacency and take the oldest or newest pending ID; keep connections and drawing fixed.',dependsOn=['Point_Trace','Point_Triangle_Context','Topology_Entropy_Morphogenesis'],reuses='PointBody unchanged; arrays, nested lists, loops, conditions, functions and action signals.',given='Endless Museum, XRTools hands; complete seven-lamp display/input host printed in tutorial.md.',later='Layout changes coordinates. Pathfinding later adds route reconstruction. Bridge/Euler question stays a separate optional encounter.',checks=[f'{count} fresh exact-printed-code checks: orders, cycle/disconnection, input, XRTools, independent edit and three caught faults.',f'{native} native museum checks; 57 supported clear aisle samples; no headset or blind-reader claim.'],transfer='Change only neighbours[0] from [1,2] to [2,1]. Predict queue 0,2,1,5,6,3,4 and stack 0,2,5,6,1,3,4; retain every edge and position.',carry='Vertex IDs and adjacency remain distinct from drawing coordinates; pending and visited are separate records.',next='GT_Layout: reuse this graph and PointBody; change the drawing while holding connectivity fixed. Audit actual layout artifact before expanding.',notes='10 October first hall implemented and tested. Fixed missing map_ready and outdated necklace placement locally. The other seven halls retain their existing drafts; this is not a completed chapter.',summary='Encounter the two visit orders in the existing museum. Carry PointBody as a step control; write seven stable vertex IDs with explicit reciprocal neighbours. Keep the drawing fixed while a queue takes the oldest pending ID and a stack takes the newest, skipping already visited IDs. Predict the next lamp, then reverse only the start vertex\'s neighbour order and explain the changed visits without adding an edge. Carry adjacency, pending work and visited state separately into Layout.')
assert row['decision']==next(x for x in old['lessons'] if x['id']==ID)['decision'] and row['baseline']==next(x for x in old['lessons'] if x['id']==ID)['baseline']
assert [x for x in data['lessons'] if x['id']!=ID]==[x for x in old['lessons'] if x['id']!=ID]
assert stamp==p.stat().st_mtime_ns;dump(p,data);dump(O/'lesson-plan.json',row)
write(O/'SUMMARY.md','# GT_Foundations — lesson paragraph\n\n'+row['summary']+'\n\nShort instruction: Existing museum. Same PointBody → step. Seven IDs + reciprocal adjacency. Fixed layout. Queue oldest / stack newest. Skip visited. Predict; reverse root neighbours; preserve edges. Carry graph → Layout. Renderer supplied; code complete.\n')
report=f'''# Two orders, the same connections

Graph Theory begins with one question: **what changes when the connections stay fixed but the order of attention changes?** This is hall 1 of 8. The remaining seven halls keep their existing drafts and sequence order.

The black point returns as a step control. One press visits one vertex. A seven-lamp graph makes the pending list small enough to follow; the existing fifteen-lamp exhibit remains the larger encounter. The student writes adjacency and traversal. The complete renderer and inherited point are supplied, visible and tested.

| Part | Before | Now |
| --- | --- | --- |
| Tutorial | Fragmentary bridge/Euler code, unrelated to the chosen traversal focus | One complete queue/stack construction, explanations and an independent edit |
| Reflection | Two travellers, with repeated algorithm explanations | Waiting, attention, and an urgency the graph has not recorded |
| Actual hall | Old stamp omitted the travellers; oversized exhibits crossed arrival | Travellers restored, smaller supporting bridge model, continuous floor and central aisle |
| Student lineage | A new generic graph class with incomplete rendering | Same PointBody and familiar lists; new adjacency and pending-work rule |
| Evidence | No focused reconstruction receipt | {count} code checks and {native} native museum checks |

## A small change the student can explain

Queue: 0,1,2,3,4,5,6. Stack: 0,1,3,4,2,5,6. The graph does not move. Change the first neighbour list from [1,2] to [2,1]: queue becomes 0,2,1,5,6,3,4; stack becomes 0,2,5,6,1,3,4. The same edges now support another visit order. Restoring the list prepares the next hall.

The installed exhibit uses fifteen parent-to-child entries; the learner uses a smaller seven-vertex tree with reciprocal adjacency. The text declares that difference. It also distinguishes a sequence of visits from continuous movement along edges, and visiting vertices from crossing each edge once.

## What changed in the museum

The room's old hand-placement stamp had overruled the intended map. The travellers were also missing the registry's map_ready flag. Both problems are repaired for GT_Foundations. The artifact's traversal code, lamp geometry and timing are unchanged. The 13×12 hall now has a continuous floor, two exhibits and an open study bay. Other graphspace scenes remain in the project; their previous placement is preserved in the baseline. They are omitted from this focused opening hall.

The student graph shown in the captures is temporarily instanced from the exact printed code. It is not a permanently registered third exhibit. The museum supplies the room, player and XR system. The native probe checks {room['observations']['route_samples']} floor/capsule samples along the central aisle and both approaches. It does not certify passage through the next portal or physical headset comfort.

## What the tests establish

The author-operated ghost reconstruction extracts the three printed scripts, initializes every object and runs them in Godot 4.6. It checks queue/stack order, cycles, disconnected vertices, self-loops, unchanged adjacency, drawing endpoints, actual key events, synthetic XRTools pickup/trigger/release, and the independent edit. Three deliberately faulty variants are caught. It does not establish that an independent student understood the explanation.

All {count} code checks and {native} native checks pass. The images are native Godot captures. No script/parse errors occurred in the final runs; existing project UID, Jolt and renderer warnings remain in the logs. The final source, logs and receipts are packaged alongside the texts.

## The next room

GT_Layout can keep the graph record and the point while letting positions move. This gives the next operation a precise boundary: rearrange a drawing without changing what is connected. Its full tutorial is the next writing pass.
'''
write(O/'REPORT.md',report)
css='''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#eeeae1;color:#24232a;font:18px/1.6 Georgia,serif}header,main,footer{max-width:1400px;margin:auto;padding:28px 4vw}header{border-bottom:1px solid #bdb8ad}nav{display:flex;gap:10px 24px;flex-wrap:wrap;font:15px/1.5 system-ui}a{color:#345463;text-underline-offset:3px}h1{font-size:clamp(36px,5vw,68px);line-height:1.08;max-width:1000px}h2{font-size:30px;line-height:1.2;margin-top:2em}article{max-width:850px;margin:auto}.spread{display:grid;grid-template-columns:1fr 1fr;gap:2px;max-width:1800px}.spread article{background:#fcfaf4;padding:30px;min-width:0;width:100%}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}.pair article{padding:24px;background:#fcfaf4;min-width:0}.eyebrow,figcaption,summary,footer{font:14px/1.6 system-ui}.eyebrow{text-transform:uppercase;letter-spacing:.12em;color:#64616a}.note{padding:16px 22px;border-left:4px solid #678591;background:#f8f6f0;font-family:system-ui}figure{margin:24px 0}img{width:100%;height:auto;display:block;background:#272f36}figcaption{padding:12px 0;color:#5b5860}pre{overflow:auto;background:#202931;color:#edf0e8;padding:18px;line-height:1.5;font-size:14px;tab-size:4}code{font-size:.85em}pre code{font-size:inherit}table{border-collapse:collapse;width:100%;font:15px/1.5 system-ui}td,th{padding:12px;border-bottom:1px solid #c9c3b7;text-align:left;vertical-align:top}details{margin:24px 0;border:1px solid #d0cabd;padding:16px}summary{cursor:pointer;font-weight:700}footer{border-top:1px solid #bdb8ad;color:#666}@media(max-width:900px){.spread,.pair{grid-template-columns:1fr}.spread article{padding:20px}main{padding:20px}}@media print{nav{display:none}details{display:block}pre{white-space:pre-wrap}body{background:white}}'''
def md(s):
 out=markdown.markdown(s,extensions=['fenced_code','tables'])
 source=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
 return re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(source)+'\n')+m[2],out,flags=re.S)
def page(title,body):
 return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p class="eyebrow">Endless Museum · Graph Theory 01 / 08 · 10 October 2026</p><nav><a href="index.html">Room and report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="graph-foundations-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Native museum images. Executable author-operated reconstruction. Physical headset and independent learner review remain open.</footer></body></html>'
def fig(src,caption):return '<figure><img loading="lazy" src="'+src+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
for key in ['tutorial','final']:write(O/(key+'.html'),page(key,'<main><article>'+md(text(O/(key+'.md')))+'</article></main>'))
write(O/'parallel.html',page('Two orders — facing texts','<main class="spread"><article><p class="eyebrow">Left · tutorial.md</p>'+md(text(M/'tutorial.md'))+'</article><article><p class="eyebrow">Right · final.md</p>'+md(text(M/'final.md'))+'</article></main>'))
changes='<main><h1>Before and after</h1>'
for key in ['tutorial','final']:
 changes+='<h2>'+key+'.md</h2><div class="pair"><article><p class="eyebrow">Before · historical draft</p>'+md(text(O/'before/commons/maps'/ID/(key+'.md')))+'</article><article><p class="eyebrow">Now</p>'+md(text(M/(key+'.md')))+'</article></div>'
write(O/'changes.html',page('First hall changes',changes+'</main>'))
body='<main><p class="eyebrow">The point returns as a step control</p><h1>Two orders.<br>The same connections.</h1><p class="note">'+str(count)+' code checks + '+str(native)+' native museum checks passed. First hall only; the eight-hall sequence keeps its order.</p>'
body+=fig('assets/student-queue.png','Printed seven-lamp study inside GT_Foundations. After three queue visits: 0,1,2. The carried black PointBody advances the next visit.')
body+='<div class="pair">'+fig('assets/student-queue.png','Queue takes the left end. Pending neighbours spread across the next layer.')+fig('assets/student-stack.png','Stack takes the right end. After three visits: 0,1,3. Vertex2 still waits.')+'</div>'
body+=fig('assets/encounter.png','The existing fifteen-lamp Two Travellers is now present in the museum. Its traversal algorithm and geometry are unchanged.')
body+='<h2>The room can be read</h2><div class="pair">'+fig('before-museum/above.png','Before: an old placement override spread oversized graph worlds through the hall and omitted the travellers.')+fig('assets/study-above.png','Now, from above: two permanent exhibits, a clear central aisle and the temporary printed study in its reserved bay.')+'</div>'
body+='<div class="pair">'+fig('before-museum/entry.png','Before: a supporting exhibit obstructed arrival.')+fig('assets/entry.png','Now: arrival opens toward the travellers and the smaller bridge model.')+'</div>'
body+='<article>'+md(report)+'<p><a href="SUMMARY.md">Lesson paragraph + short instruction</a> · <a href="checks.json">Code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="technical.md">Implementation and limits</a></p></article>'
sequence=read(R/'commons/maps/sequences/graphtheory.json')['sequences']['graphtheory']
body+='<h2>Route through Graph Theory</h2><ol>'
for i,line in enumerate(sequence['content']):body+='<li>'+html.escape(line)+(' — this pass.' if i==0 else ' — existing draft; next passes.')+'</li>'
body+='</ol></main>'
write(O/'index.html',page('Two orders, the same connections',body))
write(O/'README.txt','Open index.html for images/report, parallel.html for the two text tracks. This is Graph Theory hall1, not the complete eight-hall chapter. printed/ holds the three exact scripts and one-node study scene. Run within the existing AdaResearch project with Godot4.6 and XRTools; this is not a standalone export. The study is temporarily instanced in native captures. Triggers/1 advance;2 changes method;R restarts. variation/ changes root neighbour order. fault-* scripts are intentionally wrong. See technical.md and receipts for scope and replay.\n')
for name in ['graph_foundations_room.gd','graph_foundations_student.gd']:shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
for name in ['test_graph_foundations.py','place_graph_foundations.py','write_graph_foundations_lesson.py','publish_graph_foundations.py']:shutil.copyfile(R/'tools'/name,O/'probes'/name)
dump(O/'manifest.json',{'canonical':{n:sha(M/n) for n in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':code['printed_hashes'],'protected':{p:sha(R/p) for p in protected},'checks':[count,native],'first_hall_only':True,'physical_headset':False,'independent_reader':False})
archive=O/'graph-foundations-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in O.rglob('*'):
  if not p.is_file() or p.suffix in ['.zip','.uid'] or p.name=='validation.json':continue
  # Preserve only selected-row metadata in the distributable review; full rollback files stay local.
  if p.is_relative_to(O/'before') and p.name in ['em_plan.json','em_layout_walk.json','long_museum.json','plan.json','necklace_hand.json']:continue
  data=p.read_bytes()
  if p.suffix=='.html':data=data.replace(b'href="graph-foundations-review.zip"',b'href="README.txt"')
  z.writestr(p.relative_to(O).as_posix(),data)
class Links(HTMLParser):
 def __init__(self):super().__init__();self.refs=[]
 def handle_starttag(self,tag,attrs):
  for k,v in attrs:
   if k in ['href','src'] and v and not v.startswith(('#','/','http:','https:','mailto:')):self.refs.append(v.split('#')[0].split('?')[0])
links=0
for p in O.glob('*.html'):
 parser=Links();parser.feed(text(p))
 for ref in parser.refs:assert (p.parent/ref).exists(),(p,ref);links+=1
 for found in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',text(p),re.S):
  if p.name!='changes.html':assert html.unescape(found) in [source+'\n' for _,source in blocks]
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None
 for name in [n for n in z.namelist() if n.endswith('.html')]:
  parser=Links();parser.feed(z.read(name).decode())
  for ref in parser.refs:assert (Path(name).parent/ref).as_posix() in z.namelist(),(name,ref)
dump(O/'validation.json',{'passed':True,'local_links':links,'printed_files':len(blocks),'rendered_code_matches':True,'zip_crc':True,'zip_links':True,'size_mb':round(archive.stat().st_size/1e6,2),'checks':[count,native]})
print(json.dumps(read(O/'validation.json')))
