class_name SimulatedAnnealingVisualization
extends Node3D

# Simulated Annealing: Thermal Optimization & Cooling Resistance
# Visualizes global optimization through thermal metaphors
# Explores resistance to local optima and gradual constraint tightening

@export_category("Simulated Annealing Configuration")
@export var initial_temperature: float = 100.0
@export var final_temperature: float = 0.1
@export var cooling_rate: float = 0.95
@export var cooling_schedule: String = "exponential"  # exponential, linear, logarithmic, fast
@export var max_iterations: int = 1000
@export var equilibrium_steps: int = 10  # Steps per temperature level

@export_category("Optimization Problem")
@export var problem_type: String = "rastrigin"  # rastrigin, ackley, sphere, rosenbrock, custom
@export var problem_dimensions: int = 2
@export var search_space_size: float = 10.0
@export var num_local_minima: int = 25  # For custom landscapes

@export_category("Visualization")
@export var show_optimization_path: bool = true
@export var show_temperature_trail: bool = true
@export var show_acceptance_decisions: bool = true
@export var show_energy_landscape: bool = true
@export var landscape_resolution: int = 50
@export var trail_length: int = 100

@export_category("Animation")
@export var auto_start: bool = true
@export var step_delay: float = 0.05
@export var show_real_time: bool = true
@export var animate_cooling: bool = true

# Colors for visualization
@export var current_solution_color: Color = Color(0.9, 0.2, 0.2, 1.0)  # Red
@export var best_solution_color: Color = Color(0.2, 0.9, 0.2, 1.0)    # Green
@export var path_color: Color = Color(0.9, 0.9, 0.2, 0.8)             # Yellow
@export var accepted_move_color: Color = Color(0.3, 0.9, 0.3, 0.7)    # Light Green
@export var rejected_move_color: Color = Color(0.9, 0.3, 0.3, 0.7)    # Light Red

# Algorithm state
var current_solution: Array = []
var best_solution: Array = []
var current_energy: float = 0.0
var best_energy: float = INF
var current_temperature: float = 0.0
var current_iteration: int = 0
var equilibrium_count: int = 0

# Algorithm tracking
var is_optimizing: bool = false
var optimization_complete: bool = false
var optimization_timer: Timer
var energy_history: Array = []
var temperature_history: Array = []
var acceptance_history: Array = []

# Visualization elements
var current_solution_marker: MeshInstance3D
var best_solution_marker: MeshInstance3D
var optimization_path: Array = []
var path_line: MeshInstance3D
var landscape_mesh: MeshInstance3D
var ui_display: CanvasLayer

# Statistics
var total_moves: int = 0
var accepted_moves: int = 0
var rejected_moves: int = 0
var improvements: int = 0

func _init():
	name = "SimulatedAnnealing_Visualization"

func _ready():
	setup_ui()
	setup_timer()
	initialize_optimization_problem()
	create_energy_landscape()
	
	if auto_start:
		call_deferred("start_optimization")

func setup_ui():
	"""Create comprehensive UI for Simulated Annealing visualization"""
	ui_display = CanvasLayer.new()
	add_child(ui_display)
	
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.size = Vector2(400, 700)
	panel.position = Vector2(10, 10)
	ui_display.add_child(panel)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Create labels for algorithm information
	for i in range(25):
		var label = Label.new()
		label.name = "info_label_" + str(i)
		label.text = ""
		vbox.add_child(label)
	
	update_ui()

func setup_timer():
	"""Setup timer for optimization animation"""
	optimization_timer = Timer.new()
	optimization_timer.wait_time = step_delay
	optimization_timer.timeout.connect(_on_optimization_timer_timeout)
	add_child(optimization_timer)

func initialize_optimization_problem():
	"""Initialize the optimization problem"""
	# Generate random starting solution
	current_solution.clear()
	for i in range(problem_dimensions):
		current_solution.append(randf_range(-search_space_size, search_space_size))
	
	# Evaluate initial solution
	current_energy = evaluate_objective_function(current_solution)
	best_solution = current_solution.duplicate()
	best_energy = current_energy
	
	# Reset algorithm state
	current_temperature = initial_temperature
	current_iteration = 0
	equilibrium_count = 0
	
	# Clear tracking arrays
	energy_history.clear()
	temperature_history.clear()
	acceptance_history.clear()
	optimization_path.clear()
	
	# Reset statistics
	total_moves = 0
	accepted_moves = 0
	rejected_moves = 0
	improvements = 0
	
	# Add initial point to path
	optimization_path.append(current_solution.duplicate())
	
	print("Initialized ", problem_type, " problem with starting energy: ", current_energy)

func evaluate_objective_function(solution: Array) -> float:
	"""Evaluate the objective function for a given solution"""
	match problem_type:
		"rastrigin":
			return evaluate_rastrigin(solution)
		"ackley":
			return evaluate_ackley(solution)
		"sphere":
			return evaluate_sphere(solution)
		"rosenbrock":
			return evaluate_rosenbrock(solution)
		"custom":
			return evaluate_custom_landscape(solution)
		_:
			return evaluate_rastrigin(solution)

func evaluate_rastrigin(solution: Array) -> float:
	"""Rastrigin function - many local minima"""
	var A = 10.0
	var n = solution.size()
	var sum = A * n
	
	for x in solution:
		sum += x * x - A * cos(2.0 * PI * x)
	
	return sum

func evaluate_ackley(solution: Array) -> float:
	"""Ackley function - highly multimodal"""
	var a = 20.0
	var b = 0.2
	var c = 2.0 * PI
	var n = solution.size()
	
	var sum1 = 0.0
	var sum2 = 0.0
	
	for x in solution:
		sum1 += x * x
		sum2 += cos(c * x)
	
	return -a * exp(-b * sqrt(sum1 / n)) - exp(sum2 / n) + a + exp(1.0)

func evaluate_sphere(solution: Array) -> float:
	"""Sphere function - single global minimum"""
	var sum = 0.0
	for x in solution:
		sum += x * x
	return sum

func evaluate_rosenbrock(solution: Array) -> float:
	"""Rosenbrock function - narrow curved valley"""
	var sum = 0.0
	for i in range(solution.size() - 1):
		var term1 = solution[i + 1] - solution[i] * solution[i]
		var term2 = 1.0 - solution[i]
		sum += 100.0 * term1 * term1 + term2 * term2
	return sum

func evaluate_custom_landscape(solution: Array) -> float:
	"""Custom multi-modal landscape"""
	var energy = 0.0
	
	# Base quadratic term
	for x in solution:
		energy += 0.1 * x * x
	
	# Add multiple local minima
	for i in range(num_local_minima):
		var center_x = randf_range(-search_space_size * 0.8, search_space_size * 0.8)
		var center_y = randf_range(-search_space_size * 0.8, search_space_size * 0.8)
		
		var dist_sq = (solution[0] - center_x) * (solution[0] - center_x)
		if solution.size() > 1:
			dist_sq += (solution[1] - center_y) * (solution[1] - center_y)
		
		energy -= 5.0 * exp(-dist_sq / 2.0)
	
	return energy

func create_energy_landscape():
	"""Create 3D visualization of the energy landscape"""
	if not show_energy_landscape or problem_dimensions != 2:
		return
	
	if landscape_mesh:
		landscape_mesh.queue_free()
	
	landscape_mesh = MeshInstance3D.new()
	var mesh = create_landscape_mesh()
	landscape_mesh.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.3, 0.8, 0.7)
	material.emission_enabled = true
	material.emission = Color(0.1, 0.1, 0.3, 1.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	landscape_mesh.material_override = material
	
	add_child(landscape_mesh)

func create_landscape_mesh() -> ArrayMesh:
	"""Create mesh for energy landscape visualization"""
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	var min_energy = INF
	var max_energy = -INF
	
	# Sample the landscape
	var energy_grid = []
	for i in range(landscape_resolution):
		var row = []
		for j in range(landscape_resolution):
			var x = (i / float(landscape_resolution - 1)) * search_space_size * 2 - search_space_size
			var y = (j / float(landscape_resolution - 1)) * search_space_size * 2 - search_space_size
			
			var energy = evaluate_objective_function([x, y])
			row.append(energy)
			
			min_energy = min(min_energy, energy)
			max_energy = max(max_energy, energy)
		
		energy_grid.append(row)
	
	# Create vertices
	var energy_range = max_energy - min_energy
	if energy_range == 0:
		energy_range = 1.0
	
	for i in range(landscape_resolution):
		for j in range(landscape_resolution):
			var x = (i / float(landscape_resolution - 1)) * search_space_size * 2 - search_space_size
			var y = (j / float(landscape_resolution - 1)) * search_space_size * 2 - search_space_size
			
			var normalized_energy = (energy_grid[i][j] - min_energy) / energy_range
			var z = -normalized_energy * 5.0  # Scale height
			
			vertices.append(Vector3(x, y, z))
			normals.append(Vector3(0, 0, 1))  # Simplified normals
			uvs.append(Vector2(i / float(landscape_resolution), j / float(landscape_resolution)))
	
	# Create triangles
	for i in range(landscape_resolution - 1):
		for j in range(landscape_resolution - 1):
			var idx = i * landscape_resolution + j
			
			# First triangle
			indices.append(idx)
			indices.append(idx + 1)
			indices.append(idx + landscape_resolution)
			
			# Second triangle
			indices.append(idx + 1)
			indices.append(idx + landscape_resolution + 1)
			indices.append(idx + landscape_resolution)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	return array_mesh

func start_optimization():
	"""Start the simulated annealing optimization"""
	if is_optimizing:
		return
	
	is_optimizing = true
	optimization_complete = false
	
	# Initialize visualization markers
	create_solution_markers()
	
	if show_real_time:
		optimization_timer.start()
	else:
		run_full_optimization()
	
	print("Starting simulated annealing optimization...")

func create_solution_markers():
	"""Create visual markers for current and best solutions"""
	# Current solution marker
	if current_solution_marker:
		current_solution_marker.queue_free()
	
	current_solution_marker = MeshInstance3D.new()
	var current_mesh = SphereMesh.new()
	current_mesh.radius = 0.15
	current_mesh.height = 0.3
	current_solution_marker.mesh = current_mesh
	
	var current_material = StandardMaterial3D.new()
	current_material.albedo_color = current_solution_color
	current_material.emission_enabled = true
	current_material.emission = current_solution_color * 0.5
	current_solution_marker.material_override = current_material
	
	update_current_marker_position()
	add_child(current_solution_marker)
	
	# Best solution marker
	if best_solution_marker:
		best_solution_marker.queue_free()
	
	best_solution_marker = MeshInstance3D.new()
	var best_mesh = SphereMesh.new()
	best_mesh.radius = 0.12
	best_mesh.height = 0.24
	best_solution_marker.mesh = best_mesh
	
	var best_material = StandardMaterial3D.new()
	best_material.albedo_color = best_solution_color
	best_material.emission_enabled = true
	best_material.emission = best_solution_color * 0.5
	best_solution_marker.material_override = best_material
	
	update_best_marker_position()
	add_child(best_solution_marker)

func update_current_marker_position():
	"""Update position of current solution marker"""
	if current_solution_marker and current_solution.size() >= 2:
		var z = -evaluate_objective_function(current_solution) * 0.1 + 1.0
		current_solution_marker.position = Vector3(current_solution[0], current_solution[1], z)

func update_best_marker_position():
	"""Update position of best solution marker"""
	if best_solution_marker and best_solution.size() >= 2:
		var z = -evaluate_objective_function(best_solution) * 0.1 + 1.5
		best_solution_marker.position = Vector3(best_solution[0], best_solution[1], z)

func _on_optimization_timer_timeout():
	"""Handle optimization timer timeout"""
	if not is_optimizing:
		return
	
	# Perform one step of simulated annealing
	perform_annealing_step()
	
	# Check termination conditions
	if current_temperature <= final_temperature or current_iteration >= max_iterations:
		finalize_optimization()
	else:
		update_ui()

func perform_annealing_step():
	"""Perform one step of the simulated annealing algorithm"""
	# Generate neighbor solution
	var neighbor_solution = generate_neighbor(current_solution)
	var neighbor_energy = evaluate_objective_function(neighbor_solution)
	
	# Calculate energy difference
	var delta_energy = neighbor_energy - current_energy
	
	# Decide whether to accept the move
	var accept_move = false
	
	if delta_energy < 0:
		# Better solution - always accept
		accept_move = true
		improvements += 1
	else:
		# Worse solution - accept with probability
		var probability = exp(-delta_energy / current_temperature)
		accept_move = randf() < probability
	
	total_moves += 1
	
	# Apply the move if accepted
	if accept_move:
		current_solution = neighbor_solution
		current_energy = neighbor_energy
		accepted_moves += 1
		
		# Update best solution if necessary
		if current_energy < best_energy:
			best_solution = current_solution.duplicate()
			best_energy = current_energy
			update_best_marker_position()
		
		# Add to path
		optimization_path.append(current_solution.duplicate())
		if optimization_path.size() > trail_length:
			optimization_path.pop_front()
		
		update_current_marker_position()
		
		if show_optimization_path:
			update_path_visualization()
	else:
		rejected_moves += 1
	
	# Record statistics
	energy_history.append(current_energy)
	temperature_history.append(current_temperature)
	acceptance_history.append(accept_move)
	
	# Update temperature and iteration counters
	equilibrium_count += 1
	if equilibrium_count >= equilibrium_steps:
		update_temperature()
		equilibrium_count = 0
	
	current_iteration += 1

func generate_neighbor(solution: Array) -> Array:
	"""Generate a neighbor solution"""
	var neighbor = solution.duplicate()
	
	# Random perturbation based on temperature
	var perturbation_strength = current_temperature / initial_temperature * 0.5
	
	for i in range(neighbor.size()):
		var perturbation = randf_range(-perturbation_strength, perturbation_strength)
		neighbor[i] = clamp(neighbor[i] + perturbation, -search_space_size, search_space_size)
	
	return neighbor

func update_temperature():
	"""Update temperature according to cooling schedule"""
	match cooling_schedule:
		"exponential":
			current_temperature *= cooling_rate
		"linear":
			var progress = float(current_iteration) / float(max_iterations)
			current_temperature = initial_temperature * (1.0 - progress)
		"logarithmic":
			current_temperature = initial_temperature / log(2.0 + current_iteration)
		"fast":
			current_temperature = initial_temperature / (1.0 + current_iteration)
		_:
			current_temperature *= cooling_rate

func update_path_visualization():
	"""Update visualization of optimization path"""
	if not show_optimization_path or optimization_path.size() < 2:
		return
	
	if path_line:
		path_line.queue_free()
	
	path_line = MeshInstance3D.new()
	var mesh = create_path_mesh()
	path_line.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = path_color
	material.emission_enabled = true
	material.emission = path_color * 0.3
	material.vertex_color_use_as_albedo = true
	path_line.material_override = material
	
	add_child(path_line)

func create_path_mesh() -> ArrayMesh:
	"""Create mesh for optimization path"""
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var colors = PackedColorArray()
	var indices = PackedInt32Array()
	
	# Create path vertices
	for i in range(optimization_path.size()):
		var point = optimization_path[i]
		if point.size() >= 2:
			var z = -evaluate_objective_function(point) * 0.1 + 0.5
			vertices.append(Vector3(point[0], point[1], z))
			
			# Color gradient based on position in path
			var alpha = float(i) / float(optimization_path.size())
			var color = path_color
			color.a = alpha * 0.8 + 0.2
			colors.append(color)
	
	# Create line indices
	for i in range(vertices.size() - 1):
		indices.append(i)
		indices.append(i + 1)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	
	return array_mesh

func run_full_optimization():
	"""Run full optimization without animation"""
	while current_temperature > final_temperature and current_iteration < max_iterations:
		for step in range(equilibrium_steps):
			perform_annealing_step()
	
	finalize_optimization()

func finalize_optimization():
	"""Finalize the optimization process"""
	is_optimizing = false
	optimization_complete = true
	optimization_timer.stop()
	
	print("Optimization complete!")
	print("Best energy found: ", best_energy)
	print("Best solution: ", best_solution)
	print("Acceptance rate: ", float(accepted_moves) / float(total_moves) * 100.0, "%")
	
	update_ui()

func get_acceptance_rate() -> float:
	"""Get current acceptance rate"""
	if total_moves == 0:
		return 0.0
	return float(accepted_moves) / float(total_moves)

func get_improvement_rate() -> float:
	"""Get rate of improvements"""
	if total_moves == 0:
		return 0.0
	return float(improvements) / float(total_moves)

func update_ui():
	"""Update UI with current algorithm state"""
	if not ui_display:
		return
	
	var labels = []
	for i in range(25):
		var label = ui_display.get_node("Panel/VBoxContainer/info_label_" + str(i))
		if label:
			labels.append(label)
	
	if labels.size() >= 25:
		labels[0].text = "🔥 Simulated Annealing - Thermal Optimization"
		labels[1].text = "Problem: " + problem_type.capitalize()
		labels[2].text = "Dimensions: " + str(problem_dimensions)
		labels[3].text = "Cooling: " + cooling_schedule.capitalize()
		labels[4].text = ""
		labels[5].text = "Status: " + ("Optimizing..." if is_optimizing else "Complete" if optimization_complete else "Ready")
		labels[6].text = "Iteration: " + str(current_iteration) + "/" + str(max_iterations)
		labels[7].text = "Temperature: " + str(current_temperature).pad_decimals(3)
		labels[8].text = "Equilibrium: " + str(equilibrium_count) + "/" + str(equilibrium_steps)
		labels[9].text = ""
		labels[10].text = "Current Energy: " + str(current_energy).pad_decimals(4)
		labels[11].text = "Best Energy: " + str(best_energy).pad_decimals(4)
		labels[12].text = "Energy Improvement: " + str((current_energy - best_energy)).pad_decimals(4)
		labels[13].text = ""
		labels[14].text = "Statistics:"
		labels[15].text = "Total Moves: " + str(total_moves)
		labels[16].text = "Accepted: " + str(accepted_moves) + " (" + str(get_acceptance_rate() * 100).pad_decimals(1) + "%)"
		labels[17].text = "Rejected: " + str(rejected_moves)
		labels[18].text = "Improvements: " + str(improvements) + " (" + str(get_improvement_rate() * 100).pad_decimals(1) + "%)"
		labels[19].text = ""
		labels[20].text = "Controls:"
		labels[21].text = "SPACE - Start/Stop, R - Reset"
		labels[22].text = "1-4 - Change Problem, ↑/↓ - Temperature"
		labels[23].text = ""
		labels[24].text = "🏳️‍🌈 Explores thermal resistance to local optima"

func _input(event):
	"""Handle user input"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				if is_optimizing:
					stop_optimization()
				else:
					start_optimization()
			KEY_R:
				reset_optimization()
			KEY_1:
				change_problem("rastrigin")
			KEY_2:
				change_problem("ackley")
			KEY_3:
				change_problem("sphere")
			KEY_4:
				change_problem("rosenbrock")
			KEY_UP:
				initial_temperature = min(initial_temperature * 1.5, 500.0)
				reset_optimization()
			KEY_DOWN:
				initial_temperature = max(initial_temperature / 1.5, 10.0)
				reset_optimization()

func stop_optimization():
	"""Stop the optimization process"""
	is_optimizing = false
	optimization_timer.stop()

func reset_optimization():
	"""Reset the optimization"""
	stop_optimization()
	optimization_complete = false
	
	# Clear visualization
	if current_solution_marker:
		current_solution_marker.queue_free()
	if best_solution_marker:
		best_solution_marker.queue_free()
	if path_line:
		path_line.queue_free()
	
	initialize_optimization_problem()
	create_energy_landscape()

func change_problem(new_problem: String):
	"""Change the optimization problem"""
	problem_type = new_problem
	reset_optimization()
	print("Changed to ", new_problem, " problem")

func get_algorithm_info() -> Dictionary:
	"""Get comprehensive algorithm information"""
	return {
		"name": "Simulated Annealing",
		"description": "Global optimization through thermal cooling",
		"parameters": {
			"initial_temperature": initial_temperature,
			"final_temperature": final_temperature,
			"cooling_rate": cooling_rate,
			"cooling_schedule": cooling_schedule,
			"max_iterations": max_iterations,
			"equilibrium_steps": equilibrium_steps
		},
		"problem": {
			"type": problem_type,
			"dimensions": problem_dimensions,
			"search_space_size": search_space_size
		},
		"status": {
			"is_optimizing": is_optimizing,
			"optimization_complete": optimization_complete,
			"current_iteration": current_iteration,
			"current_temperature": current_temperature
		},
		"results": {
			"best_energy": best_energy,
			"best_solution": best_solution,
			"current_energy": current_energy,
			"acceptance_rate": get_acceptance_rate(),
			"improvement_rate": get_improvement_rate()
		}
	} 