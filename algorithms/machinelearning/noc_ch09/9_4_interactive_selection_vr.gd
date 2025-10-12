extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")

const MAX_FLOWERS := 8
const HOVER_RADIUS := 0.12

var mutation_rate: float = 0.05
var cycle_duration: float = 6.0

var _sim_root: Node3D
var _flowers: Array[FlowerEntity] = []
var _hover_orbit := 0.0
var _cycle_timer := 0.0
var _generation: int = 1
var _status_label: Label3D

func _ready() -> void:
	_setup_environment()
	_spawn_population()
	_update_status()
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	_sim_root.name = "SimulationRoot"
	add_child(_sim_root)


	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.font_size = 24
	_status_label.position = Vector3(0, 0.82, 0)
	_sim_root.add_child(_status_label)

	_create_controllers()

func _create_controllers() -> void:
	var controller_root := Node3D.new()
	controller_root.position = Vector3(0.75, 0.45, 0)
	add_child(controller_root)

	var mutation_controller := CONTROLLER_SCENE.instantiate()
	mutation_controller.parameter_name = "Mutation"
	mutation_controller.min_value = 0.0
	mutation_controller.max_value = 0.2
	mutation_controller.default_value = mutation_rate
	mutation_controller.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(mutation_controller)
	mutation_controller.value_changed.connect(func(v: float) -> void:
		mutation_rate = clamp(v, 0.0, 0.2)
	)
	mutation_controller.set_value(mutation_rate)

	var cycle_controller := CONTROLLER_SCENE.instantiate()
	cycle_controller.parameter_name = "Cycle Time"
	cycle_controller.min_value = 2.0
	cycle_controller.max_value = 10.0
	cycle_controller.default_value = cycle_duration
	cycle_controller.position = Vector3(0, -0.18, 0)
	cycle_controller.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(cycle_controller)
	cycle_controller.value_changed.connect(func(v: float) -> void:
		cycle_duration = v
	)
	cycle_controller.set_value(cycle_duration)

func _spawn_population() -> void:
	var positions := _flower_positions()
	_flowers.clear()
	for i in range(MAX_FLOWERS):
		var dna := DNA.new()
		var entity := FlowerEntity.new()
		entity.init(_sim_root, positions[i], dna)
		_flowers.append(entity)

func _flower_positions() -> Array[Vector3]:
	var poses: Array[Vector3] = []
	var rows := 2
	var cols := 4
	var x_spacing := 0.28
	var y_spacing := 0.35
	var start_x := -0.42
	var start_y := 0.3
	for row in range(rows):
		for col in range(cols):
			if poses.size() >= MAX_FLOWERS:
				break
			var pos := Vector3(start_x + col * x_spacing, start_y + row * y_spacing, 0)
			poses.append(pos)
	return poses

func _process(delta: float) -> void:
	_cycle_timer += delta
	_hover_orbit += delta * TAU / cycle_duration
	var hover_pos := Vector3(0, 0.5, 0)
	hover_pos.x += 0.25 * sin(_hover_orbit)
	hover_pos.y += 0.2 * cos(_hover_orbit)

	var total_fitness := 0.0
	var best_fit := 0.0
	for flower in _flowers:
		var active := flower.position.distance_to(hover_pos) < HOVER_RADIUS
		flower.set_hover(active)
		if active:
			flower.fitness += delta * 0.5
		total_fitness += flower.fitness
		best_fit = max(best_fit, flower.fitness)

	if _cycle_timer >= cycle_duration:
		_cycle_timer = 0.0
		_evolve()

	_update_status(best_fit)

func _evolve() -> void:
	var total_fit := 0.0
	for flower in _flowers:
		total_fit += flower.fitness
	if total_fit <= 0.0:
		total_fit = 0.001

	var new_dnas: Array[DNA] = []
	for i in range(_flowers.size()):
		var parent_a := _weighted_selection(total_fit)
		var parent_b := _weighted_selection(total_fit)
		var child := parent_a.dna.crossover(parent_b.dna)
		child.mutate(mutation_rate)
		new_dnas.append(child)

	for i in range(_flowers.size()):
		_flowers[i].apply_dna(new_dnas[i])
		_flowers[i].fitness = 1.0

	_generation += 1

func _weighted_selection(total_fit: float) -> FlowerEntity:
	var threshold := randf() * total_fit
	for flower in _flowers:
		threshold -= flower.fitness
		if threshold <= 0:
			return flower
	return _flowers.back()

func _update_status(best_fit: float = 0.0) -> void:
	_status_label.text = "Gen %d | Best %.2f | Mutation %.2f" % [_generation, best_fit, mutation_rate]

class DNA:
	var genes: Array[float] = []

	func _init(length: int = 14) -> void:
		genes.resize(length)
		for i in range(length):
			genes[i] = randf()

	func crossover(partner: DNA) -> DNA:
		var child := DNA.new(genes.size())
		var midpoint := randi() % genes.size()
		for i in range(genes.size()):
			child.genes[i] = genes[i] if i < midpoint else partner.genes[i]
		return child

	func mutate(rate: float) -> void:
		for i in range(genes.size()):
			if randf() < rate:
				genes[i] = randf()

class FlowerEntity:
	var root: Node3D
	var petals: Array[MeshInstance3D] = []
	var petal_mesh: SphereMesh
	var stem: MeshInstance3D
	var center: MeshInstance3D
	var dna: DNA
	var fitness: float = 1.0
	var position: Vector3

	func init(parent: Node3D, pos: Vector3, dna_value: DNA) -> void:
		position = pos
		dna = dna_value
		root = Node3D.new()
		root.name = "Flower"
		root.position = pos
		parent.add_child(root)

		stem = MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.01
		cylinder.bottom_radius = 0.012
		cylinder.height = 0.4
		stem.mesh = cylinder
		stem.position = Vector3(0, -0.2, 0)
		root.add_child(stem)

		petal_mesh = SphereMesh.new()
		petal_mesh.radius = 0.03

		for i in range(16):
			var petal := MeshInstance3D.new()
			petal.mesh = petal_mesh
			petal.visible = false
			root.add_child(petal)
			petals.append(petal)

		center = MeshInstance3D.new()
		var center_mesh := SphereMesh.new()
		center_mesh.radius = 0.05
		center.mesh = center_mesh
		root.add_child(center)

		apply_dna(dna)

	func apply_dna(new_dna: DNA) -> void:
		dna = new_dna
		var genes := dna.genes

		var petal_color := Color(genes[0], genes[1], genes[2], 1.0)
		var petal_size = lerp(0.03, 0.12, genes[4])
		var petal_count = clamp(int(lerp(3, 12, genes[5])), 3, 12)
		var center_color := Color(genes[6], genes[7], genes[8], 1.0)
		var center_size = lerp(0.05, 0.12, genes[9])
		var stem_color := Color(genes[10] * 0.6, genes[11], genes[12] * 0.6, 1.0)
		var stem_length = lerp(0.25, 0.45, genes[13])

		if stem.mesh is CylinderMesh:
			var cyl := stem.mesh as CylinderMesh
			cyl.height = stem_length
		stem.position = Vector3(0, -stem_length * 0.5, 0)
		var stem_mat := StandardMaterial3D.new()
		stem_mat.albedo_color = stem_color
		stem.material_override = stem_mat

		var petal_mat := StandardMaterial3D.new()
		petal_mat.albedo_color = petal_color
		petal_mat.emission_enabled = true
		petal_mat.emission = petal_color * 0.4

		petal_mesh.radius = petal_size

		for i in range(petals.size()):
			var petal := petals[i]
			if i < petal_count:
				petal.visible = true
				petal.material_override = petal_mat
				var angle := TAU * float(i) / float(petal_count)
				var offset := Vector3(petal_size * 1.4 * cos(angle), petal_size * 1.4 * sin(angle), 0)
				petal.position = offset
			else:
				petal.visible = false

		if center.mesh is SphereMesh:
			(center.mesh as SphereMesh).radius = center_size
		var center_mat := StandardMaterial3D.new()
		center_mat.albedo_color = center_color
		center_mat.emission_enabled = true
		center_mat.emission = center_color * 0.3
		center.material_override = center_mat

	func set_hover(active: bool) -> void:
		var scale = active if 1.1 else 1.0
		root.scale = Vector3(scale, scale, scale)

	func queue_free() -> void:
		if is_instance_valid(root):
			root.queue_free()
