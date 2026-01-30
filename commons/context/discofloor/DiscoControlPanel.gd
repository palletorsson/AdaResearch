# DiscoControlPanel.gd
# VR-friendly control panel for the StandaloneDiscoFloor
# Provides buttons to change patterns and control playback

extends Node3D
class_name DiscoControlPanel

## Configuration
@export var disco_floor_path: NodePath
@export var button_size: float = 0.12
@export var button_spacing: float = 0.14
@export var panel_color: Color = Color(0.1, 0.1, 0.15, 0.9)

## References
var disco_floor: StandaloneDiscoFloor
var pattern_buttons: Array[Node3D] = []
var control_buttons: Dictionary = {}
var current_label: Label3D
var status_label: Label3D

func _ready() -> void:
	# Find disco floor
	if disco_floor_path:
		disco_floor = get_node_or_null(disco_floor_path)
	if not disco_floor:
		disco_floor = _find_disco_floor()
	
	if not disco_floor:
		push_error("DiscoControlPanel: No StandaloneDiscoFloor found!")
		return
	
	_create_panel()
	_connect_signals()
	print("DiscoControlPanel: Ready, connected to disco floor")

func _find_disco_floor() -> StandaloneDiscoFloor:
	# Search siblings first
	var parent = get_parent()
	for child in parent.get_children():
		if child is StandaloneDiscoFloor:
			return child
	# Search scene
	return _find_in_tree(get_tree().current_scene)

func _find_in_tree(node: Node) -> StandaloneDiscoFloor:
	if node is StandaloneDiscoFloor:
		return node
	for child in node.get_children():
		var result = _find_in_tree(child)
		if result:
			return result
	return null

func _create_panel() -> void:
	# Create panel background
	var panel_mesh = MeshInstance3D.new()
	panel_mesh.name = "PanelBackground"
	var box = BoxMesh.new()
	box.size = Vector3(0.8, 0.5, 0.02)
	panel_mesh.mesh = box
	panel_mesh.position = Vector3(0, 0.25, -0.01)
	
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = panel_color
	panel_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	panel_mesh.material_override = panel_mat
	add_child(panel_mesh)
	
	# Title
	var title = Label3D.new()
	title.text = "🕺 DISCO CONTROL"
	title.font_size = 48
	title.position = Vector3(0, 0.45, 0.02)
	title.modulate = Color.WHITE
	title.outline_size = 8
	add_child(title)
	
	# Current pattern label
	current_label = Label3D.new()
	current_label.text = "Pattern: " + disco_floor.get_current_pattern_name()
	current_label.font_size = 32
	current_label.position = Vector3(0, 0.35, 0.02)
	current_label.modulate = Color.CYAN
	add_child(current_label)
	
	# Status label
	status_label = Label3D.new()
	status_label.text = "▶ Playing"
	status_label.font_size = 24
	status_label.position = Vector3(0, 0.28, 0.02)
	status_label.modulate = Color.LIME
	add_child(status_label)
	
	# Create control buttons (top row)
	_create_control_button("⏮", Vector3(-0.25, 0.18, 0.02), "prev", Color.ORANGE)
	_create_control_button("⏯", Vector3(0, 0.18, 0.02), "toggle", Color.LIME)
	_create_control_button("⏭", Vector3(0.25, 0.18, 0.02), "next", Color.ORANGE)
	
	# Create pattern buttons (grid below)
	var patterns = disco_floor.get_all_pattern_names()
	var cols = 5
	var start_x = -0.3
	var start_y = 0.05
	
	for i in range(patterns.size()):
		var row = i / cols
		var col = i % cols
		var pos = Vector3(
			start_x + col * button_spacing,
			start_y - row * button_spacing,
			0.02
		)
		_create_pattern_button(patterns[i], pos, i)

func _create_control_button(icon: String, pos: Vector3, action: String, color: Color) -> void:
	var button = _create_button_base(pos, color)
	button.name = "Control_" + action
	
	var label = Label3D.new()
	label.text = icon
	label.font_size = 48
	label.position = Vector3(0, 0, 0.01)
	button.add_child(label)
	
	# Add interaction area
	var area = _create_button_area(button)
	area.input_event.connect(_on_control_button_pressed.bind(action))
	
	control_buttons[action] = button
	add_child(button)

func _create_pattern_button(pattern_name: String, pos: Vector3, index: int) -> void:
	# Use first 2 chars as abbreviation
	var abbrev = pattern_name.left(2).to_upper()
	var color = Color.from_hsv(float(index) / 10.0, 0.5, 0.8)
	
	var button = _create_button_base(pos, color, button_size * 0.8)
	button.name = "Pattern_" + str(index)
	
	var label = Label3D.new()
	label.text = abbrev
	label.font_size = 24
	label.position = Vector3(0, 0, 0.01)
	button.add_child(label)
	
	var area = _create_button_area(button)
	area.input_event.connect(_on_pattern_button_pressed.bind(index))
	
	pattern_buttons.append(button)
	add_child(button)

func _create_button_base(pos: Vector3, color: Color, size: float = button_size) -> Node3D:
	var button = Node3D.new()
	button.position = pos
	
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(size, size, 0.02)
	mesh.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.3
	mesh.material_override = mat
	
	button.add_child(mesh)
	return button

func _create_button_area(button: Node3D) -> Area3D:
	var area = Area3D.new()
	area.name = "ClickArea"
	
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(button_size, button_size, 0.05)
	collision.shape = shape
	
	area.add_child(collision)
	button.add_child(area)
	
	# Enable input
	area.input_ray_pickable = true
	area.monitoring = true
	
	return area

func _connect_signals() -> void:
	disco_floor.pattern_changed.connect(_on_pattern_changed)
	disco_floor.disco_toggled.connect(_on_disco_toggled)

func _on_control_button_pressed(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int, action: String) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.pressed:
		return
	
	match action:
		"prev":
			disco_floor.previous_pattern()
		"next":
			disco_floor.next_pattern()
		"toggle":
			disco_floor.toggle_disco()
	
	# Visual feedback
	_flash_button(control_buttons.get(action))

func _on_pattern_button_pressed(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int, index: int) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.pressed:
		return
	
	disco_floor.set_pattern(index)
	
	if index < pattern_buttons.size():
		_flash_button(pattern_buttons[index])

func _flash_button(button: Node3D) -> void:
	if not button:
		return
	var mesh = button.get_node_or_null("MeshInstance3D")
	if mesh and mesh.material_override:
		var mat = mesh.material_override as StandardMaterial3D
		var original = mat.emission_energy_multiplier
		mat.emission_energy_multiplier = 2.0
		await get_tree().create_timer(0.1).timeout
		mat.emission_energy_multiplier = original

func _on_pattern_changed(pattern_name: String) -> void:
	current_label.text = "Pattern: " + pattern_name

func _on_disco_toggled(is_on: bool) -> void:
	if is_on:
		status_label.text = "▶ Playing"
		status_label.modulate = Color.LIME
	else:
		status_label.text = "⏸ Paused"
		status_label.modulate = Color.GRAY
