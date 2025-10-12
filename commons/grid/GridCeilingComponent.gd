# GridCeilingComponent.gd
# Generates suspended acoustic tile ceilings with integrated fluorescent lighting
# Creates institutional atmosphere with T-grid structure and diffused lighting

extends Node
class_name GridCeilingComponent

# References
var grid_system: Node3D
var data_component: GridDataComponent

# Ceiling configuration
var ceiling_height: float = 4.0  # Height from floor
var tile_size: float = 0.5  # Tile size - should match grid cell size
var grid_thickness: float = 0.02  # T-grid metal thickness
var drop_distance: float = 0.3  # Distance ceiling drops from actual ceiling
var ceiling_width: float = -1.0  # Coverage width in meters (-1 = auto from grid)
var ceiling_depth: float = -1.0  # Coverage depth in meters (-1 = auto from grid)
var cube_size: float = 1.0  # Grid cube size (from grid system)
var gutter: float = 0.0  # Grid gutter (from grid system)

# Materials
var tile_material: StandardMaterial3D
var grid_material: StandardMaterial3D
var light_material: StandardMaterial3D

# Lighting configuration
var light_spacing: int = 2  # Place light every 2 tiles
var light_intensity: float = 1.5
var light_color: Color = Color(0.95, 0.95, 1.0)  # Cool fluorescent white
var light_pattern: String = "sparse"  # Pattern type: sparse, random, sine, growing, checkerboard, perimeter

# State
var ceiling_tiles: Array[Node3D] = []
var ceiling_lights: Array[Node3D] = []

# Signals
signal ceiling_generation_complete(tile_count: int, light_count: int)

func _ready():
	print("GridCeilingComponent: Initialized")
	_setup_materials()

# Initialize component
func initialize(grid_sys: Node3D, data_comp: GridDataComponent, settings: Dictionary = {}):
	grid_system = grid_sys
	data_component = data_comp

	# Apply settings
	ceiling_height = settings.get("ceiling_height", ceiling_height)
	tile_size = settings.get("tile_size", tile_size)
	ceiling_width = settings.get("ceiling_width", ceiling_width)
	ceiling_depth = settings.get("ceiling_depth", ceiling_depth)
	light_spacing = settings.get("light_spacing", light_spacing)
	light_intensity = settings.get("light_intensity", light_intensity)
	light_pattern = settings.get("light_pattern", light_pattern)

	# Get grid spacing from settings to align ceiling with floor grid
	cube_size = settings.get("cube_size", cube_size)
	gutter = settings.get("gutter", gutter)

	# Override tile_size to match grid cell size (cube_size + gutter)
	var grid_cell_size = cube_size + gutter
	tile_size = 0.5  # Force 0.5m cells for ceiling grid

	print("GridCeilingComponent: Ready to generate ceiling")
	print("  Height: %s, Tile size: %s, Light spacing: %d" % [ceiling_height, tile_size, light_spacing])

# Setup materials for ceiling elements
func _setup_materials():
	# Acoustic tile material - off-white with slight texture
	tile_material = StandardMaterial3D.new()
	tile_material.albedo_color = Color(0.92, 0.92, 0.90)  # Off-white
	tile_material.roughness = 0.85  # Matte finish
	tile_material.metallic = 0.0

	# T-grid metal material
	grid_material = StandardMaterial3D.new()
	grid_material.albedo_color = Color(0.7, 0.7, 0.7)  # Light gray metal
	grid_material.roughness = 0.5
	grid_material.metallic = 0.8

	# Light panel material - emissive
	light_material = StandardMaterial3D.new()
	light_material.albedo_color = light_color
	light_material.emission_enabled = true
	light_material.emission = light_color
	light_material.emission_energy_multiplier = 2.0
	light_material.roughness = 0.3

# Generate ceiling for the entire grid
func generate_ceiling(ceiling_config: Dictionary = {}):
	print("GridCeilingComponent: Generating suspended ceiling...")

	# Parse config if provided (from map data)
	_parse_ceiling_config(ceiling_config)

	# Get grid dimensions
	var dimensions = data_component.get_grid_dimensions()
	if dimensions == Vector3i.ZERO:
		print("GridCeilingComponent: WARNING - No grid dimensions available")
		return

	# Clear existing ceiling
	clear_ceiling()

	# Calculate ceiling bounds in 0.5m cells
	var width: int
	var depth: int

	# Calculate how many 0.5m ceiling cells we need to cover the grid area
	var grid_width_m = dimensions.x * (cube_size + gutter)
	var grid_depth_m = dimensions.z * (cube_size + gutter)

	# Use explicit width/depth if specified, otherwise calculate from grid dimensions
	if ceiling_width > 0:
		width = int(ceiling_width / tile_size)
	else:
		# Each grid cell might contain multiple 0.5m ceiling cells
		width = int(grid_width_m / tile_size)

	if ceiling_depth > 0:
		depth = int(ceiling_depth / tile_size)
	else:
		depth = int(grid_depth_m / tile_size)

	var coverage_width_m = width * tile_size
	var coverage_depth_m = depth * tile_size

	print("GridCeilingComponent: Creating ceiling with 0.5m cells covering %.1fm × %.1fm (%d×%d cells) at height %.1fm" % [coverage_width_m, coverage_depth_m, width, depth, ceiling_height])
	print("  Grid dimensions: %dx%d (cube_size: %.1fm, gutter: %.1fm)" % [dimensions.x, dimensions.z, cube_size, gutter])

	# Generate T-grid structure
	_generate_grid_structure(width, depth)

	# Generate acoustic tiles
	var tile_count = _generate_ceiling_tiles(width, depth)

	# Generate integrated light panels
	var light_count = _generate_light_panels(width, depth)

	print("GridCeilingComponent: ✅ Ceiling complete - %d tiles, %d lights" % [tile_count, light_count])
	ceiling_generation_complete.emit(tile_count, light_count)

# Parse ceiling configuration from map data
func _parse_ceiling_config(config: Dictionary):
	if config.is_empty():
		return

	# Apply preset configurations FIRST (if specified)
	var preset = config.get("preset", "")
	match preset:
		"institutional":
			ceiling_height = 4.0
			light_spacing = 2
			light_intensity = 1.5
			light_pattern = "sparse"
		"laboratory":
			ceiling_height = 4.5
			light_spacing = 1
			light_intensity = 2.0
			light_pattern = "checkerboard"
		"office":
			ceiling_height = 3.5
			light_spacing = 2
			light_intensity = 1.2
			light_pattern = "sparse"
		"warehouse":
			ceiling_height = 6.0
			light_spacing = 3
			light_intensity = 1.8
			light_pattern = "random"
		"liminal":
			ceiling_height = 4.0
			light_spacing = 2
			light_intensity = 1.3
			light_pattern = "sine"
		"growing":
			ceiling_height = 4.0
			light_spacing = 2
			light_intensity = 1.5
			light_pattern = "growing"

	# Then apply custom overrides (these override preset values)
	if config.has("height"):
		ceiling_height = config.get("height")
	if config.has("tile_size"):
		tile_size = config.get("tile_size")
	if config.has("width"):
		ceiling_width = config.get("width")
	if config.has("depth"):
		ceiling_depth = config.get("depth")
	if config.has("light_spacing"):
		light_spacing = config.get("light_spacing")
	if config.has("light_intensity"):
		light_intensity = config.get("light_intensity")
	if config.has("pattern"):
		light_pattern = config.get("pattern")

# Generate T-grid structure
func _generate_grid_structure(width: int, depth: int):
	var grid_container = Node3D.new()
	grid_container.name = "CeilingGrid"
	grid_system.add_child(grid_container)

	# Create horizontal grid lines (along X axis)
	for z in range(depth + 1):
		var grid_line = _create_grid_beam(width, grid_thickness)
		grid_line.position = Vector3(width / 2.0, ceiling_height, z * tile_size)
		grid_container.add_child(grid_line)

	# Create depth grid lines (along Z axis)
	for x in range(width + 1):
		var grid_line = _create_grid_beam(depth, grid_thickness)
		grid_line.position = Vector3(x * tile_size, ceiling_height, depth / 2.0)
		grid_line.rotation_degrees = Vector3(0, 90, 0)
		grid_container.add_child(grid_line)

# Create a single T-grid beam
func _create_grid_beam(length: float, thickness: float) -> MeshInstance3D:
	var beam = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(length, thickness, thickness)
	beam.mesh = box_mesh
	beam.material_override = grid_material
	return beam

# Generate acoustic ceiling tiles
func _generate_ceiling_tiles(width: int, depth: int) -> int:
	var tiles_container = Node3D.new()
	tiles_container.name = "CeilingTiles"
	grid_system.add_child(tiles_container)

	var tile_count = 0

	for x in range(width):
		for z in range(depth):
			# Check if this position should have a light panel instead
			if _should_place_light(x, z):
				continue

			var tile = _create_ceiling_tile()
			tile.position = Vector3(
				x * tile_size + tile_size / 2.0,
				ceiling_height + 0.005,  # Tiny bit above grid to show T-grid structure
				z * tile_size + tile_size / 2.0
			)
			tiles_container.add_child(tile)
			ceiling_tiles.append(tile)
			tile_count += 1

	return tile_count

# Check if position should have a light panel
func _should_place_light(x: int, z: int) -> bool:
	match light_pattern:
		"sparse":
			# Sparse institutional pattern
			# Pattern: O O O O O
			#          O L O O L
			#          O O O O O
			return (x % 3 == 1) and (z % 3 == 1)

		"checkerboard":
			# Alternating checkerboard
			# Pattern: O L O L
			#          L O L O
			return (x + z) % 2 == 0

		"random":
			# Random placement with seed based on position
			var rng = RandomNumberGenerator.new()
			rng.seed = hash(Vector2i(x, z))
			return rng.randf() < 0.3  # 30% chance of light

		"sine":
			# Sinusoidal wave pattern - creates flowing light pattern
			var wave_x = sin(x * 0.5)
			var wave_z = sin(z * 0.5)
			var combined = (wave_x + wave_z) / 2.0
			return combined > 0.3

		"growing":
			# Density increases from center outward (or inward)
			var dimensions = data_component.get_grid_dimensions() if data_component else Vector3i(10, 6, 10)
			var center_x = dimensions.x / 2.0
			var center_z = dimensions.z / 2.0
			var dist = sqrt(pow(x - center_x, 2) + pow(z - center_z, 2))
			var max_dist = sqrt(pow(center_x, 2) + pow(center_z, 2))
			var normalized_dist = dist / max_dist
			# More lights toward edges
			return randf() < normalized_dist * 0.6

		"perimeter":
			# Lights only on edges/perimeter
			var dimensions = data_component.get_grid_dimensions() if data_component else Vector3i(10, 6, 10)
			var is_edge = (x == 0 or x == dimensions.x - 1 or z == 0 or z == dimensions.z - 1)
			return is_edge and (x % 2 == 0 or z % 2 == 0)

		"grid":
			# Regular grid pattern based on spacing
			return (x % light_spacing == 0) and (z % light_spacing == 0)

		_:
			# Default to sparse
			return (x % 3 == 1) and (z % 3 == 1)

# Create a single acoustic ceiling tile
func _create_ceiling_tile() -> MeshInstance3D:
	var tile = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	# Make tiles slightly smaller to show T-grid structure (92% of tile_size)
	var visible_tile_size = tile_size * 0.92
	plane_mesh.size = Vector2(visible_tile_size, visible_tile_size)
	tile.mesh = plane_mesh
	tile.material_override = tile_material
	tile.rotation_degrees = Vector3(180, 0, 0)  # Flip to face downward

	# Add slight random variation for realism
	tile.scale = Vector3(1.0, 1.0, randf_range(0.998, 1.002))

	return tile

# Generate integrated fluorescent light panels
func _generate_light_panels(width: int, depth: int) -> int:
	var lights_container = Node3D.new()
	lights_container.name = "CeilingLights"
	grid_system.add_child(lights_container)

	var light_count = 0

	for x in range(width):
		for z in range(depth):
			if _should_place_light(x, z):
				var light_panel = _create_light_panel()
				light_panel.position = Vector3(
					x * tile_size + tile_size / 2.0,
					ceiling_height + 0.005,  # Same height as tiles (tiny bit above grid)
					z * tile_size + tile_size / 2.0
				)
				lights_container.add_child(light_panel)
				ceiling_lights.append(light_panel)
				light_count += 1

	return light_count

# Create a light panel with integrated OmniLight3D
func _create_light_panel() -> Node3D:
	var light_panel = Node3D.new()

	# Create the glowing panel mesh
	var panel_mesh = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	# Make light panels same size as tiles (92% of tile_size)
	var visible_tile_size = tile_size * 0.92
	plane.size = Vector2(visible_tile_size, visible_tile_size)
	panel_mesh.mesh = plane
	panel_mesh.material_override = light_material
	panel_mesh.rotation_degrees = Vector3(180, 0, 0)  # Flip to face downward
	light_panel.add_child(panel_mesh)

	# Add actual light source
	var light = OmniLight3D.new()
	light.light_color = light_color
	light.light_energy = light_intensity
	light.omni_range = tile_size * 3.0
	light.omni_attenuation = 0.5  # Soft falloff for diffused lighting
	light.position = Vector3(0, -0.1, 0)  # Below the panel
	light_panel.add_child(light)

	# Add slight flicker for realism (optional)
	if randf() < 0.1:  # 10% of lights have subtle flicker
		_add_subtle_flicker(light)

	return light_panel

# Add subtle flicker effect to simulate fluorescent behavior
func _add_subtle_flicker(light: OmniLight3D):
	var timer = Timer.new()
	timer.wait_time = randf_range(3.0, 8.0)
	timer.autostart = true
	timer.timeout.connect(func():
		# Very subtle energy variation
		var tween = create_tween()
		tween.tween_property(light, "light_energy", light_intensity * 0.95, 0.05)
		tween.tween_property(light, "light_energy", light_intensity, 0.05)
		timer.wait_time = randf_range(3.0, 8.0)
	)
	light.add_child(timer)

# Clear all ceiling elements
func clear_ceiling():
	# Clear tiles
	for tile in ceiling_tiles:
		if tile and is_instance_valid(tile):
			tile.queue_free()
	ceiling_tiles.clear()

	# Clear lights
	for light in ceiling_lights:
		if light and is_instance_valid(light):
			light.queue_free()
	ceiling_lights.clear()

	# Clear container nodes
	if grid_system:
		var grid_node = grid_system.find_child("CeilingGrid", false, false)
		if grid_node:
			grid_node.queue_free()

		var tiles_node = grid_system.find_child("CeilingTiles", false, false)
		if tiles_node:
			tiles_node.queue_free()

		var lights_node = grid_system.find_child("CeilingLights", false, false)
		if lights_node:
			lights_node.queue_free()

# Get ceiling info for debugging
func get_ceiling_info() -> Dictionary:
	return {
		"height": ceiling_height,
		"tile_size": tile_size,
		"tile_count": ceiling_tiles.size(),
		"light_count": ceiling_lights.size(),
		"light_spacing": light_spacing
	}

# Public API to adjust lighting dynamically
func set_light_intensity(intensity: float):
	light_intensity = intensity
	for light_panel in ceiling_lights:
		var light = light_panel.find_child("OmniLight3D", false, false)
		if light:
			light.light_energy = intensity

func set_light_color(color: Color):
	light_color = color
	for light_panel in ceiling_lights:
		var light = light_panel.find_child("OmniLight3D", false, false)
		if light:
			light.light_color = color
