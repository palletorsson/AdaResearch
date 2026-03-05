# monte_carlo_estimator.gd
## Estimates π using Monte Carlo integration: throw random points into a
## unit square, count how many land inside the inscribed unit circle, then
## apply π ≈ 4 × (inside / total). Convergence follows the law of large
## numbers — more samples yield a tighter estimate.
##
## QFEP: Order (π) emerges from randomness through accumulation

extends Node3D

class_name MonteCarloEstimator

# -- Constants --
const BOARD_THICKNESS := 0.02
const GRID_LINE_THICKNESS := 0.002
const GRID_LINE_Y := 0.005
const GRID_DIVISIONS := 5
const CIRCLE_OUTLINE_Y := 0.008
const CIRCLE_FILL_HEIGHT := 0.001
const DART_RADIUS := 0.006
const DART_Y := 0.01
const EMISSION_ENERGY := 0.3

## Side length of the square dartboard
@export_range(0.1, 2.0, 0.05) var board_size: float = 0.5

## How many darts are thrown per second during auto-throw
@export_range(1.0, 100.0) var darts_per_second: float = 20.0:
	set(value):
		darts_per_second = clampf(value, 1.0, 100.0)

## Maximum number of darts before auto-throw stops
@export_range(100, 10000) var max_darts: int = 2000

## Whether darts are thrown automatically each frame
@export var auto_throw: bool = true

## Color for darts that land inside the circle
@export var color_inside: Color = Color(0.3, 0.8, 1.0)
## Color for darts that land outside the circle
@export var color_outside: Color = Color(1.0, 0.4, 0.3)
## Color of the circle outline overlay
@export var color_circle: Color = Color(0.8, 0.8, 0.8, 0.3)

# State
var _inside_count: int = 0
var _total_count: int = 0
var _throw_timer: float = 0.0

# Visuals
var _board: MeshInstance3D
var _circle_outline: MeshInstance3D
var _dart_mm: MultiMesh
var _dart_mmi: MultiMeshInstance3D
var _info_label: Label3D
var _pi_label: Label3D
var _control_panel: Node3D

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")
const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")

func _ready() -> void:
	_create_board()
	_create_circle()
	_create_dart_multimesh()
	_create_labels()
	_create_vr_controls()

## Build the square dartboard with grid lines
func _create_board() -> void:
	_board = MeshInstance3D.new()
	_board.name = "Board"
	var box = BoxMesh.new()
	box.size = Vector3(board_size, BOARD_THICKNESS, board_size)
	_board.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.08, 0.1)
	_board.material_override = mat
	_board.position = Vector3(0, -BOARD_THICKNESS / 2, 0)
	add_child(_board)

	# Grid lines via MultiMesh
	var line_mat = StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.2, 0.2, 0.25)

	var line_count = GRID_DIVISIONS * 2 + 1  # -5..5 = 11

	# Horizontal grid lines
	var h_box = BoxMesh.new()
	h_box.size = Vector3(board_size, GRID_LINE_THICKNESS, GRID_LINE_THICKNESS)
	var h_mm = MultiMesh.new()
	h_mm.transform_format = MultiMesh.TRANSFORM_3D
	h_mm.mesh = h_box
	h_mm.instance_count = line_count
	for i in line_count:
		var t = float(i - GRID_DIVISIONS) / float(GRID_DIVISIONS) * board_size / 2
		var xf = Transform3D()
		xf.origin = Vector3(0, GRID_LINE_Y, t)
		h_mm.set_instance_transform(i, xf)
	var h_mmi = MultiMeshInstance3D.new()
	h_mmi.multimesh = h_mm
	h_mmi.material_override = line_mat
	add_child(h_mmi)

	# Vertical grid lines
	var v_box = BoxMesh.new()
	v_box.size = Vector3(GRID_LINE_THICKNESS, GRID_LINE_THICKNESS, board_size)
	var v_mm = MultiMesh.new()
	v_mm.transform_format = MultiMesh.TRANSFORM_3D
	v_mm.mesh = v_box
	v_mm.instance_count = line_count
	for i in line_count:
		var t = float(i - GRID_DIVISIONS) / float(GRID_DIVISIONS) * board_size / 2
		var xf = Transform3D()
		xf.origin = Vector3(t, GRID_LINE_Y, 0)
		v_mm.set_instance_transform(i, xf)
	var v_mmi = MultiMeshInstance3D.new()
	v_mmi.multimesh = v_mm
	v_mmi.material_override = line_mat
	add_child(v_mmi)

## Draw the inscribed circle and translucent fill
func _create_circle() -> void:
	_circle_outline = MeshInstance3D.new()
	_circle_outline.name = "CircleOutline"

	var torus = TorusMesh.new()
	torus.inner_radius = board_size / 2 - 0.005
	torus.outer_radius = board_size / 2 + 0.005
	_circle_outline.mesh = torus
	_circle_outline.rotation_degrees.x = 90

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_circle
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_circle_outline.material_override = mat
	_circle_outline.position = Vector3(0, CIRCLE_OUTLINE_Y, 0)
	add_child(_circle_outline)

	var circle_fill = MeshInstance3D.new()
	circle_fill.name = "CircleFill"
	var cyl = CylinderMesh.new()
	cyl.top_radius = board_size / 2
	cyl.bottom_radius = board_size / 2
	cyl.height = CIRCLE_FILL_HEIGHT
	circle_fill.mesh = cyl

	var fill_mat = StandardMaterial3D.new()
	fill_mat.albedo_color = Color(0.2, 0.3, 0.4, 0.2)
	fill_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	circle_fill.material_override = fill_mat
	circle_fill.position = Vector3(0, 0.003, 0)
	add_child(circle_fill)

## Pre-allocate the dart MultiMesh for GPU-instanced rendering
func _create_dart_multimesh() -> void:
	var sphere = SphereMesh.new()
	sphere.radius = DART_RADIUS
	sphere.height = DART_RADIUS * 2.0

	_dart_mm = MultiMesh.new()
	_dart_mm.transform_format = MultiMesh.TRANSFORM_3D
	_dart_mm.use_colors = true
	_dart_mm.mesh = sphere
	_dart_mm.instance_count = max_darts
	_dart_mm.visible_instance_count = 0

	_dart_mmi = MultiMeshInstance3D.new()
	_dart_mmi.name = "Darts"
	_dart_mmi.multimesh = _dart_mm

	# Shader drives albedo + emission from per-instance COLOR
	var shader = Shader.new()
	shader.code = "shader_type spatial;\nvoid fragment() {\n\tALBEDO = COLOR.rgb;\n\tEMISSION = COLOR.rgb * 0.3;\n}\n"
	var smat = ShaderMaterial.new()
	smat.shader = shader
	_dart_mmi.material_override = smat

	add_child(_dart_mmi)

## Create floating text labels for the pi estimate
func _create_labels() -> void:
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 16
	_info_label.position = Vector3(0, 0.15, 0)
	_info_label.text = "MONTE CARLO π"
	add_child(_info_label)

	_pi_label = Label3D.new()
	_pi_label.name = "PiLabel"
	_pi_label.pixel_size = 0.003
	_pi_label.font_size = 24
	_pi_label.position = Vector3(0, 0.08, 0)
	_pi_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_pi_label)
	_update_pi_display()

## Build the VR control panel with speed slider and action buttons
func _create_vr_controls() -> void:
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, -0.05, board_size / 2 + 0.15)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)

	# Panel backdrop
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.35, 0.12, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.01
	_control_panel.add_child(panel_back)

	# Speed slider
	var speed_slider = SLIDER_HORIZONTAL.instantiate()
	speed_slider.name = "SpeedSlider"
	speed_slider.position = Vector3(0, 0.025, 0)
	speed_slider.rotation_degrees.x = -30
	speed_slider.scale = Vector3(0.8, 0.8, 0.8)
	var speed_label = speed_slider.get_node_or_null("Frame/LabelName")
	if speed_label:
		speed_label.text = "SPEED"
	_control_panel.add_child(speed_slider)
	speed_slider.slider_moved.connect(func(_pos):
		if speed_slider.has_method("get_normalized_value"):
			darts_per_second = 1.0 + speed_slider.get_normalized_value() * 99.0
	)

	# Control buttons
	var buttons = [
		["THROW", func(): _throw_dart()],
		["×10", func(): for i in 10: _throw_dart()],
		["×100", func(): for i in 100: _throw_dart()],
		["CLEAR", func(): _clear_darts()]
	]

	for i in range(buttons.size()):
		var btn = PUSH_BUTTON.instantiate()
		btn.name = "Btn%d" % i
		btn.position = Vector3(-0.12 + i * 0.08, -0.025, 0)
		btn.scale = Vector3(0.65, 0.65, 0.65)
		_control_panel.add_child(btn)
		_add_button_label(btn, buttons[i][0])

		var callback = buttons[i][1]
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(callback)

## Add a text label below a VR button
func _add_button_label(btn: Node, text: String) -> void:
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.0008
	lbl.font_size = 7
	lbl.position = Vector3(0, -0.02, 0)
	btn.add_child(lbl)

func _process(delta: float) -> void:
	if auto_throw and _total_count < max_darts:
		_throw_timer += delta
		var interval = 1.0 / darts_per_second
		while _throw_timer >= interval and _total_count < max_darts:
			_throw_timer -= interval
			_throw_dart()
		# Bound accumulator to prevent floating-point precision loss
		_throw_timer = fmod(_throw_timer, maxf(interval, 0.001))

## Place a single dart at a random position and update the estimate
func _throw_dart() -> void:
	if _total_count >= max_darts:
		return

	var x = randf() * 2.0 - 1.0
	var z = randf() * 2.0 - 1.0

	var inside = (x * x + z * z) <= 1.0

	if inside:
		_inside_count += 1

	# Set MultiMesh instance transform and color
	var xf = Transform3D()
	xf.origin = Vector3(x * board_size / 2, DART_Y, z * board_size / 2)
	_dart_mm.set_instance_transform(_total_count, xf)
	_dart_mm.set_instance_color(_total_count, color_inside if inside else color_outside)

	_total_count += 1
	_dart_mm.visible_instance_count = _total_count

	_update_pi_display()

## Remove all darts and reset the estimate
func _clear_darts() -> void:
	_dart_mm.visible_instance_count = 0
	_inside_count = 0
	_total_count = 0
	_throw_timer = 0.0
	_update_pi_display()

## Refresh the pi label text and color based on current accuracy
func _update_pi_display() -> void:
	if _total_count == 0:
		_pi_label.text = "π ≈ ?"
		return

	var pi_estimate = 4.0 * float(_inside_count) / maxf(float(_total_count), 0.0001)
	var error = abs(pi_estimate - PI)

	_pi_label.text = "π ≈ %.6f\n(%d/%d)" % [pi_estimate, _inside_count, _total_count]

	# Color by accuracy
	if error < 0.01:
		_pi_label.modulate = Color(0.3, 1.0, 0.4)
	elif error < 0.1:
		_pi_label.modulate = Color(1.0, 0.8, 0.3)
	else:
		_pi_label.modulate = Color(1.0, 0.5, 0.3)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE: _throw_dart()
			KEY_C: _clear_darts()
			KEY_T: for i in 10: _throw_dart()
			KEY_H: for i in 100: _throw_dart()

## Throw a single dart (public API)
func throw() -> void:
	_throw_dart()

## Clear all darts and reset (public API)
func clear() -> void:
	_clear_darts()

## Returns the current π estimate, or 0.0 if no darts thrown
func get_estimate() -> float:
	if _total_count == 0:
		return 0.0
	return 4.0 * float(_inside_count) / maxf(float(_total_count), 0.0001)

## Grid system integration hook
func apply_grid_config(config_data: Dictionary) -> void:
	pass
