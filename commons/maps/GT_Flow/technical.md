# GT Flow — Technical

A flow network is a directed graph with a source vertex s, a sink vertex t, and a capacity c(u,v) on every edge. The max-flow problem finds the maximum amount of flow that can be pushed from s to t without exceeding any edge's capacity.

Ford-Fulkerson repeatedly finds an augmenting path (a source-to-sink path with positive residual capacity) and pushes flow along it. With BFS-based augmentation (Edmonds-Karp), the running time is O(V·E²). Push-relabel algorithms are asymptotically faster — O(V²·E) or O(V³) in the standard variants — and often faster in practice because they operate locally.

```gdscript
# Edmonds-Karp — BFS augmentation
func max_flow(source, sink) -> float:
    var flow: Dictionary = {}  # edge -> amount
    var residual := build_residual()
    var total := 0.0
    while true:
        var path := bfs_augmenting_path(residual, source, sink)
        if path.is_empty(): break
        var bottleneck := INF
        for e in path:
            bottleneck = min(bottleneck, residual[e])
        for e in path:
            residual[e] -= bottleneck
            residual[reverse(e)] = residual.get(reverse(e), 0) + bottleneck
            flow[e] = flow.get(e, 0) + bottleneck
        total += bottleneck
    return total
```

The key data structure is the residual graph. For every edge (u,v) with capacity c and current flow f, the residual graph contains (u,v) with capacity c − f and (v,u) with capacity f. The reverse edges allow the algorithm to undo previously routed flow when a better routing becomes available.

The max-flow min-cut theorem says that the maximum flow equals the minimum s-t cut — the smallest total edge capacity whose removal disconnects s from t. The map displays the cut visibly as a line across the network, and the cut's capacity matches the flow on every frame.

The funnel geometry in the map makes the bottleneck physical. The narrowing exit means the flow is capped by the exit's capacity regardless of the internal network, and the learner can feel the constraint as a physical architecture rather than as a numerical bound.

Within the sequence, Flow is the throughput chapter. The next and final map, GT_Matching, closes the sequence by turning the flow machinery toward a different kind of optimisation.

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
