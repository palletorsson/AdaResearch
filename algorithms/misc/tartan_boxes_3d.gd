# Bright & Happy Tartan Boxes 3D
extends Node3D
class_name TartanBoxes3D

@export var grid_size: int = 10
@export var box_size: float = 1.0
@export var spacing: float = 1.2
@export var tartan_shader: Shader
@export var brightness_boost: float = 1.3
@export var saturation_boost: float = 1.5
var box_instances: Array[Node3D] = []

func _ready():
	if tartan_shader == null:
		tartan_shader = load("res://commons/resourses/shaders/tartanshader.gdshader")
	
	create_tartan_grid()
	setup_lighting()
	
	print("TartanBoxes3D: Created %d x %d grid with vibrant tartan patterns" % [grid_size, grid_size])

func setup_lighting():
	# Bright main directional light for vibrant colors
	var main_light = DirectionalLight3D.new()
	main_light.name = "MainLight"
	main_light.position = Vector3(5, 10, 5)
	main_light.look_at_from_position(main_light.position, Vector3.ZERO, Vector3.UP)
	main_light.light_energy = 1.5  # Increased brightness
	main_light.shadow_enabled = true
	add_child(main_light)
	
	# Additional fill light for even brighter appearance
	var fill_light = DirectionalLight3D.new()
	fill_light.name = "FillLight"
	fill_light.position = Vector3(-3, 8, -3)
	fill_light.look_at_from_position(fill_light.position, Vector3.ZERO, Vector3.UP)
	fill_light.light_energy = 0.8
	fill_light.light_color = Color(1.1, 1.0, 0.9)  # Slightly warm
	add_child(fill_light)
	
	# Bright ambient light
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky_rotation = Vector3(0, PI/4, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.6  # Much brighter ambient
	
	# Add subtle bloom for extra vibrancy
	env.glow_enabled = true
	env.glow_intensity = 0.3
	env.glow_strength = 0.8
	env.glow_bloom = 0.05
	
	var world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

func create_tartan_grid():
	# Clear existing boxes
	for box in box_instances:
		if is_instance_valid(box):
			box.queue_free()
	box_instances.clear()
	
	# Create new grid with extra variety
	for row in range(grid_size):
		for col in range(grid_size):
			var box = create_tartan_box(row, col)
			box_instances.append(box)
			add_child(box)
	
	print("Created %d vibrant tartan boxes" % box_instances.size())

func create_tartan_box(row: int, col: int) -> Node3D:
	var box_root = Node3D.new()
	box_root.name = "TartanBox_%d_%d" % [row, col]
	box_root.position = Vector3(col * spacing, 0, row * spacing)
	
	# Create the main box mesh
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "BoxMesh"
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(box_size, box_size, box_size)
	mesh_instance.mesh = box_mesh
	
	# Create bright, happy tartan material
	var material = create_bright_tartan_material(row, col)
	mesh_instance.material_override = material
	
	box_root.add_child(mesh_instance)
	
	return box_root

func create_bright_tartan_material(row: int, col: int) -> ShaderMaterial:
	var material = ShaderMaterial.new()
	material.shader = tartan_shader
	
	# Create unique seed
	var unique_seed = float(row * grid_size + col + 1) * 47.3 + row * 123.7 + col * 89.1
	material.set_shader_parameter("object_seed", unique_seed)
	
	# Randomize UV scale
	var rng = RandomNumberGenerator.new()
	rng.seed = int(unique_seed)
	
	var scale_x = rng.randf_range(15.0, 60.0)
	var scale_y = rng.randf_range(8.0, 25.0)
	material.set_shader_parameter("uv_scale", Vector2(scale_x, scale_y))
	
	# Reduced randomization for more consistent bright colors
	material.set_shader_parameter("color_randomness", rng.randf_range(0.1, 0.3))
	material.set_shader_parameter("line_width_randomness", rng.randf_range(0.2, 0.5))
	
	# BRIGHT, HAPPY COLOR PALETTES!
	var palette_choice = rng.randi() % 5
	match palette_choice:
		0: # Tropical Sunset
			material.set_shader_parameter("color_a", Color(1.0, 0.95, 0.1))      # Bright yellow
			material.set_shader_parameter("color_b", Color(1.0, 0.4, 0.0))       # Orange
			material.set_shader_parameter("color_c", Color(1.0, 0.1, 0.5))       # Hot pink
			material.set_shader_parameter("color_d", Color(0.2, 0.8, 1.0))       # Sky blue
		1: # Spring Garden
			material.set_shader_parameter("color_a", Color(0.1, 1.0, 0.3))       # Bright green
			material.set_shader_parameter("color_b", Color(1.0, 0.8, 0.9))       # Light pink
			material.set_shader_parameter("color_c", Color(0.9, 0.2, 0.9))       # Magenta
			material.set_shader_parameter("color_d", Color(0.4, 0.9, 1.0))       # Cyan
		2: # Candy Shop
			material.set_shader_parameter("color_a", Color(1.0, 0.2, 0.8))       # Hot pink
			material.set_shader_parameter("color_b", Color(0.3, 1.0, 0.4))       # Lime green
			material.set_shader_parameter("color_c", Color(1.0, 0.9, 0.0))       # Gold
			material.set_shader_parameter("color_d", Color(0.6, 0.3, 1.0))       # Purple
		3: # Ocean Breeze
			material.set_shader_parameter("color_a", Color(0.0, 0.9, 1.0))       # Bright cyan
			material.set_shader_parameter("color_b", Color(1.0, 1.0, 0.9))       # Cream
			material.set_shader_parameter("color_c", Color(0.2, 1.0, 0.6))       # Mint green
			material.set_shader_parameter("color_d", Color(1.0, 0.5, 0.2))       # Coral
		4: # Electric Dreams
			material.set_shader_parameter("color_a", Color(1.0, 0.0, 1.0))       # Electric magenta
			material.set_shader_parameter("color_b", Color(0.0, 1.0, 1.0))       # Electric cyan
			material.set_shader_parameter("color_c", Color(1.0, 1.0, 0.0))       # Electric yellow
			material.set_shader_parameter("color_d", Color(0.5, 1.0, 0.0))       # Electric lime
	
	# Add brightness and saturation boost
	material.set_shader_parameter("brightness_boost", brightness_boost)
	material.set_shader_parameter("saturation_boost", saturation_boost)
	
	return material
