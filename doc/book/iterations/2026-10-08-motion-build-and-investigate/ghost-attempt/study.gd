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
