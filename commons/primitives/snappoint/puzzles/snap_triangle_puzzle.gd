extends Node3D
class_name SnapTrianglePuzzle

## Snap Triangle Puzzle Controller
## Manages a puzzle where 3 snap points must be connected to form a triangle
## When complete, spawns a configurable object and removes the puzzle

enum PuzzleState {
	BUILDING,     # Player is connecting points
	VALIDATING,   # Checking if shape is complete
	LOCKED,       # Shape validated, points frozen
	COMPLETED     # Puzzle solved, rewards given
}

## Export parameters
@export_group("Puzzle Configuration")
@export var auto_solve: bool = true  # Automatically complete when triangle is formed
@export var spawn_scene_path: String = "res://commons/primitives/cubes/cube_scene.tscn"  # What to spawn on completion
@export var spawn_position: Vector3 = Vector3(0, 0, 1)  # Where object appears
@export var spawn_scale: float = 0.5  # Size multiplier for spawned object
@export var spawn_rotation: Vector3 = Vector3(0, 0, 0)  # Orientation (euler angles)

@export_group("Visual Feedback")
@export var locked_material: Material  # Material to apply when points are locked
@export var show_success_message: bool = true
@export var success_message: String = "Triangle complete!"

## Internal state
var current_state: PuzzleState = PuzzleState.BUILDING
var snap_points: Array[Node3D] = []
var connection_manager: SnapConnectionManager
var success_label: Label3D
var instruction_label: Label3D
var required_edges: int = 3  # Triangle has 3 edges
var last_edge_count: int = 0
var spawned_object: Node3D

## Signals
signal puzzle_solved
signal object_spawned(obj: Node3D)

func _ready() -> void:
	# Find all snap points as children
	for child in get_children():
		if child is XRToolsPickable and child.has_signal("snap_completed"):
			snap_points.append(child)
	
	print("SnapTrianglePuzzle: Found %d snap points" % snap_points.size())
	
	# Find instruction label
	instruction_label = get_node_or_null("InstructionLabel")
	if instruction_label:
		_update_thought_label()
	
	# Create success label if needed
	if show_success_message:
		success_label = Label3D.new()
		success_label.name = "SuccessLabel"
		success_label.text = success_message
		success_label.font_size = 32
		success_label.outline_size = 8
		success_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		success_label.modulate = Color(0.2, 1.0, 0.3, 1.0)  # Bright green
		success_label.visible = false
		add_child(success_label)
	
	# Find the SnapConnectionManager
	connection_manager = get_node_or_null("SnapConnectionManager")
	if not connection_manager:
		# Try to find it in the scene tree
		connection_manager = _find_connection_manager(get_tree().root)
	
	if connection_manager:
		# Connect to triangle formation signal
		if not connection_manager.triangle_formed.is_connected(_on_triangle_formed):
			connection_manager.triangle_formed.connect(_on_triangle_formed)
		print("SnapTrianglePuzzle: Connected to SnapConnectionManager")
	else:
		push_error("SnapTrianglePuzzle: Could not find SnapConnectionManager!")

func _find_connection_manager(node: Node) -> SnapConnectionManager:
	if node is SnapConnectionManager:
		return node
	for child in node.get_children():
		var result = _find_connection_manager(child)
		if result:
			return result
	return null

func _process(_delta: float) -> void:
	if current_state == PuzzleState.BUILDING:
		_update_thought_label()

func _update_thought_label() -> void:
	if not instruction_label:
		return
	
	# Count how many edges are currently connected among our points
	var edge_count = 0
	if connection_manager:
		for point_a in snap_points:
			for point_b in snap_points:
				if point_a != point_b and connection_manager.are_points_connected(point_a, point_b):
					edge_count += 1
		# Each edge is counted twice (A->B and B->A)
		edge_count = edge_count / 2
	
	if edge_count != last_edge_count:
		instruction_label.text = "Connect 3 points to form a triangle\n%d/3 edges" % edge_count
		last_edge_count = edge_count

func _on_triangle_formed(points: Array) -> void:
	# Check if this triangle uses our points
	var our_points_count = 0
	for point in points:
		if point in snap_points:
			our_points_count += 1
	
	# If all 3 points are ours, this is our triangle!
	if our_points_count == 3:
		print("SnapTrianglePuzzle: Triangle completed with our points!")
		print("SnapTrianglePuzzle: 3/3 edges connected")
		_validate_and_complete()

func _validate_and_complete() -> void:
	if current_state != PuzzleState.BUILDING:
		return
	
	current_state = PuzzleState.VALIDATING
	
	# Freeze all snap points
	_lock_points()
	
	current_state = PuzzleState.LOCKED
	
	# Spawn object and hide puzzle if auto_solve is enabled
	if auto_solve:
		_spawn_object()

func _lock_points() -> void:
	for point in snap_points:
		if point is RigidBody3D:
			point.freeze = true
		
		# Apply locked material if provided
		if locked_material and point.has_node("MeshInstance3D"):
			var mesh_instance = point.get_node("MeshInstance3D")
			if mesh_instance is MeshInstance3D:
				mesh_instance.material_override = locked_material
		
		# Change color to indicate locked state
		if point.has_node("MeshInstance3D/Sphere"):
			var sphere = point.get_node("MeshInstance3D/Sphere")
			if sphere.has_method("set_base_color"):
				sphere.set_base_color(Color(0.5, 0.5, 1.0, 1.0))  # Blue-ish

func _spawn_object() -> void:
	if current_state == PuzzleState.COMPLETED:
		return
	
	# Load the scene
	var object_scene = load(spawn_scene_path)
	if not object_scene:
		push_error("SnapTrianglePuzzle: Could not load scene: %s" % spawn_scene_path)
		_complete_without_spawn()
		return
	
	# Instantiate the object
	spawned_object = object_scene.instantiate()
	spawned_object.name = "SpawnedFromTriangle"
	
	# Find GridScene node to add the object to
	var grid_scene = _find_grid_scene()
	if not grid_scene:
		push_error("SnapTrianglePuzzle: Could not find GridScene node to spawn object in")
		_complete_without_spawn()
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
	
	# Update state
	current_state = PuzzleState.COMPLETED
	
	# Show success message
	if success_label:
		success_label.visible = true
		success_label.global_position = global_position + Vector3(0, 0.3, 0)
		# Auto-hide after 3 seconds
		await get_tree().create_timer(3.0).timeout
		if success_label:
			success_label.visible = false
	
	# Hide snap points and connections after a delay
	await get_tree().create_timer(1.0).timeout
	_hide_puzzle()
	
	# Emit signals
	puzzle_solved.emit()
	object_spawned.emit(spawned_object)
	
	print("SnapTrianglePuzzle: Spawned object at ", world_spawn_pos)

func _complete_without_spawn() -> void:
	"""Complete puzzle without spawning (if spawn fails)"""
	current_state = PuzzleState.COMPLETED
	
	if success_label:
		success_label.visible = true
		success_label.global_position = global_position + Vector3(0, 0.3, 0)
		await get_tree().create_timer(3.0).timeout
		if success_label:
			success_label.visible = false
	
	await get_tree().create_timer(1.0).timeout
	_hide_puzzle()
	
	puzzle_solved.emit()

func _hide_puzzle() -> void:
	"""Hide/remove all snap points and their visual connections"""
	for point in snap_points:
		if is_instance_valid(point):
			point.visible = false
			if point is RigidBody3D:
				point.freeze = true
			print("SnapTrianglePuzzle: Hidden snap point ", point.name)
	
	# Hide any lines/triangles that were created
	_hide_visual_connections()
	
	print("SnapTrianglePuzzle: Triangle puzzle completed!")

func _hide_visual_connections() -> void:
	"""Hide lines and triangles connected to our snap points"""
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

func _find_grid_scene() -> Node:
	"""Find the GridScene node to spawn objects in"""
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
