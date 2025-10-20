class_name TessellationLatticeWalk
extends Node3D

## A perfect space-filling tessellation revealed by random walk
## Creates a pre-computed lattice grid and reveals forms one at a time

enum TessellationType {
	CUBE,
	OCTAHEDRON,
	RHOMBIC_DODECAHEDRON,
	TRUNCATED_OCTAHEDRON
}

## Configuration
@export_group("Lattice Properties")
@export var tessellation_type: TessellationType = TessellationType.CUBE
@export var grid_size: Vector3i = Vector3i(10, 10, 10)
@export var cell_size: float = 2.0

@export_group("Random Walk")
@export var walk_speed: float = 5.0  # Cells revealed per second
@export var auto_walk: bool = true
@export var loop_walk: bool = true

@export_group("Visual Effects")
@export var color_start: Color = Color(0.3, 0.6, 1.0)
@export var color_end: Color = Color(1.0, 0.3, 0.6)
@export var emission_strength: float = 0.8
@export var show_all_at_start: bool = false

@export_group("Generation")
@export var random_seed: int = 0

# Internal data
var lattice_positions: Array[Vector3i] = []  # Grid coordinates of all cells
var lattice_transforms: Array[Transform3D] = []  # World transforms for each cell
var grid_to_index: Dictionary = {}  # Fast lookup: Vector3i -> int index
var walk_path: Array[int] = []  # Indices into lattice arrays (random order)
var current_walk_index: int = 0
var revealed_indices: Array[int] = []  # Which cells are currently visible

var cell_mesh: Mesh
var multimesh_instance: MultiMeshInstance3D
var walk_timer: float = 0.0

func _ready():
	if random_seed != 0:
		seed(random_seed)

	print("=== Tessellation Lattice Walk ===")
	print("Type: ", TessellationType.keys()[tessellation_type])
	print("Grid size: ", grid_size)
	print("Total cells: ", grid_size.x * grid_size.y * grid_size.z)

	# Create the mesh for the selected tessellation type
	create_cell_mesh()

	# Generate the lattice grid
	generate_lattice()

	# Create random walk path
	generate_walk_path()

	# Setup multimesh for rendering
	setup_multimesh()

	if show_all_at_start:
		reveal_all()

func _process(delta):
	if auto_walk and walk_path.size() > 0:
		walk_timer += delta
		var cells_to_reveal = int(walk_timer * walk_speed)

		if cells_to_reveal > 0:
			walk_timer -= cells_to_reveal / walk_speed

			for i in range(cells_to_reveal):
				if current_walk_index < walk_path.size():
					reveal_next_cell()
				elif loop_walk:
					reset_walk()
					reveal_next_cell()

func create_cell_mesh():
	"""Create mesh based on tessellation type"""
	match tessellation_type:
		TessellationType.CUBE:
			cell_mesh = create_cube_mesh()
		TessellationType.OCTAHEDRON:
			cell_mesh = create_octahedron_mesh()
		TessellationType.RHOMBIC_DODECAHEDRON:
			cell_mesh = create_rhombic_dodecahedron_mesh()
		TessellationType.TRUNCATED_OCTAHEDRON:
			cell_mesh = create_truncated_octahedron_mesh()

	print("Cell mesh created: ", cell_mesh.get_faces().size(), " faces")

func create_cube_mesh() -> Mesh:
	"""Create a simple cube mesh"""
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)

	var verts = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()

	var size = cell_size * 0.5

	# Define 8 vertices of a cube
	var cube_verts = [
		Vector3(-size, -size, -size),  # 0
		Vector3(size, -size, -size),   # 1
		Vector3(size, size, -size),    # 2
		Vector3(-size, size, -size),   # 3
		Vector3(-size, -size, size),   # 4
		Vector3(size, -size, size),    # 5
		Vector3(size, size, size),     # 6
		Vector3(-size, size, size)     # 7
	]

	# Define 6 faces (each with 4 vertices -> 2 triangles)
	var faces = [
		[0, 1, 2, 3, Vector3(0, 0, -1)],   # Front
		[4, 7, 6, 5, Vector3(0, 0, 1)],    # Back
		[0, 3, 7, 4, Vector3(-1, 0, 0)],   # Left
		[1, 5, 6, 2, Vector3(1, 0, 0)],    # Right
		[3, 2, 6, 7, Vector3(0, 1, 0)],    # Top
		[0, 4, 5, 1, Vector3(0, -1, 0)]    # Bottom
	]

	var vertex_index = 0
	for face in faces:
		var normal = face[4]

		# Add 4 vertices for this face
		for i in range(4):
			verts.append(cube_verts[face[i]])
			normals.append(normal)

		# Two triangles
		indices.append_array([vertex_index, vertex_index + 1, vertex_index + 2])
		indices.append_array([vertex_index, vertex_index + 2, vertex_index + 3])
		vertex_index += 4

	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices

	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	return array_mesh

func create_octahedron_mesh() -> Mesh:
	"""Create a regular octahedron - 8 triangular faces"""
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)

	var verts = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()

	var s = cell_size * 0.5

	# 6 vertices at axis endpoints
	var vertices = [
		Vector3(s, 0, 0),    # 0 - +X
		Vector3(-s, 0, 0),   # 1 - -X
		Vector3(0, s, 0),    # 2 - +Y
		Vector3(0, -s, 0),   # 3 - -Y
		Vector3(0, 0, s),    # 4 - +Z
		Vector3(0, 0, -s)    # 5 - -Z
	]

	# 8 triangular faces (indices into vertices array)
	var faces = [
		[4, 0, 2],  # 0: Top-front-right
		[4, 2, 1],  # 1: Top-front-left
		[4, 1, 3],  # 2: Top-back-left
		[4, 3, 0],  # 3: Top-back-right
		[5, 2, 0],  # 4: Bottom-front-right
		[5, 1, 2],  # 5: Bottom-front-left
		[5, 3, 1],  # 6: Bottom-back-left
		[5, 0, 3]   # 7: Bottom-back-right
	]

	var vertex_index = 0
	for face in faces:
		# Calculate face normal
		var v0 = vertices[face[0]]
		var v1 = vertices[face[1]]
		var v2 = vertices[face[2]]
		var edge1 = v1 - v0
		var edge2 = v2 - v0
		var normal = edge1.cross(edge2).normalized()

		# Add 3 vertices for this triangular face
		verts.append(v0)
		normals.append(normal)
		verts.append(v1)
		normals.append(normal)
		verts.append(v2)
		normals.append(normal)

		# Add indices for this triangle
		indices.append_array([vertex_index, vertex_index + 1, vertex_index + 2])
		vertex_index += 3

	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices

	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	return array_mesh

func create_rhombic_dodecahedron_mesh() -> Mesh:
	"""Create a rhombic dodecahedron - 12 rhombic faces"""
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)

	var verts = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()

	var s = cell_size * 0.5

	# 14 vertices: 8 cube corners + 6 face centers
	var vertices = [
		Vector3(s, s, s),      # 0
		Vector3(s, s, -s),     # 1
		Vector3(s, -s, s),     # 2
		Vector3(s, -s, -s),    # 3
		Vector3(-s, s, s),     # 4
		Vector3(-s, s, -s),    # 5
		Vector3(-s, -s, s),    # 6
		Vector3(-s, -s, -s),   # 7
		Vector3(2*s, 0, 0),    # 8 - +X face center
		Vector3(-2*s, 0, 0),   # 9 - -X face center
		Vector3(0, 2*s, 0),    # 10 - +Y face center
		Vector3(0, -2*s, 0),   # 11 - -Y face center
		Vector3(0, 0, 2*s),    # 12 - +Z face center
		Vector3(0, 0, -2*s)    # 13 - -Z face center
	]

	# 12 rhombic faces (4 vertices each, forming rhombi)
	var faces = [
		[0, 8, 2, 12],   # 0
		[0, 12, 4, 10],  # 1
		[0, 10, 1, 8],   # 2
		[1, 10, 5, 13],  # 3
		[2, 8, 3, 11],   # 4
		[3, 8, 1, 13],   # 5
		[4, 12, 6, 9],   # 6
		[5, 10, 4, 9],   # 7
		[6, 12, 2, 11],  # 8
		[7, 9, 6, 11],   # 9
		[7, 11, 3, 13],  # 10
		[7, 13, 5, 9]    # 11
	]

	var vertex_index = 0
	for face in faces:
		# Calculate face normal
		var v0 = vertices[face[0]]
		var v1 = vertices[face[1]]
		var v2 = vertices[face[2]]
		var edge1 = v1 - v0
		var edge2 = v2 - v0
		var normal = edge1.cross(edge2).normalized()

		# Add 4 vertices for this rhombus
		for i in range(4):
			verts.append(vertices[face[i]])
			normals.append(normal)

		# Two triangles for rhombus
		indices.append_array([vertex_index, vertex_index + 1, vertex_index + 2])
		indices.append_array([vertex_index, vertex_index + 2, vertex_index + 3])
		vertex_index += 4

	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices

	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	return array_mesh

func create_truncated_octahedron_mesh() -> Mesh:
	"""Create a truncated octahedron - 6 square faces + 8 hexagonal faces"""
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)

	var verts = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()

	var s = cell_size * 0.5

	# 24 vertices
	var vertices = [
		Vector3(0, s, 2*s),        # 0
		Vector3(0, s, -2*s),       # 1
		Vector3(0, -s, 2*s),       # 2
		Vector3(0, -s, -2*s),      # 3
		Vector3(s, 0, 2*s),        # 4
		Vector3(s, 0, -2*s),       # 5
		Vector3(-s, 0, 2*s),       # 6
		Vector3(-s, 0, -2*s),      # 7
		Vector3(s, 2*s, 0),        # 8
		Vector3(s, -2*s, 0),       # 9
		Vector3(-s, 2*s, 0),       # 10
		Vector3(-s, -2*s, 0),      # 11
		Vector3(2*s, 0, s),        # 12
		Vector3(2*s, 0, -s),       # 13
		Vector3(-2*s, 0, s),       # 14
		Vector3(-2*s, 0, -s),      # 15
		Vector3(2*s, s, 0),        # 16
		Vector3(2*s, -s, 0),       # 17
		Vector3(-2*s, s, 0),       # 18
		Vector3(-2*s, -s, 0),      # 19
		Vector3(0, 2*s, s),        # 20
		Vector3(0, 2*s, -s),       # 21
		Vector3(0, -2*s, s),       # 22
		Vector3(0, -2*s, -s)       # 23
	]

	# 44 triangular faces
	var faces = [
		[16, 13, 5],   # 0
		[16, 5, 1],    # 1
		[16, 1, 21],   # 2
		[16, 21, 8],   # 3
		[21, 10, 20],  # 4
		[21, 20, 8],   # 5
		[20, 0, 4],    # 6
		[20, 4, 12],   # 7
		[20, 12, 16],  # 8
		[20, 16, 8],   # 9
		[12, 17, 13],  # 10
		[12, 13, 16],  # 11
		[1, 7, 15],    # 12
		[1, 15, 18],   # 13
		[1, 18, 10],   # 14
		[1, 10, 21],   # 15
		[10, 18, 14],  # 16
		[10, 14, 6],   # 17
		[10, 6, 0],    # 18
		[10, 0, 20],   # 19
		[17, 9, 23],   # 20
		[17, 23, 3],   # 21
		[17, 3, 5],    # 22
		[17, 5, 13],   # 23
		[4, 2, 22],    # 24
		[4, 22, 9],    # 25
		[4, 9, 17],    # 26
		[4, 17, 12],   # 27
		[5, 3, 7],     # 28
		[5, 7, 1],     # 29
		[6, 2, 4],     # 30
		[6, 4, 0],     # 31
		[3, 23, 11],   # 32
		[3, 11, 19],   # 33
		[3, 19, 15],   # 34
		[3, 15, 7],    # 35
		[15, 19, 14],  # 36
		[15, 14, 18],  # 37
		[14, 19, 11],  # 38
		[14, 11, 22],  # 39
		[14, 22, 2],   # 40
		[14, 2, 6],    # 41
		[22, 11, 23],  # 42
		[22, 23, 9]    # 43
	]

	var vertex_index = 0
	for face in faces:
		# Calculate face normal
		var v0 = vertices[face[0]]
		var v1 = vertices[face[1]]
		var v2 = vertices[face[2]]
		var edge1 = v1 - v0
		var edge2 = v2 - v0
		var normal = edge1.cross(edge2).normalized()

		# Add 3 vertices for this triangular face
		verts.append(v0)
		normals.append(normal)
		verts.append(v1)
		normals.append(normal)
		verts.append(v2)
		normals.append(normal)

		# Add indices for this triangle
		indices.append_array([vertex_index, vertex_index + 1, vertex_index + 2])
		vertex_index += 3

	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices

	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	return array_mesh

func generate_lattice():
	"""Generate grid positions and transforms for the tessellation"""
	lattice_positions.clear()
	lattice_transforms.clear()
	grid_to_index.clear()

	var spacing = Vector3(cell_size, cell_size, cell_size)

	# Adjust spacing based on tessellation type
	match tessellation_type:
		TessellationType.OCTAHEDRON:
			spacing = Vector3(cell_size * 1.5, cell_size * 1.5, cell_size * 1.5)
		TessellationType.RHOMBIC_DODECAHEDRON:
			spacing = Vector3(cell_size, cell_size, cell_size)
		TessellationType.TRUNCATED_OCTAHEDRON:
			spacing = Vector3(cell_size * 2, cell_size * 2, cell_size * 2)

	# Generate grid
	var index = 0
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			for z in range(grid_size.z):
				var grid_pos = Vector3i(x, y, z)
				lattice_positions.append(grid_pos)
				grid_to_index[grid_pos] = index

				# Calculate world position (centered around origin)
				var world_pos = Vector3(
					(x - grid_size.x / 2.0) * spacing.x,
					(y - grid_size.y / 2.0) * spacing.y,
					(z - grid_size.z / 2.0) * spacing.z
				)

				var transform = Transform3D(Basis.IDENTITY, world_pos)
				lattice_transforms.append(transform)
				index += 1

	print("Generated lattice with ", lattice_positions.size(), " cells")

func generate_walk_path():
	"""Create a TRUE random walk path through the lattice (neighbor to neighbor)"""
	walk_path.clear()

	var visited = {}  # Track visited cells
	var total_cells = lattice_positions.size()

	# Start at a random cell (or center)
	var start_index = randi() % total_cells
	var current_index = start_index

	walk_path.append(current_index)
	visited[current_index] = true

	print("Starting random walk from index ", start_index, " at ", lattice_positions[start_index])

	# Continue until all cells are visited
	while walk_path.size() < total_cells:
		# Get unvisited neighbors
		var neighbors = _get_unvisited_neighbors(current_index, visited)

		if neighbors.size() > 0:
			# Pick a random neighbor and move there
			var next_index = neighbors[randi() % neighbors.size()]
			walk_path.append(next_index)
			visited[next_index] = true
			current_index = next_index
		else:
			# Stuck! Find nearest unvisited cell and jump there
			var next_index = _find_nearest_unvisited(current_index, visited)
			if next_index >= 0:
				walk_path.append(next_index)
				visited[next_index] = true
				current_index = next_index
			else:
				# All cells visited
				break

		# Progress indicator
		if walk_path.size() % 100 == 0:
			print("Walk progress: ", walk_path.size(), " / ", total_cells)

	print("Generated neighbor-based random walk with ", walk_path.size(), " steps")

func _get_unvisited_neighbors(index: int, visited: Dictionary) -> Array[int]:
	"""Get all unvisited neighbors of a cell"""
	var neighbors: Array[int] = []
	var grid_pos = lattice_positions[index]

	# Check all 6 orthogonal neighbors (up/down, left/right, forward/back)
	var offsets = [
		Vector3i(1, 0, 0),
		Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0),
		Vector3i(0, -1, 0),
		Vector3i(0, 0, 1),
		Vector3i(0, 0, -1)
	]

	for offset in offsets:
		var neighbor_pos = grid_pos + offset
		var neighbor_index = _grid_pos_to_index(neighbor_pos)

		if neighbor_index >= 0 and not visited.has(neighbor_index):
			neighbors.append(neighbor_index)

	return neighbors

func _grid_pos_to_index(grid_pos: Vector3i) -> int:
	"""Convert grid position to lattice array index (O(1) lookup)"""
	# Check bounds
	if grid_pos.x < 0 or grid_pos.x >= grid_size.x:
		return -1
	if grid_pos.y < 0 or grid_pos.y >= grid_size.y:
		return -1
	if grid_pos.z < 0 or grid_pos.z >= grid_size.z:
		return -1

	# Fast dictionary lookup
	return grid_to_index.get(grid_pos, -1)

func _find_nearest_unvisited(from_index: int, visited: Dictionary) -> int:
	"""Find nearest unvisited cell (for when walk gets stuck)"""
	var from_pos = lattice_positions[from_index]
	var nearest_index = -1
	var nearest_dist = 999999.0

	for i in range(lattice_positions.size()):
		if not visited.has(i):
			var dist = (lattice_positions[i] - from_pos).length()
			if dist < nearest_dist:
				nearest_dist = dist
				nearest_index = i

	return nearest_index

func setup_multimesh():
	"""Create multimesh for efficient rendering"""
	if multimesh_instance:
		multimesh_instance.queue_free()

	multimesh_instance = MultiMeshInstance3D.new()
	var mm = MultiMesh.new()

	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cell_mesh
	mm.use_colors = true
	mm.instance_count = lattice_transforms.size()

	# Initially set all invisible (scale to 0 or move far away)
	for i in range(lattice_transforms.size()):
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3.ZERO))
		mm.set_instance_color(i, Color.TRANSPARENT)

	multimesh_instance.multimesh = mm

	# Create material
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.emission_enabled = true
	material.emission = color_start
	material.emission_energy_multiplier = emission_strength

	multimesh_instance.material_override = material
	add_child(multimesh_instance)

	print("Multimesh setup complete")

func reveal_next_cell():
	"""Reveal the next cell in the walk path"""
	if current_walk_index >= walk_path.size():
		return

	var lattice_index = walk_path[current_walk_index]
	revealed_indices.append(lattice_index)

	# Update multimesh instance
	var mm = multimesh_instance.multimesh
	mm.set_instance_transform(lattice_index, lattice_transforms[lattice_index])

	# Color based on walk progression
	var t = float(current_walk_index) / float(walk_path.size())
	var color = color_start.lerp(color_end, t)
	mm.set_instance_color(lattice_index, color)

	current_walk_index += 1

	if current_walk_index % 100 == 0:
		print("Revealed ", current_walk_index, " / ", walk_path.size(), " cells")

func reveal_all():
	"""Reveal all cells at once"""
	for i in range(walk_path.size()):
		reveal_next_cell()

func reset_walk():
	"""Reset the walk to the beginning"""
	# Hide all cells
	var mm = multimesh_instance.multimesh
	for i in range(lattice_transforms.size()):
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3.ZERO))
		mm.set_instance_color(i, Color.TRANSPARENT)

	revealed_indices.clear()
	current_walk_index = 0

	# Optionally regenerate walk path
	generate_walk_path()

	print("Walk reset")

## Public API
func pause_walk():
	auto_walk = false

func resume_walk():
	auto_walk = true

func set_tessellation_type(type: TessellationType):
	tessellation_type = type
	create_cell_mesh()
	setup_multimesh()
	reset_walk()

func get_stats() -> Dictionary:
	return {
		"tessellation_type": TessellationType.keys()[tessellation_type],
		"grid_size": grid_size,
		"total_cells": lattice_positions.size(),
		"revealed_cells": revealed_indices.size(),
		"walk_progress": float(current_walk_index) / float(walk_path.size()) if walk_path.size() > 0 else 0.0
	}
