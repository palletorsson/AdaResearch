# pulsar_glass_tubes.gd - 3D Glass Tube Visualization of Pulsar Radio Waves
# Arrays as height - each tube's height represents signal intensity
extends Node3D
class_name PulsarGlassTubes

@export var tube_spacing_x: float = 0.015  # Space between tubes in a row
@export var tube_spacing_z: float = 0.025  # Space between pulse rows
@export var max_height: float = 0.25  # Maximum tube height
@export var tube_radius: float = 0.004
@export var rows_to_show: int = 40  # How many pulse rows to visualize
@export var cols_per_row: int = 50
@export var min_intensity: float = 0.05  # Skip tubes below this

@export_group("Glass Material")
@export var glass_color: Color = Color(0.85, 0.92, 1.0, 0.25)
@export var glow_color: Color = Color(1.0, 1.0, 1.0, 0.8)
@export var use_emission: bool = true

@export_group("Visualization Mode")
@export var visualization_mode: int = 0  # 0=tubes, 1=lines, 2=points

# Materials
var glass_material: StandardMaterial3D
var glow_material: StandardMaterial3D

# Data
var pulsar_data: Array = []

func _ready() -> void:
	_setup_materials()
	_load_data()
	build_visualization()

func _setup_materials() -> void:
	# Glass tube material (outer)
	glass_material = StandardMaterial3D.new()
	glass_material.albedo_color = glass_color
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.roughness = 0.0
	glass_material.metallic = 0.1
	glass_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX

	# Inner glow material
	glow_material = StandardMaterial3D.new()
	glow_material.albedo_color = glow_color
	glow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if use_emission:
		glow_material.emission_enabled = true
		glow_material.emission = Color(1.0, 1.0, 1.0)
		glow_material.emission_energy_multiplier = 0.4

func _load_data() -> void:
	pulsar_data = PulsarData.get_pulsar_data(80, 50)

func build_visualization() -> void:
	# Clear existing children (except non-tube nodes)
	for child in get_children():
		if child.name.begins_with("Tube") or child.name.begins_with("Row"):
			child.queue_free()

	if pulsar_data.is_empty():
		_load_data()

	# Calculate row step to show requested number of rows
	var total_rows = pulsar_data.size()
	var row_step = max(1, total_rows / rows_to_show)

	# Center the visualization
	var total_width = cols_per_row * tube_spacing_x
	var total_depth = rows_to_show * tube_spacing_z
	var offset = Vector3(-total_width / 2.0, 0, -total_depth / 2.0)

	var tube_count = 0
	for row_idx in range(0, mini(total_rows, rows_to_show * row_step), row_step):
		var row_data = pulsar_data[row_idx]
		var display_row = row_idx / row_step

		# Create a parent node for this row (for organization)
		var row_node = Node3D.new()
		row_node.name = "Row_%d" % display_row
		add_child(row_node)

		for col in range(mini(row_data.size(), cols_per_row)):
			var intensity = row_data[col]

			if intensity < min_intensity:
				continue  # Skip very small tubes

			var height = intensity * max_height
			var tube = _create_tube(height, intensity)
			tube.name = "Tube_%d_%d" % [display_row, col]
			tube.position = Vector3(
				col * tube_spacing_x,
				height / 2.0,
				display_row * tube_spacing_z
			) + offset
			row_node.add_child(tube)
			tube_count += 1

	print("PulsarGlassTubes: Created %d tubes" % tube_count)

func _create_tube(height: float, intensity: float) -> Node3D:
	var group = Node3D.new()

	match visualization_mode:
		0:  # Tubes
			_add_cylinder_tube(group, height, intensity)
		1:  # Lines (simpler, better performance)
			_add_line_tube(group, height, intensity)
		2:  # Points
			_add_point_tube(group, height, intensity)

	return group

func _add_cylinder_tube(group: Node3D, height: float, intensity: float) -> void:
	# Glass tube (outer)
	var glass = MeshInstance3D.new()
	glass.name = "Glass"
	var cyl = CylinderMesh.new()
	cyl.top_radius = tube_radius
	cyl.bottom_radius = tube_radius
	cyl.height = height
	cyl.radial_segments = 6  # Hexagonal for performance
	cyl.rings = 1
	glass.mesh = cyl
	glass.material_override = glass_material
	group.add_child(glass)

	# Inner glow (intensity-based)
	if intensity > 0.2:
		var inner = MeshInstance3D.new()
		inner.name = "Glow"
		var inner_cyl = CylinderMesh.new()
		inner_cyl.top_radius = tube_radius * 0.6
		inner_cyl.bottom_radius = tube_radius * 0.6
		inner_cyl.height = height
		inner_cyl.radial_segments = 4
		inner_cyl.rings = 1
		inner.mesh = inner_cyl

		# Brighter glow for stronger signals
		var glow_mat = glow_material.duplicate()
		glow_mat.emission_energy_multiplier = intensity * 0.8
		inner.material_override = glow_mat
		group.add_child(inner)

func _add_line_tube(group: Node3D, height: float, intensity: float) -> void:
	# Simple line visualization (much faster for large datasets)
	var line = MeshInstance3D.new()
	line.name = "Line"

	var immediate_mesh = ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate_mesh.surface_add_vertex(Vector3(0, -height / 2.0, 0))
	immediate_mesh.surface_add_vertex(Vector3(0, height / 2.0, 0))
	immediate_mesh.surface_end()

	line.mesh = immediate_mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 1.0, intensity)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if use_emission:
		mat.emission_enabled = true
		mat.emission = Color(1.0, 1.0, 1.0)
		mat.emission_energy_multiplier = intensity * 0.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line.material_override = mat

	group.add_child(line)

func _add_point_tube(group: Node3D, height: float, intensity: float) -> void:
	# Point at the top of where tube would be
	var point = MeshInstance3D.new()
	point.name = "Point"

	var sphere = SphereMesh.new()
	sphere.radius = tube_radius * (1.0 + intensity)
	sphere.height = sphere.radius * 2
	sphere.radial_segments = 4
	sphere.rings = 2
	point.mesh = sphere

	var mat = glow_material.duplicate()
	mat.emission_energy_multiplier = intensity * 1.0
	point.material_override = mat
	point.position.y = height / 2.0

	group.add_child(point)

# =============================================================================
# GRID SYSTEM INTEGRATION
# =============================================================================

func apply_grid_config(config: Dictionary) -> void:
	if config.has("rows"):
		rows_to_show = config["rows"]
	if config.has("cols"):
		cols_per_row = config["cols"]
	if config.has("max_height"):
		max_height = config["max_height"]
	if config.has("tube_spacing"):
		tube_spacing_x = config["tube_spacing"]
		tube_spacing_z = config["tube_spacing"] * 1.5
	if config.has("visualization_mode"):
		visualization_mode = config["visualization_mode"]
	if config.has("glow_color") and config["glow_color"] is Array:
		var c = config["glow_color"]
		glow_color = Color(c[0], c[1], c[2], c[3] if c.size() > 3 else 0.8)
		_setup_materials()

	build_visualization()

# =============================================================================
# ANIMATION
# =============================================================================

var _time: float = 0.0
@export var animate: bool = false
@export var animation_speed: float = 1.0

func _process(delta: float) -> void:
	if not animate:
		return

	_time += delta * animation_speed

	# Subtle wave animation - tubes gently pulse
	for row_node in get_children():
		if not row_node.name.begins_with("Row"):
			continue
		for tube in row_node.get_children():
			var glow = tube.get_node_or_null("Glow")
			if glow and glow.material_override:
				var base_energy = 0.4
				var wave = sin(_time * 2.0 + tube.position.x * 10.0) * 0.2
				glow.material_override.emission_energy_multiplier = base_energy + wave

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

