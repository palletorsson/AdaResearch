extends Node3D

# Multi-Algorithm Sphere Evolution System
# Three different approaches: Cellular Automata, Random Walk, Hill Seeking

@export_enum("Cellular_Automata", "Random_Walk", "Hill_Seeking") var evolution_mode: int = 0
@export var sphere_subdivisions: int = 3
@export var max_iterations: int = 20
@export var auto_evolve: bool = false
@export var evolution_speed: float = 1.0

# Cellular Automata parameters
@export_group("Cellular Automata")
@export var ca_growth_rate: float = 0.15
@export var ca_survival_min: int = 2
@export var ca_survival_max: int = 3
@export var ca_birth_count: int = 3

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
var indices: PackedInt32Array
var original_positions: PackedVector3Array

# Algorithm-specific data
var vertex_states: Array[bool]
var vertex_neighbors: Array[Array]
var walker_positions: PackedVector3Array
var walker_directions: PackedVector3Array
var vertex_expansions: PackedFloat32Array
var hill_peaks: PackedVector3Array

# Evolution tracking
var current_iteration: int = 0
var evolution_timer: Timer
var is_evolving: bool = false
var sphere_material: StandardMaterial3D

func _ready():
	setup_material()
	setup_mesh()
	generate_initial_sphere()
	build_neighbor_topology()
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

func surface_get_arrays_from_mesh(mesh: Mesh) -> Array:
	var a: Array = []
	a.resize(Mesh.ARRAY_MAX)
	var s_arr: Array = mesh.surface_get_arrays(0)
	a[Mesh.ARRAY_VERTEX] = s_arr[Mesh.ARRAY_VERTEX]
	a[Mesh.ARRAY_INDEX] = s_arr[Mesh.ARRAY_INDEX]
	return a

func generate_initial_sphere():
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 1.0
	sphere_mesh.height = 2.0
	sphere_mesh.radial_segments = int(pow(2, sphere_subdivisions)) * 8
	sphere_mesh.rings = int(pow(2, sphere_subdivisions)) * 4
	
	var arrays = surface_get_arrays_from_mesh(sphere_mesh)
	vertices = arrays[Mesh.ARRAY_VERTEX]
	indices = arrays[Mesh.ARRAY_INDEX]
	original_positions = vertices.duplicate()
	
	print("Generated sphere with ", vertices.size(), " vertices")
	update_mesh()

func build_neighbor_topology():
	var vertex_count = vertices.size()
	vertex_neighbors.clear()
	vertex_neighbors.resize(vertex_count)
	
	for i in range(vertex_count):
		vertex_neighbors[i] = []
	
	for i in range(0, indices.size(), 3):
		var v0 = indices[i]
		var v1 = indices[i + 1]
		var v2 = indices[i + 2]
		
		add_unique_neighbor(v0, v1)
		add_unique_neighbor(v0, v2)
		add_unique_neighbor(v1, v0)
		add_unique_neighbor(v1, v2)
		add_unique_neighbor(v2, v0)
		add_unique_neighbor(v2, v1)

func add_unique_neighbor(vertex: int, neighbor: int):
	if not vertex_neighbors[vertex].has(neighbor):
		vertex_neighbors[vertex].append(neighbor)

func initialize_algorithms():
	var vertex_count = vertices.size()
	
	vertex_states.clear()
	vertex_states.resize(vertex_count)
	for i in range(vertex_count):
		vertex_states[i] = randf() > 0.7
	
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
	
	hill_peaks.clear()
	var num_peaks = randi_range(3, 6)
	hill_peaks.resize(num_peaks)
	for i in range(num_peaks):
		hill_peaks[i] = Vector3(
			randf_range(-1.5, 1.5),
			randf_range(-1.5, 1.5),
			randf_range(-1.5, 1.5)
		)

func evolve_cellular_automata():
	var new_states = vertex_states.duplicate()
	
	for i in range(vertices.size()):
		var alive_neighbors = count_alive_neighbors(i)
		var current_state = vertex_states[i]
		
		if current_state:
			new_states[i] = (alive_neighbors >= ca_survival_min and alive_neighbors <= ca_survival_max)
		else:
			new_states[i] = (alive_neighbors == ca_birth_count)
	
	vertex_states = new_states
	
	for i in range(vertices.size()):
		var original_pos = original_positions[i]
		var direction = original_pos.normalized()
		
		if vertex_states[i]:
			var growth = direction * ca_growth_rate * (1.0 + current_iteration * 0.05)
			vertices[i] = original_pos + growth
		else:
			var shrink = direction * ca_growth_rate * 0.2
			vertices[i] = original_pos - shrink
		
		var noise_offset = Vector3(
			randf_range(-0.01, 0.01),
			randf_range(-0.01, 0.01),
			randf_range(-0.01, 0.01)
		) * current_iteration * 0.05
		
		vertices[i] += noise_offset

func count_alive_neighbors(vertex_index: int) -> int:
	var count = 0
	for neighbor_idx in vertex_neighbors[vertex_index]:
		if vertex_states[neighbor_idx]:
			count += 1
	return count

func evolve_random_walk():
	for i in range(vertices.size()):
		var current_direction = walker_directions[i]
		var direction_change = Vector3(
			randf_range(-walk_direction_change, walk_direction_change),
			randf_range(-walk_direction_change, walk_direction_change),
			randf_range(-walk_direction_change, walk_direction_change)
		)
		
		walker_directions[i] = (current_direction + direction_change).normalized()
		walker_positions[i] += walker_directions[i] * walk_step_size
		vertex_expansions[i] += walk_expansion_rate
		
		var original_pos = original_positions[i]
		var expansion_direction = original_pos.normalized()
		var expansion = expansion_direction * vertex_expansions[i]
		var walk_offset = (walker_positions[i] - original_positions[i]) * 0.25
		
		vertices[i] = original_pos + expansion + walk_offset

func evolve_hill_seeking():
	for i in range(vertices.size()):
		var current_pos = vertices[i]
		var total_force = Vector3.ZERO
		var nearest_peak_distance = INF
		
		for peak in hill_peaks:
			var to_peak = peak - current_pos
			var distance = to_peak.length()
			
			if distance < nearest_peak_distance:
				nearest_peak_distance = distance
			
			if distance > 0.01 and distance < hill_seek_radius:
				var attraction = hill_seek_strength * pow(1.0 / distance, hill_attraction_power)
				total_force += to_peak.normalized() * attraction
		
		vertices[i] += total_force
		
		if nearest_peak_distance < hill_seek_radius:
			var expansion_factor = 1.0 - (nearest_peak_distance / hill_seek_radius)
			var radial_expansion = original_positions[i].normalized() * expansion_factor * 0.08
			vertices[i] += radial_expansion

func update_mesh():
	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var normals = calculate_smooth_normals()
	arrays[Mesh.ARRAY_NORMAL] = normals
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if array_mesh.get_surface_count() > 0:
		mesh_instance.mesh = array_mesh

func calculate_smooth_normals() -> PackedVector3Array:
	var normals = PackedVector3Array()
	normals.resize(vertices.size())
	
	for i in range(vertices.size()):
		normals[i] = Vector3.ZERO
	
	for i in range(0, indices.size(), 3):
		var v0 = indices[i]
		var v1 = indices[i + 1]
		var v2 = indices[i + 2]
		
		var edge1 = vertices[v1] - vertices[v0]
		var edge2 = vertices[v2] - vertices[v0]
		var face_normal = edge1.cross(edge2).normalized()
		
		normals[v0] += face_normal
		normals[v1] += face_normal
		normals[v2] += face_normal
	
	for i in range(vertices.size()):
		normals[i] = normals[i].normalized()
	
	return normals

func start_evolution():
	if not is_evolving:
		is_evolving = true
		current_iteration = 0
		evolution_timer.start()
		
		var mode_names = ["Cellular Automata", "Random Walk", "Hill Seeking"]
		print("Starting evolution: ", mode_names[evolution_mode])

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
	sphere_material.albedo_color = Color(0.2, 0.6, 0.8, 1.0)
	print("Sphere reset")

func single_evolution_step():
	if current_iteration < max_iterations:
		match evolution_mode:
			0:
				evolve_cellular_automata()
			1:
				evolve_random_walk()
			2:
				evolve_hill_seeking()
		
		update_mesh()
		current_iteration += 1
		
		var progress = float(current_iteration) / max_iterations
		var colors = [Color.CYAN, Color.GREEN, Color.ORANGE]
		var target_color = colors[evolution_mode]
		sphere_material.albedo_color = Color.WHITE.lerp(target_color, progress * 0.7)
		
		print("Step: ", current_iteration, "/", max_iterations)
		
		if current_iteration >= max_iterations:
			stop_evolution()
			print("Evolution complete!")

func _on_evolution_step():
	single_evolution_step()

func set_evolution_mode(mode: int):
	evolution_mode = mode
	reset_sphere()
	var mode_names = ["Cellular Automata", "Random Walk", "Hill Seeking"]
	print("Switched to: ", mode_names[evolution_mode])

func _input(event):
	if event.is_action_pressed("ui_accept"):
		single_evolution_step()
	elif event.is_action_pressed("ui_cancel"):
		reset_sphere()
	elif event.is_action_pressed("ui_select"):
		if is_evolving:
			stop_evolution()
		else:
			start_evolution()
	elif event.is_action_pressed("ui_up"):
		evolution_mode = (evolution_mode + 1) % 3
		set_evolution_mode(evolution_mode)
	elif event.is_action_pressed("ui_down"):
		evolution_mode = (evolution_mode - 1 + 3) % 3
		set_evolution_mode(evolution_mode)
