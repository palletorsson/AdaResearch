from pathlib import Path
from html.parser import HTMLParser
import copy,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1];ID='GT_Connectivity'
O=R/'doc/book/iterations/2026-10-10-connectivity-a-way-back';M=R/'commons/maps'/ID;S=R/'doc/book/studies/graphs-through-the-hands'/ID
RUN=R/'ada_run/encounter_pilot'/ID/'connectivity-final';KEY='graphtheory|gt connectivity'
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
assert len(blocks)==7 and hashlib.sha256(text(M/'tutorial.md').encode()).hexdigest()==code['tutorial_sha256']
for name,source in blocks:
 assert source+'\n'==text(S/name)==text(O/'printed'/name)
 assert hashlib.sha256((source+'\n').encode()).hexdigest()==code['printed_hashes'][name]
protected=['commons/maps/sequences/graphtheory.json','algorithms/graphtheory/tarjan_algorithm/tarjan_algorithm.gd','algorithms/graphtheory/tarjan_algorithm/tarjan_algorithm.tscn','commons/artifacts/registry/algorithms_misc.json','ada_run/necklace_hand.json']
for rel in protected:assert (R/rel).read_bytes()==(O/'before'/rel).read_bytes(),rel
for name in ['point_body.gd','traversal.gd','route.gd','ledger.gd']:assert (S/name).read_bytes()==(S.parent/'GT_Network_Analysis'/name).read_bytes()
assert (S/'network_study.gd').read_bytes()==(S.parent/'GT_Network_Analysis'/'study.gd').read_bytes()
for directory in ['assets','museum','before-museum','after','probes']:(O/directory).mkdir(exist_ok=True)
for p in RUN.glob('*.png'):shutil.copyfile(p,O/'assets'/p.name)
for name in ['report.json','engine.log','source_manifest.json']:shutil.copyfile(RUN/name,O/'museum'/name)
for name in ['above.png','entry.png','report.json','engine.log']:shutil.copyfile(RUN.parent/'connectivity-before'/name,O/'before-museum'/name)
count=len(code['checks']);native=len(room['checks'])
technical=f'''# Connectivity — implementation and verification

The learner carries five files unchanged from Network Analysis, renaming its study.gd to network_study.gd. The new reachability.gd extends the ledger; a new study.gd extends the existing host. The seven IDs and earlier seven records remain. One explicitly authored fictional report, R04: 5 reports to 1, is added but starts omitted. No reverse events are inferred from the drawing. The old undirected scaffold remains available but is not used for directed queries.

directed() builds fresh adjacency arrays from active records. Reversal swaps endpoints only in this derived structure. reachable() reuses the first hall's Traversal queue, assigns directed neighbours and the chosen start, and runs to exhaustion. component() intersects forward and backward reachability, returning the maximal strongly connected group containing the start. Self-reachability includes zero edges; isolated vertices are singleton components. Duplicate events are deduplicated only in adjacency; record counts remain event counts. This is not Tarjan or full Kosaraju and does not partition all components in one pass.

The host inherits the full point/mesh/controls construction. Start is initially 4. RETURN or the held point trigger toggles R04; START/1 cycles IDs after release; LAYOUT/3 changes the drawing; RESET/R restores original drawing, start 4 and omitted return. Movement updates local XY only. Colours have matching OUT/BACK/BOTH/neither text. The previous filter method name is overridden by START; this host has no kind-filter control, while the model still respects filters. Trigger is explicitly reconnected. No new player, camera, lights or hidden scene-node references are required.

Without R04, outward membership from 4 is [4,5], backward [0,1,4], component [4]. With R04 included: outward [1,3,4,5], backward [0,1,2,4,5], component [1,4,5]. The independent exercise changes R04 to 5→2 and its source sentence: component(4) stays [4], while component(2) and component(5) become [2,5]. This illustrates a cycle that cannot return to the original start.

{count} fresh code checks pass. Seven exact printed scripts are extracted and run. An independent Floyd-Warshall closure oracle checks all 256 omission subsets × 3 filters × 7 starting vertices. It uses literal endpoints rather than the implementation's adjacency builder. Checks also cover direction, immutable sources, invalid starts, singleton/parallel/self-loop cases, arrow geometry, actual keyboard and pointer input, transformed-host XRTools pickup/trigger/release, retained point identity, the independently edited study and three deliberately faulty variants (outward search twice, union instead of intersection, ignoring omissions).

The first run checked the selected point before the frame/physics synchronization had settled after a START press. The checker now awaits five frame/physics pairs, as the held/drop checks already did; no learner logic was changed. The initial failed log is retained as first-start-check.log. The native room independently checks the same START behaviour after release. Current receipts require an explicit completed marker and matching tutorial/source hashes; no final script/parse errors. Existing UID/Jolt warnings remain.

The museum's existing Tarjan implementation and registry are unchanged. The map selects its existing mutuality=split preset: 12 vertices in two internally strongly connected rings, one crossing v0→v6. The actual traversal completes with components v0–v5 and v6–v11 and an empty unresolved stack. Its graph differs from the seven-vertex learner dataset. The reflection describes this comparison, not a room architecture that literally enforces one-way travel. Other visible algorithm procedures are not silently made tutorial prerequisites. Source comments describing a DAG as having no SCCs are imprecise: every vertex is its own SCC; the tutorial states the correct distinction.

The previous 14x10 hall had internal walls, a raised middle room, overlapping diagrams and a blocked t-exit fallback. The revised hall retains the footprint and doorway positions, has a continuous floor and clear central passage, and places Tarjan in the right bay at cell(10,6), yaw180, elevation1.15m, scale0.5. Kosaraju and topological-sort scenes remain in the catalogue but are removed from this hall placement. The temporary learner is in the left bay at map-local(3.5,-0.25,5.5), yaw180, scale1; isolated hall-root(3.5,-0.25,9.5). The tutorial explicitly instructs this student installation; it is not a permanent extra exhibit.

{native} native checks pass, including completion/capture assertions: installed Tarjan preset and result, directed crossing, supported central aisle and approaches, exact printed learner, actual pointer selection, synthetic XRTools hold/trigger/release and unchanged reachability under drawing movement. Eye-level and above captures accompany the before/after report. This is author-operated reconstruction, not a blind student or physical headset test. Quest comfort/performance and continuous portal traversal remain unverified.

Replay code: python tools/test_graph_connectivity.py

Replay museum: python tools/run_encounter_probe.py GT_Connectivity --sequence graphtheory --render --no-bridges --output-tag connectivity-final --probe tools/probes/graph_connectivity_room.gd
'''
write(M/'technical.md',technical)
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
 shutil.copyfile(M/name,O/'after'/name)
 if name.endswith('.md'):shutil.copyfile(M/name,O/name)
# Change only this hall in shared views. Preserve review decisions and all other work.
plan=next(x for x in read(R/'commons/data/museum/em_plan.json')['plans'] if x.get('map')==ID)
layout=read(RUN/'em_layout_walk.json')['halls'][KEY]
for rel in ['ada_run/em_layout_walk.json','commons/data/museum/em_layout_walk.json']:
 p=R/rel;preserve(p);stamp=p.stat().st_mtime_ns;d=read(p);old=copy.deepcopy(d);d['halls'][KEY]=layout
 assert {k:v for k,v in d['halls'].items() if k!=KEY}=={k:v for k,v in old['halls'].items() if k!=KEY}
 assert stamp==p.stat().st_mtime_ns;dump(p,d)
p=R/'commons/data/long_museum.json';preserve(p);stamp=p.stat().st_mtime_ns;d=read(p);old=copy.deepcopy(d)
row=next(x for x in d['segments'] if x['name']==ID);old_count=len(row['artifacts'])
row['artifacts']=[{'x':a['cell'][0],'z':a['cell'][1],'token':a['token'],'rot':a['rotation'],'scale':a['scale']} for a in plan['artifacts']]
row.update(structure=read(M/'map_data.json')['layers']['structure'],tile=plan['tile'],tile_w=14,tile_h=10,tile_source='map',built=True)
delta=len(row['artifacts'])-old_count;d['totals']['artifacts']+=delta;next(c for c in d['chapters'] if c['sequence']=='graphtheory')['artifacts']+=delta
assert [x for x in d['segments'] if x['name']!=ID]==[x for x in old['segments'] if x['name']!=ID]
assert stamp==p.stat().st_mtime_ns;write(p,json.dumps(d,ensure_ascii=False,separators=(',',':')))
p=R/'doc/book/course/execution-plan/plan.json';preserve(p);stamp=p.stat().st_mtime_ns;d=read(p);old=copy.deepcopy(d)
row=next(x for x in d['lessons'] if x['id']==ID)
summary='Carry the point and seven directed records from Network Analysis. Derive adjacency from active records, follow the arrows from a selected start, then search their reversal. Intersect the visited sets to find its strongly connected component. Predict how adding the explicit return 5→1 joins 1,4,5; move the held point without changing that result. Independently redirect the return to 5→2, update its source, and explain why 4 stays alone while 2 and 5 join. Compare the existing Tarjan rings, then carry the distinction between directed mutual reachability and the next hall’s undirected connection objective.'
row.update(object='The same PointBody marks a selected vertex in the carried directed ledger.',change='Build directed adjacency; reuse queue traversal outward and on reversed arrows; intersect sets to find the selected strongly connected component.',dependsOn=['GT_Foundations','GT_Network_Analysis'],reuses='Five unchanged files: PointBody, traversal, route, ledger and renamed network host; same IDs and prior records.',given='Existing Endless Museum and XRTools, inherited display/input host, larger Tarjan split-ring comparison. One new fictional return record is explicitly authored.',later='Tarjan low-link invariants and full Kosaraju partitioning remain deeper studies. Spanning Trees must explicitly introduce an undirected connection model.',checks=[f'{count} fresh exact-source code checks; 768 subset/filter combinations, all seven starts, independent closure oracle; edited return and three faulty variants.',f'{native} native museum checks; real Tarjan result, route clearance, pointer controls and synthetic XRTools; no physical-headset or blind-reader claim.'],transfer='Change R04 from5→1 to5→2 and update its source. With it active, predict component(4)=[4] and component(2)=component(5)=[2,5]; verify the new arrow.',carry='Mutual reachability is a path in both directions; counts and proximity alone do not establish it. Isolated vertices still form singleton components.',next='GT_Spanning_Trees: declare undirected links before selecting a tree; remember what a cycle made possible under the previous objective.',notes='10 October: hall5 only. Two new scripts, five carried unchanged. Reflection stays with return and the limits of connectedness; production Tarjan logic unchanged. Review decision and baseline retained.',summary=summary)
previous=next(x for x in old['lessons'] if x['id']==ID)
assert row['decision']==previous['decision'] and row['baseline']==previous['baseline']
assert [x for x in d['lessons'] if x['id']!=ID]==[x for x in old['lessons'] if x['id']!=ID]
assert stamp==p.stat().st_mtime_ns;dump(p,d);dump(O/'lesson-plan.json',row)
write(O/'SUMMARY.md','# Connectivity — lesson paragraph\n\n'+summary+'\n\nShort instruction: Museum given. Carry PointBody + seven records + queue + host. Derive active directed adjacency and transpose. Out ∩ back = SCC(start), including zero-edge self. Add explicit5→1 return; start4 joins1,4,5. Move drawing≠change relation. Transfer5→2: SCC4=[4], SCC2=[2,5]. Tarjan supplied comparison; next declare undirected model.\n')
report=f'''# A way back

Graph Theory hall 5 of 8 keeps the point, seven IDs and directed ledger. Counting connections becomes following them. Two familiar traversals answer one new question: which vertices can the start reach, and which can reach it?

| Part | Before | Now |
| --- | --- | --- |
| Tutorial | Tarjan recursion, condensation, topological sort and undeclared room helpers | Directed adjacency, reversed search and intersection for one chosen start |
| Lineage | A new DirectedGraph with no complete host | Five unchanged carried files; two small new files |
| Interaction | Watch the larger algorithm | Hold the same point; trigger includes/omits a return; nearby START selects another ID |
| Reflection | Mostly explains traversal machinery | Stay with a way back, the reach of an opening, and the limited promise of being connected |
| Space | Interior walls obscure diagrams; exit falls back from a blocked position | Open middle passage, Tarjan comparison on the right, learner bay on the left |
| Independent exercise | No exact runnable transfer | Redirect the return to 5→2; predict which group changes and which does not |

Start 4 reaches 5 but cannot return. Including the new report 5→1 makes 1,4,5 mutually reachable. Vertex 3 remains reachable only outward. Vertices 0 and 2 can enter the group but cannot be reached from it. Moving the drawing changes none of these relations.

The larger existing Tarjan display is configured as two rings with a one-way crossing. Its unchanged algorithm finds two components. The student does not need its low-link machinery to understand or reconstruct the smaller operation. A directed path is also not a guarantee that a body, payment or message can travel it in practice.

**{count} code checks and {native} native museum checks pass.** The independent oracle covers 768 omission/filter states and all seven starting vertices. The separate transfer exercise and three intentionally faulty variants run in Godot. Native checks cover real Tarjan output, clear approaches, actual pointer events and synthetic XRTools pickup/trigger/release.

The first test sampled the point before its frame/physics position settled after START. The checker now waits for synchronization; learner logic did not change to satisfy the assertion. The rejected log remains in the review package.

The learner shown here is an explicit temporary student installation inside the real museum. Production artifact code, registry and sequence order remain unchanged. All images are native Godot captures. Physical headset, Quest performance and independent-reader review remain open.

**Next: Spanning Trees.** An undirected tree keeps vertices connected while omitting cycles. That changes both the model and the objective; the next tutorial must say so.
'''
write(O/'REPORT.md',report)
# Reuse the established presentation only, without executing another hall's publisher.
template=text(R/'tools/publish_graph_network.py')
css=template.split("css='''",1)[1].split("'''",1)[0]
def md(s):
 result=markdown.markdown(s,extensions=['fenced_code','tables']);source=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
 return re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(source)+'\n')+m[2],result,flags=re.S)
def page(title,body):
 return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p class="eyebrow">Endless Museum · Graph Theory 05 / 08 · 10 October 2026</p><nav><a href="index.html">Room and report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="graph-connectivity-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Native museum images. Tested author-operated reconstruction. Physical headset and independent reader review remain open.</footer></body></html>'
def fig(src,caption):return '<figure><img loading="lazy" src="'+src+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
for key in ['tutorial','final']:write(O/(key+'.html'),page(key,'<main><article>'+md(text(M/(key+'.md')))+'</article></main>'))
write(O/'parallel.html',page('Connectivity — facing texts','<main class="spread"><article><p class="eyebrow">Left · tutorial.md</p>'+md(text(M/'tutorial.md'))+'</article><article><p class="eyebrow">Right · final.md</p>'+md(text(M/'final.md'))+'</article></main>'))
changes='<main><h1>Before and after</h1>'
for key in ['tutorial','final']:changes+='<h2>'+key+'.md</h2><div class="pair"><article><p class="eyebrow">Previous draft</p>'+md(text(O/'before/commons/maps'/ID/(key+'.md')))+'</article><article><p class="eyebrow">Now</p>'+md(text(M/(key+'.md')))+'</article></div>'
write(O/'changes.html',page('Connectivity changes',changes+'</main>'))
body='<main><p class="eyebrow">The same point, a return</p><h1>A way back</h1><p class="note">'+str(count)+' code checks + '+str(native)+' native museum checks passed. Hall 5 of 8.</p>'
body+='<div class="pair">'+fig('assets/student-before.png','Start 4 can reach 5, but only 4 belongs to its strongly connected component.')+fig('assets/student-return.png','Include the authored return 5→1: 1,4,5 can now reach one another.')+'</div>'
body+=fig('assets/student-moved.png','Move the held point: the drawing changes, the mutual group remains. Its trigger toggles the return.')
body+='<h2>The existing comparison</h2>'+fig('assets/tarjan-rings.png','The existing Tarjan display: two strongly connected rings and one one-way crossing. A different algorithm and dataset, the same question about return.')
body+='<h2>Room arrangement</h2><div class="pair">'+fig('before-museum/above.png','Before: walls and overlapping diagrams obscure the relations.')+fig('assets/study-above.png','After: clear central route, learner study on the left, larger comparison on the right.')+'</div>'
body+='<div class="pair">'+fig('before-museum/entry.png','Previous arrival.')+fig('assets/entry.png','Revised arrival with open sightlines.')+'</div>'
body+='<article>'+md(report)+'<p><a href="SUMMARY.md">Paragraph and short instruction</a> · <a href="checks.json">Code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="technical.md">Implementation and limits</a></p></article></main>'
write(O/'index.html',page('Connectivity — a way back',body))
write(O/'README.txt','Graph Theory hall5/8. index.html: native images/report. parallel.html: tutorial left/reflection right. printed/: seven complete scripts and one-node scene, extracted from canonical tutorial.md. Run inside AdaResearch Godot4.6 with existing museum/XRTools, not a standalone export. Five files carried unchanged, previous host renamed. variation/ redirects R04 to5→2; fault-* deliberately incorrect. Current receipts are fresh and completed. first-start-check.log preserves a rejected timing assertion. Physical headset and independent reader remain open.\n')
for name in ['graph_connectivity_student.gd','graph_connectivity_room.gd']:shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
for name in ['test_graph_connectivity.py','place_graph_connectivity.py','write_graph_connectivity.py','publish_graph_connectivity.py','start_graph_connectivity.py']:shutil.copyfile(R/'tools'/name,O/'probes'/name)
dump(O/'manifest.json',{'canonical':{n:sha(M/n) for n in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':code['printed_hashes'],'protected':{rel:sha(R/rel) for rel in protected},'checks':[count,native],'hall':ID,'physical_headset':False,'independent_reader':False})
archive=O/'graph-connectivity-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in O.rglob('*'):
  if not p.is_file() or p.suffix in ['.zip','.uid'] or p.name=='validation.json':continue
  if p.is_relative_to(O/'before') and p.name in ['em_plan.json','em_layout_walk.json','long_museum.json','plan.json','necklace_hand.json']:continue
  data=p.read_bytes()
  if p.suffix=='.html':data=data.replace(b'href="graph-connectivity-review.zip"',b'href="README.txt"')
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
for name in ['tutorial.html','parallel.html']:
 found=re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',text(O/name),re.S)
 assert [html.unescape(v) for v in found]==[source+'\n' for _,source in blocks]
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None
 for name in [n for n in z.namelist() if n.endswith('.html')]:
  parser=Links();parser.feed(z.read(name).decode())
  for ref in parser.refs:assert (Path(name).parent/ref).as_posix() in z.namelist(),(name,ref)
dump(O/'validation.json',{'passed':True,'local_links':links,'printed_files':len(blocks),'rendered_code_matches':True,'zip_crc':True,'zip_links':True,'size_mb':round(archive.stat().st_size/1e6,2),'checks':[count,native]})
print(json.dumps(read(O/'validation.json')))
