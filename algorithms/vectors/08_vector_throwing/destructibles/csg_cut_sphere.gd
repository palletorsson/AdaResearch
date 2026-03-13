# csg_cut_sphere.gd
# Sphere that uses CSG (Constructive Solid Geometry) for realistic cutting
extends Node3D

signal piece_split(parent_piece: Node3D, children: Array)
signal fully_fragmented(sphere: Node3D)

@export_group("Sphere Properties")
@export var sphere_radius: float = 0.3
@export var sphere_color: Color = Color(0.6, 0.3, 0.9, 1.0)  # Purple
@export var max_split_levels: int = 3
@export var shatter_all_on_hit: bool = true  # Shatter all pieces on any hit
@export var split_impulse_strength: float = 2.0

@export_group("CSG Settings")
@export var use_impact_plane: bool = true  # Use impact direction for cut plane
@export var cutting_thickness: float = 0.02  # Thickness of cutting plane

# CSG nodes for cutting operations
var csg_clip: CSGMesh3D
var csg_mask: CSGMesh3D

var pieces: Array[Node3D] = []
var piece_data: Dictionary = {}

class CSGPieceData:
	var mesh_instance: MeshInstance3D
	var rigid_body: RigidBody3D
	var area: Area3D
	var split_level: int
	var original_mesh: Mesh

	func _init(mesh: MeshInstance3D, rb: RigidBody3D, area_node: Area3D, level: int, mesh_data: Mesh) -> void:
		mesh_instance = mesh
		rigid_body = rb
		area = area_node
		split_level = level
		original_mesh = mesh_data

func _ready() -> void:
	_setup_csg_nodes()
	_create_initial_sphere()

func _setup_csg_nodes() -> void:
	"""Setup CSG nodes for cutting operations"""
	# Create CSG container (hidden in scene tree)
	var csg_container = Node3D.new()
	csg_container.name = "CSGContainer"
	add_child(csg_container)

	csg_clip = CSGMesh3D.new()
	csg_clip.name = "CSGClip"
	csg_container.add_child(csg_clip)

	csg_mask = CSGMesh3D.new()
	csg_mask.name = "CSGMask"
	csg_mask.operation = CSGShape3D.OPERATION_INTERSECTION
	csg_clip.add_child(csg_mask)

	# Make invisible (only used for calculations)
	csg_container.visible = false

func _create_initial_sphere() -> void:
	"""Create the initial whole sphere"""
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = sphere_radius
	sphere_mesh.height = sphere_radius * 2.0
	sphere_mesh.radial_segments = 32
	sphere_mesh.rings = 16

	var piece = _create_sphere_piece(sphere_mesh, Vector3.ZERO, 0)
	add_child(piece)
	pieces.append(piece)

func _create_sphere_piece(mesh: Mesh, offset: Vector3, level: int) -> RigidBody3D:
	"""Create a sphere piece from a mesh"""
	var rigid_body = RigidBody3D.new()
	rigid_body.name = "CSGPiece_L%d" % level
	rigid_body.position = offset

	# Create mesh instance
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh

	# Material with color variation by level
	var color = sphere_color
	color.h = fmod(sphere_color.h + level * 0.12, 1.0)

	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.2
	material.metallic = 0.0
	material.roughness = 1.0

	mesh_instance.material_override = material
	rigid_body.add_child(mesh_instance)

	# Create collision from mesh
	var collision = CollisionShape3D.new()
	var convex_shape = mesh.create_convex_shape()
	collision.shape = convex_shape
	rigid_body.add_child(collision)

	# Hit detection area
	var area = Area3D.new()
	area.monitoring = true
	area.collision_layer = 0
	area.collision_mask = 2

	var area_collision = CollisionShape3D.new()
	var area_shape = mesh.create_convex_shape()
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
		rigid_body.mass = 0.5 / pow(2, level)

	# Store data
	var data = CSGPieceData.new(mesh_instance, rigid_body, area, level, mesh)
	piece_data[rigid_body] = data

	# Connect hit
	area.body_entered.connect(_on_piece_hit.bind(rigid_body))

	return rigid_body

func _on_piece_hit(body: Node, piece: RigidBody3D) -> void:
	"""Handle when a piece is hit"""
	if not body.is_in_group("throwable"):
		return

	if piece not in piece_data:
		return

	var data: CSGPieceData = piece_data[piece]

	# Get impact info
	var impact_velocity = Vector3.ZERO
	var impact_point = Vector3.ZERO

	if body is RigidBody3D:
		impact_velocity = body.linear_velocity
		impact_point = body.global_position

	if shatter_all_on_hit:
		# First cut once if it's the whole sphere
		if data.split_level == 0:
			await _cut_piece_with_csg(piece, data, impact_point, impact_velocity)
			await get_tree().create_timer(0.1).timeout
		# Then shatter all pieces
		_shatter_all_pieces(impact_velocity, impact_point)
	elif data.split_level < max_split_levels:
		# Cut this piece using CSG
		await _cut_piece_with_csg(piece, data, impact_point, impact_velocity)
	else:
		print("[CSGCutSphere] Max split level reached")

func _cut_piece_with_csg(piece: RigidBody3D, data: CSGPieceData, impact_point: Vector3, impact_velocity: Vector3) -> void:
	"""Cut a piece in half using CSG operations"""

	# Determine cutting plane
	var plane_normal: Vector3
	var plane_point: Vector3 = piece.global_position

	if use_impact_plane and impact_velocity.length() > 0.1:
		# Use impact direction
		plane_normal = (impact_point - piece.global_position).normalized()
	else:
		# Random plane
		plane_normal = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()

	# Create cutting plane mesh (large box oriented along plane)
	var cutting_box = BoxMesh.new()
	cutting_box.size = Vector3(sphere_radius * 4, sphere_radius * 4, cutting_thickness)

	# Calculate rotation to align box with plane normal
	var box_basis = Basis()
	box_basis.z = plane_normal  # Box's Z axis becomes the normal
	box_basis.x = Vector3.UP.cross(plane_normal).normalized()
	if box_basis.x.length() < 0.1:  # Handle edge case
		box_basis.x = Vector3.RIGHT.cross(plane_normal).normalized()
	box_basis.y = plane_normal.cross(box_basis.x).normalized()

	# Perform CSG cutting
	var half1_mesh = await _cut_mesh_half(data.original_mesh, cutting_box, box_basis, plane_point, true)
	var half2_mesh = await _cut_mesh_half(data.original_mesh, cutting_box, box_basis, plane_point, false)

	if not half1_mesh or not half2_mesh:
		print("[CSGCutSphere] CSG cutting failed")
		return

	# Create two new pieces
	var offset1 = plane_normal * 0.05
	var offset2 = -plane_normal * 0.05

	var child1 = _create_sphere_piece(half1_mesh, piece.global_position + offset1, data.split_level + 1)
	var child2 = _create_sphere_piece(half2_mesh, piece.global_position + offset2, data.split_level + 1)

	get_parent().add_child(child1)
	get_parent().add_child(child2)

	# Apply physics
	var impulse1 = plane_normal * split_impulse_strength + impact_velocity * 0.2
	var impulse2 = -plane_normal * split_impulse_strength + impact_velocity * 0.2

	child1.linear_velocity = impulse1
	child2.linear_velocity = impulse2

	child1.angular_velocity = Vector3(randf_range(-3, 3), randf_range(-3, 3), randf_range(-3, 3))
	child2.angular_velocity = Vector3(randf_range(-3, 3), randf_range(-3, 3), randf_range(-3, 3))

	# Track new pieces
	pieces.append(child1)
	pieces.append(child2)

	# Remove parent
	pieces.erase(piece)
	piece_data.erase(piece)
	piece.queue_free()

	# Emit signal
	piece_split.emit(piece, [child1, child2])

	print("[CSGCutSphere] CSG cut successful (level %d)" % (data.split_level + 1))

func _cut_mesh_half(original_mesh: Mesh, cutting_plane: Mesh, plane_basis: Basis, plane_position: Vector3, keep_positive_side: bool) -> Mesh:
	"""Use CSG to cut mesh and keep one half"""

	# Set up the mesh to be cut
	csg_clip.mesh = original_mesh

	# Set up the cutting plane
	csg_mask.mesh = cutting_plane
	csg_mask.transform.origin = plane_position
	csg_mask.transform.basis = plane_basis

	# For the negative side, we need to offset the plane
	if not keep_positive_side:
		csg_mask.transform.origin += plane_basis.z * cutting_thickness

	# Force CSG update
	csg_clip._update_shape()

	# Wait a frame for CSG to process
	await get_tree().process_frame

	# Bake the result
	var result_mesh = csg_clip.get_meshes()

	if result_mesh.size() < 2:
		print("[CSGCutSphere] CSG returned no mesh")
		return null

	# Get the baked mesh (index 1 is the mesh, 0 is the transform)
	var baked_mesh: ArrayMesh = result_mesh[1] as ArrayMesh

	if not baked_mesh or baked_mesh.get_surface_count() == 0:
		print("[CSGCutSphere] Baked mesh is invalid")
		return null

	return baked_mesh

func _shatter_all_pieces(impact_velocity: Vector3, impact_point: Vector3) -> void:
	"""Shatter all pieces at once with explosion effect"""
	var pieces_to_destroy = pieces.duplicate()

	for piece in pieces_to_destroy:
		if piece not in piece_data:
			continue

		var data: CSGPieceData = piece_data[piece]

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

	print("[CSGCutSphere] All pieces shattered!")

func get_pieces_count() -> int:
	return pieces.size()

func get_max_split_level_reached() -> int:
	var max_level = 0
	for piece in pieces:
		if piece in piece_data:
			var data: CSGPieceData = piece_data[piece]
			max_level = max(max_level, data.split_level)
	return max_level

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

