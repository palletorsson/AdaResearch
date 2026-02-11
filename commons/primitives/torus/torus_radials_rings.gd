# torus_radials_rings.gd - Configurable torus with rings and ring segments
# Usage: torus_radials_rings:90:1:#config:16:8 for 16 rings and 8 ring_segments
# rings = divisions around the main circle (donut path)
# ring_segments = divisions around the tube cross-section
extends Node3D

const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")

@export var base_color: Color = Color(0.7, 0.3, 0.5)  # Dark magenta (not pure red)
@export var wireframe_color: Color = Color(1.0, 1.0, 1.0)  # White wireframe for contrast
@export var rings: int = 24  # Higher divisions for visible triangular structure
@export var ring_segments: int = 12  # More tube segments
@export var inner_radius: float = 0.3  # Radius of the hole (distance from center to tube center)
@export var outer_radius: float = 0.5  # Outer radius (inner_radius + tube_radius)

var _mesh_instance: MeshInstance3D

func _ready():
	# Check for config metadata set by grid system
	if has_meta("config_config"):
		var config_str = str(get_meta("config_config"))
		_parse_config_string(config_str)

	_build_torus()

# Parse config string like "16:8" for rings:ring_segments
func _parse_config_string(config_str: String) -> void:
	var parts = config_str.split(":")
	if parts.size() >= 1 and parts[0].is_valid_int():
		rings = max(3, int(parts[0]))  # Minimum 3 for a valid torus
	if parts.size() >= 2 and parts[1].is_valid_int():
		ring_segments = max(3, int(parts[1]))  # Minimum 3 for tube cross-section
	print("Torus configured: rings=%d, ring_segments=%d" % [rings, ring_segments])

# Called by grid system for #config syntax
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("config"):
		_parse_config_string(str(config_data.config))
	if config_data.has("rings"):
		rings = max(3, int(config_data.rings))
	if config_data.has("segments"):
		ring_segments = max(3, int(config_data.segments))
	if config_data.has("ring_segments"):
		ring_segments = max(3, int(config_data.ring_segments))
	if config_data.has("inner"):
		inner_radius = float(config_data.inner)
	if config_data.has("outer"):
		outer_radius = float(config_data.outer)

	# Rebuild if already built
	if _mesh_instance:
		_build_torus()

func _build_torus() -> void:
	# Clean up existing mesh
	if _mesh_instance:
		if _mesh_instance.get_parent() == self:
			remove_child(_mesh_instance)
		_mesh_instance.queue_free()
		_mesh_instance = null

	# Use Godot's TorusMesh with our parameters
	var torus_mesh = TorusMesh.new()
	torus_mesh.inner_radius = inner_radius
	torus_mesh.outer_radius = outer_radius
	torus_mesh.rings = rings
	torus_mesh.ring_segments = ring_segments

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = torus_mesh
	_mesh_instance.name = "TorusMesh"
	# Use distinct wireframe color for visible triangular structure
	_mesh_instance.material_override = GridMaterialFactory.make(base_color, {
		"wireframe_color": wireframe_color,
		"wireframe_width": 2.5,
		"wireframe_brightness": 3.0
	})
	add_child(_mesh_instance)

	# Add collision (approximate with multiple capsules or use convex)
	_create_collision()

func _create_collision() -> void:
	# Remove existing collision
	var existing = get_node_or_null("TorusCollision")
	if existing:
		existing.queue_free()

	var static_body = StaticBody3D.new()
	static_body.name = "TorusCollision"
	add_child(static_body)

	# Create convex collision from mesh
	if _mesh_instance and _mesh_instance.mesh:
		var collision = CollisionShape3D.new()
		# Use a simple approximation - a flattened cylinder covering the torus
		var shape = CylinderShape3D.new()
		shape.radius = outer_radius
		shape.height = (outer_radius - inner_radius)  # Tube diameter
		collision.shape = shape
		static_body.add_child(collision)

func set_base_color(color: Color) -> void:
	base_color = color
	if _mesh_instance:
		_mesh_instance.material_override = GridMaterialFactory.make(base_color)

# Convenience method to update torus parameters
func set_torus_params(new_rings: int = -1, new_ring_segments: int = -1, new_inner: float = -1, new_outer: float = -1) -> void:
	if new_rings > 0:
		rings = max(3, new_rings)
	if new_ring_segments > 0:
		ring_segments = max(3, new_ring_segments)
	if new_inner > 0:
		inner_radius = new_inner
	if new_outer > 0:
		outer_radius = new_outer

	_build_torus()
