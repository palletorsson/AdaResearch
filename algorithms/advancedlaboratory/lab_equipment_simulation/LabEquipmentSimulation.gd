extends Node3D
class_name LabEquipmentSimulation

var time: float = 0.0
var particle_speed: float = 2.0
var equipment_active: bool = true

func _ready():
	# Initialize the lab equipment simulation
	print("Lab Equipment Simulation initialized")
	setup_equipment_animation()

func _process(delta):
	time += delta
	
	if equipment_active:
		animate_equipment(delta)
		animate_particles(delta)

func setup_equipment_animation():
	# Set initial states for equipment
	var microscope = get_node_safe("Equipment/Microscope")
	var bunsen_burner = get_node_safe("Equipment/BunsenBurner")
	
	# Add some initial rotation to microscope
	if microscope and microscope is Node3D:
		microscope.rotation.y = randf() * PI * 2

func animate_equipment(delta):
	# Animate microscope lens rotation
	var microscope = get_node_safe("Equipment/Microscope")
	if microscope and microscope is Node3D:
		microscope.rotation.y += delta * 0.5
	
	# Animate bunsen burner flame with proper type checking
	var flame = get_node_safe("Equipment/BunsenBurner/Flame")
	if flame and flame is Node3D:
		# Ensure the node has scale property (all Node3D derived classes should)
		if "scale" in flame:
			flame.scale.y = 1.0 + sin(time * 3.0) * 0.2
		if "rotation" in flame:
			flame.rotation.z += delta * 2.0

func animate_particles(delta):
	# Animate floating particles with proper type checking
	var particles_container = get_node_safe("Particles/FloatingParticles")
	if not particles_container:
		return
		
	for i in range(particles_container.get_child_count()):
		var particle = particles_container.get_child(i)
		if particle and particle is Node3D:
			# Create floating motion
			particle.position.y += sin(time * particle_speed + i) * delta * 0.5
			particle.position.x += cos(time * particle_speed * 0.7 + i) * delta * 0.3
			particle.position.z += sin(time * particle_speed * 0.5 + i) * delta * 0.4
			
			# Keep particles within bounds
			particle.position.x = clamp(particle.position.x, -8, 8)
			particle.position.y = clamp(particle.position.y, 1, 7)
			particle.position.z = clamp(particle.position.z, -8, 8)
			
			# Add rotation
			particle.rotation += Vector3(delta, delta * 0.7, delta * 0.5)

func get_node_safe(path: String) -> Node:
	"""Safely get a node with error checking"""
	var node = get_node_or_null(path)
	if not node:
		print("Warning: Node not found at path: ", path)
		return null
	return node

func toggle_equipment():
	equipment_active = !equipment_active
	print("Equipment active: ", equipment_active)

func reset_simulation():
	time = 0.0
	# Reset particle positions with proper error checking
	var particles_container = get_node_safe("Particles/FloatingParticles")
	if not particles_container:
		return
		
	for i in range(particles_container.get_child_count()):
		var particle = particles_container.get_child(i)
		if particle and particle is Node3D:
			particle.position = Vector3(
				randf_range(-3, 3),
				randf_range(3, 5),
				randf_range(-3, 3)
			)

# Additional utility functions for debugging
func print_scene_structure():
	"""Debug function to print the scene tree structure"""
	print("=== Lab Equipment Scene Structure ===")
	_print_node_recursive(self, 0)

func _print_node_recursive(node: Node, depth: int):
	"""Recursively print node structure"""
	var indent = ""
	for i in range(depth):
		indent += "  "
	
	var type_info = node.get_class()
	print(indent + "- " + node.name + " (" + type_info + ")")
	
	for child in node.get_children():
		_print_node_recursive(child, depth + 1)

func validate_scene_setup() -> bool:
	"""Validate that all required nodes exist with correct types"""
	var required_paths = [
		"Equipment/Microscope",
		"Equipment/BunsenBurner",
		"Equipment/BunsenBurner/Flame",
		"Particles/FloatingParticles"
	]
	
	var all_valid = true
	for path in required_paths:
		var node = get_node_or_null(path)
		if not node:
			print("ERROR: Missing required node: ", path)
			all_valid = false
		elif not node is Node3D:
			print("ERROR: Node is not Node3D type: ", path, " (", node.get_class(), ")")
			all_valid = false
		else:
			print("OK: Found ", path, " (", node.get_class(), ")")
	
	return all_valid
