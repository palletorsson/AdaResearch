# A route, a detour, and no route

Graph Theory hall 3 of 8 carries the same point and graph into Pathfinding. Layout changed coordinates while preserving connections. This hall changes availability and asks which journey remains possible.

| Part | Before | Now |
| --- | --- | --- |
| Tutorial | A* and maze fragments, with undeclared helpers | Complete runnable queue search, predecessor record and point traveller |
| Lineage | No explicit bridge from the previous graph | Same seven IDs and previous edges; one declared extra edge 4–5 permits a detour |
| Reflection | Implied that losing a stone always yields another crossing | A route may survive, or the traveller may stop; no route is a valid answer |
| Museum | Oversized maze; the river named by the text was absent | River restored, compact supporting maze, clear middle passage and learner bay |
| Independent task | Broad algorithm comparison | Remove the added edge; predict which journey survives |

The learner travels from 3 to 6. With everything available, the answer is 3→1→0→2→6. Blocking 0 yields 3→1→4→5→2→6. Blocking 0 and 4 leaves no route. The point remains available to pick up and restore the conditions. Holding it pauses the journey; its inherited trigger changes availability.

The code separates the vertices visited during search from those in the chosen route. It records predecessors at discovery, then reconstructs the answer. The point plays this answer afterwards. A smooth animation must not be mistaken for a view of every search decision.

The existing river uses AStar3D with distance costs. Our smaller queue example finds the fewest edges. The texts name that distinction rather than treating all meanings of shortest as interchangeable. In the captured river, the first sinking actually removes the crossing; the learner's controlled graph lets us test a detour as well.

**32 code checks and 31 native museum checks pass.** The code suite compares all 128 blocked-vertex combinations against an independent exhaustive path oracle, runs the student's remove-an-edge variation and catches three faulty algorithms. The museum suite checks the real river button connection, restoration, no-route behavior, 69 aisle clearance samples, and synthetic XRTools pickup, trigger and release.

The exact tutorial scripts are included. The learner study is temporarily installed for these captures, with a declared placement for the student to use. The existing river and maze algorithms are unchanged. Images are native Godot views, including the hall from above.

These are author-operated reconstruction checks. An independent reader and a physical headset remain separate tests. Quest performance, comfort and continuous portal traversal are not verified.

**Next: Network Analysis.** We now know how to request one journey. The next hall asks what a vertex's connections permit across the network.
