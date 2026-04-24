# Single

One cube, one platform, one grab. The VR baseline.

Spawn the cube.

```gdscript
func spawn_cube() -> RigidBody3D:
    var cube := RigidBody3D.new()
    var mesh := MeshInstance3D.new()
    mesh.mesh = BoxMesh.new()
    cube.add_child(mesh)
    cube.global_position = Vector3(0, 1, 0)
    add_child(cube)
    return cube
```

RigidBody3D for physics; MeshInstance3D for rendering. Godot composes them as a parent-child pair.

Add a collision shape.

```gdscript
func add_collision(cube: RigidBody3D) -> void:
    var shape := CollisionShape3D.new()
    shape.shape = BoxShape3D.new()
    cube.add_child(shape)
```

Without the shape, the body does not interact with anything. The shape matches the mesh.

Make it grabbable.

```gdscript
func make_grabbable(cube: RigidBody3D) -> void:
    cube.add_to_group("grabbable")
    var grab_area := Area3D.new()
    var area_shape := CollisionShape3D.new()
    area_shape.shape = BoxShape3D.new()
    grab_area.add_child(area_shape)
    cube.add_child(grab_area)
```

The Area3D detects the controller's grab collision. The separate area prevents collision interference with the body.

Handle grab events.

```gdscript
class_name GrabbableCube extends RigidBody3D

var held_by: XRController3D = null

func _on_controller_grip_pressed(controller: XRController3D) -> void:
    var distance: float = controller.global_position.distance_to(global_position)
    if distance < 0.3:
        held_by = controller
        freeze = true

func _on_controller_grip_released() -> void:
    held_by = null
    freeze = false
```

Grip press while near the cube grabs it. Release drops it back into physics.

Follow the controller while held.

```gdscript
func _physics_process(_delta: float) -> void:
    if held_by:
        global_position = held_by.global_position
        global_rotation = held_by.global_rotation
```

Direct teleport each frame. A more sophisticated implementation would add velocity smoothing.

Add a teleporter at the end.

```gdscript
func add_teleporter(position: Vector3, target_map: String) -> void:
    var teleporter := Area3D.new()
    teleporter.global_position = position
    teleporter.body_entered.connect(func(body):
        if body.is_in_group("learner"):
            get_tree().change_scene_to_file(target_map)
    )
    add_child(teleporter)
```

The teleporter triggers a scene change when the learner's body enters. No confirmation needed — the learner opted in by walking onto the pad.

You can now spawn a grabbable cube, handle grab and release, and place a teleporter. Tutorial_Row extends into a single-dimension corridor.

Detect the grip gesture.

```gdscript
func is_grip_pressed(controller: XRController3D) -> bool:
    return controller.get_float("grip") > 0.8
```

The grip button reports a float from 0 to 1. Threshold at 0.8 for a reliable press detection.

Add a brief haptic buzz on grab.

```gdscript
func buzz_controller(controller: XRController3D) -> void:
    controller.trigger_haptic_pulse("haptic", 0.0, 0.5, 0.1, 0.0)
```

A short pulse confirms the grab. The parameters are frequency, amplitude, duration, and delay.

Limit the grab range.

```gdscript
const GRAB_RANGE := 0.3

func within_grab_range(controller: XRController3D, target: Node3D) -> bool:
    return controller.global_position.distance_to(target.global_position) < GRAB_RANGE
```

30 centimetres is a comfortable reach without overcommitting. Outside the range, the grab doesn't register.
