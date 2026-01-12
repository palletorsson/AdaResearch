extends Node3D
class_name SnapTetrahedronPuzzle

## Snap Tetrahedron Puzzle Controller
## Manages a 4-point tetrahedron puzzle that spawns a cube when completed

enum PuzzleState {
	BUILDING,      # Points are movable
	VALIDATING,    # Checking if tetrahedron is correct
	LOCKED,        # Tetrahedron formed, points frozen
	COMPLETED      # Cube spawned
}

## Export parameters
@export_group("Puzzle Configuration")
@export var spawn_position: Vector3 = Vector3(0, 0, 1.5)  # Where cube appears relative to puzzle
@export var spawn_scale: float = 0.1  # Size multiplier for cube
@export var auto_solve: bool = true  # Automatically spawn cube when tetrahedron is formed

@export_group("Visual Feedback")
@export var locked_material: Material  # Material to apply when points are locked
@export var show_success_message: bool = true
@export var success_message: String = "Tetrahedron complete! Cube spawned."

## Internal state
var current_state: PuzzleState = PuzzleState.BUILDING
var snap_points: Array[Node3D] = []
var connection_manager: SnapConnectionManager
var spawned_cube: Node3D
var success_label: Label3D
var instruction_label: Label3D
var required_edges: int = 6  # Tetrahedron has 6 edges (complete graph K4)
var last_edge_count: int = 0

## Signals
signal puzzle_solved
signal cube_spawned(cube: Node3D)

func _ready() -> void:
	# Find all snap points as children
	for child in get_children():
		if child is XRToolsPickable and child.has_signal("snap_completed"):
			snap_points.append(child)
	
	print("SnapTetrahedronPuzzle: Found %d snap points" % snap_points.size())
	
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
		push_error("SnapTetrahedronPuzzle: No SnapConnectionManager found in scene!")
		return
	
	# Connect to tetrahedron_formed signal
	if not connection_manager.tetrahedron_formed.is_connected(_on_tetrahedron_formed):
		connection_manager.tetrahedron_formed.connect(_on_tetrahedron_formed)
	
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
		instruction_label.text = "Connect all 4 points to form a tetrahedron\n%d/%d edges" % [edge_count, required_edges]
		print("SnapTetrahedronPuzzle: %d/%d edges connected" % [edge_count, required_edges])
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

func _on_tetrahedron_formed(points: Array) -> void:
	# Check if this tetrahedron uses our snap points
	var our_points_count = 0
	for point in points:
		if point in snap_points:
			our_points_count += 1
	
	# If all 4 points are ours, this is our tetrahedron!
	if our_points_count == 4:
		print("SnapTetrahedronPuzzle: Tetrahedron completed with our points!")
		_validate_and_complete()

func _validate_and_complete() -> void:
	if current_state != PuzzleState.BUILDING:
		return
	
	current_state = PuzzleState.VALIDATING
	
	# Freeze all snap points
	_lock_points()
	
	current_state = PuzzleState.LOCKED
	
	# Play completion sound
	_play_completion_sound()
	
	# Spawn the cube if auto_solve is enabled
	if auto_solve:
		_spawn_cube()

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

func _spawn_cube() -> void:
	if current_state == PuzzleState.COMPLETED:
		return
	
	# Load the cube scene
	var cube_scene = load("res://commons/primitives/cubes/cube_scene.tscn")
	if not cube_scene:
		push_error("SnapTetrahedronPuzzle: Failed to load cube_scene.tscn")
		return
	
	# Instantiate the cube
	spawned_cube = cube_scene.instantiate()
	spawned_cube.name = "SpawnedCube"
	
	# Find GridScene node to add the cube to
	var grid_scene = _find_grid_scene()
	if not grid_scene:
		push_error("SnapTetrahedronPuzzle: Could not find GridScene node to spawn cube in")
		return
	
	# Add to GridScene first (must be in tree before setting global_position)
	grid_scene.add_child(spawned_cube)
	
	# Calculate center of tetrahedron for cube placement
	var center = _calculate_center(snap_points)
	spawned_cube.global_position = center + spawn_position
	
	# Apply scale
	spawned_cube.scale = Vector3.ONE * spawn_scale
	
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
	
	# Hide snap points and connections after a delay
	await get_tree().create_timer(1.0).timeout
	_hide_puzzle()
	
	# Emit signals
	puzzle_solved.emit()
	cube_spawned.emit(spawned_cube)
	
	print("SnapTetrahedronPuzzle: Spawned cube at ", spawned_cube.global_position)

func _hide_puzzle() -> void:
	"""Hide/remove all snap points and their visual connections"""
	for point in snap_points:
		if is_instance_valid(point):
			point.visible = false
	
	# Hide any lines/triangles that were created
	_hide_visual_connections()
	
	print("SnapTetrahedronPuzzle: Puzzle hidden")

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

func _calculate_center(points: Array[Node3D]) -> Vector3:
	"""Calculate the average position of all points"""
	var center = Vector3.ZERO
	for point in points:
		if is_instance_valid(point):
			center += point.global_position
	if points.size() > 0:
		center /= float(points.size())
	return center

func _apply_puzzle_materials() -> void:
	"""Apply transparent emissive materials to snap points"""
	# Create transparent emissive material
	var puzzle_material = StandardMaterial3D.new()
	puzzle_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puzzle_material.albedo_color = Color(0.3, 1.0, 0.8, 0.6)  # Cyan-ish with 60% opacity
	puzzle_material.metallic = 0.5
	puzzle_material.roughness = 0.3
	puzzle_material.emission_enabled = true
	puzzle_material.emission = Color(0.3, 1.0, 0.8, 1.0)
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
			print("SnapTetrahedronPuzzle: Applied transparent material to ", point.name)

## Public methods for manual control
func solve_puzzle() -> void:
	"""Manually trigger puzzle completion (for testing or scripted events)"""
	_validate_and_complete()

func reset_puzzle() -> void:
	"""Reset the puzzle to initial state"""
	if current_state == PuzzleState.COMPLETED and spawned_cube:
		spawned_cube.queue_free()
		spawned_cube = null
	
	# Unfreeze points
	for point in snap_points:
		if point is RigidBody3D:
			point.freeze = false
	
	current_state = PuzzleState.BUILDING
	print("SnapTetrahedronPuzzle: Puzzle reset")

func _find_grid_scene() -> Node:
	"""Find the GridScene node in the scene tree"""
	# Try to find GridScene by name first
	var current = self
	while current:
		if current.name == "GridScene":
			return current
		current = current.get_parent()
	
	# Try searching from root
	var root = get_tree().root
	if root:
		var grid_scene = _search_for_grid_scene(root)
		if grid_scene:
			return grid_scene
	
	# Fallback to current scene
	var current_scene = get_tree().current_scene
	if current_scene:
		return current_scene
	
	# Last resort: return root
	return root

func _search_for_grid_scene(node: Node) -> Node:
	"""Recursively search for GridScene node"""
	if node.name == "GridScene":
		return node
	
	for child in node.get_children():
		var result = _search_for_grid_scene(child)
		if result:
			return result
	
	return null

func _play_completion_sound() -> void:
	"""Play a happy sound when puzzle is completed"""
	if not has_node("/root/SoundBank"):
		print("SnapTetrahedronPuzzle: SoundBank not found, skipping completion sound")
		return
	
	var sound_bank = get_node("/root/SoundBank")
	var sound_stream = sound_bank.get_sound("AudioSynthesizer.POWER_UP_JINGLE")
	
	if not sound_stream:
		print("SnapTetrahedronPuzzle: Could not get completion sound")
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
	print("SnapTetrahedronPuzzle: Playing completion sound")
