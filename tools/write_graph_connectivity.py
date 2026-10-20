from pathlib import Path
R=Path(__file__).resolve().parents[1];M=R/'commons/maps/GT_Connectivity';S=R/'doc/book/studies/graphs-through-the-hands/GT_Connectivity'
def code(name):return '<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf8').rstrip()+'\n```\n'
t='''# Connectivity — a way back

**Learning elements**

- Directed adjacency from records
- Reachability using the queue we already built
- Reversing arrows without changing the ledger
- Set intersection and a strongly connected component

Our point already belongs to a graph. In Network Analysis we counted incoming and outgoing records. Now follow them: from point 4 you can reach 5, but the seven records provide no way back.

In the museum, inspect the two rings of the Tarjan exhibit. Each ring contains return routes; the arrow between them goes only one way. The larger procedure colours its completed components. Our smaller reconstruction will find the group containing one chosen start by using familiar traversal twice.

**Carry:** the same seven IDs, PointBody, traversal, route and ledger. **New:** directed adjacency and two reachability sets. **Supplied:** the previous display, controls, museum, player and XRTools. We will not reconstruct Tarjan's low-link procedure here.

## Keep the earlier object

Copy the Network Analysis lesson folder as `GT_Connectivity`. Rename its `study.gd` to `network_study.gd`; keep `point_body.gd`, `traversal.gd`, `route.gd` and `ledger.gd` unchanged. Create the two files printed below. The inherited host creates the point, lamps, arrow cylinders, labels and buttons. Our new host changes their behaviour; it does not create another player or camera.

Create a Node3D scene named `study.tscn`, attach the new `study.gd`, and instance it under this museum hall's root. Place it in the clear left bay. For the current hall root, use position `(3.5, -0.25, 9.5)`, rotation Y `180°`, scale `(1,1,1)`; this corresponds to map-local `(3.5, -0.25, 5.5)`. Run the existing museum. Remove the previous temporary learner instance if it is still installed.

## Follow, then reverse

Save this as `reachability.gd`.

'''+code('reachability.gd')+'''
The seven earlier records are unchanged. `_init()` adds an eighth, invented report: **5 reports to 1**. It starts omitted. Including it is an explicit change to our model, not a discovery about the people imagined in the previous hall. Following mixed payment and report records is a graph exercise; it does not prove that money, a person or a message can physically travel that route.

`directed(false)` makes one fresh neighbour list for each ID, then places each destination in its source's list. It reads only active records, so the earlier omission and filter rules still apply. It never adds a reverse neighbour automatically. Duplicate events between the same endpoints need only one entry for reachability, although the earlier counting lesson counted every event.

`directed(true)` swaps source and destination **in these temporary lists**. It does not rewrite a record. If the reversed search can get from 4 to 0, the original graph can get from 0 to 4.

`reachable()` reuses our first hall's queue traversal. We replace its default neighbours with the directed lists and its default starting entry with the selected ID. Each call creates a fresh walker, so an earlier visit cannot make the next search skip a vertex. The `while` loop stops when `next_visit()` returns `-1`. The returned array records visited IDs, not a continuous walk or a shortest route.

The starting vertex is reachable from itself by a path of zero edges. An isolated vertex therefore forms a one-vertex strongly connected component. “No cycle” does not mean “no component.”

`component()` keeps the IDs found in **both** searches. For each retained vertex, the start can reach it and it can reach the start. Any two retained vertices can consequently reach each other through the start. Every vertex satisfying both conditions is included: this is the maximal strongly connected group containing that start. We find one component, not an entire partition in one pass.

## Predict the return

Keep START at 4 and all kinds included. Compare membership, not traversal order:

| Records | OUT: reachable from 4 | BACK: can reach 4 | BOTH: component |
| --- | --- | --- | --- |
| Original seven | 4, 5 | 0, 1, 4 | 4 |
| Include R04, 5→1 | 1, 3, 4, 5 | 0, 1, 2, 4, 5 | 1, 4, 5 |

With the return included, 3 is reachable but cannot return. Vertices 0 and 2 can enter the group but cannot be reached from it. Vertex 6 does neither. A vertex's incoming/outgoing counts alone cannot tell you these routes.

## Put the question in the hand

Save this as the new `study.gd`.

'''+code('study.gd')+'''
`extends "network_study.gd"` retains the previous construction. `super._ready()` builds it once; the new ledger is assigned before that construction begins. `super.redraw()` still places the arrows. We then replace the count labels with OUT, BACK, BOTH or neither, using colour as a second cue. The point remains black and pickable; its label identifies the selected start.

The inherited point signal is reconnected to `toggle_record()`. **Hold the point and press its trigger to include or omit the return.** Moving your hand changes the selected vertex's drawing position, not its connections. Let go before selecting another start, changing layout or resetting.

- **START / 1:** cycle through the seven starting IDs; the same point marks the selection.
- **RETURN / 2 / held trigger:** include or omit R04; its arrow appears or disappears.
- **LAYOUT / 3:** move the drawing without changing the component.
- **RESET / R:** return to start 4, the original drawing and R04 omitted.

The inherited method name `cycle_filter()` is overridden for START. This host no longer cycles kinds from a control; the ledger still supports filters for later reuse. The old route finder also remains in the carried files, but these searches use newly derived directed adjacency. They do not call that undirected route finder.

Include the return. Select 1, 4 and 5 in turn: each gives `[1, 4, 5]`. Then select 3. It stands alone even though an arrow reaches it from that group. Rearranging the drawing changes none of those answers.

## Make a different return

In `reachability.gd`, change R04's destination from **1 to 2**, and change its source sentence to **“R04: 5 reports to 2.”** Keep the other seven records and the start at 4. Before running, predict the result.

With the new return included, the component containing 4 is still `[4]`: 4 reaches 5 and 2, but they cannot get back to 4. Select 2 or 5 and the component is `[2, 5]`. Check the arrow's new endpoint as well as the labels. You have made a cycle, but it is not a return for every starting point.

Carry this distinction onward. Strong connectivity asks whether directed journeys exist in both directions. The next hall's spanning tree asks a different question about keeping an undirected network connected while selecting edges. It must declare that change of model; it cannot silently treat these event arrows as two-way roads.

## Complete carried files

These are unchanged from Network Analysis, with its host renamed `network_study.gd`. They are printed for reconstruction; the lesson's new work is in the two files above.

'''
for name in ['ledger.gd','network_study.gd','route.gd','traversal.gd','point_body.gd']:
 t+=f'<details>\n<summary>{name} — carried unchanged</summary>\n\n'+code(name)+'\n</details>\n\n'
(M/'tutorial.md').write_text(t,encoding='utf8')
(M/'final.md').write_text('''# A way back

Two rings hang beside the passage. Follow the arrow that leaves one for the other. Getting across is easy to imagine. Now try to return.

<!-- @tarjan_algorithm -->

The drawing has joined them. The direction has kept them apart.

Watch the traversal finish. Each ring receives a colour. Within either group, every vertex can reach every other by following the arrows. The crossing between them remains one-way. A strongly connected component names this mutual reachability; it does not name a community, an agreement or a place where anybody belongs.

In the smaller graph, carry the point we have followed through these rooms. Moving it changes the length of a line. Adding a return changes who can reach whom. A short arrow can do more to the relation than a large movement of the drawing.

Press RETURN. Three vertices now share a group. A fourth can be reached from them and still cannot come back. The new opening has consequences beyond its endpoints, but those consequences stop somewhere. Follow them far enough to find where.

There is a temptation to let the word “connected” do all the work. We have a contact. We have a link. We can get there. Each sentence can be true while leaving another question unanswered. Can a reply pass? Can you leave by the way you came? Does the route remain available when you need it?

The algorithm answers one exact part: a directed path exists in each direction. It has no duration, fare, fatigue or opening hours to consider. A long, fragile return counts here as fully as a short one. The colour is correct within the question we gave it. We still have to decide whether that question is enough.

Move the point again. The group keeps its colour. For a moment, the relation survives a change of place. Then omit the return and watch the same bodies cease to belong to the same strongly connected group. They have not disappeared. Something they could do together has become unavailable.

<!-- @ -->

In the next hall, a tree will keep an undirected network connected while leaving out cycles. We will be asked to value a different arrangement. Remember what this return made possible before calling an extra connection unnecessary.
''',encoding='utf8')
print('Connectivity texts written: two new scripts, five carried scripts.')
