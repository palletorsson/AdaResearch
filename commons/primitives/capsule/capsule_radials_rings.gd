# capsule_radials_rings.gd - Configurable capsule with radial segments and rings
# Usage: capsule_radials_rings:90:1:#config:8:4 for 8 radial segments and 4 rings
extends Node3D

const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")

@export var base_color: Color = Color(0.4, 0.8, 0.6)  # Teal
@export var radial_segments: int = 8  # Number of segments around the circumference
@export var rings: int = 4  # Number of ring divisions along the capsule
@export var height: float = 1.0  # Total height including caps
@export var radius: float = 0.25  # Radius of the capsule

var _mesh_instance: MeshInstance3D

func _ready():
	# Check for config metadata set by grid system
	if has_meta("config_config"):
		var config_str = str(get_meta("config_config"))
		_parse_config_string(config_str)

	_build_capsule()

# Parse config string like "8:4" for radial:rings
func _parse_config_string(config_str: String) -> void:
	var parts = config_str.split(":")
	if parts.size() >= 1 and parts[0].is_valid_int():
		radial_segments = max(3, int(parts[0]))  # Minimum 3 for a valid shape
	if parts.size() >= 2 and parts[1].is_valid_int():
		rings = max(1, int(parts[1]))  # Minimum 1 ring
	print("Capsule configured: radial_segments=%d, rings=%d" % [radial_segments, rings])

# Called by grid system for #config syntax
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("config"):
		_parse_config_string(str(config_data.config))
	if config_data.has("radial"):
		radial_segments = max(3, int(config_data.radial))
	if config_data.has("rings"):
		rings = max(1, int(config_data.rings))
	if config_data.has("height"):
		height = float(config_data.height)
	if config_data.has("radius"):
		radius = float(config_data.radius)

	# Rebuild if already built
	if _mesh_instance:
		_build_capsule()

func _build_capsule() -> void:
	# Clean up existing mesh
	if _mesh_instance:
		if _mesh_instance.get_parent() == self:
			remove_child(_mesh_instance)
		_mesh_instance.queue_free()
		_mesh_instance = null

	# Use Godot's CapsuleMesh with our parameters
	var capsule_mesh = CapsuleMesh.new()
	capsule_mesh.radius = radius
	capsule_mesh.height = height
	capsule_mesh.radial_segments = radial_segments
	capsule_mesh.rings = rings

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = capsule_mesh
	_mesh_instance.name = "CapsuleMesh"
	_mesh_instance.material_override = GridMaterialFactory.make(base_color)
	add_child(_mesh_instance)

	# Add collision
	_create_collision()

func _create_collision() -> void:
	# Remove existing collision
	var existing = get_node_or_null("CapsuleCollision")
	if existing:
		existing.queue_free()

	var static_body = StaticBody3D.new()
	static_body.name = "CapsuleCollision"
	add_child(static_body)

	var collision = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = radius
	shape.height = height
	collision.shape = shape
	static_body.add_child(collision)

func set_base_color(color: Color) -> void:
	base_color = color
	if _mesh_instance:
		_mesh_instance.material_override = GridMaterialFactory.make(base_color)

# Convenience method to update capsule parameters
func set_capsule_params(new_radial: int = -1, new_rings: int = -1, new_height: float = -1, new_radius: float = -1) -> void:
	if new_radial > 0:
		radial_segments = max(3, new_radial)
	if new_rings > 0:
		rings = max(1, new_rings)
	if new_height > 0:
		height = new_height
	if new_radius > 0:
		radius = new_radius

	_build_capsule()
