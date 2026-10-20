from pathlib import Path
from html.parser import HTMLParser
import copy,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1];ID='GT_Pathfinding'
O=R/'doc/book/iterations/2026-10-10-pathfinding-a-route-kept';M=R/'commons/maps'/ID;S=R/'doc/book/studies/graphs-through-the-hands'/ID
RUN=R/'ada_run/encounter_pilot'/ID/'path-final';KEY='graphtheory|gt pathfinding'
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
protected=['commons/maps/sequences/graphtheory.json','commons/artifacts/impatient_river/impatient_river.gd','commons/artifacts/impatient_river/impatient_river.tscn','ada_run/necklace_hand.json']
for rel in protected:assert (R/rel).read_bytes()==(O/'before'/rel).read_bytes(),rel
registry='commons/artifacts/registry/graphtheory.json'
old_registry=read(O/'before'/registry)
old_registry['artifacts']['impatient_river'].update(lookup_name='impatient_river',map_ready=True)
assert read(R/registry)==old_registry
for name in ['point_body.gd','traversal.gd']:assert (S/name).read_bytes()==(S.parent/'GT_Layout'/name).read_bytes()
plans=read(R/'commons/data/museum/em_plan.json')['plans'];oldplans=read(O/'before/commons/data/museum/em_plan.json')['plans']
# em_plan is read-only here; other halls may have concurrent edits.
old_by_map={x.get('map'):x for x in oldplans}
unrelated_changes=[x.get('map') for x in plans if x.get('map')!=ID and x!=old_by_map.get(x.get('map'))]
print('Other plan rows retained:', unrelated_changes)
plan=next(x for x in plans if x.get('map')==ID)
for directory in ['assets','museum','before-museum','after','probes']:(O/directory).mkdir(exist_ok=True)
for p in RUN.glob('*.png'):shutil.copyfile(p,O/'assets'/p.name)
for name in ['report.json','engine.log','source_manifest.json']:shutil.copyfile(RUN/name,O/'museum'/name)
for name in ['above.png','entry.png','report.json','engine.log']:shutil.copyfile(RUN.parent/'path-before'/name,O/'before-museum'/name)
count=len(code['checks']);native=len(room['checks'])
technical=f"""# Pathfinding — implementation and verification

The permanent primary exhibit is commons/artifacts/impatient_river/impatient_river.gd and its scene. Both remain byte-for-byte unchanged. This run restored the registry entry's lookup_name and map_ready flag so the exhibit named in the reflection actually loads. The existing pathfinding3d maze remains as a smaller supporting exhibit. The eight-hall sequence is unchanged.

The river constructs two banks and eleven seeded stones. Pairs within link_r are connected, and each bank receives a link to its nearest stone if needed. AStar3D's default cost minimises summed Euclidean segment lengths, not stone count. Pressing the real connected button disables a stone on the current route, or another available interior stone if no route exists. Replanning happens immediately; route indices reset. If a route exists the spark returns to its start bank; otherwise it stays where it stopped. Once more than three stones have been disabled, the oldest resurfaces. The production plaque's reference to the next crossing is imprecise; these texts follow the implemented immediate replanning. Source: https://docs.godotengine.org/en/stable/classes/class_astar3d.html

The learner carries point_body.gd and traversal.gd byte-for-byte from Layout. The same seven vertex IDs, initial positions and previous edges remain. A new route.gd subclass adds exactly one reciprocal edge, 4–5: the earlier tree could not offer a detour. New find_path uses the existing queue state with a goal, discovers each vertex once, records its predecessor at enqueue time, and reconstructs from goal back to the sentinel at the start. Every edge costs one. Availability is a separate filter; adjacency is retained. The drawing has no influence on this search. The complete display/input host and both carried files are printed in tutorial.md. No hidden dollar reference or scene-only initializer is required.

The point follows a completed answer. Holding pauses its recorded cursor. Releasing returns it to that cursor; trigger or 1 changes availability and replans from 3. R replays the current route. With no route the point waits at a reachable parking position. A synthetic XRTools pickup exercises the inherited trigger and release in a transformed host; it is not a physical headset test.

The exact four printed scripts are extracted and run in a fresh Godot 4.6 process. All {count} checks pass, including all 128 availability masks compared with an independent exhaustive simple-path oracle, blocked and invalid endpoints, start=goal, clearing previous search state, unchanged adjacency, rod geometry, input echo, goal arrival and held/released behavior. Removing the extra edge is executed as the student's independent edit: it keeps the first route and eliminates the detour. Three deliberately faulty variants are rejected: ignoring blocked vertices, using a stack while promising fewest edges, and reversing path reconstruction.

Two harness problems were corrected before this receipt. A dynamically called typed-array parameter required an explicitly typed array in the test helper. Also, the test had disabled the host's frame loop and then expected that loop to maintain the parked body's transform across physics frames. That assertion now runs with the real frame loop enabled, and checks the parked position after frames have elapsed. The same check passes in the native museum. Diagnostic logs are retained. Learner code was not weakened to satisfy those tests.

The native baseline had a very large maze and no river. The revised 13x14 hall keeps entry/exit positions, supplies a continuous floor and central passage, and uses map placement while bypassing its older hand stamp locally. The river occupies map cell (9,8), yaw 180, scale 1. The maze occupies (3,10), yaw 180, scale 0.16. The learner bay is map-local(3.5,-0.25,5.5),yaw180,scale1; its equivalent isolated hall-root position is(3.5,-0.25,9.5). It is temporarily installed for checks and captures, not silently registered as another permanent exhibit. Installation instructions are printed.

All {native} native checks pass, including 69 floor/body-clearance samples, both exhibit approaches, real river button signal, stone restoration, explicit no-route and restored-route cases, and learner XRTools pickup/trigger/release. The default seed's first sinking leaves no route; the two text tracks now admit this actual outcome. The smaller learner graph deliberately demonstrates both a detour and no route. Native eye-level and above images are included.

This is an author-operated ghost-student reconstruction. Independent reader, physical headset, Quest performance, comfort and continuous portal traversal remain untested. Existing UID, Jolt and renderer warnings are preserved in logs; final runs have no script/parse errors.

Reproduce code: python tools/test_graph_pathfinding.py

Reproduce museum: python tools/run_encounter_probe.py GT_Pathfinding --sequence graphtheory --render --no-bridges --output-tag path-final --probe tools/probes/graph_pathfinding_room.gd
"""
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
row.update(structure=read(M/'map_data.json')['layers']['structure'],tile=plan['tile'],tile_w=13,tile_h=14,tile_source='map',built=True)
delta=len(row['artifacts'])-old_count;d['totals']['artifacts']+=delta;next(c for c in d['chapters'] if c['sequence']=='graphtheory')['artifacts']+=delta
assert [x for x in d['segments'] if x['name']!=ID]==[x for x in old['segments'] if x['name']!=ID]
assert stamp==p.stat().st_mtime_ns;write(p,json.dumps(d,ensure_ascii=False,separators=(',',':')))
p=R/'doc/book/course/execution-plan/plan.json';preserve(p);stamp=p.stat().st_mtime_ns;d=read(p);old=copy.deepcopy(d)
row=next(x for x in d['lessons'] if x['id']==ID)
row.update(object='The carried PointBody travels through the same seven-vertex graph, with one explicit extra connection.',change='Add reciprocal edge 4–5; use the queue to discover predecessors and reconstruct a fewest-edge route. Filter availability without deleting adjacency.',dependsOn=['GT_Foundations','GT_Layout'],reuses='Unchanged PointBody and traversal.gd; seven vertex IDs, queue, adjacency, local coordinates, cylinder rendering and inherited trigger.',given='Existing Endless Museum and XRTools; complete host and both carried scripts printed. The river uses AStar3D; the learner rebuilds route availability with unweighted BFS.',later='Weighted search, heuristics and performance are not taught here. Path animation is not search animation or player navigation.',checks=[f'{count} fresh exact-source checks; all 128 availability masks compared with exhaustive simple paths; independent detour removal; three faulty variants rejected.',f'{native} native museum checks: 69 aisle samples, real river button signal, synthetic XRTools hold/trigger/release. No physical headset or independent-reader claim.'],transfer='Remove the added4–5 edge: predict the first route remains, but blocking0 now gives no route. Recover the route from predecessor and distinguish it from visited.',carry='The same graph can produce a route, detour or no route under different availability. Discovery order and recovered path have different jobs.',next='GT_Network_Analysis: inspect relationships across the network rather than one requested journey.',notes='10 October: third hall only. Existing river restored to registry; maze scaled to fit. Complete tested learner code and reflective text. Production exhibit algorithms unchanged. Review decision retained.',summary='Watch the museum river lose a stone, then continue the same seven vertices and PointBody. Add one reciprocal connection, 4–5, so the earlier tree can offer a detour. Extend the queue search to record predecessors and reconstruct a route from 3 to 6. Hold the point to pause its journey; use its trigger to block 0, then 4, then restore both. Predict a four-edge route, a five-edge detour and no route, and test that removing the extra connection removes only the detour. Carry the distinction between search order, route and availability into Network Analysis.')
previous=next(x for x in old['lessons'] if x['id']==ID)
assert row['decision']==previous['decision'] and row['baseline']==previous['baseline']
assert [x for x in d['lessons'] if x['id']!=ID]==[x for x in old['lessons'] if x['id']!=ID]
assert stamp==p.stat().st_mtime_ns;dump(p,d);dump(O/'lesson-plan.json',row)
write(O/'SUMMARY.md','# Pathfinding — lesson paragraph\n\n'+row['summary']+'\n\nShort instruction: Museum given. Carry PointBody + traversal + seven IDs. Add reciprocal4–5 explicitly. New predecessor at enqueue; BFS goal; reconstruct via sentinel; empty result valid. Hold→pause; trigger/1→block 0/block 0,4/restore; R→replay. Route≠visited. Test remove4–5. River AStar distance≠learner BFS hops. Next: network relationships.\n')
report=f"""# A route, a detour, and no route

Graph Theory hall 3 of 8 carries the same point and graph into Pathfinding. Layout changed coordinates while preserving connections. This hall changes availability and asks which journey remains possible.

| Part | Before | Now |
| --- | --- | --- |
| Tutorial | A* and maze fragments, with undeclared helpers | Complete runnable queue search, predecessor record and point traveller |
| Lineage | No explicit bridge from the previous graph | Same seven IDs and previous edges; one declared extra edge 4–5 permits a detour |
| Reflection | Implied that losing a stone always yields another crossing | A route may survive, or the traveller may stop; no route is a valid answer |
| Museum | Oversized maze; the river named by the text was absent | River restored, compact supporting maze, clear middle passage and learner bay |
| Independent task | Broad algorithm comparison | Remove the added edge; predict which journey survives |

The learner travels from 3 to 6. With everything available, the answer is 3→1→0→2→6. Blocking 0 yields 3→1→4→5→2→6. Blocking 0 and 4 leaves no route. The point remains available to pick up and restore the conditions. Holding it pauses the journey; its inherited trigger changes availability.

The code separates the vertices visited during search from those in the chosen route. It records predecessors at discovery, then reconstructs the answer. The point plays this answer afterwards. A smooth animation must not be mistaken for a view of every search decision.

The existing river uses AStar3D with distance costs. Our smaller queue example finds the fewest edges. The texts name that distinction rather than treating all meanings of shortest as interchangeable. In the captured river, the first sinking actually removes the crossing; the learner's controlled graph lets us test a detour as well.

**{count} code checks and {native} native museum checks pass.** The code suite compares all 128 blocked-vertex combinations against an independent exhaustive path oracle, runs the student's remove-an-edge variation and catches three faulty algorithms. The museum suite checks the real river button connection, restoration, no-route behavior, 69 aisle clearance samples, and synthetic XRTools pickup, trigger and release.

The exact tutorial scripts are included. The learner study is temporarily installed for these captures, with a declared placement for the student to use. The existing river and maze algorithms are unchanged. Images are native Godot views, including the hall from above.

These are author-operated reconstruction checks. An independent reader and a physical headset remain separate tests. Quest performance, comfort and continuous portal traversal are not verified.

**Next: Network Analysis.** We now know how to request one journey. The next hall asks what a vertex's connections permit across the network.
"""
write(O/'REPORT.md',report)
css='''*{box-sizing:border-box}body{margin:0;background:#eeeae1;color:#24232a;font:18px/1.6 Georgia,serif}header,main,footer{max-width:1400px;margin:auto;padding:28px 4vw}header,footer{border-bottom:1px solid #bdb8ad}nav{display:flex;gap:12px 24px;flex-wrap:wrap;font:15px system-ui}a{color:#345463}h1{font-size:clamp(36px,5vw,66px);line-height:1.08}h2{font-size:30px;line-height:1.2;margin-top:2em}article{max-width:850px;margin:auto}.spread{display:grid;grid-template-columns:1fr 1fr;gap:2px;max-width:1800px}.spread article{background:#fcfaf4;padding:30px;min-width:0;width:100%;align-self:start}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}.pair article{min-width:0;padding:20px;background:#fcfaf4}.eyebrow,figcaption,footer{font:14px/1.6 system-ui}.eyebrow{text-transform:uppercase;letter-spacing:.12em;color:#64616a}.note{padding:18px;border-left:4px solid #678591;background:#faf7f1;font-family:system-ui}figure{margin:24px 0}img{width:100%;height:auto;display:block}figcaption{padding:12px 0;color:#5b5860}pre{overflow:auto;background:#202931;color:#edf0e8;padding:18px;line-height:1.5;font-size:14px;tab-size:4}code{font-size:.85em}pre code{font-size:inherit}table{border-collapse:collapse;width:100%;font:15px/1.5 system-ui}td,th{padding:12px;border-bottom:1px solid #c9c3b7;text-align:left;vertical-align:top}@media(max-width:900px){.spread,.pair{grid-template-columns:1fr}.spread article{padding:20px}}@media print{nav{display:none}pre{white-space:pre-wrap}body{background:white}}'''
def md(s):
 result=markdown.markdown(s,extensions=['fenced_code','tables']);source=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
 return re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(source)+'\n')+m[2],result,flags=re.S)
def page(title,body):
 return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p class="eyebrow">Endless Museum · Graph Theory 03 / 08 · 10 October 2026</p><nav><a href="index.html">Room and report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="graph-pathfinding-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Native museum images. Tested author-operated reconstruction. Physical headset and independent reader review remain open.</footer></body></html>'
def fig(src,caption):return '<figure><img loading="lazy" src="'+src+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
for key in ['tutorial','final']:write(O/(key+'.html'),page(key,'<main><article>'+md(text(M/(key+'.md')))+'</article></main>'))
write(O/'parallel.html',page('Pathfinding — facing texts','<main class="spread"><article><p class="eyebrow">Left · tutorial.md</p>'+md(text(M/'tutorial.md'))+'</article><article><p class="eyebrow">Right · final.md</p>'+md(text(M/'final.md'))+'</article></main>'))
changes='<main><h1>Before and after</h1>'
for key in ['tutorial','final']:changes+='<h2>'+key+'.md</h2><div class="pair"><article><p class="eyebrow">Previous draft</p>'+md(text(O/'before/commons/maps'/ID/(key+'.md')))+'</article><article><p class="eyebrow">Now</p>'+md(text(M/(key+'.md')))+'</article></div>'
write(O/'changes.html',page('Pathfinding changes',changes+'</main>'))
body='<main><p class="eyebrow">The same point becomes a traveller</p><h1>A route, a detour,<br>and no route.</h1><p class="note">'+str(count)+' code checks + '+str(native)+' native museum checks passed. Hall 3 of 8.</p>'
body+=fig('assets/student-route.png','The carried point follows the first route inside GT_Pathfinding. Gold rods mark the answer; the readout separately lists the search visits.')
body+='<div class="pair">'+fig('assets/student-detour.png','Block vertex 0: the point can take the explicit4–5 detour.')+fig('assets/student-no-route.png','Block 0 and 4: no route remains. The same point waits where it can be picked up again.')+'</div>'
body+='<h2>The existing river</h2><div class="pair">'+fig('assets/river-before.png','A crossing exists through the seeded stepping stones.')+fig('assets/river-after.png','After pressing the real button, this crossing has no surviving route. Replanning does not promise success.')+'</div>'
body+='<h2>Room arrangement</h2><div class="pair">'+fig('before-museum/above.png','Baseline: the maze dominates the room and the river is missing.')+fig('assets/study-above.png','Now: river on the right, compact maze at rear left, learner study at front left and a clear central passage.')+'</div>'
body+='<div class="pair">'+fig('before-museum/entry.png','Baseline arrival.')+fig('assets/entry.png','Revised arrival. The route through the hall stays open.')+'</div>'
body+='<article>'+md(report)+'<p><a href="SUMMARY.md">Paragraph and short instruction</a> · <a href="checks.json">Code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="technical.md">Implementation and limits</a></p></article></main>'
write(O/'index.html',page('Pathfinding — a route kept',body))
write(O/'README.txt','Graph Theory hall 3/8. Open index.html for native images/report, parallel.html for tutorial left and reflection right. printed/ has four exact scripts and the one-node study.tscn. Use inside AdaResearch Godot 4.6 with existing XRTools and museum; not a standalone export. PointBody and traversal are unchanged from Layout. variation/ removes the extra edge; fault-* folders deliberately contain wrong algorithms. Historical failed harness logs are retained; checks.json and museum/report.json are the current successful receipts. Physical headset and independent-reader review remain open.\n')
for name in ['graph_pathfinding_student.gd','graph_pathfinding_room.gd']:shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
for name in ['test_graph_pathfinding.py','place_graph_pathfinding.py','write_graph_pathfinding.py','publish_graph_pathfinding.py','start_graph_pathfinding.py']:shutil.copyfile(R/'tools'/name,O/'probes'/name)
dump(O/'manifest.json',{'canonical':{n:sha(M/n) for n in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':code['printed_hashes'],'protected':{rel:sha(R/rel) for rel in protected},'checks':[count,native],'hall':ID,'physical_headset':False,'independent_reader':False})
archive=O/'graph-pathfinding-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in O.rglob('*'):
  if not p.is_file() or p.suffix in ['.zip','.uid'] or p.name=='validation.json':continue
  if p.is_relative_to(O/'before') and p.name in ['em_plan.json','em_layout_walk.json','long_museum.json','plan.json','necklace_hand.json']:continue
  data=p.read_bytes()
  if p.suffix=='.html':data=data.replace(b'href="graph-pathfinding-review.zip"',b'href="README.txt"')
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
