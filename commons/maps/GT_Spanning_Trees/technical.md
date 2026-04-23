# GT Spanning Trees — Technical

A minimum spanning tree (MST) is a subset of edges that connects every vertex and minimises total edge weight. The map implements both Kruskal's and Prim's algorithms and shows their step-by-step progress.

Kruskal's algorithm sorts all edges by weight, then adds them greedily, skipping any edge that would form a cycle with the edges already chosen. Cycle detection uses a disjoint-set (union-find) data structure:

```gdscript
class UnionFind:
    var parent: Dictionary = {}
    var rank: Dictionary = {}

    func find(x):
        if parent[x] != x:
            parent[x] = find(parent[x])  # path compression
        return parent[x]

    func union(x, y) -> bool:
        var rx = find(x)
        var ry = find(y)
        if rx == ry: return false  # would form cycle
        if rank[rx] < rank[ry]:
            parent[rx] = ry
        elif rank[rx] > rank[ry]:
            parent[ry] = rx
        else:
            parent[ry] = rx
            rank[rx] += 1
        return true

func kruskal() -> Array:
    var tree := []
    var uf := UnionFind.new()
    for v in vertices: uf.parent[v] = v
    edges.sort_custom(func(a, b): return a.weight < b.weight)
    for e in edges:
        if uf.union(e.a, e.b):
            tree.append(e)
            if tree.size() == vertices.size() - 1: break
    return tree
```

Union-find with path compression and union-by-rank supports find and union in effectively O(α(V)) amortised time, where α is the inverse Ackermann function (practically constant). The sort dominates: O(E log E) total.

Prim's algorithm grows the tree from a root vertex by repeatedly adding the lightest edge that connects a new vertex to the existing tree. A priority queue maintains the candidate edges, giving O((V + E) log V) with a binary heap or O(E + V log V) with a Fibonacci heap.

The two algorithms produce the same tree when edge weights are distinct. The map animates them side by side so the learner can see the different orders in which the same edges are selected.

The scattered platforms in the map at varying heights make edge weights physical — longer connections cost more, shorter ones cost less. Building the MST by hand produces the same tree the algorithms find automatically, which confirms that the problem has a structural optimum rather than an algorithmic one.

Within the sequence, Spanning_Trees is the optimisation-on-structure chapter. GT_Flow will next optimise throughput rather than structure.

## Correctness of the Greedy Approach

Kruskal's and Prim's algorithms are greedy, and greedy algorithms are not always correct. For the MST problem, the cut property guarantees correctness: for any cut of the graph, the minimum-weight edge crossing the cut is in some MST. Both algorithms can be shown to always respect the cut property, and therefore always produce an MST.

Kruskal's correctness: the sorted-and-added edge is the minimum-weight edge crossing the cut between the two components it connects. Prim's correctness: the lightest edge leaving the current tree is the minimum-weight edge crossing the cut between the tree and the rest of the graph.

## When Weights Are Not Distinct

If two edges have the same weight, the MST is not unique. Kruskal's and Prim's algorithms may produce different trees depending on tie-breaking order. Every MST has the same total weight, though, so the choice of tie-breaking is cosmetic for the optimisation objective.

## Borůvka's Algorithm

A third MST algorithm, Borůvka's, is parallelisable. It finds, for each component simultaneously, the minimum-weight outgoing edge, adds all such edges, and merges the resulting components. Repeating halves the component count each iteration, so the algorithm terminates in O(log V) rounds, each round costing O(E).

```gdscript
func boruvka() -> Array:
    var tree := []
    var uf := UnionFind.new()
    for v in vertices: uf.parent[v] = v
    while uf.components() > 1:
        var min_edge_per_component := {}
        for e in edges:
            var ca := uf.find(e.a)
            var cb := uf.find(e.b)
            if ca == cb: continue
            if not min_edge_per_component.has(ca) or min_edge_per_component[ca].weight > e.weight:
                min_edge_per_component[ca] = e
            if not min_edge_per_component.has(cb) or min_edge_per_component[cb].weight > e.weight:
                min_edge_per_component[cb] = e
        for me in min_edge_per_component.values():
            if uf.union(me.a, me.b):
                tree.append(me)
    return tree
```

The parallelism matters for very large graphs. The map's graphs are small enough that Kruskal and Prim are adequate, but Borůvka becomes competitive at the scale of continental road networks.

Within the sequence, Spanning_Trees optimises structure. GT_Flow will next optimise throughput.
