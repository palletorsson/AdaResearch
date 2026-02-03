# monte_carlo_estimator.gd
# Monte Carlo Pi estimation with falling darts
# Visual proof: π ≈ 4 × (points in circle / total points)
#
# QFEP: Order (π) emerges from randomness through accumulation

extends Node3D

class_name MonteCarloEstimator

## Board size
@export var board_size: float = 0.5

## Sampling
@export var darts_per_second: float = 20.0:
	set(value):
		darts_per_second = clampf(value, 1.0, 100.0)

@export var max_darts: int = 2000
@export var auto_throw: bool = true

## Colors
@export var color_inside: Color = Color(0.3, 0.8, 1.0)
@export var color_outside: Color = Color(1.0, 0.4, 0.3)
@export var color_circle: Color = Color(0.8, 0.8, 0.8, 0.3)

# State
var _inside_count: int = 0
var _total_count: int = 0
var _throw_timer: float = 0.0

# Visuals
var _board: MeshInstance3D
var _circle_outline: MeshInstance3D
var _dart_container: Node3D
var _info_label: Label3D
var _pi_label: Label3D
var _control_panel: Node3D

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")
const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")

func _ready():
	_create_board()
	_create_circle()
	_create_dart_container()
	_create_labels()
	_create_vr_controls()

func _create_board():
	_board = MeshInstance3D.new()
	_board.name = "Board"
	var box = BoxMesh.new()
	box.size = Vector3(board_size, 0.02, board_size)
	_board.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.08, 0.1)
	_board.material_override = mat
	_board.position = Vector3(0, -0.01, 0)
	add_child(_board)
	
	# Grid lines
	var line_mat = StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.2, 0.2, 0.25)
	
	for i in range(-5, 6):
		var t = float(i) / 5.0 * board_size / 2
		
		# Horizontal
		var h_line = MeshInstance3D.new()
		var h_mesh = BoxMesh.new()
		h_mesh.size = Vector3(board_size, 0.002, 0.002)
		h_line.mesh = h_mesh
		h_line.material_override = line_mat
		h_line.position = Vector3(0, 0.005, t)
		add_child(h_line)
		
		# Vertical
		var v_line = MeshInstance3D.new()
		var v_mesh = BoxMesh.new()
		v_mesh.size = Vector3(0.002, 0.002, board_size)
		v_line.mesh = v_mesh
		v_line.material_override = line_mat
		v_line.position = Vector3(t, 0.005, 0)
		add_child(v_line)

func _create_circle():
	_circle_outline = MeshInstance3D.new()
	_circle_outline.name = "CircleOutline"
	
	# Create circle using torus
	var torus = TorusMesh.new()
	torus.inner_radius = board_size / 2 - 0.005
	torus.outer_radius = board_size / 2 + 0.005
	_circle_outline.mesh = torus
	_circle_outline.rotation_degrees.x = 90
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_circle
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_circle_outline.material_override = mat
	_circle_outline.position = Vector3(0, 0.008, 0)
	add_child(_circle_outline)
	
	# Filled circle (very thin cylinder)
	var circle_fill = MeshInstance3D.new()
	circle_fill.name = "CircleFill"
	var cyl = CylinderMesh.new()
	cyl.top_radius = board_size / 2
	cyl.bottom_radius = board_size / 2
	cyl.height = 0.001
	circle_fill.mesh = cyl
	
	var fill_mat = StandardMaterial3D.new()
	fill_mat.albedo_color = Color(0.2, 0.3, 0.4, 0.2)
	fill_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	circle_fill.material_override = fill_mat
	circle_fill.position = Vector3(0, 0.003, 0)
	add_child(circle_fill)

func _create_dart_container():
	_dart_container = Node3D.new()
	_dart_container.name = "Darts"
	add_child(_dart_container)

func _create_labels():
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

func _create_vr_controls():
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, -0.05, board_size/2 + 0.15)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)
	
	# Panel
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

func _add_button_label(btn: Node, text: String):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.0008
	lbl.font_size = 7
	lbl.position = Vector3(0, -0.02, 0)
	btn.add_child(lbl)

func _process(delta):
	if auto_throw and _total_count < max_darts:
		_throw_timer += delta
		var interval = 1.0 / darts_per_second
		while _throw_timer >= interval and _total_count < max_darts:
			_throw_timer -= interval
			_throw_dart()

func _throw_dart():
	if _total_count >= max_darts:
		return
	
	# Random point in square [-1, 1] × [-1, 1]
	var x = randf() * 2.0 - 1.0
	var z = randf() * 2.0 - 1.0
	
	# Check if inside unit circle
	var inside = (x * x + z * z) <= 1.0
	
	if inside:
		_inside_count += 1
	_total_count += 1
	
	# Create dart visual
	var dart = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.006
	sphere.height = 0.012
	dart.mesh = sphere
	
	var color = color_inside if inside else color_outside
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.3
	dart.material_override = mat
	
	dart.position = Vector3(x * board_size/2, 0.01, z * board_size/2)
	_dart_container.add_child(dart)
	
	_update_pi_display()

func _clear_darts():
	for child in _dart_container.get_children():
		child.queue_free()
	_inside_count = 0
	_total_count = 0
	_update_pi_display()

func _update_pi_display():
	if _total_count == 0:
		_pi_label.text = "π ≈ ?"
		return
	
	var pi_estimate = 4.0 * float(_inside_count) / float(_total_count)
	var error = abs(pi_estimate - PI)
	
	_pi_label.text = "π ≈ %.6f\n(%d/%d)" % [pi_estimate, _inside_count, _total_count]
	
	# Color by accuracy
	if error < 0.01:
		_pi_label.modulate = Color(0.3, 1.0, 0.4)
	elif error < 0.1:
		_pi_label.modulate = Color(1.0, 0.8, 0.3)
	else:
		_pi_label.modulate = Color(1.0, 0.5, 0.3)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE: _throw_dart()
			KEY_C: _clear_darts()
			KEY_T: for i in 10: _throw_dart()
			KEY_H: for i in 100: _throw_dart()

func throw():
	_throw_dart()

func clear():
	_clear_darts()

func get_estimate() -> float:
	if _total_count == 0:
		return 0.0
	return 4.0 * float(_inside_count) / float(_total_count)