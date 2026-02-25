# Point One

This chapter focuses on one thing: how a point becomes manipulable in VR while staying mathematically minimal.

## Point as Data

In Godot, a point is represented as a `Vector3` position:

```gdscript
var point_position: Vector3 = Vector3(1.0, 0.5, 0.0)
```

The vector is the data-model. Any visible sphere is only a proxy so bodies can see and grab that position.

## Interactive Point Implementation

`interactive_point_origin.tscn` uses `XRToolsPickable` and adds three feedback channels:

1. Material glow when picked up.
2. Audio + haptic pulse on pickup/drop.
3. A live line from current point position to `Vector3.ZERO`.

Core loop (simplified):

```gdscript
extends XRToolsPickable

var _is_held := false
var _line_mesh_instance: MeshInstance3D
var _line_cylinder: CylinderMesh

func _process(_delta: float) -> void:
	if _is_held:
		_update_line_to_origin()
		_update_position_label()
```

The current optimization avoids creating a new cylinder mesh every frame. The line mesh is created once and only its transform/height is updated while held.

## Fixed vs Movable Point

Point One now places:

- `static_point` on the isolated cube (fixed reference)
- `interactive_point_origin` on the main platform (movable reference)

This creates a direct technical contrast:

- static point: no XR pickup, low runtime updates
- interactive point: XR pickup, per-frame feedback only while held

## Script Runner Link

`script_runner#point` demonstrates the same concept in code form:

```gdscript
var point = Vector3(1.0, 0.5, 0.0)
print(point.x)
```

So the map aligns embodiment (grab and move) with symbolic representation (execute and inspect).

## VR Performance Notes

For this map's interactables:

- Keep per-frame work conditional (`_is_held`) for interactive objects.
- Reuse meshes/materials in loops; avoid runtime mesh allocation in `_process`.
- Keep tiny point meshes low-segment where possible.
- Debounce tactile button triggers so one touch does not cause multiple toggles.

## Key Takeaway

A point is still just coordinates. VR interaction layers on top of that model: feedback, visibility, and embodied control. The implementation should preserve that simplicity while staying robust at VR frame rates.
