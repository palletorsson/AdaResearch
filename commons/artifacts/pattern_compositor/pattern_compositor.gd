## PatternCompositor
## Renders a SpatialComposition as a grid of QuadMesh tiles, each with its own
## wallpaper_tile ShaderMaterial. Zones get distinct wallpaper groups, palettes,
## and aging effects.
##
## Config keys:
##   preset           – "carpet", "facade", "mosaic", "quilt", "tunnel"
##   width            – grid width in tiles (default 20)
##   height           – grid height in tiles (default 20)
##   tile_size        – world size per tile in meters (default 0.5)
##   surface          – "floor" or "wall" (default "floor")
##   emission_strength – emission for visibility (default 0.8)

extends Node3D
class_name PatternCompositor

const SC := preload("res://commons/composition/spatial_composition.gd")

@export var preset_name: String = "carpet"
@export var grid_width: int = 20
@export var grid_height: int = 20
@export var tile_size: float = 0.5
@export var surface: String = "floor"  # "floor" or "wall"
@export var emission_strength: float = 0.8

const WALLPAPER_SHADER = preload("res://commons/resourses/shaders/wallpaper_tile.gdshader")

var _composition
var _tile_count: int = 0
var _rng := RandomNumberGenerator.new()

# Neon palettes: [background, primary, secondary, accent1, accent2]
const PALETTES: Array = [
	[Color(0.05, 0.05, 0.07), Color(0.0, 0.95, 0.3), Color(1.0, 0.0, 0.6), Color(0.0, 0.5, 1.0), Color(1.0, 1.0, 0.0)],
	[Color(0.0, 0.0, 0.0), Color(0.95, 0.15, 0.15), Color(1.0, 0.55, 0.0), Color(1.0, 0.85, 0.0), Color(0.6, 0.0, 0.3)],
	[Color(0.9, 0.9, 0.92), Color(0.0, 0.2, 0.8), Color(0.0, 0.7, 0.85), Color(0.5, 0.0, 0.8), Color(0.95, 0.0, 0.5)],
	[Color(0.0, 0.0, 0.0), Color(0.0, 0.9, 0.2), Color(0.3, 1.0, 0.0), Color(0.0, 0.4, 0.15), Color(1.0, 0.0, 1.0)],
	[Color(1.0, 1.0, 1.0), Color(1.0, 0.0, 0.5), Color(0.0, 0.8, 1.0), Color(1.0, 0.7, 0.0), Color(0.5, 0.0, 1.0)],
	[Color(0.12, 0.12, 0.12), Color(0.85, 0.85, 0.85), Color(0.95, 0.2, 0.1), Color(0.4, 0.4, 0.4), Color(1.0, 0.8, 0.0)],
	[Color(0.06, 0.0, 0.12), Color(1.0, 0.3, 0.7), Color(0.3, 0.8, 1.0), Color(0.6, 0.2, 0.9), Color(0.0, 1.0, 0.7)],
	[Color(0.95, 0.92, 0.85), Color(0.9, 0.15, 0.1), Color(0.0, 0.25, 0.6), Color(1.0, 0.8, 0.0), Color(0.1, 0.1, 0.1)],
	[Color(0.95, 0.85, 0.9), Color(0.6, 0.8, 1.0), Color(1.0, 0.7, 0.75), Color(0.7, 1.0, 0.7), Color(0.9, 0.7, 1.0)],
	[Color(0.0, 0.05, 0.1), Color(0.0, 0.7, 1.0), Color(1.0, 0.4, 0.0), Color(0.0, 1.0, 0.5), Color(0.8, 0.0, 0.6)],
]

# Zone → pattern mapping: wallpaper_group, palette_index, seed, tile_scale, aging
const ZONE_DEFAULTS: Dictionary = {
	# Carpet zones
	"field":         {"wallpaper_group": 16, "palette_index": 6, "seed": 99, "tile_scale": 5.0},
	"border_outer":  {"wallpaper_group": 5,  "palette_index": 0, "seed": 42, "tile_scale": 8.0},
	"border_inner":  {"wallpaper_group": 3,  "palette_index": 1, "seed": 17, "tile_scale": 6.0},
	"gutter":        {"wallpaper_group": 0,  "palette_index": 5, "seed": 1,  "tile_scale": 2.0, "grout_width": 0.03},
	"medallion":     {"wallpaper_group": 10, "palette_index": 4, "seed": 7,  "tile_scale": 10.0},
	"corners":       {"wallpaper_group": 8,  "palette_index": 2, "seed": 33, "tile_scale": 5.0},
	# Facade zones
	"wall":          {"wallpaper_group": 1,  "palette_index": 7, "seed": 50, "tile_scale": 4.0, "wear_amount": 0.2},
	"base":          {"wallpaper_group": 0,  "palette_index": 5, "seed": 60, "tile_scale": 3.0, "wear_amount": 0.4},
	"cornice":       {"wallpaper_group": 5,  "palette_index": 0, "seed": 70, "tile_scale": 6.0},
	"frieze":        {"wallpaper_group": 16, "palette_index": 6, "seed": 80, "tile_scale": 8.0},
	"columns":       {"wallpaper_group": 2,  "palette_index": 7, "seed": 55, "tile_scale": 3.0},
	"door":          {"wallpaper_group": 9,  "palette_index": 3, "seed": 44, "tile_scale": 6.0},
	# Mosaic/quilt zones
	"background":    {"wallpaper_group": 0,  "palette_index": 5, "seed": 10, "tile_scale": 2.0},
	"border":        {"wallpaper_group": 5,  "palette_index": 0, "seed": 20, "tile_scale": 6.0},
	"sashing":       {"wallpaper_group": 1,  "palette_index": 7, "seed": 15, "tile_scale": 3.0},
	# Tunnel zones
	"floor":         {"wallpaper_group": 4,  "palette_index": 5, "seed": 30, "tile_scale": 4.0},
	"wall_left":     {"wallpaper_group": 8,  "palette_index": 1, "seed": 31, "tile_scale": 5.0},
	"ceiling":       {"wallpaper_group": 16, "palette_index": 6, "seed": 32, "tile_scale": 6.0},
	"wall_right":    {"wallpaper_group": 12, "palette_index": 3, "seed": 33, "tile_scale": 5.0},
	"keystone":      {"wallpaper_group": 10, "palette_index": 4, "seed": 34, "tile_scale": 8.0},
}

func _ready() -> void:
	_rng.seed = 42
	_build_composition()
	_render()
	_add_lights()
	print("[PatternCompositor] Rendered %s preset: %dx%d = %d tiles" % [preset_name, grid_width, grid_height, _tile_count])

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("preset"):
		preset_name = str(config_data["preset"])
	if config_data.has("width"):
		grid_width = clampi(int(config_data["width"]), 4, 40)
	if config_data.has("height"):
		grid_height = clampi(int(config_data["height"]), 4, 40)
	if config_data.has("tile_size"):
		tile_size = clampf(float(config_data["tile_size"]), 0.1, 2.0)
	if config_data.has("surface"):
		surface = str(config_data["surface"])
	if config_data.has("emission_strength"):
		emission_strength = clampf(float(config_data["emission_strength"]), 0.0, 5.0)

func _build_composition() -> void:
	# Call static via preloaded script reference
	_composition = SC.get_preset(preset_name, grid_width, grid_height)

func _render() -> void:
	for gy in grid_height:
		for gx in grid_width:
			var zone = _composition.resolve_zone(gx, gy)
			if not zone:
				continue

			var quad := QuadMesh.new()
			quad.size = Vector2(tile_size * 0.98, tile_size * 0.98)  # Tiny gap between tiles

			var mesh_inst := MeshInstance3D.new()
			mesh_inst.mesh = quad
			mesh_inst.name = "T_%d_%d" % [gx, gy]

			# Position based on surface orientation
			var world_x := (float(gx) - float(grid_width) / 2.0 + 0.5) * tile_size
			var world_y := (float(gy) - float(grid_height) / 2.0 + 0.5) * tile_size
			if surface == "floor":
				mesh_inst.position = Vector3(world_x, 0.01, world_y)
				mesh_inst.rotation_degrees.x = -90.0
			else:  # wall
				mesh_inst.position = Vector3(world_x, -world_y + float(grid_height) * tile_size, 0.01)

			# Get zone pattern properties
			var props := _get_zone_pattern(zone)
			var mat := _create_zone_material(props)
			mesh_inst.material_override = mat

			add_child(mesh_inst)
			_tile_count += 1

func _get_zone_pattern(zone) -> Dictionary:
	# Start with zone's own properties, fall back to defaults by zone ID
	var base_id = zone.id
	# Strip numeric suffixes for matching (e.g., "panel_3" → "panel", "window_2_upper" → check specific first)
	var props: Dictionary = {}

	# Check exact match first, then base patterns
	if ZONE_DEFAULTS.has(zone.id):
		props = ZONE_DEFAULTS[zone.id].duplicate()
	else:
		# Try stripping numbers: "block_a_0" → "block_a", "panel_3" → "panel", "window_2_upper" → "window"
		for key in ZONE_DEFAULTS:
			if zone.id.begins_with(key):
				props = ZONE_DEFAULTS[key].duplicate()
				break
		if props.is_empty():
			# Random fallback
			props = {
				"wallpaper_group": _rng.randi_range(0, 16),
				"palette_index": _rng.randi_range(0, PALETTES.size() - 1),
				"seed": _rng.randi_range(1, 999),
				"tile_scale": _rng.randf_range(3.0, 8.0),
			}

	# Override with zone-specific properties
	for key in zone.properties:
		props[key] = zone.properties[key]

	# Vary seed per instance for panels/blocks with index
	if zone.properties.has("panel_index"):
		props["seed"] = int(props.get("seed", 1)) + int(zone.properties["panel_index"]) * 7
		props["wallpaper_group"] = int(zone.properties["panel_index"]) % 17
		props["palette_index"] = int(zone.properties["panel_index"]) % PALETTES.size()
	if zone.properties.has("block_index"):
		props["seed"] = int(props.get("seed", 1)) + int(zone.properties["block_index"]) * 13

	# block_a vs block_b get different groups
	if zone.id.begins_with("block_a"):
		props["wallpaper_group"] = (int(props.get("seed", 0)) + int(zone.properties.get("block_index", 0))) % 17
		props["palette_index"] = int(zone.properties.get("block_index", 0)) % PALETTES.size()
	elif zone.id.begins_with("block_b"):
		props["wallpaper_group"] = (int(props.get("seed", 0)) + int(zone.properties.get("block_index", 0)) + 8) % 17
		props["palette_index"] = (int(zone.properties.get("block_index", 0)) + 5) % PALETTES.size()

	return props

func _create_zone_material(props: Dictionary) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = WALLPAPER_SHADER

	var group_id: int = int(props.get("wallpaper_group", 0))
	var palette_idx: int = int(props.get("palette_index", 0)) % PALETTES.size()
	var seed_val: int = int(props.get("seed", 1))
	var t_scale: float = float(props.get("tile_scale", 5.0))

	# Generate domain texture
	var palette: Array = PALETTES[palette_idx]
	var domain := _generate_domain(seed_val)
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y in 8:
		for x in 8:
			var idx: int = domain[y * 8 + x]
			var color: Color = palette[idx] if idx < palette.size() else Color.WHITE
			img.set_pixel(x, y, color)
	var tex := ImageTexture.create_from_image(img)

	mat.set_shader_parameter("domain_texture", tex)
	mat.set_shader_parameter("wallpaper_group", group_id)
	mat.set_shader_parameter("tile_scale", t_scale)
	mat.set_shader_parameter("grout_width", float(props.get("grout_width", 0.01)))
	mat.set_shader_parameter("grout_color", Vector3(0.05, 0.05, 0.06))
	mat.set_shader_parameter("noise_distort", float(props.get("noise_distort", 0.0)))
	mat.set_shader_parameter("emission_strength", emission_strength)
	mat.set_shader_parameter("metallic", float(props.get("metallic", 0.0)))
	mat.set_shader_parameter("roughness", float(props.get("roughness", 0.8)))
	mat.set_shader_parameter("wear_amount", float(props.get("wear_amount", 0.0)))
	mat.set_shader_parameter("dust_amount", float(props.get("dust_amount", 0.0)))
	mat.set_shader_parameter("fade_amount", float(props.get("fade_amount", 0.0)))
	mat.set_shader_parameter("crack_density", float(props.get("crack_density", 0.0)))
	mat.set_shader_parameter("stain_amount", float(props.get("stain_amount", 0.0)))
	mat.set_shader_parameter("chip_amount", float(props.get("chip_amount", 0.0)))

	return mat

# ═══════════════════════════════════════════════════════════════════
# DOMAIN PATTERN GENERATORS — 8x8 flat array
# ═══════════════════════════════════════════════════════════════════

func _generate_domain(seed_val: int) -> Array:
	var gen := RandomNumberGenerator.new()
	gen.seed = seed_val * 7919 + 31
	var pattern_type: int = seed_val % 8
	match pattern_type:
		0: return _domain_blocks(gen)
		1: return _domain_stripes(gen)
		2: return _domain_diagonal(gen)
		3: return _domain_cross(gen)
		4: return _domain_concentric(gen)
		5: return _domain_checker(gen)
		6: return _domain_scatter(gen)
		7: return _domain_stairs(gen)
		_: return _domain_blocks(gen)

func _grid8(fill: int = 0) -> Array:
	var arr: Array = []
	arr.resize(64)
	arr.fill(fill)
	return arr

func _set8(arr: Array, x: int, y: int, val: int) -> void:
	if x >= 0 and x < 8 and y >= 0 and y < 8:
		arr[y * 8 + x] = val

func _domain_blocks(gen: RandomNumberGenerator) -> Array:
	var grid := _grid8(0)
	for _i in gen.randi_range(3, 6):
		var x0 := gen.randi_range(0, 5)
		var y0 := gen.randi_range(0, 5)
		var x1 := gen.randi_range(x0 + 1, mini(x0 + 5, 8))
		var y1 := gen.randi_range(y0 + 1, mini(y0 + 5, 8))
		var c := gen.randi_range(1, 4)
		for y in range(y0, y1):
			for x in range(x0, x1):
				_set8(grid, x, y, c)
	return grid

func _domain_stripes(gen: RandomNumberGenerator) -> Array:
	var grid := _grid8(0)
	var horiz: bool = gen.randf() > 0.5
	var thick := gen.randi_range(1, 3)
	for y in 8:
		for x in 8:
			grid[y * 8 + x] = ((y if horiz else x) / thick) % 5
	return grid

func _domain_diagonal(gen: RandomNumberGenerator) -> Array:
	var grid := _grid8(0)
	var thick := gen.randi_range(1, 3)
	for y in 8:
		for x in 8:
			grid[y * 8 + x] = ((x + y) / thick) % 5
	return grid

func _domain_cross(gen: RandomNumberGenerator) -> Array:
	var bg := gen.randi_range(0, 1)
	var grid := _grid8(bg)
	var arm := gen.randi_range(1, 3)
	var c := gen.randi_range(2, 4)
	for y in 8:
		for x in 8:
			if abs(x - 4) < arm or abs(y - 4) < arm:
				_set8(grid, x, y, c)
	return grid

func _domain_concentric(_gen: RandomNumberGenerator) -> Array:
	var grid := _grid8(0)
	for y in 8:
		for x in 8:
			grid[y * 8 + x] = mini(mini(x, y), mini(7 - x, 7 - y)) % 5
	return grid

func _domain_checker(gen: RandomNumberGenerator) -> Array:
	var grid := _grid8(0)
	var block := gen.randi_range(1, 3)
	var c1 := gen.randi_range(0, 2)
	var c2 := gen.randi_range(3, 4)
	for y in 8:
		for x in 8:
			grid[y * 8 + x] = c1 if ((x / block) + (y / block)) % 2 == 0 else c2
	return grid

func _domain_scatter(gen: RandomNumberGenerator) -> Array:
	var bg := gen.randi_range(0, 1)
	var grid := _grid8(bg)
	for _i in gen.randi_range(12, 25):
		var x := gen.randi_range(0, 7)
		var y := gen.randi_range(0, 7)
		var c := gen.randi_range(1, 4)
		_set8(grid, x, y, c)
		_set8(grid, x + 1, y, c)
		_set8(grid, x, y + 1, c)
	return grid

func _domain_stairs(gen: RandomNumberGenerator) -> Array:
	var grid := _grid8(0)
	var step := gen.randi_range(1, 2)
	var c1 := gen.randi_range(1, 2)
	var c2 := gen.randi_range(3, 4)
	for y in 8:
		for x in 8:
			grid[y * 8 + x] = c1 if ((x + y * step) % 8) < 4 else c2
	return grid

# ═══════════════════════════════════════════════════════════════════
# LIGHTING
# ═══════════════════════════════════════════════════════════════════

func _add_lights() -> void:
	var extent = max(float(grid_width), float(grid_height)) * tile_size
	var num_lights := clampi(int(extent / 3.0) + 1, 1, 8)

	for i in num_lights:
		var light := OmniLight3D.new()
		var t := float(i) / float(num_lights)
		if surface == "floor":
			light.position = Vector3(
				lerp(-extent * 0.3, extent * 0.3, t),
				extent * 0.5,
				lerp(-extent * 0.3, extent * 0.3, t)
			)
		else:
			light.position = Vector3(
				lerp(-extent * 0.3, extent * 0.3, t),
				float(grid_height) * tile_size * 0.5,
				-extent * 0.3
			)
		light.light_energy = 4.0
		light.omni_range = extent * 0.8
		light.light_color = Color(0.98, 0.95, 0.9)
		light.shadow_enabled = false
		light.name = "CL_%d" % i
		add_child(light)
