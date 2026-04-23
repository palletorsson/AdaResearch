import sys
sys.stdout.reconfigure(encoding='utf-8')
from pathlib import Path

adds = {}

adds['GT_Foundations'] = """

## Data Structures and Memory

The adjacency list is the most common graph representation in practice. It stores, for each vertex, a collection of its neighbours. Space is O(V + E), which is efficient for sparse graphs — graphs where E is much smaller than V². Dense graphs (E close to V²) are often better represented by an adjacency matrix: a V by V boolean or weight matrix whose entry at (i,j) records the edge from i to j. Adjacency matrices use O(V²) space but offer O(1) edge-existence queries.

The map's `graphspace` artifact uses adjacency lists. The tradeoff — O(V + E) space versus O(V²) space — matters because the map's graphs are small (dozens of vertices) and sparse (a handful of edges per vertex). An adjacency matrix would waste memory on mostly-empty rows.

## Operations and Their Costs

Adding a vertex to an adjacency list is O(1) — a dictionary insertion. Adding an edge is O(1) — two dictionary insertions, one for each direction in an undirected graph. Removing a vertex is O(degree), because every incident edge must be removed from the neighbour's list. Removing an edge is O(1) if the neighbour sets are hash-backed.

Iterating over all edges is O(V + E) because every vertex must be visited and every edge enumerated once per direction. In an undirected graph, naive iteration visits each edge twice — once from each endpoint — so edge-iterating code typically applies an i < j filter to visit each edge once.

Checking edge existence is O(1) with hash-set-backed adjacency. Without the hash, edge existence is O(degree), which is fast enough for small graphs and can become a bottleneck on dense ones.

Within the sequence, Foundations trains the learner's intuition for these tradeoffs without formalising them. GT_Layout's force-directed layout revisits the adjacency list when each vertex needs to iterate its neighbours during the attraction pass, and the iteration pattern becomes a performance bottleneck at scale.
"""

adds['GT_Layout'] = """

## Convergence and Parameter Tuning

The force-directed simulation does not always converge. If repulsion is too strong relative to attraction, the graph expands without bound; if attraction dominates, vertices collapse to a single point. The damping factor controls the rate at which kinetic energy leaves the system, and without damping the simulation oscillates indefinitely.

A practical stability condition is that the product of spring_k and damping exceeds a threshold that depends on the graph's topology. The map chooses default parameters that work for graphs up to a few hundred vertices. Beyond that, repulsion dominates and the layout drifts — the Barnes-Hut approximation is the standard remedy.

## Stress and Embedding Quality

Layout quality is usually measured by stress: the sum over pairs (u, v) of the squared difference between the graph-theoretic distance (edge count) and the spatial distance (Euclidean). A good layout has low stress, meaning the spatial distances approximate the graph distances.

```gdscript
func compute_stress() -> float:
    var stress := 0.0
    for u in vertices:
        var dists := bfs_distances(u)
        for v in vertices:
            if u == v: continue
            var gd: float = dists[v]
            var sd: float = (v.position - u.position).length()
            stress += (gd - sd) * (gd - sd)
    return stress
```

Stress-minimising layouts can be computed directly via majorisation, but force-directed algorithms are simpler and produce similar results for most graphs. The map uses force-directed because the algorithm's per-frame iterative nature is visually legible — the layout is seen to settle rather than appearing fully formed.

Within the sequence, Layout's physics borrowing prefigures the stress metric: springs pulled to rest length implicitly minimise graph-distance error. GT_Pathfinding will next treat the laid-out graph as a navigable space the learner can walk through.
"""

adds['GT_Pathfinding'] = """

## Heuristic Design

A* requires an admissible heuristic — one that never overestimates the true cost to the goal. For grid-based pathfinding, the Euclidean distance is always admissible (it is the optimum unconstrained path). The Manhattan distance is admissible when movement is restricted to orthogonal directions. Chebyshev distance is admissible when diagonal movement costs the same as orthogonal.

Choosing the tightest admissible heuristic matters for performance. A* with a perfectly tight heuristic explores only the optimal path — it wastes no work. A* with a loose heuristic degenerates toward Dijkstra. The map's configurable heuristic_weight lets the learner experiment with inadmissible heuristics (weight above 1.0) that are faster but lose the optimality guarantee.

## Data Structures

The open set is a priority queue. A binary heap supports push and pop in O(log n), which is adequate for typical maze sizes. A Fibonacci heap achieves amortised O(1) push and O(log n) pop, theoretically faster, but the constant factors make binary heaps competitive in practice.

The closed set records already-explored vertices. A hash set gives O(1) membership checks. Without the closed set, A* can loop indefinitely on graphs with cycles; with it, A* terminates after at most V vertex expansions.

```gdscript
class PriorityQueue:
    var heap: Array = []

    func push(item, priority: float) -> void:
        heap.append({"item": item, "pri": priority})
        _sift_up(heap.size() - 1)

    func pop():
        var top = heap[0]
        heap[0] = heap.pop_back()
        if heap.size() > 0:
            _sift_down(0)
        return top["item"]
```

Path reconstruction walks the came_from dictionary backward from goal to start, then reverses. The operation is O(path length).

Within the sequence, Pathfinding's algorithms operate on the same graph data structure GT_Foundations introduced. The maze itself is a grid graph where each cell is a vertex and each unblocked wall is an edge.
"""

adds['GT_Network_Analysis'] = """

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
"""

adds['GT_Connectivity'] = """

## Weakly vs Strongly Connected

A directed graph is strongly connected if every vertex can reach every other vertex. It is weakly connected if the underlying undirected graph (ignoring directions) is connected but the directed version is not. Most real directed graphs are weakly connected but not strongly connected.

The map's three-room architecture corresponds to a graph that is weakly connected globally (you can reach any room from any other if you ignore directions) but contains three strongly connected components internally (within each room, you can reach any vertex from any other).

## Condensation

Collapsing each SCC to a single vertex produces the condensation graph. The condensation is always a DAG — acyclic — because any cycle in the condensation would contradict the maximality of the components it spans.

```gdscript
func condense(sccs: Array) -> Dictionary:
    var scc_id := {}
    for i in range(sccs.size()):
        for v in sccs[i]:
            scc_id[v] = i
    var condensation := {}
    for e in edges:
        var a := scc_id[e.u]
        var b := scc_id[e.v]
        if a != b:
            condensation.get_or_add(a, {})[b] = null
    return condensation
```

Topological sort on the condensation gives a linear ordering of the components such that every directed edge runs from an earlier component to a later one.

## Articulation Points and Bridges

Tarjan's algorithm also finds articulation points (vertices whose removal disconnects the graph) and bridges (edges whose removal disconnects the graph). These are related to SCCs but live in undirected graphs and use the same DFS-with-lowlink machinery.

```gdscript
func find_bridges(graph) -> Array:
    var bridges := []
    var index := 0
    var indices := {}
    var lowlink := {}
    var dfs := func(u, parent):
        indices[u] = index
        lowlink[u] = index
        index += 1
        for v in graph[u]:
            if not indices.has(v):
                dfs.call(v, u)
                lowlink[u] = min(lowlink[u], lowlink[v])
                if lowlink[v] > indices[u]:
                    bridges.append([u, v])
            elif v != parent:
                lowlink[u] = min(lowlink[u], indices[v])
    for u in graph:
        if not indices.has(u):
            dfs.call(u, null)
    return bridges
```

Within the sequence, Connectivity is where direction becomes load-bearing. GT_Spanning_Trees will next ask how to cover a graph most cheaply.
"""

adds['GT_Spanning_Trees'] = """

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
"""

adds['GT_Flow'] = """

## Dinic's Algorithm

Dinic's algorithm is a faster alternative to Ford-Fulkerson for max-flow. It runs in O(V²·E) for general graphs and O(E·√V) for unit-capacity graphs, which is a substantial improvement over Edmonds-Karp's O(V·E²).

The algorithm operates in phases. Each phase builds a layered graph (BFS levels from the source) and finds a blocking flow in it — a flow that saturates at least one edge on every source-to-sink path. The blocking flow is found by repeated DFS. After the phase, the distance from source to sink in the residual graph increases, and the algorithm terminates when no path remains.

```gdscript
func dinic(source, sink) -> float:
    var total := 0.0
    while true:
        var levels := bfs_levels(source)
        if not levels.has(sink): break
        var blocking := find_blocking_flow(levels, source, sink)
        if blocking == 0: break
        total += blocking
    return total
```

## Min-Cost Max-Flow

A natural extension is to minimise cost subject to achieving maximum flow. This combines the max-flow problem with a shortest-path computation on a cost-weighted residual graph. The successive-shortest-path algorithm solves min-cost max-flow in O(F·V·E) where F is the flow value; cycle-cancelling algorithms achieve better worst-case bounds at the cost of more complex implementations.

## Applications Beyond Flow

Max-flow and min-cut have surprising applications. Bipartite matching reduces to max-flow. Graph partitioning uses min-cut to decompose large graphs. Image segmentation can be cast as a min-cut problem where pixels are vertices and colour similarities determine edge weights.

```gdscript
# Bipartite matching via max-flow
func bipartite_matching_via_flow(left, right, edges_lr) -> Dictionary:
    var s := "source"
    var t := "sink"
    var capacity := {}
    for u in left:
        capacity[[s, u]] = 1
    for v in right:
        capacity[[v, t]] = 1
    for e in edges_lr:
        capacity[[e.left, e.right]] = 1
    var _flow = max_flow_edmonds_karp(s, t, capacity)
    var matching := {}
    for e in edges_lr:
        if flow_on_edge[[e.left, e.right]] > 0:
            matching[e.right] = e.left
    return matching
```

Within the sequence, Flow's max-flow min-cut duality is the sequence's most elegant result. GT_Matching will next close the sequence by turning flow toward allocation.
"""

adds['GT_Matching'] = """

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
"""

for m, add in adds.items():
    p = Path(f'commons/maps/{m}/technical.md')
    t = p.read_text(encoding='utf-8')
    p.write_text(t.rstrip() + add, encoding='utf-8')

print('done', len(adds))
