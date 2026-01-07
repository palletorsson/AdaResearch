extends Node3D

## Snap Wedge Puzzle Controller
## Manages a 5-point wedge puzzle that spawns a walkable ramp when completed

enum PuzzleState {
	BUILDING,      # Points are movable
	VALIDATING,    # Checking if wedge is correct
	LOCKED,        # Wedge formed, points frozen
	COMPLETED      # Walkable ramp spawned
}

## Export parameters
@export_group("Puzzle Configuration")
@export var spawn_position: Vector3 = Vector3(0, 0, 2)  # Where walkable ramp appears
@export var spawn_scale: float = 1.0  # Size multiplier for ramp (default 1 unit)
@export var ramp_rotation: Vector3 = Vector3(0, 0, 0)  # Orientation of spawned ramp (euler angles)
@export var auto_solve: bool = true  # Automatically spawn ramp when wedge is formed

@export_group("Visual Feedback")
@export var locked_material: Material  # Material to apply when points are locked
@export var show_success_message: bool = true
@export var success_message: String = "Wedge complete! Ramp spawned."

## Internal state
var current_state: PuzzleState = PuzzleState.BUILDING
var snap_points: Array[Node3D] = []
var connection_manager: SnapConnectionManager
var spawned_ramp: Node3D
var success_label: Label3D

## Signals
signal puzzle_solved
signal ramp_spawned(ramp: Node3D)

func _ready() -> void:
	# Find all snap points as children
	for child in get_children():
		if child is XRToolsPickable and child.has_signal("snap_completed"):
			snap_points.append(child)
	
	print("SnapWedgePuzzle: Found %d snap points" % snap_points.size())
	
	# Apply transparent emissive material to snap points
	_apply_puzzle_materials()
	
	# Find or create SnapConnectionManager
	connection_manager = _find_connection_manager()
	if not connection_manager:
		push_error("SnapWedgePuzzle: No SnapConnectionManager found in scene!")
		return
	
	# Connect to wedge_formed signal
	if not connection_manager.wedge_formed.is_connected(_on_wedge_formed):
		connection_manager.wedge_formed.connect(_on_wedge_formed)
	
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

func _on_wedge_formed(points: Array) -> void:
	# Check if this wedge uses our snap points
	var our_points_count = 0
	for point in points:
		if point in snap_points:
			our_points_count += 1
	
	# If all 6 points are ours, this is our wedge!
	if our_points_count == 6:
		print("SnapWedgePuzzle: Wedge completed with our points!")
		_validate_and_complete()

func _validate_and_complete() -> void:
	if current_state != PuzzleState.BUILDING:
		return
	
	current_state = PuzzleState.VALIDATING
	
	# Freeze all snap points
	_lock_points()
	
	current_state = PuzzleState.LOCKED
	
	# Spawn the walkable ramp if auto_solve is enabled
	if auto_solve:
		_spawn_walkable_ramp()

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

func _spawn_walkable_ramp() -> void:
	if current_state == PuzzleState.COMPLETED:
		return
	
	# Load the walkable prism scene
	var walkable_prism_scene = load("res://commons/scenes/mapobjects/walkableprism.tscn")
	if not walkable_prism_scene:
		push_error("SnapWedgePuzzle: Could not load walkableprism.tscn")
		return
	
	# Instantiate the ramp
	spawned_ramp = walkable_prism_scene.instantiate()
	spawned_ramp.name = "SpawnedRamp"
	
	# Calculate world position (relative to this puzzle or absolute)
	var world_spawn_pos = global_position + spawn_position
	spawned_ramp.global_position = world_spawn_pos
	
	# Apply rotation
	spawned_ramp.rotation_degrees = ramp_rotation
	
	# Apply scale
	spawned_ramp.scale = Vector3.ONE * spawn_scale
	
	# Add to scene
	var root = get_tree().current_scene
	if not root:
		root = get_tree().root
	root.add_child(spawned_ramp)
	
	# Update state
	current_state = PuzzleState.COMPLETED
	
	# Show success message
	if success_label:
		success_label.visible = true
		success_label.global_position = global_position + Vector3(0, 0.5, 0)
		# Auto-hide after 5 seconds
		await get_tree().create_timer(5.0).timeout
		if success_label:
			success_label.visible = false
	
	# Emit signals
	puzzle_solved.emit()
	ramp_spawned.emit(spawned_ramp)
	
	print("SnapWedgePuzzle: Spawned walkable ramp at ", world_spawn_pos)

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
			print("SnapWedgePuzzle: Applied transparent material to ", point.name)

## Public methods for manual control
func solve_puzzle() -> void:
	"""Manually trigger puzzle completion (for testing or scripted events)"""
	_validate_and_complete()

func reset_puzzle() -> void:
	"""Reset the puzzle to initial state"""
	if current_state == PuzzleState.COMPLETED and spawned_ramp:
		spawned_ramp.queue_free()
		spawned_ramp = null
	
	# Unfreeze points
	for point in snap_points:
		if point is RigidBody3D:
			point.freeze = false
	
	current_state = PuzzleState.BUILDING
	print("SnapWedgePuzzle: Puzzle reset")

