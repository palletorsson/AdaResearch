# The Line
Connecting Points in Space

A line connects two points in space, creating direction and distance.

```
var point_a = Vector3(0, 0, 0)
var point_b = Vector3(1, 1, 0)

var direction = point_b - point_a
var distance = direction.length()
```

---

## Drawing Lines

Using ImmediateMesh for simple, flexible line drawing:

```
var mesh_instance = MeshInstance3D.new()
var immediate_mesh = ImmediateMesh.new()
mesh_instance.mesh = immediate_mesh

immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
immediate_mesh.surface_add_vertex(point_a)
immediate_mesh.surface_add_vertex(point_b)
immediate_mesh.surface_end()

add_child(mesh_instance)
```

---

## Direction and Magnitude

A line has both direction and magnitude (length).

```
var direction = (point_b - point_a).normalized()
var distance = point_a.distance_to(point_b)

# Move along the line
var t = 0.5  # halfway
var midpoint = point_a + direction * distance * t
```

The parameter
