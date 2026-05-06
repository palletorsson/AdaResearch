# GT Network Analysis — Technical

The map computes several centrality measures on a shared graph and displays them side by side. Degree centrality counts direct edges. Betweenness centrality counts the number of shortest paths that pass through a vertex. Eigenvector centrality rewards vertices connected to other well-connected vertices.

```gdscript
# Degree centrality: O(V)
func degree_centrality() -> Dictionary:
    var c := {}
    for v in vertices:
        c[v] = adj[v].size()
    return c

# Betweenness: O(V * (V + E)) using Brandes' algorithm
func betweenness_centrality() -> Dictionary:
    var b := {}
    for v in vertices:
        b[v] = 0.0
    for s in vertices:
        var stack := []
        var preds := {}
        var sigma := {s: 1}
        var dist := {s: 0}
        var queue := [s]
        # ... shortest-path BFS omitted for brevity ...
        # Accumulate contributions on the reverse-stack pass
    return b
```

Betweenness is the expensive measure. Brandes' algorithm computes it in O(V·(V+E)) time for unweighted graphs, which is tractable for graphs up to a few thousand vertices. Naive implementations that enumerate all shortest paths are O(V³) and become impractical much sooner. The map uses Brandes because the interactive parameter-tuning the map rewards requires recomputing betweenness frequently.

Eigenvector centrality is computed by power iteration on the adjacency matrix: repeatedly multiply a vector by the adjacency matrix and normalise until the result stabilises. For a graph with N vertices and E edges, each iteration is O(E), and convergence takes O(log(1/ε)/log(λ₁/λ₂)) iterations where λ₁ and λ₂ are the dominant and second eigenvalues. In practice, twenty iterations is usually enough.

The `networkflow3d` artifact adds flow analysis. Pipes replace edges with capacity-bounded throughput; a source-to-sink flow is computed using Ford-Fulkerson or push-relabel. The algorithms differ in their approach: Ford-Fulkerson augments along paths iteratively; push-relabel operates locally by pushing flow to neighbours and relabelling vertices when pushes block.

Within the sequence, Network_Analysis is the measurement chapter. The previous map staged traversal; this map stages quantification. GT_Connectivity will next introduce directed edges and the asymmetric reachability they produce.

## PageRank as Eigenvector Centrality

Google's PageRank is the most famous application of eigenvector centrality. The algorithm treats each web page as a vertex and each hyperlink as a directed edge. The PageRank of a page is proportional to the sum of the PageRanks of the pages that link to it, weighted by the out-degree of those pages.

```gdscript
func pagerank(damping: float = 0.85, tol: float = 1e-6) -> Dictionary:
    var n := vertices.size()
    var pr := {}
    for v in vertices:
        pr[v] = 1.0 / n
    while true:
        var new_pr := {}
        var diff := 0.0
        for v in vertices:
            var s := 0.0
            for u in in_neighbors(v):
                s += pr[u] / out_degree(u)
            new_pr[v] = (1.0 - damping) / n + damping * s
            diff += abs(new_pr[v] - pr[v])
        pr = new_pr
        if diff < tol: break
    return pr
```

Damping (typically 0.85) models a random surfer who jumps to a random page with probability 1−damping. Without damping, vertices with no outgoing edges (sinks) accumulate all the rank. The random-jump term ensures the algorithm converges.

## Clustering Coefficient

Local clustering coefficient measures how tightly a vertex's neighbours are connected to each other. For vertex v with k neighbours, the coefficient is the number of edges among the neighbours divided by k(k−1)/2, the maximum possible. High clustering indicates communities; low clustering indicates a tree-like or random structure.

The global clustering coefficient averages the local values. Small-world networks, like social graphs, typically have high clustering and short path lengths.

## Structural Holes

Betweenness centrality is closely related to Burt's concept of structural holes: vertices that bridge otherwise disconnected communities. A high-betweenness vertex controls information flow because shortest paths between communities must pass through it. The map's hub-and-spoke layout is engineered to make such vertices visually dominant.

Within the sequence, Network_Analysis is the measurement chapter. GT_Connectivity will extend measurement into directed graphs where reachability itself is asymmetric.

## One More Note on Weighted Centrality

Closeness centrality — one over the average shortest-path distance from a vertex to all others — is a fourth common measure the map can display. It rewards central vertices in the literal sense: vertices whose average distance to the rest of the graph is small. Computing it requires running shortest-path from every vertex, giving O(V · (V + E)) total.
