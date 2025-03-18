extends Node3D

# Example scene that shows how to use the GrahamCondenser class to create
# the two different condenser styles from the images

func _ready():
	# Set up environment
	setup_environment()
	
	# Create the first condenser (Image 1 - straight tube)
	create_condenser_1()
	
	# Create the second condenser (Image 2 - bulged tube)
	create_condenser_2()

func setup_environment():
	# Create a simple environment
	var env = WorldEnvironment.new()
	var environment = Environment.new()
	
	# Set ambient light
	environment.ambient_light_color = Color(0.2, 0.2, 0.2)
	environment.ambient_light_energy = 0.5
	
	# Set up background
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.1, 0.1, 0.1)
	
	# Enable SSAO and other effects for better glass appearance
	environment.ssao_enabled = true
	environment.ssr_enabled = true
	environment.glow_enabled = true
	
	env.environment = environment
	add_child(env)
	
	# Add a camera
	var camera = Camera3D.new()
	camera.position = Vector3(0, 0, 2)
	camera.current = true
	add_child(camera)
	
	# Add lights for better rendering of glass
	add_lights()

func add_lights():
	# Create a directional light
	var dir_light = DirectionalLight3D.new()
	dir_light.position = Vector3(2, 4, 3)
	dir_light.look_at(Vector3(0, 0, 0), Vector3.UP)
	dir_light.light_energy = 1.2
	dir_light.shadow_enabled = true
	add_child(dir_light)
	
	# Create a soft omni light to provide fill lighting
	var omni_light = OmniLight3D.new()
	omni_light.position = Vector3(-2, 1, 3)
	omni_light.light_energy = 0.6
	omni_light.shadow_enabled = false
	omni_light.omni_range = 10
	add_child(omni_light)

func create_condenser_1():
	# Create the straight tube condenser (Image 1)
	var condenser1 = GrahamCondenser.new()
	condenser1.condenser_height = 1.5
	condenser1.condenser_radius = 0.08
	condenser1.spiral_loops = 14
	condenser1.tube_radius = 0.01
	condenser1.spiral_radius = 0.05
	condenser1.spiral_pitch = 0.08
	condenser1.has_bulges = false
	condenser1.side_arm_angle = 110.0
	
	# Position the first condenser
	condenser1.position = Vector3(-0.5, 0, 0)
	add_child(condenser1)
	
	# Add a label for the first condenser
	add_label("Straight Condenser (Image 1)", Vector3(-0.5, -0.9, 0))

func create_condenser_2():
	# Create the bulged tube condenser (Image 2)
	var condenser2 = GrahamCondenser.new()
	condenser2.condenser_height = 1.5
	condenser2.condenser_radius = 0.08
	condenser2.spiral_loops = 10
	condenser2.tube_radius = 0.01
	condenser2.spiral_radius = 0.05
	condenser2.spiral_pitch = 0.10
	condenser2.has_bulges = true
	condenser2.side_arm_angle = 115.0
	
	# Position the second condenser
	condenser2.position = Vector3(0.5, 0, 0)
	add_child(condenser2)
	
	# Add a label for the second condenser
	add_label("Bulged Condenser (Image 2)", Vector3(0.5, -0.9, 0))

func add_label(text: String, position: Vector3):
	# Create a 3D text label
	var label = Label3D.new()
	label.text = text
	label.font_size = 24
	label.position = position
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	add_child(label)

# Optional: Creates CSGCylinder3D version of a condenser for simpler visualization
func create_simple_condenser(position: Vector3):
	# This is a very simplified version using CSG
	# Create the main tube
	var main_tube = CSGCylinder3D.new()
	main_tube.radius = 0.08
	main_tube.height = 1.5
	main_tube.sides = 24
	
	# Create a material for the glass
	var glass_material = StandardMaterial3D.new()
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.albedo_color = Color(1.0, 1.0, 1.0, 0.2)
	glass_material.roughness = 0.05
	glass_material.metallic_specular = 0.9
	
	main_tube.material = glass_material
	main_tube.position = position
	
	# Add the inner tube as a subtraction
	var inner_tube = CSGCylinder3D.new()
	inner_tube.radius = 0.075
	inner_tube.height = 1.6  # Slightly longer to ensure proper subtraction
	inner_tube.sides = 24
	inner_tube.operation = CSGShape3D.OPERATION_SUBTRACTION
	
	main_tube.add_child(inner_tube)
	
	# Add side arms
	var arm1 = CSGCylinder3D.new()
	arm1.radius = 0.015
	arm1.height = 0.25
	arm1.position = Vector3(0, 0.35, 0)
	arm1.rotation_degrees = Vector3(0, 0, 90)
	
	var arm2 = CSGCylinder3D.new()
	arm2.radius = 0.015
	arm2.height = 0.25
	arm2.position = Vector3(0, -0.35, 0)
	arm2.rotation_degrees = Vector3(0, 0, 90)
	
	main_tube.add_child(arm1)
	main_tube.add_child(arm2)
	
	add_child(main_tube)
	
	return main_tube
