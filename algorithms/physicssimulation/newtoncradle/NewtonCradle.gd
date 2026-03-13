# ===========================================================================
# NewtonCradle.gd - Newton's Cradle Demonstration
# 5 pendulum balls on strings — pull one back, release, watch momentum transfer
# Shows conservation of momentum + energy, elastic collisions, F=ma
#
# QFEP: Momentum as conserved quantity — what enters must exit.
# ===========================================================================
extends Node3D

class_name NewtonCradle

## Cradle parameters
@export var ball_count: int = 5
@export var ball_radius: float = 0.12
@export var string_length: float = 0.6
@export var ball_mass: float = 1.0

## Physics
@export var gravity: float = 9.8
@export var damping: float = 0.998  # Very slight energy loss

## Colors
@export var frame_color: Color = Color(0.3, 0.3, 0.35)
@export var ball_color: Color = Color(0.85, 0.85, 0.9)
@export var string_color: Color = Color(0.5, 0.5, 0.55, 0.8)

# State per ball: angle from vertical, angular velocity
var _angles: Array[float] = []
var _angular_velocities: Array[float] = []

# Visuals
var _balls: Array[MeshInstance3D] = []
var _strings: Array[MeshInstance3D] = []
var _pivot_y: float = 0.0
var _info_label: Label3D
var _control_panel: Node3D

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")
const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")

func _ready() -> void:
	_pivot_y = string_length + ball_radius + 0.1
	_create_frame()
	_create_balls()
	_create_labels()
	_create_vr_controls()
	_release_left(1)  # Start with 1 ball pulled back

func _create_frame() -> void:
	# Top bar
	var bar := MeshInstance3D.new()
	bar.name = "TopBar"
	var box := BoxMesh.new()
	var total_width: float = (ball_count - 1) * ball_radius * 2.0 + ball_radius * 2.0 + 0.1
	box.size = Vector3(total_width + 0.15, 0.03, 0.03)
	bar.mesh = box
	bar.position = Vector3(0, _pivot_y, 0)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = frame_color
	mat.metallic = 0.7
	mat.roughness = 0.3
	bar.material_override = mat
	add_child(bar)

	# Two vertical supports
	for side in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		post.name = "Post"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.015
		cyl.bottom_radius = 0.015
		cyl.height = _pivot_y + 0.05
		post.mesh = cyl
		post.material_override = mat
		post.position = Vector3(side * (total_width / 2.0 + 0.05), _pivot_y / 2.0 - 0.025, 0)
		add_child(post)

	# Base plate
	var base := MeshInstance3D.new()
	base.name = "Base"
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(total_width + 0.3, 0.02, 0.2)
	base.mesh = base_mesh
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.15, 0.15, 0.18)
	base_mat.metallic = 0.5
	base.material_override = base_mat
	base.position = Vector3(0, -0.01, 0)
	add_child(base)

func _create_balls() -> void:
	var spacing := ball_radius * 2.0
	var start_x := -(ball_count - 1) * spacing / 2.0

	for i in range(ball_count):
		# Init physics state
		_angles.append(0.0)
		_angular_velocities.append(0.0)

		var x := start_x + i * spacing

		# String
		var string_mesh := MeshInstance3D.new()
		string_mesh.name = "String_%d" % i
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.003
		cyl.bottom_radius = 0.003
		cyl.height = string_length
		string_mesh.mesh = cyl

		var str_mat := StandardMaterial3D.new()
		str_mat.albedo_color = string_color
		str_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		string_mesh.material_override = str_mat
		add_child(string_mesh)
		_strings.append(string_mesh)

		# Ball
		var ball := MeshInstance3D.new()
		ball.name = "Ball_%d" % i
		var sphere := SphereMesh.new()
		sphere.radius = ball_radius
		sphere.height = ball_radius * 2.0
		ball.mesh = sphere

		var mat := StandardMaterial3D.new()
		mat.albedo_color = ball_color
		mat.metallic = 0.8
		mat.roughness = 0.15
		mat.emission_enabled = true
		mat.emission = ball_color * 0.1
		mat.emission_energy_multiplier = 0.5
		ball.material_override = mat
		add_child(ball)
		_balls.append(ball)

	_update_ball_positions()

func _update_ball_positions() -> void:
	var spacing := ball_radius * 2.0
	var start_x := -(ball_count - 1) * spacing / 2.0

	for i in range(ball_count):
		var base_x := start_x + i * spacing
		var angle := _angles[i]

		# Ball position: pendulum swing from pivot
		var ball_x := base_x + sin(angle) * string_length
		var ball_y := _pivot_y - cos(angle) * string_length
		_balls[i].position = Vector3(ball_x, ball_y, 0)

		# String: connect pivot to ball
		var pivot_pos := Vector3(base_x, _pivot_y, 0)
		var ball_pos := _balls[i].position
		var midpoint := (pivot_pos + ball_pos) / 2.0
		_strings[i].position = midpoint

		# Orient string
		_strings[i].transform.basis = Basis.IDENTITY
		var dir := (ball_pos - pivot_pos).normalized()
		if dir.length() > 0.001:
			var up := Vector3.FORWARD if abs(dir.dot(Vector3.FORWARD)) < 0.99 else Vector3.RIGHT
			_strings[i].look_at(_strings[i].global_position + dir, up)
			_strings[i].rotate_object_local(Vector3.RIGHT, PI / 2.0)

func _physics_process(delta: float) -> void:
	# Pendulum physics for each ball
	for i in range(ball_count):
		# Angular acceleration from gravity: alpha = -(g/L) * sin(theta)
		var alpha := -(gravity / string_length) * sin(_angles[i])
		_angular_velocities[i] += alpha * delta
		_angular_velocities[i] *= damping
		_angles[i] += _angular_velocities[i] * delta

	# Collision detection: adjacent balls transfer momentum on contact
	for i in range(ball_count - 1):
		var angle_diff := _angles[i + 1] - _angles[i]
		# Balls are touching when angle difference is small enough
		# At rest, they're all at angle=0 and touching.
		# A collision happens when left ball catches up to right ball
		var spacing_angle := ball_radius * 2.0 / string_length  # angular size of one ball diameter
		if angle_diff < spacing_angle * 0.1 and _angular_velocities[i] > _angular_velocities[i + 1]:
			# Elastic collision: swap velocities (equal mass)
			var temp := _angular_velocities[i]
			_angular_velocities[i] = _angular_velocities[i + 1]
			_angular_velocities[i + 1] = temp

	_update_ball_positions()
	_update_info()

func _release_left(count: int = 1) -> void:
	_reset_all()
	count = clampi(count, 1, ball_count - 1)
	for i in range(count):
		_angles[i] = -0.8  # Pull left ball(s) back ~45 degrees

func _release_right(count: int = 1) -> void:
	_reset_all()
	count = clampi(count, 1, ball_count - 1)
	for i in range(ball_count - count, ball_count):
		_angles[i] = 0.8

func _release_both() -> void:
	_reset_all()
	_angles[0] = -0.8
	_angles[ball_count - 1] = 0.8

func _reset_all() -> void:
	for i in range(ball_count):
		_angles[i] = 0.0
		_angular_velocities[i] = 0.0

func _create_labels() -> void:
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 14
	_info_label.position = Vector3(0, _pivot_y + 0.12, 0)
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.text = "NEWTON'S CRADLE"
	add_child(_info_label)

func _create_vr_controls() -> void:
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, -0.05, 0.35)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)

	# Panel backing
	var panel_back := MeshInstance3D.new()
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(0.45, 0.12, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat := StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.01
	_control_panel.add_child(panel_back)

	# Preset buttons
	var presets = ["1 BALL", "2 BALLS", "BOTH", "RESET"]
	for i in range(presets.size()):
		var btn = PUSH_BUTTON.instantiate()
		btn.name = "Preset%d" % i
		btn.position = Vector3(-0.12 + i * 0.08, 0.025, 0)
		btn.scale = Vector3(0.65, 0.65, 0.65)
		_control_panel.add_child(btn)
		_add_button_label(btn, presets[i])

		var idx := i
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b):
				match idx:
					0: _release_left(1)
					1: _release_left(2)
					2: _release_both()
					3: _reset_all()
			)

func _add_button_label(btn: Node, text: String) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.0008
	lbl.font_size = 6
	lbl.position = Vector3(0, -0.02, 0)
	btn.add_child(lbl)

func _update_info() -> void:
	var total_ke := 0.0
	var total_pe := 0.0
	for i in range(ball_count):
		var v := _angular_velocities[i] * string_length
		total_ke += 0.5 * ball_mass * v * v
		var h := string_length * (1.0 - cos(_angles[i]))
		total_pe += ball_mass * gravity * h
	_info_label.text = "NEWTON'S CRADLE\nKE=%.3f  PE=%.3f  Total=%.3f" % [total_ke, total_pe, total_ke + total_pe]

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _release_left(1)
			KEY_2: _release_left(2)
			KEY_3: _release_both()
			KEY_R: _reset_all()

func reset() -> void:
	_reset_all()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

