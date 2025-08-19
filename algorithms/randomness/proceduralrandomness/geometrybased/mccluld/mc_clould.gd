extends Node3D

# Script to create a 3D composition inspired by David McLeod's style
# Using recursive sphere packing and various primitives created on the fly

# Materials
var materials = {
	"coral": null,
	"pink_bubble": null,
	"orange_stripe": null,
	"yellow_fur": null,
	"chrome": null,
	"glass": null
}

# Parameters
var max_recursion_level = 3
var sphere_cluster_count = 5
var main_composition_size = 4.0
var bubble_density = 0.8
var min_sphere_size = 0.1
var max_sphere_size = 1.2

func _ready():
	# Set up environment
	setup_environment()
	
	# Create materials
	create_materials()
	
	# Create the main composition
	create_composition()
	
	# Setup camera
	setup_camera()

func setup_environment():
	# World environment
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	
	# Environment settings
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.0, 0.8, 0.4)  # Green background
	
	# Ambient light
	env.ambient_light_color = Color(0.2, 0.2, 0.2)
	env.ambient_light_energy = 1.0
	
	# Tonemap settings for better visual quality
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.tonemap_white = 1.0
	
	# SSR for reflections
	env.ssr_enabled = true
	env.ssr_max_steps = 64
	env.ssr_fade_in = 0.15
	env.ssr_fade_out = 2.0
	env.ssr_depth_tolerance = 0.2
	
	# Glow effect
	env.glow_enabled = true
	env.glow_intensity = 0.2
	env.glow_bloom = 0.1
	
	# Apply environment
	environment.environment = env
	add_child(environment)
	
	# Add directional light
	var dir_light = DirectionalLight3D.new()
	dir_light.light_energy = 1.5
	dir_light.shadow_enabled = true
	dir_light.rotation_degrees = Vector3(-45, 45, 0)
	add_child(dir_light)
	
	# Add some point lights for better illumination
	var light_positions = [
		Vector3(3, 3, 3),
		Vector3(-3, 2, -2),
		Vector3(0, -3, 2)
	]
	
	var light_colors = [
		Color(1.0, 0.8, 0.8),
		Color(0.8, 0.8, 1.0),
		Color(1.0, 1.0, 0.8)
	]
	
	for i in range(light_positions.size()):
		var point_light = OmniLight3D.new()
		point_light.position = light_positions[i]
		point_light.light_color = light_colors[i]
		point_light.light_energy = 1.0
		point_light.omni_range = 10.0
		add_child(point_light)

func create_materials():
	# Coral material (red bubbles)
	materials.coral = StandardMaterial3D.new()
	materials.coral.albedo_color = Color(1.0, 0.4, 0.4)
	materials.coral.roughness = 0.2
	materials.coral.metallic = 0.0
	materials.coral.metallic_specular = 0.8
	
	# Pink bubble material
	materials.pink_bubble = StandardMaterial3D.new()
	materials.pink_bubble.albedo_color = Color(1.0, 0.7, 0.8)
	materials.pink_bubble.roughness = 0.1
	materials.pink_bubble.metallic = 0.0
	materials.pink_bubble.metallic_specular = 0.9
	
	# Orange stripe material
	materials.orange_stripe = StandardMaterial3D.new()
	materials.orange_stripe.albedo_color = Color(1.0, 0.6, 0.1)
	materials.orange_stripe.roughness = 0.4
	materials.orange_stripe.metallic = 0.0
	
	# Add procedural stripes
	var noise_texture = NoiseTexture2D.new()
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	noise.cellular_jitter = 1.0
	noise.frequency = 10.0
	noise_texture.noise = noise
	noise_texture.width = 512
	noise_texture.height = 512
	
	materials.orange_stripe.albedo_texture = noise_texture
	
	# Yellow fur material
	materials.yellow_fur = StandardMaterial3D.new()
	materials.yellow_fur.albedo_color = Color(1.0, 0.9, 0.1)
	materials.yellow_fur.roughness = 0.9
	materials.yellow_fur.metallic = 0.0
	
	# Chrome material
	materials.chrome = StandardMaterial3D.new()
	materials.chrome.albedo_color = Color(0.9, 0.9, 0.9)
	materials.chrome.roughness = 0.05
	materials.chrome.metallic = 1.0
	
	# Glass material
	materials.glass = StandardMaterial3D.new()
	materials.glass.albedo_color = Color(0.9, 0.9, 0.9, 0.3)
	materials.glass.roughness = 0.0
	materials.glass.metallic = 0.0
	materials.glass.refraction_enabled = true
	materials.glass.refraction_scale = 0.05
	materials.glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	materials.glass.cull_mode = BaseMaterial3D.CULL_DISABLED

# Create primitive meshes on the fly
func create_sphere_mesh():
	var sphere = SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 32
	sphere.rings = 16
	return sphere

func create_cube_mesh():
	var cube = BoxMesh.new()
	cube.size = Vector3(1, 1, 1)
	return cube

func create_cylinder_mesh():
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.5
	cylinder.bottom_radius = 0.5
	cylinder.height = 1.0
	cylinder.radial_segments = 32
	return cylinder

func create_composition():
	# Create a root node for the composition
	var composition = Node3D.new()
	composition.name = "McLeodComposition"
	add_child(composition)
	
	# Create several main clusters
	for i in range(sphere_cluster_count):
		var cluster_position = random_position_in_sphere(main_composition_size * 0.5)
		var cluster_size = randf_range(min_sphere_size, max_sphere_size)
		var cluster_type = ["bubble", "stripe", "fur", "glass", "chrome"].pick_random()
		
		create_cluster(composition, cluster_position, cluster_size, cluster_type, 0)
	
	# Add some glass cubes as refraction elements
	add_refractive_elements(composition)

func create_cluster(parent, position, size, type, recursion_level):
	if recursion_level > max_recursion_level:
		return
	
	# Create a container for this cluster
	var cluster = Node3D.new()
	cluster.position = position
	parent.add_child(cluster)
	
	match type:
		"bubble":
			create_bubble_cluster(cluster, size, recursion_level)
		"stripe":
			create_striped_sphere(cluster, size)
		"fur":
			create_fur_object(cluster, size)
		"glass":
			create_glass_object(cluster, size)
		"chrome":
			create_chrome_object(cluster, size)
	
	# Add some sub-clusters if not at max recursion
	if recursion_level < max_recursion_level:
		var sub_cluster_count = randi_range(1, 3)
		
		for i in range(sub_cluster_count):
			var sub_position = random_position_in_sphere(size * 0.7)
			var sub_size = size * randf_range(0.3, 0.6)
			var sub_type = ["bubble", "stripe", "fur", "glass", "chrome"].pick_random()
			
			create_cluster(cluster, sub_position, sub_size, sub_type, recursion_level + 1)

func create_bubble_cluster(parent, size, recursion_level):
	# Calculate how many bubbles to create based on size and density
	var bubble_count = int(size * bubble_density * 50)
	bubble_count = min(bubble_count, 100)  # Cap to prevent too many objects
	
	# Material selection
	var material = materials.coral if randf() < 0.5 else materials.pink_bubble
	
	# Create bubbles
	for i in range(bubble_count):
		var bubble = MeshInstance3D.new()
		bubble.mesh = create_sphere_mesh()
		
		# Random size scaled by parent size
		var bubble_size = size * randf_range(0.1, 0.3)
		bubble.scale = Vector3(bubble_size, bubble_size, bubble_size)
		
		# Position within parent sphere
		bubble.position = random_position_in_sphere(size * 0.7)
		
		# Apply material
		bubble.material_override = material
		
		parent.add_child(bubble)

func create_striped_sphere(parent, size):
	var sphere = MeshInstance3D.new()
	sphere.mesh = create_sphere_mesh()
	sphere.scale = Vector3(size, size, size)
	sphere.material_override = materials.orange_stripe
	parent.add_child(sphere)

func create_fur_object(parent, size):
	# Base object
	var base = MeshInstance3D.new()
	base.mesh = create_sphere_mesh() if randf() < 0.7 else create_cylinder_mesh()
	base.scale = Vector3(size * 0.8, size * 0.8, size * 0.8)
	base.material_override = materials.yellow_fur
	parent.add_child(base)
	
	# Add fur effect with many small cylinders
	var fur_count = int(size * 80)
	fur_count = min(fur_count, 200)  # Cap to prevent too many objects
	
	for i in range(fur_count):
		var fur_strand = MeshInstance3D.new()
		fur_strand.mesh = create_cylinder_mesh()
		
		# Thin, long cylinder for fur
		var strand_width = size * 0.02
		var strand_length = size * randf_range(0.1, 0.3)
		fur_strand.scale = Vector3(strand_width, strand_length, strand_width)
		
		# Position on surface of base sphere
		var direction = Vector3(
			randf_range(-1, 1),
			randf_range(-1, 1),
			randf_range(-1, 1)
		).normalized()
		
		var base_radius = size * 0.8
		fur_strand.position = direction * base_radius
		
	
		var _direction = (fur_strand.position * 2) - fur_strand.position
		var new_basis = Basis().looking_at(_direction, Vector3.UP)

		fur_strand.transform = Transform3D(new_basis, fur_strand.position)
		# Apply material
		fur_strand.material_override = materials.yellow_fur
		
		parent.add_child(fur_strand)

func create_glass_object(parent, size):
	var glass_shape = MeshInstance3D.new()
	
	# Randomly choose between different shapes
	var shape_type = randi() % 3
	
	match shape_type:
		0:  # Cube
			glass_shape.mesh = create_cube_mesh()
		1:  # Sphere
			glass_shape.mesh = create_sphere_mesh()
		2:  # Cylinder
			glass_shape.mesh = create_cylinder_mesh()
	
	glass_shape.scale = Vector3(size, size, size)
	glass_shape.material_override = materials.glass
	
	# Randomly rotate
	glass_shape.rotation = Vector3(
		randf_range(0, PI),
		randf_range(0, PI),
		randf_range(0, PI)
	)
	
	parent.add_child(glass_shape)

func create_chrome_object(parent, size):
	var chrome_object = MeshInstance3D.new()
	chrome_object.mesh = create_sphere_mesh()
	chrome_object.scale = Vector3(size, size, size)
	chrome_object.material_override = materials.chrome
	parent.add_child(chrome_object)

func add_refractive_elements(parent):
	# Add some glass cubes that intersect with the composition
	for i in range(3):
		var glass_element = MeshInstance3D.new()
		glass_element.mesh = create_cube_mesh()
		
		# Size and position
		var element_size = randf_range(0.8, 1.5)
		glass_element.scale = Vector3(element_size, element_size, element_size * 0.2)  # Thin in one dimension
		
		glass_element.position = random_position_in_sphere(main_composition_size * 0.8)
		
		# Random rotation
		glass_element.rotation = Vector3(
			randf_range(0, PI),
			randf_range(0, PI),
			randf_range(0, PI)
		)
		
		glass_element.material_override = materials.glass
		parent.add_child(glass_element)

func setup_camera():
	var camera = Camera3D.new()
	camera.position = Vector3(0, 0, 6)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	
	# Camera settings
	camera.fov = 60
	camera.near = 0.1
	camera.far = 100
	
	add_child(camera)

func random_position_in_sphere(radius):
	var theta = randf_range(0, TAU)
	var phi = acos(randf_range(-1, 1))
	var r = radius * pow(randf(), 1.0/3.0)  # Uniform distribution within sphere
	
	return Vector3(
		r * sin(phi) * cos(theta),
		r * sin(phi) * sin(theta),
		r * cos(phi)
	)

# Optional: add animation
func _process(delta):
	# Add gentle rotation to the composition
	var composition = get_node("McLeodComposition")
	if composition:
		composition.rotate_y(delta * 0.1)
		composition.rotate_x(delta * 0.05)
