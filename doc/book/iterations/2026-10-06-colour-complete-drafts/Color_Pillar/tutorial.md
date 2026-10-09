# Pillar — colour has a height

**Learning elements**

- Hue, saturation and value as a coordinate model
- A function returning a colour from a position
- Mapping a reachable height to a taller field
- Distinguishing a colour value from illumination

Stand among the museum's columns. Colour rises towards the ceiling; near their tops, a column and its surrounding colour can become hard to separate. The dark floor gives that ascent a beginning.

Return to the point from Nails. Its position still supplies three numbers, but the numbers now control hue, saturation and value. Y becomes a way to move from dark to light while X and Z stay still.

## Continue with PointBody

Keep the unchanged `point_body.gd` from Lines, Coordinates and Nails. Save `lesson.gd` beside it. Attach the script to a Node3D in your working copy of the Pillar hall. Its local origin is the floor-level corner of a 12.8 by 19.2 metre colour field, with X across and Z along the field. Keep the study and its parents at unit scale. These extents match the museum's colour rule; they are not inferred from room walls.

The point starts halfway across that field, 1.25 metres above its floor. The small preview and readout travel with it. Walk to it and grip it using the prepared XR hands. On desktop, change `start` and run again. The existing columns and ceiling remain the large illustration; this study adds a sampler and does not rebuild them or attach itself to their materials.

## The complete continuation — lesson.gd

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const VALUE_BOTTOM := 0.46
const VALUE_TOP := 4.6

var start := Vector3(6.4, 1.25, 9.6)
var point: XRToolsPickable
var swatch: StandardMaterial3D
var readout: Label3D

func _ready() -> void:
    point = PointBody.new()
    point.position = start
    add_child(point)
    var preview := MeshInstance3D.new()
    var tile := BoxMesh.new()
    tile.size = Vector3(0.28, 0.28, 0.025)
    preview.mesh = tile
    preview.position = Vector3(0.35, 0, 0)
    swatch = StandardMaterial3D.new()
    swatch.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    preview.material_override = swatch
    point.add_child(preview)
    readout = Label3D.new()
    readout.position = Vector3(0.35, 0.35, 0)
    readout.font_size = 28
    readout.pixel_size = 0.002
    point.add_child(readout)

func _process(_delta: float) -> void:
    var hand := to_local(point.global_position)
    var field := hand_to_field(hand)
    var hsv := hsv_at(field)
    var colour := colour_at(field)
    swatch.albedo_color = colour
    readout.text = "HSV %.3f %.3f %.3f\nRGB %.3f %.3f %.3f" % [hsv.x, hsv.y, hsv.z, colour.r, colour.g, colour.b]

func hand_to_field(hand: Vector3) -> Vector3:
    var fraction := clampf((hand.y - 0.65) / 1.2, 0, 1)
    return Vector3(hand.x, lerpf(VALUE_BOTTOM, VALUE_TOP, fraction), hand.z)

func hsv_at(p: Vector3) -> Vector3:
    var hue := clampf(p.x / 12.8, 0, 1) * 0.85
    var saturation := lerpf(0.25, 1.0, clampf(p.z / 19.2, 0, 1))
    var value := clampf((p.y - VALUE_BOTTOM) / (VALUE_TOP - VALUE_BOTTOM), 0, 1)
    return Vector3(hue, saturation, value)

func colour_at(p: Vector3) -> Color:
    var hsv := hsv_at(p)
    return Color.from_hsv(hsv.x, hsv.y, hsv.z)
```

At the start, expect `HSV 0.425 0.625 0.500` and approximately `RGB 0.188 0.500 0.359`. The displayed RGB numbers are rounded; their unrounded values are `(0.1875, 0.5, 0.359375)`.

## Two mappings, two scales

`to_local(point.global_position)` expresses the carried point in this study's frame. `hand_to_field` then maps reachable hand heights from 0.65 to 1.85 metres onto field heights from 0.46 to 4.6 metres. You can inspect the whole vertical colour range without reaching the ceiling. `clampf` stops the returned fraction at zero and one; it does not stop your hand.

`hsv_at` gives each field coordinate a role. X chooses hue from 0 to 0.85. Z chooses saturation from 0.25 to 1. Y chooses value from 0 to 1. These ranges are authored decisions, including the omitted end of the hue cycle and the absence of zero saturation.

`colour_at` passes those three values to `Color.from_hsv` and returns a Color. The receiving material needs RGB channels; Godot performs the conversion. `hsv_at` also returns the original parameters for the readout, so a hue remains visible as a number even when value is zero and the swatch is black.

In Nails, moving up changed green. Here it changes value. The axis has acquired a different function. Neither coordinate arrangement is inherent in colour.

## Hold two coordinates still

1. Keep X = 6.4 and Z = 9.6. Set the starting Y to 0.65. Value reaches zero and the preview is black.
2. Set Y to 1.85. Value reaches one. Hue and saturation keep their previous values; all three RGB channels are twice their middle-height values.
3. Set Y to 2.5. The point is above the mapped hand range, but value stays at one.

Restore the starting height. Choose another X or Z and predict which HSV parameter will change. Then choose two different positions with the same Y. Their colours can differ while their value parameter stays equal.

The preview uses an unshaded material for comparison. Raising value does not add a light, and equal value does not guarantee equal perceived brightness for different hues. The columns' lighting and the ceiling's apparent fog belong to the larger encounter.

Write down one RGB result with enough precision to use again. Grid begins with the middle sample above as an entry in a palette. That record is the handoff; no automatic save between these study scripts is assumed.

## Inherited point — point_body.gd

The exact earlier class is included for a complete runnable folder. Its sphere, collider and pickup behaviour remain unchanged.

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable

const RADIUS := 0.14

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)
```
