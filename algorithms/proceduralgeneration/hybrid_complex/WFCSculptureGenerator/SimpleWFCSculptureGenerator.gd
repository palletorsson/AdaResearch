# Simple example showing how to use the WFC Sculpture Generator
# Attach this to a Node3D in your scene for a quick start

extends Node3D

func _ready():
	await create_example_sculptures()

func create_example_sculptures():
	# Create only the Hollow_Organic sculpture
	await create_sculpture_variant("Hollow_Organic", Vector3(0, 0, 0), 0.7, 0.8, 0.9)

func create_sculpture_variant(name: String, pos: Vector3, hollow: float, complexity: float, organic: float):
	# Create a new sculpture generator
	var sculpture = WFCSculptureGenerator.new()
	sculpture.name = name
	sculpture.position = pos
	
	# Configure parameters
	sculpture.sculpture_size = Vector3i(15, 18, 15)  # Smaller for quick generation
	sculpture.voxel_size = 0.4
	sculpture.hollow_intensity = hollow
	sculpture.surface_complexity = complexity
	sculpture.organic_flow = organic
	sculpture.sculpture_seed = hash(name)  # Unique seed based on name
	
	# Set sculpture type to ABSTRACT_ORGANIC for Hollow_Organic
	sculpture.sculpture_type = WFCSculptureGenerator.SculptureType.ABSTRACT_ORGANIC
	
	# Add to scene
	add_child(sculpture)
	
	# Generate the sculpture
	await sculpture.create_hollow_sculpture()
	
	print("Created sculpture: ", name)

# Call this function to regenerate the sculpture with new parameters
func regenerate_all():
	for child in get_children():
		if child is WFCSculptureGenerator:
			child.clear_generated_sculpture()
			await child.create_hollow_sculpture()
			print("Regenerated sculpture: ", child.name)

# Example of interactive parameter modification
func _input(event):
	if event.is_action_pressed("ui_accept"):  # Space key
		print("Regenerating all sculptures...")
		await regenerate_all()
	
	if event.is_action_pressed("ui_select"):  # Enter key
		await modify_random_sculpture()

func modify_random_sculpture():
	var sculptures = get_children().filter(func(child): return child is WFCSculptureGenerator)
	if not sculptures.is_empty():
		var random_sculpture = sculptures[randi() % sculptures.size()]
		
		# Randomize parameters
		random_sculpture.hollow_intensity = randf_range(0.2, 0.8)
		random_sculpture.surface_complexity = randf_range(0.3, 0.9)
		random_sculpture.organic_flow = randf_range(0.2, 0.9)
		
		# Regenerate
		random_sculpture.clear_generated_sculpture()
		await random_sculpture.create_hollow_sculpture()
		
		print("Modified sculpture: ", random_sculpture.name)
