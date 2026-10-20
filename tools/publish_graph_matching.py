"""Publish the tested Matching lesson and sourced Ada relational atlas."""
from pathlib import Path
from html.parser import HTMLParser
import copy,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1];ID='GT_Matching';KEY='graphtheory|gt matching'
O=R/'doc/book/iterations/2026-10-10-matching-room-for-two';M=R/'commons/maps'/ID
S=R/'doc/book/studies/graphs-through-the-hands'/ID
RUN=R/'ada_run/encounter_pilot'/ID/'matching-final';A=R/'commons/artifacts/ada_relations'
def text(p):return p.read_text(encoding='utf8')
def read(p):return json.loads(text(p))
def write(p,s):p.write_bytes(s.encode('utf8'))
def dump(p,d):write(p,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def preserve(p):
 q=O/'before'/p.relative_to(R);q.parent.mkdir(parents=True,exist_ok=True)
 if not q.exists():shutil.copy2(p,q)
code=read(O/'checks.json');room=read(RUN/'report.json');data=read(A/'data.json')
assert code['passed'] and code['completed'] and room['passed'] and room['completed']
for p in [O/'code.log',RUN/'engine.log']:assert 'SCRIPT ERROR' not in text(p) and 'Parse Error' not in text(p)
assert code['atlas_data_sha256']==sha(A/'data.json')
for rel,h in data['source_hashes'].items():assert sha(R/rel)==h,rel
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',text(M/'tutorial.md'),re.S)
assert len(blocks)==5 and hashlib.sha256(text(M/'tutorial.md').encode()).hexdigest()==code['tutorial_sha256']
for name,source in blocks:
 assert source+'\n'==text(S/name)==text(O/'printed'/name)
 assert hashlib.sha256((source+'\n').encode()).hexdigest()==code['printed_hashes'][name]
protected=['commons/maps/sequences/graphtheory.json','commons/maps/curriculum_spine.json','algorithms/graphtheory/edmonds_algorithm/edmonds_algorithm.gd','algorithms/graphtheory/edmonds_algorithm/edmonds_algorithm.tscn','commons/artifacts/registry/algorithms_misc.json','ada_run/necklace_hand.json']
for rel in protected:assert (R/rel).read_bytes()==(O/'before'/rel).read_bytes(),rel
for name in ['point_body.gd','route.gd','traversal.gd']:assert (S/name).read_bytes()==(S.parent/'GT_Flow'/name).read_bytes()
before=read(O/'before/commons/maps/GT_Matching/map_data.json');current=read(M/'map_data.json')
assert {k:v for k,v in before['layers'].items() if k!='interactables'}=={k:v for k,v in current['layers'].items() if k!='interactables'}
for directory in ['assets','museum','before-museum','after','probes','prefab/ada_relations','prefab/matching_workshop']:(O/directory).mkdir(exist_ok=True,parents=True)
for p in RUN.glob('*.png'):shutil.copyfile(p,O/'assets'/p.name)
for name in ['report.json','engine.log','source_manifest.json','first-rejected-report.json','first-rejected-engine.log']:shutil.copyfile(RUN/name,O/'museum'/name)
for name in ['above.png','entry.png','report.json','engine.log']:shutil.copyfile(RUN.parent/'matching-before'/name,O/'before-museum'/name)
for folder in ['ada_relations','matching_workshop']:
 for p in (R/'commons/artifacts'/folder).iterdir():
  if p.is_file() and p.suffix in ['.gd','.tscn','.json']:shutil.copyfile(p,O/'prefab'/folder/p.name)
shutil.copyfile(R/'commons/artifacts/registry/graph_contexts.json',O/'prefab/registry.json')
count=len(code['checks']);native=len(room['checks'])
plan=next(x for x in read(R/'commons/data/museum/em_plan.json')['plans'] if x.get('map')==ID)
layout=read(RUN/'em_layout_walk.json')['halls'][KEY]
for rel in ['ada_run/em_layout_walk.json','commons/data/museum/em_layout_walk.json']:
 p=R/rel;preserve(p);stamp=p.stat().st_mtime_ns;d=read(p);old=copy.deepcopy(d);d['halls'][KEY]=layout
 assert {k:v for k,v in d['halls'].items() if k!=KEY}=={k:v for k,v in old['halls'].items() if k!=KEY}
 assert stamp==p.stat().st_mtime_ns;dump(p,d)
p=R/'commons/data/long_museum.json';preserve(p);stamp=p.stat().st_mtime_ns;d=read(p);old=copy.deepcopy(d)
row=next(x for x in d['segments'] if x['name']==ID);old_count=len(row['artifacts'])
row['artifacts']=[{'x':a['cell'][0],'z':a['cell'][1],'token':a['token'],'rot':a.get('rotation',0),'scale':a.get('scale',1)} for a in plan['artifacts']]
row.update(structure=current['layers']['structure'],tile=plan['tile'],tile_w=15,tile_h=17,tile_source='map',built=True)
delta=len(row['artifacts'])-old_count;d['totals']['artifacts']+=delta;next(c for c in d['chapters'] if c['sequence']=='graphtheory')['artifacts']+=delta
assert [x for x in d['segments'] if x['name']!=ID]==[x for x in old['segments'] if x['name']!=ID]
assert stamp==p.stat().st_mtime_ns;write(p,json.dumps(d,ensure_ascii=False,separators=(',',':')))
lesson=next(x for x in read(R/'doc/book/course/execution-plan/plan.json')['lessons'] if x['id']==ID)
previous=next(x for x in read(O/'before/doc/book/course/execution-plan/plan.json')['lessons'] if x['id']==ID)
assert lesson['decision']==previous['decision'] and lesson['baseline']==previous['baseline']
dump(O/'lesson-plan.json',lesson)
technical=f'''# Matching — implementation and verification

Graph Theory hall8/8. Existing Endless Museum and XRTools are supplied. One reconstruction: two makers and two tools. A new four-role model is explicitly declared; the harbour's seven IDs are not silently repurposed. PointBody, Route and Traversal are carried byte-identically from Flow. The full model, full procedural host and all three dependencies are printed in tutorial.md. final.md carries reflection on revision, omitted costs and kinds of relation.

People[0,1], tools[2,3], links[[0,2],[0,3],[1,2]]. Each selected pair is stored symmetrically in mate; -1 means free. Listed greedy takes0–2, a valid maximal matching of1. Search directs unused edges left-to-right and selected edges right-to-left. Reused BFS finds[1,2,0,3]; augmentation removes2–0 then adds1–2 and0–3. Count2 reaches the upper bound of two available people/tools. Another search finds no path. Reversed greedy finds2 directly. The operation is unweighted bipartite maximum cardinality, not preference or fairness, and not general odd-cycle blossom.

Input contract: consecutive disjoint IDs, all people first, then tools; permitted links always person-to-tool. The model assumes valid input; it does not validate arbitrary datasets. Search tries free start/end pairs in declared order; no claim of globally shortest augmenting path. Independent transfer replaces0–3 with1–3: listed greedy2; reversed greedy1 then augmentation[0,2,1,3] gives2. Fixed four-role host does not grow automatically with larger data.

Permanent matching_workshop.tscn references the actual learner study.gd. It builds figures, recognisable drill/saw, table, thin cylinder relations, labels and nearby controls. NEXT/1: greedy then augmentation; ORDER/O: reverse scan and reset; RESET/R: clear after release. Same black PointBody is a handle above makerA. Transformed-host hand position becomes localXZ; drawn height stays1. Release retains point identity and figure attachment. Trigger calls NEXT. Pair-count history[0,1,2] is not a complete state recording. Pink elevated rod shows cancelled pairing; gold rods are chosen links. A backing board separates the caption from the atlas behind it.

{count} exact-source Godot checks pass. Five scripts extracted from Markdown, hashed and executed, with rendered parity checked during publication. All1056 two-by-two and three-by-three graph/order combinations agree with independent exhaustive enumeration of disjoint edge subsets; validity and +1 growth checked at each augmentation. Actual keyboard/pointer and synthetic XRTools; transfer; three executed faulty variants: missing reverse search edge, allowing occupied endpoints, flipping wrong parity. The occupied-endpoint fault uses the two-link prefix because later overwrites in the three-link example accidentally repair its final state. An initial atlas parse failed on the built-in wrap name and inferred Color type; fixed before passing run.

{native} native museum checks pass. Existing greedy artifact uses ten vertices, five-cycle plus five spokes. Actual named STEP/ORDER controls yield3 versus5 pairs. No production algorithm changes. The first native probe addressed children by index and reached a label/backing instead of the button; rejected receipt/log preserved, then changed to named actual controls. Workshop controls, atlas five views/hall detail, exact printed reconstruction, synthetic pickup/trigger/release and39 completed checks verified. Images include baseline/after eye-level and above, both pairing states, greedy3/5 and all atlas views.

Map15x17 floor/walls/doorways/utilities retained. Permanent workshop cell(3,5),yaw180,height0,scale1; atlas(3,12),yaw180,height0,scale1. Existing greedy display(11,11),yaw0,height1.2,scale.42. All plinth0,pin1. Central29 supported clear capsule samples and exhibit/learner approaches pass. Temporary printed learner map-local(10,0,5),yaw180 (isolated hall-root(10,0,9)); it is not a second permanent installation. Selected layout rows, long_museum, execution-plan row and three wall-text rows aligned; other rows, draft decision and baseline preserved. Actual atlas sources are hashed after lesson-plan update.

Atlas snapshot:25 sequences,206 halls. 413 aggregate typed relation groups:24 walk,138 dependency,54 concept return,197 shared placement. The native table distinguishes global sequence and selected hall scale. Dependency/concept within-sequence groups are expanded at hall scale; shared placements are cross-sequence groups and direct visitors to ALL. Global self-groups are counted, not drawn as misleading tiny loops. Dates are eight selected review folders3–10October, not first-invention/completion claims. Eleven references outside current spine are explicitly listed, not invented as current halls. No inferred semantic similarity or live-object sharing. See ATLAS.md and atlas.html.

Read-only source generator: python tools/build_ada_relations.py. It reads current ordered spine,25 sequence files,206 map placements and execution-plan declarations; data.json is a saved snapshot, not an automatically live model. Test verifies source hashes and every relation's declared provenance. Edit authoritative sources then regenerate/retest/republish. The data contain more than one relation between some sequence pairs; each type stays separate.

During publication, a concurrent Symmetry_Seventeen edit changed its plan summary, notes and baseline. Those changes were preserved. The source ledger was regenerated; nodes, edges, omissions, dates and all other snapshot fields were asserted identical, with only source_hashes changed. Code/source checks were rerun. Native images still represent the same relationship data. The saved atlas-before-source-refresh.json makes that distinction inspectable.

The book-review route blocks scripts by design. atlas.html is a static reading/capture page; explorer.html is the portable interactive file, also published to the existing encyclopedia public/research/ada-relations/index.html. Server security headers are unchanged. Browser controls were exercised for all five relation types and graph-hall detail; the dependency view shows8 halls and13 declared relations. Source evidence expands in the ledger. The new public file is generated by this publisher.

Replay code: python tools/test_graph_matching.py

Replay native: python tools/run_encounter_probe.py GT_Matching --sequence graphtheory --render --no-bridges --output-tag matching-final --probe tools/probes/graph_matching_room.gd

Publish: python tools/publish_graph_matching.py

Author-operated ghost reconstruction and native render evidence. No physical-headset, Quest performance, independent blind-reader or continuous portal-traversal claim. Existing engine Jolt/UID warnings remain; no final script/parse errors. Next sequence: Foundations Crisis.
'''
write(M/'technical.md',technical)
for name in ['tutorial.md','final.md','technical.md','map_data.json']:
 shutil.copyfile(M/name,O/'after'/name)
 if name.endswith('.md'):shutil.copyfile(M/name,O/name)
write(O/'SUMMARY.md','# Matching — lesson paragraph\n\n'+lesson['summary']+'\n\nShort instruction: Museum given. Carry PointBody+Route+Traversal. New roles0,1people;2,3tools. Links02,03,12. Greedy02→maximal1. Unused L→R; chosen R→L. BFS1–2–0–3; remove20/add12+03→maximum2. Transfer03→13 reverses bad order. Grab moves drawing, not compatibility. Old odd-cycle scan3/5≠bipartite solver. Atlas companion: separate next/depend/return/share/date, preserve provenance. Reflection asks what the allocation omits.\n')
counts={k:sum(e['kind']==k for e in data['edges']) for k in ['walk','dependency','concept','shared']}
guide='''# Ada — which relation does the line record?

The new native table stands in Matching. It connects the finished graph sequence back to the research that produced it. It is a companion exhibit; learners do not have to implement it to complete the matching operation.

| View | A node means | A link means | Source | It does not claim |
|---|---|---|---|---|
| Spine | Sequence, or hall in detail view | Comes next in the recommended walk | curriculum_spine.json and sequence files | Chronology or prerequisite |
| Depends on | Sequence, or hall | A lesson declares this prerequisite | execution-plan/plan.json → lessons[].dependsOn | Mastery or a verified best order |
| Concept returns | Sequence, or hall | Declared first introduction → later return | execution-plan/plan.json → topics[] | Semantic similarity inferred by AI |
| Shared artifact | Sequence | Same placed token occurs in both | Actual map_data.json interactable layers | Same runtime instance or state |
| Timeline | Selected saved review | Next selected date | Existing dated iteration folder | First invention, completion, exhaustive history |

VIEW changes the relation. PREVIOUS/NEXT selects a sequence. HALLS/ALL changes scale. Within-sequence dependency/concept groups expand into their hall relations. Shared-token mode describes cross-sequence connections; use ALL for it. The native display draws thin cylinders and arrow cones for directed relations. Shared-token rods have no arrow. Counts and detailed evidence remain available in the browser ledger below.

Edit the authoritative sources, then run `python tools/build_ada_relations.py`, `python tools/test_graph_matching.py` and the native probe/publisher recorded in technical.md. Do not edit generated data.json as if it were the authoritative plan. Nothing here automatically changes a lesson's decision or rewrites the spine. The snapshot records 10 October 2026.

The eleven references below are outside the current spine. They mainly refer to earlier vector-room IDs. They may be retained catalog material or stale plan references; absence from the current spine alone does not decide which. We expose them for review rather than automatically redirecting their dependencies.

| Kind | From | To / topic |
|---|---|---|
'''
for item in data['omissions']:guide+='|'+item['kind']+'|'+item['from']+'|'+item['to']+(' / '+item['topic'] if 'topic' in item else '')+'|\n'
guide+='\n## Selected chronology\n\n'
for item in data['history']:guide+='- '+item['date']+' — '+item['title']+'; `'+item['source']+'`.\n'
guide+='\n## Quantities\n\n25 sequences; 206 halls; '+', '.join(f'{n} {k}' for k,n in counts.items())+' aggregate relation groups. Evidence lists can contain multiple declarations or placements per group. These counts are not counts of distinct algorithms or proof of curriculum completeness.\n'
write(O/'ATLAS.md',guide)
write(R/'doc/book/course/ada-relational-atlas.md',guide)
report=f'''# Matching — room for two

Graph Theory hall8/8 now has one complete tutorial operation and two companions. Two makers and two tools make pairing concrete. The older ring-and-spokes display exposes greedy order. A new 3D Ada atlas shows how the whole project connects.

| Part | Before | Now |
|---|---|---|
| Tutorial | Five algorithms, incomplete helper functions | One complete alternating-path repair, with unchanged PointBody and BFS |
| Main object | Abstract endpoint allocation | Two people, drill, saw and declared task compatibility |
| Event | A valid first choice | Revise that choice so both people can work |
| Reflection | Broad claims about pairing | The unused possibility, the cost of reconsidering, the limits of the model |
| Room | One large abstract comparison | Workshop front-left, project atlas rear-left, greedy comparison rear-right; clear central route |
| Ada as a graph | Not represented here | Actual spine, prerequisites, concept returns, shared placement tokens and selected chronology |

First A gets the drill and B waits. Search B→drill→A→saw; cancel A's first pairing and give the saw to A, the drill to B. The tools and permitted relations are unchanged. The lesson builds directly on Flow's revisable commitment. Moving the familiar black PointBody moves the drawing; changing task compatibility requires editing the relation.

The project atlas contains 25 sequences and 206 halls. Its 413 typed relation groups have source evidence. It distinguishes what comes next from what depends on what. Eleven references to halls outside the current spine remain visible for review. The timeline gives eight selected saved reviews from 3–10 October; it is not the entire history of Ada.

**{count} exact-source code checks and {native} native museum checks pass.** The matching model agrees with an independent exhaustive oracle on 1,056 small graph/order cases. The independent learner edit, three deliberately faulty variants, actual controls and synthetic XRTools pickup are covered. Tutorial code, executed code and rendered code match.

The room images are actual Godot museum renders. The second workshop shown front-right is the temporary reconstruction from the printed tutorial. Physical-headset and independent-reader review remain open. Next in the existing spine: Foundations Crisis.
'''
write(O/'REPORT.md',report)
css=text(R/'tools/publish_graph_network.py').split("css='''",1)[1].split("'''",1)[0]
css+='''
.pair figure{margin:0}section{margin:3rem 0;scroll-margin-top:2rem}.viewer{background:#f8f4ed;border:1px solid #b8aea2;padding:1.2rem}.filters{display:flex;gap:1rem;flex-wrap:wrap;margin-bottom:1rem}select,button{font:inherit;padding:.5rem;background:white;color:#262326;border:1px solid #a19689;border-radius:4px}#network{width:100%;height:auto;max-height:660px;background:#fffdfa}#network text{font:12px system-ui;fill:#343039}#network .node{cursor:pointer}#network .edge{stroke-width:1.6;fill:none;opacity:.65}#network .node:focus rect{stroke:#a32460;stroke-width:3}.ledger{max-height:500px;overflow:auto;background:white;padding:1rem}.ledger details{padding:.7rem;border-bottom:1px solid #ddd}.ledger pre{white-space:pre-wrap;overflow-wrap:anywhere;font-size:.78rem}.small{font-size:.87rem}.worlds{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:1rem}.worlds details{border-top:1px solid #aaa;padding:.8rem}svg [role=button]{outline:none} @media print{.ledger{max-height:none}.filters{display:none}section{break-before:page}}
'''
def md(s):
 result=markdown.markdown(s,extensions=['fenced_code','tables']);source=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
 return re.sub(r'<pre><code class="language-gdscript">.*?</code></pre>',lambda _: '<pre><code class="language-gdscript">'+html.escape(next(source)+'\n')+'</code></pre>',result,flags=re.S)
def page(title,body):
 return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p class="eyebrow">Endless Museum · Graph Theory 08 / 08 · 10 October 2026</p><nav><a href="index.html">Room and report</a><a href="atlas.html">Ada relations</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="graph-matching-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Native museum captures. Author-operated reconstruction. Physical-headset and independent-reader review remain open.</footer></body></html>'
def fig(src,caption):return '<figure><img loading="lazy" width="1800" height="1200" src="'+src+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
for key in ['tutorial','final']:write(O/(key+'.html'),page('Matching — '+key,'<main><article>'+md(text(M/(key+'.md')))+'</article></main>'))
write(O/'parallel.html',page('Matching — facing texts','<main class="spread"><article><p class="eyebrow">Left · tutorial.md</p>'+md(text(M/'tutorial.md'))+'</article><article><p class="eyebrow">Right · final.md</p>'+md(text(M/'final.md'))+'</article></main>'))
changes='<main><h1>Before and after</h1>'
for key in ['tutorial','final']:changes+='<h2>'+key+'.md</h2><div class="pair"><article><p class="eyebrow">Previous draft</p>'+md(text(O/'before/commons/maps'/ID/(key+'.md')))+'</article><article><p class="eyebrow">Now</p>'+md(text(M/(key+'.md')))+'</article></div>'
write(O/'changes.html',page('Matching changes',changes+'</main>'))
body=f'<main><p class="eyebrow">A previous choice can change</p><h1>Room for two</h1><p class="note">{count} code checks + {native} native museum checks passed. Graph Theory hall8 of8.</p>'
body+='<div class="pair">'+fig('assets/workshop-first.png','First: A takes the drill. B waits while the saw remains free. One pair is maximal, but not maximum.')+fig('assets/workshop-revised.png','Next: A changes to the saw; B gets the drill. Gold links are chosen; pink marks the cancelled pair.')+'</div>'
body+='<h2>Ada becomes an exhibit</h2><p><a href="http://localhost:3003/research/ada-relations/index.html?view=images&amp;map=GT_Matching">Hall images, what travels onward and artist references →</a></p><p><a href="atlas.html">Explore the spine, concept returns, prerequisites, shared artifacts and timeline →</a></p>'+fig('assets/atlas-walk.png','25 actual sequences in recommended walking order. The selected sequence can expand into its halls.')
body+='<h2>The same graph, different greedy orders</h2><div class="pair">'+fig('assets/greedy-three.png','The original odd-cycle display: cycle-first gives three pairs.')+fig('assets/greedy-five.png','Spokes-first gives five. This is an order comparison, not a general blossom solver.')+'</div>'
body+='<h2>Room arrangement</h2><div class="pair">'+fig('before-museum/above.png','Before: the existing comparison in the original hall.')+fig('assets/study-above.png','After: workshop and atlas left; comparison rear-right. Temporary student reconstruction front-right.')+'</div><div class="pair">'+fig('before-museum/entry.png','Previous arrival.')+fig('assets/study-entry.png','Arrival with the printed learner reconstruction. The central passage remains clear.')+'</div>'
body+='<article>'+md(report)+'<p><a href="SUMMARY.md">Paragraph and short instruction</a> · <a href="ATLAS.md">Relation definitions and sources</a> · <a href="checks.json">Code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="technical.md">Implementation and limits</a></p></article></main>'
write(O/'index.html',page('Matching — room for two',body))
body='''<main><p class="eyebrow">The research as a set of declared relations</p><h1>What connects Ada?</h1><p>25 sequences · 206 halls. These links come from the project files. Change the relation before interpreting the shape. Select a sequence, or click its building, to inspect the evidence.</p><div class="viewer"><div class="filters"><label>Relation <select id="relation"><option value="walk">Spine order</option><option value="dependency">Declared prerequisites</option><option value="concept">Concept returns</option><option value="shared">Shared artifacts</option><option value="history">Selected timeline</option></select></label><label>Sequence <select id="sequence"></select></label><button id="detail" type="button">Show halls</button></div><p id="meaning" aria-live="polite"></p><svg id="network" viewBox="0 0 1100 650" role="img" aria-label="Ada project relations"></svg><p id="stats"></p><div class="ledger" id="ledger"></div></div>'''
body+='<section><h2>Inside Matching</h2><p>The same five views are available on the native 3D table. VIEW cycles the relation; PREVIOUS/NEXT selects a sequence; HALLS/ALL changes scale.</p><div class="pair">'+fig('assets/atlas-walk.png','Recommended walking order; not chronological time.')+fig('assets/atlas-dependency.png','Declared prerequisites involving Graph Theory; arrow from prerequisite to dependent.')+'</div><div class="pair">'+fig('assets/atlas-concept.png','Concept introductions and returns declared in the execution plan.')+fig('assets/atlas-shared.png','Same placed artifact token, across sequences; not a claim of the same live object.')+'</div><div class="pair">'+fig('assets/atlas-halls.png','The graph sequence opens into eight halls.')+fig('assets/atlas-hall-dependencies.png','Inside that sequence, dependency links differ from the walking order.')+'</div>'+fig('assets/atlas-history.png','Eight selected dated reviews. Dates identify these saved accounts, not the first appearance of each idea.')+'</section><article>'+md(guide)+'</article>'
body+='<section><h2>Every hall in order</h2><div class="worlds">'
for n in data['nodes']:body+='<details><summary>'+html.escape(f"{n['order']:02} · {n['title']} ({len(n['maps'])})")+'</summary><ol>'+''.join('<li>'+html.escape(mid)+'</li>' for mid in n['maps'])+'</ol><p class="small">'+html.escape(n['source'])+'</p></details>'
body+='</div></section><p><a href="prefab/ada_relations/data.json">Full snapshot and source hashes</a> · <a href="ATLAS.md">Editable guide</a></p></main>'
body+='<script id="atlas-data" type="application/json">'+json.dumps(data,ensure_ascii=False).replace('<','\\u003c')+'</script>'
body+='''<script>
const data=JSON.parse(document.getElementById('atlas-data').textContent),relation=document.getElementById('relation'),sequence=document.getElementById('sequence'),detailButton=document.getElementById('detail'),svg=document.getElementById('network'),ledger=document.getElementById('ledger');let detail=false;
const meanings={walk:'A → B: B follows A in the recommended walk. This is not chronology.',dependency:'A → B: the plan declares A as a prerequisite of B. This is not proof of learning.',concept:'A → B: the subject register declares an introduction at A and return at B. No similarity inference.',shared:'A — B: the same artifact token is placed in both sequences. No shared live-state claim.',history:'Selected dated review folders, in date order. Not first invention, completion or the whole project history.'};
const colors={walk:'#7b808b',dependency:'#ac741c',concept:'#ae4880',shared:'#2b8e95',history:'#887655'};
for(const n of data.nodes){const o=document.createElement('option');o.value=n.id;o.textContent=String(n.order).padStart(2,'0')+' '+n.id;sequence.append(o)}sequence.value='graphtheory';
function el(tag,attrs,parent=svg){const n=document.createElementNS('http://www.w3.org/2000/svg',tag);for(const [k,v]of Object.entries(attrs))n.setAttribute(k,v);parent.append(n);return n}
function draw(){
 const kind=relation.value,s=data.nodes.find(n=>n.id===sequence.value),history=kind==='history',hall=detail&&!history;let nodes,edges;
 sequence.disabled=history;detailButton.disabled=history;detailButton.textContent=detail?'Show sequences':'Show halls';
 if(history){nodes=data.history.map(n=>({id:n.source,title:n.date+' / '+n.title}));edges=nodes.slice(1).map((n,i)=>({a:nodes[i].id,b:n.id,kind,evidence:[{from:data.history[i],to:data.history[i+1]}]}))}
 else if(hall){nodes=s.maps.map(id=>({id,title:id}));edges=kind==='walk'?s.maps.slice(1).map((b,i)=>({a:s.maps[i],b,kind,evidence:[{source:s.source}]})):data.edges.filter(e=>e.kind===kind&&['dependency','concept'].includes(kind)).flatMap(e=>e.evidence.filter(p=>s.maps.includes(p.from)&&s.maps.includes(p.to)).map(p=>({a:p.from,b:p.to,kind,evidence:[p]})))}
 else{nodes=data.nodes.map(n=>({id:n.id,title:String(n.order).padStart(2,'0')+' / '+n.id}));edges=data.edges.filter(e=>e.kind===kind&&(kind==='walk'||e.a===s.id||e.b===s.id))}
 document.getElementById('meaning').textContent=meanings[kind]+(hall&&kind==='shared'?' Use sequences for cross-sequence shared tokens.':'');
 svg.replaceChildren();const defs=el('defs',{}),marker=el('marker',{id:'arrow',viewBox:'0 0 10 10',refX:8,refY:5,markerWidth:6,markerHeight:6,orient:'auto-start-reverse'},defs);el('path',{d:'M 0 0 L 10 5 L 0 10 Z',fill:colors[kind]},marker);
 const cols=nodes.length>16?5:4,rows=Math.ceil(nodes.length/cols),positions=new Map();nodes.forEach((n,i)=>{const row=Math.floor(i/cols),col=row%2?cols-1-i%cols:i%cols;positions.set(n.id,{x:110+col*215,y:75+row*(490/Math.max(rows-1,1))})});
 const loops=edges.filter(e=>e.a===e.b).length;
 for(const e of edges){if(e.a===e.b)continue;const a=positions.get(e.a),b=positions.get(e.b);if(!a||!b)continue;const dx=b.x-a.x,dy=b.y-a.y,d=Math.hypot(dx,dy),x=b.x-dx*38/d,y=b.y-dy*30/d;const line=el('path',{d:`M${a.x},${a.y} L${x},${y}`,class:'edge',stroke:colors[kind]});if(kind!=='shared')line.setAttribute('marker-end','url(#arrow)');el('title',{},line).textContent=e.a+' → '+e.b+' / '+e.evidence.length+' source item(s)'}
 for(const n of nodes){const p=positions.get(n.id),g=el('g',{class:'node',transform:`translate(${p.x},${p.y})`,role:'button',tabindex:0,'aria-label':n.title});el('rect',{x:-32,y:-22,width:64,height:42,rx:3,fill:n.id===s.id?'#d9b169':'#b4d5ce',stroke:'#425a58'},g);el('rect',{x:-5,y:-3,width:10,height:23,fill:'#364547'},g);const t=el('text',{x:0,y:38,'text-anchor':'middle'},g);const parts=n.title.replaceAll('_',' ').split(' ');let lines=[''];for(const word of parts){if((lines.at(-1)+' '+word).length>23)lines.push('');lines[lines.length-1]+=(lines.at(-1)?' ':'')+word}lines.forEach((line,i)=>el('tspan',{x:0,dy:i?15:0},t).textContent=line);const choose=()=>{if(!hall&&!history){sequence.value=n.id;draw()}};g.addEventListener('click',choose);g.addEventListener('keydown',e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();choose()}})}
 document.getElementById('stats').textContent=nodes.length+' nodes · '+edges.length+' represented relations · '+loops+' within-sequence groups counted in the ledger, not drawn as loops · '+data.omissions.length+' references outside the current spine';
 ledger.replaceChildren();if(!edges.length){const p=document.createElement('p');p.textContent='No relations represented in this view. This is a limit of the selected source/view, not proof of no relationship.';ledger.append(p)}
 for(const e of edges){const d=document.createElement('details'),s=document.createElement('summary'),p=document.createElement('pre');s.textContent=e.a+(kind==='shared'?' — ':' → ')+e.b+' · '+e.evidence.length+' source item(s)';p.textContent=JSON.stringify(e.evidence,null,2);d.append(s,p);ledger.append(d)}
}
relation.addEventListener('change',draw);sequence.addEventListener('change',draw);detailButton.addEventListener('click',()=>{detail=!detail;draw()});draw();
</script>'''
interactive=page('Ada — what connects the work?',body)
write(O/'explorer.html',interactive)
# The book-review route intentionally blocks scripts. Keep it a reading page;
# deploy the authored interactive view through the existing public research UI.
reading='<main><p class="eyebrow">25 sequences /206 halls</p><h1>What connects Ada?</h1><p><a href="http://localhost:3003/research/ada-relations/index.html">Open the interactive atlas: select a relation and sequence, inspect its source evidence →</a></p><p>The downloaded review also includes <a href="explorer.html">explorer.html</a>, which runs when opened locally. The book-review reading route does not execute scripts.</p><section><h2>Inside Matching</h2>'+body.split('<section><h2>Inside Matching</h2>',1)[1].split('<script id="atlas-data"',1)[0]
write(O/'atlas.html',page('Ada — native atlas and sources',reading))
public=R.parent/'ada_encyclopedia/public/research/ada-relations'
public.mkdir(parents=True,exist_ok=True)
base='/book-review/'+O.relative_to(R).as_posix()+'/'
live=interactive.replace('href="atlas.html"','href="/research/ada-relations/index.html"')
live=re.sub(r'(href|src)="([^"#/:][^"]*)"',lambda m:m[1]+'="'+base+m[2]+'"',live)
write(public/'index.html',live)
write(O/'README.txt','Graph Theory hall8/8. index.html: native room/report; atlas.html: native atlas and source guide; explorer.html: interactive sources (also live at /research/ada-relations/index.html); parallel.html: tutorial left/reflection right. printed/: complete scripts and one-node scene extracted from tutorial.md. Requires AdaResearch Godot4.6 with existing XRTools. Workshop/atlas permanent; second learner shown is temporary. variation/: changed compatibility. fault-* deliberately incorrect. prefab/: native sources; paths refer to original repository. Code/native receipts completed. Headset and independent-reader review remain open.\n')
for name in ['graph_matching_student.gd','graph_matching_room.gd']:shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
for name in ['test_graph_matching.py','write_graph_matching.py','publish_graph_matching.py','build_ada_relations.py','align_graph_matching_wall.py']:shutil.copyfile(R/'tools'/name,O/'probes'/name)
dump(O/'manifest.json',{'canonical':{n:sha(M/n) for n in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':code['printed_hashes'],'atlas':sha(A/'data.json'),'protected':{rel:sha(R/rel) for rel in protected},'checks':[count,native],'hall':ID,'sequences':25,'maps':206,'relations':counts,'physical_headset':False,'independent_reader':False})
archive=O/'graph-matching-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in O.rglob('*'):
  if not p.is_file() or p.suffix in ['.zip','.uid'] or p.name=='validation.json':continue
  if p.is_relative_to(O/'before') and p.name in ['em_plan.json','em_layout_walk.json','long_museum.json','plan.json','necklace_hand.json','trunk_branches.json']:continue
  content=p.read_bytes()
  if p.suffix=='.html':content=content.replace(b'href="graph-matching-review.zip"',b'href="README.txt"')
  z.writestr(p.relative_to(O).as_posix(),content)
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
dump(O/'validation.json',{'passed':True,'local_links':links,'printed_files':len(blocks),'rendered_code_matches':True,'zip_crc':True,'zip_links':True,'size_mb':round(archive.stat().st_size/1e6,2),'checks':[count,native],'relations':counts})
print(json.dumps(read(O/'validation.json')))
# Preserve the current browser companion when republishing this older review.
# The native snapshot and its receipts above remain unchanged.
from publish_ada_atlas import publish as publish_image_atlas
publish_image_atlas()
