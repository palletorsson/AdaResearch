from pathlib import Path
R=Path(__file__).resolve().parents[1];M=R/'commons/maps/GT_Pathfinding';S=R/'doc/book/studies/graphs-through-the-hands/GT_Pathfinding'
def block(name):return '<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf8').rstrip()+'\n```\n'
t='''# Pathfinding — keep the way back

## Learning elements

- Breadth-first search with a goal
- A predecessor record for each discovered vertex
- Reconstructing a route, distinct from search order
- Availability, detours and an explicit no-route result

## The river and the point

Watch the spark cross the museum river. Press its button and a stone on the route sinks. The exhibit asks for a new route immediately. If one exists, the spark starts again at a bank; otherwise it stops where it is. The stones supply the graph; their availability changes what the search can use. The little maze elsewhere in the room is a supporting encounter. We will build one route-finding operation here.

Keep our seven vertices and the point. In Layout, we changed the drawing without changing adjacency. Here we keep the drawing still and change **which vertices are available**. Our point becomes the traveller. Holding it pauses its journey; its trigger changes the available options. Releasing it returns it to the recorded journey.

There is one necessary addition. Our earlier graph was a tree: each pair of vertices had only one simple route between them. A detour requires another connection. Add the reciprocal edge **4–5**, keeping every previous vertex and edge. This is a deliberate change in the relation record, not a consequence of two drawn points being close.

## Continue inside the museum

Keep `traversal.gd` and `point_body.gd` unchanged from Layout. Add `route.gd` beside them and use the complete `study.gd` below. The layout simulation is set aside for this lesson; the initial coordinates return as a fixed drawing. Save the four scripts together and attach `study.gd` to one empty Node3D. The supplied `study.tscn` contains just this node. The museum project supplies camera, lighting, player and XRTools.

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

## Let the point follow the result

This complete host continues the familiar numbered spheres and cylinders. Gold cylinders show the chosen route. Blocked vertices turn pink and their incident rods disappear; the underlying connection record is retained. The black point travels just in front of the rods so it remains visible.

'''+block('study.gd')+'''
The host searches to completion before the point moves. The readout separates **Route** from **Search visited**. The animation plays the answer; it is not a display of the search running one step at a time.

Trigger or **1** cycles through blocking0, blocking0and4, and restoring both. Each change replans from3 and starts a new journey. **R** replays the current route without changing availability. Holding the point pauses its cursor; on release it returns to that cursor. If you change availability while holding it, release starts the newly computed journey instead. With no route it waits in the small parking position, where it remains pickable for the next action.

## Change something the code depends on

Remove the two append lines in `route.gd` that add4–5, leaving `pass` as the body of `_init()`. Predict before running: the initial route remains3,1,0,2,6, but blocking0 now gives **NO ROUTE**. You removed the detour itself. Restore the two lines afterwards.

Then inspect the normal search's predecessor record. Recover the route by hand, starting at6. Explain why a vertex in `visited` can be absent from `path`. You have learned more than making a sphere move: you can say which stored relation made its journey possible and why another attempt fails.

## Carried files — unchanged

`traversal.gd` provides the original graph and traversal state. The route subclass adds to this existing construction rather than introducing an unrelated Graph class.

'''+block('traversal.gd')+'''
`point_body.gd` still supplies the same pickable point. The new host connects its inherited trigger and uses its existing held state.

'''+block('point_body.gd')+'''
## What the larger exhibit adds

The river uses Godot's `AStar3D`, with a seeded arrangement of stones and links based on proximity. That default search minimises summed Euclidean segment lengths, whereas our queue minimises the number of edges. The river's displayed stone count describes the returned route; it is not the search's optimisation rule. We have rebuilt the availability-and-route question with a smaller cost model, not claimed to reproduce A* here. [Godot AStar3D documentation](https://docs.godotengine.org/en/stable/classes/class_astar3d.html)

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
(M/'final.md').write_text('''# The route after a stone disappears

Watch the spark reach the other bank. Choose one stone it seems to depend on.

<!-- @impatient_river -->

Press the button. A stone on the route sinks. The spark may begin another journey from a bank, or stop where it is. For an instant you may still be following the crossing that is no longer there.

Something of that crossing can remain useful. The new route may keep its first steps and change only the middle, or approach the far bank by a connection you had overlooked. Losing one option does not make every earlier step a mistake.

In the last room the drawing moved while its connections stayed available. Here the record of availability changes. An edge that still seems possible to your eye may lead to a stone the traveller can no longer use.

The river was constructed before the spark was asked to cross it. Distances between stones decided most of its links; the banks were given connections into the field. The spark cannot improvise a leap the graph does not contain. Its small hop is an animation of a permitted connection, not evidence that your body could make the crossing.

Watch a stone return. After the fourth sinking, the oldest of the three previously disabled stones rises again. What looks like the traveller finding a better way may also be the world giving an option back. Its apparent resourcefulness belongs partly to these conditions.

Sometimes the answer is no route. Stay with the empty crossing. The search has finished its work; the request remains unsatisfied. Asking again cannot supply a missing connection. We might have to build another bridge, restore a stone, or change what kind of passage we are willing to count.

Before the spark moves, its route has already been found. We see the chosen crossing more easily than the alternatives considered and left behind. A smooth journey can conceal the search that made it possible.

Which part of this crossing belongs to the traveller, and which part have we arranged for it?

<!-- @ -->

The next hall looks beyond one journey: what can a vertex's connections tell us about its place in the network?
''',encoding='utf8')
print('Pathfinding tutorial and reflection written with complete four-file reconstruction.')
