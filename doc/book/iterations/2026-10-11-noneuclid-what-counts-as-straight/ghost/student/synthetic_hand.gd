extends Node3D
# Test fixture only: synthetic sustained desktop movement, not an XR controller.
var point: Node3D
var frame: Node3D
var local_target := Vector3.ZERO
var active := false
var render_ticks := 0
var physics_ticks := 0

func _ready() -> void:
    process_priority = -100
    process_physics_priority = -100

func _process(_delta: float) -> void:
    if active:
        point.global_position = frame.to_global(local_target)
        render_ticks += 1

func _physics_process(_delta: float) -> void:
    if active:
        point.global_position = frame.to_global(local_target)
        physics_ticks += 1
