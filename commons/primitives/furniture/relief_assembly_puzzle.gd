extends TransformPuzzleBase
class_name ReliefAssemblyPuzzle

## ReliefAssemblyPuzzle - Constructivist relief compositions
##
## Inspired by Charles Biederman's painted reliefs: rectangular bars
## at varying depths creating dynamic spatial compositions.
##
## Players scale and position bars to match ghost guides on a vertical plane.
## Each bar has a specific color, position, and depth (Z projection).

## Relief type presets
enum ReliefType {
	BIEDERMAN,        # Horizontal bars, varied depths, primary colors
	MONDRIAN,         # Grid-based, right angles, De Stijl colors
	ALBERS,           # Nested rectangles, color study
	CONSTRUCTIVIST,   # Dynamic diagonals, Soviet poster style
	CUSTOM
}

## Relief Configuration
@export_group("Relief Configuration")
@export var relief_type: ReliefType = ReliefType.BIEDERMAN
@export var backing_color: Color = Color(0.1, 0.55, 0.9)  # Biederman blue
@export var show_backing_plane: bool = true
@export var backing_size: Vector2 = Vector2(1.0, 1.2)  # Width x Height

## Piece Configuration
@export_group("Piece Configuration")
@export var piece_scene: PackedScene
@export var auto_spawn_pieces: bool = true
@export var use_direct_mesh: bool = true  # Create pieces as direct box meshes (matches ghost size exactly)
@export var workbench_offset: Vector3 = Vector3(0.35, 0.1, 0.25)  # Moved back to stay on platform
@export var extra_pieces: int = 3
@export var pieces_all_white: bool = true  # Make all pieces white (neutral) for placement

## Color Palette (Biederman-style)
@export_group("Color Palette")
@export var palette: Array[Color] = [
	Color(0.9, 0.15, 0.15),   # Red
	Color(0.95, 0.85, 0.1),   # Yellow
	Color(0.15, 0.65, 0.15),  # Green
	Color(0.15, 0.15, 0.85),  # Blue
	Color(0.95, 0.5, 0.1),    # Orange
	Color(0.75, 0.25, 0.75),  # Magenta
	Color(0.1, 0.1, 0.1),     # Black
	Color(0.95, 0.95, 0.95),  # White
]

## Internal state
var relief_pieces: Array[Node3D] = []
var final_pieces: Array[Node3D] = []
var backing_plane: MeshInstance3D
var piece_colors: Dictionary = {}  # piece_id -> Color
var piece_spawn_positions: Array[Vector3] = []

## Signals
signal relief_assembled()


func _ready() -> void:
	relief_pieces.clear()
	final_pieces.clear()
	piece_colors.clear()
	piece_spawn_positions.clear()

	# Create backing plane first
	if show_backing_plane:
		_create_backing_plane()

	# Define targets based on relief type
	_setup_relief_targets()

	# Call parent ready
	super()

	# Connect to final piece signal
	final_piece_created.connect(_on_final_piece_created)

	# Spawn pieces if enabled
	if auto_spawn_pieces and piece_scene:
		call_deferred("_spawn_pieces")


func _create_backing_plane() -> void:
	backing_plane = MeshInstance3D.new()
	backing_plane.name = "BackingPlane"

	var quad = QuadMesh.new()
	quad.size = backing_size
	backing_plane.mesh = quad

	var mat = StandardMaterial3D.new()
	mat.albedo_color = backing_color
	mat.roughness = 0.9
	mat.metallic = 0.0
	backing_plane.material_override = mat

	# Position at back (Z = 0), facing forward
	backing_plane.position = Vector3(0, backing_size.y / 2, 0)

	add_child(backing_plane)


func _setup_relief_targets() -> void:
	match relief_type:
		ReliefType.BIEDERMAN:
			_setup_biederman_targets()
		ReliefType.MONDRIAN:
			_setup_mondrian_targets()
		ReliefType.ALBERS:
			_setup_albers_targets()
		ReliefType.CONSTRUCTIVIST:
			_setup_constructivist_targets()
		ReliefType.CUSTOM:
			pass


## Biederman-style: Mix of horizontal and vertical bars at various depths
## Dimensions match snap scale values: 0.05, 0.075, 0.1, 0.125, 0.15, 0.2, 0.3, 0.4
func _setup_biederman_targets() -> void:
	# Bar definitions: [id, x, y, z_depth, width, height, color_index]
	# Using dimensions that match snap values (base 0.1 * scale_snap_values)
	var bars = [
		# Horizontal bars (width 0.3 or 0.4, height 0.05)
		["bar_h1", -0.05, 0.85, 0.08, 0.3, 0.05, 0],   # Red - top horizontal
		["bar_h2", 0.0, 0.55, 0.12, 0.4, 0.05, 1],     # Yellow - middle horizontal
		["bar_h3", -0.10, 0.20, 0.06, 0.3, 0.05, 3],   # Blue - bottom horizontal

		# Vertical bars (width 0.05, height 0.3 or 0.2)
		["bar_v1", -0.28, 0.50, 0.10, 0.05, 0.3, 2],   # Green - left vertical
		["bar_v2", 0.28, 0.60, 0.14, 0.05, 0.3, 4],    # Orange - right vertical
		["bar_v3", 0.12, 0.32, 0.08, 0.05, 0.2, 5],    # Magenta - small vertical
	]

	for bar in bars:
		var target = PieceTarget.new(
			bar[0],                                      # id
			Vector3(bar[1], bar[2], bar[3]),            # position (x, y, z_depth)
			Vector3.ZERO,                                # rotation (flat)
			Vector3(bar[4], bar[5], 0.05)               # scale (width, height, thickness)
		)
		target.position_tolerance = 0.08
		target.rotation_tolerance = 25.0
		target.scale_tolerance = 0.02  # Slightly more forgiving
		piece_targets.append(target)
		piece_colors[bar[0]] = palette[bar[6]]

	print("ReliefAssemblyPuzzle: Setup %d Biederman targets" % piece_targets.size())


## Mondrian-style: Grid-based, De Stijl primary colors
func _setup_mondrian_targets() -> void:
	# Primary colors only: red, yellow, blue, black, white
	var mondrian_palette = [
		Color(0.9, 0.1, 0.1),   # Red
		Color(0.95, 0.85, 0.1), # Yellow
		Color(0.1, 0.2, 0.7),   # Blue
		Color(0.05, 0.05, 0.05),# Black
		Color(0.95, 0.95, 0.9), # Off-white
	]

	var bars = [
		# Vertical black lines
		["v_01", -0.25, 0.5, 0.03, 0.02, 0.8, 3],
		["v_02", 0.10, 0.5, 0.03, 0.02, 0.8, 3],
		["v_03", 0.30, 0.5, 0.03, 0.02, 0.6, 3],
		# Horizontal black lines
		["h_01", 0.0, 0.75, 0.03, 0.7, 0.02, 3],
		["h_02", 0.0, 0.35, 0.03, 0.7, 0.02, 3],
		# Color blocks
		["r_01", -0.35, 0.85, 0.05, 0.15, 0.15, 0],  # Red
		["y_01", 0.35, 0.55, 0.05, 0.12, 0.25, 1],   # Yellow
		["b_01", -0.10, 0.15, 0.05, 0.25, 0.20, 2],  # Blue
	]

	for bar in bars:
		var target = PieceTarget.new(
			bar[0],
			Vector3(bar[1], bar[2], bar[3]),
			Vector3.ZERO,
			Vector3(bar[4], bar[5], 0.03)
		)
		target.position_tolerance = 0.05
		target.scale_tolerance = 0.015
		piece_targets.append(target)
		piece_colors[bar[0]] = mondrian_palette[bar[6]]


## Albers-style: Nested squares, color interaction study
func _setup_albers_targets() -> void:
	var albers_palette = [
		Color(0.85, 0.35, 0.15),  # Warm orange
		Color(0.75, 0.55, 0.25),  # Gold
		Color(0.55, 0.45, 0.35),  # Warm brown
		Color(0.35, 0.35, 0.45),  # Cool gray
	]

	# Nested squares from outer to inner
	var squares = [
		["sq_01", 0.0, 0.5, 0.02, 0.5, 0.5, 0],
		["sq_02", 0.0, 0.48, 0.04, 0.38, 0.38, 1],
		["sq_03", 0.0, 0.46, 0.06, 0.26, 0.26, 2],
		["sq_04", 0.0, 0.44, 0.08, 0.14, 0.14, 3],
	]

	for sq in squares:
		var target = PieceTarget.new(
			sq[0],
			Vector3(sq[1], sq[2], sq[3]),
			Vector3.ZERO,
			Vector3(sq[4], sq[5], 0.02)
		)
		target.position_tolerance = 0.04
		target.scale_tolerance = 0.02
		piece_targets.append(target)
		piece_colors[sq[0]] = albers_palette[sq[6]]


## Constructivist-style: Dynamic diagonals
func _setup_constructivist_targets() -> void:
	var soviet_palette = [
		Color(0.85, 0.15, 0.1),   # Soviet red
		Color(0.1, 0.1, 0.1),     # Black
		Color(0.95, 0.9, 0.85),   # Cream
	]

	# Diagonal bars creating dynamic tension
	var bars = [
		# Main diagonal thrust
		["d_01", 0.0, 0.5, 0.08, 0.6, 0.06, 0, 35],     # Red diagonal
		["d_02", -0.1, 0.55, 0.12, 0.4, 0.04, 1, 35],   # Black parallel
		["d_03", 0.1, 0.45, 0.06, 0.35, 0.03, 2, 35],   # Cream parallel
		# Counter diagonal
		["d_04", 0.15, 0.65, 0.10, 0.3, 0.05, 0, -25],  # Red
		["d_05", 0.20, 0.60, 0.14, 0.25, 0.03, 1, -25], # Black
		# Horizontal accents
		["h_01", -0.2, 0.3, 0.04, 0.25, 0.04, 0, 0],
		["h_02", 0.2, 0.7, 0.04, 0.2, 0.03, 1, 0],
	]

	for bar in bars:
		var rotation = bar[7] if bar.size() > 7 else 0
		var target = PieceTarget.new(
			bar[0],
			Vector3(bar[1], bar[2], bar[3]),
			Vector3(0, 0, rotation),  # Z rotation
			Vector3(bar[4], bar[5], 0.025)
		)
		target.position_tolerance = 0.06
		target.rotation_tolerance = 15.0
		target.scale_tolerance = 0.02
		piece_targets.append(target)
		piece_colors[bar[0]] = soviet_palette[bar[6]]


## Pickable scene for grabbable pieces
var pickable_scene: PackedScene = preload("res://addons/godot-xr-tools/objects/pickable.tscn")


## Create a direct box mesh piece with exact size (no scaling needed)
func _create_direct_mesh_piece(piece_name: String, size: Vector3, color: Color) -> Node3D:
	# Use XR Tools pickable as base for grab functionality
	var piece = pickable_scene.instantiate()
	piece.name = piece_name

	# Make piece float (no gravity)
	if piece is RigidBody3D:
		piece.gravity_scale = 0.0

	# Find and update collision shape
	var collision = piece.get_node_or_null("CollisionShape3D")
	if collision:
		var shape = BoxShape3D.new()
		shape.size = size
		collision.shape = shape

	# Find existing mesh or create new one
	var mesh_instance = piece.get_node_or_null("MeshInstance3D")
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "MeshInstance3D"
		piece.add_child(mesh_instance)

	var box = BoxMesh.new()
	box.size = size  # Use size directly, not as scale
	mesh_instance.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	mesh_instance.material_override = mat

	return piece


## Spawn pieces at workbench
func _spawn_pieces() -> void:
	if not use_direct_mesh and not piece_scene:
		push_error("ReliefAssemblyPuzzle: No piece_scene assigned and use_direct_mesh is false!")
		return

	var total_pieces = piece_targets.size() + extra_pieces
	_calculate_spawn_positions(total_pieces)

	for i in range(piece_targets.size()):
		var target = piece_targets[i]
		var spawn_pos = piece_spawn_positions[i] if i < piece_spawn_positions.size() else workbench_offset + Vector3(i * 0.12, 0, 0)
		var color = Color.WHITE if pieces_all_white else piece_colors.get(target.piece_id, Color.WHITE)

		var piece: Node3D
		if use_direct_mesh:
			# Create box mesh with exact target size
			piece = _create_direct_mesh_piece("Piece_" + target.piece_id, target.target_scale, color)
		else:
			# Use piece_scene and scale it
			piece = piece_scene.instantiate()
			piece.name = "Piece_" + target.piece_id
			piece.scale = target.target_scale
			if piece.has_method("set_scale_index"):
				piece.set_scale_index(2)
			_set_piece_color(piece, color)

		add_child(piece)
		piece.position = spawn_pos

		register_piece(target.piece_id, piece)
		relief_pieces.append(piece)

		print("ReliefAssemblyPuzzle: Spawned piece '%s' size=%s" % [target.piece_id, target.target_scale])

	# Spawn extra pieces (use average target size)
	var avg_size = Vector3(0.15, 0.15, 0.05)  # Default size for extras
	if piece_targets.size() > 0:
		var total_size = Vector3.ZERO
		for t in piece_targets:
			total_size += t.target_scale
		avg_size = total_size / piece_targets.size()

	for i in range(extra_pieces):
		var spawn_idx = piece_targets.size() + i
		var spawn_pos = piece_spawn_positions[spawn_idx] if spawn_idx < piece_spawn_positions.size() else workbench_offset + Vector3(spawn_idx * 0.12, 0, 0)
		var color = Color.WHITE if pieces_all_white else palette[i % palette.size()]

		var piece: Node3D
		if use_direct_mesh:
			piece = _create_direct_mesh_piece("Piece_extra_%d" % i, avg_size, color)
		else:
			piece = piece_scene.instantiate()
			piece.name = "Piece_extra_%d" % i
			piece.scale = avg_size
			if piece.has_method("set_scale_index"):
				piece.set_scale_index(2)
			_set_piece_color(piece, color)

		add_child(piece)
		piece.position = spawn_pos

		register_piece("extra_%d" % i, piece)
		relief_pieces.append(piece)


func _calculate_spawn_positions(total_count: int) -> void:
	piece_spawn_positions.clear()

	var cols = ceili(sqrt(total_count))
	var spacing = 0.12

	for i in range(total_count):
		var row = i / cols
		var col = i % cols
		var pos = workbench_offset + Vector3(col * spacing, 0.02, row * spacing)
		piece_spawn_positions.append(pos)


func _set_piece_color(piece: Node3D, color: Color) -> void:
	# Find the mesh instance and set color
	var mesh_instance = piece.get_node_or_null("MeshInstance3D")
	if not mesh_instance:
		for child in piece.get_children():
			if child is MeshInstance3D:
				mesh_instance = child
				break

	if mesh_instance:
		var mat = mesh_instance.material_override
		if mat is ShaderMaterial:
			mat.set_shader_parameter("modelColor", color)
		elif mat is StandardMaterial3D:
			mat.albedo_color = color
		else:
			var new_mat = StandardMaterial3D.new()
			new_mat.albedo_color = color
			mesh_instance.material_override = new_mat


func _on_final_piece_created(piece: Node3D, target_id: String) -> void:
	final_pieces.append(piece)

	# Apply the correct color to the final piece
	var color = piece_colors.get(target_id, Color.WHITE)
	_apply_final_piece_color(piece, color)

	print("ReliefAssemblyPuzzle: Final piece for '%s' with color %s" % [target_id, color])


func _apply_final_piece_color(piece: MeshInstance3D, color: Color) -> void:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.6
	mat.metallic = 0.0
	# Slight emission for vibrancy
	mat.emission_enabled = true
	mat.emission = color * 0.15
	mat.emission_energy_multiplier = 0.5
	piece.material_override = mat


## Override final piece creation to use correct colors (not wood)
func _create_final_piece(target: PieceTarget) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "FinalPiece_" + target.piece_id

	# Create box mesh with target size
	var box = BoxMesh.new()
	box.size = target.target_scale
	mesh_instance.mesh = box

	# Use the piece color instead of wood material
	var color = piece_colors.get(target.piece_id, Color.WHITE)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.6
	mat.metallic = 0.0
	mat.emission_enabled = true
	mat.emission = color * 0.15
	mat.emission_energy_multiplier = 0.5
	mesh_instance.material_override = mat

	return mesh_instance


## Override completion
func _complete_puzzle() -> void:
	await super()
	# Remove leftover unused cubes so they don't cover the artwork
	_remove_remaining_cubes()
	relief_assembled.emit()
	print("ReliefAssemblyPuzzle: Relief composition complete!")


## Remove remaining unused cubes
func _remove_remaining_cubes() -> void:
	for piece in relief_pieces:
		if is_instance_valid(piece):
			piece.queue_free()
	relief_pieces.clear()


## Get relief type as string
func get_relief_type_name() -> String:
	match relief_type:
		ReliefType.BIEDERMAN:
			return "Biederman"
		ReliefType.MONDRIAN:
			return "Mondrian"
		ReliefType.ALBERS:
			return "Albers"
		ReliefType.CONSTRUCTIVIST:
			return "Constructivist"
		ReliefType.CUSTOM:
			return "Custom"
	return "Unknown"


## Add a custom bar target
func add_bar_target(bar_id: String, pos: Vector3, rot: Vector3, size: Vector3, color: Color) -> void:
	var target = PieceTarget.new(bar_id, pos, rot, size)
	piece_targets.append(target)
	piece_colors[bar_id] = color


## Apply configuration from grid system / artifact registry
## Accepts explicit names: "biederman", "mondrian", "albers", "constructivist" or numbers
## Shorthand: #biederman, #mondrian, #albers, #constructivist
func apply_grid_config(config_data: Dictionary) -> void:
	print("ReliefAssemblyPuzzle: Applying config: %s" % config_data)

	# Check for relief_type in config
	if config_data.has("relief_type"):
		var new_type = _parse_relief_type(config_data["relief_type"])
		if new_type != relief_type:
			print("ReliefAssemblyPuzzle: Changing relief type to %s" % get_relief_type_name())
			relief_type = new_type
			_rebuild_for_new_type()

	# Piece color config: white:true or colored:true
	if config_data.has("white"):
		pieces_all_white = str(config_data["white"]).to_lower() != "false"
	if config_data.has("colored"):
		pieces_all_white = str(config_data["colored"]).to_lower() != "true"

	# Mesh mode: direct_mesh:true (default) or direct_mesh:false to use piece_scene
	if config_data.has("direct_mesh"):
		use_direct_mesh = str(config_data["direct_mesh"]).to_lower() != "false"

	# Shorthand configs: just the key name without value
	# e.g., #biederman, #mondrian
	# Grid system may set value to true (boolean), "" (string), or null
	for key in config_data.keys():
		var val = config_data[key]
		var is_shorthand = val == null or (val is bool and val == true) or (val is String and val == "")
		if is_shorthand:
			var parsed_type = _parse_relief_type(key)
			if parsed_type != relief_type:
				relief_type = parsed_type
				_rebuild_for_new_type()
				break


## Parse relief type from string name or number
func _parse_relief_type(value) -> ReliefType:
	if value is int:
		return clampi(value, 0, ReliefType.size() - 1) as ReliefType

	var type_str = str(value).to_lower().strip_edges()

	match type_str:
		"biederman", "0":
			return ReliefType.BIEDERMAN
		"mondrian", "destijl", "de_stijl", "1":
			return ReliefType.MONDRIAN
		"albers", "color_study", "2":
			return ReliefType.ALBERS
		"constructivist", "soviet", "3":
			return ReliefType.CONSTRUCTIVIST
		"custom", "4":
			return ReliefType.CUSTOM
		_:
			if type_str.is_valid_int():
				return clampi(int(type_str), 0, ReliefType.size() - 1) as ReliefType
			push_warning("ReliefAssemblyPuzzle: Unknown relief_type '%s', defaulting to BIEDERMAN" % value)
			return ReliefType.BIEDERMAN


## Rebuild puzzle for a new relief type (called when config changes type)
func _rebuild_for_new_type() -> void:
	# Clear existing pieces
	for piece in relief_pieces:
		if is_instance_valid(piece):
			piece.queue_free()
	relief_pieces.clear()
	final_pieces.clear()

	# Clear targets and colors
	piece_targets.clear()
	piece_colors.clear()
	piece_spawn_positions.clear()

	# Clear ghost guides
	for child in get_children():
		if child.name.begins_with("Ghost_"):
			child.queue_free()

	# Setup new targets
	_setup_relief_targets()

	# Recreate ghost guides (parent class)
	if show_ghost_guides:
		_setup_ghost_guides()

	# Respawn pieces
	if auto_spawn_pieces and piece_scene:
		call_deferred("_spawn_pieces")

	print("ReliefAssemblyPuzzle: Rebuilt for %s type" % get_relief_type_name())
