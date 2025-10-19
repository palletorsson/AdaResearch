# This is a guide to recreating the Alex McLeod-inspired scene in Godot 4
# The implementation is structured as a series of steps with corresponding GDScript code

# --- STEP 1: PROJECT SETUP ---
# Create a new Godot 4 project and set up the basic scene structure

# Main scene structure (to be saved as main_scene.tscn)
extends Node3D

func _ready():
	# Set up environment
	setup_environment()
	# Create terrain
	create_terrain()
	# Add water
	add_water()
	# Add structures
	add_structures()
	# Add decorative elements
	add_decorative_elements()
	# Set up camera and lighting
	setup_camera_and_lighting()
	
func setup_environment():
	# Create WorldEnvironment node
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	
	# Sky settings
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = PhysicalSkyMaterial.new()
	env.sky.sky_material.rayleigh_coefficient = 2.0
	env.sky.sky_material.mie_coefficient = 0.005
	env.sky.sky_material.sun_disk_scale = 10.0
	
	# Ambient light settings
	env.ambient_light_color = Color(0.5, 0.6, 0.7)
	env.ambient_light_energy = 1.0
	
	# Fog settings for the dreamy look
	env.fog_enabled = true
	env.fog_density = 0.01
	env.fog_aerial_perspective = 0.5
	env.fog_sky_affect = 0.5
	#env.fog_color = Color(0.8, 0.9, 1.0)
	
	# Glow effect for the crystal elements
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_bloom = 0.2
	
	environment.environment = env
	add_child(environment)


# --- STEP 2: TERRAIN CREATION ---
func create_terrain():
	# Base terrain
	var terrain_mesh = PlaneMesh.new()
	terrain_mesh.size = Vector2(50, 50)
	terrain_mesh.subdivide_width = 100
	terrain_mesh.subdivide_depth = 100
	
	# Create MeshInstance for terrain
	var terrain = MeshInstance3D.new()
	terrain.mesh = terrain_mesh
	terrain.name = "Terrain"
	
	# Create material for terrain
	var terrain_material = StandardMaterial3D.new()
	terrain_material.albedo_color = Color(0.2, 0.4, 0.15)
	terrain_material.roughness = 0.9
	terrain.material_override = terrain_material
	
	# Apply noise-based height to the terrain
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.05
	
	# Generate heightmap from noise
	var mesh_data_tool = MeshDataTool.new()
	mesh_data_tool.create_from_surface(terrain_mesh, 0)
	
	for i in range(mesh_data_tool.get_vertex_count()):
		var vertex = mesh_data_tool.get_vertex(i)
		var noise_value = noise.get_noise_2d(vertex.x, vertex.z) * 5.0
		vertex.y = noise_value
		mesh_data_tool.set_vertex(i, vertex)
	
	# Create a new array mesh and add the modified surface
	var array_mesh = ArrayMesh.new()
	mesh_data_tool.commit_to_surface(array_mesh)
	terrain.mesh = array_mesh
	
	# Add collision
	var terrain_collision = CollisionShape3D.new()
	var terrain_shape = terrain_mesh.create_trimesh_shape()
	terrain_collision.shape = terrain_shape
	terrain.add_child(terrain_collision)
	
	add_child(terrain)
	
	# Add central "island" formations
	create_central_formations()
	
	# Add smaller rock formations
	create_rock_formations()


# --- STEP 3: CENTRAL FORMATIONS ---
func create_central_formations():
	# Create the tall spiral/floral formations
	for i in range(3):
		var spiral = create_spiral_formation()
		spiral.position = Vector3(randf_range(-5, 5), 5, randf_range(-5, 5))
		spiral.scale = Vector3(2 + randf() * 2, 5 + randf() * 5, 2 + randf() * 2)
		spiral.rotation_degrees.y = randf() * 360
		add_child(spiral)
	
	# Create the blue crystal formation
	var crystal = create_crystal_formation()
	crystal.position = Vector3(0, 7, 0)
	crystal.scale = Vector3(3, 6, 3)
	add_child(crystal)


func create_spiral_formation():
	var spiral = Node3D.new()
	spiral.name = "SpiralFormation"
	
	# Create the core
	var core_mesh = CylinderMesh.new()
	core_mesh.top_radius = 0.5
	core_mesh.bottom_radius = 1.0
	core_mesh.height = 10.0
	
	var core = MeshInstance3D.new()
	core.mesh = core_mesh
	
	# Material for spiral core
	var core_material = StandardMaterial3D.new()
	core_material.albedo_color = Color(0.8, 0.7, 0.6)
	core_material.roughness = 0.7
	core.material_override = core_material
	
	spiral.add_child(core)
	
	# Add decorative elements to make it look like the floral/coral formations
	for i in range(20):
		var petal_mesh = CapsuleMesh.new()
		petal_mesh.radius = 0.3
		petal_mesh.height = 2.0
		
		var petal = MeshInstance3D.new()
		petal.mesh = petal_mesh
		
		# Position the petal around the core
		var angle = i * (PI * 2 / 20)
		var height = (i % 5) * 2.0
		petal.position = Vector3(cos(angle) * 1.2, height, sin(angle) * 1.2)
		
		# Orient the petal outward
		petal.look_at_from_position(petal.position, Vector3(petal.position.x * 2, petal.position.y, petal.position.z * 2), Vector3.UP)
		
		# Material for petals with varying colors
		var petal_material = StandardMaterial3D.new()
		var hue = fmod(i * 0.1, 1.0)
		petal_material.albedo_color = Color.from_hsv(hue, 0.3, 0.9)
		petal_material.roughness = 0.5
		petal.material_override = petal_material
		
		spiral.add_child(petal)
	
	return spiral


func create_crystal_formation():
	var crystal = Node3D.new()
	crystal.name = "CrystalFormation"
	
	# Create the main crystal body
	var crystal_mesh = PrismMesh.new()
	crystal_mesh.size = Vector3(2, 4, 2)
	
	var crystal_instance = MeshInstance3D.new()
	crystal_instance.mesh = crystal_mesh
	
	# Material for the crystal
	var crystal_material = StandardMaterial3D.new()
	crystal_material.albedo_color = Color(0.2, 0.4, 0.8, 0.7)
	crystal_material.metallic = 0.7
	crystal_material.roughness = 0.2
	crystal_material.emission = Color(0.1, 0.3, 0.6)
	crystal_material.emission_energy = 0.5
	crystal_material.refraction_enabled = true
	crystal_material.refraction_scale = 0.05
	crystal_material.flags_transparent = true
	crystal_instance.material_override = crystal_material
	
	crystal.add_child(crystal_instance)
	
	# Add smaller crystals around the main one
	for i in range(5):
		var small_crystal_mesh = PrismMesh.new()
		small_crystal_mesh.size = Vector3(0.5, 1.5, 0.5)
		
		var small_crystal = MeshInstance3D.new()
		small_crystal.mesh = small_crystal_mesh
		
		# Position the small crystals around the main one
		var angle = i * (PI * 2 / 5)
		small_crystal.position = Vector3(cos(angle) * 1.5, 0, sin(angle) * 1.5)
		small_crystal.rotation_degrees.y = randf() * 360
		
		# Material for smaller crystals with slight variations
		var small_crystal_material = crystal_material.duplicate()
		small_crystal_material.albedo_color = Color(0.2, 0.5, 0.7, 0.7)
		small_crystal.material_override = small_crystal_material
		
		crystal.add_child(small_crystal)
	
	return crystal


# --- STEP 4: ROCK FORMATIONS ---
func create_rock_formations():
	for i in range(15):
		var rock = create_rock()
		var pos_x = randf_range(-20, 20)
		var pos_z = randf_range(-20, 20)
		var distance = sqrt(pos_x * pos_x + pos_z * pos_z)
		
		# Place rocks away from center
		if distance < 10:
			pos_x *= 1.5
			pos_z *= 1.5
		
		rock.position = Vector3(pos_x, randf_range(0, 2), pos_z)
		rock.scale = Vector3(randf_range(0.5, 2), randf_range(0.5, 2), randf_range(0.5, 2))
		rock.rotation_degrees = Vector3(randf() * 30, randf() * 360, randf() * 30)
		add_child(rock)


func create_rock():
	var rock = MeshInstance3D.new()
	rock.name = "Rock"
	
	# Choose between several rock meshes
	var rock_type = randi() % 3
	match rock_type:
		0:
			rock.mesh = BoxMesh.new()
		1:
			rock.mesh = SphereMesh.new()
		2:
			rock.mesh = CapsuleMesh.new()
	
	# Material for rocks
	var rock_material = StandardMaterial3D.new()
	rock_material.albedo_color = Color(0.4, 0.35, 0.3)
	rock_material.roughness = 0.9
	rock.material_override = rock_material
	
	return rock


# --- STEP 5: WATER FEATURES ---
func add_water():
	# Create water plane
	var water_mesh = PlaneMesh.new()
	water_mesh.size = Vector2(50, 50)
	
	var water = MeshInstance3D.new()
	water.mesh = water_mesh
	water.name = "Water"
	water.position.y = 1.0  # Slightly above the lowest terrain point
	
	# Create water material
	var water_material = StandardMaterial3D.new()
	water_material.albedo_color = Color(0.1, 0.3, 0.5, 0.7)
	water_material.roughness = 0.1
	water_material.metallic = 0.3
	water_material.flags_transparent = true
	water.material_override = water_material
	
	add_child(water)
	
	# Add boats
	add_boats()


func add_boats():
	for i in range(3):
		var boat = create_boat()
		var pos_x = randf_range(-15, 15)
		var pos_z = randf_range(-15, 15)
		boat.position = Vector3(pos_x, 1.1, pos_z)  # Just above water level
		boat.rotation_degrees.y = randf() * 360
		add_child(boat)


func create_boat():
	var boat = Node3D.new()
	boat.name = "Boat"
	
	# Create boat hull
	var hull_mesh = BoxMesh.new()
	hull_mesh.size = Vector3(1.0, 0.3, 2.0)
	
	var hull = MeshInstance3D.new()
	hull.mesh = hull_mesh
	
	# Material for boat hull
	var hull_material = StandardMaterial3D.new()
	hull_material.albedo_color = Color(0.6, 0.4, 0.2)
	hull.material_override = hull_material
	
	boat.add_child(hull)
	
	# Create mast (for some boats)
	if randf() > 0.5:
		var mast_mesh = CylinderMesh.new()
		mast_mesh.top_radius = 0.05
		mast_mesh.bottom_radius = 0.05
		mast_mesh.height = 1.5
		
		var mast = MeshInstance3D.new()
		mast.mesh = mast_mesh
		mast.position = Vector3(0, 0.9, 0)
		
		# Material for mast
		var mast_material = StandardMaterial3D.new()
		mast_material.albedo_color = Color(0.8, 0.7, 0.6)
		mast.material_override = mast_material
		
		boat.add_child(mast)
	
	return boat


# --- STEP 6: STRUCTURES ---
func add_structures():
	# Add the cabin/house
	var cabin = create_cabin()
	cabin.position = Vector3(randf_range(-5, 5), 4.0, randf_range(-5, 5))
	cabin.rotation_degrees.y = randf() * 360
	add_child(cabin)


func create_cabin():
	var cabin = Node3D.new()
	cabin.name = "Cabin"
	
	# Create cabin base
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(2.0, 1.5, 2.0)
	
	var base = MeshInstance3D.new()
	base.mesh = base_mesh
	
	# Material for cabin base
	var base_material = StandardMaterial3D.new()
	base_material.albedo_color = Color(0.5, 0.35, 0.2)
	base.material_override = base_material
	
	cabin.add_child(base)
	
	# Create cabin roof
	var roof_mesh = PrismMesh.new()
	roof_mesh.size = Vector3(2.2, 1.0, 2.2)
	
	var roof = MeshInstance3D.new()
	roof.mesh = roof_mesh
	roof.position = Vector3(0, 1.25, 0)
	
	# Material for cabin roof
	var roof_material = StandardMaterial3D.new()
	roof_material.albedo_color = Color(0.7, 0.3, 0.2)
	roof.material_override = roof_material
	
	cabin.add_child(roof)
	
	# Add a chimney
	var chimney_mesh = BoxMesh.new()
	chimney_mesh.size = Vector3(0.3, 0.8, 0.3)
	
	var chimney = MeshInstance3D.new()
	chimney.mesh = chimney_mesh
	chimney.position = Vector3(0.6, 1.9, 0)
	
	# Material for chimney
	var chimney_material = StandardMaterial3D.new()
	chimney_material.albedo_color = Color(0.4, 0.3, 0.25)
	chimney.material_override = chimney_material
	
	cabin.add_child(chimney)
	
	# Add a door
	var door_mesh = BoxMesh.new()
	door_mesh.size = Vector3(0.5, 0.8, 0.05)
	
	var door = MeshInstance3D.new()
	door.mesh = door_mesh
	door.position = Vector3(0, -0.35, 1.025)
	
	# Material for door
	var door_material = StandardMaterial3D.new()
	door_material.albedo_color = Color(0.3, 0.2, 0.1)
	door.material_override = door_material
	
	cabin.add_child(door)
	
	# Add windows
	add_window(cabin, Vector3(0.7, 0, 1.025))
	add_window(cabin, Vector3(-0.7, 0, 1.025))
	add_window(cabin, Vector3(0.7, 0, -1.025))
	add_window(cabin, Vector3(-0.7, 0, -1.025))
	
	return cabin


func add_window(parent, position):
	var window_mesh = BoxMesh.new()
	window_mesh.size = Vector3(0.4, 0.4, 0.05)
	
	var window = MeshInstance3D.new()
	window.mesh = window_mesh
	window.position = position
	
	# Material for window
	var window_material = StandardMaterial3D.new()
	window_material.albedo_color = Color(0.8, 0.9, 1.0, 0.7)
	window_material.emission = Color(0.8, 0.9, 1.0)
	window_material.emission_energy = 0.5
	window_material.flags_transparent = true
	window.material_override = window_material
	
	parent.add_child(window)


# --- STEP 7: DECORATIVE ELEMENTS ---
func add_decorative_elements():
	# Add trees
	add_trees()
	
	# Add floating clouds
	add_clouds()


func add_trees():
	for i in range(20):
		var tree = create_tree()
		var pos_x = randf_range(-20, 20)
		var pos_z = randf_range(-20, 20)
		var distance = sqrt(pos_x * pos_x + pos_z * pos_z)
		
		# Avoid center area and water
		if distance < 8:
			pos_x *= 1.5
			pos_z *= 1.5
		
		tree.position = Vector3(pos_x, 0, pos_z)
		tree.scale = Vector3(randf_range(0.5, 1.5), randf_range(0.7, 2.0), randf_range(0.5, 1.5))
		add_child(tree)


func create_tree():
	var tree = Node3D.new()
	tree.name = "Tree"
	
	# Create tree trunk
	var trunk_mesh = CylinderMesh.new()
	trunk_mesh.top_radius = 0.1
	trunk_mesh.bottom_radius = 0.2
	trunk_mesh.height = 1.0
	
	var trunk = MeshInstance3D.new()
	trunk.mesh = trunk_mesh
	trunk.position.y = 0.5
	
	# Material for trunk
	var trunk_material = StandardMaterial3D.new()
	trunk_material.albedo_color = Color(0.4, 0.3, 0.2)
	trunk.material_override = trunk_material
	
	tree.add_child(trunk)
	
	# Create tree top (conical for pine trees like in the image)
	var top_mesh = CylinderMesh.new()
	top_mesh.top_radius = 0.0
	top_mesh.bottom_radius = 0.7
	top_mesh.height = 2.0
	
	var top = MeshInstance3D.new()
	top.mesh = top_mesh
	top.position.y = 2.0
	
	# Material for tree top
	var top_material = StandardMaterial3D.new()
	top_material.albedo_color = Color(0.1, 0.4, 0.2)
	top.material_override = top_material
	
	tree.add_child(top)
	
	return tree


func add_clouds():
	for i in range(8):
		var cloud = create_cloud()
		cloud.position = Vector3(randf_range(-20, 20), randf_range(10, 15), randf_range(-20, 20))
		cloud.scale = Vector3(randf_range(1, 3), randf_range(0.5, 1.5), randf_range(1, 3))
		add_child(cloud)


func create_cloud():
	var cloud = Node3D.new()
	cloud.name = "Cloud"
	
	# Create cloud from multiple spheres
	for i in range(5):
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 1.0
		sphere_mesh.height = 2.0
		
		var sphere = MeshInstance3D.new()
		sphere.mesh = sphere_mesh
		
		# Position spheres to form a cloud
		var offset_x = randf_range(-1, 1)
		var offset_y = randf_range(-0.5, 0.5)
		var offset_z = randf_range(-1, 1)
		sphere.position = Vector3(offset_x, offset_y, offset_z)
		
		# Material for clouds
		var cloud_material = StandardMaterial3D.new()
		cloud_material.albedo_color = Color(1.0, 1.0, 1.0, 0.8)
		cloud_material.flags_transparent = true
		sphere.material_override = cloud_material
		
		cloud.add_child(sphere)
	
	return cloud


# --- STEP 8: CAMERA AND LIGHTING ---
func setup_camera_and_lighting():
	# Create camera
	var camera = Camera3D.new()
	camera.name = "MainCamera"
	camera.position = Vector3(15, 10, 15)
	camera.look_at_from_position(camera.position, Vector3(0, 5, 0), Vector3.UP)
	
	# Set up camera properties
	camera.fov = 60
	
	add_child(camera)
	
	# Add directional light (sun)
	var sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.position = Vector3(0, 20, 0)
	sun.look_at_from_position(sun.position, Vector3(5, 0, 5), Vector3.UP)
	
	# Set up sun properties
	sun.light_color = Color(1.0, 0.9, 0.8)
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	
	add_child(sun)
	
	# Add ambient lights for better scene illumination
	var ambient_light = OmniLight3D.new()
	ambient_light.name = "AmbientLight"
	ambient_light.position = Vector3(0, 10, 0)
	
	# Set up ambient light properties
	ambient_light.light_color = Color(0.6, 0.7, 0.8)
	ambient_light.light_energy = 0.5
	ambient_light.omni_range = 30
	
	add_child(ambient_light)
