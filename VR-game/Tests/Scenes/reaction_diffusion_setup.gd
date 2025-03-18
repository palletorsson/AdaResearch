extends Node3D

# Ada Research: Reaction-Diffusion Maze Setup
# This script sets up a complete scene for the reaction-diffusion system

func _ready():
	# Create environment
	setup_environment()
	
	# Create reaction-diffusion system
	create_reaction_diffusion_system()
	


func setup_environment():
	# Create a nice environment for viewing
	
	# Add environment lighting
	var world_env = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	var env = Environment.new()
	
	# Ambient settings
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color(0.2, 0.2, 0.3)
	env.ambient_light_energy = 1.0
	
	# Post-processing
	env.ssao_enabled = true
	env.ssr_enabled = true
	env.glow_enabled = true
	
	# Background
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	var sky_material = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.1, 0.12, 0.25)
	sky_material.sky_horizon_color = Color(0.3, 0.2, 0.4)
	sky_material.ground_bottom_color = Color(0.1, 0.1, 0.1)
	sky_material.ground_horizon_color = Color(0.22, 0.15, 0.3)
	env.sky.sky_material = sky_material
	
	world_env.environment = env
	add_child(world_env)
	
	# Add main directional light (sun)
	var dir_light = DirectionalLight3D.new()
	dir_light.name = "SunLight"
	dir_light.position = Vector3(0, 10, 0)
	dir_light.rotation_degrees = Vector3(-45, 45, 0)
	dir_light.light_energy = 1.0
	dir_light.shadow_enabled = true
	add_child(dir_light)
	
	# Add a second light from another angle
	var fill_light = DirectionalLight3D.new()
	fill_light.name = "FillLight"
	fill_light.position = Vector3(0, 10, 0)
	fill_light.rotation_degrees = Vector3(-30, -60, 0)
	fill_light.light_energy = 0.5
	fill_light.light_color = Color(0.9, 0.8, 1.0)  # Slightly purple fill light
	add_child(fill_light)

func create_reaction_diffusion_system():
	# Create the main reaction-diffusion system
	var rd_system = load("res://adaresearch/Tests/Scenes/reaction_diffusion_systems.gd").new()
	rd_system.name = "ReactionDiffusionSystem"
	
	# First, let's print all available properties to debug
	print("Available properties in RD system:")
	for prop in rd_system.get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			print("- " + prop.name + " (type: " + str(prop.type) + ")")
	
	# Set properties safely - Using property set method to avoid type issues
	# Common properties that should exist regardless of property names
	if "grid_size" in rd_system:
		# Try different ways of setting the grid size
		rd_system.set("grid_size", Vector2i(200, 200))
	elif "width" in rd_system and "height" in rd_system:
		rd_system.set("width", 200)
		rd_system.set("height", 200)
	
	# Set other properties safely
	safe_set_property(rd_system, "iterations_per_frame", 5)
	safe_set_property(rd_system, "feed_rate", 0.055)
	safe_set_property(rd_system, "kill_rate", 0.062)
	safe_set_property(rd_system, "diffusion_rate_a", 1.0)
	safe_set_property(rd_system, "diffusion_rate_b", 0.5)
	safe_set_property(rd_system, "mesh_height", 3.0)
	safe_set_property(rd_system, "initialize_as_maze", true)
	safe_set_property(rd_system, "auto_start", true)
	
	# Create materials
	var b_material = create_b_material()
	var path_material = create_path_material()
	
	safe_set_property(rd_system, "material_b", b_material)
	safe_set_property(rd_system, "path_material", path_material)
	
	add_child(rd_system)
	
	# Create a timer to extract the maze path after the system has evolved
	var path_timer = Timer.new()
	path_timer.wait_time = 10.0  # Wait for pattern to develop
	path_timer.one_shot = true
	
	# Check if the method exists before connecting
	if rd_system.has_method("visualize_maze_path"):
		path_timer.connect("timeout", Callable(rd_system, "visualize_maze_path"))
	else:
		print("Warning: visualize_maze_path method not found")
	
	add_child(path_timer)
	path_timer.start()

# Utility function to safely set properties
func safe_set_property(object, property_name, value):
	if property_name in object:
		# Try to set the property directly
		object.set(property_name, value)
		print("Set property: " + property_name)
	else:
		print("Warning: Property " + property_name + " not found")

func create_b_material() -> Material:
	# Create a material for the reaction-diffusion mesh
	var material = StandardMaterial3D.new()
	
	# Custom shader for better visualization
	material.albedo_color = Color(0.05, 0.1, 0.2)
	material.metallic = 0.8
	material.roughness = 0.2
	material.normal_enabled = true
	material.normal_scale = 3.0
	
	return material

func create_path_material() -> Material:
	# Create a material for the maze path
	var material = StandardMaterial3D.new()
	
	material.albedo_color = Color(0.8, 0.5, 1.0, 0.8)
	material.emission_enabled = true
	material.emission = Color(0.5, 0.2, 1.0)
	material.emission_energy_multiplier = 1.5
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.metallic = 0.7
	material.roughness = 0.2
	
	return material
