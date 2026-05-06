# GT Spanning Trees

Connect every vertex. Minimise total weight. MST via Kruskal.

Build a weighted graph.

```gdscript
class_name WeightedGraph

var vertices: Array = []
var edges: Array = []  # [a, b, weight]

func add_edge(a, b, weight: float) -> void:
    if not a in vertices: vertices.append(a)
    if not b in vertices: vertices.append(b)
    edges.append([a, b, weight])
```

Each edge carries a weight. The MST minimises the sum of chosen weights.

Union-find data structure.

```gdscript
class_name UnionFind

var parent: Dictionary = {}
var rank: Dictionary = {}

func make_set(x) -> void:
    parent[x] = x
    rank[x] = 0

func find(x):
    if parent[x] != x:
        parent[x] = find(parent[x])  # path compression
    return parent[x]

func union(x, y) -> bool:
    var rx = find(x); var ry = find(y)
    if rx == ry: return false
    if rank[rx] < rank[ry]:
        parent[rx] = ry
    elif rank[rx] > rank[ry]:
        parent[ry] = rx
    else:
        parent[ry] = rx
        rank[rx] += 1
    return true
```

Path compression and union by rank give effectively O(α(n)) per operation.

Kruskal's algorithm.

```gdscript
func kruskal(g: WeightedGraph) -> Array:
    var uf := UnionFind.new()
    for v in g.vertices: uf.make_set(v)
    var sorted_edges = g.edges.duplicate()
    sorted_edges.sort_custom(func(a, b): return a[2] < b[2])
    var tree: Array = []
    for edge in sorted_edges:
        if uf.union(edge[0], edge[1]):
            tree.append(edge)
            if tree.size() == g.vertices.size() - 1: break
    return tree
```

Sort by weight, add if it doesn't form a cycle. Stops when V-1 edges are added.

Prim's algorithm.

```gdscript
func prim(g: WeightedGraph, start) -> Array:
    var tree: Array = []
    var in_tree: Dictionary = {start: true}
    var candidates: Array = []
    for edge in g.edges:
        if edge[0] == start or edge[1] == start:
            candidates.append(edge)
    while tree.size() < g.vertices.size() - 1:
        candidates.sort_custom(func(a, b): return a[2] < b[2])
        var best = candidates.pop_front()
        var other = best[1] if best[0] in in_tree else best[0]
        if other in in_tree: continue
        tree.append(best)
        in_tree[other] = true
        for edge in g.edges:
            if edge[0] == other or edge[1] == other:
                candidates.append(edge)
    return tree
```

Grow from the root. Always add the cheapest edge that connects a new vertex.

Verify the MST.

```gdscript
func verify_mst(tree: Array, g: WeightedGraph) -> bool:
    if tree.size() != g.vertices.size() - 1: return false
    var uf := UnionFind.new()
    for v in g.vertices: uf.make_set(v)
    for edge in tree:
        if not uf.union(edge[0], edge[1]): return false
    return true
```

V-1 edges, no cycles. Valid spanning tree.

Compute total weight.

```gdscript
func total_weight(tree: Array) -> float:
    var total: float = 0.0
    for edge in tree:
        total += edge[2]
    return total
```

Sum of selected edges' weights. Kruskal and Prim produce the same total on a connected weighted graph with unique weights.

Animate the MST construction.

```gdscript
func animate_mst(tree: Array, delay: float = 0.3) -> void:
    for edge in tree:
        highlight_edge(edge)
        await get_tree().create_timer(delay).timeout
```

One edge at a time, with a pause between. The learner watches the tree grow.

You can now build a weighted graph, compute the MST via Kruskal or Prim using union-find, verify the result, and animate the construction. GT_Flow extends into network flow.
