# Point One — build the difference

Start with [the supplied Point One study](README.md). Import its `project.godot` in Godot 4.6 and run it with F6 from `study.tscn`, or F5 for the project. It is a small separate project with a fixed camera, floor, lights and three labels already placed. You do not need the museum or its add-ons to run these first three constructions.

The left station has no sphere. The middle and right stations look alike. Only the right one has a collision body. This study supplies a view for making and comparing; walking and grabbing belong to the museum encounter.

Open `position.gd`. It contains the complete first step:

```gdscript
extends Node3D

func _ready() -> void:
    var point_position := Vector3(0.0, 1.12, 0.0)
```

`extends Node3D` makes the script part of a station with a position in 3D. Godot runs `_ready()` when the station enters the scene. The indented lines go inside that function. `var` gives a value a name; `:=` lets Godot infer the kind of value from what follows. Here that value is a `Vector3`, holding X, Y and Z.

Changing these numbers alone draws nothing. Godot may warn that the variable is unused: it is waiting for the next step. The position is local to this station, 1.12 metres up its Y direction. The three stations already occupy different places in the scene.

## Give the position a visible body

In `visible.gd` the same first line is followed by the construction of a visible sphere. The full file is supplied; these are its additions inside `_ready()`:

```gdscript
var radius := 0.14
var sphere := SphereMesh.new()
sphere.radius = radius
sphere.height = radius * 2.0

var visible_point := MeshInstance3D.new()
visible_point.mesh = sphere
visible_point.position = point_position
add_child(visible_point)
```

`SphereMesh` is the shape description; `MeshInstance3D` is the node that displays it. `.new()` creates each part. Assigning `mesh` gives the node its shape, and assigning `position` puts it at the place we kept. `add_child()` attaches it to this station in the scene.

Change `1.12` in the first line to `1.8` and run again: the middle sphere is higher. Return it to `1.12`. Change `radius` from `0.14` to `0.3`: the sphere is larger, while its centre stays put. Its height follows the radius because the code calculates it as `radius * 2.0`.

You have changed a body and an address separately. These same choices will let you arrange more than one point.

## Give the visible body a boundary

`solid.gd` keeps all of `visible.gd` and adds:

```gdscript
var solid := StaticBody3D.new()
solid.position = point_position

var sphere_shape := SphereShape3D.new()
sphere_shape.radius = radius
var collider := CollisionShape3D.new()
collider.shape = sphere_shape

solid.add_child(collider)
add_child(solid)
```

The fixed physics body and the visible mesh are separate children of the station. The collision shape belongs to the physics body. Both use `point_position` and `radius`, so their centres and surfaces agree.

To see the otherwise invisible boundary, enable **Debug → Visible Collision Shapes** in the Godot editor, then run the study. Change only `sphere_shape.radius = radius` to `sphere_shape.radius = 0.35`. The physics boundary expands; the visible sphere stays small. Undo that change to make them coincide again.

This is a choice you can now author: how much room must a body leave around something it sees? A collision test responds to the boundary you supplied.

## A first arrangement

Select the `Solid` station in `study.tscn` and duplicate it. Move the copy using its Position in the Inspector. Both copies run the same script, so a change to `radius` in that script changes both. Their station positions remain separate.

Make a small arrangement from copies of `Visible` and `Solid`. Give them space, crowd them together, or let them overlap. The geometry can look the same while its permissions differ. The inspector moves each station; `point_position` places the sphere within it. You have begun working with two references without needing to construct the whole coordinate room.

## What we borrow next

The museum's black point uses `commons/primitives/point/interactive_point_origin.tscn` and the held branch of `point_condition.gd`. That branch supplies the dark finish, radius and coordinate identity. Its inherited pickup system manages hands, holding and release. These scripts are part of the full AdaResearch project, with XR Tools and museum dependencies; they are not included in this small standalone study.

The first building exercise stops at position, visible shape and fixed collision. A portable pickup starter is a further teaching step. Point Lines can connect positions you already know how to keep and show.

## A further look inside the museum

These three examples explain the coordinate cards and arrival target in the main text. They belong to the museum's existing components; they are not further lines to paste into `solid.gd`.

### A shorter address

The report accepts a scene node called `point` and reads its world position:

```gdscript
func report_position(point: Node3D) -> String:
    var p := point.global_position
    return "(%.2f, %.2f, %.2f)" % [p.x, p.y, p.z]
```

`%.2f` rounds each component to two decimal places in the text: `1.231` and `1.234` both print as `1.23`. The function returns a string. The museum card displays that string; this function alone does not create a card. Formatting leaves the stored position unchanged.

### Two references

Here `point` is the held body and `frame` is the coordinate frame, both existing `Node3D` objects in the museum:

```gdscript
var world_p := point.global_position
var local_p := frame.to_local(world_p)
```

`global_position` supplies the world address. `to_local()` expresses it relative to the frame, accounting for its position, orientation and scale. Both readings describe the same body.

### Room to arrive

This reduced distance test belongs to a target node with its own position:

```gdscript
@export var catch_radius: float = 0.45
@export var catch_height: float = 1.20

func accepts_position(p: Vector3) -> bool:
    var centre := global_position + Vector3(0.0, catch_height, 0.0)
    return p.distance_to(centre) <= catch_radius
```

`p` is the point's world position. The target's centre is 1.20 metres above its origin. `distance_to()` measures the gap; `<=` accepts 0.45 metres or less. The exported values are editable parameters.

The actual museum target also remembers whether the point is already inside, rearms when it leaves, and releases the falling balls on entry. This function isolates the acceptance test; it does not supply those other actions.
