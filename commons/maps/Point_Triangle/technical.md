# Point Triangle - Technical Tutorial

## Three Positions, One Closure

Two positions define a line. Three non-collinear positions define a plane and **enclose space**.

```gdscript
# Defining the Triangle
var point_a = Vector3(0, 0, 0)
var point_b = Vector3(2, 0, 0)
var point_c = Vector3(1, 0, 2)

var edges = [
    [point_a, point_b],  # Edge AB
    [point_b, point_c],  # Edge BC
    [point_c, point_a]   # Edge CA
]
```

Three vertices. Three edges. One face.

The triangle is the first structure where **relations close upon themselves**. Edge AB connects to BC connects to CA connects back to AB - forming a loop.

## Orientation and Normal

Unlike the line, the triangle has **orientation** - it faces a direction.

```gdscript
# Computing the Normal Vector
var point_a = Vector3(0, 0, 0)
var point_b = Vector3(2, 0, 0)
var point_c = Vector3(1, 0, 2)

var edge1 = point_b - point_a  # Vector from A to B
var edge2 = point_c - point_a  # Vector from A to C

var normal = edge1.cross(edge2).normalized()
print("Normal direction: ", normal)  # Which side is "front"
```

The **cross product** determines which side is front and which is back. **Winding order matters**:
- Counter-clockwise winding (A→B→C) → Normal points "up"
- Clockwise winding (A→C→B) → Normal points "down"

The triangle distinguishes between **the side that sees and the side that is seen**.

## Area: Measure of Capture

If the line measured distance, the triangle measures **area**.

```gdscript
# Computing Triangle Area
var edge1 = point_b - point_a
var edge2 = point_c - point_a

var cross = edge1.cross(edge2)
var area = cross.length() * 0.5

print("Triangle area: ", area, " square units")
```

Area quantifies **enclosure** - how much space has been captured.

This is the first moment geometry can **contain**.

## Creating a Triangle Mesh

To render the triangle, relations become surface:

```gdscript
extends Node3D

var point_a = Vector3(0, 0, 0)
var point_b = Vector3(2, 0, 0)
var point_c = Vector3(1, 0, 2)

func _ready():
    create_triangle()

func create_triangle():
    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

    # Calculate normal for proper lighting
    var edge1 = point_b - point_a
    var edge2 = point_c - point_a
    var normal = edge1.cross(edge2).normalized()

    # Add vertices in order (winding matters!)
    surface_tool.set_normal(normal)
    surface_tool.add_vertex(point_a)
    surface_tool.add_vertex(point_b)
    surface_tool.add_vertex(point_c)

    var triangle_mesh = surface_tool.commit()

    # Create mesh instance
    var mesh_instance = MeshInstance3D.new()
    mesh_instance.mesh = triangle_mesh

    # Add material
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.3, 0.7, 1.0)
    material.cull_mode = BaseMaterial3D.CULL_BACK  # Only render front face
    mesh_instance.material_override = material

    add_child(mesh_instance)
```

The triangle now exists as a **visible boundary**. Space is divided.

## Dynamic Triangle: Grabbable Vertices

The `triangle` interactable in Point_Triangle allows moving vertices:

```gdscript
extends Node3D

@export var vertex_a: Node3D
@export var vertex_b: Node3D
@export var vertex_c: Node3D

var mesh_instance: MeshInstance3D

func _ready():
    mesh_instance = MeshInstance3D.new()
    add_child(mesh_instance)
    update_triangle()

func _process(delta):
    # Update triangle every frame as vertices move
    if vertex_a and vertex_b and vertex_c:
        update_triangle()

func update_triangle():
    var pos_a = vertex_a.global_position
    var pos_b = vertex_b.global_position
    var pos_c = vertex_c.global_position

    # Check if vertices are collinear (degenerate triangle)
    var edge1 = pos_b - pos_a
    var edge2 = pos_c - pos_a
    var cross = edge1.cross(edge2)

    if cross.length() < 0.001:
        # Vertices are collinear - no valid triangle
        mesh_instance.visible = false
        return

    mesh_instance.visible = true

    # Rebuild triangle mesh
    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

    var normal = cross.normalized()
    surface_tool.set_normal(normal)
    surface_tool.add_vertex(pos_a)
    surface_tool.add_vertex(pos_b)
    surface_tool.add_vertex(pos_c)

    mesh_instance.mesh = surface_tool.commit()
```

The triangle **persists as long as vertices are non-collinear**. Moving one vertex changes all three edges simultaneously.

## Inside and Outside: Point-in-Triangle Test

The triangle introduces a decisive binary: A position is either **inside** the boundary or **outside** it.

```gdscript
# Barycentric coordinate method
func point_in_triangle(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> bool:
    var v0 = c - a
    var v1 = b - a
    var v2 = p - a

    var dot00 = v0.dot(v0)
    var dot01 = v0.dot(v1)
    var dot02 = v0.dot(v2)
    var dot11 = v1.dot(v1)
    var dot12 = v1.dot(v2)

    var inv_denom = 1.0 / (dot00 * dot11 - dot01 * dot01)
    var u = (dot11 * dot02 - dot01 * dot12) * inv_denom
    var v = (dot00 * dot12 - dot01 * dot02) * inv_denom

    return (u >= 0) and (v >= 0) and (u + v <= 1)

# Usage
var test_point = Vector3(1, 0, 1)
var is_inside = point_in_triangle(test_point, point_a, point_b, point_c)
print("Point is inside triangle: ", is_inside)  # true or false
```

The algorithm returns a **boolean**. Inside or outside. True or false. **Ambiguity is excluded.**

## The Atomic Surface

All polygonal surfaces reduce to triangles. Every mesh rendered by the GPU is composed of triangular faces.

```gdscript
# Complex meshes are triangle collections
var sphere = SphereMesh.new()
sphere.radial_segments = 32
sphere.rings = 16
# Result: 32 × 16 × 2 = 1,024 triangles

var box = BoxMesh.new()
# Result: 12 triangles (2 per face × 6 faces)
```

Triangles are used because:
- **Three points always lie on a plane** (four points might not)
- **Computationally stable** (no ambiguity in rendering)
- **Hardware optimized** (GPUs have dedicated triangle rasterizers)

Every complex surface is a **repetition of the simplest enclosure**.

## Triangle Profiles: Variations

The `triangleprofiles` object displays different triangle types:

```gdscript
# Equilateral Triangle (all sides equal)
var side_length = 2.0
var height = side_length * sqrt(3.0) / 2.0
var equilateral = [
    Vector3(0, 0, 0),
    Vector3(side_length, 0, 0),
    Vector3(side_length / 2.0, 0, height)
]

# Isosceles Triangle (two sides equal)
var isosceles = [
    Vector3(0, 0, 0),
    Vector3(2, 0, 0),
    Vector3(1, 0, 1.5)
]

# Right Triangle (90° angle)
var right = [
    Vector3(0, 0, 0),
    Vector3(2, 0, 0),
    Vector3(0, 0, 1.5)
]

# Scalene Triangle (all sides different)
var scalene = [
    Vector3(0, 0, 0),
    Vector3(2.5, 0, 0),
    Vector3(0.8, 0, 1.2)
]
```

All share the same structure (3 vertices, 3 edges, 1 face) but differ in **proportions and angles**.

## Pythagorean Theorem (Right Triangles)

For right triangles, the relationship between edge lengths is deterministic:

```gdscript
# Right triangle with legs a, b and hypotenuse c
var a = 3.0  # First leg
var b = 4.0  # Second leg
var c = sqrt(a * a + b * b)  # Hypotenuse
print("Hypotenuse length: ", c)  # 5.0

# Create right triangle mesh
var right_triangle = [
    Vector3(0, 0, 0),
    Vector3(a, 0, 0),
    Vector3(0, 0, b)
]
```

The Pythagorean theorem establishes **geometric constraint** - not all combinations of edge lengths form valid triangles.

## Triangle Inequality

For any triangle, the sum of two sides must exceed the third:

```gdscript
# Validate triangle is constructible
func is_valid_triangle(a: float, b: float, c: float) -> bool:
    return (a + b > c) and (a + c > b) and (b + c > a)

# Examples
print(is_valid_triangle(3, 4, 5))    # true - valid
print(is_valid_triangle(1, 2, 10))   # false - impossible
```

This constraint ensures **closure** - the three edges must actually meet to form a triangle.

## Key Takeaway

The triangle is the **first closed geometry**. It introduces:
- **Enclosure** (inside vs. outside)
- **Orientation** (front and back faces)
- **Area** (quantified containment)
- **Surface** (visible boundary)

All complex 3D surfaces are built from triangles - the **atomic unit of computational boundaries**. The triangle transforms open relations (lines) into closed containers (faces).
