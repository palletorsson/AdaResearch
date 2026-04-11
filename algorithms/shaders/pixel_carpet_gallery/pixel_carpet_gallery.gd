## PixelCarpetGallery — A corridor of bold pixel-art carpets
##
## Inspired by Art to Eat textile installations: a walkable gallery hallway
## completely covered in large woven pixel carpets — floor, walls, ceiling.
## Each carpet uses a different procedural domain pattern, wallpaper group,
## and neon palette. All rendered via wallpaper_tile.gdshader on the GPU.
extends Node3D
class_name PixelCarpetGallery

const WALLPAPER_SHADER = preload("res://commons/resourses/shaders/wallpaper_tile.gdshader")

# ── Neon / Art-to-Eat palette sets ──────────────────────────────────
# Each set: [background, primary, secondary, accent1, accent2]
const PALETTES: Array = [
	# Electric pop
	[Color(0.05, 0.05, 0.07), Color(0.0, 0.95, 0.3), Color(1.0, 0.0, 0.6), Color(0.0, 0.5, 1.0), Color(1.0, 1.0, 0.0)],
	# Hot sunset
	[Color(0.0, 0.0, 0.0), Color(0.95, 0.15, 0.15), Color(1.0, 0.55, 0.0), Color(1.0, 0.85, 0.0), Color(0.6, 0.0, 0.3)],
	# Cool digital
	[Color(0.9, 0.9, 0.92), Color(0.0, 0.2, 0.8), Color(0.0, 0.7, 0.85), Color(0.5, 0.0, 0.8), Color(0.95, 0.0, 0.5)],
	# Neon forest
	[Color(0.0, 0.0, 0.0), Color(0.0, 0.9, 0.2), Color(0.3, 1.0, 0.0), Color(0.0, 0.4, 0.15), Color(1.0, 0.0, 1.0)],
	# Candy stripe
	[Color(1.0, 1.0, 1.0), Color(1.0, 0.0, 0.5), Color(0.0, 0.8, 1.0), Color(1.0, 0.7, 0.0), Color(0.5, 0.0, 1.0)],
	# Brutalist
	[Color(0.12, 0.12, 0.12), Color(0.85, 0.85, 0.85), Color(0.95, 0.2, 0.1), Color(0.4, 0.4, 0.4), Color(1.0, 0.8, 0.0)],
	# Vaporwave
	[Color(0.06, 0.0, 0.12), Color(1.0, 0.3, 0.7), Color(0.3, 0.8, 1.0), Color(0.6, 0.2, 0.9), Color(0.0, 1.0, 0.7)],
	# Bauhaus
	[Color(0.95, 0.92, 0.85), Color(0.9, 0.15, 0.1), Color(0.0, 0.25, 0.6), Color(1.0, 0.8, 0.0), Color(0.1, 0.1, 0.1)],
	# Pixel acid
	[Color(0.0, 0.0, 0.0), Color(0.0, 1.0, 0.0), Color(1.0, 0.0, 0.0), Color(0.0, 0.0, 1.0), Color(1.0, 1.0, 1.0)],
	# Pastel glitch
	[Color(0.95, 0.85, 0.9), Color(0.6, 0.8, 1.0), Color(1.0, 0.7, 0.75), Color(0.7, 1.0, 0.7), Color(0.9, 0.7, 1.0)],
]

# Corridor config — all dimensions in 1m grid units
@export var corridor_length: float = 30.0
@export var corridor_width: float = 6.0
@export var corridor_height: float = 4.0

var _rng := RandomNumberGenerator.new()
var _panel_idx := 0  # Global counter for unique seeds

func _ready() -> void:
	_rng.seed = 42
	_build_corridor_shell()
	_tile_floor()
	_tile_walls()
	_tile_ceiling()
	_build_lighting()
	print("[PixelCarpetGallery] Built — %d carpet panels across %.0fm corridor" % [_panel_idx, corridor_length])

# ═══════════════════════════════════════════════════════════════════
# CORRIDOR SHELL — thin dark backing behind the carpets
# ═══════════════════════════════════════════════════════════════════

func _build_corridor_shell() -> void:
	# Floor substrate
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = PlaneMesh.new()
	(floor_mesh.mesh as PlaneMesh).size = Vector2(corridor_width + 0.5, corridor_length + 1.0)
	floor_mesh.material_override = _flat_mat(Color(0.06, 0.06, 0.07))
	floor_mesh.position = Vector3(0, -0.005, 0)
	add_child(floor_mesh)

	# Wall backing
	for side in [-1, 1]:
		var wall := MeshInstance3D.new()
		wall.mesh = BoxMesh.new()
		(wall.mesh as BoxMesh).size = Vector3(0.04, corridor_height, corridor_length + 1.0)
		wall.material_override = _flat_mat(Color(0.92, 0.90, 0.87))  # White gallery walls
		wall.position = Vector3(side * (corridor_width * 0.5 + 0.02), corridor_height * 0.5, 0)
		add_child(wall)

	# Ceiling backing
	var ceil_mesh := MeshInstance3D.new()
	ceil_mesh.mesh = PlaneMesh.new()
	(ceil_mesh.mesh as PlaneMesh).size = Vector2(corridor_width + 0.5, corridor_length + 1.0)
	ceil_mesh.material_override = _flat_mat(Color(0.08, 0.08, 0.09))
	ceil_mesh.position = Vector3(0, corridor_height, 0)
	ceil_mesh.rotation_degrees.x = 180
	add_child(ceil_mesh)

# ═══════════════════════════════════════════════════════════════════
# FLOOR — edge-to-edge carpet patchwork like Art to Eat
# ═══════════════════════════════════════════════════════════════════

func _tile_floor() -> void:
	# Fill the floor with a patchwork of carpets — 2 columns side by side
	var z: float = -corridor_length * 0.5
	while z < corridor_length * 0.5 - 0.5:
		# Each row: 1-3 carpets spanning the full width
		var segments: int = _rng.randi_range(1, 3)
		var depth_m: int = _rng.randi_range(2, 4)
		var widths: Array = _split_width(int(corridor_width), segments)

		var x_cursor: float = -corridor_width * 0.5
		for seg_i in segments:
			var w: float = float(widths[seg_i])
			var carpet := _make_carpet_panel(
				Vector2(w, float(depth_m)),
				_next_panel_seed()
			)
			carpet.position = Vector3(x_cursor + w * 0.5, 0.003, z + float(depth_m) * 0.5)
			carpet.rotation_degrees.x = -90
			add_child(carpet)
			x_cursor += w
		z += float(depth_m)

## Split a total width into N integer segments that sum to total
func _split_width(total: int, segments: int) -> Array:
	if segments == 1:
		return [total]
	if segments == 2:
		var a: int = _rng.randi_range(2, total - 2)
		return [a, total - a]
	# 3 segments
	var a: int = _rng.randi_range(1, total - 3)
	var b: int = _rng.randi_range(1, total - a - 1)
	return [a, b, total - a - b]

# ═══════════════════════════════════════════════════════════════════
# WALLS — large carpets hung edge-to-edge, floor to near-ceiling
# ═══════════════════════════════════════════════════════════════════

func _tile_walls() -> void:
	for side in [-1, 1]:
		var z: float = -corridor_length * 0.5
		while z < corridor_length * 0.5 - 0.5:
			var len_m: int = _rng.randi_range(2, 5)
			# Stack vertically: bottom carpet + top carpet
			var bottom_h: int = _rng.randi_range(2, int(corridor_height) - 1)
			var top_h: int = int(corridor_height) - bottom_h

			# Bottom carpet
			var carpet_b := _make_carpet_panel(
				Vector2(float(len_m), float(bottom_h)),
				_next_panel_seed()
			)
			carpet_b.position = Vector3(
				side * (corridor_width * 0.5 - 0.003),
				float(bottom_h) * 0.5,
				z + float(len_m) * 0.5
			)
			carpet_b.rotation_degrees.y = -side * 90
			add_child(carpet_b)

			# Top carpet (different pattern)
			if top_h >= 1:
				var carpet_t := _make_carpet_panel(
					Vector2(float(len_m), float(top_h)),
					_next_panel_seed()
				)
				carpet_t.position = Vector3(
					side * (corridor_width * 0.5 - 0.003),
					float(bottom_h) + float(top_h) * 0.5,
					z + float(len_m) * 0.5
				)
				carpet_t.rotation_degrees.y = -side * 90
				add_child(carpet_t)

			z += float(len_m)

# ═══════════════════════════════════════════════════════════════════
# CEILING — also covered, slightly less dense
# ═══════════════════════════════════════════════════════════════════

func _tile_ceiling() -> void:
	var z: float = -corridor_length * 0.5
	while z < corridor_length * 0.5 - 0.5:
		var depth_m: int = _rng.randi_range(2, 4)
		var width_m: int = _rng.randi_range(3, int(corridor_width))
		var x_off: float = (_rng.randf() - 0.5) * (corridor_width - float(width_m))

		var carpet := _make_carpet_panel(
			Vector2(float(width_m), float(depth_m)),
			_next_panel_seed()
		)
		carpet.position = Vector3(x_off, corridor_height - 0.003, z + float(depth_m) * 0.5)
		carpet.rotation_degrees.x = 90
		add_child(carpet)
		z += float(depth_m)

# ═══════════════════════════════════════════════════════════════════
# LIGHTING — bright gallery spots
# ═══════════════════════════════════════════════════════════════════

func _build_lighting() -> void:
	# Bright ambient — gallery-lit, not moody
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.15, 0.14, 0.16)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.95, 0.93, 0.9)
	env.ambient_light_energy = 0.6
	env.glow_enabled = true
	env.glow_intensity = 0.15
	env.glow_bloom = 0.05
	env_node.environment = env
	add_child(env_node)

	# Overhead strip lights along corridor — every 3 meters
	var light_count := int(corridor_length / 3.0)
	for i in light_count:
		var z_pos: float = -corridor_length * 0.5 + (float(i) + 0.5) * corridor_length / float(light_count)

		# Central downlight
		var spot := SpotLight3D.new()
		spot.position = Vector3(0, corridor_height - 0.15, z_pos)
		spot.rotation_degrees.x = -90
		spot.light_energy = 4.0
		spot.light_color = Color(0.98, 0.95, 0.9)
		spot.spot_range = corridor_height + 2.0
		spot.spot_angle = 65.0
		spot.shadow_enabled = i % 3 == 0  # Shadow every 3rd light for perf
		add_child(spot)

	# Fill light from both ends of corridor
	for z_end in [-corridor_length * 0.5, corridor_length * 0.5]:
		var dir_light := DirectionalLight3D.new()
		dir_light.rotation_degrees = Vector3(-30, 0 if z_end < 0 else 180, 0)
		dir_light.light_energy = 0.3
		dir_light.light_color = Color(0.9, 0.9, 0.95)
		add_child(dir_light)

# ═══════════════════════════════════════════════════════════════════
# CARPET PANEL BUILDER
# ═══════════════════════════════════════════════════════════════════

func _next_panel_seed() -> int:
	_panel_idx += 1
	return _panel_idx

func _make_carpet_panel(size: Vector2, seed_val: int) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = size
	mesh_inst.mesh = plane

	# Pick palette and pattern deterministically from seed
	var palette: Array = PALETTES[seed_val % PALETTES.size()]
	var group_id: int = _pick_group(seed_val)
	var domain: Array = _generate_domain(seed_val)

	# Build domain texture
	var domain_size: int = domain.size()
	var img := Image.create(domain_size, domain_size, false, Image.FORMAT_RGBA8)
	for y in domain_size:
		for x in domain_size:
			var idx: int = domain[y][x] if y < domain.size() and x < domain[y].size() else 0
			var color: Color = palette[idx] if idx < palette.size() else Color.WHITE
			img.set_pixel(x, y, color)
	var tex := ImageTexture.create_from_image(img)

	# Shader material
	var mat := ShaderMaterial.new()
	mat.shader = WALLPAPER_SHADER
	mat.set_shader_parameter("domain_texture", tex)
	mat.set_shader_parameter("wallpaper_group", group_id)
	mat.set_shader_parameter("tile_scale", _rng.randf_range(3.0, 10.0))
	mat.set_shader_parameter("grout_width", 0.0)  # Clean pixel look, no grout
	mat.set_shader_parameter("grout_color", Vector3(0.05, 0.05, 0.06))
	mat.set_shader_parameter("noise_distort", 0.0)
	mat.set_shader_parameter("wear_amount", 0.0)
	mat.set_shader_parameter("dust_amount", 0.0)
	mat.set_shader_parameter("fade_amount", 0.0)
	mat.set_shader_parameter("crack_density", 0.0)
	mat.set_shader_parameter("stain_amount", 0.0)
	mat.set_shader_parameter("chip_amount", 0.0)

	mesh_inst.material_override = mat
	return mesh_inst

# ═══════════════════════════════════════════════════════════════════
# DOMAIN PATTERN GENERATORS — 8x8 pixel art domains
# ═══════════════════════════════════════════════════════════════════

func _generate_domain(seed_val: int) -> Array:
	var gen := RandomNumberGenerator.new()
	gen.seed = seed_val * 7919 + 31
	var pattern_type: int = seed_val % 10
	match pattern_type:
		0: return _domain_blocks(gen)
		1: return _domain_stripes(gen)
		2: return _domain_diagonal(gen)
		3: return _domain_cross(gen)
		4: return _domain_concentric(gen)
		5: return _domain_checker_mix(gen)
		6: return _domain_pixel_scatter(gen)
		7: return _domain_stairs(gen)
		8: return _domain_zigzag(gen)
		9: return _domain_frame(gen)
		_: return _domain_blocks(gen)

func _domain_blocks(gen: RandomNumberGenerator) -> Array:
	var s := 8
	var grid := _empty_grid(s, 0)
	for _i in gen.randi_range(3, 6):
		var x0 := gen.randi_range(0, s - 2)
		var y0 := gen.randi_range(0, s - 2)
		var x1 := gen.randi_range(x0 + 1, mini(x0 + 5, s))
		var y1 := gen.randi_range(y0 + 1, mini(y0 + 5, s))
		var c := gen.randi_range(1, 4)
		for y in range(y0, y1):
			for x in range(x0, x1):
				grid[y][x] = c
	return grid

func _domain_stripes(gen: RandomNumberGenerator) -> Array:
	var s := 8
	var grid := _empty_grid(s, 0)
	var horiz: bool = gen.randf() > 0.5
	var thickness := gen.randi_range(1, 3)
	for y in s:
		for x in s:
			var idx: int = y if horiz else x
			grid[y][x] = (idx / thickness) % 5
	return grid

func _domain_diagonal(gen: RandomNumberGenerator) -> Array:
	var s := 8
	var grid := _empty_grid(s, 0)
	var thickness := gen.randi_range(1, 3)
	for y in s:
		for x in s:
			grid[y][x] = ((x + y) / thickness) % 5
	return grid

func _domain_cross(gen: RandomNumberGenerator) -> Array:
	var s := 8
	var grid := _empty_grid(s, gen.randi_range(0, 1))
	var arm := gen.randi_range(1, 3)
	var c := gen.randi_range(2, 4)
	for y in s:
		for x in s:
			if abs(x - s / 2) < arm or abs(y - s / 2) < arm:
				grid[y][x] = c
	return grid

func _domain_concentric(gen: RandomNumberGenerator) -> Array:
	var s := 8
	var grid := _empty_grid(s, 0)
	var _unused := gen.randf()  # consume seed
	for y in s:
		for x in s:
			var ring: int = mini(mini(x, y), mini(s - 1 - x, s - 1 - y))
			grid[y][x] = ring % 5
	return grid

func _domain_checker_mix(gen: RandomNumberGenerator) -> Array:
	var s := 8
	var grid := _empty_grid(s, 0)
	var block := gen.randi_range(1, 3)
	var c1 := gen.randi_range(0, 2)
	var c2 := gen.randi_range(3, 4)
	for y in s:
		for x in s:
			grid[y][x] = c1 if ((x / block) + (y / block)) % 2 == 0 else c2
	return grid

func _domain_pixel_scatter(gen: RandomNumberGenerator) -> Array:
	var s := 8
	var grid := _empty_grid(s, gen.randi_range(0, 1))
	for _i in gen.randi_range(12, 25):
		var x := gen.randi_range(0, s - 1)
		var y := gen.randi_range(0, s - 1)
		var c := gen.randi_range(1, 4)
		grid[y][x] = c
		if x + 1 < s: grid[y][x + 1] = c
		if y + 1 < s: grid[y + 1][x] = c
	return grid

func _domain_stairs(gen: RandomNumberGenerator) -> Array:
	var s := 8
	var grid := _empty_grid(s, 0)
	var step := gen.randi_range(1, 2)
	var c1 := gen.randi_range(1, 2)
	var c2 := gen.randi_range(3, 4)
	for y in s:
		for x in s:
			grid[y][x] = c1 if ((x + y * step) % s) < s / 2 else c2
	return grid

func _domain_zigzag(gen: RandomNumberGenerator) -> Array:
	var s := 8
	var grid := _empty_grid(s, 0)
	var amp: int = gen.randi_range(2, 4)
	var c := gen.randi_range(1, 4)
	for y in s:
		var wave: int = int(abs(float(y % (amp * 2)) - float(amp)))
		for x in s:
			if abs(x - s / 2) <= wave:
				grid[y][x] = c
	return grid

func _domain_frame(gen: RandomNumberGenerator) -> Array:
	var s := 8
	var grid := _empty_grid(s, gen.randi_range(0, 1))
	var border := gen.randi_range(1, 2)
	var outer_c := gen.randi_range(2, 4)
	var inner_c := gen.randi_range(1, 3)
	for y in s:
		for x in s:
			if x < border or x >= s - border or y < border or y >= s - border:
				grid[y][x] = outer_c
			elif x == s / 2 or y == s / 2:
				grid[y][x] = inner_c
	return grid

func _empty_grid(size: int, fill: int) -> Array:
	var grid: Array = []
	for y in size:
		var row: Array = []
		for x in size:
			row.append(fill)
		grid.append(row)
	return grid

func _pick_group(index: int) -> int:
	var groups: Array = [0, 5, 10, 16, 2, 9, 12, 15, 1, 7, 11, 14, 3, 8, 13, 4, 6]
	return groups[index % groups.size()]

func _flat_mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	return mat

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("corridor_length"):
		corridor_length = float(config_data["corridor_length"])
	if config_data.has("corridor_width"):
		corridor_width = float(config_data["corridor_width"])
	if config_data.has("corridor_height"):
		corridor_height = float(config_data["corridor_height"])
