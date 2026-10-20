extends "res://commons/museum_runner/forms/point_body.gd"
## The lesson's PointBody, with desktop input parity and a dark finish.
var desktop_held := false

func _ready() -> void:
	super()
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color("10131d")
	finish.metallic = 0.65
	finish.roughness = 0.16
	for child in get_children():
		if child is MeshInstance3D: child.material_override = finish

func is_held() -> bool: return desktop_held or is_picked_up()

func on_desktop_grab(_pointer: Node) -> void:
	desktop_held = true
	picked_up.emit(self)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_held = false
	dropped.emit(self)
