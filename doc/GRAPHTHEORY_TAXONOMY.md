# Graph theory, taught in the order the engine needs it

> Second run of the recipe in `doc/COLOR_TAXONOMY.md` (2026-08-27, same day). The seed
> cheat-code said it: **the scene tree is already a graph** — the deepest one-liner in
> the table, so graph theory went second.

The June concept map was algorithm-name soup — "Edmonds Algorithm", "Karger s
Algorithm", one tile each: a filing cabinet, not a ladder. Replaced by a canon authored
in `tools/build_concept_map.py` (CONFIG.graphtheory), 13 rungs in existence order, live
at **localhost:3003/graphtheory-concepts**. Sequence truth kept: *"Everything is a graph
if you squint hard enough"* — the taxonomy's answer is that in this engine you don't
even need to squint.

## The Godot cheat-code for graphs

| engine primitive | what it admits about graphs |
|---|---|
| `Node` + `add_child` | the engine's home data structure IS a rooted directed tree |
| reparent under your own descendant | **refused** — the tree is acyclic by law, not by luck |
| `NodePath`, `get_node("../x")` | an address is a WALK: '..' climbs an edge, a name descends |
| `signal` / `connect()` | a second graph laid over the tree — and it permits cycles |
| `get_children()`, `propagate_call` | traversal is built in; order is the algorithm's choice |
| `AStar3D` | the engine says "shortest path" out loud: points, edges, costs |
| `get_nodes_in_group` | membership without wires — labels over the graph |
| `GraphEdit` / `GraphNode` | the editor itself ships a graph editor |

## The ladder — 13 rungs, 7 acts, every hero BUILT or ADOPTED

Eight heroes built 2026-08-27 (probe: 0 broken), joining 24 standing bodies assigned by
the hand layer (`doc/graphtheory_concept_additions.json`):

1. **The pair** *(I)* — a node and an edge. Bodies: graphspace, graphspace3d, network_analysis.
2. **The tree** *(II)* — HERO **family_chandelier**: a chandelier that IS a scene tree;
   press, one branch swings, and its whole line of descent swings rigidly — transform
   inheritance made brass.
3. **The address** *(II)* — HERO **postman_of_paths**: a letter walking NodePaths along
   glowing ropes; in a tree there is exactly one simple path, and the address IS it.
4. **The cycle** *(III)* — HERO **ouroboros_signals**: three telephones, real `connect()`
   edges, a call circling forever — beside a grey tree whose red back-edge is refused.
5. **Direction** *(III)* — topological_sort ×2: arrows one way, and an order exists
   exactly when there is no cycle.
6. **Degree** *(IV)* — HERO **wallflower_and_star**: twelve ribbons against one, counted
   in brass at their feet. Degree counts edges, not importance.
7. **Components** *(IV)* — HERO **archipelago_wedding**: two islands, two colours; lower
   the drawbridge and every lamp turns wedding gold — membership is global. Bodies:
   tarjan, kosaraju (the strongly-connected cousins).
8. **The layout** *(IV)* — adopt **graph_basilica** + force_directed_layout,
   forcedirected3d: a graph has no WHERE until physics gives it one.
9. **Traversal** *(V)* — HERO **two_travelers**: one tree, the tide (BFS) and the diver
   (DFS) taking turns. Bodies: living_paper_bfs, living_paper_dfs_maze, grid3d family.
10. **The shortest path** *(V)* — HERO **impatient_river**: a spark commuting on live
    `AStar3D`; sink a stone and it learns a new river. Bodies: pathfinding3d.
11. **The seven bridges** *(V)* — adopt **KonigsbergBridge**: the founding story, and the
    proof needed only degrees.
12. **The skeleton and the pipes** *(VI)* — mst_visualization, grid3d_prim, networkflow3d,
    env_one, push_relabel, karger, edmonds: graphs with prices on their edges. (A future
    hero could be a plumbing organ — flow as pipes with a loudest-possible chord.)
13. **The graph you are in** *(VII, the mirror)* — HERO **the_tree_you_are_in**: a
    pedestal that walks its own `get_children()` once a second and redraws itself as
    the graph it is, with one honest "…" where the projection contains the projection.
    The loop closes: rung 1 was never an abstraction here.

Architecture note: the heroes live in a fresh `commons/artifacts/registry/graphtheory.json`
(the standing bodies stay in algorithms_misc et al. — scanning misc wholesale would have
dumped its unrelated tokens into Off-the-ladder, so the hand layer assigns exactly the 24
that belong).
