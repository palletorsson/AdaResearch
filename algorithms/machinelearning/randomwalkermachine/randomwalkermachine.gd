# Main.gd - Attach to a Node3D in your main scene
extends Node3D

# Noise and sampling
var noise = FastNoiseLite.new()
var circle_radius = 10.0
var target_points = []
var walker_agents = []
var num_walkers = 300

# ML-inspired parameters
var learning_rate = 0.1
var temperature = 2.0  # Randomness control
var exploration_rate = 0.3

# Visualization
var target_material: StandardMaterial3D
var walker_material: StandardMaterial3D
var trail_material: StandardMaterial3D

class RandomWalker:
	var position: Vector3
	var target: Vector3
	var velocity: Vector3
	var trail_points: Array[Vector3] = []
	var fitness: float = 0.0
	var neural_weights: Array[float] = []
	var exploration_noise: float
	
	func _init(start_pos: Vector3, target_pos: Vector3):
		position = start_pos
		target = target_pos
		velocity = Vector3.ZERO
		exploration_noise = randf_range(0.1, 0.5)
		
		# Simple neural network weights (input: distance vector, output: movement direction)
		for i in range(12):  # 3 inputs -> 4 hidden -> 3 outputs
			neural_weights.append(randf_range(-1.0, 1.0))
	
	func update_position(temperature: float) -> Vector3:
		# Calculate input (normalized distance to target)
		var distance_vector = (target - position).normalized()
		
		# Simple neural network forward pass
		var hidden = Vector4()
		hidden.x = tanh(neural_weights[0] * distance_vector.x + neural_weights[1] * distance_vector.y + neural_weights[2] * distance_vector.z)
		hidden.y = tanh(neural_weights[3] * distance_vector.x + neural_weights[4] * distance_vector.y + neural_weights[5] * distance_vector.z)
		hidden.z = tanh(neural_weights[6] * distance_vector.x + neural_weights[7] * distance_vector.y + neural_weights[8] * distance_vector.z)
		hidden.w = tanh(neural_weights[9] * distance_vector.x + neural_weights[10] * distance_vector.y + neural_weights[11] * distance_vector.z)
		
		# Output layer (movement direction)
		var movement = Vector3()
		movement.x = tanh(hidden.x * 0.5 + hidden.y * 0.3)
		movement.y = tanh(hidden.z * 0.5 + hidden.w * 0.3)
		movement.z = tanh(hidden.x * 0.3 + hidden.z * 0.5)
		
		# Add randomness based on temperature
		var random_factor = Vector3(
			randf_range(-1, 1) * temperature * exploration_noise,
			randf_range(-1, 1) * temperature * exploration_noise,
			randf_range(-1, 1) * temperature * exploration_noise
		)
		
		movement += random_factor
		velocity = velocity * 0.8 + movement * 0.3  # Momentum
		
		var new_position = position + velocity * 0.1
		trail_points.append(position)
		if trail_points.size() > 50:  # Limit trail length
			trail_points.pop_front()
		
		position = new_position
		
		# Update fitness (inverse distance to target)
		fitness = 1.0 / (1.0 + position.distance_to(target))
		
		return position

func _ready():
	setup_noise()
	generate_target_points()
	create_walker_agents()
	setup_materials()
	visualize_targets()

func setup_noise():
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.1
	noise.seed = randi()

func generate_target_points():
	# Sample 100 points on a noise-disturbed circle
	for i in range(100):
		var angle = (i / 100.0) * TAU
		var base_x = cos(angle) * circle_radius
		var base_z = sin(angle) * circle_radius
		
		# Add noise displacement
		var noise_offset = noise.get_noise_2d(base_x, base_z) * 2.0
		var noise_height = noise.get_noise_2d(base_x + 100, base_z + 100) * 3.0
		
		var target_point = Vector3(
			base_x + noise_offset,
			noise_height,
			base_z + noise_offset
		)
		target_points.append(target_point)

func create_walker_agents():
	# Create 100 random walkers starting from center
	for i in range(num_walkers):
		var start_position = Vector3.ZERO  # Always start from center
		var target = target_points[i % target_points.size()]
		var walker = RandomWalker.new(start_position, target)
		walker_agents.append(walker)

func setup_materials():
	target_material = StandardMaterial3D.new()
	target_material.albedo_color = Color.CYAN
	target_material.emission = Color.CYAN * 0.3
	
	walker_material = StandardMaterial3D.new()
	walker_material.albedo_color = Color.RED
	walker_material.emission = Color.RED * 0.2
	
	trail_material = StandardMaterial3D.new()
	trail_material.albedo_color = Color.YELLOW
	trail_material.emission = Color.YELLOW * 0.1

func visualize_targets():
	# Create target spheres
	for i in range(target_points.size()):
		var mesh_instance = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.1
		mesh_instance.mesh = sphere
		mesh_instance.material_override = target_material
		mesh_instance.position = target_points[i]
		add_child(mesh_instance)

func _process(delta):
	# Update all walkers
	update_walkers()
	
	# Evolutionary learning every 100 frames
	if Engine.get_process_frames() % 200 == 0:
		evolve_walkers()
	
	# Dynamic temperature control
	temperature = 1.0 + sin(Time.get_time_dict_from_system()["second"] * 0.1) * 0.5
	
	# Visualize walkers and trails
	visualize_walkers()

func update_walkers():
	for walker in walker_agents:
		walker.update_position(temperature)

func evolve_walkers():
	# Sort walkers by fitness
	walker_agents.sort_custom(func(a, b): return a.fitness > b.fitness)
	
	# Keep top 30%, mutate middle 40%, replace bottom 30%
	var top_count = int(walker_agents.size() * 0.3)
	var middle_count = int(walker_agents.size() * 0.4)
	
	# Reset ALL walkers to center for next round
	for walker in walker_agents:
		walker.position = Vector3.ZERO  # Start from center each round
		walker.velocity = Vector3.ZERO
		walker.trail_points.clear()
		walker.fitness = 0.0
	
	# Mutate middle performers
	for i in range(top_count, top_count + middle_count):
		var walker = walker_agents[i]
		for j in range(walker.neural_weights.size()):
			if randf() < 0.3:  # 30% mutation rate
				walker.neural_weights[j] += randf_range(-0.2, 0.2)
				walker.neural_weights[j] = clamp(walker.neural_weights[j], -2.0, 2.0)
	
	# Replace bottom performers with mutated versions of top performers
	for i in range(top_count + middle_count, walker_agents.size()):
		var parent_idx = randi() % top_count
		var parent = walker_agents[parent_idx]
		var new_walker = RandomWalker.new(
			Vector3.ZERO,  # Always start from center
			target_points[i % target_points.size()]
		)
		
		# Copy and mutate parent weights
		for j in range(parent.neural_weights.size()):
			new_walker.neural_weights[j] = parent.neural_weights[j] + randf_range(-0.3, 0.3)
			new_walker.neural_weights[j] = clamp(new_walker.neural_weights[j], -2.0, 2.0)
		
		walker_agents[i] = new_walker

func visualize_walkers():
	# Remove old walker visualizations
	for child in get_children():
		if child.has_meta("walker_viz"):
			child.queue_free()
	
	# Create new walker visualizations
	for i in range(min(20, walker_agents.size())):  # Only show top 20 for performance
		var walker = walker_agents[i]
		
		# Walker sphere
		var mesh_instance = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.05
		mesh_instance.mesh = sphere
		mesh_instance.material_override = walker_material
		mesh_instance.position = walker.position
		mesh_instance.set_meta("walker_viz", true)
		add_child(mesh_instance)
		
		# Trail visualization
		if walker.trail_points.size() > 1:
			var line_mesh = MeshInstance3D.new()
			var array_mesh = ArrayMesh.new()
			var vertices = PackedVector3Array()
			var indices = PackedInt32Array()
			
			for j in range(walker.trail_points.size()):
				vertices.append(walker.trail_points[j])
				if j > 0:
					indices.append(j - 1)
					indices.append(j)
			
			var arrays = []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = vertices
			arrays[Mesh.ARRAY_INDEX] = indices
			
			array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
			line_mesh.mesh = array_mesh
			line_mesh.material_override = trail_material
			line_mesh.set_meta("walker_viz", true)
			add_child(line_mesh)

# Input handling for experimentation
func _input(event):
	if event.is_action_pressed("ui_accept"):  # Space key
		# Experiment: Add burst of randomness
		temperature += 2.0
		print("Randomness burst! Temperature: ", temperature)
	
	if event.is_action_pressed("ui_cancel"):  # Escape key
		# Reset experiment
		walker_agents.clear()
		create_walker_agents()
		print("Experiment reset!")

# Additional experiment methods
func experiment_with_randomness_injection():
	# Method to test different randomness injection strategies
	pass

func log_performance_metrics():
	var avg_fitness = 0.0
	var best_fitness = 0.0
	
	for walker in walker_agents:
		avg_fitness += walker.fitness
		if walker.fitness > best_fitness:
			best_fitness = walker.fitness
	
	avg_fitness /= walker_agents.size()
	print("Avg Fitness: ", avg_fitness, " Best: ", best_fitness, " Temp: ", temperature)
