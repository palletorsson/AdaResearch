# Primitives Polyhedra

Five regular polyhedra exist in 3D. The constraint that produces them is angular.

Define a regular polyhedron by its face count.

```gdscript
enum Solid { TETRAHEDRON, CUBE, OCTAHEDRON, DODECAHEDRON, ICOSAHEDRON }

func face_count(solid: Solid) -> int:
    match solid:
        Solid.TETRAHEDRON: return 4
        Solid.CUBE: return 6
        Solid.OCTAHEDRON: return 8
        Solid.DODECAHEDRON: return 12
        Solid.ICOSAHEDRON: return 20
    return 0
```

Five solids. Four, six, eight, twelve, twenty faces respectively. Nothing between or beyond.

Spawn a tetrahedron via four vertices.

```gdscript
func tetrahedron_vertices() -> Array:
    return [
        Vector3(1, 1, 1),
        Vector3(1, -1, -1),
        Vector3(-1, 1, -1),
        Vector3(-1, -1, 1),
    ]
```

Alternating corners of a cube form a regular tetrahedron. Every pair of vertices is the same distance apart — the tetrahedron's edge length.

Check the angular constraint.

```gdscript
func interior_angle_sum(solid: Solid) -> float:
    # Triangles: 60°, squares: 90°, pentagons: 108°
    # Meeting at a vertex: interior_angle × faces_per_vertex < 360°
    match solid:
        Solid.TETRAHEDRON: return 60 * 3  # 180
        Solid.CUBE: return 90 * 3         # 270
        Solid.OCTAHEDRON: return 60 * 4   # 240
        Solid.DODECAHEDRON: return 108 * 3 # 324
        Solid.ICOSAHEDRON: return 60 * 5  # 300
    return 0
```

Every regular solid's interior-angle sum at a vertex is less than 360°. Six equilateral triangles (360°) collapse into a plane; five or fewer rise into a point.

Compute Euler's formula.

```gdscript
func euler_check(V: int, E: int, F: int) -> bool:
    return V - E + F == 2
```

Every convex polyhedron satisfies V - E + F = 2. For a cube: 8 - 12 + 6 = 2. For an icosahedron: 12 - 30 + 20 = 2.

Spawn a polyhedron mesh.

```gdscript
func spawn_polyhedron(solid: Solid) -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    match solid:
        Solid.CUBE:
            mesh.mesh = BoxMesh.new()
        Solid.TETRAHEDRON:
            mesh.mesh = build_tetrahedron_mesh()
        # ... etc
    add_child(mesh)
    return mesh
```

Godot provides BoxMesh directly. The other four solids need custom SurfaceTool construction.

Compute a polyhedron's volume.

```gdscript
func solid_volume(solid: Solid, edge_length: float) -> float:
    var a := edge_length
    match solid:
        Solid.TETRAHEDRON: return a * a * a / (6.0 * sqrt(2))
        Solid.CUBE: return a * a * a
        Solid.OCTAHEDRON: return a * a * a * sqrt(2) / 3.0
        Solid.DODECAHEDRON: return a * a * a * (15 + 7 * sqrt(5)) / 4.0
        Solid.ICOSAHEDRON: return a * a * a * 5 * (3 + sqrt(5)) / 12.0
    return 0.0
```

Closed-form volumes from the edge length. The constants are irrational — these are continuous 3D objects, not grid artifacts.

You can now spawn any of the five regular polyhedra, verify the angular constraint that produces them, and compute their volumes. Point_Animatedcube will next animate a cube through a deliberate transformation.
