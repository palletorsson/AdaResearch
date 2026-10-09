# Point One

Place a single point in space. Before it, the coordinate system must already exist.

Declare the three axes.

```gdscript
const AXIS_X := Vector3(1, 0, 0)
const AXIS_Y := Vector3(0, 1, 0)
const AXIS_Z := Vector3(0, 0, 1)
```

The axes are unit vectors. They name directions, not points.

Mark the origin.

```gdscript
var origin := Vector3.ZERO  # (0, 0, 0)
```

The origin is a point made special by convention. What is chosen is not that it exists, but that this one is called zero and everything else is measured from it.

Instantiate your first point.

```gdscript
func place_point(position: Vector3) -> MeshInstance3D:
    var point := MeshInstance3D.new()
    point.mesh = SphereMesh.new()
    point.position = position
    add_child(point)
    return point
```

The sphere mesh is rendering help. The point itself is the Vector3 that was passed in.

Place it at a specific location.

```gdscript
var p := place_point(Vector3(1.0, 0.5, 0.0))
```

Three floats. One position. No extent.

Show the coordinate system as visible axes.

```gdscript
func draw_axes(length: float = 3.0) -> void:
    spawn_axis_line(Vector3.ZERO, AXIS_X * length, Color.RED)
    spawn_axis_line(Vector3.ZERO, AXIS_Y * length, Color.GREEN)
    spawn_axis_line(Vector3.ZERO, AXIS_Z * length, Color.BLUE)
```

Red for X, green for Y, blue for Z. The convention is shared across Godot, OpenGL, and most 3D software.

Spawn a gyroscope to track orientation.

```gdscript
var gyro := preload("res://commons/primitives/gyroscope.tscn").instantiate()
gyro.position = Vector3(2, 1, 0)
add_child(gyro)
```

The gyroscope's axes align with yours. Move relative to it and the relationship stays constant.

Make the point grabbable.

```gdscript
func make_interactive(pickable: XRToolsPickable) -> void:
    pickable.picked_up.connect(_on_picked_up)
    pickable.dropped.connect(_on_dropped)
```

Grabbing is not a Godot feature. It comes from XR Tools, an add-on this project carries: a thing can be picked up because it is an `XRToolsPickable`, and it reports `picked_up` and `dropped` when it is. `grab_sphere_point_snap` in this room connects those two signals and nothing else.

The previous version of this step built an `Area3D` and added it to a group called `grabbable`. That compiles, and no code in this project reads that group.

Read the point's current coordinates.

```gdscript
func report_position(point: Node3D) -> String:
    var p := point.global_position
    return "(%.2f, %.2f, %.2f)" % [p.x, p.y, p.z]
```

The coordinates change as the point moves. The point's identity does not.

You can now place a Vector3 in space, show the axes that give it meaning, and move it while its identity persists. The next map, Point_Line, connects two of these instances into a line.

Test point comparison.

```gdscript
func are_same_point(a: Vector3, b: Vector3, tolerance: float = 0.001) -> bool:
    return a.distance_to(b) < tolerance
```

Floating-point equality is unreliable. Use tolerance-based comparison for any practical test of identity.

Snap a point to a nearby grid.

```gdscript
func snap_to_grid(p: Vector3, cell_size: float = 0.5) -> Vector3:
    return Vector3(
        round(p.x / cell_size) * cell_size,
        round(p.y / cell_size) * cell_size,
        round(p.z / cell_size) * cell_size,
    )
```

Snapping trades precision for discreteness. Useful for level editors and puzzle games.
