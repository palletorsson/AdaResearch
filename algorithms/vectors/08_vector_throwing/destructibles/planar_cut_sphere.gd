# planar_cut_sphere.gd
# Sphere that splits in half along a plane, then those halves can split again
extends Node3D

signal piece_split(parent_piece: Node3D, children: Array)
signal fully_fragmented(sphere: Node3D)

@export_group("Sphere Properties")
@export var sphere_radius: float = 0.3
@export var sphere_color: Color = Color(0.9, 0.6, 0.3, 1.0)  # Orange
@export var max_split_levels: int = 3  # How many times can we split (1=half, 2=quarters, 3=eighths)
@export var shatter_all_on_hit: bool = true  # Shatter all pieces on any hit
@export var split_impulse_strength: float = 2.0

# Track pieces and their split level
var pieces: Array[Node3D] = []
var piece_data: Dictionary = {}  # piece -> SphereData

class SphereData:
	var mesh_instance: MeshInstance3D
	var rigid_body: RigidBody3D
	var area: Area3D
	var split_level: int
	var vertices: PackedVector3Array
	var center: Vector3

	func _init(mesh: MeshInstance3D, rb: RigidBody3D, area_node: Area3D, level: int, verts: PackedVector3Array, pos: Vector3) -> void:
		mesh_instance = mesh
		rigid_body = rb
		area = area_node
		split_level = level
		vertices = verts
		center = pos

func _ready() -> void:
	_create_initial_sphere()

func _create_initial_sphere() -> void:
	"""Create the initial whole sphere"""
	var vertices = _generate_sphere_vertices(sphere_radius)
	var piece = _create_sphere_piece(vertices, Vector3.ZERO, 0)
	add_child(piece)
	pieces.append(piece)

func _generate_sphere_vertices(radius: float, segments: int = 16, rings: int = 8) -> PackedVector3Array:
	"""Generate UV sphere vertices"""
	var vertices = PackedVector3Array()

	for ring in range(rings + 1):
		var phi = PI * float(ring) / float(rings)
		var sin_phi = sin(phi)
		var cos_phi = cos(phi)

		for segment in range(segments + 1):
			var theta = TAU * float(segment) / float(segments)
			var sin_theta = sin(theta)
			var cos_theta = cos(theta)

			var x = radius * sin_phi * cos_theta
			var y = radius * cos_phi
			var z = radius * sin_phi * sin_theta

			vertices.append(Vector3(x, y, z))

	return vertices

func _create_sphere_piece(vertices: PackedVector3Array, offset: Vector3, split_level: int) -> RigidBody3D:
	"""Create a sphere piece from vertices"""
	var rigid_body = RigidBody3D.new()
	rigid_body.name = "SpherePiece_L%d" % split_level
	rigid_body.position = offset

	# Create mesh
	var mesh_instance = MeshInstance3D.new()
	var mesh = _create_mesh_from_vertices(vertices)
	mesh_instance.mesh = mesh

	# Material
	var color = sphere_color
	color.h = fmod(sphere_color.h + split_level * 0.1, 1.0)

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
	if split_level == 0:
		rigid_body.freeze = true
		rigid_body.gravity_scale = 0.0
	else:
		rigid_body.freeze = false
		rigid_body.gravity_scale = 1.0
		rigid_body.mass = 0.5 / pow(2, split_level)

	# Store data
	var data = SphereData.new(mesh_instance, rigid_body, area, split_level, vertices, offset)
	piece_data[rigid_body] = data

	# Connect hit
	area.body_entered.connect(_on_piece_hit.bind(rigid_body))

	return rigid_body

func _create_mesh_from_vertices(vertices: PackedVector3Array) -> ArrayMesh:
	"""Create a mesh from vertices using convex hull"""
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Simple triangulation - fan from center
	var center = _calculate_center(vertices)

	for i in range(vertices.size()):
		var next = (i + 1) % vertices.size()
		var v0 = center
		var v1 = vertices[i]
		var v2 = vertices[next]

		var normal = (v1 - v0).cross(v2 - v0).normalized()

		st.set_normal(normal)
		st.add_vertex(v0)
		st.set_normal(normal)
		st.add_vertex(v1)
		st.set_normal(normal)
		st.add_vertex(v2)

	return st.commit()

func _calculate_center(vertices: PackedVector3Array) -> Vector3:
	"""Calculate centroid of vertices"""
	var sum = Vector3.ZERO
	for v in vertices:
		sum += v
	return sum / vertices.size() if vertices.size() > 0 else Vector3.ZERO

func _on_piece_hit(body: Node, piece: RigidBody3D) -> void:
	"""Handle when a piece is hit - split it or shatter all"""
	if not body.is_in_group("throwable"):
		return

	if piece not in piece_data:
		return

	var data: SphereData = piece_data[piece]

	# Get impact info
	var impact_velocity = Vector3.ZERO
	if body is RigidBody3D:
		impact_velocity = body.linear_velocity

	var impact_point = body.global_position

	if shatter_all_on_hit:
		# First split once if it's the whole sphere
		if data.split_level == 0:
			_split_piece(piece, data, impact_point, impact_velocity)
			await get_tree().create_timer(0.1).timeout
		# Then shatter all pieces
		_shatter_all_pieces(impact_velocity, impact_point)
	elif data.split_level < max_split_levels:
		# Split this piece
		_split_piece(piece, data, impact_point, impact_velocity)
	else:
		print("[PlanarCutSphere] Already at max split level")

func _split_piece(piece: RigidBody3D, data: SphereData, impact_point: Vector3, impact_velocity: Vector3) -> void:
	"""Split a piece in half along a plane"""

	# Determine split plane - use impact direction or random
	var plane_normal = (impact_point - piece.global_position).normalized()
	if plane_normal.length() < 0.1:
		plane_normal = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()

	var plane_point = data.center

	# Split vertices into two groups
	var half1_verts = PackedVector3Array()
	var half2_verts = PackedVector3Array()

	for vertex in data.vertices:
		var to_vertex = vertex - plane_point
		var side = plane_normal.dot(to_vertex)

		if side >= 0:
			half1_verts.append(vertex)
		else:
			half2_verts.append(vertex)

	# Need vertices on both sides
	if half1_verts.size() < 3 or half2_verts.size() < 3:
		print("[PlanarCutSphere] Not enough vertices to split")
		return

	# Create two new pieces
	var offset1 = plane_normal * 0.05
	var offset2 = -plane_normal * 0.05

	var child1 = _create_sphere_piece(half1_verts, piece.global_position + offset1, data.split_level + 1)
	var child2 = _create_sphere_piece(half2_verts, piece.global_position + offset2, data.split_level + 1)

	get_parent().add_child(child1)
	get_parent().add_child(child2)

	# Apply impulse
	var split_impulse1 = plane_normal * split_impulse_strength + impact_velocity * 0.2
	var split_impulse2 = -plane_normal * split_impulse_strength + impact_velocity * 0.2

	child1.linear_velocity = split_impulse1
	child2.linear_velocity = split_impulse2

	child1.angular_velocity = Vector3(randf_range(-3, 3), randf_range(-3, 3), randf_range(-3, 3))
	child2.angular_velocity = Vector3(randf_range(-3, 3), randf_range(-3, 3), randf_range(-3, 3))

	# Add to tracking
	pieces.append(child1)
	pieces.append(child2)

	# Remove parent piece
	pieces.erase(piece)
	piece_data.erase(piece)
	piece.queue_free()

	# Emit signal
	piece_split.emit(piece, [child1, child2])

	print("[PlanarCutSphere] Split into %d and %d vertices (level %d)" % [half1_verts.size(), half2_verts.size(), data.split_level + 1])

func _shatter_all_pieces(impact_velocity: Vector3, impact_point: Vector3) -> void:
	"""Shatter all pieces at once with explosion effect"""
	var pieces_to_destroy = pieces.duplicate()

	for piece in pieces_to_destroy:
		if piece not in piece_data:
			continue

		var data: SphereData = piece_data[piece]

		# Enable physics if frozen
		if piece.freeze:
			piece.freeze = false
			piece.gravity_scale = 1.0

		# Calculate explosion direction from center
		var direction = (piece.global_position - global_position).normalized()

		# Add influence from impact point
		var to_impact = (impact_point - global_position).normalized()
		direction = (direction * 0.7 + to_impact * 0.3).normalized()

		# Apply force with variation
		var force_strength = split_impulse_strength * randf_range(0.8, 1.2)
		piece.linear_velocity = direction * force_strength + impact_velocity * 0.3
		piece.angular_velocity = Vector3(randf_range(-5, 5), randf_range(-5, 5), randf_range(-5, 5))

		# Emit signal
		piece_split.emit(piece, [])

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

	fully_fragmented.emit(self)
	await get_tree().create_timer(4.0).timeout
	queue_free()

	print("[PlanarCutSphere] All pieces shattered!")

func get_pieces_count() -> int:
	return pieces.size()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
