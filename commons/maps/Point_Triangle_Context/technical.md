# Point Triangle Context - Technical Tutorial

## Triangle Rigidity: Invariant Structure

Three edges form a **rigid** configuration. Unlike quads (which can "squash"), triangles maintain their shape.

```gdscript
# Triangle edges are mutually constrained
var a = 3.0  # Edge 1
var b = 4.0  # Edge 2
var c = 5.0  # Edge 3 (must satisfy triangle inequality)

# Constraint: a + b > c, a + c > b, b + c > a
# Result: 3 + 4 > 5 ✓, 3 + 5 > 4 ✓, 4 + 5 > 3 ✓
# This triangle is valid and rigid
```

Changing one edge length **requires** changing at least one other edge. The triangle cannot deform without breaking.

## Pythagorean Theorem: Geometric Determinism

For right triangles (one 90° angle), the edge lengths are **deterministically related**:

**a² + b² = c²**

```gdscript
# Right triangle with 90° angle at vertex A
var leg_a = 3.0
var leg_b = 4.0

# Hypotenuse is determined
var hypotenuse = sqrt(leg_a * leg_a + leg_b * leg_b)
print("Hypotenuse: ", hypotenuse)  # 5.0

# Creating Pythagorean triangle mesh
var v0 = Vector3(0, 0, 0)
var v1 = Vector3(leg_a, 0, 0)
var v2 = Vector3(0, 0, leg_b)

# Distance v1 to v2 MUST equal hypotenuse
var measured = v1.distance_to(v2)
print("Measured hypotenuse: ", measured)  # 5.0 - matches!
```

This constraint enables:
- **Predictability** - Given two sides, compute third
- **Validation** - Check if triangle is right-angled
- **Trigonometry** - Foundation for sine, cosine, tangent

## Visual Pythagorean Proof

The `pythagorean_triangle_angles` object demonstrates geometric proof:

```gdscript
# Create squares on each side of right triangle
func create_pythagorean_proof(a: float, b: float, c: float):
    # Square on leg A (area = a²)
    create_square(leg_a_start, leg_a_end, a * a)

    # Square on leg B (area = b²)
    create_square(leg_b_start, leg_b_end, b * b)

    # Square on hypotenuse (area = c²)
    create_square(hyp_start, hyp_end, c * c)

    # Visual proof: area(square_a) + area(square_b) = area(square_c)
    # 9 + 16 = 25 ✓
```

The proof is **visual and metric** - areas of squares relate geometrically.

## Quads: Hidden Triangulation

Quads appear as single surfaces but render as **two triangles**:

```gdscript
# Quad vertices
var v0 = Vector3(-0.5, -0.5, 0)
var v1 = Vector3( 0.5, -0.5, 0)
var v2 = Vector3( 0.5,  0.5, 0)
var v3 = Vector3(-0.5,  0.5, 0)

# GPU triangulation (diagonal v0→v2)
# Triangle 1: v0, v1, v2
# Triangle 2: v0, v2, v3

var surface_tool = SurfaceTool.new()
surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

# First triangle
surface_tool.add_vertex(v0)
surface_tool.add_vertex(v1)
surface_tool.add_vertex(v2)

# Second triangle
surface_tool.add_vertex(v0)
surface_tool.add_vertex(v2)
surface_tool.add_vertex(v3)

var quad_mesh = surface_tool.commit()
```

The diagonal (v0→v2) is **invisible** but always present.

## Alternative Diagonal

Two possible ways to split a quad:

```gdscript
# Option 1: Diagonal v0→v2
# Triangles: (v0,v1,v2) and (v0,v2,v3)

# Option 2: Diagonal v1→v3
# Triangles: (v0,v1,v3) and (v1,v2,v3)
```

For planar quads, both appear identical. For **twisted quads**, the choice becomes visible as a crease.

## Quad Instability: Non-Planar Deformation

Four vertices do **not** guarantee planarity:

```gdscript
# Planar quad (all on same plane)
var v0 = Vector3(-0.5, -0.5, 0)
var v1 = Vector3( 0.5, -0.5, 0)
var v2 = Vector3( 0.5,  0.5, 0)
var v3 = Vector3(-0.5,  0.5, 0)
# All have z=0 - perfectly planar

# Twisted quad (v3 lifted)
v3 = Vector3(-0.5, 0.5, 0.3)  # z=0.3 breaks planarity

# Check planarity
func is_planar(v0, v1, v2, v3: Vector3) -> bool:
    var edge1 = v1 - v0
    var edge2 = v2 - v0
    var normal = edge1.cross(edge2).normalized()

    # Check if v3 lies on same plane
    var dist = abs(normal.dot(v3 - v0))
    return dist < 0.001  # Tolerance for floating-point

print("Quad is planar: ", is_planar(v0, v1, v2, v3))  # false
```

Quads can **twist**, **bow**, or **saddle** - they're geometrically unstable.

## Editable Quad with Four Vertices

The `quad` interactable lets you manipulate all four vertices:

```gdscript
extends Node3D

@export var vertex_0: Node3D
@export var vertex_1: Node3D
@export var vertex_2: Node3D
@export var vertex_3: Node3D

func _process(delta):
    update_quad()

func update_quad():
    var v0 = vertex_0.global_position
    var v1 = vertex_1.global_position
    var v2 = vertex_2.global_position
    var v3 = vertex_3.global_position

    # Rebuild as two triangles
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)

    # Triangle 1
    st.add_vertex(v0)
    st.add_vertex(v1)
    st.add_vertex(v2)

    # Triangle 2
    st.add_vertex(v0)
    st.add_vertex(v2)
    st.add_vertex(v3)

    mesh_instance.mesh = st.commit()
```

Moving vertices reveals the hidden diagonal - quads crease and fold.

## Triangle Profiles: Systematic Variations

```gdscript
# Equilateral (all sides equal, all angles 60°)
var side = 2.0
var height = side * sqrt(3.0) / 2.0
var equilateral = [
    Vector3(0, 0, 0),
    Vector3(side, 0, 0),
    Vector3(side/2.0, 0, height)
]

# Isosceles (two sides equal)
var isosceles = [
    Vector3(0, 0, 0),
    Vector3(2, 0, 0),
    Vector3(1, 0, 1.5)
]

# Right (one 90° angle)
var right = [
    Vector3(0, 0, 0),
    Vector3(3, 0, 0),
    Vector3(0, 0, 4)
]

# Scalene (all sides different)
var scalene = [
    Vector3(0, 0, 0),
    Vector3(2.5, 0, 0),
    Vector3(0.8, 0, 1.2)
]
```

All share the same **structure** (3 vertices, 3 edges, 1 face) but differ in **metric properties**.

## Key Takeaway

**Triangles are rigid** - three edges produce stable, deterministic structures. The Pythagorean theorem shows how right triangles are **geometrically constrained**.

**Quads are flexible** - four edges allow twisting and deformation. Quads render as **two hidden triangles**, making them a modeling abstraction rather than a computational primitive.

Rigidity enables **calculation and stability**. Flexibility enables **modeling convenience** but introduces **instability**.
