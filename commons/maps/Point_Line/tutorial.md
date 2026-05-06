# Point Line

Two points define a line. The line is the relation, not the endpoints.

Place two points.

```gdscript
var a := Vector3(0, 0, 0)
var b := Vector3(2, 1, 0)
```

Each is a Vector3. Neither implies the other.

Compute the direction from a to b.

```gdscript
var direction: Vector3 = (b - a).normalized()
```

Subtraction produces the vector from a to b. Normalisation sets its length to 1, keeping only the direction.

Compute the length between them.

```gdscript
var length: float = a.distance_to(b)
# or equivalently: (b - a).length()
```

The distance is a scalar. It is how far the line extends, not which way.

Draw the line as a cylinder.

```gdscript
func draw_line(start: Vector3, end: Vector3, thickness: float = 0.02) -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = thickness
    cylinder.bottom_radius = thickness
    cylinder.height = start.distance_to(end)
    mesh.mesh = cylinder
    mesh.position = (start + end) / 2.0
    mesh.look_at(end, Vector3.UP)
    mesh.rotate_object_local(Vector3.RIGHT, PI / 2)
    add_child(mesh)
    return mesh
```

The cylinder is centred between the endpoints and rotated to point along them. Godot's CylinderMesh defaults to Y-up, so a 90-degree rotation aligns it with the line direction.

Parameterise points along the segment.

```gdscript
func point_at(start: Vector3, end: Vector3, t: float) -> Vector3:
    return start + (end - start) * t
```

`t` runs from 0 to 1. At 0 you are at the start; at 1 you are at the end; at 0.5 you are halfway.

Label the distance.

```gdscript
func attach_distance_label(line: MeshInstance3D, a: Vector3, b: Vector3) -> void:
    var label := Label3D.new()
    label.text = "%.2f m" % a.distance_to(b)
    label.position = (a + b) / 2.0 + Vector3.UP * 0.3
    line.add_child(label)
```

The label sits above the midpoint. Its text is the measured length.

Record the learner's path as a trace.

```gdscript
var trace_points: Array = []

func _process(_delta: float) -> void:
    var learner = get_tree().get_first_node_in_group("learner")
    trace_points.append(learner.global_position)
    if trace_points.size() > 100:
        trace_points.pop_front()
```

The trace is a ring buffer of recent positions. Rendering each consecutive pair as a short line produces a visible trail.

You can now compute a direction, measure a length, and render the segment between any two points. Point_Lines will next extend this into a full grid of related points.

Find the perpendicular from a point to the line.

```gdscript
func closest_point_on_line(p: Vector3, a: Vector3, b: Vector3) -> Vector3:
    var ab: Vector3 = b - a
    var t: float = (p - a).dot(ab) / ab.length_squared()
    t = clamp(t, 0.0, 1.0)
    return a + ab * t
```

Project p onto the segment, clamp to [0, 1] to stay within the endpoints. The closest point on the segment is never beyond a or b.

Measure the shortest distance.

```gdscript
func point_to_line_distance(p: Vector3, a: Vector3, b: Vector3) -> float:
    return p.distance_to(closest_point_on_line(p, a, b))
```

The distance is always non-negative. Zero means the point lies on the segment.
