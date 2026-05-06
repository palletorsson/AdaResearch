extends Node3D

const RackTpl = preload("res://commons/audio/rack_templates/RackTemplates.gd")

var _timer := 0.0
var _shot := 0
var _cam: Camera3D

func _ready():
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.72, 0.70, 0.66)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 4.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var light := DirectionalLight3D.new()
	light.light_energy = 2.0
	light.rotation_degrees = Vector3(-40, -30, 0)
	light.shadow_enabled = true
	add_child(light)

	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.6
	fill.rotation_degrees = Vector3(-20, 150, 0)
	add_child(fill)

	_cam = Camera3D.new()
	_cam.fov = 30
	_cam.current = true
	add_child(_cam)
	_cam.transform.origin = Vector3(0.03, 0.02, 0.12)
	_cam.look_at(Vector3(0, -0.01, 0), Vector3.UP)

	# Panel with just one button
	var panel: Node3D = RackTpl.create_panel("BUTTON", [
		[{"type": "button", "label": "PRESS"}],
	])
	add_child(panel)

	print("ButtonCloseup: ready")


func _process(delta: float) -> void:
	_timer += delta
	if _timer > 1.0 and _shot == 0:
		_save("button_front")
		_cam.transform.origin = Vector3(0.08, 0.03, 0.08)
		_cam.look_at(Vector3(0, -0.01, 0), Vector3.UP)
		_shot = 1
		_timer = 0.0
	elif _timer > 0.5 and _shot == 1:
		_save("button_side")
		_cam.transform.origin = Vector3(0.01, 0.10, 0.02)
		_cam.look_at(Vector3(0, -0.01, 0), Vector3.UP)
		_shot = 2
		_timer = 0.0
	elif _timer > 0.5 and _shot == 2:
		_save("button_top")
		print("ButtonCloseup: ALL 3 SHOTS SAVED")
		_shot = 3


func _save(name: String) -> void:
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("user://button_shots")
	var path := "user://button_shots/%s.png" % name
	img.save_png(path)
	print("ButtonCloseup: Saved %s" % path)
