from pathlib import Path
R=Path(__file__).resolve().parents[1];M=R/'commons/maps/GT_Network_Analysis';S=R/'doc/book/studies/graphs-through-the-hands/GT_Network_Analysis'
def block(name):return '<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf8').rstrip()+'\n```\n'
t='''# Network Analysis — count a recorded relation

## Learning elements

- Directed records: source, destination, kind and provenance
- Incoming and outgoing counts
- Filtering and omission as different operations
- A measure that stays unchanged when the drawing moves

## Begin with the record wall

In the museum, find **A relation needs a record**. Use RECORD to follow a highlighted arrow into its written source. Use NODE to choose whose incoming and outgoing records are counted. FILTER changes which kinds count; LAYOUT moves the drawing. These are invented institutional records, not evidence about actual people.

In Pathfinding we asked for one journey. Here we ask a smaller question of every vertex: **how many of the selected records enter it, and how many leave it?** We will implement this count before making claims about importance.

Carry our seven IDs and the same point. Keep `point_body.gd`, `traversal.gd` and `route.gd` unchanged. Their seven undirected connections, including the last hall's extra 4–5 edge, remain our underlying scaffold. Add `ledger.gd` and replace the host with the complete `study.gd` below. Save all five scripts together; attach the host to one empty Node3D, or use the supplied one-node `study.tscn`. The existing Endless Museum supplies camera, lights, player and XRTools.

Place this study in the front-left learner bay at **map-local (4.5, -0.25, 6.5), Y rotation 180 degrees, scale 1**. In the isolated hall the equivalent root-local position is (4.5, -0.25, 10.5). The large record wall is already installed farther along the right wall.

## Give a connection a direction and a source

Previously, the edge 4–5 permitted travel both ways. That tells us nothing about who paid whom. We now author **one fictional directed record for each existing pair**. The direction and kind are new choices; neither the previous adjacency nor the positions can supply them.

Each dictionary names `from`, `to`, `kind` and `source`. P04 says that 4 pays 5. It counts once as outgoing at 4 and once as incoming at 5. It does not also record a payment in the other direction. The source string makes our claim inspectable; writing it does not establish that an event occurred.

'''+block('ledger.gd')+'''
`active_records()` returns indices into the full ledger. Filtering to payments keeps the reports in storage but leaves them outside this question. `omitted` can additionally exclude a particular record. Neither action renumbers the remaining entries or destroys the original list.

`counts()` reads only those active records. In its returned `Vector2i`, `x` means incoming and `y` means outgoing. These are two integer counters, not spatial coordinates. The two independent `if` statements matter: a self-addressed event would count in both directions. Two separate events between the same endpoints would each count. This is a count of recorded events, not unique neighbours, money, influence or trust.

The inherited `neighbours` still describes our **undirected scaffold**. This count does not use it, and the inherited route finder would not answer a directed question about the ledger. We preserve that distinction until Connectivity builds a directed adjacency from these records.

## Predict the effect before changing the view

Start with ALL and all seven records present.

| View | Vertex 4: in / out | Vertex 5: in / out |
| --- | --- | --- |
| All records | 1 / 1 | 2 / 0 |
| All, omitting P04 | 1 / 0 | 1 / 0 |
| Payments | 1 / 1 | 1 / 0 |
| Reports | 0 / 0 | 1 / 0 |

In the reports view, omitting P04 cannot change the counts: that payment was already outside the filter. Switching back to all records makes its omission visible again. Layout should change none of these answers.

## Keep the drawing answerable to the records

The same black point now marks vertex 4, the source of P04. Hold it and move that vertex in the drawing plane, as we did in Layout. The blue marker shows the projected position. Cylinders and arrowheads follow their recorded endpoints; every label shows its incoming and outgoing count. Release returns the black point to the plane.

Trigger or **1** cycles ALL → PAYMENTS → REPORTS. **2** omits or restores P04. **3** changes the arrangement. **R** resets. The nearby pointer buttons provide the same actions in VR. Release the point before LAYOUT or RESET; those two controls deliberately wait while it is held.

The host supplies the display and input wiring in full. The new counting operation is in the shorter ledger above.

'''+block('study.gd')+'''
Moving a marker cannot create or remove a record. Even if two markers coincide, their counts remain distinct. The host hides a zero-length arrow because it has no drawable direction; the record remains counted. Its label and ledger still identify what the picture can no longer separate.

## Make one independent change

Edit P04 to say **5 pays 4**: change its `from` to 5, its `to` to 4 and its source sentence to match. Leave every other record unchanged. In ALL, predict that vertex 4 changes from **1 in / 1 out** to **2 in / 0 out**, while vertex 5 changes from **2 in / 0 out** to **1 in / 1 out**. The arrow reverses and the total number of records stays seven. Then move the point: the new counts must remain.

Explain why deleting P04, reversing it and moving its endpoints are three different edits. Restore the original record before continuing.

## Carried files — unchanged

These complete files make the reconstruction runnable. They are the previous hall's work, not new operations to learn here.

<details>
<summary>PointBody: the same pickable sphere</summary>

'''+block('point_body.gd')+'''
</details>

<details>
<summary>Traversal and route: the retained undirected scaffold</summary>

'''+block('traversal.gd')+'\n'+block('route.gd')+'''
</details>

## What travels onward

Keep the point, stable IDs and directed ledger. The museum wall has eight named institutions and twelve records; our reconstruction deliberately uses the seven vertices we already built. Both make a count traceable to selected source records.

Incoming and outgoing counts do not establish whether a journey can return. In Connectivity, we will follow the directed records and ask where mutual reachability begins and ends.
'''
(M/'tutorial.md').write_text(t,encoding='utf8')
(M/'final.md').write_text('''# Important by which measure?

A fine curve joins the Studio to the Builder. Follow its arrow, then select RECORD.

<!-- @evidence_network -->

A date and a payment appear beneath the drawing. The line says which way the payment went. It says nothing about whether the work was done, whether the price was fair, or who waited to be paid.

Choose the Builder with NODE. Two payments arrive. For this question, each is one incoming record. Their amounts differ. The count has kept the events and set their amounts aside. We can check its answer without accepting it as an account of everything that matters.

Change LAYOUT. The Archive moves without receiving another report. A place near the centre can catch your attention before any new relation justifies it. Watch the count remain still while the drawing moves around it.

Now select PAYMENTS. Several arrows disappear. The institutions have not ceased to report to one another; those records remain in the ledger. We have narrowed the question. A clean diagram can make this act of selection easy to forget.

There is a difference between leaving a record outside a view and deciding that it should no longer count at all. There is another difference between either of those decisions and the absence of a record for something that happened. The display can show its own omissions. It cannot reveal an event nobody put into it.

This archive is openly fictional. Each arrow leads to a sentence we wrote. That makes the construction inspectable, but gives it no authority over an actual person. The little date beneath a line can look reassuring; it, too, was made.

Stay with one relation long enough to name what it claims. Then name what the measure counts. “Important” can wait until we have said important to whom, and for which question.

<!-- @ -->

One incoming arrow and one outgoing arrow still do not promise a way back. In the next hall, follow a directed journey and see whether it can return.
''',encoding='utf8')
print('Network Analysis two tracks written; five exact source blocks.')
