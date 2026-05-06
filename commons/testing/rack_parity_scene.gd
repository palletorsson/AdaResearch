extends Node3D

## Rack Parity Scene — 2D and 3D versions side by side, clean background.
## No cables, no back panel, no autoloads. Just the controls.

const CONTROLS = [
	{"key": "slv", "name": "Vertical Slider", "scene": "res://commons/audio/rack_controls/RackSliderV.tscn"},
	{"key": "slh", "name": "Horizontal Slider", "scene": "res://commons/audio/rack_controls/RackSliderH.tscn"},
	{"key": "sls", "name": "Stepped Slider", "scene": "res://commons/audio/rack_controls/RackSliderStepped.tscn"},
	{"key": "slz", "name": "Bipolar Slider", "scene": "res://commons/audio/rack_controls/RackSliderBipolar.tscn"},
	{"key": "knob", "name": "Knob", "scene": "res://commons/audio/rack_controls/RackKnob.tscn"},
	{"key": "wheel", "name": "Wheel", "scene": "res://commons/audio/rack_controls/RackWheel.tscn"},
	{"key": "xy", "name": "XY Pad", "scene": "res://commons/audio/rack_controls/RackXYPad.tscn"},
	{"key": "joystick", "name": "Joystick", "scene": "res://commons/audio/rack_controls/RackJoystick.tscn"},
	{"key": "lever", "name": "Lever", "scene": "res://commons/audio/rack_controls/RackLever.tscn"},
	{"key": "btn", "name": "Button", "scene": "res://commons/audio/rack_controls/RackButton.tscn"},
	{"key": "meter", "name": "Meter", "scene": "res://commons/audio/rack_controls/RackMeter.tscn"},
	{"key": "label", "name": "Label", "scene": "res://commons/audio/rack_controls/RackLabel.tscn"},
]

const ROW_SPACING := 0.28
const COL_2D := -0.3
const COL_3D := 0.3
const START_Y := 1.8
const BEZEL_DEPTH := 0.015


func _ready() -> void:
	# Kill any autoloaded audio/cable systems that might clutter
	for child in get_tree().root.get_children():
		if child != self and child.name != "RackParityScene":
			if "cable" in child.name.to_lower() or "audio" in child.name.to_lower() or "rack" in child.name.to_lower():
				child.visible = false

	_setup_environment()
	_build_rows()


func _setup_environment() -> void:
	# Clean dark background — no grid, no floor, no sky
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.04, 0.04, 0.06)
	env.environment.ambient_light_color = Color(0.9, 0.9, 0.95)
	env.environment.ambient_light_energy = 0.8
	add_child(env)

	# Soft front light
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-30, 0, 0)
	light.light_energy = 0.6
	light.shadow_enabled = false
	add_child(light)

	# Camera centered on the control wall
	var center_y := START_Y - (CONTROLS.size() * ROW_SPACING * 0.5)
	var cam := Camera3D.new()
	cam.name = "ParityCamera"
	cam.position = Vector3(0.0, center_y, 1.0)
	cam.look_at(Vector3(0.0, center_y, 0.0))
	cam.fov = 50.0
	cam.current = true
	add_child(cam)

	# Column headers
	_add_label("2D", Vector3(COL_2D, START_Y + 0.12, 0.01), 16, Color(0.5, 0.7, 1.0))
	_add_label("3D VR", Vector3(COL_3D, START_Y + 0.12, 0.01), 16, Color(1.0, 0.6, 0.3))


func _build_rows() -> void:
	for i in CONTROLS.size():
		var ctrl: Dictionary = CONTROLS[i]
		var y := START_Y - i * ROW_SPACING

		# Row label on far left
		_add_label(ctrl["name"], Vector3(-0.65, y, 0.01), 9, Color(0.5, 0.5, 0.55))

		# 2D version — flat quad with SubViewport
		_add_2d_version(ctrl["scene"], ctrl["key"], Vector3(COL_2D, y, 0.0))

		# 3D version — same control but with bezel chassis
		_add_3d_version(ctrl["scene"], ctrl["key"], Vector3(COL_3D, y, 0.0))


func _add_2d_version(scene_path: String, key: String, pos: Vector3) -> void:
	var packed := load(scene_path) as PackedScene
	if not packed:
		_add_label("missing", pos, 8, Color(0.8, 0.2, 0.2))
		return

	var control := packed.instantiate()
	if not control is Control:
		_add_label("not Control", pos, 8, Color(0.8, 0.2, 0.2))
		return

	# Configure
	if "normalized_value" in control:
		control.normalized_value = 0.65
	if "control_label" in control:
		control.control_label = key.to_upper()
	if "level" in control:
		control.level = 0.7
	if "text" in control:
		control.text = key.to_upper()

	var px: Vector2 = control.custom_minimum_size
	if px == Vector2.ZERO:
		px = Vector2(80, 180)

	# SubViewport
	var vp := SubViewport.new()
	vp.disable_3d = true
	vp.size = Vector2i(int(px.x * 3), int(px.y * 3))
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = true

	control.anchors_preset = Control.PRESET_FULL_RECT
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	vp.add_child(control)
	add_child(vp)

	# Flat quad — no bezel, just the control
	var phys: Vector2 = px / 1000.0
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "2D_%s" % key
	var quad := QuadMesh.new()
	quad.size = Vector2(phys.x, phys.y)
	mesh_inst.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = vp.get_texture()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission_texture = vp.get_texture()
	mat.emission_energy_multiplier = 1.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.material_override = mat
	mesh_inst.position = pos
	add_child(mesh_inst)


func _add_3d_version(scene_path: String, key: String, pos: Vector3) -> void:
	var packed := load(scene_path) as PackedScene
	if not packed:
		_add_label("missing", pos, 8, Color(0.8, 0.2, 0.2))
		return

	var control := packed.instantiate()
	if not control is Control:
		_add_label("not Control", pos, 8, Color(0.8, 0.2, 0.2))
		return

	# Configure
	if "normalized_value" in control:
		control.normalized_value = 0.65
	if "control_label" in control:
		control.control_label = key.to_upper()
	if "level" in control:
		control.level = 0.7
	if "text" in control:
		control.text = key.to_upper()

	var px: Vector2 = control.custom_minimum_size
	if px == Vector2.ZERO:
		px = Vector2(80, 180)

	# SubViewport
	var vp := SubViewport.new()
	vp.disable_3d = true
	vp.size = Vector2i(int(px.x * 3), int(px.y * 3))
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = true

	control.anchors_preset = Control.PRESET_FULL_RECT
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	vp.add_child(control)
	add_child(vp)

	var phys: Vector2 = px / 1000.0

	# Bezel chassis — dark box behind the screen
	var chassis := MeshInstance3D.new()
	chassis.name = "Chassis_%s" % key
	var chassis_mesh := BoxMesh.new()
	chassis_mesh.size = Vector3(phys.x + 0.01, phys.y + 0.01, BEZEL_DEPTH)
	chassis.mesh = chassis_mesh
	var bezel_mat := StandardMaterial3D.new()
	bezel_mat.albedo_color = Color(0.06, 0.06, 0.08)
	bezel_mat.metallic = 0.3
	bezel_mat.roughness = 0.7
	chassis.material_override = bezel_mat
	chassis.position = pos
	add_child(chassis)

	# Screen quad on front face of chassis
	var screen := MeshInstance3D.new()
	screen.name = "Screen_%s" % key
	var quad := QuadMesh.new()
	quad.size = Vector2(phys.x * 0.92, phys.y * 0.92)
	screen.mesh = quad
	var screen_mat := StandardMaterial3D.new()
	screen_mat.albedo_texture = vp.get_texture()
	screen_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	screen_mat.emission_enabled = true
	screen_mat.emission_texture = vp.get_texture()
	screen_mat.emission_energy_multiplier = 0.9
	screen_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	screen.material_override = screen_mat
	screen.position = pos + Vector3(0, 0, BEZEL_DEPTH * 0.5 + 0.001)
	add_child(screen)


func _add_label(text: String, pos: Vector3, font_size: int, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size
	label.position = pos
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(label)
