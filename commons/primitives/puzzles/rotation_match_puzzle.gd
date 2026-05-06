extends Node3D
class_name RotationMatchPuzzle

## Rotation Match Puzzle - Inspired by Vera Molnár's algorithmic art
## 2D canvas with rotated rectangles - systematic rotation variations
## Reference: Molnár's "(Dés)Ordres" and "Interruptions" series

signal puzzle_completed
signal piece_matched(piece_index: int)

# Canvas configuration
@export_group("Canvas")
@export var grid_size: Vector2i = Vector2i(5, 5)  # Grid of rectangles
@export var cell_size: float = 0.3  # Size of each cell
@export var rect_scale: float = 0.85  # Rectangle size relative to cell (< 1 for gaps)
@export var canvas_vertical: bool = true  # Stand up like a painting

@export_group("Style")
@export_enum("Molnar Desordres", "Molnar Interruptions", "Random", "Gradient", "Custom") var style: int = 0
@export var max_rotation: float = 25.0  # Maximum rotation deviation (degrees)
@export var custom_rotations: Array[float] = []  # For custom style

@export_group("Colors - Molnár Palette")
@export var background_color: Color = Color(0.95, 0.95, 0.92, 1.0)  # Off-white canvas
@export var rect_color: Color = Color(0.05, 0.05, 0.08, 1.0)  # Near-black rectangles
@export var ghost_color: Color = Color(0.6, 0.85, 1.0, 0.4)  # Cyan ghost outlines

@export_group("Interaction")
@export var frozen: bool = true  # Freeze pieces for development
@export var show_pieces: bool = true  # Show moveable pieces on the side

# Internal
var canvas_mesh: MeshInstance3D
var ghost_container: Node3D
var piece_container: Node3D
var targets: Array[Dictionary] = []  # {grid_pos, rotation, ghost_mesh}
var pieces: Array[Node3D] = []

func _ready():
	_create_canvas()
	_generate_composition()
	if show_pieces:
		_spawn_pieces_on_side()
	print("RotationMatchPuzzle: Vera Molnár composition - %dx%d grid, %s style" % [
		grid_size.x, grid_size.y, _get_style_name()
	])

func _get_style_name() -> String:
	match style:
		0: return "(Dés)Ordres"
		1: return "Interruptions"
		2: return "Random"
		3: return "Gradient"
		4: return "Custom"
	return "Unknown"

func _create_canvas():
	# Background canvas plane
	canvas_mesh = MeshInstance3D.new()
	canvas_mesh.name = "Canvas"

	var plane = PlaneMesh.new()
	var canvas_width = grid_size.x * cell_size + cell_size
	var canvas_height = grid_size.y * cell_size + cell_size
	plane.size = Vector2(canvas_width, canvas_height)
	canvas_mesh.mesh = plane

	# Canvas material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = background_color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	canvas_mesh.material_override = mat

	# Orient canvas
	if canvas_vertical:
		canvas_mesh.rotation_degrees.x = -90  # Stand up facing -Z

	add_child(canvas_mesh)

	# Container for ghost rectangles (on canvas)
	ghost_container = Node3D.new()
	ghost_container.name = "GhostRectangles"
	if canvas_vertical:
		ghost_container.rotation_degrees.x = -90
	add_child(ghost_container)

	# Container for moveable pieces
	piece_container = Node3D.new()
	piece_container.name = "Pieces"
	add_child(piece_container)

func _generate_composition():
	targets.clear()
	var index = 0

	for row in range(grid_size.y):
		for col in range(grid_size.x):
			var local_pos = Vector3(
				(col - grid_size.x / 2.0 + 0.5) * cell_size,
				0.001,  # Slightly above canvas
				(row - grid_size.y / 2.0 + 0.5) * cell_size
			)

			var rot = _calculate_rotation(col, row, index)

			var ghost = _create_rect_mesh(local_pos, rot, false)
			ghost_container.add_child(ghost)

			targets.append({
				"grid_pos": Vector2i(col, row),
				"position": local_pos,
				"rotation": rot,
				"ghost_mesh": ghost,
				"matched": false
			})
			index += 1

func _calculate_rotation(col: int, row: int, index: int) -> float:
	match style:
		0:  # Molnár (Dés)Ordres - disorder increases from center
			var center_x = grid_size.x / 2.0
			var center_y = grid_size.y / 2.0
			var dist = sqrt(pow(col - center_x, 2) + pow(row - center_y, 2))
			var max_dist = sqrt(pow(center_x, 2) + pow(center_y, 2))
			var disorder = dist / max_dist if max_dist > 0 else 0
			# Pseudo-random direction based on position
			var seed_val = (col * 7 + row * 13 + 42) % 100
			var sign = 1.0 if seed_val % 2 == 0 else -1.0
			var variance = (seed_val / 100.0) * 0.5 + 0.5
			return disorder * max_rotation * sign * variance

		1:  # Molnár Interruptions - mostly aligned, some rotated
			var seed_val = (col * 11 + row * 17 + 31) % 100
			if seed_val < 15:  # 15% interruption
				var rot_seed = (col * 23 + row * 29) % 100
				return (rot_seed / 100.0 - 0.5) * 2.0 * max_rotation
			return 0.0

		2:  # Random
			var seed_val = (col * 37 + row * 41 + index * 53) % 1000
			return (seed_val / 1000.0 - 0.5) * 2.0 * max_rotation

		3:  # Gradient - rotation increases diagonally
			var t = float(col + row) / float(grid_size.x + grid_size.y - 2) if (grid_size.x + grid_size.y > 2) else 0
			return lerp(-max_rotation, max_rotation, t)

		4:  # Custom
			if index < custom_rotations.size():
				return custom_rotations[index]
			return 0.0

	return 0.0

func _create_rect_mesh(pos: Vector3, rot: float, is_piece: bool) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()

	# Create rectangle (slightly smaller than cell)
	var rect_size = cell_size * rect_scale
	var quad = QuadMesh.new()
	quad.size = Vector2(rect_size, rect_size)
	mesh_instance.mesh = quad

	# Material
	var mat = StandardMaterial3D.new()
	if is_piece:
		mat.albedo_color = rect_color
	else:
		# Ghost outline style
		mat.albedo_color = ghost_color
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # Visible from both sides
	mesh_instance.material_override = mat

	mesh_instance.position = pos
	mesh_instance.rotation_degrees.y = rot  # Rotate around Y (up) when vertical

	return mesh_instance

func _spawn_pieces_on_side():
	# Spawn dark rectangles to the right of the canvas
	var offset_x = (grid_size.x / 2.0 + 2) * cell_size
	var index = 0

	for row in range(grid_size.y):
		for col in range(grid_size.x):
			var local_pos = Vector3(
				offset_x + (col % 3) * cell_size * 1.2,
				0.001,
				(row - grid_size.y / 2.0 + 0.5) * cell_size
			)

			var piece = _create_rect_mesh(local_pos, 0.0, true)
			piece.name = "Piece_%d" % index

			if canvas_vertical:
				# Create a container that's rotated with the canvas
				var piece_holder = Node3D.new()
				piece_holder.rotation_degrees.x = -90
				piece_holder.add_child(piece)
				piece_container.add_child(piece_holder)
			else:
				piece_container.add_child(piece)

			pieces.append(piece)
			index += 1

			# Only show same count as targets
			if index >= targets.size():
				return

# Grid artifact configuration API
func apply_grid_config(config: Dictionary) -> void:
	print("RotationMatchPuzzle: Applying config: %s" % str(config))

	if config.has("style"):
		var style_str = str(config["style"]).to_lower()
		match style_str:
			"molnar", "desordres", "0": style = 0
			"interruptions", "1": style = 1
			"random", "2": style = 2
			"gradient", "3": style = 3
			"custom", "4": style = 4

	if config.has("grid_x"):
		grid_size.x = int(config["grid_x"])
	if config.has("grid_z") or config.has("grid_y"):
		grid_size.y = int(config.get("grid_z", config.get("grid_y", grid_size.y)))
	if config.has("max_rot"):
		max_rotation = float(config["max_rot"])
	if config.has("frozen"):
		frozen = str(config["frozen"]).to_lower() == "true"
	if config.has("pieces"):
		show_pieces = str(config["pieces"]).to_lower() == "true"
	if config.has("cell"):
		cell_size = float(config["cell"])
