extends Node3D
class_name TartanBoxes3D

@export var grid_size: int = 10
@export var box_size: float = 1.0
@export var spacing: float = 1.2
@export var tartan_shader: Shader

var box_instances: Array[Node3D] = []

func _ready():
	if tartan_shader == null:
		tartan_shader = load("res://commons/resourses/shaders/tartanshader.gdshader")
	
	create_tartan_grid()
	setup_lighting()
	
	print("TartanBoxes3D: Created %d x %d grid with unique tartan patterns" % [grid_size, grid_size])



func setup_lighting():
	# Main directional light
	var main_light = DirectionalLight3D.new()
	main_light.name = "MainLight"
	main_light.position = Vector3(5, 10, 5)
	main_light.look_at(Vector3.ZERO, Vector3.UP)
	main_light.light_energy = 1.2
	main_light.shadow_enabled = true
	add_child(main_light)
	
	# Ambient light for better visibility
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.3
	
	var world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

func create_tartan_grid():
	# Clear existing boxes
	for box in box_instances:
		if is_instance_valid(box):
			box.queue_free()
	box_instances.clear()
	
	# Create new grid
	for row in range(grid_size):
		for col in range(grid_size):
			var box = create_tartan_box(row, col)
			box_instances.append(box)
			add_child(box)
	
	print("Created %d unique tartan boxes" % box_instances.size())

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
	
	# Create unique tartan material
	var material = create_unique_tartan_material(row, col)
	mesh_instance.material_override = material
	
	box_root.add_child(mesh_instance)
	
	return box_root

func create_unique_tartan_material(row: int, col: int) -> ShaderMaterial:
	var material = ShaderMaterial.new()
	material.shader = tartan_shader
	
	# Create unique seed based on position
	var unique_seed = float(row * grid_size + col + 1) * 47.3 + row * 123.7 + col * 89.1
	material.set_shader_parameter("object_seed", unique_seed)
	
	# Randomize UV scale for different tartan patterns
	var rng = RandomNumberGenerator.new()
	rng.seed = int(unique_seed)
	
	var scale_x = rng.randf_range(20.0, 80.0)
	var scale_y = rng.randf_range(5.0, 30.0)
	material.set_shader_parameter("uv_scale", Vector2(scale_x, scale_y))
	
	# Set randomization parameters
	material.set_shader_parameter("color_randomness", rng.randf_range(0.3, 0.8))
	material.set_shader_parameter("line_width_randomness", rng.randf_range(0.2, 0.6))
	
	# Create unique base colors
	var hue_base = rng.randf()
	material.set_shader_parameter("color_a", Color.from_hsv(hue_base, 0.2, 0.95))               # Light color
	material.set_shader_parameter("color_b", Color.from_hsv(fmod(hue_base + 0.5, 1.0), 0.8, 0.3))  # Dark color
	material.set_shader_parameter("color_c", Color.from_hsv(fmod(hue_base + 0.33, 1.0), 0.9, 0.8)) # Accent color
	material.set_shader_parameter("color_d", Color.from_hsv(fmod(hue_base + 0.66, 1.0), 0.4, 0.7)) # Base color
	
	return material
