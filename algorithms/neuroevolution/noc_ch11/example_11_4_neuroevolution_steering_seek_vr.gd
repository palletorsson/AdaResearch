# ===========================================================================
# NOC Example 11.4: Neuroevolution Steering: Seek
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 11.4 - Neuroevolution Steering Seek VR
## Steering agents evolved to seek goals while avoiding hazards
## 
# Steering creature with neural network
class NeuroCreature extends VREntity:
	var brain: NeuralNetwork
	var fitness: float = 0.0
	var alive: bool = true
	var max_speed: float = 0.2
	var max_force: float = 0.05
	var sensor_range: float = 0.3
	var lifetime: float = 0.0
	var max_lifetime: float = 20.0

	# Steering visualization
	var arrow_mesh: ImmediateMesh
	var arrow_node: MeshInstance3D

	func _init():
		# Brain: 8 inputs, 12 hidden, 2 outputs
		# Inputs: position (3), velocity (3), goal direction (2)
		# Outputs: steering force X, steering force Y
		brain = NeuralNetwork.new(8, 12, 2)

	func setup_mesh():
		# Body
		mesh_instance = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.025
		mesh_instance.mesh = sphere
		add_child(mesh_instance)

		# Steering arrow
		arrow_mesh = ImmediateMesh.new()
		arrow_node = MeshInstance3D.new()
		arrow_node.mesh = arrow_mesh
		add_child(arrow_node)

	func think(goal_pos: Vector3, hazards: Array):
		if not alive:
			return

		# Calculate direction to goal
		var to_goal = goal_pos - position_v
		var goal_dir = to_goal.normalized()

		# Prepare inputs
		var inputs: Array[float] = []
		inputs.append(position_v.x)
		inputs.append(position_v.y)
		inputs.append(position_v.z)
		inputs.append(velocity.x)
		inputs.append(velocity.y)
		inputs.append(velocity.z)
		inputs.append(goal_dir.x)
		inputs.append(goal_dir.y)

		# Get steering force from brain
		var output = brain.predict(inputs)
		var steer = Vector3(
			output[0] * 2.0 - 1.0,  # -1 to 1
			output[1] * 2.0 - 1.0,
			0
		) * max_force

		apply_force(steer)

		# Draw steering arrow
		draw_arrow(steer)

	func draw_arrow(force: Vector3):
		"""Visualize steering force as pink arrow"""
		if force.length() < 0.001:
			return

		arrow_mesh.clear_surfaces()
		arrow_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

		var start = Vector3.ZERO
		var end = force * 5.0  # Scale for visibility

		arrow_mesh.surface_set_color(primary_pink)
		arrow_mesh.surface_add_vertex(start)
		arrow_mesh.surface_add_vertex(end)

		arrow_mesh.surface_end()

	func _physics_process(delta):
		if not alive:
			return

		super._physics_process(delta)

		# Limit speed
		if velocity.length() > max_speed:
			velocity = velocity.normalized() * max_speed

		# Update lifetime
		lifetime += delta
		if lifetime > max_lifetime:
			alive = false

		# Update glow based on fitness
		if material:
			var glow_intensity = clampf(fitness / 10.0, 0.3, 1.5)
			material.emission_energy_multiplier = glow_intensity

	func check_goal(goal_pos: Vector3, radius: float) -> bool:
		if position_v.distance_to(goal_pos) < radius:
			fitness += 10.0
			return true
		return false

	func check_hazard(hazard_pos: Vector3, size: float):
		if abs(position_v.x - hazard_pos.x) < size and \
		   abs(position_v.y - hazard_pos.y) < size:
			alive = false
			fitness *= 0.5  # Penalty
			if material:
				material.albedo_color.a = 0.2

	func calculate_fitness(goal_pos: Vector3):
		"""Calculate fitness based on proximity to goal and survival time"""
		var distance = position_v.distance_to(goal_pos)
		fitness += 1.0 / (distance + 1.0)
		fitness += lifetime * 0.5  # Bonus for staying alive

# Goal
class Goal extends Node3D:
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
		mat.emission = accent_pink * 0.9
		mat.emission_energy_multiplier = 1.5
		mesh_instance.material_override = mat

		add_child(mesh_instance)

# Hazard
class Hazard extends Node3D:
	var size: float = 0.12
	var mesh_instance: MeshInstance3D

	func _ready():
		mesh_instance = MeshInstance3D.new()
		var prism = BoxMesh.new()
		prism.size = Vector3(size, size, size)
		mesh_instance.mesh = prism

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.65, 0.5, 0.7, 0.4)  # Desaturated purple
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh_instance.material_override = mat

		add_child(mesh_instance)

	func _process(delta):
		# Slowly rotate
		mesh_instance.rotate_y(delta * 0.5)

# Main scene
var population: Array[NeuroCreature] = []
var population_size: int = 20
var generation: int = 1
var goal: Goal
var hazards: Array[Hazard] = []
var mutation_rate: float = 0.1

var goal_position: float = 0.0  # Z-axis position

# UI
var gen_label: Label3D
var alive_label: Label3D
var best_label: Label3D

func _ready():
	# Create goal
	goal = Goal.new()
	goal.position = Vector3(0, 0.2, goal_position)
	add_child(goal)

	# Create hazards
	create_hazards()

	# Create population
	create_population()

	# Create UI
	create_ui()

func create_hazards():
	"""Create hazard obstacles"""
	var haz1 = Hazard.new()
	haz1.position = Vector3(-0.15, 0.1, -0.1)
	add_child(haz1)
	hazards.append(haz1)

	var haz2 = Hazard.new()
	haz2.position = Vector3(0.15, 0, -0.15)
	add_child(haz2)
	hazards.append(haz2)

	var haz3 = Hazard.new()
	haz3.position = Vector3(0, -0.1, -0.05)
	add_child(haz3)
	hazards.append(haz3)

func create_population():
	"""Create or evolve population"""
	for i in range(population_size):
		var creature = NeuroCreature.new()
		creature.position_v = Vector3(
			randf_range(-0.3, 0.3),
			randf_range(-0.3, -0.1),
			0.3
		)
		add_child(creature)
		population.append(creature)

func create_ui():
	gen_label = Label3D.new()
	gen_label.text = "Generation: 1"
	gen_label.font_size = 28
	gen_label.outline_size = 4
	gen_label.position = Vector3(-0.35, 0.45, 0)
	gen_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(gen_label)

	alive_label = Label3D.new()
	alive_label.text = "Alive: " + str(population_size)
	alive_label.font_size = 22
	alive_label.outline_size = 2
	alive_label.position = Vector3(-0.35, 0.4, 0)
	alive_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(alive_label)

	best_label = Label3D.new()
	best_label.text = "Best: 0.0"
	best_label.font_size = 22
	best_label.outline_size = 2
	best_label.position = Vector3(-0.35, 0.35, 0)
	best_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(best_label)

func _process(_delta):
	# Make creatures think
	for creature in population:
		if creature.alive:
			creature.think(goal.position, hazards)

	# Check goal and hazards
	for creature in population:
		if not creature.alive:
			continue

		# Check if reached goal
		if creature.check_goal(goal.position, goal.radius):
			# Respawn goal
			goal.position = Vector3(
				randf_range(-0.25, 0.25),
				randf_range(-0.2, 0.3),
				randf_range(-0.2, 0.2)
			)

		# Check hazards
		for hazard in hazards:
			creature.check_hazard(hazard.position, hazard.size)

	# Update UI
	var alive_count = 0
	for creature in population:
		if creature.alive:
			alive_count += 1

	alive_label.text = "Alive: " + str(alive_count)

	# Check if all dead or time expired
	if alive_count == 0:
		next_generation()

func next_generation():
	"""Evolve next generation"""
	generation += 1
	gen_label.text = "Generation: " + str(generation)

	# Calculate fitness
	for creature in population:
		creature.calculate_fitness(goal.position)

	# Find best
	var best_fitness = 0.0
	for creature in population:
		if creature.fitness > best_fitness:
			best_fitness = creature.fitness

	best_label.text = "Best: " + str(snappedf(best_fitness, 0.1))

	# Total fitness
	var total_fitness = 0.0
	for creature in population:
		total_fitness += creature.fitness

	# Mating pool
	var mating_pool: Array[NeuralNetwork] = []
	for creature in population:
		var n = int((creature.fitness / total_fitness) * 100) if total_fitness > 0 else 1
		for i in range(n):
			mating_pool.append(creature.brain)

	# New population
	var new_population: Array[NeuroCreature] = []
	for i in range(population_size):
		var creature = NeuroCreature.new()

		if mating_pool.size() > 0:
			var parent = mating_pool[randi() % mating_pool.size()]
			creature.brain = parent.copy()
			creature.brain.mutate(mutation_rate)

		creature.position_v = Vector3(
			randf_range(-0.3, 0.3),
			randf_range(-0.3, -0.1),
			0.3
		)
		add_child(creature)
		new_population.append(creature)

	# Remove old
	for creature in population:
		creature.queue_free()

	population = new_population

	# Reset goal
	goal.position = Vector3(0, 0.2, goal_position)
