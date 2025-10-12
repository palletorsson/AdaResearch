extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_BLOOP := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_BLOOP_ALPHA := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")
const MAT_FOOD := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")

const MIN_X := -0.45
const MAX_X := 0.45
const MIN_Y := 0.05
const MAX_Y := 0.95
const MIN_Z := -0.15
const MAX_Z := 0.15

@export var initial_population: int = 20
@export var mutation_rate: float = 0.01
@export var food_spawn_interval: float = 2.0

var _sim_root: Node3D
var _bloops: Array[Bloop] = []
var _foods: Array[FoodItem] = []
var _spawn_timer: float = 0.0
var _status_label: Label3D
var _generation: int = 1
var _births: int = 0

func _ready() -> void:
	randomize()
	_setup_environment()
	_spawn_initial_population()
	set_physics_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)
	_sim_root.name = "SimulationRoot"


	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 22
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.position = Vector3(0, 0.82, 0)
	_sim_root.add_child(_status_label)

	_create_controllers()
	_update_status()

func _create_controllers() -> void:
	var controller_root := Node3D.new()
	controller_root.position = Vector3(0.75, 0.45, 0)
	add_child(controller_root)

	var mutation_controller := CONTROLLER_SCENE.instantiate()
	mutation_controller.parameter_name = "Mutation"
	mutation_controller.min_value = 0.0
	mutation_controller.max_value = 0.1
	mutation_controller.default_value = mutation_rate
	mutation_controller.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(mutation_controller)
	mutation_controller.value_changed.connect(func(v: float) -> void:
		mutation_rate = clamp(v, 0.0, 0.1)
	)
	mutation_controller.set_value(mutation_rate)

	var food_controller := CONTROLLER_SCENE.instantiate()
	food_controller.parameter_name = "Food Interval"
	food_controller.min_value = 0.5
	food_controller.max_value = 4.0
	food_controller.default_value = food_spawn_interval
	food_controller.position = Vector3(0, -0.18, 0)
	food_controller.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(food_controller)
	food_controller.value_changed.connect(func(v: float) -> void:
		food_spawn_interval = v
	)
	food_controller.set_value(food_spawn_interval)

func _spawn_initial_population() -> void:
	for i in range(initial_population):
		_spawn_bloop(Vector3(randf_range(MIN_X, MAX_X), randf_range(MIN_Y, MAX_Y), randf_range(MIN_Z, MAX_Z)))

	for i in range(initial_population):
		_spawn_food(Vector3(randf_range(MIN_X, MAX_X), randf_range(MIN_Y, MAX_Y), randf_range(MIN_Z, MAX_Z)))

func _spawn_bloop(pos: Vector3, dna_value: DNA = DNA.new()) -> void:
	var bloop := Bloop.new()
	bloop.init(_sim_root, pos, dna_value)
	_bloops.append(bloop)

func _spawn_food(pos: Vector3) -> void:
	var food := FoodItem.new()
	food.init(_sim_root, pos, MAT_FOOD)
	_foods.append(food)

func _physics_process(delta: float) -> void:
	_spawn_timer += delta
	if _spawn_timer >= food_spawn_interval:
		_spawn_food(Vector3(randf_range(MIN_X, MAX_X), randf_range(MIN_Y, MAX_Y), randf_range(MIN_Z, MAX_Z)))
		_spawn_timer = 0.0

	for food in _foods:
		food.pulse(delta)

	var new_births := []
	for bloop in _bloops:
		bloop.update(delta)
		bloop.wrap_bounds(MIN_X, MAX_X, MIN_Y, MAX_Y, MIN_Z, MAX_Z)
		bloop.consume_food(_foods)
		var child_dna := bloop.maybe_reproduce(mutation_rate)
		if child_dna:
			var child_pos := bloop.position + Vector3(randf_range(-0.05, 0.05), randf_range(-0.05, 0.05), 0)
			child_pos = Vector3(clamp(child_pos.x, MIN_X, MAX_X), clamp(child_pos.y, MIN_Y, MAX_Y), clamp(child_pos.z, MIN_Z, MAX_Z))
			new_births.append([child_pos, child_dna])

	for entry in new_births:
		_spawn_bloop(entry[0], entry[1])
		_births += 1

	for bloop in _bloops.duplicate():
		if bloop.is_dead():
			_spawn_food(bloop.position)
			bloop.queue_free()
			_bloops.erase(bloop)

	for food in _foods.duplicate():
		if food.consumed:
			food.queue_free()
			_foods.erase(food)

	_update_status()

func _update_status() -> void:
	_status_label.text = "Gen %d | Bloops %d | Food %d | Births %d" % [_generation, _bloops.size(), _foods.size(), _births]

class DNA:
	var gene: float

	func _init():
		gene = clamp(randf(), 0.0, 1.0)

	func copy() -> DNA:
		var clone := DNA.new()
		clone.gene = gene
		return clone

	func mutate(rate: float) -> void:
		if randf() < rate:
			gene = clamp(gene + randfn(0, 0.1), 0.0, 1.0)

class Bloop:
	var root: Node3D
	var body: MeshInstance3D
	var dna: DNA
	var velocity: Vector3 = Vector3.ZERO
	var energy: float = 200.0
	var heading: float = randf_range(0, TAU)
	var max_speed: float = 0.3
	var radius: float = 0.05
	var noise_offset: Vector2 = Vector2(randf() * 1000.0, randf() * 1000.0)

	var position: Vector3:
		get:
			return root.global_position
		set(value):
			root.global_position = value

	func init(parent: Node3D, pos: Vector3, dna_value: DNA) -> void:
		dna = dna_value
		root = Node3D.new()
		root.name = "Bloop"
		parent.add_child(root)
		root.global_position = pos

		body = MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.05
		body.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.6, 0.9, 0.8)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.6, 0.9) * 0.4
		body.material_override = mat
		root.add_child(body)

		_apply_traits()

	func _apply_traits() -> void:
		radius = lerp(0.03, 0.12, dna.gene)
		max_speed = lerp(0.6, 0.2, dna.gene)
		if body.mesh is SphereMesh:
			(body.mesh as SphereMesh).radius = radius

	func update(delta: float) -> void:
		var vx: float = lerp(-max_speed, max_speed, _noise(noise_offset.x))
		var vy: float = lerp(-max_speed, max_speed, _noise(noise_offset.y))
		noise_offset.x += 0.6 * delta
		noise_offset.y += 0.6 * delta
		velocity = Vector3(vx, vy, 0)
		position += velocity * delta * 60.0
		energy -= delta * lerp(0.4, 0.18, dna.gene)
		var transparency: float = clamp(energy / 200.0, 0.1, 1.0)
		if body.material_override and body.material_override is StandardMaterial3D:
			var mat := body.material_override as StandardMaterial3D
			mat.albedo_color = Color(1.0, 0.6, 0.9, transparency)

	func _noise(t: float) -> float:
		# Simple smooth pseudo-noise in [0,1]
		return 0.5 + 0.5 * sin(t)

	func consume_food(foods: Array[FoodItem]) -> void:
		for food in foods.duplicate():
			if food.consumed:
				continue
			if position.distance_to(food.position) < radius + food.radius:
				energy += 60.0
				food.mark_consumed()

	func maybe_reproduce(rate: float) -> DNA:
		if randf() < rate * 0.2:
			var child_dna := dna.copy()
			child_dna.mutate(rate)
			return child_dna
		return null

	func wrap_bounds(min_x: float, max_x: float, min_y: float, max_y: float, min_z: float, max_z: float) -> void:
		var pos := position
		if pos.x < min_x:
			pos.x = max_x
		elif pos.x > max_x:
			pos.x = min_x
		if pos.y < min_y:
			pos.y = max_y
		elif pos.y > max_y:
			pos.y = min_y
		position = pos

	func is_dead() -> bool:
		return energy <= 0.0

	func queue_free() -> void:
		if is_instance_valid(root):
			root.queue_free()

class FoodItem:
	var root: Node3D
	var mesh: MeshInstance3D
	var consumed: bool = false
	var radius: float = 0.04
	var pulse_value: float = 0.0

	var position: Vector3:
		get:
			return root.global_position
		set(value):
			root.global_position = value

	func init(parent: Node3D, pos: Vector3, material: Material) -> void:
		root = Node3D.new()
		root.name = "Food"
		root.global_position = pos
		parent.add_child(root)

		mesh = MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = radius
		mesh.mesh = sphere
		mesh.material_override = material
		root.add_child(mesh)

	func pulse(delta: float) -> void:
		if consumed:
			return
		pulse_value += delta * 3.0
		var scale := 1.0 + 0.15 * sin(pulse_value)
		mesh.scale = Vector3.ONE * scale

	func mark_consumed() -> void:
		consumed = true
		mesh.visible = false

	func queue_free() -> void:
		if is_instance_valid(root):
			root.queue_free()
