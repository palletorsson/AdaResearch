# Bricolage_Dome - Technical

## Core Concept in Code

Geodesic dome generation through icosahedron subdivision:

```gdscript
# Geodesic dome generator
class GeodesicDome:
    var vertices: Array[Vector3]
    var faces: Array[Triangle]  # Each face references 3 vertex indices
    var frequency: int  # Subdivision level

    func generate(freq: int, radius: float) -> void:
        frequency = freq
        _create_icosahedron(radius)
        for i in range(frequency):
            _subdivide()
            _project_to_sphere(radius)

    func _create_icosahedron(radius: float):
        # Golden ratio for icosahedron proportions
        var phi = (1.0 + sqrt(5.0)) / 2.0

        # 12 vertices of icosahedron
        vertices = [
            Vector3(-1, phi, 0).normalized() * radius,
            Vector3(1, phi, 0).normalized() * radius,
            Vector3(-1, -phi, 0).normalized() * radius,
            Vector3(1, -phi, 0).normalized() * radius,
            Vector3(0, -1, phi).normalized() * radius,
            Vector3(0, 1, phi).normalized() * radius,
            Vector3(0, -1, -phi).normalized() * radius,
            Vector3(0, 1, -phi).normalized() * radius,
            Vector3(phi, 0, -1).normalized() * radius,
            Vector3(phi, 0, 1).normalized() * radius,
            Vector3(-phi, 0, -1).normalized() * radius,
            Vector3(-phi, 0, 1).normalized() * radius,
        ]

        # 20 triangular faces (indices into vertices array)
        faces = [
            Triangle.new(0, 11, 5), Triangle.new(0, 5, 1),
            Triangle.new(0, 1, 7), Triangle.new(0, 7, 10),
            Triangle.new(0, 10, 11), Triangle.new(1, 5, 9),
            Triangle.new(5, 11, 4), Triangle.new(11, 10, 2),
            Triangle.new(10, 7, 6), Triangle.new(7, 1, 8),
            Triangle.new(3, 9, 4), Triangle.new(3, 4, 2),
            Triangle.new(3, 2, 6), Triangle.new(3, 6, 8),
            Triangle.new(3, 8, 9), Triangle.new(4, 9, 5),
            Triangle.new(2, 4, 11), Triangle.new(6, 2, 10),
            Triangle.new(8, 6, 7), Triangle.new(9, 8, 1),
        ]

    func _subdivide():
        var new_faces = []
        var edge_midpoints = {}  # Cache to avoid duplicate vertices

        for face in faces:
            # Get or create midpoints for each edge
            var mid_a = _get_midpoint(face.v0, face.v1, edge_midpoints)
            var mid_b = _get_midpoint(face.v1, face.v2, edge_midpoints)
            var mid_c = _get_midpoint(face.v2, face.v0, edge_midpoints)

            # Replace 1 triangle with 4
            new_faces.append(Triangle.new(face.v0, mid_a, mid_c))
            new_faces.append(Triangle.new(mid_a, face.v1, mid_b))
            new_faces.append(Triangle.new(mid_c, mid_b, face.v2))
            new_faces.append(Triangle.new(mid_a, mid_b, mid_c))

        faces = new_faces

    func _project_to_sphere(radius: float):
        for i in range(vertices.size()):
            vertices[i] = vertices[i].normalized() * radius
```

## Strut Generation

```gdscript
# Convert dome mesh to struts (edges)
class DomeStruts:
    var struts: Array[Strut]

    func generate_from_dome(dome: GeodesicDome) -> void:
        var edges = {}  # Set of unique edges

        for face in dome.faces:
            _add_edge(face.v0, face.v1, edges, dome.vertices)
            _add_edge(face.v1, face.v2, edges, dome.vertices)
            _add_edge(face.v2, face.v0, edges, dome.vertices)

        struts = edges.values()

    func _add_edge(v0: int, v1: int, edges: Dictionary, vertices: Array):
        var key = _edge_key(v0, v1)
        if not edges.has(key):
            edges[key] = Strut.new(
                vertices[v0],
                vertices[v1],
                vertices[v0].distance_to(vertices[v1])
            )

    func _edge_key(v0: int, v1: int) -> String:
        return "%d-%d" % [min(v0, v1), max(v0, v1)]

# Strut class
class Strut:
    var start: Vector3
    var end: Vector3
    var length: float
    var type: String  # "A", "B", "C" based on length category

    func _init(s: Vector3, e: Vector3, l: float):
        start = s
        end = e
        length = l
        type = categorize_length(l)
```

## Interactive Dome Builder

```gdscript
# Dome construction interface
class DomeBuilder extends InteractableBase:
    var target_dome: GeodesicDome
    var placed_struts: Array[Strut]
    var hub_positions: Array[Vector3]
    var current_frequency: int = 1

    func _ready():
        target_dome = GeodesicDome.new()
        target_dome.generate(current_frequency, 1.0)
        hub_positions = target_dome.vertices.duplicate()
        _show_ghost_structure()

    func on_strut_placed(strut: Strut) -> bool:
        # Check if strut connects valid hubs
        var start_hub = find_nearest_hub(strut.start)
        var end_hub = find_nearest_hub(strut.end)

        if start_hub == null or end_hub == null:
            return false  # Invalid placement

        if is_duplicate_strut(start_hub, end_hub):
            return false  # Already placed

        if not is_valid_edge(start_hub, end_hub):
            return false  # Not part of target structure

        placed_struts.append(strut)
        _update_progress()
        return true

    func is_complete() -> bool:
        var target_struts = DomeStruts.new()
        target_struts.generate_from_dome(target_dome)
        return placed_struts.size() >= target_struts.struts.size()
```

## Fuller's Insight in Code

```gdscript
# The dome emerges from constraints, not design
func demonstrate_emergence():
    # Start with just constraints:
    var constraints = [
        TriangulationConstraint.new(),      # All faces must be triangles
        ConnectivityConstraint.new(),        # All edges must connect
        SphericalConstraint.new(radius=1.0)  # All vertices on sphere
    ]

    # Start with random points on sphere
    var points = generate_random_sphere_points(42)

    # Apply constraint relaxation
    for iteration in range(1000):
        for c in constraints:
            points = c.relax(points)

    # Result: approaches geodesic structure
    # The dome isn't designed—it's what these constraints produce
```

## Why These Design Choices

1. **Icosahedron starting point**: Shows dome isn't arbitrary—starts from platonic solid
2. **Subdivision demonstration**: The algorithm is visible, not hidden
3. **Strut inventory**: Emphasizes that dome uses near-identical parts (bricoleur inventory)
4. **Interactive builder**: Construction reveals the structure
5. **Higher spawn point**: Lets player see dome geometry from above

## Key Takeaway

The geodesic dome is not an invention but a discovery—what triangulated struts want to become when arranged on a sphere. Fuller found the dome; he didn't make it. This is bricolage at scale: local constraints (triangulate, connect, sphere) producing global optimum (maximum strength, minimum material).
