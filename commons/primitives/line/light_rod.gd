# @identity
# essence: a row of glowing vertical rods placed by a single config string — the cheapest light-as-line primitive
# desire: get a measured rhythm of light from a single token (lightrod#config:N:spacing) without touching scene tree
# critical_parameter: count and spacing — they define a discrete rhythm of vertical lines in the map
# triggers: _ready() reads config meta; _build_rods() spawns count copies at spacing intervals
# emerges: a colonnade of cyan glow strokes that read as both structure and decoration
# needs: rod color export [present]; emission strength export [present]; height export [present]
# relationships: line-primitive sibling of vectorline (single line) and laser_measure (single beam); used in map-editor lighting passes for theatrical mood
# truth: A row of light rods is a punctuation mark for space — they don't illuminate the room, they tell you how to read it.

extends Node3D

const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")

# Configuration
@export var count: int = 1  # Number of rods
@export var spacing: float = 1.0  # Distance between rods
@export var rod_height: float = 2.0  # Height of each rod
@export var rod_radius: float = 0.02  # Thickness of rods

# Visual settings
@export var rod_color: Color = Color(0.3, 0.5, 1.0)  # Blue
@export var emission_strength: float = 2.0  # Glow intensity

# Internal
var _rod_instances: Array[MeshInstance3D] = []

func _ready():
	# Check for config metadata set by grid system
	if has_meta("config_config"):
		var config_str = str(get_meta("config_config"))
		_parse_config_string(config_str)

	_build_rods()

# Parse config string like "4:1" for count:spacing
func _parse_config_string(config_str: String) -> void:
	var parts = config_str.split(":")
	if parts.size() >= 1 and parts[0].is_valid_int():
		count = max(1, int(parts[0]))
	if parts.size() >= 2 and parts[1].is_valid_float():
		spacing = float(parts[1])
	print("LightRod configured: count=%d, spacing=%.2f" % [count, spacing])

# Called by grid system for #config syntax
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("config"):
		_parse_config_string(str(config_data.config))
	if config_data.has("count"):
		count = max(1, int(config_data.count))
	if config_data.has("spacing"):
		spacing = float(config_data.spacing)
	if config_data.has("height"):
		rod_height = float(config_data.height)
	if config_data.has("radius"):
		rod_radius = float(config_data.radius)
	if config_data.has("color"):
		# Parse color string if provided
		var color_str = str(config_data.color)
		if color_str.begins_with("#"):
			rod_color = Color.html(color_str)

	# Rebuild if already built
	if _rod_instances.size() > 0:
		_build_rods()

func _build_rods() -> void:
	# Clean up existing
	for rod in _rod_instances:
		if is_instance_valid(rod):
			rod.queue_free()
	_rod_instances.clear()

	# Create emissive material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = rod_color
	mat.emission_enabled = true
	mat.emission = rod_color
	mat.emission_energy_multiplier = emission_strength
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Calculate total width and starting offset
	var total_width = (count - 1) * spacing
	var start_x = -total_width / 2.0

	# Create each rod
	for i in range(count):
		var x_pos = start_x + i * spacing
		_create_rod(Vector3(x_pos, rod_height / 2.0, 0), mat)

func _create_rod(pos: Vector3, material: Material) -> void:
	var cylinder = CylinderMesh.new()
	cylinder.height = rod_height
	cylinder.top_radius = rod_radius
	cylinder.bottom_radius = rod_radius
	cylinder.radial_segments = 8

	var instance = MeshInstance3D.new()
	instance.mesh = cylinder
	instance.material_override = material
	instance.position = pos
	instance.name = "LightRod"

	add_child(instance)
	_rod_instances.append(instance)

# Public API
func set_count(new_count: int) -> void:
	count = max(1, new_count)
	_build_rods()

func set_spacing(new_spacing: float) -> void:
	spacing = new_spacing
	_build_rods()

func set_color(color: Color) -> void:
	rod_color = color
	_build_rods()

func set_height(height: float) -> void:
	rod_height = height
	_build_rods()
