# Forces — shared code and the museum boundary

Use the existing Endless Museum and the PointStudy established in Primitives. Add the lesson files to the same project; they require its installed Godot XR Tools and existing push_button.tscn. The shared files are supplied in full below. No dollar references or undeclared scene nodes are required.

This is a sequence of related studies, not a claim that one physical instance automatically travels through every hall. Save your source files; replace the script on PointStudy for each lesson. The code continues the point class. Ordinary physics uses metres, kilograms and seconds. Only the flight lesson requires the museum’s player receiver; its exact contract is declared there.

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
