extends Node3D
class_name ArrayCarpet

## Array Carpet — Display artifact showing the player's tiled pattern as floor art.
##
## Reads the saved pattern from TraceData singleton (saved by PatternTilePuzzle).
## If no pattern is saved yet, shows a default rug motif.
## Live-updates when the player edits their pattern.

# --- Configuration ---

@export var carpet_world_size: Vector2 = Vector2(0.8, 0.8)
@export var carpet_repeats: Vector2i = Vector2i(6, 6)
@export var default_tile_size: int = 4
@export var default_repeat_mode: int = 3  ## MIRROR_XY

## Default palette (same as PatternTilePuzzle)
var _default_palette: Array[Color] = [
	Color(0.95, 0.92, 0.85),  # Cream/natural
	Color(0.8, 0.2, 0.15),    # Deep red
	Color(0.15, 0.25, 0.5),   # Navy blue
	Color(0.7, 0.55, 0.2),    # Gold/ochre
	Color(0.2, 0.4, 0.25),    # Forest green
	Color(0.4, 0.2, 0.15),    # Brown
	Color(0.1, 0.1, 0.12),    # Near black
	Color(0.6, 0.3, 0.5)      # Dusty purple
]

## Default pattern — a handmade 4x4 tile that looks nice with MIRROR_XY
var _default_grid: Array = [
	[1, 3, 3, 2],
	[3, 0, 5, 3],
	[3, 5, 0, 3],
	[2, 3, 3, 1]
]

# --- Internal ---

var _carpet_mesh: MeshInstance3D
var _carpet_material: StandardMaterial3D
var _grid_data: Array = []
var _tile_size: int = 4
var _repeat_mode: int = 3
var _palette: Array = []

# --- Repeat mode constants (matching PatternTilePuzzle.RepeatMode) ---

const SIMPLE = 0
const MIRROR_X = 1
const MIRROR_Y = 2
const MIRROR_XY = 3
const ROTATE_90 = 4
const ROTATE_180 = 5
const BRICK_X = 6
const BRICK_Y = 7
const HERRINGBONE = 8
const DIAMOND = 9


func _ready() -> void:
	_create_carpet_mesh()
	_load_pattern_and_generate()

	# Connect to TraceData for live updates
	var trace_data = get_node_or_null("/root/TraceData")
	if trace_data and trace_data.has_signal("pattern_saved"):
		trace_data.pattern_saved.connect(_on_pattern_updated)


func _create_carpet_mesh() -> void:
	_carpet_mesh = MeshInstance3D.new()
	_carpet_mesh.name = "CarpetMesh"

	var quad = QuadMesh.new()
	quad.size = carpet_world_size
	_carpet_mesh.mesh = quad

	# Lie flat on the floor
	_carpet_mesh.rotation_degrees.x = -90
	_carpet_mesh.position.y = 0.005  # Slight offset to avoid z-fighting

	# Material
	_carpet_material = StandardMaterial3D.new()
	_carpet_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_carpet_material.roughness = 0.9
	_carpet_material.metallic = 0.0
	_carpet_mesh.material_override = _carpet_material

	add_child(_carpet_mesh)


func _load_pattern_and_generate() -> void:
	var trace_data = get_node_or_null("/root/TraceData")

	if trace_data and trace_data.has_method("has_pattern") and trace_data.has_pattern():
		var pattern: Dictionary = trace_data.get_pattern()
		_grid_data = pattern.get("grid_data", _default_grid).duplicate(true)
		_tile_size = int(pattern.get("tile_size", default_tile_size))
		_repeat_mode = int(pattern.get("repeat_mode", default_repeat_mode))
		_palette = pattern.get("palette", _default_palette).duplicate()
	else:
		# Use default fallback
		_grid_data = _default_grid.duplicate(true)
		_tile_size = default_tile_size
		_repeat_mode = default_repeat_mode
		_palette = Array(_default_palette)

	_generate_texture()


func _generate_texture() -> void:
	if _grid_data.is_empty() or _tile_size <= 0:
		return

	var tex_w: int = carpet_repeats.x * _tile_size
	var tex_h: int = carpet_repeats.y * _tile_size
	if tex_w <= 0 or tex_h <= 0:
		return

	var image: Image = Image.create(tex_w, tex_h, false, Image.FORMAT_RGBA8)

	for py in range(tex_h):
		for px in range(tex_w):
			var color_idx: int = _get_tiled_color(px, py)
			var color: Color = _palette[color_idx] if color_idx < _palette.size() else Color.WHITE
			image.set_pixel(px, py, color)

	var texture: ImageTexture = ImageTexture.create_from_image(image)
	_carpet_material.albedo_texture = texture


func _on_pattern_updated() -> void:
	_load_pattern_and_generate()


## Get the color index for a position in the tiled pattern.
## Tiling math copied from PatternTilePuzzle._get_tiled_color().
func _get_tiled_color(px: int, py: int) -> int:
	var tx: int
	var ty: int

	match _repeat_mode:
		SIMPLE:
			tx = px % _tile_size
			ty = py % _tile_size

		MIRROR_X:
			var tile_x = px / _tile_size
			tx = px % _tile_size
			if tile_x % 2 == 1:
				tx = _tile_size - 1 - tx
			ty = py % _tile_size

		MIRROR_Y:
			tx = px % _tile_size
			var tile_y = py / _tile_size
			ty = py % _tile_size
			if tile_y % 2 == 1:
				ty = _tile_size - 1 - ty

		MIRROR_XY:
			var tile_x = px / _tile_size
			var tile_y = py / _tile_size
			tx = px % _tile_size
			ty = py % _tile_size
			if tile_x % 2 == 1:
				tx = _tile_size - 1 - tx
			if tile_y % 2 == 1:
				ty = _tile_size - 1 - ty

		ROTATE_90:
			var tile_idx = (px / _tile_size + py / _tile_size) % 4
			tx = px % _tile_size
			ty = py % _tile_size
			for i in range(tile_idx):
				var new_tx = _tile_size - 1 - ty
				var new_ty = tx
				tx = new_tx
				ty = new_ty

		ROTATE_180:
			var tile_x = px / _tile_size
			var tile_y = py / _tile_size
			tx = px % _tile_size
			ty = py % _tile_size
			if (tile_x + tile_y) % 2 == 1:
				tx = _tile_size - 1 - tx
				ty = _tile_size - 1 - ty

		BRICK_X:
			var tile_y = py / _tile_size
			var offset = (_tile_size / 2) * (tile_y % 2)
			tx = (px + offset) % _tile_size
			ty = py % _tile_size

		BRICK_Y:
			var tile_x = px / _tile_size
			var offset = (_tile_size / 2) * (tile_x % 2)
			tx = px % _tile_size
			ty = (py + offset) % _tile_size

		HERRINGBONE:
			var block_x = px / _tile_size
			var block_y = py / _tile_size
			tx = px % _tile_size
			ty = py % _tile_size
			if (block_x + block_y) % 2 == 1:
				var temp = tx
				tx = ty
				ty = temp

		DIAMOND:
			var rotated_x = px + py
			var rotated_y = py - px + carpet_repeats.x * _tile_size
			tx = abs(rotated_x) % _tile_size
			ty = abs(rotated_y) % _tile_size

		_:
			tx = px % _tile_size
			ty = py % _tile_size

	# Clamp to valid range
	tx = clampi(tx, 0, _tile_size - 1)
	ty = clampi(ty, 0, _tile_size - 1)

	if ty < _grid_data.size() and tx < _grid_data[ty].size():
		return _grid_data[ty][tx]
	return 0


## Grid system integration — accept configuration from map data
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("tile_size"):
		default_tile_size = int(config_data["tile_size"])
	if config_data.has("repeat_mode"):
		default_repeat_mode = int(config_data["repeat_mode"])
	if config_data.has("carpet_repeats_x"):
		carpet_repeats.x = int(config_data["carpet_repeats_x"])
	if config_data.has("carpet_repeats_y"):
		carpet_repeats.y = int(config_data["carpet_repeats_y"])

	# Reload with new defaults
	_load_pattern_and_generate()
