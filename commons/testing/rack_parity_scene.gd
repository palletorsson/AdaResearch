extends Node3D

## Rack Parity Scene — shows 2D and 3D versions of each control side by side.
## Run this scene to capture comparison screenshots.
##
## Layout: Left column = 2D controls in SubViewport quads
##         Right column = 3D VR-wrapped controls
##         Each row is one control type, labeled.

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

const ROW_SPACING := 0.25
const COL_OFFSET := 0.35  # distance between 2D and 3D columns
const START_Y := 1.5


func _ready() -> void:
	_setup_environment()
	_build_rows()


func _setup_environment() -> void:
	# Dark background
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.06, 0.06, 0.08)
	env.environment.ambient_light_color = Color(0.8, 0.8, 0.85)
	env.environment.ambient_light_energy = 0.6
	add_child(env)

	# Soft directional light
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, -20, 0)
	light.light_energy = 0.8
	light.shadow_enabled = false
	add_child(light)

	# Camera facing the control wall
	var cam := Camera3D.new()
	cam.name = "ParityCamera"
	cam.position = Vector3(0.0, START_Y - (CONTROLS.size() * ROW_SPACING * 0.5), 1.2)
	cam.look_at(Vector3(0.0, START_Y - (CONTROLS.size() * ROW_SPACING * 0.5), 0.0))
	cam.current = true
	add_child(cam)

	# Column headers
	_add_header("2D Control", Vector3(-COL_OFFSET, START_Y + 0.15, 0.01))
	_add_header("3D VR Wrap", Vector3(COL_OFFSET, START_Y + 0.15, 0.01))


func _build_rows() -> void:
	for i in CONTROLS.size():
		var ctrl: Dictionary = CONTROLS[i]
		var y := START_Y - i * ROW_SPACING

		# Row label
		var label := Label3D.new()
		label.text = ctrl["name"]
		label.font_size = 10
		label.position = Vector3(-0.7, y, 0.01)
		label.modulate = Color(0.7, 0.7, 0.75, 0.8)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		add_child(label)

		# 2D version — SubViewport rendered onto a quad
		_add_2d_control(ctrl["scene"], ctrl["key"], Vector3(-COL_OFFSET, y, 0.0))

		# 3D version — VRRackControl wrapper
		_add_3d_control(ctrl["scene"], ctrl["key"], Vector3(COL_OFFSET, y, 0.0))

		# Thin separator line
		if i < CONTROLS.size() - 1:
			var sep := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(1.6, 0.001, 0.001)
			sep.mesh = box
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.2, 0.2, 0.25, 0.3)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			sep.material_override = mat
			sep.position = Vector3(0.0, y - ROW_SPACING * 0.5, 0.0)
			add_child(sep)


func _add_2d_control(scene_path: String, key: String, pos: Vector3) -> void:
	var scene := load(scene_path) as PackedScene
	if not scene:
		return

	var control_instance := scene.instantiate() as Control
	if not control_instance:
		return

	# Set a value so it's not at default
	if "normalized_value" in control_instance:
		control_instance.normalized_value = 0.65
	if "control_label" in control_instance:
		control_instance.control_label = key.to_upper()

	# Get pixel size
	var px_size := control_instance.custom_minimum_size
	if px_size == Vector2.ZERO:
		px_size = Vector2(80, 180)

	# SubViewport
	var viewport := SubViewport.new()
	viewport.disable_3d = true
	viewport.size = Vector2i(int(px_size.x * 2), int(px_size.y * 2))
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = true

	control_instance.anchors_preset = Control.PRESET_FULL_RECT
	control_instance.anchor_right = 1.0
	control_instance.anchor_bottom = 1.0
	viewport.add_child(control_instance)
	add_child(viewport)

	# Quad showing the viewport texture
	var physical_size := px_size / 1000.0  # pixels to meters
	var quad_mesh := MeshInstance3D.new()
	quad_mesh.name = "2D_%s" % key
	var quad := QuadMesh.new()
	quad.size = Vector2(physical_size.x, physical_size.y)
	quad_mesh.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = viewport.get_texture()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission_texture = viewport.get_texture()
	mat.emission_energy_multiplier = 0.8
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	quad_mesh.material_override = mat
	quad_mesh.position = pos
	add_child(quad_mesh)


func _add_3d_control(scene_path: String, key: String, pos: Vector3) -> void:
	var ctrl := VRRackControl.new()
	ctrl.control_scene_path = scene_path
	ctrl.name = "3D_%s" % key
	ctrl.position = pos
	add_child(ctrl)

	# Set value and label after build
	call_deferred("_configure_vr_control", ctrl, key)


func _configure_vr_control(ctrl: VRRackControl, key: String) -> void:
	if not is_instance_valid(ctrl):
		return
	ctrl.set_param_name(key.to_upper())
	ctrl.set_normalized_value(0.65)


func _add_header(text: String, pos: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 14
	label.position = pos
	label.modulate = Color(0.9, 0.9, 0.95, 0.9)
	add_child(label)


func apply_grid_config(_config: Dictionary) -> void:
	pass
