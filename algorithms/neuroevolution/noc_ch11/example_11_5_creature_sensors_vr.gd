# ===========================================================================
# NOC Example 11.5: Creature Sensors
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 11.5 - Creature Sensors VR
## Single creature with forward sensors reacting to food items
## 
# Sensor ray
class Sensor:
	var angle: float
	var max_distance: float = 0.3
	var current_reading: float = 0.0

	func _init(a: float, dist: float = 0.3):
		angle = a
		max_distance = dist

	func get_reading(creature_pos: Vector3, creature_forward: Vector3, food_items: Array) -> float:
		# Calculate sensor direction
		var sensor_dir = creature_forward.rotated(Vector3.UP, angle)

		# Find closest food in this direction
		var min_dist = max_distance
		for food in food_items:
			var to_food = food.position - creature_pos
			var projected = to_food.dot(sensor_dir)

			if projected > 0:  # In front of sensor
				var dist = to_food.length()
				if dist < min_dist:
					# Check if within sensor cone
					var angle_to_food = acos(to_food.normalized().dot(sensor_dir))
					if angle_to_food < deg_to_rad(30):  # 30 degree cone
						min_dist = dist

		current_reading = 1.0 - (min_dist / max_distance)
		return current_reading

# Food item
class FoodItem extends Node3D:
	var consumed: bool = false
	var mesh_instance: MeshInstance3D
	var sparkle_timer: float = 0.0
	var accent_pink: Color = Color(1.0, 0.6, 1.0, 1.0)

	func _ready():
		mesh_instance = MeshInstance3D.new()
		var cube = BoxMesh.new()
		cube.size = Vector3(0.03, 0.03, 0.03)
		mesh_instance.mesh = cube

		var mat = StandardMaterial3D.new()
		mat.albedo_color = accent_pink
		mat.emission_enabled = true
		mat.emission = accent_pink * 0.7
		mat.emission_energy_multiplier = 1.0
		mesh_instance.material_override = mat

		add_child(mesh_instance)

	func _process(delta):
		# Sparkle effect
		sparkle_timer += delta
		var sparkle = sin(sparkle_timer * 5.0) * 0.5 + 0.5
		if mesh_instance and mesh_instance.material_override:
			mesh_instance.material_override.emission_energy_multiplier = 0.5 + sparkle

		# Slow rotation
		rotate_y(delta)

# Creature with sensors
class SensorCreature extends VREntity:
	var sensors: Array[Sensor] = []
	var num_sensors: int = 5
	var sensor_range: float = 0.3
	var max_speed: float = 0.15
	var rotation_speed: float = 1.0

	# Sensor visualization
	var sensor_meshes: Array[MeshInstance3D] = []

	func _init():
		# Create sensors in a forward arc
		for i in range(num_sensors):
			var angle = -PI/3 + (i * (2 * PI/3) / (num_sensors - 1))  # -60 to +60 degrees
			var sensor = Sensor.new(angle, sensor_range)
			sensors.append(sensor)

	func setup_mesh():
		# Body
		mesh_instance = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.04
		mesh_instance.mesh = sphere
		add_child(mesh_instance)

		# Create sensor cone visualizations
		for i in range(num_sensors):
			var cone_mesh = MeshInstance3D.new()
			var cone = CylinderMesh.new()
			cone.top_radius = 0.0  # Makes it a cone
			cone.bottom_radius = 0.02
			cone.height = sensor_range
			cone_mesh.mesh = cone

			var mat = StandardMaterial3D.new()
			var alpha = 0.15 + (i * 0.1)  # Vary transparency
			mat.albedo_color = Color(primary_pink.r, primary_pink.g, primary_pink.b, alpha)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			cone_mesh.material_override = mat

			# Position and orient sensor cone
			cone_mesh.rotation.x = -PI / 2  # Point forward
			add_child(cone_mesh)
			sensor_meshes.append(cone_mesh)

	func sense(food_items: Array) -> Array[float]:
		"""Read all sensors and return normalized readings"""
		var readings: Array[float] = []
		var forward = -global_transform.basis.z

		for i in range(sensors.size()):
			var reading = sensors[i].get_reading(position_v, forward, food_items)
			readings.append(reading)

			# Update sensor visualization
			if i < sensor_meshes.size():
				var cone = sensor_meshes[i]
				var angle = sensors[i].angle

				# Position cone
				var offset = forward.rotated(Vector3.UP, angle) * (sensor_range / 2)
				cone.position = offset
				cone.rotation.y = angle

				# Update brightness based on reading
				if cone.material_override:
					var brightness = 0.5 + reading * 0.5
					cone.material_override.emission_energy_multiplier = brightness

		return readings

	func move_towards_food(readings: Array[float], delta: float):
		"""Simple reactive behavior: turn towards strongest sensor signal"""
		if readings.size() == 0:
			return

		# Find strongest sensor
		var max_reading = 0.0
		var max_index = num_sensors / 2  # Default to center

		for i in range(readings.size()):
			if readings[i] > max_reading:
				max_reading = readings[i]
				max_index = i

		# Turn towards that sensor
		if max_reading > 0.1:
			var turn_angle = sensors[max_index].angle
			rotate_y(turn_angle * rotation_speed * delta)

		# Move forward
		var forward = -global_transform.basis.z
		velocity = forward * max_speed

	func check_food_consumption(food_items: Array) -> FoodItem:
		"""Check if creature is close enough to consume food"""
		for food in food_items:
			if food.consumed:
				continue

			var dist = position_v.distance_to(food.position)
			if dist < 0.05:
				return food

		return null

# Main scene
var creature: SensorCreature
var food_items: Array[FoodItem] = []
var num_food: int = 8
var score: int = 0

# UI
var score_label: Label3D
var sensor_label: Label3D

func _ready():
	# Create creature
	creature = SensorCreature.new()
	creature.position_v = Vector3(0, 0, 0)
	add_child(creature)

	# Spawn food
	spawn_food()

	# Create UI
	create_ui()

func spawn_food():
	"""Spawn food items randomly in tank"""
	for i in range(num_food):
		var food = FoodItem.new()
		food.position = Vector3(
			randf_range(-0.35, 0.35),
			randf_range(-0.25, 0.25),
			randf_range(-0.35, 0.35)
		)
		add_child(food)
		food_items.append(food)

func create_ui():
	score_label = Label3D.new()
	score_label.text = "Food: 0"
	score_label.font_size = 32
	score_label.outline_size = 4
	score_label.position = Vector3(0, 0.4, -0.4)
	score_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(score_label)

	sensor_label = Label3D.new()
	sensor_label.text = "Sensors: [0 0 0 0 0]"
	sensor_label.font_size = 20
	sensor_label.outline_size = 2
	sensor_label.position = Vector3(0, 0.35, -0.4)
	sensor_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(sensor_label)

func _process(delta):
	# Creature senses environment
	var readings = creature.sense(food_items)

	# Display sensor readings
	var reading_text = "Sensors: ["
	for i in range(readings.size()):
		reading_text += str(snappedf(readings[i], 0.1))
		if i < readings.size() - 1:
			reading_text += " "
	reading_text += "]"
	sensor_label.text = reading_text

	# Move creature based on sensor input
	creature.move_towards_food(readings, delta)

	# Check food consumption
	var consumed_food = creature.check_food_consumption(food_items)
	if consumed_food:
		score += 1
		score_label.text = "Food: " + str(score)
		consumed_food.consumed = true
		food_items.erase(consumed_food)
		consumed_food.queue_free()

		# Spawn new food
		var new_food = FoodItem.new()
		new_food.position = Vector3(
			randf_range(-0.35, 0.35),
			randf_range(-0.25, 0.25),
			randf_range(-0.35, 0.35)
		)
		add_child(new_food)
		food_items.append(new_food)
