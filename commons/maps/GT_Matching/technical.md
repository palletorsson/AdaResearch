# GT Matching — Technical

A matching is a subset of edges in which every vertex is incident to at most one edge. A perfect matching covers every vertex. A maximum matching is one with the most possible edges.

Bipartite matching is the easier case. The Hungarian algorithm solves the weighted bipartite matching problem in O(V³) using augmenting paths in a residual graph derived from the bipartite structure. The unweighted case — maximum bipartite matching — reduces to max-flow by adding a source connected to one side and a sink connected to the other, and can be solved in O(V·E) with Hopcroft-Karp.

```gdscript
# Hopcroft-Karp bipartite matching
func bipartite_matching(left, right, edges_lr) -> Dictionary:
    var matching := {}  # right_vertex -> left_vertex
    var improved := true
    while improved:
        improved = false
        var layers := bfs_layers(matching, left, right, edges_lr)
        if layers.is_empty(): break
        for u in left:
            if not matching.values().has(u):
                if dfs_augment(u, layers, matching, edges_lr):
                    improved = true
    return matching
```

General matching (matching in arbitrary graphs) is harder because of odd cycles. Edmonds' blossom algorithm handles this by contracting odd-length augmenting cycles into single pseudo-nodes (blossoms), finding augmenting paths through the contracted graph, and expanding the contractions back out once the matching is extended. The algorithm runs in O(V³) in the classical formulation; Micali-Vazirani improves this to O(V·√E).

The blossom contraction is the algorithm's distinctive move. When a BFS for augmenting paths discovers an odd cycle, the cycle is contracted into a super-vertex, the search continues from the super-vertex, and any augmenting path found through the super-vertex is expanded by lifting it back through the contraction when the matching is updated.

The map's two symmetric halves stage the bipartite case visually. Each side holds a set of vertices; edges run between the sides; the Hungarian algorithm finds the maximum matching and draws it as a set of thick edges. A toggle switches to general-graph mode, where odd cycles become possible and the blossom algorithm takes over.

Within the sequence, Matching is the capstone. It closes Graph Theory and the whole spine. The map argues that fair, exclusive, complete allocation is a graph problem, and the algorithms the sequence has built are enough to solve it.

## König's Theorem

For bipartite graphs, the maximum matching size equals the minimum vertex cover size — a set of vertices that covers every edge. This is König's theorem, and it has a constructive proof: given a maximum matching, a minimum vertex cover can be computed in linear time by following alternating paths from unmatched vertices.

## Weighted Matching

The Hungarian algorithm solves the weighted bipartite matching problem: find the matching that maximises total edge weight (or minimises total cost). It runs in O(V³) and is the standard algorithm for job-assignment problems where workers have different costs for different tasks.

```gdscript
# Hungarian algorithm — simplified kernel
func hungarian(cost: Array) -> Array:
    var n := cost.size()
    var u := []; var v := []
    u.resize(n + 1); v.resize(n + 1)
    var p := []; var way := []
    p.resize(n + 1); way.resize(n + 1)
    for i in range(1, n + 1):
        p[0] = i
        var j0 := 0
        var minv := []; var used := []
        minv.resize(n + 1); used.resize(n + 1)
        for k in range(n + 1):
            minv[k] = INF; used[k] = false
        while p[j0] != 0:
            used[j0] = true
            var i0: int = p[j0]
            var delta := INF
            var j1 := 0
            for j in range(1, n + 1):
                if not used[j]:
                    var cur = cost[i0 - 1][j - 1] - u[i0] - v[j]
                    if cur < minv[j]:
                        minv[j] = cur
                        way[j] = j0
                    if minv[j] < delta:
                        delta = minv[j]
                        j1 = j
            for j in range(n + 1):
                if used[j]:
                    u[p[j]] += delta
                    v[j] -= delta
                else:
                    minv[j] -= delta
            j0 = j1
        while j0 != 0:
            var j1 = way[j0]
            p[j0] = p[j1]
            j0 = j1
    var ans := []
    ans.resize(n)
    for j in range(1, n + 1):
        ans[p[j] - 1] = j - 1
    return ans
```

## Applications

Kidney donation matching uses general-graph matching because donor-recipient compatibility forms arbitrary graphs. Organ exchange programmes solve maximum matching subject to compatibility constraints, sometimes with additional constraints on cycle length.

Stable marriage (the Gale-Shapley algorithm) is a different kind of matching problem — one where preferences are two-sided rather than weights being symmetric. It runs in O(V²) and always produces a stable matching, though the stability comes at the cost of not being the maximum-weight matching.

Within the sequence, Matching closes Graph Theory and the entire spine. The curriculum's closing argument is that allocation problems are graph problems, and the algorithms the sequence has built are enough to solve them.
