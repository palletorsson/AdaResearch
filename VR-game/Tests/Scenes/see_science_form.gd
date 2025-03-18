extends Node3D

# Science Forms Viewer
# This script creates a showcase of all the science forms

@export var auto_rotate: bool = true
@export var rotation_speed: float = 0.5

# References to all module instances
var modules = []
var current_module_index = 0
var labels = []

# UI elements
var ui_container: Control
var prev_button: Button
var next_button: Button
var info_label: Label

func _ready():
	# Set up environment
	setup_environment()
	
	# Create science modules
	create_modules()
	
	# Create UI
	setup_ui()
	
	# Show the first module
	show_module(0)

func _process(delta):
	if auto_rotate:
		for module in modules:
			module.rotate_y(delta * rotation_speed)

func setup_environment():
	# Create a nice environment for viewing the modules
	
	# Add a ground plane
	var ground = MeshInstance3D.new()
	ground.name = "Ground"
	ground.mesh = PlaneMesh.new()
	ground.mesh.size = Vector2(20, 20)
	ground.position = Vector3(0, -1, 0)
	
	var ground_material = StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.1, 0.1, 0.1)
	ground_material.metallic = 0.1
	ground_material.roughness = 0.9
	ground.material_override = ground_material
	
	add_child(ground)
	
	# Add lighting
	var dir_light = DirectionalLight3D.new()
	dir_light.position = Vector3(0, 10, 0)
	dir_light.rotation_degrees = Vector3(-45, 45, 0)
	dir_light.light_energy = 1.0
	dir_light.shadow_enabled = true
	add_child(dir_light)
	
	# Add a fill light from another direction
	var fill_light = DirectionalLight3D.new()
	fill_light.position = Vector3(0, 10, 0)
	fill_light.rotation_degrees = Vector3(-45, -135, 0)
	fill_light.light_energy = 0.5
	fill_light.light_color = Color(0.9, 0.9, 1.0)
	add_child(fill_light)
	
	# Add environment
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color(0.2, 0.2, 0.3)
	env.ambient_light_energy = 1.0
	
	env.ssao_enabled = true
	env.ssr_enabled = true
	env.glow_enabled = true
	
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	var sky_material = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.1, 0.1, 0.3)
	sky_material.sky_horizon_color = Color(0.3, 0.4, 0.6)
	env.sky.sky_material = sky_material
	
	world_env.environment = env
	add_child(world_env)
	
	# Add camera
	var camera = Camera3D.new()
	camera.position = Vector3(0, 1, 3)
	camera.look_at(Vector3(0, 0, 0))
	camera.current = true
	add_child(camera)

func create_modules():
	# Create all the science modules
	
	# This is the order of modules we'll show
	var module_names = [
		"empty",
		"cube", 
		"cylinder", 
		"sphere", 
		"dna", 
		"atom", 
		"crystal", 
		"neuron", 
		"fractal"
	]
	
	var module_descriptions = [
		"Empty Module: A foundational module with connection points only, used for structural relationships.",
		"Cube Module: A simple geometric form with six faces, representing order and structure.",
		"Cylinder Module: A circular prism showing radial symmetry, common in engineering and biology.",
		"Sphere Module: The perfect three-dimensional shape with rotational symmetry in all directions.",
		"DNA Module: The double helix structure storing genetic information, the basic blueprint of life.",
		"Atom Module: Representation of the building blocks of matter, showing electron orbits around a nucleus.",
		"Crystal Lattice: A regular grid of points showing the repeating structure of solid materials.",
		"Neuron Module: The specialized cell of the nervous system that processes and transmits information.",
		"Fractal Module: A self-similar pattern showing complexity at different scales, like the Menger sponge."
	]
	
	# Store descriptions for UI
	labels = module_descriptions
	
	# Create a container for positioning
	var container = Node3D.new()
	container.name = "ModulesContainer"
	container.position = Vector3(0, 0, 0)
	add_child(container)
	
	# Generate each module
	var generator = load("res://adaresearch/Tests/Scenes/science-space-modules-generator.gd").new()
	add_child(generator)
	
	for name in module_names:
		var module_node
		
		# Call the appropriate creation method
		match name:
			"empty":
				module_node = generator.create_empty_module()
			"cube":
				module_node = generator.create_cube_module()
			"cylinder":
				module_node = generator.create_cylinder_module()
			"sphere":
				module_node = generator.create_sphere_module()
			"dna":
				module_node = generator.create_dna_module()
			"atom":
				module_node = generator.create_atom_module()
			"crystal":
				module_node = generator.create_crystal_module()
			"neuron":
				module_node = generator.create_neuron_module()
			"fractal":
				module_node = generator.create_fractal_module()
		
		# Configure module
		if module_node:
			module_node.name = name.capitalize()
			module_node.visible = false  # Hide initially
			container.add_child(module_node)
			modules.append(module_node)
	
	# Remove the generator after we're done
	generator.queue_free()

func setup_ui():
	# Create UI for navigating between modules
	ui_container = Control.new()
	ui_container.anchor_right = 1.0
	ui_container.anchor_bottom = 1.0
	add_child(ui_container)
	
	# Info label at the top
	info_label = Label.new()
	info_label.anchor_right = 1.0
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	info_label.position.y = 20
	info_label.add_theme_color_override("font_color", Color(1, 1, 1))
	info_label.add_theme_font_size_override("font_size", 18)
	ui_container.add_child(info_label)
	
	# Navigation buttons
	prev_button = Button.new()
	prev_button.text = "< Previous"
	prev_button.position = Vector2(50, 550)
	prev_button.size = Vector2(100, 40)
	prev_button.connect("pressed", Callable(self, "_on_prev_pressed"))
	ui_container.add_child(prev_button)
	
	next_button = Button.new()
	next_button.text = "Next >"
	next_button.position = Vector2(850, 550)
	next_button.size = Vector2(100, 40)
	next_button.connect("pressed", Callable(self, "_on_next_pressed"))
	ui_container.add_child(next_button)

func show_module(index):
	# Hide all modules
	for module in modules:
		module.visible = false
	
	# Show the selected module
	if index >= 0 and index < modules.size():
		modules[index].visible = true
		current_module_index = index
		
		# Update info label
		if index < labels.size():
			info_label.text = labels[index]

func _on_prev_pressed():
	var new_index = current_module_index - 1
	if new_index < 0:
		new_index = modules.size() - 1
	show_module(new_index)

func _on_next_pressed():
	var new_index = current_module_index + 1
	if new_index >= modules.size():
		new_index = 0
	show_module(new_index)
