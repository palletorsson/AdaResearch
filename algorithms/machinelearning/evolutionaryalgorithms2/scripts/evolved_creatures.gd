extends Node3D

## Evolved Creatures – a population of exotic creature types evolving via genetic algorithm.
## Creature morphologies include symbiotic clusters, phase-shifting blobs, recursive fractals,
## resonance wave-forms, and topology-changing shapes.

# ──────────────────────────────────────────────
# Configuration — all @export vars can be tweaked at runtime
# ──────────────────────────────────────────────
@export_range(4, 50) var population_size: int = 20:
	set(v):
		population_size = v
@export_range(0.01, 0.5) var mutation_rate: float = 0.1
@export_range(0.1, 1.0) var crossover_rate: float = 0.7
@export_range(5.0, 120.0) var evolution_interval: float = 30.0

# Creature types
enum CreatureType {SYMBIOTIC, PHASE_SHIFTING, RECURSIVE, RESONANCE, TOPOLOGY}

# Resources
var creature_scene = preload("res://algorithms/machinelearning/evolutionaryalgorithms2/scenes/creature.tscn")
var evolution_timer: Timer
var creatures = []
var environment: Node3D
var _generation_count: int = 0
var _status_label: Label3D

func _ready() -> void:
	# Setup VR
	setup_vr()
	
	# Setup environment
	setup_environment()
	
	# Initialize creatures
	initialize_population()
	
	# Setup evolution timer
	evolution_timer = Timer.new()
	evolution_timer.wait_time = evolution_interval
	evolution_timer.connect("timeout", Callable(self, "_on_evolution_timer_timeout"))
	add_child(evolution_timer)
	evolution_timer.start()
	
	# 3D HUD label for generation info
	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 42
	_status_label.modulate = Color(1.0, 0.85, 0.2)
	_status_label.outline_modulate = Color(0, 0, 0, 0.6)
	_status_label.outline_size = 4
	_status_label.position = Vector3(0, 6, 0)
	_status_label.text = "Generation 0 | Pop %d" % population_size
	add_child(_status_label)

func setup_vr() -> void:
	var xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		get_viewport().use_xr = true
	
	# Add XR Origin and Controllers
	var xr_origin = XROrigin3D.new()
	var xr_camera = XRCamera3D.new()
	var left_controller = XRController3D.new()
	var right_controller = XRController3D.new()
	
	left_controller.tracker = "left_hand"
	right_controller.tracker = "right_hand"
	
	xr_origin.add_child(xr_camera)
	xr_origin.add_child(left_controller)
	xr_origin.add_child(right_controller)
	add_child(xr_origin)
	
	# Connect controller signals
	left_controller.button_pressed.connect(Callable(self, "_on_controller_button_pressed").bind(left_controller))
	right_controller.button_pressed.connect(Callable(self, "_on_controller_button_pressed").bind(right_controller))

func setup_environment() -> void:
	environment = Node3D.new()
	environment.name = "Environment"
	add_child(environment)
	
	# Add a ground plane
	var ground = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(50, 50)
	ground.mesh = plane_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.3, 0.4)
	material.roughness = 0.85
	material.metallic = 0.05
	ground.material_override = material
	
	var ground_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = BoxShape3D.new()
	collision_shape.shape.size = Vector3(50, 0.1, 50)
	ground_body.add_child(collision_shape)
	
	ground_body.add_child(ground)
	environment.add_child(ground_body)
	ground_body.position.y = -0.5
	
	# Add ambient light
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 45, 0)
	environment.add_child(light)

func initialize_population() -> void:
	for i in range(population_size):
		var creature = spawn_random_creature()
		creatures.append(creature)

func spawn_random_creature() -> Node3D:
	var creature = creature_scene.instantiate()
	
	# Set random creature type
	var creature_type = randi() % CreatureType.size()
	creature.initialize(creature_type)
	
	# Set random position
	var pos_x = randf_range(-10, 10)
	var pos_z = randf_range(-10, 10)
	creature.position = Vector3(pos_x, 0, pos_z)
	
	environment.add_child(creature)
	return creature

func _on_evolution_timer_timeout() -> void:
	evolve_population()

func evolve_population() -> void:
	_generation_count += 1
	
	# Sort creatures by fitness
	creatures.sort_custom(Callable(self, "_sort_by_fitness"))
	
	# Flash the best creature with gold emission
	if creatures.size() > 0:
		var best = creatures[0]
		if best.body_parts.size() > 0 and is_instance_valid(best.body_parts[0]):
			var mesh_child = best.body_parts[0].get_child(1) if best.body_parts[0].get_child_count() > 1 else null
			if mesh_child is MeshInstance3D and mesh_child.material_override is StandardMaterial3D:
				var mat = mesh_child.material_override as StandardMaterial3D
				var old_emission = mat.emission
				mat.emission = Color(1.0, 0.85, 0.2) * 0.8
				var flash_tw = create_tween()
				flash_tw.tween_property(mat, "emission", old_emission, 1.2)
	
	# Update HUD label
	if _status_label:
		var best_fit = creatures[0].get_fitness() if creatures.size() > 0 else 0.0
		_status_label.text = "Gen %d | Pop %d | Best %.1f" % [_generation_count, creatures.size(), best_fit]
	
	# Keep top performers
	var elite_count = max(1, population_size / 10)
	var new_creatures = []
	
	for i in range(elite_count):
		new_creatures.append(creatures[i])
	
	# Create offspring until we reach population_size
	while new_creatures.size() < population_size:
		var parent1 = select_parent()
		
		if randf() < crossover_rate:
			# Sexual reproduction - crossover
			var parent2 = select_parent()
			var child = crossover(parent1, parent2)
			new_creatures.append(child)
		else:
			# Asexual reproduction - clone with mutation
			var child = clone(parent1)
			new_creatures.append(child)
	
	# Replace old population with new one
	for i in range(creatures.size()):
		if i >= new_creatures.size():
			creatures[i].queue_free()
	
	creatures = new_creatures

func select_parent():
	# Tournament selection
	var tournament_size = 3
	var best = null
	var best_fitness = -INF
	
	for _i in range(tournament_size):
		var contestant = creatures[randi() % creatures.size()]
		var fitness = contestant.get_fitness()
		
		if fitness > best_fitness:
			best = contestant
			best_fitness = fitness
	
	return best

func crossover(parent1, parent2):
	var child = creature_scene.instantiate()
	
	# Genetic crossover logic
	var genes1 = parent1.get_genes()
	var genes2 = parent2.get_genes()
	var child_genes = {}
	
	# Simple crossover - each gene has 50% chance from each parent
	for key in genes1.keys():
		if key in genes2:
			if randf() < 0.5:
				child_genes[key] = genes1[key]
			else:
				child_genes[key] = genes2[key]
		else:
			child_genes[key] = genes1[key]
	
	# Add any genes from parent2 that weren't in parent1
	for key in genes2.keys():
		if not key in genes1:
			child_genes[key] = genes2[key]
	
	# Apply mutation
	mutate(child_genes)
	
	# Initialize with new genes
	child.initialize_from_genes(child_genes)
	
	# Set random position
	var pos_x = randf_range(-10, 10)
	var pos_z = randf_range(-10, 10)
	child.position = Vector3(pos_x, 0, pos_z)
	
	environment.add_child(child)
	return child

func clone(parent):
	var child = creature_scene.instantiate()
	
	# Clone genes
	var genes = parent.get_genes().duplicate(true)
	
	# Apply mutation
	mutate(genes)
	
	# Initialize with new genes
	child.initialize_from_genes(genes)
	
	# Set random position
	var pos_x = randf_range(-10, 10)
	var pos_z = randf_range(-10, 10)
	child.position = Vector3(pos_x, 0, pos_z)
	
	environment.add_child(child)
	return child

func mutate(genes) -> void:
	for key in genes.keys():
		if randf() < mutation_rate:
			# If it's a numeric value, mutate by adding/subtracting a small amount
			if typeof(genes[key]) == TYPE_FLOAT:
				genes[key] += randf_range(-0.2, 0.2)
			elif typeof(genes[key]) == TYPE_INT:
				genes[key] += randi_range(-1, 1)
			elif typeof(genes[key]) == TYPE_VECTOR3:
				genes[key].x += randf_range(-0.2, 0.2)
				genes[key].y += randf_range(-0.2, 0.2)
				genes[key].z += randf_range(-0.2, 0.2)
			# For other types like arrays, you would need custom mutation logic

func _sort_by_fitness(a, b):
	return a.get_fitness() > b.get_fitness()

func _on_controller_button_pressed(button_name, controller) -> void:
	if button_name == "trigger_click":
		# Raycast from controller to identify creature
		var from = controller.global_transform.origin
		var to = from + controller.global_transform.basis.z * -10
		
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		var result = space_state.intersect_ray(query)
		
		if result and result.collider.get_parent() in creatures:
			var creature = result.collider.get_parent()
			creature.interact()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

