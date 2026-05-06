# @identity
# essence: a small grabbable colored cube — the physical pixel in a VR pattern editor; each cube IS one cell of color that the player places by hand onto the tile grid
# desire: to make the act of programming a pattern embodied — the player doesn't click, they reach; the tile is made by hands, not cursor; the pattern is the player's gesture made permanent
# critical_parameter: color_index — each cube carries one color from the puzzle's palette; placing it in a grid cell is a single bit of the pattern decision; the tile is the sum of all placements
# triggers: dropped signal fires when player releases grip; _on_dropped() checks proximity to grid cells and snaps to the nearest valid slot; picked_up() lifts cube back to hand space
# emerges: the constraint of physical placement — you can only hold one cube at a time, which makes pattern-making a sequence of decisions rather than a batch paint-fill; the slowness is the lesson
# needs: VR grab and release [has — XRToolsPickable]; color switching [missing — cube color is fixed at spawn]; multi-cube grab [missing]; apply_grid_config [missing]
# relationships: spawned by PatternTilePuzzle into a palette rack; snaps to PatternTilePuzzle.grid_cells; the placed pattern is saved to TraceData and read by ArrayCarpet; the three form one system
# truth: a pixel is a decision — the pattern_tile_cube proves this by making you pick up each color and place it; the tile is not drawn, it is assembled

@tool
extends XRToolsPickable
class_name PatternTileCube

## Small grabbable cube for pattern tile puzzle
## Drag to grid cells to place colors

## Color index this cube represents
@export var color_index: int = 0:
	set(v):
		color_index = v
		_update_color()

## Size of the cube in meters
@export var cube_size: float = 0.04

## Reference to parent puzzle (set automatically)
var puzzle: PatternTilePuzzle = null

## Whether this cube has been placed on the grid
var is_placed: bool = false

## Grid position if placed (-1,-1 if not)
var grid_position: Vector2i = Vector2i(-1, -1)

## Internal
var _mesh_instance: MeshInstance3D


func _ready() -> void:
	super()

	if Engine.is_editor_hint():
		return

	# Listen for drop event
	dropped.connect(_on_dropped)
	picked_up.connect(_on_picked_up)


func setup(p_puzzle: PatternTilePuzzle, p_color_index: int, p_size: float = 0.04) -> void:
	puzzle = p_puzzle
	cube_size = p_size
	color_index = p_color_index
	_create_visual()
	# Store meta for fallback identification
	set_meta("color_index", color_index)
	set_meta("puzzle", puzzle)


func _create_visual() -> void:
	# Try to use existing mesh first
	_mesh_instance = get_node_or_null("MeshInstance3D")

	if _mesh_instance:
		# Update existing mesh size
		if _mesh_instance.mesh is BoxMesh:
			_mesh_instance.mesh.size = Vector3.ONE * cube_size
	else:
		# Create new mesh
		_mesh_instance = MeshInstance3D.new()
		_mesh_instance.name = "MeshInstance3D"

		var box = BoxMesh.new()
		box.size = Vector3.ONE * cube_size
		_mesh_instance.mesh = box

		add_child(_mesh_instance)

	_update_color()

	# Update collision shape to match cube size
	var collision = get_node_or_null("CollisionShape3D")
	if collision:
		if collision.shape is BoxShape3D:
			collision.shape.size = Vector3.ONE * cube_size
		else:
			# Replace with box shape
			var box_shape = BoxShape3D.new()
			box_shape.size = Vector3.ONE * cube_size
			collision.shape = box_shape


func _update_color() -> void:
	if not _mesh_instance:
		return
	if not puzzle:
		return

	var mat = StandardMaterial3D.new()
	if color_index < puzzle.palette.size():
		mat.albedo_color = puzzle.palette[color_index]
	else:
		mat.albedo_color = Color.WHITE
	mat.roughness = 0.8
	_mesh_instance.material_override = mat


func _on_picked_up(_pickable) -> void:
	# If was placed, clear the grid cell
	if is_placed and puzzle and grid_position.x >= 0:
		# Optionally clear the cell when picked up (or leave it)
		pass

	is_placed = false
	grid_position = Vector2i(-1, -1)

	# Re-enable physics (unfreeze when picked up)
	freeze = false
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO


func _on_dropped(_pickable) -> void:
	if not puzzle:
		return

	# Check if we're over a grid cell
	var cell_info = puzzle._find_nearest_cell(global_position)
	if cell_info.valid:
		# Snap to cell
		_snap_to_cell(cell_info.x, cell_info.y, cell_info.world_pos)
	else:
		# Not over grid - could return to spawn or just stay
		pass


func _snap_to_cell(x: int, y: int, target_pos: Vector3) -> void:
	# Move to cell position
	global_position = target_pos

	# Align rotation
	global_rotation = puzzle._editor_container.global_rotation

	# Freeze in place
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	# Mark as placed
	is_placed = true
	grid_position = Vector2i(x, y)

	# Update puzzle grid data
	puzzle.set_cell(x, y, color_index)

	# Play snap sound if available
	if puzzle.has_method("_play_snap_sound"):
		puzzle._play_snap_sound()
