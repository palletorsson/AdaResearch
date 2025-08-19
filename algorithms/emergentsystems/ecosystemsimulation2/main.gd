# ecosystem_controller.gd
extends Node3D

func _ready():
	# Initialize all systems
	var environment_node = EcosystemEnvironment.new()
	add_child(environment_node)
	
	var resource_system = ResourceSystem.new()
	add_child(resource_system)
	
	var relationship_network = RelationshipNetwork.new()
	add_child(relationship_network)
	
	var morphology_generator = MorphologyGenerator.new()
	add_child(morphology_generator)
	
	var boundary_system = BoundarySystem.new()
	add_child(boundary_system)
	
	var event_system = EventSystem.new()
	add_child(event_system)
	
	var visualization = Visualization.new()
	add_child(visualization)
	
	# Create a few test entities
	for i in range(10):
		var entity = Entity.new()
		entity.name = "Entity_" + str(i)
		
		# Create random traits
		var traits = QueerTraits.new()
		traits.randomize_traits()
		entity.traits = traits
		
		# Position randomly
		entity.position = Vector3(
			randf_range(-10, 10),
			randf_range(0, 5),
			randf_range(-10, 10)
		)
		
		add_child(entity)
		
		# Generate morphology for entity
		morphology_generator.generate_morphology(entity)
		
		# Add to visualization
		visualization.add_entity_visualization(entity)
	
	# Add a camera
	var camera = Camera3D.new()
	camera.name = "Camera"
	camera.position = Vector3(0, 10, 20)
	camera.look_at(Vector3.ZERO)
	add_child(camera)


func _process(delta):
	# Update all systems
	var current_day = 1  # Or whatever your current day value is

	for child in get_children():
		if child.has_method("update"):
		# Try most common signature first (2 parameters)
			if child is ResourceSystem or child is EcosystemEnvironment:
				# These need both delta and current_day
				child.update(delta, current_day)
			else:
				# Others might only need delta
				child.update(delta)
