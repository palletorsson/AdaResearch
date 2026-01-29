extends Node3D

# Dew-Covered Foliage Scene Generator
# Recreates lush garden foliage with realistic water droplets

@export var leaf_count: int = 50
@export var droplet_density: float = 0.3  # Droplets per leaf
@export var scene_radius: float = 5.0
@export var leaf_size_min: float = 0.5
@export var leaf_size_max: float = 1.2
@export var generate_on_start: bool = true

# Materials
var leaf_material: StandardMaterial3D
var droplet_material: StandardMaterial3D
var stem_material: StandardMaterial3D

# Collections
var leaves: Array = []
var droplets: Array = []
var stems: Array = []

# Lighting
var main_light: DirectionalLight3D
var environment_resource: Environment

func _ready():
	setup_lighting()
	setup_materials()
	if generate_on_start:
		generate_foliage_scene()

func setup_lighting():
	# Create natural outdoor lighting
	main_light = DirectionalLight3D.new()
	main_light.position = Vector3(2, 4, 3)
	main_light.rotation_degrees = Vector3(-30, -45, 0)
	main_light.light_energy = 0.8
	main_light.light_color = Color(1.0, 0.95, 0.8)  # Warm morning light
	main_light.shadow_enabled = true
	main_light.shadow_bias = 0.1
	add_child(main_light)
	
	# Set up environment
	environment_resource = Environment.new()
	environment_resource.background_mode = Environment.BG_COLOR
	environment_resource.background_color = Color(0.4, 0.6, 0.3, 1.0)  # Forest green
	environment_resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment_resource.ambient_light_color = Color(0.6, 0.8, 0.6)
	environment_resource.ambient_light_energy = 0.3
	
	# Apply environment to camera
	var camera = get_viewport().get_camera_3d()
	if camera:
		camera.environment = environment_resource

func setup_materials():
	# Leaf material - various shades of green
	leaf_material = StandardMaterial3D.new()
	leaf_material.albedo_color = Color(0.2, 0.6, 0.2)
	leaf_material.metallic = 0.0
	leaf_material.roughness = 0.7
	leaf_material.subsurface_scattering_strength = 0.3  # Light transmission through leaves
	
	# Water droplet material - clear and refractive
	droplet_material = StandardMaterial3D.new()
	droplet_material.albedo_color = Color(0.9, 0.95, 1.0, 0.8)
	droplet_material.metallic = 0.0
	droplet_material.roughness = 0.0
	droplet_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	droplet_material.refraction_enabled = true
	droplet_material.refraction_scale = 0.1
	droplet_material.rim_enabled = true
	 
	droplet_material.rim_tint = 0.5
	
	# Stem material
	stem_material = StandardMaterial3D.new()
	stem_material.albedo_color = Color(0.15, 0.4, 0.15)
	stem_material.metallic = 0.0
	stem_material.roughness = 0.9

func generate_foliage_scene():
	clear_scene()
	
	for i in range(leaf_count):
		create_leaf_cluster()

func clear_scene():
	for leaf in leaves:
		if is_instance_valid(leaf):
			leaf.queue_free()
	for droplet in droplets:
		if is_instance_valid(droplet):
			droplet.queue_free()
	for stem in stems:
		if is_instance_valid(stem):
			stem.queue_free()
	
	leaves.clear()
	droplets.clear()
	stems.clear()

func create_leaf_cluster():
	# Random position within scene radius
	var position = Vector3(
		randf_range(-scene_radius, scene_radius),
		randf_range(-1.0, 2.0),
		randf_range(-scene_radius, scene_radius)
	)
	
	# Create 2-4 leaves per cluster
	var cluster_size = randi_range(2, 4)
	
	for i in range(cluster_size):
		var leaf = create_single_leaf(position, i)
		leaves.append(leaf)
		
		# Add water droplets to this leaf
		add_droplets_to_leaf(leaf)

func create_single_leaf(base_position: Vector3, leaf_index: int) -> MeshInstance3D:
	var leaf = MeshInstance3D.new()
	
	# Create leaf shape using a flattened ellipsoid
	var leaf_mesh = SphereMesh.new()
	var size = randf_range(leaf_size_min, leaf_size_max)
	leaf_mesh.radius = size * 0.5
	leaf_mesh.height = size * 0.05  # Very flat for leaf-like appearance
	
	leaf.mesh = leaf_mesh
	
	# Random leaf material variation
	var leaf_mat = leaf_material.duplicate()
	var green_variation = randf_range(0.8, 1.2)
	leaf_mat.albedo_color = Color(
		0.2 * green_variation,
		0.6 * green_variation,
		0.2 * green_variation
	)
	leaf.material_override = leaf_mat
	
	# Position with slight offset for natural clustering
	leaf.position = base_position + Vector3(
		randf_range(-0.3, 0.3),
		randf_range(-0.2, 0.2),
		randf_range(-0.3, 0.3)
	)
	
	# Natural rotation
	leaf.rotation_degrees = Vector3(
		randf_range(-30, 30),
		randf_range(0, 360),
		randf_range(-45, 45)
	)
	
	# Add serrated edges effect by scaling slightly
	var edge_variation = randf_range(0.9, 1.1)
	leaf.scale = Vector3(edge_variation, 1.0, edge_variation * 0.8)
	
	add_child(leaf)
	
	# Add stem
	create_stem_for_leaf(leaf)
	
	return leaf

func create_stem_for_leaf(leaf: MeshInstance3D):
	var stem = MeshInstance3D.new()
	
	var stem_mesh = CylinderMesh.new()
	stem_mesh.top_radius = 0.02
	stem_mesh.bottom_radius = 0.03
	stem_mesh.height = randf_range(0.2, 0.4)
	
	stem.mesh = stem_mesh
	stem.material_override = stem_material
	
	# Position stem below leaf
	stem.position = leaf.position + Vector3(0, -stem_mesh.height * 0.5, 0)
	stem.rotation_degrees = Vector3(
		randf_range(-10, 10),
		randf_range(0, 360),
		randf_range(-10, 10)
	)
	
	add_child(stem)
	stems.append(stem)

func add_droplets_to_leaf(leaf: MeshInstance3D):
	var droplet_count = int(randf() * droplet_density * 10) + 1
	
	for i in range(droplet_count):
		create_water_droplet(leaf)

func create_water_droplet(leaf: MeshInstance3D) -> MeshInstance3D:
	var droplet = MeshInstance3D.new()
	
	# Create droplet shape - slightly flattened sphere
	var droplet_mesh = SphereMesh.new()
	var droplet_size = randf_range(0.02, 0.08)
	droplet_mesh.radius = droplet_size
	droplet_mesh.height = droplet_size * 1.5  # Slightly elongated
	
	droplet.mesh = droplet_mesh
	droplet.material_override = droplet_material
	
	# Position on leaf surface
	var leaf_bounds = leaf.get_aabb()
	droplet.position = leaf.position + Vector3(
		randf_range(-leaf_bounds.size.x * 0.3, leaf_bounds.size.x * 0.3),
		leaf_bounds.size.y * 0.5 + droplet_size * 0.5,  # Sit on top of leaf
		randf_range(-leaf_bounds.size.z * 0.3, leaf_bounds.size.z * 0.3)
	)
	
	# Slight random rotation
	droplet.rotation_degrees = Vector3(
		randf_range(-5, 5),
		randf_range(0, 360),
		randf_range(-5, 5)
	)
	
	add_child(droplet)
	droplets.append(droplet)
	
	return droplet

func add_animated_effects():
	# Add gentle swaying to leaves
	var tween = create_tween()
	tween.set_loops()
	
	for leaf in leaves:
		if is_instance_valid(leaf):
			# Gentle wind effect
			var original_rotation = leaf.rotation_degrees
			tween.parallel().tween_method(
				func(rot): leaf.rotation_degrees = original_rotation + Vector3(sin(rot) * 2, 0, cos(rot) * 1),
				0.0, PI * 2, randf_range(3.0, 6.0)
			)

func regenerate_scene():
	generate_foliage_scene()
	if leaves.size() > 0:
		add_animated_effects()

# Public interface
func set_leaf_count(count: int):
	leaf_count = count
	regenerate_scene()

func set_droplet_density(density: float):
	droplet_density = clamp(density, 0.0, 1.0)
	regenerate_scene()

func set_scene_size(radius: float):
	scene_radius = radius
	regenerate_scene()

func toggle_animation():
	add_animated_effects()

# Called when scene loads
func _input(event):
	if event.is_action_pressed("ui_accept"):  # Space key
		regenerate_scene()
		add_animated_effects()
