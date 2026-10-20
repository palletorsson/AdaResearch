extends Node3D
## F6 architectural viewer, not a gameplay or VR staging scene.
const Architecture := preload("res://commons/void/architecture.gd")
const Atmosphere := preload("res://commons/void/atmosphere.gd")
var building: Node3D
var camera: Camera3D
var hud: Label
var view_index := 0
var view_names := ["01 / rooftop", "02 / looking into shaft A", "03 / floor 01", "04 / structural overview", "05 / floor plan"]

func _ready() -> void:
	building = Architecture.new()
	building.name = "VoidArchitecture"
	add_child(building)
	var atmosphere := Atmosphere.new()
	add_child(atmosphere)
	camera = Camera3D.new()
	camera.environment = atmosphere.environment
	camera.near = 0.05
	camera.far = 600
	camera.fov = 78
	add_child(camera)
	camera.make_current()
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Label.new()
	hud.position = Vector2(24, 20)
	hud.add_theme_font_size_override("font_size", 18)
	hud.add_theme_color_override("font_color", Color("f5f1e9"))
	hud.add_theme_color_override("font_shadow_color", Color("252e3e"))
	hud.add_theme_constant_override("shadow_offset_x", 1)
	hud.add_theme_constant_override("shadow_offset_y", 2)
	canvas.add_child(hud)
	set_view(0)

func set_view(index: int) -> void:
	view_index = posmod(index, view_names.size())
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	var target := Vector3.ZERO
	match view_index:
		0:
			camera.position = Vector3(1, 1.7, 6.5)
			target = Vector3(-8.5, -0.2, 0)
		1:
			camera.position = Vector3(-8.0, 1.7, 1.8)
			target = Vector3(-10.5, -7.5, -0.2)
		2:
			camera.position = Vector3(-3.6, -4.3, 6.2)
			target = Vector3(8, -5.7, -1)
		3:
			camera.projection = Camera3D.PROJECTION_ORTHOGONAL
			camera.size = 42
			camera.position = Vector3(31, 15, 36)
			target = Vector3(0, -5, 0)
		4:
			camera.projection = Camera3D.PROJECTION_ORTHOGONAL
			camera.size = 36
			camera.position = Vector3(0, 40, 0.01)
			target = Vector3.ZERO
	camera.look_at(target)
	hud.text = "THE VOID  /  architecture study\n%s\n1–5: views   P: optional wall\nPlayable descent: main menu > The Void" % view_names[view_index]

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo: return
	if event.keycode >= KEY_1 and event.keycode <= KEY_5:
		set_view(event.keycode - KEY_1)
	elif event.keycode == KEY_P:
		building.show_partitions(not building.partitions.visible)
