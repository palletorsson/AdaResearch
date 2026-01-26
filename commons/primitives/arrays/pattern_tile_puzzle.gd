@tool
extends Node3D
class_name PatternTilePuzzle

## Pattern Tile Puzzle - Handmade meets Computational
##
## Create patterns on a small tile grid, watch them repeat across
## a carpet/floor. Explores the connection between textile traditions
## and digital patterns.
##
## Progression: Simple repeat → Mirror → Rotate → Offset → Wallpaper groups

## Tile grid size
@export var tile_size: int = 4:
	set(v):
		tile_size = clampi(v, 2, 16)
		if is_inside_tree() and not Engine.is_editor_hint():
			_rebuild_grid()

## Preview repeat count (how many times tile shows in preview)
@export var preview_repeats: Vector2i = Vector2i(4, 4)

## Cell size in meters
@export var cell_size: float = 0.05

## Repeat mode
enum RepeatMode {
	SIMPLE,          ## Basic XY tiling
	MIRROR_X,        ## Mirror horizontally
	MIRROR_Y,        ## Mirror vertically
	MIRROR_XY,       ## Mirror both axes (kaleidoscope)
	ROTATE_90,       ## 90° rotational symmetry
	ROTATE_180,      ## 180° rotational symmetry
	BRICK_X,         ## Half-offset rows (brick pattern)
	BRICK_Y,         ## Half-offset columns
	HERRINGBONE,     ## Alternating diagonal
	DIAMOND          ## Diamond/diagonal tiling
}

@export var repeat_mode: RepeatMode = RepeatMode.SIMPLE:
	set(v):
		repeat_mode = v
		_update_preview()
		repeat_mode_changed.emit(v)

## Symmetry mode - switch between legacy RepeatMode and WallpaperGroups
enum SymmetryMode {
	LEGACY,     ## Use RepeatMode enum (original 10 modes)
	WALLPAPER   ## Use WallpaperGroups (17 mathematical groups)
}

@export var symmetry_mode: SymmetryMode = SymmetryMode.LEGACY:
	set(v):
		symmetry_mode = v
		_update_preview()
		_update_mode_label()

## Current wallpaper group (when symmetry_mode == WALLPAPER)
@export var wallpaper_group: WallpaperGroups.Group = WallpaperGroups.Group.P1:
	set(v):
		wallpaper_group = v
		_update_preview()
		_update_mode_label()
		wallpaper_group_changed.emit(v)

## Lattice order for VR navigation (B/Y cycles through these)
const LATTICE_ORDER: Array[String] = ["oblique", "rectangular", "rhombic", "square", "hexagonal"]

## Groups per lattice for VR navigation (A/X cycles within current lattice)
const GROUPS_BY_LATTICE: Dictionary = {
	"oblique": [WallpaperGroups.Group.P1, WallpaperGroups.Group.P2],
	"rectangular": [WallpaperGroups.Group.PM, WallpaperGroups.Group.PG, WallpaperGroups.Group.PMM,
					WallpaperGroups.Group.PMG, WallpaperGroups.Group.PGG],
	"rhombic": [WallpaperGroups.Group.CM, WallpaperGroups.Group.CMM],
	"square": [WallpaperGroups.Group.P4, WallpaperGroups.Group.P4M, WallpaperGroups.Group.P4G],
	"hexagonal": [WallpaperGroups.Group.P3, WallpaperGroups.Group.P3M1, WallpaperGroups.Group.P31M,
				  WallpaperGroups.Group.P6, WallpaperGroups.Group.P6M]
}

## Current lattice index for navigation
var _current_lattice_index: int = 0

## Color palette (like yarn colors)
@export var palette: Array[Color] = [
	Color(0.95, 0.92, 0.85),  # Cream/natural
	Color(0.8, 0.2, 0.15),    # Deep red
	Color(0.15, 0.25, 0.5),   # Navy blue
	Color(0.7, 0.55, 0.2),    # Gold/ochre
	Color(0.2, 0.4, 0.25),    # Forest green
	Color(0.4, 0.2, 0.15),    # Brown
	Color(0.1, 0.1, 0.12),    # Near black
	Color(0.6, 0.3, 0.5)      # Dusty purple
]

## Current selected color index
@export var selected_color: int = 1

## Preview offset from editor
@export var preview_offset: Vector3 = Vector3(0, 0, -0.8)

## Show grid lines
@export var show_grid_lines: bool = true

## Signals
signal cell_changed(x: int, y: int, color_index: int)
signal pattern_complete()
signal repeat_mode_changed(mode: RepeatMode)
signal wallpaper_group_changed(group: WallpaperGroups.Group)
signal color_selected(color_index: int)

## Cube size for grabbable pieces
@export var cube_size_ratio: float = 0.8  # Cube size relative to cell

## Spawn offset for cube dispensers
@export var spawner_offset: Vector3 = Vector3(0.25, 0, 0)

## === CURSOR VISUALIZATION ===
## The cursor makes array indexing visible - it's the index incarnate

@export_group("Cursor")
## Enable cursor visualization
@export var cursor_enabled: bool = false:
	set(v):
		cursor_enabled = v
		if is_inside_tree():
			_update_cursor_visibility()

## Cursor animation speed (cells per second)
@export var cursor_speed: float = 2.0

## Show index math label
@export var show_index_math: bool = true

## Cursor signals
signal cursor_moved(preview_x: int, preview_y: int, source_x: int, source_y: int)

## Cursor state
var _cursor_position: Vector2i = Vector2i.ZERO  # Position in preview grid
var _cursor_animating: bool = false
var _cursor_timer: float = 0.0

## Cursor visuals
var _cursor_highlight: MeshInstance3D  # Highlight on preview
var _source_highlight: MeshInstance3D  # Highlight on editor grid (source cell)
var _index_label: Label3D  # Shows the index math
var _cursor_trail: Array[MeshInstance3D] = []  # Optional: show recent positions

## Internal state
var _grid_data: Array = []  # 2D array of color indices
var _editor_cells: Array = []  # MeshInstance3D for each cell
var _cell_snap_positions: Array = []  # World positions for each cell
var _preview_mesh: MeshInstance3D
var _cube_spawners: Array = []  # Cube dispensers for each color
var _placed_cubes: Dictionary = {}  # grid_pos (Vector2i) -> cube reference
var _editor_container: Node3D
var _preview_container: Node3D
var _spawner_container: Node3D
var _mode_label: Label3D
var _grid_lines: Node3D

## Preload cube scene
var _cube_scene: PackedScene = null

## Materials cache
var _cell_materials: Dictionary = {}


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	# Try to load cube scene
	_cube_scene = load("res://commons/primitives/arrays/pattern_tile_cube.tscn")

	_initialize_grid_data()
	_create_editor_grid()
	_create_preview()
	_create_cube_spawners()
	_create_mode_label()
	_create_cursor_visuals()
	_update_preview()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if not cursor_enabled or not _cursor_animating:
		return

	_cursor_timer += delta
	var step_time = 1.0 / cursor_speed

	if _cursor_timer >= step_time:
		_cursor_timer -= step_time
		cursor_step()


func _initialize_grid_data() -> void:
	_grid_data.clear()
	for y in range(tile_size):
		var row = []
		for x in range(tile_size):
			row.append(0)  # Default to first color
		_grid_data.append(row)


func _create_editor_grid() -> void:
	# Container for editor
	_editor_container = Node3D.new()
	_editor_container.name = "EditorGrid"
	add_child(_editor_container)

	# Center the grid
	var grid_total_size = tile_size * cell_size
	var offset = -grid_total_size / 2.0

	_editor_cells.clear()
	_cell_snap_positions.clear()

	for y in range(tile_size):
		var row_cells = []
		var row_positions = []
		for x in range(tile_size):
			var cell = _create_cell(x, y)
			var local_pos = Vector3(
				offset + x * cell_size + cell_size / 2,
				offset + y * cell_size + cell_size / 2,
				cell_size / 2  # Slightly in front of the grid
			)
			cell.position = local_pos
			_editor_container.add_child(cell)
			row_cells.append(cell)
			row_positions.append(local_pos)
		_editor_cells.append(row_cells)
		_cell_snap_positions.append(row_positions)

	# Add grid lines
	if show_grid_lines:
		_create_grid_lines()


func _create_cell(x: int, y: int) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Cell_%d_%d" % [x, y]

	var quad = QuadMesh.new()
	quad.size = Vector2(cell_size * 0.95, cell_size * 0.95)
	mesh_instance.mesh = quad

	# Get material for color
	var color_idx = _grid_data[y][x] if y < _grid_data.size() and x < _grid_data[y].size() else 0
	mesh_instance.material_override = _get_material_for_color(color_idx)

	return mesh_instance



func _create_grid_lines() -> void:
	_grid_lines = Node3D.new()
	_grid_lines.name = "GridLines"
	_editor_container.add_child(_grid_lines)

	var grid_total_size = tile_size * cell_size
	var offset = -grid_total_size / 2.0

	var line_mat = StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.3, 0.3, 0.35, 0.8)
	line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Vertical lines
	for x in range(tile_size + 1):
		var line = _create_line_mesh(
			Vector3(offset + x * cell_size, offset, 0.001),
			Vector3(offset + x * cell_size, offset + grid_total_size, 0.001),
			line_mat
		)
		_grid_lines.add_child(line)

	# Horizontal lines
	for y in range(tile_size + 1):
		var line = _create_line_mesh(
			Vector3(offset, offset + y * cell_size, 0.001),
			Vector3(offset + grid_total_size, offset + y * cell_size, 0.001),
			line_mat
		)
		_grid_lines.add_child(line)


func _create_line_mesh(from: Vector3, to: Vector3, mat: Material) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var immediate = ImmediateMesh.new()

	immediate.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate.surface_add_vertex(from)
	immediate.surface_add_vertex(to)
	immediate.surface_end()

	mesh_instance.mesh = immediate
	mesh_instance.material_override = mat
	return mesh_instance


func _create_preview() -> void:
	_preview_container = Node3D.new()
	_preview_container.name = "Preview"
	_preview_container.position = preview_offset
	add_child(_preview_container)

	_preview_mesh = MeshInstance3D.new()
	_preview_mesh.name = "PreviewMesh"
	_preview_container.add_child(_preview_mesh)

	# Add frame around preview
	_create_preview_frame()


func _create_preview_frame() -> void:
	var frame = Node3D.new()
	frame.name = "Frame"
	_preview_container.add_child(frame)

	var total_width = preview_repeats.x * tile_size * cell_size
	var total_height = preview_repeats.y * tile_size * cell_size
	var frame_width = 0.01

	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.4, 0.3, 0.2)

	# Create frame borders (simplified - just corners)
	# Full frame would need 4 box meshes


func _create_cube_spawners() -> void:
	_spawner_container = Node3D.new()
	_spawner_container.name = "CubeSpawners"
	_spawner_container.position = spawner_offset
	add_child(_spawner_container)

	_cube_spawners.clear()

	var spawner_size = cell_size * cube_size_ratio
	var spacing = spawner_size * 1.5
	var start_y = (palette.size() - 1) * spacing / 2.0

	for i in range(palette.size()):
		var spawner = _create_cube_spawner(i, spawner_size)
		spawner.position = Vector3(0, start_y - i * spacing, 0)
		_spawner_container.add_child(spawner)
		_cube_spawners.append(spawner)

	# Spawn initial cubes after tree is ready
	call_deferred("_spawn_initial_cubes")


func _spawn_initial_cubes() -> void:
	for i in range(palette.size()):
		_spawn_cube_at_spawner(i)


func _create_cube_spawner(color_idx: int, size: float) -> Node3D:
	var spawner_root = Node3D.new()
	spawner_root.name = "Spawner_%d" % color_idx

	# Base platform for the spawner (small pedestal)
	var platform = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = size * 0.8
	cylinder.bottom_radius = size * 0.9
	cylinder.height = size * 0.3
	platform.mesh = cylinder
	platform.position.y = -size * 0.15

	var platform_mat = StandardMaterial3D.new()
	platform_mat.albedo_color = Color(0.3, 0.3, 0.35)
	platform_mat.roughness = 0.9
	platform.material_override = platform_mat
	spawner_root.add_child(platform)

	# Color indicator ring
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = size * 0.5
	torus.outer_radius = size * 0.7
	ring.mesh = torus
	ring.rotation_degrees.x = 90
	ring.position.y = -size * 0.1
	ring.material_override = _get_material_for_color(color_idx)
	spawner_root.add_child(ring)

	# Area to detect when cube is taken (to spawn new one)
	var detect_area = Area3D.new()
	detect_area.name = "SpawnArea"
	# Set collision to only detect physics bodies (layer 1), not hands
	detect_area.collision_layer = 0  # Not on any layer (non-pickable)
	detect_area.collision_mask = 1   # Only detect layer 1 (physics objects)
	detect_area.monitorable = false  # Can't be detected by other areas
	detect_area.monitoring = true    # Can detect other bodies
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = size
	collision.shape = shape
	detect_area.add_child(collision)
	spawner_root.add_child(detect_area)

	# Monitor when cube leaves
	detect_area.body_exited.connect(_on_cube_left_spawner.bind(color_idx))

	return spawner_root


func _spawn_cube_at_spawner(color_idx: int) -> void:
	if color_idx < 0 or color_idx >= _cube_spawners.size():
		return

	var spawner = _cube_spawners[color_idx]
	var spawn_pos = spawner.global_position + Vector3(0, cell_size * 0.5, 0)

	var cube = _create_color_cube(color_idx)

	# Add to scene first
	add_child(cube)

	# Then set position and freeze
	cube.global_position = spawn_pos
	cube.freeze = true  # Start frozen on pedestal


func _create_color_cube(color_idx: int) -> Node3D:
	var cube_actual_size = cell_size * cube_size_ratio

	# Try to use scene if available
	if _cube_scene:
		var cube = _cube_scene.instantiate()
		if cube.has_method("setup"):
			cube.setup(self, color_idx, cube_actual_size)
		return cube

	# Fallback: create cube manually as RigidBody3D with XRToolsPickable behavior
	var cube = RigidBody3D.new()
	cube.name = "ColorCube_%d" % color_idx

	# Mesh
	var mesh = MeshInstance3D.new()
	mesh.name = "MeshInstance3D"
	var box = BoxMesh.new()
	box.size = Vector3.ONE * cube_actual_size
	mesh.mesh = box
	mesh.material_override = _get_material_for_color(color_idx)
	cube.add_child(mesh)

	# Collision
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3.ONE * cube_actual_size
	collision.shape = shape
	cube.add_child(collision)

	# Store color info
	cube.set_meta("color_index", color_idx)
	cube.set_meta("puzzle", self)

	return cube


func _on_cube_left_spawner(body: Node3D, color_idx: int) -> void:
	# Check if the body that left is a color cube
	if body.has_meta("color_index") or body is PatternTileCube:
		# Spawn a new cube after a short delay
		await get_tree().create_timer(0.5).timeout
		_spawn_cube_at_spawner(color_idx)


func _create_mode_label() -> void:
	_mode_label = Label3D.new()
	_mode_label.name = "ModeLabel"
	_mode_label.font_size = 24
	_mode_label.pixel_size = 0.001
	_mode_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_mode_label.position = Vector3(0, tile_size * cell_size / 2 + 0.08, 0)
	_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mode_label.modulate = Color(0.9, 0.85, 0.75)
	add_child(_mode_label)
	_update_mode_label()


func _update_mode_label() -> void:
	if not _mode_label:
		return

	if symmetry_mode == SymmetryMode.WALLPAPER:
		# Show wallpaper group info
		var group_info = WallpaperGroups.get_group_info(wallpaper_group)
		var group_name = group_info.get("name", "?").to_upper()
		var lattice = group_info.get("lattice", "unknown")
		var description = group_info.get("description", "")
		_mode_label.text = "%s (%s)\n%s" % [group_name, lattice.capitalize(), description]
	else:
		# Show legacy repeat mode
		var mode_names = {
			RepeatMode.SIMPLE: "Simple Tile",
			RepeatMode.MIRROR_X: "Mirror X",
			RepeatMode.MIRROR_Y: "Mirror Y",
			RepeatMode.MIRROR_XY: "Mirror XY",
			RepeatMode.ROTATE_90: "Rotate 90°",
			RepeatMode.ROTATE_180: "Rotate 180°",
			RepeatMode.BRICK_X: "Brick (Rows)",
			RepeatMode.BRICK_Y: "Brick (Cols)",
			RepeatMode.HERRINGBONE: "Herringbone",
			RepeatMode.DIAMOND: "Diamond"
		}
		_mode_label.text = mode_names.get(repeat_mode, "Unknown")


## === CURSOR VISUALIZATION METHODS ===

func _create_cursor_visuals() -> void:
	# Cursor highlight on preview (where we're reading)
	_cursor_highlight = MeshInstance3D.new()
	_cursor_highlight.name = "CursorHighlight"
	var cursor_mesh = BoxMesh.new()
	cursor_mesh.size = Vector3(cell_size * 1.1, cell_size * 1.1, 0.005)
	_cursor_highlight.mesh = cursor_mesh

	var cursor_mat = StandardMaterial3D.new()
	cursor_mat.albedo_color = Color(1.0, 1.0, 0.2, 0.8)
	cursor_mat.emission_enabled = true
	cursor_mat.emission = Color(1.0, 1.0, 0.2)
	cursor_mat.emission_energy_multiplier = 2.0
	cursor_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cursor_highlight.material_override = cursor_mat

	if _preview_container:
		_preview_container.add_child(_cursor_highlight)
	_cursor_highlight.visible = false

	# Source highlight on editor grid (where the value comes from)
	_source_highlight = MeshInstance3D.new()
	_source_highlight.name = "SourceHighlight"
	var source_mesh = BoxMesh.new()
	source_mesh.size = Vector3(cell_size * 1.2, cell_size * 1.2, 0.008)
	_source_highlight.mesh = source_mesh

	var source_mat = StandardMaterial3D.new()
	source_mat.albedo_color = Color(0.2, 1.0, 0.4, 0.9)
	source_mat.emission_enabled = true
	source_mat.emission = Color(0.2, 1.0, 0.4)
	source_mat.emission_energy_multiplier = 3.0
	source_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_source_highlight.material_override = source_mat

	if _editor_container:
		_editor_container.add_child(_source_highlight)
	_source_highlight.visible = false

	# Index math label
	_index_label = Label3D.new()
	_index_label.name = "IndexLabel"
	_index_label.font_size = 18
	_index_label.pixel_size = 0.001
	_index_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_index_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_index_label.modulate = Color(1.0, 1.0, 0.8)
	_index_label.position = Vector3(0, -tile_size * cell_size / 2 - 0.12, 0)

	if _preview_container:
		_preview_container.add_child(_index_label)
	_index_label.visible = false


func _update_cursor_visibility() -> void:
	if _cursor_highlight:
		_cursor_highlight.visible = cursor_enabled
	if _source_highlight:
		_source_highlight.visible = cursor_enabled
	if _index_label:
		_index_label.visible = cursor_enabled and show_index_math

	if cursor_enabled:
		_update_cursor_display()


func _update_cursor_display() -> void:
	if not cursor_enabled:
		return

	var px = _cursor_position.x
	var py = _cursor_position.y

	# Calculate source position using the same logic as _get_tiled_color
	var source_x: int
	var source_y: int

	if symmetry_mode == SymmetryMode.WALLPAPER:
		# For wallpaper groups, we need to reverse-engineer the source
		# For now, use simple modulo (the actual transform is in the color lookup)
		source_x = px % tile_size
		source_y = py % tile_size
	else:
		# Calculate based on repeat mode
		var result = _calculate_source_index(px, py)
		source_x = result.x
		source_y = result.y

	# Update cursor highlight position on preview
	if _cursor_highlight and _preview_container:
		var preview_width = preview_repeats.x * tile_size
		var preview_height = preview_repeats.y * tile_size
		var total_w = preview_width * cell_size
		var total_h = preview_height * cell_size

		_cursor_highlight.position = Vector3(
			-total_w / 2 + (px + 0.5) * cell_size,
			-total_h / 2 + (py + 0.5) * cell_size,
			0.01
		)

	# Update source highlight position on editor
	if _source_highlight and _editor_container:
		var grid_total = tile_size * cell_size
		var offset = -grid_total / 2.0

		_source_highlight.position = Vector3(
			offset + (source_x + 0.5) * cell_size,
			offset + (source_y + 0.5) * cell_size,
			0.01
		)

	# Update index label with the math
	if _index_label and show_index_math:
		var math_text = "Index: (%d, %d)\n" % [px, py]

		if symmetry_mode == SymmetryMode.WALLPAPER:
			var group_name = WallpaperGroups.get_group_name(wallpaper_group)
			math_text += "%s transform\n" % group_name.to_upper()
			math_text += "→ source: (%d, %d)" % [source_x, source_y]
		else:
			# Show the modulo math
			math_text += "%d %% %d = %d\n" % [px, tile_size, px % tile_size]
			math_text += "%d %% %d = %d\n" % [py, tile_size, py % tile_size]
			math_text += "→ source: (%d, %d)" % [source_x, source_y]

		_index_label.text = math_text

	# Emit signal
	cursor_moved.emit(px, py, source_x, source_y)


## Calculate the source index for a preview position (reverse of _get_tiled_color)
func _calculate_source_index(px: int, py: int) -> Vector2i:
	var tx: int
	var ty: int

	match repeat_mode:
		RepeatMode.SIMPLE:
			tx = px % tile_size
			ty = py % tile_size

		RepeatMode.MIRROR_X:
			var tile_x = px / tile_size
			tx = px % tile_size
			if tile_x % 2 == 1:
				tx = tile_size - 1 - tx
			ty = py % tile_size

		RepeatMode.MIRROR_Y:
			tx = px % tile_size
			var tile_y = py / tile_size
			ty = py % tile_size
			if tile_y % 2 == 1:
				ty = tile_size - 1 - ty

		RepeatMode.MIRROR_XY:
			var tile_x = px / tile_size
			var tile_y = py / tile_size
			tx = px % tile_size
			ty = py % tile_size
			if tile_x % 2 == 1:
				tx = tile_size - 1 - tx
			if tile_y % 2 == 1:
				ty = tile_size - 1 - ty

		RepeatMode.ROTATE_90:
			var tile_idx = (px / tile_size + py / tile_size) % 4
			tx = px % tile_size
			ty = py % tile_size
			for i in range(tile_idx):
				var new_tx = tile_size - 1 - ty
				var new_ty = tx
				tx = new_tx
				ty = new_ty

		RepeatMode.ROTATE_180:
			var tile_x = px / tile_size
			var tile_y = py / tile_size
			tx = px % tile_size
			ty = py % tile_size
			if (tile_x + tile_y) % 2 == 1:
				tx = tile_size - 1 - tx
				ty = tile_size - 1 - ty

		_:
			tx = px % tile_size
			ty = py % tile_size

	return Vector2i(clampi(tx, 0, tile_size - 1), clampi(ty, 0, tile_size - 1))


## Cursor control methods

func cursor_play() -> void:
	cursor_enabled = true
	_cursor_animating = true
	_update_cursor_visibility()


func cursor_pause() -> void:
	_cursor_animating = false


func cursor_stop() -> void:
	_cursor_animating = false
	_cursor_position = Vector2i.ZERO
	_update_cursor_display()


func cursor_toggle() -> void:
	if _cursor_animating:
		cursor_pause()
	else:
		cursor_play()


func cursor_step() -> void:
	cursor_enabled = true
	_update_cursor_visibility()

	var preview_width = preview_repeats.x * tile_size
	var preview_height = preview_repeats.y * tile_size

	# Move to next position (row by row)
	_cursor_position.x += 1
	if _cursor_position.x >= preview_width:
		_cursor_position.x = 0
		_cursor_position.y += 1
		if _cursor_position.y >= preview_height:
			_cursor_position.y = 0  # Wrap around

	_update_cursor_display()


func cursor_step_back() -> void:
	cursor_enabled = true
	_update_cursor_visibility()

	var preview_width = preview_repeats.x * tile_size
	var preview_height = preview_repeats.y * tile_size

	_cursor_position.x -= 1
	if _cursor_position.x < 0:
		_cursor_position.x = preview_width - 1
		_cursor_position.y -= 1
		if _cursor_position.y < 0:
			_cursor_position.y = preview_height - 1

	_update_cursor_display()


func cursor_goto(x: int, y: int) -> void:
	cursor_enabled = true
	var preview_width = preview_repeats.x * tile_size
	var preview_height = preview_repeats.y * tile_size

	_cursor_position.x = clampi(x, 0, preview_width - 1)
	_cursor_position.y = clampi(y, 0, preview_height - 1)

	_update_cursor_visibility()
	_update_cursor_display()


func _get_material_for_color(color_idx: int) -> Material:
	if color_idx in _cell_materials:
		return _cell_materials[color_idx]

	var mat = StandardMaterial3D.new()
	var color = palette[color_idx] if color_idx < palette.size() else Color.WHITE
	mat.albedo_color = color
	mat.roughness = 0.9
	mat.metallic = 0.0

	_cell_materials[color_idx] = mat
	return mat


## Find the nearest grid cell to a world position
## Returns { valid: bool, x: int, y: int, world_pos: Vector3, distance: float }
func _find_nearest_cell(world_pos: Vector3) -> Dictionary:
	var result = {
		"valid": false,
		"x": -1,
		"y": -1,
		"world_pos": Vector3.ZERO,
		"distance": INF
	}

	if _cell_snap_positions.is_empty() or not _editor_container:
		return result

	var snap_threshold = cell_size * 1.2  # Allow some tolerance

	var best_distance = snap_threshold
	var best_x = -1
	var best_y = -1
	var best_world_pos = Vector3.ZERO

	for y in range(tile_size):
		for x in range(tile_size):
			var local_pos = _cell_snap_positions[y][x]
			var cell_world_pos = _editor_container.global_transform * local_pos
			var distance = world_pos.distance_to(cell_world_pos)

			if distance < best_distance:
				best_distance = distance
				best_x = x
				best_y = y
				best_world_pos = cell_world_pos

	if best_x >= 0:
		result.valid = true
		result.x = best_x
		result.y = best_y
		result.world_pos = best_world_pos
		result.distance = best_distance

	return result


## Play snap sound effect
func _play_snap_sound() -> void:
	# Could add AudioStreamPlayer3D here
	pass


## Set a cell's color
func set_cell(x: int, y: int, color_idx: int) -> void:
	if x < 0 or x >= tile_size or y < 0 or y >= tile_size:
		return
	if color_idx < 0 or color_idx >= palette.size():
		return

	_grid_data[y][x] = color_idx

	# Update visual
	if y < _editor_cells.size() and x < _editor_cells[y].size():
		var cell = _editor_cells[y][x]
		cell.material_override = _get_material_for_color(color_idx)

	cell_changed.emit(x, y, color_idx)
	_update_preview()


## Get a cell's color
func get_cell(x: int, y: int) -> int:
	if x < 0 or x >= tile_size or y < 0 or y >= tile_size:
		return 0
	return _grid_data[y][x]


## Select a palette color (for keyboard shortcuts)
func select_color(color_idx: int) -> void:
	if color_idx < 0 or color_idx >= palette.size():
		return
	selected_color = color_idx
	color_selected.emit(color_idx)


## Remove a placed cube from a cell (when picking up)
func remove_cube_from_cell(x: int, y: int) -> void:
	var key = Vector2i(x, y)
	if key in _placed_cubes:
		_placed_cubes.erase(key)


## Register a placed cube at a cell
func register_cube_at_cell(x: int, y: int, cube: Node3D) -> void:
	var key = Vector2i(x, y)
	# If there's already a cube here, remove it
	if key in _placed_cubes:
		var old_cube = _placed_cubes[key]
		if is_instance_valid(old_cube):
			old_cube.queue_free()
	_placed_cubes[key] = cube


## Update the preview mesh based on current pattern and repeat mode
func _update_preview() -> void:
	if not _preview_mesh or _grid_data.is_empty():
		return

	# Generate tiled image
	var preview_width = preview_repeats.x * tile_size
	var preview_height = preview_repeats.y * tile_size

	var image = Image.create(preview_width, preview_height, false, Image.FORMAT_RGBA8)

	for py in range(preview_height):
		for px in range(preview_width):
			var color_idx = _get_tiled_color(px, py)
			var color = palette[color_idx] if color_idx < palette.size() else Color.WHITE
			image.set_pixel(px, py, color)

	# Create texture
	var texture = ImageTexture.create_from_image(image)

	# Create mesh with texture
	var quad = QuadMesh.new()
	quad.size = Vector2(
		preview_width * cell_size,
		preview_height * cell_size
	)
	_preview_mesh.mesh = quad

	var mat = StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST  # Pixel art look
	mat.roughness = 0.95
	_preview_mesh.material_override = mat


## Get the color index for a position in the tiled pattern
func _get_tiled_color(px: int, py: int) -> int:
	# Use WallpaperGroups when in wallpaper mode
	if symmetry_mode == SymmetryMode.WALLPAPER:
		return WallpaperGroups.get_symmetric_color(px, py, tile_size, _grid_data, wallpaper_group)

	var tx: int  # Tile-local x
	var ty: int  # Tile-local y

	match repeat_mode:
		RepeatMode.SIMPLE:
			tx = px % tile_size
			ty = py % tile_size

		RepeatMode.MIRROR_X:
			var tile_x = px / tile_size
			tx = px % tile_size
			if tile_x % 2 == 1:
				tx = tile_size - 1 - tx
			ty = py % tile_size

		RepeatMode.MIRROR_Y:
			tx = px % tile_size
			var tile_y = py / tile_size
			ty = py % tile_size
			if tile_y % 2 == 1:
				ty = tile_size - 1 - ty

		RepeatMode.MIRROR_XY:
			var tile_x = px / tile_size
			var tile_y = py / tile_size
			tx = px % tile_size
			ty = py % tile_size
			if tile_x % 2 == 1:
				tx = tile_size - 1 - tx
			if tile_y % 2 == 1:
				ty = tile_size - 1 - ty

		RepeatMode.ROTATE_90:
			var tile_idx = (px / tile_size + py / tile_size) % 4
			tx = px % tile_size
			ty = py % tile_size
			for i in range(tile_idx):
				var new_tx = tile_size - 1 - ty
				var new_ty = tx
				tx = new_tx
				ty = new_ty

		RepeatMode.ROTATE_180:
			var tile_x = px / tile_size
			var tile_y = py / tile_size
			tx = px % tile_size
			ty = py % tile_size
			if (tile_x + tile_y) % 2 == 1:
				tx = tile_size - 1 - tx
				ty = tile_size - 1 - ty

		RepeatMode.BRICK_X:
			var tile_y = py / tile_size
			var offset = (tile_size / 2) * (tile_y % 2)
			tx = (px + offset) % tile_size
			ty = py % tile_size

		RepeatMode.BRICK_Y:
			var tile_x = px / tile_size
			var offset = (tile_size / 2) * (tile_x % 2)
			tx = px % tile_size
			ty = (py + offset) % tile_size

		RepeatMode.HERRINGBONE:
			var block_x = px / tile_size
			var block_y = py / tile_size
			tx = px % tile_size
			ty = py % tile_size
			if (block_x + block_y) % 2 == 1:
				# Swap and flip for herringbone effect
				var temp = tx
				tx = ty
				ty = temp

		RepeatMode.DIAMOND:
			# Rotate 45 degrees conceptually
			var rotated_x = px + py
			var rotated_y = py - px + preview_repeats.x * tile_size
			tx = abs(rotated_x) % tile_size
			ty = abs(rotated_y) % tile_size

	# Clamp to valid range
	tx = clampi(tx, 0, tile_size - 1)
	ty = clampi(ty, 0, tile_size - 1)

	return _grid_data[ty][tx]


## Cycle to next repeat mode (legacy mode)
func next_repeat_mode() -> void:
	if symmetry_mode == SymmetryMode.WALLPAPER:
		# In wallpaper mode, cycle to next group within current lattice
		next_wallpaper_group()
	else:
		var next = (repeat_mode + 1) % RepeatMode.size()
		repeat_mode = next as RepeatMode
		_update_mode_label()


## Set repeat mode
func set_repeat_mode(mode: RepeatMode) -> void:
	repeat_mode = mode
	_update_mode_label()


## Toggle between legacy and wallpaper symmetry modes
func toggle_symmetry_mode() -> void:
	if symmetry_mode == SymmetryMode.LEGACY:
		symmetry_mode = SymmetryMode.WALLPAPER
	else:
		symmetry_mode = SymmetryMode.LEGACY


## Get current lattice name
func get_current_lattice() -> String:
	var group_info = WallpaperGroups.get_group_info(wallpaper_group)
	return group_info.get("lattice", "oblique")


## Cycle to next lattice type (B/Y buttons in VR)
## This selects the first group in the next lattice
func next_lattice() -> void:
	# Ensure we're in wallpaper mode
	if symmetry_mode != SymmetryMode.WALLPAPER:
		symmetry_mode = SymmetryMode.WALLPAPER

	# Find current lattice index
	var current_lattice = get_current_lattice()
	_current_lattice_index = LATTICE_ORDER.find(current_lattice)
	if _current_lattice_index < 0:
		_current_lattice_index = 0

	# Move to next lattice
	_current_lattice_index = (_current_lattice_index + 1) % LATTICE_ORDER.size()
	var next_lattice_name = LATTICE_ORDER[_current_lattice_index]

	# Select first group in that lattice
	var groups = GROUPS_BY_LATTICE.get(next_lattice_name, [])
	if groups.size() > 0:
		wallpaper_group = groups[0]


## Cycle to previous lattice type
func prev_lattice() -> void:
	# Ensure we're in wallpaper mode
	if symmetry_mode != SymmetryMode.WALLPAPER:
		symmetry_mode = SymmetryMode.WALLPAPER

	# Find current lattice index
	var current_lattice = get_current_lattice()
	_current_lattice_index = LATTICE_ORDER.find(current_lattice)
	if _current_lattice_index < 0:
		_current_lattice_index = 0

	# Move to previous lattice
	_current_lattice_index = (_current_lattice_index - 1 + LATTICE_ORDER.size()) % LATTICE_ORDER.size()
	var prev_lattice_name = LATTICE_ORDER[_current_lattice_index]

	# Select first group in that lattice
	var groups = GROUPS_BY_LATTICE.get(prev_lattice_name, [])
	if groups.size() > 0:
		wallpaper_group = groups[0]


## Cycle to next wallpaper group within current lattice (A/X buttons in VR)
func next_wallpaper_group() -> void:
	# Ensure we're in wallpaper mode
	if symmetry_mode != SymmetryMode.WALLPAPER:
		symmetry_mode = SymmetryMode.WALLPAPER

	var current_lattice = get_current_lattice()
	var groups = GROUPS_BY_LATTICE.get(current_lattice, [])

	if groups.size() == 0:
		return

	# Find current index in the lattice's groups
	var current_idx = groups.find(wallpaper_group)
	if current_idx < 0:
		current_idx = 0

	# Cycle to next
	var next_idx = (current_idx + 1) % groups.size()
	wallpaper_group = groups[next_idx]


## Cycle to previous wallpaper group within current lattice
func prev_wallpaper_group() -> void:
	# Ensure we're in wallpaper mode
	if symmetry_mode != SymmetryMode.WALLPAPER:
		symmetry_mode = SymmetryMode.WALLPAPER

	var current_lattice = get_current_lattice()
	var groups = GROUPS_BY_LATTICE.get(current_lattice, [])

	if groups.size() == 0:
		return

	# Find current index in the lattice's groups
	var current_idx = groups.find(wallpaper_group)
	if current_idx < 0:
		current_idx = 0

	# Cycle to previous
	var prev_idx = (current_idx - 1 + groups.size()) % groups.size()
	wallpaper_group = groups[prev_idx]


## Set a specific wallpaper group
func set_wallpaper_group(group: WallpaperGroups.Group) -> void:
	symmetry_mode = SymmetryMode.WALLPAPER
	wallpaper_group = group


## Clear the grid
func clear_grid() -> void:
	for y in range(tile_size):
		for x in range(tile_size):
			set_cell(x, y, 0)


## Fill the grid with a color
func fill_grid(color_idx: int) -> void:
	for y in range(tile_size):
		for x in range(tile_size):
			set_cell(x, y, color_idx)


## Get the pattern data as a 2D array
func get_pattern_data() -> Array:
	return _grid_data.duplicate(true)


## Set the pattern data from a 2D array
func set_pattern_data(data: Array) -> void:
	if data.size() != tile_size:
		return
	for y in range(tile_size):
		if data[y].size() != tile_size:
			return

	_grid_data = data.duplicate(true)

	# Update visuals
	for y in range(tile_size):
		for x in range(tile_size):
			if y < _editor_cells.size() and x < _editor_cells[y].size():
				var cell = _editor_cells[y][x]
				cell.material_override = _get_material_for_color(_grid_data[y][x])

	_update_preview()


## Spawn a carpet/floor object with the current pattern
func spawn_carpet(at_position: Vector3) -> Node3D:
	var carpet = MeshInstance3D.new()
	carpet.name = "Carpet"

	# Create larger mesh
	var carpet_size = Vector2(
		preview_repeats.x * tile_size * cell_size * 2,
		preview_repeats.y * tile_size * cell_size * 2
	)

	var quad = QuadMesh.new()
	quad.size = carpet_size
	carpet.mesh = quad

	# Generate high-res texture
	var tex_size = preview_repeats.x * tile_size * 4  # Higher resolution
	var image = Image.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)

	for py in range(tex_size):
		for px in range(tex_size):
			# Map to pattern coordinates
			var pattern_x = int(float(px) / tex_size * preview_repeats.x * tile_size)
			var pattern_y = int(float(py) / tex_size * preview_repeats.y * tile_size)
			var color_idx = _get_tiled_color(pattern_x, pattern_y)
			var color = palette[color_idx] if color_idx < palette.size() else Color.WHITE
			image.set_pixel(px, py, color)

	var texture = ImageTexture.create_from_image(image)

	var mat = StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.roughness = 0.95
	carpet.material_override = mat

	# Rotate to lie flat on floor
	carpet.rotation_degrees.x = -90

	carpet.global_position = at_position

	# Add to scene
	var grid_scene = _find_grid_scene()
	if grid_scene:
		grid_scene.add_child(carpet)
	else:
		get_tree().current_scene.add_child(carpet)

	return carpet


func _find_grid_scene() -> Node:
	var current = self
	while current:
		if current.name == "GridScene":
			return current
		current = current.get_parent()
	return null


func _rebuild_grid() -> void:
	# Clear existing
	if _editor_container:
		_editor_container.queue_free()
	_editor_cells.clear()
	_cell_snap_positions.clear()
	_cell_materials.clear()

	# Clear placed cubes
	for cube in _placed_cubes.values():
		if is_instance_valid(cube):
			cube.queue_free()
	_placed_cubes.clear()

	# Rebuild
	_initialize_grid_data()
	call_deferred("_create_editor_grid")
	call_deferred("_update_preview")


## VR input handling - pointer click (legacy, cubes are now drag-and-drop)
func _on_pointer_pressed(_position: Vector3) -> void:
	pass  # Interaction is now via grabbable cubes


## Keyboard input for mode cycling
## VR mapping: B/Y = lattice (up/down), A/X = group within lattice (left/right)
## Keyboard: Tab = next mode, W = toggle symmetry mode, Q/E = lattice, A/D = group
func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return

	if event is InputEventKey:
		var key = event as InputEventKey
		if key.pressed and not key.echo:
			if key.keycode == KEY_TAB:
				next_repeat_mode()
			elif key.keycode == KEY_W:
				# Toggle between legacy and wallpaper modes
				toggle_symmetry_mode()
			elif key.keycode == KEY_Q:
				# Previous lattice (like B button in VR)
				prev_lattice()
			elif key.keycode == KEY_E:
				# Next lattice (like Y button in VR)
				next_lattice()
			elif key.keycode == KEY_A:
				# Previous group in lattice (like X button in VR)
				prev_wallpaper_group()
			elif key.keycode == KEY_D:
				# Next group in lattice (like A button in VR)
				next_wallpaper_group()
			elif key.keycode >= KEY_1 and key.keycode <= KEY_8:
				select_color(key.keycode - KEY_1)
			# Cursor controls
			elif key.keycode == KEY_SPACE:
				cursor_toggle()
			elif key.keycode == KEY_C:
				# Toggle cursor visibility
				cursor_enabled = not cursor_enabled
			elif key.keycode == KEY_RIGHT:
				cursor_step()
			elif key.keycode == KEY_LEFT:
				cursor_step_back()
			elif key.keycode == KEY_UP:
				# Move cursor up one row
				var preview_width = preview_repeats.x * tile_size
				cursor_goto(_cursor_position.x, _cursor_position.y - 1)
			elif key.keycode == KEY_DOWN:
				# Move cursor down one row
				cursor_goto(_cursor_position.x, _cursor_position.y + 1)
			elif key.keycode == KEY_HOME:
				cursor_goto(0, 0)
			elif key.keycode == KEY_END:
				cursor_stop()


## VR Controller button handling
## Call this from XRController3D button_pressed signal
## button: "ax_button", "by_button", "primary_click", "secondary_click", etc.
func handle_vr_button(button: String, controller_name: String) -> void:
	match button:
		"by_button":
			# B/Y cycles lattices
			if controller_name.contains("left"):
				prev_lattice()  # Left hand B = previous
			else:
				next_lattice()  # Right hand Y = next
		"ax_button":
			# A/X cycles groups within lattice
			if controller_name.contains("left"):
				prev_wallpaper_group()  # Left hand X = previous
			else:
				next_wallpaper_group()  # Right hand A = next
		"primary_click":
			# Trigger click - could toggle symmetry mode
			toggle_symmetry_mode()


## Apply configuration from grid system / artifact registry
## Accepts explicit names: "mirror", "4x4", "brick", etc.
## Shorthand: #mirror, #4x4, #8x8, #brick, #herringbone
## Wallpaper groups: #p1, #p2, #pm, #p4m, #p6m, etc. or wallpaper_group: "p4m"
func apply_grid_config(config_data: Dictionary) -> void:
	print("PatternTilePuzzle: Applying config: %s" % config_data)

	var needs_rebuild := false

	# Check for tile_size
	if config_data.has("tile_size"):
		var new_size = _parse_tile_size(config_data["tile_size"])
		if new_size != tile_size:
			tile_size = new_size
			needs_rebuild = true

	# Check for repeat_mode
	if config_data.has("repeat_mode"):
		var new_mode = _parse_repeat_mode(config_data["repeat_mode"])
		if new_mode != repeat_mode:
			repeat_mode = new_mode

	# Check for symmetry_mode
	if config_data.has("symmetry_mode"):
		var mode_str = str(config_data["symmetry_mode"]).to_lower()
		if mode_str == "wallpaper" or mode_str == "1":
			symmetry_mode = SymmetryMode.WALLPAPER
		else:
			symmetry_mode = SymmetryMode.LEGACY

	# Check for wallpaper_group
	if config_data.has("wallpaper_group"):
		var parsed_group = _parse_wallpaper_group(config_data["wallpaper_group"])
		if parsed_group >= 0:
			wallpaper_group = parsed_group as WallpaperGroups.Group
			symmetry_mode = SymmetryMode.WALLPAPER  # Auto-switch to wallpaper mode

	# Check for cursor settings
	if config_data.has("cursor_enabled"):
		cursor_enabled = _to_bool(config_data["cursor_enabled"])
	if config_data.has("cursor_speed"):
		cursor_speed = float(config_data["cursor_speed"])
	if config_data.has("show_index_math"):
		show_index_math = _to_bool(config_data["show_index_math"])

	# Shorthand configs: just the key name without value
	# e.g., #mirror, #4x4, #brick, #p4m, #hexagonal, #cursor
	# Grid system may set value to true (boolean), "" (string), or null
	for key in config_data.keys():
		var val = config_data[key]
		var is_shorthand = val == null or (val is bool and val == true) or (val is String and val == "")
		if is_shorthand:
			var parsed = _parse_shorthand(key)
			if parsed.has("tile_size") and parsed["tile_size"] != tile_size:
				tile_size = parsed["tile_size"]
				needs_rebuild = true
			if parsed.has("repeat_mode") and parsed["repeat_mode"] != repeat_mode:
				repeat_mode = parsed["repeat_mode"]
			if parsed.has("wallpaper_group"):
				wallpaper_group = parsed["wallpaper_group"]
				symmetry_mode = SymmetryMode.WALLPAPER
			if parsed.has("lattice"):
				# Set to first group in that lattice
				var groups = GROUPS_BY_LATTICE.get(parsed["lattice"], [])
				if groups.size() > 0:
					wallpaper_group = groups[0]
					symmetry_mode = SymmetryMode.WALLPAPER
			if parsed.has("cursor_enabled"):
				cursor_enabled = parsed["cursor_enabled"]

	if needs_rebuild:
		_rebuild_grid()


## Parse tile size from string or number
func _parse_tile_size(value) -> int:
	if value is int:
		return clampi(value, 2, 16)

	var size_str = str(value).to_lower().strip_edges()

	# Handle "4x4", "8x8" format
	if "x" in size_str:
		var parts = size_str.split("x")
		if parts.size() > 0 and parts[0].is_valid_int():
			return clampi(int(parts[0]), 2, 16)

	# Handle plain number
	if size_str.is_valid_int():
		return clampi(int(size_str), 2, 16)

	return tile_size  # Keep current


## Parse repeat mode from string or number
func _parse_repeat_mode(value) -> RepeatMode:
	if value is int:
		return clampi(value, 0, RepeatMode.size() - 1) as RepeatMode

	var mode_str = str(value).to_lower().strip_edges()

	match mode_str:
		"simple", "0":
			return RepeatMode.SIMPLE
		"mirror_x", "mirrorx", "1":
			return RepeatMode.MIRROR_X
		"mirror_y", "mirrory", "2":
			return RepeatMode.MIRROR_Y
		"mirror_xy", "mirrorxy", "mirror", "kaleidoscope", "3":
			return RepeatMode.MIRROR_XY
		"rotate_90", "rotate90", "4":
			return RepeatMode.ROTATE_90
		"rotate_180", "rotate180", "5":
			return RepeatMode.ROTATE_180
		"brick_x", "brickx", "brick", "6":
			return RepeatMode.BRICK_X
		"brick_y", "bricky", "7":
			return RepeatMode.BRICK_Y
		"herringbone", "8":
			return RepeatMode.HERRINGBONE
		"diamond", "9":
			return RepeatMode.DIAMOND
		_:
			if mode_str.is_valid_int():
				return clampi(int(mode_str), 0, RepeatMode.size() - 1) as RepeatMode
			push_warning("PatternTilePuzzle: Unknown repeat_mode '%s'" % value)
			return repeat_mode


## Parse wallpaper group from string
## Returns group enum value or -1 if not found
func _parse_wallpaper_group(value) -> int:
	if value is int:
		if value >= 0 and value < WallpaperGroups.Group.size():
			return value
		return -1

	var group_str = str(value).to_lower().strip_edges()

	# Map group names to enum values
	var group_map = {
		"p1": WallpaperGroups.Group.P1,
		"p2": WallpaperGroups.Group.P2,
		"pm": WallpaperGroups.Group.PM,
		"pg": WallpaperGroups.Group.PG,
		"cm": WallpaperGroups.Group.CM,
		"pmm": WallpaperGroups.Group.PMM,
		"pmg": WallpaperGroups.Group.PMG,
		"pgg": WallpaperGroups.Group.PGG,
		"cmm": WallpaperGroups.Group.CMM,
		"p4": WallpaperGroups.Group.P4,
		"p4m": WallpaperGroups.Group.P4M,
		"p4g": WallpaperGroups.Group.P4G,
		"p3": WallpaperGroups.Group.P3,
		"p3m1": WallpaperGroups.Group.P3M1,
		"p31m": WallpaperGroups.Group.P31M,
		"p6": WallpaperGroups.Group.P6,
		"p6m": WallpaperGroups.Group.P6M
	}

	if group_str in group_map:
		return group_map[group_str]

	return -1


## Parse shorthand config (just key name, no value)
## e.g., "mirror" -> {repeat_mode: MIRROR_XY}
## e.g., "4x4" -> {tile_size: 4}
## e.g., "p4m" -> {wallpaper_group: P4M}
## e.g., "hexagonal" -> {lattice: "hexagonal"}
func _parse_shorthand(key: String) -> Dictionary:
	var result := {}
	var k = key.to_lower().strip_edges()

	# Tile size shorthands
	if k == "4x4" or k == "4":
		result["tile_size"] = 4
	elif k == "8x8" or k == "8":
		result["tile_size"] = 8
	elif k == "2x2" or k == "2":
		result["tile_size"] = 2
	elif k == "16x16" or k == "16":
		result["tile_size"] = 16

	# Repeat mode shorthands
	if k == "simple":
		result["repeat_mode"] = RepeatMode.SIMPLE
	elif k == "mirror" or k == "mirror_xy" or k == "kaleidoscope":
		result["repeat_mode"] = RepeatMode.MIRROR_XY
	elif k == "mirror_x":
		result["repeat_mode"] = RepeatMode.MIRROR_X
	elif k == "mirror_y":
		result["repeat_mode"] = RepeatMode.MIRROR_Y
	elif k == "rotate_90" or k == "rotate90":
		result["repeat_mode"] = RepeatMode.ROTATE_90
	elif k == "rotate_180" or k == "rotate180":
		result["repeat_mode"] = RepeatMode.ROTATE_180
	elif k == "brick" or k == "brick_x":
		result["repeat_mode"] = RepeatMode.BRICK_X
	elif k == "brick_y":
		result["repeat_mode"] = RepeatMode.BRICK_Y
	elif k == "herringbone":
		result["repeat_mode"] = RepeatMode.HERRINGBONE
	elif k == "diamond":
		result["repeat_mode"] = RepeatMode.DIAMOND

	# Wallpaper group shorthands
	var parsed_group = _parse_wallpaper_group(k)
	if parsed_group >= 0:
		result["wallpaper_group"] = parsed_group as WallpaperGroups.Group

	# Lattice type shorthands
	if k in LATTICE_ORDER:
		result["lattice"] = k

	# Cursor shorthand
	if k == "cursor" or k == "index" or k == "cursor_enabled":
		result["cursor_enabled"] = true

	return result


## Convert value to boolean
func _to_bool(value) -> bool:
	if value is bool:
		return value
	var s = str(value).to_lower().strip_edges()
	return s == "true" or s == "1" or s == "yes" or s == "on"
