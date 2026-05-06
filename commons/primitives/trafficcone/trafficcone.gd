# trafficcone.gd - Traffic cone with orange/white stripes
# Classic construction site safety cone
extends Node3D

const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")

@export var orange_color: Color = Color(1.0, 0.4, 0.0)  # Traffic cone orange
@export var white_color: Color = Color(1.0, 1.0, 1.0)   # White stripe
@export var height: float = 0.7  # ~70cm tall
@export var base_radius: float = 0.15  # Base radius
@export var top_radius: float = 0.02  # Tiny top
@export var radial_segments: int = 12
@export var stripe_count: int = 2  # Number of white stripes

var _cone_mesh: MeshInstance3D
var _base_mesh: MeshInstance3D

func _ready():
	_build_traffic_cone()

func _build_traffic_cone():
	# Clean up existing
	for child in get_children():
		child.queue_free()

	# Build the cone body with stripes
	_build_cone_with_stripes()

	# Build the square base
	_build_base()

	# Add collision
	_create_collision()

func _build_cone_with_stripes():
	# We'll create multiple ring sections with alternating colors
	# Stripes are at roughly 1/3 and 2/3 height
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Define stripe positions (normalized 0-1 along height)
	var sections = []
	# Orange bottom, white stripe, orange middle, white stripe, orange top
	var stripe_height = 0.12  # Each stripe is 12% of height
	var stripe_positions = [0.30, 0.55]  # Where stripes start

	var current_pos = 0.0
	var is_orange = true

	for stripe_start in stripe_positions:
		# Orange section before stripe
		sections.append({"start": current_pos, "end": stripe_start, "color": orange_color})
		current_pos = stripe_start
		# White stripe
		sections.append({"start": current_pos, "end": current_pos + stripe_height, "color": white_color})
		current_pos = current_pos + stripe_height

	# Final orange section to top
	sections.append({"start": current_pos, "end": 1.0, "color": orange_color})

	# Build geometry for each section
	for section in sections:
		_add_cone_section(st, section.start, section.end, section.color)

	_cone_mesh = MeshInstance3D.new()
	_cone_mesh.mesh = st.commit()
	_cone_mesh.name = "ConeMesh"
	add_child(_cone_mesh)

func _add_cone_section(st: SurfaceTool, start_t: float, end_t: float, color: Color):
	# Calculate radii at start and end of section
	var r_start = lerp(base_radius, top_radius, start_t)
	var r_end = lerp(base_radius, top_radius, end_t)
	var y_start = start_t * height
	var y_end = end_t * height

	# Generate ring of vertices at start and end
	for i in range(radial_segments):
		var angle = i * TAU / radial_segments
		var next_angle = ((i + 1) % radial_segments) * TAU / radial_segments

		# Current segment vertices
		var v0 = Vector3(cos(angle) * r_start, y_start, sin(angle) * r_start)
		var v1 = Vector3(cos(next_angle) * r_start, y_start, sin(next_angle) * r_start)
		var v2 = Vector3(cos(next_angle) * r_end, y_end, sin(next_angle) * r_end)
		var v3 = Vector3(cos(angle) * r_end, y_end, sin(angle) * r_end)

		# Calculate normals (pointing outward)
		var edge1 = v1 - v0
		var edge2 = v3 - v0
		var normal = edge1.cross(edge2).normalized()

		# Set color via UV or we'll apply material later
		# For now, we'll create separate meshes or use vertex colors
		st.set_color(color)

		# Triangle 1
		st.set_normal(normal)
		st.add_vertex(v0)
		st.set_normal(normal)
		st.add_vertex(v1)
		st.set_normal(normal)
		st.add_vertex(v2)

		# Triangle 2
		st.set_normal(normal)
		st.add_vertex(v0)
		st.set_normal(normal)
		st.add_vertex(v2)
		st.set_normal(normal)
		st.add_vertex(v3)

func _build_base():
	# Square base plate
	var base_size = base_radius * 2.5  # Wider than cone
	var base_height = 0.03  # Thin plate

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half = base_size / 2.0

	# Top face
	var v0 = Vector3(-half, base_height, -half)
	var v1 = Vector3(half, base_height, -half)
	var v2 = Vector3(half, base_height, half)
	var v3 = Vector3(-half, base_height, half)

	st.set_color(orange_color)
	st.set_normal(Vector3.UP)
	st.add_vertex(v0)
	st.add_vertex(v1)
	st.add_vertex(v2)
	st.set_normal(Vector3.UP)
	st.add_vertex(v0)
	st.add_vertex(v2)
	st.add_vertex(v3)

	# Bottom face
	var b0 = Vector3(-half, 0, -half)
	var b1 = Vector3(half, 0, -half)
	var b2 = Vector3(half, 0, half)
	var b3 = Vector3(-half, 0, half)

	st.set_normal(Vector3.DOWN)
	st.add_vertex(b2)
	st.add_vertex(b1)
	st.add_vertex(b0)
	st.set_normal(Vector3.DOWN)
	st.add_vertex(b3)
	st.add_vertex(b2)
	st.add_vertex(b0)

	# Side faces
	# Front
	st.set_normal(Vector3.FORWARD)
	st.add_vertex(v2)
	st.add_vertex(v3)
	st.add_vertex(b3)
	st.add_vertex(v2)
	st.add_vertex(b3)
	st.add_vertex(b2)

	# Back
	st.set_normal(Vector3.BACK)
	st.add_vertex(v0)
	st.add_vertex(v1)
	st.add_vertex(b1)
	st.add_vertex(v0)
	st.add_vertex(b1)
	st.add_vertex(b0)

	# Left
	st.set_normal(Vector3.LEFT)
	st.add_vertex(v3)
	st.add_vertex(v0)
	st.add_vertex(b0)
	st.add_vertex(v3)
	st.add_vertex(b0)
	st.add_vertex(b3)

	# Right
	st.set_normal(Vector3.RIGHT)
	st.add_vertex(v1)
	st.add_vertex(v2)
	st.add_vertex(b2)
	st.add_vertex(v1)
	st.add_vertex(b2)
	st.add_vertex(b1)

	_base_mesh = MeshInstance3D.new()
	_base_mesh.mesh = st.commit()
	_base_mesh.name = "BaseMesh"

	# Apply vertex color material
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.albedo_color = orange_color
	_base_mesh.material_override = material

	add_child(_base_mesh)

func _create_collision():
	var static_body = StaticBody3D.new()
	static_body.name = "ConeCollision"
	add_child(static_body)

	# Cone collision (approximated with cylinder)
	var cone_collision = CollisionShape3D.new()
	var cone_shape = CylinderShape3D.new()
	cone_shape.radius = base_radius * 0.7  # Average radius
	cone_shape.height = height
	cone_collision.shape = cone_shape
	cone_collision.position = Vector3(0, height / 2.0, 0)
	static_body.add_child(cone_collision)

	# Base collision
	var base_collision = CollisionShape3D.new()
	var base_shape = BoxShape3D.new()
	var base_size = base_radius * 2.5
	base_shape.size = Vector3(base_size, 0.03, base_size)
	base_collision.shape = base_shape
	base_collision.position = Vector3(0, 0.015, 0)
	static_body.add_child(base_collision)

func set_orange_color(color: Color):
	orange_color = color
	_build_traffic_cone()

func _init():
	# Apply vertex color material to cone when ready
	pass

func _enter_tree():
	# Apply proper material after build
	call_deferred("_apply_materials")

func _apply_materials():
	if _cone_mesh:
		var material = StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		_cone_mesh.material_override = material
