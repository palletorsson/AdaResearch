extends Node3D
class_name SnapOctahedronPuzzle

## Snap Octahedron Puzzle Controller
## Manages a 6-point octahedron puzzle that removes snap points when completed

enum PuzzleState {
	BUILDING,      # Points are movable
	VALIDATING,    # Checking if octahedron is correct
	LOCKED,        # Octahedron formed, points frozen
	COMPLETED      # Snap points hidden/removed
}

## Export parameters
@export_group("Puzzle Configuration")
@export var auto_solve: bool = true  # Automatically remove points when octahedron is formed
@export var spawn_position: Vector3 = Vector3(0, 0, 2)  # Where walkable prism appears
@export var spawn_scale: float = 1.0  # Size multiplier for prism (default 1 unit)
@export var prism_rotation: Vector3 = Vector3(0, 0, 0)  # Orientation of spawned prism (euler angles)

@export_group("Visual Feedback")
@export var locked_material: Material  # Material to apply when points are locked
@export var show_success_message: bool = true
@export var success_message: String = "Octahedron complete! Ramp spawned."

## Internal state
var current_state: PuzzleState = PuzzleState.BUILDING
var snap_points: Array[Node3D] = []
var connection_manager: SnapConnectionManager
var success_label: Label3D
var instruction_label: Label3D
var required_edges: int = 12  # Octahedron has 12 edges
var last_edge_count: int = 0
var spawned_prism: Node3D

## Signals
signal puzzle_solved
signal prism_spawned(prism: Node3D)

func _ready() -> void:
	# Find all snap points as children
	for child in get_children():
		if child is XRToolsPickable and child.has_signal("snap_completed"):
			snap_points.append(child)
	
	print("SnapOctahedronPuzzle: Found %d snap points" % snap_points.size())
	
	# Find instruction label
	for child in get_children():
		if child is Label3D and child.name == "InstructionLabel":
			instruction_label = child
			break
	
	# Apply transparent emissive material to snap points
	_apply_puzzle_materials()
	
	# Find or create SnapConnectionManager
	connection_manager = _find_connection_manager()
	if not connection_manager:
		push_error("SnapOctahedronPuzzle: No SnapConnectionManager found in scene!")
		return
	
	# Connect to octahedron_formed signal
	if not connection_manager.octahedron_formed.is_connected(_on_octahedron_formed):
		connection_manager.octahedron_formed.connect(_on_octahedron_formed)
	
	# Update initial progress
	_update_progress_display()
	
	# Create success message label
	if show_success_message:
		success_label = Label3D.new()
		success_label.name = "SuccessLabel"
		success_label.text = success_message
		success_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		success_label.font_size = 48
		success_label.modulate = Color(0.3, 1.0, 0.3, 1.0)  # Green
		success_label.outline_size = 8
		success_label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
		success_label.scale = Vector3.ONE * 0.15
		success_label.visible = false
		add_child(success_label)

func _find_connection_manager() -> SnapConnectionManager:
	# Check siblings first
	if get_parent():
		for sibling in get_parent().get_children():
			if sibling is SnapConnectionManager:
				return sibling
	
	# Check as autoload
	if Engine.has_singleton("SnapConnectionManager"):
		return Engine.get_singleton("SnapConnectionManager")
	
	# Search entire scene tree
	var root = get_tree().root
	return _find_manager_recursive(root)

func _find_manager_recursive(node: Node) -> SnapConnectionManager:
	if node is SnapConnectionManager:
		return node
	for child in node.get_children():
		var result = _find_manager_recursive(child)
		if result:
			return result
	return null

func _process(_delta: float) -> void:
	if current_state == PuzzleState.BUILDING:
		_update_progress_display()

func _update_progress_display() -> void:
	if not connection_manager or not instruction_label:
		return
	
	var edge_count = _count_edges_between_our_points()
	
	# Only update if count changed
	if edge_count != last_edge_count:
		instruction_label.text = "Connect the 6 points to form an octahedron\n%d/%d edges" % [edge_count, required_edges]
		print("SnapOctahedronPuzzle: %d/%d edges connected" % [edge_count, required_edges])
		last_edge_count = edge_count

func _count_edges_between_our_points() -> int:
	if not connection_manager:
		return 0
	
	var edge_count = 0
	
	# Count connections between our snap points
	for i in range(snap_points.size()):
		for j in range(i + 1, snap_points.size()):
			if connection_manager.are_points_connected(snap_points[i], snap_points[j]):
				edge_count += 1
	
	return edge_count

func _on_octahedron_formed(points: Array) -> void:
	# Check if this octahedron uses our snap points
	var our_points_count = 0
	for point in points:
		if point in snap_points:
			our_points_count += 1
	
	# If all 6 points are ours, this is our octahedron!
	if our_points_count == 6:
		print("SnapOctahedronPuzzle: Octahedron completed with our points!")
		_validate_and_complete()

func _validate_and_complete() -> void:
	if current_state != PuzzleState.BUILDING:
		return
	
	current_state = PuzzleState.VALIDATING
	
	# Freeze all snap points
	_lock_points()
	
	current_state = PuzzleState.LOCKED
	
	# Remove/hide the snap points if auto_solve is enabled
	if auto_solve:
		_hide_snap_points()

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

func _hide_snap_points() -> void:
	if current_state == PuzzleState.COMPLETED:
		return
	
	# Spawn walkable prism first
	_spawn_walkable_prism()
	
	# Hide/remove all snap points and their visual connections
	for point in snap_points:
		if is_instance_valid(point):
			point.visible = false
			if point is RigidBody3D:
				point.freeze = true
			print("SnapOctahedronPuzzle: Hidden snap point ", point.name)
	
	# Hide any lines/triangles that were created
	_hide_visual_connections()
	
	# Update state
	current_state = PuzzleState.COMPLETED
	
	# Show success message
	if success_label:
		success_label.visible = true
		success_label.global_position = global_position + Vector3(0, 0.5, 0)
		# Auto-hide after 3 seconds
		await get_tree().create_timer(3.0).timeout
		if success_label:
			success_label.visible = false
	
	# Emit signal
	puzzle_solved.emit()
	
	print("SnapOctahedronPuzzle: Octahedron puzzle completed!")

func _spawn_walkable_prism() -> void:
	# Load the walkable prism scene
	var walkable_prism_scene = load("res://commons/scenes/mapobjects/walkableprism.tscn")
	if not walkable_prism_scene:
		push_error("SnapOctahedronPuzzle: Could not load walkableprism.tscn")
		return
	
	# Instantiate the prism
	spawned_prism = walkable_prism_scene.instantiate()
	spawned_prism.name = "SpawnedPrismFromOctahedron"
	
	# Find GridScene node to add the prism to
	var grid_scene = _find_grid_scene()
	if not grid_scene:
		push_error("SnapOctahedronPuzzle: Could not find GridScene node to spawn prism in")
		return
	
	# Add to GridScene first (must be in tree before setting global_position)
	grid_scene.add_child(spawned_prism)
	
	# Calculate world position (relative to this puzzle or absolute)
	var world_spawn_pos = global_position + spawn_position
	spawned_prism.global_position = world_spawn_pos
	
	# Apply rotation
	spawned_prism.rotation_degrees = prism_rotation
	
	# Apply scale
	spawned_prism.scale = Vector3.ONE * spawn_scale
	
	# Emit signal
	prism_spawned.emit(spawned_prism)
	
	print("SnapOctahedronPuzzle: Spawned walkable prism at ", world_spawn_pos)

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

func _hide_visual_connections() -> void:
	"""Hide lines and triangles connected to our snap points"""
	# Get all SnapLine and SnapTriangle nodes from the scene
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

func _apply_puzzle_materials() -> void:
	"""Apply transparent emissive materials to snap points"""
	# Create transparent emissive material
	var puzzle_material = StandardMaterial3D.new()
	puzzle_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puzzle_material.albedo_color = Color(1.0, 0.8, 0.3, 0.6)  # Orange-ish with 60% opacity
	puzzle_material.metallic = 0.5
	puzzle_material.roughness = 0.3
	puzzle_material.emission_enabled = true
	puzzle_material.emission = Color(1.0, 0.8, 0.3, 1.0)
	puzzle_material.emission_energy_multiplier = 2.0
	
	# Apply to all snap points
	for point in snap_points:
		if not point:
			continue
		
		# Find the MeshInstance3D child
		var mesh_instance = point.get_node_or_null("MeshInstance3D")
		if mesh_instance and mesh_instance is MeshInstance3D:
			# Apply material to the mesh instance
			mesh_instance.material_override = puzzle_material
			print("SnapOctahedronPuzzle: Applied transparent material to ", point.name)

## Public methods for manual control
func solve_puzzle() -> void:
	"""Manually trigger puzzle completion (for testing or scripted events)"""
	_validate_and_complete()

func reset_puzzle() -> void:
	"""Reset the puzzle to initial state"""
	# Show snap points again
	for point in snap_points:
		if is_instance_valid(point):
			point.visible = true
			if point is RigidBody3D:
				point.freeze = false
	
	current_state = PuzzleState.BUILDING
	print("SnapOctahedronPuzzle: Puzzle reset")
