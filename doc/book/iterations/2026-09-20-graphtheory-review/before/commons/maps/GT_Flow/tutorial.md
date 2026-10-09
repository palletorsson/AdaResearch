# GT Flow

Max flow from source to sink. Edmonds-Karp via BFS.

Build a flow network.

```gdscript
class_name FlowNetwork

var capacity: Dictionary = {}  # [u, v] -> capacity
var flow: Dictionary = {}       # [u, v] -> current flow

func add_edge(u, v, cap: float) -> void:
    capacity[[u, v]] = cap
    flow[[u, v]] = 0.0
    flow[[v, u]] = 0.0  # reverse edge with zero capacity
    if not capacity.has([v, u]):
        capacity[[v, u]] = 0.0
```

Each edge has a capacity. Reverse edges are created automatically for residual flow.

Residual capacity.

```gdscript
func residual(u, v) -> float:
    return capacity.get([u, v], 0.0) - flow.get([u, v], 0.0)
```

How much more can flow along (u, v). Forward flow reduces it; reverse flow increases it.

BFS for augmenting path.

```gdscript
func bfs_augmenting(source, sink) -> Array:
    var came_from: Dictionary = {source: null}
    var queue: Array = [source]
    while not queue.is_empty():
        var u = queue.pop_front()
        if u == sink: break
        for v in all_vertices():
            if v in came_from: continue
            if residual(u, v) > 0:
                came_from[v] = u
                queue.push_back(v)
    if not sink in came_from: return []
    return reconstruct_path(came_from, sink)
```

Standard BFS; edges are considered only if they have residual capacity. Returns the shortest augmenting path.

Push flow along the path.

```gdscript
func push_flow(path: Array) -> float:
    var bottleneck: float = INF
    for i in range(path.size() - 1):
        bottleneck = min(bottleneck, residual(path[i], path[i + 1]))
    for i in range(path.size() - 1):
        flow[[path[i], path[i + 1]]] += bottleneck
        flow[[path[i + 1], path[i]]] -= bottleneck
    return bottleneck
```

Find the path's bottleneck and push that amount. Reverse edges track allowing flow to be undone.

Edmonds-Karp loop.

```gdscript
func max_flow(source, sink) -> float:
    var total: float = 0.0
    while true:
        var path := bfs_augmenting(source, sink)
        if path.is_empty(): break
        total += push_flow(path)
    return total
```

Push flow along augmenting paths until no more exist. The total is the maximum flow.

Find the min cut.

```gdscript
func min_cut(source) -> Array:
    var reachable: Array = [source]
    var visited: Dictionary = {source: true}
    var queue: Array = [source]
    while not queue.is_empty():
        var u = queue.pop_front()
        for v in all_vertices():
            if v in visited: continue
            if residual(u, v) > 0:
                visited[v] = true
                reachable.append(v)
                queue.push_back(v)
    var cut: Array = []
    for u in reachable:
        for v in all_vertices():
            if not v in visited and capacity.get([u, v], 0) > 0:
                cut.append([u, v])
    return cut
```

After max flow, the min cut is the set of saturated edges from reachable to unreachable vertices. Their total capacity equals the max flow.

Animate flow propagation.

```gdscript
func animate_push(path: Array, amount: float) -> void:
    for i in range(path.size() - 1):
        var start: Vector3 = position_of(path[i])
        var end: Vector3 = position_of(path[i + 1])
        spawn_flow_particle(start, end, amount)
```

Particles travel along the augmenting path. Scale reflects the flow amount.

You can now build a flow network, find augmenting paths via BFS, push flow along them, compute the max flow via Edmonds-Karp, extract the min cut, and animate flow propagation. GT_Matching closes the sequence.
