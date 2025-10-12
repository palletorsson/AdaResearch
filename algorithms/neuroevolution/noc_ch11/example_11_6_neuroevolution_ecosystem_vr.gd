# ===========================================================================
# NOC Example 11.6: Neuroevolution Ecosystem
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 11.6 - Neuroevolution Ecosystem VR
## Combined ecosystem of evolved creatures foraging on food within shared environment
## 
# Evolved creature with sensors and neural network
class EcoCreature extends VREntity:
	var brain: NeuralNetwork
	var health: float = 100.0
	var max_health: float = 100.0
	var alive: bool = true
	var age: float = 0.0
	var max_age: float = 30.0

	# Sensors
	var sensors: Array[Sensor] = []
	var num_sensors: int = 4
	var sensor_range: float = 0.25

	# Movement
	var max_speed: float = 0.12
	var max_force: float = 0.04

	# Trail
	var trail_points: Array[Vector3] = []
	var max_trail_length: int = 20
	var trail_mesh: ImmediateMesh
	var trail_node: MeshInstance3D

	# Reproduction
	var reproduction_threshold: float = 80.0
	var reproduction_cost: float = 40.0

	func _init():
		# Brain: num_sensors inputs, 8 hidden, 2 outputs (turn, speed)
		brain = NeuralNetwork.new(num_sensors, 8, 2)

		# Create sensors
		for i in range(num_sensors):
			var angle = (TAU / num_sensors) * i
			sensors.append(Sensor.new(angle, sensor_range))

	func setup_mesh():
		# Body
		mesh_instance = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.03
		mesh_instance.mesh = sphere
		add_child(mesh_instance)

		# Trail
		trail_mesh = ImmediateMesh.new()
		trail_node = MeshInstance3D.new()
		trail_node.mesh = trail_mesh
		add_child(trail_node)

	func think(food_items: Array):
		if not alive:
			return

		# Sense environment
		var inputs: Array[float] = []
		var forward = -global_transform.basis.z

		for sensor in sensors:
			var reading = sensor.get_reading(position_v, forward, food_items)
			inputs.append(reading)

		# Get output from brain
		var output = brain.predict(inputs)

		# Turn and move based on output
		var turn = (output[0] * 2.0 - 1.0) * PI  # -PI to PI
		rotate_y(turn * 0.5 * get_physics_process_delta_time())

		var speed = output[1] * max_speed
		var move_forward = -global_transform.basis.z
		velocity = move_forward * speed

	func _physics_process(delta):
		if not alive:
			return

		super._physics_process(delta)

		# Update age and health
		age += delta
		health -= 0.5 * delta  # Constant health drain

		# Add trail
		if Engine.get_physics_frames() % 5 == 0:
			trail_points.append(position_v)
			if trail_points.size() > max_trail_length:
				trail_points.pop_front()
			update_trail()

		# Check death conditions
		if health <= 0 or age > max_age:
			die()

		# Update color based on health
		update_appearance()

	func update_trail():
		"""Draw pink trail"""
		if trail_points.size() < 2:
			return

		trail_mesh.clear_surfaces()
		trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

		for i in range(trail_points.size()):
			var alpha = float(i) / trail_points.size()
			var color = Color(primary_pink.r, primary_pink.g, primary_pink.b, alpha * 0.5)
			trail_mesh.surface_set_color(color)
			trail_mesh.surface_add_vertex(trail_points[i])

		trail_mesh.surface_end()

	func update_appearance():
		"""Update color and glow based on health"""
		if not material:
			return

		var health_ratio = health / max_health

		# Color fades as health decreases
		var color = primary_pink.lerp(Color(0.5, 0.3, 0.4), 1.0 - health_ratio)
		material.albedo_color = color
		material.emission = color * health_ratio
		material.emission_energy_multiplier = health_ratio * 1.2

		# Show alpha creature (high health) with halo
		if health > 90.0:
			material.emission_energy_multiplier = 2.0

	func eat(food_value: float):
		"""Consume food and gain health"""
		health += food_value
		health = min(health, max_health)

	func can_reproduce() -> bool:
		"""Check if creature can reproduce"""
		return health > reproduction_threshold

	func reproduce() -> EcoCreature:
		"""Create offspring with mutated brain"""
		if not can_reproduce():
			return null

		health -= reproduction_cost

		var child = EcoCreature.new()
		child.brain = brain.copy()
		child.brain.mutate(0.05)  # 5% mutation rate
		child.position_v = position_v + Vector3(randf_range(-0.05, 0.05), 0, randf_range(-0.05, 0.05))

		return child

	func die():
		"""Mark creature as dead"""
		alive = false
		if material:
			material.albedo_color.a = 0.1

# Sensor for creatures
class Sensor:
	var angle: float
	var max_distance: float

	func _init(a: float, dist: float):
		angle = a
		max_distance = dist

	func get_reading(pos: Vector3, forward: Vector3, food_items: Array) -> float:
		var sensor_dir = forward.rotated(Vector3.UP, angle)
		var min_dist = max_distance

		for food in food_items:
			if not food.active:
				continue

			var to_food = food.position - pos
			var dist = to_food.length()

			if dist < min_dist:
				var angle_to_food = acos(to_food.normalized().dot(sensor_dir))
				if angle_to_food < deg_to_rad(45):
					min_dist = dist

		return 1.0 - (min_dist / max_distance)

# Food orb
class FoodOrb extends Node3D:
	var active: bool = true
	var value: float = 20.0
	var mesh_instance: MeshInstance3D
	var grow_timer: float = 0.0
	var accent_pink: Color = Color(1.0, 0.6, 1.0, 0.8)

	func _ready():
		mesh_instance = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.02
		mesh_instance.mesh = sphere

		var mat = StandardMaterial3D.new()
		mat.albedo_color = accent_pink
		mat.emission_enabled = true
		mat.emission = accent_pink * 0.9
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh_instance.material_override = mat

		add_child(mesh_instance)

	func _process(delta):
		grow_timer += delta

		# Pulse effect
		var scale_factor = 1.0 + sin(grow_timer * 3.0) * 0.2
		mesh_instance.scale = Vector3.ONE * scale_factor

		# Shrink on consumption (visual feedback)
		if not active and mesh_instance.scale.x > 0.1:
			mesh_instance.scale *= 0.95

# Main ecosystem
var creatures: Array[EcoCreature] = []
var food_items: Array[FoodOrb] = []
var initial_population: int = 10
var max_population: int = 30
var food_spawn_rate: float = 2.0
var max_food: int = 15

var spawn_timer: float = 0.0
var generation_count: int = 0

# UI
var pop_label: Label3D
var food_label: Label3D
var gen_label: Label3D

# Energy fog plane (visual indicator)
var energy_fog: MeshInstance3D

func _ready():
	# Create energy fog plane
	create_energy_fog()

	# Spawn initial population
	for i in range(initial_population):
		spawn_creature(Vector3(randf_range(-0.2, 0.2), randf_range(-0.2, 0.2), randf_range(-0.2, 0.2)))

	# Spawn initial food
	for i in range(max_food / 2):
		spawn_food()

	# Create UI
	create_ui()

func create_energy_fog():
	"""Pink fog plane at tank base to signal environment energy"""
	energy_fog = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(1.0, 1.0)
	energy_fog.mesh = plane
	energy_fog.position = Vector3(0, -0.48, 0)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.7, 0.9, 0.15)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.9) * 0.3
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	energy_fog.material_override = mat

	add_child(energy_fog)

func spawn_creature(pos: Vector3):
	"""Spawn a new creature"""
	var creature = EcoCreature.new()
	creature.position_v = pos
	add_child(creature)
	creatures.append(creature)

func spawn_food():
	"""Spawn food in random location"""
	if food_items.size() >= max_food:
		return

	var food = FoodOrb.new()
	food.position = Vector3(
		randf_range(-0.35, 0.35),
		randf_range(-0.35, 0.35),
		randf_range(-0.35, 0.35)
	)
	add_child(food)
	food_items.append(food)

func create_ui():
	pop_label = Label3D.new()
	pop_label.text = "Population: " + str(initial_population)
	pop_label.font_size = 26
	pop_label.outline_size = 3
	pop_label.position = Vector3(-0.35, 0.45, 0)
	pop_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(pop_label)

	food_label = Label3D.new()
	food_label.text = "Food: 0"
	food_label.font_size = 22
	food_label.outline_size = 2
	food_label.position = Vector3(-0.35, 0.4, 0)
	food_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(food_label)

	gen_label = Label3D.new()
	gen_label.text = "Births: 0"
	gen_label.font_size = 22
	gen_label.outline_size = 2
	gen_label.position = Vector3(-0.35, 0.35, 0)
	gen_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(gen_label)

func _process(delta):
	# Spawn food periodically
	spawn_timer += delta
	if spawn_timer > food_spawn_rate:
		spawn_food()
		spawn_timer = 0.0

	# Creatures think and move
	for creature in creatures:
		if creature.alive:
			creature.think(food_items)

	# Check food consumption
	for creature in creatures:
		if not creature.alive:
			continue

		for food in food_items:
			if not food.active:
				continue

			if creature.position_v.distance_to(food.position) < 0.05:
				creature.eat(food.value)
				food.active = false
				food.queue_free()
				food_items.erase(food)

	# Check reproduction
	var new_creatures: Array[EcoCreature] = []
	for creature in creatures:
		if not creature.alive:
			continue

		if creature.can_reproduce() and creatures.size() < max_population:
			var child = creature.reproduce()
			if child:
				add_child(child)
				new_creatures.append(child)
				generation_count += 1

	creatures.append_array(new_creatures)

	# Remove dead creatures
	var to_remove: Array[EcoCreature] = []
	for creature in creatures:
		if not creature.alive:
			to_remove.append(creature)

	for creature in to_remove:
		creatures.erase(creature)
		creature.queue_free()

	# Update UI
	pop_label.text = "Population: " + str(creatures.size())
	food_label.text = "Food: " + str(food_items.size())
	gen_label.text = "Births: " + str(generation_count)
