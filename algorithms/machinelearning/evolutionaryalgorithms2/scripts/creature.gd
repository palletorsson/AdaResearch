extends Node3D

# Creature properties
var creature_type = 0
var genome = {}
var age = 0
var energy = 100.0
var last_reproduction_time = 0
var fitness = 0.0

# Physical properties
var body_parts = []
var joints = []
var base_color = Color(1, 1, 1)

# Lifetime signals
signal reproduction_event(parent, child)
signal death_event(creature)

# Called when the node enters the scene tree for the first time
func _ready():
	# Generate initial fitness evaluation
	evaluate_fitness()

# Called every frame
func _process(delta):
	# Update age
	age += delta
	
	# Update energy
	update_energy(delta)
	
	# Check if it's time to attempt reproduction
	if can_reproduce():
		attempt_reproduction()
	
	# Update behavior based on creature type
	match creature_type:
		0: # SYMBIOTIC
			process_symbiotic(delta)
		1: # PHASE_SHIFTING
			process_phase_shifting(delta)
		2: # RECURSIVE
			process_recursive(delta)
		3: # RESONANCE
			process_resonance(delta)
		4: # TOPOLOGY
			process_topology(delta)
	
	# Update fitness
	evaluate_fitness()

func initialize(type):
	creature_type = type
	
	# Generate random genome based on type
	genome = generate_random_genome(type)
	
	# Build physical structure based on genome
	build_body()
	
	# Set up behaviors
	setup_behaviors()

func initialize_from_genes(genes):
	genome = genes
	creature_type = genome.get("type", 0)
	
	# Build physical structure based on genome
	build_body()
	
	# Set up behaviors
	setup_behaviors()

func generate_random_genome(type):
	var genes = {}
	
	# Common genes
	genes["type"] = type
	genes["body_scale"] = Vector3(randf_range(0.5, 1.5), randf_range(0.5, 1.5), randf_range(0.5, 1.5))
	genes["body_parts_count"] = randi_range(3, 8)  # Number of body segments
	genes["color_r"] = randf()
	genes["color_g"] = randf()
	genes["color_b"] = randf()
	genes["move_speed"] = randf_range(0.5, 2.0)
	genes["energy_efficiency"] = randf_range(0.7, 1.3)
	
	# Type-specific genes
	match type:
		0: # SYMBIOTIC
			genes["connection_points"] = randi_range(2, 5)
			genes["symbiosis_factor"] = randf_range(0.1, 1.0)
		1: # PHASE_SHIFTING
			genes["phase_duration"] = randf_range(5.0, 15.0)
			genes["phase_shift_speed"] = randf_range(0.5, 2.0)
		2: # RECURSIVE
			genes["recursion_depth"] = randi_range(1, 3)
			genes["inner_scale_factor"] = randf_range(0.3, 0.6)
		3: # RESONANCE
			genes["base_frequency"] = randf_range(0.5, 2.0)
			genes["amplitude"] = randf_range(0.1, 0.5)
			genes["harmonic_count"] = randi_range(2, 5)
		4: # TOPOLOGY
			genes["genus"] = randi_range(0, 3)  # Number of "holes"
			genes["morph_speed"] = randf_range(0.2, 1.0)
	
	return genes

# Add auxiliary functions here for better organization
func _add_joint_between(body_a, body_b, position):
	# Create joint between parent and child
	if body_a.is_inside_tree() and body_b.is_inside_tree():
		var joint = Generic6DOFJoint3D.new()
		joint.node_a = body_a.get_path()
		joint.node_b = body_b.get_path()
		
		# Set joint limits
		for i in range(3):
			joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, -0.01)
			joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.01)
		
		joint.position = position
		
		add_child(joint)
		joints.push_back(joint)

func _add_symbiotic_joint(body_a, body_b, position):
	# Create joint between symbiotic body parts
	if body_a.is_inside_tree() and body_b.is_inside_tree():
		var joint = Generic6DOFJoint3D.new()
		joint.node_a = body_a.get_path()
		joint.node_b = body_b.get_path()
		
		# Allow limited movement
		joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, -0.5)
		joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0.5)
		joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, -0.5)
		joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0.5)
		
		joint.position = position
		
		add_child(joint)
		joints.push_back(joint)

func _add_resonance_joint(body_a, body_b, position):
	# Create joint between resonance body parts
	if body_a.is_inside_tree() and body_b.is_inside_tree():
		var joint = Generic6DOFJoint3D.new()
		joint.node_a = body_a.get_path()
		joint.node_b = body_b.get_path()
		
		joint.position = position
		
		add_child(joint)
		joints.push_back(joint)

func build_body():
	# Clear existing body parts
	for part in body_parts:
		part.queue_free()
	
	for joint in joints:
		joint.queue_free()
	
	body_parts.clear()
	joints.clear()
	
	# Set base color
	base_color = Color(genome["color_r"], genome["color_g"], genome["color_b"])
	
	# Create main body
	var main_body = RigidBody3D.new()
	var collision_shape = CollisionShape3D.new()
	var mesh_instance = MeshInstance3D.new()
	
	match creature_type:
		0: # SYMBIOTIC - Multiple connected spheres
			build_symbiotic_body(main_body, collision_shape, mesh_instance)
		1: # PHASE_SHIFTING - Blob mesh with shader
			build_phase_shifting_body(main_body, collision_shape, mesh_instance)
		2: # RECURSIVE - Fractal structure
			build_recursive_body(main_body, collision_shape, mesh_instance)
		3: # RESONANCE - Wave-based form
			build_resonance_body(main_body, collision_shape, mesh_instance)
		4: # TOPOLOGY - Genus-changing mesh
			build_topology_body(main_body, collision_shape, mesh_instance)
	
	add_child(main_body)
	body_parts.push_back(main_body)

func build_symbiotic_body(main_body, collision_shape, mesh_instance):
	# Create base sphere
	collision_shape.shape = SphereShape3D.new()
	collision_shape.shape.radius = 0.5 * genome["body_scale"].x
	
	mesh_instance.mesh = SphereMesh.new()
	mesh_instance.mesh.radius = 0.5 * genome["body_scale"].x
	mesh_instance.mesh.height = genome["body_scale"].x
	
	var material = StandardMaterial3D.new()
	material.albedo_color = base_color
	mesh_instance.material_override = material
	
	main_body.add_child(collision_shape)
	main_body.add_child(mesh_instance)
	
	# Add connection points
	var connection_points = genome.get("connection_points", 3)
	
	for i in range(connection_points):
		var angle = (2.0 * PI / connection_points) * i
		var radius = 0.7 * genome["body_scale"].x
		
		var part = RigidBody3D.new()
		var part_collision = CollisionShape3D.new()
		var part_mesh = MeshInstance3D.new()
		
		part_collision.shape = SphereShape3D.new()
		part_collision.shape.radius = 0.3 * genome["body_scale"].x
		
		part_mesh.mesh = SphereMesh.new()
		part_mesh.mesh.radius = 0.3 * genome["body_scale"].x
		part_mesh.mesh.height = 0.6 * genome["body_scale"].x
		
		var part_material = StandardMaterial3D.new()
		part_material.albedo_color = base_color.lightened(0.2)
		part_mesh.material_override = part_material
		
		part.add_child(part_collision)
		part.add_child(part_mesh)
		
		var pos_x = cos(angle) * radius
		var pos_z = sin(angle) * radius
		part.position = Vector3(pos_x, 0, pos_z)
		
		add_child(part)
		body_parts.push_back(part)
		
		# Use deferred call to create joint after nodes are in the tree
		call_deferred("_add_symbiotic_joint", main_body, part, Vector3(pos_x/2, 0, pos_z/2))

func build_phase_shifting_body(main_body, collision_shape, mesh_instance):
	# Use a blob mesh that can be morphed via shader
	collision_shape.shape = SphereShape3D.new()
	collision_shape.shape.radius = 0.7 * genome["body_scale"].x
	
	mesh_instance.mesh = SphereMesh.new()
	mesh_instance.mesh.radius = 0.7 * genome["body_scale"].x
	mesh_instance.mesh.height = 1.4 * genome["body_scale"].x
	
	# Create a shader material
	var shader_material = ShaderMaterial.new()
	var shader = load("res://shaders/phase_shifting.gdshader")
	if shader:
		shader_material.shader = shader
		shader_material.set_shader_parameter("base_color", base_color)
		shader_material.set_shader_parameter("phase_time", 0.0)
		shader_material.set_shader_parameter("liquid_factor", 0.0)  # Will animate between states
	else:
		# Fallback material
		var material = StandardMaterial3D.new()
		material.albedo_color = base_color
		shader_material = material
	
	mesh_instance.material_override = shader_material
	
	main_body.add_child(collision_shape)
	main_body.add_child(mesh_instance)

func build_recursive_body(main_body, collision_shape, mesh_instance):
	# Start with a cube base
	collision_shape.shape = BoxShape3D.new()
	collision_shape.shape.size = genome["body_scale"]
	
	mesh_instance.mesh = BoxMesh.new()
	mesh_instance.mesh.size = genome["body_scale"]
	
	var material = StandardMaterial3D.new()
	material.albedo_color = base_color
	mesh_instance.material_override = material
	
	main_body.add_child(collision_shape)
	main_body.add_child(mesh_instance)
	
	# Add recursive smaller cubes
	var recursion_depth = genome.get("recursion_depth", 2)
	var scale_factor = genome.get("inner_scale_factor", 0.5)
	
	create_recursive_parts(main_body, recursion_depth, scale_factor, genome["body_scale"])

func create_recursive_parts(parent_body, depth, scale_factor, parent_size):
	if depth <= 0:
		return
	
	# Create smaller cubes on each face of parent
	var directions = [
		Vector3(1, 0, 0),
		Vector3(-1, 0, 0),
		Vector3(0, 1, 0),
		Vector3(0, -1, 0),
		Vector3(0, 0, 1),
		Vector3(0, 0, -1)
	]
	
	for dir in directions:
		var child = RigidBody3D.new()
		var child_collision = CollisionShape3D.new()
		var child_mesh = MeshInstance3D.new()
		
		child_collision.shape = BoxShape3D.new()
		var child_size = parent_size * scale_factor
		child_collision.shape.size = child_size
		
		child_mesh.mesh = BoxMesh.new()
		child_mesh.mesh.size = child_size
		
		var child_material = StandardMaterial3D.new()
		child_material.albedo_color = base_color.darkened(0.1 * (3 - depth))
		child_mesh.material_override = child_material
		
		child.add_child(child_collision)
		child.add_child(child_mesh)
		
		# Position the child on the face of the parent
		var offset = dir * (parent_size[dir.abs().max_axis_index()] * 0.5 + child_size[dir.abs().max_axis_index()] * 0.5)
		child.position = offset
		
		add_child(child)
		body_parts.push_back(child)
		
		# Wait until the next frame to add joints when nodes are in tree
		call_deferred("_add_joint_between", parent_body, child, offset * 0.5)
		
		# Recurse for next level
		if depth > 1:
			call_deferred("create_recursive_parts", child, depth - 1, scale_factor, child_size)

func build_resonance_body(main_body, collision_shape, mesh_instance):
	# Use a cylinder with wave distortion shader
	collision_shape.shape = CylinderShape3D.new()
	collision_shape.shape.radius = 0.5 * genome["body_scale"].x
	collision_shape.shape.height = genome["body_scale"].y
	
	mesh_instance.mesh = CylinderMesh.new()
	mesh_instance.mesh.top_radius = 0.5 * genome["body_scale"].x
	mesh_instance.mesh.bottom_radius = 0.5 * genome["body_scale"].x
	mesh_instance.mesh.height = genome["body_scale"].y
	
	# Create a shader material for wave effect
	var shader_material = ShaderMaterial.new()
	var shader = load("res://shaders/resonance.gdshader")
	if shader:
		shader_material.shader = shader
		shader_material.set_shader_parameter("base_color", base_color)
		shader_material.set_shader_parameter("frequency", genome.get("base_frequency", 1.0))
		shader_material.set_shader_parameter("amplitude", genome.get("amplitude", 0.2))
	else:
		# Fallback material
		var material = StandardMaterial3D.new()
		material.albedo_color = base_color
		shader_material = material
	
	mesh_instance.material_override = shader_material
	
	main_body.add_child(collision_shape)
	main_body.add_child(mesh_instance)
	
	# Add harmonic cylinders
	var harmonic_count = genome.get("harmonic_count", 3)
	
	for i in range(harmonic_count):
		var harmonic = RigidBody3D.new()
		var harmonic_collision = CollisionShape3D.new()
		var harmonic_mesh = MeshInstance3D.new()
		
		harmonic_collision.shape = CylinderShape3D.new()
		harmonic_collision.shape.radius = 0.3 * genome["body_scale"].x * (harmonic_count - i) / harmonic_count
		harmonic_collision.shape.height = genome["body_scale"].y * 0.8
		
		harmonic_mesh.mesh = CylinderMesh.new()
		harmonic_mesh.mesh.top_radius = 0.3 * genome["body_scale"].x * (harmonic_count - i) / harmonic_count
		harmonic_mesh.mesh.bottom_radius = 0.3 * genome["body_scale"].x * (harmonic_count - i) / harmonic_count
		harmonic_mesh.mesh.height = genome["body_scale"].y * 0.8
		
		var harmonic_material = ShaderMaterial.new()
		if shader:
			harmonic_material.shader = shader
			harmonic_material.set_shader_parameter("base_color", base_color.lightened(0.2 * i / harmonic_count))
			harmonic_material.set_shader_parameter("frequency", genome.get("base_frequency", 1.0) * (i + 2))
			harmonic_material.set_shader_parameter("amplitude", genome.get("amplitude", 0.2) * 0.7)
		else:
			var material = StandardMaterial3D.new()
			material.albedo_color = base_color.lightened(0.2 * i / harmonic_count)
			harmonic_material = material
		
		harmonic_mesh.material_override = harmonic_material
		
		harmonic.add_child(harmonic_collision)
		harmonic.add_child(harmonic_mesh)
		
		# Position harmonics in a spiral pattern
		var angle = (2.0 * PI / harmonic_count) * i
		var radius = 0.6 * genome["body_scale"].x
		
		var pos_x = cos(angle) * radius
		var pos_z = sin(angle) * radius
		harmonic.position = Vector3(pos_x, 0, pos_z)
		
		add_child(harmonic)
		body_parts.push_back(harmonic)
		
		# Create joint using deferred call
		call_deferred("_add_resonance_joint", main_body, harmonic, Vector3(pos_x/2, 0, pos_z/2))

func build_topology_body(main_body, collision_shape, mesh_instance):
	# Use a torus shape that can change genus
	collision_shape.shape = SphereShape3D.new()  # Approximation for physics
	collision_shape.shape.radius = 0.7 * genome["body_scale"].x
	
	var genus = genome.get("genus", 1)
	
	if genus == 0:
		# Sphere (genus 0)
		mesh_instance.mesh = SphereMesh.new()
		mesh_instance.mesh.radius = 0.7 * genome["body_scale"].x
		mesh_instance.mesh.height = 1.4 * genome["body_scale"].x
	else:
		# Torus (genus 1+)
		mesh_instance.mesh = TorusMesh.new()
		mesh_instance.mesh.inner_radius = 0.3 * genome["body_scale"].x * genus
		mesh_instance.mesh.outer_radius = 0.7 * genome["body_scale"].x
	
	var shader_material = ShaderMaterial.new()
	var shader = load("res://shaders/topology.gdshader")
	if shader:
		shader_material.shader = shader
		shader_material.set_shader_parameter("base_color", base_color)
		shader_material.set_shader_parameter("genus", float(genus))
		shader_material.set_shader_parameter("morph_factor", 0.0)  # Will be animated
	else:
		# Fallback material
		var material = StandardMaterial3D.new()
		material.albedo_color = base_color
		shader_material = material
	
	mesh_instance.material_override = shader_material
	
	main_body.add_child(collision_shape)
	main_body.add_child(mesh_instance)

func setup_behaviors():
	# Set up behavior trees or state machines based on creature type
	match creature_type:
		0: # SYMBIOTIC
			setup_symbiotic_behavior()
		1: # PHASE_SHIFTING
			setup_phase_shifting_behavior()
		2: # RECURSIVE
			setup_recursive_behavior()
		3: # RESONANCE
			setup_resonance_behavior()
		4: # TOPOLOGY
			setup_topology_behavior()

func setup_symbiotic_behavior():
	# Behavior: Seek other symbiotic creatures to connect with
	pass

func setup_phase_shifting_behavior():
	# Behavior: Cycle through different physical states
	pass

func setup_recursive_behavior():
	# Behavior: Occasionally spawn smaller creatures
	pass

func setup_resonance_behavior():
	# Behavior: Generate harmonic patterns
	pass

func setup_topology_behavior():
	# Behavior: Change topological genus periodically
	pass

func process_symbiotic(delta):
	# Look for nearby symbiotic creatures to connect with
	var nearby_creatures = find_nearby_creatures(3.0)
	
	for creature in nearby_creatures:
		if creature.creature_type == creature_type:
			attempt_connection(creature)

func process_phase_shifting(delta):
	# Cycle between states: solid, liquid, gas
	var phase_time = fmod(age, genome.get("phase_duration", 10.0))
	var phase_progress = phase_time / genome.get("phase_duration", 10.0)
	
	# Update shader parameter for visual effect
	if body_parts.size() > 0 and body_parts[0].get_child_count() > 0:
		var mesh_instance = body_parts[0].get_child(1)
		if mesh_instance is MeshInstance3D and mesh_instance.material_override is ShaderMaterial:
			mesh_instance.material_override.set_shader_parameter("phase_time", phase_progress)
			
			# Liquid factor follows a sin wave
			var liquid_factor = (sin(phase_progress * 2.0 * PI) + 1.0) / 2.0
			mesh_instance.material_override.set_shader_parameter("liquid_factor", liquid_factor)
	
	# Adjust physics properties based on current phase
	if phase_progress < 0.33:
		# Solid phase - higher mass, more friction
		adjust_physical_properties(5.0, 1.0, 0.2)
	elif phase_progress < 0.66:
		# Liquid phase - medium mass, low friction
		adjust_physical_properties(3.0, 0.2, 0.8)
	else:
		# Gas phase - low mass, no friction, more bounce
		adjust_physical_properties(1.0, 0.05, 0.9)

func process_recursive(delta):
	# Occasionally spawn smaller versions of self
	if randf() < 0.01 * delta and energy > 50.0:
		var spawn_chance = 0.05 * genome.get("recursion_depth", 2)
		
		if randf() < spawn_chance:
			spawn_recursive_child()
	
	# Apply fractal movement patterns
	for i in range(body_parts.size()):
		if i == 0:  # Skip main body
			continue
			
		var part = body_parts[i]
		var depth = i % genome.get("recursion_depth", 2) + 1
		
		# Apply forces in fractal pattern
		var force = Vector3(
			sin(age * (depth + 1) * 0.3),
			cos(age * depth * 0.5),
			sin(age * (depth + 0.5) * 0.7)
		) * 2.0 / depth
		
		part.apply_central_force(force)

func process_resonance(delta):
	# Update resonance wave parameters
	var base_freq = genome.get("base_frequency", 1.0)
	var amplitude = genome.get("amplitude", 0.2)
	
	# Apply wave motion to all body parts
	for i in range(body_parts.size()):
		var part = body_parts[i]
		var freq_mod = 1.0
		
		if i > 0:  # Harmonic frequencies for secondary parts
			freq_mod = (i + 1) * 1.5
		
		var mesh_instance = null
		if part.get_child_count() > 1:
			mesh_instance = part.get_child(1)
		
		if mesh_instance is MeshInstance3D and mesh_instance.material_override is ShaderMaterial:
			# Update wave parameters in shader
			mesh_instance.material_override.set_shader_parameter("time", age)
			mesh_instance.material_override.set_shader_parameter("frequency", base_freq * freq_mod)
			
			# Phase shift for interference patterns
			if i > 0:
				var phase = fmod(age * 0.2 * i, PI * 2.0)
				mesh_instance.material_override.set_shader_parameter("phase", phase)
		
		# Apply oscillating force
		var force = Vector3(
			sin(age * base_freq * freq_mod),
			cos(age * base_freq * freq_mod * 0.7),
			sin(age * base_freq * freq_mod * 1.3)
		) * amplitude * 5.0
		
		part.apply_central_force(force)
		
		# Create resonance effects with nearby objects
		emit_resonance_wave(part.global_transform.origin, base_freq * freq_mod, amplitude)

func process_topology(delta):
	# Change topological genus over time
	var morph_time = fmod(age, 20.0) 
	var morph_speed = genome.get("morph_speed", 0.5)
	var morph_factor = 0.0
	
	# Calculate morph factor (0 to 1)
	if morph_time < 10.0:
		morph_factor = min(morph_time * morph_speed * 0.2, 1.0)
	else:
		morph_factor = max(1.0 - (morph_time - 10.0) * morph_speed * 0.2, 0.0)
	
	# Update shader parameter for visual morphing
	if body_parts.size() > 0 and body_parts[0].get_child_count() > 0:
		var mesh_instance = body_parts[0].get_child(1)
		if mesh_instance is MeshInstance3D and mesh_instance.material_override is ShaderMaterial:
			mesh_instance.material_override.set_shader_parameter("morph_factor", morph_factor)
			mesh_instance.material_override.set_shader_parameter("time", age)
	
	# Adjust physical properties based on current topology
	var mass = 2.0 + morph_factor * 3.0
	var center_of_mass = Vector3(0, morph_factor * 0.5, 0)
	
	if body_parts.size() > 0:
		body_parts[0].mass = mass
		body_parts[0].center_of_mass = center_of_mass

func update_energy(delta):
	# Base energy consumption
	var consumption_rate = 1.0 / genome.get("energy_efficiency", 1.0)
	
	# Additional consumption based on movement and actions
	var activity_consumption = 0.0
	for part in body_parts:
		if part is RigidBody3D:
			activity_consumption += part.linear_velocity.length_squared() * 0.01
	
	# Type-specific energy considerations
	match creature_type:
		0: # SYMBIOTIC - less energy used when connected to others
			var connections = count_active_connections()
			consumption_rate *= max(0.5, 1.0 - connections * 0.1)
		1: # PHASE_SHIFTING - energy varies by phase
			var phase_time = fmod(age, genome.get("phase_duration", 10.0))
			var phase_progress = phase_time / genome.get("phase_duration", 10.0)
			if phase_progress < 0.33:  # Solid phase - less energy
				consumption_rate *= 0.7
			elif phase_progress < 0.66:  # Liquid phase - normal energy
				consumption_rate *= 1.0
			else:  # Gas phase - more energy
				consumption_rate *= 1.3
		2: # RECURSIVE - energy based on complexity
			consumption_rate *= 0.8 + 0.2 * genome.get("recursion_depth", 2)
		3: # RESONANCE - energy based on frequency
			consumption_rate *= 0.9 + 0.3 * genome.get("base_frequency", 1.0)
		4: # TOPOLOGY - energy based on genus
			consumption_rate *= 0.8 + 0.2 * genome.get("genus", 1)
	
	# Total energy consumption
	var total_consumption = consumption_rate * delta + activity_consumption
	energy -= total_consumption
	
	# Energy gain from environment or food
	var energy_gain = find_energy_sources(delta)
	energy += energy_gain
	
	# Check for death
	if energy <= 0:
		die()

func evaluate_fitness():
	# Base fitness from age and energy
	var base_fitness = age * 0.1 + energy * 0.2
	
	# Type-specific fitness factors
	match creature_type:
		0: # SYMBIOTIC - fitness from successful connections
			var connections = count_active_connections()
			base_fitness *= 1.0 + connections * 0.5
		1: # PHASE_SHIFTING - fitness from successful phase transitions
			var phase_shifts = floor(age / genome.get("phase_duration", 10.0))
			base_fitness *= 1.0 + phase_shifts * 0.1
		2: # RECURSIVE - fitness from structural complexity
			base_fitness *= 1.0 + genome.get("recursion_depth", 2) * 0.3
		3: # RESONANCE - fitness from harmony
			var resonance_factor = get_resonance_harmony()
			base_fitness *= 1.0 + resonance_factor
		4: # TOPOLOGY - fitness from successful genus changes
			var genus_changes = floor(age / 20.0)
			base_fitness *= 1.0 + genus_changes * 0.2
	
	fitness = base_fitness

func can_reproduce():
	# Check if creature can reproduce based on energy, age, and time since last reproduction
	return (
		energy > 60.0 and
		age > 30.0 and
		(age - last_reproduction_time) > 30.0
	)
func attempt_reproduction():
	# Try to reproduce, creating offspring with mutated genes
	var offspring_genes = mutate_genes(genome)
	
	# Create new creature
	var offspring_scene = load("res://scenes/creature.tscn")
	var offspring = offspring_scene.instantiate()
	
	# Position near parent
	var spawn_offset = Vector3(randf_range(-1.0, 1.0), 0.5, randf_range(-1.0, 1.0)).normalized() * 2.0
	offspring.global_transform.origin = global_transform.origin + spawn_offset
	
	# Initialize with mutated genes
	offspring.initialize_from_genes(offspring_genes)
	
	# Add to scene
	get_parent().add_child(offspring)
	
	# Update energy and last reproduction time
	energy -= 50.0
	last_reproduction_time = age
	
	# Emit signal
	emit_signal("reproduction_event", self, offspring)
	
	return offspring

func mutate_genes(parent_genes):
	# Create a copy of the parent genes
	var mutated_genes = parent_genes.duplicate(true)
	
	# Chance of mutation for each gene
	var mutation_chance = 0.2
	var mutation_strength = 0.2
	
	# Mutate common genes
	if randf() < mutation_chance:
		mutated_genes["body_scale"] = Vector3(
			clamp(parent_genes["body_scale"].x * (1.0 + randf_range(-mutation_strength, mutation_strength)), 0.3, 2.0),
			clamp(parent_genes["body_scale"].y * (1.0 + randf_range(-mutation_strength, mutation_strength)), 0.3, 2.0),
			clamp(parent_genes["body_scale"].z * (1.0 + randf_range(-mutation_strength, mutation_strength)), 0.3, 2.0)
		)
	
	if randf() < mutation_chance:
		mutated_genes["body_parts_count"] = clamp(parent_genes["body_parts_count"] + randi_range(-1, 1), 2, 10)
	
	if randf() < mutation_chance:
		mutated_genes["color_r"] = clamp(parent_genes["color_r"] + randf_range(-mutation_strength, mutation_strength), 0.0, 1.0)
	
	if randf() < mutation_chance:
		mutated_genes["color_g"] = clamp(parent_genes["color_g"] + randf_range(-mutation_strength, mutation_strength), 0.0, 1.0)
	
	if randf() < mutation_chance:
		mutated_genes["color_b"] = clamp(parent_genes["color_b"] + randf_range(-mutation_strength, mutation_strength), 0.0, 1.0)
	
	if randf() < mutation_chance:
		mutated_genes["move_speed"] = clamp(parent_genes["move_speed"] * (1.0 + randf_range(-mutation_strength, mutation_strength)), 0.3, 3.0)
	
	if randf() < mutation_chance:
		mutated_genes["energy_efficiency"] = clamp(parent_genes["energy_efficiency"] * (1.0 + randf_range(-mutation_strength, mutation_strength)), 0.5, 1.5)
	
	# Type-specific gene mutations
	match parent_genes["type"]:
		0: # SYMBIOTIC
			if randf() < mutation_chance:
				mutated_genes["connection_points"] = clamp(parent_genes["connection_points"] + randi_range(-1, 1), 1, 8)
			
			if randf() < mutation_chance:
				mutated_genes["symbiosis_factor"] = clamp(parent_genes["symbiosis_factor"] + randf_range(-mutation_strength, mutation_strength), 0.05, 1.2)
				
		1: # PHASE_SHIFTING
			if randf() < mutation_chance:
				mutated_genes["phase_duration"] = clamp(parent_genes["phase_duration"] * (1.0 + randf_range(-mutation_strength, mutation_strength)), 3.0, 20.0)
			
			if randf() < mutation_chance:
				mutated_genes["phase_shift_speed"] = clamp(parent_genes["phase_shift_speed"] * (1.0 + randf_range(-mutation_strength, mutation_strength)), 0.2, 3.0)
				
		2: # RECURSIVE
			if randf() < mutation_chance:
				mutated_genes["recursion_depth"] = clamp(parent_genes["recursion_depth"] + randi_range(-1, 1), 1, 4)
			
			if randf() < mutation_chance:
				mutated_genes["inner_scale_factor"] = clamp(parent_genes["inner_scale_factor"] + randf_range(-mutation_strength, mutation_strength), 0.1, 0.8)
				
		3: # RESONANCE
			if randf() < mutation_chance:
				mutated_genes["base_frequency"] = clamp(parent_genes["base_frequency"] * (1.0 + randf_range(-mutation_strength, mutation_strength)), 0.2, 3.0)
				
			if randf() < mutation_chance:
				mutated_genes["amplitude"] = clamp(parent_genes["amplitude"] + randf_range(-mutation_strength, mutation_strength), 0.05, 0.8)
				
			if randf() < mutation_chance:
				mutated_genes["harmonic_count"] = clamp(parent_genes["harmonic_count"] + randi_range(-1, 1), 1, 8)
				
		4: # TOPOLOGY
			if randf() < mutation_chance:
				mutated_genes["genus"] = clamp(parent_genes["genus"] + randi_range(-1, 1), 0, 4)
				
			if randf() < mutation_chance:
				mutated_genes["morph_speed"] = clamp(parent_genes["morph_speed"] * (1.0 + randf_range(-mutation_strength, mutation_strength)), 0.1, 2.0)
	
	# Small chance of type mutation (speciation)
	if randf() < 0.05:
		var new_type = randi_range(0, 4)
		if new_type != parent_genes["type"]:
			mutated_genes["type"] = new_type
			# Generate new type-specific genes
			var temp_genes = generate_random_genome(new_type)
			for key in temp_genes.keys():
				if not key in mutated_genes:
					mutated_genes[key] = temp_genes[key]
	
	return mutated_genes

func die():
	# Emit death signal
	emit_signal("death_event", self)
	
	# Decay effect
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(0.1, 0.1, 0.1), 2.0)
	tween.tween_callback(Callable(self, "queue_free"))
	
	# Disable physics
	for part in body_parts:
		if part is RigidBody3D:
			part.freeze = true

# Helper functions

func find_nearby_creatures(radius):
	var nearby = []
	var space_state = get_world_3d().direct_space_state
	
	var query = PhysicsShapeQueryParameters3D.new()
	var shape = SphereShape3D.new()
	shape.radius = radius
	query.shape = shape
	query.transform = global_transform
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var collider = result["collider"]
		if collider is RigidBody3D and collider.get_parent() != self:
			var potential_creature = collider.get_parent()
			if potential_creature.has_method("get_creature_type"):
				nearby.append(potential_creature)
	
	return nearby

func adjust_physical_properties(mass_factor, friction, bounce):
	# Apply physics properties to all body parts
	for part in body_parts:
		if part is RigidBody3D:
			part.mass = mass_factor
			part.physics_material_override = PhysicsMaterial.new()
			part.physics_material_override.friction = friction
			part.physics_material_override.bounce = bounce

func count_active_connections():
	var count = 0
	
	for joint in joints:
		if joint is Generic6DOFJoint3D and joint.has_meta("symbiotic"):
			count += 1
	
	return count

func get_resonance_harmony():
	# Calculate how well this creature's resonance matches the environment
	var harmony = 0.0
	
	# Get base frequency
	var base_freq = genome.get("base_frequency", 1.0)
	
	# Check for harmonic resonance with nearby objects
	var nearby_objects = find_nearby_creatures(5.0)
	
	for obj in nearby_objects:
		if obj.creature_type == 3:  # Other resonance creatures
			var other_freq = obj.genome.get("base_frequency", 1.0)
			
			# Calculate frequency ratio
			var ratio = base_freq / other_freq
			
			# Check if it's a harmonic relationship (1:1, 2:1, 3:2, etc.)
			var harmonic_factor = 0.0
			
			if abs(ratio - 1.0) < 0.1:
				harmonic_factor = 1.0  # Unison
			elif abs(ratio - 2.0) < 0.1 or abs(ratio - 0.5) < 0.1:
				harmonic_factor = 0.8  # Octave
			elif abs(ratio - 1.5) < 0.1 or abs(ratio - 0.67) < 0.1:
				harmonic_factor = 0.6  # Fifth
			elif abs(ratio - 1.33) < 0.1 or abs(ratio - 0.75) < 0.1:
				harmonic_factor = 0.4  # Fourth
			
			harmony += harmonic_factor
	
	return min(harmony, 2.0)  # Cap harmony value

func attempt_connection(other_creature):
	# Check if already connected
	for joint in joints:
		if joint.has_meta("connected_to") and joint.get_meta("connected_to") == other_creature.get_instance_id():
			return
	
	# Calculate symbiosis benefit
	var symbiosis_factor = genome.get("symbiosis_factor", 0.5)
	var other_symbiosis = other_creature.genome.get("symbiosis_factor", 0.5)
	
	var compatibility = 1.0 - abs(symbiosis_factor - other_symbiosis)
	
	# Only connect if compatible enough
	if compatibility > 0.7:
		# Create a joint between creatures
		var joint = Generic6DOFJoint3D.new()
		
		# Set up the joint between primary body parts
		if body_parts.size() > 0 and other_creature.body_parts.size() > 0:
			joint.node_a = body_parts[0].get_path()
			joint.node_b = other_creature.body_parts[0].get_path()
			
			# Position halfway between creatures
			var midpoint = (global_transform.origin + other_creature.global_transform.origin) / 2.0
			joint.global_transform.origin = midpoint
			
			# Add metadata
			joint.set_meta("symbiotic", true)
			joint.set_meta("connected_to", other_creature.get_instance_id())
			joint.set_meta("compatibility", compatibility)
			
			# Add to scene
			get_parent().add_child(joint)
			joints.push_back(joint)
			
			# Energy bonus for both creatures
			energy += 10.0 * compatibility
			other_creature.energy += 10.0 * compatibility
			
			return true
	
	return false

func spawn_recursive_child():
	# Create a smaller version with similar genes
	var child_genes = genome.duplicate(true)
	
	# Make it smaller
	child_genes["body_scale"] = genome["body_scale"] * 0.6
	
	# Reduce recursion depth to avoid infinite recursion
	child_genes["recursion_depth"] = max(1, genome.get("recursion_depth", 2) - 1)
	
	# Create new creature
	var child_scene = load("res://scenes/creature.tscn")
	var child = child_scene.instantiate()
	
	# Position near parent
	var spawn_offset = Vector3(randf_range(-1.0, 1.0), 0.5, randf_range(-1.0, 1.0)).normalized()
	child.global_transform.origin = global_transform.origin + spawn_offset
	
	# Initialize and add to scene
	child.initialize_from_genes(child_genes)
	get_parent().add_child(child)
	
	# Use some energy
	energy -= 20.0
	
	return child

func emit_resonance_wave(position, frequency, amplitude):
	# Emit a resonance wave that affects nearby objects
	var nearby = find_nearby_creatures(amplitude * 10.0)
	
	for obj in nearby:
		if obj == self:
			continue
			
		var distance = global_transform.origin.distance_to(obj.global_transform.origin)
		var intensity = amplitude * 5.0 / max(1.0, distance)
		
		if obj.has_method("receive_resonance"):
			obj.receive_resonance(frequency, intensity)
		elif obj is RigidBody3D:
			# Apply force to physics objects
			var direction = (obj.global_transform.origin - global_transform.origin).normalized()
			var force = direction * intensity * sin(frequency * age)
			obj.apply_central_force(force)

func receive_resonance(frequency, intensity):
	# React to resonance from other objects
	if creature_type == 3:  # Only resonance creatures directly respond
		var base_freq = genome.get("base_frequency", 1.0)
		var ratio = frequency / base_freq
		
		# Calculate resonance effect
		var effect = intensity
		
		# Stronger effect for harmonic frequencies
		if abs(ratio - 1.0) < 0.1 or abs(ratio - 2.0) < 0.1 or abs(ratio - 0.5) < 0.1:
			effect *= 2.0
		
		# Apply movement effect
		var force_direction = Vector3(
			sin(age * base_freq),
			cos(age * base_freq * 1.3),
			sin(age * base_freq * 0.7)
		).normalized()
		
		if body_parts.size() > 0 and body_parts[0] is RigidBody3D:
			body_parts[0].apply_central_force(force_direction * effect * 10.0)
		
		# Energy effect
		energy += effect * 0.5
		
		return true
	
	return false

func find_energy_sources(delta):
	# Find energy from environment or food
	var energy_gain = 0.0
	
	# Base energy gain from environment
	energy_gain += 0.2 * delta
	
	# Type-specific energy sources
	match creature_type:
		0: # SYMBIOTIC - gains energy from connections
			energy_gain += count_active_connections() * 0.3 * delta
		1: # PHASE_SHIFTING - gains energy from phase transitions
			var phase_time = fmod(age, genome.get("phase_duration", 10.0))
			var phase_transition = phase_time < delta
			if phase_transition:
				energy_gain += 5.0
		2: # RECURSIVE - gains energy from structure
			energy_gain += body_parts.size() * 0.05 * delta
		3: # RESONANCE - gains energy from harmony
			energy_gain += get_resonance_harmony() * 0.4 * delta
		4: # TOPOLOGY - gains energy from genus changes
			var morph_time = fmod(age, 20.0)
			var morphing = (morph_time < 2.0 or (morph_time > 10.0 and morph_time < 12.0))
			if morphing:
				energy_gain += 0.5 * delta
	
	# Check for food objects in environment
	var food = find_food_objects()
	for item in food:
		energy_gain += consume_food(item)
	
	return energy_gain

func find_food_objects():
	# Find food objects in the environment
	var food_items = []
	var body_scale := _get_body_scale()
	var radius = 1.5 * body_scale.x
	
	var space_state = get_world_3d().direct_space_state
	
	var query = PhysicsShapeQueryParameters3D.new()
	var shape = SphereShape3D.new()
	shape.radius = radius
	query.shape = shape
	query.transform = global_transform
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var collider = result["collider"]
		if collider.has_meta("food") or collider.get_parent().has_meta("food"):
			food_items.append(collider.get_parent() if collider.get_parent().has_meta("food") else collider)
	
	return food_items

func consume_food(food_item):
	# Consume food and gain energy
	var energy_value = food_item.get_meta("energy_value") if food_item.has_meta("energy_value") else 10.0
	
	# Different creature types process food differently
	match creature_type:
		0: # SYMBIOTIC
			energy_value *= 0.8
		1: # PHASE_SHIFTING
			var phase_time = fmod(age, genome.get("phase_duration", 10.0))
			var phase_progress = phase_time / genome.get("phase_duration", 10.0)
			if phase_progress < 0.33:  # Solid phase - less efficient
				energy_value *= 0.7
			elif phase_progress < 0.66:  # Liquid phase - more efficient
				energy_value *= 1.2
			else:  # Gas phase - normal
				energy_value *= 1.0
		2: # RECURSIVE
			energy_value *= 1.0 + (genome.get("recursion_depth", 2) * 0.1)
		3: # RESONANCE
			energy_value *= 0.9
		4: # TOPOLOGY
			var genus = genome.get("genus", 1)
			energy_value *= 1.0 + (genus * 0.1)
	
	# Remove the food
	food_item.queue_free()
	
	return energy_value

func get_creature_type():
	return creature_type

func get_genome():
	return genome

func _get_body_scale() -> Vector3:
	# Safely get body scale from genome; supports different stored formats
	if genome.has("body_scale"):
		var v = genome["body_scale"]
		if typeof(v) == TYPE_VECTOR3:
			return v
		if typeof(v) == TYPE_DICTIONARY:
			# Expecting keys x,y,z
			return Vector3(v.get("x", 1.0), v.get("y", 1.0), v.get("z", 1.0))
		if typeof(v) == TYPE_ARRAY and v.size() >= 3:
			return Vector3(float(v[0]), float(v[1]), float(v[2]))
	# Fallback scale
	return Vector3.ONE
