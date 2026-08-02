extends TransformPuzzleBase
class_name FurnitureAssemblyPuzzle

# @identity
# essence: place_and_scale(cube_pieces) to match holographic ghost guides — transformations as furniture assembly
# desire: learner discovers that scale, rotate, and translate together are sufficient to build any rectangular form
# critical_parameter: furniture_type enum — selects which target configuration (CHAIR/STOOL/TABLE/SHELF/CUSTOM)
# triggers: snapping a piece to its ghost guide — piece locks with a pulse effect; all snapped → grow animation
# emerges: Judd's insight made playable: "a chair is just rectangles with the right transforms"
# needs: [has grab_cube_scalable pieces [has], has ghost holographic guides [has], missing undo/reset button]
# relationships: extends TransformPuzzleBase; used in Trans_Scale as chair_assembly_puzzle artifact
# truth: all furniture is transformation applied to a primitive — the cube is the universal raw material

# ─────────────────────────────────────────────────────────────────────────────
# ONE SCENE, FOUR REGISTRY NAMES. chair_assembly_puzzle.tscn is also registered as
# shelf_assembly_puzzle, stool_assembly_puzzle and table_assembly_puzzle — one
# script, one scene, four tokens that differ only by furniture_type. They are a
# family and take ONE axis, so they are meant to measure alike.
#
#   tell   WHAT THE PUZZLE DISCLOSES OF ITS ANSWER   ghost · none · mark · exemplar
#
#   ghost     the legacy lineage, byte for byte — every piece pre-shown as a
#             translucent cyan hologram at full size, in place, correctly rotated
#   none      nothing: loose cubes on a workbench and no clue what they make
#   mark      where, not what — a thin stake to each target with a bright head at
#             the exact point; position disclosed, size and shape withheld
#   exemplar  the answer stood up in solid wood at the targets, next to the cubes
#             you must still transform to match it
#
# This is the puzzle's real argument, not the solving of it: a puzzle that shows
# you the finished chair is a different teacher from one that shows you six glowing
# boxes, and both are different from one that shows you nothing at all. `furniture_type`
# says WHICH thing; `tell` says how much of it you are allowed to know in advance.
#
# Deliberately NOT routed through tell: the targets themselves, their tolerances,
# and the snap logic. What has to be built and how close is close enough are the
# same at every value — only the disclosure changes, so the axis cannot make the
# puzzle easier to pass, just easier or harder to read.
# ─────────────────────────────────────────────────────────────────────────────

## FurnitureAssemblyPuzzle - Assembly puzzles for furniture (chair, table, etc.)
##
## Inspired by Donald Judd's furniture: complex forms from simple rectangles.
## "A chair is just rectangles with the right transforms."
##
## Players scale, rotate, and position cube pieces to match holographic guides.
## Clean Alyx-style completion - pieces snap with satisfying pulse, no text.

## Furniture type presets
enum FurnitureType {
	CHAIR,
	STOOL,
	TABLE,
	SHELF,
	CUSTOM
}


## Furniture Configuration
@export_group("Furniture Configuration")
@export var furniture_type: FurnitureType = FurnitureType.CHAIR

## AXIS — WHAT THE PUZZLE DISCLOSES OF ITS ANSWER before you have solved it. Shared word for
## word with [[balance_puzzle]] and [[configurable_portal]]: one vocabulary for "how much of
## the far side is shown in advance". Only the disclosure changes; the targets, the
## tolerances and the snap are identical at every value.
##
##   ghost     the legacy lineage — every piece pre-shown as a translucent cyan hologram
##   none      nothing at all — loose cubes and no clue what they make
##   mark      where, not what — a stake to each target with a bright head at the point
##   exemplar  the answer in solid wood, standing at the targets beside the raw cubes
@export var tell: String = "ghost"
const TELLS: PackedStringArray = ["ghost", "none", "mark", "exemplar"]
@export var model_scale: float = 0.3  # Working scale (tabletop size)
@export var final_scale: float = 1.0  # Real furniture size
@export var grow_on_complete: bool = true
@export var grow_duration: float = 1.5
@export var final_position_offset: Vector3 = Vector3(0, 0, 1.5)  # Where grown furniture lands

## Piece Configuration
@export_group("Piece Configuration")
@export var piece_scene: PackedScene  # Scene to use for pieces (grab_cube_scalable)
@export var auto_spawn_pieces: bool = true  # Spawn pieces automatically
@export var workbench_offset: Vector3 = Vector3(0.3, 0.1, 0.3)  # Where pieces start (centered on 1x1 platform)
@export var extra_pieces: int = 3  # Extra cubes in case some fall off
## Freeze the spawned cubes where they are laid out. Default false = the legacy lineage: the
## pieces are live XR pickables and fall the moment they exist, which in a map is caught by
## the floor and in a headless capture is not — they drop several metres in the settle and
## drag the framing down with them. A capture rig should set this; a map never needs to.
@export var pieces_static: bool = false

## Reward Configuration
@export_group("Reward")
@export var reward_chair_scene: PackedScene  # Premade chair to spawn on completion
@export var reward_scale: float = 1.2  # Scale of the reward chair (slightly bigger)

## Internal state
var furniture_pieces: Array[Node3D] = []  # Original spawned cubes (will be freed on snap)
var final_pieces: Array[Node3D] = []  # Wood meshes created when snapped
var assembled_furniture: Node3D = null
var piece_spawn_positions: Array[Vector3] = []

## Signals
signal furniture_assembled()
signal furniture_grown(final_position: Vector3)


func _ready() -> void:
	# Ensure clean state on load (reset any persisted state)
	furniture_pieces.clear()
	final_pieces.clear()
	assembled_furniture = null
	piece_spawn_positions.clear()

	# Define targets based on furniture type
	_setup_furniture_targets()

	# Call parent ready (sets up ghost guides, etc.)
	super()

	# Connect to final piece signal to track wood meshes
	final_piece_created.connect(_on_final_piece_created)

	# Spawn pieces if enabled
	if auto_spawn_pieces and piece_scene:
		call_deferred("_spawn_pieces")


## Setup targets based on furniture type
func _setup_furniture_targets() -> void:
	match furniture_type:
		FurnitureType.CHAIR:
			_setup_chair_targets()
		FurnitureType.STOOL:
			_setup_stool_targets()
		FurnitureType.TABLE:
			_setup_table_targets()
		FurnitureType.SHELF:
			_setup_shelf_targets()
		FurnitureType.CUSTOM:
			# Child class should define custom targets
			pass


## Chair: Judd-style minimal chair (6 pieces)
## Seat + 4 legs + back
## Using achievable dimensions based on scale snap values [0.25, 0.5, 0.75, 1, 1.25, 1.5, 2, 3, 4]
## multiplied by base cube size 0.1m = [0.025, 0.05, 0.075, 0.1, 0.125, 0.15, 0.2, 0.3, 0.4]m
func _setup_chair_targets() -> void:
	# Chair is ~45cm seat height, ~40cm wide, ~40cm deep

	# Seat - wide, flat rectangle
	# 0.4m x 0.05m x 0.4m = 4x, 0.5x, 4x scale
	var seat = PieceTarget.new("seat",
		Vector3(0, 0.45, 0),           # Position: centered, at seat height
		Vector3.ZERO,                   # Rotation: flat
		Vector3(0.4, 0.05, 0.4)         # Scale: wide (4x), thin (0.5x), deep (4x)
	)
	seat.position_tolerance = 0.08
	seat.rotation_tolerance = 15.0
	seat.scale_tolerance = 0.03  # Tight tolerance for scale
	piece_targets.append(seat)

	# Four legs - tall, thin rectangles
	# 0.05m x 0.4m x 0.05m = 0.5x, 4x, 0.5x scale
	var leg_offset = 0.175  # Half of seat width minus half of leg width
	var leg_y = 0.225  # Half of leg height + small offset
	var leg_positions = [
		Vector3(-leg_offset, leg_y, leg_offset),   # Front left
		Vector3(leg_offset, leg_y, leg_offset),    # Front right
		Vector3(-leg_offset, leg_y, -leg_offset),  # Back left
		Vector3(leg_offset, leg_y, -leg_offset),   # Back right
	]

	for i in range(4):
		var leg = PieceTarget.new("leg_%d" % i,
			leg_positions[i],
			Vector3.ZERO,
			Vector3(0.05, 0.4, 0.05)  # Thin (0.5x), tall (4x), thin (0.5x)
		)
		leg.position_tolerance = 0.06
		leg.rotation_tolerance = 15.0
		leg.scale_tolerance = 0.03
		piece_targets.append(leg)

	# Back - tall rectangle behind seat
	# 0.3m x 0.4m x 0.05m = 3x, 4x, 0.5x scale
	var back = PieceTarget.new("back",
		Vector3(0, 0.67, -leg_offset),  # Position: centered, above seat, at back edge
		Vector3.ZERO,                   # Rotation: vertical
		Vector3(0.3, 0.4, 0.05)         # Scale: wide (3x), tall (4x), thin (0.5x)
	)
	back.position_tolerance = 0.08
	back.rotation_tolerance = 15.0
	back.scale_tolerance = 0.03
	piece_targets.append(back)

	print("FurnitureAssemblyPuzzle: Setup %d chair targets" % piece_targets.size())


## Stool: Simple seat + legs (5 pieces)
func _setup_stool_targets() -> void:
	# Seat
	var seat = PieceTarget.new("seat",
		Vector3(0, 0.45, 0),
		Vector3.ZERO,
		Vector3(0.35, 0.04, 0.35)
	)
	piece_targets.append(seat)

	# Four legs
	var leg_positions = [
		Vector3(-0.12, 0.22, 0.12),
		Vector3(0.12, 0.22, 0.12),
		Vector3(-0.12, 0.22, -0.12),
		Vector3(0.12, 0.22, -0.12),
	]

	for i in range(4):
		var leg = PieceTarget.new("leg_%d" % i,
			leg_positions[i],
			Vector3.ZERO,
			Vector3(0.04, 0.44, 0.04)
		)
		piece_targets.append(leg)


## Table: Flat top + legs (5 pieces)
func _setup_table_targets() -> void:
	# Table top
	var top = PieceTarget.new("top",
		Vector3(0, 0.75, 0),
		Vector3.ZERO,
		Vector3(0.6, 0.04, 0.4)
	)
	piece_targets.append(top)

	# Four legs
	var leg_positions = [
		Vector3(-0.26, 0.36, 0.16),
		Vector3(0.26, 0.36, 0.16),
		Vector3(-0.26, 0.36, -0.16),
		Vector3(0.26, 0.36, -0.16),
	]

	for i in range(4):
		var leg = PieceTarget.new("leg_%d" % i,
			leg_positions[i],
			Vector3.ZERO,
			Vector3(0.04, 0.72, 0.04)
		)
		piece_targets.append(leg)


## Shelf: Simple shelf with just 3 pieces (2 supports + 1 shelf)
## Using larger, easier-to-scale dimensions
func _setup_shelf_targets() -> void:
	# Two vertical supports - simple tall blocks
	var support_left = PieceTarget.new("support_left",
		Vector3(-0.20, 0.25, 0),
		Vector3.ZERO,
		Vector3(0.08, 0.5, 0.15)  # Thicker, easier to scale
	)
	support_left.position_tolerance = 0.10
	support_left.rotation_tolerance = 20.0
	support_left.scale_tolerance = 0.04
	piece_targets.append(support_left)

	var support_right = PieceTarget.new("support_right",
		Vector3(0.20, 0.25, 0),
		Vector3.ZERO,
		Vector3(0.08, 0.5, 0.15)  # Same as left
	)
	support_right.position_tolerance = 0.10
	support_right.rotation_tolerance = 20.0
	support_right.scale_tolerance = 0.04
	piece_targets.append(support_right)

	# One horizontal shelf - simple flat piece
	var shelf = PieceTarget.new("shelf_0",
		Vector3(0, 0.52, 0),
		Vector3.ZERO,
		Vector3(0.48, 0.06, 0.15)  # Wide, thick enough to scale easily
	)
	shelf.position_tolerance = 0.10
	shelf.rotation_tolerance = 20.0
	shelf.scale_tolerance = 0.04
	piece_targets.append(shelf)

	print("FurnitureAssemblyPuzzle: Setup %d simple shelf targets" % piece_targets.size())


## Spawn pieces at workbench positions
func _spawn_pieces() -> void:
	if not piece_scene:
		push_error("FurnitureAssemblyPuzzle: No piece_scene assigned!")
		return

	# Calculate spawn positions (laid out on workbench) - include extra pieces
	var total_pieces = piece_targets.size() + extra_pieces
	_calculate_spawn_positions(total_pieces)

	# Spawn pieces for each target
	for i in range(piece_targets.size()):
		var target = piece_targets[i]
		var spawn_pos = piece_spawn_positions[i] if i < piece_spawn_positions.size() else workbench_offset + Vector3(i * 0.15, 0, 0)

		# Instantiate piece
		var piece = piece_scene.instantiate()
		piece.name = "Piece_" + target.piece_id
		add_child(piece)

		# Set initial position (on workbench)
		piece.position = spawn_pos

		# Set initial scale (start at 1.0, player scales to match target)
		piece.scale = Vector3.ONE * 0.1  # Base cube size

		# If it's a scalable cube, set initial scale index
		if piece.has_method("set_scale_index"):
			piece.set_scale_index(2)  # 1.0x

		# Hold the piece on the bench for a still capture (default off — see pieces_static).
		if pieces_static and piece is RigidBody3D:
			(piece as RigidBody3D).freeze = true

		# Register with puzzle system
		register_piece(target.piece_id, piece)
		furniture_pieces.append(piece)

		print("FurnitureAssemblyPuzzle: Spawned piece '%s' at %v" % [target.piece_id, spawn_pos])

	# Spawn extra pieces (spares in case some fall)
	for i in range(extra_pieces):
		var spawn_idx = piece_targets.size() + i
		var spawn_pos = piece_spawn_positions[spawn_idx] if spawn_idx < piece_spawn_positions.size() else workbench_offset + Vector3(spawn_idx * 0.15, 0, 0)

		var piece = piece_scene.instantiate()
		piece.name = "Piece_extra_%d" % i
		add_child(piece)

		piece.position = spawn_pos
		piece.scale = Vector3.ONE * 0.1

		if piece.has_method("set_scale_index"):
			piece.set_scale_index(2)

		if pieces_static and piece is RigidBody3D:
			(piece as RigidBody3D).freeze = true

		# Register extra pieces with unique IDs
		register_piece("extra_%d" % i, piece)
		furniture_pieces.append(piece)

		print("FurnitureAssemblyPuzzle: Spawned extra piece 'extra_%d' at %v" % [i, spawn_pos])


## Calculate where to spawn pieces (laid out nicely)
func _calculate_spawn_positions(total_count: int = -1) -> void:
	piece_spawn_positions.clear()

	var num_pieces = total_count if total_count > 0 else piece_targets.size()
	var cols = ceili(sqrt(num_pieces))
	var spacing = 0.15

	for i in range(num_pieces):
		var row = i / cols
		var col = i % cols
		var pos = workbench_offset + Vector3(col * spacing, 0.05, row * spacing)
		piece_spawn_positions.append(pos)


## Called when a final wood piece is created (from base class signal)
func _on_final_piece_created(piece: Node3D, target_id: String) -> void:
	final_pieces.append(piece)
	print("FurnitureAssemblyPuzzle: Tracking final piece for '%s' (total: %d)" % [target_id, final_pieces.size()])


## Override completion to add grow animation
func _complete_puzzle() -> void:
	# Call parent completion first
	await super()

	# Grow animation if enabled
	if grow_on_complete:
		await _grow_to_final_size()


## Make assembled furniture into a grabbable object - clean transition
func _grow_to_final_size() -> void:
	print("FurnitureAssemblyPuzzle: Spawning reward...")

	# Calculate center of assembled pieces for positioning reward
	var center = Vector3.ZERO
	var valid_count = 0

	for piece in final_pieces:
		if is_instance_valid(piece):
			center += piece.global_position
			valid_count += 1

	if valid_count > 0:
		center /= valid_count
	else:
		center = global_position

	# Remove all remaining cubes (unused pieces)
	_remove_remaining_cubes()

	# Remove the assembled wood pieces (we're replacing with premade chair)
	for piece in final_pieces:
		if is_instance_valid(piece):
			piece.queue_free()
	final_pieces.clear()

	# Spawn the reward chair
	if reward_chair_scene:
		assembled_furniture = reward_chair_scene.instantiate()
	else:
		# Fallback: load throne chair
		var throne_scene = load("res://commons/primitives/chair/chair_throne.tscn")
		if throne_scene:
			assembled_furniture = throne_scene.instantiate()
		else:
			push_warning("FurnitureAssemblyPuzzle: No reward chair scene!")
			furniture_assembled.emit()
			return

	assembled_furniture.name = "RewardChair"

	# Find grid scene to add reward to
	var grid_scene = _find_grid_scene()
	if grid_scene:
		grid_scene.add_child(assembled_furniture)
	else:
		get_parent().add_child(assembled_furniture)

	# Position at center of the assembled pieces, on the ground
	assembled_furniture.global_position = Vector3(center.x, global_position.y, center.z)
	assembled_furniture.scale = Vector3.ONE * reward_scale

	furniture_assembled.emit()
	furniture_grown.emit(assembled_furniture.global_position)

	print("FurnitureAssemblyPuzzle: Reward chair spawned at %v (scale: %.1f)" % [assembled_furniture.global_position, reward_scale])


## Remove all remaining cubes that weren't used
func _remove_remaining_cubes() -> void:
	print("FurnitureAssemblyPuzzle: Removing %d remaining cubes..." % furniture_pieces.size())
	for piece in furniture_pieces:
		if is_instance_valid(piece):
			piece.queue_free()
	furniture_pieces.clear()


## Add a custom piece target
func add_piece_target(piece_id: String, pos: Vector3, rot: Vector3, scl: Vector3) -> void:
	var target = PieceTarget.new(piece_id, pos, rot, scl)
	piece_targets.append(target)


## Get furniture type as string
func get_furniture_type_name() -> String:
	match furniture_type:
		FurnitureType.CHAIR:
			return "Chair"
		FurnitureType.STOOL:
			return "Stool"
		FurnitureType.TABLE:
			return "Table"
		FurnitureType.SHELF:
			return "Shelf"
		FurnitureType.CUSTOM:
			return "Custom"
	return "Unknown"


## Override completion sound to play for only 3 seconds
func _play_completion_sound() -> void:
	if not has_node("/root/SoundBank"):
		return

	var sound_bank = get_node("/root/SoundBank")
	var sound_stream = sound_bank.get_sound("AudioSynthesizer.POWER_UP_JINGLE")

	if not sound_stream:
		return

	var player = AudioStreamPlayer3D.new()
	player.stream = sound_stream
	player.volume_db = 0.0
	player.max_distance = 20.0
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC
	add_child(player)

	if is_inside_tree():
		player.global_position = global_position

	player.finished.connect(player.queue_free)
	player.play()


## Apply configuration from grid system / artifact registry
## Accepts explicit names: "chair", "stool", "table", "shelf" or numbers
func apply_grid_config(config_data: Dictionary) -> void:
	print("FurnitureAssemblyPuzzle: Applying config: %s" % config_data)

	# AXIS — read BEFORE the furniture_type branch so a token that sets both rebuilds once.
	# An unknown word keeps the current value rather than silently building a different puzzle.
	var tell_changed: bool = false
	if config_data.has("tell"):
		var t: String = str(config_data["tell"]).strip_edges().to_lower()
		if TELLS.has(t) and t != tell:
			tell = t
			tell_changed = true

	if config_data.has("furniture_type"):
		var new_type = _parse_furniture_type(config_data["furniture_type"])
		if new_type != furniture_type:
			furniture_type = new_type
			_rebuild_for_new_type()
			tell_changed = false          # that rebuild already re-ran the guides at the new tell

	if tell_changed:
		_rebuild_tell()


## Parse furniture type from string name or number
func _parse_furniture_type(value) -> FurnitureType:
	if value is int:
		return value as FurnitureType

	var type_str = str(value).to_lower().strip_edges()

	match type_str:
		"chair", "0":
			return FurnitureType.CHAIR
		"stool", "1":
			return FurnitureType.STOOL
		"table", "2":
			return FurnitureType.TABLE
		"shelf", "3":
			return FurnitureType.SHELF
		"custom", "4":
			return FurnitureType.CUSTOM
		_:
			# Try parsing as int
			if type_str.is_valid_int():
				return int(type_str) as FurnitureType
			push_warning("FurnitureAssemblyPuzzle: Unknown furniture_type '%s', defaulting to CHAIR" % value)
			return FurnitureType.CHAIR


## Rebuild puzzle for a new furniture type
func _rebuild_for_new_type() -> void:
	# Clear existing pieces
	for piece in furniture_pieces:
		if is_instance_valid(piece):
			piece.queue_free()
	furniture_pieces.clear()

	for piece in final_pieces:
		if is_instance_valid(piece):
			piece.queue_free()
	final_pieces.clear()

	# Clear existing ghosts
	for ghost_id in ghost_guides.keys():
		var ghost = ghost_guides[ghost_id]
		if is_instance_valid(ghost):
			ghost.queue_free()
	ghost_guides.clear()

	# Clear targets
	piece_targets.clear()

	# Setup new targets
	_setup_furniture_targets()

	# Rebuild ghosts
	_setup_ghost_guides()

	# Respawn pieces if auto-spawn enabled
	if auto_spawn_pieces and piece_scene:
		call_deferred("_spawn_pieces")

	print("FurnitureAssemblyPuzzle: Rebuilt for %s" % get_furniture_type_name())


# ── TELL ─────────────────────────────────────────────────────────────────────
# What the puzzle discloses of its answer. Appended LAST, and the default value
# calls straight through to the parent, so the legacy lineage runs the same code
# it always did — the ghosts are built by TransformPuzzleBase, untouched.

func _setup_ghost_guides() -> void:
	_clear_tell_nodes()
	match tell:
		"none":
			pass                                  # the workbench, and nothing else
		"mark":
			_tell_mark()
		"exemplar":
			_tell_exemplar()
		_:
			super()                               # "ghost" — the legacy lineage


## Drop anything a previous tell built, so switching values in a live map does not stack
## two disclosures on top of each other. Ghost guides are tracked separately, in ghost_guides.
func _clear_tell_nodes() -> void:
	if not ghost_container:
		return
	for c in ghost_container.get_children():
		if str(c.name).begins_with("Tell_"):
			ghost_container.remove_child(c)
			c.queue_free()


## MARK — where, not what. Each target gets its plan drawn on the ground as a bright outline
## the size of the piece's footprint, and a thin stake standing up to a small bright head at
## the exact target point. You are told where every piece goes and how high it sits; you are
## told nothing about how big it is or which way round it faces.
func _tell_mark() -> void:
	if not ghost_container:
		return
	var lit := StandardMaterial3D.new()
	lit.albedo_color = Color(ghost_color.r, ghost_color.g, ghost_color.b, 1.0)
	lit.emission_enabled = true
	lit.emission = Color(ghost_color.r, ghost_color.g, ghost_color.b, 1.0)
	lit.emission_energy_multiplier = ghost_emission_energy * 1.6
	lit.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var stem_mat := StandardMaterial3D.new()
	stem_mat.albedo_color = Color(0.10, 0.12, 0.15)
	stem_mat.roughness = 0.85

	for target in piece_targets:
		var p: Vector3 = target.target_position
		var holder := Node3D.new()
		holder.name = "Tell_mark_" + target.piece_id
		holder.position = Vector3(p.x, 0.0, p.z)
		ghost_container.add_child(holder)
		# The plan on the floor: four thin bars outlining the piece's footprint.
		var fx: float = maxf(target.target_scale.x, 0.03)
		var fz: float = maxf(target.target_scale.z, 0.03)
		var t: float = 0.008
		holder.add_child(_tell_box(Vector3(0, 0.003, fz * 0.5), Vector3(fx + t, 0.005, t), lit))
		holder.add_child(_tell_box(Vector3(0, 0.003, -fz * 0.5), Vector3(fx + t, 0.005, t), lit))
		holder.add_child(_tell_box(Vector3(fx * 0.5, 0.003, 0), Vector3(t, 0.005, fz + t), lit))
		holder.add_child(_tell_box(Vector3(-fx * 0.5, 0.003, 0), Vector3(t, 0.005, fz + t), lit))
		# The stake: a dark stem up to a small bright head sitting exactly at the target point.
		var stem_h: float = maxf(p.y, 0.02)
		holder.add_child(_tell_box(Vector3(0, stem_h * 0.5, 0), Vector3(0.007, stem_h, 0.007), stem_mat))
		holder.add_child(_tell_box(Vector3(0, stem_h, 0), Vector3(0.032, 0.032, 0.032), lit))


## EXEMPLAR — the answer stood up. Every target is built as a solid wood piece, in place, at
## full size, using the very mesh the puzzle makes when a piece snaps. The finished furniture
## stands there while the raw cubes still sit on the workbench beside it: you are shown the
## whole answer and still have to perform the transformations that reach it.
func _tell_exemplar() -> void:
	if not ghost_container:
		return
	for target in piece_targets:
		var solid: MeshInstance3D = _create_final_piece(target)
		if not solid:
			continue
		solid.name = "Tell_exemplar_" + target.piece_id
		ghost_container.add_child(solid)
		solid.position = target.target_position
		solid.rotation_degrees = target.target_rotation


## Rebuild the disclosure after a live `tell` change (map token / apply_grid_config).
func _rebuild_tell() -> void:
	for ghost_id in ghost_guides.keys():
		var ghost = ghost_guides[ghost_id]
		if is_instance_valid(ghost):
			ghost.queue_free()
	ghost_guides.clear()
	_setup_ghost_guides()


func _tell_box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi
