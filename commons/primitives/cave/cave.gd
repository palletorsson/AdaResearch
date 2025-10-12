extends Node3D

# Mystical Cave Generator for Godot 4
# Attach this script to a Node3D in your scene

@export var cave_radius: float = 15.0
@export var cave_height: float = 10.0
@export var bubble_count: int = 50
@export var crystal_count: int = 30
@export var use_pink_lighting: bool = true

var cave_material: StandardMaterial3D
var bubble_material: StandardMaterial3D
var crystal_material: StandardMaterial3D
var water_material: StandardMaterial3D

func _ready():
	create_materials()
	create_cave_structure()
	create_bubble_formations()
	create_crystal_clusters()
	create_lighting()
	create_teleport_platform()
	create_water_plane()
	add_fog_effect()
	
func create_materials():
	# Cave rock material
	cave_material = StandardMaterial3D.new()
	cave_material.albedo_color = Color(0.3, 0.25, 0.35)
	cave_material.roughness = 0.9
	cave_material.metallic = 0.1
	cave_material.normal_enabled = true
	cave_material.normal_scale = 2.0
	
	# Bubble/foam material with subsurface scattering effect
	bubble_material = StandardMaterial3D.new()
	bubble_material.albedo_color = Color(0.9, 0.85, 0.95, 0.8)
	bubble_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bubble_material.roughness = 0.2
	bubble_material.metallic = 0.0
	bubble_material.rim_enabled = true
	bubble_material.rim = 1.0
	bubble_material.rim_tint = 0.5
	bubble_material.emission_enabled = true
	bubble_material.emission = Color(0.8, 0.6, 0.9)
	bubble_material.emission_energy = 0.3
	
	# Crystal material
	crystal_material = StandardMaterial3D.new()
	crystal_material.albedo_color = Color(0.95, 0.9, 1.0, 0.7)
	crystal_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	crystal_material.roughness = 0.1
	crystal_material.metallic = 0.3
	crystal_material.emission_enabled = true
	crystal_material.emission = Color(1.0, 0.8, 1.0)
	crystal_material.emission_energy = 0.5
	
	# Water material
	water_material = StandardMaterial3D.new()
	water_material.albedo_color = Color(0.3, 0.2, 0.4, 0.6)
	water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_material.roughness = 0.0
	water_material.metallic = 0.5

func create_cave_structure():
	# Create main cave body using CSG shapes
	var cave_base = CSGSphere3D.new()
	cave_base.name = "CaveBase"
	cave_base.radius = cave_radius
	cave_base.radial_segments = 32
	cave_base.rings = 16
	cave_base.operation = CSGShape3D.OPERATION_SUBTRACTION
	cave_base.position = Vector3(0, cave_height * 0.5, 0)
	# Scale Y to create an elongated cave shape
	cave_base.scale = Vector3(1.0, cave_height / cave_radius, 1.0)
	add_child(cave_base)
	
	# Create cave shell
	var cave_shell = CSGBox3D.new()
	cave_shell.name = "CaveShell"
	cave_shell.size = Vector3(cave_radius * 2.5, cave_height * 2, cave_radius * 2.5)
	cave_shell.material = cave_material
	add_child(cave_shell)
	
	# Add organic cave deformations
	for i in range(8):
		var deform = CSGSphere3D.new()
		deform.operation = CSGShape3D.OPERATION_SUBTRACTION
		deform.radius = randf_range(2.0, 5.0)
		deform.position = Vector3(
			randf_range(-cave_radius * 0.8, cave_radius * 0.8),
			randf_range(0, cave_height),
			randf_range(-cave_radius * 0.8, cave_radius * 0.8)
		)
		cave_shell.add_child(deform)

func create_bubble_formations():
	var bubble_parent = Node3D.new()
	bubble_parent.name = "BubbleFormations"
	add_child(bubble_parent)
	
	for i in range(bubble_count):
		var bubble_cluster = Node3D.new()
		bubble_cluster.position = Vector3(
			randf_range(-cave_radius, cave_radius),
			randf_range(0, cave_height),
			randf_range(-cave_radius, cave_radius)
		)
		bubble_parent.add_child(bubble_cluster)
		
		# Create cluster of bubbles
		var cluster_size = randi_range(3, 8)
		for j in range(cluster_size):
			var bubble = CSGSphere3D.new()
			bubble.radius = randf_range(0.2, 1.2)
			bubble.material = bubble_material
			bubble.position = Vector3(
				randf_range(-1, 1),
				randf_range(-1, 1),
				randf_range(-1, 1)
			)
			bubble_cluster.add_child(bubble)

func create_crystal_clusters():
	var crystal_parent = Node3D.new()
	crystal_parent.name = "CrystalClusters"
	add_child(crystal_parent)
	
	for i in range(crystal_count):
		var crystal = CSGCylinder3D.new()
		crystal.radius = randf_range(0.1, 0.4)
		crystal.height = randf_range(0.5, 2.0)
		crystal.sides = 6  # Hexagonal crystals
		crystal.material = crystal_material
		
		# Position on walls and ceiling
		var angle = randf() * TAU
		var height = randf_range(0, cave_height)
		var distance = cave_radius * randf_range(0.7, 0.95)
		
		crystal.position = Vector3(
			cos(angle) * distance,
			height,
			sin(angle) * distance
		)
		
		# Random rotation for variety
		crystal.rotation = Vector3(
			randf_range(-PI/4, PI/4),
			randf() * TAU,
			randf_range(-PI/4, PI/4)
		)
		
		crystal_parent.add_child(crystal)

func create_lighting():
	# Main ambient light
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.05, 0.15)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.3, 0.5)
	env.ambient_light_energy = 0.3
	
	# Add volumetric fog
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.05
	env.volumetric_fog_albedo = Color(0.8, 0.6, 0.9)
	env.volumetric_fog_emission = Color(0.6, 0.4, 0.7)
	env.volumetric_fog_emission_energy = 0.2
	
	var camera_attributes = CameraAttributesPractical.new()
	camera_attributes.dof_blur_far_enabled = true
	camera_attributes.dof_blur_far_distance = 20.0
	
	var world_env = WorldEnvironment.new()
	world_env.environment = env
	world_env.camera_attributes = camera_attributes
	add_child(world_env)
	
	# Pink/purple key lights
	if use_pink_lighting:
		# Main pink light
		var pink_light = OmniLight3D.new()
		pink_light.position = Vector3(0, cave_height * 0.7, 0)
		pink_light.light_color = Color(1.0, 0.6, 0.9)
		pink_light.light_energy = 2.0
		pink_light.omni_range = cave_radius * 1.5
		pink_light.light_volumetric_fog_energy = 0.5
		add_child(pink_light)
		
		# Secondary purple lights
		for i in range(3):
			var purple_light = OmniLight3D.new()
			var angle = i * TAU / 3
			purple_light.position = Vector3(
				cos(angle) * cave_radius * 0.5,
				cave_height * 0.5,
				sin(angle) * cave_radius * 0.5
			)
			purple_light.light_color = Color(0.7, 0.4, 1.0)
			purple_light.light_energy = 1.0
			purple_light.omni_range = cave_radius * 0.6
			add_child(purple_light)

func create_teleport_platform():
	var platform_parent = Node3D.new()
	platform_parent.name = "TeleportPlatform"
	platform_parent.position = Vector3(0, 0.1, 0)
	add_child(platform_parent)
	
	# Platform base
	var platform = CSGCylinder3D.new()
	platform.radius = 2.0
	platform.height = 0.3
	platform.sides = 8
	var platform_mat = StandardMaterial3D.new()
	platform_mat.albedo_color = Color(0.2, 0.6, 0.7)
	platform_mat.metallic = 0.8
	platform_mat.roughness = 0.2
	platform_mat.emission_enabled = true
	platform_mat.emission = Color(0.2, 0.8, 0.9)
	platform_mat.emission_energy = 1.0
	platform.material = platform_mat
	platform_parent.add_child(platform)
	
	# Glowing teleport effect
	var glow_ring = CSGTorus3D.new()
	glow_ring.inner_radius = 1.5
	glow_ring.outer_radius = 2.0
	glow_ring.position.y = 0.5
	var glow_mat = StandardMaterial3D.new()
	glow_mat.albedo_color = Color(0.2, 0.9, 1.0, 0.8)
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(0.2, 1.0, 1.0)
	glow_mat.emission_energy = 3.0
	glow_ring.material = glow_mat
	platform_parent.add_child(glow_ring)
	
	# Add rotating animation
	var tween = get_tree().create_tween()
	tween.set_loops()
	tween.tween_property(glow_ring, "rotation:y", TAU, 4.0)

func create_water_plane():
	var water = CSGBox3D.new()
	water.name = "Water"
	water.size = Vector3(cave_radius * 2, 0.1, cave_radius * 2)
	water.position.y = -0.05
	water.material = water_material
	add_child(water)

func add_fog_effect():
	# Add particle effects for atmosphere
	var particles = GPUParticles3D.new()
	particles.name = "FogParticles"
	particles.amount = 100
	particles.lifetime = 10.0
	particles.visibility_aabb = AABB(Vector3(-cave_radius, 0, -cave_radius), 
									  Vector3(cave_radius * 2, cave_height, cave_radius * 2))
	
	var process_mat = ParticleProcessMaterial.new()
	process_mat.initial_velocity_min = 0.1
	process_mat.initial_velocity_max = 0.5
	process_mat.angular_velocity_min = -180.0
	process_mat.angular_velocity_max = 180.0
	process_mat.gravity = Vector3(0, -0.1, 0)
	process_mat.scale_min = 2.0
	process_mat.scale_max = 4.0
	process_mat.color = Color(0.9, 0.8, 1.0, 0.3)
	
	particles.process_material = process_mat
	particles.draw_pass_1 = SphereMesh.new()
	particles.draw_pass_1.radial_segments = 8
	particles.draw_pass_1.rings = 4
	
	add_child(particles)

# Optional: Add camera controller
func add_camera():
	var camera = Camera3D.new()
	camera.position = Vector3(0, cave_height * 0.5, cave_radius * 0.8)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	camera.fov = 60
	add_child(camera)
