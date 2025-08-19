extends Node3D
class_name ChengSimulation

# Simulation parameters
@export_category("Simulation Settings")
@export var entity_count: int = 30
@export var environment_size: Vector3 = Vector3(15.0, 8.0, 15.0)
@export var complexity_level: float = 0.7  # How complex the simulation behaviors are
@export var evolution_speed: float = 1.0  # How quickly entities evolve/change
@export var chaos_factor: float = 0.5  # Unpredictability of behaviors
@export var environment_reactivity: float = 0.6  # How much the environment responds

# Visual settings
@export_category("Visual Settings")
@export var visual_style: int = 0  # 0=minimal, 1=organic, 2=glitch, 3=painterly
@export var color_palette: int = 0  # Different color schemes
@export var use_post_processing: bool = true
@export var emit_particles: bool = true

# Entity configuration
@export_category("Entity Types")
@export var enable_wanderers: bool = true
@export var enable_growers: bool = true
@export var enable_networkers: bool = true
@export var enable_predators: bool = true
@export var enable_builders: bool = true

# Technical settings
@export_category("Technical Settings")
@export var max_entities: int = 100
@export var min_entity_distance: float = 1.0
@export var use_spatial_partitioning: bool = true
@export var enable_multithreading: bool = false
@export var debug_mode: bool = false

# Internal variables
var simulation_time: float = 0.0
var entities = []
var entity_types = []
var materials = []
var rng = RandomNumberGenerator.new()
var partitioning_grid = {}
var grid_cell_size = 2.0
var narrative_state = 0
var environment_nodes = []
var resource_points = []
var behavior_networks = {}
var event_history = []
var entities_to_remove = []

# Camera for recording
var recorder_camera: Camera3D

# VR integration components
var xr_origin: XROrigin3D
var xr_camera: XRCamera3D
var left_controller: XRController3D
var right_controller: XRController3D
var interaction_distance: float = 2.0
var highlighted_entity = null

# Class to hold state for simulation entities
class SimulationEntity:
	var id: int
	var type: String
	var position: Vector3
	var rotation: Vector3
	var scale: Vector3
	var velocity: Vector3
	var acceleration: Vector3
	var energy: float
	var age: float
	var state: String
	var lifespan: float
	var color: Color
	var relationships = {}
	var attributes = {}
	var history = []
	var node: Node3D
	var target: Vector3
	var path = []
	var behavior_tree = {}
	var evolved_steps = 0
	
	func _init():
		id = 0
		type = "generic"
		position = Vector3.ZERO
		rotation = Vector3.ZERO
		scale = Vector3.ONE
		velocity = Vector3.ZERO
		acceleration = Vector3.ZERO
		energy = 100.0
		age = 0.0
		state = "idle"
		lifespan = 100.0
		color = Color.WHITE
		node = null
		target = Vector3.ZERO
		evolved_steps = 0
	
	func update(delta: float, simulation) -> void:
		# Basic update logic - will be overridden by specific entity types
		age += delta
		position += velocity * delta
		
		if node:
			node.position = position
			node.rotation = rotation
			node.scale = scale
	
	func set_state(new_state: String) -> void:
		if state != new_state:
			history.append({"time": Time.get_ticks_msec(), "old_state": state, "new_state": new_state})
			state = new_state
	
	func apply_force(force: Vector3) -> void:
		acceleration += force
	
	func seek(target_pos: Vector3, weight: float = 1.0) -> Vector3:
		var desired = target_pos - position
		desired = desired.normalized() * weight
		var steer = desired - velocity
		return steer.limit_length(weight)
	
	func flee(target_pos: Vector3, weight: float = 1.0) -> Vector3:
		return seek(target_pos, -weight)
	
	func wander(weight: float = 1.0) -> Vector3:
		var circle_distance = 2.0
		var circle_radius = 1.0
		var angle_change = 0.3
		
		attributes["wander_angle"] = attributes.get("wander_angle", 0.0) + randf_range(-angle_change, angle_change)
		
		var circle_pos = velocity.normalized() * circle_distance
		var displacement = Vector3(0, 0, -1) * circle_radius
		
		displacement = displacement.rotated(Vector3.UP, attributes["wander_angle"])
		var wander_force = circle_pos + displacement
		
		return wander_force * weight

# Initialize the simulation
func _ready():
	rng.randomize()
	
	# Create materials for different entity types
	create_materials()
	
	# Register entity types
	register_entity_types()
	
	# Create the environment
	create_environment()
	
	# Create initial entities
	for i in range(entity_count):
		create_random_entity()
	
	# Setup resource points in the environment
	create_resource_points()
	
	# Setup a recorder camera
	setup_recorder_camera()
	
	# Initialize behavior networks
	initialize_behavior_networks()
	
	# Create environment influences
	create_environment_influences()
	
	# Set up VR integration
	setup_vr_integration()

# Process frame update
func _process(delta):
	simulation_time += delta * evolution_speed
	
	# Update environment
	update_environment(delta)
	
	# Update entities
	update_entities(delta)
	
	# Handle entity interactions
	handle_entity_interactions()
	
	# Apply environmental effects
	apply_environmental_effects(delta)
	
	# Evolve the simulation
	evolve_simulation(delta)
	
	# Generate emergent events
	generate_emergent_events(delta)
	
	# Maintain entity population
	maintain_entity_population()
	
	# Handle entity removal
	process_entity_removal()
	
	# Process VR interactions
	process_vr_interactions()
	
	# Debug visualization
	if debug_mode:
		update_debug_visualization()

# Create materials for different entity types
func create_materials():
	var base_material = StandardMaterial3D.new()
	base_material.roughness = 0.4
	base_material.metallic = 0.0
	materials.append(base_material)
	
	# Wanderer material
	var wanderer_material = StandardMaterial3D.new()
	wanderer_material.roughness = 0.2
	wanderer_material.metallic = 0.7
	wanderer_material.albedo_color = Color(0.3, 0.7, 0.9, 0.8)
	wanderer_material.emission_enabled = true
	wanderer_material.emission = Color(0.1, 0.3, 0.5)
	wanderer_material.emission_energy_multiplier = 0.6
	materials.append(wanderer_material)
	
	# Grower material
	var grower_material = StandardMaterial3D.new()
	grower_material.roughness = 0.8
	grower_material.metallic = 0.1
	grower_material.albedo_color = Color(0.2, 0.8, 0.4, 0.9)
	grower_material.emission_enabled = true
	grower_material.emission = Color(0.0, 0.5, 0.0)
	grower_material.emission_energy_multiplier = 0.4
	materials.append(grower_material)
	
	# Networker material
	var networker_material = StandardMaterial3D.new()
	networker_material.roughness = 0.5
	networker_material.metallic = 0.3
	networker_material.albedo_color = Color(0.8, 0.2, 0.8, 0.7)
	networker_material.emission_enabled = true
	networker_material.emission = Color(0.5, 0.0, 0.5)
	networker_material.emission_energy_multiplier = 0.5
	materials.append(networker_material)
	
	# Predator material
	var predator_material = StandardMaterial3D.new()
	predator_material.roughness = 0.3
	predator_material.metallic = 0.5
	predator_material.albedo_color = Color(0.9, 0.2, 0.2, 0.9)
	predator_material.emission_enabled = true
	predator_material.emission = Color(0.5, 0.0, 0.0)
	predator_material.emission_energy_multiplier = 0.7
	materials.append(predator_material)
	
	# Builder material
	var builder_material = StandardMaterial3D.new()
	builder_material.roughness = 0.6
	builder_material.metallic = 0.4
	builder_material.albedo_color = Color(0.9, 0.8, 0.2, 0.8)
	builder_material.emission_enabled = true
	builder_material.emission = Color(0.4, 0.4, 0.0)
	builder_material.emission_energy_multiplier = 0.5
	materials.append(builder_material)
	
	# Apply different visual styles based on setting
	apply_visual_style()

func apply_visual_style():
	match visual_style:
		0:  # Minimal
			for mat in materials:
				mat.roughness = 0.9
				mat.metallic = 0.1
				mat.emission_energy_multiplier = 0.3
		
		1:  # Organic
			for mat in materials:
				mat.roughness = 0.7
				mat.metallic = 0.2
				mat.emission_energy_multiplier = 0.4
		
		2:  # Glitch
			for mat in materials:
				mat.roughness = 0.3
				mat.metallic = 0.8
				mat.emission_energy_multiplier = 1.0
		
		3:  # Painterly
			for mat in materials:
				mat.roughness = 0.8
				mat.metallic = 0.0
				mat.emission_energy_multiplier = 0.3

# Register different entity types
func register_entity_types():
	if enable_wanderers:
		entity_types.append("wanderer")
	
	if enable_growers:
		entity_types.append("grower")
	
	if enable_networkers:
		entity_types.append("networker")
	
	if enable_predators:
		entity_types.append("predator")
	
	if enable_builders:
		entity_types.append("builder")
	
	if entity_types.is_empty():
		# Add at least one type if none are enabled
		entity_types.append("wanderer")

# Create the base environment
func create_environment():
	var environment_container = Node3D.new()
	environment_container.name = "SimulationEnvironment"
	add_child(environment_container)
	
	# Create ground plane
	var ground = MeshInstance3D.new()
	var ground_mesh = PlaneMesh.new()
	ground_mesh.size = Vector2(environment_size.x, environment_size.z)
	
	var ground_material = StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.2, 0.2, 0.2)
	ground_material.roughness = 0.8
	
	ground.mesh = ground_mesh
	ground.material_override = ground_material
	
	# Add collision shape for ground
	var ground_body = StaticBody3D.new()
	var ground_collision = CollisionShape3D.new()
	var ground_shape = BoxShape3D.new()
	ground_shape.size = Vector3(environment_size.x, 0.1, environment_size.z)
	ground_collision.shape = ground_shape
	ground_body.add_child(ground_collision)
	
	ground.add_child(ground_body)
	environment_container.add_child(ground)
	
	# Create environment features based on complexity level
	var feature_count = int(complexity_level * 20)
	
	for i in range(feature_count):
		var feature_type = rng.randi() % 3  # 0=mound, 1=pit, 2=structure
		
		match feature_type:
			0:  # Mound
				create_environment_mound(environment_container)
			1:  # Pit
				create_environment_pit(environment_container)
			2:  # Structure
				create_environment_structure(environment_container)

func create_environment_mound(parent: Node3D):
	var mound = MeshInstance3D.new()
	mound.name = "Mound"
	
	var radius = rng.randf_range(1.0, 3.0)
	var height = rng.randf_range(0.5, 2.0)
	
	var mound_mesh = SphereMesh.new()
	mound_mesh.radius = radius
	mound_mesh.height = height * 2
	mound_mesh.is_hemisphere = true
	
	var mound_material = StandardMaterial3D.new()
	mound_material.albedo_color = Color(0.3, 0.3, 0.3)
	mound_material.roughness = 0.9
	
	mound.mesh = mound_mesh
	mound.material_override = mound_material
	
	var x = rng.randf_range(-environment_size.x/2 + radius, environment_size.x/2 - radius)
	var z = rng.randf_range(-environment_size.z/2 + radius, environment_size.z/2 - radius)
	mound.position = Vector3(x, 0, z)
	
	# Add collision
	var mound_body = StaticBody3D.new()
	var mound_collision = CollisionShape3D.new()
	var mound_shape = SphereShape3D.new()
	mound_shape.radius = radius
	mound_collision.shape = mound_shape
	mound_collision.position.y = -radius + height/2
	mound_body.add_child(mound_collision)
	mound.add_child(mound_body)
	
	parent.add_child(mound)
	environment_nodes.append(mound)

func create_environment_pit(parent: Node3D):
	var pit = MeshInstance3D.new()
	pit.name = "Pit"
	
	var radius = rng.randf_range(1.0, 3.0)
	var depth = rng.randf_range(0.5, 2.0)
	
	var pit_mesh = CylinderMesh.new()
	pit_mesh.top_radius = radius
	pit_mesh.bottom_radius = radius * 0.7
	pit_mesh.height = depth
	
	var pit_material = StandardMaterial3D.new()
	pit_material.albedo_color = Color(0.1, 0.1, 0.1)
	pit_material.roughness = 0.7
	
	pit.mesh = pit_mesh
	pit.material_override = pit_material
	
	var x = rng.randf_range(-environment_size.x/2 + radius, environment_size.x/2 - radius)
	var z = rng.randf_range(-environment_size.z/2 + radius, environment_size.z/2 - radius)
	pit.position = Vector3(x, -depth/2, z)
	
	parent.add_child(pit)
	environment_nodes.append(pit)

func create_environment_structure(parent: Node3D):
	var structure = Node3D.new()
	structure.name = "Structure"
	
	var width = rng.randf_range(0.5, 2.0)
	var height = rng.randf_range(1.0, 4.0)
	var depth = rng.randf_range(0.5, 2.0)
	
	var structure_mesh = BoxMesh.new()
	structure_mesh.size = Vector3(width, height, depth)
	
	var structure_material = StandardMaterial3D.new()
	structure_material.albedo_color = Color(0.4, 0.4, 0.4)
	structure_material.roughness = 0.6
	structure_material.metallic = 0.2
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = structure_mesh
	mesh_instance.material_override = structure_material
	
	var x = rng.randf_range(-environment_size.x/2 + width, environment_size.x/2 - width)
	var z = rng.randf_range(-environment_size.z/2 + depth, environment_size.z/2 - depth)
	structure.position = Vector3(x, height/2, z)
	
	# Add collision
	var structure_body = StaticBody3D.new()
	var structure_collision = CollisionShape3D.new()
	var structure_shape = BoxShape3D.new()
	structure_shape.size = Vector3(width, height, depth)
	structure_collision.shape = structure_shape
	structure_body.add_child(structure_collision)
	
	structure.add_child(structure_body)
	structure.add_child(mesh_instance)
	parent.add_child(structure)
	environment_nodes.append(structure)

func create_resource_points():
	var resource_container = Node3D.new()
	resource_container.name = "ResourcePoints"
	add_child(resource_container)
	
	var resource_count = int(complexity_level * 15)
	
	for i in range(resource_count):
		var resource = MeshInstance3D.new()
		resource.name = "Resource_" + str(i)
		
		var resource_mesh = SphereMesh.new()
		resource_mesh.radius = 0.3
		resource_mesh.height = 0.6
		
		var resource_material = StandardMaterial3D.new()
		resource_material.albedo_color = Color(0.0, 0.8, 0.5)
		resource_material.emission_enabled = true
		resource_material.emission = Color(0.0, 0.5, 0.3)
		resource_material.emission_energy_multiplier = 0.8
		
		resource.mesh = resource_mesh
		resource.material_override = resource_material
		
		var x = rng.randf_range(-environment_size.x/2 + 1, environment_size.x/2 - 1)
		var z = rng.randf_range(-environment_size.z/2 + 1, environment_size.z/2 - 1)
		var y = 0.3  # Just above ground level
		resource.position = Vector3(x, y, z)
		
		resource_container.add_child(resource)
		resource_points.append({
			"node": resource,
			"position": resource.position,
			"energy": 100.0,
			"type": "standard",
			"last_used": 0.0
		})

# Create a random entity
func create_random_entity():
	if entities.size() >= max_entities:
		return
	
	if entity_types.is_empty():
		return
	
	var entity_type = entity_types[rng.randi() % entity_types.size()]
	var entity = SimulationEntity.new()
	entity.id = entities.size()
	entity.type = entity_type
	
	# Set random position
	var x = rng.randf_range(-environment_size.x/2 + 1, environment_size.x/2 - 1)
	var y = rng.randf_range(0.5, 1.5)
	var z = rng.randf_range(-environment_size.z/2 + 1, environment_size.z/2 - 1)
	entity.position = Vector3(x, y, z)
	
	# Set random initial velocity
	entity.velocity = Vector3(
		rng.randf_range(-1, 1),
		rng.randf_range(-0.5, 0.5),
		rng.randf_range(-1, 1)
	).normalized() * rng.randf_range(0.5, 2.0)
	
	# Set entity-specific properties
	setup_entity_properties(entity)
	
	# Create visual representation
	create_entity_visual(entity)
	
	# Add to entities list
	entities.append(entity)
	
	# Add to spatial partitioning if enabled
	if use_spatial_partitioning:
		add_to_spatial_partition(entity)

func setup_entity_properties(entity: SimulationEntity):
	# Set common properties with some randomization
	entity.energy = rng.randf_range(70.0, 100.0)
	entity.lifespan = rng.randf_range(60.0, 180.0) * (1.0 + complexity_level)
	
	match entity.type:
		"wanderer":
			entity.attributes["wander_strength"] = rng.randf_range(0.5, 1.5)
			entity.attributes["perception_radius"] = rng.randf_range(3.0, 6.0)
			entity.attributes["max_speed"] = rng.randf_range(1.5, 3.0)
			entity.attributes["curiosity"] = rng.randf_range(0.3, 1.0)
			entity.color = Color(0.3, 0.7, 0.9)
		
		"grower":
			entity.attributes["growth_rate"] = rng.randf_range(0.2, 0.8)
			entity.attributes["max_size"] = rng.randf_range(1.5, 3.0)
			entity.attributes["split_threshold"] = rng.randf_range(0.7, 0.9)
			entity.attributes["resource_efficiency"] = rng.randf_range(0.6, 1.2)
			entity.color = Color(0.2, 0.8, 0.4)
		
		"networker":
			entity.attributes["connection_range"] = rng.randf_range(2.0, 5.0)
			entity.attributes["max_connections"] = rng.randi_range(2, 6)
			entity.attributes["signal_strength"] = rng.randf_range(0.5, 1.5)
			entity.attributes["cooperation_factor"] = rng.randf_range(0.4, 1.0)
			entity.color = Color(0.8, 0.2, 0.8)
		
		"predator":
			entity.attributes["attack_strength"] = rng.randf_range(1.0, 2.5)
			entity.attributes["hunting_efficiency"] = rng.randf_range(0.6, 1.2)
			entity.attributes["aggression"] = rng.randf_range(0.5, 1.0)
			entity.attributes["stealth"] = rng.randf_range(0.3, 0.8)
			entity.color = Color(0.9, 0.2, 0.2)
		
		"builder":
			entity.attributes["construction_speed"] = rng.randf_range(0.3, 0.9)
			entity.attributes["structure_complexity"] = rng.randf_range(0.5, 1.5)
			entity.attributes["precision"] = rng.randf_range(0.7, 1.0)
			entity.attributes["creativity"] = rng.randf_range(0.4, 1.2)
			entity.color = Color(0.9, 0.8, 0.2)
		
		_:  # Default
			entity.attributes["generic_value"] = rng.randf_range(0.5, 1.5)
			entity.color = Color(0.7, 0.7, 0.7)

func create_entity_visual(entity: SimulationEntity):
	var visual = Node3D.new()
	visual.name = "Entity_" + entity.type + "_" + str(entity.id)
	
	var mesh_instance = MeshInstance3D.new()
	
	# Create different mesh based on entity type
	var mesh
	
	match entity.type:
		"wanderer":
			mesh = SphereMesh.new()
			mesh.radius = 0.3
			mesh.height = 0.6
			mesh_instance.material_override = materials[1]
		
		"grower":
			mesh = PrismMesh.new()
			mesh.size = Vector3(0.5, 0.7, 0.5)
			mesh_instance.material_override = materials[2]
		
		"networker":
			mesh = BoxMesh.new()
			mesh.size = Vector3(0.4, 0.4, 0.4)
			mesh_instance.material_override = materials[3]
		
		"predator":
			mesh = CapsuleMesh.new()
			mesh.radius = 0.25
			mesh.height = 0.8
			mesh_instance.material_override = materials[4]
		
		"builder":
			mesh = CylinderMesh.new()
			mesh.top_radius = 0.2
			mesh.bottom_radius = 0.3
			mesh.height = 0.6
			mesh_instance.material_override = materials[5]
		
		_:  # Default
			mesh = SphereMesh.new()
			mesh.radius = 0.3
			mesh.height = 0.6
			mesh_instance.material_override = materials[0]
	
	mesh_instance.mesh = mesh
	
	# Add trail effect for some entities
	if entity.type == "wanderer" or entity.type == "predator":
		var trail = create_trail_effect(entity.color)
		visual.add_child(trail)
	
	# Add custom effects for specific types
	match entity.type:
		"networker":
			var connection_visualizer = create_connection_visualizer()
			visual.add_child(connection_visualizer)
		
		"builder":
			var construction_visualizer = create_construction_visualizer()
			visual.add_child(construction_visualizer)
	
	# Add collider for entity
	var entity_body = Area3D.new()
	entity_body.collision_layer = 2  # Entity layer
	entity_body.collision_mask = 1    # Environment layer
	
	var collision_shape = CollisionShape3D.new()
	var shape
	
	match entity.type:
		"wanderer":
			shape = SphereShape3D.new()
			shape.radius = 0.3
		"grower":
			shape = BoxShape3D.new()
			shape.size = Vector3(0.5, 0.7, 0.5)
		"networker":
			shape = BoxShape3D.new()
			shape.size = Vector3(0.4, 0.4, 0.4)
		"predator":
			shape = CapsuleShape3D.new()
			shape.radius = 0.25
			shape.height = 0.8
		"builder":
			shape = CylinderShape3D.new()
			shape.radius = 0.3
			shape.height = 0.6
		_:
			shape = SphereShape3D.new()
			shape.radius = 0.3
	
	collision_shape.shape = shape
	entity_body.add_child(collision_shape)
	visual.add_child(entity_body)
	
	# Add selection area for VR interaction
	var selection_area = Area3D.new()
	selection_area.collision_layer = 4  # Interactive layer
	selection_area.collision_mask = 0    # No collision with anything
	
	var selection_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.5  # Slightly larger than entity for easier selection
	selection_shape.shape = sphere_shape
	selection_area.add_child(selection_shape)
	visual.add_child(selection_area)
	
	# Connect signals for interaction
	entity_body.body_entered.connect(_on_entity_body_entered.bind(entity))
	entity_body.body_exited.connect(_on_entity_body_exited.bind(entity))
	selection_area.input_event.connect(_on_entity_input_event.bind(entity))
	
	visual.add_child(mesh_instance)
	add_child(visual)
	
	entity.node = visual
	entity.node.position = entity.position

func update_environment(delta: float):
	# Process resource points
	for resource in resource_points:
		# Regenerate energy slowly
		if resource.energy < 100.0:
			resource.energy += delta * 2.0
			
			# Visual feedback for regeneration
			if resource.node:
				var material = resource.node.material_override as StandardMaterial3D
				if material:
					var energy_ratio = resource.energy / 100.0
					material.emission_energy_multiplier = 0.3 + energy_ratio * 0.5
		
		# Slowly move resources
		if rng.randf() < delta * 0.05:
			var movement = Vector3(
				rng.randf_range(-0.5, 0.5),
				0,
				rng.randf_range(-0.5, 0.5)
			) * delta
			
			resource.position += movement
			
			if resource.node:
				resource.node.position = resource.position

func handle_entity_interactions():
	# Handle interactions between entities that are close to each other
	if use_spatial_partitioning:
		# Only check entities that are in the same or adjacent cells
		for cell_key in partitioning_grid.keys():
			var entities_in_cell = partitioning_grid[cell_key]
			if entities_in_cell.size() < 2:
				continue
				
			# Check interactions between entities in this cell
			for i in range(entities_in_cell.size()):
				for j in range(i + 1, entities_in_cell.size()):
					var entity1_id = entities_in_cell[i]
					var entity2_id = entities_in_cell[j]
					
					if entity1_id < entities.size() and entity2_id < entities.size():
						var entity1 = entities[entity1_id]
						var entity2 = entities[entity2_id]
						
						var distance = entity1.position.distance_to(entity2.position)
						if distance < 1.0:
							process_entity_interaction(entity1, entity2)
			
			# Also check adjacent cells
			for dx in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					for dz in [-1, 0, 1]:
						if dx == 0 and dy == 0 and dz == 0:
							continue
							
						var adjacent_key = Vector3i(cell_key.x + dx, cell_key.y + dy, cell_key.z + dz)
						if partitioning_grid.has(adjacent_key):
							var entities_in_adjacent = partitioning_grid[adjacent_key]
							
							for entity1_id in entities_in_cell:
								for entity2_id in entities_in_adjacent:
									if entity1_id < entities.size() and entity2_id < entities.size():
										var entity1 = entities[entity1_id]
										var entity2 = entities[entity2_id]
										
										var distance = entity1.position.distance_to(entity2.position)
										if distance < 1.0:
											process_entity_interaction(entity1, entity2)
	else:
		# Brute force approach
		for i in range(entities.size()):
			for j in range(i + 1, entities.size()):
				var entity1 = entities[i]
				var entity2 = entities[j]
				
				var distance = entity1.position.distance_to(entity2.position)
				if distance < 1.0:
					process_entity_interaction(entity1, entity2)

func apply_environmental_effects(delta: float):
	# Apply environmental constraints
	for entity in entities:
		# Apply gravity
		if entity.position.y > 0.5:
			entity.velocity.y -= 9.8 * delta
		
		# Constrain to environment boundaries
		constrain_to_environment(entity)
		
		# Apply friction
		entity.velocity = entity.velocity.lerp(Vector3.ZERO, delta)
		
		# Apply dynamic environment effects
		if chaos_factor > 0:
			# Add random noise to velocity
			entity.velocity += Vector3(
				rng.randf_range(-1, 1),
				rng.randf_range(-0.5, 0.5),
				rng.randf_range(-1, 1)
			) * delta * chaos_factor
func process_entity_interaction(entity1: SimulationEntity, entity2: SimulationEntity):
	# Different interactions based on entity types
	
	# Create a type pair key for easy matching
	var type_pair = entity1.type + "_" + entity2.type
	if entity1.type > entity2.type:
		type_pair = entity2.type + "_" + entity1.type
	
	match type_pair:
		"wanderer_wanderer":
			# Wanderers might exchange information or briefly follow each other
			if rng.randf() < 0.3:
				# Share information (represented as temporary target)
				if entity1.target != Vector3.ZERO and entity2.target == Vector3.ZERO:
					entity2.target = entity1.target
					entity2.attributes["curiosity"] = min(1.0, entity2.attributes["curiosity"] + 0.05)
				elif entity2.target != Vector3.ZERO and entity1.target == Vector3.ZERO:
					entity1.target = entity2.target
					entity1.attributes["curiosity"] = min(1.0, entity1.attributes["curiosity"] + 0.05)
		
		"wanderer_grower":
			# Wanderers might stimulate growth in growers
			if entity1.type == "wanderer":
				entity2.energy = min(100.0, entity2.energy + 5.0)
				entity2.attributes["growth_rate"] = min(1.0, entity2.attributes["growth_rate"] + 0.02)
			else:
				entity1.energy = min(100.0, entity1.energy + 5.0)
				entity1.attributes["growth_rate"] = min(1.0, entity1.attributes["growth_rate"] + 0.02)
		
		"wanderer_networker":
			# Wanderers can provide information to networkers
			if entity1.type == "wanderer":
				entity2.energy = min(100.0, entity2.energy + 2.0)
				entity2.attributes["signal_strength"] = min(2.0, entity2.attributes["signal_strength"] + 0.05)
			else:
				entity1.energy = min(100.0, entity1.energy + 2.0)
				entity1.attributes["signal_strength"] = min(2.0, entity1.attributes["signal_strength"] + 0.05)
		
		"wanderer_predator":
			# Wanderers might get attacked by predators
			if entity1.type == "predator":
				if rng.randf() < entity1.attributes["attack_strength"] * 0.2:
					entity2.energy = max(10.0, entity2.energy - 15.0)
					entity1.energy = min(100.0, entity1.energy + 10.0)
					create_attack_effect(entity1.position, entity2.position)
			else:
				if rng.randf() < entity2.attributes["attack_strength"] * 0.2:
					entity1.energy = max(10.0, entity1.energy - 15.0)
					entity2.energy = min(100.0, entity2.energy + 10.0)
					create_attack_effect(entity2.position, entity1.position)
		
		"wanderer_builder":
			# Wanderers might inspire builders
			if entity1.type == "wanderer":
				entity2.attributes["creativity"] = min(2.0, entity2.attributes["creativity"] + 0.03)
			else:
				entity1.attributes["creativity"] = min(2.0, entity1.attributes["creativity"] + 0.03)
		
		"grower_grower":
			# Growers might accelerate each other's growth
			entity1.attributes["growth_rate"] = min(1.0, entity1.attributes["growth_rate"] + 0.01)
			entity2.attributes["growth_rate"] = min(1.0, entity2.attributes["growth_rate"] + 0.01)
		
		"grower_networker":
			# Growers can provide energy to networkers
			if entity1.type == "grower" and entity1.energy > 50.0:
				var transfer = min(10.0, entity1.energy * 0.1)
				entity1.energy -= transfer
				entity2.energy = min(100.0, entity2.energy + transfer)
			elif entity2.type == "grower" and entity2.energy > 50.0:
				var transfer = min(10.0, entity2.energy * 0.1)
				entity2.energy -= transfer
				entity1.energy = min(100.0, entity1.energy + transfer)
		
		"grower_predator":
			# Predators might attack growers
			if entity1.type == "predator":
				if rng.randf() < entity1.attributes["attack_strength"] * 0.3:
					var damage = min(20.0, entity2.energy * 0.3)
					entity2.energy -= damage
					entity1.energy = min(100.0, entity1.energy + damage * 0.8)
					create_attack_effect(entity1.position, entity2.position)
			else:
				if rng.randf() < entity2.attributes["attack_strength"] * 0.3:
					var damage = min(20.0, entity1.energy * 0.3)
					entity1.energy -= damage
					entity2.energy = min(100.0, entity2.energy + damage * 0.8)
					create_attack_effect(entity2.position, entity1.position)
		
		"grower_builder":
			# Growers can provide resources to builders
			if entity1.type == "grower" and entity1.energy > 40.0:
				var transfer = min(5.0, entity1.energy * 0.1)
				entity1.energy -= transfer
				entity2.energy = min(100.0, entity2.energy + transfer * 1.5)
			elif entity2.type == "grower" and entity2.energy > 40.0:
				var transfer = min(5.0, entity2.energy * 0.1)
				entity2.energy -= transfer
				entity1.energy = min(100.0, entity1.energy + transfer * 1.5)
		
		"networker_networker":
			# Networkers form connections and share energy/information
			if not entity1.relationships.has(entity2.id) or entity1.relationships[entity2.id] != "connected":
				entity1.relationships[entity2.id] = "connected"
				entity2.relationships[entity1.id] = "connected"
				
				# Balance energy between them
				var avg_energy = (entity1.energy + entity2.energy) / 2.0
				#entity1.energy = entity2.energy = avg_energy
		
		"networker_predator":
			# Networkers might get attacked by predators but can warn others
			if entity1.type == "predator":
				if rng.randf() < entity1.attributes["attack_strength"] * 0.2:
					entity2.energy = max(10.0, entity2.energy - 15.0)
					entity1.energy = min(100.0, entity1.energy + 10.0)
					create_attack_effect(entity1.position, entity2.position)
					
					# Warn connected networkers
					warn_connected_networkers(entity2, entity1)
			else:
				if rng.randf() < entity2.attributes["attack_strength"] * 0.2:
					entity1.energy = max(10.0, entity1.energy - 15.0)
					entity2.energy = min(100.0, entity2.energy + 10.0)
					create_attack_effect(entity2.position, entity1.position)
					
					# Warn connected networkers
					warn_connected_networkers(entity1, entity2)
		
		"networker_builder":
			# Networkers can coordinate with builders
			if entity1.type == "networker":
				entity2.attributes["precision"] = min(1.0, entity2.attributes["precision"] + 0.02)
			else:
				entity1.attributes["precision"] = min(1.0, entity1.attributes["precision"] + 0.02)
		
		"predator_predator":
			# Predators might fight or form temporary hunting packs
			if rng.randf() < 0.3:
				# Form hunting pack
				entity1.relationships[entity2.id] = "pack"
				entity2.relationships[entity1.id] = "pack"
			else:
				# Fight for dominance
				var winner
				var loser
				
				if entity1.attributes["attack_strength"] > entity2.attributes["attack_strength"]:
					winner = entity1
					loser = entity2
				else:
					winner = entity2
					loser = entity1
				
				var damage = winner.attributes["attack_strength"] * 10.0
				loser.energy = max(5.0, loser.energy - damage)
				winner.energy = min(100.0, winner.energy + damage * 0.2)
				
				create_attack_effect(winner.position, loser.position)
		
		"predator_builder":
			# Predators might attack builders
			if entity1.type == "predator":
				if rng.randf() < entity1.attributes["attack_strength"] * 0.25:
					entity2.energy = max(10.0, entity2.energy - 20.0)
					entity1.energy = min(100.0, entity1.energy + 10.0)
					create_attack_effect(entity1.position, entity2.position)
					
					# Disrupt construction
					if entity2.attributes.has("construction_state") and entity2.attributes["construction_state"] == "building":
						entity2.attributes["construction_progress"] = max(0.0, entity2.attributes["construction_progress"] - 0.3)
			else:
				if rng.randf() < entity2.attributes["attack_strength"] * 0.25:
					entity1.energy = max(10.0, entity1.energy - 20.0)
					entity2.energy = min(100.0, entity2.energy + 10.0)
					create_attack_effect(entity2.position, entity1.position)
					
					# Disrupt construction
					if entity1.attributes.has("construction_state") and entity1.attributes["construction_state"] == "building":
						entity1.attributes["construction_progress"] = max(0.0, entity1.attributes["construction_progress"] - 0.3)
		
		"builder_builder":
			# Builders can collaborate on projects
			if rng.randf() < 0.4:
				# Share construction techniques
				var avg_precision = (entity1.attributes["precision"] + entity2.attributes["precision"]) / 2.0
				var avg_speed = (entity1.attributes["construction_speed"] + entity2.attributes["construction_speed"]) / 2.0
				
				entity1.attributes["precision"] = avg_precision + 0.05
				entity2.attributes["precision"] = avg_precision + 0.05
				
				entity1.attributes["construction_speed"] = avg_speed + 0.05
				entity2.attributes["construction_speed"] = avg_speed + 0.05
				
				# If one is building, help the other
				if entity1.attributes.has("construction_state") and entity1.attributes["construction_state"] == "building":
					entity1.attributes["construction_progress"] = min(1.0, entity1.attributes["construction_progress"] + 0.1)
				
				if entity2.attributes.has("construction_state") and entity2.attributes["construction_state"] == "building":
					entity2.attributes["construction_progress"] = min(1.0, entity2.attributes["construction_progress"] + 0.1)

func update_wanderer(entity: SimulationEntity, delta: float):
	# Wanderers explore and seek interesting things
	
	# Apply wander behavior
	var wander_force = entity.wander(entity.attributes["wander_strength"])
	
	# Check if entity should seek a target
	if entity.target != Vector3.ZERO:
		# If close to target, clear it
		if entity.position.distance_to(entity.target) < 1.0:
			entity.target = Vector3.ZERO
		else:
			# Seek the target
			var seek_force = entity.seek(entity.target)
			entity.apply_force(seek_force)
	else:
		# Find a new target occasionally
		if rng.randf() < delta * entity.attributes["curiosity"]:
			var new_target = find_interest_target(entity)
			if new_target:
				entity.target = new_target
	
	# Apply forces
	entity.apply_force(wander_force)
	
	# Update velocity and position
	entity.velocity += entity.acceleration * delta
	var max_speed = entity.attributes["max_speed"]
	entity.velocity = entity.velocity.limit_length(max_speed)
	entity.position += entity.velocity * delta
	
	# Reset acceleration
	entity.acceleration = Vector3.ZERO
	
	# Update node position and rotation
	if entity.node:
		entity.node.position = entity.position
		
		# Orient in direction of movement
		if entity.velocity.length() > 0.1:
			var look_dir = entity.velocity.normalized()
			entity.node.look_at(entity.position + look_dir, Vector3.UP)
	
	# Check for state changes
	if entity.energy < 30.0:
		entity.set_state("hungry")
	elif entity.energy > 70.0:
		entity.set_state("exploring")
	else:
		entity.set_state("searching")


func update_grower(entity: SimulationEntity, delta: float):
	# Growers stay relatively stationary and grow
	
	# Slower movement for growers
	var wander_force = entity.wander(0.5)
	entity.apply_force(wander_force)
	
	# Update velocity and position
	entity.velocity += entity.acceleration * delta
	entity.velocity = entity.velocity.limit_length(1.0)  # Growers move slowly
	entity.position += entity.velocity * delta
	
	# Reset acceleration
	entity.acceleration = Vector3.ZERO
	
	# Handle growth
	var growth_rate = entity.attributes["growth_rate"]
	var max_size = entity.attributes["max_size"]
	
	# Scale up to max size based on age and growth rate
	var target_scale = min(1.0 + (entity.age * growth_rate * 0.05), max_size)
	
	# Check if near resources to accelerate growth
	var nearby_resources = get_entities_in_radius(entity.position, 2.0)
	for resource in resource_points:
		if entity.position.distance_to(resource.position) < 2.0 and resource.energy > 10.0:
			# Consume resource
			var consumption = min(delta * 10.0, resource.energy * 0.5)
			resource.energy -= consumption
			entity.energy += consumption * entity.attributes["resource_efficiency"]
			
			# Accelerate growth
			target_scale += delta * 0.1
			break
	
	# Update scale
	if entity.node:
		entity.scale = Vector3.ONE * target_scale
		entity.node.scale = entity.scale
	
	# Check for reproduction
	if entity.scale.x >= entity.attributes["split_threshold"] * max_size and entity.energy > 80.0:
		if entities.size() < max_entities:
			split_grower(entity)
	
	# Update state
	if entity.energy < 30.0:
		entity.set_state("absorbing")
	elif entity.scale.x >= entity.attributes["split_threshold"] * max_size:
		entity.set_state("splitting")
	else:
		entity.set_state("growing")


func update_networker(entity: SimulationEntity, delta: float):
	# Networkers form connections and share information
	
	# Movement - attracted to other networkers
	var wander_force = entity.wander(0.7)
	entity.apply_force(wander_force)
	
	# Find nearby networkers to connect with
	var nearby_entities = get_entities_in_radius(entity.position, entity.attributes["connection_range"])
	var connected_count = 0
	
	for nearby in nearby_entities:
		if nearby.id != entity.id and nearby.type == "networker":
			# Establish connection
			if not entity.relationships.has(nearby.id) or entity.relationships[nearby.id] != "connected":
				entity.relationships[nearby.id] = "connected"
				nearby.relationships[entity.id] = "connected"
				
				# Draw connection line
				update_network_connections(entity)
				
				connected_count += 1
			
			# Seek other networkers
			var seek_force = entity.seek(nearby.position, 0.5)
			entity.apply_force(seek_force)
		
		# Reached max connections
		if connected_count >= entity.attributes["max_connections"]:
			break
	
	# Update velocity and position
	entity.velocity += entity.acceleration * delta
	entity.velocity = entity.velocity.limit_length(1.5)
	entity.position += entity.velocity * delta
	
	# Reset acceleration
	entity.acceleration = Vector3.ZERO
	
	# Update node
	if entity.node:
		entity.node.position = entity.position
		
		# Update connection visualizer
		var connector = entity.node.get_node_or_null("Connections")
		if connector:
			for child in connector.get_children():
				if child is MeshInstance3D:
					child.visible = false
	
	# Update state
	if connected_count > 0:
		entity.set_state("connected")
	else:
		entity.set_state("searching")


func update_predator(entity: SimulationEntity, delta: float):
	# Predators hunt other entities
	
	# Wander behavior
	var wander_force = entity.wander(0.8)
	entity.apply_force(wander_force)
	
	# Find prey
	var target_entity = null
	var nearest_distance = INF
	
	# Look for potential prey within perception range
	var nearby_entities = get_entities_in_radius(entity.position, 6.0)
	for nearby in nearby_entities:
		if nearby.id != entity.id and (nearby.type == "wanderer" or nearby.type == "grower" or nearby.type == "networker"):
			var distance = entity.position.distance_to(nearby.position)
			
			if distance < nearest_distance:
				nearest_distance = distance
				target_entity = nearby
	
	# Hunt target
	if target_entity and entity.energy < 80.0:
		var hunt_strength = entity.attributes["hunting_efficiency"]
		var seek_force = entity.seek(target_entity.position, hunt_strength)
		entity.apply_force(seek_force)
		
		entity.target = target_entity.position
		entity.set_state("hunting")
		
		# If close enough, attempt attack
		if nearest_distance < 1.0 and rng.randf() < entity.attributes["attack_strength"] * 0.1:
			var damage = 10.0 * entity.attributes["attack_strength"]
			target_entity.energy = max(10.0, target_entity.energy - damage)
			entity.energy = min(100.0, entity.energy + damage * 0.7)
			
			create_attack_effect(entity.position, target_entity.position)
	else:
		entity.set_state("stalking")
	
	# Update velocity and position
	entity.velocity += entity.acceleration * delta
	var max_speed = 2.0 + entity.attributes["hunting_efficiency"] * 0.5
	entity.velocity = entity.velocity.limit_length(max_speed)
	entity.position += entity.velocity * delta
	
	# Reset acceleration
	entity.acceleration = Vector3.ZERO
	
	# Update node position and rotation
	if entity.node:
		entity.node.position = entity.position
		
		# Orient in direction of movement
		if entity.velocity.length() > 0.1:
			var look_dir = entity.velocity.normalized()
			entity.node.look_at(entity.position + look_dir, Vector3.UP)


func update_builder(entity: SimulationEntity, delta: float):
	# Builders construct structures
	
	# Slower movement when building
	var movement_speed = 1.5
	var is_building = entity.attributes.get("construction_state", "") == "building"
	
	if is_building:
		movement_speed = 0.5
	
	# Apply wander behavior
	var wander_force = entity.wander(0.6)
	entity.apply_force(wander_force)
	
	# Either building or looking for resources
	if is_building:
		# Update construction progress
		entity.attributes["construction_progress"] = min(1.0, entity.attributes["construction_progress"] + delta * entity.attributes["construction_speed"])
		
		# If construction complete
		if entity.attributes["construction_progress"] >= 1.0:
			complete_construction(entity)
			entity.attributes.erase("construction_state")
	else:
		# Find resources to start building
		if entity.energy > 50.0 and rng.randf() < delta * entity.attributes["creativity"]:
			start_construction(entity)
	
	# Update velocity and position
	entity.velocity += entity.acceleration * delta
	entity.velocity = entity.velocity.limit_length(movement_speed)
	entity.position += entity.velocity * delta
	
	# Reset acceleration
	entity.acceleration = Vector3.ZERO
	
	# Update node
	if entity.node:
		entity.node.position = entity.position
		
		# Update construction visualizer
		if is_building:
			update_construction_visualizer(entity)
	
	# Update state
	if is_building:
		entity.set_state("building")
	elif entity.energy < 30.0:
		entity.set_state("gathering")
	else:
		entity.set_state("planning")


func evolve_entity(entity: SimulationEntity):
	# Apply evolutionary changes based on entity state and history
	var evolution_factor = 0.2
	entity.evolved_steps += 1
	
	match entity.type:
		"wanderer":
			if entity.state == "exploring":
				entity.attributes["perception_radius"] = min(8.0, entity.attributes["perception_radius"] + evolution_factor * 0.5)
			elif entity.state == "hungry":
				entity.attributes["max_speed"] = min(4.0, entity.attributes["max_speed"] + evolution_factor * 0.3)
		
		"grower":
			if entity.state == "growing":
				entity.attributes["growth_rate"] = min(1.2, entity.attributes["growth_rate"] + evolution_factor * 0.1)
			elif entity.state == "absorbing":
				entity.attributes["resource_efficiency"] = min(1.5, entity.attributes["resource_efficiency"] + evolution_factor * 0.1)
		
		"networker":
			if entity.state == "connected":
				entity.attributes["signal_strength"] = min(2.0, entity.attributes["signal_strength"] + evolution_factor * 0.2)
			elif entity.state == "searching":
				entity.attributes["connection_range"] = min(7.0, entity.attributes["connection_range"] + evolution_factor * 0.3)
		
		"predator":
			if entity.state == "hunting":
				entity.attributes["attack_strength"] = min(3.0, entity.attributes["attack_strength"] + evolution_factor * 0.15)
			elif entity.state == "stalking":
				entity.attributes["stealth"] = min(1.0, entity.attributes["stealth"] + evolution_factor * 0.1)
		
		"builder":
			if entity.state == "building":
				entity.attributes["construction_speed"] = min(1.2, entity.attributes["construction_speed"] + evolution_factor * 0.1)
			elif entity.state == "planning":
				entity.attributes["creativity"] = min(1.7, entity.attributes["creativity"] + evolution_factor * 0.15)
	
	# Update entity appearance based on evolution
	if entity.node and entity.evolved_steps % 3 == 0:
		var mesh_instance = entity.node.get_child(0)
		if mesh_instance is MeshInstance3D:
			var material = mesh_instance.material_override.duplicate()
			
			# Increase emission with evolution
			if material:
				material.emission_energy_multiplier = min(2.0, material.emission_energy_multiplier + 0.2)
				mesh_instance.material_override = material
	
	# Record evolution event
	event_history.append({
		"time": simulation_time,
		"type": "evolution",
		"entity_id": entity.id,
		"entity_type": entity.type,
		"state": entity.state,
		"evolved_steps": entity.evolved_steps
	})


func apply_environmental_influences(delta: float):
	# Apply dynamic environmental influences based on settings
	var influence_range = environment_reactivity * 10.0
	
	# Create temporary environmental effects
	if rng.randf() < delta * environment_reactivity * 0.1:
		var effect_type = rng.randi() % 3
		
		match effect_type:
			0:  # Energy field
				create_energy_field()
			
			1:  # Atmospheric disturbance
				create_atmospheric_disturbance()
			
			2:  # Resource wave
				create_resource_wave()


func create_energy_field():
	# Create a temporary energy field that affects entities
	var field_position = Vector3(
		rng.randf_range(-environment_size.x/2, environment_size.x/2),
		rng.randf_range(0.5, environment_size.y/2),
		rng.randf_range(-environment_size.z/2, environment_size.z/2)
	)
	
	var field_radius = rng.randf_range(3.0, 6.0)
	var field_duration = rng.randf_range(5.0, 15.0)
	var boost_energy = rng.randf_range(10.0, 30.0)
	
	# Create field visualization
	var field_visualization = Node3D.new()
	field_visualization.name = "EnergyField"
	
	var field_mesh = SphereMesh.new()
	field_mesh.radius = field_radius
	field_mesh.height = field_radius * 2
	
	var field_material = StandardMaterial3D.new()
	field_material.albedo_color = Color(0.2, 0.8, 0.9, 0.3)
	field_material.emission_enabled = true
	field_material.emission = Color(0.4, 0.7, 0.9)
	field_material.emission_energy_multiplier = 0.5
	field_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	var field_instance = MeshInstance3D.new()
	field_instance.mesh = field_mesh
	field_instance.material_override = field_material
	
	field_visualization.position = field_position
	field_visualization.add_child(field_instance)
	add_child(field_visualization)
	
	# Apply effects
	for entity in get_entities_in_radius(field_position, field_radius):
		entity.energy = min(100.0, entity.energy + boost_energy)
		
		# Type-specific boosts
		match entity.type:
			"wanderer":
				entity.attributes["curiosity"] *= 1.2
			"grower":
				entity.attributes["growth_rate"] *= 1.2
			"networker":
				entity.attributes["signal_strength"] *= 1.2
			"predator":
				entity.attributes["attack_strength"] *= 1.2
			"builder":
				entity.attributes["creativity"] *= 1.2
	
	# Make field disappear after duration
	var timer = Timer.new()
	timer.wait_time = field_duration
	timer.one_shot = true
	timer.autostart = true
	field_visualization.add_child(timer)
	timer.timeout.connect(func(): field_visualization.queue_free())


func create_atmospheric_disturbance():
	# Create a temporary atmospheric effect that influences entity behavior
	var disturbance_position = Vector3(
		rng.randf_range(-environment_size.x/2, environment_size.x/2),
		rng.randf_range(0.5, environment_size.y/2),
		rng.randf_range(-environment_size.z/2, environment_size.z/2)
	)
	
	var disturbance_radius = rng.randf_range(5.0, 10.0)
	var disturbance_duration = rng.randf_range(10.0, 20.0)
	var disturbance_strength = rng.randf_range(0.5, 2.0)
	
	# Create disturbance visualization
	var disturbance_visualization = CPUParticles3D.new()
	disturbance_visualization.name = "AtmosphericDisturbance"
	disturbance_visualization.position = disturbance_position
	disturbance_visualization.amount = 100
	disturbance_visualization.lifetime = 2.0
	disturbance_visualization.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	disturbance_visualization.emission_sphere_radius = disturbance_radius
	disturbance_visualization.gravity = Vector3.ZERO
	disturbance_visualization.initial_velocity_min = 0.5
	disturbance_visualization.initial_velocity_max = 1.5
	disturbance_visualization.color = Color(0.7, 0.7, 0.9, 0.5)
	
	add_child(disturbance_visualization)
	
	# Schedule effect application
	var effect_timer = Timer.new()
	effect_timer.wait_time = 1.0
	effect_timer.autostart = true
	disturbance_visualization.add_child(effect_timer)
	
	# Apply disturbance effects periodically
	effect_timer.timeout.connect(func():
		for entity in get_entities_in_radius(disturbance_position, disturbance_radius):
			# Apply a force away from the center
			var direction = (entity.position - disturbance_position).normalized()
			entity.apply_force(direction * disturbance_strength)
			
			# Slightly reduce energy
			entity.energy = max(10.0, entity.energy - 1.0)
	)
	
	# Make disturbance disappear after duration
	var timer = Timer.new()
	timer.wait_time = disturbance_duration
	timer.one_shot = true
	timer.autostart = true
	disturbance_visualization.add_child(timer)
	timer.timeout.connect(func():
		effect_timer.queue_free()
		disturbance_visualization.queue_free()
	)


func create_resource_wave():
	# Create a wave of temporary resources
	var wave_center = Vector3(
		rng.randf_range(-environment_size.x/2, environment_size.x/2),
		0.3,  # Just above ground
		rng.randf_range(-environment_size.z/2, environment_size.z/2)
	)
	
	var resource_count = rng.randi_range(5, 10)
	var wave_radius = rng.randf_range(3.0, 8.0)
	var wave_duration = rng.randf_range(20.0, 40.0)
	
	var wave_container = Node3D.new()
	wave_container.name = "ResourceWave"
	add_child(wave_container)
	
	var temp_resources = []
	
	# Create resources in a circular pattern
	for i in range(resource_count):
		var angle = 2 * PI * i / resource_count
		var distance = wave_radius * rng.randf_range(0.5, 1.0)
		var x = wave_center.x + cos(angle) * distance
		var z = wave_center.z + sin(angle) * distance
		
		var resource = MeshInstance3D.new()
		resource.name = "WaveResource_" + str(i)
		
		var resource_mesh = SphereMesh.new()
		resource_mesh.radius = 0.25
		resource_mesh.height = 0.5
		
		var resource_material = StandardMaterial3D.new()
		resource_material.albedo_color = Color(0.4, 0.9, 0.4)
		resource_material.emission_enabled = true
		resource_material.emission = Color(0.2, 0.8, 0.2)
		resource_material.emission_energy_multiplier = 0.7
		
		resource.mesh = resource_mesh
		resource.material_override = resource_material
		resource.position = Vector3(x, wave_center.y, z)
		
		wave_container.add_child(resource)
		
		# Add to temporary resources list
		temp_resources.append({
			"node": resource,
			"position": resource.position,
			"energy": 50.0,
			"type": "wave",
			"last_used": 0.0
		})
	
	# Add temporary resources to the main resource points list
	resource_points.append_array(temp_resources)
	
	# Create wave effect
	var particles = CPUParticles3D.new()
	particles.position = wave_center
	particles.amount = 50
	particles.lifetime = 2.0
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 180.0
	particles.initial_velocity_min = 1.0
	particles.initial_velocity_max = 3.0
	particles.color = Color(0.4, 0.9, 0.4)
	
	particles.emitting = true
	wave_container.add_child(particles)
	
	# Remove wave after duration
	var timer = Timer.new()
	timer.wait_time = wave_duration
	timer.one_shot = true
	timer.autostart = true
	wave_container.add_child(timer)
	timer.timeout.connect(func():
		# Remove temporary resources from the main list
		for temp_resource in temp_resources:
			resource_points.erase(temp_resource)
		
		wave_container.queue_free()
	)


func split_grower(entity: SimulationEntity):
	# Create a new grower as a result of splitting
	var new_entity = SimulationEntity.new()
	new_entity.id = entities.size()
	new_entity.type = "grower"
	
	# Position slightly offset from parent
	var random_offset = Vector3(
		rng.randf_range(-1.0, 1.0),
		rng.randf_range(0.0, 0.5),
		rng.randf_range(-1.0, 1.0)
	).normalized() * 1.0
	
	new_entity.position = entity.position + random_offset
	
	# Set properties - inherit some from parent
	new_entity.energy = entity.energy * 0.5
	entity.energy *= 0.5
	
	new_entity.attributes["growth_rate"] = entity.attributes["growth_rate"] * rng.randf_range(0.9, 1.1)
	new_entity.attributes["max_size"] = entity.attributes["max_size"] * rng.randf_range(0.9, 1.1)
	new_entity.attributes["split_threshold"] = entity.attributes["split_threshold"] * rng.randf_range(0.9, 1.1)
	new_entity.attributes["resource_efficiency"] = entity.attributes["resource_efficiency"] * rng.randf_range(0.9, 1.1)
	
	new_entity.color = entity.color
	
	# Reset parent entity's scale
	entity.scale = Vector3.ONE * 0.7
	if entity.node:
		entity.node.scale = entity.scale
	
	# Create visual representation
	create_entity_visual(new_entity)
	
	# Add to entities list
	entities.append(new_entity)
	
	# Add to spatial partitioning
	if use_spatial_partitioning:
		add_to_spatial_partition(new_entity)
	
	# Create split effect
	var particles = CPUParticles3D.new()
	particles.position = entity.position
	particles.amount = 20
	particles.lifetime = 1.0
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 180.0
	particles.initial_velocity_min = 1.0
	particles.initial_velocity_max = 2.0
	particles.color = entity.color
	
	particles.emitting = true
	add_child(particles)
	
	# Auto-remove after effect finishes
	var timer = Timer.new()
	timer.wait_time = 1.5
	timer.one_shot = true
	timer.autostart = true
	particles.add_child(timer)
	timer.timeout.connect(func(): particles.queue_free())


func update_network_connections(entity: SimulationEntity):
	if not entity.node:
		return
	
	var connector = entity.node.get_node_or_null("Connections")
	if not connector:
		return
	
	# Clear existing connections
	for child in connector.get_children():
		child.queue_free()
	
	# Draw connections to other entities
	for connected_id in entity.relationships.keys():
		if entity.relationships[connected_id] == "connected" and connected_id < entities.size():
			var connected_entity = entities[connected_id]
			
			# Create connection line
			var line = MeshInstance3D.new()
			line.name = "Connection_" + str(connected_id)
			
			var line_mesh = CylinderMesh.new()
			line_mesh.top_radius = 0.02
			line_mesh.bottom_radius = 0.02
			line_mesh.height = 1.0  # Will be scaled
			
			var line_material = StandardMaterial3D.new()
			line_material.albedo_color = Color(0.8, 0.2, 0.8, 0.7)
			line_material.emission_enabled = true
			line_material.emission = Color(0.8, 0.2, 0.8)
			line_material.emission_energy_multiplier = 0.5
			line_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			
			line.mesh = line_mesh
			line.material_override = line_material
			
			# Position and scale line to connect entities
			var direction = connected_entity.position - entity.position
			var distance = direction.length()
			line.scale.y = distance
			
			# Orient the line
			if direction.length() > 0.1:
				line.look_at(connected_entity.position, Vector3.UP)
				line.rotation.x = PI/2  # Adjust for cylinder orientation
			
			# Position at midpoint
			line.position = direction * 0.5
			
			connector.add_child(line)


func create_attack_effect(attacker_pos: Vector3, target_pos: Vector3):
	var effect = CPUParticles3D.new()
	var midpoint = (attacker_pos + target_pos) / 2
	effect.position = midpoint
	
	effect.amount = 20
	effect.lifetime = 0.5
	effect.one_shot = true
	effect.explosiveness = 0.8
	effect.direction = (target_pos - attacker_pos).normalized()
	effect.spread = 45.0
	effect.initial_velocity_min = 2.0
	effect.initial_velocity_max = 5.0
	effect.color = Color(1.0, 0.2, 0.2)
	
	effect.emitting = true
	add_child(effect)
	
	# Auto-remove after effect finishes
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.autostart = true
	effect.add_child(timer)
	timer.timeout.connect(func(): effect.queue_free())


func warn_connected_networkers(networker: SimulationEntity, predator: SimulationEntity):
	# Send warning to connected networkers
	for connected_id in networker.relationships.keys():
		if networker.relationships[connected_id] == "connected" and connected_id < entities.size():
			var connected_entity = entities[connected_id]
			
			if connected_entity.type == "networker":
				# Mark predator as a threat
				connected_entity.relationships[predator.id] = "threat"
				
				# Flee from the predator
				connected_entity.target = connected_entity.position + (connected_entity.position - predator.position).normalized() * 5.0
				
				# Create warning effect
				create_warning_effect(connected_entity.position)


func create_warning_effect(position: Vector3):
	var warning = CPUParticles3D.new()
	warning.position = position
	
	warning.amount = 15
	warning.lifetime = 0.7
	warning.one_shot = true
	warning.explosiveness = 0.8
	warning.direction = Vector3(0, 1, 0)
	warning.spread = 90.0
	warning.initial_velocity_min = 1.0
	warning.initial_velocity_max = 2.0
	warning.color = Color(1.0, 0.8, 0.2)
	
	warning.emitting = true
	add_child(warning)
	
	# Auto-remove after effect finishes
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.autostart = true
	warning.add_child(timer)
	timer.timeout.connect(func(): warning.queue_free())

func complete_construction(entity: SimulationEntity):
	# This function is called when a builder entity completes a construction project
	
	if not entity.attributes.has("construction_type"):
		return
	
	var construction_type = entity.attributes["construction_type"]
	var construction_position = entity.position + Vector3(0, 0.5, 0)  # Slightly above the builder
	
	# Create the completed structure
	var structure = Node3D.new()
	structure.name = "Structure_" + construction_type + "_" + str(rng.randi() % 1000)
	
	var mesh_instance = MeshInstance3D.new()
	var mesh
	var material = StandardMaterial3D.new()
	
	# Configure based on construction type
	match construction_type:
		"shelter":
			mesh = BoxMesh.new()
			mesh.size = Vector3(1.5, 1.0, 1.5)
			material.albedo_color = Color(0.8, 0.7, 0.2)
			construction_position.y += 0.5  # Adjust for box height
			
		"tower":
			mesh = CylinderMesh.new()
			mesh.top_radius = 0.3
			mesh.bottom_radius = 0.5
			mesh.height = 2.5
			material.albedo_color = Color(0.7, 0.7, 0.2)
			construction_position.y += 1.25  # Adjust for tower height
			
		"bridge":
			mesh = BoxMesh.new()
			mesh.size = Vector3(0.7, 0.2, 2.5)
			material.albedo_color = Color(0.6, 0.5, 0.2)
			construction_position.y += 0.8  # Position above ground
			
		"sculpture":
			mesh = PrismMesh.new()
			mesh.size = Vector3(1.0, 1.5, 1.0)
			material.albedo_color = Color(0.9, 0.8, 0.3)
			construction_position.y += 0.75  # Adjust for sculpture height
	
	# Apply common material properties
	material.roughness = 0.7
	material.metallic = 0.3
	
	# Add a subtle glow based on builder's creativity
	var creativity = entity.attributes["creativity"]
	if creativity > 0.8:
		material.emission_enabled = true
		material.emission = material.albedo_color * 0.5
		material.emission_energy_multiplier = 0.5
	
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	
	structure.position = construction_position
	structure.add_child(mesh_instance)
	
	# Add collision shape
	var collision_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	var shape
	
	match construction_type:
		"shelter":
			shape = BoxShape3D.new()
			shape.size = Vector3(1.5, 1.0, 1.5)
		"tower":
			shape = CylinderShape3D.new()
			shape.radius = 0.5
			shape.height = 2.5
		"bridge":
			shape = BoxShape3D.new()
			shape.size = Vector3(0.7, 0.2, 2.5)
		"sculpture":
			shape = BoxShape3D.new()
			shape.size = Vector3(1.0, 1.5, 1.0)
	
	collision_shape.shape = shape
	collision_body.add_child(collision_shape)
	structure.add_child(collision_body)
	
	# Make structure slightly interactive
	var interaction_area = Area3D.new()
	var interaction_shape = CollisionShape3D.new()
	var interaction_sphere = SphereShape3D.new()
	interaction_sphere.radius = 1.5
	interaction_shape.shape = interaction_sphere
	interaction_area.add_child(interaction_shape)
	structure.add_child(interaction_area)
	
	# Connect interaction signals
	interaction_area.input_event.connect(_on_structure_input_event.bind(structure))
	
	# Add to scene
	add_child(structure)
	
	# Add to environment objects list
	environment_nodes.append(structure)
	
	# Create completion effect
	var particles = CPUParticles3D.new()
	particles.position = construction_position
	particles.amount = 30
	particles.lifetime = 2.0
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 180.0
	particles.initial_velocity_min = 1.0
	particles.initial_velocity_max = 3.0
	particles.color = material.albedo_color
	particles.emitting = true
	add_child(particles)
	
	# Auto-remove particles after effect finishes
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.autostart = true
	particles.add_child(timer)
	timer.timeout.connect(func(): particles.queue_free())
	
	# Give builder a reward
	entity.energy = min(100.0, entity.energy + 30.0)
	
	# Increase builder's skills
	entity.attributes["construction_speed"] = min(1.5, entity.attributes["construction_speed"] + 0.05)
	entity.attributes["precision"] = min(1.5, entity.attributes["precision"] + 0.05)
	
	# Clear construction state
	entity.attributes.erase("construction_state")
	entity.attributes.erase("construction_progress")
	entity.attributes.erase("construction_type")
	
	# Record the event
	event_history.append({
		"time": simulation_time,
		"type": "construction_completed",
		"entity_id": entity.id,
		"structure_type": construction_type,
		"position": construction_position
	})


func _on_structure_input_event(camera, event, position, normal, shape_idx, structure):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Create interaction effect on structure
			var particles = CPUParticles3D.new()
			particles.position = structure.position
			particles.amount = 15
			particles.lifetime = 1.0
			particles.one_shot = true
			particles.explosiveness = 0.8
			particles.direction = Vector3(0, 1, 0)
			particles.spread = 90.0
			particles.initial_velocity_min = 1.0
			particles.initial_velocity_max = 2.0
			particles.color = Color(1.0, 0.9, 0.3)
			
			particles.emitting = true
			add_child(particles)
			
			# Auto-remove after effect finishes
			var timer = Timer.new()
			timer.wait_time = 1.5
			timer.one_shot = true
			timer.autostart = true
			particles.add_child(timer)
			timer.timeout.connect(func(): particles.queue_free())
			
			# Attract nearby builders to this location
			for entity in get_entities_in_radius(structure.position, 10.0):
				if entity.type == "builder":
					entity.target = structure.position
					entity.energy = min(100.0, entity.energy + 10.0) 
					
func start_construction(entity: SimulationEntity):
	entity.attributes["construction_state"] = "building"
	entity.attributes["construction_progress"] = 0.0
	entity.attributes["construction_type"] = ["shelter", "tower", "bridge", "sculpture"][rng.randi() % 4]
	entity.set_state("building")
	
	# Create construction visualization
	update_construction_visualizer(entity)


func update_construction_visualizer(entity: SimulationEntity):
	if not entity.node:
		return
	
	var constructor = entity.node.get_node_or_null("Construction")
	if not constructor:
		return
	
	# Clear existing visualization
	for child in constructor.get_children():
		child.queue_free()
	
	var progress = entity.attributes["creativity"] 
	var construction

func evolve_simulation(delta: float):
	# Apply evolutionary changes based on elapsed time and entity states
	if evolution_speed <= 0.0:
		return
		
	var evolution_chance = delta * evolution_speed * 0.01
	
	for entity in entities:
		# Chance for entity to evolve
		if rng.randf() < evolution_chance:
			evolve_entity(entity)
		
		# Age the entity
		entity.age += delta
		
		# Check if entity should expire based on age and lifespan
		if entity.age > entity.lifespan:
			entity.energy = max(0.0, entity.energy - delta * 5.0)
			entity.set_state("dying")
		
		# Remove entities with no energy
		if entity.energy <= 0:
			entity.set_state("dead")
			mark_entity_for_removal(entity)
					
func create_trail_effect(color: Color) -> Node3D:
	var trail = Node3D.new()
	trail.name = "Trail"
	
	# Create a CPUParticles3D system
	var particles = CPUParticles3D.new()
	particles.name = "Particles"
	particles.amount = 20
	particles.lifetime = 1.0
	particles.local_coords = false
	particles.emitting = true
	particles.mesh = SphereMesh.new()
	particles.mesh.radius = 0.05
	particles.mesh.height = 0.1
	particles.direction = Vector3(0, -1, 0)
	particles.spread = 10.0
	particles.gravity = Vector3(0, -0.5, 0)
	particles.color = color
	particles.position = Vector3(0, 0, 0)
	
	trail.add_child(particles)
	return trail

func create_connection_visualizer() -> Node3D:
	var connector = Node3D.new()
	connector.name = "Connections"
	return connector

func create_construction_visualizer() -> Node3D:
	var constructor = Node3D.new()
	constructor.name = "Construction"
	return constructor

func add_to_spatial_partition(entity: SimulationEntity):
	var cell_x = int(entity.position.x / grid_cell_size)
	var cell_y = int(entity.position.y / grid_cell_size)
	var cell_z = int(entity.position.z / grid_cell_size)
	var cell_key = Vector3i(cell_x, cell_y, cell_z)
	
	if not partitioning_grid.has(cell_key):
		partitioning_grid[cell_key] = []
	
	partitioning_grid[cell_key].append(entity.id)



func update_spatial_partition(entity: SimulationEntity, old_position: Vector3):
	var old_cell_x = int(old_position.x / grid_cell_size)
	var old_cell_y = int(old_position.y / grid_cell_size)
	var old_cell_z = int(old_position.z / grid_cell_size)
	var old_cell_key = Vector3i(old_cell_x, old_cell_y, old_cell_z)
	
	var new_cell_x = int(entity.position.x / grid_cell_size)
	var new_cell_y = int(entity.position.y / grid_cell_size)
	var new_cell_z = int(entity.position.z / grid_cell_size)
	var new_cell_key = Vector3i(new_cell_x, new_cell_y, new_cell_z)
	
	if old_cell_key == new_cell_key:
		return
	
	# Remove from old cell
	if partitioning_grid.has(old_cell_key):
		partitioning_grid[old_cell_key].erase(entity.id)
	
	# Add to new cell
	if not partitioning_grid.has(new_cell_key):
		partitioning_grid[new_cell_key] = []
	
	partitioning_grid[new_cell_key].append(entity.id)

func setup_vr_integration():
	# Find existing XR Origin in the scene if available
	xr_origin = get_node_or_null("../XROrigin3D")
	
	if xr_origin:
		# Get references to VR components
		xr_camera = xr_origin.get_node_or_null("XRCamera3D")
		left_controller = xr_origin.get_node_or_null("LeftController")
		right_controller = xr_origin.get_node_or_null("RightController")
		
		# Connect controller signals
		if right_controller:
			var trigger = right_controller.get_node_or_null("TriggerAction")
			if trigger:
				trigger.button_pressed.connect(_on_vr_trigger_pressed)
				trigger.button_released.connect(_on_vr_trigger_released)
	else:
		# Create fallback camera for non-VR testing
		var camera = Camera3D.new()
		camera.name = "FallbackCamera"
		camera.position = Vector3(0, 5, 10)
		camera.rotation_degrees = Vector3(-20, 0, 0)
		add_child(camera)

func process_vr_interactions():
	if not xr_origin:
		return
		
	# Check for entity hovering with right controller
	if right_controller:
		var controller_pos = right_controller.global_position
		var controller_forward = -right_controller.global_transform.basis.z.normalized()
		
		var ray_length = interaction_distance
		var closest_entity = null
		var closest_distance = ray_length
		
		# Cast ray to find closest entity
		var entities_in_range = get_entities_in_radius(controller_pos, ray_length)
		for entity in entities_in_range:
			var to_entity = entity.position - controller_pos
			var distance = to_entity.length()
			var dot_product = to_entity.normalized().dot(controller_forward)
			
			# Check if entity is in front of controller and closer than current closest
			if dot_product > 0.7 and distance < closest_distance:
				closest_entity = entity
				closest_distance = distance
		
		# Highlight the closest entity
		if highlighted_entity != closest_entity:
			if highlighted_entity and highlighted_entity.node:
				unhighlight_entity(highlighted_entity)
			
			highlighted_entity = closest_entity
			
			if highlighted_entity and highlighted_entity.node:
				highlight_entity(highlighted_entity)

func highlight_entity(entity: SimulationEntity):
	if entity.node:
		var mesh_instance = entity.node.get_child(0)
		if mesh_instance is MeshInstance3D:
			var original_material = mesh_instance.material_override
			var highlight_material = original_material.duplicate()
			highlight_material.emission_enabled = true
			highlight_material.emission_energy_multiplier = 2.0
			highlight_material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
			
			# Store original material for later unhighlighting
			entity.node.set_meta("original_material", original_material)
			mesh_instance.material_override = highlight_material

func unhighlight_entity(entity: SimulationEntity):
	if entity.node:
		var mesh_instance = entity.node.get_child(0)
		if mesh_instance is MeshInstance3D and entity.node.has_meta("original_material"):
			var original_material = entity.node.get_meta("original_material")
			mesh_instance.material_override = original_material

func _on_vr_trigger_pressed():
	# Interact with highlighted entity
	if highlighted_entity:
		# Boost entity energy
		highlighted_entity.energy = min(100.0, highlighted_entity.energy + 20.0)
		
		# Apply type-specific boost
		match highlighted_entity.type:
			"wanderer":
				highlighted_entity.attributes["curiosity"] = min(1.5, highlighted_entity.attributes["curiosity"] * 1.2)
			"grower":
				highlighted_entity.attributes["growth_rate"] = min(1.5, highlighted_entity.attributes["growth_rate"] * 1.2)
			"networker":
				highlighted_entity.attributes["signal_strength"] = min(2.0, highlighted_entity.attributes["signal_strength"] * 1.2)
			"predator":
				highlighted_entity.attributes["hunting_efficiency"] = min(1.5, highlighted_entity.attributes["hunting_efficiency"] * 1.2)
			"builder":
				highlighted_entity.attributes["creativity"] = min(1.5, highlighted_entity.attributes["creativity"] * 1.2)
		
		# Visual effect for interaction
		create_interaction_effect(highlighted_entity.position)

func _on_vr_trigger_released():
	# Additional functionality can be added here
	pass

func _on_entity_body_entered(body, entity: SimulationEntity):
	# Handle collision with environment
	if body is StaticBody3D:
		# Bounce off
		entity.velocity = entity.velocity.bounce(Vector3.UP) * 0.5

func _on_entity_body_exited(body, entity: SimulationEntity):
	# Additional functionality can be added here
	pass

func _on_entity_input_event(camera, event, position, normal, shape_idx, entity: SimulationEntity):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Handle mouse interaction (for desktop testing)
			highlighted_entity = entity
			_on_vr_trigger_pressed()

func create_interaction_effect(position: Vector3):
	var effect = CPUParticles3D.new()
	effect.position = position
	effect.amount = 30
	effect.lifetime = 0.8
	effect.explosiveness = 0.8
	effect.local_coords = false
	effect.mesh = SphereMesh.new()
	effect.mesh.radius = 0.05
	effect.mesh.height = 0.1
	effect.direction = Vector3(0, 1, 0)
	effect.spread = 90.0
	effect.initial_velocity_min = 2.0
	effect.initial_velocity_max = 5.0
	effect.color = Color(1.0, 1.0, 0.5)
	effect.emitting = true
	effect.one_shot = true
	
	add_child(effect)
	
	# Auto-remove after effect finishes
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.autostart = true
	effect.add_child(timer)
	timer.timeout.connect(func(): effect.queue_free())

func setup_recorder_camera():
	# Add a camera to record the simulation
	recorder_camera = Camera3D.new()
	recorder_camera.name = "RecorderCamera"
	recorder_camera.position = Vector3(0, 10, 0)
	recorder_camera.rotation_degrees = Vector3(-90, 0, 0)  # Look down
	recorder_camera.far = 100.0
	
	add_child(recorder_camera)

func initialize_behavior_networks():
	# Initialize networks that define relationships between entities
	behavior_networks = {
		"predator_prey": {"predators": [], "prey": []},
		"networkers": [],
		"builders": []
	}

func create_environment_influences():
	# Set up environmental factors that influence entity behavior
	var world_environment = get_node_or_null("../WorldEnvironment")
	if not world_environment:
		world_environment = WorldEnvironment.new()
		world_environment.name = "SimulationWorldEnvironment"
		
		var environment = Environment.new()
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = Color(0.05, 0.05, 0.1)
		environment.fog_enabled = true
		#environment.fog_color = Color(0.1, 0.1, 0.2)
		environment.fog_depth_begin = 10.0
		environment.fog_depth_end = 30.0
		
		# Add ambient light
		environment.ambient_light_color = Color(0.2, 0.2, 0.3)
		environment.ambient_light_energy = 0.5
		
		world_environment.environment = environment
		get_parent().add_child(world_environment)

func update_entities(delta):
	for entity in entities:
		var old_position = entity.position
		
		# Apply entity type-specific update behavior
		match entity.type:
			"wanderer":
				update_wanderer(entity, delta)
			"grower":
				update_grower(entity, delta)
			"networker":
				update_networker(entity, delta)
			"predator":
				update_predator(entity, delta)
			"builder":
				update_builder(entity, delta)
			_:
				# Default update
				entity.update(delta, self)
		
		# Common updates for all entities
		
		# Apply constraints
		constrain_to_environment(entity)
		
		# Update energy
		entity.energy -= delta * (1.0 + entity.velocity.length() * 0.5)
		
		# Update spatial partitioning
		if use_spatial_partitioning:
			update_spatial_partition(entity, old_position)

func constrain_to_environment(entity: SimulationEntity):
	# Constrain to environment boundaries with bounce
	var half_width = environment_size.x / 2
	var half_depth = environment_size.z / 2
	var half_height = environment_size.y / 2
	var bounce_factor = 0.5
	
	if entity.position.x < -half_width:
		entity.position.x = -half_width
		entity.velocity.x = abs(entity.velocity.x) * bounce_factor
	elif entity.position.x > half_width:
		entity.position.x = half_width
		entity.velocity.x = -abs(entity.velocity.x) * bounce_factor
	
	if entity.position.z < -half_depth:
		entity.position.z = -half_depth
		entity.velocity.z = abs(entity.velocity.z) * bounce_factor
	elif entity.position.z > half_depth:
		entity.position.z = half_depth
		entity.velocity.z = -abs(entity.velocity.z) * bounce_factor
	
	if entity.position.y < 0.5:
		entity.position.y = 0.5
		entity.velocity.y = abs(entity.velocity.y) * bounce_factor
	elif entity.position.y > half_height:
		entity.position.y = half_height
		entity.velocity.y = -abs(entity.velocity.y) * bounce_factor

func get_entities_in_radius(position: Vector3, radius: float) -> Array:
	var result = []
	
	if use_spatial_partitioning:
		# Get the cells in the vicinity
		var cell_radius = int(radius / grid_cell_size) + 1
		var center_cell_x = int(position.x / grid_cell_size)
		var center_cell_y = int(position.y / grid_cell_size)
		var center_cell_z = int(position.z / grid_cell_size)
		
		for x in range(center_cell_x - cell_radius, center_cell_x + cell_radius + 1):
			for y in range(center_cell_y - cell_radius, center_cell_y + cell_radius + 1):
				for z in range(center_cell_z - cell_radius, center_cell_z + cell_radius + 1):
					var cell_key = Vector3i(x, y, z)
					if partitioning_grid.has(cell_key):
						for entity_id in partitioning_grid[cell_key]:
							if entity_id < entities.size():
								var entity = entities[entity_id]
								var distance = position.distance_to(entity.position)
								if distance <= radius:
									result.append(entity)
	else:
		# Brute force approach
		for entity in entities:
			var distance = position.distance_to(entity.position)
			if distance <= radius:
				result.append(entity)
	
	return result

func find_nearest_resource(position: Vector3):
	var nearest_resource = null
	var nearest_distance = INF
	
	for resource in resource_points:
		var distance = position.distance_to(resource.position)
		if distance < nearest_distance and resource.energy > 10.0:
			nearest_distance = distance
			nearest_resource = resource
	
	return nearest_resource

func find_nearest_entity_of_type(position: Vector3, type: String, exclude_id: int = -1):
	var nearest_entity = null
	var nearest_distance = INF
	
	for entity in entities:
		if entity.type == type and entity.id != exclude_id:
			var distance = position.distance_to(entity.position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_entity = entity
	
	return nearest_entity

func find_interest_target(entity: SimulationEntity):
	# Look for resources first
	var nearest_resource = find_nearest_resource(entity.position)
	if nearest_resource and nearest_resource.position.distance_to(entity.position) < entity.attributes["perception_radius"]:
		return nearest_resource.position
	
	# Look for interesting entities
	var interest_types = []
	match entity.type:
		"wanderer":
			interest_types = ["networker", "builder"]
		"networker":
			interest_types = ["networker", "grower"]
		"grower":
			interest_types = ["grower", "resource"]
		"predator":
			interest_types = ["wanderer", "grower", "networker"]
		"builder":
			interest_types = ["wanderer", "resource"]
	
	for type in interest_types:
		if type == "resource":
			continue  # Already checked above
			
		var interesting_entity = find_nearest_entity_of_type(entity.position, type, entity.id)
		if interesting_entity and interesting_entity.position.distance_to(entity.position) < entity.attributes["perception_radius"]:
			return interesting_entity.position
	
	return null

func mark_entity_for_removal(entity: SimulationEntity):
	if not entities_to_remove.has(entity):
		entities_to_remove.append(entity)

func process_entity_removal():
	if entities_to_remove.size() > 0:
		for entity in entities_to_remove:
			# Remove from entities list
			entities.erase(entity)
			
			# Remove from spatial partitioning
			if use_spatial_partitioning:
				var cell_x = int(entity.position.x / grid_cell_size)
				var cell_y = int(entity.position.y / grid_cell_size)
				var cell_z = int(entity.position.z / grid_cell_size)
				var cell_key = Vector3i(cell_x, cell_y, cell_z)
				
				if partitioning_grid.has(cell_key):
					partitioning_grid[cell_key].erase(entity.id)
			
			# Remove visual node
			if entity.node:
				entity.node.queue_free()
			
			# Create death effect
			create_death_effect(entity.position, entity.type)
		
		entities_to_remove.clear()

func create_death_effect(position: Vector3, type: String):
	var particles = CPUParticles3D.new()
	particles.position = position
	particles.amount = 20
	particles.lifetime = 1.0
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.randomness = 0.5
	particles.local_coords = false
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 180.0
	particles.gravity = Vector3(0, -0.5, 0)
	particles.initial_velocity_min = 2.0
	particles.initial_velocity_max = 4.0
	
	# Set color based on entity type
	match type:
		"wanderer":
			particles.color = Color(0.3, 0.7, 0.9)
		"grower":
			particles.color = Color(0.2, 0.8, 0.4)
		"networker":
			particles.color = Color(0.8, 0.2, 0.8)
		"predator":
			particles.color = Color(0.9, 0.2, 0.2)
		"builder":
			particles.color = Color(0.9, 0.8, 0.2)
		_:
			particles.color = Color(0.7, 0.7, 0.7)
	
	particles.emitting = true
	add_child(particles)
	
	# Auto-remove after effect finishes
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.autostart = true
	particles.add_child(timer)
	timer.timeout.connect(func(): particles.queue_free())

func maintain_entity_population():
	# Keep entity population at healthy levels
	var current_count = entities.size()
	
	# Create new entities if population is too low
	if current_count < entity_count * 0.7:
		var entities_to_create = int(entity_count * 0.2)
		
		for i in range(entities_to_create):
			if entities.size() < max_entities:
				create_random_entity()

func generate_emergent_events(delta: float):
	# Chance for spontaneous events to occur
	if rng.randf() < delta * complexity_level * 0.1:
		var event_type = rng.randi() % 3
		
		match event_type:
			0:  # Entity mutation
				if entities.size() > 0:
					var random_entity = entities[rng.randi() % entities.size()]
					mutate_entity(random_entity)
			
			1:  # Resource emergence
				create_emergent_resource()
			
			2:  # Environmental shift
				create_environmental_shift()

func mutate_entity(entity: SimulationEntity):
	# Apply significant mutations to an entity
	var mutation_strength = 0.5 + rng.randf() * 0.5
	
	match entity.type:
		"wanderer":
			entity.attributes["max_speed"] *= 1.0 + (mutation_strength * 0.5)
			entity.attributes["curiosity"] *= 1.0 + mutation_strength
			entity.energy = 100.0
		"grower":
			entity.attributes["growth_rate"] *= 1.0 + mutation_strength
			entity.attributes["max_size"] *= 1.0 + (mutation_strength * 0.3)
			entity.energy = 100.0
		"networker":
			entity.attributes["connection_range"] *= 1.0 + mutation_strength
			entity.attributes["signal_strength"] *= 1.0 + mutation_strength
			entity.energy = 100.0
		"predator":
			entity.attributes["attack_strength"] *= 1.0 + mutation_strength
			entity.attributes["hunting_efficiency"] *= 1.0 + (mutation_strength * 0.5)
			entity.energy = 100.0
		"builder":
			entity.attributes["construction_speed"] *= 1.0 + mutation_strength
			entity.attributes["creativity"] *= 1.0 + mutation_strength
			entity.energy = 100.0
	
	# Visual feedback
	#if entity.node:
		#var material = entity.node.get_child(0).material_override
		#material.emission_energy_multiplier = 2.0
		
		#var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		#tween.tween_property(material, "emission_energy_multiplier", 0.5, 2.0)
	
	# Record the event
	event_history.append({
		"time": simulation_time,
		"type": "mutation",
		"entity_id": entity.id,
		"entity_type": entity.type,
		"strength": mutation_strength
	})

func create_emergent_resource():
	# Create a new resource at a random location
	var resource_container = get_node_or_null("ResourcePoints")
	if not resource_container:
		return
	
	var resource = MeshInstance3D.new()
	resource.name = "Resource_Emergent"
	
	var resource_mesh = SphereMesh.new()
	resource_mesh.radius = 0.4
	resource_mesh.height = 0.8
	
	var resource_material = StandardMaterial3D.new()
	resource_material.albedo_color = Color(0.1, 0.9, 0.6)
	resource_material.emission_enabled = true
	resource_material.emission = Color(0.1, 0.8, 0.5)
	resource_material.emission_energy_multiplier = 1.2
	
	resource.mesh = resource_mesh
	resource.material_override = resource_material
	
	var x = rng.randf_range(-environment_size.x/2 + 1, environment_size.x/2 - 1)
	var z = rng.randf_range(-environment_size.z/2 + 1, environment_size.z/2 - 1)
	var y = 0.4  # Just above ground level
	resource.position = Vector3(x, y, z)
	
	resource_container.add_child(resource)
	resource_points.append({
		"node": resource,
		"position": resource.position,
		"energy": 150.0,  # More energy than standard resources
		"type": "emergent",
		"last_used": 0.0
	})
	
	# Create emergence effect
	var particles = CPUParticles3D.new()
	particles.position = resource.position
	particles.amount = 30
	particles.lifetime = 2.0
	particles.one_shot = true
	particles.explosiveness = 0.5
	particles.local_coords = false
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 180.0
	particles.gravity = Vector3(0, -0.2, 0)
	particles.initial_velocity_min = 1.0
	particles.initial_velocity_max = 3.0
	particles.color = Color(0.1, 0.9, 0.6)
	
	particles.emitting = true
	add_child(particles)
	
	# Auto-remove after effect finishes
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.autostart = true
	particles.add_child(timer)
	timer.timeout.connect(func(): particles.queue_free())

func create_environmental_shift():
	# Change the environment in some significant way
	var shift_type = rng.randi() % 3
	
	match shift_type:
		0:  # Gravity shift
			var gravity_direction = Vector3(
				rng.randf_range(-0.3, 0.3),
				rng.randf_range(-1.0, -0.5),
				rng.randf_range(-0.3, 0.3)
			).normalized() * 9.8
			
			PhysicsServer3D.area_set_param(get_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY_VECTOR, gravity_direction)
			
			# Reset after a while
			var timer = Timer.new()
			timer.wait_time = 10.0
			timer.one_shot = true
			timer.autostart = true
			add_child(timer)
			timer.timeout.connect(func(): PhysicsServer3D.area_set_param(get_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY_VECTOR, Vector3(0, -1, 0)))
		
		1:  # Light shift
			var world_env = get_node_or_null("../WorldEnvironment")
			if world_env and world_env.environment:
				var env = world_env.environment
				var original_color = env.ambient_light_color
				var shift_color = Color(
					rng.randf_range(0.1, 0.5),
					rng.randf_range(0.1, 0.5),
					rng.randf_range(0.1, 0.5)
				)
				
				env.ambient_light_color = shift_color
				
				# Reset after a while
				var timer = Timer.new()
				timer.wait_time = 8.0
				timer.one_shot = true
				timer.autostart = true
				add_child(timer)
				timer.timeout.connect(func(): env.ambient_light_color = original_color)
		
		2:  # Terrain shift
			# Make a portion of the terrain uneven
			var x = rng.randf_range(-environment_size.x/2 + 5, environment_size.x/2 - 5)
			var z = rng.randf_range(-environment_size.z/2 + 5, environment_size.z/2 - 5)
			var shift_position = Vector3(x, 0, z)
			var shift_radius = rng.randf_range(3.0, 6.0)
			
			create_terrain_shift(shift_position, shift_radius)

func create_terrain_shift(position: Vector3, radius: float):
	var terrain_shift = Node3D.new()
	terrain_shift.name = "TerrainShift"
	
	var mesh_instance = MeshInstance3D.new()
	var noise_mesh = PlaneMesh.new()
	noise_mesh.size = Vector2(radius * 2, radius * 2)
	noise_mesh.subdivide_width = 20
	noise_mesh.subdivide_depth = 20
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.3, 0.3)
	
	mesh_instance.mesh = noise_mesh
	mesh_instance.material_override = material
	
	# Deform the mesh with noise
	var surface_tool = SurfaceTool.new()
	surface_tool.create_from(noise_mesh, 0)
	var array_mesh = surface_tool.commit()
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(array_mesh, 0)
	
	for i in range(mdt.get_vertex_count()):
		var vertex = mdt.get_vertex(i)
		var distance_from_center = Vector2(vertex.x, vertex.z).length()
		var falloff = 1.0 - min(1.0, distance_from_center / radius)
		
		if falloff > 0:
			var noise_value = rng.randf_range(-0.5, 0.5) * falloff
			vertex.y += noise_value
			mdt.set_vertex(i, vertex)
	
	# Recreate the mesh
	array_mesh = ArrayMesh.new()
	mdt.commit_to_surface(array_mesh)
	mesh_instance.mesh = array_mesh
	
	terrain_shift.position = position
	terrain_shift.add_child(mesh_instance)
	
	# Add collision
	var collision_shape = CollisionShape3D.new()
	var shape = HeightMapShape3D.new()
	# Note: HeightMapShape3D requires additional setup which is omitted here for brevity
	
	add_child(terrain_shift)
	
	# Remove after a while
	var timer = Timer.new()
	timer.wait_time = 15.0
	timer.one_shot = true
	timer.autostart = true
	terrain_shift.add_child(timer)
	timer.timeout.connect(func(): terrain_shift.queue_free())

func update_debug_visualization():
	# Visualize spatial partitioning grid
	if use_spatial_partitioning:
		var debug_lines = get_node_or_null("DebugLines")
		if not debug_lines:
			debug_lines = Node3D.new()
			debug_lines.name = "DebugLines"
			add_child(debug_lines)
		
		# Clear previous debug visualization
		for child in debug_lines.get_children():
			child.queue_free()
		
		# Draw grid cells that contain entities
		for cell_key in partitioning_grid.keys():
			if partitioning_grid[cell_key].size() > 0:
				var cell_pos = Vector3(
					cell_key.x * grid_cell_size,
					cell_key.y * grid_cell_size,
					cell_key.z * grid_cell_size
				)
				
				var box = MeshInstance3D.new()
				var box_mesh = BoxMesh.new()
				box_mesh.size = Vector3.ONE * grid_cell_size
				
				var material = StandardMaterial3D.new()
				material.albedo_color = Color(0.5, 0.5, 1.0, 0.2)
				material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				
				box.mesh = box_mesh
				box.material_override = material
				box.position = cell_pos
				
				debug_lines.add_child(box)
