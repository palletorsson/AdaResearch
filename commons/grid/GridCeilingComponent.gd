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
var ceiling_offset_x: float = 0.0  # X offset in meters for ceiling placement
var ceiling_offset_z: float = 0.0  # Z offset in meters for ceiling placement
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
var ceiling_fixtures: Array[Node3D] = []

# Ceiling fixtures — procedural overhead props (vents, sprinklers,
# sensors, speakers, extra light panels) distributed deterministically
# across the ceiling. Each type's count is independent. Driven by the
# map's settings.ceiling.fixtures config block.
var fixtures_seed: int = 42
var fixture_vent_count: int = 0
var fixture_sprinkler_count: int = 0
var fixture_sensor_count: int = 0
var fixture_speaker_count: int = 0
var fixture_panel_count: int = 0     # extra recessed light panels (decor, no Light3D)

# Grid dimensions in cells (stored after generation)
var grid_width_cells: int = 0
var grid_depth_cells: int = 0

# Disco / Array Learning State
var array_learning_enabled: bool = false
var light_map: Dictionary = {}
var disco_timer: float = 0.0
var current_lesson: int = 0
var animation_step: int = 0
var step_timer: float = 0.0
var animation_speed: float = 0.05
var lesson_duration: float = 10.0

enum ArrayLesson {
	CORNER_BLINK,
	ROW_LIGHTING,
	COLUMN_LIGHTING,
	SNAKE_PATTERN,
	SPIRAL_INWARD,
	PULSE_CENTER,
	WAVE_DIAGONAL,
	DISCO_CELEBRATION,
	INDEX_LINEAR_SCAN,
	INDEX_STRIDE,
	SUBARRAY_REGION,
	DIAGONAL_ACCESS
}

var lesson_colors: Dictionary = {
	ArrayLesson.CORNER_BLINK: Color.YELLOW,
	ArrayLesson.ROW_LIGHTING: Color.CYAN,
	ArrayLesson.COLUMN_LIGHTING: Color.MAGENTA,
	ArrayLesson.SNAKE_PATTERN: Color.GREEN,
	ArrayLesson.SPIRAL_INWARD: Color.ORANGE,
	ArrayLesson.PULSE_CENTER: Color.RED,
	ArrayLesson.WAVE_DIAGONAL: Color.BLUE,
	ArrayLesson.DISCO_CELEBRATION: Color.WHITE,
	ArrayLesson.INDEX_LINEAR_SCAN: Color.LIME,
	ArrayLesson.INDEX_STRIDE: Color.PURPLE,
	ArrayLesson.SUBARRAY_REGION: Color.TEAL,
	ArrayLesson.DIAGONAL_ACCESS: Color.PINK
}

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
	print("  Grid dimensions: %dx%d (cube_size: %.1fm, gutter: %.1fm) offset: (%.1f, %.1f)" % [dimensions.x, dimensions.z, cube_size, gutter, ceiling_offset_x, ceiling_offset_z])

	# Store dimensions for disco mode
	grid_width_cells = width
	grid_depth_cells = depth

	# Generate T-grid structure
	_generate_grid_structure(width, depth)

	# Generate acoustic tiles
	var tile_count = _generate_ceiling_tiles(width, depth)

	# Generate integrated light panels
	var light_count = _generate_light_panels(width, depth)

	# Generate procedural ceiling fixtures (vents/sprinklers/sensors/speakers/panels)
	var fixture_count = _generate_ceiling_fixtures(width, depth)

	print("GridCeilingComponent: ✅ Ceiling complete - %d tiles, %d lights, %d fixtures" % [tile_count, light_count, fixture_count])
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

	# Size overrides (size_x/size_z override width/depth if both present)
	if config.has("size_x"):
		ceiling_width = config.get("size_x")
	if config.has("size_z"):
		ceiling_depth = config.get("size_z")

	# Offset for ceiling placement
	if config.has("offset_x"):
		ceiling_offset_x = config.get("offset_x")
	if config.has("offset_z"):
		ceiling_offset_z = config.get("offset_z")

	if config.has("array_learning") and config.get("array_learning"):
		# Auto-start array learning (deferred to ensure generation is complete)
		call_deferred("start_array_learning")

	# Fixtures (vents / sprinklers / sensors / speakers / extra panels)
	# A "fixtures" sub-block keeps the config cleanly grouped:
	#   "ceiling": { "preset": "laboratory", "fixtures": {
	#       "seed": 7, "vents": 3, "sprinklers": 5, "sensors": 4,
	#       "speakers": 2, "panels": 0
	#   }}
	# Or use a preset name to load a curated config:
	#   "ceiling": { "fixtures": "research" }
	if config.has("fixtures"):
		var f = config.get("fixtures")
		if typeof(f) == TYPE_STRING:
			_apply_fixture_preset(String(f))
		elif typeof(f) == TYPE_DICTIONARY:
			fixtures_seed = int(f.get("seed", fixtures_seed))
			fixture_vent_count = int(f.get("vents", fixture_vent_count))
			fixture_sprinkler_count = int(f.get("sprinklers", fixture_sprinkler_count))
			fixture_sensor_count = int(f.get("sensors", fixture_sensor_count))
			fixture_speaker_count = int(f.get("speakers", fixture_speaker_count))
			fixture_panel_count = int(f.get("panels", fixture_panel_count))


# Named fixture-mix presets — pick by string instead of authoring counts
# per map. Combine with `preset` for the underlying tile/light spacing.
func _apply_fixture_preset(name: String) -> void:
	match name:
		"minimal":
			fixture_vent_count = 1; fixture_sprinkler_count = 0
			fixture_sensor_count = 1; fixture_speaker_count = 0
			fixture_panel_count = 0
		"research":
			fixture_vent_count = 2; fixture_sprinkler_count = 3
			fixture_sensor_count = 2; fixture_speaker_count = 1
			fixture_panel_count = 2
		"industrial":
			fixture_vent_count = 6; fixture_sprinkler_count = 4
			fixture_sensor_count = 1; fixture_speaker_count = 0
			fixture_panel_count = 0
		"med_lab":
			fixture_vent_count = 1; fixture_sprinkler_count = 5
			fixture_sensor_count = 4; fixture_speaker_count = 3
			fixture_panel_count = 2
		"datacenter":
			fixture_vent_count = 4; fixture_sprinkler_count = 6
			fixture_sensor_count = 3; fixture_speaker_count = 0
			fixture_panel_count = 0
		_:
			push_warning("GridCeilingComponent: unknown fixture preset '%s'" % name)

# Generate T-grid structure
func _generate_grid_structure(width: int, depth: int):
	var grid_container = Node3D.new()
	grid_container.name = "CeilingGrid"
	grid_system.add_child(grid_container)

	# Calculate beam lengths in meters (cells * tile_size)
	var width_m = width * tile_size
	var depth_m = depth * tile_size

	# Create horizontal grid lines (along X axis)
	for z in range(depth + 1):
		var grid_line = _create_grid_beam(width_m, grid_thickness)
		grid_line.position = Vector3(ceiling_offset_x + width_m / 2.0, ceiling_height, ceiling_offset_z + z * tile_size)
		grid_container.add_child(grid_line)

	# Create depth grid lines (along Z axis)
	for x in range(width + 1):
		var grid_line = _create_grid_beam(depth_m, grid_thickness)
		grid_line.position = Vector3(ceiling_offset_x + x * tile_size, ceiling_height, ceiling_offset_z + depth_m / 2.0)
		grid_line.rotation_degrees = Vector3(0, 90, 0)
		grid_container.add_child(grid_line)
	
	# Create solid ceiling top to block exterior light/sky
	_create_ceiling_cap(width, depth, grid_container)

# Create solid ceiling cap to block sky/exterior
func _create_ceiling_cap(width: int, depth: int, container: Node3D):
	var cap = MeshInstance3D.new()
	cap.name = "CeilingCap"
	
	var box = BoxMesh.new()
	# Cover entire ceiling area with thick solid panel above the tiles
	var width_m = width * tile_size + 0.5  # Slight overhang
	var depth_m = depth * tile_size + 0.5
	box.size = Vector3(width_m, 0.3, depth_m)  # 30cm thick solid cap
	cap.mesh = box
	
	# Dark non-reflective material (absorbs light, no rendering overhead)
	var cap_mat = StandardMaterial3D.new()
	cap_mat.albedo_color = Color(0.02, 0.02, 0.02)  # Near black
	cap_mat.roughness = 1.0
	cap_mat.metallic = 0.0
	cap_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # No lighting calcs
	cap.material_override = cap_mat
	
	# Position above the visible ceiling
	cap.position = Vector3(ceiling_offset_x + width_m / 2.0 - 0.25, ceiling_height + 0.2, ceiling_offset_z + depth_m / 2.0 - 0.25)
	container.add_child(cap)
	print("GridCeilingComponent: Created ceiling cap (%.1fm x %.1fm)" % [width_m, depth_m])

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
				ceiling_offset_x + x * tile_size + tile_size / 2.0,
				ceiling_height + 0.005,  # Tiny bit above grid to show T-grid structure
				ceiling_offset_z + z * tile_size + tile_size / 2.0
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
	# Make tiles nearly full size with minimal gap (98% of tile_size)
	var visible_tile_size = tile_size * 0.98
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
	
	light_map.clear()

	var light_count = 0

	for x in range(width):
		for z in range(depth):
			if _should_place_light(x, z):
				var light_panel = _create_light_panel()
				light_panel.position = Vector3(
					ceiling_offset_x + x * tile_size + tile_size / 2.0,
					ceiling_height + 0.005,  # Same height as tiles (tiny bit above grid)
					ceiling_offset_z + z * tile_size + tile_size / 2.0
				)
				lights_container.add_child(light_panel)
				ceiling_lights.append(light_panel)
				light_map[Vector2i(x, z)] = light_panel
				light_count += 1

	return light_count

# Create a light panel - optimized for performance
# Uses emission for visual glow, OmniLight only for key lights
func _create_light_panel() -> Node3D:
	var light_panel = Node3D.new()

	# Create the glowing panel mesh
	var panel_mesh = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	var visible_tile_size = tile_size * 0.98
	plane.size = Vector2(visible_tile_size, visible_tile_size)
	panel_mesh.mesh = plane
	panel_mesh.name = "PanelMesh"
	panel_mesh.material_override = light_material.duplicate()
	panel_mesh.rotation_degrees = Vector3(180, 0, 0)
	light_panel.add_child(panel_mesh)

	# Only add actual OmniLight to sparse key positions (1 in 4)
	# Most panels just use emissive material (free)
	var panel_count = ceiling_lights.size()
	if panel_count % 4 == 0:
		var light = OmniLight3D.new()
		light.light_color = light_color
		light.light_energy = light_intensity * 2.0  # Boost since fewer lights
		light.omni_range = tile_size * 5.0  # Larger range
		light.omni_attenuation = 0.7
		light.shadow_enabled = false  # No shadows = much faster
		light.position = Vector3(0, -0.1, 0)
		light_panel.add_child(light)

	return light_panel


# ── Procedural ceiling fixtures ───────────────────────────────────────
# Distribute vents/sprinklers/sensors/speakers/extra-panels across the
# ceiling deterministically using fixtures_seed. Picks positions from a
# candidate-cell grid scaled to ceiling coverage; seeded shuffle keeps
# the layout reproducible. Fixtures hang BELOW the ceiling plane as
# small protrusions so they read as ceiling-mounted equipment.
func _generate_ceiling_fixtures(width: int, depth: int) -> int:
	# If no fixtures requested, skip — most existing maps won't have
	# the `fixtures` config block at all and shouldn't get spammed.
	var total: int = fixture_vent_count + fixture_sprinkler_count \
		+ fixture_sensor_count + fixture_speaker_count + fixture_panel_count
	if total <= 0:
		return 0

	var container := Node3D.new()
	container.name = "CeilingFixtures"
	grid_system.add_child(container)

	# Candidate grid in METRES along the ceiling coverage. We sample
	# every ~1m so fixtures don't crowd against the T-grid metal.
	var cell_m: float = 1.0
	var cols: int = max(1, int((width * tile_size) / cell_m))
	var rows: int = max(1, int((depth * tile_size) / cell_m))
	var step_x: float = (width * tile_size) / float(cols)
	var step_z: float = (depth * tile_size) / float(rows)

	var rng := RandomNumberGenerator.new()
	rng.seed = fixtures_seed

	var positions: Array = []
	for ix in range(cols):
		for iz in range(rows):
			var x: float = ceiling_offset_x + step_x * (ix + 0.5)
			var z: float = ceiling_offset_z + step_z * (iz + 0.5)
			# Small jitter so the layout doesn't look mechanically gridded.
			x += rng.randf_range(-step_x * 0.15, step_x * 0.15)
			z += rng.randf_range(-step_z * 0.15, step_z * 0.15)
			positions.append(Vector3(x, ceiling_height, z))

	# Seeded shuffle.
	for i in range(positions.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp = positions[i]; positions[i] = positions[j]; positions[j] = tmp

	# Consume positions in fixed order so tweaking one count doesn't
	# reshuffle the others.
	var idx: int = 0
	var placed: int = 0
	for _i in range(fixture_vent_count):
		if idx >= positions.size(): break
		_add_grid_vent_fixture(container, positions[idx]); idx += 1; placed += 1
	for _i in range(fixture_sprinkler_count):
		if idx >= positions.size(): break
		_add_grid_sprinkler_fixture(container, positions[idx]); idx += 1; placed += 1
	for _i in range(fixture_sensor_count):
		if idx >= positions.size(): break
		_add_grid_sensor_fixture(container, positions[idx]); idx += 1; placed += 1
	for _i in range(fixture_speaker_count):
		if idx >= positions.size(): break
		_add_grid_speaker_fixture(container, positions[idx]); idx += 1; placed += 1
	for _i in range(fixture_panel_count):
		if idx >= positions.size(): break
		_add_grid_panel_fixture(container, positions[idx]); idx += 1; placed += 1
	return placed


func _add_grid_vent_fixture(parent: Node3D, anchor: Vector3) -> void:
	var n := MeshInstance3D.new()
	n.name = "Vent"
	var bm := BoxMesh.new()
	bm.size = Vector3(0.40, 0.04, 0.40)
	n.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.20, 0.22)
	mat.roughness = 0.55
	mat.metallic = 0.5
	n.material_override = mat
	n.position = Vector3(anchor.x, anchor.y - 0.02, anchor.z)
	parent.add_child(n)
	ceiling_fixtures.append(n)


func _add_grid_sprinkler_fixture(parent: Node3D, anchor: Vector3) -> void:
	var disc := MeshInstance3D.new()
	disc.name = "SprinklerDisc"
	var dm := CylinderMesh.new()
	dm.top_radius = 0.06; dm.bottom_radius = 0.06; dm.height = 0.012
	disc.mesh = dm
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.85, 0.85, 0.88)
	dmat.roughness = 0.45; dmat.metallic = 0.3
	disc.material_override = dmat
	disc.position = Vector3(anchor.x, anchor.y - 0.006, anchor.z)
	parent.add_child(disc)
	ceiling_fixtures.append(disc)
	var nozzle := MeshInstance3D.new()
	nozzle.name = "SprinklerNozzle"
	var nm := CylinderMesh.new()
	nm.top_radius = 0.022; nm.bottom_radius = 0.012; nm.height = 0.06
	nozzle.mesh = nm
	var nmat := StandardMaterial3D.new()
	nmat.albedo_color = Color(0.82, 0.58, 0.22)  # brass
	nmat.roughness = 0.35; nmat.metallic = 0.75
	nozzle.material_override = nmat
	nozzle.position = Vector3(anchor.x, anchor.y - 0.04, anchor.z)
	parent.add_child(nozzle)
	ceiling_fixtures.append(nozzle)


func _add_grid_sensor_fixture(parent: Node3D, anchor: Vector3) -> void:
	var disc := MeshInstance3D.new()
	disc.name = "SmokeDetector"
	var dm := CylinderMesh.new()
	dm.top_radius = 0.075; dm.bottom_radius = 0.075; dm.height = 0.025
	disc.mesh = dm
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.94, 0.94, 0.95)
	dmat.roughness = 0.45
	disc.material_override = dmat
	disc.position = Vector3(anchor.x, anchor.y - 0.012, anchor.z)
	parent.add_child(disc)
	ceiling_fixtures.append(disc)
	var led := MeshInstance3D.new()
	led.name = "SensorLED"
	var lm := SphereMesh.new()
	lm.radius = 0.008; lm.height = 0.016
	led.mesh = lm
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(0.95, 0.20, 0.22)
	lmat.emission_enabled = true
	lmat.emission = Color(0.95, 0.20, 0.22)
	lmat.emission_energy_multiplier = 2.2
	lmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	led.material_override = lmat
	led.position = Vector3(anchor.x + 0.03, anchor.y - 0.025, anchor.z + 0.02)
	parent.add_child(led)
	ceiling_fixtures.append(led)


func _add_grid_speaker_fixture(parent: Node3D, anchor: Vector3) -> void:
	var ring := MeshInstance3D.new()
	ring.name = "SpeakerRim"
	var rm := CylinderMesh.new()
	rm.top_radius = 0.10; rm.bottom_radius = 0.10; rm.height = 0.015
	ring.mesh = rm
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.25, 0.26, 0.30)
	rmat.roughness = 0.55; rmat.metallic = 0.35
	ring.material_override = rmat
	ring.position = Vector3(anchor.x, anchor.y - 0.007, anchor.z)
	parent.add_child(ring)
	ceiling_fixtures.append(ring)
	var cone := MeshInstance3D.new()
	cone.name = "SpeakerCone"
	var cm := CylinderMesh.new()
	cm.top_radius = 0.075; cm.bottom_radius = 0.075; cm.height = 0.005
	cone.mesh = cm
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.08, 0.09, 0.11)
	cmat.roughness = 0.85
	cone.material_override = cmat
	cone.position = Vector3(anchor.x, anchor.y - 0.018, anchor.z)
	parent.add_child(cone)
	ceiling_fixtures.append(cone)


func _add_grid_panel_fixture(parent: Node3D, anchor: Vector3) -> void:
	# Extra recessed light panel — same look as the integrated panels
	# but without an OmniLight3D, so you can decorate density without
	# adding more dynamic lights.
	var p := MeshInstance3D.new()
	p.name = "AccentPanel"
	var pm := BoxMesh.new()
	pm.size = Vector3(0.9, 0.03, 0.3)
	p.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.96, 0.97, 1.00)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.98, 0.92)
	mat.emission_energy_multiplier = 0.9
	mat.roughness = 0.25
	p.material_override = mat
	p.position = Vector3(anchor.x, anchor.y - 0.014, anchor.z)
	parent.add_child(p)
	ceiling_fixtures.append(p)


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
	light_map.clear()

	# Clear fixtures (vents/sprinklers/sensors/speakers/extra panels)
	for fx in ceiling_fixtures:
		if fx and is_instance_valid(fx):
			fx.queue_free()
	ceiling_fixtures.clear()
	if grid_system:
		var fx_node = grid_system.find_child("CeilingFixtures", false, false)
		if fx_node:
			fx_node.queue_free()

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

func _process(delta: float):
	if array_learning_enabled:
		_process_array_learning(delta)

func start_array_learning():
	if ceiling_lights.is_empty():
		print("GridCeilingComponent: ❌ Cannot start array learning - no lights generated")
		return
		
	array_learning_enabled = true
	current_lesson = 0
	animation_step = 0
	disco_timer = 0.0
	step_timer = 0.0
	
	# Clear current lighting
	_clear_all_lights()
	print("GridCeilingComponent: 🎓 Array Learning Mode STARTED. Lights: %d, Size: %dx%d" % [ceiling_lights.size(), grid_width_cells, grid_depth_cells])
	_print_current_lesson()

func stop_array_learning():
	array_learning_enabled = false
	_restore_normal_lighting()
	print("GridCeilingComponent: Array Learning Mode STOPPED")

func next_lesson():
	current_lesson = (current_lesson + 1) % ArrayLesson.size()
	disco_timer = 0.0
	animation_step = 0
	step_timer = 0.0
	_clear_all_lights()
	_print_current_lesson()

func _process_array_learning(delta: float):
	disco_timer += delta
	step_timer += delta
	
	# Auto-advance lesson
	if disco_timer >= lesson_duration:
		next_lesson()
		return
		
	match current_lesson:
		ArrayLesson.CORNER_BLINK:
			_lesson_corner_blink()
		ArrayLesson.ROW_LIGHTING:
			_lesson_row_lighting()
		ArrayLesson.COLUMN_LIGHTING:
			_lesson_column_lighting()
		ArrayLesson.SNAKE_PATTERN:
			_lesson_snake_pattern()
		ArrayLesson.SPIRAL_INWARD:
			_lesson_spiral_inward()
		ArrayLesson.PULSE_CENTER:
			_lesson_pulse_center()
		ArrayLesson.WAVE_DIAGONAL:
			_lesson_wave_diagonal()
		ArrayLesson.DISCO_CELEBRATION:
			_lesson_disco_celebration()
		ArrayLesson.INDEX_LINEAR_SCAN:
			_lesson_linear_scan()
		ArrayLesson.INDEX_STRIDE:
			_lesson_stride()
		ArrayLesson.SUBARRAY_REGION:
			_lesson_subarray()
		ArrayLesson.DIAGONAL_ACCESS:
			_lesson_diagonal()

func _clear_all_lights():
	for light_panel in ceiling_lights:
		var light = light_panel.find_child("OmniLight3D", false, false)
		if light:
			light.light_color = Color.BLACK
			light.light_energy = 0.0
			
		var input_mesh = light_panel.find_child("PanelMesh", false, false)
		if input_mesh and input_mesh.material_override:
			input_mesh.material_override.albedo_color = Color.BLACK
			input_mesh.material_override.emission = Color.BLACK

func _restore_normal_lighting():
	for light_panel in ceiling_lights:
		var light = light_panel.find_child("OmniLight3D", false, false)
		if light:
			light.light_color = light_color
			light.light_energy = light_intensity
			
		var input_mesh = light_panel.find_child("PanelMesh", false, false)
		if input_mesh and input_mesh.material_override:
			input_mesh.material_override.albedo_color = light_color
			input_mesh.material_override.emission = light_color

# Public API for external control (DiscoGridAlgorithm)
func light_ceiling_at(x: int, z: int, color: Color):
	_light_ceiling_at(x, z, color)

func clear_all_lights():
	_clear_all_lights()

func _light_ceiling_at(x: int, z: int, color: Color):
	if light_map.has(Vector2i(x, z)):
		var panel = light_map[Vector2i(x, z)]
		var light = panel.find_child("OmniLight3D", false, false)
		if light:
			if color == Color.BLACK:
				light.light_energy = 0.0
			else:
				light.light_color = color
				light.light_energy = 3.0 # Boost for visibility
		
		var input_mesh = panel.find_child("PanelMesh", false, false)
		if input_mesh and input_mesh.material_override:
			input_mesh.material_override.albedo_color = color
			input_mesh.material_override.emission = color

# === LESSONS ===

func _lesson_corner_blink():
	if step_timer >= animation_speed * 10.0: # Slower blink
		step_timer = 0.0
		_clear_all_lights()
		
		var corners = [
			Vector2i(0, 0),
			Vector2i(grid_width_cells - 1, 0),
			Vector2i(0, grid_depth_cells - 1),
			Vector2i(grid_width_cells - 1, grid_depth_cells - 1)
		]
		
		var corner = corners[animation_step % corners.size()]
		_light_ceiling_at(corner.x, corner.y, lesson_colors[ArrayLesson.CORNER_BLINK])
		animation_step += 1

func _lesson_row_lighting():
	if step_timer >= animation_speed:
		step_timer = 0.0
		
		# Clear previous ONLY if starting new row? No, keep it building?
		# Original disco cleared every step? No.
		# Let's clear row by row.
		
		var current_row = animation_step % grid_depth_cells
		if current_row == 0:
			_clear_all_lights()
			
		for x in range(grid_width_cells):
			_light_ceiling_at(x, current_row, lesson_colors[ArrayLesson.ROW_LIGHTING])
		
		animation_step += 1

func _lesson_column_lighting():
	if step_timer >= animation_speed:
		step_timer = 0.0
		
		var current_col = animation_step % grid_width_cells
		if current_col == 0:
			_clear_all_lights()
			
		for z in range(grid_depth_cells):
			_light_ceiling_at(current_col, z, lesson_colors[ArrayLesson.COLUMN_LIGHTING])
			
		animation_step += 1

func _lesson_snake_pattern():
	if step_timer >= animation_speed * 0.5:
		step_timer = 0.0
		_clear_all_lights()
		
		# Generate snake pattern on the fly or cached
		# For large grids, simple logic is better
		var total_cells = grid_width_cells * grid_depth_cells
		var current_idx = animation_step % total_cells
		
		var z = current_idx / grid_width_cells
		var x = current_idx % grid_width_cells
		if z % 2 == 1: # Zigzag
			x = (grid_width_cells - 1) - x
			
		_light_ceiling_at(x, z, lesson_colors[ArrayLesson.SNAKE_PATTERN])
		
		# Trail
		for i in range(1, 5):
			var trail_idx = (current_idx - i + total_cells) % total_cells
			var tz = trail_idx / grid_width_cells
			var tx = trail_idx % grid_width_cells
			if tz % 2 == 1: tx = (grid_width_cells - 1) - tx
			_light_ceiling_at(tx, tz, lesson_colors[ArrayLesson.SNAKE_PATTERN] * (1.0 - i/5.0))
			
		animation_step += 1

func _lesson_spiral_inward():
	if step_timer >= animation_speed:
		step_timer = 0.0
		
		# Generating full spiral list might be needed
		# Let's implement robust spiral generator
		var positions = _generate_spiral_pattern()
		if positions.is_empty():
			return
			
		var idx = animation_step % positions.size()
		if idx == 0: _clear_all_lights()
		
		var pos = positions[idx]
		_light_ceiling_at(pos.x, pos.y, lesson_colors[ArrayLesson.SPIRAL_INWARD])
		
		animation_step += 1

func _lesson_pulse_center():
	var center = Vector2(grid_width_cells / 2.0, grid_depth_cells / 2.0)
	var max_dist = max(grid_width_cells, grid_depth_cells) * 0.7
	var pulse_r = (sin(disco_timer * 2.0) * 0.5 + 0.5) * max_dist
	
	_clear_all_lights()
	for x in range(grid_width_cells):
		for z in range(grid_depth_cells):
			var dist = Vector2(x, z).distance_to(center)
			if abs(dist - pulse_r) < 1.0:
				var inten = 1.0 - abs(dist - pulse_r)
				_light_ceiling_at(x, z, lesson_colors[ArrayLesson.PULSE_CENTER] * inten)

func _lesson_wave_diagonal():
	_clear_all_lights()
	for x in range(grid_width_cells):
		for z in range(grid_depth_cells):
			var val = sin(disco_timer * 3.0 + (x + z) * 0.2)
			if val > 0.0:
				_light_ceiling_at(x, z, lesson_colors[ArrayLesson.WAVE_DIAGONAL] * val)

func _lesson_disco_celebration():
	var colors = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.MAGENTA, Color.CYAN]
	for x in range(grid_width_cells):
		for z in range(grid_depth_cells):
			var t = disco_timer + x * 0.1 + z * 0.1
			var col_idx = int(t) % colors.size()
			var pulse = sin(t * 5.0) * 0.5 + 0.5
			if pulse > 0.2:
				_light_ceiling_at(x, z, colors[col_idx] * pulse)

func _lesson_linear_scan():
	if step_timer >= animation_speed * 0.2: # Fast scan
		step_timer = 0.0
		_clear_all_lights()
		
		var total_cells = grid_width_cells * grid_depth_cells
		var current_idx = animation_step % total_cells
		
		# Simple row-major mapping (flat array simulation)
		var z = current_idx / grid_width_cells
		var x = current_idx % grid_width_cells
		
		# Highlight current index
		_light_ceiling_at(x, z, lesson_colors[ArrayLesson.INDEX_LINEAR_SCAN])
		
		# Show "past" indices fading out
		for i in range(1, 10):
			var past_idx = (current_idx - i + total_cells) % total_cells
			var pz = past_idx / grid_width_cells
			var px = past_idx % grid_width_cells
			_light_ceiling_at(px, pz, lesson_colors[ArrayLesson.INDEX_LINEAR_SCAN] * (1.0 - i/10.0))
			
		animation_step += 1

func _lesson_stride():
	if step_timer >= animation_speed * 5.0:
		step_timer = 0.0
		_clear_all_lights()
		
		var stride = 3
		var offset = animation_step % stride
		
		var total_cells = grid_width_cells * grid_depth_cells
		for i in range(total_cells):
			if (i % stride) == offset:
				var z = i / grid_width_cells
				var x = i % grid_width_cells
				_light_ceiling_at(x, z, lesson_colors[ArrayLesson.INDEX_STRIDE])
		
		animation_step += 1

func _lesson_subarray():
	if step_timer >= animation_speed * 10.0:
		step_timer = 0.0
		_clear_all_lights()
		
		# Simulate a sliding window or random region
		# 4x4 window moving across
		var window_size = 4
		var max_x = max(1, grid_width_cells - window_size)
		var max_z = max(1, grid_depth_cells - window_size)
		
		var total_windows = max_x * max_z
		var win_idx = animation_step % total_windows
		
		var start_z = win_idx / max_x
		var start_x = win_idx % max_x
		
		for x in range(start_x, min(start_x + window_size, grid_width_cells)):
			for z in range(start_z, min(start_z + window_size, grid_depth_cells)):
				_light_ceiling_at(x, z, lesson_colors[ArrayLesson.SUBARRAY_REGION])
				
		animation_step += 1

func _lesson_diagonal():
	if step_timer >= animation_speed:
		step_timer = 0.0
		_clear_all_lights()
		
		var size = min(grid_width_cells, grid_depth_cells)
		var idx = animation_step % (size * 2)
		
		# Main diagonal
		if idx < size:
			_light_ceiling_at(idx, idx, lesson_colors[ArrayLesson.DIAGONAL_ACCESS])
			# Anti-diagonal
			var anti_x = (grid_width_cells - 1) - idx
			if anti_x >= 0 and idx < grid_depth_cells:
				_light_ceiling_at(anti_x, idx, lesson_colors[ArrayLesson.DIAGONAL_ACCESS] * 0.5)
		else:
			# Sweep back? Or just clear.
			pass
			
		animation_step += 1

func _generate_spiral_pattern() -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	var top = 0
	var bottom = grid_depth_cells - 1
	var left = 0
	var right = grid_width_cells - 1
	
	while top <= bottom and left <= right:
		for x in range(left, right + 1): positions.append(Vector2i(x, top))
		top += 1
		for z in range(top, bottom + 1): positions.append(Vector2i(right, z))
		right -= 1
		if top <= bottom:
			for x in range(right, left - 1, -1): positions.append(Vector2i(x, bottom))
			bottom -= 1
		if left <= right:
			for z in range(bottom, top - 1, -1): positions.append(Vector2i(left, z))
			left += 1
	return positions

func _print_current_lesson():
	var lesson_name = ArrayLesson.keys()[current_lesson]
	print("GridCeiling: 🎓 LESSON %d: %s" % [current_lesson + 1, lesson_name])
