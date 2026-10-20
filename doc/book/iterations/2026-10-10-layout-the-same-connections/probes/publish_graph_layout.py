from pathlib import Path
from html.parser import HTMLParser
import copy,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1];ID='GT_Layout'
O=R/'doc/book/iterations/2026-10-10-layout-the-same-connections';M=R/'commons/maps'/ID;S=R/'doc/book/studies/graphs-through-the-hands'/ID
RUN=R/'ada_run/encounter_pilot'/ID/'layout-final';KEY='graphtheory|gt layout'
def read(p):return json.loads(p.read_text(encoding='utf8'))
def text(p):return p.read_text(encoding='utf8')
def write(p,s):p.write_bytes(s.encode('utf8'))
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def preserve(p):
 q=O/'before'/p.relative_to(R);q.parent.mkdir(parents=True,exist_ok=True)
 if not q.exists():shutil.copy2(p,q)
code=read(O/'checks.json');room=read(RUN/'report.json')
assert code['passed'] and code['completed'] and room['passed'] and room['completed']
for p in [O/'code.log',RUN/'engine.log']:assert 'SCRIPT ERROR' not in text(p) and 'Parse Error' not in text(p)
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',text(M/'tutorial.md'),re.S)
assert len(blocks)==4 and hashlib.sha256(text(M/'tutorial.md').encode()).hexdigest()==code['tutorial_sha256']
for name,source in blocks:
 assert source+'\n'==text(S/name)==text(O/'printed'/name)
 assert hashlib.sha256((source+'\n').encode()).hexdigest()==code['printed_hashes'][name]
protected=['commons/maps/sequences/graphtheory.json','algorithms/graphtheory/force_directed_layout/ForceDirectedLayout.gd','algorithms/graphtheory/force_directed_layout/force_directed_layout.tscn','commons/artifacts/registry/graphtheory.json','ada_run/necklace_hand.json']
for rel in protected:assert (R/rel).read_bytes()==(O/'before'/rel).read_bytes(),rel
for name in ['point_body.gd','traversal.gd']:assert (S/name).read_bytes()==(S.parent/'GT_Foundations'/name).read_bytes()
plans=read(R/'commons/data/museum/em_plan.json')['plans'];oldplans=read(O/'before/commons/data/museum/em_plan.json')['plans']
assert [x for x in plans if x.get('map')!=ID]==[x for x in oldplans if x.get('map')!=ID]
plan=next(x for x in plans if x.get('map')==ID)
for directory in ['assets','museum','before-museum','after','probes']:(O/directory).mkdir(exist_ok=True)
for p in RUN.glob('*.png'):shutil.copyfile(p,O/'assets'/p.name)
for name in ['report.json','engine.log','source_manifest.json']:shutil.copyfile(RUN/name,O/'museum'/name)
for name in ['above.png','entry.png','report.json','engine.log']:shutil.copyfile(RUN.parent/'layout-before'/name,O/'before-museum'/name)
count=len(code['checks']);native=len(room['checks'])
technical=f'''# Layout — implementation and verification

The permanent exhibit remains algorithms/graphtheory/force_directed_layout/ForceDirectedLayout.gd and its existing scene, byte-for-byte unchanged. It uses eight vertices, twelve cube edges, pair repulsion, rest-length springs, velocity damping and bounds. Native checks confirm all degrees are three. Its source comments suggesting a uniquely best or natural arrangement are not adopted by either text.

The learner carries traversal.gd and point_body.gd byte-for-byte from GT_Foundations. Its seven IDs, six reciprocal undirected edges and initial coordinates are unchanged. New layout.gd keeps positions and velocities separate from adjacency, accumulates pair forces before advancing any vertex, and uses fixed physics callbacks with exponential damping. Near-contact repulsion is limited, speed is capped at two local units per second, and an exact coincident pair has no chosen separation direction. These safeguards do not prove convergence. It uses unit mass and is a diagram layout rather than a rigid-body simulation. The learner's exponential damping and parameters are intentionally simpler and more explicit than the installed exhibit's per-frame factor. They do not claim numerical equivalence.

The carried point now controls vertex0. Held world position is converted to local coordinates and projected onto XY; the blue marker displays that projection. On release the black point returns to the plane and moves with the layout. The host redraws cylinder lengths, midpoints and orientations. Trigger/1 pauses or resumes; R resets the drawing. Reset during holding is immediately superseded by the hand position on the next physics callback. Traversal readouts invoke the unchanged traversal and remain independent from geometry. No hidden scene reference, camera, lighting or replacement player is introduced.

The exact printed four-file source is extracted afresh by tools/test_graph_layout.py and run in Godot4.6. {count} checks pass: independent two-body force arithmetic, pair balance, read-before-write, repulsion without edges, compression, finite overlap, pin/release, ten seconds of default integration, unchanged adjacency and visit orders, cylinder endpoint geometry, keyboard dispatch and synthetic XRTools in a rotated host. The independent rest-length edit changes 0.65 to0.9; at600 steps of1/60s mean edge length changes from {code['observations']['mean_edge_default']:.6f} to {code['observations']['mean_edge_variation']:.6f}. Executed faults are caught for adjacency mutation, fixed-length rods and per-vertex force recalculation after earlier movement.

The native baseline rendered an irregular wall-filled interior and a full-scale graph cutting through it, although its map token requested scale0.6. This hall now declares artifact_placement=map and bypasses its old hand stamp without deleting the stamp. The15x13 footprint and entrance/exit columns remain. Tall interior cells become a continuous floor. The graph is at map cell(10,7), yaw180, elevation2.4m, scale0.3, graph=cube and layout_seed=41. Other catalogued graph artifacts remain in the registry. This is a focused hall arrangement, not an algorithm replacement.

The learner is temporarily instanced in native checks/captures at map-local(4.5,-0.45,4.5),yaw180; it is not silently installed as a permanent museum artifact. The tutorial describes exactly how to add it. The equivalent isolated hall-root position is(4.5,-0.45,8.5). {native} native checks pass, including66 floor/capsule samples along the middle passage, both exhibit approaches, initial point reach height, the installed cube graph and synthetic-hand pickup/trigger/release. Initial close-up cameras hit the front wall; the final captures move the camera inside, with no geometry hidden for the photograph.

This is an author-operated ghost-student reconstruction. It has not been independently read or tested in a physical headset. Continuous portal crossing, Quest performance and comfort are not verified. Existing UID, Jolt and renderer warnings remain in the logs; the final runs have no script/parse errors. Screenshots are native Godot captures.

Reproduce code: python tools/test_graph_layout.py

Reproduce museum: python tools/run_encounter_probe.py GT_Layout --sequence graphtheory --render --no-bridges --output-tag layout-final --probe tools/probes/graph_layout_room.gd
'''
write(M/'technical.md',technical)
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
 shutil.copyfile(M/name,O/'after'/name)
 if name.endswith('.md'):shutil.copyfile(M/name,O/name)
# Keep the existing editable views in agreement; never replace another hall's row.
layout=read(RUN/'em_layout_walk.json')['halls'][KEY]
for rel in ['ada_run/em_layout_walk.json','commons/data/museum/em_layout_walk.json']:
 p=R/rel;preserve(p);stamp=p.stat().st_mtime_ns;d=read(p);old=copy.deepcopy(d);d['halls'][KEY]=layout
 assert {k:v for k,v in d['halls'].items() if k!=KEY}=={k:v for k,v in old['halls'].items() if k!=KEY}
 assert stamp==p.stat().st_mtime_ns;dump(p,d)
p=R/'commons/data/long_museum.json';preserve(p);stamp=p.stat().st_mtime_ns;d=read(p);old=copy.deepcopy(d)
row=next(x for x in d['segments'] if x['name']==ID);old_count=len(row['artifacts'])
row['artifacts']=[{'x':a['cell'][0],'z':a['cell'][1],'token':a['token'],'rot':a['rotation'],'scale':a['scale']} for a in plan['artifacts']]
row.update(structure=read(M/'map_data.json')['layers']['structure'],tile=plan['tile'],tile_w=15,tile_h=13,tile_source='map',built=True)
delta=len(row['artifacts'])-old_count;d['totals']['artifacts']+=delta;next(c for c in d['chapters'] if c['sequence']=='graphtheory')['artifacts']+=delta
assert [x for x in d['segments'] if x['name']!=ID]==[x for x in old['segments'] if x['name']!=ID]
assert stamp==p.stat().st_mtime_ns;write(p,json.dumps(d,ensure_ascii=False,separators=(',',':')))
p=R/'doc/book/course/execution-plan/plan.json';preserve(p);stamp=p.stat().st_mtime_ns;d=read(p);old=copy.deepcopy(d)
row=next(x for x in d['lessons'] if x['id']==ID)
row.update(object='The carried PointBody becomes vertex0 of the same seven-vertex graph.',change='Keep adjacency fixed; compute springs along its edges and repulsion between all pairs. Hold zero to pin its local-plane position; release into the moving layout.',dependsOn=['GT_Foundations','SoftBodies_Cloth_Physics'],reuses='Unchanged PointBody and traversal.gd; IDs, adjacency, force accumulation, velocity, damping, local/world conversion and cylinder rendering.',given='Existing Endless Museum and XRTools. Complete display/input host and carried files printed alongside the new layout model.',later='No stress metric, shortest-route reconstruction, network influence measure or claim of unique equilibrium. Pathfinding will change availability.',checks=[f'{count} fresh exact-source checks, including independent force arithmetic and rest-length variation; three executed faulty variants caught.',f'{native} native museum checks: 66 clear floor samples, actual installed cube graph, synthetic XRTools interaction. No physical headset or blind-reader claim.'],transfer='Change only rest_length0.65 to0.9. Predict reduced spring pull at the same stretched separation, increased average edge length here, unchanged adjacency and queue/stack orders.',carry='Vertex identity and adjacency do not depend on the current drawing. Pin/release changes coordinates, never reachability.',next='GT_Pathfinding: retain point and graph representation; reconstruct a route and explain what changes when an option becomes unavailable.',notes='10 October: complete runnable Layout study and two texts; second hall only. Production ForceDirectedLayout algorithm unchanged. One permanent exhibit, reserved learner bay, old hand stamp bypassed locally. Review decision retained.',summary='Follow an edge in the museum\'s eight-vertex cube graph, then continue the student\'s seven-vertex graph and unchanged PointBody. Store positions and velocities separately from adjacency; let listed edges act as springs and all pairs repel. Hold the point to pin vertex0 in the drawing plane; release it and watch the layout continue. Predict and test a longer spring rest length while both earlier visit orders remain unchanged. Carry the difference between a new drawing and a new route into Pathfinding.')
previous=next(x for x in old['lessons'] if x['id']==ID)
assert row['decision']==previous['decision'] and row['baseline']==previous['baseline']
assert [x for x in d['lessons'] if x['id']!=ID]==[x for x in old['lessons'] if x['id']!=ID]
assert stamp==p.stat().st_mtime_ns;dump(p,d);dump(O/'lesson-plan.json',row)
write(O/'SUMMARY.md','# Layout — lesson paragraph\n\n'+row['summary']+'\n\nShort instruction: Museum given. Same seven IDs + adjacency + PointBody. New position/velocity record. Edge springs; all-pair repulsion; shared step; damping. Hold0→localXY pin; release→layout. Redraw endpoints. Rest0.65→0.9; predict spread, retain BFS/DFS. Next: route availability.\n')
report=f'''# Move the drawing. Keep the connections.

Graph Theory hall2 of8 continues Foundations with the same seven vertex IDs, the same adjacency and the same PointBody. The student now moves vertex0 while springs and repulsion rearrange the picture. The traversal code and point class are unchanged.

| Part | Before | Now |
| --- | --- | --- |
| Tutorial | Disconnected force fragments, missing host, undefined stress helpers | Four complete printed scripts; new layout model beside the carried graph and point |
| Operation | Moving sphere positions without complete edge updates | Every cylinder follows its two stable endpoint IDs |
| Reflection | Repeated explanations of layout | A drawing can suggest importance that the recorded relationships do not support |
| Museum | Large interior blocks conceal the graph | Open passage, fitted and elevated existing exhibit, space for the learner study |
| Independent task | Unspecified variation | Increase spring rest length; predict greater spread and unchanged visit orders |

The installed exhibit uses eight vertices in cube connectivity; every vertex has degree3. The tutorial uses the seven-vertex graph we already built. The texts explicitly distinguish these objects. This carries the student's work without pretending every museum artifact belongs to the tutorial.

The ghost reconstruction passes **{count} code checks and {native} native museum checks**. At the same600 simulation steps, the student's longer-rest edit increases mean edge length from {code['observations']['mean_edge_default']:.3f} to {code['observations']['mean_edge_variation']:.3f}. The queue remains0,1,2,3,4,5,6; the stack remains0,1,3,4,2,5,6. The code checks detect deliberately broken connectivity, rod updates and step ordering.

The room checks find continuous floor and body clearance at66 central-aisle samples and both exhibit approaches. The synthetic XRTools hand can pick up the point, move vertex0, pause/resume and release it. The learner study appears temporarily in the review captures; its installation instructions are in the tutorial. The permanent exhibit's algorithm and the eight-hall route remain unchanged.

These are author-operated engine checks, not an independent reader or physical headset assessment. We have not tested Quest performance, comfort or continuous portal crossing. The above and eye-level images are native Godot captures. An initial close-up camera clipped the front wall; the reviewed close-up is taken from inside the room.

**Next: Pathfinding.** This hall moved positions without removing an option. The next hall can make a stone unavailable and ask what the route must keep or replace.
'''
write(O/'REPORT.md',report)
css='''*{box-sizing:border-box}body{margin:0;background:#eeeae1;color:#24232a;font:18px/1.6 Georgia,serif}header,main,footer{max-width:1400px;margin:auto;padding:28px 4vw}header,footer{border-bottom:1px solid #bdb8ad}nav{display:flex;gap:12px 24px;flex-wrap:wrap;font:15px system-ui}a{color:#345463}h1{font-size:clamp(36px,5vw,66px);line-height:1.08}h2{font-size:30px;line-height:1.2;margin-top:2em}article{max-width:850px;margin:auto}.spread{display:grid;grid-template-columns:1fr 1fr;gap:2px;max-width:1800px}.spread article{background:#fcfaf4;padding:30px;min-width:0;width:100%;align-self:start}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}.pair article{min-width:0;padding:20px;background:#fcfaf4}.eyebrow,figcaption,footer{font:14px/1.6 system-ui}.eyebrow{text-transform:uppercase;letter-spacing:.12em;color:#64616a}.note{padding:18px;border-left:4px solid #678591;background:#faf7f1;font-family:system-ui}figure{margin:24px 0}img{width:100%;height:auto;display:block}figcaption{padding:12px 0;color:#5b5860}pre{overflow:auto;background:#202931;color:#edf0e8;padding:18px;line-height:1.5;font-size:14px;tab-size:4}code{font-size:.85em}pre code{font-size:inherit}table{border-collapse:collapse;width:100%;font:15px/1.5 system-ui}td,th{padding:12px;border-bottom:1px solid #c9c3b7;text-align:left;vertical-align:top}@media(max-width:900px){.spread,.pair{grid-template-columns:1fr}.spread article{padding:20px}}@media print{nav{display:none}pre{white-space:pre-wrap}body{background:white}}'''
def md(s):
 result=markdown.markdown(s,extensions=['fenced_code','tables']);source=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
 return re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(source)+'\n')+m[2],result,flags=re.S)
def page(title,body):
 return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p class="eyebrow">Endless Museum · Graph Theory 02 / 08 · 10 October 2026</p><nav><a href="index.html">Room and report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="graph-layout-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Native museum images. Tested author-operated reconstruction. Physical headset and independent reader review remain open.</footer></body></html>'
def fig(src,caption):return '<figure><img loading="lazy" src="'+src+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
for key in ['tutorial','final']:write(O/(key+'.html'),page(key,'<main><article>'+md(text(M/(key+'.md')))+'</article></main>'))
write(O/'parallel.html',page('Layout — facing texts','<main class="spread"><article><p class="eyebrow">Left · tutorial.md</p>'+md(text(M/'tutorial.md'))+'</article><article><p class="eyebrow">Right · final.md</p>'+md(text(M/'final.md'))+'</article></main>'))
changes='<main><h1>Before and after</h1>'
for key in ['tutorial','final']:changes+='<h2>'+key+'.md</h2><div class="pair"><article><p class="eyebrow">Previous draft</p>'+md(text(O/'before/commons/maps'/ID/(key+'.md')))+'</article><article><p class="eyebrow">Now</p>'+md(text(M/(key+'.md')))+'</article></div>'
write(O/'changes.html',page('Layout changes',changes+'</main>'))
body='<main><p class="eyebrow">The point returns as vertex zero</p><h1>Move the drawing.<br>Keep the connections.</h1><p class="note">'+str(count)+' code checks + '+str(native)+' native museum checks passed. Hall2 of8.</p>'
body+=fig('assets/student-after.png','The printed seven-vertex study inside GT_Layout, after pulling and releasing the black point. Both visit orders remain unchanged.')
body+='<div class="pair">'+fig('assets/student-before.png','Before the hand moves vertex0. The simulation is paused for comparison.')+fig('assets/student-after.png','After the hand moves vertex0 and the drawing responds. Paused for inspection; six edges remain.')+'</div>'
body+=fig('assets/installed-layout.png','The existing eight-vertex cube graph, scaled to fit and elevated above the floor. Its production algorithm is unchanged.')
body+='<h2>Room arrangement</h2><div class="pair">'+fig('before-museum/above.png','Baseline: the graph crosses a wall-filled interior.')+fig('assets/study-above.png','Revised hall: central passage, permanent layout on one side and the temporarily installed learner study on the other.')+'</div>'
body+='<div class="pair">'+fig('before-museum/entry.png','Baseline arrival: a wall interrupts the view.')+fig('assets/entry.png','The revised arrival looks into the open hall.')+'</div>'
body+='<article>'+md(report)+'<p><a href="SUMMARY.md">Paragraph and short instruction</a> · <a href="checks.json">Code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="technical.md">Implementation and limits</a></p></article></main>'
write(O/'index.html',page('Move the drawing, keep the connections',body))
write(O/'README.txt','Graph Theory hall2/8. Open index.html for native images/report, parallel.html for tutorial left and reflection right. printed/ has four exact scripts and the one-node study.tscn. Use inside AdaResearch Godot4.6 with existing XRTools and museum; not a standalone export. PointBody and traversal are unchanged from Foundations. variation/ changes spring rest length; fault-* files are intentionally wrong. Source tests, receipts and limitations are included.\n')
for name in ['graph_layout_student.gd','graph_layout_room.gd']:shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
for name in ['test_graph_layout.py','place_graph_layout.py','write_graph_layout.py','publish_graph_layout.py','start_graph_layout.py']:shutil.copyfile(R/'tools'/name,O/'probes'/name)
dump(O/'manifest.json',{'canonical':{n:sha(M/n) for n in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':code['printed_hashes'],'protected':{rel:sha(R/rel) for rel in protected},'checks':[count,native],'hall':ID,'physical_headset':False,'independent_reader':False})
archive=O/'graph-layout-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in O.rglob('*'):
  if not p.is_file() or p.suffix in ['.zip','.uid'] or p.name=='validation.json':continue
  if p.is_relative_to(O/'before') and p.name in ['em_plan.json','em_layout_walk.json','long_museum.json','plan.json','necklace_hand.json']:continue
  data=p.read_bytes()
  if p.suffix=='.html':data=data.replace(b'href="graph-layout-review.zip"',b'href="README.txt"')
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
 if p.name!='changes.html':
  for found in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',text(p),re.S):assert html.unescape(found) in [source+'\n' for _,source in blocks]
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None
 for name in [n for n in z.namelist() if n.endswith('.html')]:
  parser=Links();parser.feed(z.read(name).decode())
  for ref in parser.refs:assert (Path(name).parent/ref).as_posix() in z.namelist(),(name,ref)
dump(O/'validation.json',{'passed':True,'local_links':links,'printed_files':len(blocks),'rendered_code_matches':True,'zip_crc':True,'zip_links':True,'size_mb':round(archive.stat().st_size/1e6,2),'checks':[count,native]})
print(json.dumps(read(O/'validation.json')))
