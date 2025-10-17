extends Node3D

## Pheromone Terrain - Walkers that follow pheromone trails
## Walkers deposit pheromones as they move and are attracted to existing pheromones
## Creates organic, path-like terrain deformation patterns

@export_category("Walker Settings")
@export var walker_count: int = 5
@export var walk_speed: float = 2.0  # Steps per second
@export var raise_amount: float = 0.05  # Height increase per step
@export var max_height: float = 3.0

@export_category("Pheromone Settings")
@export var pheromone_deposit: float = 1.0  # Amount of pheromone deposited per step
@export var pheromone_decay_rate: float = 0.1  # How fast pheromones decay per second
@export var pheromone_attraction: float = 0.7  # 0-1: How much walkers are attracted (vs random)
@export var sensor_distance: int = 2  # How far ahead walkers sense pheromones

@onready var plane_node = $Plane

# Grid data
var x_segments: int
var y_segments: int
var vertex_grid: Array = []
var pheromone_grid: Array = []
var indices: PackedInt32Array

# Walker data
var walkers: Array = []
var mesh_instance: MeshInstance3D
var time_accumulator: float = 0.0

func _ready():
	set_process(false)
	await get_tree().process_frame
	await get_tree().process_frame
	
	if not plane_node:
		push_error("Pheromoneterrain: No 'Plane' child node found!")
		return
	
	# Find mesh instance
	mesh_instance = _find_mesh_instance(plane_node)
	if not mesh_instance:
		push_error("PheromoneeTerrain: No MeshInstance3D found!")
		return
	
	_initialize_grids()
	_create_walkers()
	
	set_process(true)
	print("PheromoneeTerrain: Initialized with %d walkers on %dx%d grid" % [walker_count, x_segments, y_segments])

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	"""Recursively find MeshInstance3D"""
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		if child is MeshInstance3D:
			return child
		var result = _find_mesh_instance(child)
		if result:
			return result
	return null

func _initialize_grids():
	"""Initialize vertex and pheromone grids"""
	# PlaneMesh doesn't have x_segments/y_segments, so we'll use reasonable defaults
	x_segments = 50  # Default grid resolution
	y_segments = 50  # Default grid resolution
	
	# PlaneMesh doesn't have width/height properties, so we'll use reasonable defaults
	var plane_width = 20.0  # Default plane width
	var plane_height = 20.0  # Default plane height
	var half_width = plane_width / 2.0
	var half_height = plane_height / 2.0
	var x_step = plane_width / float(x_segments)
	var y_step = plane_height / float(y_segments)
	
	# Build vertex grid
	vertex_grid.clear()
	pheromone_grid.clear()
	
	for j in range(y_segments + 1):
		var vertex_row = []
		var pheromone_row = []
		for i in range(x_segments + 1):
			var x = -half_width + i * x_step
			var z = half_height - j * y_step
			vertex_row.append(Vector3(x, 0, z))
			pheromone_row.append(0.0)  # Start with no pheromones
		vertex_grid.append(vertex_row)
		pheromone_grid.append(pheromone_row)
	
	# Build indices
	_build_indices()

func _build_indices():
	"""Build triangle indices"""
	indices.clear()
	for j in range(y_segments):
		for i in range(x_segments):
			var a = j * (x_segments + 1) + i
			var b = a + 1
			var c = (j + 1) * (x_segments + 1) + i
			var d = c + 1
			# CCW winding
			indices.append(a)
			indices.append(c)
			indices.append(b)
			indices.append(b)
			indices.append(c)
			indices.append(d)

func _create_walkers():
	"""Create walkers at random positions"""
	walkers.clear()
	for i in range(walker_count):
		walkers.append({
			"x": randi_range(0, x_segments),
			"y": randi_range(0, y_segments),
			"active": true
		})

func _process(delta: float):
	if not mesh_instance or vertex_grid.is_empty():
		return
	
	# Decay pheromones
	_decay_pheromones(delta)
	
	# Update walkers at specified speed
	time_accumulator += delta
	var step_interval = 1.0 / walk_speed
	
	if time_accumulator >= step_interval:
		time_accumulator = 0.0
		_walk_step()
		_update_mesh()

func _decay_pheromones(delta: float):
	"""Decay all pheromones over time"""
	var decay_amount = pheromone_decay_rate * delta
	for j in range(y_segments + 1):
		for i in range(x_segments + 1):
			if pheromone_grid[j][i] > 0:
				pheromone_grid[j][i] = max(0.0, pheromone_grid[j][i] - decay_amount)

func _walk_step():
	"""Move walkers based on pheromone attraction"""
	for walker in walkers:
		if not walker.active:
			continue
		
		# Deposit pheromone at current location
		pheromone_grid[walker.y][walker.x] += pheromone_deposit
		
		# Raise terrain at current location
		var current_vertex = vertex_grid[walker.y][walker.x]
		if current_vertex.y < max_height:
			current_vertex.y += raise_amount
			vertex_grid[walker.y][walker.x] = current_vertex
		
		# Decide next move based on pheromones
		var next_pos = _choose_next_position(walker.x, walker.y)
		walker.x = next_pos.x
		walker.y = next_pos.y

func _choose_next_position(x: int, y: int) -> Vector2i:
	"""Choose next position based on pheromone concentration"""
	# Get possible directions (8-way movement)
	var directions = [
		Vector2i(1, 0),   # Right
		Vector2i(-1, 0),  # Left
		Vector2i(0, 1),   # Down
		Vector2i(0, -1),  # Up
		Vector2i(1, 1),   # Down-right
		Vector2i(-1, 1),  # Down-left
		Vector2i(1, -1),  # Up-right
		Vector2i(-1, -1)  # Up-left
	]
	
	# Use pheromone attraction vs random choice
	if randf() < pheromone_attraction:
		# Follow pheromones - sense ahead and pick highest concentration
		var best_dir = directions[0]
		var best_pheromone = -1.0
		
		for dir in directions:
			var sense_x = x + dir.x * sensor_distance
			var sense_y = y + dir.y * sensor_distance
			
			# Check bounds
			if sense_x < 0 or sense_x > x_segments or sense_y < 0 or sense_y > y_segments:
				continue
			
			var pheromone_level = pheromone_grid[sense_y][sense_x]
			if pheromone_level > best_pheromone:
				best_pheromone = pheromone_level
				best_dir = dir
		
		# Move one step in the best direction
		var new_x = clamp(x + best_dir.x, 0, x_segments)
		var new_y = clamp(y + best_dir.y, 0, y_segments)
		return Vector2i(new_x, new_y)
	else:
		# Random movement
		var dir = directions[randi() % directions.size()]
		var new_x = clamp(x + dir.x, 0, x_segments)
		var new_y = clamp(y + dir.y, 0, y_segments)
		return Vector2i(new_x, new_y)

func _update_mesh():
	"""Update mesh with modified vertices and proper normals"""
	if not mesh_instance:
		return
	
	# Flatten vertex grid to array
	var new_vertices = PackedVector3Array()
	for row in vertex_grid:
		for vertex in row:
			new_vertices.append(vertex)
	
	var mesh: ArrayMesh = mesh_instance.mesh
	
	# Use SurfaceTool for proper normal generation
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for i in range(0, indices.size(), 3):
		st.add_vertex(new_vertices[indices[i]])
		st.add_vertex(new_vertices[indices[i + 1]])
		st.add_vertex(new_vertices[indices[i + 2]])
	
	st.generate_normals()
	
	mesh.clear_surfaces()
	st.commit(mesh)
	
	# Preserve material
	if mesh_instance.material_override:
		mesh.surface_set_material(0, mesh_instance.material_override)

func get_pheromone_at(x: int, y: int) -> float:
	"""Get pheromone level at grid position"""
	if x < 0 or x > x_segments or y < 0 or y > y_segments:
		return 0.0
	return pheromone_grid[y][x]

func reset_terrain():
	"""Reset terrain and pheromones"""
	for j in range(y_segments + 1):
		for i in range(x_segments + 1):
			vertex_grid[j][i].y = 0.0
			pheromone_grid[j][i] = 0.0
	_update_mesh()
