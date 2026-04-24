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
