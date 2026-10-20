from pathlib import Path
from html.parser import HTMLParser
import copy,hashlib,html,json,re,shutil,zipfile
import markdown
R=Path(__file__).resolve().parents[1];ID='GT_Flow';KEY='graphtheory|gt flow'
O=R/'doc/book/iterations/2026-10-10-flow-room-for-another';M=R/'commons/maps'/ID
S=R/'doc/book/studies/graphs-through-the-hands'/ID
RUN=R/'ada_run/encounter_pilot'/ID/'flow-final';A=R/'commons/artifacts/graph_worlds'
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
assert len(blocks)==5 and hashlib.sha256(text(M/'tutorial.md').encode()).hexdigest()==code['tutorial_sha256']
for name,source in blocks:
 assert source+'\n'==text(S/name)==text(O/'printed'/name)
 assert hashlib.sha256((source+'\n').encode()).hexdigest()==code['printed_hashes'][name]
protected=['commons/maps/sequences/graphtheory.json','algorithms/graphtheory/push_relabel/push_relabel.gd','algorithms/graphtheory/push_relabel/push_relabel.tscn','commons/artifacts/registry/algorithms_misc.json','ada_run/necklace_hand.json']
for rel in protected:assert (R/rel).read_bytes()==(O/'before'/rel).read_bytes(),rel
for name in ['point_body.gd','traversal.gd']:assert (S/name).read_bytes()==(S.parent/'GT_Spanning_Trees'/name).read_bytes()
assert (S/'route.gd').read_bytes()==(S.parent/'GT_Pathfinding/route.gd').read_bytes()
for name in ['flow_model.gd','route.gd','traversal.gd']:assert (S/name).read_bytes()==(A/name).read_bytes()
for directory in ['assets','museum','before-museum','after','probes','prefab']:(O/directory).mkdir(exist_ok=True)
for p in RUN.glob('*.png'):shutil.copyfile(p,O/'assets'/p.name)
for name in ['report.json','engine.log','source_manifest.json']:shutil.copyfile(RUN/name,O/'museum'/name)
for name in ['above.png','entry.png','report.json','engine.log']:shutil.copyfile(RUN.parent/'flow-before'/name,O/'before-museum'/name)
for p in A.iterdir():
 if p.is_file() and p.suffix in ['.gd','.tscn','.json']:shutil.copyfile(p,O/'prefab'/p.name)
shutil.copyfile(R/'commons/artifacts/registry/graph_contexts.json',O/'prefab/registry.json')
count=len(code['checks']);native=len(room['checks']);cases=read(A/'cases.json')
summary='Carry PointBody, seven vertex IDs and the complete route finder. Declare a new directed harbour plan with crate-slot capacities for one interval; keep the earlier build-cost model intact. Reuse breadth-first search on positive residual connections. Allocate the first delivery, then find a second route that cancels one previous commitment so both deliveries fit. Read the bottleneck, conservation and the two-slot limiting cut. Move the held point without changing capacities. Independently reduce the final link to one slot and predict the new maximum. Compare the existing forward-only preflow display without calling its blocked result a maximum. At the next hall, use the same possibility of revision to reconsider who gets which tool.'
technical=f'''# Flow — implementation and verification

The learner carries point_body.gd and traversal.gd byte-identically from Spanning Trees, and route.gd from Pathfinding. Seven IDs remain. New flow_model.gd declares a directed, integer-capacity planning network; new study.gd prints the complete harbour host. Earlier records and build-cost examples remain intact. No hidden scene references or new player setup.

Original directed links are 0→1,0→2,1→3,1→4,2→3,3→5,4→5 with capacity1, and5→6 with capacity2. Every capacity denotes crate slots during the same planning interval. Source0, sink6. Independent matrix rows hold capacity and antisymmetric net flow. Positive capacity-minus-flow entries become the reused BFS route finder's neighbours. A successful step adds the path's minimum residual and subtracts its reverse entries. Original antiparallel edges are outside this lesson's dataset.

First route [0,1,3,5,6] allocates1. Second [0,2,3,1,4,5,6] cancels1→3 and allocates another1. Final actual routes are0→1→4→5→6 and0→2→3→5→6. A third search finds no path. Source cut and sink capacity both equal2. Reverse residual means a revisable commitment before dispatch, not physical backwards shipment. Conservation holds at intermediate vertices after each complete augmentation; the older preflow comparison has a different intermediate-state contract.

Transfer changes5→6 capacity2 to1: final maximum1. The prose also asks what happens when1→4 is closed: maximum1 because3→5 then limits every delivery. Changes are made to the declared data, not patched into the algorithm.

The complete host draws seven stations, eight cylinder/cone roads, eight binary allocation markers and amount/capacity labels. A raised pink link marks a cancelled commitment. The same black point moves yard4 in localXZ while its drawn height stays1. Trigger/1 or PLAN NEXT advances; RESET/R waits for release. Existing XRTools is given. Temporary installation map-local(9,0,3.8), yaw180, scale1; isolated hall-root(9,0,7.8). The learner is not a registered permanent extra exhibit.

{count} exact-source code checks pass. Five tutorial scripts are extracted and hashed. An independent literal-endpoint min-cut oracle checks768 capacity configurations (256 subsets ×3 capacity cases). Capacity bounds, antisymmetry and intermediate conservation are checked during augmentation. Tests cover full host, real pointer/keyboard entry points, transformed-host synthetic XRTools pickup/trigger/release, retained point identity, independent transfer and three executed faulty variants: missing reverse update, maximum instead of minimum bottleneck, and ignoring assigned flow in residual capacity. No final script/parse errors.

{native} native museum checks pass. The original forward-only display terminates BLOCKED with sink receipt7 and unresolved positive excess. No maximum is claimed. The first native assertion incorrectly read current_operation rather than operation_label.text; that rejected receipt/log is retained. An early student camera was outside the front wall; the corrected camera is inside the hall. An overwritten Label3D and MeshInstance3D allocation caused leaks in an early host; redundant initial allocations were removed and code checks rerun.

Permanent graph_worlds.tscn supplies eleven concrete comparisons for the eight halls and three extensions. The source Flow, Route and Traversal are identical to learner files; TreeModel is carried from Spanning. Other small case operations remain separate and explicit. Previous/Next selects a case; Try It changes the represented condition; Reset restores it. Captures show before and after for every case. Disease uses seeded synchronous toy SI with probability0.35 per infectious-susceptible edge per round, no recovery or biological calibration. Historical bridges preserve the multigraph topology, not geographic appearance. Future relays are an invented scenario. See WORLD-EXAMPLES.md for what every node, edge and action denotes.

The13×12 hall has continuous floor and3m perimeter with central doorway openings. The gallery occupies left cell(3,6), height0, yaw180, scale1. The old forward-only comparison is right rear at(9,9), height1.2, yaw180, scale0.32. Grid DFS, Prim and Karger are removed only from this hall's placement; their sources/catalog entries remain.19 supported clear capsule samples plus both approaches pass. Authored book and both shipped/source wall rows are aligned only for Flow. Selected layout, long-museum and execution-plan rows follow the actual placement; other rows and review decision/baseline are preserved.

This is author-operated ghost reconstruction and rendered native museum evidence. No physical headset, independent-reader, Quest performance or continuous portal-traversal claim. The gallery is permanently installed in Flow; earlier halls have companion examples in this gallery, not additional installations in their rooms. Matching has a preview here; its full lesson remains next.

Replay code: python tools/test_graph_flow.py

Replay museum: python tools/run_encounter_probe.py GT_Flow --sequence graphtheory --render --no-bridges --output-tag flow-final --probe tools/probes/graph_flow_room.gd
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
row.update(structure=read(M/'map_data.json')['layers']['structure'],tile=plan['tile'],tile_w=13,tile_h=12,tile_source='map',built=True)
delta=len(row['artifacts'])-old_count;d['totals']['artifacts']+=delta;next(c for c in d['chapters'] if c['sequence']=='graphtheory')['artifacts']+=delta
assert [x for x in d['segments'] if x['name']!=ID]==[x for x in old['segments'] if x['name']!=ID]
assert stamp==p.stat().st_mtime_ns;write(p,json.dumps(d,ensure_ascii=False,separators=(',',':')))
p=R/'doc/book/course/execution-plan/plan.json';preserve(p);stamp=p.stat().st_mtime_ns;d=read(p);old=copy.deepcopy(d)
row=next(x for x in d['lessons'] if x['id']==ID)
row.update(object='Same PointBody and seven IDs in a new directed harbour allocation model.',change='Reuse pathfinding on residual links; cancel an earlier commitment so another delivery fits.',dependsOn=['GT_Pathfinding','GT_Spanning_Trees'],reuses='PointBody, Traversal and Route unchanged; seven IDs.',given='Existing Endless Museum/XRTools; complete harbour host; original forward-only preflow comparison.',later='A second algorithm for preflow/push-relabel is a comparison, not another implementation requirement. Matching follows.',checks=[f'{count} exact-source Godot checks;768 configurations against independent min-cut oracle; transfer and three rejected faults.',f'{native} native checks; eleven contexts, actual pointer, synthetic XRTools, supported route.'],transfer='Reduce5→6 from2 to1; predict and obtain maximum1 without changing the algorithm.',carry='A route existing does not guarantee available capacity. A reversible earlier allocation can make room for another.',next='GT_Matching: revise the first pairing so both makers can work.',notes='10 October: hall7. Eleven concrete companion cases permanently installed here. Earlier halls unchanged. Matching example is a preview. Draft decision and baseline preserved.',summary=summary)
previous=next(x for x in old['lessons'] if x['id']==ID)
assert row['decision']==previous['decision'] and row['baseline']==previous['baseline']
assert [x for x in d['lessons'] if x['id']!=ID]==[x for x in old['lessons'] if x['id']!=ID]
assert stamp==p.stat().st_mtime_ns;dump(p,d);dump(O/'lesson-plan.json',row)
write(O/'SUMMARY.md','# Flow — lesson paragraph\n\n'+summary+'\n\nShort instruction: Museum given. Carry point+IDs+queue+Route. Declare directed slot capacities, not costs. Residual>0→BFS; bottleneck=min. First1; second cancels1→3→total2; cut2 certifies. Reverse=revise before dispatch. Move point, preserve capacities. Transfer sink cap1→max1. Old preflow blocked≠maximum. Next: revise pairing.\n')
descriptions={
 'visit':('Rooms; passages between them. Figures mark visits, not extra vertices.','Advance the breadth-first queue one room at a time. Separate visiting vertices from using every passage.','Human movement gives reachability a purpose. A queue orders inspection; it is not a claim that a visitor walks the displayed tree in that order.'),
 'ants':('Trail junctions; trail connections. Ant forms identify the setting.','Switch from one drawing to a circular drawing. All six links remain.','Moving a drawn junction need not alter the habitat model. Real foraging would require additional behaviour and environmental assumptions.'),
 'bridges':('Places in a fictional town; equally costly crossings.','Close1→3 in both directions; the route changes to the other branch.','Reuse BFS before adding travel time, slopes or access requirements. Fewest edges is the declared objective.'),
 'shares':('Accounts; recorded directed share events. Parallel events remain countable.','Omit one0→1 share. Incoming count at1 drops from2 to1.','The count changes because the included evidence changes. A share is not evidence of agreement, exposure or influence.'),
 'ferry':('Six islands; one-way service connections.','Add3→2 to the existing2→3 crossing. Two three-island return groups become one.','A way out and a way back are distinct. Timetable details would change what a usable journey means.'),
 'pipes':('Seven homes; candidate undirected pipe links with assigned build costs.','Eight steps build cost21; ninth breaks0–1; tenth adds spare4–5 and restores reachability.','This applies the exact preceding tree model. The pipe analogy introduces a practical motive for a spare, while pressure remains outside the model.'),
 'harbour':('Stock, depots, yards, dock, destination; directed crate-slot capacities.','First allocation uses yard3. Second cancels1→3, reroutes the first through4, and reaches total2.','The tutorial focus is revision of an allocation. Buildings make the roles visible; flow remains a plan, not a physical shipment simulator.'),
 'tools':('Two makers and two tools; declared task-compatible pairings.','First maker takes the tool the second needs. Reassign the first to the other tool; both can work.','A concrete preview of Matching. This small declared case does not implement a general matching solver or an account of fair allocation.'),
 'contact':('People; assumed potentially infectious contacts.','Advance synchronous seeded rounds. Newly infected people can transmit only in later rounds.','A contact graph alone does not spread disease. The explicitly additional probability and update rule produce a toy SI process.'),
 'euler':('Four shores; seven distinct bridges, including parallel pairs.','Reveal degrees5,3,3,3. Four odd-degree vertices rule out a walk using every bridge exactly once.','This historical problem asks about edges, unlike the opening vertex-visit lesson. The 3D town is a schematic setting, not old Königsberg reconstructed.'),
 'future':('Neighbourhood communication relays; permitted bidirectional connections.','Lose3–5, then add4–5. The source-to-destination route disappears and returns.','An invented future gives the existing reachability operation a new purpose. The model tests a particular failure; it does not predict social resilience.')
}
guide='# Graphs with something at stake\n\nEleven native 3D companion examples for the eight Graph Theory halls. They are selectable in **Graph worlds**, permanently installed in **GT_Flow**. Earlier halls retain their existing installations. Each comparison gives a graph operation a concrete setting without adding another required tutorial algorithm.\n\nThe learner still carries the point and reusable code. A different setting must declare what its vertices, edges and quantities mean. A message can be copied; allocated crates are conserved; a contact only offers a possibility of transmission. These are different contracts.\n\n## Route\n\n| Hall | Concrete example | Action |\n|---|---|---|\n'
for c in cases:guide+=f"| {c['hall']} | {c['title']} | {c['action']} |\n"
guide+='\n## The examples\n\n'
for c in cases:
 meanings,change,why=descriptions[c['id']]
 guide+=f"### {c['title']}\n\n**{c['hall']} · {c['era']}**\n\n**What is represented:** {meanings}\n\n**What changes:** {change}\n\n**Teaching purpose:** {why}\n\n**Boundary:** {c['limit']}\n\n"
 if c['source']:guide+=f"Contextual reading: [source]({c['source']}). The geometry and datasets here are our own schematic examples.\n\n"
guide+='''## Research and attribution

- [Ant foraging and minimal paths in simple graphs](https://arxiv.org/abs/1103.1612) studies a foraging model with reinforcement. It is context for the animal comparison, not evidence that our static ants implement that behaviour.
- [Thinking clearly about social aspects of infectious disease transmission](https://www.nature.com/articles/s41586-021-03694-x) helps distinguish contact structure and transmission assumptions. Our probability0.35 is arbitrary and uncalibrated.
- [Bluesky custom feeds](https://bsky.social/about/blog/7-27-2023-custom-feeds) offers a current-platform example of selection affecting what is shown. Our gallery counts fictional share records, not a real platform's reach or algorithm.
- [NetworkX maximum-flow documentation](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.flow.maximum_flow.html) is a reference for the residual-network conventions. The learner implementation is GDScript with no NetworkX dependency.
- [The Euler Archive](https://eulerarchive.maa.org/) provides primary historical works. Our bridge graph preserves the usual four-vertex, seven-edge problem; the buildings are illustrative.

## How to revise this collection

Edit commons/artifacts/graph_worlds/cases.json for the title, declared era, action and boundary. These appear in the native gallery. Its graph_worlds.gd contains the separate small case operations and geometry. Cases share a display but do not share an invented universal social meaning. The editable guide is doc/book/course/graph-world-examples.md. Reports are generated by tools/publish_graph_flow.py.

Short instruction: Concrete setting per operation. Declare node/edge/quantity/action/omissions. Preserve carried code. Historical topology≠physical reconstruction. Fictional future≠forecast. Contact≠infection. Shares≠trust. Crates conserved, messages copied. One required learner object per principle; other contexts remain companions. Test the represented change.
'''
write(O/'WORLD-EXAMPLES.md',guide)
write(R/'doc/book/course/graph-world-examples.md',guide)
report=f'''# Room for another

Graph Theory hall7/8 now teaches capacity through a small harbour. It also houses eleven concrete companion examples for the sequence: people, ant trails, bridges, recorded shares, ferries, water-pipe plans, deliveries, shared tools, infection assumptions, historical bridges and future relays.

| Part | Before | Now |
|---|---|---|
| Tutorial | General flow material without a precise carried learner state | Same point, IDs and BFS; one complete reconstructable residual-allocation operation |
| Concrete subject | Abstract capacities | Crate slots available during one planning interval |
| Key event | An allocation appears | A previous commitment is cancelled so both deliveries fit |
| Reflection | General network bottlenecks | Revision, irreversibility, the chosen interval and who waits |
| Room | Raised internal walls and four loosely related comparisons | Continuous floor, left context gallery, rear comparison, right learner bay |
| Wider sequence | Mainly abstract graph examples | Eleven declared contexts, each with an action and a boundary |

The first route allocates one unit. The next path reverses1→3, puts the first delivery through yard4 and allows the second through yard3. Total2 matches the limiting cut. The allocation is still a plan: this does not recall a departed shipment. In the independent learner edit, the destination link permits only one unit, and the same code obtains1.

The older forward-only push/relabel exhibit is retained. It stops with unresolved excess and explicitly does not establish a maximum. Its algorithm is unchanged. The learner's completed augmenting paths conserve flow at intermediate vertices; the difference between the two procedures is explained.

**{count} exact-source code checks and {native} native museum checks pass.** An independent min-cut oracle covers768 capacity configurations. The printed host, independent edit, three deliberate faults, pointer controls and synthetic XRTools are exercised. Each context has native before/after captures and an actual Try It interaction.

These examples keep the sequence focused: one required reconstruction per principle; other settings can illuminate or challenge it. Disease transmission is an extension with an explicit extra stochastic rule. Matching is a preview of the next lesson. None of the fictional people, animals, accounts or quantities are real-world measurements.

All images are rendered inside the museum. Gallery cases are installed in Flow, not separately added to all previous halls. The printed learner installation is temporary. Headset and independent-reader review remain open. Earlier rejected checks and captures are documented in technical.md.

**Next: Matching.** Two people need tools; the first acceptable pairing may need revision.
'''
write(O/'REPORT.md',report)
css=text(R/'tools/publish_graph_network.py').split("css='''",1)[1].split("'''",1)[0]
css+='\n.context-nav{display:flex;gap:.6rem;flex-wrap:wrap}.context-nav a{padding:.4rem .7rem;background:#eee8df;border-radius:4px}section{scroll-margin-top:2rem;margin:4rem 0} .boundary{border-left:3px solid #b37989;padding-left:1rem} .context-meta{max-width:75ch} .pair figure{margin:0} @media print{section{break-before:page}}'
def md(s):
 result=markdown.markdown(s,extensions=['fenced_code','tables']);source=iter(re.findall(r'```gdscript\n(.*?)\n```',s,re.S))
 return re.sub(r'<pre><code class="language-gdscript">.*?</code></pre>',lambda _: '<pre><code class="language-gdscript">'+html.escape(next(source)+'\n')+'</code></pre>',result,flags=re.S)
def page(title,body):
 return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+css+'</style></head><body><header><p class="eyebrow">Endless Museum · Graph Theory07 /08 ·10 October2026</p><nav><a href="index.html">Room and report</a><a href="worlds.html">11 concrete worlds</a><a href="parallel.html">Facing texts</a><a href="tutorial.html">Tutorial</a><a href="final.html">Reflection</a><a href="changes.html">Before / after</a><a href="graph-flow-review.zip">Review ZIP</a></nav></header>'+body+'<footer>Native museum captures. Author-operated reconstruction. Headset and independent reader review remain open.</footer></body></html>'
def fig(src,caption):return '<figure><img loading="lazy" width="1800" height="1200" src="'+src+'" alt="'+html.escape(caption,quote=True)+'"><figcaption>'+html.escape(caption)+'</figcaption></figure>'
for key in ['tutorial','final']:write(O/(key+'.html'),page(key,'<main><article>'+md(text(M/(key+'.md')))+'</article></main>'))
write(O/'parallel.html',page('Flow — facing texts','<main class="spread"><article><p class="eyebrow">Left · tutorial.md</p>'+md(text(M/'tutorial.md'))+'</article><article><p class="eyebrow">Right · final.md</p>'+md(text(M/'final.md'))+'</article></main>'))
changes='<main><h1>Before and after</h1>'
for key in ['tutorial','final']:changes+='<h2>'+key+'.md</h2><div class="pair"><article><p class="eyebrow">Previous draft</p>'+md(text(O/'before/commons/maps'/ID/(key+'.md')))+'</article><article><p class="eyebrow">Now</p>'+md(text(M/(key+'.md')))+'</article></div>'
write(O/'changes.html',page('Flow changes',changes+'</main>'))
body=f'<main><p class="eyebrow">The same point, a revisable plan</p><h1>Room for another</h1><p class="note">{count} code checks + {native} native museum checks passed. Hall7 of8.</p>'
body+='<div class="pair">'+fig('assets/student-first.png','First delivery uses yard3. Total1; the second depot has no unallocated forward path.')+fig('assets/student-revised.png','The pink step cancels an earlier commitment. Both deliveries now fit; total2.')+'</div>'
body+='<h2>Concrete worlds across the sequence</h2><p><a href="worlds.html">See all eleven native before/after comparisons →</a></p><div class="pair">'+fig('assets/context-ants-after.png','Ant trails: change the drawing while preserving its connections.')+fig('assets/context-contact-after.png','People and contacts: transmission requires an additional, explicitly declared rule.')+'</div>'
body+='<h2>Room arrangement</h2><div class="pair">'+fig('before-museum/above.png','Before: raised internal divisions and four comparisons.')+fig('assets/study-above.png','After: gallery left, older comparison rear right, temporary printed learner front right; clear central route.')+'</div>'
body+='<div class="pair">'+fig('before-museum/entry.png','Previous arrival.')+fig('assets/study-entry.png','Revised arrival with the learner installation.')+'</div>'
body+='<article>'+md(report)+'<p><a href="SUMMARY.md">Paragraph and short instruction</a> · <a href="WORLD-EXAMPLES.md">Contexts and sources</a> · <a href="checks.json">Code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="technical.md">Implementation and limits</a></p></article></main>'
write(O/'index.html',page('Flow — room for another',body))
body='<main><p class="eyebrow">People · animals · societies · history · possible futures</p><h1>What does this connection mean?</h1><p>Eleven working 3D companions, photographed inside Endless Museum. Select them at the Graph worlds table in Flow. Every setting names its nodes, edges, action and limits. The eight-hall order stays intact.</p><p><a href="WORLD-EXAMPLES.md">Editable guide and sources</a> · <a href="prefab/cases.json">Case labels</a> · <a href="parallel.html">Flow tutorial beside reflection</a></p><nav class="context-nav">'
for i,c in enumerate(cases):body+=f'<a href="#{c["id"]}">{i+1}. {html.escape(c["title"])}</a>'
body+='</nav>'
for i,c in enumerate(cases):
 meanings,change,why=descriptions[c['id']]
 body+=f'<section id="{c["id"]}"><p class="eyebrow">{i+1:02} · {html.escape(c["hall"])} · {html.escape(c["era"])}</p><h2>{html.escape(c["title"])}</h2><div class="pair">'
 body+=fig('assets/context-'+c['id']+'-before.png','Before: '+meanings)+fig('assets/context-'+c['id']+'-after.png','After: '+change)+'</div>'
 body+='<div class="context-meta">'+md('**Represented:** '+meanings+'\n\n**Try:** '+change+'\n\n'+why)+f'<p class="boundary">{html.escape(c["limit"])}</p>'
 if c['source']:body+='<p><a href="'+html.escape(c['source'],quote=True)+'">Contextual reading</a> · Schematic geometry and fictional data.</p>'
 body+='</div></section>'
body+='<article>'+md('## Keep the lineage\n\nPoint → connection → drawing → route → record → return → economical connection → capacity → pairing. A new setting should make the current operation easier to see. It does not require a new lesson for every object. Disease is an optional process on the graph; historical bridge-walking is an explicitly different question about edges. Future scenarios apply existing operations to declared assumptions.')+'</article></main>'
write(O/'worlds.html',page('Eleven concrete graph worlds',body))
write(O/'README.txt','Graph Theory hall7/8. index.html: native room/report; worlds.html: eleven native before/after contexts; parallel.html: tutorial left/reflection right. printed/: five complete scripts and one-node scene extracted from tutorial.md. Run inside AdaResearch Godot4.6 with existing museum/XRTools. Gallery permanently installed in Flow; previous halls not altered. Matching is a preview. variation/: final capacity1. fault-* deliberately incorrect. prefab/: gallery source (original project paths required). First-room-check retains rejected status-variable assertion. Current receipts fresh/completed. Physical headset and independent reader remain open.\n')
for name in ['graph_flow_student.gd','graph_flow_room.gd']:shutil.copyfile(R/'tools/probes'/name,O/'probes'/name)
for name in ['test_graph_flow.py','place_graph_flow.py','write_graph_flow.py','publish_graph_flow.py','start_graph_flow.py','build_graph_worlds.py','align_graph_flow_wall.py']:shutil.copyfile(R/'tools'/name,O/'probes'/name)
dump(O/'manifest.json',{'canonical':{n:sha(M/n) for n in ['tutorial.md','final.md','technical.md','map_data.json']},'printed':code['printed_hashes'],'prefab':{p.name:sha(p) for p in A.iterdir() if p.suffix in ['.gd','.json','.tscn']},'protected':{rel:sha(R/rel) for rel in protected},'checks':[count,native],'hall':ID,'contexts':len(cases),'physical_headset':False,'independent_reader':False})
archive=O/'graph-flow-review.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in O.rglob('*'):
  if not p.is_file() or p.suffix in ['.zip','.uid'] or p.name=='validation.json':continue
  if p.is_relative_to(O/'before') and p.name in ['em_plan.json','em_layout_walk.json','long_museum.json','plan.json','necklace_hand.json','trunk_branches.json']:continue
  data=p.read_bytes()
  if p.suffix=='.html':data=data.replace(b'href="graph-flow-review.zip"',b'href="README.txt"')
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
dump(O/'validation.json',{'passed':True,'local_links':links,'printed_files':len(blocks),'rendered_code_matches':True,'zip_crc':True,'zip_links':True,'size_mb':round(archive.stat().st_size/1e6,2),'checks':[count,native],'contexts':len(cases)})
print(json.dumps(read(O/'validation.json')))
