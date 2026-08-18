# octree_sphere.gd
# Sphere that divides into 8 octants, then each octant can subdivide into 8 more
extends Node3D

signal octant_split(parent: Node3D, children: Array)
signal fully_subdivided(sphere: Node3D)

@export_group("Sphere Properties")
@export var sphere_radius: float = 0.3
@export var sphere_color: Color = Color(0.3, 0.9, 0.7, 1.0)  # Green
@export var max_subdivision_levels: int = 2  # 0=whole, 1=8 pieces, 2=64 pieces
@export var shatter_all_on_hit: bool = true  # Shatter all octants on any hit
@export var explosion_strength: float = 2.0

var pieces: Array[Node3D] = []
var piece_data: Dictionary = {}

class OctantData:
	var mesh_instance: MeshInstance3D
	var rigid_body: RigidBody3D
	var area: Area3D
	var subdivision_level: int
	var octant_bounds: AABB  # Which octant of space this occupies
	var center: Vector3

	func _init(mesh: MeshInstance3D, rb: RigidBody3D, area_node: Area3D, level: int, bounds: AABB, pos: Vector3) -> void:
		mesh_instance = mesh
		rigid_body = rb
		area = area_node
		subdivision_level = level
		octant_bounds = bounds
		center = pos

func _ready() -> void:
	_create_initial_sphere()

func _create_initial_sphere() -> void:
	"""Create the whole sphere"""
	var full_bounds = AABB(Vector3(-sphere_radius, -sphere_radius, -sphere_radius), Vector3(sphere_radius * 2, sphere_radius * 2, sphere_radius * 2))
	var piece = _create_octant_piece(full_bounds, Vector3.ZERO, 0)
	add_child(piece)
	pieces.append(piece)

func _create_octant_piece(bounds: AABB, offset: Vector3, level: int) -> RigidBody3D:
	"""Create a piece representing an octant"""
	var rigid_body = RigidBody3D.new()
	rigid_body.name = "Octant_L%d" % level
	rigid_body.position = offset

	# Create spherical sector mesh
	var mesh_instance = MeshInstance3D.new()
	var mesh = _create_octant_mesh(bounds, level)
	mesh_instance.mesh = mesh

	# Color varies by level
	var color = sphere_color
	color.h = fmod(sphere_color.h + level * 0.15, 1.0)

	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.2
	material.metallic = 0.0
	material.roughness = 1.0

	mesh_instance.material_override = material
	rigid_body.add_child(mesh_instance)

	# Collision
	var collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = bounds.size * 0.9  # Slightly smaller
	collision.shape = box_shape
	collision.position = bounds.get_center()
	rigid_body.add_child(collision)

	# Hit detection
	var area = Area3D.new()
	area.monitoring = true
	area.collision_layer = 0
	area.collision_mask = 2

	var area_collision = CollisionShape3D.new()
	var area_box = BoxShape3D.new()
	area_box.size = bounds.size
	area_collision.shape = area_box
	area_collision.position = bounds.get_center()
	area.add_child(area_collision)
	rigid_body.add_child(area)

	# Physics
	if level == 0:
		rigid_body.freeze = true
		rigid_body.gravity_scale = 0.0
	else:
		rigid_body.freeze = false
		rigid_body.gravity_scale = 1.0
		rigid_body.mass = 0.5 / pow(8, level)

	# Store data
	var data = OctantData.new(mesh_instance, rigid_body, area, level, bounds, offset)
	piece_data[rigid_body] = data

	area.body_entered.connect(_on_octant_hit.bind(rigid_body))

	return rigid_body

func _create_octant_mesh(bounds: AABB, level: int) -> Mesh:
	"""Create a spherical segment mesh within the bounds"""
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var center = bounds.get_center()
	var segments = 8
	var rings = 4

	# Generate sphere vertices within this octant
	for ring in range(rings + 1):
		var phi = PI * float(ring) / float(rings) / (1 if level == 0 else 2)
		var start_phi = 0.0 if center.y >= 0 else PI / 2

		for segment in range(segments + 1):
			var theta = TAU * float(segment) / float(segments) / (1 if level == 0 else 2)
			var start_theta = 0.0
			if center.x < 0:
				start_theta = PI
			if center.z < 0:
				start_theta += PI / 2

			var actual_phi = start_phi + phi
			var actual_theta = start_theta + theta

			var x = sphere_radius * sin(actual_phi) * cos(actual_theta)
			var y = sphere_radius * cos(actual_phi)
			var z = sphere_radius * sin(actual_phi) * sin(actual_theta)

			var vertex = Vector3(x, y, z)

			# Only include if within bounds
			if bounds.has_point(vertex):
				st.set_normal(vertex.normalized())
				st.add_vertex(vertex - center)

	if st.commit().get_surface_count() == 0:
		# Fallback: simple box
		var box = BoxMesh.new()
		box.size = bounds.size * 0.8
		return box

	return st.commit()

func _on_octant_hit(body: Node, piece: RigidBody3D) -> void:
	"""Handle hit - subdivide into 8 octants or shatter all"""
	if not body.is_in_group("throwable"):
		return

	if piece not in piece_data:
		return

	var data: OctantData = piece_data[piece]

	var impact_velocity = Vector3.ZERO
	var impact_point = Vector3.ZERO
	if body is RigidBody3D:
		impact_velocity = body.linear_velocity
		impact_point = body.global_position

	if shatter_all_on_hit:
		# First subdivide once if it's the whole sphere
		if data.subdivision_level == 0:
			_subdivide_octant(piece, data, impact_velocity)
			await get_tree().create_timer(0.1).timeout
		# Then shatter all pieces
		_shatter_all_octants(impact_velocity, impact_point)
	elif data.subdivision_level < max_subdivision_levels:
		_subdivide_octant(piece, data, impact_velocity)

func _subdivide_octant(piece: RigidBody3D, data: OctantData, impact_velocity: Vector3) -> void:
	"""Split into 8 sub-octants"""

	var bounds = data.octant_bounds
	var half_size = bounds.size / 2.0
	var children: Array[Node3D] = []

	# Create 8 octants
	for x in range(2):
		for y in range(2):
			for z in range(2):
				var octant_pos = bounds.position + Vector3(x, y, z) * half_size
				var octant_bounds = AABB(octant_pos, half_size)

				var offset = octant_bounds.get_center()
				var child = _create_octant_piece(octant_bounds, piece.global_position + offset - bounds.get_center(), data.subdivision_level + 1)

				get_parent().add_child(child)
				children.append(child)
				pieces.append(child)

				# Apply explosion force outward
				var direction = (offset - bounds.get_center()).normalized()
				var force = direction * explosion_strength + impact_velocity * 0.1
				child.linear_velocity = force
				child.angular_velocity = Vector3(randf_range(-4, 4), randf_range(-4, 4), randf_range(-4, 4))

	# Remove parent
	pieces.erase(piece)
	piece_data.erase(piece)
	piece.queue_free()

	octant_split.emit(piece, children)

	print("[OctreeSphere] Subdivided into 8 octants (level %d)" % (data.subdivision_level + 1))

func _shatter_all_octants(impact_velocity: Vector3, impact_point: Vector3) -> void:
	"""Shatter all octants at once with explosion effect"""
	var pieces_to_destroy = pieces.duplicate()

	for piece in pieces_to_destroy:
		if piece not in piece_data:
			continue

		var data: OctantData = piece_data[piece]

		# Enable physics if frozen
		if piece.freeze:
			piece.freeze = false
			piece.gravity_scale = 1.0

		# Calculate explosion direction from center through octant center
		var direction = data.center.normalized()

		# Add influence from impact point
		var to_impact = (impact_point - global_position).normalized()
		direction = (direction * 0.7 + to_impact * 0.3).normalized()

		# Apply force with variation
		var force_strength = explosion_strength * randf_range(0.8, 1.2)
		piece.linear_velocity = direction * force_strength + impact_velocity * 0.3
		piece.angular_velocity = Vector3(randf_range(-5, 5), randf_range(-5, 5), randf_range(-5, 5))

		# Emit signal
		octant_split.emit(piece, [])

		# Fade out
		await get_tree().create_timer(3.0).timeout
		var mesh = data.mesh_instance
		if mesh and mesh.material_override:
			var tween = create_tween()
			tween.set_parallel(true)
			var material = mesh.material_override
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			tween.tween_property(material, "albedo_color:a", 0.0, 1.0)
			tween.tween_property(mesh, "scale", Vector3.ZERO, 1.0)
			tween.tween_callback(piece.queue_free).set_delay(1.0)

	# Clear tracking
	pieces.clear()
	piece_data.clear()

	fully_subdivided.emit(self)
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().create_timer(4.0).timeout
	queue_free()

	print("[OctreeSphere] All octants shattered!")

func get_pieces_count() -> int:
	return pieces.size()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
