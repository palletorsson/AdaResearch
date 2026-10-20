from pathlib import Path
from html.parser import HTMLParser
import copy,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1];ID='GT_Spanning_Trees'
O=R/'doc/book/iterations/2026-10-10-spanning-the-cost-of-a-spare';M=R/'commons/maps'/ID;S=R/'doc/book/studies/graphs-through-the-hands'/ID
RUN=R/'ada_run/encounter_pilot'/ID/'spanning-final';KEY='graphtheory|gt spanning trees'
def text(p):return p.read_text(encoding='utf8')
def read(p):return json.loads(text(p))
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
protected=['commons/maps/sequences/graphtheory.json','algorithms/graphtheory/minimumspanningtree/mst_visualization.gd','algorithms/graphtheory/minimumspanningtree/mst_visualization.tscn','commons/artifacts/registry/algorithms_misc.json','commons/artifacts/spine_films/more_structure/spanning_choice.gd','ada_run/necklace_hand.json']
for rel in protected:assert (R/rel).read_bytes()==(O/'before'/rel).read_bytes(),rel
for name in ['point_body.gd','traversal.gd']:assert (S/name).read_bytes()==(S.parent/'GT_Connectivity'/name).read_bytes()
for directory in ['assets','museum','before-museum','after','probes']:(O/directory).mkdir(exist_ok=True)
for p in RUN.glob('*.png'):shutil.copyfile(p,O/'assets'/p.name)
for name in ['report.json','engine.log','source_manifest.json']:shutil.copyfile(RUN/name,O/'museum'/name)
for name in ['above.png','entry.png','report.json','engine.log']:shutil.copyfile(RUN.parent/'spanning-before'/name,O/'before-museum'/name)
count=len(code['checks']);native=len(room['checks'])
summary='Carry PointBody, seven vertex identities and queue traversal from Connectivity. Explicitly introduce a new undirected list of links with assigned build costs; keep the earlier event ledger in its own lesson. Sort link indices, then reuse reachability to refuse any link whose endpoints are already joined. Predict and build the cost21 tree. Break0–1 and identify the three stranded vertices; add the cost7 spare4–5 to restore this route without pretending to protect every failure. Move the held point without changing costs. Independently reduce the spare’s cost to0.5, predict the new cost15.5 tree, and explain why that same spare no longer repairs the selected break. Compare the museum’s larger distance-weighted construction; carry the distinction between a route existing and its capacity into Flow.'
technical=f'''# Spanning Trees — implementation and verification

The learner carries point_body.gd and traversal.gd byte-identically from Connectivity, retaining the same seven IDs and initial positions. New tree_model.gd declares eight undirected links and assigned build costs. The earlier directed event ledger is preserved in its earlier lesson and is not silently reinterpreted. New study.gd supplies complete visible construction and input code. No scene-node dollar references, new player or undisclosed geometry dependencies.

The model sorts stable link indices by cost, using the index to break ties. For each candidate it builds undirected adjacency from the chosen links and reuses the queue search. Reachable endpoints would form a cycle, so the candidate is refused. This is Kruskal with repeated reachability rather than union-find, suitable for seven vertices. Disconnected input produces a minimum spanning forest. spans() checks coverage and edge count under the acyclic selection invariant; it does not independently prove minimum cost.

Cost order: [2,1,3,0,5,4,6,7]. Chosen: [2,1,3,0,5,4], cost21. Refused: [6,7]. Break0–1 leaves reachable membership{{0,2,5,6}}. Add4–5 at cost7 and all seven become reachable. Restoring0–1 while retaining the spare creates a cycle. The spare cannot protect leaf3 against losing1–3. Failure toggles operate on a derived active list; the original build-cost total and selected tree remain intact.

The transfer exercise changes4–5 from7 to0.5. The tree becomes [6,2,1,3,0,5], cost15.5;2–5 is refused. The existing spare switch neither duplicates a selected edge nor charges twice. Because4–5 is already selected, it cannot then reconnect the graph when0–1 breaks. This changed consequence is explained rather than hidden by a special case.

The same black PointBody moves vertex4 in the drawing’s local XY plane. Dragging does not change assigned costs or connectivity. The held trigger/1 and STEP consider one edge. BREAK/2 and SPARE/3 become meaningful after the scan. R/RESET requires release. On release the same point parks in the drawing plane. Nearby controls use the existing pointer event contract. Cylinder rods have no arrowheads. Costs and state labels accompany colours; bottom vertex labels are below the vertices to separate them from edge costs.

{count} fresh exact-source code checks pass. The four scripts printed in tutorial.md are extracted, hashed and run in Godot4.6. An independent exhaustive forest enumerator uses literal endpoints and a separate component-merging calculation:256 available-link subsets ×4 cost scenarios =1024 cases, including disconnected, equal and negative cost inputs. It compares maximum achievable forest rank and minimum cost. Other checks cover complete host construction, reset, unchanged records, duplicate/self-loop cases, actual keyboard/pointer, transformed-host XRTools pickup/trigger/release, retained object identity, the independently edited study and three deliberately wrong variants: expensive-first selection, accepting cycles and missing reverse adjacency.

{native} native museum checks pass, including captures and completion. Production MST code remains unchanged: ten vertices, Kruskal/union-find, Euclidean weights from generated source positions. It selects nine edges with cost42.5414566993713, agreeing with an independent Prim cut search. This run considered24 links, refused15 and finalized on call25. Considered underlying lines stay yellow; accepted edges receive green overlays; unconsidered lines can stay grey. The tutorial distinguishes that display from the learner’s full eight-edge scan. The existing wall film remains.

The first native run correctly broke the link but the checker compared queue visitation order instead of reachable membership. The assertion now sorts the reached set; the failed receipt/log remain as first-room-check.json/log. Native inspection also revealed crowded labels; label placement and line breaks were improved, followed by fresh code and native runs. No algorithm logic changed to satisfy that assertion. Current receipts require explicit completion, current hashes and no script/parse errors. Existing Jolt/UID warnings remain.

The15×17 hall retains its walls, floor, entry, exit and wall film. The existing MST is moved from cell(7,9), height3.6, scale0.4 to the right rear cell(11,11), height2.8, scale0.28, yaw180. This opens a left learner bay and keeps the central route clear.29 supported capsule samples plus both approaches pass. Temporary student installation: map-local(4,-0.25,6), yaw180, scale1; isolated hall-root(4,-0.25,10). The learner is not a permanently registered additional exhibit. Native eye-level and above images show the printed study inside the real museum.

This is author-operated ghost reconstruction, not a blind reader or physical headset test. Quest comfort/performance and continuous portal traversal remain unverified. Production artifact code, film, registry and sequence order are unchanged; only this hall’s placement and selected documentation/view rows change. Review decision and baseline are preserved.

Replay code: python tools/test_graph_spanning.py

Replay museum: python tools/run_encounter_probe.py GT_Spanning_Trees --sequence graphtheory --render --no-bridges --output-tag spanning-final --probe tools/probes/graph_spanning_room.gd
'''
write(M/'technical.md',technical)
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
 shutil.copyfile(M/name,O/'after'/name)
 if name.endswith('.md'):shutil.copyfile(M/name,O/name)
plan=next(x for x in read(R/'commons/data/museum/em_plan.json')['plans'] if x.get('map')==ID)
layout=read(RUN/'em_layout_walk.json')['halls'][KEY]
for rel in ['ada_run/em_layout_walk.json','commons/data/museum/em_layout_walk.json']:
 p=R/rel;preserve(p);stamp=p.stat().st_mtime_ns;d=read(p);old=copy.deepcopy(d);d['halls'][KEY]=layout
 assert {k:v for k,v in d['halls'].items() if k!=KEY}=={k:v for k,v in old['halls'].items() if k!=KEY}
 assert stamp==p.stat().st_mtime_ns;dump(p,d)
p=R/'commons/data/long_museum.json';preserve(p);stamp=p.stat().st_mtime_ns;d=read(p);old=copy.deepcopy(d)
row=next(x for x in d['segments'] if x['name']==ID);old_count=len(row['artifacts'])
row['artifacts']=[{'x':a['cell'][0],'z':a['cell'][1],'token':a['token'],'rot':a.get('rotation',0),'scale':a.get('scale',1)} for a in plan['artifacts']]
row.update(structure=read(M/'map_data.json')['layers']['structure'],tile=plan['tile'],tile_w=15,tile_h=17,tile_source='map',built=True)
delta=len(row['artifacts'])-old_count;d['totals']['artifacts']+=delta;next(c for c in d['chapters'] if c['sequence']=='graphtheory')['artifacts']+=delta
assert [x for x in d['segments'] if x['name']!=ID]==[x for x in old['segments'] if x['name']!=ID]
assert stamp==p.stat().st_mtime_ns;write(p,json.dumps(d,ensure_ascii=False,separators=(',',':')))
p=R/'doc/book/course/execution-plan/plan.json';preserve(p);stamp=p.stat().st_mtime_ns;d=read(p);old=copy.deepcopy(d)
row=next(x for x in d['lessons'] if x['id']==ID)
row.update(object='The same PointBody and seven vertex identities in a new undirected build-cost model.',change='Sort weighted link indices; reuse reachability to reject cycles; compare a minimum tree with a spare route after failure.',dependsOn=['GT_Foundations','GT_Connectivity'],reuses='PointBody and queue traversal unchanged; seven IDs and initial drawing positions.',given='Existing Endless Museum, XRTools and larger distance-weighted MST comparison. Complete display/input host is printed.',later='Union-find and other MST algorithms remain deeper studies. Flow introduces capacity as another explicit edge quantity.',checks=[f'{count} exact-source Godot checks;1024 cases against independent exhaustive minimum-forest oracle; transfer and three rejected faults.',f'{native} native museum checks; independent production-cost oracle, route clearance, actual pointer and synthetic XRTools.'],transfer='Make4–5 cost0.5. Predict cost15.5,2–5 refused. Explain why adding4–5 again cannot repair broken0–1.',carry='A minimum-cost connection has no spare routes. Redundancy depends on the objective; one spare does not protect every edge.',next='GT_Flow: a route can exist yet have limited capacity.',notes='10 October: hall6 only. New explicit undirected model, two unchanged carried files. Production MST and film unchanged. Review decision and baseline retained.',summary=summary)
previous=next(x for x in old['lessons'] if x['id']==ID)
assert row['decision']==previous['decision'] and row['baseline']==previous['baseline']
assert [x for x in d['lessons'] if x['id']!=ID]==[x for x in old['lessons'] if x['id']!=ID]
assert stamp==p.stat().st_mtime_ns;dump(p,d);dump(O/'lesson-plan.json',row)
write(O/'SUMMARY.md','# Spanning Trees — lesson paragraph\n\n'+summary+'\n\nShort instruction: Museum given. Carry point+IDs+queue. Declare new two-way weighted links; preserve old ledger. Sort indices; reachable endpoints→refuse cycle, else join. Tree cost21. Break0–1→3 stranded; spare4–5 cost7→return. Spare≠universal protection. Drag changes drawing only. Transfer4–5 cost0.5→tree15.5; same spare now no repair. Next: capacity.\n')
report=f'''# The cost of a spare

Graph Theory hall6/8. The point and vertex identities continue; the question changes from a directed return to an undirected connection at minimum build cost.

| Part | Before | Now |
|---|---|---|
| Tutorial | Generic MST chapter introduces Kruskal, union-find and Prim | One reconstructable operation: sort, reuse reachability, refuse a cycle |
| Data | No precise handoff from the directed ledger | Explicit new undirected links and assigned costs; previous ledger preserved |
| Consequence | A completed tree ends the construction | Break a selected link; compare the cost and limits of a spare |
| Reflection | Broad economy of connections | Stay with the price of a route, failure, and what redundancy means under an objective |
| Space | Large comparison centred in the hall | Existing comparison at right rear; left learner bay and open central passage |
| Transfer | No tested independent edit of the carried object | Lower4–5 cost; predict a different tree and different failure consequence |

The small tree costs21. Break0–1 and vertices1,3,4 cannot be reached from0. Add the previously refused4–5 link at cost7 and that route returns. A different failure can still isolate a leaf. The tutorial keeps the original chosen tree separate from this changed active network.

The larger existing museum graph uses distances from its own generated positions. Our small graph uses deliberately assigned build costs. Moving the point changes its drawing without changing those costs. Both constructions use Kruskal’s selection principle; their datasets and visual traces differ explicitly.

**{count} code checks and {native} native museum checks pass.** Exact printed scripts run in Godot. An independent exhaustive oracle checks1024 input/cost cases; a separate Prim oracle confirms the real museum exhibit’s total. Tests include the independent cost edit, three intentionally faulty variants, pointer controls and synthetic XRTools pickup/trigger/release.

Native inspection led to clearer label positions. The first room assertion was corrected to compare reachable membership rather than queue order; its rejected receipt is retained. Every image here is a native Godot capture. The learner installation is temporary and explicitly described in the tutorial. Physical headset and independent-reader review remain open.

**Next: Flow.** A route may exist while allowing only a limited amount through.
'''
write(O/'REPORT.md',report)
css=text(R/'tools/publish_graph_network.py').split("css='''",1)[1].split("'''",1)[0]
def md(s):
 result=markdown.markdown(s,extensions=['fenced_code','tables']);source=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
 return re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(source)+'\n')+m[2],result,flags=re.S)
def page(title,body):
 return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p class="eyebrow">Endless Museum · Graph Theory06 /08 ·10 October2026</p><nav><a href="index.html">Room and report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="graph-spanning-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Native museum captures. Author-operated reconstruction. Headset and independent reader review remain open.</footer></body></html>'
def fig(src,caption):return '<figure><img loading="lazy" src="'+src+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
for key in ['tutorial','final']:write(O/(key+'.html'),page(key,'<main><article>'+md(text(M/(key+'.md')))+'</article></main>'))
write(O/'parallel.html',page('Spanning Trees — facing texts','<main class="spread"><article><p class="eyebrow">Left · tutorial.md</p>'+md(text(M/'tutorial.md'))+'</article><article><p class="eyebrow">Right · final.md</p>'+md(text(M/'final.md'))+'</article></main>'))
changes='<main><h1>Before and after</h1>'
for key in ['tutorial','final']:changes+='<h2>'+key+'.md</h2><div class="pair"><article><p class="eyebrow">Previous draft</p>'+md(text(O/'before/commons/maps'/ID/(key+'.md')))+'</article><article><p class="eyebrow">Now</p>'+md(text(M/(key+'.md')))+'</article></div>'
write(O/'changes.html',page('Spanning Trees changes',changes+'</main>'))
body=f'<main><p class="eyebrow">The same point, a different objective</p><h1>The cost of a spare</h1><p class="note">{count} code checks + {native} native museum checks passed. Hall6 of8.</p>'
body+='<div class="pair">'+fig('assets/student-before.png','Eight undirected links. Costs are assigned, and the selection is still open.')+fig('assets/student-tree.png','Six chosen links, cost21. Both remaining links would form cycles.')+'</div>'
body+='<div class="pair">'+fig('assets/student-break.png','Break0–1: three vertices lose their route from0.')+fig('assets/student-spare.png','Keep the break; add4–5. The spare restores this route at an extra cost7.')+'</div>'
body+=fig('assets/student-moved.png','The same held point moves the drawing; weights and selected tree remain unchanged.')
body+='<h2>The existing comparison</h2>'+fig('assets/museum-tree.png','Ten vertices and Euclidean source weights. The production Kruskal result agrees with an independent minimum-cost calculation.')
body+='<h2>Room arrangement</h2><div class="pair">'+fig('before-museum/above.png','Before: the large comparison occupies the middle of the hall.')+fig('assets/study-above.png','After: learner study on the left, large comparison on the right; the floor and doorway positions are retained.')+'</div>'
body+='<div class="pair">'+fig('before-museum/entry.png','Previous arrival.')+fig('assets/study-entry.png','Revised arrival with the temporary learner installation.')+'</div>'
body+='<article>'+md(report)+'<p><a href="SUMMARY.md">Paragraph and short instruction</a> · <a href="checks.json">Code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="technical.md">Implementation and limits</a></p></article></main>'
write(O/'index.html',page('Spanning Trees — the cost of a spare',body))
write(O/'README.txt','Graph Theory hall6/8. index.html: native images/report. parallel.html: tutorial left/reflection right. printed/: four complete scripts and one-node scene, extracted from tutorial.md. Run inside AdaResearch Godot4.6 with existing museum/XRTools. PointBody and Traversal carried unchanged. variation/: cost4–5 lowered to0.5. fault-* are deliberately incorrect. First-room-check files retain a rejected visitation-order assertion. Current receipts are fresh/completed. Headset and independent reader remain open.\n')
for name in ['graph_spanning_student.gd','graph_spanning_room.gd']:shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
for name in ['test_graph_spanning.py','place_graph_spanning.py','write_graph_spanning.py','publish_graph_spanning.py','start_graph_spanning.py']:shutil.copyfile(R/'tools'/name,O/'probes'/name)
dump(O/'manifest.json',{'canonical':{n:sha(M/n) for n in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':code['printed_hashes'],'protected':{rel:sha(R/rel) for rel in protected},'checks':[count,native],'hall':ID,'physical_headset':False,'independent_reader':False})
archive=O/'graph-spanning-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in O.rglob('*'):
  if not p.is_file() or p.suffix in ['.zip','.uid'] or p.name=='validation.json':continue
  if p.is_relative_to(O/'before') and p.name in ['em_plan.json','em_layout_walk.json','long_museum.json','plan.json','necklace_hand.json']:continue
  data=p.read_bytes()
  if p.suffix=='.html':data=data.replace(b'href="graph-spanning-review.zip"',b'href="README.txt"')
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
