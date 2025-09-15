extends Node3D

# Multi-Algorithm Sphere Evolution System
# Three different approaches: Cellular Automata, Random Walk, Hill Seeking

@export_enum("Cellular_Automata", "Random_Walk", "Hill_Seeking") var evolution_mode: int = 0
@export var sphere_subdivisions: int = 4
@export var max_iterations: int = 20
@export var auto_evolve: bool = false
@export var evolution_speed: float = 1.0

# Cellular Automata parameters
@export_group("Cellular Automata")
@export var ca_growth_rate: float = 0.1
@export var ca_neighbor_threshold: int = 3

# Random Walk parameters
@export_group("Random Walk")
@export var walk_step_size: float = 0.05
@export var walk_expansion_rate: float = 0.02
@export var walk_direction_change: float = 0.3

# Hill Seeking parameters
@export_group("Hill Seeking")
@export var hill_seek_strength: float = 0.08
@export var hill_seek_radius: float = 0.5
@export var hill_attraction_power: float = 2.0

# Mesh components
var mesh_instance: MeshInstance3D
var vertices: PackedVector3Array
var original_positions: PackedVector3Array

# Algorithm-specific data
var vertex_states: Array[bool]  # CA states
var vertex_neighbors: Array[Array]  # CA neighbors
var walker_positions: PackedVector3Array  # Random walk current positions
var walker_directions: PackedVector3Array  # Random walk directions
var vertex_expansions: PackedFloat32Array  # Expansion amounts
var hill_peaks: PackedVector3Array  # Hill seeking targets

# Evolution tracking
var current_iteration: int = 0
var evolution_timer: Timer
var is_evolving: bool = false

# Material
var sphere_material: StandardMaterial3D

func _ready():
	setup_material()
	setup_mesh()
	generate_initial_sphere()
	initialize_algorithms()
	setup_evolution_timer()

func setup_material():
	sphere_material = StandardMaterial3D.new()
	sphere_material.albedo_color = Color(0.2, 0.6, 0.8, 1.0)
	sphere_material.metallic = 0.3
	sphere_material.roughness = 0.4
	sphere_material.emission_enabled = true
	sphere_material.emission = Color(0.1, 0.3, 0.4) * 0.2

func setup_mesh():
	mesh_instance = MeshInstance3D.new()
	mesh_instance.material_override = sphere_material
	add_child(mesh_instance)

func setup_evolution_timer():
	evolution_timer = Timer.new()
	evolution_timer.wait_time = 1.0 / evolution_speed
	evolution_timer.timeout.connect(_on_evolution_step)
	add_child(evolution_timer)
	
	if auto_evolve:
		start_evolution()

func generate_initial_sphere():
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 1.0
	sphere_mesh.height = 2.0
	sphere_mesh.radial_segments = pow(2, sphere_subdivisions) * 8
	sphere_mesh.rings = pow(2, sphere_subdivisions) * 4
	
	var arrays = sphere_mesh.surface_get_arrays(0)
	vertices = arrays[Mesh.ARRAY_VERTEX]
	original_positions = vertices.duplicate()
	
	update_mesh()

func initialize_algorithms():
	var vertex_count = vertices.size()
	
	# Initialize Cellular Automata
	vertex_states.clear()
	vertex_states.resize(vertex_count)
	vertex_neighbors.clear()
	vertex_neighbors.resize(vertex_count)
	
	for i in range(vertex_count):
		vertex_states[i] = randf() > 0.5
	
	calculate_vertex_neighbors()
	
	# Initialize Random Walk
	walker_positions = original_positions.duplicate()
	walker_directions.clear()
	walker_directions.resize(vertex_count)
	vertex_expansions.clear()
	vertex_expansions.resize(vertex_count)
	
	for i in range(vertex_count):
		walker_directions[i] = Vector3(
			randf_range(-1, 1),
			randf_range(-1, 1),
			randf_range(-1, 1)
		).normalized()
		vertex_expansions[i] = 0.0
	
	# Initialize Hill Seeking
	hill_peaks.clear()
	hill_peaks.resize(randi_range(3, 8))  # Random number of peaks
	
	for i in range(hill_peaks.size()):
		hill_peaks[i] = Vector3(
			randf_range(-2, 2),
			randf_range(-2, 2),
			randf_range(-2, 2)
		)

func calculate_vertex_neighbors():
	var neighbor_distance = 0.3
	
	for i in range(vertices.size()):
		vertex_neighbors[i] = []
		var current_vertex = vertices[i]
		
		for j in range(vertices.size()):
			if i == j:
				continue
			
			var distance = current_vertex.distance_to(vertices[j])
			if distance < neighbor_distance:
				vertex_neighbors[i].append(j)

# CELLULAR AUTOMATA ALGORITHM
func evolve_cellular_automata():
	# Apply CA rules in chunks to avoid blocking
	var new_states = vertex_states.duplicate()
	var chunk_size = 50  # Process 50 vertices at a time
	
	for start_idx in range(0, vertices.size(), chunk_size):
		var end_idx = min(start_idx + chunk_size, vertices.size())
		
		for i in range(start_idx, end_idx):
			var alive_neighbors = count_alive_neighbors(i)
			var current_state = vertex_states[i]
			
			if current_state:
				new_states[i] = alive_neighbors >= 2 and alive_neighbors <= ca_neighbor_threshold + 1
			else:
				new_states[i] = alive_neighbors == ca_neighbor_threshold
		
		# Yield control after each chunk
		if end_idx < vertices.size():
			await get_tree().process_frame
	
	vertex_states = new_states
	
	# Move vertices based on CA state in chunks
	for start_idx in range(0, vertices.size(), chunk_size):
		var end_idx = min(start_idx + chunk_size, vertices.size())
		
		for i in range(start_idx, end_idx):
			var original_pos = original_positions[i]
			var direction = original_pos.normalized()
			
			if vertex_states[i]:
				var growth = direction * ca_growth_rate * (current_iteration + 1) * 0.1
				vertices[i] = original_pos + growth
			else:
				var shrink = direction * ca_growth_rate * 0.3
				vertices[i] = original_pos - shrink
			
			# Add organic variation
			var noise_offset = Vector3(
				randf_range(-0.02, 0.02),
				randf_range(-0.02, 0.02),
				randf_range(-0.02, 0.02)
			) * current_iteration * 0.1
			
			vertices[i] += noise_offset
		
		# Yield control after each chunk
		if end_idx < vertices.size():
			await get_tree().process_frame

func count_alive_neighbors(vertex_index: int) -> int:
	var count = 0
	for neighbor_idx in vertex_neighbors[vertex_index]:
		if vertex_states[neighbor_idx]:
			count += 1
	return count

# RANDOM WALK ALGORITHM
func evolve_random_walk():
	var chunk_size = 50  # Process 50 vertices at a time
	
	for start_idx in range(0, vertices.size(), chunk_size):
		var end_idx = min(start_idx + chunk_size, vertices.size())
		
		for i in range(start_idx, end_idx):
			# Random walk step
			var current_direction = walker_directions[i]
			
			# Add random direction change
			var direction_change = Vector3(
				randf_range(-walk_direction_change, walk_direction_change),
				randf_range(-walk_direction_change, walk_direction_change),
				randf_range(-walk_direction_change, walk_direction_change)
			)
			
			walker_directions[i] = (current_direction + direction_change).normalized()
			
			# Take a step
			walker_positions[i] += walker_directions[i] * walk_step_size
			
			# Each step increases expansion
			vertex_expansions[i] += walk_expansion_rate
			
			# Apply expansion from original position
			var original_pos = original_positions[i]
			var expansion_direction = original_pos.normalized()
			var expansion_amount = vertex_expansions[i]
			
			# Combine walk position with radial expansion
			var base_expansion = original_pos + expansion_direction * expansion_amount
			var walk_offset = walker_positions[i] - original_positions[i]
			
			vertices[i] = base_expansion + walk_offset * 0.3  # Dampen walk influence
		
		# Yield control after each chunk
		if end_idx < vertices.size():
			await get_tree().process_frame

# HILL SEEKING ALGORITHM
func evolve_hill_seeking():
	var chunk_size = 50  # Process 50 vertices at a time
	
	for start_idx in range(0, vertices.size(), chunk_size):
		var end_idx = min(start_idx + chunk_size, vertices.size())
		
		for i in range(start_idx, end_idx):
			var current_pos = vertices[i]
			var total_force = Vector3.ZERO
			
			# Calculate attraction to all hill peaks
			for peak in hill_peaks:
				var to_peak = peak - current_pos
				var distance = to_peak.length()
				
				if distance < hill_seek_radius and distance > 0.01:
					# Stronger attraction to closer peaks
					var attraction_strength = hill_seek_strength * pow(1.0 / distance, hill_attraction_power)
					var attraction_force = to_peak.normalized() * attraction_strength
					total_force += attraction_force
			
			# Apply force
			vertices[i] += total_force
			
			# Also apply some radial expansion based on distance to nearest peak
			var nearest_peak_distance = INF
			for peak in hill_peaks:
				var distance = current_pos.distance_to(peak)
				if distance < nearest_peak_distance:
					nearest_peak_distance = distance
			
			# Vertices closer to peaks expand more
			if nearest_peak_distance < hill_seek_radius:
				var expansion_factor = 1.0 - (nearest_peak_distance / hill_seek_radius)
				var radial_expansion = original_positions[i].normalized() * expansion_factor * 0.1
				vertices[i] += radial_expansion
		
		# Yield control after each chunk
		if end_idx < vertices.size():
			await get_tree().process_frame

func update_mesh():
	# Defer mesh update to avoid blocking
	call_deferred("_update_mesh_async")

func _update_mesh_async():
	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	
	var indices = PackedInt32Array()
	generate_mesh_indices(indices)
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var normals = calculate_normals()
	arrays[Mesh.ARRAY_NORMAL] = normals
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = array_mesh

func generate_mesh_indices(indices: PackedInt32Array):
	var vertex_count = vertices.size()
	
	for i in range(vertex_count):
		var neighbors = vertex_neighbors[i]
		
		for j in range(neighbors.size()):
			var next_j = (j + 1) % neighbors.size()
			if j < neighbors.size() - 1:
				indices.append(i)
				indices.append(neighbors[j])
				indices.append(neighbors[next_j])

func calculate_normals() -> PackedVector3Array:
	var normals = PackedVector3Array()
	normals.resize(vertices.size())
	
	for i in range(vertices.size()):
		normals[i] = vertices[i].normalized()
	
	return normals

func start_evolution():
	if not is_evolving:
		is_evolving = true
		current_iteration = 0
		evolution_timer.start()
		
		var mode_names = ["Cellular Automata", "Random Walk", "Hill Seeking"]
		print("Starting evolution with: ", mode_names[evolution_mode])

func stop_evolution():
	if is_evolving:
		is_evolving = false
		evolution_timer.stop()
		print("Evolution stopped at iteration: ", current_iteration)

func reset_sphere():
	vertices = original_positions.duplicate()
	current_iteration = 0
	initialize_algorithms()
	update_mesh()
	print("Sphere reset to original state")

func single_evolution_step():
	if current_iteration < max_iterations:
		# Apply the selected algorithm asynchronously
		call_deferred("_apply_evolution_algorithm")
		
		current_iteration += 1
		
		# Update material color
		var progress = float(current_iteration) / max_iterations
		var colors = [Color.BLUE, Color.GREEN, Color.ORANGE]  # Different color per algorithm
		var target_color = colors[evolution_mode]
		var color = Color.WHITE.lerp(target_color, progress)
		sphere_material.albedo_color = color
		
		print("Evolution step: ", current_iteration, "/", max_iterations)
		
		if current_iteration >= max_iterations:
			stop_evolution()
			print("Evolution complete!")

func _apply_evolution_algorithm():
	"""Apply the selected evolution algorithm asynchronously"""
	match evolution_mode:
		0:  # Cellular Automata
			evolve_cellular_automata()
		1:  # Random Walk
			evolve_random_walk()
		2:  # Hill Seeking
			evolve_hill_seeking()
	
	# Update mesh asynchronously
	call_deferred("update_mesh")

func _on_evolution_step():
	single_evolution_step()

# Public interface
func set_evolution_mode(mode: int):
	evolution_mode = mode
	reset_sphere()
	var mode_names = ["Cellular Automata", "Random Walk", "Hill Seeking"]
	print("Switched to: ", mode_names[evolution_mode])

func evolve_one_step():
	single_evolution_step()

# Input handling
func _input(event):
	if event.is_action_pressed("ui_accept"):  # Space
		evolve_one_step()
	elif event.is_action_pressed("ui_cancel"):  # Escape
		reset_sphere()
	elif event.is_action_pressed("ui_select"):  # Enter
		if is_evolving:
			stop_evolution()
		else:
			start_evolution()
	elif event.is_action_pressed("ui_up"):  # Up arrow
		evolution_mode = (evolution_mode + 1) % 3
		set_evolution_mode(evolution_mode)
	elif event.is_action_pressed("ui_down"):  # Down arrow
		evolution_mode = (evolution_mode - 1) % 3
		if evolution_mode < 0:
			evolution_mode = 2
		set_evolution_mode(evolution_mode)
