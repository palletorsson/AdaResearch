extends Node3D

# 3D Tartan Grid Generator
# Creates a 3D grid of tartan-patterned cubes with various clan patterns

const GRID_SIZE = 10
const CUBE_SIZE = 2.0
const SPACING = 0.2
const TOTAL_SPACING = CUBE_SIZE + SPACING

# Scottish Clan Tartan Color Schemes
var clan_tartans = [
	{
		"name": "Royal Stewart",
		"colors": [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW],
		"brightness": 1.4,
		"saturation": 2.0
	},
	{
		"name": "Black Watch",
		"colors": [Color(0, 0.3, 0.8), Color(0, 0.5, 0.2), Color(0.1, 0.1, 0.1), Color.WHITE],
		"brightness": 1.2,
		"saturation": 1.6
	},
	{
		"name": "Gordon",
		"colors": [Color(0, 0.6, 0.2), Color(0, 0.2, 0.8), Color.BLACK, Color.YELLOW],
		"brightness": 1.3,
		"saturation": 1.8
	},
	{
		"name": "MacLeod",
		"colors": [Color.YELLOW, Color.BLACK, Color.RED, Color.WHITE],
		"brightness": 1.5,
		"saturation": 2.2
	},
	{
		"name": "Campbell",
		"colors": [Color(0, 0.5, 0.1), Color(0, 0.3, 0.7), Color.BLACK, Color.WHITE],
		"brightness": 1.3,
		"saturation": 1.7
	},
	{
		"name": "MacKenzie",
		"colors": [Color(0, 0.4, 0.2), Color(0.8, 0, 0), Color(0, 0.2, 0.6), Color.BLACK],
		"brightness": 1.4,
		"saturation": 1.9
	},
	{
		"name": "Fraser",
		"colors": [Color.RED, Color(0, 0.5, 0.3), Color(0, 0.3, 0.8), Color.WHITE],
		"brightness": 1.3,
		"saturation": 1.8
	},
	{
		"name": "MacDonald",
		"colors": [Color(0, 0.6, 0.1), Color.RED, Color.BLACK, Color(0, 0.4, 0.8)],
		"brightness": 1.4,
		"saturation": 2.0
	},
	{
		"name": "Wallace",
		"colors": [Color.YELLOW, Color.RED, Color.BLACK, Color.WHITE],
		"brightness": 1.5,
		"saturation": 2.1
	},
	{
		"name": "Scott",
		"colors": [Color.RED, Color(0, 0.5, 0.2), Color.BLACK, Color.WHITE],
		"brightness": 1.3,
		"saturation": 1.7
	}
]

# Modern/Pride Tartans
var modern_tartans = [
	{
		"name": "Pride Rainbow",
		"colors": [Color.RED, Color(1, 0.5, 0), Color.YELLOW, Color.GREEN, Color.BLUE, Color(0.5, 0, 1)],
		"brightness": 1.6,
		"saturation": 2.5
	},
	{
		"name": "Trans Pride",
		"colors": [Color(0.34, 0.81, 0.98), Color(0.96, 0.68, 0.81), Color.WHITE, Color(0.96, 0.68, 0.81)],
		"brightness": 1.4,
		"saturation": 1.8
	},
	{
		"name": "Lesbian Pride",
		"colors": [Color(0.84, 0.15, 0.27), Color(1, 0.42, 0.18), Color.WHITE, Color(0.84, 0.42, 0.92)],
		"brightness": 1.5,
		"saturation": 2.0
	},
	{
		"name": "Bi Pride",
		"colors": [Color(0.84, 0.15, 0.57), Color(0.62, 0.35, 0.71), Color(0, 0.32, 0.82)],
		"brightness": 1.4,
		"saturation": 2.2
	},
	{
		"name": "Pan Pride",
		"colors": [Color(1, 0.13, 0.53), Color(1, 0.85, 0), Color(0.13, 0.67, 1)],
		"brightness": 1.5,
		"saturation": 2.3
	},
	{
		"name": "Non-Binary",
		"colors": [Color.YELLOW, Color.WHITE, Color(0.61, 0.35, 0.71), Color.BLACK],
		"brightness": 1.3,
		"saturation": 1.9
	}
]

var all_tartans = []
var cube_instances = []
var current_animation_time = 0.0
var animation_speed = 1.0

@export var animate_colors: bool = true
@export var rotate_cubes: bool = false
@export var wave_height: float = 2.0

func _ready():
	print("🏴󠁧󠁢󠁳󠁣󠁴󠁿 TartanGrid3D: Initializing 3D tartan cube gallery...")
	
	# Combine all tartan patterns
	all_tartans = clan_tartans + modern_tartans
	
	# Generate additional random patterns to fill the grid
	while all_tartans.size() < GRID_SIZE * GRID_SIZE:
		all_tartans.append(generate_random_tartan())
	
	setup_camera()
	generate_3d_tartan_grid()
	
	print("✅ Generated ", cube_instances.size(), " tartan cubes in 10x10x1 grid")
	print("🎮 Controls: R=Regenerate, T=Toggle Animation, Space=Wave Effect")

func setup_camera():
	# Add a camera if none exists
	if not get_viewport().get_camera_3d():
		var camera = Camera3D.new()
		camera.position = Vector3(GRID_SIZE * TOTAL_SPACING * 0.5, 15, GRID_SIZE * TOTAL_SPACING * 0.8)
		camera.look_at(Vector3(GRID_SIZE * TOTAL_SPACING * 0.5, 0, GRID_SIZE * TOTAL_SPACING * 0.5), Vector3.UP)
		add_child(camera)
		print("📷 Added camera for 3D tartan grid view")

func generate_3d_tartan_grid():
	# Clear existing cubes
	for cube in cube_instances:
		if is_instance_valid(cube):
			cube.queue_free()
	cube_instances.clear()
	
	# Generate grid of tartan cubes
	for x in range(GRID_SIZE):
		for z in range(GRID_SIZE):
			var index = x * GRID_SIZE + z
			var tartan = all_tartans[index % all_tartans.size()]
			
			var cube = create_tartan_cube(tartan, index)
			cube.position = Vector3(
				x * TOTAL_SPACING - (GRID_SIZE * TOTAL_SPACING * 0.5),
				0,
				z * TOTAL_SPACING - (GRID_SIZE * TOTAL_SPACING * 0.5)
			)
			
			add_child(cube)
			cube_instances.append(cube)

func create_tartan_cube(tartan: Dictionary, index: int) -> MeshInstance3D:
	var cube = MeshInstance3D.new()
	cube.name = "TartanCube_" + str(index) + "_" + tartan.name.replace(" ", "_")
	
	# Create box mesh
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(CUBE_SIZE, CUBE_SIZE, CUBE_SIZE)
	cube.mesh = box_mesh
	
	# Create tartan material
	var material = create_tartan_material(tartan, index)
	cube.material_override = material
	
	# Add metadata for interactions
	cube.set_meta("tartan_data", tartan)
	cube.set_meta("grid_index", index)
	cube.set_meta("original_position", cube.position)
	
	# Make clickable
	var area = Area3D.new()
	var collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(CUBE_SIZE, CUBE_SIZE, CUBE_SIZE)
	collision.shape = box_shape
	
	area.add_child(collision)
	cube.add_child(area)
	
	area.input_event.connect(_on_cube_clicked.bind(cube))
	area.mouse_entered.connect(_on_cube_hover_enter.bind(cube))
	area.mouse_exited.connect(_on_cube_hover_exit.bind(cube))
	
	return cube

func create_tartan_material(tartan: Dictionary, index: int) -> ShaderMaterial:
	# Load the tartan shader
	var shader = load("res://commons/resourses/shaders/tartanshader.gdshader")
	var material = ShaderMaterial.new()
	material.shader = shader
	
	# Set colors from tartan pattern
	var colors = tartan.colors
	material.set_shader_parameter("color_a", colors[0] if colors.size() > 0 else Color.RED)
	material.set_shader_parameter("color_b", colors[1] if colors.size() > 1 else Color.BLUE)
	material.set_shader_parameter("color_c", colors[2] if colors.size() > 2 else Color.GREEN)
	material.set_shader_parameter("color_d", colors[3] if colors.size() > 3 else Color.YELLOW)
	
	# Set unique seed for each cube
	material.set_shader_parameter("object_seed", float(index))
	
	# Set brightness and saturation from tartan data
	material.set_shader_parameter("brightness_boost", tartan.get("brightness", 1.3))
	material.set_shader_parameter("saturation_boost", tartan.get("saturation", 1.8))
	material.set_shader_parameter("contrast", 1.2)
	
	# Randomize pattern parameters slightly for each cube
	material.set_shader_parameter("color_randomness", 0.3 + randf() * 0.4)
	material.set_shader_parameter("line_width_randomness", 0.2 + randf() * 0.3)
	
	# UV scale for pattern density
	var scale_variation = Vector2(
		30.0 + randf() * 20.0,
		8.0 + randf() * 6.0
	)
	material.set_shader_parameter("uv_scale", scale_variation)
	
	# Animation speed
	material.set_shader_parameter("time_speed", 0.05 + randf() * 0.1)
	
	return material

func generate_random_tartan() -> Dictionary:
	var colors = []
	var num_colors = randi_range(3, 6)
	
	# Generate vibrant random colors
	for i in range(num_colors):
		var hue = randf()
		var saturation = 0.7 + randf() * 0.3
		var value = 0.7 + randf() * 0.3
		colors.append(Color.from_hsv(hue, saturation, value))
	
	return {
		"name": "Generated_" + str(randi() % 1000),
		"colors": colors,
		"brightness": 1.2 + randf() * 0.6,
		"saturation": 1.5 + randf() * 1.0
	}

func _process(delta):
	current_animation_time += delta * animation_speed
	
	if animate_colors:
		update_cube_animations()
	
	if rotate_cubes:
		rotate_all_cubes(delta)

func update_cube_animations():
	for i in range(cube_instances.size()):
		var cube = cube_instances[i]
		if not is_instance_valid(cube):
			continue
		
		var material = cube.material_override as ShaderMaterial
		if material:
			# Update animation time for shader
			material.set_shader_parameter("time_speed", 0.1 + sin(current_animation_time + i * 0.1) * 0.05)
			
			# Subtle position wave
			var original_pos = cube.get_meta("original_position", cube.position)
			var wave_offset = sin(current_animation_time * 2.0 + i * 0.2) * wave_height * 0.1
			cube.position.y = original_pos.y + wave_offset

func rotate_all_cubes(delta):
	for i in range(cube_instances.size()):
		var cube = cube_instances[i]
		if is_instance_valid(cube):
			cube.rotation.y += delta * (0.5 + i * 0.01)
			cube.rotation.x += delta * (0.3 + i * 0.005)

func _on_cube_clicked(camera, event, position, normal, shape_idx, cube: MeshInstance3D):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var tartan_data = cube.get_meta("tartan_data", {})
		var grid_index = cube.get_meta("grid_index", -1)
		
		print("🏴󠁧󠁢󠁳󠁣󠁴󠁿 Clicked tartan cube: ", tartan_data.get("name", "Unknown"))
		print("  Grid position: ", grid_index % GRID_SIZE, ",", grid_index / GRID_SIZE)
		print("  Colors: ", tartan_data.get("colors", []).size())
		
		# Bounce effect
		var tween = create_tween()
		var original_scale = cube.scale
		tween.tween_property(cube, "scale", original_scale * 1.2, 0.1)
		tween.tween_property(cube, "scale", original_scale, 0.1)

func _on_cube_hover_enter(cube: MeshInstance3D):
	# Subtle glow effect on hover
	var tween = create_tween()
	tween.tween_property(cube, "scale", cube.scale * 1.05, 0.1)

func _on_cube_hover_exit(cube: MeshInstance3D):
	# Remove glow effect
	var original_scale = Vector3.ONE
	var tween = create_tween()
	tween.tween_property(cube, "scale", original_scale, 0.1)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				print("🔄 Regenerating tartan grid...")
				regenerate_grid()
			KEY_T:
				animate_colors = !animate_colors
				print("🎭 Animation toggled: ", animate_colors)
			KEY_SPACE:
				trigger_wave_effect()
			KEY_Q:
				rotate_cubes = !rotate_cubes
				print("🔄 Rotation toggled: ", rotate_cubes)
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
				var speed_level = event.keycode - KEY_0
				animation_speed = speed_level * 0.5
				print("⚡ Animation speed: ", animation_speed)

func regenerate_grid():
	# Regenerate random patterns
	for i in range(clan_tartans.size() + modern_tartans.size(), all_tartans.size()):
		all_tartans[i] = generate_random_tartan()
	
	# Regenerate the grid
	generate_3d_tartan_grid()

func trigger_wave_effect():
	print("🌊 Triggering wave effect...")
	
	for i in range(cube_instances.size()):
		var cube = cube_instances[i]
		if not is_instance_valid(cube):
			continue
		
		var delay = i * 0.02
		var tween = create_tween()
		
		tween.tween_delay(delay)
		tween.tween_property(cube, "position:y", cube.position.y + wave_height, 0.3)
		tween.tween_property(cube, "position:y", cube.position.y, 0.3)

func print_stats():
	print("\n🏴󠁧󠁢󠁳󠁣󠁴󠁿 3D Tartan Grid Statistics:")
	print("  Total cubes: ", cube_instances.size())
	print("  Clan tartans: ", clan_tartans.size())
	print("  Modern tartans: ", modern_tartans.size())
	print("  Random patterns: ", all_tartans.size() - clan_tartans.size() - modern_tartans.size())
	print("  Animation active: ", animate_colors)
	print("  Rotation active: ", rotate_cubes)
	print("  Wave height: ", wave_height)
