# ===========================================================================
# NOC Example 11.3: Smart Rockets Neuroevolution
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 11.3 - Smart Rockets Neuroevolution VR
## Rockets with neural network brains evolving to reach target while avoiding obstacles
## 
# Rocket with neural network brain
class NeuroRocket extends VREntity:
	var brain: NeuralNetwork
	var fitness: float = 0.0
	var alive: bool = true
	var hit_target: bool = false
	var hit_obstacle: bool = false
	var frame_count: int = 0
	var max_frames: int = 300

	# Trail rendering
	var trail_points: Array[Vector3] = []
	var trail_mesh: ImmediateMesh
	var trail_node: MeshInstance3D

	func _init():
		# Brain: 6 inputs, 8 hidden, 4 outputs (force X, Y, Z, magnitude)
		# Inputs: position (3), velocity (3)
		brain = NeuralNetwork.new(6, 8, 4)

	func setup_mesh():
		mesh_instance = MeshInstance3D.new()
		var cone = CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.015
		cone.height = 0.04
		mesh_instance.mesh = cone
		add_child(mesh_instance)

		# Create trail
		trail_mesh = ImmediateMesh.new()
		trail_node = MeshInstance3D.new()
		trail_node.mesh = trail_mesh
		add_child(trail_node)

	func think(target_pos: Vector3, obstacles: Array):
		if not alive or hit_target:
			return

		# Prepare inputs
		var inputs: Array[float] = []
		inputs.append(position_v.x)
		inputs.append(position_v.y)
		inputs.append(position_v.z)
		inputs.append(velocity.x)
		inputs.append(velocity.y)
		inputs.append(velocity.z)

		# Get output from brain
		var output = brain.predict(inputs)

		# Convert output to force vector
		var force = Vector3(
			output[0] * 2.0 - 1.0,  # -1 to 1
			output[1] * 2.0 - 1.0,
			output[2] * 2.0 - 1.0
		)
		var magnitude = output[3] * 0.05  # 0 to 0.05
		force = force.normalized() * magnitude

		apply_force(force)

	func _physics_process(delta):
		if not alive or hit_target:
			return

		super._physics_process(delta)
		frame_count += 1

		# Add trail point
		if frame_count % 3 == 0:
			trail_points.append(position_v)
			update_trail()

		# Check if exceeded max frames
		if frame_count > max_frames:
			alive = false

	func update_trail():
		"""Draw pink trail ribbon"""
		if trail_points.size() < 2:
			return

		trail_mesh.clear_surfaces()
		trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

		for point in trail_points:
			trail_mesh.surface_set_color(primary_pink)
			trail_mesh.surface_add_vertex(point)

		trail_mesh.surface_end()

	func check_target(target_pos: Vector3, radius: float):
		if position_v.distance_to(target_pos) < radius:
			hit_target = true
			# Brighten color
			set_color(accent_pink)

	func check_obstacle(obstacle_pos: Vector3, size: float):
		if abs(position_v.x - obstacle_pos.x) < size and \
		   abs(position_v.y - obstacle_pos.y) < size and \
		   abs(position_v.z - obstacle_pos.z) < size:
			hit_obstacle = true
			alive = false
			# Fade out
			if material:
				material.albedo_color.a = 0.2

	func calculate_fitness(target_pos: Vector3):
		"""Calculate fitness based on distance to target and success"""
		var distance = position_v.distance_to(target_pos)
		fitness = 1.0 / (distance + 1.0)

		if hit_target:
			fitness *= 10.0

		if hit_obstacle:
			fitness *= 0.1

		# Bonus for reaching faster
		if hit_target:
			fitness += 1.0 / (frame_count + 1)

# Obstacle
class Obstacle extends Node3D:
	var size: float = 0.15
	var mesh_instance: MeshInstance3D

	func _ready():
		mesh_instance = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(size, size, size)
		mesh_instance.mesh = box

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.7, 0.5, 0.7, 0.3)  # Desaturated purple
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh_instance.material_override = mat

		add_child(mesh_instance)

# Target
class Target extends Node3D:
	var radius: float = 0.08
	var mesh_instance: MeshInstance3D
	var accent_pink: Color = Color(1.0, 0.6, 1.0, 1.0)

	func _ready():
		mesh_instance = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = radius
		mesh_instance.mesh = sphere

		var mat = StandardMaterial3D.new()
		mat.albedo_color = accent_pink
		mat.emission_enabled = true
		mat.emission = accent_pink * 0.8
		mat.emission_energy_multiplier = 1.2
		mesh_instance.material_override = mat

		add_child(mesh_instance)

# Main scene variables
var population: Array[NeuroRocket] = []
var population_size: int = 25
var generation: int = 1
var target: Target
var obstacles: Array[Obstacle] = []
var mutation_rate: float = 0.1

var simulation_running: bool = true

# UI
var gen_label: Label3D
var alive_label: Label3D
var best_label: Label3D

func _ready():
	# Create target
	target = Target.new()
	target.position = Vector3(0, 0.35, -0.3)
	add_child(target)

	# Create obstacles
	create_obstacles()

	# Create population
	create_population()

	# Create UI
	create_ui()

func create_obstacles():
	"""Create obstacles in the path"""
	var obs1 = Obstacle.new()
	obs1.position = Vector3(0, 0.1, -0.1)
	add_child(obs1)
	obstacles.append(obs1)

	var obs2 = Obstacle.new()
	obs2.position = Vector3(-0.15, 0.2, -0.2)
	add_child(obs2)
	obstacles.append(obs2)

func create_population():
	"""Create or evolve population of rockets"""
	for i in range(population_size):
		var rocket = NeuroRocket.new()
		rocket.position_v = Vector3(0.2, -0.3, 0.2)
		rocket.velocity = Vector3.ZERO
		add_child(rocket)
		population.append(rocket)

func create_ui():
	gen_label = Label3D.new()
	gen_label.text = "Generation: 1"
	gen_label.font_size = 32
	gen_label.outline_size = 4
	gen_label.position = Vector3(-0.3, 0.45, 0)
	gen_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(gen_label)

	alive_label = Label3D.new()
	alive_label.text = "Alive: " + str(population_size)
	alive_label.font_size = 24
	alive_label.outline_size = 2
	alive_label.position = Vector3(-0.3, 0.4, 0)
	alive_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(alive_label)

	best_label = Label3D.new()
	best_label.text = "Best: 0.0"
	best_label.font_size = 24
	best_label.outline_size = 2
	best_label.position = Vector3(-0.3, 0.35, 0)
	best_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(best_label)

func _process(_delta):
	if not simulation_running:
		return

	# Make rockets think
	for rocket in population:
		if rocket.alive and not rocket.hit_target:
			rocket.think(target.position, obstacles)

	# Check collisions
	for rocket in population:
		if not rocket.alive:
			continue

		# Check target
		rocket.check_target(target.position, target.radius)

		# Check obstacles
		for obstacle in obstacles:
			rocket.check_obstacle(obstacle.position, obstacle.size)

	# Update UI
	var alive_count = 0
	var hit_count = 0
	for rocket in population:
		if rocket.alive or rocket.hit_target:
			alive_count += 1
		if rocket.hit_target:
			hit_count += 1

	alive_label.text = "Alive: %d | Hit: %d" % [alive_count, hit_count]

	# Check if all done
	if alive_count == 0:
		next_generation()

func next_generation():
	"""Evolve next generation"""
	generation += 1
	gen_label.text = "Generation: " + str(generation)

	# Calculate fitness
	for rocket in population:
		rocket.calculate_fitness(target.position)

	# Find best fitness
	var best_fitness = 0.0
	for rocket in population:
		if rocket.fitness > best_fitness:
			best_fitness = rocket.fitness

	best_label.text = "Best: " + str(snappedf(best_fitness, 0.01))

	# Calculate total fitness
	var total_fitness = 0.0
	for rocket in population:
		total_fitness += rocket.fitness

	# Create mating pool
	var mating_pool: Array[NeuralNetwork] = []
	for rocket in population:
		var n = int((rocket.fitness / total_fitness) * 100) if total_fitness > 0 else 1
		for i in range(n):
			mating_pool.append(rocket.brain)

	# Create new population
	var new_population: Array[NeuroRocket] = []
	for i in range(population_size):
		var rocket = NeuroRocket.new()

		# Pick parent from mating pool
		if mating_pool.size() > 0:
			var parent = mating_pool[randi() % mating_pool.size()]
			rocket.brain = parent.copy()
			rocket.brain.mutate(mutation_rate)

		rocket.position_v = Vector3(0.2, -0.3, 0.2)
		rocket.velocity = Vector3.ZERO
		add_child(rocket)
		new_population.append(rocket)

	# Remove old population
	for rocket in population:
		rocket.queue_free()

	population = new_population
