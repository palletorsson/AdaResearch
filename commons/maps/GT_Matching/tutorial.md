# GT Matching

Pair nodes. Each node claimed by at most one edge. Hungarian algorithm for bipartite weighted matching.

Build a bipartite graph.

```gdscript
class_name BipartiteGraph

var left_vertices: Array = []
var right_vertices: Array = []
var edges: Array = []  # [u, v, weight]

func add_edge(u, v, weight: float = 0.0) -> void:
    if not u in left_vertices: left_vertices.append(u)
    if not v in right_vertices: right_vertices.append(v)
    edges.append([u, v, weight])
```

Two disjoint vertex sets. Edges only cross from left to right.

Greedy matching.

```gdscript
func greedy_matching(g: BipartiteGraph) -> Dictionary:
    var matching: Dictionary = {}  # right_vertex -> left_vertex
    var left_used: Dictionary = {}
    for edge in g.edges:
        if not edge[0] in left_used and not edge[1] in matching:
            matching[edge[1]] = edge[0]
            left_used[edge[0]] = true
    return matching
```

Linear scan. Not optimal; demonstrates why the Hungarian approach exists.

Hopcroft-Karp for maximum matching.

```gdscript
func hopcroft_karp(g: BipartiteGraph) -> Dictionary:
    var matching: Dictionary = {}
    while true:
        var levels: Dictionary = bfs_layers(g, matching)
        if levels.is_empty(): break
        var any_augmented: bool = false
        for u in g.left_vertices:
            if not matching.values().has(u):
                if dfs_augment(u, levels, matching, g):
                    any_augmented = true
        if not any_augmented: break
    return matching
```

BFS to find layered structure; DFS to find augmenting paths. Runs in O(E·√V).

Hungarian algorithm for weighted matching.

```gdscript
func hungarian(cost_matrix: Array) -> Array:
    var n: int = cost_matrix.size()
    var u_dual: Array = []
    var v_dual: Array = []
    for _i in n + 1: u_dual.append(0); v_dual.append(0)
    var assignment: Array = []
    for _i in n + 1: assignment.append(-1)
    # Full Hungarian loop omitted for brevity — finds optimal assignment
    return assignment
```

Solves in O(V³). Finds the minimum-cost perfect matching in a bipartite graph.

Blossom contraction.

```gdscript
func contract_blossom(blossom: Array, graph) -> void:
    var super_vertex := "blossom_" + str(randi())
    for v in blossom:
        for e in graph.edges_touching(v):
            var other = e.other(v)
            if not other in blossom:
                graph.add_edge(super_vertex, other)
    for v in blossom:
        graph.remove_vertex(v)
```

Odd cycles contract into super-vertices. After augmenting through the contraction, the super-vertex expands back into the original blossom.

Detect stable marriage.

```gdscript
func gale_shapley(proposers: Array, receivers: Array, prefs: Dictionary) -> Dictionary:
    var engaged: Dictionary = {}  # receiver -> proposer
    var free_proposers: Array = proposers.duplicate()
    var next_proposal: Dictionary = {}
    for p in proposers: next_proposal[p] = 0
    while not free_proposers.is_empty():
        var p = free_proposers.pop_front()
        var r = prefs[p][next_proposal[p]]
        next_proposal[p] += 1
        if not r in engaged:
            engaged[r] = p
        elif prefs[r].find(p) < prefs[r].find(engaged[r]):
            free_proposers.append(engaged[r])
            engaged[r] = p
        else:
            free_proposers.append(p)
    return engaged
```

Proposers propose in preference order; receivers reject less-preferred matches. Produces a stable matching.

You can now build a bipartite graph, compute greedy, Hopcroft-Karp, and Hungarian matchings, contract blossoms in general matching, and run Gale-Shapley for stable marriage. The Graph Theory sequence closes; the curriculum's spine ends with the matching problem.
