# ===========================================================================
# NOC Example 11.2: Flappy Bird Neuroevolution
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 11.2 - Flappy Bird Neuroevolution VR
## Neuroevolved flock of birds learning to navigate pipes using neural networks
## 
# Bird with neural network brain
class NeuroBird extends VREntity:
	var brain: NeuralNetwork
	var fitness: float = 0.0
	var alive: bool = true
	var gravity: Vector3 = Vector3(0, -0.5, 0)
	var flap_force: float = 0.15
	var distance_traveled: float = 0.0
	var pipes_passed: int = 0

	func _init():
		# Create brain: 5 inputs, 8 hidden neurons, 1 output
		# Inputs: bird Y, bird velocity Y, nearest pipe X distance, upper gap Y, lower gap Y
		brain = NeuralNetwork.new(5, 8, 1)

	func setup_mesh():
		mesh_instance = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.025
		mesh_instance.mesh = sphere
		add_child(mesh_instance)

	func think(pipes: Array):
		if not alive:
			return

		# Get inputs for neural network
		var inputs: Array[float] = []
		inputs.append(position_v.y)  # Bird Y position
		inputs.append(velocity.y)    # Bird Y velocity

		# Find nearest pipe
		var nearest_pipe = null
		var min_dist = 999.0
		for pipe in pipes:
			var dist = pipe.position.x - position_v.x
			if dist > 0 and dist < min_dist:
				min_dist = dist
				nearest_pipe = pipe

		if nearest_pipe:
			inputs.append(min_dist)  # Distance to pipe
			inputs.append(nearest_pipe.gap_y + nearest_pipe.gap_size / 2)  # Upper gap
			inputs.append(nearest_pipe.gap_y - nearest_pipe.gap_size / 2)  # Lower gap
		else:
			inputs.append(1.0)
			inputs.append(0.0)
			inputs.append(0.0)

		# Get output from brain
		var output = brain.predict(inputs)

		# If output > 0.5, flap
		if output[0] > 0.5:
			flap()

	func flap():
		velocity.y = flap_force

	func _physics_process(delta):
		if not alive:
			return

		# Apply gravity
		apply_force(gravity)
		super._physics_process(delta)

		# Update fitness
		distance_traveled += delta
		fitness = distance_traveled + pipes_passed * 10.0

		# Keep within tank Y bounds
		if position_v.y > 0.45 or position_v.y < -0.45:
			alive = false
			# Fade out dead bird
			if material:
				material.albedo_color.a = 0.2

# Pipe obstacle (same as 11.1)
class Pipe extends Node3D:
	var gap_y: float = 0.0
	var gap_size: float = 0.2
	var speed: float = 0.15

	var upper_mesh: MeshInstance3D
	var lower_mesh: MeshInstance3D
	var secondary_pink: Color = Color(0.9, 0.5, 0.8, 0.5)
	var accent_pink: Color = Color(1.0, 0.6, 1.0, 0.8)  # Glow when passed

	func _init(y_pos: float = 0.0):
		gap_y = y_pos

	func _ready():
		create_pipes()

	func create_pipes():
		# Upper pipe
		upper_mesh = MeshInstance3D.new()
		var upper_box = BoxMesh.new()
		upper_box.size = Vector3(0.08, 0.5 - gap_y - gap_size / 2, 0.08)
		upper_mesh.mesh = upper_box
		upper_mesh.position = Vector3(0, 0.25 + gap_y + gap_size / 2, 0)

		var mat_upper = StandardMaterial3D.new()
		mat_upper.albedo_color = secondary_pink
		mat_upper.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		upper_mesh.material_override = mat_upper
		add_child(upper_mesh)

		# Lower pipe
		lower_mesh = MeshInstance3D.new()
		var lower_box = BoxMesh.new()
		lower_box.size = Vector3(0.08, 0.5 + gap_y - gap_size / 2, 0.08)
		lower_mesh.mesh = lower_box
		lower_mesh.position = Vector3(0, -0.25 + gap_y - gap_size / 2, 0)

		var mat_lower = StandardMaterial3D.new()
		mat_lower.albedo_color = secondary_pink
		mat_lower.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		lower_mesh.material_override = mat_lower
		add_child(lower_mesh)

	func _process(delta):
		position.x -= speed * delta

	func check_collision(bird_pos: Vector3) -> bool:
		if abs(bird_pos.x - position.x) < 0.05:
			if bird_pos.y < gap_y - gap_size / 2 or bird_pos.y > gap_y + gap_size / 2:
				return true
		return false

	func glow():
		"""Glow when bird successfully passes"""
		if upper_mesh and lower_mesh:
			upper_mesh.material_override.albedo_color = accent_pink
			lower_mesh.material_override.albedo_color = accent_pink

# Main scene variables
var population: Array[NeuroBird] = []
var population_size: int = 20
var generation: int = 1
var pipes: Array[Pipe] = []
var spawn_timer: float = 0.0
var spawn_interval: float = 2.0
var mutation_rate: float = 0.1

# UI
var gen_label: Label3D
var alive_label: Label3D
var best_label: Label3D

# Colors for different performance levels
var primary_pink: Color = Color(1.0, 0.7, 0.9, 1.0)
var alt_pink: Color = Color(0.9, 0.5, 0.8, 1.0)

func _ready():
	# Create initial population
	create_population()

	# Create UI
	create_ui()

	# Spawn first pipe
	spawn_pipe()

func create_population():
	"""Create or evolve new population of birds"""
	for i in range(population_size):
		var bird = NeuroBird.new()
		bird.position_v = Vector3(0.15, randf_range(-0.1, 0.1), 0)

		# Alternate colors
		if i % 2 == 0:
			bird.set_color(primary_pink)
		else:
			bird.set_color(alt_pink)

		add_child(bird)
		population.append(bird)

func create_ui():
	# Generation label
	gen_label = Label3D.new()
	gen_label.text = "Generation: 1"
	gen_label.font_size = 32
	gen_label.outline_size = 4
	gen_label.position = Vector3(0, 0.4, -0.4)
	gen_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(gen_label)

	# Alive count label
	alive_label = Label3D.new()
	alive_label.text = "Alive: " + str(population_size)
	alive_label.font_size = 24
	alive_label.outline_size = 2
	alive_label.position = Vector3(0, 0.35, -0.4)
	alive_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(alive_label)

	# Best fitness label
	best_label = Label3D.new()
	best_label.text = "Best: 0.0"
	best_label.font_size = 24
	best_label.outline_size = 2
	best_label.position = Vector3(0, 0.3, -0.4)
	best_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(best_label)

func _process(delta):
	# Spawn pipes
	spawn_timer += delta
	if spawn_timer > spawn_interval:
		spawn_pipe()
		spawn_timer = 0.0

	# Make birds think
	for bird in population:
		if bird.alive:
			bird.think(pipes)

	# Check collisions
	for bird in population:
		if not bird.alive:
			continue

		for pipe in pipes:
			if pipe.check_collision(bird.position_v):
				bird.alive = false
				# Fade out
				if bird.material:
					bird.material.albedo_color.a = 0.2

	# Update pipe passing
	for pipe in pipes:
		if pipe.position.x < 0.15:  # Passed bird spawn point
			for bird in population:
				if bird.alive and pipe.position.x > 0.10:  # Just passed
					bird.pipes_passed += 1
					pipe.glow()

	# Remove off-screen pipes
	var to_remove: Array[Pipe] = []
	for pipe in pipes:
		if pipe.position.x < -0.6:
			to_remove.append(pipe)

	for pipe in to_remove:
		pipes.erase(pipe)
		pipe.queue_free()

	# Update UI
	var alive_count = 0
	var best_fitness = 0.0
	for bird in population:
		if bird.alive:
			alive_count += 1
		if bird.fitness > best_fitness:
			best_fitness = bird.fitness

	alive_label.text = "Alive: " + str(alive_count)
	best_label.text = "Best: " + str(snappedf(best_fitness, 0.1))

	# Check if all birds are dead
	if alive_count == 0:
		next_generation()

func spawn_pipe():
	"""Spawn a new pipe at random height"""
	var gap_y = randf_range(-0.2, 0.2)
	var pipe = Pipe.new(gap_y)
	pipe.position = Vector3(0.5, 0, 0)
	add_child(pipe)
	pipes.append(pipe)

func next_generation():
	"""Evolve next generation using neuroevolution"""
	generation += 1
	gen_label.text = "Generation: " + str(generation)

	# Calculate total fitness
	var total_fitness = 0.0
	for bird in population:
		total_fitness += bird.fitness

	# Create mating pool based on fitness
	var mating_pool: Array[NeuralNetwork] = []
	for bird in population:
		var n = int((bird.fitness / total_fitness) * 100)
		for i in range(n):
			mating_pool.append(bird.brain)

	# Create new population
	var new_population: Array[NeuroBird] = []
	for i in range(population_size):
		var bird = NeuroBird.new()

		# Pick parent brain from mating pool
		if mating_pool.size() > 0:
			var parent = mating_pool[randi() % mating_pool.size()]
			bird.brain = parent.copy()
			bird.brain.mutate(mutation_rate)
		# else keep random brain

		bird.position_v = Vector3(0.15, randf_range(-0.1, 0.1), 0)

		# Alternate colors
		if i % 2 == 0:
			bird.set_color(primary_pink)
		else:
			bird.set_color(alt_pink)

		add_child(bird)
		new_population.append(bird)

	# Remove old population
	for bird in population:
		bird.queue_free()

	population = new_population

	# Clear pipes
	for pipe in pipes:
		pipe.queue_free()
	pipes.clear()

	spawn_timer = 0.0
	spawn_pipe()
