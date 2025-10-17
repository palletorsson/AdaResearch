extends Node3D

# Evolutionary Creatures inspired by Karl Sims
# Generates random creatures and evolves them for movement

const MAX_BODY_PARTS = 8
const POPULATION_SIZE = 12
const GENERATION_TIME = 15.0
const MUTATION_RATE = 0.15

var generation := 0
var timer := 0.0
var current_population := []
var next_generation := []
var arena_floor: StaticBody3D

class CreatureGenome:
	var body_parts := []
	var joints := []
	var fitness := 0.0
	var start_position := Vector3.ZERO
	
	func _init():
		randomize_genome()
	
	func randomize_genome():
		var num_parts = randi() % (MAX_BODY_PARTS - 2) + 3
		body_parts.clear()
		joints.clear()
		
		# Root body
		body_parts.append({
			"type": "box",
			"size": Vector3(randf_range(0.4, 1.2), randf_range(0.4, 1.0), randf_range(0.4, 1.2)),
			"mass": randf_range(1.0, 3.0),
			"color": Color(randf(), randf(), randf())
		})
		
		# Add connected parts
		for i in range(1, num_parts):
			var part_type = ["box", "cylinder", "sphere"][randi() % 3]
			var part_data = {
				"type": part_type,
				"mass": randf_range(0.5, 2.0),
				"color": Color(randf(), randf(), randf())
			}
			
			if part_type == "box":
				part_data["size"] = Vector3(randf_range(0.3, 1.0), randf_range(0.3, 1.0), randf_range(0.3, 1.0))
			elif part_type == "cylinder":
				part_data["radius"] = randf_range(0.2, 0.5)
				part_data["height"] = randf_range(0.5, 1.5)
			else:
				part_data["radius"] = randf_range(0.3, 0.6)
			
			body_parts.append(part_data)
			
			# Create joint to parent
			var parent_idx = randi() % i
			var joint_type = ["pin", "hinge", "cone"][randi() % 3]
			var joint_data = {
				"type": joint_type,
				"parent": parent_idx,
				"child": i,
				"offset": Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5), randf_range(-0.5, 0.5)),
				"motor_strength": randf_range(0.0, 5.0),
				"motor_frequency": randf_range(0.5, 3.0),
				"motor_phase": randf_range(0.0, TAU)
			}
			
			if joint_type == "hinge":
				joint_data["axis"] = Vector3.UP.rotated(Vector3(randf(), randf(), randf()).normalized(), randf() * TAU)
			elif joint_type == "cone":
				joint_data["swing_span"] = randf_range(20.0, 60.0)
				joint_data["twist_span"] = randf_range(10.0, 30.0)
			
			joints.append(joint_data)
	
	func crossover(other: CreatureGenome) -> CreatureGenome:
		var child = CreatureGenome.new()
		child.body_parts.clear()
		child.joints.clear()
		
		var crossover_point = randi() % min(body_parts.size(), other.body_parts.size())
		
		for i in range(crossover_point):
			child.body_parts.append(body_parts[i].duplicate())
		for i in range(crossover_point, other.body_parts.size()):
			child.body_parts.append(other.body_parts[i].duplicate())
		
		for i in range(min(joints.size(), other.joints.size())):
			if i < crossover_point and i < joints.size():
				child.joints.append(joints[i].duplicate())
			elif i < other.joints.size():
				child.joints.append(other.joints[i].duplicate())
		
		return child
	
	func mutate():
		if randf() < MUTATION_RATE:
			for part in body_parts:
				if randf() < 0.3:
					if part.has("size"):
						part["size"] += Vector3(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1), randf_range(-0.1, 0.1))
						part["size"] = part["size"].clamp(Vector3(0.2, 0.2, 0.2), Vector3(2.0, 2.0, 2.0))
					if part.has("radius"):
						part["radius"] = clamp(part["radius"] + randf_range(-0.1, 0.1), 0.2, 1.0)
					part["mass"] = clamp(part["mass"] + randf_range(-0.3, 0.3), 0.3, 5.0)
		
		if randf() < MUTATION_RATE:
			for joint in joints:
				if randf() < 0.4:
					joint["motor_strength"] = clamp(joint["motor_strength"] + randf_range(-1.0, 1.0), 0.0, 8.0)
					joint["motor_frequency"] = clamp(joint["motor_frequency"] + randf_range(-0.5, 0.5), 0.3, 4.0)

class EvolvedCreature:
	var genome: CreatureGenome
	var bodies := []
	var joints := []
	var root_body: RigidBody3D
	var time := 0.0
	var start_pos := Vector3.ZERO
	var is_alive := true
	
	func _init(g: CreatureGenome):
		genome = g

func _ready():
	_setup_environment()
	_create_arena()
	_initialize_population()

func _setup_environment():
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45.0, -30.0, 0.0)
	light.light_energy = 1.2
	light.shadow_enabled = true
	add_child(light)
	
	var ambient := WorldEnvironment.new()
	ambient.environment = Environment.new()
	ambient.environment.background_mode = Environment.BG_COLOR
	ambient.environment.background_color = Color(0.15, 0.18, 0.25)
	ambient.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambient.environment.ambient_light_color = Color(0.3, 0.3, 0.35)
	ambient.environment.ambient_light_energy = 0.6
	add_child(ambient)
	
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 15.0, 25.0)
	camera.look_at_from_position(camera.position, Vector3(0.0, 2.0, 0.0), Vector3.UP)
	camera.current = true
	add_child(camera)

func _create_arena():
	arena_floor = StaticBody3D.new()
	arena_floor.name = "ArenaFloor"
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(50.0, 0.5, 50.0)
	collider.shape = shape
	arena_floor.add_child(collider)
	
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(50.0, 0.5, 50.0)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.25, 0.2)
	mesh.material_override = mat
	arena_floor.add_child(mesh)
	add_child(arena_floor)
	
	# Grid lines
	for i in range(-5, 6):
		_create_grid_line(Vector3(i * 4.0, 0.26, -20.0), Vector3(i * 4.0, 0.26, 20.0))
		_create_grid_line(Vector3(-20.0, 0.26, i * 4.0), Vector3(20.0, 0.26, i * 4.0))

func _create_grid_line(from: Vector3, to: Vector3):
	var mesh := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.35, 0.3, 0.5)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = mat
	add_child(mesh_instance)

func _initialize_population():
	for i in range(POPULATION_SIZE):
		var genome = CreatureGenome.new()
		var x = (i % 4 - 1.5) * 6.0
		var z = (i / 4 - 1.5) * 6.0
		genome.start_position = Vector3(x, 3.0, z)
		var creature = _spawn_creature(genome)
		current_population.append(creature)

func _spawn_creature(genome: CreatureGenome) -> EvolvedCreature:
	var creature = EvolvedCreature.new(genome)
	creature.start_pos = genome.start_position
	
	# Build bodies
	for i in range(genome.body_parts.size()):
		var part = genome.body_parts[i]
		var body: RigidBody3D
		
		if part["type"] == "box":
			body = _create_box(part["size"], genome.start_position, part["mass"], part["color"])
		elif part["type"] == "cylinder":
			body = _create_cylinder(part["radius"], part["height"], genome.start_position, part["mass"], part["color"])
		else:
			body = _create_sphere(part["radius"], genome.start_position, part["mass"], part["color"])
		
		creature.bodies.append(body)
		if i == 0:
			creature.root_body = body
	
	# Build joints
	for joint_data in genome.joints:
		var parent_body = creature.bodies[joint_data["parent"]]
		var child_body = creature.bodies[joint_data["child"]]
		var joint_pos = parent_body.global_position + joint_data["offset"]
		child_body.global_position = joint_pos + Vector3(0, -1, 0)
		
		var joint: Joint3D
		if joint_data["type"] == "pin":
			joint = PinJoint3D.new()
		elif joint_data["type"] == "hinge":
			var hinge = HingeJoint3D.new()
			hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
			joint = hinge
		else:
			var cone = ConeTwistJoint3D.new()
			cone.swing_span = deg_to_rad(joint_data["swing_span"])
			cone.twist_span = deg_to_rad(joint_data["twist_span"])
			joint = cone
		
		joint.node_a = parent_body.get_path()
		joint.node_b = child_body.get_path()
		joint.position = joint_pos
		joint.set_exclude_nodes_from_collision(true)
		add_child(joint)
		creature.joints.append({"node": joint, "data": joint_data})
	
	return creature

func _create_box(size: Vector3, pos: Vector3, mass: float, color: Color) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.mass = mass
	body.position = pos
	body.can_sleep = false
	var collider := CollisionShape3D.new()
	collider.shape = BoxShape3D.new()
	(collider.shape as BoxShape3D).size = size
	body.add_child(collider)
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	(mesh.mesh as BoxMesh).size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	body.add_child(mesh)
	add_child(body)
	return body

func _create_cylinder(radius: float, height: float, pos: Vector3, mass: float, color: Color) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.mass = mass
	body.position = pos
	body.can_sleep = false
	var collider := CollisionShape3D.new()
	collider.shape = CylinderShape3D.new()
	(collider.shape as CylinderShape3D).radius = radius
	(collider.shape as CylinderShape3D).height = height
	body.add_child(collider)
	var mesh := MeshInstance3D.new()
	mesh.mesh = CylinderMesh.new()
	(mesh.mesh as CylinderMesh).bottom_radius = radius
	(mesh.mesh as CylinderMesh).top_radius = radius
	(mesh.mesh as CylinderMesh).height = height
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	body.add_child(mesh)
	add_child(body)
	return body

func _create_sphere(radius: float, pos: Vector3, mass: float, color: Color) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.mass = mass
	body.position = pos
	body.can_sleep = false
	var collider := CollisionShape3D.new()
	collider.shape = SphereShape3D.new()
	(collider.shape as SphereShape3D).radius = radius
	body.add_child(collider)
	var mesh := MeshInstance3D.new()
	mesh.mesh = SphereMesh.new()
	(mesh.mesh as SphereMesh).radius = radius
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	body.add_child(mesh)
	add_child(body)
	return body

func _physics_process(delta):
	timer += delta
	
	# Apply motor forces
	for creature in current_population:
		if not creature.is_alive:
			continue
		creature.time += delta
		
		for joint_info in creature.joints:
			var joint_node = joint_info["node"]
			var joint_data = joint_info["data"]
			
			if joint_node is HingeJoint3D:
				var target_vel = joint_data["motor_strength"] * sin(creature.time * joint_data["motor_frequency"] + joint_data["motor_phase"])
				joint_node.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, target_vel)
	
	# End generation
	if timer >= GENERATION_TIME:
		_evaluate_fitness()
		_evolve_population()
		timer = 0.0

func _evaluate_fitness():
	print("Generation ", generation, " fitness:")
	for creature in current_population:
		if not is_instance_valid(creature.root_body):
			creature.genome.fitness = 0.0
			continue
		
		var distance = creature.root_body.global_position.distance_to(creature.start_pos)
		var forward_distance = creature.root_body.global_position.x - creature.start_pos.x
		var height_bonus = max(0, creature.root_body.global_position.y - 0.5)
		
		creature.genome.fitness = forward_distance * 2.0 + distance + height_bonus * 0.5
		print("  Creature fitness: ", creature.genome.fitness)

func _evolve_population():
	generation += 1
	print("\n=== EVOLVING TO GENERATION ", generation, " ===\n")
	
	# Sort by fitness
	var genomes = []
	for creature in current_population:
		genomes.append(creature.genome)
	genomes.sort_custom(func(a, b): return a.fitness > b.fitness)
	
	# Clear old creatures
	for creature in current_population:
		for body in creature.bodies:
			if is_instance_valid(body):
				body.queue_free()
		for joint_info in creature.joints:
			if is_instance_valid(joint_info["node"]):
				joint_info["node"].queue_free()
	current_population.clear()
	
	# Create next generation
	var new_genomes = []
	
	# Elitism: keep top 2
	new_genomes.append(genomes[0])
	new_genomes.append(genomes[1])
	
	# Breed the rest
	while new_genomes.size() < POPULATION_SIZE:
		var parent1 = genomes[randi() % min(6, genomes.size())]
		var parent2 = genomes[randi() % min(6, genomes.size())]
		var child = parent1.crossover(parent2)
		child.mutate()
		new_genomes.append(child)
	
	# Spawn new generation
	for i in range(POPULATION_SIZE):
		var x = (i % 4 - 1.5) * 6.0
		var z = (i / 4 - 1.5) * 6.0
		new_genomes[i].start_position = Vector3(x, 3.0, z)
		var creature = _spawn_creature(new_genomes[i])
		current_population.append(creature)
