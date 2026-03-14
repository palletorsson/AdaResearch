## WallPatternGallery
## Overlays wallpaper group shader patterns on grid wall cubes in clusters.
## Like the Becoming Catalyst's chromatic mode, but with GPU shader patterns.
##
## Finds GridSystem wall cubes (y > 0), groups them by Z position into clusters,
## and places a thin BoxMesh overlay on each cube face with the wallpaper_tile
## shader configured for that cluster's wallpaper group.
##
## Config keys:
##   cluster_size     – cubes per cluster along Z axis (default 3)
##   tile_scale       – shader tiling scale (default 4.0)
##   emission_strength – for visibility (default 0.8)
##   grout_width      – tile grout (default 0.02)

extends Node3D
class_name WallPatternGallery

@export var cluster_size: int = 3
@export var tile_scale: float = 4.0
@export var emission_strength: float = 0.8
@export var grout_width: float = 0.02

# All 17 wallpaper groups
const GROUP_NAMES: Array = [
	"P1", "P2", "PM", "PG", "PMM", "PMG", "PGG",
	"CM", "CMM", "P4", "P4M", "P4G",
	"P3", "P3M1", "P31M", "P6", "P6M",
]

# Neon palettes for domain textures
const PALETTES: Array = [
	[Color(1.0, 0.1, 0.5), Color(0.0, 1.0, 0.8), Color(1.0, 0.9, 0.0), Color(0.2, 0.1, 0.6)],
	[Color(0.0, 0.8, 1.0), Color(1.0, 0.3, 0.0), Color(0.6, 0.0, 1.0), Color(0.0, 1.0, 0.3)],
	[Color(1.0, 0.0, 0.3), Color(0.3, 0.0, 1.0), Color(0.0, 1.0, 0.5), Color(1.0, 1.0, 0.0)],
	[Color(0.9, 0.0, 0.9), Color(0.0, 0.9, 0.9), Color(0.9, 0.9, 0.0), Color(0.3, 0.3, 1.0)],
	[Color(1.0, 0.4, 0.7), Color(0.4, 1.0, 0.7), Color(0.7, 0.4, 1.0), Color(1.0, 0.8, 0.3)],
	[Color(0.0, 0.5, 1.0), Color(1.0, 0.5, 0.0), Color(0.5, 1.0, 0.0), Color(1.0, 0.0, 0.5)],
	[Color(0.8, 0.2, 0.0), Color(0.0, 0.6, 0.8), Color(0.8, 0.8, 0.0), Color(0.4, 0.0, 0.8)],
	[Color(0.2, 1.0, 0.6), Color(1.0, 0.2, 0.6), Color(0.6, 0.2, 1.0), Color(1.0, 0.8, 0.2)],
]

var _wallpaper_shader: Shader

func _ready() -> void:
	_wallpaper_shader = load("res://commons/resourses/shaders/wallpaper_tile.gdshader") as Shader
	if not _wallpaper_shader:
		print("[WallPatternGallery] Failed to load wallpaper_tile shader")
		return
	await get_tree().create_timer(0.5).timeout
	_build_gallery()

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("cluster_size"):
		cluster_size = clampi(int(config_data["cluster_size"]), 1, 10)
	if config_data.has("tile_scale"):
		tile_scale = clampf(float(config_data["tile_scale"]), 1.0, 16.0)
	if config_data.has("emission_strength"):
		emission_strength = clampf(float(config_data["emission_strength"]), 0.0, 3.0)
	if config_data.has("grout_width"):
		grout_width = clampf(float(config_data["grout_width"]), 0.0, 0.1)

func _build_gallery() -> void:
	# Find GridSystem like the catalyst does
	var grids := get_tree().get_nodes_in_group("grid_system")
	if grids.is_empty():
		print("[WallPatternGallery] No grid_system found")
		return

	var grid: Node = grids[0]
	var struct = grid.get("structure_component")
	if not struct:
		print("[WallPatternGallery] No structure_component")
		return

	var positions: Array = struct.get("cube_positions")
	if positions.is_empty():
		print("[WallPatternGallery] No cube_positions")
		return

	var cs: float = struct.get("cube_size")
	var gt: float = struct.get("gutter")
	var total_size: float = cs + gt
	var grid_origin: Vector3 = grid.global_position if grid is Node3D else Vector3.ZERO

	# Collect ALL cubes (walls + ceiling + floor) grouped by Z
	var z_groups: Dictionary = {}
	for i in positions.size():
		var gp: Vector3i = positions[i]
		if not z_groups.has(gp.z):
			z_groups[gp.z] = []
		z_groups[gp.z].append({"index": i, "pos": gp})

	# Sort Z values
	var z_values: Array = z_groups.keys()
	z_values.sort()

	if z_values.is_empty():
		print("[WallPatternGallery] No wall cubes found")
		return

	# Assign clusters: every cluster_size Z-rows get the same wallpaper group
	var group_index: int = 0
	var z_count: int = 0

	for z_val in z_values:
		var cluster_group_id: int = group_index % GROUP_NAMES.size()
		var palette_id: int = group_index % PALETTES.size()

		# Create shared material for this cluster
		var mat := _create_wallpaper_material(cluster_group_id, palette_id, group_index * 7 + 1)

		# Place overlay on each wall cube in this Z row
		for cube_data in z_groups[z_val]:
			var gp: Vector3i = cube_data["pos"]
			var world_pos := grid_origin + Vector3(gp.x, gp.y, gp.z) * total_size
			_add_overlay(world_pos, cs, mat, gp)

		z_count += 1
		if z_count >= cluster_size:
			z_count = 0
			group_index += 1

	# Build ceiling cubes to close the tunnel
	_build_ceiling(grid_origin, positions, z_values, z_groups, cs, total_size)

	# Add lights inside the tunnel
	_add_lights(grid_origin, z_values, total_size)

	var num_groups := mini(group_index + 1, GROUP_NAMES.size())
	print("[WallPatternGallery] Built %d clusters showing %d wallpaper groups on %d Z-rows" % [num_groups, mini(num_groups, GROUP_NAMES.size()), z_values.size()])

func _add_overlay(world_pos: Vector3, cube_size: float, material: ShaderMaterial, gp: Vector3i) -> void:
	# Thin box slightly larger than cube face, offset outward
	var overlay := MeshInstance3D.new()
	var box := BoxMesh.new()
	var thickness := 0.02

	# Full face overlay on the cube
	box.size = Vector3(cube_size * 1.01, cube_size * 1.01, thickness)
	overlay.mesh = box
	overlay.material_override = material

	# Position at the cube's center, offset slightly on Z to avoid z-fighting
	overlay.global_position = world_pos + Vector3(0, 0, cube_size * 0.51)
	overlay.name = "PatternOverlay_%d_%d_%d" % [gp.x, gp.y, gp.z]
	add_child(overlay)

	# Also add overlay on opposite Z face
	var overlay_back := MeshInstance3D.new()
	overlay_back.mesh = box
	overlay_back.material_override = material
	overlay_back.global_position = world_pos - Vector3(0, 0, cube_size * 0.51)
	add_child(overlay_back)

	# Add overlays on X faces for side views
	var box_x := BoxMesh.new()
	box_x.size = Vector3(thickness, cube_size * 1.01, cube_size * 1.01)

	var overlay_left := MeshInstance3D.new()
	overlay_left.mesh = box_x
	overlay_left.material_override = material
	overlay_left.global_position = world_pos - Vector3(cube_size * 0.51, 0, 0)
	add_child(overlay_left)

	var overlay_right := MeshInstance3D.new()
	overlay_right.mesh = box_x
	overlay_right.material_override = material
	overlay_right.global_position = world_pos + Vector3(cube_size * 0.51, 0, 0)
	add_child(overlay_right)

	# Top face
	var box_y := BoxMesh.new()
	box_y.size = Vector3(cube_size * 1.01, thickness, cube_size * 1.01)

	var overlay_top := MeshInstance3D.new()
	overlay_top.mesh = box_y
	overlay_top.material_override = material
	overlay_top.global_position = world_pos + Vector3(0, cube_size * 0.51, 0)
	add_child(overlay_top)

func _create_wallpaper_material(group_id: int, palette_id: int, seed_val: int) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = _wallpaper_shader
	mat.set_shader_parameter("wallpaper_group", group_id)
	mat.set_shader_parameter("tile_scale", tile_scale)
	mat.set_shader_parameter("grout_width", grout_width)
	mat.set_shader_parameter("grout_color", Vector3(0.05, 0.05, 0.08))
	mat.set_shader_parameter("emission_strength", emission_strength)
	mat.set_shader_parameter("roughness", 0.4)
	mat.set_shader_parameter("metallic", 0.1)
	mat.set_shader_parameter("noise_distort", 0.01)

	# Generate domain texture
	var domain_tex := _generate_domain_texture(seed_val, palette_id)
	mat.set_shader_parameter("domain_texture", domain_tex)

	return mat

func _generate_domain_texture(seed_val: int, palette_id: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var palette: Array = PALETTES[palette_id % PALETTES.size()]

	var size := 8
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)

	# Pattern type varies by seed
	var pattern_type := seed_val % 6

	for y in range(size):
		for x in range(size):
			var color: Color
			match pattern_type:
				0:  # Blocks
					var block_x := x / 4
					var block_y := y / 4
					color = palette[(block_x + block_y * 2) % palette.size()]
				1:  # Stripes
					color = palette[x % palette.size()]
				2:  # Diagonal
					color = palette[(x + y) % palette.size()]
				3:  # Concentric
					var cx := absi(x - 3)
					var cy := absi(y - 3)
					color = palette[maxi(cx, cy) % palette.size()]
				4:  # Checker
					color = palette[(x + y) % 2]
				5:  # Cross
					if x == 3 or x == 4 or y == 3 or y == 4:
						color = palette[0]
					else:
						color = palette[((x / 2) + (y / 2)) % palette.size()]
			img.set_pixel(x, y, color)

	var tex := ImageTexture.create_from_image(img)
	return tex

func _build_ceiling(grid_origin: Vector3, positions: Array, z_values: Array, z_groups: Dictionary, cs: float, total_size: float) -> void:
	# Find the tunnel dimensions: max Y of wall cubes, and X range of void cells
	var max_y: int = 0
	var x_occupied: Dictionary = {}  # Track which X positions have cubes per Z

	for i in positions.size():
		var gp: Vector3i = positions[i]
		if gp.y > max_y:
			max_y = gp.y
		if not x_occupied.has(gp.z):
			x_occupied[gp.z] = {}
		x_occupied[gp.z][gp.x] = true

	# Find the void gap (X positions without cubes) to span ceiling across
	if z_values.is_empty():
		return

	var first_z: int = z_values[0]
	var all_x: Array = []
	if x_occupied.has(first_z):
		all_x = x_occupied[first_z].keys()
	all_x.sort()

	if all_x.is_empty():
		return

	var x_min: int = all_x[0]
	var x_max: int = all_x[-1]

	# Ceiling goes at y = max_y + 1, spanning from x_min to x_max
	var ceiling_y: float = float(max_y + 1) * total_size
	var group_index: int = 0
	var z_count: int = 0

	# Also build floor cubes with patterns across the walkway
	for z_val in z_values:
		var cluster_group_id: int = group_index % GROUP_NAMES.size()
		var palette_id: int = group_index % PALETTES.size()
		var mat := _create_wallpaper_material(cluster_group_id, palette_id, group_index * 7 + 1)

		# Ceiling cubes spanning full width
		for x in range(x_min, x_max + 1):
			var ceil_pos := grid_origin + Vector3(float(x) * total_size, ceiling_y, float(z_val) * total_size)
			var ceil_cube := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(cs, cs, cs)
			ceil_cube.mesh = box
			ceil_cube.material_override = mat
			ceil_cube.global_position = ceil_pos
			add_child(ceil_cube)

		# Floor pattern cubes in the walkway (void cells)
		for x in range(x_min, x_max + 1):
			if x_occupied.has(z_val) and x_occupied[z_val].has(x):
				continue  # Skip cells that already have grid cubes
			var floor_pos := grid_origin + Vector3(float(x) * total_size, 0.0, float(z_val) * total_size)
			var floor_cube := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(cs, cs * 0.1, cs)
			floor_cube.mesh = box
			floor_cube.material_override = mat
			floor_cube.global_position = floor_pos
			add_child(floor_cube)

		z_count += 1
		if z_count >= cluster_size:
			z_count = 0
			group_index += 1

	print("[WallPatternGallery] Built ceiling + floor at y=%d spanning x=%d to x=%d" % [max_y + 1, x_min, x_max])

func _add_lights(grid_origin: Vector3, z_values: Array, total_size: float) -> void:
	if z_values.is_empty():
		return
	var z_min: int = z_values[0]
	var z_max: int = z_values[-1]
	var light_spacing := 4
	var z := z_min
	while z <= z_max:
		var light := OmniLight3D.new()
		light.position = grid_origin + Vector3(2.0, 2.0, float(z) * total_size)
		light.light_energy = 3.0
		light.omni_range = 6.0
		light.light_color = Color(1.0, 0.97, 0.92)
		light.shadow_enabled = false
		add_child(light)
		z += light_spacing
