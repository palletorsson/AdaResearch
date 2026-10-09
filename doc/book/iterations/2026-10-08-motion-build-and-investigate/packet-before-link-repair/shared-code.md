# Forces — one body gains responses

Walk through the existing Endless Museum. Try the artifact first, then reconstruct one operation with the point you built earlier. The room contains more than the tutorial asks you to make. Return to those larger experiments when you want to combine what you have learned.

The point gains motion, force, resistance and attachments. The cube returns when support and shape matter. In the last hall, the points move you.

## Set up once

Keep `point_body.gd`, `free_point.gd` and `study.gd` in one Forces study folder. Their [complete source](forces-shared-code.md) accompanies the lessons:

- `point_body.gd` is your unchanged Lines point: sphere, collider and pickup.
- `free_point.gd` extends it with physical release. Gravity and damping begin at zero; each lesson changes these settings when needed.
- `study.gd` supplies a caption, a button and a thin cylinder for drawing relations. Each lesson contains its own motion or force rule.

Use your existing `PointStudy` Node3D in a clear working bay inside each hall, with a floor-level origin and scale `(1, 1, 1)`. Save each lesson script and replace the script attached to `PointStudy` as you proceed. You carry the class and your saved code; a single physical sphere does not automatically travel between halls.

The museum supplies the floor, lighting, camera and XR hands. These scripts use its installed Godot XR Tools and the declared `push_button.tscn`. The flight lesson also uses the existing capability court’s player movement adapter.

## Compare, then combine

Predict one change before editing. Restart the study to compare from the same beginning. Use metres, kilograms and seconds throughout. After the comparison, return to the larger artifact: another body, a second push or a changed release can make the next event harder to predict.

Each lesson keeps the complete code visible. “Model notes” records the limits and implementation details you may want to revisit after the first experiment.


## point_body.gd

Unchanged from Lines: a visible sphere, matching collision boundary and XR pickup.


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

## free_point.gd

A new subclass: physical release, explicit damping and gravity settings. Each lesson chooses whether to enable gravity or freeze its marker.


```gdscript
extends "point_body.gd"

func _ready() -> void:
    super()
    release_mode = XRToolsPickable.ReleaseMode.UNFROZEN
    freeze = false
    gravity_scale = 0.0
    linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
    linear_damp = 0.0
    angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
    angular_damp = 0.0
    can_sleep = false
    var black := StandardMaterial3D.new()
    black.albedo_color = Color("17191c")
    black.roughness = 0.16
    get_child(0).material_override = black
```

## study.gd

Supplied display furniture. Buttons emit the named action once per press. The thin cylinder is a drawing of a relation, without a collider.


```gdscript
extends Node3D
# Supplied display/control furniture; no motion or force calculation.
const Point = preload("free_point.gd")
const PushButton = preload("res://commons/interactables/push_button.tscn")
var buttons: Dictionary = {}

func caption(words: String, at := Vector3(0, 1.8, -0.5)) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = 36
    text.pixel_size = 0.004
    text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(text)
    return text

func button(title: String, at: Vector3, action: Callable) -> void:
    var control = PushButton.instantiate()
    control.position = at
    control.rotation.x = -PI / 2.0
    add_child(control)
    control.pressed.connect(action)
    buttons[title] = control
    caption(title, at + Vector3.UP * 0.16)

func rod() -> MeshInstance3D:
    var surface := MeshInstance3D.new()
    var shape := CylinderMesh.new()
    shape.top_radius = 0.015
    shape.bottom_radius = 0.015
    shape.height = 1.0
    surface.mesh = shape
    add_child(surface)
    return surface

func join(surface: MeshInstance3D, a: Vector3, b: Vector3) -> void:
    var d := b - a
    surface.visible = d.length() > 0.0001
    if not surface.visible:
        return
    surface.position = (a + b) / 2.0
    surface.quaternion = Quaternion(Vector3.UP, d.normalized())
    surface.scale = Vector3(1, d.length(), 1)
```

## Existing receiver for the last hall

`commons/artifacts/force_capability_lab/force_capability_lab.gd` sums `acceleration()` from `ada_thrust_points` whose `receiver()` matches the player. `commons/artifacts/force_field_zone/field_carry_provider.gd` performs the XRTools movement handoff. These supplied museum components own collisions and gravity. Rebuilding the player is not part of this lesson. The continuation introduces the point’s action and its receiver contract.
