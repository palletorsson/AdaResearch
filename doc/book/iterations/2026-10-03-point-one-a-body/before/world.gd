extends Node3D
## Supplied room and input context. main.tscn attaches the student's study separately.

const DesktopPlayer = preload("res://prepared/desktop_player.gd")
const XRPlayer = preload("res://prepared/xr_player.gd")
const CUBE_HOME := Vector3(-1.65, 1.24, -0.2)

@export_group("Studio light")
@export var studio_environment: Environment = preload("res://prepared/studio_environment.tres")
@export_range(0.0, 3.0, 0.05) var key_energy := 0.65
@export var key_rotation_degrees := Vector3(-48, -32, 0)
@export_range(0.0, 1.0, 0.05) var fill_energy := 0.18

var player: Node3D
var test_cube: XRToolsPickable
var xr_active := false
var xr_interface: OpenXRInterface

func _ready() -> void:
	_make_room()
	_make_test_cube()
	xr_interface = XRServer.find_interface("OpenXR")
	xr_active = xr_interface != null and xr_interface.is_initialized()
	if xr_active:
		player = XRPlayer.new()
		get_viewport().use_xr = true
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		xr_interface.session_focussed.connect(_resume_xr)
		xr_interface.session_visible.connect(_pause_xr)
		xr_interface.session_stopping.connect(_pause_xr)
	else:
		player = DesktopPlayer.new()
		_desktop_help()
	player.position = Vector3(0, 0, 2.5)
	player.reset_requested.connect(reset_cube)
	add_child(player)
	if xr_active:
		player.set_input_active(xr_interface.get_session_state() == OpenXRInterface.SESSION_STATE_FOCUSED)
		if xr_interface.get_session_state() == OpenXRInterface.SESSION_STATE_FOCUSED:
			_resume_xr()
	print("Ada starter: ", "XR" if xr_active else "desktop", " / Point Zero is a separate study.")

func _physics_process(_delta: float) -> void:
	if test_cube.global_position.y < -3.0 and not test_cube.is_picked_up():
		reset_cube()

func reset_cube() -> void:
	test_cube.drop()
	test_cube.linear_velocity = Vector3.ZERO
	test_cube.angular_velocity = Vector3.ZERO
	test_cube.global_transform = Transform3D(Basis.IDENTITY, CUBE_HOME)
	test_cube.sleeping = false

func _pause_xr() -> void:
	player.set_input_active(false)

func _resume_xr() -> void:
	player.set_input_active(true)
	var rate := xr_interface.get_display_refresh_rate()
	if rate > 0:
		Engine.physics_ticks_per_second = int(rate)

func _make_room() -> void:
	var environment := WorldEnvironment.new()
	environment.name = "StudioEnvironment"
	environment.environment = studio_environment.duplicate(true)
	var interface := XRServer.find_interface("OpenXR")
	var on_headset := interface != null and interface.is_initialized()
	var renderer := RenderingServer.get_current_rendering_method()
	var desktop_studio := renderer == "forward_plus" and not on_headset
	# Calibrated separately: Compatibility otherwise clips the pale surfaces.
	var light_gain := 0.5 if renderer == "gl_compatibility" else 1.0
	# Keep the changing counter legible; temporal AA ghosts successive digits.
	get_viewport().use_taa = false
	environment.environment.ssao_enabled = desktop_studio
	environment.environment.ssao_radius = 0.35
	environment.environment.ssao_intensity = 1.3
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.name = "KeyLight"
	sun.rotation_degrees = key_rotation_degrees
	sun.light_color = Color("fff2df")
	sun.light_energy = key_energy * light_gain
	sun.shadow_enabled = true
	sun.shadow_blur = 1.25
	sun.shadow_normal_bias = 2.0
	sun.directional_shadow_max_distance = 18.0
	sun.light_angular_distance = 1.5 if desktop_studio else 0.0
	add_child(sun)
	# A dim, unshadowed fill is a deliberate studio approximation, not bounced GI.
	var fill := DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.rotation_degrees = Vector3(-28, 145, 0)
	fill.light_color = Color("d5dfef")
	fill.light_energy = fill_energy * light_gain
	add_child(fill)
	_box(Vector3(8, 0.2, 9), Vector3(0, -0.1, 0), Color("333139"))
	_box(Vector3(8, 3.2, 0.2), Vector3(0, 1.6, -4.5), Color("e7e3d9"))
	_box(Vector3(0.2, 3.2, 9), Vector3(-4, 1.6, 0), Color("e7e3d9"))
	_box(Vector3(0.2, 3.2, 9), Vector3(4, 1.6, 0), Color("e7e3d9"))
	_box(Vector3(8, 3.2, 0.2), Vector3(0, 1.6, 4.5), Color("e7e3d9"))
	_box(Vector3(3.6, 2.55, 0.14), Vector3(0, 1.275, -3), Color("292830"))
	_box(Vector3(0.8, 1.0, 0.8), Vector3(-1.65, 0.5, -0.2), Color("e7e3d9"))
	_label("ADA / A PLACE TO BEGIN", Vector3(0, 2.95, -4.37), 44, Color("333139"))
	_label("YOUR STUDY", Vector3(0, 2.2, -2.91), 25, Color("d6abbc"))
	_label("A room, a view, a body.\nThe counter is yours to change.", Vector3(0, 0.77, -2.91), 23, Color("ddd5d8"))
	_label("PICK UP / LET GO", Vector3(-1.65, 0.78, 0.21), 17, Color("333139"))
	_label("XR: left stick to move / right stick to turn\nGrip near the cube to hold / B or Y to return it", Vector3(0, 0.26, -2.91), 16, Color("c9c3c6"))

func _box(size: Vector3, at: Vector3, colour: Color) -> void:
	var body := StaticBody3D.new()
	body.position = at
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.9
	mesh.material_override = material
	body.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _label(words: String, at: Vector3, size: int, colour: Color) -> void:
	var label := Label3D.new()
	label.text = words
	label.position = at
	label.font_size = size
	label.pixel_size = 0.003
	label.modulate = colour
	label.outline_size = 0
	add_child(label)

func _make_test_cube() -> void:
	test_cube = XRToolsPickable.new()
	test_cube.name = "SuppliedPickup"
	test_cube.position = CUBE_HOME
	test_cube.collision_layer = 4
	test_cube.collision_mask = 1 | 4
	test_cube.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	test_cube.mass = 0.25
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = Vector3.ONE * 0.35
	mesh.mesh = shape
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("c95083")
	material.roughness = 0.32
	mesh.material_override = material
	test_cube.add_child(mesh)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = shape.size
	collision.shape = box
	test_cube.add_child(collision)
	add_child(test_cube)

func _desktop_help() -> void:
	var layer := CanvasLayer.new()
	var help := Label.new()
	help.text = "DESKTOP  /  Click to look · WASD / arrows to walk · Aim + E / click to pick up or drop · R to return cube · Esc for cursor"
	help.position = Vector2(20, 20)
	help.add_theme_font_size_override("font_size", 15)
	help.add_theme_color_override("font_color", Color("ffffff"))
	help.add_theme_color_override("font_shadow_color", Color("18171b"))
	help.add_theme_constant_override("shadow_offset_x", 1)
	help.add_theme_constant_override("shadow_offset_y", 1)
	layer.add_child(help)
	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(crosshair)
	add_child(layer)
