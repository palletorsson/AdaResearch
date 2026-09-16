# Polyhedra: closure, collision and passage

## The Trihedron: Three Faces Meeting at a Vertex

A trihedron is a 3D corner where three triangular faces meet at a single point. It's not a closed solid - it's a **spatial junction**.

```gdscript
# Trihedron: Three faces sharing one vertex
var apex = Vector3(0, 1, 0)  # Shared vertex

# Three triangular faces radiating from apex
var face_1 = [apex, Vector3(1, 0, 0), Vector3(0, 0, 0)]
var face_2 = [apex, Vector3(0, 0, 0), Vector3(0, 0, 1)]
var face_3 = [apex, Vector3(0, 0, 1), Vector3(1, 0, 0)]
```

The trihedron demonstrates **how 2D triangles can exist in 3D space** at angles to each other, not confined to a single plane.

## The Tetrahedron: Simplest 3D Solid

The tetrahedron is the simplest Platonic solid - four vertices, six edges, four triangular faces.

```gdscript
# Tetrahedron vertices (regular)
var v0 = Vector3( 1,  1,  1)
var v1 = Vector3( 1, -1, -1)
var v2 = Vector3(-1,  1, -1)
var v3 = Vector3(-1, -1,  1)

# Properties
# 4 vertices
# 6 edges: v0-v1, v0-v2, v0-v3, v1-v2, v1-v3, v2-v3
# 4 faces: all equilateral triangles
# 1 enclosed volume
```

## Creating a Tetrahedron Mesh

```gdscript
extends Node3D

func _ready():
    create_tetrahedron()

func create_tetrahedron():
    # Define vertices
    var v0 = Vector3( 1,  1,  1)
    var v1 = Vector3( 1, -1, -1)
    var v2 = Vector3(-1,  1, -1)
    var v3 = Vector3(-1, -1,  1)

    # Create mesh
    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

    # Face 1: v0, v1, v2
    add_triangle(surface_tool, v0, v1, v2)

    # Face 2: v0, v2, v3
    add_triangle(surface_tool, v0, v2, v3)

    # Face 3: v0, v3, v1
    add_triangle(surface_tool, v0, v3, v1)

    # Face 4: v1, v3, v2 (bottom face)
    add_triangle(surface_tool, v1, v3, v2)

    var mesh = surface_tool.commit()

    var mesh_instance = MeshInstance3D.new()
    mesh_instance.mesh = mesh
    add_child(mesh_instance)

func add_triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3):
    var normal = (b - a).cross(c - a).normalized()
    st.set_normal(normal)
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)
```

## The Five Platonic Solids

Only five convex polyhedra satisfy conditions of perfect regularity:

```gdscript
# 1. Tetrahedron - 4 triangular faces
var tetrahedron_faces = 4
var tetrahedron_vertices = 4
var tetrahedron_edges = 6

# 2. Cube - 6 square faces
var cube_faces = 6
var cube_vertices = 8
var cube_edges = 12

# 3. Octahedron - 8 triangular faces
var octahedron_faces = 8
var octahedron_vertices = 6
var octahedron_edges = 12

# 4. Dodecahedron - 12 pentagonal faces
var dodecahedron_faces = 12
var dodecahedron_vertices = 20
var dodecahedron_edges = 30

# 5. Icosahedron - 20 triangular faces
var icosahedron_faces = 20
var icosahedron_vertices = 12
var icosahedron_edges = 30
```

## Euler's Polyhedron Formula

For all convex polyhedra: **V - E + F = 2**

```gdscript
# Verify for tetrahedron
var V = 4  # Vertices
var E = 6  # Edges
var F = 4  # Faces

var euler_characteristic = V - E + F
print("Euler characteristic: ", euler_characteristic)  # 2 for this tetrahedron

# Verify for cube
V = 8
E = 12
F = 6
print("Cube: ", V - E + F)  # 2

# Verify for icosahedron
V = 12
E = 30
F = 20
print("Icosahedron: ", V - E + F)  # 2
```

This formula is **topological invariant** - it holds for any convex polyhedron, regardless of size or exact shape.

## Why Only Five Platonic Solids?

At each vertex, faces must meet with interior angles summing to **less than 360°** (otherwise the surface becomes flat).

```gdscript
# Triangles (60° each)
# 3 triangles: 3 × 60° = 180° < 360° ✓ → Tetrahedron
# 4 triangles: 4 × 60° = 240° < 360° ✓ → Octahedron
# 5 triangles: 5 × 60° = 300° < 360° ✓ → Icosahedron
# 6 triangles: 6 × 60° = 360° = 360° ✗ → Flat

# Squares (90° each)
# 3 squares: 3 × 90° = 270° < 360° ✓ → Cube
# 4 squares: 4 × 90° = 360° = 360° ✗ → Flat

# Pentagons (108° each)
# 3 pentagons: 3 × 108° = 324° < 360° ✓ → Dodecahedron
# 4 pentagons: 4 × 108° = 432° > 360° ✗ → Impossible

# Hexagons or larger: Always >= 360° → Impossible
```

This **angular constraint closes the system** - only five regular solids are geometrically possible.

## Tetrahedron Volume Calculation

```gdscript
# For regular tetrahedron with edge length a
func tetrahedron_volume(edge_length: float) -> float:
    return (edge_length ** 3) / (6.0 * sqrt(2.0))

var edge = 2.0
var volume = tetrahedron_volume(edge)
print("Tetrahedron volume: ", volume)  # ~1.886

# Alternative: Using vertex positions
func calculate_tetrahedron_volume(v0, v1, v2, v3: Vector3) -> float:
    # Volume = |det(v1-v0, v2-v0, v3-v0)| / 6
    var a = v1 - v0
    var b = v2 - v0
    var c = v3 - v0

    var determinant = a.dot(b.cross(c))
    return abs(determinant) / 6.0
```

## The placed encounters

The current room offers `grab_trihedron`, `grab_tetrahedron` and `pyramid_edit`. The older `snap_tetrahedron_puzzle` is not placed here. Its proposed assembly sequence must not be treated as an available interaction.

The open trihedron renders three faces from four vertices but gives physics the convex hull of those vertices. The missing visual base therefore remains part of its collision enclosure. The pyramid editor exposes five handles, including four base corners; moving them rebuilds faces without certifying that the result remains a valid enclosed pyramid.

## Primitives as Components

The tetrahedron demonstrates that all previous primitives are **building blocks**:

```gdscript
# Tetrahedron decomposition
class Tetrahedron:
    var vertices: Array[Vector3] = []  # 4 points
    var edges: Array = []              # 6 lines
    var faces: Array = []              # 4 triangles
    var volume: float                  # 1 enclosed space

    func _init(v0, v1, v2, v3: Vector3):
        vertices = [v0, v1, v2, v3]

        # Edges connect vertices
        edges = [
            [v0, v1], [v0, v2], [v0, v3],
            [v1, v2], [v1, v3], [v2, v3]
        ]

        # Faces are triangles
        faces = [
            [v0, v1, v2],
            [v0, v2, v3],
            [v0, v3, v1],
            [v1, v3, v2]
        ]

        volume = calculate_volume()
```

The tetrahedron is:
- 4 **points** (vertices)
- 6 **lines** (edges)
- 4 **triangles** (faces)
- Combined into **one volumetric primitive**

## Extrusion becomes a barrier

First trace the ends and sides of `prism_block`. A triangular prism has six vertices, nine edges and five geometric faces. Its rectangular sides may each become two rendering triangles.

The room's concrete barriers use a more detailed cross-section. These lines come from `commons/artifacts/concrete_barrier/concrete_barrier.gd`:

```gdscript
var outline := MF.jersey_outline(base_width, top_width, barrier_height)
body.mesh = MF.extrude_profile(outline, barrier_length, barrier_height)
```

The outline is swept along local X. The object's origin rests on the floor. The museum placements use one-metre lengths, a height of 0.85 metres and a base width of 0.60 metres. Twelve sections replace the former prism enclosure in the same cells; the separate bare prism examples remain.

Mesh generation alone does not enforce a boundary. This map enables `#blocking:1`, which adds a `StaticBody3D` on collision layer 1 and constructs its shape with:

```gdscript
shape.shape = body.mesh.create_convex_shape()
```

This convex hull can span details of the stepped profile. Other uses of the artifact retain `blocking = false` unless they opt in. Red and white stripes are a visual cue; they do not supply collision.

## The wedge carries movement upward

Compare a low approach to the existing `wp` utility wedges with approach to an upright face. `endless_museum.gd::_stamp_wedge` instantiates the walkable prism scene, including its collision surface, and adapts its dimensions:

```gdscript
w.scale = Vector3(1.0, maxf(0.05, rise), maxf(0.2, run_cells))
```

The lower bounds avoid collapsing the shape. The utility builder reads neighbouring floor heights to derive the rise when a higher neighbouring floor exists. A usable ascent also depends on that floor connection, the body's collision mask and movement settings. The current room's utility wedges are preserved.

## Signs ask for a direction

`street_sign` has a red STOP variant and four configured geometric arrows: `direction:ahead`, `direction:left`, `direction:right` and `direction:both`. Directional variants replace the text with a rectangular shaft and triangular head, using a blue plate in this room. The two-headed variant indicates both lateral directions. The sign front is local +Z; these placements rotate it 180 degrees toward the earlier map rows.

These sign scenes contain no collision body. Predict whether a pause will come from reading a sign or reaching a barrier. Then compare the direction offered with the space actually available. Signs are fixed fixtures here, not grabbable controls or a pathfinding system.

## Verification boundary

`commons/testing/probe_polyhedra_flow.gd` derives current map placements through the museum loader and checks all twelve barriers, five signs and two cones. Its separate movement trial uses the real barrier and museum wedge builder with supplied capsule movement: concrete blocks direct approach and the wedge permits ascent onto a test stage. Full-room routes, tracked player movement and headset comfort still need an in-museum pass.
