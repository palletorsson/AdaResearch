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
@export var show_success_message: bool = false
@export var success_message: String = "Puzzle complete!"
@export var success_display_duration: float = 3.0

## Reset Timer
@export_group("Reset Timer")
@export var enable_reset_timer: bool = true
@export var reset_time_seconds: float = 60.0  # Reset after 1 minute

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

## Reset timer state
var _elapsed_time: float = 0.0
var _progress_bar: MeshInstance3D
var _progress_material: ShaderMaterial
var _initial_positions: Dictionary = {}  # Store initial positions for reset

## Signals
signal puzzle_solved
signal puzzle_reset
signal object_spawned(obj: Node3D)

@onready var logic_display = get_node_or_null("CategoryLogicDisplay")

func _ready() -> void:
	_find_snap_points()
	_setup_success_label()
	_setup_progress_bar()
	_store_initial_positions()
	_find_connection_manager()
	_connect_signals()  # Implemented by child classes

	# Auto-hide tagged objects if enabled OR if action is "reveal"
	# reveal → things should start hidden
	# remove/shrink_and_remove → things should start visible
	var should_auto_hide = auto_hide_tagged or (trigger_action == "reveal")

	if should_auto_hide and trigger_tag != "":
		# Wait a frame to ensure tagged objects are registered
		await get_tree().process_frame
		# out-of-tree guard: get_tree() is null once a map is torn down
		if not is_inside_tree():
			await tree_entered
		await get_tree().process_frame
		TagSystem.trigger_tag_action(trigger_tag, "hide")
		print("%s: Auto-hid objects with tag '%s' (action=%s)" % [get_class(), trigger_tag, trigger_action])

func _process(delta: float) -> void:
	if not enable_reset_timer:
		return
	if current_state != PuzzleState.BUILDING:
		return

	# Update elapsed time
	_elapsed_time += delta

	# Update progress bar (shows time remaining)
	var progress = _elapsed_time / reset_time_seconds
	_update_progress_bar(1.0 - progress)  # Invert so bar depletes

	# Check for reset
	if _elapsed_time >= reset_time_seconds:
		_reset_puzzle()

## Find all snap points as children
func _find_snap_points() -> void:
	for child in get_children():
		if child is XRToolsPickable and child.has_signal("snap_completed"):
			snap_points.append(child)
			# Exclude snap points from gravity gun capture
			if not child.is_in_group("no_gravity_gun"):
				child.add_to_group("no_gravity_gun")

	print("%s: Found %d snap points (added to no_gravity_gun group)" % [get_class(), snap_points.size()])

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

## Create progress bar for reset timer
func _setup_progress_bar() -> void:
	if not enable_reset_timer:
		return

	# Create shader material for progress bar
	var shader = load("res://commons/scenes/main_menu/components/linear_progress.gdshader")
	_progress_material = ShaderMaterial.new()
	_progress_material.shader = shader
	_progress_material.set_shader_parameter("progress", 1.0)
	_progress_material.set_shader_parameter("color", Color(0.3, 0.8, 1.0, 0.6))

	# Create quad mesh for progress bar
	var quad = QuadMesh.new()
	quad.size = Vector2(0.3, 0.02)

	# Create mesh instance
	_progress_bar = MeshInstance3D.new()
	_progress_bar.name = "ResetTimerBar"
	_progress_bar.mesh = quad
	_progress_bar.material_override = _progress_material
	_progress_bar.position = Vector3(0, -0.15, 0)  # Below puzzle
	add_child(_progress_bar)

## Store initial positions of snap points for reset
func _store_initial_positions() -> void:
	for point in snap_points:
		if is_instance_valid(point):
			_initial_positions[point] = point.transform

## Update progress bar display
func _update_progress_bar(progress: float) -> void:
	if _progress_material:
		_progress_material.set_shader_parameter("progress", clamp(progress, 0.0, 1.0))
		# Change color as time runs out (green -> yellow -> red)
		var color: Color
		if progress > 0.5:
			color = Color(0.3, 0.8, 0.3, 0.6)  # Green
		elif progress > 0.25:
			color = Color(0.8, 0.8, 0.3, 0.6)  # Yellow
		else:
			color = Color(0.8, 0.3, 0.3, 0.6)  # Red
		_progress_material.set_shader_parameter("color", color)

## Reset puzzle to initial state
func _reset_puzzle() -> void:
	if current_state != PuzzleState.BUILDING:
		return

	print("%s: Resetting puzzle (timeout)" % get_class())

	# Reset all snap points to initial positions
	for point in snap_points:
		if is_instance_valid(point) and point in _initial_positions:
			# Keep frozen during transform reset to prevent physics interference
			if point is RigidBody3D:
				point.freeze = true
				point.linear_velocity = Vector3.ZERO
				point.angular_velocity = Vector3.ZERO
			point.transform = _initial_positions[point]
			# Clear connections
			if point.has_method("get_connected_points"):
				var connected = point.get_connected_points()
				for other in connected:
					if point.has_method("remove_connection"):
						point.remove_connection(other)

	# Clear connection manager state
	if connection_manager:
		# Break all connections by unregistering and re-registering points
		for point in snap_points:
			if is_instance_valid(point):
				if connection_manager.has_method("unregister_snap_point"):
					connection_manager.unregister_snap_point(point)
		# Re-register after a frame
		await get_tree().process_frame
		for point in snap_points:
			if is_instance_valid(point):
				if connection_manager.has_method("register_snap_point"):
					connection_manager.register_snap_point(point)

	# Reset timer
	_elapsed_time = 0.0
	_update_progress_bar(1.0)

	puzzle_reset.emit()

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

	# Hide progress bar
	if _progress_bar:
		_progress_bar.visible = false

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
		# out-of-tree guard: get_tree() is null once a map is torn down
		if not is_inside_tree():
			await tree_entered
		await get_tree().create_timer(success_display_duration).timeout
		if success_label:
			success_label.visible = false
	
	# Legacy spawn behavior (if enabled)
	if enable_spawn and spawn_scene_path != "":
		_spawn_object()
	
	# Mark as completed
	current_state = PuzzleState.COMPLETED
	
	# Hide puzzle after delay
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
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

## Play completion sound (max 3 seconds)
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
				# Disable collision to prevent invisible colliders
				point.set_collision_layer(0)
				point.set_collision_mask(0)
			# Also disable any CollisionShape3D children
			for child in point.get_children():
				if child is CollisionShape3D:
					child.disabled = true
			print("%s: Hidden snap point %s" % [get_class(), point.name])

	# Hide any lines/triangles that were created
	_hide_visual_connections()

	if logic_display:
		logic_display.visible = false

	# Hide puzzle boundary sphere if present
	var boundary = get_node_or_null("PuzzleBoundary")
	if boundary:
		boundary.visible = false

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
