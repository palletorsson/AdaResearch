# sectored_sphere.gd
# Sphere divided into wedge sectors (like an orange), each sector can split further
extends Node3D

signal sector_destroyed(sector: Node3D, impact_velocity: Vector3)
signal sphere_fully_destroyed(sphere: Node3D)

@export_group("Sphere Properties")
@export var sphere_radius: float = 0.3
@export var sphere_color: Color = Color(1.0, 0.6, 0.2, 1.0)  # Orange
@export var initial_sectors: int = 8  # How many wedges initially
@export var can_subdivide: bool = false  # Can sectors split into smaller sectors
@export var shatter_all_on_hit: bool = true  # Shatter all sectors on any hit
@export var explosion_strength: float = 2.5

var sectors: Array[Node3D] = []
var sector_data: Dictionary = {}

class SectorData:
	var mesh_instance: MeshInstance3D
	var rigid_body: RigidBody3D
	var area: Area3D
	var start_angle: float
	var end_angle: float
	var subdivision_level: int

	func _init(mesh: MeshInstance3D, rb: RigidBody3D, area_node: Area3D, start: float, end: float, level: int) -> void:
		mesh_instance = mesh
		rigid_body = rb
		area = area_node
		start_angle = start
		end_angle = end
		subdivision_level = level

func _ready() -> void:
	_create_sectors()

func _create_sectors() -> void:
	"""Create initial wedge sectors"""
	var angle_step = TAU / initial_sectors

	for i in range(initial_sectors):
		var start_angle = i * angle_step
		var end_angle = (i + 1) * angle_step

		var sector = _create_sector(start_angle, end_angle, 0)
		add_child(sector)
		sectors.append(sector)

func _create_sector(start_angle: float, end_angle: float, level: int) -> RigidBody3D:
	"""Create a wedge sector of the sphere"""
	var rigid_body = RigidBody3D.new()
	rigid_body.name = "Sector_%.2f_%.2f_L%d" % [rad_to_deg(start_angle), rad_to_deg(end_angle), level]

	# Create sector mesh
	var mesh_instance = MeshInstance3D.new()
	var mesh = _create_sector_mesh(start_angle, end_angle)
	mesh_instance.mesh = mesh

	# Color varies by angle
	var color = sphere_color
	var angle_mid = (start_angle + end_angle) / 2.0
	color.h = fmod(sphere_color.h + (angle_mid / TAU), 1.0)

	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.2
	material.metallic = 0.0
	material.roughness = 1.0

	mesh_instance.material_override = material
	rigid_body.add_child(mesh_instance)

	# Collision - use convex shape
	var vertices = _generate_sector_vertices(start_angle, end_angle)
	var collision = CollisionShape3D.new()
	var convex_shape = ConvexPolygonShape3D.new()
	convex_shape.points = vertices
	collision.shape = convex_shape
	rigid_body.add_child(collision)

	# Hit detection
	var area = Area3D.new()
	area.monitoring = true
	area.collision_layer = 0
	area.collision_mask = 2

	var area_collision = CollisionShape3D.new()
	var area_shape = ConvexPolygonShape3D.new()
	area_shape.points = vertices
	area_collision.shape = area_shape
	area.add_child(area_collision)
	rigid_body.add_child(area)

	# Physics
	if level == 0:
		rigid_body.freeze = true
		rigid_body.gravity_scale = 0.0
	else:
		rigid_body.freeze = false
		rigid_body.gravity_scale = 1.0

	rigid_body.mass = 0.3 / pow(2, level)

	# Store data
	var data = SectorData.new(mesh_instance, rigid_body, area, start_angle, end_angle, level)
	sector_data[rigid_body] = data

	area.body_entered.connect(_on_sector_hit.bind(rigid_body))

	return rigid_body

func _generate_sector_vertices(start_angle: float, end_angle: float) -> PackedVector3Array:
	"""Generate vertices for a wedge sector"""
	var vertices = PackedVector3Array()

	# Center point
	vertices.append(Vector3.ZERO)

	# Generate vertices along the sector arc
	var segments = 8
	var rings = 4

	for ring in range(rings + 1):
		var phi = PI * float(ring) / float(rings)
		var sin_phi = sin(phi)
		var cos_phi = cos(phi)

		for segment in range(segments + 1):
			var t = float(segment) / float(segments)
			var theta = lerp(start_angle, end_angle, t)
			var sin_theta = sin(theta)
			var cos_theta = cos(theta)

			var x = sphere_radius * sin_phi * cos_theta
			var y = sphere_radius * cos_phi
			var z = sphere_radius * sin_phi * sin_theta

			vertices.append(Vector3(x, y, z))

	# Add edge vertices
	vertices.append(Vector3(sphere_radius * cos(start_angle), 0, sphere_radius * sin(start_angle)))
	vertices.append(Vector3(sphere_radius * cos(end_angle), 0, sphere_radius * sin(end_angle)))

	return vertices

func _create_sector_mesh(start_angle: float, end_angle: float) -> ArrayMesh:
	"""Create mesh for a sector wedge"""
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var segments = 12
	var rings = 8
	var angle_range = end_angle - start_angle

	# Generate sphere surface within sector
	for ring in range(rings):
		var phi0 = PI * float(ring) / float(rings)
		var phi1 = PI * float(ring + 1) / float(rings)

		for segment in range(segments):
			var t0 = float(segment) / float(segments)
			var t1 = float(segment + 1) / float(segments)

			var theta0 = start_angle + angle_range * t0
			var theta1 = start_angle + angle_range * t1

			# Four corners of quad
			var v00 = _sphere_point(phi0, theta0)
			var v01 = _sphere_point(phi0, theta1)
			var v10 = _sphere_point(phi1, theta0)
			var v11 = _sphere_point(phi1, theta1)

			# Two triangles
			_add_triangle(st, v00, v10, v11)
			_add_triangle(st, v00, v11, v01)

	# Add side caps (flat faces on the wedge sides)
	_add_side_cap(st, start_angle)
	_add_side_cap(st, end_angle)

	return st.commit()

func _sphere_point(phi: float, theta: float) -> Vector3:
	"""Get point on sphere surface"""
	return Vector3(
		sphere_radius * sin(phi) * cos(theta),
		sphere_radius * cos(phi),
		sphere_radius * sin(phi) * sin(theta)
	)

func _add_triangle(st: SurfaceTool, v0: Vector3, v1: Vector3, v2: Vector3) -> void:
	"""Add triangle with calculated normal"""
	var normal = (v1 - v0).cross(v2 - v0).normalized()
	st.set_normal(normal)
	st.add_vertex(v0)
	st.set_normal(normal)
	st.add_vertex(v1)
	st.set_normal(normal)
	st.add_vertex(v2)

func _add_side_cap(st: SurfaceTool, angle: float) -> void:
	"""Add flat triangular cap on sector side"""
	var rings = 8
	var center = Vector3.ZERO

	for ring in range(rings):
		var phi0 = PI * float(ring) / float(rings)
		var phi1 = PI * float(ring + 1) / float(rings)

		var v0 = center
		var v1 = _sphere_point(phi0, angle)
		var v2 = _sphere_point(phi1, angle)

		_add_triangle(st, v0, v1, v2)

func _on_sector_hit(body: Node, sector: RigidBody3D) -> void:
	"""Handle sector hit"""
	if not body.is_in_group("throwable"):
		return

	if sector not in sector_data:
		return

	var data: SectorData = sector_data[sector]

	var impact_velocity = Vector3.ZERO
	var impact_point = Vector3.ZERO
	if body is RigidBody3D:
		impact_velocity = body.linear_velocity
		impact_point = body.global_position

	if shatter_all_on_hit:
		# Shatter ALL sectors at once
		_shatter_all_sectors(impact_velocity, impact_point)
	elif can_subdivide and data.subdivision_level < 2:
		# Split this sector in half
		_split_sector(sector, data, impact_velocity)
	else:
		# Destroy sector
		_destroy_sector(sector, data, impact_velocity)

func _shatter_all_sectors(impact_velocity: Vector3, impact_point: Vector3) -> void:
	"""Shatter all sectors at once with explosion effect"""
	var sectors_to_destroy = sectors.duplicate()

	for sector in sectors_to_destroy:
		if sector not in sector_data:
			continue

		var data: SectorData = sector_data[sector]

		# Enable physics if frozen
		if sector.freeze:
			sector.freeze = false
			sector.gravity_scale = 1.0

		# Calculate direction for this sector
		var mid_angle = (data.start_angle + data.end_angle) / 2.0
		var direction = Vector3(cos(mid_angle), 0, sin(mid_angle))

		# Add some influence from impact point
		var to_impact = (impact_point - global_position).normalized()
		direction = (direction * 0.7 + to_impact * 0.3).normalized()

		# Apply force with variation
		var force_strength = explosion_strength * randf_range(0.8, 1.2)
		sector.linear_velocity = direction * force_strength + impact_velocity * 0.3
		sector.angular_velocity = Vector3(randf_range(-5, 5), randf_range(-5, 5), randf_range(-5, 5))

		# Emit signal
		sector_destroyed.emit(sector, impact_velocity)

		# Fade out
		_fade_out_sector(sector, data.mesh_instance)

	# Clear tracking
	sectors.clear()
	sector_data.clear()

	sphere_fully_destroyed.emit(self)
	await get_tree().create_timer(4.0).timeout
	queue_free()

	print("[SectoredSphere] All sectors shattered!")

func _split_sector(sector: RigidBody3D, data: SectorData, impact_velocity: Vector3) -> void:
	"""Split sector into two halves"""
	var mid_angle = (data.start_angle + data.end_angle) / 2.0

	# Create two child sectors
	var child1 = _create_sector(data.start_angle, mid_angle, data.subdivision_level + 1)
	var child2 = _create_sector(mid_angle, data.end_angle, data.subdivision_level + 1)

	child1.global_position = sector.global_position
	child2.global_position = sector.global_position

	get_parent().add_child(child1)
	get_parent().add_child(child2)

	# Apply forces outward
	var dir1 = Vector3(cos(data.start_angle + (mid_angle - data.start_angle) / 2.0), 0, sin(data.start_angle + (mid_angle - data.start_angle) / 2.0))
	var dir2 = Vector3(cos(mid_angle + (data.end_angle - mid_angle) / 2.0), 0, sin(mid_angle + (data.end_angle - mid_angle) / 2.0))

	child1.linear_velocity = dir1 * explosion_strength * 0.5 + impact_velocity * 0.2
	child2.linear_velocity = dir2 * explosion_strength * 0.5 + impact_velocity * 0.2

	# Add to tracking
	sectors.append(child1)
	sectors.append(child2)

	# Remove parent
	sectors.erase(sector)
	sector_data.erase(sector)
	sector.queue_free()

	print("[SectoredSphere] Split sector into two halves")

func _destroy_sector(sector: RigidBody3D, data: SectorData, impact_velocity: Vector3) -> void:
	"""Destroy a sector completely"""
	sectors.erase(sector)
	sector_data.erase(sector)

	# Apply physics if frozen
	if sector.freeze:
		sector.freeze = false
		sector.gravity_scale = 1.0

	# Explosion force
	var mid_angle = (data.start_angle + data.end_angle) / 2.0
	var dir = Vector3(cos(mid_angle), 0, sin(mid_angle))
	sector.linear_velocity = dir * explosion_strength + impact_velocity * 0.3
	sector.angular_velocity = Vector3(randf_range(-5, 5), randf_range(-5, 5), randf_range(-5, 5))

	sector_destroyed.emit(sector, impact_velocity)

	# Fade out
	_fade_out_sector(sector, data.mesh_instance)

	if sectors.is_empty():
		sphere_fully_destroyed.emit(self)

	print("[SectoredSphere] Sector destroyed")

func _fade_out_sector(sector: RigidBody3D, mesh: MeshInstance3D) -> void:
	"""Fade and remove sector"""
	await get_tree().create_timer(3.0).timeout

	var tween = create_tween()
	tween.set_parallel(true)

	if mesh.material_override:
		var material = mesh.material_override
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tween.tween_property(material, "albedo_color:a", 0.0, 1.0)

	tween.tween_property(mesh, "scale", Vector3.ZERO, 1.0)
	tween.tween_callback(sector.queue_free).set_delay(1.0)

func get_sectors_count() -> int:
	return sectors.size()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
