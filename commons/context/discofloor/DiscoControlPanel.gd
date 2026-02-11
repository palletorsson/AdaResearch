# DiscoControlPanel.gd
# VR-friendly control panel for the StandaloneDiscoFloor
# Uses rack audio system interactables (push buttons, sliders)

extends Node3D
class_name DiscoControlPanel

# Interactable scenes from rack audio system
const PUSH_BUTTON_SCENE = preload("res://commons/interactables/push_button.tscn")
const SLIDER_SCENE = preload("res://commons/interactables/slider_smooth.tscn")
const DIAL_SCENE = preload("res://commons/interactables/dial_smooth.tscn")

## Configuration
@export var disco_floor_path: NodePath
@export var button_size: float = 0.08
@export var button_spacing: float = 0.12
@export var panel_color: Color = Color(0.1, 0.1, 0.15, 0.9)

## References
var disco_floor: StandaloneDiscoFloor
var pattern_buttons: Array[Node3D] = []
var control_buttons: Dictionary = {}
var speed_slider: Node3D
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
	print("DiscoControlPanel: Ready, connected to disco floor (using rack interactables)")

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
	box.size = Vector3(0.9, 0.6, 0.03)
	panel_mesh.mesh = box
	panel_mesh.position = Vector3(0, 0.3, -0.015)
	
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = panel_color
	panel_mat.metallic = 0.3
	panel_mat.roughness = 0.7
	panel_mesh.material_override = panel_mat
	add_child(panel_mesh)
	
	# Title
	var title = Label3D.new()
	title.text = "🕺 DISCO CONTROL"
	title.font_size = 42
	title.position = Vector3(0, 0.52, 0.02)
	title.modulate = Color.WHITE
	title.outline_size = 6
	add_child(title)
	
	# Current pattern label
	current_label = Label3D.new()
	current_label.text = "Pattern: " + disco_floor.get_current_pattern_name()
	current_label.font_size = 28
	current_label.position = Vector3(0, 0.43, 0.02)
	current_label.modulate = Color.CYAN
	add_child(current_label)
	
	# Status label
	status_label = Label3D.new()
	status_label.text = "▶ Playing"
	status_label.font_size = 22
	status_label.position = Vector3(0, 0.36, 0.02)
	status_label.modulate = Color.LIME
	add_child(status_label)
	
	# Create control buttons (using rack interactables)
	_create_rack_button("⏮", Vector3(-0.28, 0.24, 0.02), "prev", Color.ORANGE)
	_create_rack_button("⏯", Vector3(0, 0.24, 0.02), "toggle", Color.LIME)
	_create_rack_button("⏭", Vector3(0.28, 0.24, 0.02), "next", Color.ORANGE)
	
	# Speed slider
	_create_speed_slider(Vector3(0.35, 0.42, 0.02))
	
	# Create pattern buttons (grid below)
	var patterns = disco_floor.get_all_pattern_names()
	var cols = 5
	var start_x = -0.32
	var start_y = 0.12
	
	for i in range(patterns.size()):
		var row = i / cols
		var col = i % cols
		var pos = Vector3(
			start_x + col * button_spacing,
			start_y - row * button_spacing,
			0.02
		)
		_create_pattern_button(patterns[i], pos, i)

func _create_rack_button(icon: String, pos: Vector3, action: String, color: Color) -> void:
	"""Create a button using the rack audio system's push_button scene"""
	var button = PUSH_BUTTON_SCENE.instantiate()
	button.name = "Control_" + action
	button.position = pos
	button.scale = Vector3(0.8, 0.8, 0.8)
	
	# Set button color if possible
	if "button_color" in button:
		button.button_color = color
	
	# Add label above button
	var label = Label3D.new()
	label.text = icon
	label.font_size = 36
	label.position = Vector3(0, 0.06, 0)
	label.outline_size = 4
	button.add_child(label)
	
	# Connect signal
	if button.has_signal("button_pressed"):
		button.button_pressed.connect(_on_rack_button_pressed.bind(action))
	elif button.has_signal("pressed"):
		button.pressed.connect(_on_rack_button_pressed.bind(action))
	else:
		# Fallback: find InteractableAreaButton child
		var area_btn = button.get_node_or_null("InteractableAreaButton")
		if area_btn and area_btn.has_signal("button_pressed"):
			area_btn.button_pressed.connect(_on_rack_button_pressed.bind(action))
	
	control_buttons[action] = button
	add_child(button)

func _create_speed_slider(pos: Vector3) -> void:
	"""Create a speed control slider using rack audio system"""
	speed_slider = SLIDER_SCENE.instantiate()
	speed_slider.name = "SpeedSlider"
	speed_slider.position = pos
	speed_slider.scale = Vector3(0.6, 0.6, 0.6)
	speed_slider.rotation_degrees.z = 90  # Horizontal orientation
	
	# Add label
	var label = Label3D.new()
	label.text = "SPEED"
	label.font_size = 18
	label.position = Vector3(0.12, 0, 0)
	speed_slider.add_child(label)
	
	# Connect signal
	if speed_slider.has_signal("slider_moved"):
		speed_slider.slider_moved.connect(_on_speed_slider_moved)
	elif speed_slider.has_signal("value_changed"):
		speed_slider.value_changed.connect(_on_speed_slider_moved)
	
	add_child(speed_slider)

func _create_pattern_button(pattern_name: String, pos: Vector3, index: int) -> void:
	"""Create a pattern selection button using rack interactables"""
	var abbrev = pattern_name.left(2).to_upper()
	var hue = float(index) / disco_floor.get_pattern_count()
	var color = Color.from_hsv(hue, 0.6, 0.9)
	
	var button = PUSH_BUTTON_SCENE.instantiate()
	button.name = "Pattern_" + str(index)
	button.position = pos
	button.scale = Vector3(0.65, 0.65, 0.65)
	
	# Add abbreviation label
	var label = Label3D.new()
	label.text = abbrev
	label.font_size = 20
	label.position = Vector3(0, 0.04, 0)
	label.modulate = color
	label.outline_size = 3
	button.add_child(label)
	
	# Connect signal
	if button.has_signal("button_pressed"):
		button.button_pressed.connect(_on_pattern_button_pressed.bind(index))
	elif button.has_signal("pressed"):
		button.pressed.connect(_on_pattern_button_pressed.bind(index))
	else:
		var area_btn = button.get_node_or_null("InteractableAreaButton")
		if area_btn and area_btn.has_signal("button_pressed"):
			area_btn.button_pressed.connect(_on_pattern_button_pressed.bind(index))
	
	pattern_buttons.append(button)
	add_child(button)

func _connect_signals() -> void:
	disco_floor.pattern_changed.connect(_on_pattern_changed)
	disco_floor.disco_toggled.connect(_on_disco_toggled)

func _on_rack_button_pressed(action: String) -> void:
	print("DiscoControlPanel: Button pressed - %s" % action)
	match action:
		"prev":
			disco_floor.previous_pattern()
		"next":
			disco_floor.next_pattern()
		"toggle":
			disco_floor.toggle_disco()

func _on_pattern_button_pressed(index: int) -> void:
	print("DiscoControlPanel: Pattern button pressed - %d" % index)
	disco_floor.set_pattern(index)

func _on_speed_slider_moved(value: float) -> void:
	# Map slider 0-1 to speed 0.02-0.2
	var speed = lerp(0.02, 0.2, 1.0 - value)  # Inverted: high slider = fast
	disco_floor.set_speed(speed)
	print("DiscoControlPanel: Speed set to %.3f" % speed)

func _on_pattern_changed(pattern_name: String) -> void:
	current_label.text = "Pattern: " + pattern_name

func _on_disco_toggled(is_on: bool) -> void:
	if is_on:
		status_label.text = "▶ Playing"
		status_label.modulate = Color.LIME
	else:
		status_label.text = "⏸ Paused"
		status_label.modulate = Color.GRAY
