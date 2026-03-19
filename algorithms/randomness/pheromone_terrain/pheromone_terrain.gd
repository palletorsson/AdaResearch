# @identity
# essence: trail(x,y) += deposit; next = argmax(pheromone[neighbors]) with P(random) = 1 - attraction — stigmergy
# desire: watch random walkers leave glowing trails that attract other walkers, building ridges from nothing
# critical_parameter: pheromone_attraction — the probability a walker follows pheromone vs moves randomly (0 = pure random, 1 = pure trail-following)
# triggers: _walk_step() deposits pheromone, raises terrain, then _choose_next_position() balances attraction vs random
# emerges: path networks self-organize — walkers converge on trails they collectively created without communication
# needs: PlaneMesh child with dynamic vertex modification [has]; VR observation [has]; controls [missing]
# relationships: feeds Random_Pheromone map; depends on random walk concept; contrasts with pixel_cloud (self-avoiding vs self-attracting)
# truth: Stigmergy is memory without a brain — the environment itself becomes the communication channel.

extends Node3D

## Pheromone Terrain - Walkers that follow pheromone trails
## Walkers deposit pheromones as they move and are attracted to existing pheromones
## Creates organic, path-like terrain deformation patterns

@export_category("Walker Settings")
@export var walker_count: int = 5
@export var walk_speed: float = 5.0  # Steps per second
@export var raise_amount: float = 0.05  # Height increase per step
@export var max_height: float = 3.0

@export_category("Pheromone Settings")
@export var pheromone_deposit: float = 0.5  # Amount of pheromone deposited per step
@export var pheromone_decay_rate: float = 0.2  # How fast pheromones decay per second
@export var pheromone_attraction: float = 0.3  # 0-1: How much walkers are attracted (vs random)
@export var sensor_distance: int = 2  # How far ahead walkers sense pheromones
@export var pheromone_color: Color = Color(1.0, 0.0, 1.0) # Magenta for "Queer Energy"

@export_category("Terrain Settings")
@export var border_size: int = 10  # Unmanipulated border size (in segments) for walkable edges

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

func _ready() -> void:
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

	# Read dimensions from PlaneMesh before converting
	if mesh_instance.mesh is PlaneMesh:
		var plane_mesh = mesh_instance.mesh as PlaneMesh
		x_segments = plane_mesh.subdivide_width
		y_segments = plane_mesh.subdivide_depth
		# Store size as metadata for later use
		mesh_instance.set_meta("plane_width", plane_mesh.size.x)
		mesh_instance.set_meta("plane_height", plane_mesh.size.y)

	# Convert PrimitiveMesh to ArrayMesh for dynamic modification
	if mesh_instance.mesh is PrimitiveMesh:
		var primitive_mesh = mesh_instance.mesh as PrimitiveMesh
		var array_mesh = ArrayMesh.new()
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, primitive_mesh.get_mesh_arrays())
		
		# Create/Ensure material supports vertex colors
		var material = primitive_mesh.material
		if material:
			if material is StandardMaterial3D:
				material.vertex_color_use_as_albedo = true
			array_mesh.surface_set_material(0, material)
		else:
			# Create default material if none exists
			var new_mat = StandardMaterial3D.new()
			new_mat.vertex_color_use_as_albedo = true
			new_mat.albedo_color = Color.WHITE
			array_mesh.surface_set_material(0, new_mat)
			
		mesh_instance.mesh = array_mesh

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

func _initialize_grids() -> void:
	"""Initialize vertex and pheromone grids"""
	# Use dimensions stored as metadata (set during initialization)
	var plane_width: float = mesh_instance.get_meta("plane_width", 20.0)
	var plane_height: float = mesh_instance.get_meta("plane_height", 20.0)

	# x_segments and y_segments are already set in _ready()
	if x_segments == 0:
		x_segments = 100
	if y_segments == 0:
		y_segments = 100
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

func _build_indices() -> void:
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

func _create_walkers() -> void:
	"""Create walkers at random positions (inside border)"""
	walkers.clear()
	var min_x = border_size
	var max_x = x_segments - border_size
	var min_y = border_size
	var max_y = y_segments - border_size

	for i in range(walker_count):
		walkers.append({
			"x": randi_range(min_x, max_x),
			"y": randi_range(min_y, max_y),
			"active": true
		})

func _process(delta: float) -> void:
	if not mesh_instance or vertex_grid.is_empty():
		return
	
	# Decay pheromones
	_decay_pheromones(delta)
	
	# Update walkers at specified speed
	time_accumulator += delta
	var step_interval = 1.0 / maxf(walk_speed, 0.001)
	var steps_to_run := 0
	while time_accumulator >= step_interval and steps_to_run < 32:
		time_accumulator -= step_interval
		steps_to_run += 1

	if steps_to_run > 0:
		for i in range(steps_to_run):
			_walk_step()
		_update_mesh()

func _decay_pheromones(delta: float) -> void:
	"""Decay all pheromones over time"""
	var decay_amount = pheromone_decay_rate * delta
	for j in range(y_segments + 1):
		for i in range(x_segments + 1):
			if pheromone_grid[j][i] > 0:
				pheromone_grid[j][i] = max(0.0, pheromone_grid[j][i] - decay_amount)

func _walk_step() -> void:
	"""Move walkers based on pheromone attraction"""
	for walker in walkers:
		if not walker.active:
			continue

		# Check if walker is inside the allowed area (not in border)
		if _is_in_border(walker.x, walker.y):
			# Move walker back to allowed area
			walker.x = clamp(walker.x, border_size, x_segments - border_size)
			walker.y = clamp(walker.y, border_size, y_segments - border_size)
			continue

		# Deposit pheromone at current location
		pheromone_grid[walker.y][walker.x] += pheromone_deposit

		# Raise terrain at current location (only if not in border)
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

func _update_mesh() -> void:
	"""Update mesh with modified vertices, normals, and colors"""
	if not mesh_instance:
		return
	
	# Flatten vertex grid to array
	var new_vertices = PackedVector3Array()
	var new_colors = PackedColorArray()
	
	for j in range(vertex_grid.size()):
		var row = vertex_grid[j]
		var pheromone_row = pheromone_grid[j]
		for i in range(row.size()):
			new_vertices.append(row[i])
			
			# Calculate color based on pheromone intensity
			var intensity = clamp(pheromone_row[i], 0.0, 1.0)
			# Base color (white) mixed with pheromone color
			var color = Color.WHITE.lerp(pheromone_color, intensity)
			new_colors.append(color)
	
	var mesh: ArrayMesh = mesh_instance.mesh

	# Save the material before clearing surfaces
	var saved_material = null
	if mesh.get_surface_count() > 0:
		saved_material = mesh.surface_get_material(0)

	# Use SurfaceTool for proper normal generation
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in range(0, indices.size(), 3):
		var idx1 = indices[i]
		var idx2 = indices[i+1]
		var idx3 = indices[i+2]
		
		st.set_color(new_colors[idx1])
		st.add_vertex(new_vertices[idx1])
		
		st.set_color(new_colors[idx2])
		st.add_vertex(new_vertices[idx2])
		
		st.set_color(new_colors[idx3])
		st.add_vertex(new_vertices[idx3])

	st.generate_normals()

	mesh.clear_surfaces()
	st.commit(mesh)

	# Restore the material
	if saved_material:
		mesh.surface_set_material(0, saved_material)

func get_pheromone_at(x: int, y: int) -> float:
	"""Get pheromone level at grid position"""
	if x < 0 or x > x_segments or y < 0 or y > y_segments:
		return 0.0
	return pheromone_grid[y][x]

func reset_terrain() -> void:
	"""Reset terrain and pheromones"""
	for j in range(y_segments + 1):
		for i in range(x_segments + 1):
			vertex_grid[j][i].y = 0.0
			pheromone_grid[j][i] = 0.0
	_update_mesh()

func _is_in_border(x: int, y: int) -> bool:
	"""Check if position is in the border area"""
	return x < border_size or x > x_segments - border_size or \
		   y < border_size or y > y_segments - border_size

func apply_grid_config(config: Dictionary) -> void:
	pass
