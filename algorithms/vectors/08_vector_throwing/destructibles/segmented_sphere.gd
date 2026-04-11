# segmented_sphere.gd
# Sphere pre-built from individual segment parts using SurfaceTool
# Each segment can be destroyed independently
extends Node3D

signal segment_destroyed(segment: Node3D, impact_velocity: Vector3)
signal sphere_fully_destroyed(sphere: Node3D)

@export_group("Sphere Properties")
@export var sphere_radius: float = 0.3
@export var sphere_color: Color = Color(0.2, 0.7, 0.9, 1.0)  # Cyan
@export var latitude_segments: int = 6  # Horizontal rings
@export var longitude_segments: int = 8  # Vertical slices
@export var segment_gap: float = 0.01  # Gap between segments

@export_group("Destruction")
@export var enable_physics_on_hit: bool = true
@export var explosion_strength: float = 2.0
@export var segment_health: int = 1

# Track segments
var segments: Array[Node3D] = []
var segment_data: Dictionary = {}

class SegmentData:
	var mesh_instance: MeshInstance3D
	var rigid_body: RigidBody3D
	var area: Area3D
	var lat_index: int
	var lon_index: int
	var current_health: int
	var center_offset: Vector3

	func _init(mesh: MeshInstance3D, rb: RigidBody3D, area_node: Area3D, lat: int, lon: int, health: int, offset: Vector3) -> void:
		mesh_instance = mesh
		rigid_body = rb
		area = area_node
		lat_index = lat
		lon_index = lon
		current_health = health
		center_offset = offset

func _ready() -> void:
	_build_segmented_sphere()

func _build_segmented_sphere() -> void:
	"""Build sphere from individual surface-tool segments"""

	var segments_container = Node3D.new()
	segments_container.name = "Segments"
	add_child(segments_container)

	# Create each segment
	for lat in range(latitude_segments):
		for lon in range(longitude_segments):
			var segment = _create_segment(lat, lon)
			if segment:
				segments_container.add_child(segment)
				segments.append(segment)

func _create_segment(lat_index: int, lon_index: int) -> Node3D:
	"""Create a single spherical segment using SurfaceTool"""

	# Calculate angle ranges for this segment
	var phi_start = PI * float(lat_index) / float(latitude_segments)
	var phi_end = PI * float(lat_index + 1) / float(latitude_segments)
	var theta_start = TAU * float(lon_index) / float(longitude_segments)
	var theta_end = TAU * float(lon_index + 1) / float(longitude_segments)

	# Apply gap by shrinking segment slightly
	var phi_gap = (phi_end - phi_start) * segment_gap
	var theta_gap = (theta_end - theta_start) * segment_gap
	phi_start += phi_gap
	phi_end -= phi_gap
	theta_start += theta_gap
	theta_end -= theta_gap

	# Create mesh using SurfaceTool
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Generate quad grid for this segment
	var subdivisions = 4  # Detail level within each segment

	for i in range(subdivisions):
		for j in range(subdivisions):
			# Calculate 4 corners of quad
			var phi0 = lerp(phi_start, phi_end, float(i) / float(subdivisions))
			var phi1 = lerp(phi_start, phi_end, float(i + 1) / float(subdivisions))
			var theta0 = lerp(theta_start, theta_end, float(j) / float(subdivisions))
			var theta1 = lerp(theta_start, theta_end, float(j + 1) / float(subdivisions))

			# Four corners
			var v00 = _sphere_point(sphere_radius, phi0, theta0)
			var v01 = _sphere_point(sphere_radius, phi0, theta1)
			var v10 = _sphere_point(sphere_radius, phi1, theta0)
			var v11 = _sphere_point(sphere_radius, phi1, theta1)

			# Two triangles per quad
			_add_triangle(st, v00, v10, v11)
			_add_triangle(st, v00, v11, v01)

	var segment_mesh = st.commit()

	if segment_mesh.get_surface_count() == 0:
		return null

	# Calculate segment center for positioning
	var center_phi = (phi_start + phi_end) / 2.0
	var center_theta = (theta_start + theta_end) / 2.0
	var segment_center = _sphere_point(sphere_radius * 0.7, center_phi, center_theta)

	# Create rigid body for segment
	var rigid_body = RigidBody3D.new()
	rigid_body.name = "Segment_%d_%d" % [lat_index, lon_index]

	# Create mesh instance
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = segment_mesh

	# Color varies by position
	var color = sphere_color
	var hue_offset = (float(lat_index) / latitude_segments + float(lon_index) / longitude_segments) / 2.0
	color.h = fmod(sphere_color.h + hue_offset * 0.3, 1.0)

	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.2
	material.metallic = 0.0
	material.roughness = 1.0

	mesh_instance.material_override = material
	rigid_body.add_child(mesh_instance)

	# Create collision shape from mesh
	var collision = CollisionShape3D.new()
	var convex_shape = segment_mesh.create_convex_shape()
	collision.shape = convex_shape
	rigid_body.add_child(collision)

	# Hit detection area
	var area = Area3D.new()
	area.monitoring = true
	area.collision_layer = 0
	area.collision_mask = 2

	var area_collision = CollisionShape3D.new()
	var area_shape = segment_mesh.create_convex_shape()
	area_collision.shape = area_shape
	area.add_child(area_collision)
	rigid_body.add_child(area)

	# Physics - start frozen as part of sphere
	rigid_body.freeze = true
	rigid_body.gravity_scale = 0.0
	rigid_body.mass = 0.1

	# Store data
	var data = SegmentData.new(mesh_instance, rigid_body, area, lat_index, lon_index, segment_health, segment_center)
	segment_data[rigid_body] = data

	# Connect hit
	area.body_entered.connect(_on_segment_hit.bind(rigid_body))

	return rigid_body

func _sphere_point(radius: float, phi: float, theta: float) -> Vector3:
	"""Calculate point on sphere surface"""
	return Vector3(
		radius * sin(phi) * cos(theta),
		radius * cos(phi),
		radius * sin(phi) * sin(theta)
	)

func _add_triangle(st: SurfaceTool, v0: Vector3, v1: Vector3, v2: Vector3) -> void:
	"""Add triangle with proper normal"""
	# Calculate normal from triangle
	var normal = (v1 - v0).cross(v2 - v0).normalized()

	st.set_normal(normal)
	st.set_uv(Vector2(0, 0))
	st.add_vertex(v0)

	st.set_normal(normal)
	st.set_uv(Vector2(1, 0))
	st.add_vertex(v1)

	st.set_normal(normal)
	st.set_uv(Vector2(0.5, 1))
	st.add_vertex(v2)

func _on_segment_hit(body: Node, segment: Node3D) -> void:
	"""Handle when a segment is hit - shatters ALL segments"""
	if not body.is_in_group("throwable"):
		return

	if segment not in segment_data:
		return

	# Get impact velocity
	var impact_velocity = Vector3.ZERO
	var impact_point = Vector3.ZERO
	if body is RigidBody3D:
		impact_velocity = body.linear_velocity
		impact_point = body.global_position

	# Shatter ALL segments at once
	_shatter_all_segments(impact_velocity, impact_point)

func _shatter_all_segments(impact_velocity: Vector3, impact_point: Vector3) -> void:
	"""Shatter all segments at once with explosion effect"""
	var segments_to_destroy = segments.duplicate()  # Copy array to avoid modification during iteration

	for segment in segments_to_destroy:
		if segment not in segment_data:
			continue

		var data: SegmentData = segment_data[segment]

		# Enable physics
		var rb: RigidBody3D = data.rigid_body
		rb.freeze = false
		rb.gravity_scale = 1.0

		# Calculate explosion direction from sphere center through segment center
		var direction = data.center_offset.normalized()

		# Add some variation based on impact point
		var to_impact = (impact_point - global_position).normalized()
		var influence = 0.3  # How much the impact point affects direction
		direction = (direction * (1.0 - influence) + to_impact * influence).normalized()

		# Apply force
		var base_strength = explosion_strength * randf_range(0.8, 1.2)
		var force = direction * base_strength + impact_velocity * 0.3

		rb.linear_velocity = force
		rb.angular_velocity = Vector3(
			randf_range(-5, 5),
			randf_range(-5, 5),
			randf_range(-5, 5)
		)

		# Emit signal for this segment
		segment_destroyed.emit(segment, impact_velocity)

		# Fade out
		_fade_out_segment(rb, data.mesh_instance)

	# Clear tracking
	segments.clear()
	segment_data.clear()

	# Emit fully destroyed signal
	sphere_fully_destroyed.emit(self)
	await get_tree().create_timer(4.0).timeout
	queue_free()

	print("[SegmentedSphere] All segments shattered!")

func _show_segment_damage(data: SegmentData) -> void:
	"""Visual feedback for damaged segment"""
	var mesh = data.mesh_instance

	var tween = create_tween()
	tween.set_parallel(true)

	if mesh.material_override:
		tween.tween_property(mesh.material_override, "emission_energy", 1.5, 0.1)
		tween.tween_property(mesh.material_override, "emission_energy", 0.4, 0.2).set_delay(0.1)

func _destroy_segment(segment: Node3D, data: SegmentData, impact_velocity: Vector3) -> void:
	"""Destroy a segment"""
	segments.erase(segment)
	segment_data.erase(segment)

	segment_destroyed.emit(segment, impact_velocity)

	if enable_physics_on_hit:
		# Enable physics and apply force
		var rb: RigidBody3D = data.rigid_body
		rb.freeze = false
		rb.gravity_scale = 1.0

		# Explosion direction from center
		var direction = data.center_offset.normalized()
		var force = direction * explosion_strength + impact_velocity * 0.3

		rb.linear_velocity = force
		rb.angular_velocity = Vector3(
			randf_range(-5, 5),
			randf_range(-5, 5),
			randf_range(-5, 5)
		)

		# Fade out
		_fade_out_segment(rb, data.mesh_instance)
	else:
		segment.queue_free()

	# Check if all destroyed
	if segments.is_empty():
		sphere_fully_destroyed.emit(self)
		await get_tree().create_timer(2.0).timeout
		queue_free()

	print("[SegmentedSphere] Segment [%d,%d] destroyed" % [data.lat_index, data.lon_index])

func _fade_out_segment(rb: RigidBody3D, mesh: MeshInstance3D) -> void:
	"""Fade and remove segment"""
	await get_tree().create_timer(3.0).timeout

	var tween = create_tween()
	tween.set_parallel(true)

	if mesh.material_override:
		var material = mesh.material_override
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tween.tween_property(material, "albedo_color:a", 0.0, 1.0)

	tween.tween_property(mesh, "scale", Vector3.ZERO, 1.0)
	tween.tween_callback(rb.queue_free).set_delay(1.0)

func get_segments_remaining() -> int:
	return segments.size()

func get_total_segments() -> int:
	return latitude_segments * longitude_segments

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
