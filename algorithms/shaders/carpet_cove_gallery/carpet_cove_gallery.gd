## CarpetCoveGallery — Grid-based gallery of pattern cove displays
##
## Uses the 1m grid system: each cove display occupies a known number of
## grid cells. The gallery lays out coves in rows along the corridor,
## each showing a different wallpaper pattern on its curved surface.
##
## Grid layout (top view, each cell = 1m):
##
##   [cove][cove][cove]     ← back row (wall-mounted, facing player)
##   [    walk space   ]    ← 2m aisle
##   [cove][cove][cove]     ← front row (facing back wall)
##
## The curved cove form means the pattern flows from the floor surface
## up through a smooth curve onto the vertical back — like a photo backdrop.
extends Node3D
class_name CarpetCoveGallery

const WALLPAPER_SHADER = preload("res://commons/resourses/shaders/wallpaper_tile.gdshader")
## CoveDisplay scene — loaded at runtime to avoid circular class resolution
var _cove_scene: PackedScene

# Grid constants
const CELL_SIZE: float = 1.0  # 1 meter per grid cell

# Neon palettes (same as pixel gallery + some new ones)
const PALETTES: Array = [
	[Color(0.05, 0.05, 0.07), Color(0.0, 0.95, 0.3), Color(1.0, 0.0, 0.6), Color(0.0, 0.5, 1.0), Color(1.0, 1.0, 0.0)],
	[Color(0.0, 0.0, 0.0), Color(0.95, 0.15, 0.15), Color(1.0, 0.55, 0.0), Color(1.0, 0.85, 0.0), Color(0.6, 0.0, 0.3)],
	[Color(0.9, 0.9, 0.92), Color(0.0, 0.2, 0.8), Color(0.0, 0.7, 0.85), Color(0.5, 0.0, 0.8), Color(0.95, 0.0, 0.5)],
	[Color(0.0, 0.0, 0.0), Color(0.0, 0.9, 0.2), Color(0.3, 1.0, 0.0), Color(0.0, 0.4, 0.15), Color(1.0, 0.0, 1.0)],
	[Color(1.0, 1.0, 1.0), Color(1.0, 0.0, 0.5), Color(0.0, 0.8, 1.0), Color(1.0, 0.7, 0.0), Color(0.5, 0.0, 1.0)],
	[Color(0.12, 0.12, 0.12), Color(0.85, 0.85, 0.85), Color(0.95, 0.2, 0.1), Color(0.4, 0.4, 0.4), Color(1.0, 0.8, 0.0)],
	[Color(0.06, 0.0, 0.12), Color(1.0, 0.3, 0.7), Color(0.3, 0.8, 1.0), Color(0.6, 0.2, 0.9), Color(0.0, 1.0, 0.7)],
	[Color(0.95, 0.92, 0.85), Color(0.9, 0.15, 0.1), Color(0.0, 0.25, 0.6), Color(1.0, 0.8, 0.0), Color(0.1, 0.1, 0.1)],
	# Italian textile
	[Color(0.95, 0.92, 0.85), Color(0.8, 0.2, 0.15), Color(0.15, 0.25, 0.5), Color(0.7, 0.55, 0.2), Color(0.1, 0.1, 0.12)],
	# Synthwave
	[Color(0.05, 0.0, 0.1), Color(1.0, 0.0, 0.4), Color(0.0, 0.9, 1.0), Color(0.9, 0.0, 0.9), Color(0.0, 0.3, 0.6)],
]

# Gallery config
@export var corridor_cells_x: int = 12    # Width in grid cells
@export var corridor_cells_z: int = 30    # Length in grid cells
@export var cove_width_cells: int = 3     # Each cove is 3m wide
@export var cove_depth_cells: int = 2     # Each cove is 2m deep (floor+curve)
@export var aisle_cells: int = 3          # 3m walkway between rows

var _rng := RandomNumberGenerator.new()
var _cove_count := 0

func _ready() -> void:
	_rng.seed = 77
	_cove_scene = load("res://algorithms/shaders/carpet_cove_gallery/cove_display.tscn")
	_build_floor()
	_build_cove_rows()
	_build_lighting()
	print("[CarpetCoveGallery] Built — %d cove displays on %dx%d grid" % [_cove_count, corridor_cells_x, corridor_cells_z])

# ═══════════════════════════════════════════════════════════════════
# FLOOR — dark gallery floor, grid-aligned
# ═══════════════════════════════════════════════════════════════════

func _build_floor() -> void:
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = PlaneMesh.new()
	(floor_mesh.mesh as PlaneMesh).size = Vector2(
		corridor_cells_x * CELL_SIZE,
		corridor_cells_z * CELL_SIZE
	)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.08, 0.09)
	mat.roughness = 0.9
	floor_mesh.material_override = mat
	floor_mesh.position = Vector3(0, -0.005, 0)
	add_child(floor_mesh)

	# Gallery walls (white, like a real gallery)
	for side in [-1, 1]:
		var wall := MeshInstance3D.new()
		wall.mesh = BoxMesh.new()
		(wall.mesh as BoxMesh).size = Vector3(0.1, 4.0, corridor_cells_z * CELL_SIZE)
		var wmat := StandardMaterial3D.new()
		wmat.albedo_color = Color(0.93, 0.91, 0.88)
		wmat.roughness = 0.85
		wall.material_override = wmat
		wall.position = Vector3(side * corridor_cells_x * CELL_SIZE * 0.5, 2.0, 0)
		add_child(wall)

# ═══════════════════════════════════════════════════════════════════
# COVE ROWS — placed on the 1m grid
# ═══════════════════════════════════════════════════════════════════

func _build_cove_rows() -> void:
	# How many coves fit across the width?
	var coves_per_row: int = corridor_cells_x / cove_width_cells
	var row_width: float = coves_per_row * cove_width_cells * CELL_SIZE
	var start_x: float = -row_width * 0.5 + cove_width_cells * CELL_SIZE * 0.5

	# Total depth per double-row: cove + aisle + cove
	var double_row_depth: int = cove_depth_cells + aisle_cells + cove_depth_cells
	var z_cursor: float = -corridor_cells_z * CELL_SIZE * 0.5 + CELL_SIZE

	while z_cursor < corridor_cells_z * CELL_SIZE * 0.5 - float(double_row_depth):
		# Back row — coves facing forward (toward +Z)
		for i in coves_per_row:
			var x: float = start_x + i * cove_width_cells * CELL_SIZE
			_place_cove(
				Vector3(x, 0, z_cursor),
				0.0,  # Facing forward
				_cove_count
			)

		# Front row — coves facing backward (toward -Z)
		var front_z: float = z_cursor + float(cove_depth_cells + aisle_cells) * CELL_SIZE
		for i in coves_per_row:
			var x: float = start_x + i * cove_width_cells * CELL_SIZE
			_place_cove(
				Vector3(x, 0, front_z + float(cove_depth_cells) * CELL_SIZE),
				180.0,  # Facing backward
				_cove_count
			)

		z_cursor += float(double_row_depth + 1) * CELL_SIZE  # +1 gap between sections

func _place_cove(pos: Vector3, y_rot: float, seed_val: int) -> void:
	var cove: Node3D = _cove_scene.instantiate()
	cove.cove_width = cove_width_cells * CELL_SIZE
	cove.floor_depth = (cove_depth_cells - 0.5) * CELL_SIZE  # Leave room for curve
	cove.wall_height = 2.5
	cove.cove_radius = 0.5
	cove.curve_segments = 16
	cove.position = pos
	cove.rotation_degrees.y = y_rot
	add_child(cove)

	# Build shader material for this cove
	var mat := _make_pattern_material(seed_val)
	# Defer material application so mesh is built first
	cove.call_deferred("apply_shader_material", mat)
	_cove_count += 1

func _make_pattern_material(seed_val: int) -> ShaderMaterial:
	var palette: Array = PALETTES[seed_val % PALETTES.size()]
	var group_id: int = _pick_group(seed_val)
	var domain: Array = _generate_domain(seed_val)

	# Build 8x8 domain texture
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y in 8:
		for x in 8:
			var idx: int = domain[y][x]
			var color: Color = palette[idx] if idx < palette.size() else Color.WHITE
			img.set_pixel(x, y, color)
	var tex := ImageTexture.create_from_image(img)

	var mat := ShaderMaterial.new()
	mat.shader = WALLPAPER_SHADER
	mat.set_shader_parameter("domain_texture", tex)
	mat.set_shader_parameter("wallpaper_group", group_id)
	mat.set_shader_parameter("tile_scale", _rng.randf_range(4.0, 8.0))
	mat.set_shader_parameter("grout_width", _rng.randf_range(0.0, 0.015))
	mat.set_shader_parameter("grout_color", Vector3(0.05, 0.05, 0.06))
	mat.set_shader_parameter("noise_distort", 0.0)
	# Some coves get aging
	if _rng.randf() < 0.4:
		mat.set_shader_parameter("wear_amount", _rng.randf_range(0.1, 0.4))
		mat.set_shader_parameter("dust_amount", _rng.randf_range(0.05, 0.3))
		mat.set_shader_parameter("crack_density", _rng.randf_range(0.0, 0.3))
	else:
		mat.set_shader_parameter("wear_amount", 0.0)
		mat.set_shader_parameter("dust_amount", 0.0)
		mat.set_shader_parameter("crack_density", 0.0)
	mat.set_shader_parameter("fade_amount", 0.0)
	mat.set_shader_parameter("stain_amount", 0.0)
	mat.set_shader_parameter("chip_amount", 0.0)
	return mat

# ═══════════════════════════════════════════════════════════════════
# LIGHTING
# ═══════════════════════════════════════════════════════════════════

func _build_lighting() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.12, 0.14)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.95, 0.93, 0.9)
	env.ambient_light_energy = 0.5
	env_node.environment = env
	add_child(env_node)

	# Track lighting over each row of coves
	var light_spacing: float = 4.0
	var light_count: int = int(corridor_cells_z * CELL_SIZE / light_spacing)
	for i in light_count:
		var z_pos: float = -corridor_cells_z * CELL_SIZE * 0.5 + (float(i) + 0.5) * light_spacing
		var spot := SpotLight3D.new()
		spot.position = Vector3(0, 3.8, z_pos)
		spot.rotation_degrees.x = -75
		spot.light_energy = 3.5
		spot.light_color = Color(0.98, 0.95, 0.9)
		spot.spot_range = 6.0
		spot.spot_angle = 50.0
		spot.shadow_enabled = i % 2 == 0
		add_child(spot)

# ═══════════════════════════════════════════════════════════════════
# PATTERN GENERATORS (same as pixel_carpet_gallery)
# ═══════════════════════════════════════════════════════════════════

func _generate_domain(seed_val: int) -> Array:
	var gen := RandomNumberGenerator.new()
	gen.seed = seed_val * 7919 + 31
	match seed_val % 8:
		0: return _domain_blocks(gen)
		1: return _domain_stripes(gen)
		2: return _domain_diagonal(gen)
		3: return _domain_cross(gen)
		4: return _domain_concentric(gen)
		5: return _domain_checker(gen)
		6: return _domain_scatter(gen)
		7: return _domain_frame(gen)
		_: return _domain_blocks(gen)

func _domain_blocks(gen: RandomNumberGenerator) -> Array:
	var g := _grid8(0)
	for _i in gen.randi_range(3, 5):
		var x0 := gen.randi_range(0, 5); var y0 := gen.randi_range(0, 5)
		var x1 := gen.randi_range(x0+1, 8); var y1 := gen.randi_range(y0+1, 8)
		var c := gen.randi_range(1, 4)
		for y in range(y0, y1):
			for x in range(x0, x1):
				g[y][x] = c
	return g

func _domain_stripes(gen: RandomNumberGenerator) -> Array:
	var g := _grid8(0); var h := gen.randf() > 0.5; var t := gen.randi_range(1, 3)
	for y in 8:
		for x in 8:
			g[y][x] = ((y if h else x) / t) % 5
	return g

func _domain_diagonal(gen: RandomNumberGenerator) -> Array:
	var g := _grid8(0); var t := gen.randi_range(1, 3)
	for y in 8:
		for x in 8:
			g[y][x] = ((x + y) / t) % 5
	return g

func _domain_cross(gen: RandomNumberGenerator) -> Array:
	var g := _grid8(gen.randi_range(0, 1)); var arm := gen.randi_range(1, 3); var c := gen.randi_range(2, 4)
	for y in 8:
		for x in 8:
			if abs(x - 4) < arm or abs(y - 4) < arm: g[y][x] = c
	return g

func _domain_concentric(_gen: RandomNumberGenerator) -> Array:
	var g := _grid8(0)
	for y in 8:
		for x in 8:
			g[y][x] = mini(mini(x, y), mini(7 - x, 7 - y)) % 5
	return g

func _domain_checker(gen: RandomNumberGenerator) -> Array:
	var g := _grid8(0); var b := gen.randi_range(1, 3)
	var c1 := gen.randi_range(0, 2); var c2 := gen.randi_range(3, 4)
	for y in 8:
		for x in 8:
			g[y][x] = c1 if ((x / b) + (y / b)) % 2 == 0 else c2
	return g

func _domain_scatter(gen: RandomNumberGenerator) -> Array:
	var g := _grid8(gen.randi_range(0, 1))
	for _i in gen.randi_range(12, 20):
		var x := gen.randi_range(0, 7); var y := gen.randi_range(0, 7); var c := gen.randi_range(1, 4)
		g[y][x] = c
		if x + 1 < 8: g[y][x + 1] = c
		if y + 1 < 8: g[y + 1][x] = c
	return g

func _domain_frame(gen: RandomNumberGenerator) -> Array:
	var g := _grid8(gen.randi_range(0, 1)); var b := gen.randi_range(1, 2)
	var oc := gen.randi_range(2, 4)
	for y in 8:
		for x in 8:
			if x < b or x >= 8 - b or y < b or y >= 8 - b: g[y][x] = oc
	return g

func _grid8(fill: int) -> Array:
	var g: Array = []
	for y in 8:
		var row: Array = []
		for x in 8: row.append(fill)
		g.append(row)
	return g

func _pick_group(index: int) -> int:
	var groups: Array = [0, 5, 10, 16, 2, 9, 12, 15, 1, 7, 11, 14, 3, 8, 13, 4, 6]
	return groups[index % groups.size()]

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("corridor_cells_x"):
		corridor_cells_x = int(config_data["corridor_cells_x"])
	if config_data.has("corridor_cells_z"):
		corridor_cells_z = int(config_data["corridor_cells_z"])
	if config_data.has("cove_width_cells"):
		cove_width_cells = int(config_data["cove_width_cells"])
	if config_data.has("aisle_cells"):
		aisle_cells = int(config_data["aisle_cells"])
