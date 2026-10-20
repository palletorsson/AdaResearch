from pathlib import Path
R=Path(__file__).resolve().parents[1];M=R/'commons/maps/GT_Pathfinding';S=R/'doc/book/studies/graphs-through-the-hands/GT_Pathfinding'
def block(name):return '<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf8').rstrip()+'\n```\n'
t='''# Pathfinding — the same river, three searches

## Learning elements

- Breadth-first search with a goal
- A predecessor record for each discovered vertex
- Reconstructing a route, distinct from search order
- Availability, detours and an explicit no-route result
- Dijkstra: distance costs and improving a known route
- A*: cost so far plus a lower bound on remaining distance

## The river and the point

Watch the spark cross the museum river. Press its button and a stone on the route sinks. The exhibit asks for a new route immediately. If one exists, the spark starts again at a bank; otherwise it stops where it is. The stones supply the graph; their availability changes what the search can use. The little maze elsewhere in the room is a supporting encounter. We will keep this crossing and change the search in three short passes: BFS, Dijkstra, then A*.

Keep our seven vertices and the point. In Layout, we changed the drawing without changing adjacency. Here we keep the drawing still and change **which vertices are available**. Our point becomes the traveller. Holding it pauses its journey; its trigger changes the available options. Releasing it returns it to the recorded journey.

There is one necessary addition. Our earlier graph was a tree: each pair of vertices had only one simple route between them. A detour requires another connection. Add the reciprocal edge **4–5**, keeping every previous vertex and edge. This is a deliberate change in the relation record, not a consequence of two drawn points being close.

## Continue inside the museum

Keep `traversal.gd` and `point_body.gd` unchanged from Layout. Add `route.gd`, then `weighted_route.gd`, beside them and use the complete `study.gd` below. Begin in BFS mode; return to the same display for each new rule. The layout simulation is set aside for this lesson; the drawing stays fixed during each comparison, with vertex 0 raised as explained below. Save the five scripts together and attach `study.gd` to one empty Node3D. The supplied `study.tscn` contains just this node. The museum project supplies camera, lighting, player and XRTools.

The reviewed learner bay is at **map-local (3.5, -0.25, 5.5), Y rotation180 degrees, scale1**. In the isolated museum its hall-root position is(3.5,-0.25,9.5), because map zero starts four metres after that root. The permanent river is already in the right bay. Add one instance of the learner study in the left bay; do not replace the river or rebuild the player.

## What a search must remember

Our earlier queue answered: which vertex should be visited next? Now it also records **from which vertex each new discovery was reached**. `predecessor[2] = 0` means that this search first discovered2 from0. It is not a second adjacency list: it keeps only the discovery relation needed to recover this route.

`route.gd` extends our unchanged traversal file, so it already has `neighbours`, `pending`, `visited` and `restart()`. Its constructor adds4–5 in both directions. `find_path()` clears old search state each time, refuses a blocked endpoint, and uses the same queue rule: take the oldest pending ID.

'''+block('route.gd')+'''
The predecessor record also marks discovery. We set it **when adding a vertex to the queue**, so another connection cannot add that vertex again or replace its first predecessor. This matters now that4–5 creates a cycle. `visited` records vertices actually taken from the queue; it can contain branches the eventual traveller does not use.

Every edge has the same cost here. The queue reaches vertices in increasing numbers of edges from the start, so the first discovery gives a route with the fewest edges. This does not promise the shortest physical distance. The search never reads coordinates.

When the goal has a predecessor record, follow it backwards until the start's sentinel value`-1`. `push_front()` places those IDs in start-to-goal order. If the goal was never discovered, return an empty list. Looking up an absent goal would be a code error; **NO ROUTE** is a valid result.

## Three outcomes on the same drawing

We travel from **3 to6**. Before running, trace these outcomes with your finger:

| Unavailable vertices | Returned route | Edges |
| --- | --- | --- |
| None | 3 → 1 → 0 → 2 → 6 | 4 |
| 0 | 3 → 1 → 4 → 5 → 2 → 6 | 5 |
| 0 and4 | No route | — |

The original adjacency stays stored. A separate `blocked` list filters the search. Restoring availability therefore needs no rebuilding of the graph. A route is a result for those conditions: when they change, we search again.

## Count distance: Dijkstra

Keep every vertex ID and edge. Raise vertex 0 from `y = 2.3` to `y = 2.7` in the host; this makes the upper crossing longer. Keep this new drawing fixed while comparing all three rules. Our BFS route, **3 → 1 → 0 → 2 → 6**, uses four edges and spans about **3.330 metres**. The five-edge detour **3 → 1 → 4 → 5 → 2 → 6** spans about **2.932 metres**. An extra crossing can make the journey shorter.

We now give each edge a cost: the distance between its endpoints in the study's local metre coordinates. Dijkstra selects the pending vertex with the lowest **cost so far**, instead of the oldest pending vertex. A first discovery may be expensive. If a later route reaches that vertex more cheaply, replace its cost and predecessor. The queue's first-discovery rule is no longer enough.

Create `weighted_route.gd`, extending the BFS file. It inherits `find_path()` unchanged. The new method takes the same start, goal and blocked IDs, plus the existing positions and a switch for the estimate. With the switch false, it is Dijkstra.

'''+block('weighted_route.gd')+'''

`costs` keeps the best distance found to each vertex. `priority()` determines which pending entry to expand next. The small loop scans that list; a heap would make selection faster on larger graphs, but is not needed to understand seven points. `visited` records expansions, separately from the reconstructed route.

The last loop follows predecessors exactly as before. Edge distances are nonnegative. A vertex is updated only by a strictly cheaper candidate, so a zero-length edge cannot endlessly replace an equal cost.

## Add an estimate: A*

Now turn `use_estimate` on. The only change is the priority:

**cost already travelled + straight-line distance to the goal**.

The estimate does not add a new edge. A direct line can cross the water where no crossing exists; it is only a lower bound on the distance still required. Every available route is a chain of Euclidean segments, so its total cannot be shorter than that straight line. This makes our heuristic both admissible and consistent. These conditions justify stopping when the goal is selected. A guessed or learned estimate does not automatically have them.

Dijkstra is this same code with the estimate set to zero. A* aims for the same minimum distance while guiding the expansion order. It need not find a different route, and it will not always inspect fewer vertices. This is search using a supplied estimate; no training happens.

| Rule | Route on the unchanged starting drawing | Edges | Distance |
| --- | --- | --- | --- |
| BFS | 3 → 1 → 0 → 2 → 6 | 4 | 3.330 m |
| Dijkstra | 3 → 1 → 4 → 5 → 2 → 6 | 5 | 2.932 m |
| A* | 3 → 1 → 4 → 5 → 2 → 6 | 5 | 2.932 m |

The costs here measure distance, not risk, accessibility or time. Another meaning would need another cost rule and a justified estimate. [Poole and Mackworth on A*](https://www.artint.info/3e/html/ArtInt3e.Ch3.S6.html).

## Let the point follow the result

This complete host continues the familiar numbered spheres and cylinders. Gold cylinders show the chosen route. Blocked vertices turn pink and their incident rods disappear; the underlying connection record is retained. The black point travels just in front of the rods so it remains visible.

'''+block('study.gd')+'''
The host searches to completion before the point moves. The readout separates **Route** from **Search visited**. The animation plays the answer; it is not a display of the search running one step at a time. The caption also gives edge count and distance, so changing the rule cannot silently change what shortest means.

Trigger or **1** cycles through blocking0, blocking0and4, and restoring both. Each change replans from3 and starts a new journey. **R** replays the current route without changing availability. Holding the point pauses its cursor; on release it returns to that cursor. If you change availability while holding it, release starts the newly computed journey instead. With no route it waits in the small parking position, where it remains pickable for the next action.

Press the nearby **SEARCH RULE** button, or **2**, to cycle BFS → Dijkstra → A*. This changes neither the blocked IDs nor the graph. Compare the expanded IDs as well as the resulting path. The button scene is a supplied museum control; all point, graph and route construction remains visible here.

## Change something the code depends on

Remove the two append lines in `route.gd` that add4–5, leaving `pass` as the body of `_init()`. Predict before running: the initial route remains3,1,0,2,6, but blocking0 now gives **NO ROUTE**. You removed the detour itself. Restore the two lines afterwards.

Then inspect the normal search's predecessor record. Recover the route by hand, starting at6. Explain why a vertex in `visited` can be absent from `path`. You have learned more than making a sphere move: you can say which stored relation made its journey possible and why another attempt fails.

Now restore 4–5 and change only `places[0]` to `Vector3(0, 1.4, 0)`. Before running, predict: BFS keeps its four-edge route; Dijkstra and A* now choose that route too, because its distance is lower. Confirm the result with the caption and restore the position. Finally block 0 and 4 and check **NO ROUTE** in every mode.

## Carried files — unchanged

`traversal.gd` provides the original graph and traversal state. The route subclass adds to this existing construction rather than introducing an unrelated Graph class.

'''+block('traversal.gd')+'''
`point_body.gd` still supplies the same pickable point. The new host connects its inherited trigger and uses its existing held state.

'''+block('point_body.gd')+'''
## What the larger exhibit adds

The river keeps its original banks, eleven seeded stones and distance-based links in `AStar3D`. Its **SEARCH RULE** button now runs the same printed BFS or weighted search over those connections and disabled flags. **SINK STONE** still removes an available crossing and replans immediately; older stones still resurface. Mode changes preserve the current availability and travel direction. The spark remains the same object.

The larger graph can produce equal routes under different rules. A matching route does not mean the procedures are identical: compare their expanded IDs. Godot's own default `AStar3D` distance path provides an independent comparison in our tests. [Godot AStar3D documentation](https://docs.godotengine.org/en/stable/classes/class_astar3d.html).

Carry the graph, availability record and predecessor chain onward. Network Analysis will ask what a vertex's relationships permit across the graph, beyond the single journey we just requested.
'''
for old,new in {
 'rotation180 degrees, scale1':'rotation 180 degrees, scale 1',
 'position is(3.5,-0.25,9.5)':'position is (3.5, -0.25, 9.5)',
 'discovered2 from0':'discovered 2 from 0', 'adds4–5':'adds 4–5',
 'that4–5':'that 4–5', "value`-1`":"value `-1`",
 '**3 to6**':'**3 to 6**', '0 and4':'0 and 4',
 'blocking0and4':'blocking 0 and 4', 'blocking0':'blocking 0',
 'from3':'from 3', 'add4–5':'add 4–5', 'remains3,1,0,2,6':'remains 3, 1, 0, 2, 6',
 'starting at6':'starting at 6',
}.items():t=t.replace(old,new)
(M/'tutorial.md').write_text(t,encoding='utf8')
print('Pathfinding tutorial written from five exact source files. Reflection remains separately authored.')
