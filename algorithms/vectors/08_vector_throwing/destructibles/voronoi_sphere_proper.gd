# voronoi_sphere_proper.gd
# Sphere that cracks using proper Voronoi cell generation
extends RigidBody3D

signal sphere_cracked(sphere: Node3D, impact_point: Vector3, impact_velocity: Vector3)

@export_group("Sphere Properties")
@export var sphere_radius: float = 0.3
@export var sphere_color: Color = Color(0.8, 0.3, 1.0, 1.0)
@export var voronoi_cell_count: int = 12
@export var crack_impulse_strength: float = 3.0
@export var sphere_subdivisions: int = 3  # Higher = smoother fragments

@export_group("Behavior")
@export var start_frozen: bool = true

# State
var has_cracked: bool = false
var original_sphere_mesh: ArrayMesh = null

# References
var mesh_instance: MeshInstance3D = null
var collision_shape: CollisionShape3D = null
var area: Area3D = null

func _ready() -> void:
	_setup_visual()
	_setup_collision()
	_setup_physics()
	_setup_hit_detection()

func _setup_visual() -> void:
	"""Create the sphere mesh"""
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	add_child(mesh_instance)

	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = sphere_radius
	sphere_mesh.height = sphere_radius * 2.0
	sphere_mesh.radial_segments = 16
	sphere_mesh.rings = 8
	mesh_instance.mesh = sphere_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = sphere_color
	material.emission_enabled = true
	material.emission = sphere_color
	material.emission_energy = 0.2
	material.metallic = 0.0
	material.roughness = 1.0

	mesh_instance.material_override = material

func _setup_collision() -> void:
	"""Create collision shape"""
	collision_shape = CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = sphere_radius
	collision_shape.shape = sphere_shape
	add_child(collision_shape)

func _setup_physics() -> void:
	"""Configure physics properties"""
	mass = 1.0
	contact_monitor = true
	max_contacts_reported = 4

	if start_frozen:
		freeze = true
		gravity_scale = 0.0
	else:
		freeze = false
		gravity_scale = 1.0

func _setup_hit_detection() -> void:
	"""Create Area3D for detecting ball impacts"""
	area = Area3D.new()
	area.name = "HitDetectionArea"
	area.monitoring = true
	area.monitorable = true
	area.collision_layer = 0
	area.collision_mask = 2  # Detect throwable balls

	add_child(area)

	var area_collision = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = sphere_radius * 1.1
	area_collision.shape = sphere_shape
	area.add_child(area_collision)

	area.body_entered.connect(_on_ball_hit)

func _on_ball_hit(body: Node) -> void:
	"""Handle ball impact - crack the sphere"""
	if has_cracked:
		return

	if not body.is_in_group("throwable"):
		return

	# Get impact velocity and position
	var impact_velocity = Vector3.ZERO
	if body is RigidBody3D:
		impact_velocity = body.linear_velocity

	# Calculate impact point (approximate)
	var impact_point = body.global_position - global_position
	impact_point = impact_point.normalized() * sphere_radius

	_crack_sphere_voronoi(impact_point, impact_velocity)

func _crack_sphere_voronoi(impact_point_local: Vector3, impact_velocity: Vector3) -> void:
	"""Create proper Voronoi-based fragments"""
	if has_cracked:
		return

	has_cracked = true

	# Emit signal
	sphere_cracked.emit(self, impact_point_local, impact_velocity)

	# Generate Voronoi seed points
	var voronoi_seeds: Array[Vector3] = _generate_voronoi_seeds(impact_point_local)

	# Create sphere mesh data
	var sphere_vertices: PackedVector3Array = _generate_sphere_vertices()

	# Assign each vertex to nearest Voronoi cell
	var vertex_assignments: Array[int] = _assign_vertices_to_cells(sphere_vertices, voronoi_seeds)

	# Create fragments from assigned vertices
	_create_voronoi_fragments(sphere_vertices, vertex_assignments, voronoi_seeds, impact_velocity)

	# Remove original sphere
	_fade_out_and_remove()

func _generate_voronoi_seeds(impact_point: Vector3) -> Array[Vector3]:
	"""Generate seed points for Voronoi cells"""
	var seeds: Array[Vector3] = []

	# Place seed at impact point
	seeds.append(impact_point.normalized() * sphere_radius * 0.7)

	# Generate random seeds distributed on sphere surface
	for i in range(voronoi_cell_count - 1):
		var seed = _random_point_on_sphere(sphere_radius * 0.6)
		seeds.append(seed)

	return seeds

func _generate_sphere_vertices() -> PackedVector3Array:
	"""Generate vertices for an icosphere"""
	var vertices = PackedVector3Array()

	# Create icosahedron base
	var t = (1.0 + sqrt(5.0)) / 2.0
	var base_vertices = [
		Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)
	]

	# Normalize to sphere radius
	for v in base_vertices:
		vertices.append(v.normalized() * sphere_radius)

	return vertices

func _assign_vertices_to_cells(vertices: PackedVector3Array, seeds: Array[Vector3]) -> Array[int]:
	"""Assign each vertex to its nearest Voronoi cell"""
	var assignments: Array[int] = []

	for vertex in vertices:
		var nearest_cell = 0
		var min_distance = vertex.distance_to(seeds[0])

		for i in range(1, seeds.size()):
			var distance = vertex.distance_to(seeds[i])
			if distance < min_distance:
				min_distance = distance
				nearest_cell = i

		assignments.append(nearest_cell)

	return assignments

func _create_voronoi_fragments(vertices: PackedVector3Array, assignments: Array[int], seeds: Array[Vector3], impact_velocity: Vector3) -> void:
	"""Create mesh fragments for each Voronoi cell"""

	# Group vertices by cell
	var cells: Dictionary = {}
	for i in range(assignments.size()):
		var cell_id = assignments[i]
		if not cells.has(cell_id):
			cells[cell_id] = []
		cells[cell_id].append(vertices[i])

	# Create fragment for each cell
	for cell_id in cells.keys():
		var cell_vertices: Array = cells[cell_id]
		if cell_vertices.size() < 3:
			continue  # Need at least 3 vertices for a mesh

		_create_fragment_from_vertices(cell_vertices, seeds[cell_id], impact_velocity, cell_id)

func _create_fragment_from_vertices(cell_vertices: Array, seed_pos: Vector3, impact_velocity: Vector3, index: int) -> RigidBody3D:
	"""Create a mesh fragment from vertices"""
	var fragment = RigidBody3D.new()
	fragment.name = "VoronoiFragment_%d" % index
	fragment.global_position = global_position + seed_pos

	# Create convex hull mesh from vertices
	var mesh = _create_convex_hull(cell_vertices, seed_pos)

	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = mesh

	# Vary color slightly
	var frag_color = sphere_color
	frag_color.h = fmod(sphere_color.h + randf_range(-0.1, 0.1), 1.0)
	frag_color.v = sphere_color.v * randf_range(0.8, 1.2)

	var material = StandardMaterial3D.new()
	material.albedo_color = frag_color
	material.emission_enabled = true
	material.emission = frag_color
	material.emission_energy = 0.2

	mesh_inst.material_override = material
	fragment.add_child(mesh_inst)

	# Add collision using convex hull
	var collision = CollisionShape3D.new()
	var convex_shape = ConvexPolygonShape3D.new()
	convex_shape.points = _get_local_vertices(cell_vertices, seed_pos)
	collision.shape = convex_shape
	fragment.add_child(collision)

	# Physics
	fragment.mass = 0.1
	fragment.gravity_scale = 1.0

	# Apply impulse
	var explosion_direction = seed_pos.normalized()
	if explosion_direction.length() < 0.1:
		explosion_direction = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()

	var explosion_force = explosion_direction * crack_impulse_strength
	var inherited_velocity = impact_velocity * 0.2

	fragment.linear_velocity = explosion_force + inherited_velocity
	fragment.angular_velocity = Vector3(randf_range(-5, 5), randf_range(-5, 5), randf_range(-5, 5))

	get_parent().add_child(fragment)

	# Fade out fragments
	_schedule_fragment_removal(fragment, mesh_inst)

	return fragment

func _create_convex_hull(vertices: Array, center: Vector3) -> ArrayMesh:
	"""Create a simple convex hull mesh"""
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Center the vertices around the fragment position
	var local_verts = _get_local_vertices(vertices, center)

	# Create a simple triangulated mesh
	# For simplicity, we'll create triangles from center to each edge
	var center_local = Vector3.ZERO

	for i in range(local_verts.size()):
		var next_i = (i + 1) % local_verts.size()

		var v0 = center_local
		var v1 = local_verts[i]
		var v2 = local_verts[next_i]

		var normal = (v1 - v0).cross(v2 - v0).normalized()

		st.set_normal(normal)
		st.add_vertex(v0)
		st.set_normal(normal)
		st.add_vertex(v1)
		st.set_normal(normal)
		st.add_vertex(v2)

	return st.commit()

func _get_local_vertices(vertices: Array, center: Vector3) -> PackedVector3Array:
	"""Convert global vertices to local space relative to fragment center"""
	var local_verts = PackedVector3Array()
	for v in vertices:
		local_verts.append(v - center)
	return local_verts

func _random_point_on_sphere(radius: float) -> Vector3:
	"""Generate random point on sphere surface"""
	var theta = randf() * TAU
	var phi = acos(2.0 * randf() - 1.0)

	return Vector3(
		radius * sin(phi) * cos(theta),
		radius * sin(phi) * sin(theta),
		radius * cos(phi)
	)

func _schedule_fragment_removal(fragment: RigidBody3D, mesh_inst: MeshInstance3D) -> void:
	"""Fade out and remove fragment after delay"""
	await get_tree().create_timer(3.0).timeout

	var tween = create_tween()
	tween.set_parallel(true)

	if mesh_inst.material_override:
		var material = mesh_inst.material_override
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tween.tween_property(material, "albedo_color:a", 0.0, 1.0)

	tween.tween_property(mesh_inst, "scale", Vector3.ZERO, 1.0)
	tween.tween_callback(fragment.queue_free).set_delay(1.0)

func _fade_out_and_remove() -> void:
	"""Remove the original sphere"""
	collision_layer = 0
	collision_mask = 0

	var tween = create_tween()
	tween.set_parallel(true)

	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tween.tween_property(material, "albedo_color:a", 0.0, 0.3)

	tween.tween_property(mesh_instance, "scale", Vector3.ZERO, 0.3)
	tween.tween_callback(queue_free).set_delay(0.3)
