from pathlib import Path
R=Path(__file__).resolve().parents[1];M=R/'commons/maps/GT_Spanning_Trees';S=R/'doc/book/studies/graphs-through-the-hands/GT_Spanning_Trees'
def code(name):return '<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf8').rstrip()+'\n```\n'
t='''# Spanning Trees — the cost of a spare

**Learning elements**

- Undirected links and explicit weights
- Sorting edge indices by cost
- Reusing reachability to reject a cycle
- A minimum spanning tree and a disconnected forest
- A spare route under a different objective

In Connectivity, our point asked whether a directed journey could return. Now we give the same seven vertices a different job: connect them with undirected links at minimum total build cost.

This is a **new model**. Its endpoint pairs recall our earlier graph, including the last hall's extra 1–5 pair. Each link can now be followed in either direction. Its weight is a cost we assign, not a payment record, a direction or the length of the drawing. Keep the earlier ledger in its own lesson folder.

**Carry:** the same PointBody, vertex IDs, initial positions and queue traversal. **New:** a weighted edge list and a rule for selecting edges. **Supplied:** the museum, XRTools and the complete drawing/input host below. Union-find, Prim and other implementations can wait.

## Look at the existing construction

The museum's larger graph uses ten vertices and distance-based weights calculated from its own generated positions. Its Kruskal procedure considers low-weight edges first. Green overlays mark accepted edges. A considered edge underneath stays yellow; a rejected edge is not painted red, and some grey edges are never considered because the procedure stops after nine acceptances. The wall film presents the same seeded graph as a comparison.

We will reconstruct the selection with seven familiar vertices and deliberately assigned costs. Our small scan continues through all eight links so that both refusals can be inspected. That difference is intentional.

## Reuse a search to decide

Create a `GT_Spanning_Trees` folder beside the earlier lessons. Copy `point_body.gd` and `traversal.gd` unchanged from Connectivity. Save this new file as `tree_model.gd`.

'''+code('tree_model.gd')+'''
Each dictionary holds two endpoints and a cost. `reset()` sorts **indices** into the link array, leaving its order and IDs intact. If two costs tie, the earlier index goes first. Another tie order can choose another tree with the same minimum total.

`reachable()` is our queue traversal again. This time it builds neighbours only from the selected links, adding each connection in **both** directions. That is the new undirected contract. It starts a fresh search, so visited state never leaks from an earlier question.

`step()` considers the next cheapest link. If its second endpoint can already be reached from its first using selected edges, another connection between them would complete a cycle. Refuse it. Otherwise, join the two separate groups.

This is Kruskal's selection rule with repeated reachability checks in place of union-find. It is suitable for our small graph. Sorting gives the cheapest remaining candidates; the cycle check prevents paying for a connection within a group already joined. For a connected undirected graph this rule yields a minimum-total-weight spanning tree. On a disconnected input it yields a minimum spanning forest; it cannot invent missing links.

`spans()` checks that our acyclic selection reaches all seven vertices with six edges. It does **not** prove minimum cost. A valid tree can be expensive. Our separate test enumerates every six-edge subset of this small graph and compares the costs of those that span. That checks the implementation on this data; it is not a proof for every possible graph.

## Predict eight decisions

All weights are fixed even when you move the point.

| Step | Link | Cost | Decision |
| --- | --- | --- | --- |
| 1 | 1–3 | 1 | Join |
| 2 | 0–2 | 2 | Join |
| 3 | 1–4 | 3 | Join |
| 4 | 0–1 | 4 | Join |
| 5 | 2–6 | 5 | Join |
| 6 | 2–5 | 6 | Join: all seven now connected |
| 7 | 4–5 | 7 | Refuse: 4–1–0–2–5 already exists |
| 8 | 1–5 | 8 | Refuse: 1–0–2–5 already exists |

The chosen cost is **21**. Six edges connect seven vertices. The direct 4–5 link is unused, even though keeping it would shorten that particular trip in number of links. Minimum construction cost and shortest individual journey are different objectives.

## Keep the point in the museum

Create a Node3D scene named `study.tscn`, attach the complete `study.gd` below, and instance it under this hall's root. Use hall-root position `(4.0, -0.25, 10.0)`, Y rotation `180°`, scale `(1,1,1)`; this is map-local `(4.0, -0.25, 6.0)` in the left learner bay. Run the existing museum. Remove the previous temporary learner instance if it remains installed.

The host reuses our point construction and the same positions. It creates undirected cylinders, cost/state labels and nearby controls. The former ledger host is left in its own folder; it is not turned into a fictitious source of weighted links.

- **STEP / 1 / point trigger:** consider one link. Hold the point at vertex 4 while stepping if you like.
- **BREAK 0–1 / 2:** after all eight decisions, disable that selected connection.
- **SPARE 4–5 / 3:** after the scan, include the previously refused connection.
- **RESET / R:** release the point first, then restart the scan and drawing.

Mint links are selected; pink links were refused; grey links are waiting. Gold marks the added spare. Words accompany the colours. The lamps report which vertices remain reachable from 0 through **active** links. A broken connection loses its cylinder and keeps its “broken” label.

<details open>
<summary>study.gd — complete drawing and interaction host</summary>

'''+code('study.gd')+'''
</details>

`active_links()` copies the selected list, optionally adds the spare, then removes the failed link. It does not rerun Kruskal or modify the original costs. We are testing the selected design under failure. The displayed chosen cost still includes the failed connection's original build cost; it is not a bill for currently working links.

Complete the scan, then break 0–1. Vertices 1, 3 and 4 become unreachable from 0; only 0, 2, 5 and 6 stay on its side. Add the spare 4–5: all seven reconnect through a different route. Restore 0–1 as well and you now have a cycle. The added connection costs 7, making the chosen design plus spare cost 28.

One spare does not protect every connection. If 1–3 fails, vertex 3 is still cut off. The spare protects the cycle it creates, not the whole network against any failure.

## Change the cost, not the rule

In `tree_model.gd`, change the 4–5 cost from **7.0 to 0.5**. Before running, predict what enters the tree and what leaves it.

The new tree keeps 4–5 and refuses 2–5. Its total is **15.5**. The algorithm is unchanged; the declared costs changed its answer. Check the cost label as well as the selected links. In this edited version, SPARE 4–5 adds nothing because that link is already selected. Break 0–1 and that button cannot supply a second copy as an alternate route.

Carry the distinction onward: a route can be selected, available and reachable without being able to carry everything sent through it. Flow will introduce capacity as another quantity, distinct from this build cost.

## Complete carried files

'''
for name in ['traversal.gd','point_body.gd']:
 t+=f'<details>\n<summary>{name} — carried unchanged</summary>\n\n'+code(name)+'\n</details>\n\n'
(M/'tutorial.md').write_text(t,encoding='utf8')
(M/'final.md').write_text('''# The price of one more route

A line turns yellow. A green connection appears over it. The next choice waits.

<!-- @mst_visualization -->

Before the display decides, follow the connections already kept. Can they carry you between the candidate's two ends? If they can, the new line would close a cycle. For the task we gave this procedure, that is a reason to leave it out.

The task is exact: connect every vertex at minimum total weight. Here those weights were calculated from distances in the generated drawing. They do not include the effort of a particular journey or the cost of losing a connection tomorrow.

Nine chosen edges keep ten vertices connected. The picture still contains other lines. Some were considered and refused; others were never reached before the tree was complete. The final picture does not give all these absences the same history.

In the smaller study, the point has kept its body. The question around it has changed. We have set aside the directed records and declared two-way links with build costs. Follow the cheap tree until it has nothing spare.

Now break one connection.

The arrangement was economical. Three vertices become unreachable from the start. Nothing in the earlier answer promised otherwise. A tree has one route between each pair, and each selected edge is a place where that route can be lost.

Add the refused connection between 4 and 5. The separated group becomes reachable again. An edge that contributed nothing to the minimum-cost objective now does something we need. The word “redundant” had been waiting for us to say what had to survive.

There is a pleasure in the spare: room to return another way, to keep going when a preferred connection fails. There is also a limit to its promise. A different break can still strand the last vertex on a branch. We have improved a particular arrangement under a particular failure. We have not made it invulnerable.

Keep the spare visible beside the cost. Neither number can decide for us whose interruption matters, how long someone can wait, or what kind of loss we are prepared to accept. Those choices preceded the clean result and remain after it.

<!-- @ -->

The next hall lets something travel through the network. Even when every destination can be reached, a narrow connection may not carry everything trying to pass.
''',encoding='utf8')
print('Spanning Trees texts written: explicit undirected model, four complete scripts.')
