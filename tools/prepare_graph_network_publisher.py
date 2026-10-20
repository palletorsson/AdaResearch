"""Prepare a standalone publisher from the preceding hall's review template."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
s=(R/'tools/publish_graph_pathfinding.py').read_text(encoding='utf8')
s=s.replace("ID='GT_Pathfinding'","ID='GT_Network_Analysis'").replace('2026-10-10-pathfinding-a-route-kept','2026-10-10-network-a-record-counted').replace("'path-final'","'network-final'").replace("'path-before'","'network-before'").replace('graphtheory|gt pathfinding','graphtheory|gt network analysis')
s=s.replace('graph-pathfinding-review.zip','graph-network-review.zip').replace('graph_pathfinding','graph_network').replace('Graph Theory 03 / 08','Graph Theory 04 / 08').replace('tile_w=13,tile_h=14','tile_w=23,tile_h=34').replace('assert len(blocks)==4','assert len(blocks)==5')
a=s.index('protected=');b=s.index('plans=read',a)
s=s[:a]+'''protected=['commons/maps/sequences/graphtheory.json','commons/artifacts/spine_studies/evidence_network.gd','commons/artifacts/spine_studies/network.tscn','commons/artifacts/spine_studies/station.gd','algorithms/graphtheory/network_analysis/NetworkAnalysis.gd','ada_run/necklace_hand.json']
for rel in protected:assert (R/rel).read_bytes()==(O/'before'/rel).read_bytes(),rel
for name in ['point_body.gd','traversal.gd','route.gd']:assert (S/name).read_bytes()==(S.parent/'GT_Pathfinding'/name).read_bytes()
'''+s[b:]
a=s.index('technical=f');b=s.index("write(M/'technical.md'",a)
s=s[:a]+'''technical=f"""# Network Analysis — implementation and verification

The installed evidence_network.gd contains eight named institutions and twelve fictional source records. The existing station.gd exposes LAYOUT, FILTER, RECORD, NODE and RESET through museum pointer buttons. Incoming and outgoing counts read the currently filtered records. Layout changes positions only. These are event counts; amounts occur in prose, not an amount-summing algorithm. The full ledger has four payment records, three grants and five reports. Builder has two incoming payments and one outgoing report. All production source files and the graph sequence remain unchanged.

The earlier front room was a narrow platform network over void with three overlapping exhibits: rhizomatic_structure, network_analysis and networkflow3d. These have been removed from this hall's placement, not deleted from the catalogue. NetworkAnalysis.gd assigns its centrality values from tiers and its summary values from a clock; it is not an implementation of the metrics the previous tutorial claimed to teach. The revised lesson concentrates on the existing inspectable record wall. It does not claim to implement Brandes, eigenvector centrality or A*.

The learner carries point_body.gd, traversal.gd and route.gd byte-for-byte from Pathfinding. Same seven IDs, initial positions and seven undirected endpoint pairs. New ledger.gd adds one explicitly fictional directed event for each pair; source, destination and kind are authored choices, not inferred from the undirected graph. The inherited adjacency remains an undirected scaffold; the inherited route search is not used as a directed record search. counts reads only active record indices, returns incoming/outgoing in Vector2i, treats parallel events separately, and counts a self-addressed record once each way. No normalisation by vertex count is appropriate for these event counts. The next hall must explicitly build directed adjacency from this ledger.

The complete host draws seven marker spheres with count labels, cylinders and arrowheads. The carried pickable point now marks vertex4, the source of P04. While held, its world position is converted into local XY and the projection updates the drawing, without changing records. Release returns it to the plane. Inherited trigger or1 cycles filters;2 omits/restores P04;3 changes layout;R resets. Four nearby pointer controls provide the same actions. Layout/reset wait during holding. P04's source and counted/omitted status remain visible. Coincident endpoints hide a zero-length arrow while retaining the event and counts. The tests cover this distinction.

Five exact printed scripts are extracted fresh and executed in Godot4.6. {count} code checks pass: independent endpoint tables; all384 combinations of128 omitted-record masks and three filters; total incoming and outgoing each equal active event count; source/scaffold immutability; empty filter, self-addressed and parallel-event cases; cylinder and arrow direction; keyboard echo and actual pointer-event dispatch; transformed-host synthetic XRTools hold/trigger/release. The independent P04 reversal runs as a separate edited study, producing changed counts and a reversed arrow with matching source. Three deliberately faulty models are caught: direction confusion, ignoring the filter and ignoring omission.

The first reconstruction failed because its nested Button class name shadowed Godot's native Button. It was renamed RecordButton, the tutorial regenerated, and the exact code rerun. The failed log is retained. The first native image also exposed the source sentence behind the controls; it now sits in front of them. Both code and museum were rerun after this display correction.

The museum keeps its23x34 footprint, original entry at x5–7 and exit at x10–12. The floor is continuous. The full-size record station is at cell(17,20),yaw270, so its15m wall lies along the right side rather than cutting across the journey. The learner bay is map-local(4.5,-0.25,6.5),yaw180,scale1; isolated hall-root(4.5,-0.25,10.5). The learner is temporarily installed for checks/captures, with explicit instructions for student installation, not registered as a permanent extra exhibit. The original hand stamp is retained on disk.

All {native} native checks pass: real installed wall, its pointer controls and source display, reset,71 floor/body-clearance samples along the left aisle and turn to the rear exit, both approaches, exact printed learner, inherited XRTools pickup/trigger/release and count invariance under hand movement. Native above, arrival, wall and learner comparison images are included. Counts include the capture and completion assertions listed in the receipt.

These are author-operated ghost reconstruction checks, not independent-reader or physical-headset acceptance. Quest performance, comfort and continuous portal traversal remain unverified. Existing UID/Jolt warnings are retained; final logs contain no script/parse errors.

Reproduce code: python tools/test_graph_network.py

Reproduce museum: python tools/run_encounter_probe.py GT_Network_Analysis --sequence graphtheory --render --no-bridges --output-tag network-final --probe tools/probes/graph_network_room.gd
"""
'''+s[b:]
a=s.index('row.update(object=');b=s.index('previous=next',a)
s=s[:a]+'''row.update(object='The carried PointBody marks vertex4 on the same seven-ID scaffold; a new fictional directed ledger makes each count inspectable.',change='Count selected incoming and outgoing event records. Omit P04, filter by kind, move vertex4 and rearrange the drawing while keeping provenance and IDs.',dependsOn=['GT_Pathfinding','GT_Layout'],reuses='Unchanged PointBody, traversal.gd and route.gd; stable IDs, seven endpoint pairs, dictionaries, arrays, filters, local/world conversion and cylinder geometry.',given='Existing Endless Museum and XRTools; installed eight-institution record wall; complete small display/input host. Directed roles and record kinds are explicit new authored data.',later='Do not teach centrality surveys here. Inherited adjacency remains undirected; Connectivity must derive directed adjacency from records before asking about return paths.',checks=[f'{count} exact-source code checks;384 filter/omission combinations; independent reversal rendered; three faulty variants caught.',f'{native} native museum checks;71 aisle/exit-turn samples; actual wall buttons and synthetic XRTools. No physical headset or independent-reader claim.'],transfer='Reverse P04 from4→5 to5→4 and update its source. Predict vertex4 becomes2in/0out and vertex5 becomes1in/1out in ALL; seven records remain and the arrow reverses. Moving the point must not change these counts.',carry='A measured incoming/outgoing count refers to selected directed records, not apparent prominence. Filtering, omission, reversal and layout are different operations.',next='GT_Connectivity: derive directed adjacency from this ledger, then test which vertices can reach one another and return.',notes='10 October: fourth hall only. Complete runnable ledger and host; reflective text stays with selection, provenance and the limits of counts. Existing record-wall code unchanged; other three exhibits retained in catalogue but removed from this hall placement. Review decision retained.',summary='Follow an arrow into its fictional source on the museum record wall, then continue our seven IDs and the same pickable point. Author one directed event for each existing endpoint pair and count incoming and outgoing active records. Omit P04 and predict the two affected counts; filter to reports and explain why omitting that payment has no further effect. Hold the point to move vertex4 without changing the ledger. Independently reverse P04, update its source and test the new counts and arrow. Carry a directed record set into Connectivity, where a count alone cannot promise a return journey.')
'''+s[b:]
a=s.index("write(O/'SUMMARY.md'");b=s.index("css='''",a)
s=s[:a]+'''write(O/'SUMMARY.md','# Network Analysis — lesson paragraph\\n\\n'+row['summary']+'\\n\\nShort instruction: Museum given. Carry PointBody + seven IDs + undirected scaffold. Author directed ledger, one event/pair; direction≠old adjacency. Count in/out over active records. Omit P04; filter reports; predict invariants. Hold4→localXY drawing only. Reverse P04 + source; test endpoints/arrow. Preserve ledger. Next: derive directed adjacency, test return paths.\\n')
report=f"""# What does this count keep?

Graph Theory hall4 of8 continues the same point and seven vertex IDs. Pathfinding found a journey. Network Analysis now makes one measure explicit: incoming and outgoing records under a chosen filter.

| Part | Before | Now |
| --- | --- | --- |
| Tutorial | A broad centrality survey with undeclared helpers, followed by an appended record exercise | One coherent reconstruction: directed records, counts, filtering, omission and layout invariance |
| Lineage | New Graph helpers with no runnable host | Three unchanged carried files; one new ledger and a complete display/input host |
| Reflection | Long explanation of an ornamental network, then a second encounter | Stay with the source wall: what does a count preserve, select or leave unknown? |
| Museum | Narrow platforms and voids with overlapping network scenes | Continuous floor; existing record wall faces the open room; learner bay at the entrance |
| Independent task | General parameter changes | Reverse one payment and its source, predict the two count changes, inspect the reversed arrow |

The seven previous undirected pairs are retained as a scaffold. The new event directions are explicitly authored; they cannot be inferred from those pairs or from their positions. The same point marks vertex4. Moving it changes the drawing, while its trigger changes which record kinds are counted. Nearby pointer controls omit/restore P04, switch layout and reset.

With all records active, vertex4 has1 incoming and1 outgoing event; vertex5 has2 incoming and0 outgoing. Omitting P04 (4 pays5) reduces4's outgoing and5's incoming by one. Filtering to reports already excludes that payment, so omitting it then changes no count. Reversing it changes endpoint roles without reducing the number of events.

The large museum wall retains its existing eight institutions, twelve records and controls. The learner uses the seven IDs we already built. Its smaller dataset teaches the same operation without pretending it is the same dataset. Counts refer to events, not payment amounts, unique neighbours or importance.

**{count} code checks and {native} native museum checks pass.** The code suite compares384 filter/omission states with independent endpoint tables, runs the student's reversed-record exercise and rejects three faulty counting models. The room suite exercises actual pointer controls, source readouts and synthetic XRTools pickup/trigger/release. It checks71 floor/body-clearance samples along the open aisle and turn to the existing exit.

The source sentence was obscured by the controls in the first capture. It now sits in front of them; the printed code and museum checks were rerun. All final pictures are native Godot captures. The learner installation is temporary in these captures and explicitly described in the tutorial. The permanent record-wall implementation and graph sequence order are unchanged.

This is an author-operated ghost-student reconstruction. Independent reading, physical headset use, Quest performance, comfort and continuous portal traversal are still separate checks.

**Next: Connectivity.** One incoming and one outgoing count do not promise a way back. The next lesson will derive directed adjacency from these records and follow return paths.
"""
write(O/'REPORT.md',report)
'''+s[b:]
s=s.replace('Pathfinding — facing texts','Network Analysis — facing texts').replace('Pathfinding changes','Network Analysis changes')
a=s.index("body='<main><p class=",s.index("write(O/'changes.html'"));b=s.index("for name in ['graph_network_student.gd'",a)
s=s[:a]+'''body='<main><p class="eyebrow">The same point, an inspectable count</p><h1>What does<br>this count keep?</h1><p class="note">'+str(count)+' code checks + '+str(native)+' native museum checks passed. Hall4 of8.</p>'
body+=fig('assets/student-before.png','Seven familiar vertices, now with explicitly authored directions. The black point marks4; every count refers to active source records.')
body+='<div class="pair">'+fig('assets/student-omitted.png','Omit P04:4 loses one outgoing record and5 loses one incoming record.')+fig('assets/student-moved.png','Move4 and choose payments with the point trigger. Geometry and filtering are separate operations.')+'</div>'
body+='<h2>The existing record wall</h2><div class="pair">'+fig('assets/record-wall.png','Eight fictional institutions and twelve inspectable records, unchanged from the existing museum exhibit.')+fig('assets/record-wall-filter.png','Payment filter and another layout. The highlighted source and selected institution remain explicit.')+'</div>'
body+='<h2>Room arrangement</h2><div class="pair">'+fig('before-museum/above.png','Before: narrow platform paths, voids and overlapping network scenes.')+fig('assets/study-above.png','After: continuous floor, record wall along the right side, learner bay near the entrance and open circulation.')+'</div>'
body+='<div class="pair">'+fig('before-museum/entry.png','The previous arrival interrupted by a raised hub and several large diagrams.')+fig('assets/entry.png','The revised arrival opens onto the hall.')+'</div>'
body+='<article>'+md(report)+'<p><a href="SUMMARY.md">Paragraph and short instruction</a> · <a href="checks.json">Code receipt</a> · <a href="museum/report.json">Museum receipt</a> · <a href="technical.md">Implementation and limits</a></p></article></main>'
write(O/'index.html',page('Network Analysis — a record counted',body))
write(O/'README.txt','Graph Theory hall4/8. Open index.html for native images/report, parallel.html for tutorial left and reflection right. printed/ has five exact scripts and one-node study.tscn. Use inside AdaResearch Godot4.6 with existing XRTools and museum; not a standalone export. PointBody, traversal and route are unchanged from Pathfinding. variation/ reverses P04; fault-* folders are deliberately wrong. first-name-conflict.log records the rejected initial parse failure. Current checks.json and museum/report.json are successful fresh receipts. Physical headset and independent-reader review remain open.\\n')
'''+s[b:]
# Require every printed block to survive HTML rendering, including details sections.
needle="with zipfile.ZipFile(archive) as z:\n assert z.testzip() is None"
s=s.replace(needle,"for name in ['tutorial.html','parallel.html']:\n found=re.findall(r'<pre><code class=\"language-gdscript\">(.*?)</code></pre>',text(O/name),re.S)\n assert [html.unescape(v) for v in found]==[source+'\\n' for _,source in blocks]\n"+needle)
for old,new in {'hall4 of8':'hall 4 of 8','Hall4 of8':'Hall 4 of 8','hall4/8':'hall 4/8','vertex4':'vertex 4','vertex5':'vertex 5','has1':'has 1','and1':'and 1','has2':'has 2','and0':'and 0','from4':'from 4','to5':'to 5','pays5':'pays 5','compares384':'compares 384','all384':'all 384','of128':'of 128','checks71':'checks 71','reset,71':'reset, 71','Godot4.6':'Godot 4.6','its23x34':'its 23x34','its15m':'its 15m','its trigger or1':'its trigger or 1'}.items():s=s.replace(old,new)
(R/'tools/publish_graph_network.py').write_text(s,encoding='utf8')
print('Standalone Network Analysis publisher prepared.')
