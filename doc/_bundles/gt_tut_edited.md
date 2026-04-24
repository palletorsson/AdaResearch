<<<ADA_BUNDLE>>>
sequence: graphtheory
file: tutorial.md
maps: 8
skipped_passing: 0
created: 2026-04-24T03:25:00
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: GT_Foundations>>>
# GT Foundations

A graph is vertices and edges. The Königsberg bridges have no Eulerian walk.

Build a graph.

```gdscript
class_name Graph

var vertices: Array = []
var edges: Array = []  # array of [a, b] pairs

func add_vertex(id) -> void:
    if not id in vertices:
        vertices.append(id)

func add_edge(a, b) -> void:
    add_vertex(a); add_vertex(b)
    edges.append([a, b])
```

Unordered pairs. The graph is undirected.

Count degrees.

```gdscript
func degree(v) -> int:
    var count := 0
    for edge in edges:
        if edge[0] == v or edge[1] == v:
            count += 1
    return count

func degrees() -> Dictionary:
    var d: Dictionary = {}
    for v in vertices:
        d[v] = degree(v)
    return d
```

Degree is the count of edges touching a vertex. Koenigsberg has four vertices of odd degree.

Test Eulerian walk.

```gdscript
func eulerian_walk_possible() -> bool:
    var odd_count := 0
    for v in vertices:
        if degree(v) % 2 == 1:
            odd_count += 1
    return odd_count == 0 or odd_count == 2
```

At most two odd-degree vertices. Zero means a closed tour; two means start and end at the odd vertices.

Build the Königsberg graph.

```gdscript
func build_konigsberg() -> Graph:
    var g := Graph.new()
    for land in ["A", "B", "C", "D"]:
        g.add_vertex(land)
    # Seven bridges
    g.add_edge("A", "B"); g.add_edge("A", "B")  # two bridges
    g.add_edge("A", "C"); g.add_edge("A", "C")  # two bridges
    g.add_edge("A", "D"); g.add_edge("B", "D"); g.add_edge("C", "D")
    return g
```

Four land masses, seven bridges. All four vertices have odd degree; no Eulerian walk exists.

Build an adjacency list.

```gdscript
func adjacency_list() -> Dictionary:
    var adj: Dictionary = {}
    for v in vertices: adj[v] = []
    for edge in edges:
        adj[edge[0]].append(edge[1])
        adj[edge[1]].append(edge[0])
    return adj
```

Faster neighbour lookup than iterating edges. Space is O(V + E).

Spawn graph vertices as spheres.

```gdscript
func render_vertices(positions: Dictionary) -> void:
    for v in vertices:
        var sphere := MeshInstance3D.new()
        sphere.mesh = SphereMesh.new()
        sphere.position = positions[v]
        sphere.set_meta("vertex_id", v)
        add_child(sphere)
```

One sphere per vertex. Metadata ties the visual to the graph vertex.

Spawn edges as cylinders.

```gdscript
func render_edges(positions: Dictionary) -> void:
    for edge in edges:
        var a: Vector3 = positions[edge[0]]
        var b: Vector3 = positions[edge[1]]
        spawn_cylinder_between(a, b)
```

Cylinder stretched between endpoints. Multiple edges on the same pair produce overlapping cylinders.

You can now build a graph, compute degrees, test Euler's walk condition, render vertices and edges, and reproduce the Königsberg problem. GT_Layout extends the graph into a force-directed layout.

<<<MAP: GT_Layout>>>
# GT Layout

Force-directed layout. Nodes repel; edges pull.

Track vertex positions and velocities.

```gdscript
var positions: Dictionary = {}  # vertex_id -> Vector3
var velocities: Dictionary = {}
```

Two dictionaries keyed on vertex id. Initialised with random positions and zero velocities.

Compute repulsion.

```gdscript
@export var repulsion_k: float = 1.0

func repulsion_force_on(v) -> Vector3:
    var total := Vector3.ZERO
    for other in vertices:
        if other == v: continue
        var direction: Vector3 = positions[v] - positions[other]
        var distance: float = direction.length() + 0.01
        total += direction.normalized() * repulsion_k / (distance * distance)
    return total
```

Inverse-square repulsion. Every pair of vertices pushes apart.

Compute attraction.

```gdscript
@export var spring_k: float = 0.5

func spring_force_on(v) -> Vector3:
    var total := Vector3.ZERO
    for edge in edges:
        if edge[0] == v or edge[1] == v:
            var other = edge[0] if edge[1] == v else edge[1]
            var direction: Vector3 = positions[other] - positions[v]
            total += direction * spring_k
    return total
```

Linear attraction along edges. Connected vertices pull together.

Step the simulation.

```gdscript
@export var damping: float = 0.9

func _physics_process(delta: float) -> void:
    for v in vertices:
        var force: Vector3 = repulsion_force_on(v) + spring_force_on(v)
        velocities[v] += force * delta
        velocities[v] *= damping
        positions[v] += velocities[v] * delta
    update_visual_positions()
```

Each step: compute forces, integrate, damp. The graph settles to equilibrium.

Update visuals.

```gdscript
func update_visual_positions() -> void:
    for child in get_children():
        if child.has_meta("vertex_id"):
            var v = child.get_meta("vertex_id")
            child.global_position = positions[v]
```

Visual meshes follow the computed positions. Update every frame.

Compute layout stress.

```gdscript
func layout_stress() -> float:
    var adj: Dictionary = adjacency_list()
    var total: float = 0.0
    for u in vertices:
        var distances: Dictionary = bfs_distances(u, adj)
        for v in vertices:
            if u == v: continue
            var gd: int = distances[v]
            var sd: float = positions[u].distance_to(positions[v])
            total += (gd - sd) * (gd - sd)
    return total
```

Stress measures mismatch between graph distances and spatial distances. Lower is better.

Seed random positions.

```gdscript
func seed_positions(bounds: Vector3) -> void:
    for v in vertices:
        positions[v] = Vector3(randf(), randf(), randf()) * bounds
        velocities[v] = Vector3.ZERO
```

Random initial positions in a bounded volume. The simulation will settle to a layout.

You can now build a force-directed layout with repulsion and spring attraction, integrate the dynamics, update visuals, and measure layout stress. GT_Pathfinding extends into maze navigation.

<<<MAP: GT_Pathfinding>>>
# GT Pathfinding

The maze is a graph. Walk it with DFS, BFS, or A*.

Build a grid graph.

```gdscript
func grid_graph(size: Vector2i) -> Graph:
    var g := Graph.new()
    for y in size.y:
        for x in size.x:
            g.add_vertex(Vector2i(x, y))
    for y in size.y:
        for x in size.x - 1:
            g.add_edge(Vector2i(x, y), Vector2i(x + 1, y))
    for y in size.y - 1:
        for x in size.x:
            g.add_edge(Vector2i(x, y), Vector2i(x, y + 1))
    return g
```

Every cell is a vertex; adjacent cells are connected by edges. The base for maze algorithms.

Remove random edges to form walls.

```gdscript
func remove_walls(g: Graph, remove_ratio: float = 0.3) -> void:
    var to_remove: Array = []
    for edge in g.edges:
        if randf() < remove_ratio:
            to_remove.append(edge)
    for edge in to_remove:
        g.edges.erase(edge)
```

Removing edges creates walls. The maze is the resulting sparse graph.

Depth-first search.

```gdscript
func dfs(g: Graph, start, goal) -> Array:
    var stack: Array = [start]
    var came_from: Dictionary = {start: null}
    while not stack.is_empty():
        var current = stack.pop_back()
        if current == goal: break
        for neighbour in g.neighbours(current):
            if not neighbour in came_from:
                came_from[neighbour] = current
                stack.push_back(neighbour)
    return reconstruct_path(came_from, goal)
```

Stack-based. Goes deep; backtracks on dead ends.

Breadth-first search.

```gdscript
func bfs(g: Graph, start, goal) -> Array:
    var queue: Array = [start]
    var came_from: Dictionary = {start: null}
    while not queue.is_empty():
        var current = queue.pop_front()
        if current == goal: break
        for neighbour in g.neighbours(current):
            if not neighbour in came_from:
                came_from[neighbour] = current
                queue.push_back(neighbour)
    return reconstruct_path(came_from, goal)
```

Queue-based. Explores in concentric waves. Finds the shortest path on unweighted graphs.

Reconstruct a path.

```gdscript
func reconstruct_path(came_from: Dictionary, goal) -> Array:
    var path: Array = []
    var current = goal
    while current != null:
        path.push_front(current)
        current = came_from[current]
    return path
```

Walk backward from goal to start via the came_from dictionary. Reverse order.

A* search.

```gdscript
func astar(g: Graph, start, goal, heuristic: Callable) -> Array:
    var open := PriorityQueue.new()
    open.push(start, 0.0)
    var came_from: Dictionary = {start: null}
    var g_score: Dictionary = {start: 0.0}
    while not open.is_empty():
        var current = open.pop()
        if current == goal: break
        for neighbour in g.neighbours(current):
            var tentative: float = g_score[current] + 1.0
            if tentative < g_score.get(neighbour, INF):
                came_from[neighbour] = current
                g_score[neighbour] = tentative
                var f: float = tentative + heuristic.call(neighbour, goal)
                open.push(neighbour, f)
    return reconstruct_path(came_from, goal)
```

Priority queue orders by estimated total cost. The heuristic focuses the search.

Manhattan distance heuristic.

```gdscript
func manhattan(a: Vector2i, b: Vector2i) -> float:
    return abs(a.x - b.x) + abs(a.y - b.y)
```

Sum of axis-aligned distances. Admissible for 4-connected grids.

You can now build a grid graph, carve walls, implement DFS, BFS, A*, reconstruct paths, and use Manhattan distance as a heuristic. GT_Network_Analysis extends into centrality measures.

<<<MAP: GT_Network_Analysis>>>
# GT Network Analysis

Which node matters most? Degree, betweenness, eigenvector.

Compute degree centrality.

```gdscript
func degree_centrality(g: Graph) -> Dictionary:
    var c: Dictionary = {}
    for v in g.vertices:
        c[v] = float(g.degree(v)) / (g.vertices.size() - 1)
    return c
```

Normalised by the maximum possible degree. Values in [0, 1].

Compute betweenness via Brandes.

```gdscript
func betweenness_centrality(g: Graph) -> Dictionary:
    var c: Dictionary = {}
    for v in g.vertices: c[v] = 0.0
    for s in g.vertices:
        var dist: Dictionary = {s: 0}
        var sigma: Dictionary = {s: 1}
        var pred: Dictionary = {}
        var queue: Array = [s]
        var stack: Array = []
        while not queue.is_empty():
            var u = queue.pop_front()
            stack.push_back(u)
            for w in g.neighbours(u):
                if not w in dist:
                    dist[w] = dist[u] + 1
                    queue.push_back(w)
                if dist[w] == dist[u] + 1:
                    sigma[w] = sigma.get(w, 0) + sigma[u]
                    pred.get_or_add(w, [])
                    pred[w].append(u)
        var delta: Dictionary = {}
        for v in g.vertices: delta[v] = 0.0
        while not stack.is_empty():
            var w = stack.pop_back()
            for u in pred.get(w, []):
                delta[u] += sigma[u] / float(sigma[w]) * (1 + delta[w])
            if w != s:
                c[w] += delta[w]
    return c
```

Brandes' algorithm computes betweenness in O(V·(V+E)). Counts shortest paths passing through each vertex.

Compute eigenvector centrality via power iteration.

```gdscript
func eigenvector_centrality(g: Graph, iterations: int = 50) -> Dictionary:
    var c: Dictionary = {}
    for v in g.vertices: c[v] = 1.0
    for _i in iterations:
        var next: Dictionary = {}
        for v in g.vertices:
            next[v] = 0.0
            for u in g.neighbours(v):
                next[v] += c[u]
        var norm: float = 0.0
        for v in g.vertices: norm += next[v] * next[v]
        norm = sqrt(norm)
        if norm > 0:
            for v in g.vertices: next[v] /= norm
        c = next
    return c
```

Power iteration on the adjacency matrix. Converges to the dominant eigenvector.

Compute closeness centrality.

```gdscript
func closeness_centrality(g: Graph) -> Dictionary:
    var c: Dictionary = {}
    for v in g.vertices:
        var total: int = 0
        var distances: Dictionary = bfs_distances(v, g.adjacency_list())
        for other in distances:
            total += distances[other]
        c[v] = 1.0 / total if total > 0 else 0.0
    return c
```

Reciprocal of average shortest-path distance. High closeness means short average reach.

Colour vertices by centrality.

```gdscript
func colour_by_centrality(centrality: Dictionary) -> void:
    var max_c: float = centrality.values().max()
    for child in get_children():
        if child.has_meta("vertex_id"):
            var v = child.get_meta("vertex_id")
            var t: float = centrality[v] / max_c if max_c > 0 else 0.0
            var mat: StandardMaterial3D = child.material_override
            mat.albedo_color = Color.BLUE.lerp(Color.RED, t)
```

Blue for low centrality, red for high. Visual ranking of importance.

You can now compute degree, betweenness, eigenvector, and closeness centralities, and colour the graph by any of them. GT_Connectivity extends into directed graphs.

<<<MAP: GT_Connectivity>>>
# GT Connectivity

Directed edges. Strong components. Tarjan's algorithm.

Build a directed graph.

```gdscript
class_name DirectedGraph

var vertices: Array = []
var edges_out: Dictionary = {}  # vertex -> array of out-neighbours

func add_edge(from_v, to_v) -> void:
    if not from_v in vertices: vertices.append(from_v)
    if not to_v in vertices: vertices.append(to_v)
    edges_out.get_or_add(from_v, [])
    edges_out[from_v].append(to_v)
```

Edges have direction. Out-neighbours and in-neighbours are separate.

Compute Tarjan's strongly connected components.

```gdscript
func tarjan_scc(g: DirectedGraph) -> Array:
    var index: int = 0
    var stack: Array = []
    var on_stack: Dictionary = {}
    var indices: Dictionary = {}
    var lowlink: Dictionary = {}
    var sccs: Array = []
    
    var strong_connect = func(v):
        indices[v] = index
        lowlink[v] = index
        index += 1
        stack.push_back(v)
        on_stack[v] = true
        for w in g.edges_out.get(v, []):
            if not w in indices:
                strong_connect.call(w)
                lowlink[v] = min(lowlink[v], lowlink[w])
            elif on_stack.get(w, false):
                lowlink[v] = min(lowlink[v], indices[w])
        if lowlink[v] == indices[v]:
            var component: Array = []
            while true:
                var w = stack.pop_back()
                on_stack[w] = false
                component.append(w)
                if w == v: break
            sccs.append(component)
    
    for v in g.vertices:
        if not v in indices:
            strong_connect.call(v)
    return sccs
```

Single DFS pass with the lowlink invariant. Components emerge when the DFS returns to a root.

Compute the condensation.

```gdscript
func condensation(g: DirectedGraph, sccs: Array) -> DirectedGraph:
    var scc_id: Dictionary = {}
    for i in sccs.size():
        for v in sccs[i]:
            scc_id[v] = i
    var cond := DirectedGraph.new()
    for edge_from in g.edges_out:
        for edge_to in g.edges_out[edge_from]:
            var a: int = scc_id[edge_from]
            var b: int = scc_id[edge_to]
            if a != b:
                cond.add_edge(a, b)
    return cond
```

Each SCC becomes a single vertex. The condensation is always a DAG.

Topological sort via Kahn.

```gdscript
func topological_sort(g: DirectedGraph) -> Array:
    var in_degree: Dictionary = {}
    for v in g.vertices: in_degree[v] = 0
    for u in g.edges_out:
        for v in g.edges_out[u]:
            in_degree[v] = in_degree.get(v, 0) + 1
    var queue: Array = []
    for v in g.vertices:
        if in_degree[v] == 0:
            queue.push_back(v)
    var result: Array = []
    while not queue.is_empty():
        var u = queue.pop_front()
        result.push_back(u)
        for v in g.edges_out.get(u, []):
            in_degree[v] -= 1
            if in_degree[v] == 0:
                queue.push_back(v)
    return result
```

Remove zero-in-degree vertices one at a time. The order is the topological sort.

Spawn component rooms.

```gdscript
func spawn_scc_rooms(sccs: Array) -> void:
    for i in sccs.size():
        var room := COMPONENT_ROOM_SCENE.instantiate()
        room.position = Vector3(i * 5, 0, 0)
        room.populate(sccs[i])
        add_child(room)
```

Each SCC becomes a physical room. The learner walks between rooms via one-way doors.

Highlight one-way edges.

```gdscript
func render_inter_room_edges(cond: DirectedGraph, room_positions: Dictionary) -> void:
    for u in cond.edges_out:
        for v in cond.edges_out[u]:
            var start: Vector3 = room_positions[u]
            var end: Vector3 = room_positions[v]
            spawn_directional_arrow(start, end)
```

Arrows between rooms show the directed edges in the condensation. The DAG structure is physically legible.

You can now build a directed graph, find strongly connected components via Tarjan, compute the condensation, topologically sort the DAG, and render SCCs as rooms connected by one-way arrows. GT_Spanning_Trees extends to optimal connection.

<<<MAP: GT_Spanning_Trees>>>
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

<<<MAP: GT_Flow>>>
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

<<<MAP: GT_Matching>>>
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
