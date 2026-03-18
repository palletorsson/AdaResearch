## ============================================================================
## randomwalkermachine.gd — Evolutionary Random Walker Machine Visualization
## Neural-network-driven walkers evolve to reach noise-perturbed target points.
## Demonstrates evolutionary learning, temperature-controlled exploration, and
## fitness-based selection with real-time trail visualization.
## ============================================================================
extends Node3D

# ── Runtime UI Controls ──────────────────────────────────────────────────────
@export_range(50, 500, 10) var num_walkers: int = 300  ## Total walker agents
@export_range(0.01, 1.0, 0.01) var learning_rate: float = 0.1
@export_range(0.1, 5.0, 0.1) var temperature: float = 2.0:  ## Exploration randomness
	set(v):
		temperature = v
		_update_stats_label_now()
@export_range(0.0, 1.0, 0.05) var exploration_rate: float = 0.3
@export_range(5.0, 25.0, 0.5) var circle_radius: float = 10.0
@export_range(100, 500, 50) var evolution_interval: int = 200  ## Frames between evolution cycles
@export_range(5, 50, 1) var show_top_n_walkers: int = 20  ## How many top walkers to visualize

# ── Internal State ───────────────────────────────────────────────────────────
var noise = FastNoiseLite.new()
var target_points = []
var walker_agents = []
var _generation: int = 0
var _best_fitness: float = 0.0
var _avg_fitness: float = 0.0

# ── Visualization ────────────────────────────────────────────────────────────
var target_material: StandardMaterial3D
var walker_material: StandardMaterial3D
var trail_material: StandardMaterial3D
var _stats_label: Label3D = null

class RandomWalker:
	var position: Vector3
	var target: Vector3
	var velocity: Vector3
	var trail_points: Array[Vector3] = []
	var fitness: float = 0.0
	var neural_weights: Array[float] = []
	var exploration_noise: float
	
	func _init(start_pos: Vector3, target_pos: Vector3) -> void:
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

func _ready() -> void:
	setup_noise()
	generate_target_points()
	create_walker_agents()
	setup_materials()
	visualize_targets()
	_create_stats_label()

func setup_noise() -> void:
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.1
	noise.seed = randi()

func generate_target_points() -> void:
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

func create_walker_agents() -> void:
	# Create 100 random walkers starting from center
	for i in range(num_walkers):
		var start_position = Vector3.ZERO  # Always start from center
		var target = target_points[i % target_points.size()]
		var walker = RandomWalker.new(start_position, target)
		walker_agents.append(walker)

func setup_materials() -> void:
	## Enhanced materials with metallic sheen and stronger emission
	target_material = StandardMaterial3D.new()
	target_material.albedo_color = Color(0.3, 0.5, 0.9, 1)  # Blue for targets
	target_material.emission_enabled = true
	target_material.emission = Color(0.3, 0.5, 0.9, 1) * 0.6
	target_material.emission_energy_multiplier = 1.5
	target_material.metallic = 0.5
	target_material.roughness = 0.25
	
	walker_material = StandardMaterial3D.new()
	walker_material.albedo_color = Color(0.9, 0.3, 0.3, 1)  # Red for walkers
	walker_material.emission_enabled = true
	walker_material.emission = Color(0.9, 0.3, 0.3, 1) * 0.5
	walker_material.emission_energy_multiplier = 1.8
	walker_material.metallic = 0.4
	walker_material.roughness = 0.3
	
	trail_material = StandardMaterial3D.new()
	trail_material.albedo_color = Color(1.0, 0.85, 0.2, 1)  # Gold for trails
	trail_material.emission_enabled = true
	trail_material.emission = Color(1.0, 0.85, 0.2, 1) * 0.4
	trail_material.emission_energy_multiplier = 1.2

func visualize_targets() -> void:
	# Create target spheres
	for i in range(target_points.size()):
		var mesh_instance = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.1
		sphere.height = 0.2
		mesh_instance.mesh = sphere
		mesh_instance.material_override = target_material
		mesh_instance.position = target_points[i]
		add_child(mesh_instance)

func _process(_delta):
	# ── Update all walkers ───────────────────────────────────────────────
	update_walkers()
	
	# ── Evolutionary learning at configurable interval ───────────────────
	if Engine.get_process_frames() % evolution_interval == 0:
		_generation += 1
		evolve_walkers()
	
	# ── Dynamic temperature oscillation ──────────────────────────────────
	temperature = 1.0 + sin(Time.get_time_dict_from_system()["second"] * 0.1) * 0.5
	
	# ── Visualize walkers and trails ─────────────────────────────────────
	visualize_walkers()
	_update_stats_label_now()

func update_walkers() -> void:
	for walker in walker_agents:
		walker.update_position(temperature)

func evolve_walkers() -> void:
	## Evolutionary step: keep top 30%, mutate middle 40%, replace bottom 30% with offspring
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

func visualize_walkers() -> void:
	## Remove old walker visualizations and recreate with fitness-based coloring
	for child in get_children():
		if child.has_meta("walker_viz"):
			child.queue_free()
	
	# Track fitness for stats
	_best_fitness = 0.0
	_avg_fitness = 0.0
	for w in walker_agents:
		_avg_fitness += w.fitness
		if w.fitness > _best_fitness:
			_best_fitness = w.fitness
	if walker_agents.size() > 0:
		_avg_fitness /= walker_agents.size()
	
	# Create new walker visualizations (top N for performance)
	var vis_count = min(show_top_n_walkers, walker_agents.size())
	for i in range(vis_count):
		var walker = walker_agents[i]
		
		# ── Walker sphere with fitness-based color ───────────────────────
		var mesh_instance = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.05 + walker.fitness * 0.05  # Higher fitness = larger
		sphere.height = 0.05 + walker.fitness * 0.05  # Higher fitness = larger * 2.0
		mesh_instance.mesh = sphere
		
		# Fitness gradient: red (low) → green (high)
		var fit_mat = StandardMaterial3D.new()
		var fit_color = Color(0.9 * (1.0 - walker.fitness), 0.85 * walker.fitness, 0.2, 1)
		fit_mat.albedo_color = fit_color
		fit_mat.emission_enabled = true
		fit_mat.emission = fit_color * (0.3 + walker.fitness * 0.7)
		fit_mat.emission_energy_multiplier = 1.0 + walker.fitness * 1.5
		fit_mat.metallic = 0.4
		fit_mat.roughness = 0.3
		mesh_instance.material_override = fit_mat
		mesh_instance.position = walker.position
		mesh_instance.set_meta("walker_viz", true)
		add_child(mesh_instance)
		
		# ── Trail visualization ──────────────────────────────────────────
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

# ── Input Handling ────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):  # Space key — randomness burst
		temperature += 2.0
		# Visual feedback: flash the stats label
		if _stats_label:
			var tween = create_tween()
			tween.tween_property(_stats_label, "modulate", Color(0.9, 0.3, 0.3, 1), 0.15)
			tween.tween_property(_stats_label, "modulate", Color(1.0, 0.85, 0.2, 1), 0.3)
		print("Randomness burst! Temperature: ", temperature)
	
	if event.is_action_pressed("ui_cancel"):  # Escape — full reset
		walker_agents.clear()
		_generation = 0
		_best_fitness = 0.0
		_avg_fitness = 0.0
		create_walker_agents()
		print("Experiment reset!")

# ── Experiment Methods ────────────────────────────────────────────────────────

func experiment_with_randomness_injection() -> void:
	## Method to test different randomness injection strategies
	pass

func log_performance_metrics() -> void:
	## Print current generation metrics to console
	print("Gen %d | Avg Fitness: %.4f | Best: %.4f | Temp: %.2f" % [
		_generation, _avg_fitness, _best_fitness, temperature
	])

# ── Stats Label ──────────────────────────────────────────────────────────────

func _create_stats_label() -> void:
	## Floating 3D label showing generation, fitness, and temperature in real-time
	_stats_label = Label3D.new()
	_stats_label.text = "Initializing..."
	_stats_label.font_size = 48
	_stats_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
	_stats_label.outline_modulate = Color(0, 0, 0, 0.8)
	_stats_label.outline_size = 8
	_stats_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_stats_label.position = Vector3(0, 6.0, 0)
	_stats_label.no_depth_test = true
	add_child(_stats_label)

func _update_stats_label_now() -> void:
	if _stats_label:
		_stats_label.text = "Random Walker Machine\nGen: %d  |  Best: %.3f  |  Avg: %.3f  |  Temp: %.2f" % [
			_generation, _best_fitness, _avg_fitness, temperature
		]

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
