# Supplied desktop adapter. H engages/releases a mouse-aimed study brush.
# XR uses the inherited body's pickup and action signals instead.
extends Node

var engaged := false

func _unhandled_input(event: InputEvent) -> void:
    var study := get_parent()
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_H:
        engaged = not engaged
        study.set_held(engaged)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and engaged:
        study.set_action("spray", event.pressed)

func _process(_delta: float) -> void:
    if not engaged:
        return
    var camera := get_viewport().get_camera_3d()
    if camera == null:
        return
    var mouse := get_viewport().get_mouse_position()
    var direction := camera.project_ray_normal(mouse)
    var at := camera.project_ray_origin(mouse) + direction * 0.5
    var point: Node3D = get_parent().point
    point.global_position = at
    point.look_at(at + direction)
