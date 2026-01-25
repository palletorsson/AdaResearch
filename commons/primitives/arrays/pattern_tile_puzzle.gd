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
signal color_selected(color_index: int)

## Cube size for grabbable pieces
@export var cube_size_ratio: float = 0.8  # Cube size relative to cell

## Spawn offset for cube dispensers
@export var spawner_offset: Vector3 = Vector3(0.25, 0, 0)

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
	_update_preview()


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


## Cycle to next repeat mode
func next_repeat_mode() -> void:
	var next = (repeat_mode + 1) % RepeatMode.size()
	repeat_mode = next as RepeatMode
	_update_mode_label()


## Set repeat mode
func set_repeat_mode(mode: RepeatMode) -> void:
	repeat_mode = mode
	_update_mode_label()


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
func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return

	if event is InputEventKey:
		var key = event as InputEventKey
		if key.pressed and not key.echo:
			if key.keycode == KEY_TAB:
				next_repeat_mode()
			elif key.keycode >= KEY_1 and key.keycode <= KEY_8:
				select_color(key.keycode - KEY_1)


## Apply configuration from grid system / artifact registry
## Accepts explicit names: "mirror", "4x4", "brick", etc.
## Shorthand: #mirror, #4x4, #8x8, #brick, #herringbone
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

	# Shorthand configs: just the key name without value
	# e.g., #mirror, #4x4, #brick
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


## Parse shorthand config (just key name, no value)
## e.g., "mirror" -> {repeat_mode: MIRROR_XY}
## e.g., "4x4" -> {tile_size: 4}
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

	return result
