extends Node3D
class_name TransformPuzzleBase

## TransformPuzzleBase - Base class for puzzles verifying full transforms
## Verifies position, rotation, and scale of puzzle pieces against target transforms.
## Inspired by LineSnapPuzzleBase but works with full Transform3D verification.

## Piece target definition
class PieceTarget:
	var piece_id: String
	var target_position: Vector3
	var target_rotation: Vector3  # Euler degrees
	var target_scale: Vector3
	var position_tolerance: float = 0.08  # 8cm
	var rotation_tolerance: float = 15.0  # 15 degrees
	var scale_tolerance: float = 0.15  # 15%

	func _init(id: String = "", pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE):
		piece_id = id
		target_position = pos
		target_rotation = rot
		target_scale = scl

enum PuzzleState {
	BUILDING,     # Player is arranging pieces
	VALIDATING,   # Checking transforms
	LOCKED,       # All pieces validated, frozen
	COMPLETED     # Puzzle solved, rewards given
}

## Puzzle Configuration
@export_group("Puzzle Configuration")
@export var auto_validate: bool = true  # Check transforms continuously
@export var validation_interval: float = 0.2  # How often to check (seconds)
@export var show_ghost_guides: bool = true  # Show target positions

## Ghost Guide Appearance - Alyx style holographic
@export_group("Ghost Guides")
@export var ghost_alpha: float = 0.25
@export var ghost_color: Color = Color(0.0, 0.8, 1.0, 0.25)  # Cyan hologram
@export var ghost_emission_energy: float = 0.8

## Proximity Feedback - Alyx style
@export_group("Proximity Feedback")
@export var show_proximity_feedback: bool = true
@export var close_color: Color = Color(0.2, 1.0, 0.7, 0.6)  # Teal-green when close
@export var far_color: Color = Color(0.0, 0.6, 0.8, 0.3)  # Dim cyan when far

## Success Feedback - Clean, no text
@export_group("Success Feedback")
@export var success_message: String = ""  # No text by default
@export var show_success_label: bool = false  # Clean completion
@export var success_display_duration: float = 0.5
@export var lock_on_complete: bool = true
@export var completion_pulse_color: Color = Color(0.3, 1.0, 0.6, 1.0)  # Green pulse

## Tag System (like LineSnapPuzzleBase)
@export_group("Tag System")
@export var trigger_tag: String = ""
@export var trigger_action: String = "reveal"
@export var auto_hide_tagged: bool = false

## Snap-to-target settings
@export_group("Snap to Target")
@export var snap_hold_time: float = 1.0  # Seconds to hold at target before snapping
@export var snap_threshold: float = 0.95  # Proximity threshold - only triggers when piece is actually at target (returns 1.0)

## Internal state
var current_state: PuzzleState = PuzzleState.BUILDING
var piece_targets: Array[PieceTarget] = []  # Defined by child classes
var puzzle_pieces: Dictionary = {}  # piece_id -> Node3D (the actual pieces)
var ghost_guides: Dictionary = {}  # piece_id -> ghost mesh
var piece_proximity: Dictionary = {}  # piece_id -> bool (is close to target)
var piece_snap_timers: Dictionary = {}  # target_id -> float (time at target)
var piece_snapped: Dictionary = {}  # target_id -> bool (target has been filled)
var pieces_used: Dictionary = {}  # piece_id -> bool (cube has been used for snapping)
var success_label: Label3D
var ghost_container: Node3D
var is_completed: bool = false
var _validation_timer: float = 0.0

## Signals
signal puzzle_completed()
signal piece_at_target(piece_id: String)
signal piece_left_target(piece_id: String)
signal all_pieces_aligned()
signal final_piece_created(piece: Node3D, target_id: String)  # Emitted when a wood piece is created


func _ready() -> void:
	# Ensure clean state on load (reset any persisted state)
	current_state = PuzzleState.BUILDING
	puzzle_pieces.clear()
	ghost_guides.clear()
	piece_proximity.clear()
	piece_snap_timers.clear()
	piece_snapped.clear()
	pieces_used.clear()
	is_completed = false
	_validation_timer = 0.0

	_setup_containers()

	# Child class should have populated piece_targets
	if piece_targets.is_empty():
		push_warning("TransformPuzzleBase: piece_targets not set by child class - define in _ready before super()")

	# Wait for transforms to be applied
	await get_tree().process_frame

	# Setup ghost guides if enabled
	if show_ghost_guides:
		call_deferred("_setup_ghost_guides")

	# Create success label
	if show_success_label:
		_create_success_label()

	# Auto-hide tagged objects if using reveal action
	if (auto_hide_tagged or trigger_action == "reveal") and trigger_tag != "":
		# out-of-tree guard: get_tree() is null once a map is torn down
		if not is_inside_tree():
			await tree_entered
		await get_tree().process_frame
		# out-of-tree guard: get_tree() is null once a map is torn down
		if not is_inside_tree():
			await tree_entered
		await get_tree().process_frame
		TagSystem.trigger_tag_action(trigger_tag, "hide")
		print("%s: Auto-hid objects with tag '%s'" % [name, trigger_tag])


func _process(delta: float) -> void:
	if is_completed or not auto_validate:
		return

	_validation_timer += delta
	if _validation_timer >= validation_interval:
		_validation_timer = 0.0
		_validate_all_pieces()


func _setup_containers() -> void:
	ghost_container = get_node_or_null("GhostGuides")
	if not ghost_container:
		ghost_container = Node3D.new()
		ghost_container.name = "GhostGuides"
		add_child(ghost_container)


## Register a puzzle piece to be tracked
func register_piece(piece_id: String, piece_node: Node3D) -> void:
	puzzle_pieces[piece_id] = piece_node
	piece_proximity[piece_id] = false
	pieces_used[piece_id] = false  # Track if this cube has been used

	# Connect to signals if it's a scalable grab cube
	if piece_node.has_signal("scale_changed"):
		piece_node.scale_changed.connect(_on_piece_scale_changed.bind(piece_id))

	# Connect to drop signal for immediate validation
	if piece_node.has_signal("dropped"):
		piece_node.dropped.connect(_on_piece_dropped.bind(piece_id))

	print("TransformPuzzleBase: Registered piece '%s'" % piece_id)


## Unregister a piece
func unregister_piece(piece_id: String) -> void:
	puzzle_pieces.erase(piece_id)
	piece_proximity.erase(piece_id)


## Get the target for a piece
func get_target_for_piece(piece_id: String) -> PieceTarget:
	for target in piece_targets:
		if target.piece_id == piece_id:
			return target
	return null


## Setup ghost guides showing target positions
func _setup_ghost_guides() -> void:
	if not ghost_container:
		return

	print("TransformPuzzleBase: Creating ghost guides for %d targets" % piece_targets.size())

	for target in piece_targets:
		var ghost = _create_ghost_for_target(target)
		if ghost:
			ghost_container.add_child(ghost)
			ghost_guides[target.piece_id] = ghost


## Create a ghost mesh showing target transform - Alyx holographic style
func _create_ghost_for_target(target: PieceTarget) -> Node3D:
	var ghost_container_node = Node3D.new()
	ghost_container_node.name = "Ghost_" + target.piece_id
	
	# Main ghost body - subtle fill
	var ghost = MeshInstance3D.new()
	ghost.name = "GhostBody"
	var box = BoxMesh.new()
	box.size = target.target_scale
	ghost.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(ghost_color.r, ghost_color.g, ghost_color.b, ghost_alpha * 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(ghost_color.r, ghost_color.g, ghost_color.b, 1.0)
	mat.emission_energy_multiplier = ghost_emission_energy * 0.3
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ghost.material_override = mat
	ghost_container_node.add_child(ghost)
	
	# Edge wireframe effect - brighter outline
	var edge_ghost = MeshInstance3D.new()
	edge_ghost.name = "GhostEdge"
	var edge_box = BoxMesh.new()
	edge_box.size = target.target_scale * 1.02  # Slightly larger
	edge_ghost.mesh = edge_box
	
	var edge_mat = StandardMaterial3D.new()
	edge_mat.albedo_color = Color(ghost_color.r, ghost_color.g, ghost_color.b, ghost_alpha)
	edge_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	edge_mat.emission_enabled = true
	edge_mat.emission = ghost_color
	edge_mat.emission_energy_multiplier = ghost_emission_energy
	edge_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	edge_mat.cull_mode = BaseMaterial3D.CULL_FRONT  # Only show back faces = edge effect
	edge_ghost.material_override = edge_mat
	ghost_container_node.add_child(edge_ghost)

	# Apply target transform (relative to puzzle origin)
	ghost_container_node.position = target.target_position
	ghost_container_node.rotation_degrees = target.target_rotation

	# Add subtle animation
	_add_ghost_animation(ghost_container_node)

	return ghost_container_node


## Add subtle pulse animation to ghost
func _add_ghost_animation(ghost: Node3D) -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(ghost, "scale", Vector3.ONE * 1.02, 1.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(ghost, "scale", Vector3.ONE * 0.98, 1.5).set_trans(Tween.TRANS_SINE)


## Create success label (optional - disabled by default for clean look)
func _create_success_label() -> void:
	if not show_success_label or success_message.is_empty():
		return
	
	success_label = Label3D.new()
	success_label.name = "SuccessLabel"
	success_label.text = success_message
	success_label.font_size = 28
	success_label.outline_size = 0
	success_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	success_label.modulate = Color(0.3, 1.0, 0.7, 1.0)
	success_label.visible = false
	add_child(success_label)


## Validate all pieces against their targets
## Any piece can match any unsnapped target based on position and scale similarity
func _validate_all_pieces() -> void:
	if is_completed:
		return

	# Get list of unsnapped targets
	var unsnapped_targets: Array[PieceTarget] = []
	for target in piece_targets:
		if not piece_snapped.get(target.piece_id, false):
			unsnapped_targets.append(target)

	# Get list of available pieces (not yet used for snapping)
	# IMPORTANT: Only consider pieces that are currently being held/grabbed
	var available_pieces: Array[Node3D] = []
	for piece_id in puzzle_pieces:
		var piece = puzzle_pieces[piece_id]
		if is_instance_valid(piece) and not pieces_used.get(piece_id, false):
			# Only consider piece if it's being held (has is_picked_up method and returns true)
			if piece.has_method("is_picked_up") and piece.is_picked_up():
				available_pieces.append(piece)


	# For each unsnapped target, find the best matching piece
	for target in unsnapped_targets:
		var best_piece: Node3D = null
		var best_proximity: float = 0.0
		var best_piece_id: String = ""

		for piece in available_pieces:
			# Find the piece_id for this piece
			var piece_id = ""
			for pid in puzzle_pieces:
				if puzzle_pieces[pid] == piece:
					piece_id = pid
					break

			if piece_id == "" or pieces_used.get(piece_id, false):
				continue

			var proximity = _calculate_piece_proximity_flexible(piece, target)
			if proximity > best_proximity:
				best_proximity = proximity
				best_piece = piece
				best_piece_id = piece_id

		# Update ghost color based on best match
		_update_ghost_proximity_gradient(target.piece_id, best_proximity)

		# Handle snap timer for best matching piece
		if best_piece and best_proximity >= snap_threshold:
			var current_time = piece_snap_timers.get(target.piece_id, 0.0)
			current_time += validation_interval
			piece_snap_timers[target.piece_id] = current_time

			if current_time >= snap_hold_time:
				# Snap this piece to this target
				_snap_piece_to_target(best_piece_id, best_piece, target)
				# Remove from available pieces
				available_pieces.erase(best_piece)
		else:
			piece_snap_timers[target.piece_id] = 0.0

	# Check if all targets are snapped
	var all_snapped = true
	for target in piece_targets:
		if not piece_snapped.get(target.piece_id, false):
			all_snapped = false
			break

	if all_snapped:
		_complete_puzzle()


## Snap a specific piece to a specific target (flexible matching)
func _snap_piece_to_target(piece_id: String, piece: Node3D, target: PieceTarget) -> void:
	print("TransformPuzzleBase: Snapping piece '%s' to target '%s'" % [piece_id, target.piece_id])

	# Mark target as snapped AND mark the cube as used
	piece_snapped[target.piece_id] = true
	pieces_used[piece_id] = true  # Mark this cube as used
	piece_snap_timers[target.piece_id] = 0.0

	# Play snap sound
	_play_snap_sound()

	# Get target global position
	var target_global_pos = to_global(target.target_position)

	# Replace the cube with a simple wood mesh
	var final_piece = _create_final_piece(target)

	# Store transforms before adding to scene
	var start_pos = piece.global_position
	var start_rot = piece.rotation_degrees

	# Add to scene first, then set position
	add_child(final_piece)
	final_piece.global_position = start_pos
	final_piece.rotation_degrees = start_rot

	# Emit signal so child classes can track the final piece
	final_piece_created.emit(final_piece, target.piece_id)

	# Animate the new piece to exact target
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(final_piece, "global_position", target_global_pos, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(final_piece, "rotation_degrees", target.target_rotation, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Remove the original cube
	piece.queue_free()
	puzzle_pieces.erase(piece_id)

	# Flash ghost green then fade out smoothly
	_update_ghost_color(target.piece_id, true)

	var ghost_node = ghost_guides.get(target.piece_id)
	if ghost_node:
		# Pulse then shrink away
		var ghost_tween = create_tween()
		ghost_tween.tween_property(ghost_node, "scale", Vector3.ONE * 1.1, 0.1)
		ghost_tween.tween_property(ghost_node, "scale", Vector3.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		ghost_tween.tween_callback(func(): ghost_node.visible = false)

	# Emit signal
	piece_at_target.emit(target.piece_id)


## Create a final furniture piece mesh (static wood box)
func _create_final_piece(target: PieceTarget) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "FinalPiece_" + target.piece_id

	# Create box mesh with target size
	var box = BoxMesh.new()
	box.size = target.target_scale
	mesh_instance.mesh = box

	# Try to load the wood shader material
	var wood_material = _create_wood_material()
	mesh_instance.material_override = wood_material

	return mesh_instance


## Create a wood material for final pieces
func _create_wood_material() -> Material:
	# Try to load the existing wood shader
	var wood_shader = load("res://commons/resourses/shaders/wood.gdshader")
	if wood_shader:
		var mat = ShaderMaterial.new()
		mat.shader = wood_shader
		mat.set_shader_parameter("light_color", Vector4(0.952941, 0.858824, 0.74902, 1))
		mat.set_shader_parameter("dark_color", Vector4(0.74902, 0.619608, 0.490196, 1))
		mat.set_shader_parameter("ring_scale", 4.0)
		mat.set_shader_parameter("wave_scale", 9.0)
		mat.set_shader_parameter("random_scale", 5.0)
		mat.set_shader_parameter("noise_scale", 0.03)
		return mat

	# Fallback to simple brown material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.4, 0.2)
	mat.roughness = 0.8
	return mat


## Play snap sound when piece locks into place
func _play_snap_sound() -> void:
	if not has_node("/root/SoundBank"):
		return

	var sound_bank = get_node("/root/SoundBank")
	var sound_stream = sound_bank.get_sound("AudioSynthesizer.BLIP_SELECT")

	if not sound_stream:
		return

	var player = AudioStreamPlayer3D.new()
	player.stream = sound_stream
	player.volume_db = -3.0
	player.max_distance = 15.0
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC
	player.global_position = global_position
	add_child(player)

	player.finished.connect(player.queue_free)
	player.play()


## Calculate how close a piece is to its target (0 = far, 1 = at target)
func _calculate_piece_proximity(piece: Node3D, target: PieceTarget) -> float:
	# Get piece's position relative to puzzle origin
	var piece_local_pos = to_local(piece.global_position)

	# Position proximity (0-1)
	var pos_delta = piece_local_pos.distance_to(target.target_position)
	var max_pos_dist = 1.0  # 1 meter max distance for gradient
	var pos_proximity = clampf(1.0 - (pos_delta / max_pos_dist), 0.0, 1.0)

	# Scale proximity (0-1)
	var piece_size = _get_piece_size(piece)
	var scale_diff = (piece_size - target.target_scale).length()
	var max_scale_dist = 0.5  # 0.5m max scale difference for gradient
	var scale_proximity = clampf(1.0 - (scale_diff / max_scale_dist), 0.0, 1.0)

	# Combine: use minimum of both (both need to be close)
	return min(pos_proximity, scale_proximity)


## Calculate proximity with flexible scale matching (rotation-independent)
## Simple approach: position within tolerance AND scale within tolerance = 1.0, otherwise based on distance
func _calculate_piece_proximity_flexible(piece: Node3D, target: PieceTarget) -> float:
	# Get piece's position relative to puzzle origin
	var piece_local_pos = to_local(piece.global_position)

	# Check position distance
	var pos_delta = piece_local_pos.distance_to(target.target_position)

	# Check scale difference (flexible - any axis order)
	var piece_size = _get_piece_size(piece)
	var scale_diff = _calculate_flexible_scale_diff(piece_size, target.target_scale)

	# Tolerances - more forgiving for playability
	var pos_tolerance = 0.20  # 20cm position tolerance
	var scale_tolerance = 0.15  # 15cm total scale tolerance (sum of axis differences)

	var pos_ok = pos_delta < pos_tolerance
	var scale_ok = scale_diff < scale_tolerance

	if pos_ok and scale_ok:
		return 1.0  # Perfect match

	# For visual feedback gradient (ghost color), use simple distance-based proximity
	var pos_proximity = clampf(1.0 - (pos_delta / 0.5), 0.0, 0.9)  # Cap at 0.9 so it never triggers snap
	var scale_proximity = clampf(1.0 - (scale_diff / 0.5), 0.0, 0.9)

	return min(pos_proximity, scale_proximity)


## Calculate scale difference allowing any axis permutation
## Returns the minimum difference when comparing sorted dimensions
func _calculate_flexible_scale_diff(piece_size: Vector3, target_size: Vector3) -> float:
	# Sort both sizes (ascending order)
	var piece_sorted = [piece_size.x, piece_size.y, piece_size.z]
	piece_sorted.sort()

	var target_sorted = [target_size.x, target_size.y, target_size.z]
	target_sorted.sort()

	# Compare sorted dimensions
	var diff = 0.0
	diff += abs(piece_sorted[0] - target_sorted[0])
	diff += abs(piece_sorted[1] - target_sorted[1])
	diff += abs(piece_sorted[2] - target_sorted[2])

	return diff


## Check if a piece matches its target transform
func _is_piece_at_target(piece: Node3D, target: PieceTarget) -> bool:
	# Get piece's position relative to puzzle origin
	var piece_local_pos = to_local(piece.global_position)

	# Position check
	var pos_delta = piece_local_pos.distance_to(target.target_position)
	if pos_delta > target.position_tolerance:
		return false

	# Rotation check (compare euler angles with wrapping)
	var piece_rot = piece.rotation_degrees
	var rot_diff = _rotation_difference(piece_rot, target.target_rotation)
	if rot_diff > target.rotation_tolerance:
		return false

	# Scale check - get actual size from scalable cubes
	var piece_size = _get_piece_size(piece)
	var scale_diff = (piece_size - target.target_scale).length()
	if scale_diff > target.scale_tolerance:
		return false

	return true


## Get the actual size of a piece (works with scalable cubes)
func _get_piece_size(piece: Node3D) -> Vector3:
	# For our scalable cubes, use get_scale_vector() * base_size
	if piece.has_method("get_scale_vector"):
		var scale_vec = piece.get_scale_vector()
		return scale_vec * 0.1  # Base cube size is 0.1

	# Try to get from mesh
	var mesh_instance = piece.get_node_or_null("MeshInstance3D")
	if mesh_instance and mesh_instance.mesh is BoxMesh:
		return mesh_instance.mesh.size

	# Fallback to node scale (for standard objects)
	return piece.scale


## Calculate rotation difference accounting for wrapping and axis flip
func _rotation_difference(rot_a: Vector3, rot_b: Vector3) -> float:
	# Normalize angles to -180 to 180 range
	var diff_x = _angle_difference(rot_a.x, rot_b.x)
	var diff_y = _angle_difference(rot_a.y, rot_b.y)
	var diff_z = _angle_difference(rot_a.z, rot_b.z)

	# Return max difference on any axis
	return max(max(abs(diff_x), abs(diff_y)), abs(diff_z))


func _angle_difference(a: float, b: float) -> float:
	var diff = fmod(a - b + 180.0, 360.0) - 180.0
	if diff < -180.0:
		diff += 360.0
	return diff


## Update ghost guide color based on proximity
func _update_ghost_color(piece_id: String, is_close: bool) -> void:
	if not show_proximity_feedback:
		return

	var ghost_node = ghost_guides.get(piece_id)
	if not ghost_node:
		return
	
	var color = close_color if is_close else ghost_color
	var emission_mult = 2.0 if is_close else ghost_emission_energy
	
	# Update both body and edge materials
	for child in ghost_node.get_children():
		if child is MeshInstance3D and child.material_override:
			var mat = child.material_override as StandardMaterial3D
			if mat:
				mat.emission = Color(color.r, color.g, color.b, 1.0)
				mat.emission_energy_multiplier = emission_mult
				if child.name == "GhostBody":
					mat.albedo_color = Color(color.r, color.g, color.b, ghost_alpha * 0.5)
				else:
					mat.albedo_color = Color(color.r, color.g, color.b, ghost_alpha)


## Update ghost color with smooth gradient based on proximity distance
func _update_ghost_proximity_gradient(piece_id: String, proximity: float) -> void:
	if not show_proximity_feedback:
		return

	var ghost_node = ghost_guides.get(piece_id)
	if not ghost_node:
		return
	
	# proximity is 0-1, where 1 = at target, 0 = far away
	var color = ghost_color.lerp(close_color, proximity)
	var emission_mult = lerp(ghost_emission_energy, 2.5, proximity)
	
	# Update both body and edge materials
	for child in ghost_node.get_children():
		if child is MeshInstance3D and child.material_override:
			var mat = child.material_override as StandardMaterial3D
			if mat:
				mat.emission = Color(color.r, color.g, color.b, 1.0)
				mat.emission_energy_multiplier = emission_mult
				if child.name == "GhostBody":
					mat.albedo_color = Color(color.r, color.g, color.b, ghost_alpha * 0.5 * (0.5 + proximity * 0.5))
				else:
					mat.albedo_color = Color(color.r, color.g, color.b, ghost_alpha * (0.5 + proximity * 0.5))


## Called when a piece's scale changes
func _on_piece_scale_changed(_new_scale: float, _scale_index: int, piece_id: String) -> void:
	# Trigger immediate validation
	_validate_all_pieces()


## Called when a piece is dropped
func _on_piece_dropped(_pickable, _piece_id: String) -> void:
	# Trigger immediate validation
	_validate_all_pieces()


## Complete the puzzle - clean Alyx-style (no text)
func _complete_puzzle() -> void:
	if is_completed:
		return

	is_completed = true
	current_state = PuzzleState.VALIDATING

	print("TransformPuzzleBase: Puzzle completed!")

	# Play completion pulse on all ghosts
	_play_completion_pulse()

	# Play completion sound
	_play_completion_sound()

	await get_tree().create_timer(0.3).timeout

	# Snap all pieces to exact target positions
	_snap_pieces_to_targets()

	# Lock all pieces
	if lock_on_complete:
		_lock_all_pieces()

	current_state = PuzzleState.LOCKED

	# Fade out ghost guides smoothly
	_fade_out_ghosts()

	# Trigger tag action
	if trigger_tag != "":
		var action = trigger_action if trigger_action != "" else "reveal"
		print("TransformPuzzleBase: Triggering tag action: %s -> %s" % [trigger_tag, action])
		TagSystem.trigger_tag_action(trigger_tag, action)

	current_state = PuzzleState.COMPLETED

	# Emit signals
	all_pieces_aligned.emit()
	puzzle_completed.emit()


## Play completion pulse effect on all pieces
func _play_completion_pulse() -> void:
	for ghost_id in ghost_guides:
		var ghost_node = ghost_guides[ghost_id]
		if not is_instance_valid(ghost_node):
			continue
		
		for child in ghost_node.get_children():
			if child is MeshInstance3D and child.material_override:
				var mat = child.material_override as StandardMaterial3D
				if mat:
					var tween = create_tween()
					tween.tween_property(mat, "emission", completion_pulse_color, 0.15)
					tween.tween_property(mat, "emission_energy_multiplier", 4.0, 0.15)
					tween.tween_property(mat, "emission_energy_multiplier", ghost_emission_energy, 0.3)


## Fade out ghosts smoothly
func _fade_out_ghosts() -> void:
	if not ghost_container:
		return
	
	for ghost_id in ghost_guides:
		var ghost_node = ghost_guides[ghost_id]
		if not is_instance_valid(ghost_node):
			continue
		
		var tween = create_tween()
		tween.tween_property(ghost_node, "scale", Vector3.ZERO, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_callback(func(): ghost_node.visible = false)


## Snap all pieces to their exact target positions
func _snap_pieces_to_targets() -> void:
	for target in piece_targets:
		var piece = puzzle_pieces.get(target.piece_id)
		if not piece:
			continue

		# Smoothly animate to final position
		var tween = create_tween()
		tween.set_parallel(true)

		var target_global_pos = to_global(target.target_position)
		tween.tween_property(piece, "global_position", target_global_pos, 0.3)
		tween.tween_property(piece, "rotation_degrees", target.target_rotation, 0.3)

		# For scalable cubes, we don't tween scale (they handle size via mesh)
		# Just set the mesh/collision size directly
		if piece.has_method("get_scale_vector"):
			_set_piece_size(piece, target.target_scale)
		else:
			tween.tween_property(piece, "scale", target.target_scale, 0.3)


## Set the size of a scalable cube piece
func _set_piece_size(piece: Node3D, size: Vector3) -> void:
	# Update mesh size
	var mesh_instance = piece.get_node_or_null("MeshInstance3D")
	if mesh_instance and mesh_instance.mesh is BoxMesh:
		var box_mesh = mesh_instance.mesh as BoxMesh
		# Duplicate if shared resource
		if not box_mesh.resource_local_to_scene:
			box_mesh = box_mesh.duplicate()
			mesh_instance.mesh = box_mesh
		box_mesh.size = size

	# Update collision shape size
	var collision = piece.get_node_or_null("CollisionShape3D")
	if collision and collision.shape is BoxShape3D:
		var box_shape = collision.shape as BoxShape3D
		# Duplicate if shared resource
		if not box_shape.resource_local_to_scene:
			box_shape = box_shape.duplicate()
			collision.shape = box_shape
		box_shape.size = size


## Lock all pieces (freeze rigid bodies)
func _lock_all_pieces() -> void:
	for piece_id in puzzle_pieces:
		var piece = puzzle_pieces[piece_id]
		if piece is RigidBody3D:
			piece.freeze = true

		# Disable pickable if it's an XRToolsPickable
		if piece.has_method("set") and "enabled" in piece:
			piece.enabled = false


## Play completion sound - subtle confirmation
func _play_completion_sound() -> void:
	if not has_node("/root/SoundBank"):
		return

	var sound_bank = get_node("/root/SoundBank")
	var sound_stream = sound_bank.get_sound("AudioSynthesizer.POWER_UP_JINGLE")

	if not sound_stream:
		return

	var player = AudioStreamPlayer3D.new()
	player.stream = sound_stream
	player.volume_db = -6.0  # Quieter
	player.max_distance = 15.0
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC
	add_child(player)
	if is_inside_tree():
		player.global_position = global_position

	player.finished.connect(player.queue_free)
	player.play()
	
	# Limit duration
	get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	)


## Reset the puzzle
func reset_puzzle() -> void:
	is_completed = false
	current_state = PuzzleState.BUILDING

	# Unlock pieces
	for piece_id in puzzle_pieces:
		var piece = puzzle_pieces[piece_id]
		if piece is RigidBody3D:
			piece.freeze = false
		if piece.has_method("set") and "enabled" in piece:
			piece.enabled = true

	# Reset proximity and piece tracking
	for piece_id in piece_proximity:
		piece_proximity[piece_id] = false
	for piece_id in pieces_used:
		pieces_used[piece_id] = false
	piece_snapped.clear()
	piece_snap_timers.clear()

	# Show ghost guides
	if ghost_container:
		ghost_container.visible = show_ghost_guides

	# Reset ghost colors
	for piece_id in ghost_guides:
		_update_ghost_color(piece_id, false)

	# Hide success label
	if success_label:
		success_label.visible = false


## Get completion percentage
func get_completion_percentage() -> float:
	if piece_targets.is_empty():
		return 0.0

	var pieces_at_target = 0
	for piece_id in piece_proximity:
		if piece_proximity[piece_id]:
			pieces_at_target += 1

	return float(pieces_at_target) / float(piece_targets.size())


## Find the GridScene node to add objects to
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
