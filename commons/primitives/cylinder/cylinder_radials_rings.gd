# cylinder_radials_rings.gd - Configurable cylinder with radial segments and rings
# Usage: cylinder:90:1:#config:4:3 for 4 radial segments and 3 rings
extends Node3D

const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")

@export var base_color: Color = Color(0.8, 0.4, 0.9)  # Purple
@export var radial_segments: int = 8  # Number of segments around the circumference
@export var rings: int = 1  # Number of ring divisions along height
@export var height: float = 1.0
@export var radius: float = 0.5
@export var top_cap: bool = true
@export var bottom_cap: bool = true

var _mesh_instance: MeshInstance3D

func _ready():
	# Check for config metadata set by grid system
	if has_meta("config_config"):
		var config_str = str(get_meta("config_config"))
		_parse_config_string(config_str)

	_build_cylinder()

# Parse config string like "4:3" for radial:rings
func _parse_config_string(config_str: String) -> void:
	var parts = config_str.split(":")
	if parts.size() >= 1 and parts[0].is_valid_int():
		radial_segments = max(3, int(parts[0]))  # Minimum 3 for a valid polygon
	if parts.size() >= 2 and parts[1].is_valid_int():
		rings = max(1, int(parts[1]))  # Minimum 1 ring
	print("Cylinder configured: radial_segments=%d, rings=%d" % [radial_segments, rings])

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
		_build_cylinder()

func _build_cylinder() -> void:
	# Clean up existing mesh
	if _mesh_instance:
		if _mesh_instance.get_parent() == self:
			remove_child(_mesh_instance)
		_mesh_instance.queue_free()
		_mesh_instance = null

	var geometry := _cylinder_geometry()
	var material = GridMaterialFactory.make(base_color)

	_mesh_instance = _build_mesh_instance(geometry["vertices"], geometry["faces"], material)
	add_child(_mesh_instance)

	# Add collision
	_create_collision()

func _cylinder_geometry() -> Dictionary:
	var vertices: Array[Vector3] = []
	var faces: Array = []

	var half_height = height / 2.0

	# Generate vertices for each ring level
	# rings parameter controls how many horizontal divisions
	# We need rings + 1 levels of vertices (top and bottom plus intermediate)
	var num_levels = rings + 1

	for level in range(num_levels):
		var y = lerp(-half_height, half_height, float(level) / float(rings))

		for i in range(radial_segments):
			var angle = i * TAU / radial_segments
			var x = cos(angle) * radius
			var z = sin(angle) * radius
			vertices.append(Vector3(x, y, z))

	# Add center vertices for caps
	var bottom_center_idx = vertices.size()
	vertices.append(Vector3(0, -half_height, 0))  # Bottom center
	var top_center_idx = vertices.size()
	vertices.append(Vector3(0, half_height, 0))   # Top center

	# Generate side faces (quads split into triangles)
	for level in range(rings):
		var base_idx = level * radial_segments
		var next_base_idx = (level + 1) * radial_segments

		for i in range(radial_segments):
			var next_i = (i + 1) % radial_segments

			# Current level vertices
			var v0 = base_idx + i
			var v1 = base_idx + next_i
			# Next level vertices
			var v2 = next_base_idx + next_i
			var v3 = next_base_idx + i

			# Two triangles for quad (CCW winding for outward normals)
			faces.append([v0, v1, v2])
			faces.append([v0, v2, v3])

	# Bottom cap
	if bottom_cap:
		for i in range(radial_segments):
			var next_i = (i + 1) % radial_segments
			# CCW when viewed from below (normal pointing down)
			faces.append([bottom_center_idx, next_i, i])

	# Top cap
	if top_cap:
		var top_ring_base = rings * radial_segments
		for i in range(radial_segments):
			var next_i = (i + 1) % radial_segments
			# CCW when viewed from above (normal pointing up)
			faces.append([top_center_idx, top_ring_base + i, top_ring_base + next_i])

	return {
		"vertices": vertices,
		"faces": faces
	}

func _build_mesh_instance(vertices: Array[Vector3], faces: Array, material: Material) -> MeshInstance3D:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for face in faces:
		var v0 = vertices[face[0]]
		var v1 = vertices[face[1]]
		var v2 = vertices[face[2]]

		# Calculate normal
		var edge1 = v1 - v0
		var edge2 = v2 - v0
		var normal = edge1.cross(edge2).normalized()

		st.set_normal(normal)
		st.add_vertex(v0)
		st.set_normal(normal)
		st.add_vertex(v1)
		st.set_normal(normal)
		st.add_vertex(v2)

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "CylinderMesh"
	mesh_instance.material_override = material

	return mesh_instance

func _create_collision() -> void:
	# Remove existing collision
	var existing = get_node_or_null("CylinderCollision")
	if existing:
		existing.queue_free()

	var static_body = StaticBody3D.new()
	static_body.name = "CylinderCollision"
	add_child(static_body)

	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	collision.shape = shape
	static_body.add_child(collision)

func set_base_color(color: Color) -> void:
	base_color = color
	if _mesh_instance:
		_mesh_instance.material_override = GridMaterialFactory.make(base_color)

# Convenience method to update cylinder parameters
func set_cylinder_params(new_radial: int = -1, new_rings: int = -1, new_height: float = -1, new_radius: float = -1) -> void:
	if new_radial > 0:
		radial_segments = max(3, new_radial)
	if new_rings > 0:
		rings = max(1, new_rings)
	if new_height > 0:
		height = new_height
	if new_radius > 0:
		radius = new_radius

	_build_cylinder()
