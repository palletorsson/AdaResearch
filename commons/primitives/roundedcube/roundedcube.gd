# RoundedCube.gd - Cube with rounded edges and corners (chamfered/beveled cube)
extends Node3D
const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")
const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")

@export var base_color: Color = Color(0.3, 0.8, 0.9)
@export var size: float = 1.0
@export var radius: float = 0.15  # Rounding radius (0.0 = sharp cube, higher = more rounded)
@export var segments: int = 4  # Number of segments for rounding (higher = smoother)

var _mesh_instance: MeshInstance3D

func _ready():
	_build_rounded_cube()

func _build_rounded_cube() -> void:
	if _mesh_instance:
		if _mesh_instance.get_parent() == self:
			remove_child(_mesh_instance)
		_mesh_instance.queue_free()
		_mesh_instance = null

	var geometry := _rounded_cube_geometry()
	var material = GridMaterialFactory.make(base_color)
	_mesh_instance = PrimitiveMeshBuilder.build_mesh_instance(
		geometry["vertices"],
		geometry["faces"],
		{
			"name": "RoundedCube",
			"material": material
		}
	)
	add_child(_mesh_instance)

func _rounded_cube_geometry() -> Dictionary:
	var vertices: Array[Vector3] = []
	var faces: Array = []

	var half_size = size * 0.5
	var r = clamp(radius, 0.0, half_size * 0.49)  # Clamp radius

	# Use a cube-sphere mapping approach
	# Generate vertices on a cube, then apply rounding formula

	var divs = segments
	var grid_size = divs * 2 + 1  # Total grid size for each dimension

	# Generate all vertices in a 3D grid
	var vertex_grid = {}

	for x_idx in range(grid_size):
		for y_idx in range(grid_size):
			for z_idx in range(grid_size):
				# Only generate vertices on the surface (at least one coordinate at min/max)
				var on_surface = (x_idx == 0 or x_idx == grid_size - 1 or
								  y_idx == 0 or y_idx == grid_size - 1 or
								  z_idx == 0 or z_idx == grid_size - 1)

				if not on_surface:
					continue

				# Convert grid index to normalized position (-1 to 1)
				var x = (float(x_idx) / float(grid_size - 1)) * 2.0 - 1.0
				var y = (float(y_idx) / float(grid_size - 1)) * 2.0 - 1.0
				var z = (float(z_idx) / float(grid_size - 1)) * 2.0 - 1.0

				# Start with cube position
				var pos = Vector3(x, y, z) * half_size

				# Apply rounding using the superellipsoid formula
				# For each axis, shrink toward center based on distance from edge
				var rounded_pos = _apply_rounding(pos, half_size, r)

				var v_idx = vertices.size()
				vertices.append(rounded_pos)
				vertex_grid[Vector3i(x_idx, y_idx, z_idx)] = v_idx

	# Generate faces for each cube face
	# Front face (+Z)
	_add_grid_face(faces, vertex_grid, divs, grid_size - 1,
		func(i, j): return Vector3i(i, j, grid_size - 1))

	# Back face (-Z)
	_add_grid_face(faces, vertex_grid, divs, grid_size - 1,
		func(i, j): return Vector3i(grid_size - 1 - i, j, 0))

	# Top face (+Y)
	_add_grid_face(faces, vertex_grid, divs, grid_size - 1,
		func(i, j): return Vector3i(i, grid_size - 1, j))

	# Bottom face (-Y)
	_add_grid_face(faces, vertex_grid, divs, grid_size - 1,
		func(i, j): return Vector3i(i, 0, grid_size - 1 - j))

	# Right face (+X)
	_add_grid_face(faces, vertex_grid, divs, grid_size - 1,
		func(i, j): return Vector3i(grid_size - 1, j, grid_size - 1 - i))

	# Left face (-X)
	_add_grid_face(faces, vertex_grid, divs, grid_size - 1,
		func(i, j): return Vector3i(0, j, i))

	return {
		"vertices": vertices,
		"faces": faces
	}

func _apply_rounding(pos: Vector3, half_size: float, radius: float) -> Vector3:
	# Apply rounding to cube corners and edges
	# This creates smooth transitions at edges and corners

	var x_sign = sign(pos.x) if pos.x != 0 else 1
	var y_sign = sign(pos.y) if pos.y != 0 else 1
	var z_sign = sign(pos.z) if pos.z != 0 else 1

	var ax = abs(pos.x)
	var ay = abs(pos.y)
	var az = abs(pos.z)

	var inner = half_size - radius

	# Clamp each coordinate to the inner cube
	var cx = clamp(ax, 0, inner)
	var cy = clamp(ay, 0, inner)
	var cz = clamp(az, 0, inner)

	# Calculate the offset from the inner cube
	var dx = ax - inner
	var dy = ay - inner
	var dz = az - inner

	# Apply spherical rounding to the offset
	if dx > 0 or dy > 0 or dz > 0:
		dx = max(dx, 0)
		dy = max(dy, 0)
		dz = max(dz, 0)

		var dist = sqrt(dx * dx + dy * dy + dz * dz)
		if dist > 0:
			var scale = min(dist, radius) / dist
			dx *= scale
			dy *= scale
			dz *= scale

	return Vector3(
		x_sign * (cx + dx),
		y_sign * (cy + dy),
		z_sign * (cz + dz)
	)

func _add_grid_face(faces: Array, vertex_grid: Dictionary, divs: int, max_idx: int, get_coords: Callable) -> void:
	for i in range(divs * 2):
		for j in range(divs * 2):
			var coords0 = get_coords.call(i, j)
			var coords1 = get_coords.call(i + 1, j)
			var coords2 = get_coords.call(i + 1, j + 1)
			var coords3 = get_coords.call(i, j + 1)

			# Check if all vertices exist
			if (vertex_grid.has(coords0) and vertex_grid.has(coords1) and
				vertex_grid.has(coords2) and vertex_grid.has(coords3)):

				var v0 = vertex_grid[coords0]
				var v1 = vertex_grid[coords1]
				var v2 = vertex_grid[coords2]
				var v3 = vertex_grid[coords3]

				# Two triangles per quad
				faces.append([v0, v1, v2])
				faces.append([v0, v2, v3])

func set_base_color(color: Color) -> void:
	base_color = color
	if _mesh_instance:
		_mesh_instance.material_override = GridMaterialFactory.make(base_color)

func set_size(new_size: float) -> void:
	size = new_size
	_build_rounded_cube()

func set_radius(new_radius: float) -> void:
	radius = new_radius
	_build_rounded_cube()

func set_segments(new_segments: int) -> void:
	segments = max(1, new_segments)
	_build_rounded_cube()
