"""Publish the current three-search lesson without overwriting the earlier BFS review."""
from pathlib import Path
from html.parser import HTMLParser
import hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-10-search-the-same-river'
M=R/'commons/maps/GT_Pathfinding'
S=R/'doc/book/studies/graphs-through-the-hands/GT_Pathfinding'
RUN=R/'ada_run/encounter_pilot/GT_Pathfinding/search-progression'
def text(p):return p.read_text(encoding='utf8')
def read(p):return json.loads(text(p))
def write(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(s.encode('utf8'))
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
for name in ['point_body.gd','traversal.gd']:assert (S/name).read_bytes()==(S.parent/'GT_Layout'/name).read_bytes()
n=len(code['checks']);native=len(room['checks'])

technical=f'''# Pathfinding — three searches, one river

The permanent Impatient River now uses the same search class printed in tutorial.md. Its two banks, eleven seeded stones, connections, sinking/restoration and traveller remain. AStar3D stores that graph; the exhibit chooses a route with inherited BFS or the new weighted method. SEARCH RULE cycles BFS → Dijkstra → A*. SINK STONE changes availability and replans immediately. A missing route leaves the spark stopped. After more than three stones are disabled, the oldest returns.

PointBody, traversal.gd and BFS route.gd carry forward unchanged. The learner host adds weighted_route.gd and a nearby supplied museum button. One declared coordinate edit raises vertex 0 from y=2.3 to y=2.7 before comparison. IDs and adjacency remain. The four-edge BFS answer spans 3.330 m; the five-edge weighted answer spans 2.932 m. Dijkstra prioritises accumulated Euclidean length. A* adds straight-line distance to the goal, a consistent lower bound for these edge costs. Neither method trains parameters. Local metre coordinates assume unit scale. Route playback is distinct from search expansion and player navigation.

The complete five scripts are printed and extracted into a fresh Godot 4.6 run. {n} code checks pass. The suite compares 12,544 weighted cases against an independent exhaustive simple-path oracle, retains the earlier BFS checks and synthetic XRTools pickup/trigger/release, runs an independent coordinate edit, and rejects five deliberate algorithm faults. These tests caught an initially incorrect distance example; vertex 0 was explicitly raised and the teaching comparison retested.

{native} native checks pass: the museum's actual pool and portal destination resolver read Graph Theory before Machine Learning; real search/sink button signals work; the same spark, stones and availability survive mode changes. Sixty blocked-set/direction/mode cases agree with Godot's independent AStar3D distance result. Existing floor, aisle, approach and learner interaction checks pass. The learner study is temporarily installed in the reserved bay for these checks and captures; the permanent river is updated in place.

Spine order is Swarm Intelligence → Graph Theory → Machine Learning → Foundations Crisis. The runtime artifact manifest is stably reordered, retaining all within-chapter entries. The long-museum strip snapshot retains geometry and receives new chapter offsets; it is not a fresh whole-museum capture. Historical Lab layouts are not regenerated. Fresh Endless Museum starts use the new order; saved in-progress stream cursors and exported Quest builds are not migrated by this change.

Native screenshots and receipts accompany this review. Author-operated reconstruction and synthetic XR interaction do not establish physical headset usability or independent learner comprehension. Those remain untested.

Reproduce learner checks: `python tools/test_graph_pathfinding.py`

Reproduce museum checks: `python tools/run_encounter_probe.py GT_Pathfinding --sequence graphtheory --render --no-bridges --output-tag search-progression --probe tools/probes/graph_search_room.gd`

Publish after checks: `python tools/publish_graph_search.py`
'''
write(M/'technical.md',technical)

# Change only the transition prose at the end of Matching; printed code is retained.
p=R/'commons/maps/GT_Matching/tutorial.md';preserve(p)
old="The next sequence, Foundations Crisis, asks what a procedure's success entitles us to claim. Carry this distinction: a valid pairing, a largest collection and a good arrangement for the people are three different questions."
new="The next sequence is Machine Learning. Here we searched declared connections under a fixed rule. There we will ask what changes through selection or training, which measure guides that change, and what evidence it leaves. Keep graph structure, search state and learned parameters distinct. A valid result and a welcome arrangement remain different judgments."
assert old in text(p) or new in text(p);write(p,text(p).replace(old,new))
p=R/'commons/maps/GT_Matching/final.md';preserve(p)
old="Before the next room asks what a proof can hold, keep the saw in view: the unused possibility was there all along, but the first arrangement did not make it available."
new="Keep the saw in view as we enter Machine Learning: the unused possibility was there all along, but the first arrangement did not make it available. When a system changes its own arrangement, what will it count as improvement?"
assert old in text(p) or new in text(p);write(p,text(p).replace(old,new))
p=R/'doc/book/course/execution-plan/plan.json';d=read(p)
row=next(x for x in d['lessons'] if x['id']=='GT_Pathfinding')
row['checks']=[f'{n} exact-source Godot checks; 12,544 weighted oracle cases; independent edit; five rejected faults.',f'{native} native checks; 60 engine-oracle comparisons; actual controls, same point, XR simulation and chapter destination checks.']
row['summary']='Watch the same museum river under three search rules. Carry PointBody, traversal and seven vertex IDs from Layout; add the explicit 4–5 detour, then raise vertex 0 once to compare costs. Reconstruct a fewest-edge BFS path, count segment lengths with Dijkstra, and add a straight-line lower bound with A*. Compare route, distance and expanded IDs while positions and blocked vertices stay fixed. Predict the longer four-edge route versus the shorter five-edge route, then change one position and test again. Keep the same point. Carry search criteria into later questions about learning.'
next(x for x in d['lessons'] if x['id']=='GT_Matching')['next']='Machine Learning: distinguish declared connections and search state from selection, learned parameters and their evaluation.'
ml=next(x for x in d['lessons'] if x['id']=='ML_Evolution')
if 'GT_Pathfinding' not in ml['dependsOn']:ml['dependsOn'].append('GT_Pathfinding')
addition=' Return to the difference between searching fixed possibilities and changing the candidates or parameters.'
if addition.strip() not in ml['reuses']:ml['reuses']+=addition
ids=[]
for sequence in ['graphtheory','machinelearning']:
 ids+=read(R/f'commons/maps/sequences/{sequence}.json')['sequences'][sequence]['maps']
by_id={x['id']:x for x in d['lessons']}
slots=[i for i,x in enumerate(d['lessons']) if x['id'] in ids]
assert len(slots)==len(ids)
for i,mid in zip(slots,ids):d['lessons'][i]=by_id[mid]
dump(p,d);dump(O/'lesson-plan.json',row)

for folder in ['assets','museum','after','probes']:(O/folder).mkdir(exist_ok=True)
for p in RUN.glob('*.png'):shutil.copy2(p,O/'assets'/p.name)
for name in ['report.json','engine.log','source_manifest.json','spec.json']:shutil.copy2(RUN/name,O/'museum'/name)
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
 shutil.copy2(M/name,O/'after'/name)
 if name.endswith('.md'):shutil.copy2(M/name,O/name)
for name in ['graph_pathfinding_student.gd','graph_search_room.gd']:shutil.copy2(R/'tools/probes'/name,O/'probes'/name)
for name in ['write_graph_pathfinding.py','test_graph_pathfinding.py','align_graph_search_order.py','publish_graph_search.py']:shutil.copy2(R/'tools'/name,O/'probes'/name)

report=f'''# The same river, three questions

**Graph Theory now precedes Machine Learning.** The eight graph halls keep their order. Pathfinding grows through three passes on the existing river and carried point; it does not become three disconnected examples.

| Rule | What it asks | What the student adds |
| --- | --- | --- |
| BFS | Fewest crossings? | Queue, predecessor, reconstructed route |
| Dijkstra | Least total distance? | Edge cost, accumulated cost, replace an expensive predecessor |
| A* | Which promising route should we inspect next? | Cost so far plus a lower bound on what remains |

The point keeps its appearance, grab behaviour and recorded journey. Holding pauses it; trigger or **1** changes availability. The nearby button or **2** changes the search rule; **R** replays. The river's two close controls are **SINK STONE** and **SEARCH RULE**. The readout separates route, edge count, distance and search visits.

For the small study, vertex 0 is explicitly raised once. BFS then chooses four edges totalling **3.330 m**; Dijkstra and A* choose five totalling **2.932 m**. Compare rules without changing the drawing. Afterwards lower vertex 0 and predict the new result. The permanent river keeps its existing positions; different rules may return the same route there. A* does not guarantee fewer visits on every graph.

The tutorial supplies the complete runnable code and explains each addition. The reflection adds one short encounter: what have we decided a good crossing should cost? Matching's closing paragraph now leads into learning: searching a fixed graph is different from changing candidates or learned parameters.

**{n} code checks and {native} native museum checks pass.** This includes 12,544 weighted cases against exhaustive routes, five detected deliberate faults, and 60 comparisons with Godot's AStar3D. The museum's live artifact pool and portal destination resolver also confirm the reordered chapters. Physical headset testing remains open.

The revised route is **Swarm → Graph Theory → Machine Learning → Foundations Crisis**. Machine Learning's existing draft status is preserved; this change does not claim its tutorials are finished.
'''
write(O/'REPORT.md',report);write(O/'SUMMARY.md','# Lesson paragraph\n\n'+row['summary']+'\n')
css='''*{box-sizing:border-box}body{margin:0;background:#edeae2;color:#24272b;font:18px/1.65 Georgia,serif}header,main,footer{max-width:1440px;margin:auto;padding:28px 4vw}header{border-bottom:1px solid #b7b8b2}nav{display:flex;gap:12px 24px;flex-wrap:wrap;font:15px system-ui}a{color:#28566a}h1{font-size:clamp(38px,5vw,68px);line-height:1.06}h2{line-height:1.25}article{max-width:850px;margin:auto}.pair,.spread{display:grid;grid-template-columns:1fr 1fr;gap:24px}.spread{max-width:1800px}.spread article{background:#fffdf6;padding:24px;min-width:0;align-self:start}pre{padding:20px;background:#1d2830;color:#f3f0e8;overflow:auto;font:14px/1.55 monospace;tab-size:4}code{font-size:.85em}pre code{font-size:inherit}figure{margin:24px 0}img{width:100%;display:block}figcaption,.eyebrow,footer{font:14px/1.55 system-ui;color:#565c5c}.eyebrow{text-transform:uppercase;letter-spacing:.12em}figcaption{padding:12px 0}.note{padding:20px;background:#fffdf6;border-left:4px solid #67818a}table{width:100%;border-collapse:collapse;font:16px/1.5 system-ui}td,th{text-align:left;vertical-align:top;padding:12px;border-bottom:1px solid #babbb6}@media(max-width:850px){.pair,.spread{grid-template-columns:1fr}}@media print{nav{display:none}pre{white-space:pre-wrap}}'''
def md(s):
 # Two A* mentions must not become an unintended emphasis pair in prose.
 parts=re.split(r'(```.*?```)',s,flags=re.S)
 safe=''.join(p if p.startswith('```') else re.sub(r'(?<!\\)A\*',r'A\\*',p) for p in parts)
 result=markdown.markdown(safe,extensions=['fenced_code','tables','footnotes'])
 sources=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
 return re.sub(r'(<pre><code class="language-gdscript">).*?(</code></pre>)',lambda m:m[1]+html.escape(next(sources)+'\n')+m[2],result,flags=re.S)
def page(title,body):return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p class="eyebrow">Endless Museum · Graph Theory 03 / 08 · 10 October 2026</p><nav><a href="index.html">Room and report</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="search-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Native Godot captures. Author-operated checks; physical headset and independent reader review remain open.</footer></body></html>'
def fig(name,caption):return '<figure><img loading="lazy" src="assets/'+name+'.png" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
for key in ['tutorial','final']:write(O/(key+'.html'),page(key,'<main><article>'+md(text(M/(key+'.md')))+'</article></main>'))
write(O/'parallel.html',page('The same river — facing texts','<main class="spread"><article><p class="eyebrow">Left · tutorial.md</p>'+md(text(M/'tutorial.md'))+'</article><article><p class="eyebrow">Right · final.md</p>'+md(text(M/'final.md'))+'</article></main>'))
body='<main><p class="eyebrow">BFS → Dijkstra → A*</p><h1>The same river,<br>three questions.</h1><p class="note">Graph Theory → Machine Learning. '+str(n)+' code checks + '+str(native)+' museum checks passed.</p>'
body+=fig('river-bfs','Inside the actual Pathfinding hall: the same river, stones and spark, with adjacent controls for availability and search rule.')
body+='<article>'+md(report)+'</article><h2>One point, two meanings of shortest</h2><div class="pair">'+fig('student-route','BFS: four edges. The upper crossing is longer in metres.')+fig('student-astar','A*: five edges, less total distance. The same point and connections remain.')+'</div>'
body+='<h2>The room from above</h2>'+fig('study-above','Existing river at right, supporting maze and temporary learner study at left. The middle passage remains clear.')
body+='<article><p><a href="checks.json">Code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="technical.md">Implementation and limits</a> · <a href="SUMMARY.md">Lesson paragraph</a></p></article></main>'
write(O/'index.html',page('The same river, three searches',body))
body='<main><h1>Before and after</h1>'
for key in ['tutorial','final']:body+='<h2>'+key+'.md</h2><div class="spread"><article>'+md(text(O/'before/commons/maps/GT_Pathfinding'/(key+'.md')))+'</article><article>'+md(text(M/(key+'.md')))+'</article></div>'
write(O/'changes.html',page('Search lesson changes',body+'</main>'))
write(O/'README.txt','Open index.html or parallel.html. Five complete scripts in printed/ run inside the existing AdaResearch Godot project with XRTools; this is not a standalone project export. fault-* contains intentionally wrong algorithms used to test the checks. Technical.md states verification scope.\n')
dump(O/'manifest.json',{'canonical':{n:sha(M/n) for n in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':code['printed_hashes'],'river_sha256':sha(R/'commons/artifacts/impatient_river/impatient_river.gd'),'spine_sha256':sha(R/'commons/maps/curriculum_spine.json'),'checks':[n,native],'physical_headset':False})
archive=O/'search-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in O.rglob('*'):
  if not p.is_file() or p.suffix in ['.zip','.uid'] or p.name=='validation.json' or p.is_relative_to(O/'before'):continue
  data=p.read_bytes()
  if p.suffix=='.html':data=data.replace(b'href="search-review.zip"',b'href="README.txt"')
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
  for found in re.findall(r'<pre><code class="language-gdscript">(.*?)</code></pre>',text(p),re.S):assert html.unescape(found) in [s+'\n' for _,s in blocks]
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None
 for name in [n for n in z.namelist() if n.endswith('.html')]:
  parser=Links();parser.feed(z.read(name).decode())
  for ref in parser.refs:assert (Path(name).parent/ref).as_posix() in z.namelist(),(name,ref)
dump(O/'validation.json',{'passed':True,'links':links,'code_matches':True,'zip_crc':True,'zip_links':True,'checks':[n,native]})
print(json.dumps(read(O/'validation.json')))
