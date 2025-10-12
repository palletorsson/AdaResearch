extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_BIRD := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_BIRD_CHAMP := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")
const MAT_PIPE := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")

const BIRD_X: float = -0.35
const MIN_Y: float = 0.1
const MAX_Y: float = 0.9
const PIPE_WIDTH: float = 0.12
const PIPE_DEPTH: float = 0.25
const PIPE_SPAWN_X: float = 0.55
const PIPE_DESPAWN_X: float = -0.65

@export var population_size: int = 12
@export var mutation_rate: float = 0.08
@export var pipe_gap: float = 0.38
@export var pipe_spawn_interval: float = 2.2
@export var pipe_speed: float = 0.28
@export var gravity: float = 0.55
@export var flap_strength: float = 1.8

var _sim_root: Node3D
var _birds: Array[BirdNN] = []
var _pipes: Array[Pipe] = []
var _spawn_timer: float = 0.0
var _generation: int = 1
var _score_label: Label3D
var _best_fitness: float = 0.0

func _ready() -> void:
	randomize()
	_setup_environment()
	_spawn_population()
	spawn_pipe()
	_spawn_timer = pipe_spawn_interval
	set_physics_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	_sim_root.name = "SimulationRoot"
	add_child(_sim_root)


	_score_label = Label3D.new()
	_score_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_score_label.modulate = Color(1.0, 0.85, 1.0)
	_score_label.position = Vector3(0, 0.82, 0)
	_update_label()
	_sim_root.add_child(_score_label)

	_create_controllers()

func _create_controllers() -> void:
	var controller_root := Node3D.new()
	controller_root.name = "Controllers"
	controller_root.position = Vector3(0.75, 0.45, 0.0)
	add_child(controller_root)

	var mutation_controller := CONTROLLER_SCENE.instantiate()
	mutation_controller.parameter_name = "Mutation"
	mutation_controller.min_value = 0.01
	mutation_controller.max_value = 0.3
	mutation_controller.default_value = mutation_rate
	mutation_controller.position = Vector3(0.0, 0.1, 0.0)
	mutation_controller.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(mutation_controller)
	mutation_controller.value_changed.connect(func(v: float) -> void:
		mutation_rate = v
	)
	mutation_controller.set_value(mutation_rate)

	var pipes_controller := CONTROLLER_SCENE.instantiate()
	pipes_controller.parameter_name = "Pipe Speed"
	pipes_controller.min_value = 0.15
	pipes_controller.max_value = 0.6
	pipes_controller.default_value = pipe_speed
	pipes_controller.position = Vector3(0.0, -0.15, 0.0)
	pipes_controller.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(pipes_controller)
	pipes_controller.value_changed.connect(func(v: float) -> void:
		pipe_speed = v
	)
	pipes_controller.set_value(pipe_speed)

func _spawn_population() -> void:
	for i in population_size:
		var bird := BirdNN.new()
		bird.init(_sim_root, MAT_BIRD, MAT_BIRD_CHAMP)
		bird.position = Vector3(BIRD_X, randf_range(0.2, 0.7), 0.0)
		bird.gravity = gravity
		bird.flap_strength = flap_strength
		bird.brain.mutate(0.05) # initial jitter
		_birds.append(bird)

func spawn_pipe() -> void:
	var gap_center := randf_range(MIN_Y + pipe_gap * 0.5, MAX_Y - pipe_gap * 0.5)
	var pipe := Pipe.new()
	pipe.init(_sim_root, MAT_PIPE, gap_center, pipe_gap)
	pipe.position_x = PIPE_SPAWN_X
	pipe.update_geometry(PIPE_WIDTH, PIPE_DEPTH)
	_pipes.append(pipe)

func _physics_process(delta: float) -> void:
	if _birds.is_empty():
		return

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		spawn_pipe()
		_spawn_timer = pipe_spawn_interval

	for pipe in _pipes:
		pipe.position_x -= pipe_speed * delta
		pipe.apply_positions()

	for pipe in _pipes.duplicate():
		if pipe.position_x < PIPE_DESPAWN_X:
			pipe.queue_free()
			_pipes.erase(pipe)

	var alive_count := 0
	var best_local := 0.0

	for bird in _birds:
		if not bird.alive:
			continue

		alive_count += 1
		bird.gravity = gravity
		bird.think(_pipes)
		bird.update(delta)
		bird.position = _clamp_bird_position(bird.position, bird)
		best_local = max(best_local, bird.fitness)

		for pipe in _pipes:
			if pipe.overlaps_x(bird.position.x, PIPE_WIDTH):
				if not pipe.is_within_gap(bird.position.y):
					bird.alive = false
					break

	_best_fitness = max(_best_fitness, best_local)
	if alive_count == 0:
		_next_generation()

	_update_label()

func _clamp_bird_position(pos: Vector3, bird: BirdNN) -> Vector3:
	if pos.y < MIN_Y:
		pos.y = MIN_Y
		bird.velocity.y = 0.0
		bird.alive = false
	elif pos.y > MAX_Y:
		pos.y = MAX_Y
		bird.velocity.y = 0.0
		bird.alive = false
	return pos

func _next_generation() -> void:
	var mating_pool: Array[BirdNN] = []
	for bird in _birds:
		var n := int(bird.fitness * 10.0)
		for j in n:
			mating_pool.append(bird)

	if mating_pool.is_empty():
		mating_pool = _birds.duplicate()

	for pipe in _pipes:
		pipe.queue_free()
	_pipes.clear()
	spawn_pipe()
	_spawn_timer = pipe_spawn_interval

	_generation += 1
	_best_fitness = 0.0

	var new_birds: Array[BirdNN] = []
	for i in population_size:
		var parent := mating_pool[randi() % mating_pool.size()]
		var offspring := BirdNN.new()
		offspring.init(_sim_root, MAT_BIRD, MAT_BIRD_CHAMP)
		offspring.position = Vector3(BIRD_X, randf_range(0.2, 0.7), 0.0)
		offspring.gravity = gravity
		offspring.flap_strength = flap_strength
		offspring.brain.copy_weights_from(parent.brain)
		offspring.brain.mutate(mutation_rate)
		new_birds.append(offspring)

	for bird in _birds:
		bird.queue_free()

	_birds = new_birds

func _update_label() -> void:
	_score_label.text = "Gen %d | Best %.2f" % [_generation, _best_fitness]

class BirdNN:
	var root: Node3D
	var mesh: MeshInstance3D
	var velocity: Vector3 = Vector3.ZERO
	var gravity: float = 0.5
	var flap_strength: float = 1.5
	var alive: bool = true
	var fitness: float = 0.0
	var brain := TinyBrain.new()

	var position: Vector3:
		get:
			return root.global_position
		set(value):
			root.global_position = value

	func init(parent: Node3D, body_material: Material, champ_material: Material) -> void:
		root = Node3D.new()
		root.name = "BirdNN"
		parent.add_child(root)

		mesh = MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.045
		sphere.height = 0.09
		mesh.mesh = sphere
		mesh.material_override = body_material
		root.add_child(mesh)

		var halo := MeshInstance3D.new()
		var halo_mesh := TorusMesh.new()
		halo_mesh.inner_radius = 0.03
		halo_mesh.outer_radius = 0.06
		halo.mesh = halo_mesh
		halo.material_override = champ_material
		halo.rotation_degrees = Vector3(90, 0, 0)
		halo.position = Vector3(0, 0.08, 0)
		halo.visible = false
		mesh.add_child(halo)

	func update(delta: float) -> void:
		if not alive:
			mesh.visible = false
			return

		mesh.visible = true
		velocity.y += gravity * delta
		root.position += velocity * delta
		fitness += delta

	func think(pipes: Array[Pipe]) -> void:
		if pipes.is_empty():
			return

		var next_pipe := pipes[0]
		for pipe in pipes:
			if pipe.position_x + PIPE_WIDTH * 0.5 > position.x:
				next_pipe = pipe
				break

		var inputs: Array[float] = []
		inputs.append((position.y - MIN_Y) / (MAX_Y - MIN_Y))
		inputs.append(clamp(velocity.y, -2.0, 2.0) / 2.0)
		inputs.append(next_pipe.gap_center)
		inputs.append(next_pipe.position_x)

		var decision := brain.feed_forward(inputs)
		if decision > 0.5:
			flap()

	func flap() -> void:
		velocity.y = -flap_strength

	func queue_free() -> void:
		if is_instance_valid(root):
			root.queue_free()

class Pipe:
	var root: Node3D
	var top: MeshInstance3D
	var bottom: MeshInstance3D
	var gap_center: float = 0.5
	var gap_size: float = 0.3
	var position_x: float = 0.5

	func init(parent: Node3D, pipe_material: Material, gap: float, gap_extent: float) -> void:
		root = Node3D.new()
		root.name = "Pipe"
		parent.add_child(root)
		gap_center = gap
		gap_size = gap_extent

		top = MeshInstance3D.new()
		bottom = MeshInstance3D.new()
		top.material_override = pipe_material
		bottom.material_override = pipe_material
		root.add_child(top)
		root.add_child(bottom)

	func update_geometry(width: float, depth_size: float) -> void:
		var top_height := (MAX_Y - gap_center) - gap_size * 0.5
		var bottom_height := (gap_center - MIN_Y) - gap_size * 0.5
		top_height = max(top_height, 0.05)
		bottom_height = max(bottom_height, 0.05)

		var top_mesh := BoxMesh.new()
		top_mesh.size = Vector3(width, top_height, depth_size)
		top.mesh = top_mesh

		var bottom_mesh := BoxMesh.new()
		bottom_mesh.size = Vector3(width, bottom_height, depth_size)
		bottom.mesh = bottom_mesh

		apply_positions()

	func apply_positions() -> void:
		top.position = Vector3(position_x, gap_center + gap_size * 0.5 + top.mesh.size.y * 0.5, 0)
		bottom.position = Vector3(position_x, gap_center - gap_size * 0.5 - bottom.mesh.size.y * 0.5, 0)

	func overlaps_x(bird_x: float, width: float) -> bool:
		return bird_x > position_x - width * 0.5 and bird_x < position_x + width * 0.5

	func is_within_gap(bird_y: float) -> bool:
		return bird_y > gap_center - gap_size * 0.5 and bird_y < gap_center + gap_size * 0.5

	func queue_free() -> void:
		if is_instance_valid(top):
			top.queue_free()
		if is_instance_valid(bottom):
			bottom.queue_free()
		if is_instance_valid(root):
			root.queue_free()

class TinyBrain:
	var weights: Array[float] = []

	func _init():
		weights.resize(8)
		for i in weights.size():
			weights[i] = randf_range(-1.0, 1.0)

	func feed_forward(inputs: Array[float]) -> float:
		var sum := 0.0
		for i in range(inputs.size()):
			if i < weights.size():
				sum += inputs[i] * weights[i]
		return 1.0 / (1.0 + exp(-sum))

	func mutate(rate: float) -> void:
		for i in weights.size():
			if randf() < rate:
				weights[i] += randfn(0.0, 0.3)

	func copy_weights_from(other: TinyBrain) -> void:
		weights = other.weights.duplicate()
