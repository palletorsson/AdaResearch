extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_AGENT := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_AGENT_HIGHLIGHT := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")
const MAT_HAZARD := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")
const MAT_TARGET := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

const MIN_Y := 0.05
const MAX_Y := 0.95
const MIN_X := -0.45
const MAX_X := 0.45

@export var population_size: int = 18
@export var mutation_rate: float = 0.04
@export var lifespan: int = 480
@export var max_force: float = 0.12
@export var hazard_radius: float = 0.12
@export var sensor_range: float = 0.3

var _sim_root: Node3D
var _agents: Array = []                 # keep generic to avoid forward-ref issues
var _hazards: Array = []                # Array[Hazard]
var _targets: Array[Vector3] = []       # this one can be typed precisely
var _step: int = 0
var _generation: int = 1
var _status_label: Label3D

func _ready() -> void:
	randomize()
	_setup_environment()
	_spawn_hazards()
	_spawn_targets()
	_spawn_population()
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
	controller_root.position = Vector3(0.75, 0.45, 0)
	add_child(controller_root)

	var mutation_controller := CONTROLLER_SCENE.instantiate()
	mutation_controller.parameter_name = "Mutation"
	mutation_controller.min_value = 0.01
	mutation_controller.max_value = 0.2
	mutation_controller.default_value = mutation_rate
	mutation_controller.position = Vector3(0, 0.1, 0)
	mutation_controller.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(mutation_controller)
	mutation_controller.value_changed.connect(func(v: float) -> void:
		mutation_rate = v
	)
	mutation_controller.set_value(mutation_rate)

	var sensor_controller := CONTROLLER_SCENE.instantiate()
	sensor_controller.parameter_name = "Sensor Range"
	sensor_controller.min_value = 0.1
	sensor_controller.max_value = 0.6
	sensor_controller.default_value = sensor_range
	sensor_controller.position = Vector3(0, -0.15, 0)
	sensor_controller.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(sensor_controller)
	sensor_controller.value_changed.connect(func(v: float) -> void:
		sensor_range = v
		for agent in _agents:
			agent.sensor_range = v
	)
	sensor_controller.set_value(sensor_range)

func _spawn_hazards() -> void:
	for h in _hazards:
		h.queue_free()
	_hazards.clear()

	var centers := [Vector3(0.0, 0.5, 0), Vector3(0.25, 0.3, 0), Vector3(-0.25, 0.7, 0)]
	for center in centers:
		var hazard := Hazard.new()
		hazard.init(_sim_root, center, hazard_radius, MAT_HAZARD)
		_hazards.append(hazard)

func _spawn_targets() -> void:
	_targets = [
		Vector3(0.4, 0.8, 0),
		Vector3(0.4, 0.2, 0),
		Vector3(-0.3, 0.85, 0)
	]
	for target_pos in _targets:
		var marker := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.04
		marker.mesh = sphere
		marker.material_override = MAT_TARGET
		marker.position = target_pos
		_sim_root.add_child(marker)

func _spawn_population() -> void:
	for a in _agents:
		a.queue_free()
	_agents.clear()

	for i in range(population_size):
		var creature := Agent.new()
		creature.init(_sim_root, MAT_AGENT, MAT_AGENT_HIGHLIGHT, lifespan, max_force)
		creature.root.position = Vector3(-0.35, 0.2 + (i % 5) * 0.08, 0)
		creature.sensor_range = sensor_range
		_agents.append(creature)

func _physics_process(delta: float) -> void:
	if _agents.is_empty():
		return

	if _step >= lifespan:
		_next_generation()
		return

	for agent in _agents:
		agent.apply_gene(_step)
		agent.update(delta, _targets, _hazards)

	_step += 1

	var best_fit: float = 0.0
	var all_done := true
	for agent in _agents:
		best_fit = max(best_fit, agent.fitness)
		if not (agent.done or agent.crashed):
			all_done = false

	_highlight_best(best_fit)
	_update_status(best_fit)

	if all_done:
		_next_generation()

func _highlight_best(best_fit: float) -> void:
	var threshold := best_fit * 0.98
	for agent in _agents:
		agent.set_highlight(best_fit > 0.0 and agent.fitness >= threshold and agent.done)

func _update_status(best_fit: float = 0.0) -> void:
	_status_label.text = "Gen %d | Step %d/%d | Best %.2f" % [_generation, _step, lifespan, best_fit]

func _next_generation() -> void:
	var mating_pool: Array = []
	var max_fit: float = 0.0
	for agent in _agents:
		max_fit = max(max_fit, agent.fitness)
	if max_fit <= 0.0:
		max_fit = 0.001

	for agent in _agents:
		var normalized: float = float(agent.fitness) / max_fit
		var n: int = int(normalized * 40.0)
		for j in range(n):
			mating_pool.append(agent)
	if mating_pool.is_empty():
		mating_pool = _agents.duplicate()

	var new_generation: Array = []
	for agent in _agents:
		agent.queue_free()

	for i in range(population_size):
		var parent = mating_pool[randi() % mating_pool.size()]
		var child := Agent.new()
		child.init(_sim_root, MAT_AGENT, MAT_AGENT_HIGHLIGHT, lifespan, max_force)
		child.root.position = Vector3(-0.35, 0.2 + (i % 5) * 0.08, 0)
		child.sensor_range = sensor_range
		child.brain.copy_from(parent.brain)
		child.brain.mutate(mutation_rate, max_force)
		new_generation.append(child)

	_agents = new_generation
	_generation += 1
	_step = 0
	_update_status()

# ============================ CLASSES ============================

class Agent:
	var root: Node3D
	var body: MeshInstance3D
	var sensor_mesh: MeshInstance3D
	var velocity: Vector3 = Vector3.ZERO
	var acceleration: Vector3 = Vector3.ZERO
	var dna := DNA.new()
	var brain := SteeringBrain.new()
	var done: bool = false
	var crashed: bool = false
	var fitness: float = 0.0
	var sensor_range: float = 0.3
	var max_force_limit: float = 0.12

	func init(parent: Node3D, body_material: Material, _highlight_material: Material, genome_length: int, max_force_value: float) -> void:
		root = Node3D.new()
		root.name = "Agent"
		parent.add_child(root)

		body = MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.04
		cone.height = 0.12
		body.mesh = cone
		body.material_override = body_material
		body.rotation_degrees = Vector3(0, 0, -90)
		root.add_child(body)

		sensor_mesh = MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.05
		sensor_mesh.mesh = sphere
		var smat := StandardMaterial3D.new()
		smat.albedo_color = Color(1.0, 0.7, 1.0, 0.25)
		smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sensor_mesh.material_override = smat
		sensor_mesh.visible = false
		sensor_mesh.scale = Vector3.ONE
		root.add_child(sensor_mesh)

		dna.generate_random(genome_length)
		brain.randomize()
		max_force_limit = max_force_value

	func apply_gene(step: int) -> void:
		if done or crashed:
			return
		acceleration += dna.get_force(step)

	func update(delta: float, targets: Array[Vector3], hazards: Array) -> void:
		if done or crashed:
			return

		velocity += acceleration
		velocity = velocity.limit_length(0.7)
		root.position += velocity * delta * 60.0
		acceleration = Vector3.ZERO

		if targets.is_empty():
			return
		var closest: Vector3 = _find_closest_target(targets)
		var hazard_force: Vector3 = _avoid_hazards(hazards)
		var to_target: Vector3 = closest - root.position

		var seek_force: Vector3 = Vector3.ZERO
		if to_target != Vector3.ZERO:
			seek_force = to_target.normalized() * max_force_limit

		acceleration += seek_force + hazard_force

		var dist: float = root.position.distance_to(closest)
		fitness += max(0.0, 1.3 - dist * 2.5) * delta
		if dist < 0.07:
			done = true
			fitness += 8.0

		if root.position.x < MIN_X or root.position.x > MAX_X or root.position.y < MIN_Y or root.position.y > MAX_Y:
			crashed = true
			return

		for h in hazards:
			var hz := h as Hazard
			if hz and hz.contains_point(root.position):
				crashed = true
				return

	func _find_closest_target(targets: Array[Vector3]) -> Vector3:
		var closest: Vector3 = (targets[0] as Vector3)
		var min_dist: float = INF
		for target in targets:
			var d: float = root.position.distance_squared_to(target)
			if d < min_dist:
				min_dist = d
				closest = target
		sensor_mesh.visible = min_dist <= sensor_range * sensor_range
		sensor_mesh.scale = Vector3.ONE * sensor_range * 1.6
		return closest

	func _avoid_hazards(hazards: Array) -> Vector3:
		var steer: Vector3 = Vector3.ZERO
		for h in hazards:
			var hz := h as Hazard
			if hz == null:
				continue
			var diff: Vector3 = root.position - hz.root.position
			var dist: float = diff.length()
			if dist < sensor_range and dist > 0.001:
				steer += diff.normalized() * ((sensor_range - dist) / sensor_range) * max_force_limit
		return steer

	func set_highlight(active: bool) -> void:
		var color := Color(1.0, 0.6, 1.0, 0.6) if active else Color(1.0, 0.7, 1.0, 0.25)
		if sensor_mesh.material_override is StandardMaterial3D:
			(sensor_mesh.material_override as StandardMaterial3D).albedo_color = color

	func queue_free() -> void:
		if is_instance_valid(root):
			root.queue_free()

class DNA:
	var genes: Array = []   # Array[Vector3]

	func generate_random(length: int) -> void:
		genes.resize(length)
		for i in range(length):
			genes[i] = Vector3(randfn(0, 0.12), randfn(0, 0.12), 0.0)

	func get_force(step: int) -> Vector3:
		if step >= genes.size():
			return Vector3.ZERO
		return genes[step]

class SteeringBrain:
	var bias: float = 0.0

	func randomize() -> void:
		bias = randf_range(-0.5, 0.5)

	func copy_from(other: SteeringBrain) -> void:
		bias = other.bias

	func mutate(rate: float, _max_force_value: float) -> void:
		if randf() < rate:
			bias += randfn(0, 0.1)

class Hazard:
	var root: Node3D
	var mesh: MeshInstance3D
	var radius: float

	func init(parent: Node3D, center: Vector3, radius_value: float, _material: Material) -> void:
		radius = radius_value
		root = Node3D.new()
		root.name = "Hazard"
		root.position = center
		parent.add_child(root)

		mesh = MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = radius_value
		mesh.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.4, 0.7, 0.35)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh.material_override = mat
		root.add_child(mesh)

	func contains_point(point: Vector3) -> bool:
		return root.position.distance_to(point) <= radius

	func queue_free() -> void:
		if is_instance_valid(root):
			root.queue_free()
