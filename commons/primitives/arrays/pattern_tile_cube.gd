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

## Which craft's unit of colour this is. `pixel` is the shipped plain box — the screen's
## own unit, with no lineage. The other four are the hand-held colour units this puzzle
## inherits from and never admitted to: a cut stone, a threaded bead, a wound spool, a
## moulded brick. Same 4 cm envelope, same collision shape, same colour — different trade.
@export_enum("pixel", "tessera", "bead", "bobbin", "stud") var craft: String = "pixel"

const _CRAFT_FORM: String = "CraftForm"

## True once _ready has built at least once — apply_grid_config must not rebuild before it.
var _built: bool = false

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

	if _mesh_instance == null:
		_mesh_instance = get_node_or_null("MeshInstance3D")
	_apply_craft()
	_built = true


## Map-token config. Only rebuilds when a value actually changed AND _ready has run once,
## so the seven shipped placements (which pass no `craft`) never re-enter the builder.
func apply_grid_config(config_data: Dictionary) -> void:
	var changed: bool = false

	if config_data.has("craft"):
		var v: String = str(config_data["craft"]).strip_edges().to_lower()
		if v != "" and v != craft:
			craft = v
			changed = true

	if config_data.has("color_index"):
		var ci: int = int(config_data["color_index"])
		if ci != color_index:
			color_index = ci
			changed = true

	if changed and _built:
		_apply_craft()


## Swap the shipped box for another trade's unit of colour.
## `pixel` returns before touching anything, so the default is the old code path exactly.
func _apply_craft() -> void:
	if _mesh_instance == null:
		_mesh_instance = get_node_or_null("MeshInstance3D")

	var stale: Node = get_node_or_null(_CRAFT_FORM)
	var had_form: bool = stale != null
	if had_form:
		remove_child(stale)
		stale.queue_free()

	if craft == "pixel":
		# Only un-hide what WE hid. A default cube is never written to at all.
		if had_form and _mesh_instance != null:
			_mesh_instance.layers = 1
		return

	var form: Node3D = Node3D.new()
	form.name = _CRAFT_FORM
	add_child(form)

	var s: float = cube_size
	var mat: StandardMaterial3D = _craft_material()

	match craft:
		"tessera":
			# A cut stone, set flat in its bed and never quite square to the grid.
			var slab: BoxMesh = BoxMesh.new()
			slab.size = Vector3(s * 1.06, s * 0.42, s * 1.06)
			var stone: MeshInstance3D = _add_part(form, slab, Vector3.ZERO, mat)
			stone.rotation_degrees = Vector3(3.0, 9.0, -2.0)
		"bead":
			# A colour you thread rather than stack — the hole is the whole argument.
			var ring: TorusMesh = TorusMesh.new()
			ring.inner_radius = s * 0.16
			ring.outer_radius = s * 0.55
			_add_part(form, ring, Vector3.ZERO, mat)
		"bobbin":
			# The puzzle's palette calls itself "yarn colors"; this is what a yarn comes on.
			var core: CylinderMesh = CylinderMesh.new()
			core.top_radius = s * 0.3
			core.bottom_radius = s * 0.3
			core.height = s * 0.66
			_add_part(form, core, Vector3.ZERO, mat)
			var top_flange: CylinderMesh = CylinderMesh.new()
			top_flange.top_radius = s * 0.55
			top_flange.bottom_radius = s * 0.55
			top_flange.height = s * 0.1
			_add_part(form, top_flange, Vector3(0.0, s * 0.33, 0.0), mat)
			var bottom_flange: CylinderMesh = CylinderMesh.new()
			bottom_flange.top_radius = s * 0.55
			bottom_flange.bottom_radius = s * 0.55
			bottom_flange.height = s * 0.1
			_add_part(form, bottom_flange, Vector3(0.0, -s * 0.33, 0.0), mat)
		"stud":
			# The moulded brick: a colour unit that declares which way is up.
			var brick: BoxMesh = BoxMesh.new()
			brick.size = Vector3(s, s * 0.6, s)
			_add_part(form, brick, Vector3(0.0, -s * 0.2, 0.0), mat)
			var knob: CylinderMesh = CylinderMesh.new()
			knob.top_radius = s * 0.24
			knob.bottom_radius = s * 0.24
			knob.height = s * 0.2
			_add_part(form, knob, Vector3(0.0, s * 0.2, 0.0), mat)
		_:
			# Unknown value: fall back to the shipped box rather than render nothing.
			remove_child(form)
			form.queue_free()
			if had_form and _mesh_instance != null:
				_mesh_instance.layers = 1
			return

	# Hide the shipped box without touching its material (material_override would break the
	# pickup highlight swap) and without visible=false, which would hide descendants too.
	if _mesh_instance != null:
		_mesh_instance.layers = 0


func _add_part(parent: Node3D, mesh: Mesh, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi


## The colour the craft form should wear — the puzzle's palette entry when spawned by the
## puzzle, otherwise whatever the scene's own baked material already shows.
func _craft_material() -> StandardMaterial3D:
	var col: Color = Color(0.8, 0.2, 0.15)
	if _mesh_instance != null:
		var ov: Material = _mesh_instance.material_override
		if ov is StandardMaterial3D:
			col = (ov as StandardMaterial3D).albedo_color
		elif _mesh_instance.mesh != null and _mesh_instance.mesh.get_surface_count() > 0:
			var sm: Material = _mesh_instance.mesh.surface_get_material(0)
			if sm is StandardMaterial3D:
				col = (sm as StandardMaterial3D).albedo_color
	if puzzle and color_index >= 0 and color_index < puzzle.palette.size():
		col = puzzle.palette[color_index]

	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.8
	return m


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

	# A craft form wears the colour instead of the hidden box; refresh it.
	if craft != "pixel" and get_node_or_null(_CRAFT_FORM) != null:
		_apply_craft()


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
