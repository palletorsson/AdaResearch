extends Node3D
class_name CorridorTileMesh

# Custom mesh generator for corridor tiles with visible doorways

static func create_corridor_tile(tile_id: String, tile_size: float = 1.0) -> MeshInstance3D:
	"""Create a custom mesh for a corridor tile with doorways"""
	var mesh_instance = MeshInstance3D.new()

	# Room and corridor tiles
	if tile_id == "room":
		mesh_instance.mesh = create_room_mesh(tile_size)
	elif tile_id.begins_with("doorway_"):
		mesh_instance.mesh = create_doorway_mesh(tile_id, tile_size)
	elif tile_id == "corridor_NS":
		mesh_instance.mesh = create_ns_corridor_mesh(tile_size)
	elif tile_id == "corridor_EW":
		mesh_instance.mesh = create_ew_corridor_mesh(tile_size)
	elif tile_id.begins_with("corner_"):
		mesh_instance.mesh = create_corner_mesh(tile_id, tile_size)
	elif tile_id.begins_with("tjunc_"):
		mesh_instance.mesh = create_tjunction_mesh(tile_id, tile_size)
	elif tile_id == "cross":
		mesh_instance.mesh = create_cross_mesh(tile_size)
	# Legacy corridor tiles
	elif tile_id.begins_with("corridor_") and tile_id[-1].is_valid_int():
		mesh_instance.mesh = create_lr_corridor_mesh(tile_size)
	elif tile_id == "terminal":
		mesh_instance.mesh = create_terminal_mesh(tile_size)
	elif tile_id == "wall":
		mesh_instance.mesh = create_solid_box(tile_size)
	elif tile_id == "floor":
		mesh_instance.mesh = create_floor_mesh(tile_size)
	elif tile_id == "empty":
		mesh_instance.mesh = create_empty_mesh(tile_size)
	else:
		mesh_instance.mesh = create_solid_box(tile_size)

	return mesh_instance

static func create_lr_corridor_mesh(size: float) -> ArrayMesh:
	"""Create mesh for left-right corridor (open on sides, walls on front/back)"""
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)

	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()

	var half = size / 2.0
	var thickness = size * 0.1  # Wall thickness
	var door_width = size * 0.6  # Door opening width

	# Create walls on Z faces (front and back)
	# Front wall (positive Z)
	add_wall_quad(vertices, normals, indices,
		Vector3(-half, -half, half),
		Vector3(half, -half, half),
		Vector3(half, half, half),
		Vector3(-half, half, half),
		Vector3(0, 0, 1))

	# Back wall (negative Z)
	add_wall_quad(vertices, normals, indices,
		Vector3(half, -half, -half),
		Vector3(-half, -half, -half),
		Vector3(-half, half, -half),
		Vector3(half, half, -half),
		Vector3(0, 0, -1))

	# Floor
	add_wall_quad(vertices, normals, indices,
		Vector3(-half, -half, -half),
		Vector3(half, -half, -half),
		Vector3(half, -half, half),
		Vector3(-half, -half, half),
		Vector3(0, -1, 0))

	# Ceiling with opening
	add_wall_quad(vertices, normals, indices,
		Vector3(-half, half, half),
		Vector3(half, half, half),
		Vector3(half, half, -half),
		Vector3(-half, half, -half),
		Vector3(0, 1, 0))

	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

static func create_terminal_mesh(size: float) -> ArrayMesh:
	"""Create mesh for terminal (right wall sealed, left open)"""
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)

	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()

	var half = size / 2.0

	# Right wall (sealed - positive X)
	add_wall_quad(vertices, normals, indices,
		Vector3(half, -half, -half),
		Vector3(half, -half, half),
		Vector3(half, half, half),
		Vector3(half, half, -half),
		Vector3(1, 0, 0))

	# Front wall (positive Z)
	add_wall_quad(vertices, normals, indices,
		Vector3(-half, -half, half),
		Vector3(half, -half, half),
		Vector3(half, half, half),
		Vector3(-half, half, half),
		Vector3(0, 0, 1))

	# Back wall (negative Z)
	add_wall_quad(vertices, normals, indices,
		Vector3(half, -half, -half),
		Vector3(-half, -half, -half),
		Vector3(-half, half, -half),
		Vector3(half, half, -half),
		Vector3(0, 0, -1))

	# Floor
	add_wall_quad(vertices, normals, indices,
		Vector3(-half, -half, -half),
		Vector3(half, -half, -half),
		Vector3(half, -half, half),
		Vector3(-half, -half, half),
		Vector3(0, -1, 0))

	# Ceiling
	add_wall_quad(vertices, normals, indices,
		Vector3(-half, half, half),
		Vector3(half, half, half),
		Vector3(half, half, -half),
		Vector3(-half, half, -half),
		Vector3(0, 1, 0))

	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

static func create_solid_box(size: float) -> BoxMesh:
	"""Create a solid box for walls"""
	var box = BoxMesh.new()
	box.size = Vector3(size, size, size)
	return box

static func create_floor_mesh(size: float) -> BoxMesh:
	"""Create a thin floor mesh"""
	var box = BoxMesh.new()
	box.size = Vector3(size, size * 0.2, size)
	return box

static func create_empty_mesh(size: float) -> BoxMesh:
	"""Create a very small mesh for empty space (mostly transparent)"""
	var box = BoxMesh.new()
	box.size = Vector3(size * 0.1, size * 0.1, size * 0.1)
	return box

static func create_room_mesh(size: float) -> BoxMesh:
	"""Create an enclosed room mesh"""
	var box = BoxMesh.new()
	box.size = Vector3(size * 0.9, size * 0.8, size * 0.9)
	return box

static func create_doorway_mesh(tile_id: String, size: float) -> BoxMesh:
	"""Create a doorway mesh (thin opening)"""
	var box = BoxMesh.new()
	box.size = Vector3(size * 0.8, size * 0.8, size * 0.3)
	return box

static func create_ns_corridor_mesh(size: float) -> BoxMesh:
	"""North-South corridor"""
	var box = BoxMesh.new()
	box.size = Vector3(size * 0.3, size * 0.8, size)
	return box

static func create_ew_corridor_mesh(size: float) -> BoxMesh:
	"""East-West corridor"""
	var box = BoxMesh.new()
	box.size = Vector3(size, size * 0.8, size * 0.3)
	return box

static func create_corner_mesh(tile_id: String, size: float) -> BoxMesh:
	"""Corner corridor (L-shape)"""
	var box = BoxMesh.new()
	box.size = Vector3(size * 0.7, size * 0.8, size * 0.7)
	return box

static func create_tjunction_mesh(tile_id: String, size: float) -> BoxMesh:
	"""T-junction corridor"""
	var box = BoxMesh.new()
	box.size = Vector3(size * 0.8, size * 0.8, size * 0.8)
	return box

static func create_cross_mesh(size: float) -> BoxMesh:
	"""4-way crossroads"""
	var box = BoxMesh.new()
	box.size = Vector3(size * 0.9, size * 0.8, size * 0.9)
	return box

static func add_wall_quad(vertices: PackedVector3Array, normals: PackedVector3Array,
						 indices: PackedInt32Array, v1: Vector3, v2: Vector3,
						 v3: Vector3, v4: Vector3, normal: Vector3):
	"""Add a quad to the mesh"""
	var start_idx = vertices.size()

	vertices.append(v1)
	vertices.append(v2)
	vertices.append(v3)
	vertices.append(v4)

	for i in range(4):
		normals.append(normal)

	# Two triangles for the quad
	indices.append(start_idx + 0)
	indices.append(start_idx + 1)
	indices.append(start_idx + 2)

	indices.append(start_idx + 0)
	indices.append(start_idx + 2)
	indices.append(start_idx + 3)
