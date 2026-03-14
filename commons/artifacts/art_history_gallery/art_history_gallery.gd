## ArtHistoryGallery
## Walk-through exhibition of 20 art history composition presets.
## Each composition is rendered as a floor tile with its own wallpaper group patterns.
## Inspired by Art to Eat installations — each tile a distinct artwork.
##
## Config keys:
##   tile_resolution – grid size per composition tile (default 16)
##   tile_world_size – world meters per composition (default 4.0)
##   columns         – number of tiles per row (default 4)
##   emission_strength – emission for visibility (default 1.0)

extends Node3D
class_name ArtHistoryGallery

const SC := preload("res://commons/composition/spatial_composition.gd")
const AHP := preload("res://commons/composition/art_history_presets.gd")
const WALLPAPER_SHADER = preload("res://commons/resourses/shaders/wallpaper_tile.gdshader")

@export var tile_resolution: int = 14
@export var tile_world_size: float = 4.0
@export var columns: int = 4
@export var emission_strength: float = 1.0

var _total_tiles: int = 0
var _rng := RandomNumberGenerator.new()

# Neon palettes — same as pattern_compositor
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

func _ready() -> void:
	_rng.seed = 2026
	_build_gallery()
	_add_lights()
	_add_labels()
	print("[ArtHistoryGallery] Rendered 20 compositions, %d total quads" % _total_tiles)

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("tile_resolution"):
		tile_resolution = clampi(int(config_data["tile_resolution"]), 8, 24)
	if config_data.has("tile_world_size"):
		tile_world_size = clampf(float(config_data["tile_world_size"]), 2.0, 8.0)
	if config_data.has("columns"):
		columns = clampi(int(config_data["columns"]), 2, 6)
	if config_data.has("emission_strength"):
		emission_strength = clampf(float(config_data["emission_strength"]), 0.0, 5.0)

func _build_gallery() -> void:
	var presets: Array = AHP.PRESET_NAMES
	var gap := 0.3  # Gap between compositions

	for idx in presets.size():
		var preset_name: String = presets[idx]
		var col := idx % columns
		var row := idx / columns

		# World position for this composition tile
		var world_x := float(col) * (tile_world_size + gap)
		var world_z := float(row) * (tile_world_size + gap)

		# Get the composition
		var comp = AHP.get_preset(preset_name, tile_resolution, tile_resolution)
		if not comp:
			continue

		# Container node for this composition
		var container := Node3D.new()
		container.name = preset_name
		container.position = Vector3(world_x, 0.0, world_z)
		add_child(container)

		# Render each cell
		var cell_size := tile_world_size / float(tile_resolution)
		_rng.seed = idx * 7919 + 31

		for gy in comp.height:
			for gx in comp.width:
				var zone = comp.resolve_zone(gx, gy)  # untyped return
				if not zone:
					continue

				var quad := QuadMesh.new()
				quad.size = Vector2(cell_size * 0.96, cell_size * 0.96)

				var mesh_inst := MeshInstance3D.new()
				mesh_inst.mesh = quad
				mesh_inst.name = "C_%d_%d" % [gx, gy]

				# Floor placement
				var local_x := (float(gx) - float(comp.width) / 2.0 + 0.5) * cell_size
				var local_z := (float(gy) - float(comp.height) / 2.0 + 0.5) * cell_size
				mesh_inst.position = Vector3(local_x, 0.01, local_z)
				mesh_inst.rotation_degrees.x = -90.0

				# Create material for this zone
				var mat := _create_material(zone, idx)
				mesh_inst.material_override = mat

				container.add_child(mesh_inst)
				_total_tiles += 1

func _create_material(zone, comp_index: int) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = WALLPAPER_SHADER

	# Derive pattern from zone id + composition index
	var zone_hash = zone.id.hash()
	var group_id: int = abs(zone_hash + comp_index * 3) % 17
	var palette_idx: int = abs(zone_hash + comp_index * 7) % PALETTES.size()
	var seed_val: int = abs(zone_hash * 13 + comp_index * 97) % 1000 + 1
	var t_scale: float = 3.0 + float(abs(zone_hash) % 8)

	# Use zone properties if they have overrides
	if zone.properties.has("palette_index"):
		palette_idx = int(zone.properties["palette_index"]) % PALETTES.size()
	if zone.properties.has("panel_index"):
		group_id = int(zone.properties["panel_index"]) % 17
		palette_idx = int(zone.properties["panel_index"]) % PALETTES.size()
		seed_val = int(zone.properties["panel_index"]) * 7 + comp_index * 31
	if zone.properties.has("block_index"):
		seed_val = int(zone.properties["block_index"]) * 13 + comp_index * 41

	# Generate domain texture
	var palette: Array = PALETTES[palette_idx]
	var domain := _generate_domain(seed_val)
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y in 8:
		for x in 8:
			var c_idx: int = domain[y * 8 + x]
			var color: Color = palette[c_idx] if c_idx < palette.size() else Color.WHITE
			img.set_pixel(x, y, color)
	var tex := ImageTexture.create_from_image(img)

	mat.set_shader_parameter("domain_texture", tex)
	mat.set_shader_parameter("wallpaper_group", group_id)
	mat.set_shader_parameter("tile_scale", t_scale)
	mat.set_shader_parameter("grout_width", 0.01)
	mat.set_shader_parameter("grout_color", Vector3(0.05, 0.05, 0.06))
	mat.set_shader_parameter("emission_strength", emission_strength)
	mat.set_shader_parameter("roughness", 0.8)

	return mat

# Domain pattern generators
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
	var arr: Array = []; arr.resize(64); arr.fill(fill); return arr
func _set8(arr: Array, x: int, y: int, val: int) -> void:
	if x >= 0 and x < 8 and y >= 0 and y < 8: arr[y * 8 + x] = val

func _domain_blocks(gen: RandomNumberGenerator) -> Array:
	var grid := _grid8(0)
	for _i in gen.randi_range(3, 6):
		var x0 := gen.randi_range(0, 5); var y0 := gen.randi_range(0, 5)
		var x1 := gen.randi_range(x0 + 1, mini(x0 + 5, 8))
		var y1 := gen.randi_range(y0 + 1, mini(y0 + 5, 8))
		var c := gen.randi_range(1, 4)
		for y in range(y0, y1):
			for x in range(x0, x1): _set8(grid, x, y, c)
	return grid
func _domain_stripes(gen: RandomNumberGenerator) -> Array:
	var grid := _grid8(0); var horiz: bool = gen.randf() > 0.5; var thick := gen.randi_range(1, 3)
	for y in 8:
		for x in 8: grid[y * 8 + x] = ((y if horiz else x) / thick) % 5
	return grid
func _domain_diagonal(gen: RandomNumberGenerator) -> Array:
	var grid := _grid8(0); var thick := gen.randi_range(1, 3)
	for y in 8:
		for x in 8: grid[y * 8 + x] = ((x + y) / thick) % 5
	return grid
func _domain_cross(gen: RandomNumberGenerator) -> Array:
	var bg := gen.randi_range(0, 1); var grid := _grid8(bg); var arm := gen.randi_range(1, 3); var c := gen.randi_range(2, 4)
	for y in 8:
		for x in 8:
			if abs(x - 4) < arm or abs(y - 4) < arm: _set8(grid, x, y, c)
	return grid
func _domain_concentric(_gen: RandomNumberGenerator) -> Array:
	var grid := _grid8(0)
	for y in 8:
		for x in 8: grid[y * 8 + x] = mini(mini(x, y), mini(7 - x, 7 - y)) % 5
	return grid
func _domain_checker(gen: RandomNumberGenerator) -> Array:
	var grid := _grid8(0); var block := gen.randi_range(1, 3)
	var c1 := gen.randi_range(0, 2); var c2 := gen.randi_range(3, 4)
	for y in 8:
		for x in 8: grid[y * 8 + x] = c1 if ((x / block) + (y / block)) % 2 == 0 else c2
	return grid
func _domain_scatter(gen: RandomNumberGenerator) -> Array:
	var bg := gen.randi_range(0, 1); var grid := _grid8(bg)
	for _i in gen.randi_range(12, 25):
		var x := gen.randi_range(0, 7); var y := gen.randi_range(0, 7); var c := gen.randi_range(1, 4)
		_set8(grid, x, y, c); _set8(grid, x + 1, y, c); _set8(grid, x, y + 1, c)
	return grid
func _domain_stairs(gen: RandomNumberGenerator) -> Array:
	var grid := _grid8(0); var step := gen.randi_range(1, 2)
	var c1 := gen.randi_range(1, 2); var c2 := gen.randi_range(3, 4)
	for y in 8:
		for x in 8: grid[y * 8 + x] = c1 if ((x + y * step) % 8) < 4 else c2
	return grid

func _add_lights() -> void:
	var total_w := float(columns) * (tile_world_size + 0.3)
	var rows := 20.0 / float(columns)
	var total_z := rows * (tile_world_size + 0.3)
	var extent: float = maxf(total_w, total_z)

	for i in 6:
		var light := OmniLight3D.new()
		var tx: float = float(i % 3) / 2.0
		var tz: float = float(i / 3)
		light.position = Vector3(
			lerpf(0.0, total_w, tx),
			extent * 0.4,
			lerpf(0.0, total_z, tz)
		)
		light.light_energy = 6.0
		light.omni_range = extent * 0.6
		light.light_color = Color(0.98, 0.95, 0.9)
		light.shadow_enabled = false
		light.name = "GL_%d" % i
		add_child(light)

func _add_labels() -> void:
	var presets: Array = AHP.PRESET_NAMES
	var gap := 0.3

	for idx in presets.size():
		var preset_name: String = presets[idx]
		var col := idx % columns
		var row := idx / columns
		var world_x := float(col) * (tile_world_size + gap)
		var world_z := float(row) * (tile_world_size + gap) - tile_world_size * 0.55

		var label := Label3D.new()
		label.text = "%d. %s" % [idx + 1, preset_name.replace("_", " ").capitalize()]
		label.font_size = 48
		label.position = Vector3(world_x, 0.02, world_z)
		label.rotation_degrees.x = -90.0
		label.modulate = Color(1.0, 1.0, 1.0, 0.9)
		label.outline_size = 4
		label.name = "Label_%d" % idx
		add_child(label)
