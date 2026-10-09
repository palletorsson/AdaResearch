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
