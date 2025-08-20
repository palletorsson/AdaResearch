extends Node3D

# Main controller for the ant colony ecosystem simulation

func _ready():
	# Setup the simulation
	setup_scene()

# Set up the entire simulation scene
func setup_scene():
	# Create terrain
	var terrain = create_terrain()
	
	# Create pheromone system
	var pheromone_system = create_pheromone_system(terrain)
	
	# Create colony
	var colony = create_colony(terrain, pheromone_system)
	
	# Create food system
	var food_system = create_food_system(terrain, colony)
	
	# Set up environment
	setup_environment()
	
	# Set up camera
	setup_camera()
	
	# Create UI
	setup_ui()

# Create the procedural terrain
func create_terrain():
	var terrain_node = load("res://algorithms/swarmintelligence/antcolonyoptimization/ProceduralTerrain.gd").new()
	terrain_node.name = "Terrain"
	
	# Set terrain properties
	#terrain_node.size = Vector2(50.0, 50.0)
	terrain_node.resolution = 100
	terrain_node.height_scale = 5.0
	terrain_node.base_noise_scale = 3.0
	terrain_node.detail_noise_scale = 12.0
	terrain_node.terrain_seed = randi()  # Random seed
	
	add_child(terrain_node)
	return terrain_node

# Create the pheromone system
func create_pheromone_system(terrain):
	var pheromone_system = load("res://algorithms/swarmintelligence/antcolonyoptimization/PheromoneSystem.gd").new()
	pheromone_system.name = "PheromoneSystem"
	
	# Set pheromone system properties
	pheromone_system.terrain_reference = terrain.get_path()
	pheromone_system.resolution = 100
	pheromone_system.decay_rate = 0.995
	pheromone_system.diffusion_rate = 0.1
	
	add_child(pheromone_system)
	return pheromone_system

# Create the ant colony
func create_colony(terrain, pheromone_system):
	var colony = load("res://algorithms/swarmintelligence/antcolonyoptimization/AntColony.gd").new()
	colony.name = "AntColony"
	
	# Set colony position to a suitable location
	var colony_pos = find_suitable_colony_position(terrain)
	colony.position = colony_pos
	
	# Set colony properties
	colony.colony_size = 2.0
	colony.colony_color = Color(0.6, 0.3, 0.1)
	colony.max_food_capacity = 1000.0
	colony.initial_ant_count = 50
	colony.max_ant_count = 200
	colony.terrain_path = terrain.get_path()
	colony.pheromone_system_path = pheromone_system.get_path()
	
	add_child(colony)
	return colony

# Create the food system
func create_food_system(terrain, colony):
	var food_system = load("res://algorithms/swarmintelligence/antcolonyoptimization/FoodSystem.gd").new()
	food_system.name = "FoodSystem"
	
	# Set food system properties
	food_system.terrain_path = terrain.get_path()
	food_system.colony_path = colony.get_path()
	food_system.initial_food_sources = 5
	food_system.food_per_source = 100
	
	add_child(food_system)
	return food_system

# Find a suitable position for the colony
func find_suitable_colony_position(terrain):
	var suitable_pos = Vector3.ZERO
	
	# Find a relatively flat area near the center
	var center_x = 0
	var center_z = 0
	var best_slope = INF
	var search_radius = 10.0
	
	for i in range(30):  # Try 30 positions
		var angle = randf() * TAU
		var distance = randf() * search_radius
		var x = center_x + cos(angle) * distance
		var z = center_z + sin(angle) * distance
		
		# Get height and normal
		var y = terrain.get_height_at(x, z)
		var normal = terrain.get_normal_at(x, z)
		
		# Calculate slope (0 = flat, 1 = vertical)
		var slope = 1.0 - normal.y
		
		if slope < best_slope:
			best_slope = slope
			suitable_pos = Vector3(x, y, z)
	
	return suitable_pos

# Set up environment, lighting, and sky
func setup_environment():
	# Create WorldEnvironment node
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	
	# Basic environment settings
	env.ambient_light_color = Color(0.2, 0.2, 0.2)
	env.ambient_light_energy = 1.0
	
	# Fog for atmosphere
	env.fog_enabled = true
	#env.fog_color = Color(0.8, 0.8, 0.9)
	#env.fog_sun_color = Color(1.0, 0.9, 0.7)
	#env.fog_density = 0.001
	
	# Sky
	env.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var sky_material = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.4, 0.6, 0.8)
	sky_material.sky_horizon_color = Color(0.7, 0.8, 0.9)
	sky_material.ground_bottom_color = Color(0.1, 0.1, 0.1)
	sky_material.ground_horizon_color = Color(0.6, 0.6, 0.6)
	sky_material.sun_angle_max = 30.0
	sky_material.sun_curve = 0.15
	
	sky.sky_material = sky_material
	env.sky = sky
	
	world_env.environment = env
	add_child(world_env)
	
	# Create DirectionalLight for sun
	var sun = DirectionalLight3D.new()
	sun.position = Vector3(0, 50, 0)
	sun.rotation_degrees = Vector3(-45, 45, 0)
	sun.light_energy = 1.2
	sun.light_color = Color(1.0, 0.95, 0.9)
	sun.shadow_enabled = true
	
	add_child(sun)

# Set up camera and controls
func setup_camera():
	# Create a camera and orbit controller
	var camera = Camera3D.new()
	camera.name = "Camera"
	
	# Position the camera to view the colony
	camera.position = Vector3(0, 20, 20)
	camera.rotation_degrees = Vector3(-45, 0, 0)
	
	# Set basic camera properties
	camera.current = true
	camera.far = 1000.0
	
	add_child(camera)
	
	# Create an orbit controller script
	var orbit_script = """
	extends Camera3D

	var rotation_speed = 0.005
	var zoom_speed = 0.1
	var min_zoom = 5.0
	var max_zoom = 50.0
	var camera_distance = 20.0
	var target_position = Vector3.ZERO
	var orbit_angle_x = -45.0
	var orbit_angle_y = 0.0

	func _ready():
		update_camera_position()

	func _input(event):
		if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			# Rotate camera
			orbit_angle_y -= event.relative.x * rotation_speed * 50.0
			orbit_angle_x -= event.relative.y * rotation_speed * 50.0
			orbit_angle_x = clamp(orbit_angle_x, -89.0, 0.0)
			update_camera_position()
			
		elif event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				# Zoom in
				camera_distance = max(min_zoom, camera_distance - zoom_speed * 5.0)
				update_camera_position()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				# Zoom out
				camera_distance = min(max_zoom, camera_distance + zoom_speed * 5.0)
				update_camera_position()

	func update_camera_position():
		var direction = Vector3()
		direction.x = sin(deg_to_rad(orbit_angle_y)) * cos(deg_to_rad(orbit_angle_x))
		direction.y = -sin(deg_to_rad(orbit_angle_x))
		direction.z = cos(deg_to_rad(orbit_angle_y)) * cos(deg_to_rad(orbit_angle_x))
		
		position = target_position - direction * camera_distance
		look_at(target_position, Vector3.UP)
	"""
	
	# Create and attach the script to the camera
	var script = GDScript.new()
	script.source_code = orbit_script
	script.reload()
	camera.set_script(script)

# Set up UI
func setup_ui():
	# Create control node
	var ui = Control.new()
	ui.name = "UI"
	ui.anchor_right = 1.0
	ui.anchor_bottom = 1.0
	
	# Add simulation controls
	var control_panel = create_control_panel()
	ui.add_child(control_panel)
	
	add_child(ui)

# Create control panel with simulation controls
func create_control_panel():
	var panel = Panel.new()
	panel.anchor_top = 1.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_top = -50
	
	# Add simulation speed slider
	var speed_label = Label.new()
	speed_label.text = "Simulation Speed:"
	speed_label.position = Vector2(10, 15)
	speed_label.size = Vector2(120, 20)
	panel.add_child(speed_label)
	
	var speed_slider = HSlider.new()
	speed_slider.min_value = 0.1
	speed_slider.max_value = 3.0
	speed_slider.step = 0.1
	speed_slider.value = 1.0
	speed_slider.position = Vector2(140, 15)
	speed_slider.size = Vector2(200, 20)
	
	# Connect signals
	speed_slider.connect("value_changed", Callable(self, "_on_speed_changed"))
	
	panel.add_child(speed_slider)
	
	# Add reset button
	var reset_button = Button.new()
	reset_button.text = "Reset Simulation"
	reset_button.position = Vector2(350, 10)
	reset_button.size = Vector2(150, 30)
	
	# Connect signals
	reset_button.connect("pressed", Callable(self, "_on_reset_pressed"))
	
	panel.add_child(reset_button)
	
	return panel

# Signal handler for speed slider
func _on_speed_changed(value):
	Engine.time_scale = value

# Signal handler for reset button
func _on_reset_pressed():
	# Restart the simulation
	get_tree().reload_current_scene()
