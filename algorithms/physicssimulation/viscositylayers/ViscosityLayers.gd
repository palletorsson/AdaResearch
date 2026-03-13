# ===========================================================================
# ViscosityLayers.gd - Three Fluid Columns Comparison
# Drop identical balls into air / water / honey — watch descent speed differ
# Shows drag, viscosity, terminal velocity side by side
#
# QFEP: Resistance as information — the medium tells you what it's made of.
# ===========================================================================
extends Node3D

class_name ViscosityLayers

## Column parameters
@export var column_height: float = 1.2
@export var column_width: float = 0.25
@export var ball_radius: float = 0.03

## Fluid properties: [name, color, drag_coefficient, density_label]
var fluids := [
	["AIR", Color(0.9, 0.95, 1.0, 0.05), 0.02],
	["WATER", Color(0.2, 0.5, 0.9, 0.25), 0.35],
	["HONEY", Color(0.9, 0.7, 0.2, 0.4), 2.5],
]

## Physics
@export var gravity_strength: float = 9.8
@export var ball_mass: float = 1.0

# State per ball: [position_y, velocity_y, active]
var _ball_states: Array = []  # Array of dictionaries
var _ball_meshes: Array[MeshInstance3D] = []
var _column_meshes: Array[MeshInstance3D] = []
var _speed_labels: Array[Label3D] = []
var _info_label: Label3D
var _control_panel: Node3D

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

func _ready() -> void:
	_create_columns()
	_create_balls()
	_create_labels()
	_create_vr_controls()

func _create_columns() -> void:
	var spacing := column_width * 1.8
	var start_x := -(fluids.size() - 1) * spacing / 2.0

	for i in range(fluids.size()):
		var x := start_x + i * spacing
		var fluid_data: Array = fluids[i]

		# Column tube (transparent box)
		var col := MeshInstance3D.new()
		col.name = "Column_%d" % i
		var box := BoxMesh.new()
		box.size = Vector3(column_width, column_height, column_width)
		col.mesh = box

		var mat := StandardMaterial3D.new()
		mat.albedo_color = fluid_data[1] as Color
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		col.material_override = mat
		col.position = Vector3(x, column_height / 2.0, 0)
		add_child(col)
		_column_meshes.append(col)

		# Fluid label at top
		var name_lbl := Label3D.new()
		name_lbl.text = fluid_data[0] as String
		name_lbl.pixel_size = 0.002
		name_lbl.font_size = 16
		name_lbl.outline_size = 2
		name_lbl.outline_modulate = Color.BLACK
		name_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		name_lbl.position = Vector3(x, column_height + 0.1, 0)
		add_child(name_lbl)

		# Speed readout
		var speed_lbl := Label3D.new()
		speed_lbl.name = "SpeedLabel_%d" % i
		speed_lbl.pixel_size = 0.0015
		speed_lbl.font_size = 12
		speed_lbl.outline_size = 2
		speed_lbl.outline_modulate = Color.BLACK
		speed_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		speed_lbl.position = Vector3(x + column_width / 2.0 + 0.06, column_height / 2.0, 0)
		speed_lbl.modulate = Color(0.3, 1.0, 0.4)
		add_child(speed_lbl)
		_speed_labels.append(speed_lbl)

	# Base plate
	var base := MeshInstance3D.new()
	base.name = "Base"
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(fluids.size() * spacing + 0.2, 0.02, column_width + 0.1)
	base.mesh = base_mesh
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.12, 0.12, 0.15)
	base_mat.metallic = 0.4
	base.material_override = base_mat
	base.position = Vector3(0, -0.01, 0)
	add_child(base)

func _create_balls() -> void:
	for i in range(fluids.size()):
		var ball := MeshInstance3D.new()
		ball.name = "Ball_%d" % i
		var sphere := SphereMesh.new()
		sphere.radius = ball_radius
		sphere.height = ball_radius * 2.0
		ball.mesh = sphere

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.4, 0.3)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.4, 0.3) * 0.5
		mat.emission_energy_multiplier = 1.5
		mat.metallic = 0.6
		mat.roughness = 0.3
		ball.material_override = mat
		ball.visible = false
		add_child(ball)
		_ball_meshes.append(ball)

		_ball_states.append({
			"y": column_height + ball_radius,
			"vy": 0.0,
			"active": false,
		})

func _drop_all() -> void:
	var spacing := column_width * 1.8
	var start_x := -(fluids.size() - 1) * spacing / 2.0

	for i in range(fluids.size()):
		_ball_states[i]["y"] = column_height - ball_radius
		_ball_states[i]["vy"] = 0.0
		_ball_states[i]["active"] = true
		_ball_meshes[i].visible = true
		_ball_meshes[i].position = Vector3(start_x + i * spacing, _ball_states[i]["y"], 0)

func _physics_process(delta: float) -> void:
	var spacing := column_width * 1.8
	var start_x := -(fluids.size() - 1) * spacing / 2.0

	for i in range(fluids.size()):
		var state: Dictionary = _ball_states[i]
		if not state["active"]:
			continue

		var drag_coeff: float = fluids[i][2] as float

		# Gravity pulls down
		var force_gravity := -gravity_strength * ball_mass

		# Drag opposes velocity: F_drag = -c * v * |v|  (quadratic drag)
		var vy: float = state["vy"]
		var force_drag: float = -drag_coeff * vy * absf(vy)

		# Net acceleration
		var accel: float = (force_gravity + force_drag) / ball_mass
		state["vy"] += accel * delta
		state["y"] += state["vy"] * delta

		# Floor collision
		if state["y"] <= ball_radius:
			state["y"] = ball_radius
			state["vy"] = 0.0
			state["active"] = false

		# Update visual
		var x := start_x + i * spacing
		_ball_meshes[i].position = Vector3(x, state["y"], 0)

		# Speed readout
		_speed_labels[i].text = "v=%.2f" % abs(state["vy"])

func _create_labels() -> void:
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 14
	_info_label.position = Vector3(0, column_height + 0.25, 0)
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.text = "VISCOSITY COMPARISON\nDrop balls to compare drag"
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
	panel_mesh.size = Vector3(0.3, 0.08, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat := StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.01
	_control_panel.add_child(panel_back)

	# Drop button
	var drop_btn = PUSH_BUTTON.instantiate()
	drop_btn.name = "DropBtn"
	drop_btn.position = Vector3(-0.06, 0, 0)
	drop_btn.scale = Vector3(0.7, 0.7, 0.7)
	_control_panel.add_child(drop_btn)
	_add_button_label(drop_btn, "DROP")
	var drop_area = drop_btn.get_node_or_null("InteractableAreaButton")
	if drop_area:
		drop_area.button_pressed.connect(func(_b): _drop_all())

	# Reset button
	var reset_btn = PUSH_BUTTON.instantiate()
	reset_btn.name = "ResetBtn"
	reset_btn.position = Vector3(0.06, 0, 0)
	reset_btn.scale = Vector3(0.7, 0.7, 0.7)
	_control_panel.add_child(reset_btn)
	_add_button_label(reset_btn, "RESET")
	var reset_area = reset_btn.get_node_or_null("InteractableAreaButton")
	if reset_area:
		reset_area.button_pressed.connect(func(_b): _reset())

func _add_button_label(btn: Node, text: String) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.0008
	lbl.font_size = 6
	lbl.position = Vector3(0, -0.02, 0)
	btn.add_child(lbl)

func _reset() -> void:
	for i in range(fluids.size()):
		_ball_states[i]["y"] = column_height + ball_radius
		_ball_states[i]["vy"] = 0.0
		_ball_states[i]["active"] = false
		_ball_meshes[i].visible = false
		_speed_labels[i].text = ""

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE: _drop_all()
			KEY_R: _reset()

func reset() -> void:
	_reset()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

