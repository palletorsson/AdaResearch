## ShaderArchGallery
## A rectangular tunnel of cubes — each cube shows a different wallpaper group
## tile pattern. Uses wallpaper_tile.gdshader with different groups, palettes,
## and domain textures per cube. Art to Eat patchwork style.
##
## Config keys:
##   tunnel_width      – interior width in cubes (default 5)
##   tunnel_height     – interior height in cubes (default 4)
##   tunnel_length     – length in cubes (default 25)
##   cube_size         – size of each cube (default 1.0)
##   emission_strength – emission for visibility (default 0.8)

# @identity
# essence: for i in total_cubes: cube[i].material = wallpaper_tile(random_group, random_palette, random_domain, random_scale) — every cube in a tunnel is a unique patchwork tile
# desire: to walk through a self-built tunnel where floor, walls, and ceiling are each a different wallpaper pattern — Art to Eat style patchwork quilted in light
# critical_parameter: tunnel_length — how many cubes deep the tunnel extends; 25 cubes means hundreds of unique shader-pattern surfaces
# triggers: _ready builds the full tunnel geometry procedurally; each cube gets a random wallpaper group (0-16), palette (10 options), domain pattern (10 generators), and tile_scale
# emerges: 10 domain generators (blocks, stripes, diagonal, cross, concentric, checker, scatter, stairs, zigzag, frame) combined with 10 palettes and 17 groups produce a tunnel that feels hand-curated but is entirely algorithmic
# needs: [missing] no VR sliders or buttons — pure architectural walk-through; configuration only through apply_grid_config
# relationships: the culmination of the patterngeneration sequence; synthesizes wallpaper groups, shader techniques, and procedural domain generation into a single immersive environment
# truth: a patchwork is not random — it is every possible pattern given exactly one tile to exist in, and the corridor is the argument that they all deserve space

extends Node3D
class_name ShaderArchGallery

@export var tunnel_width: int = 5
@export var tunnel_height: int = 4
@export var tunnel_length: int = 25
@export var cube_size: float = 1.0
@export var emission_strength: float = 0.8

const WALLPAPER_SHADER = preload("res://commons/resourses/shaders/wallpaper_tile.gdshader")

var _rng := RandomNumberGenerator.new()
var _tile_count: int = 0

# Neon / Art-to-Eat palettes: [background, primary, secondary, accent1, accent2]
const PALETTES: Array = [
	[Color(0.05, 0.05, 0.07), Color(0.0, 0.95, 0.3), Color(1.0, 0.0, 0.6), Color(0.0, 0.5, 1.0), Color(1.0, 1.0, 0.0)],
	[Color(0.0, 0.0, 0.0), Color(0.95, 0.15, 0.15), Color(1.0, 0.55, 0.0), Color(1.0, 0.85, 0.0), Color(0.6, 0.0, 0.3)],
	[Color(0.9, 0.9, 0.92), Color(0.0, 0.2, 0.8), Color(0.0, 0.7, 0.85), Color(0.5, 0.0, 0.8), Color(0.95, 0.0, 0.5)],
	[Color(0.0, 0.0, 0.0), Color(0.0, 0.9, 0.2), Color(0.3, 1.0, 0.0), Color(0.0, 0.4, 0.15), Color(1.0, 0.0, 1.0)],
	[Color(1.0, 1.0, 1.0), Color(1.0, 0.0, 0.5), Color(0.0, 0.8, 1.0), Color(1.0, 0.7, 0.0), Color(0.5, 0.0, 1.0)],
	[Color(0.12, 0.12, 0.12), Color(0.85, 0.85, 0.85), Color(0.95, 0.2, 0.1), Color(0.4, 0.4, 0.4), Color(1.0, 0.8, 0.0)],
	[Color(0.06, 0.0, 0.12), Color(1.0, 0.3, 0.7), Color(0.3, 0.8, 1.0), Color(0.6, 0.2, 0.9), Color(0.0, 1.0, 0.7)],
	[Color(0.95, 0.92, 0.85), Color(0.9, 0.15, 0.1), Color(0.0, 0.25, 0.6), Color(1.0, 0.8, 0.0), Color(0.1, 0.1, 0.1)],
	[Color(0.0, 0.0, 0.0), Color(0.0, 1.0, 0.0), Color(1.0, 0.0, 0.0), Color(0.0, 0.0, 1.0), Color(1.0, 1.0, 1.0)],
	[Color(0.95, 0.85, 0.9), Color(0.6, 0.8, 1.0), Color(1.0, 0.7, 0.75), Color(0.7, 1.0, 0.7), Color(0.9, 0.7, 1.0)],
]

func _ready() -> void:
	_rng.seed = 42
	_build_tunnel()
	_build_lights()
	print("[ShaderArchGallery] Built %d tile-pattern cubes" % _tile_count)

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("tunnel_width"):
		tunnel_width = clampi(int(config_data["tunnel_width"]), 3, 15)
	if config_data.has("tunnel_height"):
		tunnel_height = clampi(int(config_data["tunnel_height"]), 3, 10)
	if config_data.has("tunnel_length"):
		tunnel_length = clampi(int(config_data["tunnel_length"]), 5, 60)
	if config_data.has("cube_size"):
		cube_size = clampf(float(config_data["cube_size"]), 0.25, 3.0)
	if config_data.has("emission_strength"):
		emission_strength = clampf(float(config_data["emission_strength"]), 0.0, 5.0)

func _build_tunnel() -> void:
	var s := cube_size
	var hw := float(tunnel_width) * s * 0.5

	for zi in range(tunnel_length):
		var z := float(zi) * s

		# Floor row
		for xi in range(tunnel_width):
			var x := -hw + (float(xi) + 0.5) * s
			_place_tile_cube(Vector3(x, 0, z))

		# Ceiling row
		for xi in range(tunnel_width):
			var x := -hw + (float(xi) + 0.5) * s
			_place_tile_cube(Vector3(x, float(tunnel_height) * s, z))

		# Left wall
		for yi in range(1, tunnel_height):
			_place_tile_cube(Vector3(-hw - s * 0.5, float(yi) * s, z))

		# Right wall
		for yi in range(1, tunnel_height):
			_place_tile_cube(Vector3(hw + s * 0.5, float(yi) * s, z))

func _place_tile_cube(pos: Vector3) -> void:
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE * cube_size
	mesh_inst.mesh = box
	mesh_inst.name = "T_%d" % _tile_count
	mesh_inst.position = pos

	# Each cube gets unique wallpaper group + palette + domain pattern
	var seed_val := _tile_count + 1
	var palette: Array = PALETTES[_rng.randi() % PALETTES.size()]
	var group_id: int = _rng.randi_range(0, 16)  # All 17 wallpaper groups
	var tile_scale: float = _rng.randf_range(3.0, 10.0)

	# Generate 8x8 domain texture
	var domain := _generate_domain(seed_val)
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y in 8:
		for x in 8:
			var idx: int = domain[y][x] if y < domain.size() and x < domain[y].size() else 0
			var color: Color = palette[idx] if idx < palette.size() else Color.WHITE
			img.set_pixel(x, y, color)
	var tex := ImageTexture.create_from_image(img)

	var mat := ShaderMaterial.new()
	mat.shader = WALLPAPER_SHADER
	mat.set_shader_parameter("domain_texture", tex)
	mat.set_shader_parameter("wallpaper_group", group_id)
	mat.set_shader_parameter("tile_scale", tile_scale)
	mat.set_shader_parameter("grout_width", 0.0)
	mat.set_shader_parameter("grout_color", Vector3(0.05, 0.05, 0.06))
	mat.set_shader_parameter("noise_distort", 0.0)
	mat.set_shader_parameter("emission_strength", emission_strength)
	mat.set_shader_parameter("wear_amount", 0.0)
	mat.set_shader_parameter("dust_amount", 0.0)
	mat.set_shader_parameter("fade_amount", 0.0)
	mat.set_shader_parameter("crack_density", 0.0)
	mat.set_shader_parameter("stain_amount", 0.0)
	mat.set_shader_parameter("chip_amount", 0.0)

	mesh_inst.material_override = mat
	add_child(mesh_inst)
	_tile_count += 1

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
		5: return _domain_checker(gen)
		6: return _domain_scatter(gen)
		7: return _domain_stairs(gen)
		8: return _domain_zigzag(gen)
		9: return _domain_frame(gen)
		_: return _domain_blocks(gen)

func _domain_blocks(gen: RandomNumberGenerator) -> Array:
	var grid := _empty_grid(0)
	for _i in gen.randi_range(3, 6):
		var x0 := gen.randi_range(0, 5)
		var y0 := gen.randi_range(0, 5)
		var x1 := gen.randi_range(x0 + 1, mini(x0 + 5, 8))
		var y1 := gen.randi_range(y0 + 1, mini(y0 + 5, 8))
		var c := gen.randi_range(1, 4)
		for y in range(y0, y1):
			for x in range(x0, x1):
				grid[y][x] = c
	return grid

func _domain_stripes(gen: RandomNumberGenerator) -> Array:
	var grid := _empty_grid(0)
	var horiz: bool = gen.randf() > 0.5
	var thick := gen.randi_range(1, 3)
	for y in 8:
		for x in 8:
			grid[y][x] = ((y if horiz else x) / thick) % 5
	return grid

func _domain_diagonal(gen: RandomNumberGenerator) -> Array:
	var grid := _empty_grid(0)
	var thick := gen.randi_range(1, 3)
	for y in 8:
		for x in 8:
			grid[y][x] = ((x + y) / thick) % 5
	return grid

func _domain_cross(gen: RandomNumberGenerator) -> Array:
	var grid := _empty_grid(gen.randi_range(0, 1))
	var arm := gen.randi_range(1, 3)
	var c := gen.randi_range(2, 4)
	for y in 8:
		for x in 8:
			if abs(x - 4) < arm or abs(y - 4) < arm:
				grid[y][x] = c
	return grid

func _domain_concentric(_gen: RandomNumberGenerator) -> Array:
	var grid := _empty_grid(0)
	for y in 8:
		for x in 8:
			grid[y][x] = mini(mini(x, y), mini(7 - x, 7 - y)) % 5
	return grid

func _domain_checker(gen: RandomNumberGenerator) -> Array:
	var grid := _empty_grid(0)
	var block := gen.randi_range(1, 3)
	var c1 := gen.randi_range(0, 2)
	var c2 := gen.randi_range(3, 4)
	for y in 8:
		for x in 8:
			grid[y][x] = c1 if ((x / block) + (y / block)) % 2 == 0 else c2
	return grid

func _domain_scatter(gen: RandomNumberGenerator) -> Array:
	var grid := _empty_grid(gen.randi_range(0, 1))
	for _i in gen.randi_range(12, 25):
		var x := gen.randi_range(0, 7)
		var y := gen.randi_range(0, 7)
		var c := gen.randi_range(1, 4)
		grid[y][x] = c
		if x + 1 < 8: grid[y][x + 1] = c
		if y + 1 < 8: grid[y + 1][x] = c
	return grid

func _domain_stairs(gen: RandomNumberGenerator) -> Array:
	var grid := _empty_grid(0)
	var step := gen.randi_range(1, 2)
	var c1 := gen.randi_range(1, 2)
	var c2 := gen.randi_range(3, 4)
	for y in 8:
		for x in 8:
			grid[y][x] = c1 if ((x + y * step) % 8) < 4 else c2
	return grid

func _domain_zigzag(gen: RandomNumberGenerator) -> Array:
	var grid := _empty_grid(0)
	var amp := gen.randi_range(2, 4)
	var c := gen.randi_range(1, 4)
	for y in 8:
		var wave := int(abs(float(y % (amp * 2)) - float(amp)))
		for x in 8:
			if abs(x - 4) <= wave:
				grid[y][x] = c
	return grid

func _domain_frame(gen: RandomNumberGenerator) -> Array:
	var grid := _empty_grid(gen.randi_range(0, 1))
	var border := gen.randi_range(1, 2)
	var c1 := gen.randi_range(2, 4)
	var c2 := gen.randi_range(1, 3)
	for y in 8:
		for x in 8:
			if x < border or x >= 8 - border or y < border or y >= 8 - border:
				grid[y][x] = c1
			elif x == 4 or y == 4:
				grid[y][x] = c2
	return grid

func _empty_grid(fill: int) -> Array:
	var grid: Array = []
	for y in 8:
		var row: Array = []
		for x in 8:
			row.append(fill)
		grid.append(row)
	return grid

# ═══════════════════════════════════════════════════════════════════
# LIGHTING
# ═══════════════════════════════════════════════════════════════════

func _build_lights() -> void:
	var num := tunnel_length / 3 + 1
	for i in num:
		var z_pos := float(i) * 3.0 * cube_size + cube_size
		var light := OmniLight3D.new()
		light.position = Vector3(0.0, float(tunnel_height) * cube_size * 0.7, z_pos)
		light.light_energy = 4.0
		light.omni_range = 6.0
		light.light_color = Color(0.98, 0.95, 0.9)
		light.shadow_enabled = false
		light.name = "L_%d" % i
		add_child(light)
