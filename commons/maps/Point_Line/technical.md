# Point Line - Technical Tutorial

*This tutorial reuses and extends content from `line_axioms.md`*

## The Line: Connecting Points

Lines create direction, distance, and paths through space.

A line is the relation between two distinct points - the shortest path through space.

### Defining the Endpoints

```gdscript
var point_a = Vector3(0, 0, 0)
var point_b = Vector3(1, 1, 0)
```

The line exists **between** these positions. The line itself is not stored as an object - it is **computed** from the two endpoints.

### Computing Distance

```gdscript
var distance = point_a.distance_to(point_b)
print("Line length: ", distance)  # Euclidean distance
```

This is the **ontological imperative** of the line: Length is its defining property. If a line had no length, it would collapse back into a point.

The distance formula (Pythagorean theorem in 3D):

```gdscript
var dx = point_b.x - point_a.x
var dy = point_b.y - point_a.y
var dz = point_b.z - point_a.z
var distance = sqrt(dx*dx + dy*dy + dz*dz)
```

## Materializing the Line: Cylinders as Lines

To make a line visible, we use a cylinder aligned between the two points:

```gdscript
extends Node3D

func create_line_between(point_a: Vector3, point_b: Vector3) -> MeshInstance3D:
    # Calculate distance
    var distance = point_a.distance_to(point_b)

    # Create cylinder mesh
    var cylinder = MeshInstance3D.new()
    var cylinder_mesh = CylinderMesh.new()
    cylinder_mesh.height = distance  # Height EQUALS measured distance
    cylinder_mesh.top_radius = 0.015
    cylinder_mesh.bottom_radius = 0.015
    cylinder.mesh = cylinder_mesh

    # Position at midpoint
    var midpoint = (point_a + point_b) / 2.0
    cylinder.position = midpoint

    # Align cylinder to point_b (look_at)
    cylinder.look_at_from_position(midpoint, point_b, Vector3.UP)

    # Create material
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.3, 0.8, 1, 0.7)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    cylinder.material_override = material

    return cylinder
```

### The Snap Points

The `line_demo.tscn` scene uses two `snap_point.tscn` instances with our enhanced shiny materials:

```gdscript
# From snap_point.tscn (our modifications)
var material = StandardMaterial3D.new()
material.albedo_color = Color(1, 0.9, 0.5, 1)  # Bright golden
material.metallic = 0.6
material.roughness = 0.3
material.emission_enabled = true
material.emission = Color(0.9, 0.7, 0.2, 1)
material.emission_energy = 0.5
```

When you grab a snap point, the line updates:

```gdscript
func _on_snap_point_moved(point_index: int, new_position: Vector3):
    # Update endpoint
    if point_index == 0:
        point_a = new_position
    else:
        point_b = new_position

    # Rebuild line geometry
    update_line_mesh()
```

### Direction Vector

The line has direction:

```gdscript
var direction = (point_b - point_a).normalized()
print("Line direction: ", direction)  # Unit vector pointing from A to B
```

This direction can be reversed:

```gdscript
var reverse_direction = (point_a - point_b).normalized()
# reverse_direction == -direction
```

## The Line as Compression

The line knows only:
- Two endpoints (6 float values total)
- One distance (computed, not stored)
- One direction (computed, not stored)

Everything else about the space between the points is **compressed away**. The line is the **trace reduced to its endpoints**.

## Key Takeaway

A line in code is **computed relation** between two Vector3 positions. The visual cylinder, the measured distance, the direction vector - all of these are **derived** from just two points.

When you move the snap points in the line_demo, you're changing the relation, and the line updates instantly to reflect the new measurement. **Geometry is dynamic calculation**, not static form.
