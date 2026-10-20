from pathlib import Path
from html.parser import HTMLParser
import copy,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1];ID='GT_Network_Analysis'
O=R/'doc/book/iterations/2026-10-10-network-a-record-counted';M=R/'commons/maps'/ID;S=R/'doc/book/studies/graphs-through-the-hands'/ID
RUN=R/'ada_run/encounter_pilot'/ID/'network-final';KEY='graphtheory|gt network analysis'
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
assert len(blocks)==5 and hashlib.sha256(text(M/'tutorial.md').encode()).hexdigest()==code['tutorial_sha256']
for name,source in blocks:
 assert source+'\n'==text(S/name)==text(O/'printed'/name)
 assert hashlib.sha256((source+'\n').encode()).hexdigest()==code['printed_hashes'][name]
protected=['commons/maps/sequences/graphtheory.json','commons/artifacts/spine_studies/evidence_network.gd','commons/artifacts/spine_studies/network.tscn','commons/artifacts/spine_studies/station.gd','algorithms/graphtheory/network_analysis/NetworkAnalysis.gd','ada_run/necklace_hand.json']
for rel in protected:assert (R/rel).read_bytes()==(O/'before'/rel).read_bytes(),rel
for name in ['point_body.gd','traversal.gd','route.gd']:assert (S/name).read_bytes()==(S.parent/'GT_Pathfinding'/name).read_bytes()
plans=read(R/'commons/data/museum/em_plan.json')['plans'];oldplans=read(O/'before/commons/data/museum/em_plan.json')['plans']
# em_plan is read-only here; other halls may have concurrent edits.
old_by_map={x.get('map'):x for x in oldplans}
unrelated_changes=[x.get('map') for x in plans if x.get('map')!=ID and x!=old_by_map.get(x.get('map'))]
print('Other plan rows retained:', unrelated_changes)
plan=next(x for x in plans if x.get('map')==ID)
for directory in ['assets','museum','before-museum','after','probes']:(O/directory).mkdir(exist_ok=True)
for p in RUN.glob('*.png'):shutil.copyfile(p,O/'assets'/p.name)
for name in ['report.json','engine.log','source_manifest.json']:shutil.copyfile(RUN/name,O/'museum'/name)
for name in ['above.png','entry.png','report.json','engine.log']:shutil.copyfile(RUN.parent/'network-before'/name,O/'before-museum'/name)
count=len(code['checks']);native=len(room['checks'])
technical=f"""# Network Analysis — implementation and verification

The installed evidence_network.gd contains eight named institutions and twelve fictional source records. The existing station.gd exposes LAYOUT, FILTER, RECORD, NODE and RESET through museum pointer buttons. Incoming and outgoing counts read the currently filtered records. Layout changes positions only. These are event counts; amounts occur in prose, not an amount-summing algorithm. The full ledger has four payment records, three grants and five reports. Builder has two incoming payments and one outgoing report. All production source files and the graph sequence remain unchanged.

The earlier front room was a narrow platform network over void with three overlapping exhibits: rhizomatic_structure, network_analysis and networkflow3d. These have been removed from this hall's placement, not deleted from the catalogue. NetworkAnalysis.gd assigns its centrality values from tiers and its summary values from a clock; it is not an implementation of the metrics the previous tutorial claimed to teach. The revised lesson concentrates on the existing inspectable record wall. It does not claim to implement Brandes, eigenvector centrality or A*.

The learner carries point_body.gd, traversal.gd and route.gd byte-for-byte from Pathfinding. Same seven IDs, initial positions and seven undirected endpoint pairs. New ledger.gd adds one explicitly fictional directed event for each pair; source, destination and kind are authored choices, not inferred from the undirected graph. The inherited adjacency remains an undirected scaffold; the inherited route search is not used as a directed record search. counts reads only active record indices, returns incoming/outgoing in Vector2i, treats parallel events separately, and counts a self-addressed record once each way. No normalisation by vertex count is appropriate for these event counts. The next hall must explicitly build directed adjacency from this ledger.

The complete host draws seven marker spheres with count labels, cylinders and arrowheads. The carried pickable point now marks vertex 4, the source of P04. While held, its world position is converted into local XY and the projection updates the drawing, without changing records. Release returns it to the plane. Inherited trigger or1 cycles filters;2 omits/restores P04;3 changes layout;R resets. Four nearby pointer controls provide the same actions. Layout/reset wait during holding. P04's source and counted/omitted status remain visible. Coincident endpoints hide a zero-length arrow while retaining the event and counts. The tests cover this distinction.

Five exact printed scripts are extracted fresh and executed in Godot 4.6. {count} code checks pass: independent endpoint tables; all 384 combinations of 128 omitted-record masks and three filters; total incoming and outgoing each equal active event count; source/scaffold immutability; empty filter, self-addressed and parallel-event cases; cylinder and arrow direction; keyboard echo and actual pointer-event dispatch; transformed-host synthetic XRTools hold/trigger/release. The independent P04 reversal runs as a separate edited study, producing changed counts and a reversed arrow with matching source. Three deliberately faulty models are caught: direction confusion, ignoring the filter and ignoring omission.

The first reconstruction failed because its nested Button class name shadowed Godot's native Button. It was renamed RecordButton, the tutorial regenerated, and the exact code rerun. The failed log is retained. The first native image also exposed the source sentence behind the controls; it now sits in front of them. Both code and museum were rerun after this display correction.

The museum keeps its 23x34 footprint, original entry at x5–7 and exit at x10–12. The floor is continuous. The full-size record station is at cell(17,20),yaw270, so its 15m wall lies along the right side rather than cutting across the journey. The learner bay is map-local(4.5,-0.25,6.5),yaw180,scale1; isolated hall-root(4.5,-0.25,10.5). The learner is temporarily installed for checks/captures, with explicit instructions for student installation, not registered as a permanent extra exhibit. The original hand stamp is retained on disk.

All {native} native checks pass: real installed wall, its pointer controls and source display, reset, 71 floor/body-clearance samples along the left aisle and turn to the rear exit, both approaches, exact printed learner, inherited XRTools pickup/trigger/release and count invariance under hand movement. Native above, arrival, wall and learner comparison images are included. Counts include the capture and completion assertions listed in the receipt.

These are author-operated ghost reconstruction checks, not independent-reader or physical-headset acceptance. Quest performance, comfort and continuous portal traversal remain unverified. Existing UID/Jolt warnings are retained; final logs contain no script/parse errors.

Reproduce code: python tools/test_graph_network.py

Reproduce museum: python tools/run_encounter_probe.py GT_Network_Analysis --sequence graphtheory --render --no-bridges --output-tag network-final --probe tools/probes/graph_network_room.gd
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
row.update(structure=read(M/'map_data.json')['layers']['structure'],tile=plan['tile'],tile_w=23,tile_h=34,tile_source='map',built=True)
delta=len(row['artifacts'])-old_count;d['totals']['artifacts']+=delta;next(c for c in d['chapters'] if c['sequence']=='graphtheory')['artifacts']+=delta
assert [x for x in d['segments'] if x['name']!=ID]==[x for x in old['segments'] if x['name']!=ID]
assert stamp==p.stat().st_mtime_ns;write(p,json.dumps(d,ensure_ascii=False,separators=(',',':')))
p=R/'doc/book/course/execution-plan/plan.json';preserve(p);stamp=p.stat().st_mtime_ns;d=read(p);old=copy.deepcopy(d)
row=next(x for x in d['lessons'] if x['id']==ID)
row.update(object='The carried PointBody marks vertex 4 on the same seven-ID scaffold; a new fictional directed ledger makes each count inspectable.',change='Count selected incoming and outgoing event records. Omit P04, filter by kind, move vertex 4 and rearrange the drawing while keeping provenance and IDs.',dependsOn=['GT_Pathfinding','GT_Layout'],reuses='Unchanged PointBody, traversal.gd and route.gd; stable IDs, seven endpoint pairs, dictionaries, arrays, filters, local/world conversion and cylinder geometry.',given='Existing Endless Museum and XRTools; installed eight-institution record wall; complete small display/input host. Directed roles and record kinds are explicit new authored data.',later='Do not teach centrality surveys here. Inherited adjacency remains undirected; Connectivity must derive directed adjacency from records before asking about return paths.',checks=[f'{count} exact-source code checks;384 filter/omission combinations; independent reversal rendered; three faulty variants caught.',f'{native} native museum checks;71 aisle/exit-turn samples; actual wall buttons and synthetic XRTools. No physical headset or independent-reader claim.'],transfer='Reverse P04 from 4→5 to 5→4 and update its source. Predict vertex 4 becomes2in/0out and vertex 5 becomes1in/1out in ALL; seven records remain and the arrow reverses. Moving the point must not change these counts.',carry='A measured incoming/outgoing count refers to selected directed records, not apparent prominence. Filtering, omission, reversal and layout are different operations.',next='GT_Connectivity: derive directed adjacency from this ledger, then test which vertices can reach one another and return.',notes='10 October: fourth hall only. Complete runnable ledger and host; reflective text stays with selection, provenance and the limits of counts. Existing record-wall code unchanged; other three exhibits retained in catalogue but removed from this hall placement. Review decision retained.',summary='Follow an arrow into its fictional source on the museum record wall, then continue our seven IDs and the same pickable point. Author one directed event for each existing endpoint pair and count incoming and outgoing active records. Omit P04 and predict the two affected counts; filter to reports and explain why omitting that payment has no further effect. Hold the point to move vertex 4 without changing the ledger. Independently reverse P04, update its source and test the new counts and arrow. Carry a directed record set into Connectivity, where a count alone cannot promise a return journey.')
previous=next(x for x in old['lessons'] if x['id']==ID)
assert row['decision']==previous['decision'] and row['baseline']==previous['baseline']
assert [x for x in d['lessons'] if x['id']!=ID]==[x for x in old['lessons'] if x['id']!=ID]
assert stamp==p.stat().st_mtime_ns;dump(p,d);dump(O/'lesson-plan.json',row)
write(O/'SUMMARY.md','# Network Analysis — lesson paragraph\n\n'+row['summary']+'\n\nShort instruction: Museum given. Carry PointBody + seven IDs + undirected scaffold. Author directed ledger, one event/pair; direction≠old adjacency. Count in/out over active records. Omit P04; filter reports; predict invariants. Hold4→localXY drawing only. Reverse P04 + source; test endpoints/arrow. Preserve ledger. Next: derive directed adjacency, test return paths.\n')
report=f"""# What does this count keep?

Graph Theory hall 4 of 8 continues the same point and seven vertex IDs. Pathfinding found a journey. Network Analysis now makes one measure explicit: incoming and outgoing records under a chosen filter.

| Part | Before | Now |
| --- | --- | --- |
| Tutorial | A broad centrality survey with undeclared helpers, followed by an appended record exercise | One coherent reconstruction: directed records, counts, filtering, omission and layout invariance |
| Lineage | New Graph helpers with no runnable host | Three unchanged carried files; one new ledger and a complete display/input host |
| Reflection | Long explanation of an ornamental network, then a second encounter | Stay with the source wall: what does a count preserve, select or leave unknown? |
| Museum | Narrow platforms and voids with overlapping network scenes | Continuous floor; existing record wall faces the open room; learner bay at the entrance |
| Independent task | General parameter changes | Reverse one payment and its source, predict the two count changes, inspect the reversed arrow |

The seven previous undirected pairs are retained as a scaffold. The new event directions are explicitly authored; they cannot be inferred from those pairs or from their positions. The same point marks vertex 4. Moving it changes the drawing, while its trigger changes which record kinds are counted. Nearby pointer controls omit/restore P04, switch layout and reset.

With all records active, vertex 4 has 1 incoming and 1 outgoing event; vertex 5 has 2 incoming and 0 outgoing. Omitting P04 (4 pays 5) reduces4's outgoing and5's incoming by one. Filtering to reports already excludes that payment, so omitting it then changes no count. Reversing it changes endpoint roles without reducing the number of events.

The large museum wall retains its existing eight institutions, twelve records and controls. The learner uses the seven IDs we already built. Its smaller dataset teaches the same operation without pretending it is the same dataset. Counts refer to events, not payment amounts, unique neighbours or importance.

**{count} code checks and {native} native museum checks pass.** The code suite compares 384 filter/omission states with independent endpoint tables, runs the student's reversed-record exercise and rejects three faulty counting models. The room suite exercises actual pointer controls, source readouts and synthetic XRTools pickup/trigger/release. It checks 71 floor/body-clearance samples along the open aisle and turn to the existing exit.

The source sentence was obscured by the controls in the first capture. It now sits in front of them; the printed code and museum checks were rerun. All final pictures are native Godot captures. The learner installation is temporary in these captures and explicitly described in the tutorial. The permanent record-wall implementation and graph sequence order are unchanged.

This is an author-operated ghost-student reconstruction. Independent reading, physical headset use, Quest performance, comfort and continuous portal traversal are still separate checks.

**Next: Connectivity.** One incoming and one outgoing count do not promise a way back. The next lesson will derive directed adjacency from these records and follow return paths.
"""
write(O/'REPORT.md',report)
css='''*{box-sizing:border-box}body{margin:0;background:#eeeae1;color:#24232a;font:18px/1.6 Georgia,serif}header,main,footer{max-width:1400px;margin:auto;padding:28px 4vw}header,footer{border-bottom:1px solid #bdb8ad}nav{display:flex;gap:12px 24px;flex-wrap:wrap;font:15px system-ui}a{color:#345463}h1{font-size:clamp(36px,5vw,66px);line-height:1.08}h2{font-size:30px;line-height:1.2;margin-top:2em}article{max-width:850px;margin:auto}.spread{display:grid;grid-template-columns:1fr 1fr;gap:2px;max-width:1800px}.spread article{background:#fcfaf4;padding:30px;min-width:0;width:100%;align-self:start}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}.pair article{min-width:0;padding:20px;background:#fcfaf4}.eyebrow,figcaption,footer{font:14px/1.6 system-ui}.eyebrow{text-transform:uppercase;letter-spacing:.12em;color:#64616a}.note{padding:18px;border-left:4px solid #678591;background:#faf7f1;font-family:system-ui}figure{margin:24px 0}img{width:100%;height:auto;display:block}figcaption{padding:12px 0;color:#5b5860}pre{overflow:auto;background:#202931;color:#edf0e8;padding:18px;line-height:1.5;font-size:14px;tab-size:4}code{font-size:.85em}pre code{font-size:inherit}table{border-collapse:collapse;width:100%;font:15px/1.5 system-ui}td,th{padding:12px;border-bottom:1px solid #c9c3b7;text-align:left;vertical-align:top}@media(max-width:900px){.spread,.pair{grid-template-columns:1fr}.spread article{padding:20px}}@media print{nav{display:none}pre{white-space:pre-wrap}body{background:white}}'''
def md(s):
 result=markdown.markdown(s,extensions=['fenced_code','tables']);source=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
 return re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(source)+'\n')+m[2],result,flags=re.S)
def page(title,body):
 return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p class="eyebrow">Endless Museum · Graph Theory 04 / 08 · 10 October 2026</p><nav><a href="index.html">Room and report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="graph-network-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Native museum images. Tested author-operated reconstruction. Physical headset and independent reader review remain open.</footer></body></html>'
def fig(src,caption):return '<figure><img loading="lazy" src="'+src+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
for key in ['tutorial','final']:write(O/(key+'.html'),page(key,'<main><article>'+md(text(M/(key+'.md')))+'</article></main>'))
write(O/'parallel.html',page('Network Analysis — facing texts','<main class="spread"><article><p class="eyebrow">Left · tutorial.md</p>'+md(text(M/'tutorial.md'))+'</article><article><p class="eyebrow">Right · final.md</p>'+md(text(M/'final.md'))+'</article></main>'))
changes='<main><h1>Before and after</h1>'
for key in ['tutorial','final']:changes+='<h2>'+key+'.md</h2><div class="pair"><article><p class="eyebrow">Previous draft</p>'+md(text(O/'before/commons/maps'/ID/(key+'.md')))+'</article><article><p class="eyebrow">Now</p>'+md(text(M/(key+'.md')))+'</article></div>'
write(O/'changes.html',page('Network Analysis changes',changes+'</main>'))
body='<main><p class="eyebrow">The same point, an inspectable count</p><h1>What does<br>this count keep?</h1><p class="note">'+str(count)+' code checks + '+str(native)+' native museum checks passed. Hall 4 of 8.</p>'
body+=fig('assets/student-before.png','Seven familiar vertices, now with explicitly authored directions. The black point marks4; every count refers to active source records.')
body+='<div class="pair">'+fig('assets/student-omitted.png','Omit P04:4 loses one outgoing record and5 loses one incoming record.')+fig('assets/student-moved.png','Move4 and choose payments with the point trigger. Geometry and filtering are separate operations.')+'</div>'
body+='<h2>The existing record wall</h2><div class="pair">'+fig('assets/record-wall.png','Eight fictional institutions and twelve inspectable records, unchanged from the existing museum exhibit.')+fig('assets/record-wall-filter.png','Payment filter and another layout. The highlighted source and selected institution remain explicit.')+'</div>'
body+='<h2>Room arrangement</h2><div class="pair">'+fig('before-museum/above.png','Before: narrow platform paths, voids and overlapping network scenes.')+fig('assets/study-above.png','After: continuous floor, record wall along the right side, learner bay near the entrance and open circulation.')+'</div>'
body+='<div class="pair">'+fig('before-museum/entry.png','The previous arrival interrupted by a raised hub and several large diagrams.')+fig('assets/entry.png','The revised arrival opens onto the hall.')+'</div>'
body+='<article>'+md(report)+'<p><a href="SUMMARY.md">Paragraph and short instruction</a> · <a href="checks.json">Code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="technical.md">Implementation and limits</a></p></article></main>'
write(O/'index.html',page('Network Analysis — a record counted',body))
write(O/'README.txt','Graph Theory hall 4/8. Open index.html for native images/report, parallel.html for tutorial left and reflection right. printed/ has five exact scripts and one-node study.tscn. Use inside AdaResearch Godot 4.6 with existing XRTools and museum; not a standalone export. PointBody, traversal and route are unchanged from Pathfinding. variation/ reverses P04; fault-* folders are deliberately wrong. first-name-conflict.log records the rejected initial parse failure. Current checks.json and museum/report.json are successful fresh receipts. Physical headset and independent-reader review remain open.\n')
for name in ['graph_network_student.gd','graph_network_room.gd']:shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
for name in ['test_graph_network.py','place_graph_network.py','write_graph_network.py','publish_graph_network.py','start_graph_network.py']:shutil.copyfile(R/'tools'/name,O/'probes'/name)
dump(O/'manifest.json',{'canonical':{n:sha(M/n) for n in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':code['printed_hashes'],'protected':{rel:sha(R/rel) for rel in protected},'checks':[count,native],'hall':ID,'physical_headset':False,'independent_reader':False})
archive=O/'graph-network-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in O.rglob('*'):
  if not p.is_file() or p.suffix in ['.zip','.uid'] or p.name=='validation.json':continue
  if p.is_relative_to(O/'before') and p.name in ['em_plan.json','em_layout_walk.json','long_museum.json','plan.json','necklace_hand.json']:continue
  data=p.read_bytes()
  if p.suffix=='.html':data=data.replace(b'href="graph-network-review.zip"',b'href="README.txt"')
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
