extends Node3D
class_name SnapPointPuzzleBase

## Base class for snap point puzzles
## Provides common functionality and tag-based obstacle/reward system
## Similar to LineSnapPuzzleBase

enum PuzzleState {
	BUILDING,     # Player is connecting points
	VALIDATING,   # Checking if shape is complete
	LOCKED,       # Shape validated, points frozen
	COMPLETED     # Puzzle solved, rewards given
}

## Tag System (like LineSnapPuzzleBase)
@export_group("Tag System")
@export var trigger_tag: String = ""  # Tag to trigger on puzzle completion
@export var trigger_action: String = "shrink_and_remove"  # Action to execute (reveal, remove, hide, etc.)
@export var auto_hide_tagged: bool = false  # Automatically hide tagged objects on map start

## Visual Feedback
@export_group("Visual Feedback")
@export var locked_material: Material  # Material to apply when points are locked
@export var show_success_message: bool = true
@export var success_message: String = "Puzzle complete!"
@export var success_display_duration: float = 3.0

## Legacy Spawn System (optional, for backward compatibility)
@export_group("Legacy Spawn System")
@export var enable_spawn: bool = false  # Enable legacy spawn behavior
@export var spawn_scene_path: String = ""  # What to spawn on completion
@export var spawn_position: Vector3 = Vector3(0, 0, 1)  # Where object appears
@export var spawn_scale: float = 0.5  # Size multiplier for spawned object
@export var spawn_rotation: Vector3 = Vector3(0, 0, 0)  # Orientation (euler angles)

## Internal state
var current_state: PuzzleState = PuzzleState.BUILDING
var snap_points: Array[Node3D] = []
var connection_manager: SnapConnectionManager
var success_label: Label3D
var spawned_object: Node3D

## Signals
signal puzzle_solved
signal object_spawned(obj: Node3D)

@onready var logic_display = get_node_or_null("CategoryLogicDisplay")

func _ready() -> void:
	_find_snap_points()
	_setup_success_label()
	_find_connection_manager()
	_connect_signals()  # Implemented by child classes
	
	# Auto-hide tagged objects if enabled OR if action is "reveal"
	# reveal → things should start hidden
	# remove/shrink_and_remove → things should start visible
	var should_auto_hide = auto_hide_tagged or (trigger_action == "reveal")
	
	if should_auto_hide and trigger_tag != "":
		# Wait a frame to ensure tagged objects are registered
		await get_tree().process_frame
		await get_tree().process_frame
		TagSystem.trigger_tag_action(trigger_tag, "hide")
		print("%s: Auto-hid objects with tag '%s' (action=%s)" % [get_class(), trigger_tag, trigger_action])

## Find all snap points as children
func _find_snap_points() -> void:
	for child in get_children():
		if child is XRToolsPickable and child.has_signal("snap_completed"):
			snap_points.append(child)
	
	print("%s: Found %d snap points" % [get_class(), snap_points.size()])

## Create success label if enabled
func _setup_success_label() -> void:
	if not show_success_message:
		return
	
	success_label = Label3D.new()
	success_label.name = "SuccessLabel"
	success_label.text = success_message
	success_label.font_size = 32
	success_label.outline_size = 8
	success_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	success_label.modulate = Color(0.2, 1.0, 0.3, 1.0)  # Bright green
	success_label.visible = false
	add_child(success_label)

## Find the SnapConnectionManager
func _find_connection_manager() -> void:
	connection_manager = get_node_or_null("SnapConnectionManager")
	if not connection_manager:
		# Try to find it in the scene tree
		connection_manager = _find_connection_manager_recursive(get_tree().root)
	
	if connection_manager:
		print("%s: Connected to SnapConnectionManager" % get_class())
	else:
		push_error("%s: Could not find SnapConnectionManager!" % get_class())

func _find_connection_manager_recursive(node: Node) -> SnapConnectionManager:
	if node is SnapConnectionManager:
		return node
	for child in node.get_children():
		var result = _find_connection_manager_recursive(child)
		if result:
			return result
	return null

## Abstract method - must be implemented by child classes
## Connect to appropriate shape formation signals
func _connect_signals() -> void:
	push_error("%s: _connect_signals() not implemented!" % get_class())

## Complete the puzzle - centralized logic
func _complete_puzzle() -> void:
	if current_state == PuzzleState.COMPLETED:
		return
	
	current_state = PuzzleState.VALIDATING
	
	# Lock snap points
	_lock_points()
	
	current_state = PuzzleState.LOCKED
	
	print("%s: Puzzle completed!" % get_class())
	
	# Play completion sound
	_play_completion_sound()
	
	# Wait before executing actions
	await get_tree().create_timer(1.0).timeout
	
	# Tag system (like LineSnapPuzzleBase)
	if trigger_tag != "":
		var action = trigger_action if trigger_action != "" else "shrink_and_remove"
		print("%s: Triggering tag action: %s -> %s" % [get_class(), trigger_tag, action])
		TagSystem.trigger_tag_action(trigger_tag, action)
	
	# Show success message
	if success_label:
		success_label.visible = true
		success_label.global_position = global_position + Vector3(0, 0.3, 0)
		await get_tree().create_timer(success_display_duration).timeout
		if success_label:
			success_label.visible = false
	
	# Legacy spawn behavior (if enabled)
	if enable_spawn and spawn_scene_path != "":
		_spawn_object()
	
	# Mark as completed
	current_state = PuzzleState.COMPLETED
	
	# Hide puzzle after delay
	await get_tree().create_timer(1.0).timeout
	_hide_puzzle()
	
	# Emit signals
	puzzle_solved.emit()

## Lock all snap points
func _lock_points() -> void:
	for point in snap_points:
		if point is RigidBody3D:
			point.freeze = true
		
		# Apply locked material if provided
		if locked_material and point.has_node("MeshInstance3D"):
			var mesh_instance = point.get_node("MeshInstance3D")
			if mesh_instance is MeshInstance3D:
				mesh_instance.material_override = locked_material

## Play completion sound
func _play_completion_sound() -> void:
	if not has_node("/root/SoundBank"):
		print("%s: SoundBank not found, skipping completion sound" % get_class())
		return
	
	var sound_bank = get_node("/root/SoundBank")
	var sound_stream = sound_bank.get_sound("AudioSynthesizer.POWER_UP_JINGLE")
	
	if not sound_stream:
		print("%s: Could not get completion sound" % get_class())
		return
	
	var player = AudioStreamPlayer3D.new()
	player.name = "CompletionSoundPlayer"
	player.stream = sound_stream
	player.volume_db = 0.0
	player.max_distance = 20.0
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC
	player.global_position = global_position
	add_child(player)
	
	player.finished.connect(player.queue_free)
	player.play()
	print("%s: Playing completion sound" % get_class())

## Hide/remove all snap points and their visual connections
func _hide_puzzle() -> void:
	for point in snap_points:
		if is_instance_valid(point):
			point.visible = false
			if point is RigidBody3D:
				point.freeze = true
			print("%s: Hidden snap point %s" % [get_class(), point.name])
	
	# Hide any lines/triangles that were created
	_hide_visual_connections()
	
	if logic_display:
		logic_display.visible = false
	
	print("%s: Puzzle hidden" % get_class())

## Hide lines and triangles connected to our snap points
func _hide_visual_connections() -> void:
	var scene_root = get_tree().current_scene
	if not scene_root:
		scene_root = get_tree().root
	
	_hide_connections_recursive(scene_root)

func _hide_connections_recursive(node: Node) -> void:
	# Check if this is a SnapLine or SnapTriangle connected to our points
	if node.has_method("set_endpoints") or node.has_method("setup"):
		# Try to get the points this shape uses
		if "point_a" in node and "point_b" in node:
			# It's a line
			if node.point_a in snap_points or node.point_b in snap_points:
				node.visible = false
		elif "point_a" in node and "point_b" in node and "point_c" in node:
			# It's a triangle
			if node.point_a in snap_points or node.point_b in snap_points or node.point_c in snap_points:
				node.visible = false
	
	# Recurse through children
	for child in node.get_children():
		_hide_connections_recursive(child)

## Legacy spawn object method (for backward compatibility)
func _spawn_object() -> void:
	if current_state == PuzzleState.COMPLETED:
		return
	
	# Load the scene
	var object_scene = load(spawn_scene_path)
	if not object_scene:
		push_error("%s: Could not load scene: %s" % [get_class(), spawn_scene_path])
		return
	
	# Instantiate the object
	spawned_object = object_scene.instantiate()
	spawned_object.name = "SpawnedFromPuzzle"
	
	# Find GridScene node to add the object to
	var grid_scene = _find_grid_scene()
	if not grid_scene:
		push_error("%s: Could not find GridScene node to spawn object in" % get_class())
		return
	
	# Add to GridScene first (must be in tree before setting global_position)
	grid_scene.add_child(spawned_object)
	
	# Calculate world position (relative to this puzzle)
	var world_spawn_pos = global_position + spawn_position
	spawned_object.global_position = world_spawn_pos
	
	# Apply rotation
	spawned_object.rotation_degrees = spawn_rotation
	
	# Apply scale
	spawned_object.scale = Vector3.ONE * spawn_scale
	
	# Emit signal
	object_spawned.emit(spawned_object)
	
	print("%s: Spawned object at %v" % [get_class(), world_spawn_pos])

## Find the GridScene node to spawn objects in
func _find_grid_scene() -> Node:
	# Search up the parent chain
	var current = self
	while current:
		if current.name == "GridScene":
			return current
		current = current.get_parent()
	
	# Search the entire scene tree
	var root = get_tree().current_scene
	if not root:
		root = get_tree().root
	
	return _find_grid_scene_recursive(root)

func _find_grid_scene_recursive(node: Node) -> Node:
	if node.name == "GridScene":
		return node
	for child in node.get_children():
		var result = _find_grid_scene_recursive(child)
		if result:
			return result
	return null
