# Pathfinding — three searches, one river

The permanent Impatient River now uses the same search class printed in tutorial.md. Its two banks, eleven seeded stones, connections, sinking/restoration and traveller remain. AStar3D stores that graph; the exhibit chooses a route with inherited BFS or the new weighted method. SEARCH RULE cycles BFS → Dijkstra → A*. SINK STONE changes availability and replans immediately. A missing route leaves the spark stopped. After more than three stones are disabled, the oldest returns.

PointBody, traversal.gd and BFS route.gd carry forward unchanged. The learner host adds weighted_route.gd and a nearby supplied museum button. One declared coordinate edit raises vertex 0 from y=2.3 to y=2.7 before comparison. IDs and adjacency remain. The four-edge BFS answer spans 3.330 m; the five-edge weighted answer spans 2.932 m. Dijkstra prioritises accumulated Euclidean length. A* adds straight-line distance to the goal, a consistent lower bound for these edge costs. Neither method trains parameters. Local metre coordinates assume unit scale. Route playback is distinct from search expansion and player navigation.

The complete five scripts are printed and extracted into a fresh Godot 4.6 run. 48 code checks pass. The suite compares 12,544 weighted cases against an independent exhaustive simple-path oracle, retains the earlier BFS checks and synthetic XRTools pickup/trigger/release, runs an independent coordinate edit, and rejects five deliberate algorithm faults. These tests caught an initially incorrect distance example; vertex 0 was explicitly raised and the teaching comparison retested.

45 native checks pass: the museum's actual pool and portal destination resolver read Graph Theory before Machine Learning; real search/sink button signals work; the same spark, stones and availability survive mode changes. Sixty blocked-set/direction/mode cases agree with Godot's independent AStar3D distance result. Existing floor, aisle, approach and learner interaction checks pass. The learner study is temporarily installed in the reserved bay for these checks and captures; the permanent river is updated in place.

Spine order is Swarm Intelligence → Graph Theory → Machine Learning → Foundations Crisis. The runtime artifact manifest is stably reordered, retaining all within-chapter entries. The long-museum strip snapshot retains geometry and receives new chapter offsets; it is not a fresh whole-museum capture. Historical Lab layouts are not regenerated. Fresh Endless Museum starts use the new order; saved in-progress stream cursors and exported Quest builds are not migrated by this change.

Native screenshots and receipts accompany this review. Author-operated reconstruction and synthetic XR interaction do not establish physical headset usability or independent learner comprehension. Those remain untested.

Reproduce learner checks: `python tools/test_graph_pathfinding.py`

Reproduce museum checks: `python tools/run_encounter_probe.py GT_Pathfinding --sequence graphtheory --render --no-bridges --output-tag search-progression --probe tools/probes/graph_search_room.gd`

Publish after checks: `python tools/publish_graph_search.py`
