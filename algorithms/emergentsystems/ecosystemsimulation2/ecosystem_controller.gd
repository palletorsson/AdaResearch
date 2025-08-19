# ecosystem_controller.gd
class_name EcosystemController
extends Node3D

signal day_changed(day_number)
signal entity_born(entity)
signal entity_transformed(entity, previous_form)
signal entity_expired(entity)
signal resource_depleted(resource_type, location)
signal boundary_challenged(boundary, challenger)

# Configuration parameters
@export_category("Ecosystem Parameters")
@export var initial_entity_count: int = 20
@export var environment_size: Vector3 = Vector3(50, 20, 50)
@export var enable_seasons: bool = true
@export var season_duration_days: int = 30
@export var day_duration_seconds: float = 10.0
@export var entropy_growth_rate: float = 0.05
@export var enable_visualization: bool = true

# Ecosystem components
var entities: Array[Entity] = []
var environment: EcosystemEnvironment
var resource_system: ResourceSystem
var relationship_network: RelationshipNetwork
var morphology_generator: MorphologyGenerator
var boundary_system: BoundarySystem
var event_system: EventSystem
var visualization: Visualization

# Simulation state
var current_day: int = 0
var current_season: int = 0
var current_entropy: float = 0.0
var paused: bool = false
var day_timer: float = 0.0

func _ready():
	# Initialize ecosystem components
	_initialize_components()
	
	# Create initial entities
	_spawn_initial_entities()
	
	# Connect signals
	_connect_signals()
	
	print("Queer Computational Ecosystem initialized with " + str(initial_entity_count) + " entities")

func _initialize_components():
	# Create environment
	environment = EcosystemEnvironment.new()  # Updated class name
	environment.name = "Environment"
	environment.size = environment_size
	add_child(environment)
	
	# Create resource system
	resource_system = ResourceSystem.new()
	resource_system.name = "ResourceSystem"
	add_child(resource_system)
	
	# Create relationship network
	relationship_network = RelationshipNetwork.new()
	relationship_network.name = "RelationshipNetwork"
	add_child(relationship_network)
	
	# Create morphology generator
	morphology_generator = MorphologyGenerator.new()
	morphology_generator.name = "MorphologyGenerator"
	morphology_generator.set_entropy(current_entropy)
	add_child(morphology_generator)
	
	# Create boundary system
	boundary_system = BoundarySystem.new()
	boundary_system.name = "BoundarySystem"
	add_child(boundary_system)
	
	# Create event system
	event_system = EventSystem.new()
	event_system.name = "EventSystem"
	add_child(event_system)
	
	# Create visualization
	if enable_visualization:
		visualization = Visualization.new()
		visualization.name = "Visualization"
		add_child(visualization)

func _spawn_initial_entities():
	for i in range(initial_entity_count):
		var position = Vector3(
			randf_range(-environment_size.x/2, environment_size.x/2),
			randf_range(0, environment_size.y/2),
			randf_range(-environment_size.z/2, environment_size.z/2)
		)
		
		# Create random initial traits
		var traits = QueerTraits.new()
		traits.randomize_traits()
		
		# Create entity
		var entity = Entity.new()
		entity.name = "Entity_" + str(i)
		entity.traits = traits
		entity.position = position
		
		# Generate morphology based on traits
		morphology_generator.generate_morphology(entity)
		
		# Register entity with systems
		relationship_network.register_entity(entity)
		if enable_visualization:
			visualization.add_entity_visualization(entity)
		
		# Add entity to scene
		environment.add_child(entity)
		entities.append(entity)
		
		# Emit signal
		emit_signal("entity_born", entity)

func _connect_signals():
	# Connect to entity signals
	for entity in entities:
		entity.connect("transformation_requested", _on_entity_transformation_requested)
		entity.connect("expired", _on_entity_expired)
		entity.connect("boundary_challenge_requested", _on_boundary_challenge_requested)
	
	# Connect to environment signals
	environment.connect("resource_spawned", _on_resource_spawned)
	
	# Connect to event system signals
	event_system.connect("event_triggered", _on_event_triggered)

func _process(delta):
	if paused:
		return
	
	# Update day/night cycle
	day_timer += delta
	if day_timer >= day_duration_seconds:
		day_timer = 0
		advance_day()
	
	# Update entities
	for entity in entities:
		entity.process_behavior(delta)
	
	# Update environment
	environment.update(delta, current_day)
	
	# Update resources
	resource_system.update(delta, current_day)
	
	# Update relationships
	relationship_network.update(delta)
	
	# Update entropy
	current_entropy += entropy_growth_rate * delta / day_duration_seconds
	morphology_generator.set_entropy(current_entropy)

func advance_day():
	current_day += 1
	emit_signal("day_changed", current_day)
	
	# Check for season change
	if enable_seasons and current_day % season_duration_days == 0:
		current_season = (current_season + 1) % 4
		_on_season_changed()
	
	# Trigger random events
	event_system.consider_random_event(current_day, entities, environment)
	
	# Allow entities to potentially reproduce or transform
	for entity in entities.duplicate():  # Duplicate to avoid modification during iteration
		entity.end_of_day_update(current_day)

func _on_entity_transformation_requested(entity):
	var previous_form = entity.get_current_form()
	
	# Calculate new form based on current traits and entropy
	var new_form = morphology_generator.generate_transformation(entity, current_entropy)
	entity.apply_transformation(new_form)
	
	emit_signal("entity_transformed", entity, previous_form)
	
	# Update visualization
	if enable_visualization:
		visualization.update_entity_visualization(entity)

func _on_entity_expired(entity):
	emit_signal("entity_expired", entity)
	
	# Remove from relationships
	relationship_network.unregister_entity(entity)
	
	# Remove from visualization
	if enable_visualization:
		visualization.remove_entity_visualization(entity)
	
	# Remove from entities list
	entities.erase(entity)
	
	# Release resources back to environment
	resource_system.recycle_entity_resources(entity.position, entity.traits.resource_value)
	
	# Actually remove the entity
	entity.queue_free()

func _on_boundary_challenge_requested(entity, boundary_type):
	var challenge_result = boundary_system.challenge_boundary(entity, boundary_type, current_entropy)
	emit_signal("boundary_challenged", boundary_type, entity)
	
	if challenge_result.success:
		# Update entity traits based on successful challenge
		entity.traits.evolve_after_challenge(boundary_type, challenge_result.impact)
		
		# Might trigger an event
		event_system.trigger_event("boundary_transcended", entity, boundary_type)

func _on_resource_spawned(resource):
	# Register new resource with the resource system
	resource_system.register_resource(resource)
	
	# Update visualization
	if enable_visualization:
		visualization.add_resource_visualization(resource)

func _on_event_triggered(event_type, affected_entities):
	print("Event triggered: " + event_type + " affecting " + str(affected_entities.size()) + " entities")
	
	# Different event types might cause different ecosystem responses
	match event_type:
		"celebration":
			# Celebrations boost connection strengths in the relationship network
			relationship_network.boost_connections(affected_entities, 0.2)
		"crisis":
			# Crises might cause rapid adaptations
			for entity in affected_entities:
				entity.traits.crisis_adaptation()
		"convergence":
			# Moments where entities gather and form stronger bonds
			for entity in affected_entities:
				relationship_network.create_random_connections(entity, 2)

func _on_season_changed():
	print("Season changed to: " + _get_season_name(current_season))
	
	# Different seasons affect resource availability
	resource_system.adjust_for_season(current_season)
	
	# Inform environment about season change
	environment.set_season(current_season)
	
	# Seasonal event
	event_system.trigger_event("season_change", entities, current_season)

func _get_season_name(season_index: int) -> String:
	match season_index:
		0: return "Spring"
		1: return "Summer"
		2: return "Autumn"
		3: return "Winter"
		_: return "Unknown"

# Public methods for interaction
func pause():
	paused = true

func resume():
	paused = false

func toggle_pause():
	paused = !paused
	return paused

func set_entropy(value: float):
	current_entropy = clamp(value, 0.0, 1.0)
	morphology_generator.set_entropy(current_entropy)

func add_new_entity(position: Vector3, traits: QueerTraits = null):
	# Create entity with provided or random traits
	var entity = Entity.new()
	entity.name = "Entity_" + str(entities.size())
	entity.position = position
	
	if traits == null:
		traits = QueerTraits.new()
		traits.randomize_traits()
	
	entity.traits = traits
	
	# Generate morphology based on traits
	morphology_generator.generate_morphology(entity)
	
	# Register entity with systems
	relationship_network.register_entity(entity)
	if enable_visualization:
		visualization.add_entity_visualization(entity)
	
	# Add entity to scene
	environment.add_child(entity)
	entities.append(entity)
	
	# Connect signals
	entity.connect("transformation_requested", _on_entity_transformation_requested)
	entity.connect("expired", _on_entity_expired)
	entity.connect("boundary_challenge_requested", _on_boundary_challenge_requested)
	
	# Emit signal
	emit_signal("entity_born", entity)
	
	return entity

func get_entity_count() -> int:
	return entities.size()

func get_current_entropy() -> float:
	return current_entropy
