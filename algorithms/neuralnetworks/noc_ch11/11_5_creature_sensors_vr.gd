extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_AGENT := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_AGENT_HIGHLIGHT := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")
const MAT_FOOD := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")

const MIN_Y := 0.05
const MAX_Y := 0.95
const MIN_X := -0.45
const MAX_X := 0.45
const MIN_Z := -0.45
const MAX_Z := 0.45

@export var sensor_length: float = 0.35
@export var sensor_count: int = 16
@export var food_radius: float = 0.12
@export var food_speed: float = 0.4

var _sim_root: Node3D
var _creature: SensorCreature
var _food: FoodTarget
var _status_label: Label3D
var _time: float = 0.0

func _ready() -> void:
	_setup_environment()
	_spawn_food()
	_spawn_creature()
	_update_status()
	set_physics_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	_sim_root.name = "SimulationRoot"
	add_child(_sim_root)


	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.position = Vector3(0, 0.82, 0)
	_status_label.text = "" 
	_sim_root.add_child(_status_label)

	_create_controllers()

func _create_controllers() -> void:
	var controller_root := Node3D.new()
	controller_root.name = "Controllers"
	controller_root.position = Vector3(0.75, 0.45, 0)
	add_child(controller_root)

	var length_controller := CONTROLLER_SCENE.instantiate()
	length_controller.parameter_name = "Sensor Length"
	length_controller.min_value = 0.1
	length_controller.max_value = 0.6
	length_controller.default_value = sensor_length
	length_controller.position = Vector3(0, 0.1, 0)
	length_controller.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(length_controller)
	length_controller.value_changed.connect(func(v: float) -> void:
		sensor_length = v
		if _creature:
			_creature.sensor_length = v
	)
	length_controller.set_value(sensor_length)

	var speed_controller := CONTROLLER_SCENE.instantiate()
	speed_controller.parameter_name = "Food Speed"
	speed_controller.min_value = 0.0
	speed_controller.max_value = 1.0
	speed_controller.default_value = food_speed
	speed_controller.position = Vector3(0, -0.15, 0)
	speed_controller.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(speed_controller)
	speed_controller.value_changed.connect(func(v: float) -> void:
		food_speed = v
	)
	speed_controller.set_value(food_speed)

func _spawn_food() -> void:
	_food = FoodTarget.new()
	_food.init(_sim_root, MAT_FOOD, food_radius)

func _spawn_creature() -> void:
	_creature = SensorCreature.new()
	_creature.init(_sim_root, MAT_AGENT, MAT_AGENT_HIGHLIGHT, sensor_count, sensor_length)
	_creature.position = Vector3(0.0, 0.45, 0.0)

func _physics_process(delta: float) -> void:
	_time += delta

	# orbit creature slightly for subtle motion
	var orbit_radius := 0.15
	var orbit_height := 0.5 + 0.05 * sin(_time * 0.8)
	_creature.position = Vector3(orbit_radius * sin(_time * 0.5), orbit_height, 0.1 * cos(_time * 0.5))

	_update_food(delta)
	_creature.sensor_length = sensor_length
	_creature.update_sensors(_food)

	_update_status()

func _update_food(delta: float) -> void:
	_food.radius = food_radius
	_food.update_position(food_speed, delta)

func _update_status() -> void:
	var strongest: float = _creature.strongest_activation()
	_status_label.text = "Sensors active: %.0f%%" % (strongest * 100.0)

class SensorCreature:
	var root: Node3D
	var body: MeshInstance3D
	var sensors: Array[SensorBeam] = []
	var sensor_length: float = 0.3
	var position: Vector3:
		get:
			return root.global_position
		set(value):
			root.global_position = value

	func init(parent: Node3D, body_mat: Material, highlight_mat: Material, count: int, length: float) -> void:
		sensor_length = length
		root = Node3D.new()
		root.name = "Creature"
		parent.add_child(root)

		body = MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.06
		body.mesh = sphere
		body.material_override = body_mat
		root.add_child(body)

		sensors.clear()
		for i in range(count):
			var angle := TAU * float(i) / float(count)
			var direction := Vector3(cos(angle), sin(angle), 0)
			var beam := SensorBeam.new()
			beam.init(root, direction, sensor_length, body_mat, highlight_mat)
			sensors.append(beam)

	func update_sensors(food: FoodTarget) -> void:
		for beam in sensors:
			beam.length = sensor_length
			beam.update(position, food)

	func strongest_activation() -> float:
		var max_value := 0.0
		for beam in sensors:
			max_value = max(max_value, beam.value)
		return max_value

	func queue_free() -> void:
		if is_instance_valid(root):
			root.queue_free()

class SensorBeam:
	var direction: Vector3
	var length: float
	var value: float = 0.0
	var node: Node3D
	var beam_mesh: MeshInstance3D
	var tip_mesh: MeshInstance3D
	var base_material: Material
	var highlight_material: Material

	func init(parent: Node3D, dir: Vector3, beam_length: float, base_mat: Material, highlight_mat: Material) -> void:
		direction = dir.normalized()
		length = beam_length
		base_material = base_mat
		highlight_material = highlight_mat

		node = Node3D.new()
		node.name = "SensorBeam"
		parent.add_child(node)

		beam_mesh = MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.01
		cylinder.bottom_radius = 0.01
		cylinder.height = 1.0
		beam_mesh.mesh = cylinder
		beam_mesh.material_override = base_mat
		node.add_child(beam_mesh)

		tip_mesh = MeshInstance3D.new()
		var tip := SphereMesh.new()
		tip.radius = 0.02
		tip_mesh.mesh = tip
		var tip_mat := StandardMaterial3D.new()
		if highlight_mat is StandardMaterial3D:
			tip_mat.albedo_color = (highlight_mat as StandardMaterial3D).albedo_color
		else:
			tip_mat.albedo_color = Color.WHITE
		tip_mesh.material_override = tip_mat
		tip_mesh.visible = false
		node.add_child(tip_mesh)

	func update(origin: Vector3, food: FoodTarget) -> void:
		var tip_pos := origin + direction * length
		node.position = origin

		# orient beam towards tip (cylinder defaults along +Y)
		var direction_to_tip = (tip_pos - node.position).normalized()
		var up_vector = Vector3.UP
		if abs(direction_to_tip.dot(Vector3.UP)) > 0.9:  # If direction is nearly vertical
			up_vector = Vector3.RIGHT  # Use right vector instead
		
		node.look_at_from_position(node.position, tip_pos, up_vector)
		node.rotate_x(-PI / 2.0)

		beam_mesh.scale = Vector3(0.08, length, 0.08)
		beam_mesh.position = Vector3(0, 0, length * 0.5)

		tip_mesh.position = Vector3(0, 0, length)

		var dist := tip_pos.distance_to(food.position)
		if dist < food.radius:
			value = 1.0 - clamp(dist / food.radius, 0.0, 1.0)
			tip_mesh.visible = true
			if tip_mesh.material_override is StandardMaterial3D:
				var color: Color = highlight_material.albedo_color.lerp(Color.WHITE, value * 0.4)
				(tip_mesh.material_override as StandardMaterial3D).albedo_color = color
		else:
			value = 0.0
			tip_mesh.visible = false

class FoodTarget:
	var root: Node3D
	var mesh: MeshInstance3D
	var radius: float = 0.12
	var angle: float = 0.0
	var position: Vector3:
		get:
			return root.global_position
		set(value):
			root.global_position = value

	func init(parent: Node3D, material: Material, rad: float) -> void:
		radius = rad
		root = Node3D.new()
		root.name = "Food"
		parent.add_child(root)

		mesh = MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = rad
		mesh.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.7, 0.95, 0.6)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh.material_override = mat
		root.add_child(mesh)
		position = Vector3(0.25, 0.65, 0)

	func update_position(speed: float, delta: float) -> void:
		angle += speed * delta
		var orbit_radius := 0.25
		var x := 0.2 + orbit_radius * cos(angle)
		var y := 0.6 + 0.1 * sin(angle * 1.5)
		var z := 0.15 * sin(angle * 0.8)
		position = Vector3(clamp(x, MIN_X, MAX_X), clamp(y, MIN_Y, MAX_Y), clamp(z, MIN_Z, MAX_Z))
		if mesh and mesh.mesh is SphereMesh:
			(mesh.mesh as SphereMesh).radius = radius

class Hazard:
	pass
