# Dijkstra's Algorithm

Gradient descent navigated a continuous landscape — sliding downhill toward a minimum, guided by the slope at each step. Dijkstra's algorithm solves the discrete version. The landscape is a graph. The slopes are edge weights. The destination is the shortest path from one node to every other. Edsger Dijkstra published the algorithm in 1959. It is the foundation of every GPS, every network router, every game pathfinder that operates on weighted graphs.

The principle is greedy. At each step, settle the unvisited node with the smallest known distance. Update its neighbors. Repeat. The greedy choice is provably optimal — once a node is settled, its distance will never improve. No backtracking. No revision. The algorithm expands outward from the source like a wavefront, and every node it touches is resolved permanently.

## The Graph: Nodes and Weighted Edges

A graph is a set of nodes connected by edges. Each edge has a weight — a cost of traversal. The artifact builds an 8-node graph with 12 edges:

```gdscript
var node_positions = [
    Vector3(-4, -2, 0), Vector3(-2, 0, 0), Vector3(0, -1, 0),
    Vector3(2, 1, 0), Vector3(4, 2, 0), Vector3(1, -2, 0),
    Vector3(-1, 2, 0), Vector3(3, -1, 0)
]

var connections = [
    [0, 1, 2.3], [0, 2, 1.8], [1, 2, 1.5], [1, 3, 2.1],
    [2, 3, 1.2], [2, 5, 2.7], [3, 4, 1.9], [3, 7, 2.4],
    [1, 6, 3.1], [6, 3, 1.7], [5, 7, 1.6], [7, 4, 1.4]
]
```

Each connection is a triple: `[from, to, weight]`. Node 0 connects to node 1 with weight 2.3, to node 2 with weight 1.8. The weights are not distances — the spatial positions of the nodes are irrelevant to the algorithm. Weight could represent time, cost, energy, congestion. The graph is abstract. The 3D layout just makes it visible.

Nodes are rendered as `CSGSphere3D` objects. Edges as `CSGCylinder3D` objects oriented between their endpoints:

```gdscript
var edge_cylinder = CSGCylinder3D.new()
edge_cylinder.height = from_pos.distance_to(to_pos)
edge_cylinder.radius = 0.03
edge_cylinder.position = (from_pos + to_pos) * 0.5

var direction = (to_pos - from_pos).normalized()
edge_cylinder.look_at_from_position(edge_cylinder.position, from_pos + direction, Vector3.UP)
edge_cylinder.rotate_object_local(Vector3.RIGHT, PI / 2)
```

The cylinder is placed at the midpoint of the two nodes, then rotated to align with the edge direction. The `look_at_from_position` call points one axis toward the source, and the `rotate_object_local` corrects for Godot's default cylinder orientation (vertical). This is the standard technique for drawing directed edges in 3D — position at midpoint, orient along the vector.

## Initialization: Infinity Everywhere

Before the first step, every node's distance is infinity — unknown. The source node gets distance zero. The previous-node dictionary (for path reconstruction) is null everywhere.

```gdscript
func initialize_dijkstra():
    distances.clear()
    previous.clear()
    visited.clear()
    unvisited.clear()

    start_node = "node_0"
    end_node = "node_4"
    path_found = false

    for node in graph_nodes:
        distances[node.id] = INF
        previous[node.id] = null
        visited[node.id] = false
        unvisited.append(node.id)

    distances[start_node] = 0.0
```

`INF` is Godot's built-in positive infinity constant. Every comparison with `INF` returns true — any finite distance is better than unknown. The `unvisited` array holds all node IDs. As the algorithm settles nodes, they are removed from this list. When the list empties or the target is reached, the algorithm terminates.

The visual state reflects this initialization. The start node is green. The end node is red. Everything else is dim — unsettled, unreached, distance unknown.

## The Step: Greedy Expansion

Each tick of the algorithm performs one step. Find the unvisited node with the smallest distance. Settle it. Relax its neighbors.

```gdscript
func dijkstra_step():
    if unvisited.size() == 0:
        path_found = true
        return

    # Find unvisited node with minimum distance
    var min_distance = INF
    var min_node = null

    for node_id in unvisited:
        if distances.get(node_id, INF) < min_distance:
            min_distance = distances.get(node_id, INF)
            min_node = node_id

    if min_node == null or min_distance == INF:
        path_found = true
        return

    current_node = min_node
    visited[current_node] = true
    unvisited.erase(current_node)

    # Relax neighbors
    for edge in graph_edges:
        var neighbor = null
        if edge.from_node == current_node:
            neighbor = edge.to_node
        elif edge.to_node == current_node:
            neighbor = edge.from_node
        else:
            continue

        if not visited.get(neighbor, false):
            var alt_distance = distances.get(current_node, INF) + edge.weight
            if alt_distance < distances.get(neighbor, INF):
                distances[neighbor] = alt_distance
                previous[neighbor] = current_node
```

The linear scan over `unvisited` to find the minimum is O(n). A priority queue (binary heap) would make this O(log n). For 8 nodes, the difference is negligible. For a production pathfinder with thousands of nodes, the priority queue is essential. The artifact uses the naive approach because it is readable — the learner sees exactly what "find the minimum" means.

Relaxation is the core operation. For each edge from the current node to an unvisited neighbor: compute the alternative distance (current node's distance plus edge weight). If the alternative is shorter than the neighbor's current distance, update it. This is the triangle inequality in action — if going through the current node is cheaper than the best known route, take it.

The `previous` dictionary records which node provided the shortest path to each neighbor. This is the breadcrumb trail for reconstructing the path after the algorithm finishes.

## Path Reconstruction

Once the algorithm terminates, the shortest distances are known. But the path itself — the sequence of nodes — requires backtracking through `previous`:

```gdscript
func reconstruct_path() -> Array:
    var path = []
    var current = end_node

    while current != null:
        path.push_front(current)
        current = previous.get(current)

    return path
```

Start at the end node. Look up its `previous` — the node that provided its shortest distance. Move to that node. Repeat until `previous` is null, which means the source has been reached. `push_front` builds the path in the correct order — source first, destination last.

The reconstructed path lights up in gold. The `is_edge_in_shortest_path` function checks whether each edge connects consecutive nodes in the path:

```gdscript
func is_edge_in_shortest_path(edge: DijkstraEdge) -> bool:
    if not path_found:
        return false

    var path = reconstruct_path()
    for i in range(path.size() - 1):
        if (path[i] == edge.from_node and path[i + 1] == edge.to_node) or \
           (path[i] == edge.to_node and path[i + 1] == edge.from_node):
            return true
    return false
```

The bidirectional check (`from == a and to == b` OR `from == b and to == a`) handles undirected edges. In this graph, every edge can be traversed in either direction.

## The Cartridge: Grid3D Integration

The `cartridge_dijkstra.gd` implements Dijkstra within the Grid3D substrate — a generalized framework for graph algorithm visualization. The cartridge interface standardizes the algorithm into `initialize` and `step` methods:

```gdscript
func step(positions: PackedVector3Array, states: PackedInt32Array,
        edges: Array, edge_states: PackedInt32Array,
        edge_weights: PackedFloat32Array) -> Dictionary:

    # Find unsettled node with minimum distance
    var u = -1
    var min_d = INF
    for i in range(_dist.size()):
        if _settled[i] == 0 and _dist[i] < min_d:
            min_d = _dist[i]
            u = i

    if u == -1 or min_d == INF:
        _done = true
        return {"done": true, "description": "Dijkstra complete"}

    # Settle u
    _settled[u] = 1
    states[u] = 2  # green

    # Relax neighbors
    for entry in _adj[u]:
        var v = entry["neighbor"]
        var w = entry["weight"]
        if _settled[v] == 0:
            var new_dist = _dist[u] + w
            if new_dist < _dist[v]:
                _dist[v] = new_dist
                states[v] = 1  # cyan: frontier
```

The cartridge returns a dictionary with updated states, highlight colors, and a text description of each step. Four states encode the algorithm's progress visually: unvisited (dim blue), frontier (cyan — discovered but not settled), settled (green — distance finalized), and source (magenta). The learner watches the frontier expand outward like a wave, with settled nodes turning green in its wake.

This is the same algorithm as the standalone artifact, but abstracted. The cartridge does not know about CSG nodes or materials. It manipulates arrays of states and weights. The Grid3D substrate handles rendering. The separation means the same Dijkstra logic can run on any graph topology — lattice, random, tree, complete — without changing a line of the algorithm code.

## Complexity and Guarantees

Dijkstra's algorithm runs in O(V²) with a naive minimum scan, or O((V + E) log V) with a binary heap. V is the number of vertices, E the number of edges. The algorithm visits every node at most once. For each visit, it relaxes every outgoing edge. The guarantee: when a node is settled, its distance is optimal.

This guarantee breaks if any edge weight is negative. A negative edge could make a settled node's distance suboptimal — a longer path through a negative edge might turn out cheaper. Dijkstra assumes all weights are non-negative. Bellman-Ford handles negative weights at the cost of O(V × E) runtime. In the VR space, all weights are positive — the world has no negative distances.

The greedy approach works because of the monotonicity of non-negative edge weights. If the current minimum distance is d, any path through an unsettled node must be at least d (since that node's distance is at least d and the remaining edges add non-negative weight). This is the invariant that makes the greedy choice globally optimal, not just locally convenient.

## Visualization as Understanding

The artifact runs in real time. Every 0.5 seconds, one Dijkstra step executes. The current node pulses yellow. Visited nodes glow purple. Unvisited nodes brighten as their tentative distances decrease — a color that encodes proximity before the algorithm confirms it.

```gdscript
if node.id == current_node:
    material.albedo_color = Color(1.0, 1.0, 0.2)  # yellow: active
elif node.visited:
    material.albedo_color = Color(0.8, 0.4, 0.8)  # purple: settled
else:
    var distance_intensity = 1.0 - min(node.distance / 10.0, 1.0)
    material.albedo_color = Color(
        0.5 + distance_intensity * 0.5, 0.5,
        0.5 + distance_intensity * 0.5, 1.0
    )
```

The distance-based color for unsettled nodes maps the range `[0, 10]` to brightness. Nodes with distance 0 (only the source) are bright. Nodes with distance 10+ are dim. Nodes in between interpolate. This makes the wavefront visible — a bright ring expanding outward from the source, with the unvisited interior still dark.

When the path is found, the algorithm resets after a pause and runs again. The learner can watch the same graph solve repeatedly, building intuition for the expansion pattern. The wavefront never goes backward. It never revisits. It commits to each decision and moves on.

## From Dijkstra to A*

Dijkstra explores uniformly — it has no notion of where the target is. It expands the wavefront in all directions equally, settling the nearest unvisited node regardless of whether that node is closer to or farther from the destination. For pathfinding between two specific points, this is wasteful. Nodes behind the source are settled even though they cannot contribute to the shortest path forward.

A* — which the next map explores — adds a heuristic. Instead of settling the node with the smallest known distance, A* settles the node with the smallest `f = g + h`, where `g` is the known distance (same as Dijkstra) and `h` is an estimate of the remaining distance to the target. The heuristic steers the search toward the goal. Dijkstra is A* with h = 0 — the special case where the algorithm admits complete ignorance of the destination.

In the QFEP framework, Dijkstra is pure F — structure, cost accounting, deterministic expansion. The heuristic in A* introduces prediction — an estimate of future cost that may be wrong but is useful. The tension between known cost (F) and estimated surprise (E(S)) is the same tension that runs through every search algorithm in this sequence.

## Possible Artifacts

**priority_queue_visualizer** — A side panel that displays the priority queue as a vertical bar chart. Each bar represents an unvisited node, its height proportional to its tentative distance. When the minimum is extracted, the shortest bar highlights and disappears. When a neighbor is relaxed, its bar shrinks. The learner sees the data structure that drives the algorithm — not just the graph state but the decision-making mechanism behind it.

**dijkstra_vs_bfs_comparator** — Side-by-side graphs with the same topology. The left runs Dijkstra (weighted). The right runs BFS (unweighted — treating all edges as cost 1). Both start from the same source. The expansion patterns differ: BFS spreads uniformly by hop count; Dijkstra spreads by accumulated weight, reaching nearby-in-weight nodes before nearby-in-hops nodes. A counter shows nodes settled by each at every step.

**negative_edge_breaker** — An interactive artifact where the learner can set one edge weight to a negative value. Dijkstra runs and produces a path. A correct algorithm (Bellman-Ford) runs in parallel and produces the true shortest path. When the two disagree, both paths light up in different colors — the learner sees exactly how a negative edge breaks the greedy guarantee.
