@tool
extends Node3D
class_name BalancePuzzle

## Balance Puzzle - The Sublime Through Physics
##
## No ghost guides. No templates. Stack freely.
## Reach the height threshold while stable.
## When achieved: your creation transforms into a walking creature.
##
## QFEP: Truth emerges from physics, not prescription.
## Multiple solutions exist. The form finds itself.

## Height required to trigger transformation (meters)
@export var height_threshold: float = 0.4

## Minimum stability time before transformation (seconds)
@export var stability_time: float = 1.5

## Maximum velocity for a piece to be considered "stable"
@export var stability_velocity_threshold: float = 0.05

## Number of pieces to spawn
@export var piece_count: int = 8

## Mix of shapes: ratio of cubes to pyramids (0 = all pyramids, 1 = all cubes)
@export_range(0.0, 1.0) var cube_ratio: float = 0.7

## Piece scale
@export var piece_scale: float = 0.08

## Spawn area offset from puzzle center
@export var spawn_offset: Vector3 = Vector3(0.3, 0.1, 0)

## Platform size
@export var platform_size: Vector3 = Vector3(0.5, 0.05, 0.5)

## Platform color
@export var platform_color: Color = Color(0.3, 0.3, 0.35)

## Walker speed after transformation
@export var walker_speed: float = 0.15

## Walker step height
@export var walker_step_height: float = 0.03

## Walker step frequency
@export var walker_step_frequency: float = 3.0

## Signals
signal height_changed(current_height: float, threshold: float)
signal stability_progress(progress: float)  # 0-1 progress toward stable
signal transformation_started()
signal transformation_complete()
signal walker_created(walker: Node3D)

## Internal state
enum PuzzleState { BUILDING, STABILIZING, TRANSFORMING, WALKING, COMPLETE }
var _state: PuzzleState = PuzzleState.BUILDING
var _pieces: Array[Node3D] = []
var _platform: MeshInstance3D
var _platform_body: StaticBody3D
var _stability_timer: float = 0.0
var _current_height: float = 0.0
var _walker: Node3D = null
var _height_indicator: Label3D
var _walk_time: float = 0.0

# Scene references
var _cube_scene: PackedScene
var _pyramid_scene: PackedScene


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	# Load piece scenes
	_cube_scene = load("res://commons/primitives/cubes/grab_cube.tscn")
	_pyramid_scene = load("res://commons/primitives/pyramid/grab_pyramid.tscn")

	# Create platform
	_create_platform()

	# Create height indicator
	_create_height_indicator()

	# Spawn pieces
	call_deferred("_spawn_pieces")


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	match _state:
		PuzzleState.BUILDING, PuzzleState.STABILIZING:
			_update_height_check()
			_update_stability_check(delta)
		PuzzleState.WALKING:
			_update_walker(delta)


func _create_platform() -> void:
	# Create static body for platform
	_platform_body = StaticBody3D.new()
	_platform_body.name = "Platform"
	add_child(_platform_body)

	# Create mesh
	_platform = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = platform_size
	_platform.mesh = box

	# Material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = platform_color
	mat.roughness = 0.9
	_platform.material_override = mat

	_platform_body.add_child(_platform)

	# Collision shape
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = platform_size
	collision.shape = shape
	_platform_body.add_child(collision)

	# Position platform so top surface is at y=0
	_platform_body.position = Vector3(0, -platform_size.y / 2, 0)


func _create_height_indicator() -> void:
	_height_indicator = Label3D.new()
	_height_indicator.name = "HeightIndicator"
	_height_indicator.font_size = 28
	_height_indicator.pixel_size = 0.001
	_height_indicator.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_height_indicator.no_depth_test = true
	_height_indicator.modulate = Color(0.8, 0.9, 1.0, 0.9)
	_height_indicator.outline_size = 6
	_height_indicator.outline_modulate = Color(0.1, 0.1, 0.2, 0.8)
	_height_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_height_indicator.position = Vector3(0, height_threshold + 0.1, 0)
	add_child(_height_indicator)
	_update_height_display()


func _update_height_display() -> void:
	if not _height_indicator:
		return

	var progress = _current_height / height_threshold
	var progress_bar = _create_progress_bar(progress)

	if _state == PuzzleState.STABILIZING:
		var stable_progress = _stability_timer / stability_time
		_height_indicator.text = "%s\n%.0f%% stable" % [progress_bar, stable_progress * 100]
		_height_indicator.modulate = Color(0.5, 1.0, 0.5, 0.9)
	else:
		_height_indicator.text = "%s\n%.1f / %.1f m" % [progress_bar, _current_height, height_threshold]
		_height_indicator.modulate = Color(0.8, 0.9, 1.0, 0.9) if progress < 1.0 else Color(0.3, 1.0, 0.5, 0.9)

	# Position above threshold line
	_height_indicator.position.y = height_threshold + 0.15


func _create_progress_bar(progress: float) -> String:
	var filled = clampi(int(progress * 10), 0, 10)
	var empty = 10 - filled
	return "[" + "=".repeat(filled) + "-".repeat(empty) + "]"


func _spawn_pieces() -> void:
	if not _cube_scene and not _pyramid_scene:
		push_error("BalancePuzzle: No piece scenes loaded")
		return

	var spawn_base = spawn_offset

	for i in range(piece_count):
		var is_cube = randf() < cube_ratio
		var scene = _cube_scene if is_cube else _pyramid_scene

		if not scene:
			scene = _cube_scene if _cube_scene else _pyramid_scene

		var piece = scene.instantiate()

		# Randomize spawn position
		var offset = Vector3(
			randf_range(-0.1, 0.1),
			i * 0.12,  # Stack vertically to avoid overlap
			randf_range(-0.1, 0.1)
		)

		# Find GridScene to add pieces to (so they're grabbable)
		var grid_scene = _find_grid_scene()
		if grid_scene:
			grid_scene.add_child(piece)
		else:
			add_child(piece)

		piece.global_position = global_position + spawn_base + offset

		# Random rotation
		piece.rotation_degrees.y = randf_range(0, 360)

		_pieces.append(piece)

	print("BalancePuzzle: Spawned %d pieces" % piece_count)


func _update_height_check() -> void:
	# Find the highest point of any piece above the platform
	var max_height: float = 0.0
	var platform_top = global_position.y

	for piece in _pieces:
		if not is_instance_valid(piece):
			continue

		# Get piece bounds
		var piece_top = piece.global_position.y
		var mesh = piece.get_node_or_null("MeshInstance3D")
		if mesh and mesh.mesh:
			var aabb = mesh.mesh.get_aabb()
			piece_top += aabb.size.y / 2

		var height_above_platform = piece_top - platform_top
		if height_above_platform > max_height:
			max_height = height_above_platform

	_current_height = max_height
	height_changed.emit(_current_height, height_threshold)
	_update_height_display()


func _update_stability_check(delta: float) -> void:
	if _current_height < height_threshold:
		_stability_timer = 0.0
		if _state == PuzzleState.STABILIZING:
			_state = PuzzleState.BUILDING
		return

	# Height threshold reached - check stability
	var all_stable = true

	for piece in _pieces:
		if not is_instance_valid(piece):
			continue

		if piece is RigidBody3D:
			var velocity = piece.linear_velocity.length()
			var angular = piece.angular_velocity.length()

			if velocity > stability_velocity_threshold or angular > stability_velocity_threshold * 2:
				all_stable = false
				break

	if all_stable:
		if _state != PuzzleState.STABILIZING:
			_state = PuzzleState.STABILIZING
			print("BalancePuzzle: Height reached! Checking stability...")

		_stability_timer += delta
		stability_progress.emit(_stability_timer / stability_time)
		_update_height_display()

		if _stability_timer >= stability_time:
			_trigger_transformation()
	else:
		_stability_timer = maxf(0, _stability_timer - delta * 2)  # Decay faster than gain
		if _stability_timer <= 0 and _state == PuzzleState.STABILIZING:
			_state = PuzzleState.BUILDING


func _trigger_transformation() -> void:
	if _state == PuzzleState.TRANSFORMING:
		return

	_state = PuzzleState.TRANSFORMING
	transformation_started.emit()
	print("BalancePuzzle: TRANSFORMATION TRIGGERED!")

	# Hide height indicator
	if _height_indicator:
		_height_indicator.visible = false

	# Begin the transformation sequence
	await _transform_to_walker()


func _transform_to_walker() -> void:
	# Collect all piece positions and freeze them
	var piece_data: Array = []

	for piece in _pieces:
		if not is_instance_valid(piece):
			continue

		if piece is RigidBody3D:
			piece.freeze = true

		piece_data.append({
			"node": piece,
			"position": piece.global_position,
			"rotation": piece.rotation
		})

	if piece_data.is_empty():
		_state = PuzzleState.BUILDING
		return

	# Calculate center of mass
	var center = Vector3.ZERO
	for data in piece_data:
		center += data.position
	center /= piece_data.size()

	# Create walker container
	_walker = Node3D.new()
	_walker.name = "Walker"
	add_child(_walker)
	_walker.global_position = center

	# Dramatic pause
	await get_tree().create_timer(0.5).timeout

	# Animate pieces gathering
	var tween = create_tween()
	tween.set_parallel(true)

	for i in range(piece_data.size()):
		var data = piece_data[i]
		var piece = data.node as Node3D

		# Calculate relative position in walker
		var rel_pos = data.position - center

		# Organize into body structure
		var target_pos = _calculate_walker_position(i, piece_data.size(), rel_pos)

		tween.tween_property(piece, "global_position", center + target_pos, 0.8)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await tween.finished

	# Reparent pieces to walker
	for data in piece_data:
		var piece = data.node as Node3D
		var global_pos = piece.global_position
		var global_rot = piece.global_rotation

		piece.get_parent().remove_child(piece)
		_walker.add_child(piece)
		piece.global_position = global_pos
		piece.global_rotation = global_rot

	# Small bounce to show it's alive
	var bounce_tween = create_tween()
	bounce_tween.tween_property(_walker, "position:y", _walker.position.y + 0.05, 0.15)
	bounce_tween.tween_property(_walker, "position:y", _walker.position.y, 0.15)

	await bounce_tween.finished

	_state = PuzzleState.WALKING
	transformation_complete.emit()
	walker_created.emit(_walker)
	print("BalancePuzzle: Walker created and walking!")


func _calculate_walker_position(index: int, total: int, original_rel: Vector3) -> Vector3:
	# Simple bipedal arrangement:
	# - Bottom pieces become "legs" (left and right)
	# - Middle pieces become "body"
	# - Top pieces become "head"

	var height_ratio = float(index) / float(total)

	if height_ratio < 0.33:
		# Legs - spread horizontally
		var side = 1.0 if index % 2 == 0 else -1.0
		return Vector3(side * 0.06, original_rel.y * 0.8, 0)
	elif height_ratio < 0.66:
		# Body - center
		return Vector3(0, original_rel.y * 0.9, 0)
	else:
		# Head - top center, slightly forward
		return Vector3(0, original_rel.y, 0.02)


func _update_walker(delta: float) -> void:
	if not _walker:
		return

	_walk_time += delta

	# Walking animation
	var bob = sin(_walk_time * walker_step_frequency * TAU) * walker_step_height
	var sway = sin(_walk_time * walker_step_frequency * TAU * 0.5) * 0.02

	# Apply to walker
	_walker.position.y = bob
	_walker.rotation.z = sway

	# Move forward
	var forward = -_walker.global_transform.basis.z
	_walker.global_position += forward * walker_speed * delta

	# Slight random turning
	_walker.rotation.y += sin(_walk_time * 0.5) * 0.01

	# Animate individual pieces for "leg" motion
	var leg_index = 0
	for child in _walker.get_children():
		if child is Node3D:
			var leg_phase = leg_index * PI  # Alternate legs
			var leg_lift = abs(sin(_walk_time * walker_step_frequency * TAU + leg_phase)) * 0.02

			# Only move lower pieces (legs)
			if child.position.y < 0.1:
				child.position.y = child.position.y + leg_lift - 0.01

			leg_index += 1

	# Check if walker has gone far enough - then complete
	var distance_from_start = _walker.global_position.distance_to(global_position)
	if distance_from_start > 2.0:
		_state = PuzzleState.COMPLETE
		print("BalancePuzzle: Walker departed. Puzzle complete!")


## Find GridScene for proper piece parenting
func _find_grid_scene() -> Node:
	var current = self
	while current:
		if current.name == "GridScene":
			return current
		current = current.get_parent()

	var root = get_tree().current_scene
	if root:
		return _find_node_by_name(root, "GridScene")
	return null


func _find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result = _find_node_by_name(child, target_name)
		if result:
			return result
	return null


## Reset the puzzle
func reset() -> void:
	_state = PuzzleState.BUILDING
	_stability_timer = 0.0
	_current_height = 0.0
	_walk_time = 0.0

	# Remove walker
	if _walker:
		_walker.queue_free()
		_walker = null

	# Clear existing pieces
	for piece in _pieces:
		if is_instance_valid(piece):
			piece.queue_free()
	_pieces.clear()

	# Show height indicator
	if _height_indicator:
		_height_indicator.visible = true

	# Respawn
	call_deferred("_spawn_pieces")
