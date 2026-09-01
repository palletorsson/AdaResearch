You arrive late.

The prerequisites are in, stacked away behind you, and the fold keeps running whether or not you accepted the challenge. Everything here arrived late. You are here now.

<!-- @folding_past -->

Nested frames march inward, each 0.85 the size of the one before it. That is what a past looks like when you give it a geometry: not a line behind you but a nesting, the present as the innermost term of a regress that does not end. You did not join it. You were thrown into it.

<!-- @ -->

## Declare the three axes

Before a point can be placed, the space that measures it has to exist.

```gdscript
const AXIS_X := Vector3(1, 0, 0)
const AXIS_Y := Vector3(0, 1, 0)
const AXIS_Z := Vector3(0, 0, 1)
```

The axes are unit vectors. They name directions, not points.

<!-- @CoordinateSystem3M -->

Red, green, blue — X, Y, Z. The convention is shared across Godot, OpenGL and most 3D software, which is to say it is not a fact about space but an agreement about how to talk. Stand in front of it and nothing is here yet. You are already in it.

<!-- @ -->

## Mark the origin

```gdscript
var origin := Vector3.ZERO  # (0, 0, 0)
```

The origin is a convention, not a point. It is the reference against which other points are measured.

<!-- @origin -->

Zero is already surrounded, so you have somewhere to stand. This is the root of all vectors, and there is no turning back from it: every other position in the museum is written as a departure from here.

It was not placed but excavated — two metres down, under glass — because a corner is not a cell. Four cells meet at the origin and none of them contains it. Three of its four quadrants lie in coordinates no map row can name. The building can stand there; the language cannot.

<!-- @ -->

## Instantiate your first point

```gdscript
func place_point(position: Vector3) -> MeshInstance3D:
    var point := MeshInstance3D.new()
    point.mesh = SphereMesh.new()
    point.position = position
    add_child(point)
    return point
```

The sphere mesh is rendering help. The point itself is the Vector3 that was passed in.

<!-- @interactive_point_origin -->

That sentence is the whole argument of this room, and it is worth staying with. What you can see is a sphere. What is actually there is three floats. The visible thing is scaffolding for the invisible one, and the museum is built entirely out of that trade.

<!-- @ -->

## Place it at a specific location

```gdscript
var p := place_point(Vector3(1.0, 0.5, 0.0))
```

Three floats. One position. No extent.

<!-- @you_are_here -->

A point is that which has no part, so it has no place either: it borrows its whole existence from a coordinate system that is not itself a point. The plaque says *you are here*. It is lying in the same way every map lies, and usefully.

<!-- @ -->

## Make the point grabbable

```gdscript
func make_interactive(point: MeshInstance3D) -> void:
    var area := Area3D.new()
    var shape := CollisionShape3D.new()
    shape.shape = SphereShape3D.new()
    point.add_child(area)
    area.add_child(shape)
    area.add_to_group("grabbable")
```

The Area3D detects the controller's collision shape. Godot's XR plugin handles the grab-and-release contract.

<!-- @interactive_point_origin_force -->

*Show me what you can do with those hands.* But the hands are no different from the ball — both are code, both are Vector3 under a mesh. What sits between them is you, and the perspective from here to that dark shiny thing is the only thing in the room that is not a number.

One step at a time was the promise. We are already Alice.

<!-- @ -->

## Read the point's coordinates

```gdscript
func report_position(point: Node3D) -> String:
    var p := point.global_position
    return "(%.2f, %.2f, %.2f)" % [p.x, p.y, p.z]
```

The coordinates change as the point moves. The point's identity does not.

<!-- @frame_counter_display -->

The internal clock is running. The frame counter updates with the cycle, and the position is re-read every one of them — sixty answers a second to a question about where something is, none of them the thing itself.

<!-- @ -->

## Snap it to a grid

```gdscript
func snap_to_grid(p: Vector3, cell_size: float = 0.5) -> Vector3:
    return Vector3(
        round(p.x / cell_size) * cell_size,
        round(p.y / cell_size) * cell_size,
        round(p.z / cell_size) * cell_size,
    )
```

Snapping trades precision for discreteness.

<!-- @grab_sphere_point_snap -->

A point you can take; it snaps. The continuous position was always a fiction of the float, and the grid says so out loud: here are the places you are allowed to be. Every level editor in the world is built on this small violence, and it is the first time in the walk that the room decides something on your behalf.

<!-- @ -->

You can now place a Vector3 in space, show the axes that give it meaning, and move it while its identity persists.

The next room connects two of these into a line.
